# F-15 General Instrumentation related methods
# ---------------------------
# This module is responsible for instrumentation updates; managing the init process (i.e. reposition) has special logic
# for carrier takeoff (the F-15 can't do this in real life; but carriers are still fun so I'm leaving carrier support in the F-15)
# ---------------------------
# Richard Harrison (rjh@zaretto.com) Feb  2015 - based on F-14B version by Alexis Bory
# ---------------------------

var UPDATE_PERIOD = 0.05;
var main_loop_launched = 0; # Used to avoid to start the main loop twice.


# TACAN: nav[1]
var nav1_as_selected = getprop( "instrumentation/nav[1]/frequencies/selected-mhz" );; # the selected frequency if overriden from the tacan

var Tc               = props.globals.getNode("instrumentation/tacan");
var Vtc              = props.globals.getNode("instrumentation/nav[1]");
var Hsd              = props.globals.getNode("sim/model/f15/instrumentation/hsd", 1);
var TcFreqs          = Tc.getNode("frequencies");
var TcTrueHdg        = Tc.getNode("indicated-bearing-true-deg");
var TcMagHdg         = Tc.getNode("indicated-mag-bearing-deg", 1);
var TcIdent          = Tc.getNode("ident");
var TcServ           = Tc.getNode("serviceable");
var TcXY             = Tc.getNode("frequencies/selected-channel[4]");
var VtcIdent         = Vtc.getNode("nav-id");
var VtcFromFlag      = Vtc.getNode("from-flag");
var VtcToFlag        = Vtc.getNode("to-flag");
var VtcHdgDeflection = Vtc.getNode("heading-needle-deflection");
var VtcRadialDeg     = Vtc.getNode("radials/selected-deg");
var HsdFromFlag      = Hsd.getNode("from-flag", 1);
var HsdToFlag        = Hsd.getNode("to-flag", 1);
var HsdCdiDeflection = Hsd.getNode("needle-deflection", 1);
var TcXYSwitch       = props.globals.getNode("sim/model/f15/instrumentation/tacan/xy-switch", 1);
var TcModeSwitch     = props.globals.getNode("sim/model/f15/instrumentation/tacan/mode", 1);
var TrueHdg          = props.globals.getNode("orientation/heading-deg");
var MagHdg           = props.globals.getNode("orientation/heading-magnetic-deg");
var MagDev           = props.globals.getNode("orientation/local-mag-dev", 1);

var mag_dev = 0;
var tc_mode = 0;
var carrier_pos_first_time = 1;
var carrier_x_offset = 0;
var carrier_y_offset = 0;
var carrier_z_offset = 0;

aircraft.data.add(VtcRadialDeg, TcModeSwitch);


# Compute local magnetic deviation.
var local_mag_deviation = func {
	var true = TrueHdg.getValue();
	var mag = MagHdg.getValue();
	mag_dev = geo.normdeg( mag - true );
	if ( mag_dev > 180 ) mag_dev -= 360;
	MagDev.setValue(mag_dev); 
}


# Set nav[1] so we can use radials from a TACAN station.

var nav1_freq_update = func {
	if ( tc_mode != 0 and tc_mode != 4 ) {
		var tacan_freq = getprop( "instrumentation/tacan/frequencies/selected-mhz" );
        nav1_as_selected = getprop( "instrumentation/nav[1]/frequencies/selected-mhz" );
		setprop("instrumentation/nav[1]/frequencies/selected-mhz", tacan_freq);
	} else {
		setprop("instrumentation/nav[1]/frequencies/selected-mhz", nav1_as_selected);
	}
}
var FD_TAN3DEG = math.tan(3.0 / 57.29577950560105);

#
# ARA 63 (Military ILS type of system). This is a bit hardwired to
# work with the tuned carrier based on the TACAN channel which isn't
# right - but it is good enough.
var ara_63_update = func {
    if (carrier_ara_63_position != nil and carrier_ara_63_heading != nil)
    {
        var our_pos = geo.aircraft_position();
        range = our_pos.distance_to(carrier_ara_63_position);
        var bearing_to = our_pos.course_to(carrier_ara_63_position);
        var deviation = bearing_to - carrier_ara_63_heading;
        deviation = deviation *0.1;

        if(getprop("/instrumentation/nav/gs-in-range") and getprop("instrumentation/nav/gs-distance") < range)
        {
# Use the standard civilian ILS as it is closer.
            setprop("sim/model/f15/instrumentation/nav/gs-in-range", getprop("instrumentation/nav/gs-in-range"));
            setprop("sim/model/f15/instrumentation/nav/gs-distance", getprop("instrumentation/nav/gs-distance"));
            setprop("sim/model/f15/instrumentation/nav/gs-needle-deflection-norm",getprop("instrumentation/nav/gs-needle-deflection-norm"));
            setprop("sim/model/f15/instrumentation/nav/heading-needle-deflection-norm",getprop("instrumentation/nav/heading-needle-deflection-norm"));
            setprop("sim/model/f15/instrumentation/nav/signal-quality-norm",getprop("instrumentation/nav/signal-quality-norm"));
            setprop("sim/model/f15/lights/acl-ready-light", 0);
            setprop("sim/model/f15/lights/ap-cplr-light",0);
            setprop("sim/model/f15/lights/light-wave-off",0);
            setprop("sim/model/f15/lights/light-10-seconds",0);
            setprop("sim/model/f15/lights/landing-chk-light", 0);
            return;
        }
        else if (range < 37000 and abs(deviation) < 3) # 20nm range F14-AAD-1 17.3.2
        {
            var deck_height=20; # the height of the MRC is included in the offset of the position + 2.93218; # 20 meters + height from MRC.

            var gs_height = ((range*FD_TAN3DEG)) + deck_height;
            var gs_deviation = (gs_height - our_pos.alt()) / 42.0; 

            if (gs_deviation > 1) gs_deviation = 1;
            else if (gs_deviation < -1) gs_deviation = -1;

            setprop("sim/model/f15/instrumentation/nav/gs-in-range", 1);
            setprop("sim/model/f15/instrumentation/nav/gs-needle-deflection-norm",gs_deviation);
# VOR_FULL_ARC = 20.0
# 17.3.2 localizer width 6 deg
# factor = 3.33
            setprop("sim/model/f15/instrumentation/nav/heading-needle-deflection-norm",deviation);
            setprop("sim/model/f15/instrumentation/nav/signal-quality-norm",1);
            setprop("sim/model/f15/instrumentation/nav/gs-distance", range);

            var u_fps = getprop("/velocities/uBody-fps");
            var eta = range / (u_fps / 3.281);

#            print (" range ",range," bearing to ",deviation," eta ",eta," gsheight ", gs_height, "gsdev ",gs_deviation);

            if(eta <= 10 and range < 800 and range > 150)
            {
                setprop("sim/model/f15/lights/light-10-seconds",1);
                if(math.abs(deviation) > 0.2 or math.abs(gs_deviation) > 0.2)
                {
                    setprop("sim/model/f15/lights/light-wave-off",1);
                }
                else
                {
                    setprop("sim/model/f15/lights/light-wave-off",0);
                }

            }
            else
            {
                setprop("sim/model/f15/lights/light-10-seconds",0);
                setprop("sim/model/f15/lights/light-wave-off",0);
            }
            # Set these lights on when in range and within altitude.
            # the lights come on but it is unspecified when they go off.
            # Ref: F-14AAD-1 Figure 17-4, p17-11 (pdf p685)
            if (range < 11000) 
            {
                if (our_pos.alt() > 300 and our_pos.alt() < 425 and abs(deviation) < 1 )
                {
                    setprop("sim/model/f15/lights/acl-ready-light", 1);
                    setprop("sim/model/f15/lights/ap-cplr-light",1);
                }
                if (range > 8000)  # extinguish at roughly 4.5nm from fix.
                {
                    setprop("sim/model/f15/lights/landing-chk-light", 1);
                }
                else
                {
                    setprop("sim/model/f15/lights/landing-chk-light", 0);
                }
            }
            else
            {
                setprop("sim/model/f15/lights/landing-chk-light", 0);
                setprop("sim/model/f15/lights/acl-ready-light", 0);
                setprop("sim/model/f15/lights/ap-cplr-light",0);
                setprop("sim/model/f15/lights/light-10-seconds",0);
                setprop("sim/model/f15/lights/light-wave-off",0);
            }
        }
        else
        {
            setprop("sim/model/f15/lights/landing-chk-light", 0);
            setprop("sim/model/f15/lights/light-10-seconds",0);
            setprop("sim/model/f15/lights/light-wave-off",0);
            setprop("sim/model/f15/lights/acl-ready-light", 0);
            setprop("sim/model/f15/lights/ap-cplr-light",0);

# Use the standard civilian ILS as no carrier tuned.
            setprop("sim/model/f15/instrumentation/nav/gs-in-range", getprop("instrumentation/nav/gs-in-range"));
            setprop("sim/model/f15/instrumentation/nav/gs-distance", getprop("instrumentation/nav/gs-distance"));
            setprop("sim/model/f15/instrumentation/nav/gs-needle-deflection-norm",getprop("instrumentation/nav/gs-needle-deflection-norm"));
            setprop("sim/model/f15/instrumentation/nav/heading-needle-deflection-norm",getprop("instrumentation/nav/heading-needle-deflection-norm"));
            setprop("sim/model/f15/instrumentation/nav/signal-quality-norm",getprop("instrumentation/nav/signal-quality-norm"));

        }
        return;
    }
#
# Use the standard civilian ILS
if (getprop("instrumentation/nav/gs-in-range") != nil)
{
    setprop("sim/model/f15/instrumentation/nav/gs-in-range", getprop("instrumentation/nav/gs-in-range"));
    setprop("sim/model/f15/instrumentation/nav/gs-needle-deflection-norm",getprop("instrumentation/nav/gs-needle-deflection-norm"));
    setprop("sim/model/f15/instrumentation/nav/gs-distance", getprop("instrumentation/nav/gs-distance"));
    setprop("sim/model/f15/instrumentation/nav/heading-needle-deflection-norm",getprop("instrumentation/nav/heading-needle-deflection-norm"));
    setprop("sim/model/f15/instrumentation/nav/signal-quality-norm",getprop("instrumentation/nav/signal-quality-norm"));
}
    setprop("sim/model/f15/lights/acl-ready-light", 0);
    setprop("sim/model/f15/lights/ap-cplr-light",0);
}

var tacan_update = func {
	var tc_mode = TcModeSwitch.getValue();
	if ( tc_mode != 0 and tc_mode != 4 ) {

		# Get magnetic tacan bearing.
		var true_bearing = TcTrueHdg.getValue();
		var mag_bearing = geo.normdeg( true_bearing + mag_dev );
		if ( true_bearing != 0 ) {
			TcMagHdg.setDoubleValue( mag_bearing );
		} else {
			TcMagHdg.setDoubleValue(0);
		}

		# Get TACAN radials on HSD's Course Deviation Indicator.
		# CDI works with ils OR tacan OR vortac (which freq is tuned from the tacan panel).
		var tcnid = TcIdent.getValue();
		var vtcid = VtcIdent.getValue();
		if ( tcnid == vtcid ) {
			# We have a VORTAC.
			HsdFromFlag.setBoolValue(VtcFromFlag.getBoolValue());
			HsdToFlag.setBoolValue(VtcToFlag.getBoolValue());
			HsdCdiDeflection.setValue(VtcHdgDeflection.getValue());
		} else {
			# We have a legacy TACAN.
			var tcn_toflag = 1;
			var tcn_fromflag = 0;
			var tcn_bearing = TcMagHdg.getValue();
			var radial = VtcRadialDeg.getValue();
			var d = tcn_bearing - radial;
			if ( d > 180 ) { d -= 360 } elsif ( d < -180 ) { d += 360 }
			if ( d > 90 ) {
				d -= 180;
				tcn_toflag = 0;
				tcn_fromflag = 1;
			} elsif ( d < - 90 ) {
				d += 180;
				tcn_toflag = 0;
				tcn_fromflag = 1;
			}
			if ( d > 10 ) d = 10 ;
			if ( d < -10 ) d = -10 ;
			HsdFromFlag.setBoolValue(tcn_fromflag);
			HsdToFlag.setBoolValue(tcn_toflag);
			HsdCdiDeflection.setValue(d);
		}
	} else {
		TcMagHdg.setDoubleValue(0);
	}
}


# TACAN mode switch
var set_tacan_mode = func(s) {
	var m = TcModeSwitch.getValue();
	if ( s == 1 and m < 5 ) {
		m += 1;
	} elsif ( s == -1 and m > 0 ) {
		m -= 1;
	}
	TcModeSwitch.setValue(m);
	if ( m == 0 or m == 5 ) {
		TcServ.setBoolValue(0);
	} else {
		TcServ.setBoolValue(1);
	}
}


# TACAN XY switch
var tacan_switch_init = func {
	if (TcXY.getValue() == "X") { TcXYSwitch.setValue( 0 ) } else { TcXYSwitch.setValue( 1 ) }
}

var tacan_XYtoggle = func {
	if ( TcXY.getValue() == "X" ) {
		TcXY.setValue( "Y" );
		TcXYSwitch.setValue( 1 );
	} else {
		TcXY.setValue( "X" );
		TcXYSwitch.setValue( 0 );
	}
}

# One key bindings for RIO's ecm display mode or Pilot's hsd depending on the current view name
var mode_ecm_nav = props.globals.getNode("sim/model/f15/controls/rio-ecm-display/mode-ecm-nav");
var hsd_mode_nav = props.globals.getNode("sim/model/f15/controls/pilots-displays/hsd-mode-nav");
var select_key_ecm_nav = func {
	var v = getprop("sim/current-view/name");
	if (v == "RIO View") {
		mode_ecm_nav.setBoolValue( ! mode_ecm_nav.getBoolValue());
	} elsif (v == "Cockpit View") {
		var h = hsd_mode_nav.getValue() + 1;
		if ( h == 2 ) { h = -1 }
		hsd_mode_nav.setValue( h )
	}
}

# Save fuel state ###############
var bingo      = props.globals.getNode("sim/model/f15/controls/fuel/bingo", 1);

aircraft.data.add(	
    "sim/model/f15/controls/fuel/bingo",
    "consumables/fuel/tank[0]/level-lbs",
    "consumables/fuel/tank[1]/level-lbs",
    "consumables/fuel/tank[2]/level-lbs",
    "consumables/fuel/tank[3]/level-lbs",
    "consumables/fuel/tank[4]/level-lbs",
    "consumables/fuel/tank[5]/level-lbs",
    "consumables/fuel/tank[6]/level-lbs",
    "consumables/fuel/tank[7]/level-lbs",
    "consumables/fuel/tank[8]/level-lbs",
    "consumables/fuel/tank[9]/level-lbs",
    "consumables/fuel/tank[0]/level-gal_us",
    "consumables/fuel/tank[1]/level-gal_us",
    "consumables/fuel/tank[2]/level-gal_us",
    "consumables/fuel/tank[3]/level-gal_us",
    "consumables/fuel/tank[4]/level-gal_us",
    "consumables/fuel/tank[5]/level-gal_us",
    "consumables/fuel/tank[6]/level-gal_us",
    "consumables/fuel/tank[7]/level-gal_us",
    "consumables/fuel/tank[8]/level-gal_us",
    "consumables/fuel/tank[9]/level-gal_us",

    "consumables/fuel/tank[5]/selected",
    "consumables/fuel/tank[6]/selected",
    "consumables/fuel/tank[7]/selected",

    "/payload/weight[0]/selected",
    "/payload/weight[1]/selected",
    "/payload/weight[2]/selected",
    "/payload/weight[3]/selected",
    "/payload/weight[4]/selected",
    "/payload/weight[5]/selected",
    "/payload/weight[6]/selected",
    "/payload/weight[7]/selected",
    "/payload/weight[8]/selected",
    "/payload/weight[9]/selected",
    "/payload/weight[10]/selected",
    "sim/model/f15/systems/external-loads/external-load-set",
    "instrumentation/transponder/inputs/digit[0]", 
    "instrumentation/transponder/inputs/digit[1]", 
    "instrumentation/transponder/inputs/digit[2]", 
    "instrumentation/transponder/inputs/digit[3]",
    "sim/model/hide-pilot",
    "sim/model/hide-backseater",
    "sim/model/hide-pilots-auto"
    );

var g_max   = props.globals.getNode("sim/model/f15/instrumentation/g-meter/g-max", 1);
var g_min   = props.globals.getNode("sim/model/f15/instrumentation/g-meter/g-min", 1);
aircraft.data.add( g_min, g_max );
var GMaxMav = props.globals.getNode("sim/model/f15/instrumentation/g-meter/g-max-mooving-average", 1);
GMaxMav.initNode(nil, 0);
var g_mva_vec     = [0,0,0,0,0];

var g_min_max = func {
	# Records g min, g max and 0.5 sec averaged max values. g_min_max(). Has to be
	# fired every 0.1 sec.
	var curr = currentG;
	var max = g_max.getValue();
	var min = g_min.getValue();
	if ( curr >= max ) {
		g_max.setDoubleValue(curr);
	} elsif ( curr <= min ) {
		g_min.setDoubleValue(curr);
	}
	var g_max_mav = (g_mva_vec[0]+g_mva_vec[1]+g_mva_vec[2]+g_mva_vec[3]+g_mva_vec[4])/5;
	pop(g_mva_vec);
	g_mva_vec = [curr] ~ g_mva_vec;
	GMaxMav.setValue(g_max_mav);
}

# VSD #####################
var ticker = props.globals.getNode("sim/model/f15/instrumentation/ticker", 1);
aircraft.data.add("sim/model/f15/controls/VSD/brightness",
	"sim/model/f15/controls/VSD/contrast",
                  "sim/model/f15/controls/VSD/on-off",
                  "controls/lighting/anti-collision-switch",
                  "controls/lighting/aux-inst",
                  "controls/lighting/aux-instr-console",
                  "controls/lighting/beacon",
                  "controls/lighting/dome-norm",
                  "controls/lighting/eng-inst",
                  "controls/lighting/flt-inst",
                  "controls/lighting/hook-bypass",
                  "controls/lighting/index-norm",
                  "controls/lighting/instruments-norm",
                  "controls/lighting/l-console",
                  "controls/lighting/r-console",
                  "controls/lighting/l-console-eff-norm",
                  "controls/lighting/r-console-eff-norm",
                  "controls/lighting/landing-lights",
                  "controls/lighting/logo-lights",
                  "controls/lighting/nav-lights",
                  "controls/lighting/panel-norm",
                  "controls/lighting/position-flash-switch",
                  "controls/lighting/position-tail-switch",
                  "controls/lighting/position-wing-switch",
                  "controls/lighting/standby-inst",
                  "controls/lighting/stby-inst",
                  "controls/lighting/strobe",
                  "controls/lighting/taxi-light",
                  "controls/lighting/turn-off-lights",
                  "controls/lighting/warn-caution",
                  "sim/model/f15/lights/radio2-brightness",
                  "sim/multiplay/generic/int[1]", # lighting external see f15-common.xml for details
                  "sim/multiplay/generic/int[3]",
                  "sim/multiplay/generic/int[4]",
                  "sim/multiplay/generic/int[5]",
                  "sim/multiplay/generic/int[6]",
                  "sim/hud/visibility[0]",
                  "sim/hud/visibility[1]",
                  "sim/model/f15/controls/fuel/display-selector",
                  "sim/model/f15/controls/hud/on-off",
                  "sim/model/f15/controls/HSD/on-off",
                  "sim/model/f15/instrumentation/hud/mode-aa",
                  "sim/model/f15/instrumentation/hud/mode-ag",
                  "sim/model/f15/instrumentation/hud/mode-to",
                  "sim/model/f15/instrumentation/hud/mode-ldg",
                  "instrumentation/nav[0]/frequencies/selected-mhz",
                  "sim/model/f15/instrumentation/ils/volume-norm",
                  "sim/model/instrumentation/vhf/mode",
                  "fdm/jsbsim/fcs/pitch-damper-enable",
                  "fdm/jsbsim/fcs/roll-damper-enable",
                  "fdm/jsbsim/fcs/yaw-damper-enable",
                  "sim/model/f15/controls/MPCD/mode",
                  "sim/model/f15/controls/windshield-heat",
                  "controls/pilots-displays/hsd-mode-nav");


# Air Speed Indicator #####
aircraft.data.add("sim/model/f15/instrumentation/airspeed-indicator/safe-speed-limit-bug");

# Radar Altimeter #########
aircraft.data.add("sim/model/f15/instrumentation/radar-altimeter/limit-bug");

# Lighting ################
aircraft.data.add(
	"sim/model/f15/controls/lighting/hook-bypass",
	"controls/lighting/instruments-norm",
	"controls/lighting/panel-norm",
	"sim/model/f15/controls/lighting/anti-collision-switch",
	"sim/model/f15/controls/lighting/position-flash-switch",
	"sim/model/f15/controls/lighting/position-wing-switch");

# HSD #####################
var hsd_mode_node = props.globals.getNode("sim/model/f15/controls/pilots-displays/hsd-mode-nav");


# Afterburners FX counter #
var burner = 0;
var BurnerN = props.globals.getNode("sim/model/f15/fx/burner", 1);
BurnerN.setValue(burner);


# AFCS ####################

# Commons vars:
var Mach = props.globals.getNode("velocities/mach");
var mach = 0;

# Filters
var PitchPidPGain = props.globals.getNode("sim/model/f15/systems/afcs/pitch-pid-pgain", 1);
var PitchPidDGain = props.globals.getNode("sim/model/f15/systems/afcs/pitch-pid-dgain", 1);
var VsPidPGain    = props.globals.getNode("sim/model/f15/systems/afcs/vs-pid-pgain", 1);
var pgain = 0;

var afcs_filters = func {
	var f_mach = mach + 0.01;
	var p_gain = -0.008 / ( f_mach * f_mach * f_mach * f_mach * 1.2);
	if ( p_gain < -0.04 ) p_gain = -0.04;
	var d_gain = 0.4 * ( 2.5 - ( mach * 2 ));
	PitchPidPGain.setValue(p_gain);
	PitchPidDGain.setValue(d_gain);
	VsPidPGain.setValue(p_gain/10);
}


# Drag Computation
var Drag       = props.globals.getNode("sim/model/f15/systems/fdm/drag", 1);
var GearPos    = props.globals.getNode("gear/gear[1]/position-norm", 1);
var SpeedBrake = props.globals.getNode("controls/flight/speedbrake", 1);
var AB         = props.globals.getNode("engines/engine/afterburner", 1);

var sb_i = 0.2;
var alt_drag_factor = 25000;
var alt_drag_factor2 = 20000;

controls.stepSpoilers = func(s) {


        var curval = getprop("controls/flight/speedbrake");

        if (s < 0 and curval > 0)
            setprop("controls/flight/speedbrake", curval+s/5);
        else if (s > 0 and curval < 1)
            setprop("controls/flight/speedbrake", curval+s/5);

        return; 
}


# Send basic instruments data over MP for backseaters.
var InstrString = props.globals.getNode("sim/multiplay/generic/string[1]", 1);
var InstrString2 = props.globals.getNode("sim/multiplay/generic/string[2]", 1);
var IAS = props.globals.getNode("instrumentation/airspeed-indicator/indicated-speed-kt", 1);
var FuelTotal = props.globals.getNode("sim/model/f15/instrumentation/fuel-gauges/total", 1);
var TcBearing = props.globals.getNode("instrumentation/tacan/indicated-mag-bearing-deg", 1);
var TcInRange = props.globals.getNode("instrumentation/tacan/in-range", 1);
var TcRange = props.globals.getNode("instrumentation/tacan/indicated-distance-nm", 1);
var RangeRadar2       = props.globals.getNode("instrumentation/radar/radar2-range", 1);

var SteerModeAwl = props.globals.getNode("sim/model/f15/controls/pilots-displays/steer/awl-bt", 1);
var SteerModeDest = props.globals.getNode("sim/model/f15/controls/pilots-displays/steer/dest-bt", 1);
var SteerModeMan = props.globals.getNode("sim/model/f15/controls/pilots-displays/steer/man-bt", 1);
var SteerModeTcn = props.globals.getNode("sim/model/f15/controls/pilots-displays/steer/tacan-bt", 1);
var SteerModeVec = props.globals.getNode("sim/model/f15/controls/pilots-displays/steer/vec-bt", 1);
var SteerModeCode = props.globals.getNode("sim/model/f15/controls/pilots-displays/steer-submode-code", 1);

instruments_data_export = func {
	# Air Speed indicator.
	var ias            = sprintf( "%01.1f", IAS.getValue());
	# Mach
	var s_mach         = sprintf( "%01.1f", mach);
	# Fuel Totalizer.
	var fuel_total     = sprintf( "%01.0f", FuelTotal.getValue());
	# BDHI.
	var tc_mode        = TcModeSwitch.getValue();
	if ( TcBearing.getValue() != nil ) {
		var tc_bearing  = sprintf( "%01.1f", TcBearing.getValue());
	} else {
		var tc_bearing  = "0.00";
	}
	var tc_in_range    = TcInRange.getValue() ? 1 : 0;
	var tc_range       = sprintf( "%01.1f", TcRange.getValue());
	# Steer Submode Code
	steer_mode_code = SteerModeCode.getValue();
	# CDI
	var cdi = sprintf( "%01.2f", HsdCdiDeflection.getValue());
	var radial = VtcRadialDeg.getValue();
var powered="0";
    if ( getprop("/fdm/jsbsim/systems/electrics/ac-essential-bus1") > 0)
        powered="1";
	var l_s = [ias, s_mach, fuel_total, tc_mode, tc_bearing, tc_in_range, tc_range, steer_mode_code, cdi, radial, powered,
sprintf("%d",getprop("engines/engine[0]/egt-degC")),
sprintf("%d",getprop("engines/engine[1]/egt-degC")),
sprintf("%d",getprop("engines/engine[0]/fuel-flow_pph")),
sprintf("%d",getprop("engines/engine[1]/fuel-flow_pph")),
sprintf("%d",getprop("consumables/fuel/total-fuel-lbs")),
];
	var str = "";
	foreach( s ; l_s ) {
		str = str ~ s ~ ";";
	}
	InstrString.setValue(str);

	#InstrString2.setValue(sprintf( "%01.0f", RangeRadar2.getValue()));

}


# Main loop ###############
var cnt = 0;
var ArmSysRunning = props.globals.getNode("sim/model/f15/systems/armament/system-running", 1);

var main_loop = func {
	cnt += 1;
	# done each 0.05 sec.
	mach = Mach.getValue();
	awg_9.rdr_loop();
	var a = cnt / 2;

	burner +=1;
	if ( burner == 3 ) { burner = 0 }
	BurnerN.setValue(burner);

	if ( getprop("sim/replay/time") > 0 ) 
        setprop ("/orientation/alpha-indicated-deg", (getprop("/orientation/alpha-deg") - 0.797) / 0.8122);
    else
    	setprop ("/orientation/alpha-indicated-deg", getprop("fdm/jsbsim/aero/alpha-indicated-deg"));

	if ( ( a ) == int( a )) {
		# done each 0.1 sec, cnt even.
		tacan_update();
        ara_63_update();
		g_min_max();
		f15_chronograph.update_chrono();

		if (( cnt == 6 ) or ( cnt == 12 )) {
			# done each 0.3 sec.
			fuel_update();
			if ( cnt == 12 ) {
				# done each 0.6 sec.
				local_mag_deviation();
				nav1_freq_update();
				cnt = 0;
			}
		}
	} else {
		# done each 0.1 sec, cnt odd.
		awg_9.hud_nearest_tgt();
		instruments_data_export();
		if ( ArmSysRunning.getBoolValue() ) {
			armament_update();
		}
		if (( cnt == 5 ) or ( cnt == 11 )) {
			# done each 0.3 sec.
			afcs_filters();
		}
	}
	settimer(main_loop, UPDATE_PERIOD);
}

var common_carrier_init = func {

    if (carrier_ara_63_position != nil and geo.aircraft_position() != nil)
    {
        if (geo.aircraft_position().distance_to(carrier_ara_63_position) < 6000 and geo.aircraft_position().distance_to(carrier_ara_63_position) > 400)
        {
            print("Starting with hook down as near carrier");
            setprop("controls/gear/tailhook",1);
            setprop("fdm/jsbsim/systems/hook/tailhook-cmd-norm",1);
        }

    }

    if (!getprop("sim/model/f15/overrides/special-carrier-handling"))
        return ;

    var lat = getprop("/position/latitude-deg");
    var lon = getprop("/position/longitude-deg");
    var info = geodinfo(lat, lon);

    var carrier = getprop("/sim/presets/carrier");
    var on_carrier = 0;

    if (carrier != nil or carrier != "")
        on_carrier = 1;

    if (info == nil or info[1] == nil)
    {
# seems to be that we could be on a carrier
        on_carrier = 1;
    }

    if(on_carrier)
    {
        var ground_elevation = getprop("/position/ground-elev-ft");
        if (ground_elevation == nil)
            ground_elevation = 65.2;

        if (carrier != nil and carrier != "" ) # and substr(getprop("/sim/presets/parkpos"),0,4) == "cat-")
        {
            if (carrier_ara_63_position == nil or geo.aircraft_position().distance_to(carrier_ara_63_position) < 200)
            {
                print("Special init for Carrier cat launch");
                setprop("/fdm/jsbsim/systems/systems/holdback/holdback-cmd",1);
                setprop("gear/launchbar/position-norm",1);
            }

            var current_pos = geo.Coord.new().set_latlon(getprop("/position/latitude-deg"), getprop("/position/longitude-deg"));

#
# Locate the carrier in case it has moved from the stated initial position.

            var raw_list = props.globals.getNode("ai/models").getChildren();
            var carrier_located = 0;

            foreach( var c; raw_list )
            {
                if (!c.getNode("valid", 1).getValue()) {
                    continue;
                }
                if(c.getName() == "carrier")
                {
                    var name=c.getNode("name").getValue();
                    if (name == carrier)
                    {
                        print("Found our carrier ", c.getNode("position/latitude-deg").getValue()," ", c.getNode("position/longitude-deg").getValue());
                        var carrier_pos = geo.Coord.new().set_latlon( c.getNode("position/latitude-deg").getValue(), c.getNode("position/longitude-deg").getValue());


                        if (carrier_pos_first_time)
                        {
                            # record the offset between the carrier and the preset position; as when
                            # the carrier moves this will be need to place the aircraft correctly.
                            carrier_pos_first_time = 0;
                            carrier_x_offset = carrier_pos.x() - current_pos.x();
                            carrier_y_offset = carrier_pos.y() - current_pos.y();
                            carrier_z_offset = carrier_pos.z() - current_pos.z();
                            print("Offset to launch ",carrier_x_offset," ",carrier_y_offset," ",carrier_y_offset);                        }
                        else
                        {
                            carrier_pos.set_x(carrier_pos.x()-carrier_x_offset);
                            carrier_pos.set_y(carrier_pos.y()-carrier_y_offset);
                            carrier_pos.set_z(carrier_pos.z()-carrier_z_offset);
                        }

                        # now figure out the correct height based on the terrain elevation (which will be the carrier)
                        # initially; however once the carrier has moved we may need to adjust this.
                        # in any case is this is less than 6 meters we'd be in the bilges so this probably means
                        # that the elevation data isn't valid so use hardcoded value of 65.2
                        current_pos = carrier_pos;
                        var info = geodinfo(lat, lon);
                        if (info != nil) 
                        {
                            print("the carrier deckj is is at elevation ", info[0], " m");
                            ground_elevation = info[0]*3.28084; # convert to feet
                            if (ground_elevation < 1) ground_elevation = 65.2;
                        }
                        if (ground_elevation < 6) ground_elevation = 65.2;
                    }
                }
            }
                   
            setprop("/controls/gear/gear-down", 1);

            if (current_pos != nil)
            {
                print("Adjusting launch position by 7meters");
                current_pos.apply_course_distance(getprop("sim/presets/heading-deg"),7);
            }
            setprop("/position/latitude-deg", current_pos.lat());
            setprop("/position/longitude-deg", current_pos.lon());

            print("Moving the aircraft into the launch position properly... for ",carrier, " alt ",ground_elevation," lat ", current_pos.lat(), " lon ",current_pos.lon());

            setprop("/position/altitude-ft", ground_elevation+getprop("sim/model/f15/overrides/aircraft-agl-height"));
        }
    }

}
var common_init = func {

        print("Setting replay medium res to 50hz");
setprop("sim/hud/visibility[0]",0);
setprop("sim/hud/visibility[1]",0);

        setprop("sim/replay/buffer/medium-res-sample-dt", 0.02); 
        setprop("/controls/flight/SAS-roll",0);
        setprop("sim/model/f15/controls/AFCS/altitude",0);
        setprop("sim/model/f15/controls/AFCS/heading-gt",0);
        setprop("sim/model/f15/controls/AFCS/engage",0);
        if (getprop("sim/model/f15/controls/windshield-heat") != nil)
            setprop("fdm/jsbsim/systems/ecs/windshield-heat",getprop("sim/model/f15/controls/windshield-heat"));

#
# this is just to ensure that we start with pressure in the util hyds
        setprop("fdm/jsbsim/systems/hydraulics/util-system-preload-input",-500);
        settimer(func {
                     setprop("fdm/jsbsim/systems/hydraulics/util-system-preload-input",0); 
                        }, 4);
        if (getprop("/fdm/jsbsim/position/h-agl-ft") != nil)
        {
            if (getprop("/fdm/jsbsim/position/h-agl-ft") < 500) 
            {
                print("Starting with gear down as below 500 ft");
                setprop("/controls/gear/gear-down", 1);
                setprop("/fdm/jsbsim/fcs/gear/gear-cmd-norm",1);
                setprop("/fdm/jsbsim/fcs/gear/gear-dmd-norm",1);
                setprop("/fdm/jsbsim/fcs/gear/gear-pos-norm",1);
                setprop("/fdm/jsbsim/fcs/gear/gear-pos-norm",1);

                if (getprop("/fdm/jsbsim/position/h-agl-ft") < 50) 
                {
                    setprop("/controls/gear/brake-parking",1);
                    print("--> Set parking brake as below 50 ft");
                }
            }
            else 
            {
                print("Starting with gear up as above 500 ft");
                setprop("/controls/gear/gear-down", 0);
                setprop("/fdm/jsbsim/fcs/gear/gear-cmd-norm",0);
                setprop("/fdm/jsbsim/fcs/gear/gear-dmd-norm",0);
                setprop("/fdm/jsbsim/fcs/gear/gear-pos-norm",0);
                setprop("/fdm/jsbsim/fcs/gear/gear-pos-norm",0);
                setprop("/controls/gear/brake-parking",0);
            }
        }
        common_carrier_init();
}

# Init ####################
var init = func {
	print("Initializing f15 Systems");
	ext_loads_init();
	init_fuel_system();
	aircraft.data.load();
	f15_net.mp_network_init(1);
	weapons_init();
	ticker.setDoubleValue(0);
	local_mag_deviation();
	tacan_switch_init();
	radardist.init();
	awg_9.init();
#	an_arc_182v.init();
#	an_arc_159v1.init();
    aircraft.setup_als_lights();

	setprop("controls/switches/radar_init", 0);
	# properties to be stored
	foreach (var f_tc; TcFreqs.getChildren()) {
		aircraft.data.add(f_tc);
	}

    common_init();
    if ( ! main_loop_launched ) {
        settimer(main_loop, 0.5);
        main_loop_launched = 1;
    }
}

setlistener("sim/signals/fdm-initialized", init);


setlistener("sim/position-finalized", func (is_done) {
    print("position-finalized ",is_done.getValue());
    if (is_done.getValue())
    {
    common_init();
#        common_carrier_init();
    }

});
setlistener("sim/signals/reinit", func (reinit) {
    if (reinit.getValue()) {
        internal_save_fuel();
    } else {
        settimer(func { internal_restore_fuel() }, 0.6);
    }
});
# Miscelaneous definitions and tools ############

# warning lights medium speed flasher
# -----------------------------------
aircraft.light.new("sim/model/f15/lighting/warn-medium-lights-switch", [0.3, 0.2]);
setprop("sim/model/f15/lighting/warn-medium-lights-switch/enabled", 1);


# Old Fashioned Radio Button Selectors
# -----------------------------------
# Where group is the parent node that contains the radio state nodes as children.

sel_displays_main_mode = func(group, which) {
#setprop("sim/model/f15/instrumentation/hud/mode-aa",0);
#setprop("sim/model/f15/instrumentation/hud/mode-ag",0);
#setprop("sim/model/f15/instrumentation/hud/mode-to",0);
#setprop("sim/model/f15/instrumentation/hud/mode-ldg",0);
#setprop("sim/model/f15/instrumentation/hud/mode-crs",0);
print("set mode ",group," ",which);
#setprop(group~"-"~which,1);
	foreach (var n; props.globals.getNode(group).getChildren()) {
		n.setBoolValue(n.getName() == which);
	}
}

sel_displays_sub_mode = func(group, which) {
	foreach (var n; props.globals.getNode(group).getChildren()) {
		n.setBoolValue(n.getName() == which);
	}
	var steer_mode_code = 0;
	if ( SteerModeDest.getBoolValue() ) { steer_mode_code = 1 }
	elsif ( SteerModeMan.getBoolValue() ) { steer_mode_code = 2 }
	elsif ( SteerModeTcn.getBoolValue() ) { steer_mode_code = 3 }
	elsif ( SteerModeVec.getBoolValue() ) { steer_mode_code = 4 }
	SteerModeCode.setValue(steer_mode_code);
}



