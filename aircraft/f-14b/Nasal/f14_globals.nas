## Global constants ##

var deltaT = 1.0;

var currentG = 1.0;
#----------------------------------------------------------------------------
# sweep computer
#----------------------------------------------------------------------------

#Variables

var AutoSweep = 1;
#var OverSweep = 0;
var WingSweep = 0.0; #Normalised wing sweep


#----------------------------------------------------------------------------
# Nozzle opening
#----------------------------------------------------------------------------

# Variables
var Nozzle1Target = 0.0;
var Nozzle2Target = 0.0;
var Nozzle1 = 0.0;
var Nozzle2 = 0.0;
var usingJSBSim = getprop("/sim/flight-model") == "jsb";
print ("F-14 Using jsbsim = ",usingJSBSim);

#----------------------------------------------------------------------------
# Spoilers
#----------------------------------------------------------------------------

# Variables
var LeftSpoilersTarget = 0.0;
var RightSpoilersTarget = 0.0;
var InnerLeftSpoilersTarget = 0.0;
var InnerRightSpoilersTarget = 0.0;

# create properties for ground spoilers 
#setprop ("/controls/flight/ground-spoilers-armed", 0);
var GroundSpoilersDeployed = 0;

# Latching mechanism in order not to deploy ground spoilers if the aircraft
# is on ground and the spoilers are armed
var GroundSpoilersLatchedClosed = 1;

# create a property to control spoilers in the YaSim flight model
setprop ("/controls/flight/yasim-spoilers", 0.0);


#----------------------------------------------------------------------------
# SAS
#----------------------------------------------------------------------------

var OldPitchInput = 0;
var SASpitch = 0;
var SASroll = 0;

#----------------------------------------------------------------------------
# General aircraft values
#----------------------------------------------------------------------------

# Constants
var ThrottleIdle = 0.05;

# Variables
var CurrentMach = 0;
var CurrentAlt = 0;
var CurrentIAS = 0;
var Alpha = 0;
var Throttle = 0;
var e_trim = 0;
var rudder_trim = 0;




# tyresmoke
# =============================================================================
# Provides a property which can be used to contol particles used to simulate tyre
# smoke on landing. Weight on wheels, vertical speed, ground speed, ground friction
# factor are taken into account. Tyre slip is simulated by low pass filters.
#
# Modifications to the model file are required.
#
# Generic XML particle files are available, but are not mandatory
# (see Hawker Seahawk for an example).
#
# SYNOPSIS:
#	aircraft.tyresmoke.new(gear index [, auto = 0])
#		gear index - the index of the gear to which the tyre smoke is attached
#		auto - enable automatic update (recommended). defaults to 0 for backward compatibility.
#	aircraft.tyresmoke.del()
#		destructor.
#	aircraft.tyresmoke.update()
#		Runs the update. Not required if automatic updates are enabled.
#
# EXAMPLE:
#	var tyresmoke_0 = aircraft.tyresmoke.new(0);
#	tyresmoke_0.update();
#
# PARAMETERS:
#
#    number: index of gear to be animated, i.e. "2" for /gear/gear[2]/...
#
#    auto: 1 when tyresmoke should start on update loop. 0 when you're going
#      to call the update method from one of your own loops.
#
#    diff_norm: value adjusting the necessary percental change of roll-speed
#      to trigger tyre smoke. Default value is 0.05. More realistic results can
#      be achieved with significantly higher values (i.e. use 0.8).
#
#    check_vspeed: 1 when tyre smoke should only be triggered when vspeed is negative
#      (usually doesn't work for all gear, since vspeed=0.0 after the first gear touches
#      ground). Use 0 to make tyre smoke independent of vspeed.
#      Note: in reality, tyre smoke doesn't depend on vspeed, but only on acceleration
#      and friction.
#
#    rain_norm_trigger: threshold for deciding that there is enough standing water to 
#                       calculate spray. This is compared against rain-norm.
#
aircraft.tyresmoke = {
	new: func(number, auto = 0, diff_norm = 0.05, check_vspeed=1, rain_norm_trigger=0.2) {
print("F-14 override tyresmoke ",number);
		var m = { parents: [aircraft.tyresmoke] };
		m.vertical_speed = (!check_vspeed) ? nil : props.globals.initNode("velocities/vertical-speed-fps");
		m.diff_norm = diff_norm;
		m.speed = props.globals.initNode("velocities/groundspeed-kt");
		m.rain_node = props.globals.initNode("environment/metar/rain-norm");
                m.rain_norm_trigger = rain_norm_trigger;
		var gear = props.globals.getNode("gear/gear[" ~ number ~ "]/");
		m.wow_node = gear.initNode("wow");
      		m.last_wow = m.wow_node.getValue();
		m.tyresmoke = gear.initNode("tyre-smoke", 0, "BOOL");
		m.friction_factor_node = gear.initNode("ground-friction-factor", 1);
		m.sprayspeed = gear.initNode("sprayspeed-ms");
		m.spray = gear.initNode("spray", 0, "BOOL");
		m.spraydensity = gear.initNode("spray-density", 0, "DOUBLE");
		m.auto = auto;
		m.listener = nil;
                me.lastwow=0;

                if (getprop("sim/flight-model") == "jsb") {
			var wheel_speed = "fdm/jsbsim/gear/unit[" ~ number ~ "]/wheel-speed-fps";
			m.rollspeed_node = props.globals.initNode(wheel_speed);
			m.get_rollspeed = func m.rollspeed_node.getValue() * 0.3043;
		} else {
			m.rollspeed_node = gear.initNode("rollspeed-ms");
			m.get_rollspeed = func m.rollspeed_node.getValue();
		}

		m.lp = aircraft.lowpass.new(2);
		m.lpf_touchdown = aircraft.lowpass.new(0.15);
		auto and m.update();
		return m;
	},
	del: func {
		if (me.listener != nil) {
			removelistener(me.listener);
			me.listener = nil;
		}
		me.auto = 0;
	},
	calc_spray_factor: func(groundspeed_kts)
	{
		# based on Figure 31(a)[1]; Variation of drag parameter with ground speed in water
		# for dual tandem wheels without spray-drag alleviator curve fitted and normalized.
		#
		# My The logic here is that the spray will be a factor of the drag and using the
		# curve from Figure 31(a) is at least based in reality, whereas previously
		# a simple factor was used which tended to give spray at much too low groundspeeds.
		#
		#   |
		#   |
		# 1 |                  +-------------------------------------------------
		#   |               __/
		#   |              /
		#   |             /
		#   |            /
		#   |            /
		#   |           /
		#   |           /
		#   |          /
		#   |          /
		#   |         /
		#   |         /
		#   |        /
		#   |        /
		#   |       /
		#   |     _/
		#  0| __--
		#   +--------------------------------------------------------------------
		#    0    20    40   60    80   100  120   140  160   180  200   220  240
		#
		#_______________________________________________________________________________
		# ref: https://ntrs.nasa.gov/api/citations/19660021919/downloads/19660021919.pdf
		#-------------------
		# Curve fit: MMF Model: y = (a * b + c * x ^ d) / (b + x ^ d)
		#        Coefficient Data: a=0.03048   b=59175231  c=2.38119  d=5.08271
		# Normalized by using max value 2.38105217250475

		return ((0.03048 * 59175231 +  2.38119 * math.pow(groundspeed_kts, 5.08271))
		       / (59175231 + math.pow(groundspeed_kts, 5.08271)) / 2.38105217250475)
                       ;
        },
	update: func {
		me.rollspeed = me.get_rollspeed();
		me.vert_speed = (me.vertical_speed) != nil ? me.vertical_speed.getValue() : -999;
		me.groundspeed_kts = me.speed.getValue();
		me.friction_factor = me.friction_factor_node.getValue();
		me.wow = me.wow_node.getValue();
		me.rain = me.rain_node.getValue();

		me.filtered_rollspeed = me.lp.filter(me.rollspeed);
		me.rollspeed_diff = math.abs(me.rollspeed - me.filtered_rollspeed);
		me.rollspeed_diff_norm = me.rollspeed_diff > 0 ? me.rollspeed_diff / me.rollspeed : 0;
		me.spray_factor = me.calc_spray_factor(me.groundspeed_kts);

		# touchdown
		# - wow changed (previously 0)
		# - use a filter on touchdown and use this to determine if the smoke is active.
		me.touchdown = 0;
		if (me.wow != me.lastwow){
			if (me.wow){
			me.lpf_touchdown.set(math.abs(me.vert_speed));
			}
			else me.filtered_touchdown = me.lpf_touchdown.filter(0);
		}
		else me.filtered_touchdown = me.lpf_touchdown.filter(0);

		# touchdown smoke when
		# * recently touched down
		# * rollspeed must be over the limit
		# * friction must be over a limit (no idea why this is 0.7)
		# * moving at ground speed > 50kts (not sure about this)
		# * not raining
		# possibly using ground speed is somewhat irrelevant - but I'm leaving that here
		# as it may filter out unwanted smoke.
		if (me.filtered_touchdown > 1.0
            and me.rollspeed_diff_norm > me.diff_norm
		    and me.friction_factor > 0.7
            and me.groundspeed_kts > 50
            and me.rain <me.rain_norm_trigger) {
			me.tyresmoke.setValue(1);
			me.spray.setValue(0);
			me.spraydensity.setValue(0);
			me.active = 1;
		} elsif (me.wow and me.rain >= me.rain_norm_trigger) {
			me.tyresmoke.setValue(0);
			me.spray.setValue(1);
			me.sprayspeed.setValue(me.rollspeed * 6);
			me.spraydensity.setValue(me.rain * me.spray_factor * me.groundspeed_kts);
			me.active = 1;
		} else {
			me.active = 0;
			me.tyresmoke.setValue(0);
			me.spray.setValue(0);
			me.sprayspeed.setValue(0);
			me.spraydensity.setValue(0);
		}
		# if automatic smoke then when  we have weight on wheels
		# or smoke is currently active we will need to update again next
		# frame.
		if (me.auto) {
			if (me.active or me.wow) {
				settimer(func me.update(), 0);
				if (me.listener != nil) {
					removelistener(me.listener);
					me.listener = nil;
				}
			} elsif (me.listener == nil) {
				me.listener = setlistener(me.wow_node, func me._wowchanged_(), 0, 0);
			}
		}
		me.lastwow = me.wow;
	},
	_wowchanged_: func() {
		if (me.wow_node.getValue()) {
			me.lp.set(0);
			me.update();
		}
	},
};

# tyresmoke_system
# =============================================================================
# Helper class to contain the tyresmoke objects for all the gears.
# Will update automatically, nothing else needs to be done by the caller.
#
# SYNOPSIS:
#	aircraft.tyresmoke_system.new(<gear index 1>, <gear index 2>, ...)
#		<gear index> - the index of the gear to which the tyre smoke is attached
#	aircraft.tyresmoke_system.del()
#		destructor
# EXAMPLE:
#	var tyresmoke_system = aircraft.tyresmoke_system.new(0, 1, 2, 3, 4);

aircraft.tyresmoke_system = {
	new: func {
        print("F-14 override tyresmoke_system");
		var m = { parents: [aircraft.tyresmoke_system] };
		# preset array to proper size
		m.gears = [];
		setsize(m.gears, size(arg));
		for(var i = size(arg) - 1; i >= 0; i -= 1) {
			m.gears[i] = aircraft.tyresmoke.new(arg[i], 1);
		}
		return m;
	},
	del: func {
		foreach(var gear; me.gears) {
			gear.del();
		}
	}
};
