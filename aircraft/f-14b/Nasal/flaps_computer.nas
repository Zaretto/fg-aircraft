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

FlapsCmd.setValue(0);
AuxFlapsCmd.setValue(0);


# Hijack the generic flaps command so everybody's joystick flap command works
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
	if ( WingSweep < 0.05 and FlapsCmd.getValue() < 1 ) {
		FlapsCmd.setValue(1); # Landing.
	}
}

var raiseFlaps = func {
	if ( FlapsCmd.getValue() > 0 ) {
		FlapsCmd.setValue(0); # Clean.
		DLCactive = false;
		DLC_Engaged.setBoolValue(0);
		setprop("controls/flight/DLC", 0);
	}
}


var computeFlaps = func {

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
