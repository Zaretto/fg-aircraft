# AFCS (Auto Flight Control System) Panel
# ---------------------------------------

# Set the Autopilot in Passive Mode so the keyboard "Up, Down, Right, Left" keys
# override the Autopilot instead of changing its settings. 
setprop("autopilot/locks/passive-mode", 1);

# Switches
var alt_switch      = props.globals.getNode("sim/model/f-14b/controls/AFCS/altitude");
var hdg_gt_switch   = props.globals.getNode("sim/model/f-14b/controls/AFCS/heading-gt");
var main_ap_engaged = props.globals.getNode("sim/model/f-14b/controls/AFCS/engage");

# State
var alt_enable      = props.globals.getNode("sim/model/f-14b/controls/AFCS/altitude-enable");
	
# References
var press_alt_ft = props.globals.getNode("instrumentation/altimeter/pressure-alt-ft");
var pitch_deg    = props.globals.getNode("orientation/pitch-deg");
var roll_deg     = props.globals.getNode("orientation/roll-deg");
var hdg_bug     = props.globals.getNode("orientation/heading-magnetic-deg");

# Settings
var target_alt   = props.globals.getNode("autopilot/settings/target-altitude-ft", 1);
var target_pitch  = props.globals.getNode("autopilot/settings/target-pitch-deg", 1);
var target_roll  = props.globals.getNode("autopilot/settings/target-roll-deg", 1);
var target_hdg   = props.globals.getNode("autopilot/settings/heading-bug-deg", 1);

# Locks
var ap_alt_lock  = props.globals.getNode("autopilot/locks/altitude");
var ap_hdg_lock  = props.globals.getNode("autopilot/locks/heading");

# Locks Flag (used by SAS.nas to override Autopilot when Control Stick Steering).
# 0 = off, 1 = enabled, 2 = temporarly overriden  
var ap_lock_att          = 0; 
var ap_altlock_altitude  = 0; 
var ap_hdglock_winglevel = 0; 
var ap_hdglock_truehdg   = 0; 

# SAS
var SASpitch_on = props.globals.getNode("sim/model/f-14b/controls/SAS/pitch");
var SASroll_on  = props.globals.getNode("sim/model/f-14b/controls/SAS/roll");
var SASyaw_on   = props.globals.getNode("sim/model/f-14b/controls/SAS/yaw");


# Switches Commands
# -----------------
var sas_pitch_toggle = func {
	if (SASpitch_on.getValue()) {
		SASpitch_on.setValue(0);
		settimer(func { afcs_disengage() }, 0.2);
	} else {
		SASpitch_on.setValue(1);
	}		
}

var sas_roll_toggle = func {
	if (SASroll_on.getValue()) {
		SASroll_on.setValue(0);
		settimer(func { afcs_disengage() }, 0.2);
	} else {
		SASroll_on.setValue(1);
	}
}

var sas_yaw_toggle = func {
	if (SASyaw_on.getValue()) {
		SASyaw_on.setValue(0);
		settimer(func { afcs_disengage() }, 0.2);
	} else {
		SASyaw_on.setValue(1);
	}
}

var afcs_engage_toggle = func {
	if (! main_ap_engaged.getValue()) afcs_attitude_engage()
	else afcs_disengage();
}


var afcs_heading_switch = func(n) {
	var hdg_gt = hdg_gt_switch.getValue();
	# Hotspot 3 position switch case ( 1 or -1 )
	if (n == 1) {
		if (hdg_gt == -1) {
			hdg_gt_switch.setValue(0);
		} elsif (hdg_gt == 0) {
			hdg_gt_switch.setValue(1);
			afcs_heading_engage();
		}
	} elsif (n == -1) {
		if (hdg_gt == 0) {
			hdg_gt_switch.setValue(-1);
			afcs_groundtrack_engage();
		} elsif (hdg_gt == 1) {
			hdg_gt_switch.setValue(0);
			afcs_heading_disengage();
		}
	} else {
		# keyb Ctrl-h Toggle case ( 0 )
		if (hdg_gt == -1 or hdg_gt == 0) {
			hdg_gt_switch.setValue(1);
			afcs_heading_engage();
		} else {
			hdg_gt_switch.setValue(0);
			afcs_heading_disengage();
		}
	}
}

var afcs_altitude_engage_toggle = func() {
	# Two step mode. This is step #1
	if (alt_switch.getBoolValue()) {
		alt_switch.setBoolValue(0);
		alt_enable.setBoolValue(0);
		afcs_altitude_disengage();
	} else {
		alt_switch.setBoolValue(1);
		alt_enable.setBoolValue(1);
	}
}





# Autopilot Functions
#--------------------
var afcs_attitude_engage = func() {
	main_ap_engaged.setBoolValue( 1 );
	if ( ! SASpitch_on.getValue() or ! SASroll_on.getValue() or ! SASyaw_on.getValue()) {
		settimer(func { afcs_disengage() }, 0.1);
		return;
	}

	var pdeg = pitch_deg.getValue();
	if ( pdeg < -30 ) { pdeg = -30 }
	if ( pdeg > 30 ) { pdeg = 30 }
	target_pitch.setValue(pdeg);
	ap_alt_lock.setValue("pitch-hold");

	var rdeg = roll_deg.getValue();
	if ( hdg_gt_switch.getBoolValue()) {	
		if ( rdeg < 5 and rdeg > -5 ) {
			target_hdg.setValue(hdg_bug.getValue());
			ap_hdg_lock.setValue("dg-heading-hold");
		}
	} else {
		if ( rdeg < -60 ) { rdeg = -60 }
		if ( rdeg > 60 ) { rdeg = 60 }
		target_roll.setValue( rdeg );
		ap_hdg_lock.setValue("wing-leveler");
	}
	ap_lock_att = 1;
}



var afcs_heading_engage = func() {
	hdg_gt_switch.setBoolValue( 1 );
	if ( ! main_ap_engaged.getValue()) {
		settimer(func { afcs_disengage() }, 0.1);
		return;
	}
	var rdeg = roll_deg.getValue();
	if ( rdeg < 5 and rdeg > -5 ) {
		target_hdg.setValue(hdg_bug.getValue());
		ap_hdg_lock.setValue("dg-heading-hold");
	}
}

var afcs_engage_selected_mode = func() {
	# Two steps modes.
	# Altitude, Ground Track, Vec PCD / ACL
	if ( main_ap_engaged.getBoolValue()) {
		# This is Altitude step #2
		if (alt_enable.getBoolValue()) {
			target_alt.setValue(press_alt_ft.getValue());
			ap_alt_lock.setValue("altitude-hold");
			alt_enable.setBoolValue(0);
		}
		# Here other selectable modes.
	}
}

afcs_groundtrack_engage = func() {
	if ( ! main_ap_engaged.getBoolValue()) {
		settimer(func { afcs_disengage() }, 0.1);
		return;
	}
}



var afcs_disengage = func() {
	main_ap_engaged.setBoolValue( 0 );
	alt_switch.setBoolValue( 0 );
	alt_enable.setBoolValue(0);
	hdg_gt_switch.setBoolValue( 0 );
	ap_alt_lock.setValue("");
	ap_lock_att = 0;
	ap_hdg_lock.setValue("");
}

var afcs_altitude_disengage = func() {
	# returns to attitude autopilot
	var pdeg = pitch_deg.getValue();
	if ( pdeg < -30 ) { pdeg = -30 }
	if ( pdeg > 30 ) { pdeg = 30 }
	target_pitch.setValue(pdeg);
	ap_alt_lock.setValue("pitch-hold");
	ap_altlock_pitch = 1;
	alt_enable.setBoolValue(0);
}

var afcs_heading_disengage = func() {
	# returns to attitude autopilot
	hdg_gt_switch.setBoolValue( 0 );
	var rdeg = roll_deg.getValue();
	if ( rdeg < -60 ) { rdeg = -60 }
	if ( rdeg > 60 ) { rdeg = 60 }
	target_roll.setValue( rdeg );
	ap_hdg_lock.setValue("wing-leveler");
}
