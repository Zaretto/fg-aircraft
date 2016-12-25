#################################################################################
#######	
####### Guided/Cruise missiles, rockets and dumb/glide bombs code for Flightgear.
#######
####### License: GPL 2
#######
####### Authors:
#######  Alexis Bory, Fabien Barbier, Justin Nicholson, Nikolai V. Chr.
####### 
####### In addition, some code is derived from work by:
#######  David Culp, Vivian Meazza, M. Franz
#######
##################################################################################

# Some notes about making weapons:
#
# Firstly make sure you read the comments (line 180+) below for the properties.
# For laser/gps guided gravity bombs make sure to set the max G very low, like 0.5G, to simulate them slowly adjusting to hit the target.
# Remember for air to air missiles the speed quoted in litterature is normally the speed above the launch platform. I usually fly at the typical usage
#   regime for that missile, so for example for sidewinder it would be mach 1+ at 20000 ft,
#   there I make sure it can reach approx the max relative speed. For older missiles the max speed quoted is sometimes absolute speed though, so beware.
#   If it quotes aerodynamic speed then its the absolute speed. Speeds quoted in in unofficial sources can be any of them,
#   but if its around mach 5 for A/A its a good bet its absolute, only very few A/A missiles are likely hypersonic.
# Stage durations is allowed to be 0, so can thrust values. If there is no second stage, instead of just setting stage 2 thrust to 0,
#   set stage 2 duration to 0 also. For unpowered munitions, set all thrusts to 0.
# For very low sea skimming missiles, be sure to set terrain following to false, you cannot have it both ways.
#   Since if it goes very low (below 100ft), it cannot navigate terrain reliable.
# The property terrain following only goes into effect, if a cruise altitude is set below 10000ft and not set to 0.
#   Cruise missiles against ground targets will always terrain follow, no matter that property.
# If litterature quotes a max distance for a weapon, its a good bet it is under the condition that the target
#   is approaching the launch platform with high speed and does not evade, and also if the launch platform is an aircraft,
#   that it also is approaching the target with high speed. In other words, high closing rate. For example the AIM-7, which can hit bombers out at 32 NM,
#   will often have to be within 3 NM of an escaping target to hit it (source). Missiles typically have significantly less range against an evading
#   or escaping target than what is commonly believed. I typically fly at 20000 ft at mach 1, approach a target flying at me with same speed and altitude,
#   to test max range.
# When you test missiles against aircraft, be sure to do it with a framerate of 25+, else they will not hit very good, especially high speed missiles like
#   Amraam or Phoenix. Also notice they generally not hit so close against Scenario/AI objects compared to MP aircraft due to the way these are updated.
# Laser and semi-radar guided munitions need the target to be painted to keep lock. Notice gps guided munition that are all aspect will never lose lock,
#   whether they can 'see' the target or not.
# Remotely controlled navigation is not implemented, but the way it flies can be simulated by setting direct navigation with semi-radar or laser guidance.
#
#
# Usage:
#
# To create a weapon call AIM.new(pylon, type, description). The pylon is an integer from 0 or higher. When its launched it will read the pylon position in
#   controls/armament/station[pylon+1]/offsets, where the position properties must be x-m, y-m and z-m. The type is just a string, the description is a string
#   that is exposed in its radar properties under AI/models during flight.
# The model that is loaded and shown is located in the aircraft folder at the value of property payload/armament/models in a subfolder with same name as type.
#   Inside the subfolder the xml file is called [lowercase type]-[pylon].xml
# To start making the missile try to get a lock, set its status to MISSILE_SEARCH and call search(), the missile will then keep trying to get a lock on 'contact'.
#   'contact' can be set to nil at any time or changed. To stop the search, just set its status to MISSILE_STANDBY. To resume the search you again have to set
#   the status and call search().
# To release the munition at a target call release(), do this only after the missile has set its own status to MISSILE_LOCK.
# When using weapons without target, call releaseAtNothing() instead of release(), search() does not need to have been called beforehand.
#   To then find out where it hit the ground check the impact report in AI/models. The impact report will contain warhead weight, but that will be zero if
#   the weapon did not have time to arm before hitting ground.
# To drop the munition, without arming it nor igniting its engine, call eject().
# 
#
# Limitations:
# 
# The weapons use a simplified flight model that does not have AoA or sideslip. Mass balance, rotational inertia, wind is also not implemented. They also do not roll.
# If you fire a weapon and have HoT enabled in flightgear, they likely will not hit very precise.
# The weapons are highly dependant on framerate, so low frame rate will make them hit imprecise.
# APN does not take target sideslip and AoA into account when considering the targets acceleration. It assumes the target flies in the direction its pointed.
# The drag curves are tailored for sizable munitions, so it does not work well will bullet or cannon sized munition, submodels are better suited for that.
#
#
# Future features:
#
# Make ground hitting weapons hit all nearby targets, not just what its locked on.
# Chaff interaction for radar guided weapons.
# ECM disturbance of getting radar lock.
# Lock on jam. (advanced feature)
# After FG gets HLA: stop using MP chat for hit messages.
# Allow firing only if certain conditions are met. Like not being inverted when firing dropped weapons.
# Remote controlled guidance (advanced feature and probably not very practical in FG..yet)
# Ground launched rails/tubes that rotate towards target before firing.
# Make weapon unreliable by design, to simulate weapons which were unreliable, like Phoenix.
# Sub munitions that have their own guidance/FDM. (advanced)
# GPS guided munitions could have waypoints added.
# Specify terminal manouvres and preferred impact aspect.
# Limit guiding if needed so that the missile don't lose sight of target.
# Change flare to use helicopter property double.
# Make check for seeker FOV round instead of square.
# Consider to average the closing speed in proportional navigation. So get it between second last positions and current, instead of last to currect.
# Drag coeff due to exhaust.
#
# Please report bugs and features to Nikolai V. Chr. | ForumUser: Necolatis | Callsign: Leto

var AcModel        = props.globals.getNode("payload");
var OurHdg         = props.globals.getNode("orientation/heading-deg");
var OurRoll        = props.globals.getNode("orientation/roll-deg");
var OurPitch       = props.globals.getNode("orientation/pitch-deg");
var OurAlpha       = props.globals.getNode("orientation/alpha-deg");
var OurBeta        = props.globals.getNode("orientation/side-slip-deg");
var deltaSec       = props.globals.getNode("sim/time/delta-sec");
var speedUp        = props.globals.getNode("sim/speed-up");
var noseAir        = props.globals.getNode("velocities/uBody-fps");
var belowAir       = props.globals.getNode("velocities/wBody-fps");
var HudReticleDev  = props.globals.getNode("payload/armament/hud/reticle-total-deviation", 1);#polar coords
var HudReticleDeg  = props.globals.getNode("payload/armament/hud/reticle-total-angle", 1);
var update_loop_time = 0.000;

var SIM_TIME = 0;
var REAL_TIME = 1;

var TRUE = 1;
var FALSE = 0;

var use_fg_default_hud = FALSE;

var MISSILE_STANDBY = -1;
var MISSILE_SEARCH = 0;
var MISSILE_LOCK = 1;
var MISSILE_FLYING = 2;

var AIR = 0;
var MARINE = 1;
var SURFACE = 2;
var ORDNANCE = 3;

var g_fps        = 9.80665 * M2FT;
var slugs_to_lbm = 32.1740485564;
var const_e = 2.71828183;

var first_in_air = FALSE;# first missile is in the air, other missiles should not write to blade[x].

#
# The radar will make sure to keep this variable updated.
# Whatever is targeted and ready to be fired upon, should be set here.
#
var contact = nil;
#
# Contact should implement the following interface:
#
# get_type()      - (AIR, MARINE, SURFACE or ORDNANCE)
# getUnique()     - Used when comparing 2 targets to each other and determining if they are the same target.
# isValid()       - If this target is valid
# getElevation()
# get_bearing()
# get_Callsign()
# get_range()
# get_Coord()
# get_Latitude()
# get_Longitude()
# get_altitude()
# get_Pitch()
# get_heading()
# getFlareNode()  - Used for flares.
# isPainted()     - Tells if this target is still being tracked by the launch platform, only used in semi-radar and laser guided missiles.

var AIM = {
	#done
	new : func (p, type = "AIM-9", sign = "Sidewinder") {
		if(AIM.active[p] != nil) {
			#do not make new missile logic if one exist for this pylon.
			return -1;
		}
		var m = { parents : [AIM]};
		# Args: p = Pylon.

		m.type_lc = string.lc(type);
		m.type = type;

		m.deleted = FALSE;

		m.status            = MISSILE_STANDBY; # -1 = stand-by, 0 = searching, 1 = locked, 2 = fired.
		m.free              = 0; # 0 = status fired with lock, 1 = status fired but having lost lock.
		m.trackWeak         = 1;

		m.prop              = AcModel.getNode("armament/"~m.type_lc~"/").getChild("msl", 0, 1);
		m.SwSoundOnOff      = AcModel.getNode("armament/"~m.type_lc~"/sound-on-off");
        m.SwSoundVol        = AcModel.getNode("armament/"~m.type_lc~"/sound-volume");
		m.PylonIndex        = m.prop.getNode("pylon-index", 1).setValue(p);
		m.ID                = p;
		m.pylon_prop        = props.globals.getNode("controls/armament").getChild("station", p+1);
		m.Tgt               = nil;
		m.callsign          = "Unknown";
		m.update_track_time = 0;
		m.direct_dist_m     = nil;
		m.speed_m           = 0;

		# AIM specs:
		m.fcs_fov               = getprop("payload/armament/"~m.type_lc~"/FCS-field-deg") / 2;          # fire control system total field of view
		m.max_detect_rng        = getprop("payload/armament/"~m.type_lc~"/max-fire-range-nm");          # max range that the FCS allows firing
		m.max_seeker_dev        = getprop("payload/armament/"~m.type_lc~"/seeker-field-deg") / 2;       # missiles own seekers total FOV
		m.force_lbf_1           = getprop("payload/armament/"~m.type_lc~"/thrust-lbf-stage-1");         # stage 1 thrust, set both stages to zero to simulate gravity bomb, set them to 1 to simulate glide bomb
		m.force_lbf_2           = getprop("payload/armament/"~m.type_lc~"/thrust-lbf-stage-2");         # stage 2 thrust
		m.stage_1_duration      = getprop("payload/armament/"~m.type_lc~"/stage-1-duration-sec");       # stage 1 duration
		m.stage_2_duration      = getprop("payload/armament/"~m.type_lc~"/stage-2-duration-sec");       # stage 2 duration
		m.weight_launch_lbm     = getprop("payload/armament/"~m.type_lc~"/weight-launch-lbs");          # total weight of armament, including fuel and warhead.
		m.weight_whead_lbm      = getprop("payload/armament/"~m.type_lc~"/weight-warhead-lbs");         # warhead weight
		m.weight_fuel_lbm       = getprop("payload/armament/"~m.type_lc~"/weight-fuel-lbm");            # fuel weight [optional]. If this property is not present, it won't lose weight as the fuel is used.
		m.Cd_base               = getprop("payload/armament/"~m.type_lc~"/drag-coeff");                 # drag coefficient
		m.eda                   = getprop("payload/armament/"~m.type_lc~"/drag-area");                  # normally is crosssection area of munition (without fins)
		m.max_g                 = getprop("payload/armament/"~m.type_lc~"/max-g");                      # max G-force the missile can pull at sealevel
		m.arming_time           = getprop("payload/armament/"~m.type_lc~"/arming-time-sec");            # time for weapon to arm
		m.min_speed_for_guiding = getprop("payload/armament/"~m.type_lc~"/min-speed-for-guiding-mach"); # minimum speed before the missile steers, before it reaches this speed it will fly straight
		m.selfdestruct_time     = getprop("payload/armament/"~m.type_lc~"/self-destruct-time-sec");     # time before selfdestruct
		m.guidance              = getprop("payload/armament/"~m.type_lc~"/guidance");                   # heat/radar/semi-radar/laser/gps/vision/unguided
		m.navigation            = getprop("payload/armament/"~m.type_lc~"/navigation");                 # direct/PN/APN (use direct for bombs, use PN for very old missiles, use APN for modern missiles)
		m.all_aspect            = getprop("payload/armament/"~m.type_lc~"/all-aspect");                 # set to false if missile only locks on reliably to rear of target aircraft
		m.vol_search            = getprop("payload/armament/"~m.type_lc~"/vol-search");                 # sound volume when searcing
		m.vol_track             = getprop("payload/armament/"~m.type_lc~"/vol-track");                  # sound volume when having lock
		m.vol_track_weak        = getprop("payload/armament/"~m.type_lc~"/vol-track-weak");             # sound volume before getting solid lock
		m.angular_speed         = getprop("payload/armament/"~m.type_lc~"/seeker-angular-speed-dps");   # only for heat/vision seeking missiles. Max angular speed that the target can move as seen from seeker, before seeker loses lock.
		m.sun_lock              = getprop("payload/armament/"~m.type_lc~"/lock-on-sun-deg");            # only for heat seeking missiles. If it looks at sun within this angle, it will lose lock on target.
        m.loft_alt              = getprop("payload/armament/"~m.type_lc~"/loft-altitude");              # if 0 then no snap up. Below 10000 then cruise altitude above ground. Above 10000 max altitude it will snap up to.
        m.follow                = getprop("payload/armament/"~m.type_lc~"/terrain-follow");             # used for anti-ship missiles that should be able to terrain follow instead of purely sea skimming.
        m.min_dist              = getprop("payload/armament/"~m.type_lc~"/min-fire-range-nm");          # it wont get solid lock before the target has this range
        m.rail                  = getprop("payload/armament/"~m.type_lc~"/rail");                       # if the weapon is rail or tube fired set to true. If dropped 7ft before ignited set to false.
        m.rail_dist_m           = getprop("payload/armament/"~m.type_lc~"/rail-length-m");              # length of tube/rail
        m.rail_forward          = getprop("payload/armament/"~m.type_lc~"/rail-point-forward");         # true for rail, false for vertical tube
        m.class                 = getprop("payload/armament/"~m.type_lc~"/class");                      # put in letters here that represent the types the missile can fire at. A=air, M=marine, G=ground
        m.brevity               = getprop("payload/armament/"~m.type_lc~"/fire-msg");                   # what the pilot will call out over the comm when he fires this weapon
        m.reportDist            = getprop("payload/armament/"~m.type_lc~"/max-report-distance");        # max distance from target the missile will report that it has exploded, instead of just passed.


		m.weapon_model          = getprop("payload/armament/models")~type~"/"~m.type_lc~"-";
		m.elapsed_last          = 0;

		m.target_air = find("A", m.class)==-1?FALSE:TRUE;
		m.target_sea = find("M", m.class)==-1?FALSE:TRUE;#use M for marine, since S can be confused with surface.
		m.target_gnd = find("G", m.class)==-1?FALSE:TRUE;

		if (m.navigation == nil) {
			m.navigation = "APN";
		}

		# Find the next index for "models/model" and create property node.
		# Find the next index for "ai/models/aim-9" and create property node.
		# (M. Franz, see Nasal/tanker.nas)
		var n = props.globals.getNode("models", 1);
		var i = 0;
		for (i = 0; 1==1; i += 1) {
			if (n.getChild("model", i, 0) == nil) {
				break;
			}
		}
		m.model = n.getChild("model", i, 1);
		
		n = props.globals.getNode("ai/models", 1);
		for (i = 0; 1==1; i += 1) {
			if (n.getChild(m.type_lc, i, 0) == nil) {
				break;
			}
		}
		m.ai = n.getChild(m.type_lc, i, 1);

		m.ai.getNode("valid", 1).setBoolValue(1);
		m.ai.getNode("name", 1).setValue(type);
		m.ai.getNode("sign", 1).setValue(sign);
		#m.model.getNode("collision", 1).setBoolValue(0);
		#m.model.getNode("impact", 1).setBoolValue(0);
		var id_model = m.weapon_model ~ m.ID ~ ".xml";
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
		m.paused             = 0;
		m.old_speed_fps	     = 0;
		m.dt                 = 0;
		m.g                  = 0;

		# navigation and guidance
		m.last_deviation_e       = nil;
		m.last_deviation_h       = nil;
		m.last_track_e           = 0;
		m.last_track_h           = 0;
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
		m.curr_deviation_e       = 0;
		m.curr_deviation_h       = 0;
		m.track_signal_e         = 0;
		m.track_signal_h         = 0;

		# cruise-missiles
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

		# stats
		m.maxMach     = 0;
		m.energyBleedKt = 0;

		m.lastFlare = 0;
		m.fooled = FALSE;
		m.explodeSound = TRUE;
		m.first = FALSE;

		# these 3 is used for limiting spam to console:
		m.heatLostLock = FALSE;
		m.semiLostLock = FALSE;
		m.tooLowSpeed  = FALSE;

		m.SwSoundOnOff.setBoolValue(FALSE);
		m.SwSoundVol.setDoubleValue(m.vol_search);
		#me.trackWeak = 1;

		return AIM.active[m.ID] = m;
	},
	
	del: func {#GCD (garbage collection optimization done)
		#print("deleted");
		if (me.first == TRUE) {
			me.resetFirst();
		}
		me.model.remove();
		me.ai.remove();
		if (me.status == MISSILE_FLYING) {
			delete(AIM.flying, me.flyID);
		} else {
			delete(AIM.active, me.ID);
		}
		me.SwSoundVol.setDoubleValue(0);
		me.deleted = TRUE;
	},

	getGPS: func(x, y, z) {#GCD
		#
		# get Coord from body position. x,y,z must be in meters.
		# derived from Vivian's code in AIModel/submodel.cxx.
		#
		me.ac = geo.aircraft_position();

		if(x == 0 and y==0 and z==0) {
			return geo.Coord.new(me.ac);
		}

		me.ac_roll = OurRoll.getValue();
		me.ac_pitch = OurPitch.getValue();
		me.ac_hdg   = OurHdg.getValue();

		me.in    = [0,0,0];
		me.trans = [[0,0,0],[0,0,0],[0,0,0]];
		me.out   = [0,0,0];

		me.in[0] =  -x * M2FT;
		me.in[1] =   y * M2FT;
		me.in[2] =   z * M2FT;
		# Pre-process trig functions:
		me.cosRx = math.cos(-me.ac_roll * D2R);
		me.sinRx = math.sin(-me.ac_roll * D2R);
		me.cosRy = math.cos(-me.ac_pitch * D2R);
		me.sinRy = math.sin(-me.ac_pitch * D2R);
		me.cosRz = math.cos(me.ac_hdg * D2R);
		me.sinRz = math.sin(me.ac_hdg * D2R);
		# Set up the transform matrix:
		me.trans[0][0] =  me.cosRy * me.cosRz;
		me.trans[0][1] =  -1 * me.cosRx * me.sinRz + me.sinRx * me.sinRy * me.cosRz ;
		me.trans[0][2] =  me.sinRx * me.sinRz + me.cosRx * me.sinRy * me.cosRz;
		me.trans[1][0] =  me.cosRy * me.sinRz;
		me.trans[1][1] =  me.cosRx * me.cosRz + me.sinRx * me.sinRy * me.sinRz;
		me.trans[1][2] =  -1 * me.sinRx * me.cosRx + me.cosRx * me.sinRy * me.sinRz;
		me.trans[2][0] =  -1 * me.sinRy;
		me.trans[2][1] =  me.sinRx * me.cosRy;
		me.trans[2][2] =  me.cosRx * me.cosRy;
		# Multiply the input and transform matrices:
		me.out[0] = me.in[0] * me.trans[0][0] + me.in[1] * me.trans[0][1] + me.in[2] * me.trans[0][2];
		me.out[1] = me.in[0] * me.trans[1][0] + me.in[1] * me.trans[1][1] + me.in[2] * me.trans[1][2];
		me.out[2] = me.in[0] * me.trans[2][0] + me.in[1] * me.trans[2][1] + me.in[2] * me.trans[2][2];
		# Convert ft to degrees of latitude:
		me.out[0] = me.out[0] / (366468.96 - 3717.12 * math.cos(me.ac.lat() * D2R));
		# Convert ft to degrees of longitude:
		me.out[1] = me.out[1] / (365228.16 * math.cos(me.ac.lat() * D2R));
		# Set submodel initial position:
		me.mlat = me.ac.lat() + me.out[0];
		me.mlon = me.ac.lon() + me.out[1];
		me.malt = (me.ac.alt() * M2FT) + me.out[2];
		
		me.c = geo.Coord.new();
		me.c.set_latlon(me.mlat, me.mlon, me.malt * FT2M);

		return me.c;
	},

	eject: func () {#GCD
		me.stage_1_duration = 0;
		me.force_lbf_1      = 0;
		me.stage_2_duration = 0;
		me.force_lbf_2      = 0;
		me.arming_time      = 5000;
		me.rail             = FALSE;
		me.releaseAtNothing();
	},

	releaseAtNothing: func() {#GCD
		me.Tgt = nil;
		me.release();
	},

	release: func() {#GCn
		# Release missile/bomb from its pylon/rail/tube and send it away.
		#
		me.status = MISSILE_FLYING;
		me.flyID = rand();
		AIM.flying[me.flyID] = me;
		delete(AIM.active, me.ID);
		me.animation_flags_props();

		# Get the A/C position and orientation values.
		me.ac = geo.aircraft_position();
		me.ac_init = geo.Coord.new(me.ac);
		var ac_roll = OurRoll.getValue();# positive is banking right
		var ac_pitch = OurPitch.getValue();
		var ac_hdg   = OurHdg.getValue();

		# Compute missile initial position relative to A/C center
		me.x = me.pylon_prop.getNode("offsets/x-m").getValue();
		me.y = me.pylon_prop.getNode("offsets/y-m").getValue();
		me.z = me.pylon_prop.getNode("offsets/z-m").getValue();
		var init_coord = me.getGPS(me.x, me.y, me.z);

		# Set submodel initial position:
		var mlat = init_coord.lat();
		var mlon = init_coord.lon();
		var malt = init_coord.alt() * M2FT;
		me.latN.setDoubleValue(mlat);
		me.lonN.setDoubleValue(mlon);
		me.altN.setDoubleValue(malt);
		me.hdgN.setDoubleValue(ac_hdg);

		if (me.rail == FALSE) {
			# drop distance in time
			me.drop_time = math.sqrt(2*7/g_fps);# time to fall 7 ft to clear aircraft
		}

		me.pitchN.setDoubleValue(ac_pitch);
		me.rollN.setDoubleValue(0);

		me.coord = geo.Coord.new(init_coord);

		me.model.getNode("latitude-deg-prop", 1).setValue(me.latN.getPath());
		me.model.getNode("longitude-deg-prop", 1).setValue(me.lonN.getPath());
		me.model.getNode("elevation-ft-prop", 1).setValue(me.altN.getPath());
		me.model.getNode("heading-deg-prop", 1).setValue(me.hdgN.getPath());
		me.model.getNode("pitch-deg-prop", 1).setValue(me.pitchN.getPath());
		me.model.getNode("roll-deg-prop", 1).setValue(me.rollN.getPath());
		var loadNode = me.model.getNode("load", 1);
		loadNode.setBoolValue(1);

		# Get initial velocity vector (aircraft):
		me.speed_down_fps = getprop("velocities/speed-down-fps");
		me.speed_east_fps = getprop("velocities/speed-east-fps");
		me.speed_north_fps = getprop("velocities/speed-north-fps");
		if (me.rail == TRUE) {
			if (me.rail_forward == FALSE) {
				# rail is actually a tube pointing upward
				me.rail_speed_into_wind = -getprop("velocities/wBody-fps");# wind from below
			} else {
				# rail is pointing forward
				me.rail_speed_into_wind = getprop("velocities/uBody-fps");# wind from nose
			}
		}

		me.alt_ft = malt;
		me.pitch = ac_pitch;
		me.hdg = ac_hdg;

		if (getprop("sim/flight-model") == "jsb") {
			# currently not supported in Yasim
			me.density_alt_diff = getprop("fdm/jsbsim/atmosphere/density-altitude") - me.ac.alt()*M2FT;
		}
		if (me.Tgt != nil) {
			var dst = me.coord.distance_to(me.Tgt.get_Coord()) * M2NM;
			if (me.loft_alt > 36000) {
				#for phoenix missile
				#f(x) = y1 + ((x - x1) / (x2 - x1)) * (y2 - y1)
				me.loft_alt = 36000+((dst-38)/(me.max_detect_rng-38))*(me.loft_alt-36000);
				me.loft_alt = me.clamp(me.loft_alt, 10001, 200000);
				#printf("Loft to max %5d ft.", me.loft_alt);
			} elsif (me.loft_alt > 10000) {
				#
				# adjust the snap-up altitude to initial distance of target.
				#			
				me.loft_alt = me.loft_alt - ((me.max_detect_rng - 10) - (dst - 10))*500;
				me.loft_alt = me.clamp(me.loft_alt, 10001, 200000);
				#printf("Loft to max %5d ft.", me.loft_alt);
			}
		}


		me.SwSoundVol.setDoubleValue(0);
		me.trackWeak = 1;
		#settimer(func { HudReticleDeg.setValue(0) }, 2);
		#interpolate(HudReticleDev, 0, 2);

		me.startMach = getprop("velocities/mach");
		me.startAlt  = getprop("position/altitude-ft");
		me.startDist = 0;
		me.maxAlt = me.startAlt;
		if (me.Tgt != nil) {
			me.startDist = me.ac_init.direct_distance_to(me.Tgt.get_Coord());
		}
		printf("Launch %s at %s.", me.type, me.callsign);

		me.weight_current = me.weight_launch_lbm;
		me.mass = me.weight_launch_lbm / slugs_to_lbm;

		# find the fuel consumption - lbm/sec
		if (me.weight_fuel_lbm == nil) {
			me.weight_fuel_lbm = 0;
		}
		var energy1 = me.force_lbf_1 * me.stage_1_duration;
		var energy2 = me.force_lbf_2 * me.stage_2_duration;
		var energyT = energy1 + energy2;
		var fuel_per_energy = me.weight_fuel_lbm / energyT;
		me.fuel_per_sec_1  = (fuel_per_energy * energy1) / me.stage_1_duration;
		me.fuel_per_sec_2  = (fuel_per_energy * energy2) / me.stage_2_duration;

		# find the sun:
		if(me.guidance == "heat") {
			var sun_x = getprop("ephemeris/sun/local/x");
			var sun_y = getprop("ephemeris/sun/local/x");
			var sun_z = getprop("ephemeris/sun/local/x");
			me.sun_power = getprop("/rendering/scene/diffuse/red");
			me.sun = geo.Coord.new(me.ac_init);
			me.sun.set_xyz(me.sun.x()+sun_x*200000, me.sun.y()+sun_y*200000, me.sun.z()+sun_z*200000);#heat seeking missiles don't fly far, so setting it 200Km away is fine.
		}
		me.lock_on_sun = FALSE;

		me.flight();
		loadNode.remove();
	},

	drag: func (mach) {#GCD
		# Nikolai V. Chr.: Made the drag calc more in line with big missiles as opposed to small bullets.
		# 
		# The old equations were based on curves for a conventional shell/bullet (no boat-tail),
		# and derived from Davic Culps code in AIBallistic.
		me.Cd = 0;
		if (mach < 0.7) {
			me.Cd = (0.0125 * mach + 0.20) * 5 * me.Cd_base;
		} elsif (mach < 1.2 ) {
			me.Cd = (0.3742 * math.pow(mach, 2) - 0.252 * mach + 0.0021 + 0.2 ) * 5 * me.Cd_base;
		} else {
			me.Cd = (0.2965 * math.pow(mach, -1.1506) + 0.2) * 5 * me.Cd_base;
		}

		return me.Cd;
	},

	maxG: func (rho, max_g_sealevel) {#GCD
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

	thrust: func () {#GCD
		# Determine the thrust at this moment.
		#
		# If dropped, then ignited after fall time of what is the equivalent of 7ft.
		# If the rocket is 2 stage, then ignite the second stage when 1st has burned out.
		#
		me.thrust_lbf = 0;# pounds force (lbf)
		if (me.life_time > me.drop_time) {
			me.thrust_lbf = me.force_lbf_1;
		}
		if (me.life_time > me.stage_1_duration + me.drop_time) {
			me.thrust_lbf = me.force_lbf_2;
		}
		if (me.life_time > (me.drop_time + me.stage_1_duration + me.stage_2_duration)) {
			me.thrust_lbf = 0;
		}
		if (me.thrust_lbf < 1) {
			me.smoke_prop.setBoolValue(0);
		} else {
			me.smoke_prop.setBoolValue(1);
		}
		return me.thrust_lbf;
	},

	speedChange: func (thrust_lbf, rho, Cd) {#GCD
		# Calculate speed change from last update.
		#
		# Acceleration = thrust/mass - drag/mass;
		
		me.acc = thrust_lbf / me.mass;
		me.q = 0.5 * rho * me.old_speed_fps * me.old_speed_fps;# dynamic pressure
		me.drag_acc = (me.Cd * me.q * me.eda) / me.mass;

		# get total new speed change (minus gravity)
		return me.acc*me.dt - me.drag_acc*me.dt;
	},

    energyBleed: func (gForce, altitude) {#GCD
        # Bleed of energy from pulling Gs.
        # This is very inaccurate, but better than nothing.
        #
        # First we get the speedloss due to normal drag:
        me.b300 = me.bleed32800at0g();
        me.b000 = me.bleed0at0g();
        #
        # We then subtract the normal drag from the loss due to G and normal drag.
        me.b325 = me.bleed32800at25g()-me.b300;
        me.b025 = me.bleed0at25g()-me.b000;
        me.b300 = 0;
        me.b000 = 0;
        #
        # We now find what the speedloss will be at sealevel and 32800 ft.
        me.speedLoss32800 = me.b300 + ((gForce-0)/(25-0))*(me.b325 - me.b300);
        me.speedLoss0 = me.b000 + ((gForce-0)/(25-0))*(me.b025 - me.b000);
        #
        # We then inter/extra-polate that to the currect density-altitude.
        me.speedLoss = me.speedLoss0 + ((altitude-0)/(32800-0))*(me.speedLoss32800-me.speedLoss0);
        #
        # For good measure the result is clamped to below zero.
        me.speedLoss = me.clamp(me.speedLoss, -100000, 0);
        me.energyBleedKt += me.speedLoss * FPS2KT;
        return me.speedLoss;
    },

	bleed32800at0g: func () {#GCD
		me.loss_fps = 0 + ((me.last_dt - 0)/(15 - 0))*(-330 - 0);
		return me.loss_fps*M2FT;
	},

	bleed32800at25g: func () {#GCD
		me.loss_fps = 0 + ((me.last_dt - 0)/(3.5 - 0))*(-240 - 0);
		return me.loss_fps*M2FT;
	},

	bleed0at0g: func () {#GCD
		me.loss_fps = 0 + ((me.last_dt - 0)/(22 - 0))*(-950 - 0);
		return me.loss_fps*M2FT;
	},

	bleed0at25g: func () {#GCD
		me.loss_fps = 0 + ((me.last_dt - 0)/(7 - 0))*(-750 - 0);
		return me.loss_fps*M2FT;
	},

	flight: func {#GCD
		if (me.Tgt != nil and me.Tgt.isValid() == FALSE) {
			print(me.type~": Target went away, deleting missile.");
			me.del();
			return;
		}
		me.dt = deltaSec.getValue();#TODO: time since last time nasal timers were called
		if (me.dt == 0) {
			#FG is likely paused
			me.paused = 1;
			settimer(func me.flight(), 0.00);
			return;
		}
		#if just called from release() then dt is almost 0 (cannot be zero as we use it to divide with)
		# It can also not be too small, then the missile will lag behind aircraft and seem to be fired from behind the aircraft.
		#dt = dt/2;
		me.elapsed = systime();
		if (me.paused == 1) {
			# sim has been unpaused lets make sure dt becomes very small to let elapsed time catch up.
			me.paused = 0;
			me.elapsed_last = me.elapsed-0.02;
		}
		me.init_launch = 0;
		if (me.elapsed_last != 0) {
			#if (getprop("sim/speed-up") == 1) {
				me.dt = (me.elapsed - me.elapsed_last)*speedUp.getValue();
			#} else {
			#	dt = getprop("sim/time/delta-sec")*getprop("sim/speed-up");
			#}
			me.init_launch = 1;
			if(me.dt <= 0) {
				# to prevent pow floating point error in line:cdm = 0.2965 * math.pow(me.speed_m, -1.1506) + me.cd;
				# could happen if the OS adjusts the clock backwards
				me.dt = 0.00001;
			}
		}
		me.elapsed_last = me.elapsed;

		
		me.life_time += me.dt;
		

		me.thrust_lbf = me.thrust();# pounds force (lbf)

		
		# Get total old speed, thats what we will use in next loop.
		me.old_speed_horz_fps = math.sqrt((me.speed_east_fps*me.speed_east_fps)+(me.speed_north_fps*me.speed_north_fps));
		me.old_speed_fps = math.sqrt((me.old_speed_horz_fps*me.old_speed_horz_fps)+(me.speed_down_fps*me.speed_down_fps));

		me.setRadarProperties(me.old_speed_fps);

		

		# Get air density and speed of sound (fps):
		me.rs = me.rho_sndspeed(me.altN.getValue() + me.density_alt_diff);
		me.rho = me.rs[0];
		me.sound_fps = me.rs[1];

		me.max_g_current = me.maxG(me.rho, me.max_g);

		me.speed_m = me.old_speed_fps / me.sound_fps;

		if (me.speed_m > me.maxMach) {
			me.maxMach = me.speed_m;
		}

		me.Cd = me.drag(me.speed_m);

		me.speed_change_fps = me.speedChange(me.thrust_lbf, me.rho, me.Cd);
		

		if (me.last_dt != 0) {
			me.speed_change_fps = me.speed_change_fps + me.energyBleed(me.g, me.altN.getValue() + me.density_alt_diff);
		}

		# Get target position.
		if (me.Tgt != nil) {
			me.t_coord = me.Tgt.get_Coord();
		}

		###################
		#### Guidance.#####
		###################
		if (me.Tgt != nil and me.free == FALSE and me.guidance != "unguided"
			and (me.rail == FALSE or me.rail_passed == TRUE)) {
				#
				# Here we figure out how to guide, navigate and steer.
				#
				me.guide();
				me.limitG();
				
	            me.pitch      += me.track_signal_e;
            	me.hdg        += me.track_signal_h;
	            #printf("%.1f deg elevation command done, new pitch: %.1f deg", me.track_signal_e, pitch_deg);
	            #printf("%.1f deg bearing command done, new heading: %.1f", me.last_track_h, hdg_deg);
		} else {
			me.track_signal_e = 0;
			me.track_signal_h = 0;
		}
       	me.last_track_e = me.track_signal_e;
		me.last_track_h = me.track_signal_h;

		me.new_speed_fps        = me.speed_change_fps + me.old_speed_fps;
		if (me.new_speed_fps < 0) {
			# drag and bleed can theoretically make the speed less than 0, this will prevent that from happening.
			me.new_speed_fps = 0.001;
		}

		# Break speed change down total speed to North, East and Down components.
		me.speed_down_fps       = -math.sin(me.pitch * D2R) * me.new_speed_fps;
		me.speed_horizontal_fps = math.cos(me.pitch * D2R) * me.new_speed_fps;
		me.speed_north_fps      = math.cos(me.hdg * D2R) * me.speed_horizontal_fps;
		me.speed_east_fps       = math.sin(me.hdg * D2R) * me.speed_horizontal_fps;
		me.speed_down_fps      += g_fps * me.dt;

		if (me.rail == TRUE and me.rail_passed == FALSE) {
			# missile still on rail, lets calculate its speed relative to the wind coming in from the aircraft nose.
			me.rail_speed_into_wind = me.rail_speed_into_wind + me.speed_change_fps;
		} else {
			# gravity acc makes the weapon pitch down			
			me.pitch = math.atan2(-me.speed_down_fps, me.speed_horizontal_fps ) * R2D;
		}

		

		#printf("down_s=%.1f grav=%.1f", me.speed_down_fps*me.dt, g_fps * me.dt * !grav_bomb * me.dt);

		if (me.rail == TRUE and me.rail_passed == FALSE) {
			me.u = noseAir.getValue();# airstream from nose
			#var v = getprop("velocities/vBody-fps");# airstream from side
			me.w = belowAir.getValue();# airstream from below

			if (me.rail_forward == TRUE) {
				me.pitch = OurPitch.getValue();
				me.opposing_wind = me.u;
				me.hdg = OurHdg.getValue();
			} else {
				me.pitch = 90;
				me.opposing_wind = -me.w;
				me.hdg = me.Tgt.get_bearing();
			}			

			me.speed_on_rail = me.clamp(me.rail_speed_into_wind - me.opposing_wind, 0, 1000000);
			me.movement_on_rail = me.speed_on_rail * me.dt;
			
			me.rail_pos = me.rail_pos + me.movement_on_rail;
			if (me.rail_forward == TRUE) {
				me.x = me.x - (me.movement_on_rail * FT2M);# negative cause positive is rear in body coordinates
			} else {
				me.z = me.z + (me.movement_on_rail * FT2M);# positive cause positive is up in body coordinates
			}
		}

		if (me.rail == FALSE or me.rail_passed == TRUE) {
			# misssile not on rail, lets move it to next waypoint
			me.alt_ft = me.alt_ft - (me.speed_down_fps * me.dt);
			me.dist_h_m = me.speed_horizontal_fps * me.dt * FT2M;
			me.coord.apply_course_distance(me.hdg, me.dist_h_m);
			me.coord.set_alt(me.alt_ft * FT2M);
		} else {
			# missile on rail, lets move it on the rail
			me.coord = me.getGPS(me.x, me.y, me.z);
			me.alt_ft = me.coord.alt() * M2FT;
			# find its speed, for used in calc old speed
			me.speed_down_fps       = -math.sin(me.pitch * D2R) * me.rail_speed_into_wind;
			me.speed_horizontal_fps = math.cos(me.pitch * D2R) * me.rail_speed_into_wind;
			me.speed_north_fps      = math.cos(me.hdg * D2R) * me.speed_horizontal_fps;
			me.speed_east_fps       = math.sin(me.hdg * D2R) * me.speed_horizontal_fps;
		}
		if (me.alt_ft > me.maxAlt) {
			me.maxAlt = me.alt_ft;
		}

		# performance logging:
		#
		#var q = 0.5 * rho * me.old_speed_fps * me.old_speed_fps;
		#setprop("logging/missile/dist-nm", me.ac_init.distance_to(me.coord)*M2NM);
		#setprop("logging/missile/alt-m", me.alt_ft * FT2M);
		#setprop("logging/missile/speed-m", me.speed_m*1000);
		#setprop("logging/missile/drag-lbf", Cd * q * me.eda);
		#setprop("logging/missile/thrust-lbf", thrust_lbf);

		me.setFirst();

		me.latN.setDoubleValue(me.coord.lat());
		me.lonN.setDoubleValue(me.coord.lon());
		me.altN.setDoubleValue(me.alt_ft);
		me.pitchN.setDoubleValue(me.pitch);
		me.hdgN.setDoubleValue(me.hdg);

		# log missiles to unicsv for visualizing flightpath in Google Earth
		#
		#setprop("/logging/missile/latitude-deg", me.coord.lat());
		#setprop("/logging/missile/longitude-deg", me.coord.lon());
		#setprop("/logging/missile/altitude-ft", alt_ft);
		#setprop("/logging/missile/t-latitude-deg", me.t_coord.lat());
		#setprop("/logging/missile/t-longitude-deg", me.t_coord.lon());
		#setprop("/logging/missile/t-altitude-ft", me.t_coord.alt()*M2FT);

		##############################
		#### Proximity detection.#####
		##############################
		if (me.rail == FALSE or me.rail_passed == TRUE) {
 			if ( me.free == FALSE ) {
 				# check if the missile overloaded with G force.
				me.g = me.steering_speed_G(me.track_signal_e, me.track_signal_h, me.old_speed_fps, me.dt);

				if ( me.g > me.max_g_current and me.init_launch != 0) {
					me.free = TRUE;
					printf("%s: Missile attempted to pull too many G, it broke.", me.type);
				}
			} else {
				me.g = 0;
			}

			me.exploded = me.proximity_detection();

#
# Uncomment the following lines to check stats while flying:
#
#printf("Mach %02.1f , time %03.1f s , thrust %03.1f lbf , G-force %02.2f", me.speed_m, me.life_time, me.thrust_lbf, me.g);
#printf("Alt %05.1f ft , distance to target %02.1f NM", me.alt_ft, me.direct_dist_m*M2NM);			
			
			if (me.exploded == TRUE) {
				printf("%s max absolute %.2f Mach. Max relative %.2f Mach. Max alt %6d ft.", me.type, me.maxMach, me.maxMach-me.startMach, me.maxAlt);
				printf(" Fired at %s from %.1f Mach, %5d ft at %3d NM distance. Pursued %0.1f NM.", me.callsign, me.startMach, me.startAlt, me.startDist * M2NM, me.ac_init.direct_distance_to(me.coord)*M2NM);
				# We exploded, and start the sound propagation towards the plane
				me.sndSpeed = me.sound_fps;
				me.sndDistance = 0;
				me.elapsed_last = systime();
				if (me.explodeSound == TRUE) {
					me.sndPropagate();
				} else {
					settimer( func me.del(), 10);
				}
				return;
			}
		} else {
			me.g = 0;
		}
		# record coords so we can give the latest nearest position for impact.
		me.before_last_coord   = geo.Coord.new(me.last_coord);
		me.last_coord          = geo.Coord.new(me.coord);
		if (me.Tgt != nil) {
			me.before_last_t_coord = geo.Coord.new(me.last_t_coord);
			me.last_t_coord        = geo.Coord.new(me.t_coord);
		}

		if (me.rail_passed == FALSE and (me.rail == FALSE or me.rail_pos > me.rail_dist_m * M2FT)) {
			me.rail_passed = TRUE;
			#print("rail passed");
		}

		# consume fuel
		if (me.life_time > (me.drop_time + me.stage_1_duration + me.stage_2_duration)) {
			me.weight_current = me.weight_launch_lbm - me.weight_fuel_lbm;
		} elsif (me.life_time > (me.drop_time + me.stage_1_duration)) {
			me.weight_current = me.weight_current - me.fuel_per_sec_2 * me.dt;
		} elsif (me.life_time > me.drop_time) {
			me.weight_current = me.weight_current - me.fuel_per_sec_1 * me.dt;
		}
		#printf("weight %0.1f", me.weight_current);
		me.mass = me.weight_current / slugs_to_lbm;

		me.last_dt = me.dt;
		settimer(func me.flight(), update_loop_time, SIM_TIME);		
	},

	setFirst: func() {#GCD
		if (me.smoke_prop.getValue() == TRUE) {
			if (me.first == TRUE or first_in_air == FALSE) {
				# report position over MP for MP animation of smoke trail.
				me.first = TRUE;
				first_in_air = TRUE;
				# using helicopter properties for reporting over MP. To mount this code on a helicopter, you best change that.
				setprop("rotors/main/blade[0]/flap-deg", me.coord.lat());
				setprop("rotors/main/blade[1]/flap-deg", me.coord.lon());
				setprop("rotors/main/blade[2]/flap-deg", me.coord.alt());
			}
		} elsif (me.first == TRUE and me.life_time > me.drop_time + me.stage_1_duration + me.stage_2_duration) {
			# this weapon was reporting its position over MP, but now its fuel has used up. So allow for another to do that.
			me.resetFirst();
		}
	},

	resetFirst: func() {#GCD
		first_in_air = FALSE;
		me.first = FALSE;
		setprop("rotors/main/blade[0]/flap-deg", 0);
		setprop("rotors/main/blade[1]/flap-deg", 0);
		setprop("rotors/main/blade[2]/flap-deg", 0);
	},

	limitG: func () {#GCD
		#
		# Here will be set the max angle of pitch and the max angle of heading to avoid G overload
		#
        me.myG = me.steering_speed_G(me.track_signal_e, me.track_signal_h, me.old_speed_fps, me.dt);
        if(me.max_g_current < me.myG)
        {
            me.MyCoef = me.max_G_Rotation(me.track_signal_e, me.track_signal_h, me.old_speed_fps, me.dt, me.max_g_current);
            me.track_signal_e =  me.track_signal_e * me.MyCoef;
            me.track_signal_h =  me.track_signal_h * me.MyCoef;
            #print(sprintf("G1 %.2f", myG));
            me.myG = me.steering_speed_G(me.track_signal_e, me.track_signal_h, me.old_speed_fps, me.dt);
            #print(sprintf("G2 %.2f", myG)~sprintf(" - Coeff %.2f", MyCoef));
            if (me.limitGs == FALSE) {
            	printf("%s: Missile pulling almost max G: %.1f G", me.type, me.myG);
            }
        }
        if (me.limitGs == TRUE and me.myG > me.max_g_current/2) {
        	# Save the high performance manouving for later
        	me.track_signal_e = me.track_signal_e /2;
        }
	},

	setRadarProperties: func (new_speed_fps) {#GCD
		#
		# Set missile radar properties for use in selection view, radar and HUD.
		#
		me.self = geo.aircraft_position();
		me.ai.getNode("radar/bearing-deg", 1).setDoubleValue(me.self.course_to(me.coord));
		me.ai.getNode("radar/elevation-deg", 1).setDoubleValue(me.getPitch(me.self, me.coord));
		me.ai.getNode("velocities/true-airspeed-kt",1).setDoubleValue(new_speed_fps * FPS2KT);
	},

	rear_aspect: func () {#GCD
		#
		# If is heat-seeking rear-aspect-only missile, check if it has good view on engine(s) and can keep lock.
		#
		me.offset = me.aspect();

		if (me.offset < 45) {
			# clear view of engine heat, keep the lock
			me.rearAspect = 1;
		} else {
			# the greater angle away from clear engine view the greater chance of losing lock.
			me.offset_away = me.offset - 45;
			me.probability = me.offset_away/135;
			me.probability = me.probability*2.5;# The higher the factor, the less chance to keep lock.
			me.rearAspect = rand() > me.probability;
		}

		#print ("RB-24J deviation from full rear-aspect: "~sprintf("%01.1f", offset)~" deg, keep IR lock on engine: "~rearAspect);

		return me.rearAspect;# 1: keep lock, 0: lose lock
	},

	aspect: func () {#GCD
		me.rearAspect = 0;

		#var t_dist_m = me.coord.distance_to(me.t_coord);
		#var alt_delta_m = me.coord.alt() - me.t_coord.alt();
		me.elev_deg =  me.getPitch(me.t_coord, me.coord);#math.atan2( alt_delta_m, t_dist_m ) * R2D; elevation to missile from target aircraft
		me.elevation_offset = me.elev_deg - me.Tgt.get_Pitch();

		me.courseA = me.t_coord.course_to(me.coord);
		me.heading_offset = me.courseA - me.Tgt.get_heading();

		#
		while (me.heading_offset < -180) {
			me.heading_offset += 360;
		}
		while (me.heading_offset > 180) {
			me.heading_offset -= 360;
		}
		while (me.elevation_offset < -180) {
			me.elevation_offset += 360;
		}
		while (me.elevation_offset > 180) {
			me.elevation_offset -= 360;
		}
		me.elevation_offset = math.abs(me.elevation_offset);
		me.heading_offset = 180 - math.abs(me.heading_offset);

		me.offset = math.max(me.elevation_offset, me.heading_offset);

		return me.offset;		
	},

	guide: func() {#GCD
		#
		# navigation and guidance
		#
		me.raw_steer_signal_elev = 0;
		me.raw_steer_signal_head = 0;

		me.guiding = TRUE;

		# Calculate current target elevation and azimut deviation.
		me.t_alt            = me.t_coord.alt()*M2FT;
		#var t_alt_delta_m   = (me.t_alt - me.alt_ft) * FT2M;
		me.dist_curr        = me.coord.distance_to(me.t_coord);
		me.dist_curr_direct = me.coord.direct_distance_to(me.t_coord);
		me.t_elev_deg       = me.getPitch(me.coord, me.t_coord);#math.atan2( t_alt_delta_m, me.dist_curr ) * R2D;
		me.t_course         = me.coord.course_to(me.t_coord);
		me.curr_deviation_e = me.t_elev_deg - me.pitch;
		me.curr_deviation_h = me.t_course - me.hdg;

		#var (t_course, me.dist_curr) = courseAndDistance(me.coord, me.t_coord);
		#me.dist_curr = me.dist_curr * NM2M;	

		#printf("Altitude above launch platform = %.1f ft", M2FT * (me.coord.alt()-me.ac.alt()));

		while(me.curr_deviation_h < -180) {
			me.curr_deviation_h += 360;
		}
		while(me.curr_deviation_h > 180) {
			me.curr_deviation_h -= 360;
		}

		me.checkForFlare();

		me.checkForSun();

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
		me.last_t_course       = me.t_course;
		me.last_t_elev_deg     = me.t_elev_deg;
		me.last_cruise_or_loft = me.cruise_or_loft;
	},

	checkForFlare: func () {#GCD
		#
		# Check for being fooled by flare.
		#
		if (me.guidance == "heat") {
			#
			# TODO: Use Richards Emissary for this.
			#
			me.flareNode = me.Tgt.getFlareNode();
			if (me.flareNode != nil) {
				me.flareString = me.flareNode.getValue();
				if (me.flareString != nil and me.flareString != "") {
					me.flareVector = split(":", me.flareString);
					if (me.flareVector != nil and size(me.flareVector) == 2 and me.flareVector[1] == "flare") {
						me.flareNumber = num(me.flareVector[0]);
						if (me.flareNumber != nil and me.flareNumber != me.lastFlare) {
							# target has released a new flare, lets check if it fools us
							me.lastFlare = me.flareNumber;
							me.aspectDeg = me.aspect() / 180;
							me.fooled = rand() < (0.2 + 0.1 * me.aspectDeg);
							# 20% chance to be fooled, extra up till 10% chance added if front aspect
							if (me.fooled == TRUE) {
								# fooled by the flare
								print(me.type~": Missile fooled by flare");
								me.free = TRUE;
							} else {
								print(me.type~": Missile ignored flare");
							}
						}
					}
				}
			}
		}
	},

	checkForSun: func () {
		if (me.guidance == "heat" and me.sun_power > 0.6) {
			# test for heat seeker locked on to sun
			me.sun_dev_e = me.getPitch(me.coord, me.sun) - me.pitch;
			me.sun_dev_h = me.coord.course_to(me.sun) - me.hdg;
			while(me.sun_dev_h < -180) {
				me.sun_dev_h += 360;
			}
			while(me.sun_dev_h > 180) {
				me.sun_dev_h -= 360;
			}
			# now we check if the sun is behind the target, which is the direction the gyro seeker is pointed at:
			me.sun_dev = math.sqrt((me.sun_dev_e-me.curr_deviation_e)*(me.sun_dev_e-me.curr_deviation_e)+(me.sun_dev_h-me.curr_deviation_h)*(me.sun_dev_h-me.curr_deviation_h));
			if (me.sun_dev < me.sun_lock) {
				print(me.type~": Locked onto sun, lost target. ");
				me.lock_on_sun = TRUE;
				me.free = TRUE;
			}
		}
	},

	checkForGuidance: func () {#GCD
		if(me.speed_m < me.min_speed_for_guiding) {
			# it doesn't guide at lower speeds
			me.guiding = FALSE;
			if (me.tooLowSpeed == FALSE) {
				print(me.type~": Not guiding (too low speed)");
			}
			me.tooLowSpeed = TRUE;
		} elsif ((me.guidance == "semi-radar" or me.guidance =="laser") and me.is_painted(me.Tgt) == FALSE) {
			# if its semi-radar guided and the target is no longer painted
			me.guiding = FALSE;
			if (me.semiLostLock == FALSE) {
				print(me.type~": Not guiding (lost radar reflection, trying to reaquire)");
			}
			me.semiLostLock = TRUE;
		} elsif ((math.abs(me.curr_deviation_e) > me.max_seeker_dev or math.abs(me.curr_deviation_h) > me.max_seeker_dev) and me.guidance != "gps") {
			# target is not in missile seeker view anymore
			if (me.curr_deviation_e > me.max_seeker_dev) {
				me.viewLost = "Target is above seeker view.";
			} elsif (me.curr_deviation_e < (-1 * me.max_seeker_dev)) {
				me.viewLost = "Target is below seeker view. "~(me.dist_curr*M2NM)~" NM and "~((me.coord.alt()-me.t_coord.alt())*M2FT)~" ft diff.";
			} elsif (me.curr_deviation_h > me.max_seeker_dev) {
				me.viewLost = "Target is right of seeker view.";
			} else {
				me.viewLost = "Target is left of seeker view.";
			}
			print(me.type~": Target is not in missile seeker view anymore. "~me.viewLost);
			me.free = TRUE;
		} elsif (me.all_aspect == FALSE and me.rear_aspect() == FALSE) {
			me.guiding = FALSE;
           	if (me.heatLostLock == FALSE) {
        		print(me.type~": Missile lost heat lock, attempting to reaquire..");
        	}
        	me.heatLostLock = TRUE;
		} elsif (me.life_time < me.drop_time) {
			me.guiding = FALSE;
		} elsif (me.semiLostLock == TRUE) {
			print(me.type~": Reaquired radar reflection.");
			me.semiLostLock = FALSE;
		} elsif (me.heatLostLock == TRUE) {
	       	print(me.type~": Regained heat lock.");
	       	me.heatLostLock = FALSE;
	    } elsif (me.tooLowSpeed == TRUE) {
			print(me.type~": Gained speed and started guiding.");
			me.tooLowSpeed = FALSE;
		}
	},

	canSeekerKeepUp: func () {#GCD
		if (me.last_deviation_e != nil and (me.guidance == "heat" or me.guidance == "vision")) {
			# calculate if the seeker can keep up with the angular change of the target
			#
			# missile own movement is subtracted from this change due to seeker being on gyroscope
			#
			me.dve_dist = me.curr_deviation_e - me.last_deviation_e + me.last_track_e;
			me.dvh_dist = me.curr_deviation_h - me.last_deviation_h + me.last_track_h;
			me.deviation_per_sec = math.sqrt(me.dve_dist*me.dve_dist+me.dvh_dist*me.dvh_dist)/me.dt;

			if (me.deviation_per_sec > me.angular_speed) {
				#print(sprintf("last-elev=%.1f", me.last_deviation_e)~sprintf(" last-elev-adj=%.1f", me.last_track_e));
				#print(sprintf("last-head=%.1f", me.last_deviation_h)~sprintf(" last-head-adj=%.1f", me.last_track_h));
				# lost lock due to angular speed limit
				printf("%s: %.1f deg/s too fast angular change for seeker head.", me.type, me.deviation_per_sec);
				me.free = TRUE;
			}
		}

		me.last_deviation_e = me.curr_deviation_e;
		me.last_deviation_h = me.curr_deviation_h;
	},

	cruiseAndLoft: func () {#GCD
		#
		# cruise, loft, cruise-missile
		#
		me.loft_angle = 15;# notice Shinobi used 26.5651 degs, but Raider1 found a source saying 10-20 degs.
		me.cruise_or_loft = FALSE;
		me.time_before_snap_up = me.drop_time * 3;
		me.limitGs = FALSE;
		me.absolutePitch = me.getPitch(me.coord, me.Tgt.get_Coord());
		
        if(me.loft_alt != 0 and me.loft_alt < 10000) {
        	# this is for Air to ground/sea cruise-missile (SCALP, Sea-Eagle, Taurus, Tomahawk, RB-15...)

        	# detect terrain for use in terrain following
        	me.nextGroundElevationMem[1] -= 1;
            me.geoPlus2 = me.nextGeoloc(me.coord.lat(), me.coord.lon(), me.hdg, me.old_speed_fps, me.dt*5);
            me.geoPlus3 = me.nextGeoloc(me.coord.lat(), me.coord.lon(), me.hdg, me.old_speed_fps, me.dt*10);
            me.geoPlus4 = me.nextGeoloc(me.coord.lat(), me.coord.lon(), me.hdg, me.old_speed_fps, me.dt*20);
            me.e1 = geo.elevation(me.coord.lat(), me.coord.lon());# This is done, to make sure is does not decline before it has passed obstacle.
            me.e2 = geo.elevation(me.geoPlus2.lat(), me.geoPlus2.lon());# This is the main one.
            me.e3 = geo.elevation(me.geoPlus3.lat(), me.geoPlus3.lon());# This is an extra, just in case there is an high cliff it needs longer time to climb.
            me.e4 = geo.elevation(me.geoPlus4.lat(), me.geoPlus4.lon());
			if (me.e1 != nil) {
            	me.nextGroundElevation = me.e1;
            } else {
            	print(me.type~": nil terrain, blame terrasync! Cruise-missile keeping altitude.");
            }
            if (me.e2 != nil and me.e2 > me.nextGroundElevation) {
            	me.nextGroundElevation = me.e2;
            	if (me.e2 > me.nextGroundElevationMem[0] or me.nextGroundElevationMem[1] < 0) {
            		me.nextGroundElevationMem[0] = me.e2;
            		me.nextGroundElevationMem[1] = 5;
            	}
            }
            if (me.nextGroundElevationMem[0] > me.nextGroundElevation) {
            	me.nextGroundElevation = me.nextGroundElevationMem[0];
            }
            if (me.e3 != nil and me.e3 > me.nextGroundElevation) {
            	me.nextGroundElevation = me.e3;
            }
            if (me.e4 != nil and me.e4 > me.nextGroundElevation) {
            	me.nextGroundElevation = me.e4;
            }

            me.Daground = 0;# zero for sealevel in case target is ship. Don't shoot A/S missiles over terrain. :)
            if(me.Tgt.get_type() == SURFACE or me.follow == TRUE) {
                me.Daground = me.nextGroundElevation * M2FT;
            }
            me.loft_alt_curr = me.loft_alt;
            if (me.dist_curr < me.old_speed_fps * 4 * FT2M and me.dist_curr > me.old_speed_fps * 2.5 * FT2M) {
            	# the missile lofts a bit at the end to avoid APN to slam it into ground before target is reached.
            	# end here is between 2.5-4 seconds
            	me.loft_alt_curr = me.loft_alt*2;
            }
            if (me.dist_curr > me.old_speed_fps * 2.5 * FT2M) {# need to give the missile time to do final navigation
                # it's 1 or 2 seconds for this kinds of missiles...
                me.t_alt_delta_ft = (me.loft_alt_curr + me.Daground - me.alt_ft);
                #print("var t_alt_delta_m : "~t_alt_delta_m);
                if(me.loft_alt_curr + me.Daground > me.alt_ft) {
                    # 200 is for a very short reaction to terrain
                    #print("Moving up");
                    me.raw_steer_signal_elev = -me.pitch + math.atan2(me.t_alt_delta_ft, me.old_speed_fps * me.dt * 5) * R2D;
                } else {
                    # that means a dive angle of 22.5° (a bit less 
                    # coz me.alt is in feet) (I let this alt in feet on purpose (more this figure is low, more the future pitch is high)
                    #print("Moving down");
                    me.slope = me.clamp(me.t_alt_delta_ft / 300, -5, 0);# the lower the desired alt is, the steeper the slope.
                    me.raw_steer_signal_elev = -me.pitch + me.clamp(math.atan2(me.t_alt_delta_ft, me.old_speed_fps * me.dt * 5) * R2D, me.slope, 0);
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
        } elsif (me.loft_alt != 0 and me.absolutePitch > -25 and me.dist_curr * M2NM > 10
			 and me.t_elev_deg < me.loft_angle #and me.t_elev_deg > -7.5
			 and me.dive_token == FALSE) {
			# lofting: due to target is more than 10 miles out and we havent reached 
			# our desired cruising alt, and the elevation to target is less than lofting angle.
			# The -7.5 limit, is so the seeker don't lose track of target when lofting.
			if (me.life_time < me.time_before_snap_up and me.coord.alt() * M2FT < me.loft_alt) {
				#print("preparing for lofting");
				me.cruise_or_loft = TRUE;
			} elsif (me.coord.alt() * M2FT < me.loft_alt) {
				me.raw_steer_signal_elev = -me.pitch + me.loft_angle;
				me.limitGs = TRUE;
				#print(sprintf("Lofting %.1f degs, dev is %.1f", me.loft_angle, me.raw_steer_signal_elev));
			} else {
				me.dive_token = TRUE;
				#print("Stopped lofting");
			}
			me.cruise_or_loft = TRUE;
		} elsif (me.rail == TRUE and me.rail_forward == FALSE and me.dive_token == FALSE) {
			# tube launched missile turns towards target

			me.raw_steer_signal_elev = -me.pitch + me.t_elev_deg;
			#print("Turning, desire "~me.t_elev_deg~" degs pitch.");
			me.cruise_or_loft = TRUE;
			if (math.abs(me.curr_deviation_e) < 5) {
				me.dive_token = TRUE;
				#print("Is last turn, APN takes it from here..")
			}
		} elsif (me.coord.alt() > me.t_coord.alt() and me.last_cruise_or_loft == TRUE
		         and me.absolutePitch > -25 and me.dist_curr * M2NM > 10) {
			# cruising: keeping altitude since target is below and more than -45 degs down

			me.ratio = (g_fps * me.dt)/me.old_speed_fps;
            me.attitude = 0;

            if (me.ratio < 1 and me.ratio > -1) {
                me.attitude = math.asin(me.ratio)*R2D;
            }

			me.raw_steer_signal_elev = -me.pitch + me.attitude;
			#print("Cruising, desire "~me.attitude~" degs pitch.");
			me.cruise_or_loft = TRUE;
			me.limitGs = TRUE;
			me.dive_token = TRUE;
		} elsif (me.last_cruise_or_loft == TRUE and math.abs(me.curr_deviation_e) > 2.5 and me.life_time > me.time_before_snap_up) {
			# after cruising, point the missile in the general direction of the target, before APN starts guiding.
			#print("Rotating toward target");
			me.raw_steer_signal_elev = me.curr_deviation_e;
			me.cruise_or_loft = TRUE;
			#me.limitGs = TRUE;
		}
	},

	APN: func () {#GCD
		#
		# augmented proportional navigation
		#
		if (me.guiding == TRUE and me.free == FALSE and me.dist_last != nil and me.last_dt != 0) {
			# augmented proportional navigation for heading #
			#################################################

			if (me.navigation == "direct") {
				me.raw_steer_signal_head = me.curr_deviation_h;
				if (me.cruise_or_loft == FALSE) {
					me.raw_steer_signal_elev = me.curr_deviation_e;
				}
				return;
			} elsif (me.navigation == "PN") {
				me.apn = 0;
			} else {
				me.apn = 1;
			}

			me.horz_closing_rate_fps = me.clamp(((me.dist_last - me.dist_curr)*M2FT)/me.dt, 0.1, 1000000);#clamped due to cruise missiles that can fly slower than target.
			#printf("Horz closing rate: %5d ft/sec", me.horz_closing_rate_fps);
			me.proportionality_constant = 3;

			me.c_dv = me.t_course-me.last_t_course;
			while(me.c_dv < -180) {
				me.c_dv += 360;
			}
			while(me.c_dv > 180) {
				me.c_dv -= 360;
			}

			me.line_of_sight_rate_rps = (D2R*me.c_dv)/me.dt;

			#printf("LOS rate: %.4f rad/s", line_of_sight_rate_rps);

			#if (me.before_last_t_coord != nil) {
			#	var t_heading = me.before_last_t_coord.course_to(me.t_coord);
			#	var t_dist   = me.before_last_t_coord.distance_to(me.t_coord);
			#	var t_dist_dir   = me.before_last_t_coord.direct_distance_to(me.t_coord);
			#	var t_climb      = me.t_coord.alt() - me.before_last_t_coord.alt();
			#	var t_horz_speed = (t_dist*M2FT)/(me.dt+me.last_dt);
			#	var t_speed      = (t_dist_dir*M2FT)/(me.dt+me.last_dt);
			#} else {
			#	var t_heading = me.last_t_coord.course_to(me.t_coord);
			#	var t_dist   = me.last_t_coord.distance_to(me.t_coord);
			#	var t_dist_dir   = me.last_t_coord.direct_distance_to(me.t_coord);
			#	var t_climb      = me.t_coord.alt() - me.last_t_coord.alt();
			#	var t_horz_speed = (t_dist*M2FT)/me.dt;
			#	var t_speed      = (t_dist_dir*M2FT)/me.dt;
			#}
			
			#var t_pitch      = math.atan2(t_climb,t_dist)*R2D;
			

			# calculate target acc as normal to LOS line:
			me.t_heading        = me.Tgt.get_heading();
			me.t_pitch          = me.Tgt.get_Pitch();
			me.t_speed          = me.Tgt.get_Speed()*KT2FPS;#true airspeed

			#if (me.last_t_coord.direct_distance_to(me.t_coord) != 0) {
			#	# taking sideslip and AoA into consideration:
			#	me.t_heading    = me.last_t_coord.course_to(me.t_coord);
			#	me.t_climb      = me.t_coord.alt() - me.last_t_coord.alt();
			#	me.t_dist       = me.last_t_coord.distance_to(me.t_coord);
			#	me.t_pitch      = math.atan2(me.t_climb, me.t_dist) * R2D;
			#} elsif (me.Tgt.get_Speed() > 25) {
				# target position was not updated since last loop.
				# to avoid confusing the navigation, we just fly
				# straight.
				#print("not updated");
			#	return;
			#}


			
			me.t_horz_speed     = math.abs(math.cos(me.t_pitch*D2R)*me.t_speed);
			me.t_LOS_norm_head  = me.t_course + 90;
			me.t_LOS_norm_speed = math.cos((me.t_LOS_norm_head - me.t_heading)*D2R)*me.t_horz_speed;

			if (me.last_t_norm_speed == nil) {
				me.last_t_norm_speed = me.t_LOS_norm_speed;
			}

			me.t_LOS_norm_acc   = (me.t_LOS_norm_speed - me.last_t_norm_speed)/me.dt;

			me.last_t_norm_speed = me.t_LOS_norm_speed;

			# acceleration perpendicular to instantaneous line of sight in feet/sec^2
			me.acc_sideways_ftps2 = me.proportionality_constant*me.line_of_sight_rate_rps*me.horz_closing_rate_fps+me.apn*me.proportionality_constant*me.t_LOS_norm_acc/2;
			#printf("horz acc = %.1f + %.1f", proportionality_constant*line_of_sight_rate_rps*horz_closing_rate_fps, proportionality_constant*t_LOS_norm_acc/2);

			# now translate that sideways acc to an angle:
			me.velocity_vector_length_fps = me.old_speed_horz_fps;
			me.commanded_sideways_vector_length_fps = me.acc_sideways_ftps2*me.dt;
			me.raw_steer_signal_head = math.atan2(me.commanded_sideways_vector_length_fps, me.velocity_vector_length_fps)*R2D;

			#print(sprintf("LOS-rate=%.2f rad/s - closing-rate=%.1f ft/s",line_of_sight_rate_rps,horz_closing_rate_fps));
			#print(sprintf("commanded-perpendicular-acceleration=%.1f ft/s^2", acc_sideways_ftps2));
			#print(sprintf("horz leading by %.1f deg, commanding %.1f deg", me.curr_deviation_h, me.raw_steer_signal_head));

			if (me.cruise_or_loft == FALSE) {# and me.last_cruise_or_loft == FALSE
				# augmented proportional navigation for elevation #
				###################################################
				#print(me.navigation~" in fully control");
				me.vert_closing_rate_fps = me.clamp(((me.dist_direct_last - me.dist_curr_direct)*M2FT)/me.dt, 0.1, 1000000);
				#printf("Vert closing rate: %5d ft/sec", me.vert_closing_rate_fps);
				me.line_of_sight_rate_up_rps = (D2R*(me.t_elev_deg-me.last_t_elev_deg))/me.dt;

				# calculate target acc as normal to LOS line: (up acc is positive)
				me.t_approach_bearing             = me.t_course + 180;
				

				# used to do this with trigonometry, but vector math is simpler to understand: (they give same result though)
				me.t_LOS_elev_norm_speed     = me.scalarProj(me.t_heading,me.t_pitch,me.t_speed,me.t_approach_bearing,me.t_elev_deg*-1 +90);

				if (me.last_t_elev_norm_speed == nil) {
					me.last_t_elev_norm_speed = me.t_LOS_elev_norm_speed;
				}

				me.t_LOS_elev_norm_acc            = (me.t_LOS_elev_norm_speed - me.last_t_elev_norm_speed)/me.dt;
				me.last_t_elev_norm_speed          = me.t_LOS_elev_norm_speed;

				me.acc_upwards_ftps2 = me.proportionality_constant*me.line_of_sight_rate_up_rps*me.vert_closing_rate_fps+me.apn*me.proportionality_constant*me.t_LOS_elev_norm_acc/2;
				me.velocity_vector_length_fps = me.old_speed_fps;
				me.commanded_upwards_vector_length_fps = me.acc_upwards_ftps2*me.dt;
				me.raw_steer_signal_elev = math.atan2(me.commanded_upwards_vector_length_fps, me.velocity_vector_length_fps)*R2D;
			}
		}
	},

	scalarProj: func (head, pitch, magn, projHead, projPitch) {#GCD
		head      = head*D2R;
		pitch     = pitch*D2R;
		projHead  = projHead*D2R;
		projPitch = projPitch*D2R;

		# Convert the 2 polar vectors to cartesian
		me.ax = magn * math.cos(pitch) * math.cos(-head);
		me.ay = magn * math.cos(pitch) * math.sin(-head);
		me.az = magn * math.sin(pitch);

		me.bx = 1 * math.cos(projPitch) * math.cos(-projHead);
		me.by = 1 * math.cos(projPitch) * math.sin(-projHead);
		me.bz = 1 * math.sin(projPitch);

		# the dot product is the scalar projection.
		me.result = (me.ax * me.bx + me.ay*me.by+me.az*me.bz)/1;
		return me.result;
	},

	map: func (value, leftMin, leftMax, rightMin, rightMax) {
	    # Figure out how 'wide' each range is
	    var leftSpan = leftMax - leftMin;
	    var rightSpan = rightMax - rightMin;

	    # Convert the left range into a 0-1 range (float)
	    var valueScaled = (value - leftMin) / leftSpan;

	    # Convert the 0-1 range into a value in the right range.
	    return rightMin + (valueScaled * rightSpan);
	},

	proximity_detection: func {#GCD

		####Ground interaction
        me.ground = geo.elevation(me.coord.lat(), me.coord.lon());
        if(me.ground != nil)
        {
            if(me.ground > me.coord.alt()) {
            	me.event = "exploded";
            	if(me.life_time < me.arming_time) {
                	me.event = "landed disarmed";
            	}
            	me.explode("Hit terrain.", me.event);
                return TRUE;
            }
        }

		if (me.Tgt != nil) {
			me.cur_dir_dist_m = me.coord.direct_distance_to(me.t_coord);
			# Get current direct distance.
			if ( me.direct_dist_m != nil and me.life_time > me.arming_time) {
				#print("distance to target_m = "~cur_dir_dist_m~" prev_distance to target_m = "~me.direct_dist_m);
				if ( me.cur_dir_dist_m > me.direct_dist_m and me.cur_dir_dist_m < 250) {
					#print("passed target");
					# Distance to target increase, trigger explosion.
					me.explode("Passed target.");
					return TRUE;
				}
				if (me.life_time > me.selfdestruct_time) {
					me.explode("Selfdestructed.");
				    return TRUE;
				}
			}			
			me.direct_dist_m = me.cur_dir_dist_m;
		}
		return FALSE;
	},

	explode: func (reason, event = "exploded") {
		# Get missile relative position to the target at last frame.
		#var t_bearing_deg = me.last_t_coord.course_to(me.last_coord);
		#var t_delta_alt_m = me.last_coord.alt() - me.last_t_coord.alt();
		#var new_t_alt_m = me.t_coord.alt() + t_delta_alt_m;
		#var t_dist_m  = me.direct_dist_m;

		if (me.lock_on_sun == TRUE) {
			reason = "Locked onto sun.";
		} elsif (me.fooled == TRUE) {
			reason = "Fooled by flare.";
		}
		
		var explosion_coord = me.last_coord;
		if (me.Tgt != nil) {
			var min_distance = me.direct_dist_m;
			
			#print("min1 "~min_distance);
			#print("last_t to t    : "~me.last_t_coord.direct_distance_to(me.t_coord));
			#print("last to current: "~me.last_coord.direct_distance_to(me.coord));
			for (var i = 0.00; i <= 1; i += 0.025) {
				var t_coord = me.interpolate(me.last_t_coord, me.t_coord, i);
				var coord = me.interpolate(me.last_coord, me.coord, i);
				var dist = coord.direct_distance_to(t_coord);
				if (dist < min_distance) {
					min_distance = dist;
					explosion_coord = coord;
				}
			}
			#print("min2 "~min_distance);
			if (me.before_last_coord != nil and me.before_last_t_coord != nil) {
				for (var i = 0.00; i <= 1; i += 0.025) {
					var t_coord = me.interpolate(me.before_last_t_coord, me.last_t_coord, i);
					var coord = me.interpolate(me.before_last_coord, me.last_coord, i);
					var dist = coord.direct_distance_to(t_coord);
					if (dist < min_distance) {
						min_distance = dist;
						explosion_coord = coord;
					}
				}
			}
		}
		me.coord = explosion_coord;
		#print("min3 "~min_distance);

		# Create impact coords from this previous relative position applied to target current coord.
		#me.t_coord.apply_course_distance(t_bearing_deg, t_dist_m);
		#me.t_coord.set_alt(new_t_alt_m);		
		var wh_mass = event == "exploded"?me.weight_whead_lbm:0;#will report 0 mass if did not have time to arm
		#print("FOX2: me.direct_dist_m = ",  me.direct_dist_m, " time ",getprop("sim/time/elapsed-sec"));
		impact_report(me.coord, wh_mass, "munition", me.type); # pos, alt, mass_slug,(speed_mps)

		if (me.Tgt != nil) {
			var phrase = sprintf( me.type~" "~event~": %01.1f", min_distance) ~ " meters from: " ~ me.callsign;
			print(phrase~"  Reason: "~reason~sprintf(" time %.1f", me.life_time));
			if (min_distance < me.reportDist) {
				me.sendMessage(phrase);
			} else {
				me.sendMessage(me.type~" missed "~me.callsign~": "~reason);
			}
		}
		
		me.ai.getNode("valid", 1).setBoolValue(0);
		if (event == "exploded") {
			me.animate_explosion();
			me.explodeSound = TRUE;
		} else {
			me.animate_dud();
			me.explodeSound = FALSE;
		}
		me.Tgt = nil;
	},

	sendMessage: func (str) {#GCD
		if (getprop("payload/armament/msg")) {
			defeatSpamFilter(str);
		} else {
			setprop("/sim/messages/atc", str);
		}
	},

	interpolate: func (start, end, fraction) {#GCD
		me.xx = (start.x()*(1-fraction)+end.x()*fraction);
		me.yy = (start.y()*(1-fraction)+end.y()*fraction);
		me.zz = (start.z()*(1-fraction)+end.z()*fraction);

		me.cc = geo.Coord.new();
		me.cc.set_xyz(me.xx,me.yy,me.zz);

		return me.cc;
	},

	getPitch: func (coord1, coord2) {#GCD
		#pitch from c1 to c2
		  me.coord3 = geo.Coord.new(coord1);
		  me.coord3.set_alt(coord2.alt());
		  me.d12 = coord1.direct_distance_to(coord2);
		  me.d32 = me.coord3.direct_distance_to(coord2);
		  if (me.d12 > 0.01) {
		  	me.altDi = coord1.alt()-me.coord3.alt();
		  	me.yyy = R2D * math.acos((math.pow(me.d12, 2)+math.pow(me.altDi,2)-math.pow(me.d32, 2))/(2 * me.d12 * me.altDi));
		  	me.pitchC = -1* (90 - me.yyy);
		  	return me.pitchC;
	  	} else{
	  		# arccos wont like if the coord are the same
	  		return 0;
	  	}
		  
	},

	# aircraft searching for lock
	search: func {#GCD
		if ( me.status == MISSILE_FLYING ) {
			me.SwSoundVol.setDoubleValue(0);
			me.SwSoundOnOff.setBoolValue(FALSE);
			return;
		} elsif ( me.status == MISSILE_STANDBY ) {
			# Stand by.
			me.SwSoundVol.setDoubleValue(0);
			me.SwSoundOnOff.setBoolValue(FALSE);
			me.trackWeak = 1;
			return;
		} elsif ( me.status > MISSILE_SEARCH) {
			# Locked or fired.
			return;
		} elsif (me.deleted == TRUE) {
			return;
		}
		#print("search");
		# search.
		if (1==1 or contact != me.Tgt) {
			#print("search2");
			if (contact != nil and contact.isValid() == TRUE and
				(  (contact.get_type() == SURFACE and me.target_gnd == TRUE)
                or (contact.get_type() == AIR and me.target_air == TRUE)
                or (contact.get_type() == MARINE and me.target_sea == TRUE))) {
				#print("search3");
				me.tagt = contact; # In the radar range and horizontal field.
				me.rng = me.tagt.get_range();
				me.total_elev  = deviation_normdeg(OurPitch.getValue(), me.tagt.getElevation()); # deg.
				me.total_horiz = deviation_normdeg(OurHdg.getValue(), me.tagt.get_bearing());         # deg.
				# Check if in range and in the (square shaped here) seeker FOV.
				me.abs_total_elev = math.abs(me.total_elev);
				me.abs_dev_deg = math.abs(me.total_horiz);
				if (((me.guidance != "semi-radar" and me.guidance != "laser") or me.is_painted(me.tagt) == TRUE)
				    and me.rng < me.max_detect_rng and me.abs_total_elev < me.fcs_fov and me.abs_dev_deg < me.fcs_fov ) {
					#print("search4");
					me.status = MISSILE_LOCK;
					me.SwSoundOnOff.setBoolValue(TRUE);
					me.SwSoundVol.setDoubleValue(me.vol_track_weak);
					me.trackWeak = 1;
					me.Tgt = me.tagt;

			        me.callsign = me.Tgt.get_Callsign();

					me.time = props.globals.getNode("/sim/time/elapsed-sec", 1).getValue();
					me.update_track_time = me.time;

					settimer(func me.update_lock(), 0.1);
					return;
				} else {
					me.Tgt = nil;
				}
			} else {
				me.Tgt = nil;
			}
		}
		me.SwSoundVol.setDoubleValue(me.vol_search);
		me.SwSoundOnOff.setBoolValue(TRUE);
		me.trackWeak = 1;
		settimer(func me.search(), 0.1);
	},

	update_lock: func() {#GCD
		#
		# Missile locked on target
		#
		if ( me.Tgt == nil or me.status == MISSILE_FLYING) {
			return TRUE;
		}
		if (me.status == MISSILE_SEARCH) {
			# Status = searching.
			#print("search commanded");
			me.return_to_search();
			return TRUE;
		} elsif ( me.status == MISSILE_STANDBY ) {
			# Status = stand-by.
			me.reset_seeker();
			me.SwSoundOnOff.setBoolValue(FALSE);
			me.SwSoundVol.setDoubleValue(0);
			me.trackWeak = 1;
			return TRUE;
		} elsif (!me.Tgt.isValid()) {
			# Lost of lock due to target disapearing:
			# return to search mode.
			#print("invalid");
			me.return_to_search();
			return TRUE;
		} elsif (me.deleted == TRUE) {
			return;
		}
		#print("lock");
		# Time interval since lock time or last track loop.
		
		if (me.status == MISSILE_LOCK) {		
			# Status = locked. Get target position relative to our aircraft.
			me.curr_deviation_e = - deviation_normdeg(OurPitch.getValue(), me.Tgt.getElevation());
			me.curr_deviation_h = - deviation_normdeg(OurHdg.getValue(), me.Tgt.get_bearing());
		}

		me.time = props.globals.getNode("/sim/time/elapsed-sec", 1).getValue();

		# Compute HUD reticle position.
		if ( use_fg_default_hud == TRUE and me.status == MISSILE_LOCK ) {
			var h_rad = (90 - me.curr_deviation_h) * D2R;
			var e_rad = (90 - me.curr_deviation_e) * D2R; 
			var devs = develev_to_devroll(h_rad, e_rad);
			var combined_dev_deg = devs[0];
			var combined_dev_length =  devs[1];
			var clamped = devs[2];
			if ( clamped ) { SW_reticle_Blinker.blink();}
			else { SW_reticle_Blinker.cont();}
			HudReticleDeg.setDoubleValue(combined_dev_deg);
			HudReticleDev.setDoubleValue(combined_dev_length);
		}
		if (me.status != MISSILE_STANDBY ) {
			me.in_view = me.check_t_in_fov();
			if (me.in_view == FALSE) {
				#print("out of view");
				me.return_to_search();
				return TRUE;
			}
			# We are not launched yet: update_track() loops by itself at 10 Hz.
			me.dist = geo.aircraft_position().direct_distance_to(me.Tgt.get_Coord());
			if (me.time - me.update_track_time > 1 and me.dist != nil and me.dist > (me.min_dist * NM2M)) {
				# after 1 second we get solid track if target is further than minimum distance.
				me.SwSoundOnOff.setBoolValue(TRUE);
				me.SwSoundVol.setDoubleValue(me.vol_track);
				me.trackWeak = 0;
			} else {
				me.SwSoundOnOff.setBoolValue(TRUE);
				me.SwSoundVol.setDoubleValue(me.vol_track_weak);
				me.trackWeak = 1;
			}
			if (contact == nil or (contact.getUnique() != nil and me.Tgt.getUnique() != nil and contact.getUnique() != me.Tgt.getUnique())) {
				#print("oops ");
				me.return_to_search();
				return TRUE;
			}
			settimer(func me.update_lock(), 0.1);
		}
		return TRUE;
	},

	return_to_search: func {#GCD
		me.status = MISSILE_SEARCH;
		me.Tgt = nil;
		me.SwSoundOnOff.setBoolValue(TRUE);
		me.SwSoundVol.setDoubleValue(me.vol_search);
		me.trackWeak = 1;
		me.reset_seeker();
		settimer(func me.search(), 0.1);
	},

	check_t_in_fov: func {#GCD
		me.total_elev  = deviation_normdeg(OurPitch.getValue(), me.Tgt.getElevation()); # deg.
		me.total_horiz = deviation_normdeg(OurHdg.getValue(), me.Tgt.get_bearing());         # deg.
		# Check if in range and in the (square shaped here) seeker FOV.
		me.abs_total_elev = math.abs(me.total_elev);
		me.abs_dev_deg = math.abs(me.total_horiz);
		if (me.abs_total_elev < me.fcs_fov and me.abs_dev_deg < me.fcs_fov and me.Tgt.get_range() < me.max_detect_rng) {
			return TRUE;
		}
		# Target out of FOV or range while still not launched, return to search loop.
		return FALSE;
	},

	is_painted: func (target) {#GCD
		if(target != nil and target.isPainted() != nil and target.isPainted() == TRUE) {
			return TRUE;
		}
		return FALSE;
	},

	reset_seeker: func {#GCD
		settimer(func { HudReticleDeg.setDoubleValue(0) }, 2);
		interpolate(HudReticleDev, 0, 2);
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
		var path_base = "payload/armament/"~me.type_lc~"/flags/";

		var msl_path = path_base~"msl-id-" ~ me.ID;
		me.msl_prop = props.globals.initNode( msl_path, TRUE, "BOOL", TRUE);
		me.msl_prop.setBoolValue(TRUE);# this is cause it might already exist, and so need to force value

		var smoke_path = path_base~"smoke-id-" ~ me.ID;
		me.smoke_prop = props.globals.initNode( smoke_path, FALSE, "BOOL", TRUE);

		var explode_path = path_base~"explode-id-" ~ me.ID;
		me.explode_prop = props.globals.initNode( explode_path, FALSE, "BOOL", TRUE);

		var explode_smoke_path = path_base~"explode-smoke-id-" ~ me.ID;
		me.explode_smoke_prop = props.globals.initNode( explode_smoke_path, FALSE, "BOOL", TRUE);

		var explode_sound_path = "payload/armament/flags/explode-sound-on-" ~ me.ID;;
		me.explode_sound_prop = props.globals.initNode( explode_sound_path, FALSE, "BOOL", TRUE);

		var explode_sound_vol_path = "payload/armament/flags/explode-sound-vol-" ~ me.ID;;
		me.explode_sound_vol_prop = props.globals.initNode( explode_sound_vol_path, 0, "DOUBLE", TRUE);
	},

	animate_explosion: func {#GCD
		#
		# a last position update to where the explosion happened:
		#
		me.latN.setDoubleValue(me.coord.lat());
		me.lonN.setDoubleValue(me.coord.lon());
		me.altN.setDoubleValue(me.coord.alt()*M2FT);
		me.pitchN.setDoubleValue(0);# this will make explosions from cluster bombs (like M90) align to ground 'sorta'.
		me.msl_prop.setBoolValue(FALSE);
		me.smoke_prop.setBoolValue(FALSE);
		me.explode_prop.setBoolValue(TRUE);
		settimer( func me.explode_prop.setBoolValue(FALSE), 0.5 );
		settimer( func me.explode_smoke_prop.setBoolValue(TRUE), 0.5 );
		settimer( func me.explode_smoke_prop.setBoolValue(FALSE), 3 );
	},

	animate_dud: func {#GCD
		#
		# a last position update to where the impact happened:
		#
		me.latN.setDoubleValue(me.coord.lat());
		me.lonN.setDoubleValue(me.coord.lon());
		me.altN.setDoubleValue(me.coord.alt()*M2FT);
		#me.pitchN.setDoubleValue(0); uncomment this to let it lie flat on ground, instead of sticking its nose in it.
		me.smoke_prop.setBoolValue(FALSE);
	},

	sndPropagate: func {
		var dt = deltaSec.getValue();
		if (dt == 0) {
			#FG is likely paused
			settimer(func me.sndPropagate(), 0.01);
			return;
		}
		#dt = update_loop_time;
		var elapsed = systime();
		if (me.elapsed_last != 0) {
			dt = (elapsed - me.elapsed_last) * speedUp.getValue();
		}
		me.elapsed_last = elapsed;

		me.ac = geo.aircraft_position();
		var distance = me.coord.direct_distance_to(me.ac);

		me.sndDistance = me.sndDistance + (me.sndSpeed * dt) * FT2M;
		if(me.sndDistance > distance) {
			var volume = math.pow(2.71828,(-.00025*(distance-1000)));
			#print("explosion heard "~distance~"m vol:"~volume);
			me.explode_sound_vol_prop.setDoubleValue(volume);
			me.explode_sound_prop.setBoolValue(1);
			settimer( func me.explode_sound_prop.setBoolValue(0), 3);
			settimer( func me.del(), 4);
			return;
		} elsif (me.sndDistance > 5000) {
			settimer(func { me.del(); }, 4 );
		} else {
			settimer(func me.sndPropagate(), 0.05);
			return;
		}
	},

	steering_speed_G: func(steering_e_deg, steering_h_deg, s_fps, dt) {#GCD
		# Get G number from steering (e, h) in deg, speed in ft/s.
		me.steer_deg = math.sqrt((steering_e_deg*steering_e_deg) + (steering_h_deg*steering_h_deg));

		# next speed vector
		me.vector_next_x = math.cos(me.steer_deg*D2R)*s_fps;
		me.vector_next_y = math.sin(me.steer_deg*D2R)*s_fps;
		
		# present speed vector
		me.vector_now_x = s_fps;
		me.vector_now_y = 0;

		# subtract the vectors from each other
		me.dv = math.sqrt((me.vector_now_x - me.vector_next_x)*(me.vector_now_x - me.vector_next_x)+(me.vector_now_y - me.vector_next_y)*(me.vector_now_y - me.vector_next_y));

		# calculate g-force
		# dv/dt=a
		me.g = (me.dv/dt) / g_fps;

		return me.g;
	},

    max_G_Rotation: func(steering_e_deg, steering_h_deg, s_fps, dt, gMax) {#GCD
		me.guess = 1;
		me.coef = 1;
		me.lastgoodguess = 1;

		for(var i=1;i<25;i+=1){
			me.coef = me.coef/2;
			me.new_g = me.steering_speed_G(steering_e_deg*me.guess, steering_h_deg*me.guess, s_fps, dt);
			if (me.new_g < gMax) {
				me.lastgoodguess = me.guess;
				me.guess = me.guess + me.coef;
			} else {
				me.guess = me.guess - me.coef;
			}
		}
		return me.lastgoodguess;
	},

	nextGeoloc: func(lat, lon, heading, speed, dt, alt=100) {
	    # lng & lat & heading, in degree, speed in fps
	    # this function should send back the futures lng lat
	    me.distanceN = speed * dt * FT2M; # should be a distance in meters
	    #print("distance ", distance);
	    # much simpler than trigo
	    me.NextGeo = geo.Coord.new().set_latlon(lat, lon, alt);
	    me.NextGeo.apply_course_distance(heading, me.distanceN);
	    return me.NextGeo;
	},

	rho_sndspeed: func(altitude) {
		# Calculate density of air: rho
		# at altitude (ft), using standard atmosphere,
		# standard temperature T and pressure p.

		me.T = 0;
		me.p = 0;
		if (altitude < 36152) {
			# curve fits for the troposphere
			me.T = 59 - 0.00356 * altitude;
			me.p = 2116 * math.pow( ((me.T + 459.7) / 518.6) , 5.256);
		} elsif ( 36152 < altitude and altitude < 82345 ) {
			# lower stratosphere
			me.T = -70;
			me.p = 473.1 * math.pow( const_e , 1.73 - (0.000048 * altitude) );
		} else {
			# upper stratosphere
			me.T = -205.05 + (0.00164 * altitude);
			me.p = 51.97 * math.pow( ((me.T + 459.7) / 389.98) , -11.388);
		}

		me.rho = me.p / (1718 * (me.T + 459.7));

		# calculate the speed of sound at altitude
		# a = sqrt ( g * R * (T + 459.7))
		# where:
		# snd_speed in feet/s,
		# g = specific heat ratio, which is usually equal to 1.4
		# R = specific gas constant, which equals 1716 ft-lb/slug/R

		me.snd_speed = math.sqrt( 1.4 * 1716 * (me.T + 459.7));
		return [me.rho, me.snd_speed];

	},

	active: {},
	flying: {},
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
# valid "true" BOOL
var impact_report = func(pos, mass, string, name) {
	# Find the next index for "ai/models/model-impact" and create property node.
	var n = props.globals.getNode("ai/models", 1);
	for (var i = 0; 1; i += 1)
		if (n.getChild(string, i, 0) == nil)
			break;
	var impact = n.getChild(string, i, 1);

	impact.getNode("impact/elevation-m", 1).setDoubleValue(pos.alt());
	impact.getNode("impact/latitude-deg", 1).setDoubleValue(pos.lat());
	impact.getNode("impact/longitude-deg", 1).setDoubleValue(pos.lon());
	impact.getNode("warhead-lbm", 1).setDoubleValue(mass);
	#impact.getNode("speed-mps", 1).setValue(speed_mps);
	impact.getNode("valid", 1).setBoolValue(1);
	impact.getNode("impact/type", 1).setValue("terrain");
	impact.getNode("name", 1).setValue(name);

	var impact_str = "/ai/models/" ~ string ~ "[" ~ i ~ "]";
	setprop("ai/models/model-impact", impact_str);
}

# HUD clamped target blinker
SW_reticle_Blinker = aircraft.light.new("payload/armament/hud/hud-sw-reticle-switch", [0.1, 0.1]);
setprop("payload/armament/hud/hud-sw-reticle-switch/enabled", 1);





var eye_hud_m          = 0.6;#pilot: -3.30  hud: -3.9
var hud_radius_m       = 0.100;

#was in hud
var develev_to_devroll = func(dev_rad, elev_rad) {
	var clamped = 0;
	# Deviation length on the HUD (at level flight),
	# 0.6686m = distance eye <-> virtual HUD screen.
	var h_dev = eye_hud_m / ( math.sin(dev_rad) / math.cos(dev_rad) );
	var v_dev = eye_hud_m / ( math.sin(elev_rad) / math.cos(elev_rad) );
	# Angle between HUD center/top <-> HUD center/symbol position.
	# -90° left, 0° up, 90° right, +/- 180° down. 
	var dev_deg =  math.atan2( h_dev, v_dev ) * R2D;
	# Correction with own a/c roll.
	var combined_dev_deg = dev_deg - OurRoll.getValue();
	# Lenght HUD center <-> symbol pos on the HUD:
	var combined_dev_length = math.sqrt((h_dev*h_dev)+(v_dev*v_dev));
	# clamp and squeeze the top of the display area so the symbol follow the egg shaped HUD limits.
	var abs_combined_dev_deg = math.abs( combined_dev_deg );
	var clamp = hud_radius_m;
	if ( abs_combined_dev_deg >= 0 and abs_combined_dev_deg < 90 ) {
		var coef = ( 90 - abs_combined_dev_deg ) * 0.00075;
		if ( coef > 0.050 ) { coef = 0.050 }
		clamp -= coef; 
	}
	if ( combined_dev_length > clamp ) {
		combined_dev_length = clamp;
		clamped = 1;
	}
	var v = [combined_dev_deg, combined_dev_length, clamped];
	return(v);
}

#was in radar
var deviation_normdeg = func(our_heading, target_bearing) {
	var dev_norm = our_heading - target_bearing;
	while (dev_norm < -180) dev_norm += 360;
	while (dev_norm > 180) dev_norm -= 360;
	return(dev_norm);
}

#
# this code make sure messages don't trigger the MP spam filter:

var spams = 0;
var spamList = [];

var defeatSpamFilter = func (str) {
  spams += 1;
  if (spams == 15) {
    spams = 1;
  }
  str = str~":";
  for (var i = 1; i <= spams; i+=1) {
    str = str~".";
  }
  var newList = [str];
  for (var i = 0; i < size(spamList); i += 1) {
    append(newList, spamList[i]);
  }
  spamList = newList;  
}

var spamLoop = func {
  var spam = pop(spamList);
  if (spam != nil) {
    setprop("/sim/multiplay/chat", spam);
  }
  settimer(spamLoop, 1.20);
}

spamLoop();