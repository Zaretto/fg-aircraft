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
            weAppliedSpeedBrake=0;
            print("F14: dual purpose brakes release release airbrake brakes ",v,which);
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
            weAppliedWheelBrake=0;
            print("F14: dual purpose brakes release release wheel brakes ",v,which);
        }

    	if (v and (throttle_0.getValue() >= 0.98 or throttle_1.getValue() >= 0.98))
        {
            # do not extend speed brakes when throttle at MIL or greater.
            return;
        }
        weAppliedSpeedBrake=which;
        print("F14: airbrakes  down ",v,which);
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
var flapDemandIncrement = 0.1;

var lowerFlaps = func {
    var flaps_cmd = FlapsCmd.getValue();
	if (usingJSBSim)
    {

		if (flaps_cmd < 0.5)
        {
			demandedFlaps = 0.5;
        }
		else if (demandedFlags < 1)
        {
            demandedFlaps = flaps_cmd + flapDemandIncrement;
        }

		if (demandedFlags >= 0.98)
        {
			demandedFlaps = 1.0;
        }

        FlapsCmd.setValue(demandedFlaps);
        setprop("controls/flight/flapscommand", demandedFlaps);
    }
    else
    {
        if (getprop("/fdm/jsbsim/fcs/wing-sweep-cmd") <= 0.3235294117647059) # only flaps with <= 22 deg
        {
            if (flaps_cmd < 0.5)
            {
                demandedFlaps = 0.5;
            }
            else if (demandedFlags < 1) 
            {
                demandedFlaps = flaps_cmd + flapDemandIncrement;
            }

            if (demandedFlags >= 1.0)
            {
                demandedFlaps = 1.0;
            }

            FlapsCmd.setValue(demandedFlaps); # Landing.
        }
    }
    print("F14: lower flaps ",demandedFlaps);
}

var raiseFlaps = func {
    var flaps_cmd = FlapsCmd.getValue();

    if (flaps_cmd > 0.5)
        demandedFlaps = flaps_cmd - flapDemandIncrement;
    else
		demandedFlaps = 0; # Clean.

    FlapsCmd.setValue(demandedFlaps); 
    DLCactive = false;
    DLC_Engaged.setBoolValue(0);

    print("F14: raise flaps ",demandedFlaps);

    if(usingJSBSim)
        setprop("controls/flight/flapscommand", demandedFlaps);

    setprop("controls/flight/DLC", 0);
}

var computeFlaps = func {

    if (usingJSBSim) return;

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
		
        if (!usingJSBSim)
        {
            if (getprop("/fdm/jsbsim/fcs/wing-sweep-cmd") <= 0.3235294117647059 and CurrentMach <= m_slat_cutoff and ! wow and !getprop("controls/gear/gear-down"))
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
#flaps = m_flap_ext + max_m_slat_ext;
    			}
                else
                {
                    slats=0;
    				flaps=0;
#MainFlapsCmd.setValue(0);
#FlapsCmd.setValue(0);
#SlatsCmd.setValue(0);
    			}
#flaps = m_flap_ext;
    		}
            else
            {
#m_flap_ext = 0;
                flaps = 0;
                slats = 0;
    		}
        }
        else
        {
            flaps = 0;
            slats = 0;
  		}
  		MainFlapsCmd.setValue( flaps );
    	SlatsCmd.setValue(slats);
		FlapsCmd.setValue(flaps);
	}
	else 	if ( demandedFlaps >= 0.5 ) 
    {
  		MainFlapsCmd.setValue(1);
   		AuxFlapsCmd.setValue(1);
   		SlatsCmd.setValue(1);
    }
    demandedFlaps=-99;
}
