# F-15 HUD Support
# ---------------------------
# The F-15 has a canvas based hud; so this module really only provides 
# turning off of the standard HUD and the develev to devrool function
# ---------------------------
# Richard Harrison (rjh@zaretto.com) Feb  2015 - based on F-14B version by Alexis Bory
# ---------------------------

# This generic func is deactivated cause we don't need it and we have a better
# use for "h" keyboard shortcut.
aircraft.HUD.cycle_color = func {}

var pilot_g_alpha      = props.globals.getNode("sim/rendering/redout/alpha", 1);
var hud_intens_control = props.globals.getNode("sim/model/f15/controls/hud/intens");
var hud_alpha          = props.globals.getNode("sim[0]/hud/color/alpha", 1);
var view               = props.globals.getNode("sim/current-view/name");
var OurRoll            = props.globals.getNode("orientation/roll-deg");

# distance eye <-> to mean point of HUD screen.
var eye_hud_m          = 0.5123;
var hud_position = 5.66824; # really -5.6 but avoiding more complex equations by being optimal with the signs.
var hud_radius_m       = 0.08429;

aircraft.data.add("sim/model/f15/controls/hud/intens", "sim/hud/current-color");

hud_alpha.setDoubleValue(0);



var develev_to_devroll = func(dev_rad, elev_rad) {
	var clamped = 0;

    eye_hud_m = hud_position + getprop("sim/current-view/z-offset-m"); # optimised for signs so we get a positive distance.
	# Deviation length on the HUD (at level flight),
	var h_dev = eye_hud_m / ( math.sin(dev_rad) / math.cos(dev_rad) );
	var v_dev = eye_hud_m / ( math.sin(elev_rad) / math.cos(elev_rad) );
	# Angle between HUD center/top <-> HUD center/symbol position.
	# -90° left, 0° up, 90° right, +/- 180° down. 
	var dev_deg =  math.atan2( h_dev, v_dev ) * R2D;
	# Correction with own a/c roll.
	var combined_dev_deg = dev_deg - OurRoll.getValue();
	# Lenght HUD center <-> symbol pos on the HUD:
	var combined_dev_length = math.sqrt((h_dev*h_dev)+(v_dev*v_dev));

	# clamping
	var abs_combined_dev_deg = math.abs( combined_dev_deg );
	var clamp = hud_radius_m;

    # squeeze the top of the display area for egg shaped HUD limits.
#	if ( abs_combined_dev_deg >= 0 and abs_combined_dev_deg < 90 ) {
#		var coef = ( 90 - abs_combined_dev_deg ) * 0.00075;
#		if ( coef > 0.050 ) { coef = 0.050 }
#		clamp -= coef; 
#	}
	if ( combined_dev_length > clamp ) {
		combined_dev_length = clamp;
		clamped = 1;
	}
	var v = [combined_dev_deg, combined_dev_length, clamped];
	return(v);

}


