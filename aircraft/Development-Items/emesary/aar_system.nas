#---------------------------------------------------------------------------
#
#	Title                : Air to Air refuelling support 
#
#	File Type            : Implementation File
#
#	Description          : 
#                        : 
#	                     : 
#                        : 
#                        : 
#  
#   References           : 
#                        : 
#                        : 
#
#	Author               : Richard Harrison (richard@zaretto.com)
#
#	Creation Date        : 03 April 2016
#
#	Version              : 
#
#  Copyright © 2016 Richard Harrison           Released under GPL V2
#
#---------------------------------------------------------------------------*/
#Message Reference:
#---------------------------------------------------------------------------*/
#
#
#----------------------
# NOTE: to avoid garbage collection all of the notifications that are sent out are created during construction
#       and simply modified prior to sending. This works because emesary is synchronous and therefore the state
#       and lifetime are known.

#
# Notification(1) from tanker to all aircraft within range.
#
var AARQueryNotification = 
{
    # Query aircraft for their position and AAR status.
    # param(_aar_system): instance of AAR_System which will send the notification 
    new: func(_aar_system)
    {
        var new_class = emesary.Notification.new("AARQueryNotification", _aar_system.Ident);

        new_class.AAR_system = _aar_system;
        new_class.set_from = func(_aar_system)
        {
            me.MinimumDistance = 10e10;
            me.TankerPosition = _aar_system.GetPosition();
            me.AircraftReadyToReceive = 0;
            me.AircraftPosition = nil;
        };
        new_class.ProcessAircraft = func(_position, _readyToReceive)
        {
            # only interested in the closest aircraft, so find out the distance
            # and if it is the closest and ready then we are ready.
            var aircraft_dist = _position.distance_to(me.TankerPosition);
            if (aircraft_dist < me.MinimumDistance)
            {
                me.AircraftPosition = _position;
                me.MinimumDistance = aircraft_dist;
                if (_readyToReceive)
                    me.AircraftReadyToReceive = 1;
                print ("Aircraft dist ",me.MinimumDistance," READY=",me.AircraftReadyToReceive);
            }
        };
        return new_class;
    },
};

var AAR_System = 
{
    new: func(_ident,_model)
    {
        print("AAR system created for "~_ident);

        var new_class = emesary.Recipient.new("AAR_System "~_ident);

        new_class.aar_position = geo.Coord.new();
        new_class.Model = _model;
        new_class.UpdateRate = 10;
        new_class.PropRoot = _model.getPath();
        _model.getNode("controls/boom-position",1).setIntValue(0);
print("prop root ",new_class.PropRoot);
#-------------------------------------------
# Receive override:

       new_class.Receive = func(notification)
        {
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        }
#
# Interface methods
#-----------------------------
# Required interface to get the current carrier position
        new_class.GetPosition = func()
        {
print("Model path",me.Model.getPath());
    		var lat = me.Model.getNode("position/latitude-deg").getValue();
	    	var lon = me.Model.getNode("position/longitude-deg").getValue();
    		var alt = me.Model.getNode("position/altitude-ft").getValue();
print("Tanker pos lat=",lat,"lon=",lon,"alt=",alt);
            me.aar_position.set_latlon(lat, lon, alt);
            return me.aar_position;
        };
#
# Interface to get the carrier heading
        new_class.GetHeading = func()
        {
            return me.Model.getNode("orientation/true-heading-deg");
        };
        new_class.GetUpdateRate = func
        {
            return me.UpdateRate;
        };
#
# main entry point. The object itself will manage the update rate - but it is
# up to the caller to use this rate
        new_class.Update = func
        {
            me.msg.set_from(me);
            var rv= emesary.GlobalTransmitter.NotifyAll(me.msg);
            if (rv == emesary.Transmitter.ReceiptStatus_OK)
            {
                print("AAR: ",me.msg.MinimumDistance," ready=",me.msg.AircraftReadyToReceive);
                if (me.msg.MinimumDistance <= 2000)
                {
                    me.UpdateRate = 0.1;
                    me.Model.getNode("controls/boom-position").setValue(me.msg.AircraftReadyToReceive);
                }
                else if (me.msg.MinimumDistance <= 45000)
                {
                    me.UpdateRate = 1;
                    me.Model.getNode("controls/boom-position").setValue(me.msg.AircraftReadyToReceive);
                }
                else
                    me.UpdateRate = 10;
            }

        };

#
# create the message that will be used to notify of an active carrier. This needs to be done after the methods 
# have been created as it references them. Implemented like this to reduce garbage collection
        new_class.msg = AARQueryNotification.new(new_class);

        emesary.GlobalTransmitter.Register(new_class);
        return new_class;
    },
}
