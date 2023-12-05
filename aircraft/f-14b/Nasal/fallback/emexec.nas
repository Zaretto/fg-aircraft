 #---------------------------------------------------------------------------
 #
 #	Title                : Emesary based 'real time' module executive
 #
 #	File Type            : Implementation File
 #
 #	Description          : Uses Emesary notifications to permit Nasal subsystems to be invoked in
 #                       : a controlled manner.
 #                       : 
 #                       : Sends out a FrameNotification for each frame recipient can implement
 #                       : workload reduction as appropriate based on skipping frames (2=half,
 #                       : 4=quarter etc.) because some code can safely be run at quarter rate
 #                       : (e.g. ~10hz).
 #                       : 
 #                       : The developer should interleave slower rate modules to spread out
 #                       : workload A frame is defined by the timer rate; which is usually the
 #                       : maximum rate as determined by the FPS.
 #                       : 
 #                       : This is an alternative to the timer based or explicit function calling
 #                       : way of invoking aircraft systems.  It has the advantage of using less
 #                       : timers and remaining modular, as each aircraft subsytem can simply
 #                       : register itself with the global transmitter to receive the frame
 #                       : notification.
 #
 #	See Also             : https://wiki.flightgear.org/Nasal_Optimisation#Emesary_real_time_executive
 #                       : F-15 and F-14 for examples of how to use this.
 #
 #	Author               : Richard Harrison (richard@zaretto.com)
 #
 #	Creation Date        : 4 June 2018
 #
 #  Copyright (C) 2018 Richard Harrison           Released under GPL V2
 #
 #---------------------------------------------------------------------------*/

#
#
# This is the notification that is sent out to all recipients each frame.
# The notification contains a hash of property values.
# Frame modules can request that the hash includes key/property pairs 
# by using the FrameNotificationAddProperty
#
# An instance of this class is be contained within the  EmesaryExecutive.

var FrameNotification = 
{
    debug: 0,
    # The rate and the transmitter to use
    new: func(_rate, transmitter=nil)
    {
        if (transmitter == nil)
            transmitter = emesary.GlobalTransmitter;

        var new_class = emesary.Notification.new("FrameNotification", _rate, 0);
        append(new_class.parents, FrameNotification);
        new_class.Rate = _rate;
        new_class.FrameCount = 0;
        new_class.ElapsedSeconds = 0;
        new_class.monitored = {};
        new_class.properties = {};
        new_class.transmitter = transmitter;

        #
        # embed a recipient within this notification to allow the monitored property
        # mapping list to be modified.
        new_class.Recipient = emesary.Recipient.new("FrameNotification");
        new_class.Recipient.Receive = func(notification)
        {
            if (notification.NotificationType == "FrameNotificationAddProperty")
            {
                var root_node = props.globals;
                if (notification.root_node != nil) {
                    root_node = notification.root_node;
                }
                if (new_class.properties[notification.property] != nil 
                    and new_class.properties[notification.property] != notification.variable)
                  logprint(1,"FrameNotification: (",notification.module,") FrameNotification: already have variable ",new_class.properties[notification.property]," for ",notification.variable, " referencing property ",notification.property);

                if (new_class.monitored[notification.variable] != nil 
                    and new_class.monitored[notification.variable].getPath() != notification.property
                    and new_class.monitored[notification.variable].getPath() != "/"~notification.property)
                  logprint(1,"FrameNotification: (",notification.module,") FrameNotification: already have variable ",notification.variable,"=",new_class.monitored[notification.variable].getPath(), " using different property ",notification.property);
                #                else if (new_class.monitored[notification.variable] == nil)
                #                  print("[INFO]: (",notification.module,") FrameNotification.",notification.variable, " = ",notification.property);

                new_class.monitored[notification.variable] = root_node.getNode(notification.property,1);
                new_class.properties[notification.property] = notification.variable;

                logprint(4,"(",notification.module,") FrameNotification.",notification.variable, " = ",notification.property, " -> ", new_class.monitored[notification.variable].getPath() );
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        new_class.transmitter.Register(new_class.Recipient);
        return new_class;
    },
    fetchvars : func() {
        foreach (var mp; keys(me.monitored)){
            if(me.monitored[mp] != nil){
                if (FrameNotification.debug > 1)
                    logprint(5," ",mp, " = ",me.monitored[mp].getValue());
                me[mp] = me.monitored[mp].getValue();
            }
        }
    },
};

#
# request to add a property to the frame notification
var FrameNotificationAddProperty = 
{
    new: func(module, variable, property, root_node=nil)
    {
        var new_class = emesary.Notification.new("FrameNotificationAddProperty", variable, 0);
        if (root_node == nil)
          root_node = props.globals;
        new_class.module = module ;
        new_class.variable = variable;
        new_class.property = property;
        new_class.root_node = root_node;
        return new_class;
    },
};

#
# the main exeuctive class.
# There will be one of these as emexec.ExceModule however multiple instances could be 
# created - but only by those who understand scheduling - because it is not necessary
# to have more than one - unless we mange to enable some sort of per core threading.
var EmesaryExecutive =  {
    new : func(_ident="EMEXEC", transmitter=nil) {

        # by default use global transmitter
        if (transmitter == nil)
            transmitter = emesary.GlobalTransmitter;

        var new_class = {
            parents: [EmesaryExecutive],
            Ident: _ident,
            lp : aircraft.lowpass.new(3),
            frameNotification : FrameNotification.new(1, transmitter),
            emexecRate : props.globals.getNode("/sim/emexec/rate-hz",1),
            emexecMaxRate : props.globals.getNode("/sim/emexec/max-rate-hz",1),
            frame_inc : 0,
            cur_frame_inc : 0.033, # start off at 33hz
        };
        new_class.transmitter = transmitter;
        new_class.set_rate(30);
        
        # setup the properties to monitor for this system
        var exec_prop_list = {
                frame_rate                : "/sim/frame-rate",
                frame_rate_worst          : "/sim/frame-rate-worst",
                elapsed_seconds           : "/sim/time/elapsed-sec",
                };
        new_class.monitor_properties(exec_prop_list);

        # now setup the timer.
        # - initially use update rate of 30hz.
        # - use simulated time as otherwise will continue to be called when paused
        # - start timer now, as the listener will effectively block module calls until sim init
        new_class.frameNotification.running = 0;
        setlistener("sim/signals/fdm-initialized", func(v) {
            logprint(1,"started ",new_class.Ident);
            new_class.frameNotification.dT = 0; # seconds
            new_class.frameNotification.curT = 0;
            new_class.frameNotification.running = 1;
        });
        new_class.execTimer = maketimer(new_class.cur_frame_inc, new_class, new_class.timerCallback);
        new_class.execTimer.simulatedTime = 1;

        return new_class;
     },
     set_rate : func(ratehz){
        me.emexecRate.setValue(ratehz);
        me.cur_frame_inc = 1.0/ratehz;
        me.frame_inc = me.cur_frame_inc;
     },
     start : func {
        me.execTimer.start();
     },
     stop : func {
        me.execTimer.stop();
     },
     # request monitoring of a list of hash value pairs.
     monitor_properties : func(input){
        # this uses a notification to isolate the implementation which is also in this module; so it could
        # call directly; however the design is that a FrameNotification add property could also trigger other
        # logic that we do not know about.
        foreach (var name; keys(input)) {
            me.transmitter.NotifyAll(FrameNotificationAddProperty.new(me.Ident, name, input[name]));
        }
     },

     # ident: String (e.g F-15 HUD)
     # inputs: hash of properties to monitor
     #         : e.g 
     #           {
     #               AirspeedIndicatorIndicatedMach          : "instrumentation/airspeed-indicator/indicated-mach",
     #               Alpha                                   : "orientation/alpha-indicated-deg",
     #           }
     #          : object - must have an update(notification) method that will receive a  frame notification
     #          : rate is the frame skip update rate (1/update rate). 0 or 1 means full rate
     #          : offset is the offset to permit interleave
     #             - e.g for two objects to interleave we could have a rate of two and an offset of 0 and 1 which
     #                    would result in one object being processed per frame
     register: func(ident, properties_to_monitor, object, rate=1, frame_offset=0) {
		var new_class = emesary.Recipient.new(ident);

        me.monitor_properties(properties_to_monitor);
        new_class.object = object;
        new_class.Receive = func(notification)
        {
            if (notification.NotificationType == "FrameNotification"){
                if (rate <= 1 or 0 == math.mod(notification.FrameCount + frame_offset,rate)){
                    new_class.object.update(notification);
                }
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        me.transmitter.Register(new_class);
        return new_class;
  },
  timerCallback : func {

         if (!me.frameNotification.running){
            logprint(3, me.Ident~": Waiting for start");
            return;
        }
        me.frameNotification.fetchvars();
        me.frameNotification.dT = me.frameNotification.elapsed_seconds - me.frameNotification.curT;

        if (me.frameNotification.dT > 1.0) 
        me.frameNotification.curT = me.frameNotification.elapsed_seconds;

        me.transmitter.NotifyAll(me.frameNotification);

        me.frameNotification.FrameCount = me.frameNotification.FrameCount + 1;
        me.frameNotification.filtered_frame_rate = (int)(me.lp.filter(me.frameNotification.frame_rate));
    
        # this permits us to go up to 1/32 rate (which could be less than 1hz)
        if (me.frameNotification.FrameCount > 32) {
            me.frameNotification.FrameCount = 0;
        # adjust exec rate based on frame rate.
            # calculate exec update rate based on frame rate; this a quadratic function from a curve fit.
            me.frame_inc = (math.round((0.33227017+0.10041432*me.frameNotification.filtered_frame_rate+0.01681707*me.frameNotification.filtered_frame_rate*me.frameNotification.filtered_frame_rate)/5)*5+5);

            # limit to: 1 <= update rate <= maxRate (default 50) 
            me.frame_inc = math.max(1,math.min(me.emexecMaxRate.getValue(), me.frame_inc));
            me.frame_inc = 1/me.frame_inc;

            # Adjust timer if new value
            if (me.frame_inc != me.cur_frame_inc) {
                me.set_rate(1.0/me.frame_inc);
                me.execTimer.restart(me.cur_frame_inc);
            }
        }
    }
};

# profiling aid: embed within a class
# and each frame call log("something") to trace time
# e.g. to create using the default log level of INFO:
#    ot = OperationTimer.new("VSD");
# or for log level debug 
#    ot = OperationTimer.new("VSD",2);
# ...
# ot.reset();
# ot.log("start");
# ... code ...
# ot.log("half way");
# ... code ...
# ot.log("finished");

OperationTimer = {
    new : func (ident="timer", level=3) {
        {
            parents: [OperationTimer],
            timestamp: maketimestamp(),
            ident: ident,
            resolution_uS: 1000.0,
            level : level,
        }
    },
    log : func( text){
        logprint(me.level, sprintf("%10s: %8.3f : %s",me.ident,  me.timestamp.elapsedUSec()/me.resolution_uS, text));
    },
    reset : func {
       me.timestamp.stamp(); 
    }
};         

# ensure this property is set if not in defaults.xml
if (getprop("/sim/emexec/max-rate-hz") == nil){
   setprop("/sim/emexec/max-rate-hz",30);
}

var xmit = emesary.Transmitter.new("exec");
var ExecModule =  EmesaryExecutive.new("EMEXEC", xmit);
ExecModule.start();