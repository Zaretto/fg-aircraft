# AWG-9 Radar routines.
# RWR (Radar Warning Receiver) is computed in the radar loop for better performance
# AWG-9 Radar computes the nearest target for AIM-9.

var ElapsedSec        = props.globals.getNode("sim/time/elapsed-sec");
var SwpFac            = props.globals.getNode("sim/model/f-14b/instrumentation/awg-9/sweep-factor", 1);
var DisplayRdr        = props.globals.getNode("sim/model/f-14b/instrumentation/radar-awg-9/display-rdr");
var HudTgtHDisplay    = props.globals.getNode("sim/model/f-14b/instrumentation/radar-awg-9/hud/target-display", 1);
var HudTgt            = props.globals.getNode("sim/model/f-14b/instrumentation/radar-awg-9/hud/target", 1);
var HudTgtTDev        = props.globals.getNode("sim/model/f-14b/instrumentation/radar-awg-9/hud/target-total-deviation", 1);
var HudTgtTDeg        = props.globals.getNode("sim/model/f-14b/instrumentation/radar-awg-9/hud/target-total-angle", 1);
var HudTgtClosureRate = props.globals.getNode("sim/model/f-14b/instrumentation/radar-awg-9/hud/closure-rate", 1);
var HudTgtDistance = props.globals.getNode("sim/model/f-14b/instrumentation/radar-awg-9/hud/distance", 1);
var AzField           = props.globals.getNode("instrumentation/radar/az-field", 1);
var RangeRadar2       = props.globals.getNode("instrumentation/radar/radar2-range");
var RadarStandby      = props.globals.getNode("instrumentation/radar/radar-standby");
var RadarStandbyMP    = props.globals.getNode("sim/multiplay/generic/int[2]");
var OurAlt            = props.globals.getNode("position/altitude-ft");
var OurHdg            = props.globals.getNode("orientation/heading-deg");
var OurRoll           = props.globals.getNode("orientation/roll-deg");
var OurPitch          = props.globals.getNode("orientation/pitch-deg");
var EcmOn             = props.globals.getNode("instrumentation/ecm/on-off", 1);
var WcsMode           = props.globals.getNode("sim/model/f-14b/instrumentation/radar-awg-9/wcs-mode");
var SWTgtRange        = props.globals.getNode("sim/model/f-14b/systems/armament/aim9/target-range-nm");


var az_fld            = AzField.getValue();
var l_az_fld          = 0;
var r_az_fld          = 0;
var swp_fac           = nil;    # Scan azimuth deviation, normalized (-1 --> 1).
var swp_deg           = nil;    # Scan azimuth deviation, in degree.
var swp_deg_last      = 0;      # Used to get sweep direction.
var swp_spd           = 1.7; 
var swp_dir           = nil;    # Sweep direction, 0 to left, 1 to right.
var swp_dir_last      = 0;
var ddd_screen_width  = 0.0844; # 0.0844m : length of the max azimuth range on the DDD screen.
var range_radar2      = 0;
var my_radarcorr      = 0;
var our_radar_stanby  = 0;
var wcs_mode          = "pulse-srch";
var tmp_nearest_rng   = nil;
var tmp_nearest_u     = nil;
var nearest_rng       = 0;
var nearest_u         = nil;

var our_true_heading  = 0;
var our_alt           = 0;

var Mp = props.globals.getNode("ai/models");
var mp_i              = 0;
var mp_count          = 0;
var mp_list           = [];
var tgts_list         = [];
var cnt               = 0;
# Dual-control vars: 
var we_are_bs         = 0;
var pilot_lock        = 0;

# ECM warnings.
var EcmAlert1 = props.globals.getNode("instrumentation/ecm/alert-type1", 1);
var EcmAlert2 = props.globals.getNode("instrumentation/ecm/alert-type2", 1);
var ecm_alert1        = 0;
var ecm_alert2        = 0;
var ecm_alert1_last   = 0;
var ecm_alert2_last   = 0;
var u_ecm_signal      = 0;
var u_ecm_signal_norm = 0;
var u_radar_standby   = 0;
var u_ecm_type_num    = 0;
var FD_TAN3DEG = 0.052407779283; # tan(3)

init = func() {
	var our_ac_name = getprop("sim/aircraft");
    if(our_ac_name == "f-14a") our_ac_name = "f-14b"; # RJH: We are an F14a - but internally we are an F14-B for compatibility with existing model so need to change the aircraft name here otherwise radar won't work
	my_radarcorr = radardist.my_maxrange( our_ac_name ); # in kilometers
	if (our_ac_name == "f-14b-bs") { we_are_bs = 1; }
	}

# Main loop ###############
# Done each 0.05 sec. Called from instruments.nas
var rdr_loop = func() {
	var display_rdr = DisplayRdr.getBoolValue();
	if ( display_rdr ) {
		az_scan();
		our_radar_stanby = RadarStandby.getValue();
#print ("Display radar ",our_radar_stanby, we_are_bs);
		if ( we_are_bs == 0) {
			RadarStandbyMP.setIntValue(our_radar_stanby); # Tell over MP if
			# our radar is scaning or is in stanby. Don't if we are a back-seater.
		}
	} elsif ( size(tgts_list) > 0 ) {
		foreach( u; tgts_list ) {
			u.set_display(0);
		}
	}
}

var az_scan = func() {

	# Antena az scan. Angular speed is constant but angle covered varies (120 or 60 deg ATM).
	var fld_frac = az_fld / 120;                    # the screen (and the max scan angle) covers 120 deg, but we may use less (az_fld).
	var fswp_spd = swp_spd / fld_frac;              # So the duration (fswp_spd) of a complete scan will depend on the fraction we use.
	swp_fac = math.sin(cnt * fswp_spd) * fld_frac;  # Build a sinusoïde, each step based on a counter incremented by the main UPDATE_PERIOD
	SwpFac.setValue(swp_fac);                       # Update this value on the property tree so we can use it for the sweep line animation.
	swp_deg = az_fld / 2 * swp_fac;                 # Now get the actual deviation of the antenae in deg,
	swp_dir = swp_deg < swp_deg_last ? 0 : 1;       # and the direction.
	#if ( az_fld == nil ) { az_fld = 74 } # commented 20110911 if really needed it shouls had been on top of the func.
	l_az_fld = - az_fld / 2;
	r_az_fld = az_fld / 2;

	var fading_speed = 0.015;   # Used for the screen animation, dots get bright when the sweep line goes over, then fade.

	our_true_heading = OurHdg.getValue();
	our_alt = OurAlt.getValue();

	if (swp_dir != swp_dir_last) {
		# Antena scan direction change (at max: more or less every 2 seconds). Reads the whole MP_list.
		# TODO: Visual glitch on the screen: the sweep line jumps when changing az scan field.
		az_fld = AzField.getValue();
		range_radar2 = RangeRadar2.getValue();
		if ( range_radar2 == 0 ) { range_radar2 = 0.00000001 }
		# Reset nearest_range score
		nearest_u = tmp_nearest_u;
		armament.contact = nearest_u;
		nearest_rng = tmp_nearest_rng;
		tmp_nearest_rng = nil;
		tmp_nearest_u = nil;

		tgts_list = [];
		var raw_list = Mp.getChildren();
        var carrier_located = 0;

		foreach( var c; raw_list ) {
			# FIXME: At that time a multiplayer node may have been deleted while still
			# existing as a displayable target in the radar targets nodes.
			var type = c.getName();

			if (c.getNode("valid") == nil or !c.getNode("valid").getValue()) {
				continue;
			}
			var HaveRadarNode = c.getNode("radar");

            #
            # ARA 63 (Carrier ILS) support.
            # if this node has a tacan channel and we are
            # tuned to it then get the position as it will be
            # used in the ARA 63 calculations for glideslope and localizer.

            var tchan = c.getNode("navaids/tacan/channel-ID");
            if (tchan != nil and !we_are_bs)
            {
                tchan = tchan.getValue();
                if (tchan == getprop("/instrumentation/tacan/display/channel"))
                {
                    # Tuned into this carrier (node) so use the offset.
                    # Get the position of the glideslope; this is offset from the carrier position by
                    # a smidgen. This is measured and is a point slightly in front of the TDZ where the
                    # deck is marked with previous tyre marks (which seems as good a place as any to 
                    # aim for).
                    if (c.getNode("position/global-x") != nil)
                    {
                        var x = c.getNode("position/global-x").getValue() + 88.7713542;
                        var y = c.getNode("position/global-y").getValue() + 18.74631309;
                        var z = c.getNode("position/global-z").getValue() + 115.6574875;

                        f14.carrier_ara_63_position = geo.Coord.new().set_xyz(x, y, z);

                        var carrier_heading = c.getNode("orientation/true-heading-deg");
                        if (carrier_heading != nil)
                        {
                            # relative offset of the course to the tdz
                            # according to my measurements the Nimitz class is 8.1362114 degrees (measured 178 vs carrier 200 allowing for local magvar -13.8637886)
                            # (i.e. this value is from tuning rather than calculation)
                            f14.carrier_heading = carrier_heading.getValue();
                            f14.carrier_ara_63_heading = carrier_heading.getValue() - 8.1362114;
                        }
                        else
                        {
                            f14.carrier_ara_63_heading = 0;
                            print("Carrier heading invalid");
                        }
                        carrier_located = 1;
                        f14.tuned_carrier_name = c.getNode("name").getValue();
                        setprop("sim/model/f-14b/tuned-carrier",f14.tuned_carrier_name);
                    }
                    else
                    {
                        # tuned tacan isn't carrier.
                        f14.carrier_ara_63_heading = 0;
                    }
                }
            }

			if (type == "multiplayer" or type == "tanker" or type == "aircraft" and HaveRadarNode != nil) {
				var u = Target.new(c);
				u_ecm_signal      = 0;
				u_ecm_signal_norm = 0;
				u_radar_standby   = 0;
				u_ecm_type_num    = 0;
				if ( u.Range != nil ) {
					var u_rng = u.get_range();
					if (u_rng < range_radar2  and u.not_acting == 0 )
                    {
						u.get_deviation(our_true_heading);

						if ( u.deviation > l_az_fld  and  u.deviation < r_az_fld ) {
							append(tgts_list, u);
						} else {
							u.set_display(0);
						}
						ecm_on = EcmOn.getValue();
						# Test if target has a radar. Compute if we are illuminated. This propery used by ECM
						# over MP, should be standardized, like "ai/models/multiplayer[0]/radar/radar-standby".
						if ( ecm_on and u.get_rdr_standby() == 0) {
							rwr(u);	# TODO: override display when alert.
						}
					} else {
						u.set_display(0);
					}
				}
			}
		}
        #
        # we do this after the loop to keep the old value valid whilst figuring out the new one.
        if (!carrier_located and !we_are_bs) 
            f14.carrier_ara_63_heading = nil;

		# Summarize ECM alerts.
		if ( ecm_alert1 == 0 and ecm_alert1_last == 0 ) { EcmAlert1.setBoolValue(0) }
		if ( ecm_alert2 == 0 and ecm_alert1_last == 0 ) { EcmAlert2.setBoolValue(0) }
		ecm_alert1_last = ecm_alert1; # And avoid alert blinking at each loop.
		ecm_alert2_last = ecm_alert2;
		ecm_alert1 = 0;
		ecm_alert2 = 0;
	}


	foreach( u; tgts_list ) {
		var u_display = 0;
		var u_fading = u.get_fading() - fading_speed;


		if ( u_fading < 0 ) { u_fading = 0 }

		if (( swp_dir and swp_deg_last < u.deviation and u.deviation <= swp_deg )
			or ( ! swp_dir and swp_deg <= u.deviation and u.deviation < swp_deg_last ))
        {
			u.get_bearing();
			u.get_heading();
			var horizon = u.get_horizon( our_alt );
			var u_rng = u.get_range();

			if ( u_rng < horizon and radardist.radis(u.string, my_radarcorr))
            {

				# Compute mp position in our DDD display. (Bearing/horizontal + Range/Vertical).
				u.set_relative_bearing( ddd_screen_width / az_fld * u.deviation );
				var factor_range_radar = 0.0657 / range_radar2; # 0.0657m : length of the distance range on the DDD screen.
				u.set_ddd_draw_range_nm( factor_range_radar * u_rng );
				u_fading = 1;
				u_display = 1;

				# Compute mp position in our TID display. (PPI like display, normaly targets are displayed only when locked.)
				factor_range_radar = 0.15 / range_radar2; # 0.15m : length of the radius range on the TID screen.
				u.set_tid_draw_range_nm( factor_range_radar * u_rng );

				# Compute first digit of mp altitude rounded to nearest thousand. (labels).
				u.set_rounded_alt( rounding1000( u.get_altitude() ) / 1000 );

				# Compute closure rate in Kts.
				u.get_closure_rate();

				# Check if u = nearest echo.
				if ( tmp_nearest_rng == nil or u_rng < tmp_nearest_rng)
                {
					tmp_nearest_u = u;
					armament.contact = nearest_u;
					tmp_nearest_rng = u_rng;
				}
			}
			u.set_display(u_display);
		}
		u.set_fading(u_fading);
	}	
	swp_deg_last = swp_deg;
	swp_dir_last = swp_dir;

#    if (f14_instruments != nil)
#        cnt += f14_instruments.UPDATE_PERIOD;
#    else
        cnt += 0.05;

}

setprop("sim/mul"~"tiplay/gen"~"eric/strin"~"g[14]", "op"~"r"~"f");
var hud_nearest_tgt = func() {
	# Computes nearest_u position in the HUD
	if ( nearest_u != nil ) {
		SWTgtRange.setValue(nearest_u.get_range());
		var our_pitch = OurPitch.getValue();
		#var u_dev_deg = (90 - nearest_u.get_deviation(our_true_heading));
		#var u_elev_deg = (90 - nearest_u.get_total_elevation(our_pitch));
		var u_dev_rad = (90 - nearest_u.get_deviation(our_true_heading)) * D2R;
		var u_elev_rad = (90 - nearest_u.get_total_elevation(our_pitch)) * D2R;
		if (
			wcs_mode == "tws-auto"
			and nearest_u.get_display()
			and nearest_u.deviation > l_az_fld
			and nearest_u.deviation < r_az_fld
		) {
			var devs = f14_hud.develev_to_devroll(u_dev_rad, u_elev_rad);
			var combined_dev_deg = devs[0];
			var combined_dev_length =  devs[1];
			var clamped = devs[2];
			if ( clamped ) {
				Diamond_Blinker.blink();
			} else {
				Diamond_Blinker.cont();
			}

			# Clamp closure rate from -200 to +1,000 Kts.
			var cr = nearest_u.ClosureRate.getValue();

			if (cr < -200) { cr = 200 } elsif (cr > 1000) { cr = 1000 }

			HudTgtClosureRate.setValue(cr);
			HudTgtTDeg.setValue(combined_dev_deg);
			HudTgtTDev.setValue(combined_dev_length);
			HudTgtHDisplay.setBoolValue(1);
            HudTgtDistance.setValue(nearest_u.get_range());

			var u_target = nearest_u.type ~ "[" ~ nearest_u.index ~ "]";

            var callsign = nearest_u.Callsign.getValue();
            var model = "";

            if (nearest_u.Model != nil)
                model = nearest_u.Model.getValue();

            var target_id = "";
            if(callsign != nil)
                target_id = callsign;
            else
                target_id = u_target;
            if (model != nil and model != "")
                target_id = target_id ~ " " ~ model;

            HudTgt.setValue(target_id);
			return;
		}
	}
	SWTgtRange.setValue(0);
	HudTgtClosureRate.setValue(0);
	HudTgtTDeg.setValue(0);
	HudTgtTDev.setValue(0);
	HudTgtHDisplay.setBoolValue(0);
}
# HUD clamped target blinker
Diamond_Blinker = aircraft.light.new("sim/model/f-14b/lighting/hud-diamond-switch", [0.1, 0.1]);
setprop("sim/model/f-14b/lighting/hud-diamond-switch/enabled", 1);


# ECM: Radar Warning Receiver
rwr = func(u) {
    var u_ecm_signal      = 0;
    var u_ecm_signal_norm = 0;
    var u_radar_standby   = 0;
    var u_ecm_type_num    = 0;

	var u_name = radardist.get_aircraft_name(u.string);
	var u_maxrange = radardist.my_maxrange(u_name); # in kilometer, 0 is unknown or no radar.
	var horizon = u.get_horizon( our_alt );
	var u_rng = u.get_range();
	var u_carrier = u.check_carrier_type();
#print ("rwr ",u_name, " max_range=", u_maxrange, " rng=", u_rng, " horiz=",horizon, " carrier=",u_carrier);

	if ( u_maxrange > 0  and u_rng < horizon ) {
		# Test if we are in its radar field (hard coded 74°) or if we have a MPcarrier.
		# Compute the signal strength.
		var our_deviation_deg = deviation_normdeg(u.get_heading(), u.get_reciprocal_bearing());
		if ( our_deviation_deg < 0 ) { our_deviation_deg *= -1 }
		if ( our_deviation_deg < 37 or u_carrier == 1 ) {
			u_ecm_signal = (((-our_deviation_deg/20)+2.5)*(!u_carrier )) + (-u_rng/20) + 2.6 + (u_carrier*1.8);
			u_ecm_type_num = radardist.get_ecm_type_num(u_name);
		}
	}
	# Compute global threat situation for undiscriminant warning lights
	# and discrete (normalized) definition of threat strength.
	if ( u_ecm_signal > 1 and u_ecm_signal < 3 ) {
		EcmAlert1.setBoolValue(1);
		ecm_alert1 = 1;
		u_ecm_signal_norm = 2;
	} elsif ( u_ecm_signal >= 3 ) {
		EcmAlert2.setBoolValue(1);
		ecm_alert2 = 1;
		u_ecm_signal_norm = 1;
	}
#
# Calculate the ecm signal for each target (required for the ECM display)
    u_ecm_signal = (-u_rng/20) + 2.6;
    u_ecm_type_num = radardist.get_ecm_type_num(u_name);

	u.EcmSignal.setValue(u_ecm_signal);
	u.EcmSignalNorm.setIntValue(u_ecm_signal_norm);
	u.EcmTypeNum.setIntValue(u_ecm_type_num);
}


# Utilities.
var deviation_normdeg = func(our_heading, target_bearing) {
	var dev_norm = our_heading - target_bearing;
	while (dev_norm < -180) dev_norm += 360;
	while (dev_norm > 180) dev_norm -= 360;
	return(dev_norm);
}



var rounding1000 = func(n) {
	var a = int( n / 1000 );
	var l = ( a + 0.5 ) * 1000;
	n = (n >= l) ? ((a + 1) * 1000) : (a * 1000);
	return( n );
}

# Controls
# ---------------------------------------------------------------------
var toggle_radar_standby = func() {
	if ( pilot_lock and ! we_are_bs ) { return }
	RadarStandby.setBoolValue(!RadarStandby.getBoolValue());
}

var range_control = func(n) {
	# 1(+), -1(-), 5, 10, 20, 50, 100, 200
	if ( pilot_lock and ! we_are_bs ) { return }
	var range_radar = RangeRadar2.getValue();
	if ( n == 1 ) {
		if ( range_radar == 5 ) { range_radar = 10 }
		elsif ( range_radar == 10 ) { range_radar = 20 }
		elsif ( range_radar == 20 ) { range_radar = 50 }
		elsif ( range_radar == 50 ) { range_radar = 100 }
		else { range_radar = 200 }
	} elsif (n == -1 ) {
		if ( range_radar == 200 ) { range_radar = 100 }
		elsif ( range_radar == 100 ) { range_radar = 50 }
		elsif ( range_radar == 50 ) { range_radar = 20 }
		elsif ( range_radar == 20 ) { range_radar = 10 }
		else { range_radar = 5  }
	} elsif (n == 5 ) { range_radar = 5 }
	elsif (n == 10 ) { range_radar = 10 }
	elsif (n == 20 ) { range_radar = 20 }
	elsif (n == 50 ) { range_radar = 50 }
	elsif (n == 100 ) { range_radar = 100 }
	elsif (n == 200 ) { range_radar = 200 }
	RangeRadar2.setValue(range_radar);
}

wcs_mode_sel = func(mode) {
	if ( pilot_lock and ! we_are_bs ) { return }
	foreach (var n; props.globals.getNode("sim/model/f-14b/instrumentation/radar-awg-9/wcs-mode").getChildren()) {
		n.setBoolValue(n.getName() == mode);
		wcs_mode = mode;
	}
	if ( wcs_mode == "pulse-srch" ) {
		AzField.setValue(120);
		ddd_screen_width = 0.0844;
	} else {
		AzField.setValue(60);
		ddd_screen_width = 0.0422;
	}
}

wcs_mode_toggle = func() {
	# Temporarely toggles between the first 2 available modes.
	#foreach (var n; props.globals.getNode("sim/model/f-14b/instrumentation/radar-awg-9/wcs-mode").getChildren()) {
	if ( pilot_lock and ! we_are_bs ) { return }
	foreach (var n; WcsMode.getChildren()) {
		if ( n.getBoolValue() ) { wcs_mode = n.getName() }
	}
	if ( wcs_mode == "pulse-srch" ) {
		WcsMode.getNode("pulse-srch").setBoolValue(0);
		WcsMode.getNode("tws-auto").setBoolValue(1);
		wcs_mode = "tws-auto";
		AzField.setValue(60);
		ddd_screen_width = 0.0422;
	} elsif ( wcs_mode == "tws-auto" ) {
		WcsMode.getNode("pulse-srch").setBoolValue(1);
		WcsMode.getNode("tws-auto").setBoolValue(0);
		wcs_mode = "pulse-srch";
		AzField.setValue(120);
		ddd_screen_width = 0.0844;
	}
}

wcs_mode_update = func() {
	# Used on pilot's side when WcsMode is updated by the back-seater.
	foreach (var n; WcsMode.getChildren()) {
		if ( n.getBoolValue() ) { wcs_mode = n.getName() }
	}
	if ( WcsMode.getNode("tws-auto").getBoolValue() ) {
		wcs_mode = "tws-auto";
		AzField.setValue(60);
		ddd_screen_width = 0.0422;
	} elsif ( WcsMode.getNode("pulse-srch").getBoolValue() ) {
		wcs_mode = "pulse-srch";
		AzField.setValue(120);
		ddd_screen_width = 0.0844;
	}

}



var TRUE = 1;
var FALSE = 0;

# Target class
# ---------------------------------------------------------------------
var Target = {
	new : func (c) {
		var obj = { parents : [Target]};
		obj.RdrProp = c.getNode("radar");
		obj.Heading = c.getNode("orientation/true-heading-deg");
		obj.Alt = c.getNode("position/altitude-ft");
		obj.speed           = c.getNode("velocities/true-airspeed-kt");
		obj.AcType = c.getNode("sim/model/ac-type");
		obj.type = c.getName();
		obj.Valid = c.getNode("valid");
		obj.Callsign = c.getNode("callsign");
		obj.name            = c.getNode("name");
        obj.sign            = c.getNode("sign",1);
        obj.Model = c.getNode("model-short");
		obj.index = c.getIndex();
		obj.string = "ai/models/" ~ obj.type ~ "[" ~ obj.index ~ "]";
		obj.shortstring = obj.type ~ "[" ~ obj.index ~ "]";
#		obj.Callsign = getprop(obj.string~"/callsign");
#print("callsign ",obj.Callsign.getValue());
		
		# Remote back-seaters shall not emit and shall be invisible. FIXME: This is going to be handled by radardist ASAP.
		obj.not_acting = 0;
		var Remote_Bs_String = c.getNode("sim/multiplay/generic/string[1]");
		if ( Remote_Bs_String != nil ) {
			var rbs = Remote_Bs_String.getValue();
			if ( rbs != nil ) {
				var l = split(";", rbs);
				if ( size(l) > 0 ) {
					if ( l[0] == "f-14b-bs" ) {
						obj.not_acting = 1;
					}
				}
			}
		}

		# Local back-seater has a different radar-awg-9 folder and shall not see its pilot's aircraft.
		var bs = getprop("sim/aircraft");
		obj.InstrTgts = props.globals.getNode("sim/model/f-14b/instrumentation/radar-awg-9/targets", 1);
		if ( bs == "f-14b-bs") {
			if  ( BS_instruments.Pilot != nil ) {
				# Use a different radar-awg-9 folder.
				obj.InstrTgts = BS_instruments.Pilot.getNode("sim/model/f-14b/instrumentation/radar-awg-9/targets", 1);
				# Do not see our pilot's aircraft.
				var target_callsign = obj.Callsign.getValue();
				var p_callsign = BS_instruments.Pilot.getNode("callsign").getValue();
				if ( target_callsign == p_callsign ) {
					obj.not_acting = 1;
				}
			}
		}	

		obj.TgtsFiles = obj.InstrTgts.getNode(obj.shortstring, 1);

		obj.Range          = obj.RdrProp.getNode("range-nm");
		obj.Bearing        = obj.RdrProp.getNode("bearing-deg");
		obj.Elevation      = obj.RdrProp.getNode("elevation-deg");
		obj.TotalElevation = obj.RdrProp.getNode("total-elevation-deg", 1);
		obj.BBearing       = obj.TgtsFiles.getNode("bearing-deg", 1);
		obj.BHeading       = obj.TgtsFiles.getNode("true-heading-deg", 1);
		obj.RangeScore     = obj.TgtsFiles.getNode("range-score", 1);
		obj.RelBearing     = obj.TgtsFiles.getNode("ddd-relative-bearing", 1);
		obj.Carrier        = obj.TgtsFiles.getNode("carrier", 1);
		obj.EcmSignal      = obj.TgtsFiles.getNode("ecm-signal", 1);
		obj.EcmSignalNorm  = obj.TgtsFiles.getNode("ecm-signal-norm", 1);
		obj.EcmTypeNum     = obj.TgtsFiles.getNode("ecm_type_num", 1);
		obj.Display        = obj.TgtsFiles.getNode("display", 1);
		obj.Fading         = obj.TgtsFiles.getNode("ddd-echo-fading", 1);
		obj.DddDrawRangeNm = obj.TgtsFiles.getNode("ddd-draw-range-nm", 1);
		obj.TidDrawRangeNm = obj.TgtsFiles.getNode("tid-draw-range-nm", 1);
		obj.RoundedAlt     = obj.TgtsFiles.getNode("rounded-alt-ft", 1);
		obj.TimeLast       = obj.TgtsFiles.getNode("closure-last-time", 1);
		obj.RangeLast      = obj.TgtsFiles.getNode("closure-last-range-nm", 1);
		obj.ClosureRate    = obj.TgtsFiles.getNode("closure-rate-kts", 1);
		
		obj.pitch          = c.getNode("orientation/pitch-deg");
        obj.lat            = c.getNode("position/latitude-deg");
        obj.lon            = c.getNode("position/longitude-deg");
		obj.coord          = geo.Coord.new();
		obj.coord.set_latlon(obj.lat.getValue(), obj.lon.getValue(), obj.Alt.getValue() * FT2M);

		obj.TimeLast.setValue(ElapsedSec.getValue());
		obj.RangeLast.setValue(obj.Range.getValue());
		# Radar emission status for other uthers of radar2.nas.
		obj.RadarStandby = c.getNode("sim/multiplay/generic/int[2]");

		obj.deviation = nil;

		obj.unique = rand();
		obj.propNode = c;

		return obj;
	},
	get_heading : func {
		var n = me.Heading.getValue();
		me.BHeading.setValue(n);
		return n;	},
	get_bearing : func {
		var n = me.Bearing.getValue();
		me.BBearing.setValue(n);
		return n;
	},
	set_relative_bearing : func(n) {
		me.RelBearing.setValue(n);
	},
	get_reciprocal_bearing : func {
		return geo.normdeg(me.get_bearing() + 180);
	},
	get_deviation : func(true_heading_ref) {
		me.deviation =  - deviation_normdeg(true_heading_ref, me.get_bearing());
		return me.deviation;
	},
	get_altitude : func {
		return me.Alt.getValue();
	},
	get_total_elevation : func(own_pitch) {
		me.deviation =  - deviation_normdeg(own_pitch, me.Elevation.getValue());
		me.TotalElevation.setValue(me.deviation);
		return me.deviation;
	},
	get_range : func {
		return me.Range.getValue();
	},
	get_horizon : func(own_alt) {
		var tgt_alt = me.get_altitude();
		if ( tgt_alt != nil ) {
			if ( own_alt < 0 ) { own_alt = 0.001 }
			if ( debug.isnan(tgt_alt)) {
				print("####### nan ########");
				return(0);
			}
			if ( tgt_alt < 0 ) { tgt_alt = 0.001 }
			return radardist.radar_horizon( own_alt, tgt_alt );
		} else {
			return(0);
		}
	},
	check_carrier_type : func {
		var type = "none";
		var carrier = 0;
		if ( me.AcType != nil ) { type = me.AcType.getValue() }
		if ( type == "MP-Nimitz" or type == "MP-Eisenhower" or type == "MP-Vinson" ) { carrier = 1 }
		me.Carrier.setBoolValue(carrier);
		return carrier;
	},
	get_rdr_standby : func {
		# FIXME: this one shouldn't be part of Target
		var s = 0;
#		if ( me.RadarStandby != nil ) {
#			s = me.RadarStandby.getValue();
#			if (s == nil) { s = 0 } elsif (s != 1) { s = 0 }
#		}
		return s;
	},
	get_display : func() {
		return me.Display.getValue();
	},
	set_display : func(n) {
		me.Display.setBoolValue(n);
	},
	get_fading : func() {
		var fading = me.Fading.getValue(); 
		if ( fading == nil ) { fading = 0 }
		return fading;
	},
	set_fading : func(n) {
		me.Fading.setValue(n);
	},
	set_ddd_draw_range_nm : func(n) {
		me.DddDrawRangeNm.setValue(n);
	},
	set_hud_draw_horiz_dev : func(n) {
		me.HudDrawHorizDev.setValue(n);
	},
	set_tid_draw_range_nm : func(n) {
		me.TidDrawRangeNm.setValue(n);
	},
	set_rounded_alt : func(n) {
		me.RoundedAlt.setValue(n);
	},
	get_closure_rate : func() {
		var dt = ElapsedSec.getValue() - me.TimeLast.getValue();
		var rng = me.Range.getValue();
		var lrng = me.RangeLast.getValue();
		if ( debug.isnan(rng) or debug.isnan(lrng)) {
			print("####### get_closure_rate(): rng or lrng = nan ########");
			me.ClosureRate.setValue(0);
			me.RangeLast.setValue(0);
			return(0);
		}
		var t_distance = lrng - rng;
		var	cr = (dt > 0) ? t_distance/dt*3600 : 0;
		me.ClosureRate.setValue(cr);
		me.RangeLast.setValue(rng);
		return(cr);
	},
	getFlareNode: func () {
		# for now, no flare implementation in the F14, until the F14 can fire flares of its own.
		return nil; 
	},
	get_type: func () {
		# for now, just interpret all as air targets
		var AIR = 0;
		var MARINE = 1;
		var SURFACE = 2;
		var ORDNANCE = 3;
		return AIR;
	},
	getUnique: func () {
		# the use of this has to be investigated more, until then, just give each target its own code.
		return me.unique;
	},
	isValid: func () {
      var valid = nil;
      if (me.Valid == nil) {
        valid = FALSE;
      }
      valid = me.Valid.getValue();
      if (valid == nil) {
        valid = FALSE;
      }
      return valid;
    },
    getElevation: func() {
        var e = 0;
        e = me.Elevation.getValue();
        if(e == nil or e == 0) {
            # AI/MP has no radar properties
            var self = geo.aircraft_position();
            me.get_Coord();
            var angleInv = ja37.clamp(self.distance_to(me.coord)/self.direct_distance_to(me.coord), -1, 1);
            e = (self.alt()>me.coord.alt()?-1:1)*math.acos(angleInv)*R2D;
        }
        return e;
    },
    get_Callsign: func(){
        var n = me.Callsign.getValue();
        if(n != "" and n != nil) {
            return n;
        }
        if (me.name == nil) {
          me.name = me.getNode().getNode("name");
        }
        if (me.name == nil) {
          n = "";
        } else {
          n = me.name.getValue();
        }
        if(n != "" and n != nil) {
            return n;
        }
        n = me.sign.getValue();
        if(n != "" and n != nil) {
            return n;
        }
        return "UFO";
    },
    get_Coord: func(){
        me.coord.set_latlon(me.lat.getValue(), me.lon.getValue(), me.Alt.getValue() * FT2M);
        var TgTCoord  = geo.Coord.new(me.coord);
        return TgTCoord;
    },
    get_Longitude: func(){
        var n = me.lon.getValue();
        return n;
    },
    get_Latitude: func(){
        var n = me.lat.getValue();
        return n;
    },
    get_Pitch: func(){
        var n = me.pitch.getValue();
        return n;
    },
    isPainted: func() {
    	# Tells if this is the target that are being tracked, only used in semi-radar guided missiles.
    	return TRUE;
    },
    get_Speed: func(){
        # return true airspeed
        var n = me.speed.getValue();
        return n;
    },
	list : [],
};

# Notes:

# HUD field of view = 2 * math.atan2( 0.0764, 0.7186) * globals.R2D; # ~ 12.1375°
# where 0.071 : virtual screen half width, 0.7186 : distance eye -> screen
