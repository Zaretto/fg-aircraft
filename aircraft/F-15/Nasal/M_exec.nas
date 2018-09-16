 #---------------------------------------------------------------------------
 #
 #	Title                : Emesary based real time executive
 #
 #	File Type            : Implementation File
 #
 #	Description          : Uses emesary notifications to permit nasal subsystems to
 #                       : be invoked in a controlled manner.
 #
 #	Author               : Richard Harrison (richard@zaretto.com)
 #
 #	Creation Date        : 4 June 2018
 #
 #	Version              : 1.0
 #
 #  Copyright (C) 2018 Richard Harrison           Released under GPL V2
 #
 #---------------------------------------------------------------------------*/



# to add properties to the FrameNotification simply send a FrameNotificationAddProperty
# to the global transmitter. This will be received by the frameNotifcation object and
# included in the update.
#emesary.GlobalTransmitter.NotifyAll(new FrameNotificationAddProperty("MODULE", "wow","gear/gear[0]/wow"));
#emesary.GlobalTransmitter.NotifyAll(new FrameNotificationAddProperty("MODULE", "engine_n2", "engines/engine[0]/n2"));
#    


#
# real time exec loop.
var frame_inc = 0;
var cur_frame_inc = 0.03;

var rtExec_loop = func
{
    #    
    notifications.frameNotification.fetchvars();

    if (!notifications.frameNotification.running){
#        print("M_exec: waiting for sim start");
        return;
    }
    notifications.frameNotification.dT = notifications.frameNotification.elapsed_seconds - notifications.frameNotification.curT;

    if (notifications.frameNotification.dT > 1.0) 
      notifications.frameNotification.curT = notifications.frameNotification.elapsed_seconds;

    if (notifications.frameNotification.FrameCount >= 16) {
        notifications.frameNotification.FrameCount = 0;
    }
    emesary.GlobalTransmitter.NotifyAll(notifications.frameNotification);
    #    

    notifications.frameNotification.FrameCount = notifications.frameNotification.FrameCount + 1;

    # adjust exec rate based on frame rate.
    if (notifications.frameNotification.frame_rate_worst < 5) {
        frame_inc = 0.25;#4 Hz
    } elsif (notifications.frameNotification.frame_rate_worst < 10) {
        frame_inc = 0.125;#8 Hz
    } elsif (notifications.frameNotification.frame_rate_worst < 15) {
        frame_inc = 0.10;#10 Hz
    } elsif (notifications.frameNotification.frame_rate_worst < 20) {
        frame_inc = 0.075;#13.3 Hz
    } elsif (notifications.frameNotification.frame_rate_worst < 25) {
        frame_inc = 0.05;#20 Hz
    } elsif (notifications.frameNotification.frame_rate_worst < 40) {
        frame_inc = 0.0333;#30 Hz
    } else {
        frame_inc = 0.02;#50 Hz
    }
    if (frame_inc != cur_frame_inc) {
#        print("[EMEXEC]: Adjust frequency to ",1/frame_inc, " Hz");
        cur_frame_inc = frame_inc;
    }
    execTimer.restart(cur_frame_inc);

}

# setup the properties to monitor for this system
  input = {
           FrameRate                 : "/sim/frame-rate",
           frame_rate                : "/sim/frame-rate",
           frame_rate_worst          : "/sim/frame-rate-worst",
           elapsed_seconds           : "/sim/time/elapsed-sec",
          };

foreach (var name; keys(input)) {
    emesary.GlobalTransmitter.NotifyAll(notifications.FrameNotificationAddProperty.new("EXEC", name, input[name]));
}

setlistener("sim/signals/fdm-initialized", func {
    notifications.frameNotification.running = 1;
});

notifications.frameNotification.running = 0;
notifications.frameNotification.dT = 0; # seconds
notifications.frameNotification.curT = 0;

var execTimer = maketimer(cur_frame_inc, rtExec_loop);
execTimer.simulatedTime = 1;
execTimer.start();
