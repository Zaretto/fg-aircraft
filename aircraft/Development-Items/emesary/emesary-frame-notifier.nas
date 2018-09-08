#
#
var FrameNotification = 
{
    new: func(_rate)
    {
        var new_class = emesary.Notification.new("FrameNotification", _rate);
        new_class.Rate = _rate;
        new_class.FrameRate = 60;
        new_class.FrameCount = 0;
        new_class.ElapsedSeconds = 0;
        return new_class;
    },
        };

var frameNotification = FrameNotification.new(1);

var rtExec_loop = func
{
    var frame_rate = getprop("/sim/frame-rate");
    var elapsed_seconds = getprop("/sim/time/elapsed-sec");

#
# you can put commonly accessed properties inside the message to improve performance.
    frameNotification.FrameRate = frame_rate;
    frameNotification.ElapsedSeconds = elapsed_seconds;
    frameNotification.CurrentIAS = getprop("velocities/airspeed-kt");
    frameNotification.CurrentMach = getprop("velocities/mach");
    frameNotification.CurrentAlt = getprop("position/altitude-ft");
    frameNotification.wow = getprop("gear/gear[1]/wow") or getprop("gear/gear[2]/wow");
    frameNotification.Alpha = getprop("orientation/alpha-indicated-deg");
    frameNotification.Throttle = getprop("controls/engines/engine/throttle");
    frameNotification.e_trim = getprop("controls/flight/elevator-trim");
    frameNotification.deltaT = getprop ("sim/time/delta-sec");
    frameNotification.current_aileron = getprop("surface-positions/left-aileron-pos-norm");
    frameNotification.currentG = getprop ("accelerations/pilot-gdamped");


    if (frameNotification.FrameCount >= 4)
    {
        frameNotification.FrameCount = 0;
    }
    emesary.GlobalTransmitter.NotifyAll(frameNotification);

    frameNotification.FrameCount = frameNotification.FrameCount + 1;

    settimer(rtExec_loop, 0);
}
settimer(rtExec_loop, 1);


var enginesRecipient = emesary.Recipient.new("Engines");
enginesRecipient.Receive = func(notification)
{
    if (notification.Type == "FrameNotification" and notification.FrameCount == 2)
    {
#print("recv: ",notification.Type, " ", notification.ElapsedSeconds);
        if (APCengaged.getBoolValue())
        {
            if ( wow or !getprop("engines/engine[0]/running") or !getprop("engines/engine[1]/running"))
                APC_off();
        }
    }
}
emesary.GlobalTransmitter.Register(enginesRecipient);
