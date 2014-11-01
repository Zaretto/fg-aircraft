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
var course_demand = props.globals.getNode("instrumentation/nav[1]/radials/selected-deg",1);

# Settings
var target_alt   = props.globals.getNode("autopilot/settings/target-altitude-ft", 1);

var target_pitch  = props.globals.getNode("autopilot/settings/target-pitch-deg", 1);
var target_roll  = props.globals.getNode("autopilot/settings/target-roll-deg", 1);
var target_hdg   = props.globals.getNode("autopilot/settings/heading-bug-deg", 1);

# Locks
var ap_alt_lock  = props.globals.getNode("autopilot/locks/altitude");
var ap_hdg_lock  = props.globals.getNode("autopilot/locks/heading");

if (f14.usingJSBSim)
{
#print("Using JSB Sim AFCS Altitude hold");
#target_alt   = props.globals.getNode("fdm/jsbsim/systems/afcs/target-altitude-ft", 1);
ap_alt_lock  = props.globals.getNode("fdm/jsbsim/systems/afcs/altitude-hold-active",1);
}

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
		if (hdg_gt == -1) {
#            print("HDG: wing lev");
			hdg_gt_switch.setValue(0);
			afcs_heading_disengage();
		} else if (hdg_gt == 1) {
#            print("HDG: gt");
			hdg_gt_switch.setValue(-1);
			afcs_heading_engage();
		} else if (hdg_gt == 0) {
#            print("HDG: hdg");
			hdg_gt_switch.setValue(1);
			afcs_heading_engage();
		} else {
#            print("HDG: wing lev");
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
#        print("Alt disengage");
	} else {
		alt_switch.setBoolValue(1);
		alt_enable.setBoolValue(1);
#        print("Alt engage");
        if (f14.usingJSBSim)
        {
            target_alt.setValue(press_alt_ft.getValue());
setprop("fdm/jsbsim/systems/afcs/altitude-hold-ft",press_alt_ft.getValue());
setprop("fdm/jsbsim/systems/afcs/target-altitude-ft", press_alt_ft.getValue());
#            ap_alt_lock.setValue(1);
        }
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

    if (!f14.usingJSBSim)
	    ap_alt_lock.setValue("pitch-hold");
else
{
target_alt.setValue(press_alt_ft.getValue());
setprop("fdm/jsbsim/systems/afcs/altitude-hold-ft",press_alt_ft.getValue());
setprop("fdm/jsbsim/systems/afcs/target-altitude-ft", target_alt.getValue());
setprop("fdm/jsbsim/systems/afcs/altitude-hold-active",1);
#print("Alt lock engage[1]");
ap_alt_lock.setValue(1);

}

	var rdeg = roll_deg.getValue();
	if ( hdg_gt_switch.getBoolValue()) {	
if (hdg_gt_switch.getValue() > 0)
{
		target_hdg.setValue(course_demand.getValue());
			ap_hdg_lock.setValue("dg-heading-hold");
}
else
{
	target_hdg.setValue(course_demand.getValue());
	ap_hdg_lock.setValue("true-heading-hold");
}
#print("hdg ",ap_hdg_lock.getValue());
	} else {
		if ( rdeg < -60 ) { rdeg = -60 }
		if ( rdeg > 60 ) { rdeg = 60 }
		target_roll.setValue( rdeg );
		ap_hdg_lock.setValue("wing-leveler");
	}
	ap_lock_att = 1;
}



var afcs_heading_engage = func() {

	if ( ! main_ap_engaged.getValue()) {
		settimer(func { afcs_disengage() }, 0.1);
		return;
	}

	var rdeg = roll_deg.getValue();

	if ( hdg_gt_switch.getBoolValue()) {	
if (hdg_gt_switch.getValue() > 0)
{
		target_hdg.setValue(course_demand.getValue());
			ap_hdg_lock.setValue("dg-heading-hold");
}
else
{
	target_hdg.setValue(course_demand.getValue());
	ap_hdg_lock.setValue("true-heading-hold");
}

	} else {
		if ( rdeg < -60 ) { rdeg = -60 }
		if ( rdeg > 60 ) { rdeg = 60 }
		target_roll.setValue( rdeg );
		ap_hdg_lock.setValue("wing-leveler");
	}
}

var afcs_engage_selected_mode = func() {
	# Two steps modes.
	# Altitude, Ground Track, Vec PCD / ACL

#    print ("afcs_engage_Selected_mode");

	if ( main_ap_engaged.getBoolValue()) {
		# This is Altitude step #2
		if (alt_enable.getBoolValue()) {
			target_alt.setValue(press_alt_ft.getValue());
setprop("fdm/jsbsim/systems/afcs/target-altitude-ft", press_alt_ft.getValue());
setprop("fdm/jsbsim/systems/afcs/altitude-hold-ft",press_alt_ft.getValue());
            if (f14.usingJSBSim)
            {
#                print("Alt lock engage");
                ap_alt_lock.setValue(1);
            }
            else
            {
                ap_alt_lock.setValue("altitude-hold");
                alt_enable.setBoolValue(0);
            }
		}
		# Here other selectable modes.
	}
}

afcs_groundtrack_engage = func() {
	if ( ! main_ap_engaged.getBoolValue()) {
		settimer(func { afcs_disengage() }, 0.1);
		return;
	}
    target_hdg.setValue(course_demand.getValue());
	target_hdg.setValue(course_demand.getValue());
	ap_hdg_lock.setValue("true-heading-hold");
#	ap_hdg_lock.setValue("dg-heading-hold");
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
    target_alt.setValue(press_alt_ft.getValue());

    if (f14.usingJSBSim)
    {
#                print("Alt lock disengage");
        ap_alt_lock.setValue(0);
        alt_enable.setBoolValue(0);
        main_ap_engaged.setBoolValue( 0 );
    }
    else
    {
        ap_alt_lock.setValue("pitch-hold");
        alt_enable.setBoolValue(0);
    }
	ap_altlock_pitch = 1;
	alt_enable.setBoolValue(0);
}

var afcs_heading_disengage = func() {
	# returns to attitude autopilot
	hdg_gt_switch.setBoolValue( 0 );
	var rdeg = roll_deg.getValue();

	if ( rdeg < -60 ) 
    { 
        rdeg = -60 ;
    }
	if ( rdeg > 60 ) 
    {
        rdeg = 60 ;
    }

	target_roll.setValue( rdeg );
	ap_hdg_lock.setValue("wing-leveler");
}
if(f14.usingJSBSim)
{

setlistener("autopilot/settings/target-altitude-ft", func {
    var v = getprop("autopilot/settings/target-altitude-ft");
    if (v != nil)
        setprop("fdm/jsbsim/systems/afcs/target-altitude-ft", v);
}, 1, 0);

var current_leg_is_gs = 0;

setlistener("autopilot/route-manager/current-wp", func {
    var leg = getprop("autopilot/route-manager/current-wp");
    if(leg == nil)
        return;
#    print("Current WP changed");
    var roll_mode = getprop("autopilot/locks/heading");
    if(roll_mode == "true-heading-hold" )
    {
        if(getprop("autopilot/route-manager/active"))
        {
#            print("At waypoint ",leg);

#            print("Now adjusting altitude");
            if (leg < getprop("autopilot/route-manager/route/num"))
            {
                var legi = "autopilot/route-manager/route/wp["~leg~"]/";
                var legalt = legi ~ "altitude-ft";
                var legid = getprop(legi ~ "id");

#                print("Alt from ",legalt);
                var demalt = getprop(legalt);
                var groundElev = getprop("position/ground-elev-ft");
                if (demalt > 0)
                {
                    if (demalt > groundElev)
                        setprop("/fdm/jsbsim/systems/afcs/target-altitude-ft",demalt);
                    else
                        setprop("/fdm/jsbsim/systems/afcs/target-altitude-ft",getprop("position/ground-elev-ft") + demalt);
                }
                else
                {
                    if(!current_leg_is_gs)
                    {
                        var cruiseAlt = getprop("autopilot/route-manager/cruise/altitude-ft");
                        if (cruiseAlt != nil and cruiseAlt > groundElev)
                        {
                            print("Using cruise alt ",cruiseAlt, demalt);
                            demalt = cruiseAlt;
                        }
                        else
                            demalt = getprop("/autopilot/settings/target-altitude-ft");

                        setprop("/fdm/jsbsim/systems/afcs/target-altitude-ft",demalt);
                        setprop("/autopilot/settings/target-altitude-ft", demalt);
                    }
                }
#                print(legalt," = ",demalt, ": ",getprop("/fdm/jsbsim/systems/afcs/target-altitude-ft"));
                if(legid != nil)
                {
#                    print("Leg ID ",legid,substr(legid, size(legid)-3,3));
                    if (size(legid) > 4 and substr(legid, size(legid)-3,3) == "-GS")
                    {
                        print("Is GS");
                        current_leg_is_gs = 1;
                    }
                }
                else
                    current_leg_is_gs = 0;
            }
            else
            {
                current_leg_is_gs = 0;
                demalt = getprop("/autopilot/settings/target-altitude-ft");
                if (demalt < groundElev + 200)
                {
                    demalt = demalt + 1000;
                    print(" -- alt lock too low, using ",demalt);
                }
                setprop("fdm/jsbsim/systems/afcs/altitude-hold-ft", demalt);
#                print("staying with althold value ",getprop("fdm/jsbsim/systems/afcs/altitude-hold-ft"));
                current_leg = -1;
            }
        }
        else
            setprop("fdm/jsbsim/systems/afcs/altitude-hold-ft", getprop("autopilot/settings/target-altitude-ft"));

    }
}, 1, 0);


}
