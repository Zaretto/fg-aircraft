#
# F-15 AIM Missile
# ---------------------------
# Richard Harrison (rjh@zaretto.com) Feb  2015 - based on F-14B version by Alexis Bory


var AcModel        = props.globals.getNode("sim/model/f15");
var OurHdg         = props.globals.getNode("orientation/heading-deg");
var OurRoll        = props.globals.getNode("orientation/roll-deg");
var OurPitch       = props.globals.getNode("orientation/pitch-deg");
var HudReticleDev  = props.globals.getNode("sim/model/f15/instrumentation/radar-awg-9/hud/reticle-total-deviation", 1);
var HudReticleDeg  = props.globals.getNode("sim/model/f15/instrumentation/radar-awg-9/hud/reticle-total-angle", 1);
#var aim_9_model    = "Models/Stores/aim-9/aim-9-";
var SwSoundOnOff   = AcModel.getNode("systems/armament/aim9/sound-on-off");
var SwSoundVol     = AcModel.getNode("systems/armament/aim9/sound-volume");
var vol_search     = 0.12;
var vol_weak_track = 0.20;
var vol_track      = 0.45;

var TRUE = 1;
var FALSE = 0;

var g_fps        = 9.80665 * M2FT;
var slugs_to_lbs = 32.1740485564;



var AIM9 = {
	new : func (p, mty) {
		var m = { parents : [AIM9]};
		# Args: 
        # p = Pylon.
        # mty = missile type.
        m.variant =string.lc(mty);
        if (mty == "AIM-9")
            mty = "aim9";
        else if (mty == "AIM-7")
            mty = "aim7";
        else if (mty == "AIM-120")
            mty = "aim120";

        m.type = mty;

		m.status            = 0; # -1 = stand-by, 0 = searching, 1 = locked, 2 = fired.
		m.free              = 0; # 0 = status fired with lock, 1 = status fired but having lost lock.

		m.prop              = AcModel.getNode("systems/armament/"~m.type~"/").getChild("msl", 0 , 1);
		m.PylonIndex        = m.prop.getNode("pylon-index", 1).setValue(p);
		m.ID                = p;
		m.pylon_prop        = props.globals.getNode("sim/model/f15/systems/external-loads/").getChild("station", p);
		m.pylon_prop_name   = "sim/model/f15/systems/external-loads/station["~p~"]";
		m.Tgt               = nil;
		m.TgtValid          = nil;
		m.TgtLon_prop       = nil;
		m.TgtLat_prop       = nil;
		m.TgtAlt_prop       = nil;
		m.TgtHdg_prop       = nil;
		m.TgtSpeed_prop     = nil;
		m.TgtPitch_prop     = nil;
		m.TgtBearing_prop   = nil;
		m.update_track_time = 0;
		m.seeker_dev_e      = 0; # Seeker elevation, deg.
		m.seeker_dev_h      = 0; # Seeker horizon, deg.
		m.direct_dist_m     = nil;

		# AIM-9L specs:
		m.aim9_fov_diam     = getprop("sim/model/f15/systems/armament/"~m.type~"/fov-deg");
		m.aim9_fov          = m.aim9_fov_diam / 2;
		m.max_detect_rng    = getprop("sim/model/f15/systems/armament/"~m.type~"/max-detection-rng-nm");
		m.max_seeker_dev    = getprop("sim/model/f15/systems/armament/"~m.type~"/track-max-deg") / 2;
		m.force_lbs_1       = getprop("sim/model/f15/systems/armament/"~m.type~"/thrust-lbs-stage-1");
		m.force_lbs_2       = getprop("sim/model/f15/systems/armament/"~m.type~"/thrust-lbs-stage-2");
		m.stage_1_duration = getprop("sim/model/f15/systems/armament/"~m.type~"/stage-1-duration-sec");
		m.stage_2_duration = getprop("sim/model/f15/systems/armament/"~m.type~"/stage-2-duration-sec");
		m.weight_launch_lbs = getprop("sim/model/f15/systems/armament/"~m.type~"/weight-launch-lbs");
		m.weight_whead_lbs  = getprop("sim/model/f15/systems/armament/"~m.type~"/weight-warhead-lbs");
		m.Cd_base           = getprop("sim/model/f15/systems/armament/"~m.type~"/drag-coeff");
		m.eda               = getprop("sim/model/f15/systems/armament/"~m.type~"/drag-area");
		m.max_g             = getprop("sim/model/f15/systems/armament/"~m.type~"/max-g");
		m.selfdestruct_time = getprop("sim/model/f15/systems/armament/"~m.type~"/self-destruct-time-sec");
		m.angular_speed     = getprop("sim/model/f15/systems/armament/"~m.type~"/seeker-angular-speed-dps");
        m.loft_alt          = getprop("sim/model/f15/systems/armament/"~m.type~"/loft-altitude");
        m.min_speed_for_guiding = getprop("sim/model/f15/systems/armament/"~m.type~"/min-speed-for-guiding-mach");
        m.arm_time          = getprop("sim/model/f15/systems/armament/"~m.type~"/arming-time-sec");
        m.rail              = getprop("sim/model/f15/systems/armament/"~m.type~"/rail");
        m.rail_dist_m       = getprop("sim/model/f15/systems/armament/"~m.type~"/rail-length-m");
        m.rail_forward      = getprop("sim/model/f15/systems/armament/"~m.type~"/rail-point-forward");

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
			if (n.getChild(m.variant, i, 0) == nil)
				break;
		m.ai = n.getChild(m.variant, i, 1);

		m.ai.getNode("valid", 1).setBoolValue(1);
        var missile_model    = sprintf("Models/Stores/%s/%s-%d.xml", m.variant, m.variant, m.ID);
print("Model ",missile_model);

		m.model.getNode("path", 1).setValue(missile_model);
		m.life_time = 0;

		# Create the AI position and orientation properties.
		m.latN   = m.ai.getNode("position/latitude-deg", 1);
		m.lonN   = m.ai.getNode("position/longitude-deg", 1);
		m.altN   = m.ai.getNode("position/altitude-ft", 1);
		m.hdgN   = m.ai.getNode("orientation/true-heading-deg", 1);
		m.pitchN = m.ai.getNode("orientation/pitch-deg", 1);
		m.rollN  = m.ai.getNode("orientation/roll-deg", 1);

		m.ac      = nil;

		m.coord               = geo.Coord.new().set_latlon(0, 0, 0);
		m.last_coord          = nil;
		m.before_last_coord   = nil;
		m.t_coord             = geo.Coord.new().set_latlon(0, 0, 0);
		m.last_t_coord        = m.t_coord;
		m.before_last_t_coord = nil;

		m.speed_down_fps  = nil;
		m.speed_east_fps  = nil;
		m.speed_north_fps = nil;
		m.alt_ft          = nil;
		m.pitch           = nil;
		m.hdg             = nil;

		# Nikolai V. Chr.
		# The more variables here instead of declared locally, the better for performance.
		# Due to garbage collector.
		#		

		m.density_alt_diff   = 0;
		m.max_g_current      = m.max_g;
		m.old_speed_horz_fps = nil;
		m.old_speed_fps	     = 0;
		m.dt                 = 0;
		m.g = 0;

		# navigation and guidance
		m.last_deviation_e       = nil;
		m.last_deviation_h       = nil;
		m.last_track_e           = 0;
		m.last_track_h           = 0;
		m.last_tgt_h             = nil;
		m.last_tgt_e             = nil;
		m.guiding                = TRUE;
		m.t_alt                  = 0;
		m.dist_curr              = 0;
		m.dist_curr_direct       = 0;
		m.t_elev_deg             = 0;
		m.t_course               = 0;
		m.dist_last              = nil;
		m.dist_direct_last       = nil;
		m.last_t_course          = nil;
		m.last_t_elev_deg        = nil;
		m.last_cruise_or_loft    = FALSE;
		m.last_t_norm_speed      = nil;
		m.last_t_elev_norm_speed = nil;
		m.last_dt                = 0;
		m.dive_token             = FALSE;
		m.raw_steer_signal_elev  = 0;
		m.raw_steer_signal_head  = 0;
		m.cruise_or_loft         = FALSE;
		m.curr_tgt_e             = 0;
		m.curr_tgt_h             = 0;
		m.track_signal_e         = 0;
		m.track_signal_h         = 0;

		# cruise missiles
		m.nextGroundElevation = 0; # next Ground Elevation
		m.nextGroundElevationMem = [-10000, -1];

		#rail
		m.drop_time = 0;
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
	getGPS: func(x, y, z) {
		#
		# get Coord from body position. x,y,z must be in meters.
		# derived from Vivian's code in AIModel/submodel.cxx.
		#
		var ac_roll = getprop("orientation/roll-deg");
		var ac_pitch = getprop("orientation/pitch-deg");
		var ac_hdg   = getprop("orientation/heading-deg");

		me.ac = geo.aircraft_position();

		var in    = [0,0,0];
		var trans = [[0,0,0],[0,0,0],[0,0,0]];
		var out   = [0,0,0];

		in[0] =  -x * M2FT;
		in[1] =   y * M2FT;
		in[2] =   z * M2FT;
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
		var mlat = me.ac.lat() + out[0];
		var mlon = me.ac.lon() + out[1];
		var malt = (me.ac.alt() * M2FT) + out[2];
		
		var c = geo.Coord.new();
		c.set_latlon(mlat, mlon, malt * FT2M);

		return c;
	},
	release: func() {
		me.status = 2;
        printf("%s: release %d",me.type,me.ID);
		me.animation_flags_props();

		# Get the A/C position and orientation values.
		me.ac = geo.aircraft_position();
		var ac_roll  = getprop("orientation/roll-deg");
		var ac_pitch = getprop("orientation/pitch-deg");
		var ac_hdg   = getprop("orientation/heading-deg");

		# Compute missile initial position relative to A/C center,
		# following Vivian's code in AIModel/submodel.cxx .
		
        if (me.pylon_prop.getNode("offsets/x-m") != nil)
        {
            me.x = me.pylon_prop.getNode("offsets/x-m").getValue();
            me.y = me.pylon_prop.getNode("offsets/y-m").getValue();
            me.z = me.pylon_prop.getNode("offsets/z-m").getValue();
        }
        else
            print("ERROR pylon prop not setup correctly ",me.pylon_prop_name);

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
		me.speed_down_fps = getprop("velocities/speed-down-fps");
		me.speed_east_fps = getprop("velocities/speed-east-fps");
		me.speed_north_fps = getprop("velocities/speed-north-fps");
		if (me.rail == TRUE) {
			var u = getprop("velocities/uBody-fps");# wind from nose
			me.rail_speed_into_wind = u;
		}

		me.alt_ft = aalt;
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

	maxG: func (rho, max_g_sealevel) {
		# Nikolai V. Chr.: A function to determine max G-force depending on air density.
		#
		# density for 0ft and 50kft:
		#print("0:"~rho_sndspeed(0)[0]);       = 0.0023769
		#print("50k:"~rho_sndspeed(50000)[0]); = 0.00036159
		#
		# Fact: An aim-9j can do 22G at sealevel, 13G at 50Kft
		# 13G = 22G * 0.5909
		#
		# extra/inter-polation:
		# f(x) = y1 + ((x - x1) / (x2 - x1)) * (y2 - y1)
		# calculate its performance at current air density:
		return max_g_sealevel+((rho-0.0023769)/(0.00036159-0.0023769))*(max_g_sealevel*0.5909-max_g_sealevel);
	},

	thrust: func () {
		# Determine the thrust at this moment.
		#
		# If dropped, then ignited after fall time of what is the equivalent of 7ft.
		# If the rocket is 2 stage, then ignite the second stage when 1st has burned out.
		#
		var thrust_lbf = 0;# pounds force (lbf)
		if (me.life_time > me.drop_time) {
			thrust_lbf = me.force_lbs_1;
		}
		if (me.life_time > me.stage_1_duration + me.drop_time) {
			thrust_lbf = me.force_lbs_2;
		}
		if (me.life_time > (me.drop_time + me.stage_1_duration + me.stage_2_duration)) {
			thrust_lbf = 0;
		}
		if (thrust_lbf < 1) {
			me.smoke_prop.setBoolValue(0);
		} else {
			me.smoke_prop.setBoolValue(1);
		}
		return thrust_lbf;
	},

	speedChange: func (thrust_lbf, rho, Cd) {
		# Calculate speed change from last update.
		#
		# Acceleration = thrust/mass - drag/mass;
		var mass = me.weight_launch_lbs / slugs_to_lbs;
		var acc = thrust_lbf / mass;
		var q = 0.5 * rho * me.old_speed_fps * me.old_speed_fps;# dynamic pressure
		var drag_acc = (Cd * q * me.eda) / mass;

		# get total new speed change (minus gravity)
		return acc*me.dt - drag_acc*me.dt;
	},

    energyBleed: func (gForce, altitude) {
        # Bleed of energy from pulling Gs.
        # This is very inaccurate, but better than nothing.
        #
        # First we get the speedloss due to normal drag:
        var b300 = me.bleed32800at0g();
        var b000 = me.bleed0at0g();
        #
        # We then subtract the normal drag from the loss due to G and normal drag.
        var b325 = me.bleed32800at25g()-b300;
        var b025 = me.bleed0at25g()-b000;
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
        return me.clamp(speedLoss, -100000, 0);
    },

	bleed32800at0g: func () {
		var loss_fps = 0 + ((me.dt - 0)/(15 - 0))*(-330 - 0);
		return loss_fps*M2FT;
	},

	bleed32800at25g: func () {
		var loss_fps = 0 + ((me.dt - 0)/(3.5 - 0))*(-240 - 0);
		return loss_fps*M2FT;
	},

	bleed0at0g: func () {
		var loss_fps = 0 + ((me.dt - 0)/(22 - 0))*(-950 - 0);
		return loss_fps*M2FT;
	},

	bleed0at25g: func () {
		var loss_fps = 0 + ((me.dt - 0)/(7 - 0))*(-750 - 0);
		return loss_fps*M2FT;
	},

	update: func {
		me.dt = getprop("sim/time/delta-sec");
		var init_launch = 0;
		if ( me.life_time > 0 ) { init_launch = 1 }
		me.life_time += me.dt;
		# record coords so we can give the latest nearest position for impact.
		me.before_last_coord = geo.Coord.new(me.last_coord);
		me.last_coord = geo.Coord.new(me.coord);


		#### Calculate speed vector before steering corrections.


		var thrust_lbf = me.thrust();# pounds force (lbf)

		# Get total old speed.
		me.old_speed_horz_fps = math.sqrt((me.speed_east_fps*me.speed_east_fps)+(me.speed_north_fps*me.speed_north_fps));
		me.old_speed_fps = math.sqrt((me.old_speed_horz_fps*me.old_speed_horz_fps)+(me.speed_down_fps*me.speed_down_fps));

		if (me.rail == TRUE and me.rail_passed == FALSE) {
			var u = getprop("velocities/uBody-fps");# airstream from nose
			#var v = getprop("velocities/vBody-fps");# airstream from side
			var w = getprop("velocities/wBody-fps");# airstream from below

			var opposing_wind = u;

			if (me.rail_forward == TRUE) {
				me.pitch = getprop("orientation/pitch-deg");
				me.hdg = getprop("orientation/heading-deg");
			} else {
				me.pitch = 90;
				opposing_wind = -w;
				me.hdg = me.Tgt.get_bearing();
			}			

			var speed_on_rail = me.clamp(me.rail_speed_into_wind - opposing_wind, 0, 1000000);
			var movement_on_rail = speed_on_rail * me.dt;
			
			me.rail_pos = me.rail_pos + movement_on_rail;
			if (me.rail_forward == TRUE) {
				me.x = me.x - (movement_on_rail * FT2M);# negative cause positive is rear in body coordinates
			} else {
				me.z = me.z + (movement_on_rail * FT2M);# positive cause positive is up in body coordinates
			}
		}

		# Get air density and speed of sound (fps):
		var rs = environment.rho_sndspeed(me.altN.getValue() + me.density_alt_diff);
		var rho = rs[0];
		var sound_fps = rs[1];

		me.max_g_current = me.maxG(rho, me.max_g);

		if (me.rail == TRUE and me.rail_passed == FALSE) {
			# if missile is still on rail, we replace the speed, with the speed into the wind from nose on the rail.
			me.old_speed_fps = me.rail_speed_into_wind;
		}

		me.speed_m = me.old_speed_fps / sound_fps;

		var Cd = me.drag(me.speed_m);

		var speed_change_fps = me.speedChange(thrust_lbf, rho, Cd);
		
#var ns = speed_change_fps + me.old_speed_fps;

		if (me.last_dt != 0) {
			speed_change_fps = speed_change_fps + me.energyBleed(me.g, me.altN.getValue() + me.density_alt_diff,me.last_dt);
		}

#var nsb = speed_change_fps + me.old_speed_fps;
#printf("Percent speed due to G bleed %.1f", 100*nsb/ns);


		var grav_bomb = FALSE;
		if (me.force_lbs_1 == 0 and me.force_lbs_2 == 0) {
			# for now gravity bombs cannot be guided.
			grav_bomb == TRUE;
		}

		# Get target position.
		me.t_coord.set_latlon(me.TgtLat_prop.getValue(), me.TgtLon_prop.getValue(), me.TgtAlt_prop.getValue() * FT2M);

		#### Guidance.

        if ( me.status == 2 and me.free == FALSE and me.life_time > me.drop_time and grav_bomb == FALSE
			and (me.rail == FALSE or me.rail_passed == TRUE)) {
            
            me.update_track(me.dt);
            me.limitG();

            me.pitch      += me.track_signal_e;
            me.hdg        += me.track_signal_h;
        } else {
			me.track_signal_e = 0;
			me.track_signal_h = 0;
		}
       	me.last_track_e = me.track_signal_e;
		me.last_track_h = me.track_signal_h;

		var new_speed_fps        = speed_change_fps + me.old_speed_fps;
		if (new_speed_fps < 0) {
			# drag and bleed can theoretically make the speed less than 0, this will prevent that from happening.
			new_speed_fps = 0;
		}

		# Break speed change down total speed to North, East and Down components.
		me.speed_down_fps       = - math.sin(me.pitch * D2R) * new_speed_fps;
		var speed_horizontal_fps = math.cos(me.pitch * D2R) * new_speed_fps;
		me.speed_north_fps      = math.cos(me.hdg * D2R) * speed_horizontal_fps;
		me.speed_east_fps       = math.sin(me.hdg * D2R) * speed_horizontal_fps;

		if (me.rail == TRUE and me.rail_passed == FALSE) {
			# missile still on rail, lets calculate its speed relative to the wind coming in from the aircraft nose.
			me.rail_speed_into_wind = me.rail_speed_into_wind + speed_change_fps;
		}

		if (grav_bomb == TRUE) {
			# true gravity acc
			me.speed_down_fps += g_fps * me.dt;
			me.pitch = math.atan2( me.speed_down_fps, speed_horizontal_fps ) * R2D;
		}
		
		me.alt_ft = me.alt_ft - ((me.speed_down_fps + g_fps * me.dt * !grav_bomb) * me.dt);

		if (me.rail == FALSE or me.rail_passed == TRUE) {
			# misssile not on rail, lets move it to next waypoint
			var dist_h_m = speed_horizontal_fps * me.dt * FT2M;
			me.coord.apply_course_distance(me.hdg, dist_h_m);
			me.coord.set_alt(me.alt_ft * FT2M);
		} else {
			# missile on rail, lets move it on the rail
			new_speed_fps = me.rail_speed_into_wind;
			me.coord = me.getGPS(me.x, me.y, me.z);
			me.alt_ft = me.coord.alt() * M2FT;
		}

		me.latN.setDoubleValue(me.coord.lat());
		me.lonN.setDoubleValue(me.coord.lon());
		me.altN.setDoubleValue(me.alt_ft);
		me.pitchN.setDoubleValue(me.pitch);
		me.hdgN.setDoubleValue(me.hdg);

		me.setRadarProperties(new_speed_fps);


		#### Proximity detection.
		if (me.status == 2 and (me.rail == FALSE or me.rail_passed == TRUE)) {
 			if ( me.free == FALSE ) {
 				# check if the missile overloaded with G force.
				me.g = steering_speed_G(me.track_signal_e, me.track_signal_h, me.old_speed_fps, me.dt);

				if ( me.g > me.max_g_current) {
					me.free = TRUE;
					print("Missile attempted to pull too many G, it broke.");
				}
			} else {
				me.g = 0;
			}
        
            var v = me.poximity_detection();
            if ( ! v ) 
            {
                # We exploded, but need a few more secs to spawn the explosion animation.
                settimer(func { me.del(); }, 4 );
                #print("booom");
                return;
            }            
        } else {
        	me.g = 0;
        }

        me.before_last_t_coord = geo.Coord.new(me.last_t_coord);
		me.last_t_coord = geo.Coord.new(me.t_coord);

		if (me.rail_passed == FALSE and (me.rail == FALSE or me.rail_pos > me.rail_dist_m * M2FT)) {
			me.rail_passed = TRUE;
			#print("rail passed");
		}
		me.last_dt = me.dt;
		settimer(func me.update(), 0);
		
	},

	limitG: func () {
		#
		# Here will be set the max angle of pitch and the max angle of heading to avoid G overload
		#
        var myG = steering_speed_G(me.track_signal_e, me.track_signal_h, me.old_speed_fps, me.dt);
        if(me.max_g_current < myG)
        {
            var MyCoef = max_G_Rotation(me.track_signal_e, me.track_signal_h, me.old_speed_fps, me.dt, me.max_g_current);
            me.track_signal_e =  me.track_signal_e * MyCoef;
            me.track_signal_h =  me.track_signal_h * MyCoef;
            #print(sprintf("G1 %.2f", myG));
            var myG2 = steering_speed_G(me.track_signal_e, me.track_signal_h, me.old_speed_fps, me.dt);
            #print(sprintf("G2 %.2f", myG)~sprintf(" - Coeff %.2f", MyCoef));
            printf("Missile pulling almost max G: %.1f G", myG2);
        }
	},

	setRadarProperties: func (new_speed_fps) {
		#
		# Set missile radar properties for use in selection view, radar and HUD.
		#
		var self = geo.aircraft_position();
		me.ai.getNode("radar/bearing-deg", 1).setDoubleValue(self.course_to(me.coord));
		var angleInv = me.clamp(self.distance_to(me.coord)/self.direct_distance_to(me.coord), -1, 1);
		me.ai.getNode("radar/elevation-deg", 1).setDoubleValue((self.alt()>me.coord.alt()?-1:1)*math.acos(angleInv)*R2D);
		me.ai.getNode("velocities/true-airspeed-kt",1).setDoubleValue(new_speed_fps * FPS2KT);
	},




	update_track: func(dt_) {

		if ( me.Tgt == nil ) 
        {
            if (me.status != 2)
                setprop("sim/model/f15/systems/armament/launch-light",false);
            return(1); 
        }
# do not set launch light when missile tracking.
        if (me.status != 2)
            setprop("sim/model/f15/systems/armament/launch-light",me.status == 1);

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

			#
			# navigation and guidance
			#
			me.raw_steer_signal_elev = 0;
			me.raw_steer_signal_head = 0;

			me.guiding = TRUE;

			# Calculate current target elevation and azimut deviation.
			me.t_alt            = me.t_coord.alt()*M2FT;
			var t_alt_delta_m   = (me.t_alt - me.alt_ft) * FT2M;
			me.dist_curr        = me.coord.distance_to(me.t_coord);
			me.dist_curr_direct = me.coord.direct_distance_to(me.t_coord);
			me.t_elev_deg       = math.atan2( t_alt_delta_m, me.dist_curr ) * R2D;
			me.t_course         = me.coord.course_to(me.t_coord);
			me.curr_tgt_e       = me.t_elev_deg - me.pitch;
			me.curr_tgt_h       = me.t_course - me.hdg;


			#
			# So is course_to() or courseAndDistance() most precise? People said the latter,
			# but my experiments said it differs. The latter seems to be influenced by altitude differences,
			# which is not good for cruise-missiles, but it seems better for long distances.
			# While the former seems better for short distances.
			# ..strange
			#
			#var (t_course, me.dist_curr_direct) = courseAndDistance(me.coord, me.t_coord);
			#me.dist_curr_direct = me.dist_curr_direct * NM2M;
		

			#printf("Altitude above launch platform = %.1f ft", M2FT * (me.coord.alt()-me.ac.alt()));

			while(me.curr_tgt_h < -180) {
				me.curr_tgt_h += 360;
			}
			while(me.curr_tgt_h > 180) {
				me.curr_tgt_h -= 360;
			}

			me.checkForGuidance();

			me.canSeekerKeepUp();

			me.cruiseAndLoft();

			me.APN();# Proportional navigation

			me.track_signal_e = me.raw_steer_signal_elev * !me.free * me.guiding;
			me.track_signal_h = me.raw_steer_signal_head * !me.free * me.guiding;

			#printf("%.1f deg elevate command desired", me.track_signal_e);
			#printf("%.1f deg heading command desired", me.track_signal_h);

			# record some variables for next loop:
			me.dist_last           = me.dist_curr;
			me.dist_direct_last    = me.dist_curr_direct;
			me.last_tgt_h          = me.curr_tgt_h;
			me.last_tgt_e          = me.curr_tgt_e;
			me.last_t_course       = me.t_course;
			me.last_t_elev_deg     = me.t_elev_deg;
			me.last_cruise_or_loft = me.cruise_or_loft;
		}
		# Compute HUD reticle position.
		if ( me.status == 1 ) {
			var h_rad = (90 - me.curr_tgt_h) * D2R;
			var e_rad = (90 - me.curr_tgt_e) * D2R; 
			var devs = aircraft.develev_to_devroll(h_rad, e_rad);
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

	checkForGuidance: func () {
		if(me.speed_m < me.min_speed_for_guiding) {
			# it doesn't guide at lower speeds
			me.guiding = FALSE;
			print("Not guiding (too low speed)");
		} elsif (me.curr_tgt_e > me.max_seeker_dev or me.curr_tgt_e < (-1 * me.max_seeker_dev)
			  or me.curr_tgt_h > me.max_seeker_dev or me.curr_tgt_h < (-1 * me.max_seeker_dev)) {
			# target is not in missile seeker view anymore
			print("Target is not in missile seeker view anymore");
			me.free = TRUE;
		}
	},

	canSeekerKeepUp: func () {
		if (me.last_deviation_e != nil) {
			# calculate if the seeker can keep up with the angular change of the target
			#
			# missile own movement is subtracted from this change due to seeker being on gyroscope
			#
			var dve_dist = me.curr_tgt_e - me.last_deviation_e + me.last_track_e;
			var dvh_dist = me.curr_tgt_h - me.last_deviation_h + me.last_track_h;
			var deviation_per_sec = math.sqrt(dve_dist*dve_dist+dvh_dist*dvh_dist)/me.dt;

			if (deviation_per_sec > me.angular_speed) {
				#print(sprintf("last-elev=%.1f", me.last_deviation_e)~sprintf(" last-elev-adj=%.1f", me.last_track_e));
				#print(sprintf("last-head=%.1f", me.last_deviation_h)~sprintf(" last-head-adj=%.1f", me.last_track_h));
				# lost lock due to angular speed limit
				printf("%.1f deg/s too big angular change for seeker head.", deviation_per_sec);
				me.free = TRUE;
			}
		}

		me.last_deviation_e = me.curr_tgt_e;
		me.last_deviation_h = me.curr_tgt_h;
	},


	cruiseAndLoft: func () {
		#
		# cruise, loft, cruise-missile
		#
		var loft_angle = 15;# notice Shinobi used 26.5651 degs, but Raider1 found a source saying 10-20 degs.
		var loft_minimum = 10;# miles
		var cruise_minimum = 10;# miles
		me.cruise_or_loft = FALSE;
		
        if(me.loft_alt != 0 and me.loft_alt < 10000) {
        	# this is for Air to ground/sea cruise-missile (SCALP, Sea-Eagle, Taurus, Tomahawk, RB-15...)

        	# detect terrain for use in terrain following
        	me.nextGroundElevationMem[1] -= 1;
            var geoPlus2 = nextGeoloc(me.coord.lat(), me.coord.lon(), me.hdg, me.old_speed_fps, me.dt*5);
            var geoPlus3 = nextGeoloc(me.coord.lat(), me.coord.lon(), me.hdg, me.old_speed_fps, me.dt*10);
            var geoPlus4 = nextGeoloc(me.coord.lat(), me.coord.lon(), me.hdg, me.old_speed_fps, me.dt*20);
            var e1 = geo.elevation(me.coord.lat(), me.coord.lon());# This is done, to make sure is does not decline before it has passed obstacle.
            var e2 = geo.elevation(geoPlus2.lat(), geoPlus2.lon());# This is the main one.
            var e3 = geo.elevation(geoPlus3.lat(), geoPlus3.lon());# This is an extra, just in case there is an high cliff it needs longer time to climb.
            var e4 = geo.elevation(geoPlus4.lat(), geoPlus4.lon());
			if (e1 != nil) {
            	me.nextGroundElevation = e1;
            } else {
            	print("nil terrain, blame terrasync! Cruise-missile keeping altitude.");
            }
            if (e2 != nil and e2 > me.nextGroundElevation) {
            	me.nextGroundElevation = e2;
            	if (e2 > me.nextGroundElevationMem[0] or me.nextGroundElevationMem[1] < 0) {
            		me.nextGroundElevationMem[0] = e2;
            		me.nextGroundElevationMem[1] = 5;
            	}
            }
            if (me.nextGroundElevationMem[0] > me.nextGroundElevation) {
            	me.nextGroundElevation = me.nextGroundElevationMem[0];
            }
            if (e3 != nil and e3 > me.nextGroundElevation) {
            	me.nextGroundElevation = e3;
            }
            if (e4 != nil and e4 > me.nextGroundElevation) {
            	me.nextGroundElevation = e4;
            }

            var Daground = 0;# zero for sealevel in case target is ship. Don't shoot A/S missiles over terrain. :)
            if(me.class == "A/G") {
                Daground = me.nextGroundElevation * M2FT;
            }
            var loft_alt = me.loft_alt;
            if (me.dist_curr < me.old_speed_fps * 4 * FT2M and me.dist_curr > me.old_speed_fps * 2.5 * FT2M) {
            	# the missile lofts a bit at the end to avoid APN to slam it into ground before target is reached.
            	# end here is between 2.5-4 seconds
            	loft_alt = me.loft_alt*2;
            }
            if (me.dist_curr > me.old_speed_fps * 2.5 * FT2M) {# need to give the missile time to do final navigation
                # it's 1 or 2 seconds for this kinds of missiles...
                var t_alt_delta_ft = (loft_alt + Daground - me.alt_ft);
                #print("var t_alt_delta_m : "~t_alt_delta_m);
                if(loft_alt + Daground > me.alt_ft) {
                    # 200 is for a very short reaction to terrain
                    #print("Moving up");
                    me.raw_steer_signal_elev = -me.pitch + math.atan2(t_alt_delta_ft, me.old_speed_fps * me.dt * 5) * R2D;
                } else {
                    # that means a dive angle of 22.5° (a bit less 
                    # coz me.alt is in feet) (I let this alt in feet on purpose (more this figure is low, more the future pitch is high)
                    #print("Moving down");
                    var slope = me.clamp(t_alt_delta_ft / 300, -5, 0);# the lower the desired alt is, the steeper the slope.
                    me.raw_steer_signal_elev = -me.pitch + me.clamp(math.atan2(t_alt_delta_ft, me.old_speed_fps * me.dt * 5) * R2D, slope, 0);
                }
                me.cruise_or_loft = TRUE;
            } elsif (me.dist_curr > 500) {
                # we put 9 feets up the target to avoid ground at the
                # last minute...
                #print("less than 1000 m to target");
                #me.raw_steer_signal_elev = -me.pitch + math.atan2(t_alt_delta_m + 100, me.dist_curr) * R2D;
                #me.cruise_or_loft = 1;
            } else {
            	#print("less than 500 m to target");
            }
            if (me.cruise_or_loft == TRUE) {
            	#print(" pitch "~me.pitch~" + me.raw_steer_signal_elev "~me.raw_steer_signal_elev);
            }
        } elsif (me.loft_alt != 0 and me.dist_curr * M2NM > loft_minimum
			 and me.t_elev_deg < loft_angle #and me.t_elev_deg > -7.5
			 and me.dive_token == FALSE) {
			# stage 1 lofting: due to target is more than 10 miles out and we havent reached 
			# our desired cruising alt, and the elevation to target is less than lofting angle.
			# The -7.5 limit, is so the seeker don't lose track of target when lofting.
			if (me.coord.alt() * M2FT < me.loft_alt) {
				me.raw_steer_signal_elev = -me.pitch + loft_angle;
				#print(sprintf("Lofting %.1f degs, dev is %.1f", loft_angle, me.raw_steer_signal_elev));
			} else {
				me.dive_token = TRUE;
				#print("Cruise token");
			}
			me.cruise_or_loft = TRUE;
		} elsif (me.rail == TRUE and me.rail_forward == FALSE and me.dist_curr * M2NM > cruise_minimum and me.dive_token == FALSE) {
			# tube launched missile turns towards target

			me.raw_steer_signal_elev = -me.pitch + me.t_elev_deg;
			#print("Turning, desire "~me.t_elev_deg~" degs pitch.");
			me.cruise_or_loft = TRUE;
			if (math.abs(me.curr_tgt_e) < 5) {
				me.dive_token = TRUE;
				#print("Is last turn, APN takes it from here..")
			}
		} elsif (me.t_elev_deg < 0 and me.life_time < me.stage_1_duration+me.stage_2_duration+me.drop_time
		         and me.dist_curr * M2NM > cruise_minimum) {
			# stage 1/2 cruising: keeping altitude since target is below and more than 5 miles out

			var ratio = (g_fps * me.dt)/me.old_speed_fps;
            var attitude = 0;

            if (ratio < 1 and ratio > -1) {
                attitude = math.asin(ratio)*R2D;
            }

			me.raw_steer_signal_elev = -me.pitch + attitude;
			#print("Cruising, desire "~attitude~" degs pitch.");
			me.cruise_or_loft = TRUE;
			me.dive_token = TRUE;
		} elsif (me.last_cruise_or_loft == TRUE and math.abs(me.curr_tgt_e) > 2.5) {
			# after cruising, point the missile in the general direction of the target, before APN starts guiding.
			me.raw_steer_signal_elev = me.curr_tgt_e;
			me.cruise_or_loft = TRUE;
		}
	},

	APN: func () {
		#
		# augmented proportional navigation
		#
		if (me.guiding == TRUE and me.free == FALSE and me.dist_last != nil and me.last_dt != 0 and me.last_tgt_h != nil) {
			# augmented proportional navigation for heading #
			#################################################

			var horz_closing_rate_fps = me.clamp(((me.dist_last - me.dist_curr)*M2FT)/me.last_dt, 1, 1000000);#clamped due to cruise missiles that can fly slower than target.
			#printf("Horz closing rate: %5d", horz_closing_rate_fps);
			var proportionality_constant = 3;

			var c_dv = me.t_course-me.last_t_course;
			while(c_dv < -180) {
				c_dv += 360;
			}
			while(c_dv > 180) {
				c_dv -= 360;
			}
			var line_of_sight_rate_rps = (D2R*c_dv)/me.dt;
			#printf("LOS rate: %.4f rad/s", line_of_sight_rate_rps);

			# calculate target acc as normal to LOS line:
			var t_heading        = me.TgtHdg_prop.getValue();
			var t_pitch          = me.TgtPitch_prop.getValue();
			var t_speed          = me.TgtSpeed_prop.getValue()*KT2FPS;#true airspeed
			var t_horz_speed     = math.abs(math.cos(t_pitch*D2R)*t_speed);
			var t_LOS_norm_head  = me.t_course + 90;
			var t_LOS_norm_speed = math.cos((t_LOS_norm_head - t_heading)*D2R)*t_horz_speed;

			if (me.last_t_norm_speed == nil) {
				me.last_t_norm_speed = t_LOS_norm_speed;
			}

			var t_LOS_norm_acc   = (t_LOS_norm_speed - me.last_t_norm_speed)/me.dt;

			me.last_t_norm_speed = t_LOS_norm_speed;

			# acceleration perpendicular to instantaneous line of sight in feet/sec^2
			var acc_sideways_ftps2 = proportionality_constant*line_of_sight_rate_rps*horz_closing_rate_fps+proportionality_constant*t_LOS_norm_acc/2;
			#printf("horz acc = %.1f + %.1f", proportionality_constant*line_of_sight_rate_rps*horz_closing_rate_fps, proportionality_constant*t_LOS_norm_acc/2);
			# now translate that sideways acc to an angle:
			var velocity_vector_length_fps = me.old_speed_horz_fps;
			var commanded_sideways_vector_length_fps = acc_sideways_ftps2*me.dt;
			me.raw_steer_signal_head = math.atan2(commanded_sideways_vector_length_fps, velocity_vector_length_fps)*R2D;

			#print(sprintf("LOS-rate=%.2f rad/s - closing-rate=%.1f ft/s",line_of_sight_rate_rps,horz_closing_rate_fps));
			#print(sprintf("commanded-perpendicular-acceleration=%.1f ft/s^2", acc_sideways_ftps2));
			#print(sprintf("horz leading by %.1f deg, commanding %.1f deg", me.curr_tgt_h, me.raw_steer_signal_head));

			if (me.cruise_or_loft == FALSE) {# and me.last_cruise_or_loft == FALSE
				# augmented proportional navigation for elevation #
				###################################################
				var vert_closing_rate_fps = me.clamp(((me.dist_direct_last - me.dist_curr_direct)*M2FT)/me.last_dt,1,1000000);
				var line_of_sight_rate_up_rps = (D2R*(me.t_elev_deg-me.last_t_elev_deg))/me.dt;

				# calculate target acc as normal to LOS line: (up acc is positive)
				var t_approach_bearing             = me.t_course + 180;
				var t_horz_speed_away_from_missile = -math.cos((t_approach_bearing - t_heading)*D2R)* t_horz_speed;
				var t_horz_comp_speed              = math.cos((90+me.t_elev_deg)*D2R)*t_horz_speed_away_from_missile;
				var t_vert_comp_speed              = math.sin(t_pitch*D2R)*t_speed*math.cos(me.t_elev_deg*D2R);
				var t_LOS_elev_norm_speed          = t_horz_comp_speed + t_vert_comp_speed;

				if (me.last_t_elev_norm_speed == nil) {
					me.last_t_elev_norm_speed = t_LOS_elev_norm_speed;
				}

				var t_LOS_elev_norm_acc            = (t_LOS_elev_norm_speed - me.last_t_elev_norm_speed)/me.dt;
				me.last_t_elev_norm_speed          = t_LOS_elev_norm_speed;

				var acc_upwards_ftps2 = proportionality_constant*line_of_sight_rate_up_rps*vert_closing_rate_fps+proportionality_constant*t_LOS_elev_norm_acc/2;
				velocity_vector_length_fps = me.old_speed_fps;
				var commanded_upwards_vector_length_fps = acc_upwards_ftps2*me.dt;
				me.raw_steer_signal_elev = math.atan2(commanded_upwards_vector_length_fps, velocity_vector_length_fps)*R2D;
			}
		}
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

				var phrase = sprintf( me.variant~" exploded: %01.1f", min_distance) ~ " meters from: " ~ ident;

				var reason = "Passed target.";
				if (groundhit == 1) {
					reason = "Hit terrain.";
				} elsif (me.life_time > me.selfdestruct_time) {
					reason = "Selfdestructed.";
				}

				if(min_distance < 65) {
					me.sendMessage(phrase);
				} else {
					me.sendMessage(me.type~" missed "~ident~": "~reason);
				}
				print(phrase~", reason: "~reason);

				# Create impact coords from this previous relative position applied to target current coord.
				me.t_coord.apply_course_distance(t_bearing_deg, t_dist_m);
				me.t_coord.set_alt(new_t_alt_m);		
				var wh_mass = me.weight_whead_lbs / slugs_to_lbs;
				#print("FOX2: me.direct_dist_m = ",  me.direct_dist_m, " time ",getprop("sim/time/elapsed-sec"));
				impact_report(me.t_coord, wh_mass, "missile"); # pos, alt, mass_slug,(speed_mps)

				me.animate_explosion();
				me.Tgt = nil;
				return(0);
			}
		}
		me.direct_dist_m = cur_dir_dist_m;
		return(1);
	},

	sendMessage: func (str) {
		if (getprop("sim/model/f15/systems/armament/mp-messaging")) {
			setprop("/sim/multiplay/chat", defeatSpamFilter(str));
		} else {
			setprop("/sim/messages/atc", str);
		}
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
		if ( awg_9.active_u != nil and awg_9.active_u.Valid.getValue()) {
			var tgt = awg_9.active_u; # In the AWG-9 radar range and horizontal field.
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
				me.TgtBearing_prop   = props.globals.getNode("radar/bearing-deg");
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

	clamp: func(v, min, max) { v < min ? min : v > max ? max : v },

	animation_flags_props: func {
		# Create animation flags properties.
		var msl_path = "sim/model/f15/systems/armament/"~me.type~"/flags/msl-id-" ~ me.ID;
		me.msl_prop = props.globals.initNode( msl_path, 1, "BOOL" );
		var smoke_path = "sim/model/f15/systems/armament/"~me.type~"/flags/smoke-id-" ~ me.ID;
		me.smoke_prop = props.globals.initNode( smoke_path, 1, "BOOL" );
		var explode_path = "sim/model/f15/systems/armament/"~me.type~"/flags/explode-id-" ~ me.ID;
		me.explode_prop = props.globals.initNode( explode_path, 0, "BOOL" );
		var explode_smoke_path = "sim/model/f15/systems/armament/"~me.type~"/flags/explode-smoke-id-" ~ me.ID;
		me.explode_smoke_prop = props.globals.initNode( explode_smoke_path, 0, "BOOL" );
        printf("%s %s", smoke_path, me.smoke_prop.getValue());
        printf("%s %s", explode_path, me.explode_prop.getValue());
        printf("%s %s", explode_smoke_path, me.explode_smoke_prop.getValue());
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
        var steer_deg = math.sqrt((steering_e_deg*steering_e_deg)+(steering_h_deg*steering_h_deg));

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
        }else{
			guess = guess - coef;
        }
}
	return lastgoodguess;
}


# HUD clamped target blinker
SW_reticle_Blinker = aircraft.light.new("sim/model/f15/lighting/hud-sw-reticle-switch", [0.1, 0.1]);
setprop("sim/model/f15/lighting/hud-sw-reticle-switch/enabled", 1);

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