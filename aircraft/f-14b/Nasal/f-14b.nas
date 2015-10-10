# Utilities #########

# Lighting 
#setprop("sim/model/path","data/Aircraft/f-14b/F-14B.xml");

# Collision lights flasher
var anti_collision_switch = props.globals.getNode("sim/model/f-14b/controls/lighting/anti-collision-switch");
aircraft.light.new("sim/model/f-14b/lighting/anti-collision", [0.09, 1.20], anti_collision_switch);

# Navigation lights steady/flash dimmed/bright
var position_flash_sw = props.globals.getNode("sim/model/f-14b/controls/lighting/position-flash-switch");
var position = aircraft.light.new("sim/model/f-14b/lighting/position", [0.08, 1.15]);
setprop("/sim/model/f-14b/lighting/position/enabled", 1);
setprop("sim/model/f-14b/fx/smoke",0);

var lighting_taxi  = props.globals.getNode("controls/lighting/taxi-light", 1);

getprop("fdm/jsbsim/fcs/flap-pos-norm",0);
var sw_pos_prop = props.globals.getNode("sim/model/f-14b/controls/lighting/position-wing-switch", 1);
var position_intens = 0;
setprop("fdm/jsbsim/Factor1",1);
setprop("sim/fdm/surface/override-level", 0);

aircraft.tyresmoke_system.new(0, 1, 2);
aircraft.rain.init();

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
var cnpy = aircraft.door.new("canopy", 3.9);
#
#
# 
setprop("sim/model/f-14b/controls/canopy/canopy-switch", 0);
var pos = props.globals.getNode("canopy/position-norm");

#
#
# cockpit will simply toggle the value of this.
setlistener("sim/model/f-14b/controls/canopy/canopy-switch", func(v) {
	if (v.getValue()) 
        cnpy.open();
    else
		cnpy.close();

}, 1, 0);
#
#
# canopy switch toggle (from keyboard).
var canopyswitch = func(v) {
    var cp = getprop("sim/model/f-14b/controls/canopy/canopy-switch");

    setprop("sim/model/f-14b/controls/canopy/canopy-switch", 1 - cp);
}


# Flight control system ######################### 

# timedMotions

var CurrentLeftSpoiler = 0.0;
var CurrentRightSpoiler = 0.0;
var CurrentInnerLeftSpoiler = 0.0;
var CurrentInnerRightSpoiler = 0.0;
var SpoilerSpeed = 1.0; # full extension in 1 second
var currentSweep = 0.0;
var SweepSpeed = 0.3;


# Properties used for multiplayer syncronization.
var main_flap_output   = props.globals.getNode("surface-positions/main-flap-pos-norm", 1);
var aux_flap_output    = props.globals.getNode("surface-positions/aux-flap-pos-norm", 1);
var slat_output        = props.globals.getNode("surface-positions/slats-pos-norm", 1);

if (usingJSBSim){
    aux_flap_output    = props.globals.getNode("/fdm/jsbsim/fcs/aux-flap-pos-norm", 1);
    aux_flap_output.setDoubleValue(0);
var slat_output     = props.globals.getNode("/fdm/jsbsim/fcs/slat-cmd-norm", 1);
}
else
{
    slat_output        = props.globals.getNode("surface-positions/slats-pos-norm", 1);
}
aux_flap_output.setDoubleValue(0);


var left_elev_output   = props.globals.getNode("surface-positions/left-elevator-pos-norm", 1);
var right_elev_output  = props.globals.getNode("surface-positions/right-elevator-pos-norm", 1);
var elev_output   = props.globals.getNode("surface-positions/elevator-pos-norm", 1);
var aileron = props.globals.getNode("surface-positions/left-aileron-pos-norm", 1);

var lighting_collision = props.globals.getNode("sim/model/f-14b/lighting/anti-collision/state", 1);
var lighting_position  = props.globals.getNode("sim/model/f-14b/lighting/position/state", 1);
var left_wing_torn     = props.globals.getNode("sim/model/f-14b/wings/left-wing-torn");
var right_wing_torn    = props.globals.getNode("sim/model/f-14b/wings/right-wing-torn");

var wing_sweep_generic  = props.globals.getNode("sim/multiplay/generic/float[0]",1);
var main_flap_generic  = props.globals.getNode("sim/multiplay/generic/float[1]",1);
var aux_flap_generic   = props.globals.getNode("sim/multiplay/generic/float[2]",1);
var slat_generic       = props.globals.getNode("sim/multiplay/generic/float[3]",1);
var left_elev_generic  = props.globals.getNode("sim/multiplay/generic/float[4]",1);
var right_elev_generic = props.globals.getNode("sim/multiplay/generic/float[5]",1);
var fuel_dump_generic  = props.globals.getNode("sim/multiplay/generic/int[0]",1);
# sim/multiplay/generic/int[1] used by formation slimmers.
# sim/multiplay/generic/int[2] used by radar standby.
var lighting_collision_generic = props.globals.getNode("sim/multiplay/generic/int[3]",1);
var lighting_position_generic  = props.globals.getNode("sim/multiplay/generic/int[4]",1);
var left_wing_torn_generic     = props.globals.getNode("sim/multiplay/generic/int[5]",1);
var right_wing_torn_generic    = props.globals.getNode("sim/multiplay/generic/int[6]",1);
var lighting_taxi_generic       = props.globals.getNode("sim/multiplay/generic/int[7]",1);
# sim/multiplay/generic/string[0] used by external loads, see ext_stores.nas.


#
#
# ARA-63 (Carrier Landing System) support
var tuned_carrier_name=getprop("/sim/presets/carrier");
var carrier_ara_63_position = nil;
var carrier_heading = nil;
var carrier_ara_63_heading = nil;



var timedMotions = func {

	# disable if we are in replay mode
	if ( getprop("sim/replay/time") > 0 ) { return }

	if (deltaT == nil) deltaT = 0.0;

    if (!usingJSBSim){
    	# Outboard Spoilers
    	if (CurrentLeftSpoiler > LeftSpoilersTarget ) {
    		CurrentLeftSpoiler -= SpoilerSpeed * deltaT;
    		if (CurrentLeftSpoiler < LeftSpoilersTarget) {
    			CurrentLeftSpoiler = LeftSpoilersTarget;
    		}
    	} elsif (CurrentLeftSpoiler < LeftSpoilersTarget) {
    		CurrentLeftSpoiler += SpoilerSpeed * deltaT;
    		if (CurrentLeftSpoiler > LeftSpoilersTarget) {
    			CurrentLeftSpoiler = LeftSpoilersTarget;
    		}
    	}
    
    	if (CurrentRightSpoiler > RightSpoilersTarget ) {
    		CurrentRightSpoiler -= SpoilerSpeed * deltaT;
    		if (CurrentRightSpoiler < RightSpoilersTarget) {
    			CurrentRightSpoiler = RightSpoilersTarget;
    		}
    	} elsif (CurrentRightSpoiler < RightSpoilersTarget) {
    		CurrentRightSpoiler += SpoilerSpeed * deltaT;
    		if (CurrentRightSpoiler > RightSpoilersTarget) {
    			CurrentRightSpoiler = RightSpoilersTarget;
    		}
    	}
    
    	# Inboard Spoilers
    	if (CurrentInnerLeftSpoiler > InnerLeftSpoilersTarget ) {
    		CurrentInnerLeftSpoiler -= SpoilerSpeed * deltaT;
    		if (CurrentInnerLeftSpoiler < InnerLeftSpoilersTarget) {
    			CurrentInnerLeftSpoiler = InnerLeftSpoilersTarget;
    		}
    	} elsif (CurrentInnerLeftSpoiler < InnerLeftSpoilersTarget) {
    		CurrentInnerLeftSpoiler += SpoilerSpeed * deltaT;
    		if (CurrentInnerLeftSpoiler > InnerLeftSpoilersTarget) {
    			CurrentInnerLeftSpoiler = InnerLeftSpoilersTarget;
    		}
    	}
    
    	if (CurrentInnerRightSpoiler > InnerRightSpoilersTarget ) {
    		CurrentInnerRightSpoiler -= SpoilerSpeed * deltaT;
    		if (CurrentInnerRightSpoiler < InnerRightSpoilersTarget) {
    			CurrentInnerRightSpoiler = InnerRightSpoilersTarget;
    		}
    	} elsif (CurrentInnerRightSpoiler < InnerRightSpoilersTarget) {
    		CurrentInnerRightSpoiler += SpoilerSpeed * deltaT;
    		if (CurrentInnerRightSpoiler > InnerRightSpoilersTarget) {
    			CurrentInnerRightSpoiler = InnerRightSpoilersTarget;
    		}
    	}

# Engine nozzles
        if (Nozzle1 > Nozzle1Target) {
            Nozzle1 -= NozzleSpeed * deltaT;
            if (Nozzle1 < Nozzle1Target) {
                Nozzle1 = Nozzle1Target;
            }
        } elsif (Nozzle1 < Nozzle1Target) {
            Nozzle1 += NozzleSpeed * deltaT;
            if (Nozzle1 > Nozzle1Target) {
                Nozzle1 = Nozzle1Target;
            }
        }

        if (Nozzle2 > Nozzle2Target) {
            Nozzle2 -= NozzleSpeed * deltaT;
            if (Nozzle2 < Nozzle2Target) {
                Nozzle2 = Nozzle2Target;
            }
        } elsif (Nozzle2 < Nozzle2Target) {
            Nozzle2 += NozzleSpeed * deltaT;
            if (Nozzle2 > Nozzle2Target) {
                Nozzle2 = Nozzle2Target;
            }
        }

# Wing Sweep
    	if (currentSweep > WingSweep) {
    		currentSweep -= SweepSpeed * deltaT;
    		if (currentSweep < WingSweep) {
    			currentSweep = WingSweep;
    		}
    	} elsif (currentSweep < WingSweep) {
    		currentSweep += SweepSpeed * deltaT;
    		if (currentSweep > WingSweep) {
    			currentSweep = WingSweep;
    		}
	    }
    }

	setprop ("surface-positions/left-spoilers", CurrentLeftSpoiler);
	setprop ("surface-positions/right-spoilers", CurrentRightSpoiler);
	setprop ("surface-positions/inner-left-spoilers", CurrentInnerLeftSpoiler);
	setprop ("surface-positions/inner-right-spoilers", CurrentInnerRightSpoiler);
	setprop ("surface-positions/wing-pos-norm", currentSweep);
	setprop ("/fdm/jsbsim/fcs/wing-sweep", currentSweep);

	# Copy surfaces animations properties so they are transmited via multiplayer.
    if (usingJSBSim)
    {
        if (main_flap_generic != nil)
        {    
    	    main_flap_generic.setDoubleValue(getprop("fdm/jsbsim/fcs/flap-pos-norm"));
        } 

        if (aux_flap_generic != nil)
        {
            aux_flap_generic.setDoubleValue(aux_flap_output.getValue());
        }

        # the F14 FDM has a combined aileron deflection so split this for animation purposes.
        var current_aileron = aileron.getValue();
        if (abs(getprop("fdm/jsbsim/fcs/aileron-cmd-norm")) > deadZ_roll)
        {
#print("Outside dead zone ",current_aileron," roll ",getprop("autopilot/settings/target-roll-deg"));
            setprop("autopilot/settings/target-roll-deg", getprop("orientation/roll-deg"));
        }
        var elevator_deflection_due_to_aileron_deflection =  current_aileron / 2.0;
    	left_elev_generic.setDoubleValue(elev_output.getValue() + elevator_deflection_due_to_aileron_deflection);
    	right_elev_generic.setDoubleValue(elev_output.getValue() - elevator_deflection_due_to_aileron_deflection);

    }
    else
    {
    	setprop ("engines/engine[0]/nozzle-pos-norm", Nozzle1);
    	setprop ("engines/engine[1]/nozzle-pos-norm", Nozzle2);
    	aux_flap_generic.setDoubleValue(aux_flap_output.getValue());
    	slat_generic.setDoubleValue(slat_output.getValue());
    	left_elev_generic.setDoubleValue(left_elev_output.getValue());
    	right_elev_generic.setDoubleValue(right_elev_output.getValue());
    }
	slat_generic.setDoubleValue(slat_output.getValue());
    wing_sweep_generic.setDoubleValue(currentSweep);
	lighting_collision_generic.setIntValue(lighting_collision.getValue());
	lighting_position_generic.setIntValue(lighting_position.getValue() * position_intens);
	left_wing_torn_generic.setIntValue(left_wing_torn.getValue());
	right_wing_torn_generic.setIntValue(right_wing_torn.getValue());
	lighting_taxi_generic.setIntValue(lighting_taxi.getValue());

setprop("/sim/multiplay/generic/float[8]", getprop("/engines/engine[0]/augmentation-burner" ));
setprop("/sim/multiplay/generic/float[9]", getprop("/engines/engine[1]/augmentation-burner" ));
setprop("/sim/multiplay/generic/float[10]", getprop("/fdm/jsbsim/propulsion/engine[0]/alt/nozzle-pos-norm" ));
setprop("/sim/multiplay/generic/float[11]", getprop("/fdm/jsbsim/propulsion/engine[1]/alt/nozzle-pos-norm" ));
#setprop("/sim/multiplay/generic/int[8]", getprop("/engines/engine[0]/afterburner" ));
#setprop("/sim/multiplay/generic/int[9]", getprop("/engines/engine[1]/afterburner" ));

}



#----------------------------------------------------------------------------
# FCS update
#----------------------------------------------------------------------------
var wow = 1;
setprop("/fdm/jsbsim/fcs/roll-trim-actuator",0) ;
setprop("/controls/flight/SAS-roll",0);
var registerFCS = func {settimer (updateFCS, 0);}

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

    if(usingJSBSim)
    {
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
    }
    else
    {
        currentG = getprop ("accelerations/pilot-g");
		setprop("engines/engine[0]/augmentation", getprop("engines/engine[0]/afterburner"));
		setprop("engines/engine[1]/augmentation", getprop("engines/engine[1]/afterburner"));
        setprop("engines/engine[0]/fuel-flow_pph",getprop("engines/engine[0]/fuel-flow-gph")*1.46551724137931);
        setprop("engines/engine[1]/fuel-flow_pph",getprop("engines/engine[1]/fuel-flow-gph")*1.46551724137931);

    }

	#update functions
	f14.computeSweep ();
	f14.computeFlaps ();
	f14.computeSpoilers ();
	f14.computeNozzles ();
    if (!usingJSBSim){
	    f14.computeSAS ();
    }
	f14.computeAdverse ();
	f14.computeNWS ();
	f14.computeAICS ();
	f14.computeAPC ();
    f14.engineControls();
	f14.timedMotions ();
    f14.electricsFrame();
	f14.registerFCS (); # loop, once per frame.
}


var startProcess = func {
	settimer (updateFCS, 1.0);
	position_flash_init();
slat_output.setDoubleValue(0);

}

setlistener("/sim/signals/fdm-initialized", startProcess);

#----------------------------------------------------------------------------
# View change: Ctrl-V switchback to view #0 but switch to Rio view when already
# in view #0.
#----------------------------------------------------------------------------

var CurrentView_Num = props.globals.getNode("sim/current-view/view-number");
var rio_view_num = view.indexof("RIO View");

var toggle_cockpit_views = func() {
	cur_v = CurrentView_Num.getValue();
	if (cur_v != 0 ) {
		CurrentView_Num.setValue(0);
	} else {
		CurrentView_Num.setValue(rio_view_num);
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

    setprop("sim/model/f-14b/controls/hud/on-off",1);
    setprop("sim/model/f-14b/controls/VDI/on-off",1);
    setprop("sim/model/f-14b/controls/HSD/on-off",1);

    setprop("sim/model/f-14b/controls/electrics/emerg-flt-hyd-switch",0);
    setprop("sim/model/f-14b/controls/electrics/emerg-gen-guard-lever",0);
	setprop("sim/model/f-14b/controls/electrics/emerg-gen-switch",1);
    setprop("sim/model/f-14b/controls/electrics/l-gen-switch",1);
    setprop("sim/model/f-14b/controls/electrics/master-test-switch",0);
	setprop("sim/model/f-14b/controls/electrics/r-gen-switch",1);

    setprop("controls/engines/engine[0]/cutoff",0);
    setprop("controls/engines/engine[1]/cutoff",0);
    setprop("engines/engine[0]/out-of-fuel",0);
    setprop("engines/engine[1]/out-of-fuel",0);
    setprop("engines/engine[1]/run",1);
    setprop("engines/engine[1]/run",1);

setprop("/engines/engine[1]/cutoff",0);
setprop("/engines/engine[0]/cutoff",0);

setprop("/fdm/jsbsim/propulsion/starter_cmd",1);
setprop("/fdm/jsbsim/propulsion/cutoff_cmd",1);
setprop("/fdm/jsbsim/propulsion/set-running",1);
setprop("/fdm/jsbsim/propulsion/set-running",0);

}


# set the splash vector for the new canopy rain.

# for tuning the vector; these will be baked in once finished
setprop("/sim/model/f-14b/sfx1",-0.1);
setprop("/sim/model/f-14b/sfx2",4);
setprop("/sim/model/f-14b/sf-x-max",400);
setprop("/sim/model/f-14b/sfy1",0);
setprop("/sim/model/f-14b/sfy2",0.1);
setprop("/sim/model/f-14b/sfz1",1);
setprop("/sim/model/f-14b/sfz2",-0.1);

#var vl_x = 0;
#var vl_y = 0;
#var vl_z = 0;
#var vsplash_precision = 0.001;
var splash_vec_loop = func
{
    var v_x = 0;
    var v_y = 0;
    var v_z = 0;
    var v_x_max = getprop("/sim/model/f-14b/sf-x-max");
    if(!usingJSBSim)
    {
        v_x = getprop("/velocities/uBody-fps");
        v_y = getprop("/velocities/vBody-fps");
        v_z = getprop("/velocities/wBody-fps");
    }
    else
    {
        v_x = getprop("/fdm/jsbsim/velocities/u-aero-fps");
        v_y = getprop("/fdm/jsbsim/velocities/v-aero-fps");
        v_z = getprop("/fdm/jsbsim/velocities/w-aero-fps");
    }
 
    if (v_x > v_x_max) 
        v_x = v_x_max;
 
    if (v_x > 1)
        v_x = math.sqrt(v_x/v_x_max);

    var splash_x = getprop("/sim/model/f-14b/sfx1") - getprop("/sim/model/f-14b/sfx2") * v_x;
    var splash_y = getprop("/sim/model/f-14b/sfy1") - getprop("/sim/model/f-14b/sfy2") * v_y;
    var splash_z = getprop("/sim/model/f-14b/sfz1") - getprop("/sim/model/f-14b/sfz2") * v_z;

    setprop("/environment/aircraft-effects/splash-vector-x", splash_x);
    setprop("/environment/aircraft-effects/splash-vector-y", splash_y);
    setprop("/environment/aircraft-effects/splash-vector-z", splash_z);

    settimer( func {splash_vec_loop() },0.5);
}

splash_vec_loop();

var rate4modules = func {
	settimer (rate4modules, 0.20);
}

var rate2modules = func {
	settimer (rate2modules, 0.04);
    if(usingJSBSim)
        setprop("environment/aircraft-effects/frost-level", getprop("/fdm/jsbsim/systems/ecs/windscreen-frost-amount"));
}
#
# launch the timers; the time here isn't important as it will be rescheduled within the rate module exec
settimer (rate4modules, 1); 
settimer (rate2modules, 1);
