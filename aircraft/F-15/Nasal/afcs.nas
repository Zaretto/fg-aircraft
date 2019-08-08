#
# F-15 AFCS (Auto Flight Control System)  interfaces
# ---------------------------
# Connects the autopilot (rewritten by Octal450 (Joshua Davidson) to the autopilot system and the 
# ---------------------------
# Richard Harrison (rjh@zaretto.com) 2017-10-15
#

# Switches
var alt_switch      = props.globals.getNode("sim/model/f15/controls/AFCS/alt-hold",1);
var att_switch      = props.globals.getNode("sim/model/f15/controls/AFCS/att-hold",1);
var main_ap_engaged = props.globals.getNode("sim/model/f15/controls/AFCS/engage");

# State
var alt_enable      = props.globals.getNode("sim/model/f15/controls/AFCS/altitude-enable");
var ap_alt_lock  = props.globals.getNode("autopilot/locks/altitude");
var ap_hdg_lock  = props.globals.getNode("autopilot/locks/heading");
var target_alt   = props.globals.getNode("autopilot/settings/target-altitude-ft", 1);

# inputs
var press_alt_ft = props.globals.getNode("instrumentation/altimeter/pressure-alt-ft");

# keyboard
# ctrl t - autopilot attiude / sim/model/f15/controls/AFCS/att-hold
# ctrl a - altitude / sim/model/f15/controls/AFCS/alt-hold
# ctrl h - heading : aircraft.afcs_heading_switch(0);
# switches : Attitude hold (wing-leveler pitch-hold)
#          : altitude hold (altitude-hold)
# switches 
#  * sim/model/f15/controls/AFCS/alt-hold
#  * sim/model/f15/controls/AFCS/att-hold

# wing-leveler ->  dg-heading-hold -> true-heading-hold
var afcs_heading_switch = func(n) {
    var cv = ap_hdg_lock.getValue();
    if (cv == "")
        return;
    else if (cv == "wing-leveler")
    {
        ap_hdg_lock.setValue("dg-heading-hold");
    }
    else if (cv == "dg-heading-hold")
    {
        ap_hdg_lock.setValue("true-heading-hold");
    }
    else if (cv == "true-heading-hold")
    {
        ap_hdg_lock.setValue("wing-leveler");
    }
}


var afcs_disengage = func()
{
    att_switch.setValue(0);
    alt_switch.setValue(0);
	ap_alt_lock.setValue("");
	ap_hdg_lock.setValue("");
}

setlistener("sim/model/f15/controls/AFCS/att-hold", func(p)
{
    if (p.getValue())
    {
        ap_alt_lock.setValue("pitch-hold");
        ap_hdg_lock.setValue("wing-leveler");
        setprop("sim/model/f15/controls/AFCS/autopilot-disengage",0);
    }
    else {
        afcs_disengage();
        setprop("sim/model/f15/controls/AFCS/autopilot-disengage",1);
    }
});

setlistener("sim/model/f15/controls/AFCS/alt-hold", func(p)
{
    if (ap_alt_lock.getValue() != "")
    {
        if (p.getValue()) {
            ap_alt_lock.setValue("altitude-hold");
            target_alt.setValue(press_alt_ft.getValue());
        } else {
            ap_alt_lock.setValue("pitch-hold");
        }
    }
});

#
# route manager interface for next waypoint handling.
# this is called when the waypoint is changed. 
var current_leg_is_gs = 0;

setlistener("autopilot/route-manager/current-wp", func {
    var leg = getprop("autopilot/route-manager/current-wp");

    if(leg == nil)
        return;

    if(ap_hdg_lock.getValue() == "true-heading-hold" )
    {
        if(getprop("autopilot/route-manager/active"))
        {
            if (leg < getprop("autopilot/route-manager/route/num"))
            {
                var legi = "autopilot/route-manager/route/wp["~leg~"]/";
                var legalt = legi ~ "altitude-ft";
                var legid = getprop(legi ~ "id");

                var demalt = getprop(legalt);
                var groundElev = getprop("position/ground-elev-ft");
                if (demalt > 0)
                {
                    if (demalt > groundElev)
                        setprop("fdm/jsbsim/systems/afcs/target-altitude-ft",demalt);
                    else
                        setprop("fdm/jsbsim/systems/afcs/target-altitude-ft",getprop("position/ground-elev-ft") + demalt);
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
                            demalt = getprop("autopilot/settings/target-altitude-ft");

                        setprop("fdm/jsbsim/systems/afcs/target-altitude-ft",demalt);
                        setprop("autopilot/settings/target-altitude-ft", demalt);
                    }
                }

                if(legid != nil)
                {
                    if (size(legid) > 4 and substr(legid, size(legid)-3,3) == "-GS")
                    {
                        current_leg_is_gs = 1;
                    }
                }
                else
                    current_leg_is_gs = 0;
            }
            else
            {
                current_leg_is_gs = 0;
                demalt = getprop("autopilot/settings/target-altitude-ft");
                if (demalt < groundElev + 200)
                {
                    demalt = demalt + 1000;
                }
                setprop("fdm/jsbsim/systems/afcs/altitude-hold-ft", demalt);
                current_leg = -1;
            }
        }
        else
            setprop("fdm/jsbsim/systems/afcs/altitude-hold-ft", getprop("autopilot/settings/target-altitude-ft"));

    }
}, 1, 0);

# Route Manager advance code
# Joshua Davidson (Octal450)
var max_bank_limit = 30;
setprop("/autopilot/route-manager/advance", 1);

# Every time the waypoint changes, update the stored time
setlistener("/autopilot/route-manager/current-wp", func {
	setprop("/autopilot/internal/wp-change-time", getprop("/sim/time/elapsed-sec"));
});

# Calculates the optimum distance from waypoint to begin turning to next waypoint
var routeManagerUpdate = func {
	if (getprop("/autopilot/route-manager/route/num") > 0 and getprop("/autopilot/route-manager/active") == 1) {
		if ((getprop("/autopilot/route-manager/current-wp") + 1) < getprop("/autopilot/route-manager/route/num")) {
			gnds_mps = getprop("/velocities/groundspeed-kt") * 0.5144444444444;
			wp_fly_from = getprop("/autopilot/route-manager/current-wp");
			if (wp_fly_from < 0) {
				wp_fly_from = 0;
			}
			current_course = getprop("/autopilot/route-manager/route/wp[" ~ wp_fly_from ~ "]/leg-bearing-true-deg");
			wp_fly_to = getprop("/autopilot/route-manager/current-wp") + 1;
			if (wp_fly_to < 0) {
				wp_fly_to = 0;
			}
			next_course = getprop("/autopilot/route-manager/route/wp[" ~ wp_fly_to ~ "]/leg-bearing-true-deg");

			delta_angle = math.abs(geo.normdeg180(current_course - next_course));
			max_bank = delta_angle * 1.5;
			max_bank_limit = getprop("/fdm/jsbsim/autoflight/roll/heading/bank-max");
			if (max_bank > max_bank_limit) {
				max_bank = max_bank_limit;
			}
			radius = (gnds_mps * gnds_mps) / (9.81 * math.tan(max_bank / 57.2957795131));
			time = 0.64 * gnds_mps * delta_angle * 0.7 / (360 * math.tan(max_bank / 57.2957795131));
			delta_angle_rad = (180 - delta_angle) / 114.5915590262;
			R = radius/math.sin(delta_angle_rad);
			dist_coeff = delta_angle * -0.011111 + 2;
			if (dist_coeff < 1) {
				dist_coeff = 1;
			}
			turn_dist = math.cos(delta_angle_rad) * R * dist_coeff / 1852;
			if (getprop("/gear/gear[0]/wow") == 1 and turn_dist < 1) {
				turn_dist = 1;
			}
			setprop("/autopilot/route-manager/advance", turn_dist);
			if (getprop("/sim/time/elapsed-sec")-getprop("/autopilot/internal/wp-change-time") > 60) {
				setprop("/autopilot/internal/wp-change-check-period", time);
			}
			
			if (getprop("/autopilot/route-manager/wp/dist") <= turn_dist) {
				setprop("/autopilot/route-manager/current-wp", getprop("/autopilot/route-manager/current-wp") + 1);
			}
		}
	}
};
