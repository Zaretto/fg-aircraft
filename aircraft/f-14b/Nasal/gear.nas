# Nose Wheel Steering
# -------------------

var NWScutoffSpeed = 80.0; #knots

var computeNWS = func {
	var NWS_light = 0;
	var NWS = 0.0;
	if ( wow ) {
		var gs = getprop("velocities/groundspeed-kt");
		if (gs == nil) gs = 0.0;
		var rudderInput = getprop("controls/flight/rudder");
		if ( gs < NWScutoffSpeed ) {
			NWS = rudderInput * (NWScutoffSpeed - gs) / NWScutoffSpeed;
			NWS_light = 1;
		}
	}
setprop("controls/flight/NWS", NWS);
setprop("sim/model/f-14b/instrumentation/gears/nose-wheel-steering-warnlight", NWS_light);
}


# GearDown Control
# ----------------
# Hijacked Gear handling so we have a Weight on Wheel security to prevent
# undercarriage retraction when on ground.

controls.gearDown = func(v) {
    if (v < 0 and ! wow) {
      setprop("/controls/gear/gear-down", 0);
    } elsif (v > 0) {
      setprop("/controls/gear/gear-down", 1);
    }
}


# Landing gear handle animation 
# -----------------------------

setlistener( "controls/gear/gear-down", func { ldg_hdl_main(); } );
var ld_hdl = props.globals.getNode("sim/model/f-14b/controls/gear/ld-gear-handle-anim", 1);

var ldg_hdl_main = func {
	var pos = ld_hdl.getValue();
	if ( getprop("controls/gear/gear-down") == 1 ) {
		if ( pos > -1 ) {
			ldg_hdl_anim(-1, pos);
		}
	} elsif ( pos < 0 ) {
		ldg_hdl_anim(1, pos);
	}
}

var ldg_hdl_anim = func {
	var incr = arg[0]/10;
	var pos = arg[1] + incr;
	if ( ( arg[0] = 1 ) and ( pos >= 0 ) ) {    
		ld_hdl.setDoubleValue(0);
	} elsif ( ( arg[0] = -1 ) and ( pos <= -1 ) ) {
		ld_hdl.setDoubleValue(-1);
	} else {
		ld_hdl.setDoubleValue(pos);
		settimer( ldg_hdl_main, 0.05 );
	}
}

# Launch bar animation 
# -----------------------------
var listen_launchbar = nil;
var launchbarpos = nil;
listen_launchbar = setlistener( "gear/launchbar/state", func { settimer(update_launchbar, 0.1) },0 ,0 );

var update_launchbar = func() {
	launchbarpos = getprop("gear/launchbar/position-norm");
	if ( getprop("gear/launchbar/position-norm") == 1) {
		if ( ! getprop ("/gear/gear[0]/wow") ) {
			removelistener( listen_launchbar );
			setprop("controls/gear/launchbar", "true");
			settimer(reset_launchbar_listener, 1);
		} else {
			settimer(update_launchbar, 0.1);
		}
	}
}

var reset_launchbar_listener = func() {
	setprop("controls/gear/launchbar", "false");
	listen_launchbar = setlistener( "gear/launchbar/state", func { settimer(update_launchbar, 0.05) },0 ,0 );
}
