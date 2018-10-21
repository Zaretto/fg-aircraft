
#
# AN/SPN 46 transmits - this receives.
var ARA63Recipient =
{
    new: func(_ident)
    {
        var new_class = emesary.Recipient.new(_ident);
        new_class.ansn46_expiry = 0;
        new_class.Receive = func(notification)
        {
            if (notification.Type == "ANSPN46ActiveNotification")
            {
                print(" :: Recvd lat=",notification.Position.lat(), " lon=",notification.Position.lon(), " alt=",notification.Position.alt(), " chan=",notification.Channel);
                var response_msg = me.Response.Respond(notification);
#
# We cannot decide if in range as it is the AN/SPN system to decide if we are within range
# However we will tell the AN/SPN system if we are tuned (and powered on)
                if(notification.Channel == getprop("sim/model/f-14b/controls/electrics/ara-63-channel") and getprop("sim/model/f-14b/controls/electrics/ara-63-power-off") == 0)
                    response_msg.Tuned = 1;
                else
                    response_msg.Tuned = 0;

# normalised value based on RCS beam power etc.
# we could do this using a factor.
                response_msg.RadarReturnStrength = 1; # possibly response_msg.RadarReturnStrength*RCS_FACTOR

                emesary.GlobalTransmitter.NotifyAll(response_msg);
                return emesary.Transmitter.ReceiptStatus_OK;
            }
#---------------------
# we will only receive one of these messages when within range of the carrier (and when the ARA-63 is powered up and has the correct channel set)
#
            else if (notification.Type == "ANSPN46CommunicationNotification")
            {
                me.ansn46_expiry = getprop("/sim/time/elapsed-sec") + 10;
# Use the standard civilian ILS if it is closer.
        print("rcvd ANSPN46CommunicationNotification =",notification.InRange, " dev=",notification.LateralDeviation, ",", notification.VerticalDeviation, " dist=",notification.Distance);
                if(getprop("instrumentation/nav/gs-in-range") and getprop("instrumentation/nav/gs-distance") < notification.Distance)
                {
                    me.ansn46_expiry=0;
                    return emesary.Transmitter.ReceiptStatus_OK;
                }
                else if (notification.InRange)
                {
                    setprop("sim/model/f-14b/instrumentation/nav/gs-in-range", 1);
                    setprop("sim/model/f-14b/instrumentation/nav/gs-needle-deflection-norm",notification.VerticalAdjustmentCommanded);
                    setprop("sim/model/f-14b/instrumentation/nav/heading-needle-deflection-norm",notification.HorizontalAdjustmentCommanded);
                    setprop("sim/model/f-14b/instrumentation/nav/signal-quality-norm",notification.SignalQualityNorm);
                    setprop("sim/model/f-14b/instrumentation/nav/gs-distance", notification.Distance);
                    setprop("sim/model/f-14b/lights/light-10-seconds",notification.TenSeconds);
                    setprop("sim/model/f-14b/lights/light-wave-off",notification.WaveOff);

# Set these lights on when in range and within altitude.
# the lights come on but it is unspecified when they go off.
# Ref: F-14AAD-1 Figure 17-4, p17-11 (pdf p685)
                    if (notification.Distance < 11000) 
                    {
                        if (notification.ReturnPosition.alt() > 300 and notification.ReturnPosition.alt() < 425 and abs(notification.LateralDeviation) < 1 )
                        {
                            setprop("sim/model/f-14b/lights/acl-ready-light", 1);
                            setprop("sim/model/f-14b/lights/ap-cplr-light",1);
                        }
                        if (notification.Distance > 8000)  # extinguish at roughly 4.5nm from fix.
                        {
                            setprop("sim/model/f-14b/lights/landing-chk-light", 1);
                        }
                        else
                        {
                            setprop("sim/model/f-14b/lights/landing-chk-light", 0);
                        }
                    }
                }
                else
                {
                    #
                    # Not in range so turn it all off. 
                    # NOTE: Currently this will never be called as the AN/SPN-46 system will not notify us when we are not in range
                    #       It is implemented here for completeness and to do the correct thing if the implemntation changes
                    setprop("sim/model/f-14b/instrumentation/nav/gs-in-range", 0);
                    setprop("sim/model/f-14b/instrumentation/nav/gs-needle-deflection-norm",1);
                    setprop("sim/model/f-14b/instrumentation/nav/heading-needle-deflection-norm",1);
                    setprop("sim/model/f-14b/instrumentation/nav/signal-quality-norm",0);
                    setprop("sim/model/f-14b/instrumentation/nav/gs-distance", -1000000);
                    setprop("sim/model/f-14b/lights/landing-chk-light", 0);
                    setprop("sim/model/f-14b/lights/light-10-seconds",0);
                    setprop("sim/model/f-14b/lights/light-wave-off",0);
                    setprop("sim/model/f-14b/lights/acl-ready-light", 0);
                    setprop("sim/model/f-14b/lights/ap-cplr-light",0);
                }

                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        new_class.Response = ANSPN46ActiveResponseNotification.new("ARA-63");
        return new_class;
    },
};

#
# Instantiate ARA 63 receiver. This will work when approaching any
# carrier that has an active AN/SPN-46 transmitting.
# The ARA-63 is a Precision Approach Landing system that is fitted to all US
# carriers.
var ara63 = ARA63Recipient.new("ARA-63");
emesary.GlobalTransmitter.Register(ara63);

#
# Update the ARA-63; this doess two things - firstly to extinguish the
# lights if the validity period expires, and secondly to use the civilian ILS
# if present. Needs to be called from the main loop
var ara_63_update = func
{
#
# do not do anything whilst the AN/SPN 46 is within expiry time. 
    if(getprop("/sim/time/elapsed-sec") < ara63.ansn46_expiry)
        return;

#
# Use the standard civilian ILS
    setprop("sim/model/f-14b/lights/landing-chk-light", 0);
    setprop("sim/model/f-14b/lights/light-10-seconds",0);
    setprop("sim/model/f-14b/lights/light-wave-off",0);
    setprop("sim/model/f-14b/lights/acl-ready-light", 0);
    setprop("sim/model/f-14b/lights/ap-cplr-light",0);

    if (getprop("instrumentation/nav/gs-in-range") != nil)
    {
        setprop("sim/model/f-14b/instrumentation/nav/gs-in-range", getprop("instrumentation/nav/gs-in-range"));
        setprop("sim/model/f-14b/instrumentation/nav/gs-needle-deflection-norm",getprop("instrumentation/nav/gs-needle-deflection-norm"));
        setprop("sim/model/f-14b/instrumentation/nav/gs-distance", getprop("instrumentation/nav/gs-distance"));
        setprop("sim/model/f-14b/instrumentation/nav/heading-needle-deflection-norm",getprop("instrumentation/nav/heading-needle-deflection-norm"));
        setprop("sim/model/f-14b/instrumentation/nav/signal-quality-norm",getprop("instrumentation/nav/signal-quality-norm"));
    }
}

