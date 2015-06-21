#
# F-15 Main Nasal Module 
# ---------------------------
# Declares globals; provides update loop 
# ---------------------------
# Richard Harrison (rjh@zaretto.com) 2014-11-23. Based on F-14b by xii
#

## Global constants ##
var true = 1;
var false = 0;

var deltaT = 1.0;

var currentG = 1.0;

#----------------------------------------------------------------------------
# Nozzle opening
#----------------------------------------------------------------------------

# Variables
var Nozzle1Target = 0.0;
var Nozzle2Target = 0.0;
var Nozzle1 = 0.0;
var Nozzle2 = 0.0;

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
var aileron = props.globals.getNode("surface-positions/left-aileron-pos-norm", 1);


# Utilities #########

# Lighting 
#setprop("sim/model/path","data/Aircraft/f15/F15.xml");
#setprop("sim/model/path","Aircraft/F-15C/Models/F-15C_Eagle.xml");

# Collision lights flasher
var anti_collision_switch = props.globals.getNode("sim/model/f15/controls/lighting/anti-collision-switch");
aircraft.light.new("sim/model/f15/lighting/anti-collision", [0.09, 1.20], anti_collision_switch);
var position_flash_sw = props.globals.getNode("sim/model/f15/controls/lighting/position-flash-switch",1);

# Navigation lights steady/flash dimmed/bright
var position_flash_sw = props.globals.getNode("sim/model/f15/controls/lighting/position-flash-switch");
var position = aircraft.light.new("sim/model/f15/lighting/position", [0.08, 1.15]);
setprop("/sim/model/f15/lighting/position/enabled", 1);
setprop("sim/model/f15/fx/smoke",0);

var lighting_taxi  = props.globals.getNode("controls/lighting/taxi-light", 1);

getprop("fdm/jsbsim/fcs/flap-pos-norm",0);
var sw_pos_prop = props.globals.getNode("sim/model/f15/controls/lighting/position-wing-switch", 1);
var position_intens = 0;
setprop("fdm/jsbsim/Factor1",1);
setprop("sim/fdm/surface/override-level", 0);

aircraft.tyresmoke_system.new(0, 1, 2);
aircraft.rain.init();
setprop("/environment/aircraft-effects/overlay-alpha",0.45);
setprop("/environment/aircraft-effects/use-overlay",1);
setprop("/environment/aircraft-effects/use-reflection",1);
setprop("/environment/aircraft-effects/reflection-strength",0.25);


var position_switch = func(n) {
	var sw_pos = sw_pos_prop.getValue();
	if (n == 1) {
		if (sw_pos == 0) {
			sw_pos_prop.setIntValue(1);
			position.switch(0);
			position_intens = 0;
		} elsif (sw_pos == 1) {
			sw_pos_prop.setIntValue(2);
			position.switch(1);
			position_intens = 6;
		}
	} else {
		if (sw_pos == 2) {
			sw_pos_prop.setIntValue(1);
			position.switch(0);
			position_intens = 0;
		} elsif (sw_pos == 1) {
			sw_pos_prop.setIntValue(0);
			position.switch(1);
			position_intens = 3;
		}
	}	
}
var position_flash_switch = func {
	if (! position_flash_sw.getBoolValue() ) {
		position_flash_sw.setBoolValue(1);
		position.blink();
	} else {
		position_flash_sw.setBoolValue(0);
		position.cont();
	}
}

var position_flash_init  = func {
	if (position_flash_sw.getBoolValue() ) {
		position.blink();
	} else {
		position.cont();
	}
	var sw_pos = sw_pos_prop.getValue();
	if (sw_pos == 0 ) {
		position_intens = 3;
		position.switch(1);
	} elsif (sw_pos == 1 ) {
		position_intens = 0;
		position.switch(0);
	} elsif (sw_pos == 2 ) {
		position_intens = 6;
		position.switch(1);
	}
}


# Canopy switch animation and canopy move. Toggle keystroke and 2 positions switch.
# Timing from https://www.youtube.com/watch?v=MSWz55b_jtE 2:25 (about 5 seconds)
var cnpy = aircraft.door.new("canopy", 5);
var pos = props.globals.getNode("canopy/position-norm");


setlistener("sim/model/f15/controls/canopy/canopy-switch", func(prop) {
	var v = prop.getValue();
	if (!v)
	{
		cnpy.close();
	}
	else
	{
		cnpy.open();
	}
});


# Flight control system ######################### 


var lighting_collision = props.globals.getNode("sim/model/f15/lighting/anti-collision/state", 1);
var lighting_position  = props.globals.getNode("sim/model/f15/lighting/position/state", 1);
var left_wing_torn     = props.globals.getNode("sim/model/f15/wings/left-wing-torn");
var right_wing_torn    = props.globals.getNode("sim/model/f15/wings/right-wing-torn");

var main_flap_generic  = props.globals.getNode("sim/multiplay/generic/float[1]",1);
var aileron_generic   = props.globals.getNode("sim/multiplay/generic/float[2]",1);
#var slat_generic       = props.globals.getNode("sim/multiplay/generic/float[3]",1);
var left_elev_generic  = props.globals.getNode("sim/multiplay/generic/float[4]",1);
var right_elev_generic = props.globals.getNode("sim/multiplay/generic/float[5]",1);
var elev_output   = props.globals.getNode("surface-positions/elevator-pos-norm", 1);
var fuel_dump_generic  = props.globals.getNode("sim/multiplay/generic/int[0]",1);
# sim/multiplay/generic/int[1] used by formation slimmers.
# sim/multiplay/generic/int[2] used by radar standby.
var lighting_collision_generic = props.globals.getNode("sim/multiplay/generic/int[3]",1);
var lighting_position_generic  = props.globals.getNode("sim/multiplay/generic/int[4]",1);
var left_wing_torn_generic     = props.globals.getNode("sim/multiplay/generic/int[5]",1);
var right_wing_torn_generic    = props.globals.getNode("sim/multiplay/generic/int[6]",1);
var lighting_taxi_generic       = props.globals.getNode("sim/multiplay/generic/int[7]",1);

#
#
# ARA-63 (Carrier Landing System) support
var tuned_carrier_name=getprop("/sim/presets/carrier");
var carrier_ara_63_position = nil;
var carrier_heading = nil;
var carrier_ara_63_heading = nil;

var wow = 1;
setprop("/fdm/jsbsim/fcs/roll-trim-actuator",0) ;
setprop("/controls/flight/SAS-roll",0);
var registerFCS = func {settimer (updateFCS, 0);}

#
#
# set the splash vector for the new canopy rain.

# for tuning the vector; these will be baked in once finished
setprop("/sim/model/f15/sfx1",-0.1);
setprop("/sim/model/f15/sfx2",4);
setprop("/sim/model/f15/sf-x-max",400);
setprop("/sim/model/f15/sfy1",0);
setprop("/sim/model/f15/sfy2",0.1);
setprop("/sim/model/f15/sfz1",1);
setprop("/sim/model/f15/sfz2",-0.1);

#var vl_x = 0;
#var vl_y = 0;
#var vl_z = 0;
#var vsplash_precision = 0.001;
var splash_vec_loop = func
{
    var v_x = getprop("/fdm/jsbsim/velocities/u-aero-fps");
    var v_y = getprop("/fdm/jsbsim/velocities/v-aero-fps");
    var v_z = getprop("/fdm/jsbsim/velocities/w-aero-fps");
#    var v_x = getprop("/velocities/uBody-fps");
#    var v_y = getprop("/velocities/vBody-fps");
#    var v_z = getprop("/velocities/wBody-fps");
    var v_x_max = getprop("/sim/model/f15/sf-x-max");
 
    if (v_x > v_x_max) 
        v_x = v_x_max;
 
    if (v_x > 1)
        v_x = math.sqrt(v_x/v_x_max);
#var splash_x = -0.1 - 2.0 * v_x;
#var splash_y = 0.0;
#var splash_z = 1.0 - 1.35 * v_x;

    var splash_x = getprop("/sim/model/f15/sfx1") - getprop("/sim/model/f15/sfx2") * v_x;
    var splash_y = getprop("/sim/model/f15/sfy1") - getprop("/sim/model/f15/sfy2") * v_y;
    var splash_z = getprop("/sim/model/f15/sfz1") - getprop("/sim/model/f15/sfz2") * v_z;

#if (math.abs(vl_x - v_x) >  vsplash_precision)
    setprop("/environment/aircraft-effects/splash-vector-x", splash_x);
#if (math.abs(vl_y - v_y) >  vsplash_precision)
    setprop("/environment/aircraft-effects/splash-vector-y", splash_y);
#if (math.abs(vl_z - v_z) >  vsplash_precision)
    setprop("/environment/aircraft-effects/splash-vector-z", splash_z);
#vl_x = v_x;
#vl_y = v_y;
#vl_z = v_z;

#    interpolate("/environment/aircraft-effects/splash-vector-z", splash_z, 0.01);
 
if (wow and getprop("gear/gear[0]/rollspeed-ms") < 30)
    settimer( func {splash_vec_loop() },2.5);
else
    settimer( func {splash_vec_loop() },1.2);

}

splash_vec_loop();

#
# Rate 4 modules (5hz) (rate 4 comes from quarter frame at 30hz)

var rate4modules = func {
    aircraft.updateVSD();
    aircraft.updateTEWS();
    aircraft.updateMPCD();
    aircraft.electricsFrame();
	aircraft.computeNWS ();
	settimer (rate4modules, 0.20);
}
var rate2modules = func {
    aircraft.updateHUD();
	settimer (rate2modules, 0.04);
    setprop("environment/aircraft-effects/frost-level", getprop("/fdm/jsbsim/systems/ecs/windscreen-frost-amount"));
}
#
# launch the timers; the time here isn't important as it will be rescheduled within the rate module exec
settimer (rate4modules, 1); 
settimer (rate2modules, 1);

#
# Standard update loop.

var updateFCS = func {
	 aircraft.rain.update();

	#Fectch most commonly used values
	CurrentIAS = getprop ("/velocities/airspeed-kt");
	CurrentMach = getprop ("/velocities/mach");
	CurrentAlt = getprop ("/position/altitude-ft");
	wow = getprop ("/gear/gear[1]/wow") or getprop ("/gear/gear[2]/wow");

	Alpha = getprop ("/orientation/alpha-indicated-deg");
	Throttle = getprop ("/controls/engines/engine/throttle");
	e_trim = getprop ("/controls/flight/elevator-trim");
	deltaT = getprop ("sim/time/delta-sec");

    # the FDM has a combined aileron deflection so split this for animation purposes.
    var current_aileron = aileron.getValue();
    var elevator_deflection_due_to_aileron_deflection =  current_aileron / 3.33; # 20 aileron - 6 elevator. should come from the DTD
    left_elev_generic.setDoubleValue(elev_output.getValue() + elevator_deflection_due_to_aileron_deflection);
    right_elev_generic.setDoubleValue(elev_output.getValue() - elevator_deflection_due_to_aileron_deflection);
    aileron_generic.setDoubleValue(-current_aileron);

    currentG = getprop ("accelerations/pilot-gdamped");
    # use interpolate to make it take 1.2seconds to affect the demand

    var dmd_afcs_roll = getprop("/controls/flight/SAS-roll");
    var roll_mode = getprop("autopilot/locks/heading");

    if(roll_mode != "dg-heading-hold" and roll_mode != "wing-leveler" and roll_mode != "true-heading-hold" )
        setprop("fdm/jsbsim/fcs/roll-trim-sas-cmd-norm",0);
    else
    {
        var roll = getprop("orientation/roll-deg");
        if (dmd_afcs_roll < -0.11) dmd_afcs_roll = -0.11;
        else if (dmd_afcs_roll > 0.11) dmd_afcs_roll = 0.11;

#print("AFCS ",roll," DMD ",dmd_afcs_roll, " SAS=", getprop("/controls/flight/SAS-roll"), " cur=",getprop("fdm/jsbsim/fcs/roll-trim-cmd-norm"));
        if (roll < -45 and dmd_afcs_roll < 0) dms_afcs_roll = 0;
        if (roll > 45 and dmd_afcs_roll > 0) dms_afcs_roll = 0;

        interpolate("fdm/jsbsim/fcs/roll-trim-sas-cmd-norm",dmd_afcs_roll,0.1);
    }

	#update functions
    aircraft.computeAPC();
	aircraft.computeEngines ();
	aircraft.computeAdverse ();

	aircraft.registerFCS (); # loop, once per frame.
}


var startProcess = func {
	settimer (updateFCS, 1.0);
	position_flash_init();
#slat_output.setDoubleValue(0);

}

setlistener("/sim/signals/fdm-initialized", startProcess);

#----------------------------------------------------------------------------
# View change: Ctrl-V switchback to view #0 but switch to Rio view when already
# in view #0.
#----------------------------------------------------------------------------

var CurrentView_Num = props.globals.getNode("sim/current-view/view-number");
#var rio_view_num = view.indexof("RIO View");

var toggle_cockpit_views = func() {
	cur_v = CurrentView_Num.getValue();
	if (cur_v != 0 )
    {
		CurrentView_Num.setValue(0);
	}
#    else {
#        CurrentView_Num.setValue(rio_view_num);
#    }
}


var quickstart = func() {
#    setprop("controls/electric/engine[0]/generator",1);
#    setprop("controls/electric/engine[1]/generator",1);
#    setprop("controls/electric/engine[0]/bus-tie",1);
#    setprop("controls/electric/engine[1]/bus-tie",1);
#    setprop("systems/electrical/outputs/avionics",1);
#    setprop("controls/electric/inverter-switch",1);
    if(total_lbs < 400)
        set_fuel(5500);

        settimer(func { 

#    setprop("controls/lighting/panel-norm",1);
#    setprop("controls/lighting/instruments-norm",1);
    setprop("sim/model/f15/controls/hud/on-off",1);
    setprop("sim/model/f15/controls/VDI/on-off",1);
    setprop("sim/model/f15/controls/HSD/on-off",1);

setprop("sim/model/f15/controls/windshield-heat",1);
    setprop("sim/model/f15/controls/electrics/emerg-flt-hyd-switch",0);
    setprop("sim/model/f15/controls/electrics/emerg-gen-guard-lever",0);
	setprop("sim/model/f15/controls/electrics/emerg-gen-switch",1);
    setprop("sim/model/f15/controls/electrics/l-gen-switch",1);
    setprop("sim/model/f15/controls/electrics/master-test-switch",0);
	setprop("sim/model/f15/controls/electrics/r-gen-switch",1);

    setprop("controls/engines/engine[0]/cutoff",0);
    setprop("controls/engines/engine[1]/cutoff",0);
    setprop("engines/engine[0]/out-of-fuel",0);
    setprop("engines/engine[1]/out-of-fuel",0);
    setprop("engines/engine[1]/run",1);
    setprop("engines/engine[1]/run",1);
    setprop("fdm/jsbsim/fcs/pitch-damper-enable",1);
    setprop("fdm/jsbsim/fcs/roll-damper-enable",1);
    setprop("fdm/jsbsim/fcs/yaw-damper-enable",1);

setprop("/engines/engine[1]/cutoff",0);
setprop("/engines/engine[0]/cutoff",0);

setprop("/fdm/jsbsim/propulsion/starter_cmd",1);
setprop("/fdm/jsbsim/propulsion/cutoff_cmd",1);
setprop("/fdm/jsbsim/propulsion/set-running",1);
setprop("/fdm/jsbsim/propulsion/set-running",0);
 }, 0.2);
}



