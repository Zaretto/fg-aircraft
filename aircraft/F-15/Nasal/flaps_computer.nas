#
# F-15 Flaps and speedbrakes supporting controls
# ---------------------------
# Richard Harrison (rjh@zaretto.com) Feb  2015 - based on F-14B version by Alexis Bory

var FlapsCmd     = props.globals.getNode("controls/flight/flaps", 1);

FlapsCmd.setValue(0);

var weAppliedSpeedBrake = 99;
var weAppliedWheelBrake = 99;

controls.applyBrakes = func(v, which = 0)  {

    if (wow)
    {
        if (!v and weAppliedSpeedBrake != 99)
        {
            setprop("controls/flight/speedbrake", 0);
            weAppliedSpeedBrake=0;
#            print("F14: dual purpose brakes release release airbrake brakes ",v,which);
        }
        if (which <= 0) { interpolate("/controls/gear/brake-left", v, controls.fullBrakeTime); }
        if (which >= 0) { interpolate("/controls/gear/brake-right", v, controls.fullBrakeTime); }

        weAppliedWheelBrake = which;

#        print("F14: wheelbrakes ",v,":",which);
    }
    else
    {
        if (!v and weAppliedWheelBrake != 99)
        {
            if (weAppliedWheelBrake <= 0) { interpolate("/controls/gear/brake-left", 0, controls.fullBrakeTime); }
            if (weAppliedWheelBrake >= 0) { interpolate("/controls/gear/brake-right", 0, controls.fullBrakeTime); }
            weAppliedWheelBrake=0;
#            print("F14: dual purpose brakes release release wheel brakes ",v,which);
        }

    	if (v and (throttle_0.getValue() >= 0.98 or throttle_1.getValue() >= 0.98))
        {
            # do not extend speed brakes when throttle at MIL or greater.
            return;
        }
        weAppliedSpeedBrake=which;
#        print("F14: airbrakes  down ",v,which);
        setprop("controls/flight/speedbrake", v);
    }
}
# Hijack the generic flaps command so joystick flap command works
# for the F-14 too. 
controls.flapsDown = func(s) {
	if (s == 1) {
		lowerFlaps();
	} elsif (s == -1) {
		raiseFlaps();
	} else {
		return;
	}
}


var lowerFlaps = func {
    var demandedFlaps = 1;
    FlapsCmd.setValue(demandedFlaps);
    setprop("controls/flight/flapscommand", demandedFlaps);
}

var raiseFlaps = func {
    var demandedFlaps = 0;

    FlapsCmd.setValue(demandedFlaps); 

    setprop("controls/flight/flapscommand", demandedFlaps);
}

