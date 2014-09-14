#----------------------------------------------------------------------------
# Flaps computer     
#----------------------------------------------------------------------------

var m_slat_lo      = 7.7;          # Maneuver slats low alpha threshold.
var m_slat_hi      = 10.5;         # Maneuver slats high alpha threshold.
var m_flap_ext     = 0.286;        # Maneuver flaps extension.
var max_m_slat_ext = 0.41;         # Maximum maneuver slats extension.
var lms_coef       = 0.146428571;  # Linear maneuver slats extension coeff:

# maximum maneuver slats extension / maneuver slats high alpha threshold - maneuver slats low alpha threshold.

var FlapsCmd     = props.globals.getNode("controls/flight/flaps", 1);
var AuxFlapsCmd  = props.globals.getNode("/controls/flight/auxFlaps", 1);
var SlatsCmd     = props.globals.getNode("/fdm/jsbsim/fcs/slat-cmd", 1);
var MainFlapsCmd = props.globals.getNode("controls/flight/mainFlaps", 1);
var demandedFlaps = 0;
setprop("/fdm/jsbsim/fcs/wing-sweep-cmd",0.308823529);

FlapsCmd.setValue(0);
SlatsCmd.setValue(0);
AuxFlapsCmd.setValue(0);
demandedFlags = 0;

var weAppliedSpeedBrake = 99;
var weAppliedWheelBrake = 99;

controls.applyBrakes = func(v, which = 0)  {
    if (wow)
    {
        if (!v and weAppliedSpeedBrake != 99)
        {
            setprop("controls/flight/speedbrake", 0);
            weAppliedSpeedBrake=99;
            print("F14: dual purpose brakes release release airbrake brakes ",v,which);
            return;
        }
        if (which <= 0) { interpolate("/controls/gear/brake-left", v, controls.fullBrakeTime); }
        if (which >= 0) { interpolate("/controls/gear/brake-right", v, controls.fullBrakeTime); }
        weAppliedWheelBrake = which;
        print("F14: wheelbrakes ",v,":",which);
    }
    else
    {
        if (!v and weAppliedWheelBrake != 99)
        {
            if (weAppliedWheelBrake <= 0) { interpolate("/controls/gear/brake-left", 0, controls.fullBrakeTime); }
            if (weAppliedWheelBrake >= 0) { interpolate("/controls/gear/brake-right", 0, controls.fullBrakeTime); }
            weAppliedWheelBrake=99;
            print("F14: dual purpose brakes release release wheel brakes ",v,which);
            return;
        }
        weAppliedSpeedBrake=which;
        print("F14: airbrakes  down ",v,which);
        setprop("controls/flight/speedbrake", v);
    }
}
# Hijack the generic flaps command so everybody's joystick flap command works
# for the F-14 too. 

controls.flapsDown = func(s) {
print("F14: flaps down ",s);
	if (s == 1) {
		lowerFlaps();
	} elsif (s == -1) {
		raiseFlaps();
	} else {
		return;
	}
}

var lowerFlaps = func {
	if (getprop("/fdm/jsbsim/fcs/wing-sweep-cmd") <= 0.308823529) # only flaps with < 21 deg
    {
        print("F14: lower flaps");
		FlapsCmd.setValue(1); # Landing.
        demandedFlaps = 1;
	}
}

var raiseFlaps = func {
print("F14: raise flaps");
		FlapsCmd.setValue(0); # Clean.
        demandedFlaps = 0;
		DLCactive = false;
		DLC_Engaged.setBoolValue(0);
		setprop("controls/flight/DLC", 0);
}

var computeFlaps = func {

	# disable if we are in replay mode
	if ( getprop("sim/replay/time") > 0 ) { return }

	if (CurrentMach == nil) { CurrentMach = 0 } 
	if (CurrentAlt == nil) { CurrentAlt = 0 }
	if (Alpha == nil) { Alpha = 0 }

	var m_slat_cutoff  = 0.85; # Maneuver slats cutoff mach.

	if ( CurrentAlt < 30000.0 ) {
		m_slat_cutoff = 0.5 + CurrentAlt * 0.000011667; # 0.5 + CurrentAlt * 0.35 / 30000;
	}
	if ( demandedFlaps == 0 ) 
    {
        var slats = 0;
        var flaps = 0;
		AuxFlapsCmd.setValue(0);
		
        if ( CurrentMach <= m_slat_cutoff and ! wow and !getprop("controls/gear/gear-down"))
        {
			if ( Alpha > m_slat_lo and Alpha <= m_slat_hi )
            {
                slats =  ( Alpha - m_slat_lo ) * lms_coef ;
                flaps = (slats*0.33);
                if (flaps > 0.33)
                {
                    flaps = 0.33;
                }
			}
            elsif ( Alpha > m_slat_hi )
            {
                slats = max_m_slat_ext;
				SlatsCmd.setValue( max_m_slat_ext );
                flaps = m_flap_ext;
#                flaps = m_flap_ext + max_m_slat_ext;
			}
            else
            {
                slats=0;
				flaps=0;
#               MainFlapsCmd.setValue(0);
#   			FlapsCmd.setValue(0);
#				SlatsCmd.setValue(0);
			}
#            flaps = m_flap_ext;
		}
        else
        {
#            m_flap_ext = 0;
            flaps = 0;
            slats = 0;
		}
  		MainFlapsCmd.setValue( flaps );
    	SlatsCmd.setValue(slats);
		FlapsCmd.setValue(flaps);
#print("Flaps ",m_flap_ext, " slats ",slats," flaps ",flaps);
	}
	else if ( demandedFlaps == 1) {
		MainFlapsCmd.setValue(1);
		AuxFlapsCmd.setValue(1);
		SlatsCmd.setValue(1);
	}
}
