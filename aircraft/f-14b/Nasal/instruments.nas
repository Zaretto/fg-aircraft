 #---------------------------------------------------------------------------
 #
 # Title                : F-14 instruments and commands
 #
 # File Type            : Implementation File
 #
 # Description          : Instrument outputs, command handling.
 #
 # Authors              : xii
 #                      : Richard Harrison (richard@zaretto.com)
 #
 # Copyright (C) 2018 Authors           Released under GPL V2
 #
 #---------------------------------------------------------------------------*/


# TACAN: nav[1]
var nav1_as_selected = getprop( "instrumentation/nav[1]/frequencies/selected-mhz" );; # the selected frequency if overriden from the tacan

var Tc               = props.globals.getNode("instrumentation/tacan");
var Vtc              = props.globals.getNode("instrumentation/nav[1]");
var Hsd              = props.globals.getNode("sim/model/f-14b/instrumentation/hsd", 1);
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
var TcXYSwitch       = props.globals.getNode("sim/model/f-14b/instrumentation/tacan/xy-switch", 1);
var TcModeSwitch     = props.globals.getNode("sim/model/f-14b/instrumentation/tacan/mode", 1);
var TrueHdg          = props.globals.getNode("orientation/heading-deg");
var MagHdg           = props.globals.getNode("orientation/heading-magnetic-deg");
var MagDev           = props.globals.getNode("orientation/local-mag-dev", 1);
var post_init_method = nil;
var repos_gear_down = 0;
var mag_dev = 0;
var tc_mode = 0;
var carrier_pos_first_time = 1;
var carrier_x_offset = 0;
var carrier_y_offset = 0;
var carrier_z_offset = 0;
aircraft.ownship_pos = geo.Coord.new();

setprop("/fdm/jsbsim/systems/hook/arrestor-wire-engaged-hook",0); # FG 2018.1 has improved hook handling; this is for compatibility; 

aircraft.data.add(VtcRadialDeg, TcModeSwitch);


# Compute local magnetic deviation.
var local_mag_deviation = func {
	var true = TrueHdg.getValue();
	var mag = MagHdg.getValue();
    if (mag != nil and true != nil)
    {
        mag_dev = geo.normdeg( mag - true );
        if ( mag_dev > 180 ) mag_dev -= 360;
        MagDev.setValue(mag_dev); 
    }
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
# carrier approach 'glideslope' based on 3/4 mile @ 360feet
# (i.e. 1207m at 109m)
var FD_TANDEG = math.tan(3.5 / 57.29577950560105);

#
# AN/SPN 46 transmits - this receives.
var ARA63Recipient =
{
    new: func(_ident)
    {
        var new_class = emesary.Recipient.new(_ident);
        new_class.ansn46_expiry = 0;
        new_class.Receive = func(notification)
        {
            if (notification.NotificationType == "ANSPN46ActiveNotification")
            {
#                print(" :: Recvd lat=",notification.Position.lat(), " lon=",notification.Position.lon(), " alt=",notification.Position.alt(), " chan=",notification.Channel);
                var response_msg = me.Response.Respond(notification);
#
# We cannot decide if in range as it is the AN/SPN system to decide if we are within range
# However we will tell the AN/SPN system if we are tuned (and powered on)
                if(notification.Channel == getprop("sim/model/f-14b/controls/electrics/ara-63-channel") and getprop("sim/model/f-14b/controls/electrics/ara-63-power-off") == 0)
                    response_msg.Tuned = 1;
                else
                    response_msg.Tuned = 0;

# normalised value based on RCS beam power etc.
# we could do this using a factor.
                response_msg.RadarReturnStrength = 1; # possibly response_msg.RadarReturnStrength*RCS_FACTOR

                emesary.GlobalTransmitter.NotifyAll(response_msg);
                return emesary.Transmitter.ReceiptStatus_OK;
            }
#---------------------
# we will only receive one of these messages when within range of the carrier (and when the ARA-63 is powered up and has the correct channel set)
#
            else if (notification.NotificationType == "ANSPN46CommunicationNotification")
            {
                me.ansn46_expiry = getprop("/sim/time/elapsed-sec") + 10;
# Use the standard civilian ILS if it is closer.
#        print("rcvd ANSPN46CommunicationNotification =",notification.InRange, " dev=",notification.LateralDeviation, ",", notification.VerticalDeviation, " dist=",notification.Distance);
                if(getprop("instrumentation/nav/gs-in-range") and getprop("instrumentation/nav/gs-distance") < notification.Distance)
                {
                    me.ansn46_expiry=0;
                    return emesary.Transmitter.ReceiptStatus_OK;
                }
                else if (notification.InRange)
                {
                    setprop("sim/model/f-14b/instrumentation/nav/gs-in-range", 1);
                    setprop("sim/model/f-14b/instrumentation/nav/gs-needle-deflection-norm",notification.VerticalAdjustmentCommanded);
                    setprop("sim/model/f-14b/instrumentation/nav/heading-needle-deflection-norm",notification.HorizontalAdjustmentCommanded);
                    setprop("sim/model/f-14b/instrumentation/nav/signal-quality-norm",notification.SignalQualityNorm);
                    setprop("sim/model/f-14b/instrumentation/nav/gs-distance", notification.Distance);
                    setprop("sim/model/f-14b/lights/light-10-seconds",notification.TenSeconds);
                    setprop("sim/model/f-14b/lights/light-wave-off",notification.WaveOff);

# Set these lights on when in range and within altitude.
# the lights come on but it is unspecified when they go off.
# Ref: F-14AAD-1 Figure 17-4, p17-11 (pdf p685)
                    if (notification.Distance < 11000) 
                    {
                        if (notification.ReturnPosition.alt() > 300 and notification.ReturnPosition.alt() < 425 and abs(notification.LateralDeviation) < 1 )
                        {
                            setprop("sim/model/f-14b/lights/acl-ready-light", 1);
                            setprop("sim/model/f-14b/lights/ap-cplr-light",1);
                        }
                        if (notification.Distance > 8000)  # extinguish at roughly 4.5nm from fix.
                        {
                            setprop("sim/model/f-14b/lights/landing-chk-light", 1);
                        }
                        else
                        {
                            setprop("sim/model/f-14b/lights/landing-chk-light", 0);
                        }
                    }
                }
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        new_class.Response = ANSPN46ActiveResponseNotification.new("ARA-63");
        return new_class;
    },
};

var ara63 = ARA63Recipient.new("F-14/ARA-63");
emesary.GlobalTransmitter.Register(ara63);
#
# ARA 63 (Military ILS type of system). This is a bit hardwired to
# work with the tuned carrier based on the TACAN channel which isn't
# right - but it is good enough.
var ara_63_update = func
{
#
# do not do anything whilst the AN/SPN 46 is within expiry time. 
    if(getprop("/sim/time/elapsed-sec") < ara63.ansn46_expiry)
        return;

#
# Use the standard civilian ILS
    setprop("sim/model/f-14b/lights/landing-chk-light", 0);
    setprop("sim/model/f-14b/lights/light-10-seconds",0);
    setprop("sim/model/f-14b/lights/light-wave-off",0);
    setprop("sim/model/f-14b/lights/acl-ready-light", 0);
    setprop("sim/model/f-14b/lights/ap-cplr-light",0);

    if (getprop("instrumentation/nav/gs-in-range") != nil)
    {
        setprop("sim/model/f-14b/instrumentation/nav/gs-in-range", getprop("instrumentation/nav/gs-in-range"));
        setprop("sim/model/f-14b/instrumentation/nav/gs-needle-deflection-norm",getprop("instrumentation/nav/gs-needle-deflection-norm"));
        setprop("sim/model/f-14b/instrumentation/nav/gs-distance", getprop("instrumentation/nav/gs-distance"));
        setprop("sim/model/f-14b/instrumentation/nav/heading-needle-deflection-norm",getprop("instrumentation/nav/heading-needle-deflection-norm"));
        setprop("sim/model/f-14b/instrumentation/nav/signal-quality-norm",getprop("instrumentation/nav/signal-quality-norm"));
    }
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
var mode_ecm_nav = props.globals.getNode("sim/model/f-14b/controls/rio-ecm-display/mode-ecm-nav");
var hsd_mode_nav = props.globals.getNode("sim/model/f-14b/controls/pilots-displays/hsd-mode-nav");
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
var bingo      = props.globals.getNode("sim/model/f-14b/controls/fuel/bingo", 1);
aircraft.data.add(	bingo,
                    "consumables/fuel/total-fuel-lbs-for-restore",
					"sim/model/f-14b/systems/external-loads/station[2]/type",
					"sim/model/f-14b/systems/external-loads/station[7]/type",
					"consumables/fuel/tank[8]/selected",
					"consumables/fuel/tank[9]/selected",
					"sim/model/f-14b/systems/external-loads/external-tanks",
					"sim/weight[1]/weight-lb","sim/weight[6]/weight-lb"
				);




var g_max   = props.globals.getNode("sim/model/f-14b/instrumentation/g-meter/g-max", 1);
var g_min   = props.globals.getNode("sim/model/f-14b/instrumentation/g-meter/g-min", 1);
aircraft.data.add( g_min, g_max );
var GMaxMav = props.globals.getNode("sim/model/f-14b/instrumentation/g-meter/g-max-mooving-average", 1);
GMaxMav.initNode(nil, 0);
var g_mva_vec     = [0,0,0,0,0];

var g_min_max = func {
	# Records g min, g max and 0.5 sec averaged max values. g_min_max(). Has to be
	# fired every 0.1 sec.
	var curr = f14.currentG;
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

# VDI #####################
var ticker = props.globals.getNode("sim/model/f-14b/instrumentation/ticker", 1);
aircraft.data.add("sim/model/f-14b/controls/VDI/brightness",
	"sim/model/f-14b/controls/VDI/contrast",
	"sim/model/f-14b/controls/VDI/on-off",
	"sim/hud/visibility[0]",
	"sim/hud/visibility[1]",
	"sim/model/f-14b/controls/damage-enabled",
	"sim/model/f-14b/controls/hud/on-off",
	"sim/model/f-14b/controls/HSD/on-off",
	"sim/model/f-14b/controls/pilots-displays/mode/aa-bt",
	"sim/model/f-14b/controls/pilots-displays/mode/ag-bt",
	"sim/model/f-14b/controls/pilots-displays/mode/cruise-bt",
	"sim/model/f-14b/controls/pilots-displays/mode/ldg-bt",
	"sim/model/f-14b/controls/pilots-displays/mode/to-bt",
    "sim/model/f-14b/controls/windshield-heat",
	"sim/model/f-14b/controls/pilots-displays/hsd-mode-nav",
	"fdm/jsbsim/propulsion/engine[0]/compressor-stall-amount",
	"fdm/jsbsim/propulsion/engine[1]/compressor-stall-amount",
	"fdm/jsbsim/propulsion/engine[0]/mcb-failed",
	"fdm/jsbsim/propulsion/engine[1]/mcb-failed",
    "sim/model/f-14b/fx/vapour-color-left-r" ,
    "sim/model/f-14b/fx/vapour-color-left-g" ,
    "sim/model/f-14b/fx/vapour-color-left-b" ,
    "sim/model/f-14b/fx/vapour-color-right-r",
    "sim/model/f-14b/fx/vapour-color-right-g",
    "sim/model/f-14b/fx/vapour-color-right-b",
);

var inc_ticker = func {
	# ticker used for VDI background continuous translation animation
	var tick = ticker.getValue();
	tick += 1 ;
	ticker.setDoubleValue(tick);
}

# Air Speed Indicator #####
aircraft.data.add("sim/model/f-14b/instrumentation/airspeed-indicator/safe-speed-limit-bug");

# Radar Altimeter #########
aircraft.data.add("sim/model/f-14b/instrumentation/radar-altimeter/limit-bug");

# Lighting ################
aircraft.data.add(
	"sim/model/f-14b/controls/lighting/hook-bypass-field",
	"controls/lighting/instruments-norm",
	"controls/lighting/panel-norm",
	"sim/model/f-14b/controls/lighting/anti-collision-switch",
	"sim/model/f-14b/controls/lighting/position-flash-switch",
	"sim/model/f-14b/controls/lighting/position-wing-switch",
    "sim/model/f-14b/controls/lighting/red-flood-light-switch",
    "sim/model/f-14b/controls/lighting/white-flood-light-switch");

# HSD #####################
var hsd_mode_node = props.globals.getNode("sim/model/f-14b/controls/pilots-displays/hsd-mode-nav");


# Afterburners FX counter #
var burner = 0;
var BurnerN = props.globals.getNode("sim/model/f-14b/fx/burner", 1);
BurnerN.setValue(burner);


# AFCS ####################

# Commons vars:
var Mach = props.globals.getNode("velocities/mach");
var mach = 0;

# Filters
var PitchPidPGain = props.globals.getNode("sim/model/f-14b/systems/afcs/pitch-pid-pgain", 1);
var PitchPidDGain = props.globals.getNode("sim/model/f-14b/systems/afcs/pitch-pid-dgain", 1);
var VsPidPGain    = props.globals.getNode("sim/model/f-14b/systems/afcs/vs-pid-pgain", 1);
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
var Drag       = props.globals.getNode("sim/model/f-14b/systems/fdm/drag", 1);
var GearPos    = props.globals.getNode("gear/gear[1]/position-norm", 1);
var SpeedBrake = props.globals.getNode("controls/flight/speedbrake", 1);
var AB         = props.globals.getNode("engines/engine/afterburner", 1);

var sb_i = 0.2;
var alt_drag_factor = 25000;
var alt_drag_factor2 = 20000;
f14.usingJSBSim = 1;

controls.stepSpoilers = func(s) {

    if (f14.usingJSBSim){
        var curval = getprop("controls/flight/speedbrake");

        if (s < 0 and curval > 0)
            setprop("controls/flight/speedbrake", curval+s/5);
        else if (s > 0 and curval < 1)
            setprop("controls/flight/speedbrake", curval+s/5);

        return; 
    }

	var sb = SpeedBrake.getValue();
	if ( s == 1 ) {
		sb += sb_i;
		if ( sb > 1 ) { sb = 1 }
		SpeedBrake.setValue(sb);
	} elsif ( s == -1 ) {
		sb -= sb_i;
		if ( sb < 0 ) { sb = 0 }
		SpeedBrake.setValue(sb);
	}
}

var compute_drag = func {

    if (f14.usingJSBSim) return;  # in the FDM

	var gearpos = GearPos.getValue();
	var ab = AB.getValue(); # Prevent supercruise when no afterburners
	var gear_drag = 0;
	if ( gearpos > 0.8 ) {
		gear_drag = mach * 0.5;
	}
	# Additional drag based on altitude so we can't pass over sound speed without
	# afterburners when altitude is above 30k ft.
	var alt = getprop("position/altitude-ft");
	var alt_drag = 0;
	if ( alt > 30000 ) {
		var alt_floor = alt - 30000;
		alt_drag += (alt_floor / 50000);
	}
	#print(alt_drag);
	if ( mach <= 1 ) {
		Drag.setValue((mach * 0.5) + gear_drag + alt_drag);
	} elsif (mach <= 1.175) {
		Drag.setValue((math.sin((mach * 4.5) + 5.6) * 0.7) + 0.93 + gear_drag + alt_drag - (ab/2));
	} else {
		Drag.setValue((mach * 0.7) - 0.6 + gear_drag + alt_drag - (ab/2));
	}
}


# Send basic instruments data over MP for backseaters.
var InstrString = props.globals.getNode("sim/multiplay/generic/string[1]", 1);
var InstrString2 = props.globals.getNode("sim/multiplay/generic/string[2]", 1);
var IAS = props.globals.getNode("instrumentation/airspeed-indicator/indicated-speed-kt");
var FuelTotal = props.globals.getNode("sim/model/f-14b/instrumentation/fuel-gauges/total");
var TcBearing = props.globals.getNode("instrumentation/tacan/indicated-mag-bearing-deg");
var TcInRange = props.globals.getNode("instrumentation/tacan/in-range");
var TcRange = props.globals.getNode("instrumentation/tacan/indicated-distance-nm");
var RangeRadar2       = props.globals.getNode("instrumentation/radar/radar2-range");

var SteerModeAwl = props.globals.getNode("sim/model/f-14b/controls/pilots-displays/steer/awl-bt");
var SteerModeDest = props.globals.getNode("sim/model/f-14b/controls/pilots-displays/steer/dest-bt");
var SteerModeMan = props.globals.getNode("sim/model/f-14b/controls/pilots-displays/steer/man-bt");
var SteerModeTcn = props.globals.getNode("sim/model/f-14b/controls/pilots-displays/steer/tacan-bt");
var SteerModeVec = props.globals.getNode("sim/model/f-14b/controls/pilots-displays/steer/vec-bt");
var SteerModeCode = props.globals.getNode("sim/model/f-14b/controls/pilots-displays/steer-submode-code");

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

	var l_s = [ias, s_mach, fuel_total, tc_mode, tc_bearing, tc_in_range, tc_range, steer_mode_code, cdi, radial];
	var str = "";
	foreach( s ; l_s ) {
		str = str ~ s ~ ";";
	}
    #
    # aircraft powered - for the back seater this is a yes/no
    if ( getprop("/fdm/jsbsim/systems/electrics/ac-essential-bus1") > 0)
        str = str ~ "1" ~ ";";
    else
        str = str ~ "0" ~ ";";

	InstrString.setValue(str);

	#InstrString2.setValue(sprintf( "%01.0f", RangeRadar2.getValue()));

}


# Main loop ###############
var cnt = 0;
var ArmSysRunning = props.globals.getNode("sim/model/f-14b/systems/armament/system-running");

var instruments_exec = {
	new : func (_ident){
        print("instruments_exec: init");
        var obj = { parents: [instruments_exec]};

        # export / import properties from JSBSim that are bools as this doesn't seem to work directly.
        input = {
               aoa_indexer_slow : "/fdm/jsbsim/systems/electrics/aoa-indexer-slow",
               aoa_indexer_onspeed : "/fdm/jsbsim/systems/electrics/aoa-indexer-onspeed",
               aoa_indexer_fast : "/fdm/jsbsim/systems/electrics/aoa-indexer-fast",
               tailhook_bypass_field: "sim/model/f-14b/controls/lighting/hook-bypass-field"
        };
        foreach (var name; keys(input)) {
            emesary.GlobalTransmitter.NotifyAll(notifications.FrameNotificationAddProperty.new(_ident, name, input[name]));
        }

        # corresponding properties to export/import from/to
        obj.aoa_indexer_slow    = props.globals.getNode("sim/multiplay/generic/bool[28]");
        obj.aoa_indexer_onspeed = props.globals.getNode("sim/multiplay/generic/bool[29]");
        obj.aoa_indexer_fast    = props.globals.getNode("sim/multiplay/generic/bool[30]");
        obj.tailhook_bypass_field = props.globals.getNode("fdm/jsbsim/systems/hook/tailhook-bypass-field");


        #
        # recipient that will be registered on the global transmitter and connect this
        # subsystem to allow subsystem notifications to be received
        obj.recipient = emesary.Recipient.new(_ident~".Subsystem");
        obj.recipient.instruments_exec = obj;
        
        obj.update_items = [
            props.UpdateManager.FromHashValue("aoa_indexer_slow", 1, func(val)
                                            {
                                                obj.aoa_indexer_slow.setBoolValue(val);
                                            }),
            props.UpdateManager.FromHashValue("aoa_indexer_onspeed", 1, func(val)
                                            {
                                                obj.aoa_indexer_onspeed.setBoolValue(val);
                                            }),
            props.UpdateManager.FromHashValue("aoa_indexer_fast", 1, func(val)
                                            {
                                                obj.aoa_indexer_fast.setBoolValue(val);
                                            }),
            props.UpdateManager.FromHashValue("tailhook_bypass_field", 1, func(val)
                                            {
                                                obj.tailhook_bypass_field.setBoolValue(val);
                                            }),
        ];
        obj.recipient.Receive = func(notification)
        {
            if (notification.NotificationType == "FrameNotification")
            {
                me.instruments_exec.update(notification);
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };

        emesary.GlobalTransmitter.Register(obj.recipient);

		return obj;
	},
    update : func(notification) {
#        print("Exec instruments: dT",notification.dT, " frame=",notification.FrameCount);        
        aircraft.ownship_pos.set_latlon(getprop("position/latitude-deg"), getprop("position/longitude-deg"));
        
        foreach(var update_item; me.update_items)
        {
            update_item.update(notification);
        }

        burner +=1;
        if ( burner == 3 ) { burner = 0 }
        BurnerN.setValue(burner);

        if (f14.usingJSBSim) {
            if ( getprop("sim/replay/time") > 0 ) {
                #now recorded              setprop ("/orientation/alpha-indicated-deg", (getprop("/orientation/alpha-deg") - 0.797) / 0.8122);
            } else {
                setprop ("/gear/gear[0]/compression-adjusted-ft", getprop("fdm/jsbsim/gear/unit[0]/compression-adjusted-ft"));
                #              setprop ("/orientation/alpha-indicated-deg", getprop("fdm/jsbsim/aero/alpha-indicated-deg"));
            }
        } else
          setprop ("/orientation/alpha-indicated-deg", getprop("/orientation/alpha-deg"));

        # every other frame
        if ( !math.mod(notifications.frameNotification.FrameCount,2)){
            # even frame
            inc_ticker();
            tacan_update();
            ara_63_update();
            f14_hud.update_hud();
            g_min_max();
            f14_chronograph.update_chrono();

            if (notifications.frameNotification.FrameCount == 6 or notifications.frameNotification.FrameCount == 12 ) {
                # done each 0.3 sec.
                f14.fuel_update();
                if ( notifications.frameNotification.FrameCount == 12 ) {
                    # done each 0.6 sec.
                    local_mag_deviation();
                    nav1_freq_update();
                }
            }
        } else {
            # odd frame
            awg_9.hud.hud_nearest_tgt();
            instruments_data_export();
            if ( ArmSysRunning.getBoolValue() ) {
                f14.armament_update();
            }
            f14.armament_update2();
            if (notifications.frameNotification.FrameCount == 5 or notifications.frameNotification.FrameCount == 11 ) {
                # done each 0.3 sec.
                afcs_filters();
                compute_drag();
                if ( notifications.frameNotification.FrameCount == 11 ) {
                    # done each 0.6 sec.
                    compute_drag();
                }
            }
        }
    },
};
subsystem = instruments_exec.new("instruments_exec");

var common_carrier_init = func {

    if (f14.carrier_ara_63_position != nil and geo.aircraft_position() != nil)
    {
        if (geo.aircraft_position().distance_to(f14.carrier_ara_63_position) < 6000 and geo.aircraft_position().distance_to(f14.carrier_ara_63_position) > 400)
        {
            print("Starting with hook down as near carrier");
            setprop("controls/gear/tailhook",1);
            setprop("fdm/jsbsim/systems/hook/tailhook-cmd-norm",1);
        }

    }

    if (!getprop("sim/model/f-14b/overrides/special-carrier-handling"))
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
            if (f14.carrier_ara_63_position == nil or geo.aircraft_position().distance_to(f14.carrier_ara_63_position) < 200)
            {
                print("Special init for Carrier cat launch");
                setprop("/fdm/jsbsim/systems/holdback/holdback-cmd",1);
                setprop("gear/launchbar/position-norm",1);
                repos_gear_down = 1;
            }

            var current_pos = geo.Coord.new().set_latlon(getprop("/position/latitude-deg"), getprop("/position/longitude-deg"));

#
# Locate the carrier in case it has moved from the stated initial position.

            var raw_list = props.globals.getNode("ai/models").getChildren();
            var carrier_located = 0;

            foreach( var c; raw_list )
            {
                if (c.getNode("valid") == nil or !c.getNode("valid").getValue()) {
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
#                        var info = geodinfo(lat, lon);
#                        if (info != nil) 
#                        {
#                            print("the carrier deckj is is at elevation ", info[0], " m");
#                            ground_elevation = info[0]*3.28084; # convert to feet
#                            if (ground_elevation < 1) ground_elevation = 65.2;
#                        }
var deckAltitudeNode = c.getNode("position/deck-altitude-feet");
ground_elevation = 65;
                        if (deckAltitudeNode != nil){
                            ground_elevation =  deckAltitudeNode.getValue();
                            print("Carrier deck from node ",ground_elevation);
                        }
                        if (ground_elevation < 6) ground_elevation = 65.2;
                        print("Carrier deck now: ",ground_elevation);
                    }
                }
            }
                   
            if (current_pos != nil)
            {
                var offset = getprop("sim/model/f-14b/overrides/deck-offset-m");
                print("Adjusting launch position by ",offset," meters");
                current_pos.apply_course_distance(getprop("sim/presets/heading-deg"),offset);
            }
            setprop("/position/latitude-deg", current_pos.lat());
            setprop("/position/longitude-deg", current_pos.lon());

            print("Moving the aircraft into the launch position properly... for ",carrier, " alt ",ground_elevation," lat ", current_pos.lat(), " lon ",current_pos.lon());

            #
            # sim/model/f-14b/overrides/aircraft-agl-height is the known height of the aircraft (in feet) with gear down.
            setprop("/position/altitude-ft", ground_elevation + getprop("sim/model/f-14b/overrides/aircraft-agl-height"));
         }
    }

}

var common_init = func {
    if(f14.usingJSBSim)
    {
        #
        # part of the bombable integration. we don't have magnetos so we can use them
        # to detect damage
        #setprop("controls/engines/engine[0]/magnetos",1);
        #setprop("controls/engines/engine[1]/magnetos",1);

        if (getprop("sim/model/f-14b/controls/windshield-heat") != nil)
            setprop("fdm/jsbsim/systems/ecs/windshield-heat",getprop("sim/model/f-14b/controls/windshield-heat"));

f14_afcs.afcs_disengage();
    setprop("fdm/jsbsim/systems/hook/tailhook-bypass-field",getprop("sim/model/f-14b/controls/lighting/hook-bypass-field"));
        setprop("sim/multiplay/visibility-range-nm", 200);
	print("Setting replay medium res to 50hz");
        setprop("sim/replay/buffer/medium-res-sample-dt", 0.02); 
        setprop("/controls/flight/SAS-roll",0);
        setprop("sim/model/f-14b/controls/AFCS/altitude",0);
        setprop("sim/model/f-14b/controls/AFCS/heading-gt",0);
        setprop("sim/model/f-14b/controls/AFCS/engage",0);
        if (getprop("/fdm/jsbsim/position/h-agl-ft") != nil)
        {
            if (getprop("/fdm/jsbsim/position/h-agl-ft") < 500 or repos_gear_down) 
            {
                if (repos_gear_down)
                  print("Starting with gear down as repos_gear_down set to ",repos_gear_down);
                else
                  print("Starting with gear down as below 500 ft");
                setprop("/controls/gear/gear-down", 1);
                setprop("/fdm/jsbsim/fcs/gear/gear-cmd-norm",1);
                setprop("/fdm/jsbsim/fcs/gear/gear-dmd-norm",1);
                setprop("/fdm/jsbsim/gear/gear-pos-norm",1);

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
                setprop("/fdm/jsbsim/gear/gear-pos-norm",0);
                setprop("/controls/gear/brake-parking",0);
            }
        }
        common_carrier_init();
    }
    if (post_init_method != nil){
        post_init_method();
        post_init_method = nil;
    }
}

# Init ####################
var init = func(v) {
if (v == nil or !v.getValue())
  {
	print("init: not ready ",v.getValue());
return;
  }

	print("Initializing F-14 Systems ",v.getValue());
	f14.ext_loads_init();
	f14.init_fuel_system();
	aircraft.data.load();
	f14_net.mp_network_init(1);
	f14.weapons_init();
	ticker.setDoubleValue(0);
	local_mag_deviation();
	tacan_switch_init();
	radardist.init();
	awg_9.init();
	an_arc_182v.init();
	an_arc_159v1.init();
    f14.set_flood_lighting_colour();
	setprop("controls/switches/radar_init", 0);
	# properties to be stored
	foreach (var f_tc; TcFreqs.getChildren()) {
		aircraft.data.add(f_tc);
	}
	setprop("f14/done",0);#reset ejection seat
	view.setViewByIndex(0);
	setprop("sim/view[115]/enabled", 0);
    common_init();
}

setlistener("sim/signals/fdm-initialized", init);

var initOnce = func {
	if (getprop("sim/signals/fdm-initialized")) {
		# this method will be run once when the FDM is ready, and will never be run again. (unless the FG Reset option is used)
		removelistener(initOnceListen);
	    
	    # make failure mode for radar and fire-control, so that when aircraft is hit missiles cannot still be fired off:
	    var prop = "/instrumentation/radar";
	    var actuator_radar = compat_failure_modes.set_unserviceable(prop);
	    FailureMgr.add_failure_mode(prop, "Radar", actuator_radar);
	    
	    prop = "/payload/armament/fire-control";
	    var actuator_fire_control = compat_failure_modes.set_unserviceable(prop);
	    FailureMgr.add_failure_mode(prop, "Fire-control", actuator_fire_control);
	    
	    var fire_fc = compat_failure_modes.set_unserviceable("damage/fire");# will make smoke trail when damaged
		FailureMgr.add_failure_mode("damage/fire", "Fire", fire_fc);
	}
}
var initOnceListen = setlistener("sim/signals/fdm-initialized", initOnce);# this listener will be removed after it has ran once.


setlistener("sim/position-finalized", func (is_done) {
#    print("position-finalized ",is_done.getValue());
    if (is_done.getValue())
    {
    common_init();
#        common_carrier_init();
    }

});
setlistener("sim/signals/reinit", func (reinit) {
    if (reinit.getValue()) {
        f14.internal_save_fuel();
        setprop("ai/submodels/submodel[4]/count", 100);#replenish chaff and flares
    	setprop("ai/submodels/submodel[5]/count", 100);
    } else {
        settimer(func { f14.internal_restore_fuel() }, 0.6);
    }
});
# Miscelaneous definitions and tools ############

# warning lights medium speed flasher
# -----------------------------------
aircraft.light.new("fdm/jsbsim/systems/electrics/aoa-indexer-light", [0.3, 0.2]);
setprop("fdm/jsbsim/systems/electrics/aoa-indexer-light/enabled", 1);


# Old Fashioned Radio Button Selectors
# -----------------------------------
# Where group is the parent node that contains the radio state nodes as children.

sel_displays_main_mode = func(group, which) {
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
get_approach_onspeed = func{
    total_mass_lbs = getprop("fdm/jsbsim/inertia/weight-lbs");
    # MMF Model curve fit mass to onspeed
    # y=(a*b+c*x^d)/(b+x^d)
    # wher
    # a =	-2.62993732562E+001
    # b =	1.08584946812E+003
    # c =	8.10788076735E+002
    # d =	5.10014100237E-001
    #Quadratic Fit:  y=a+bx+cx^2
    #a =	4.58500000000E+001
    #b =	2.05500000000E-003
    #c =	-7.50000000000E-009

    #return 2+(-26.2994*1085.85+810.79*math.pow(total_mass_lbs,0.51))/(1085.85+math.pow(total_mass_lbs,0.5100));
    return 0.4+(45.85+0.002055*total_mass_lbs+-0.00000000750*total_mass_lbs*total_mass_lbs);
}

#
# Carrier reposition methods
carrier_approach_reposition = func {
    var np = geo.Coord.new()
    .set_xyz(f14.carrier_ara_63_position.x(), f14.carrier_ara_63_position.y(), f14.carrier_ara_63_position.z());
    var magvar=getprop("/orientation/local-mag-dev");
    var dist_m = 11000;
    if (getprop("sim/presets/carrier-approach-dist-m") != nil)
        dist_m  = getprop("sim/presets/carrier-approach-dist-m");
    np.apply_course_distance(f14.carrier_ara_63_heading,-dist_m);
    var gs_height = ((dist_m*FD_TANDEG)+20)*3.281;
    lat = np.lat();
    lon = np.lon();
    onspeed = get_approach_onspeed();
    print("Position to ",dist_m," height ",gs_height, " speed=",onspeed, " lat=",lat," lon=",lon);

    setprop("controls/gear/gear-down",1);
    setprop("sim/presets/trim", 1);
    setprop("sim/presets/latitude-deg",np.lat());
    setprop("sim/presets/longitude-deg",np.lon());
    setprop("sim/presets/altitude-ft",gs_height);
    setprop("sim/presets/airspeed-kt",onspeed);
    setprop("sim/presets/pitch-deg",7);
    #setprop("sim/presets/heading-deg",178-magvar);
    setprop("sim/presets/heading-deg",f14.carrier_ara_63_heading-14-magvar);
    setprop("fdm/jsbsim/systems/hook/tailhook-cmd-norm",1);
    setprop("/sim/presets/carrier","");
    setprop("/sim/presets/parkpos","");
    setprop("position/latitude-deg",lat);
    setprop("position/longitude-deg",lon);
    setprop("position/altitude-ft",gs_height);
    repos_gear_down = 1;
    setprop("fdm/jsbsim/gear/gear-cmd-norm",1);
    setprop("/controls/gear/brake-parking",0);
    setprop("/controls/flight/elevator-trim", -0.3698032779);
    setprop("/fdm/trim/trimmed", 0);
    setprop("/fdm/trim/pitch-trim", -0.3698032779);
    fgcommand("reposition");
    post_init_method = func{
        print("finish approach repos ");
        print("finalize position ",onspeed," alt=",getprop("position/altitude-agl-ft"));
        # v 0.41
        #setprop("sim/latitude-deg",lat);
        #setprop("sim/longitude-deg",lon);
        #setprop("sim/altitude-ft",gs_height);
        #    
    setprop("fdm/jsbsim/gear/gear-cmd-norm",1);
    setprop("/controls/gear/brake-parking",0);
    setprop("/controls/flight/elevator-trim", -0.3698032779);
    setprop("/fdm/trim/trimmed", 1);
        f14.APC_on();
        setprop ("fdm/jsbsim/systems/apc/target-vc-kts", onspeed);
        setprop("fdm/jsbsim/gear/gear-cmd-norm",1);
        setprop("/controls/gear/brake-parking",0);
        #    setprop("sim/presets/airspeed-kt",onspeed);
        np = geo.Coord.new().set_xyz(f14.carrier_ara_63_position.x(), f14.carrier_ara_63_position.y(), f14.carrier_ara_63_position.z());
        np.apply_course_distance(f14.carrier_ara_63_heading-116,-50);
        setprop("/sim/tower/latitude-deg",np.lat());
        setprop("/controls/flight/flaps",1);
        setprop("/controls/gear/gear-down",1);
        setprop("/sim/tower/longitude-deg",np.lon());
        setprop("/sim/tower/altitude-ft",np.alt()+100);
    };
}


f14_instruments.carrier_case_1_approach_reposition = func {
if (f14.carrier_ara_63_position == nil)
{
print("No carrier");
return;
}

print("Case 1. Onspeed=",f14_instruments.get_approach_onspeed());

    var np = geo.Coord.new()
    .set_xyz(f14.carrier_ara_63_position.x(), f14.carrier_ara_63_position.y(), f14.carrier_ara_63_position.z());
    var magvar=getprop("/orientation/local-mag-dev");

    var dist_m = -560;
    var gs_height = 800;
    var fuel = 3500;   #lbs
    var onspeed =325;

#    if (getprop("sim/presets/carrier-approach-dist-m") != nil)
#        dist_m  = getprop("sim/presets/carrier-approach-dist-m");
    np.apply_course_distance(f14.carrier_ara_63_heading-90, dist_m);
    lat = np.lat();
    lon = np.lon();
    f14.set_fuel(fuel);

    print("Position to ",dist_m," height ",gs_height, " speed=",onspeed, " lat=",lat," lon=",lon);

    setprop("controls/gear/gear-down",0);
    setprop("/controls/flight/flaps",0);
    setprop("/controls/gear/gear-down",0);
    setprop("fdm/jsbsim/gear/gear-cmd-norm",0);
    setprop("/controls/gear/brake-parking",0);
    setprop("fdm/jsbsim/gear/gear-cmd-norm",0);
    setprop("/controls/gear/brake-parking",0);
    setprop("fdm/jsbsim/systems/hook/tailhook-cmd-norm",0);
setprop("/controls/flight/flaps",0);
setprop("/controls/gear/gear-down",0);

    setprop("sim/presets/trim", 1);
    setprop("sim/presets/latitude-deg",np.lat());
    setprop("sim/presets/longitude-deg",np.lon());
    setprop("sim/presets/altitude-ft",gs_height);
    setprop("sim/presets/airspeed-kt",onspeed);
    setprop("sim/presets/pitch-deg",0);

setprop("/sim/presets/speed-set", "uvw");
var KTS_TO_FPS = 1.68781;

setprop("/sim/presets/uBody-fps",KTS_TO_FPS * onspeed);
setprop("/sim/presets/vBody-fps",0);
setprop("/sim/presets/wBody-fps",0);

    #setprop("sim/presets/heading-deg",178-magvar);
    setprop("sim/presets/heading-deg",f14.carrier_ara_63_heading-14-magvar);
    setprop("/sim/presets/carrier","");
    setprop("/sim/presets/parkpos","");
    setprop("position/latitude-deg",lat);
    setprop("position/longitude-deg",lon);
    setprop("position/altitude-ft",gs_height);

    repos_gear_down = 0;

var elevator_trim = -0.089647;

    setprop("/controls/flight/elevator-trim", elevator_trim);
    setprop("/fdm/trim/pitch-trim", elevator_trim);

    setprop("/fdm/trim/trimmed", 1);
    fgcommand("reposition");

    post_init_method = func{
        print("F-14: finish approach repos ************************");
        print("finalize position ",onspeed," alt=",getprop("position/altitude-agl-ft"));
        setprop("/controls/flight/elevator-trim", elevator_trim);
        setprop("/fdm/trim/pitch-trim", elevator_trim);

        # v 0.41
        #setprop("sim/latitude-deg",lat);
        #setprop("sim/longitude-deg",lon);
        #setprop("sim/altitude-ft",gs_height);
        #    

        setprop("fdm/jsbsim/gear/gear-cmd-norm",0);
        setprop("/controls/gear/brake-parking",0);

        #    setprop("/controls/flight/elevator-trim", -0.3698032779);
        #    setprop("/controls/flight/elevator-trim", -0.0);
        #    setprop("/fdm/trim/trimmed", 1);
        #        f14.APC_on();
        #        setprop ("fdm/jsbsim/systems/apc/target-vc-kts", onspeed);

        #    setprop("sim/presets/airspeed-kt",onspeed);

        np = geo.Coord.new().set_xyz(f14.carrier_ara_63_position.x(), f14.carrier_ara_63_position.y(), f14.carrier_ara_63_position.z());
        np.apply_course_distance(f14.carrier_ara_63_heading-116,-50);

        setprop("/sim/tower/latitude-deg",np.lat());
        setprop("/sim/tower/longitude-deg",np.lon());
        setprop("/sim/tower/altitude-ft",np.alt()+100);
    };
}
#0.3nm from carrier overhead
#f14_instruments.carrier_case_1_approach_reposition();
#break at the bow if formation lead 0.6nm


setlistener("fdm/jsbsim/systems/hook/arrestor-wire-available", func(v)
{
	if (v != nil and v.getValue() == 0 and getprop("fdm/jsbsim/systems/hook/funcs/hook-operational-efficiency") < 1)
	{
		setprop("/sim/messages/copilot", "Arrestor wire inoperable due to overspeed. Onspeed VC "~int(getprop("fdm/jsbsim/inertia/aoa-indexer-kts"))~"kts ");
	}
},0,0);
