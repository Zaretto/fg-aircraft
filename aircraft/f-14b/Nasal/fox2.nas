

var AcModel        = props.globals.getNode("sim/model/f-14b");
var OurHdg         = props.globals.getNode("orientation/heading-deg");
var OurRoll        = props.globals.getNode("orientation/roll-deg");
var OurPitch       = props.globals.getNode("orientation/pitch-deg");
var HudReticleDev  = props.globals.getNode("sim/model/f-14b/instrumentation/radar-awg-9/hud/reticle-total-deviation", 1);
var HudReticleDeg  = props.globals.getNode("sim/model/f-14b/instrumentation/radar-awg-9/hud/reticle-total-angle", 1);
var aim_9_model    = "Aircraft/f-14b/Models/Stores/aim-9/aim-9-";
var SwSoundOnOff   = AcModel.getNode("systems/armament/aim9/sound-on-off");
var SwSoundVol     = AcModel.getNode("systems/armament/aim9/sound-volume");
var vol_search     = 0.12;
var vol_weak_track = 0.20;
var vol_track      = 0.45;

var TRUE = 1;
var FALSE = 0;

var g_fps        = 9.80665 * M2FT;
var slugs_to_lbs = 32.1740485564;

var clamp = func(v, min, max) { v < min ? min : v > max ? max : v }


var AIM9 = {
	new : func (p) {
		var m = { parents : [AIM9]};
		# Args: p = Pylon.

		m.status            = 0; # -1 = stand-by, 0 = searching, 1 = locked, 2 = fired.
		m.free              = 0; # 0 = status fired with lock, 1 = status fired but having lost lock.

		m.prop              = AcModel.getNode("systems/armament/aim9/").getChild("msl", 0 , 1);
		m.PylonIndex        = m.prop.getNode("pylon-index", 1).setValue(p);
		m.ID                = p;
		m.pylon_prop        = props.globals.getNode("sim/model/f-14b/systems/external-loads/").getChild("station", p);
		m.Tgt               = nil;
		m.TgtValid          = nil;
		m.TgtLon_prop       = nil;
		m.TgtLat_prop       = nil;
		m.TgtAlt_prop       = nil;
		m.TgtHdg_prop       = nil;
		m.TgtSpeed_prop     = nil;
		m.TgtPitch_prop     = nil;
		m.update_track_time = 0;
		m.seeker_dev_e      = 0; # Seeker elevation, deg.
		m.seeker_dev_h      = 0; # Seeker horizon, deg.
		m.curr_tgt_e        = 0;
		m.curr_tgt_h        = 0;
		m.init_tgt_e        = 0;
		m.init_tgt_h        = 0;
		m.target_dev_e      = 0; # Target elevation, deg.
		m.target_dev_h      = 0; # Target horizon, deg.
		m.track_signal_e    = 0; # Seeker deviation change to keep constant angle (proportional navigation),
		m.track_signal_h    = 0; #   this is directly used as input signal for the steering command.
		m.t_coord           = geo.Coord.new().set_latlon(0, 0, 0);
		m.last_t_coord      = m.t_coord;
		m.before_last_t_coord = nil;
		#m.next_t_coord      = m.t_coord;
		m.direct_dist_m     = nil;

		# AIM-9L specs:
		m.aim9_fov_diam     = getprop("sim/model/f-14b/systems/armament/aim9/fov-deg");
		m.aim9_fov          = m.aim9_fov_diam / 2;
		m.max_detect_rng    = getprop("sim/model/f-14b/systems/armament/aim9/max-detection-rng-nm");
		m.max_seeker_dev    = getprop("sim/model/f-14b/systems/armament/aim9/track-max-deg") / 2;
		m.force_lbs_1       = getprop("sim/model/f-14b/systems/armament/aim9/thrust-lbs-stage-1");
		m.force_lbs_2       = getprop("sim/model/f-14b/systems/armament/aim9/thrust-lbs-stage-2");
		m.stage_1_duration  = getprop("sim/model/f-14b/systems/armament/aim9/stage-1-duration-sec");
		m.stage_2_duration  = getprop("sim/model/f-14b/systems/armament/aim9/stage-2-duration-sec");
		m.weight_launch_lbs = getprop("sim/model/f-14b/systems/armament/aim9/weight-launch-lbs");
		m.weight_whead_lbs  = getprop("sim/model/f-14b/systems/armament/aim9/weight-warhead-lbs");
		m.Cd_base           = getprop("sim/model/f-14b/systems/armament/aim9/drag-coeff");
		m.eda               = getprop("sim/model/f-14b/systems/armament/aim9/drag-area");
		m.max_g             = getprop("sim/model/f-14b/systems/armament/aim9/max-g");
		m.selfdestruct_time = getprop("sim/model/f-14b/systems/armament/aim9/self-destruct-time-sec");
		m.angular_speed     = getprop("sim/model/f-14b/systems/armament/aim9/seeker-angular-speed-dps");
        m.loft_alt          = getprop("sim/model/f-14b/systems/armament/aim9/loft-altitude");
        m.min_speed_for_guiding = getprop("sim/model/f-14b/systems/armament/aim9/min-speed-for-guiding-mach");
        m.arm_time          = getprop("sim/model/f-14b/systems/armament/aim9/arming-time-sec");
        m.rail              = getprop("sim/model/f-14b/systems/armament/aim9/rail");

		# Find the next index for "models/model" and create property node.
		# Find the next index for "ai/models/aim-9" and create property node.
		# (M. Franz, see Nasal/tanker.nas)
		var n = props.globals.getNode("models", 1);
		for (var i = 0; 1; i += 1)
			if (n.getChild("model", i, 0) == nil)
				break;
		m.model = n.getChild("model", i, 1);
		var n = props.globals.getNode("ai/models", 1);
		for (var i = 0; 1; i += 1)
			if (n.getChild("aim-9", i, 0) == nil)
				break;
		m.ai = n.getChild("aim-9", i, 1);

		m.ai.getNode("valid", 1).setBoolValue(1);
		var id_model = aim_9_model ~ m.ID ~ ".xml";
		m.model.getNode("path", 1).setValue(id_model);
		m.life_time = 0;

		# Create the AI position and orientation properties.
		m.latN   = m.ai.getNode("position/latitude-deg", 1);
		m.lonN   = m.ai.getNode("position/longitude-deg", 1);
		m.altN   = m.ai.getNode("position/altitude-ft", 1);
		m.hdgN   = m.ai.getNode("orientation/true-heading-deg", 1);
		m.pitchN = m.ai.getNode("orientation/pitch-deg", 1);
		m.rollN  = m.ai.getNode("orientation/roll-deg", 1);

		m.ac      = nil;
		m.coord   = geo.Coord.new().set_latlon(0, 0, 0);
		m.last_coord = nil;
		m.before_last_coord = nil;
		m.s_down  = nil;
		m.s_east  = nil;
		m.s_north = nil;
		m.alt     = nil;
		m.pitch   = nil;
		m.hdg     = nil;

		m.density_alt_diff = 0;
		m.max_g_current = m.max_g;
		m.last_deviation_e = nil;
		m.last_deviation_h = nil;
		m.last_track_e = 0;
		m.last_track_h = 0;

		#pro nav:
		m.dist_last = nil;
		m.dist_direct_last = nil;
		m.last_t_course = nil;
		m.last_t_elev_deg = nil;
		m.last_cruise_or_loft = 0;
		m.old_speed_horz_fps = nil;
		m.old_speed_fps = 0;
		m.last_t_norm_speed = nil;
		m.last_t_elev_norm_speed = nil;
		m.last_dt = 0;

		m.g = 0;

		m.dive_token = FALSE;

		#rail
		m.drop_time = 0;
		m.rail_dist_m = 2.667;#16S210 AIM-9 Missile Launcher
		m.rail_passed = FALSE;
		m.x = 0;
		m.y = 0;
		m.z = 0;
		m.rail_pos = 0;
		m.rail_speed_into_wind = 0;

		SwSoundOnOff.setValue(1);

		settimer(func { SwSoundVol.setValue(vol_search); m.search() }, 1);
		return AIM9.active[m.ID] = m;

	},
	del: func {
		me.model.remove();
		me.ai.remove();
		delete(AIM9.active, me.ID);
	},
	# get Coord from body position. x,y,z must be in meters.
	getGPS: func(x, y, z) {
		var ac_roll = getprop("orientation/roll-deg");
		var ac_pitch = getprop("orientation/pitch-deg");
		var ac_hdg   = getprop("orientation/heading-deg");

		me.ac = geo.aircraft_position();

		var in = [0,0,0];
		var trans = [[0,0,0],[0,0,0],[0,0,0]];
		var out = [0,0,0];

		in[0] =  -x * M2FT;
		in[1] =  y * M2FT;
		in[2] =  z * M2FT;
		# Pre-process trig functions:
		var cosRx = math.cos(-ac_roll * D2R);
		var sinRx = math.sin(-ac_roll * D2R);
		var cosRy = math.cos(-ac_pitch * D2R);
		var sinRy = math.sin(-ac_pitch * D2R);
		var cosRz = math.cos(ac_hdg * D2R);
		var sinRz = math.sin(ac_hdg * D2R);
		# Set up the transform matrix:
		trans[0][0] =  cosRy * cosRz;
		trans[0][1] =  -1 * cosRx * sinRz + sinRx * sinRy * cosRz ;
		trans[0][2] =  sinRx * sinRz + cosRx * sinRy * cosRz;
		trans[1][0] =  cosRy * sinRz;
		trans[1][1] =  cosRx * cosRz + sinRx * sinRy * sinRz;
		trans[1][2] =  -1 * sinRx * cosRx + cosRx * sinRy * sinRz;
		trans[2][0] =  -1 * sinRy;
		trans[2][1] =  sinRx * cosRy;
		trans[2][2] =  cosRx * cosRy;
		# Multiply the input and transform matrices:
		out[0] = in[0] * trans[0][0] + in[1] * trans[0][1] + in[2] * trans[0][2];
		out[1] = in[0] * trans[1][0] + in[1] * trans[1][1] + in[2] * trans[1][2];
		out[2] = in[0] * trans[2][0] + in[1] * trans[2][1] + in[2] * trans[2][2];
		# Convert ft to degrees of latitude:
		out[0] = out[0] / (366468.96 - 3717.12 * math.cos(me.ac.lat() * D2R));
		# Convert ft to degrees of longitude:
		out[1] = out[1] / (365228.16 * math.cos(me.ac.lat() * D2R));
		# Set submodel initial position:
		var alat = me.ac.lat() + out[0];
		var alon = me.ac.lon() + out[1];
		var aalt = (me.ac.alt() * M2FT) + out[2];
		
		var c = geo.Coord.new();
		c.set_latlon(alat, alon, aalt * FT2M);

		return c;
	},
	release: func() {
		me.status = 2;
		me.animation_flags_props();

		# Get the A/C position and orientation values.
		me.ac = geo.aircraft_position();
		var ac_roll  = getprop("orientation/roll-deg");
		var ac_pitch = getprop("orientation/pitch-deg");
		var ac_hdg   = getprop("orientation/heading-deg");

		# Compute missile initial position relative to A/C center,
		# following Vivian's code in AIModel/submodel.cxx .

		me.x = me.pylon_prop.getNode("offsets/x-m").getValue();
		me.y = me.pylon_prop.getNode("offsets/y-m").getValue();
		me.z = me.pylon_prop.getNode("offsets/z-m").getValue();
		
		var init_coord = me.getGPS(me.x, me.y, me.z);

		# Set submodel initial position:
		var alat = init_coord.lat();
		var alon = init_coord.lon();
		var aalt = init_coord.alt() * M2FT;
		me.latN.setDoubleValue(alat);
		me.lonN.setDoubleValue(alon);
		me.altN.setDoubleValue(aalt);
		me.hdgN.setDoubleValue(ac_hdg);
		if (me.rail == FALSE) {
			# align into wind (commented out since heavy wind make missiles lose sight of target.)
			var alpha = getprop("orientation/alpha-deg");
			var beta = getprop("orientation/side-slip-deg");# positive is air from right

			var alpha_diff = alpha * math.cos(ac_roll*D2R) * ((ac_roll > 90 or ac_roll < -90)?-1:1) + beta * math.sin(ac_roll*D2R);
			#alpha_diff = alpha > 0?alpha_diff:0;# not using alpha if its negative to avoid missile flying through aircraft.
			#ac_pitch = ac_pitch - alpha_diff;
			
			var beta_diff = beta * math.cos(ac_roll*D2R) * ((ac_roll > 90 or ac_roll < -90)?-1:1) - alpha * math.sin(ac_roll*D2R);
			#ac_hdg = ac_hdg + beta_diff;

			# drop distance in time
			me.drop_time = math.sqrt(2*7/g_fps);# time to fall 7 ft to clear aircraft
		}
		me.pitchN.setDoubleValue(ac_pitch);
		me.rollN.setDoubleValue(ac_roll);
		#print("roll "~ac_roll~" on "~me.rollN.getPath());
		me.coord.set_latlon(alat, alon, aalt * FT2M);

		me.model.getNode("latitude-deg-prop", 1).setValue(me.latN.getPath());
		me.model.getNode("longitude-deg-prop", 1).setValue(me.lonN.getPath());
		me.model.getNode("elevation-ft-prop", 1).setValue(me.altN.getPath());
		me.model.getNode("heading-deg-prop", 1).setValue(me.hdgN.getPath());
		me.model.getNode("pitch-deg-prop", 1).setValue(me.pitchN.getPath());
		me.model.getNode("roll-deg-prop", 1).setValue(me.rollN.getPath());
		me.model.getNode("load", 1);

		# Get initial velocity vector (aircraft):
		me.s_down = getprop("velocities/speed-down-fps");
		me.s_east = getprop("velocities/speed-east-fps");
		me.s_north = getprop("velocities/speed-north-fps");
		if (me.rail == TRUE) {
			var u = getprop("velocities/uBody-fps");# wind from nose
			me.rail_speed_into_wind = u;
		}

		me.alt = aalt;
		me.pitch = ac_pitch;
		me.hdg = ac_hdg;

		me.density_alt_diff = getprop("fdm/jsbsim/atmosphere/density-altitude") - aalt;

		me.smoke_prop.setBoolValue(1);
		SwSoundVol.setValue(0);
		settimer(func { HudReticleDeg.setValue(0) }, 2);
		interpolate(HudReticleDev, 0, 2);
		me.update();

	},

	drag: func (mach) {
		# Nikolai V. Chr.: Made the drag calc more in line with big missiles as opposed to small bullets.
		# 
		# The old equations were based on curves for a conventional shell/bullet (no boat-tail),
		# and derived from Davic Culps code in AIBallistic.
		var Cd = 0;
		if (mach < 0.7) {
			Cd = (0.0125 * mach + 0.20) * 5 * me.Cd_base;
		} elsif (mach < 1.2 ) {
			Cd = (0.3742 * math.pow(mach, 2) - 0.252 * mach + 0.0021 + 0.2 ) * 5 * me.Cd_base;
		} else {
			Cd = (0.2965 * math.pow(mach, -1.1506) + 0.2) * 5 * me.Cd_base;
		}

		return Cd;
	},

    energyBleed: func (gForce, altitude, dt) {
        # Bleed of energy from pulling Gs.
        # This is very inaccurate, but better than nothing.
        #
        # First we get the speedloss including loss due to normal drag:
        var b300 = me.bleed32800at0g(dt);
        var b325 = me.bleed32800at25g(dt)-b300;
        #
        # We then subtract the normal drag.
        var b000 = me.bleed0at0g(dt);
        var b025 = me.bleed0at25g(dt)-b000;
        b300 = 0;
        b000 = 0;
        #
        # We now find what the speedloss will be at sealevel and 32800 ft.
        var speedLoss32800 = b300 + ((gForce-0)/(25-0))*(b325 - b300);
        var speedLoss0 = b000 + ((gForce-0)/(25-0))*(b025 - b000);
        #
        # We then inter/extra-polate that to the currect density-altitude.
        var speedLoss = speedLoss0 + ((altitude-0)/(32800-0))*(speedLoss32800-speedLoss0);
        #
        # For good measure the result is clamped to below zero.
        return clamp(speedLoss, -100000, 0);
    },

	bleed32800at0g: func (dt) {
		var loss_fps = 0 + ((dt - 0)/(15 - 0))*(-330 - 0);
		return loss_fps*M2FT;
	},

	bleed32800at25g: func (dt) {
		var loss_fps = 0 + ((dt - 0)/(3.5 - 0))*(-240 - 0);
		return loss_fps*M2FT;
	},

	bleed0at0g: func (dt) {
		var loss_fps = 0 + ((dt - 0)/(22 - 0))*(-950 - 0);
		return loss_fps*M2FT;
	},

	bleed0at25g: func (dt) {
		var loss_fps = 0 + ((dt - 0)/(7 - 0))*(-750 - 0);
		return loss_fps*M2FT;
	},

	update: func {
		var dt = getprop("sim/time/delta-sec");
		var init_launch = 0;
		if ( me.life_time > 0 ) { init_launch = 1 }
		me.life_time += dt;
		# record coords so we can give the latest nearest position for impact.
		me.before_last_coord = geo.Coord.new(me.last_coord);
		me.last_coord = geo.Coord.new(me.coord);


		#### Calculate speed vector before steering corrections.

		# Rocket thrust. If dropped, then ignited after fall time of what is the equivalent of 7ft.
		# If the rocket is 2 stage, then ignite the second stage when 1st has burned out.
		var f_lbs = 0;# pounds force (lbf)
		if (me.life_time > me.drop_time) {
			f_lbs = me.force_lbs_1;
		}
		if (me.life_time > me.stage_1_duration + me.drop_time) {
			f_lbs = me.force_lbs_2;
		}
		if (me.life_time > (me.drop_time + me.stage_1_duration + me.stage_2_duration)) {
			f_lbs = 0;
		}
		if (f_lbs < 1) {
			me.smoke_prop.setBoolValue(0);
		} else {
			me.smoke_prop.setBoolValue(1);
		}

		# Kill the AI after a while.
		#if (me.life_time > 50) { return me.del(); }

		# Get total speed.
		var d_east_ft  = me.s_east * dt;
		var d_north_ft = me.s_north * dt;
		var d_down_ft  = me.s_down * dt;
		var pitch_deg  = me.pitch;
		var hdg_deg    = me.hdg;
		var dist_h_ft  = math.sqrt((d_east_ft*d_east_ft)+(d_north_ft*d_north_ft));
		var total_s_ft = math.sqrt((dist_h_ft*dist_h_ft)+(d_down_ft*d_down_ft));

		if (me.rail == TRUE and me.rail_passed == FALSE) {
			var u = getprop("velocities/uBody-fps");# wind from nose
			var v = getprop("velocities/vBody-fps");# wind from side
			var w = getprop("velocities/wBody-fps");# wind from below

			pitch_deg = getprop("orientation/pitch-deg");
			hdg_deg = getprop("orientation/heading-deg");

			var speed_on_rail = clamp(me.rail_speed_into_wind - u, 0, 1000000);
			var movement_on_rail = speed_on_rail * dt;
			
			me.rail_pos = me.rail_pos + movement_on_rail;
			me.x = me.x - (movement_on_rail * FT2M);# negative cause positive is rear in body coordinates
			#print("rail pos "~(me.rail_pos*FT2M));
		}

		# Get air density and speed of sound (fps):
		var rs = environment.rho_sndspeed(me.altN.getValue() + me.density_alt_diff);
		var rho = rs[0];
		var sound_fps = rs[1];

		# density for 0ft and 50kft:
		#print("0:"~rho_sndspeed(0)[0]);       = 0.0023769
		#print("50k:"~rho_sndspeed(50000)[0]); = 0.00036159
		#
		# a aim-9j can do 22G at sealevel, 13G at 50Kft
		# 13G = 22G * 0.5909
		#
		# extra/inter-polation:
		# f(x) = y1 + ((x - x1) / (x2 - x1)) * (y2 - y1)
		# calculate its performance at current air density:
		me.max_g_current = me.max_g+((rho-0.0023769)/(0.00036159-0.0023769))*(me.max_g*0.5909-me.max_g);
		
		var old_speed_fps = total_s_ft / dt;
		me.old_speed_horz_fps = dist_h_ft / dt;
		me.old_speed_fps = old_speed_fps;
		
		if (me.rail == TRUE and me.rail_passed == FALSE) {
			# if missile is still on rail, we replace the speed, with the speed into the wind from nose on the rail.
			old_speed_fps = me.rail_speed_into_wind;
		}

		# Adjust Cd by Mach number. The equations are based on curves
		# for a conventional shell/bullet (no boat-tail).
		me.speed_m = old_speed_fps / sound_fps;

		var Cd = me.drag(me.speed_m);

		# Add drag to the total speed using Standard Atmosphere (15C sealevel temperature);
		# rho is adjusted for altitude in environment.rho_sndspeed(altitude),
		# Acceleration = thrust/mass - drag/mass;
		var mass = me.weight_launch_lbs / slugs_to_lbs;
		
		var acc = f_lbs / mass;

		var q = 0.5 * rho * old_speed_fps * old_speed_fps;# dynamic pressure
		var drag_acc = (Cd * q * me.eda) / mass;
		var speed_fps = old_speed_fps - drag_acc*dt + acc*dt;

		if (me.last_dt != 0) {
			speed_fps = speed_fps + me.energyBleed(me.g, me.altN.getValue(), me.last_dt);
		}

		# Get target position.
		me.t_coord.set_latlon(me.TgtLat_prop.getValue(), me.TgtLon_prop.getValue(), me.TgtAlt_prop.getValue() * FT2M);
		
		#### Guidance.

		if ( me.status == 2 and me.free == 0 and me.life_time > me.drop_time) {
			if (me.rail == FALSE or me.rail_passed == TRUE)
            { 
                me.update_track(dt);
            }
            if(me.speed_m < me.min_speed_for_guiding) {
				# it doesn't guide at lower speeds

				me.track_signal_e = 0;
				me.track_signal_h = 0;

				print("Not guiding (too low speed)");
			}
			if (init_launch == 0 ) {
				# Use the rail or a/c pitch for the first frame.
				pitch_deg = getprop("orientation/pitch-deg");
			} else {
				#Here will be set the max angle of pitch and the max angle of heading to avoid G overload
                var myG = steering_speed_G(me.track_signal_e, me.track_signal_h, (total_s_ft / dt), dt);
                if(me.max_g_current < myG)
                {
                    var MyCoef = max_G_Rotation(me.track_signal_e, me.track_signal_h, (total_s_ft / dt), dt, me.max_g_current);
                    me.track_signal_e =  me.track_signal_e * MyCoef;
                    me.track_signal_h =  me.track_signal_h * MyCoef;
                    myG = steering_speed_G(me.track_signal_e, me.track_signal_h, (total_s_ft / dt), dt);
                    print(sprintf("Limiting to %.1f G", myG));
                }
                pitch_deg += me.track_signal_e;
                hdg_deg += me.track_signal_h;
                me.last_track_e = me.track_signal_e;
				me.last_track_h = me.track_signal_h;

                #print("Still Tracking : Elevation ",me.track_signal_e,"Heading ",me.track_signal_h," Gload : ", myG );
			}
		}

		# Break down total speed to North, East and Down components.
		var speed_down_fps = -math.sin(pitch_deg * D2R) * speed_fps;
		var speed_horizontal_fps = math.cos(pitch_deg * D2R) * speed_fps;
		var speed_north_fps = math.cos(hdg_deg * D2R) * speed_horizontal_fps;
		var speed_east_fps = math.sin(hdg_deg * D2R) * speed_horizontal_fps;

		if (me.rail == TRUE and me.rail_passed == FALSE) {
            # missile still on rail, lets calculate its speed relative to the wind coming in from the aircraft nose.
            me.rail_speed_into_wind = me.rail_speed_into_wind + (speed_fps - old_speed_fps);
        }

		# Add gravity to the vertical speed (no ground interaction yet).
		#speed_down_fps += gravity_fps;
		
		# Calculate altitude and elevation velocity vector (no incidence here).
		var alt_ft = me.altN.getValue() - ((speed_down_fps + g_fps*dt) * dt);
		#pitch_deg = math.atan2( speed_down_fps, speed_horizontal_fps ) * R2D;
		
		# this is commented, cause the missile just falls due to gravity, it doesn't pitch
		# a real missile would pitch ofc. but then have to calc how fuel affects CoG and its inertia
		# 
		#me.pitch = pitch_deg;
		#pitch_deg = me.pitch;
		

		# Get horizontal distance and set position and orientation.
		var dist_h_m = speed_horizontal_fps * dt * FT2M;

		if (me.rail == FALSE or me.rail_passed == TRUE) {
			# misssile not on rail, lets move it to next waypoint
			me.coord.apply_course_distance(hdg_deg, dist_h_m);
			me.coord.set_alt(alt_ft * FT2M);
		} else {
			# missile on rail, lets move it on the rail
			speed_fps = me.rail_speed_into_wind;
			me.coord = me.getGPS(me.x, me.y, me.z);
			alt_ft = me.coord.alt() * M2FT;
		}

		me.latN.setDoubleValue(me.coord.lat());
		me.lonN.setDoubleValue(me.coord.lon());
		me.altN.setDoubleValue(alt_ft);
		me.pitchN.setDoubleValue(pitch_deg);
		me.hdgN.setDoubleValue(hdg_deg);


		#### Proximity detection.

		if ( me.status == 2 and (me.rail == FALSE or me.rail_passed == TRUE)) {
			var v = me.poximity_detection();
			if ( ! v ) {
				# We exploded, but need a few more secs to spawn the explosion animation.
				settimer(func { me.del(); }, 4 );
				return;
			}			

			#### If not exploded, check if the missile can keep the lock.
 			if ( me.free == 0 ) {
				me.g = steering_speed_G(me.track_signal_e, me.track_signal_h, (total_s_ft / dt), dt);
				if ( me.g > me.max_g_current ) {
					# Target unreachable, fly free.
					me.free = 1;
				}
			} else {
				me.g = 0;
			}
		} else {
			me.g = 0;
		}

		me.before_last_t_coord = geo.Coord.new(me.last_t_coord);
		me.last_t_coord = geo.Coord.new(me.t_coord);

		# record the velocities for the next loop.
		me.s_north = speed_north_fps;
		me.s_east = speed_east_fps;
		me.s_down = speed_down_fps;
		me.alt = alt_ft;
		me.pitch = pitch_deg;
		me.hdg = hdg_deg;

		if (me.rail_pos > me.rail_dist_m * M2FT) {
			me.rail_passed = TRUE;
			#print("rail passed");
		}
		me.last_dt = dt;

		settimer(func me.update(), 0);
		
	},






	update_track: func(dt_) {
		if ( me.Tgt == nil ) { return(1); }
		if (me.status == 0) {
			# Status = searching.
			me.reset_seeker();
			SwSoundVol.setValue(vol_search);
			settimer(func me.search(), 0.1);
			return(1);
		}
		if ( me.status == -1 ) {
			# Status = stand-by.
			me.reset_seeker();
			SwSoundVol.setValue(0);
			return(1);
		}
		if (!me.Tgt.Valid.getValue()) {
			# Lost of lock due to target disapearing:
			# return to search mode.
			me.status = 0;
			me.reset_seeker();
			SwSoundVol.setValue(vol_search);
			settimer(func me.search(), 0.1);
			return(1);
		}
		# Time interval since lock time or last track loop.
		var time = props.globals.getNode("/sim/time/elapsed-sec", 1).getValue();
		var dt = time - me.update_track_time;
		me.update_track_time = time;
		var last_tgt_e = me.curr_tgt_e;
		var last_tgt_h = me.curr_tgt_h;
		if (me.status == 1) {		
			# Status = locked. Get target position relative to our aircraft.
			me.curr_tgt_e = me.Tgt.get_total_elevation(OurPitch.getValue());
			me.curr_tgt_h = me.Tgt.get_deviation(OurHdg.getValue());
		} elsif (dt_ != nil) {
			# Status = launched. Compute target position relative to seeker head.

			# Get target position.
			var t_alt = me.t_coord.alt()*M2FT;

			# Calculate current target elevation and azimut deviation.
			var t_dist_m = me.coord.distance_to(me.t_coord);
			var dist_curr = t_dist_m;
			var dist_curr_direct = me.coord.direct_distance_to(me.t_coord);
			var t_alt_delta_m = (t_alt - me.alt) * FT2M;
			var t_elev_deg =  math.atan2( t_alt_delta_m, t_dist_m ) * R2D;
			me.curr_tgt_e = t_elev_deg - me.pitch;
			#var (t_course, dst) = courseAndDistance(me.coord, me.t_coord);
			var	t_course = me.coord.course_to(me.t_coord);
			#var t_course = me.coord.course_to(me.t_coord);
			me.curr_tgt_h = t_course - me.hdg;

			# Compute gain to reduce target deviation to match an optimum 3 deg
			# This augments steering by an additional 10 deg per second during
			# the trajectory first 2 seconds.
			# Then, keep track of deviations at the end of these two initial 2 seconds.
			var e_gain = 1;
			var h_gain = 1;
			if ( me.life_time < 2 ) {
				if (me.curr_tgt_e > 3 or me.curr_tgt_e < - 3) {
					#e_gain = 1 + (0.1 * dt);
				}
				if (me.curr_tgt_h > 3 or me.curr_tgt_h < - 3) {
					#h_gain = 1 + (0.1 * dt);
				}
				me.init_tgt_e = last_tgt_e;
				me.init_tgt_h = last_tgt_h;			
			}

			while(me.curr_tgt_h < -180) {
				me.curr_tgt_h += 360;
			}
			while(me.curr_tgt_h > 180) {
				me.curr_tgt_h -= 360;
			}

			if (me.curr_tgt_e > me.max_seeker_dev or me.curr_tgt_e < (-1 * me.max_seeker_dev)
				  or me.curr_tgt_h > me.max_seeker_dev or me.curr_tgt_h < (-1 * me.max_seeker_dev)) {
				# target is not in missile seeker view anymore
				print("Target is not in missile seeker view anymore");
				me.free = 1;
				e_gain = 0;
				h_gain = 0;
			}
			

			var dev_e = 0;#me.curr_tgt_e;
			var dev_h = 0;#me.curr_tgt_h;

			#print(sprintf("curr: elev=%.1f", dev_e)~sprintf(" head=%.1f", dev_h));
			if (me.last_deviation_e != nil) {
				# its not our first seeker head move
				# calculate if the seeker can keep up with the angular change of the target

				# missile own movement is subtracted from this change due to seeker being on gyroscope
				
				var dve_dist = me.curr_tgt_e - me.last_deviation_e + me.last_track_e;
				var dvh_dist = me.curr_tgt_h - me.last_deviation_h + me.last_track_h;
				var deviation_per_sec = math.sqrt(dve_dist*dve_dist+dvh_dist*dvh_dist)/dt_;

				if (deviation_per_sec > me.angular_speed) {
					#print(sprintf("last-elev=%.1f", me.last_deviation_e)~sprintf(" last-elev-adj=%.1f", me.last_track_e));
					#print(sprintf("last-head=%.1f", me.last_deviation_h)~sprintf(" last-head-adj=%.1f", me.last_track_h));
					# lost lock due to angular speed limit
					print(sprintf("%.1f deg/s too big angular change for seeker head.", deviation_per_sec));
					#print(dt);
					me.free = 1;
					e_gain = 0;
					h_gain = 0;
				}
			}

			me.last_deviation_e = me.curr_tgt_e;
			me.last_deviation_h = me.curr_tgt_h;

			var loft_angle = 45;
			var loft_minimum = 10;# miles
			var cruise_minimum = 10;# miles
			var cruise_or_loft = 0;
			if ( t_dist_m * M2NM > loft_minimum
				 and t_elev_deg < loft_angle #and t_elev_deg > -7.5
				 and me.dive_token == FALSE) {
				# stage 1 lofting: due to target is more than 10 miles out and we havent reached 
				# our desired cruising alt, and the elevation to target is less than lofting angle.
				# The -10 limit, is so the seeker don't lose track of target when lofting.
				if (me.coord.alt() * M2FT < me.loft_alt) {
					dev_e = -me.pitch + loft_angle;
					#print(sprintf("Lofting %.1f degs, dev is %.1f", loft_angle, dev_e));
				} else {
					me.dive_token = TRUE;
				}
				cruise_or_loft = 1;
				#print(sprintf("Lofting %.1f degs", loft_angle));
			} elsif (t_elev_deg < 0 and me.life_time < me.stage_1_duration+me.stage_2_duration+me.drop_time and t_dist_m * M2NM > cruise_minimum) {
				# stage 1/2 cruising: keeping altitude since target is below and more than 5 miles out
				
				var ratio = (g_fps * dt_)/me.old_speed_fps;
                var attitude = 0;

                if (ratio < 1 and ratio > -1) {
                    attitude = math.asin(ratio)*R2D;
                }

				dev_e = -me.pitch + attitude;
				cruise_or_loft = 1;
				#print("Cruising");
			} elsif (me.last_cruise_or_loft == TRUE and math.abs(me.curr_tgt_e) > 2.5) {
				# after cruising, point the missile in the general direction of the target, before APN starts guiding.
				dev_e = me.curr_tgt_e;
				cruise_or_loft = TRUE;
			}

			###########################################
			### augmented proportional navigation   ###
			###########################################
			if (h_gain != 0 and me.dist_last != nil and me.last_dt != 0) {
					var horz_closing_rate_fps = (me.dist_last - dist_curr)*M2FT/me.last_dt;
					var proportionality_constant = 3;
					var c_dv = t_course-me.last_t_course;
					while(c_dv < -180) {
						c_dv += 360;
					}
					while(c_dv > 180) {
						c_dv -= 360;
					}
					var line_of_sight_rate_rps = D2R*c_dv/dt_;

					#print(sprintf("LOS-rate=%.2f rad/s - closing-rate=%.1f ft/s",line_of_sight_rate_rps,closing_rate_fps));

					# calculate target acc as normal to LOS line:
					var t_heading        = me.TgtHdg_prop.getValue();
					var t_pitch          = me.TgtPitch_prop.getValue();
					var t_speed          = me.TgtSpeed_prop.getValue()*KT2FPS;#true airspeed
					var t_horz_speed     = t_speed - math.abs(math.sin(t_pitch*D2R)*t_speed);
					var t_LOS_norm_head  = t_course + 90;
					var t_LOS_norm_speed = math.cos((t_LOS_norm_head - t_heading)*D2R)*t_horz_speed;

					if (me.last_t_norm_speed == nil) {
						me.last_t_norm_speed = t_LOS_norm_speed;
					}

					var t_LOS_norm_acc   = (t_LOS_norm_speed - me.last_t_norm_speed)/dt_;

					me.last_t_norm_speed = t_LOS_norm_speed;

					# acceleration perpendicular to instantaneous line of sight in feet/sec^2
					var acc_sideways_ftps2 = proportionality_constant*line_of_sight_rate_rps*horz_closing_rate_fps+proportionality_constant*t_LOS_norm_acc/2;

					#print(sprintf("commanded-perpendicular-acceleration=%.1f ft/s^2", acc_sideways_ftps2));

					# now translate that sideways acc to an angle:
					var velocity_vector_length_fps = me.old_speed_horz_fps;
					var commanded_sideways_vector_length_fps = acc_sideways_ftps2*dt_;
					dev_h = math.atan2(commanded_sideways_vector_length_fps, velocity_vector_length_fps)*R2D;
					
					#print(sprintf("horz leading by %.1f deg, commanding %.1f deg", me.curr_tgt_h, dev_h));

					if (cruise_or_loft == 0) {
						var vert_closing_rate_fps = (me.dist_direct_last - dist_curr_direct)*M2FT/me.last_dt;
						var line_of_sight_rate_up_rps = D2R*(t_elev_deg-me.last_t_elev_deg)/dt_;#((me.curr_tgt_e-me.last_tgt_e)*D2R)/dt;
						# calculate target acc as normal to LOS line: (up acc is positive)
						var t_approach_bearing             = t_course + 180;
						var t_horz_speed_away_from_missile = -math.cos((t_approach_bearing - t_heading)*D2R)* t_horz_speed;
						var t_horz_comp_speed              = math.cos((90+t_elev_deg)*D2R)*t_horz_speed_away_from_missile;
						var t_vert_comp_speed              = math.sin(t_pitch*D2R)*t_speed*math.cos(t_elev_deg*D2R);
						var t_LOS_elev_norm_speed          = t_horz_comp_speed + t_vert_comp_speed;

						if (me.last_t_elev_norm_speed == nil) {
							me.last_t_elev_norm_speed = t_LOS_elev_norm_speed;
						}

						var t_LOS_elev_norm_acc            = (t_LOS_elev_norm_speed - me.last_t_elev_norm_speed)/dt_;
						me.last_t_elev_norm_speed          = t_LOS_elev_norm_speed;

						var acc_upwards_ftps2 = proportionality_constant*line_of_sight_rate_up_rps*vert_closing_rate_fps+proportionality_constant*t_LOS_elev_norm_acc/2;
						velocity_vector_length_fps = me.old_speed_fps;
						var commanded_upwards_vector_length_fps = acc_upwards_ftps2*dt_;
						dev_e = math.atan2(commanded_upwards_vector_length_fps, velocity_vector_length_fps)*R2D;
						#print(sprintf("vert leading by %.1f deg", me.curr_tgt_e));
					}
			}
			me.dist_last = dist_curr;
			me.dist_direct_last = dist_curr_direct;
			me.last_t_course = t_course;
			me.last_t_elev_deg = t_elev_deg;
			me.last_cruise_or_loft = cruise_or_loft;
			#########################
			#########################

			# Compute target deviation variation then seeker move to keep this deviation constant.
			me.track_signal_e = dev_e * e_gain;
			me.track_signal_h = dev_h * h_gain;
			
#print ("**** curr_tgt_e = ", me.curr_tgt_e," curr_tgt_h = ", me.curr_tgt_h, " me.track_signal_e = ", me.track_signal_e," me.track_signal_h = ", me.track_signal_h);


		}
		# Compute HUD reticle position.
		if ( me.status == 1 ) {
			var h_rad = (90 - me.curr_tgt_h) * D2R;
			var e_rad = (90 - me.curr_tgt_e) * D2R; 
			var devs = f14_hud.develev_to_devroll(h_rad, e_rad);
			var combined_dev_deg = devs[0];
			var combined_dev_length =  devs[1];
			var clamped = devs[2];
			if ( clamped ) { SW_reticle_Blinker.blink();}
			else { SW_reticle_Blinker.cont();}
			HudReticleDeg.setValue(combined_dev_deg);
			HudReticleDev.setValue(combined_dev_length);
		}
		if ( me.status != 2 and me.status != -1 ) {
			me.check_t_in_fov();
			# We are not launched yet: update_track() loops by itself at 10 Hz.
			SwSoundVol.setValue(vol_track);
			settimer(func me.update_track(nil), 0.1);
		}
		return(1);
	},




	poximity_detection: func {
		var cur_dir_dist_m = me.coord.direct_distance_to(me.t_coord);
		# Get current direct distance.

		####Ground interaction
        var ground = geo.elevation(me.coord.lat(),me.coord.lon());
        #print("Ground :",ground);
        var groundhit = 0;
        if(ground != nil)
        {
            if(ground>me.coord.alt()) {
                print("Missile hit terrain");
                me.free = 1;
                groundhit = 1;
            }
        }


		#print("cur_dir_dist_m = ",cur_dir_dist_m," me.direct_dist_m = ",me.direct_dist_m);
		if ( me.direct_dist_m != nil ) {
			if ( (cur_dir_dist_m > me.direct_dist_m and cur_dir_dist_m < 250 and me.life_time > me.arm_time) or me.life_time > me.selfdestruct_time or groundhit == 1) {
				# Distance to target increase, trigger explosion.
				# Get missile relative position to the target at last frame.
				var t_bearing_deg = me.last_t_coord.course_to(me.last_coord);
				var t_delta_alt_m = me.last_coord.alt() - me.last_t_coord.alt();
				var new_t_alt_m = me.t_coord.alt() + t_delta_alt_m;
				var t_dist_m  = math.sqrt(math.abs((me.direct_dist_m * me.direct_dist_m)-(t_delta_alt_m * t_delta_alt_m)));
				

				var ident = "nil";
				if(me.Tgt.Callsign != nil and me.Tgt.Callsign.getValue() != nil) {
		          ident = me.Tgt.Callsign.getValue();
		        }

		        var min_distance = me.direct_dist_m;
				var explosion_coord = me.last_coord;
				for (var i = 0.00; i <= 1; i += 0.05) {
					var t_coord = me.interpolate(me.last_t_coord, me.t_coord, i);
					var coord = me.interpolate(me.last_coord, me.coord, i);
					var dist = coord.direct_distance_to(t_coord);
					if (dist < min_distance) {
						min_distance = dist;
						explosion_coord = coord;
					}
				}
				if (me.before_last_coord != nil and me.before_last_t_coord != nil) {
					for (var i = 0.00; i <= 1; i += 0.05) {
						var t_coord = me.interpolate(me.before_last_t_coord, me.last_t_coord, i);
						var coord = me.interpolate(me.before_last_coord, me.last_coord, i);
						var dist = coord.direct_distance_to(t_coord);
						if (dist < min_distance) {
							min_distance = dist;
							explosion_coord = coord;
						}
					}
				}
				
				var phrase = sprintf( "aim-9 exploded: %01.1f", min_distance) ~ " meters from: " ~ ident;

				#var phrase = sprintf( "%01.0f", me.direct_dist_m) ~ "meters";
				if (getprop("sim/model/f-14b/systems/armament/mp-messaging")) {
					setprop("/sim/multiplay/chat", defeatSpamFilter(phrase));
				} else {
					setprop("/sim/messages/atc", phrase);
				}


				# Create impact coords from this previous relative position applied to target current coord.
				me.t_coord.apply_course_distance(t_bearing_deg, t_dist_m);
				me.t_coord.set_alt(new_t_alt_m);		
				var wh_mass = me.weight_whead_lbs / slugs_to_lbs;
				#print("FOX2: me.direct_dist_m = ",  me.direct_dist_m, " time ",getprop("sim/time/elapsed-sec"));
				print(phrase);
				impact_report(me.t_coord, wh_mass, "missile"); # pos, alt, mass_slug,(speed_mps)

				
				me.animate_explosion();
				me.Tgt = nil;
				return(0);
			}
		}
		
		me.direct_dist_m = cur_dir_dist_m;
		return(1);
	},

	interpolate: func (start, end, fraction) {
		var x = (start.x()*(1-fraction)+end.x()*fraction);
		var y = (start.y()*(1-fraction)+end.y()*fraction);
		var z = (start.z()*(1-fraction)+end.z()*fraction);

		var c = geo.Coord.new();
		c.set_xyz(x,y,z);

		return c;
	},

	check_t_in_fov: func {
		# Used only when not launched.
		# Compute seeker total angular position clamped to seeker max total angular rotation.
		me.seeker_dev_e += me.track_signal_e;
		me.seeker_dev_e = me.clamp_min_max(me.seeker_dev_e, me.max_seeker_dev);
		me.seeker_dev_h += me.track_signal_h;
		me.seeker_dev_h = me.clamp_min_max(me.seeker_dev_h, me.max_seeker_dev);
		# Check target signal inside seeker FOV.
		var e_d = me.seeker_dev_e - me.aim9_fov;
		var e_u = me.seeker_dev_e + me.aim9_fov;
		var h_l = me.seeker_dev_h - me.aim9_fov;
		var h_r = me.seeker_dev_h + me.aim9_fov;
		if ( me.curr_tgt_e < e_d or me.curr_tgt_e > e_u or me.curr_tgt_h < h_l or me.curr_tgt_h > h_r ) {		
			# Target out of FOV while still not launched, return to search loop.
			me.status = 0;
			settimer(func me.search(), 0.1);
			me.Tgt = nil;
			SwSoundVol.setValue(vol_search);
			me.reset_seeker();
		}
		return(1);
	},


	search: func {
		if ( me.status == -1 ) {
			# Stand by.
			SwSoundVol.setValue(0);
			return;
		} elsif ( me.status > 0 ) {
			# Locked or fired.
			return;
		}
		# search.
		if ( awg_9.nearest_u != nil and awg_9.nearest_u.Valid.getValue()) {
			var tgt = awg_9.nearest_u; # In the AWG-9 radar range and horizontal field.
			var rng = tgt.get_range();
			var total_elev  = tgt.get_total_elevation(OurPitch.getValue()); # deg.
			var total_horiz = tgt.get_deviation(OurHdg.getValue());         # deg.
			# Check if in range and in the (square shaped here) seeker FOV.
			var abs_total_elev = math.abs(total_elev);
			var abs_dev_deg = math.abs(total_horiz);
			if (rng < me.max_detect_rng and abs_total_elev < me.aim9_fov_diam and abs_dev_deg < me.aim9_fov_diam ) {
				me.status = 1;
				SwSoundVol.setValue(vol_weak_track);
				me.Tgt = tgt;
				var t_pos_str = me.Tgt.string ~ "/position";
				var t_ori_str = me.Tgt.string ~ "/orientation";
				var t_vel_str = me.Tgt.string ~ "/velocities";
				me.TgtLon_prop       = props.globals.getNode(t_pos_str).getChild("longitude-deg");
				me.TgtLat_prop       = props.globals.getNode(t_pos_str).getChild("latitude-deg");
				me.TgtAlt_prop       = props.globals.getNode(t_pos_str).getChild("altitude-ft");
				me.TgtHdg_prop       = props.globals.getNode(t_ori_str).getChild("true-heading-deg");
				me.TgtPitch_prop     = props.globals.getNode(t_ori_str).getChild("pitch-deg");
				me.TgtSpeed_prop     = props.globals.getNode(t_vel_str).getChild("true-airspeed-kt");
				settimer(func me.update_track(nil), 0.1);
				return;
			}
		}
		SwSoundVol.setValue(vol_search);
		settimer(func me.search(), 0.1);
	},



	reset_steering: func {
		me.track_signal_e = 0;
		me.track_signal_h = 0;
	},



	reset_seeker: func {
		me.curr_tgt_e     = 0;
		me.curr_tgt_h     = 0;
		me.seeker_dev_e   = 0;
		me.seeker_dev_h   = 0;
		settimer(func { HudReticleDeg.setValue(0) }, 2);
		interpolate(HudReticleDev, 0, 2);
		me.reset_steering()
	},



	clamp_min_max: func (v, mm) {
		if ( v < -mm ) {
			v = -mm;
		} elsif ( v > mm ) {
			v = mm;
		}
	return(v);
	},



	animation_flags_props: func {
		# Create animation flags properties.
		var msl_path = "sim/model/f-14b/systems/armament/aim9/flags/msl-id-" ~ me.ID;
		me.msl_prop = props.globals.initNode( msl_path, 1, "BOOL" );
		var smoke_path = "sim/model/f-14b/systems/armament/aim9/flags/smoke-id-" ~ me.ID;
		me.smoke_prop = props.globals.initNode( smoke_path, 0, "BOOL" );
		var explode_path = "sim/model/f-14b/systems/armament/aim9/flags/explode-id-" ~ me.ID;
		me.explode_prop = props.globals.initNode( explode_path, 0, "BOOL" );
		var explode_smoke_path = "sim/model/f-14b/systems/armament/aim9/flags/explode-smoke-id-" ~ me.ID;
		me.explode_smoke_prop = props.globals.initNode( explode_smoke_path, 0, "BOOL" );
	},



	animate_explosion: func {
		me.msl_prop.setBoolValue(0);
		me.smoke_prop.setBoolValue(0);
		me.explode_prop.setBoolValue(1);
		settimer( func me.explode_prop.setBoolValue(0), 0.5 );
		settimer( func me.explode_smoke_prop.setBoolValue(1), 0.5 );
		settimer( func me.explode_smoke_prop.setBoolValue(0), 3 );
	},



	active: {},
};


# Create impact report.

#altitde-agl-ft DOUBLE
#impact
#	elevation-m DOUBLE
#	heading-deg DOUBLE
#	latitude-deg DOUBLE
#	longitude-deg DOUBLE
#	pitch-deg DOUBLE
#	roll-deg DOUBLE
#	speed-mps DOUBLE
#	type STRING
#valid "true" BOOL


var impact_report = func(pos, mass_slug, string) {

	# Find the next index for "ai/models/model-impact" and create property node.
	var n = props.globals.getNode("ai/models", 1);
	for (var i = 0; 1; i += 1)
		if (n.getChild(string, i, 0) == nil)
			break;
	var impact = n.getChild(string, i, 1);

	impact.getNode("impact/elevation-m", 1).setValue(pos.alt());
	impact.getNode("impact/latitude-deg", 1).setValue(pos.lat());
	impact.getNode("impact/longitude-deg", 1).setValue(pos.lon());
	impact.getNode("mass-slug", 1).setValue(mass_slug);
	#impact.getNode("speed-mps", 1).setValue(speed_mps);
	impact.getNode("valid", 1).setBoolValue(1);
	impact.getNode("impact/type", 1).setValue("terrain");

	var impact_str = "/ai/models/" ~ string ~ "[" ~ i ~ "]";
	setprop("ai/models/model-impact", impact_str);

}

var steering_speed_G = func(steering_e_deg, steering_h_deg, s_fps, dt) {
	# Get G number from steering (e, h) in deg, speed in ft/s.
	var steer_deg = math.sqrt((steering_e_deg*steering_e_deg) + (steering_h_deg*steering_h_deg));

	# next speed vector
	var vector_next_x = math.cos(steer_deg*D2R)*s_fps;
	var vector_next_y = math.sin(steer_deg*D2R)*s_fps;
	
	# present speed vector
	var vector_now_x = s_fps;
	var vector_now_y = 0;

	# subtract the vectors from each other
	var dv = math.sqrt((vector_now_x - vector_next_x)*(vector_now_x - vector_next_x)+(vector_now_y - vector_next_y)*(vector_now_y - vector_next_y));

	# calculate g-force
	# dv/dt=a
	var g = (dv/dt) / g_fps;

	# old calc with circle:
	#var radius_ft = math.abs(s_fps / math.sin(steer_deg*D2R));
	#var g = ( (s_fps * s_fps) / radius_ft ) / g_fps;
	#print("#### R = ", radius_ft, " G = ", g); ##########################################################
	return g;
}

var max_G_Rotation = func(steering_e_deg, steering_h_deg, s_fps, dt, gMax) {
	var guess = 1;
	var coef = 1;
	var lastgoodguess = 1;

	for(var i=1;i<25;i+=1){
		coef = coef/2;
		var new_g = steering_speed_G(steering_e_deg*guess, steering_h_deg*guess, s_fps, dt);
		if (new_g < gMax) {
			lastgoodguess = guess;
			guess = guess + coef;
		} else {
			guess = guess - coef;
		}
	}
	return lastgoodguess;
}


# HUD clamped target blinker
SW_reticle_Blinker = aircraft.light.new("sim/model/f-14b/lighting/hud-sw-reticle-switch", [0.1, 0.1]);
setprop("sim/model/f-14b/lighting/hud-sw-reticle-switch/enabled", 1);












var spams = 0;

var defeatSpamFilter = func (str) {
  spams += 1;
  if (spams == 15) {
    spams = 1;
  }
  str = str~":";
  for (var i = 1; i <= spams; i+=1) {
    str = str~".";
  }
  return str;
}