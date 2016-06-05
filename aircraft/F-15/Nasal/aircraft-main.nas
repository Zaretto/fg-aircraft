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

# Collision lights flasher
var anti_collision_switch = props.globals.getNode("sim/model/f15/controls/lighting/anti-collision-switch");
aircraft.light.new("sim/model/f15/lighting/anti-collision", [0.09, 1.20], anti_collision_switch);
var position_flash_sw = props.globals.getNode("sim/model/f15/controls/lighting/position-flash-switch",1);

# Navigation lights steady/flash dimmed/bright
var position_flash_sw = props.globals.getNode("sim/model/f15/controls/lighting/position-flash-switch");
var position = aircraft.light.new("sim/model/f15/lighting/position", [0.08, 1.15]);
setprop("sim/model/f15/lighting/position/enabled", 1);
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


#
#
# setprop within range
var  setprop_inrange = func(p,v,mn,mx)
{
    if (mn != nil and v < mn)
        v = mn;
    if (mx != nil and  v > mx)
        v = mx;
    setprop(p,v);
};

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
var wing_torn_generic     = props.globals.getNode("sim/multiplay/generic/float[3]",1);
var lighting_taxi_generic       = props.globals.getNode("sim/multiplay/generic/int[6]",1);

#
#
# ARA-63 (Carrier Landing System) support
var tuned_carrier_name=getprop("/sim/presets/carrier");
var carrier_ara_63_position = nil;
var carrier_heading = nil;
var carrier_ara_63_heading = nil;

var wow = 1;
setprop("fdm/jsbsim/fcs/roll-trim-actuator",0) ;
setprop("controls/flight/SAS-roll",0);
var registerFCS = func {settimer (updateFCS, 0);}

#
#
# set the splash vector for the new canopy rain.

# for tuning the vector; these will be baked in once finished
#setprop("sim/model/f15/sfx1",-0.1);
#setprop("sim/model/f15/sfx2",4);
#setprop("sim/model/f15/sf-x-max",400);
#setprop("sim/model/f15/sfy1",0);
#setprop("sim/model/f15/sfy2",0.1);
#setprop("sim/model/f15/sfz1",1);
#setprop("sim/model/f15/sfz2",-0.1);

#var vl_x = 0;
#var vl_y = 0;
#var vl_z = 0;
#var vsplash_precision = 0.001;
var splash_vec_loop = func
{
    var v_x = getprop("fdm/jsbsim/velocities/u-aero-fps");
    var v_y = getprop("fdm/jsbsim/velocities/v-aero-fps");
    var v_z = getprop("fdm/jsbsim/velocities/w-aero-fps");
#    var v_x = getprop("velocities/uBody-fps");
#    var v_y = getprop("velocities/vBody-fps");
#    var v_z = getprop("velocities/wBody-fps");
#    var v_x_max = getprop("sim/model/f15/sf-x-max");
    var v_x_max =400;
 
    if (v_x > v_x_max) 
        v_x = v_x_max;
 
    if (v_x > 1)
        v_x = math.sqrt(v_x/v_x_max);
#var splash_x = -0.1 - 2.0 * v_x;
#var splash_y = 0.0;
#var splash_z = 1.0 - 1.35 * v_x;
#    var splash_x = getprop("sim/model/f15/sfx1") - getprop("sim/model/f15/sfx2") * v_x;
#    var splash_y = getprop("sim/model/f15/sfy1") - getprop("sim/model/f15/sfy2") * v_y;
#    var splash_z = getprop("sim/model/f15/sfz1") - getprop("sim/model/f15/sfz2") * v_z;

    var splash_x = -0.1 - 4   * v_x;
    var splash_y =  0   - 0.1 * v_y;
    var splash_z =  1   - 0.1 * v_z;

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
# Sound volumes; need to do it here because the sound calculation methods are not capable of this.

var updateVolume = func
{
#var n1_l = getprop("engines/engine[0]/n1");
#var n1_r = getprop("engines/engine[1]/n1");
var n2_l = getprop("engines/engine[0]/n2");
var n2_r = getprop("engines/engine[1]/n2");

    if(getprop("sim/current-view/internal"))
        setprop("fdm/jsbsim/systems/sound/cockpit-adjusted-external-volume",
                0.2
                + getprop("canopy/position-norm")-getprop("fdm/jsbsim/systems/ecs/pilot-helmet-volume-attenuation"));
    else
        setprop("fdm/jsbsim/systems/sound/cockpit-adjusted-external-volume",1);


    setprop_inrange("fdm/jsbsim/systems/sound/cockpit-effects-volume", 
             0.3
             - getprop("fdm/jsbsim/systems/ecs/pilot-helmet-volume-attenuation"),0,1);

#
# cold end of the engines
    setprop_inrange("fdm/jsbsim/systems/sound/engine-jet-intake-l-volume",
             0.0133
             * n2_l
             * getprop("fdm/jsbsim/systems/sound/cockpit-adjusted-external-volume"),nil,1);

    setprop_inrange("fdm/jsbsim/systems/sound/engine-jet-intake-r-volume",
             0.0133
             * n2_r
             * getprop("fdm/jsbsim/systems/sound/cockpit-adjusted-external-volume"),nil,1);

    setprop_inrange("fdm/jsbsim/systems/sound/engine-n2-l-volume",
             0.015
             * n2_l
             * getprop("fdm/jsbsim/systems/sound/cockpit-adjusted-external-volume"),nil,0.4);
    setprop_inrange("fdm/jsbsim/systems/sound/engine-n2-r-volume",
             0.015
             * n2_r
             * getprop("fdm/jsbsim/systems/sound/cockpit-adjusted-external-volume"),nil,0.4);

#
# hot end of the engines.
# using PB (the gasgen based pressure at the burner) for this is more accurate
# however it doesn't produce the right sort of levels for external in-air (and flyby) views
# - the physics for sound volume is (a more complex version) of pressure and velocity - however
#   PB is relative to the engine so at speed the velocity of the aircraft isn't going to be added in
#   to produce realistic levels for an observer. I could take PB and add back in velocity but that would
#   effectively be the same as n2 as PB is based on N2 and mach.

#
#
# this is the fade out as the engines spool down. the noise from the stuff coming out the back
# decreases quite rapidly ; so I'm using ln(n) based on 40% n2.
# previous I did math.ln((getprop("engines/engine[0]/PB"))) but that doesn't work well at higher speeds
# as PB drops with forward velocity (because of the decreased resistance behind the engine).
#             math.ln((getprop("engines/engine[1]/PB")))

#var n2_r_f = 1;
#if (n2_r < 40)
#{
#    var v1 = 1-n2_r/40;
#    if (v1 != 0)
#        n2_r_f = math.ln(v1)/-3.82970;
#    else
#        n2_r_f = 0;
#}

#var n2_l_f = 1;
#if (n2_l < 40)
#{
#    var v1 = 1-n2_l/40;
#    if (v1 != 0)
#        n2_l_f = math.ln(v1)/-3.82970;
#    else
#        n2_l_f = 0;
#}
#=math.ln(math.max(0.01,n2_l*0.01))/4.605*5*(n2_l-30);

    setprop_inrange("fdm/jsbsim/systems/sound/engine-jet-exhaust-l-volume",
             (n2_l-30)/70
             * getprop("fdm/jsbsim/systems/sound/cockpit-adjusted-external-volume"), 0, 1.0);

    setprop_inrange("fdm/jsbsim/systems/sound/engine-jet-exhaust-r-volume",
             (n2_r-30)/70
             * getprop("fdm/jsbsim/systems/sound/cockpit-adjusted-external-volume"), 0, 1.0);

    setprop_inrange("fdm/jsbsim/systems/sound/engine-efflux-l-volume",
             (n2_l-30)/70
             * getprop("fdm/jsbsim/systems/sound/cockpit-adjusted-external-volume"), 0, 1.0);


    setprop_inrange("fdm/jsbsim/systems/sound/engine-efflux-r-volume",
             (n2_r-30)/70
             * getprop("fdm/jsbsim/systems/sound/cockpit-adjusted-external-volume"),0, 1.0);

    setprop_inrange("fdm/jsbsim/systems/sound/engine-jet-augmentation-l-volume",
             0.06
             * getprop("engines/engine[0]/afterburner")
             * getprop("fdm/jsbsim/systems/sound/cockpit-adjusted-external-volume"),nil,0.4);

    setprop_inrange("fdm/jsbsim/systems/sound/engine-jet-augmentation-r-volume",
             0.06
             * getprop("engines/engine[1]/afterburner")
             * getprop("fdm/jsbsim/systems/sound/cockpit-adjusted-external-volume"),nil,0.4);

#efflux was: 
# cond  : engines/engine[0]/thrust_lb > 200 and instrumentation/airspeed-indicator/indicated-speed-kt > 100
# volume: 0.4
#
#exhaust was 
# volume: -0.3 + 0.01 * engines/engine[0]/n2
}

#
# --------------------------
# Frame adapative update - two methods either rate 2 or rate 4.
# RJH: 2015-08-16
# Note: continual update of canvas elements at low frame rates makes 
# things worse so we skip frames to reduce the load.
# At higher frame rates the extra updates aren't required so we will skip
# frames based on the frame rate (this is effectively 4/15 - i.e. the update
# every 4 frames but extended to work for higher rates)
#
# continual update of canvas elements at low frame rates makes things worse
# so we skip frames to reduce the load.
# at higher frame rates the extra updates aren't required so we will skip
# frames based on the frame rate (this is effectively 4/15 - i.e. the update
# every 4 frames but extended to work for higher rates)
# ---------------

# Rate 4 modules (5hz) (rate 4 comes from quarter frame at 30hz)
var r4_count = 0;
var r2_count = 0;

var rate4modules = func {
    r4_count = r4_count - 1;
    var frame_rate = getprop("/sim/frame-rate");

    if (frame_rate <= 15 or frame_rate > 100)
        r4_count = 4;
    else
        r4_count = (int)(frame_rate * 0.26667);

    aircraft.updateVSD();
    aircraft.updateTEWS();
    aircraft.updateMPCD();
    aircraft.electricsFrame();
	aircraft.computeNWS ();
aircraft.update_weapons_over_mp();
updateVolume();
#	settimer (rate4modules, 0.20);

#
# ensure that we're not ground refuelling in air...
if (getprop("fdm/jsbsim/propulsion/ground-refuel") and (!wow or getprop("fdm/jsbsim/gear/unit[2]/wheel-speed-fps") > 0))
{
setprop("fdm/jsbsim/propulsion/refuel",0);
setprop("fdm/jsbsim/propulsion/ground-refuel",0);
}

}
#
#
# rate 2 modules; nominally at half rate.
var rate2modules = func {
    r2_count = r2_count - 1;
    if (r2_count > 0)
        return;

    var frame_rate = getprop("/sim/frame-rate");
    if (frame_rate <= 15 or frame_rate > 100)
        r2_count = 2;
    else
        r2_count = (int)(frame_rate * 0.1333);

    aircraft.updateHUD();
#	settimer (rate2modules, 0.1);
    setprop("/environment/aircraft-effects/frost-level", getprop("fdm/jsbsim/systems/ecs/windscreen-frost-amount"));
}
#
# launch the timers; the time here isn't important as it will be rescheduled within the rate module exec
#settimer (rate4modules, 1); 
#settimer (rate2modules, 1);

#
# Standard update loop.

var updateFCS = func {
	 aircraft.rain.update();

	#Fetch most commonly used values
	CurrentIAS = getprop("velocities/airspeed-kt");
	CurrentMach = getprop("velocities/mach");
	CurrentAlt = getprop("position/altitude-ft");
	wow = getprop("gear/gear[1]/wow") or getprop("gear/gear[2]/wow");

	Alpha = getprop("orientation/alpha-indicated-deg");
	Throttle = getprop("controls/engines/engine/throttle");
	e_trim = getprop("controls/flight/elevator-trim");
	deltaT = getprop ("sim/time/delta-sec");

    # the FDM has a combined aileron deflection so split this for animation purposes.
    var current_aileron = aileron.getValue();
    var elevator_deflection_due_to_aileron_deflection =  current_aileron / 3.33; # 20 aileron - 6 elevator. should come from the DTD
    left_elev_generic.setDoubleValue(elev_output.getValue() + elevator_deflection_due_to_aileron_deflection);
    right_elev_generic.setDoubleValue(elev_output.getValue() - elevator_deflection_due_to_aileron_deflection);
    aileron_generic.setDoubleValue(-current_aileron);

    currentG = getprop ("accelerations/pilot-gdamped");
    # use interpolate to make it take 1.2seconds to affect the demand

    var dmd_afcs_roll = getprop("controls/flight/SAS-roll");
    var roll_mode = getprop("autopilot/locks/heading");

    if(roll_mode != "dg-heading-hold" and roll_mode != "wing-leveler" and roll_mode != "true-heading-hold" )
        setprop("fdm/jsbsim/fcs/roll-trim-sas-cmd-norm",0);
    else
    {
        var roll = getprop("orientation/roll-deg");
        if (dmd_afcs_roll < -0.11) dmd_afcs_roll = -0.11;
        else if (dmd_afcs_roll > 0.11) dmd_afcs_roll = 0.11;

#print("AFCS ",roll," DMD ",dmd_afcs_roll, " SAS=", getprop("controls/flight/SAS-roll"), " cur=",getprop("fdm/jsbsim/fcs/roll-trim-cmd-norm"));
        if (roll < -45 and dmd_afcs_roll < 0) dms_afcs_roll = 0;
        if (roll > 45 and dmd_afcs_roll > 0) dms_afcs_roll = 0;

        interpolate("fdm/jsbsim/fcs/roll-trim-sas-cmd-norm",dmd_afcs_roll,0.1);
    }

	#update functions
    aircraft.computeAPC();
	aircraft.computeEngines ();
	aircraft.computeAdverse ();
rate2modules();
rate4modules();
	aircraft.registerFCS (); # loop, once per frame.
}


var startProcess = func {
	settimer (updateFCS, 1.0);
	position_flash_init();
#slat_output.setDoubleValue(0);

}
var two_seater = getprop("fdm/jsbsim/metrics/two-place-canopy");
if (two_seater)
print("F-15 two seat variant (B,D,E)");

setlistener("/sim/signals/fdm-initialized", startProcess);

#----------------------------------------------------------------------------
# View change: Ctrl-V switchback to view #0 but switch to Rio view when already
# in view #0.
#----------------------------------------------------------------------------

var CurrentView_Num = props.globals.getNode("sim/current-view/view-number");
var backseat_view_num = view.indexof("Backseat View");

var toggle_cockpit_views = func() {
	cur_v = CurrentView_Num.getValue();
	if (cur_v != 0 )
    {
		CurrentView_Num.setValue(0);
	}
    else if(two_seater){
        CurrentView_Num.setValue(backseat_view_num);
    }
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
    setprop("sim/model/f15/controls/HUD/brightness",1);
    setprop("sim/model/f15/controls/HUD/on-off",true);
    setprop("sim/model/f15/controls/VSD/brightness",1);
    setprop("sim/model/f15/controls/VSD/on-off",true);
    setprop("sim/model/f15/controls/TEWS/brightness",1);
    setprop("sim/model/f15/controls/MPCD/brightness",1);
    setprop("sim/model/f15/controls/MPCD/on-off",true);
    setprop("sim/model/f15/controls/MPCD/mode",2);
    setprop("sim/model/f15/lights/radio2-brightness",0.6);

#    setprop("sim/model/f15/controls/windshield-heat",1);
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

setprop("engines/engine[1]/cutoff",0);
setprop("engines/engine[0]/cutoff",0);

setprop("fdm/jsbsim/propulsion/starter_cmd",1);
setprop("fdm/jsbsim/propulsion/cutoff_cmd",1);
setprop("fdm/jsbsim/propulsion/set-running",1);
setprop("fdm/jsbsim/propulsion/set-running",0);

    setprop("sim/model/f15/controls/engines/l-ramp-switch", 1);
    setprop("sim/model/f15/controls/engines/r-ramp-switch", 1);
    setprop("sim/model/f15/controls/fuel/dump-switch",0);
    setprop("sim/model/f15/controls/fuel/refuel-probe-switch",0);

    setprop("sim/model/f15/controls/engines/l-eec-switch",1);
    setprop("sim/model/f15/controls/engines/r-eec-switch",1);
    setprop("sim/model/f15/controls/electrics/emerg-gen-switch",1);
    setprop("sim/model/f15/controls/engs/l-eng-master-guard",0);
    setprop("sim/model/f15/controls/engs/r-eng-master-guard",0);
 }, 0.2);
}

var cold_and_dark = func()
{
	setprop("sim/model/f15/controls/electrics/emerg-gen-switch",9);
	setprop("sim/model/f15/controls/electrics/r-gen-switch",0);

    setprop("controls/engines/engine[0]/cutoff",1-getprop("controls/engines/engine[0]/cutoff"));
    setprop("controls/engines/engine[1]/cutoff",1-getprop("controls/engines/engine[1]/cutoff"));
    
    setprop("controls/lighting/aux-inst", 0);
    setprop("controls/lighting/eng-inst", 0);
    setprop("controls/lighting/flt-inst", 0);
    setprop("controls/lighting/instruments-norm",0);
    setprop("controls/lighting/l-console", 0);
    setprop("controls/lighting/panel-norm", 0);
    setprop("controls/lighting/panel-norm",0);
    setprop("controls/lighting/r-console", 0);
    setprop("controls/lighting/stby-inst", 0);
    setprop("controls/lighting/warn-caution", 0);

    setprop("fdm/jsbsim/fcs/pitch-damper-enable",0);
    setprop("fdm/jsbsim/fcs/roll-damper-enable",0);
    setprop("fdm/jsbsim/fcs/yaw-damper-enable",0);

    setprop("sim/model/f15/controls/HUD/brightness",0);
    setprop("sim/model/f15/controls/HUD/on-off",false);
    setprop("sim/model/f15/controls/MPCD/brightness",0);
    setprop("sim/model/f15/controls/MPCD/on-off",0);
    setprop("sim/model/f15/controls/TEWS/brightness",0);
    setprop("sim/model/f15/controls/VSD/on-off",false);
    setprop("sim/model/f15/controls/VSD/brightness",0);

    setprop("sim/model/f15/controls/electrics/emerg-flt-hyd-switch",0);
    setprop("sim/model/f15/controls/electrics/emerg-gen-guard-lever",0);
    setprop("sim/model/f15/controls/electrics/l-gen-switch",0);
    setprop("sim/model/f15/controls/electrics/master-test-switch",0);

    setprop("sim/model/f15/lights/master-test-lights", 0);
    setprop("sim/model/f15/lights/radio2-brightness",0);

    setprop("sim/multiplay/generic/int[1]", 0);
    setprop("sim/multiplay/generic/int[3]", 0);
    setprop("sim/multiplay/generic/int[4]", 0);
    setprop("sim/multiplay/generic/int[5]", 0);
    setprop("sim/multiplay/generic/int[6]", 0);
    setprop("sim/model/f15/controls/windshield-heat",0);

    setprop("sim/model/f15/controls/engines/l-ramp-switch", 0);
    setprop("sim/model/f15/controls/engines/r-ramp-switch", 0);
    setprop("sim/model/f15/controls/fuel/dump-switch",0);
    setprop("sim/model/f15/controls/fuel/refuel-probe-switch",0);

    setprop("sim/model/f15/controls/engines/l-eec-switch",0);
    setprop("sim/model/f15/controls/engines/r-eec-switch",0);
    setprop("sim/model/f15/controls/electrics/emerg-gen-switch",0);
    setprop("sim/model/f15/controls/engs/l-eng-master-guard",1);
    setprop("sim/model/f15/controls/engs/r-eng-master-guard",1);
    setprop("sim/model/f15/controls/electrics/jfs-starter",0);

    setprop("fdm/jsbsim/systems/electrics/ground-power",0);

}



setlistener("sim/walker/outside", func
{
#    if (getprop("sim/walker/outside") and getprop("sim/walker/outfit") == 1)
    if (getprop("sim/walker/outside"))
    {
        setprop("sim/model/hide-pilot",1);
        if (two_seater)
            setprop("sim/model/hide-backseater",1);
    }
    else
    {
        setprop("sim/model/hide-pilot",0);
        if (two_seater)
            setprop("sim/model/hide-backseater",0);
    }
});
setlistener("sim/walker/outfit", func
{
#    if (getprop("sim/walker/outside") and getprop("sim/walker/outfit") == 1)
    if (getprop("sim/walker/outside"))
    {
        setprop("sim/model/hide-pilot",1);
        if (two_seater)
            setprop("sim/model/hide-backseater",1);
    }
    else
    {
        setprop("sim/model/hide-pilot",0);
        if (two_seater)
            setprop("sim/model/hide-backseater",0);
    }
});

var resetView = func () {
  setprop("sim/current-view/field-of-view", getprop("sim/current-view/config/default-field-of-view-deg"));
  setprop("sim/current-view/heading-offset-deg", getprop("sim/current-view/config/heading-offset-deg"));
  setprop("sim/current-view/pitch-offset-deg", getprop("sim/current-view/config/pitch-offset-deg"));
  setprop("sim/current-view/roll-offset-deg", getprop("sim/current-view/config/roll-offset-deg"));
}