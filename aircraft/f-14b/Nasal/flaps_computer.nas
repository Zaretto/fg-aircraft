#----------------------------------------------------------------------------
# Flaps computer     
#----------------------------------------------------------------------------

var m_slat_lo      = 7.7;          # Maneuver slats low alpha threshold.
var m_slat_hi      = 10.5;         # Maneuver slats high alpha threshold.
var m_flap_ext     = 0.286;        # Maneuver flaps extension.
var max_m_slat_ext = 0.41;         # Maximum maneuver slats extension.
var lms_coef       = 0.146428571;  # Linear maneuver slats extension coeff:
# maximum maneuver slats extension / maneuver slats high alpha threshold - maneuver slats low alpha threshold.

var FlapsCmd     = props.globals.getNode("controls/flight/flapscommand", 1);
var AuxFlapsCmd  = props.globals.getNode("/controls/flight/auxFlaps", 1);
var SlatsCmd     = props.globals.getNode("controls/flight/slats", 1);
var MainFlapsCmd = props.globals.getNode("controls/flight/mainFlaps", 1);
#
#
# when deploying the flaps go 0.5, then 0.6 until 1.0
var flapDemandIncrement = 0.1;
if(usingJSBSim)
{
FlapsCmd     = props.globals.getNode("controls/flight/flaps", 1);
SlatsCmd     = props.globals.getNode("/fdm/jsbsim/fcs/slat-cmd", 1);
}

FlapsCmd.setValue(0);
SlatsCmd.setValue(0);
AuxFlapsCmd.setValue(0);

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
    var flaps_cmd = FlapsCmd.getValue();
    var demandedFlaps = 0;

	if (usingJSBSim)
    {
		if (flaps_cmd < 0.5)
        {
			demandedFlaps = 0.5;
        }
		else if (flaps_cmd < 1)
        {
            demandedFlaps = flaps_cmd + flapDemandIncrement;
        }
        else
        {
			demandedFlaps = 1.0;
        }

        FlapsCmd.setValue(demandedFlaps);
        setprop("controls/flight/flapscommand", demandedFlaps);
    }
    else
    {
    	if ( WingSweep < maxSweepAuxFlaps and FlapsCmd.getValue() < 1 ) 
        {
	    	FlapsCmd.setValue(1); # Landing.
        }
    }
    print("F14: lower flaps ",demandedFlaps," ",WingSweep);
}

var raiseFlaps = func {
    var flaps_cmd = FlapsCmd.getValue();
    var demandedFlaps = flaps_cmd;
    if (usingJSBSim)
    {

        if (flaps_cmd > 0.5)
            demandedFlaps = flaps_cmd - flapDemandIncrement;
        else
            demandedFlaps = 0; # Clean.

        FlapsCmd.setValue(demandedFlaps); 
        DLCactive = false;
        DLC_Engaged.setBoolValue(0);

        print("F14: raise flaps ",demandedFlaps);

        setprop("controls/flight/flapscommand", demandedFlaps);
    }
    else
    {
        if ( FlapsCmd.getValue() > 0 ) {
            FlapsCmd.setValue(0); # Clean.
        }
    }
    setprop("controls/flight/DLC", 0);
}

var computeFlaps = func {

    if (usingJSBSim) return;

# disable if we are in replay mode
	if ( getprop("sim/replay/time") > 0 ) { return }

	if (CurrentMach == nil) { CurrentMach = 0 } 
	if (CurrentAlt == nil) { CurrentAlt = 0 }
	if (Alpha == nil) { Alpha = 0 }
	var fc = FlapsCmd.getValue();
	var m_slat_cutoff  = 0.85; # Maneuver slats cutoff mach.
	if ( CurrentAlt < 30000.0 ) {
		m_slat_cutoff = 0.5 + CurrentAlt * 0.000011667; # 0.5 + CurrentAlt * 0.35 / 30000;
	}
	if ( fc == 0 ) {
		AuxFlapsCmd.setValue(0);
		if ( CurrentMach <= m_slat_cutoff and ! wow ) {
			if ( Alpha > m_slat_lo and Alpha <= m_slat_hi ) {
				MainFlapsCmd.setValue( m_flap_ext );
				SlatsCmd.setValue( ( Alpha - m_slat_lo ) * lms_coef );
			} elsif ( Alpha > m_slat_hi ) {
				MainFlapsCmd.setValue( m_flap_ext );
    				SlatsCmd.setValue( max_m_slat_ext );
			} else {
				MainFlapsCmd.setValue(0);
				SlatsCmd.setValue(0);
			}
		} else {
			MainFlapsCmd.setValue(0);
			SlatsCmd.setValue(0);
    			}
	}
	if ( fc == 1 ) {
  		MainFlapsCmd.setValue(1);
   		AuxFlapsCmd.setValue(1);
   		SlatsCmd.setValue(1);
    }
}
