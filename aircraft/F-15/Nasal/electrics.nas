#
# F-15 Electrical System: Misc (EMMISC)
# ---------------------------
# Manages caution lights, and electrics controls
# ---------------------------
# Richard Harrison (rjh@zaretto.com) 2014-11-23; based on my F-14 version


# Constants

var oil_pressure_l = props.globals.getNode("engines/engine[0]/oil-pressure-psi", 1);
var oil_pressure_r = props.globals.getNode("engines/engine[1]/oil-pressure-psi", 1);
var ca_oil_press_light  = props.globals.getNode("sim/model/f15/lights/ca-oil-press", 1);

var bingo      = props.globals.getNode("sim/model/f15/controls/fuel/bingo", 1);
var ca_bingo_light  = props.globals.getNode("sim/model/f15/lights/ca-bingo-fuel", 1);

var ca_canopy_light = props.globals.getNode("sim/model/f15/lights/ca-canopy-lock", 1);
var canopy = props.globals.getNode("canopy/position-norm", 1);
canopy.setValue(0);

var ca_ramp_light = props.globals.getNode("sim/model/f15/lights/ca-l-inlet", 1);

var masterCaution_light = props.globals.getNode("sim/model/f15/instrumentation/warnings/master-caution", 1);
var masterCaution_light_set = props.globals.getNode("sim/model/f15/controls/master-caution-set", 1);
masterCaution_light_set.setBoolValue(0);

var jettisonLeft = props.globals.getNode("controls/armament/station[2]/jettison-all", 1);
var jettisonRight = props.globals.getNode("controls/armament/station[7]/jettison-all", 1);

var ca_l_gen_light  = props.globals.getNode("sim/model/f15/lights/ca-l-gen-out", 1);
var ca_r_gen_light  = props.globals.getNode("sim/model/f15/lights/ca-r-gen-out", 1);

var ca_l_inlet_light  = props.globals.getNode("sim/model/f15/lights/ca-l-inlet", 1);
var ca_r_inlet_light  = props.globals.getNode("sim/model/f15/lights/ca-r-inlet", 1);

var ca_l_fuel_press_light  = props.globals.getNode("sim/model/f15/lights/ca-l-bst-pmp", 1);
var ca_r_fuel_press_light  = props.globals.getNode("sim/model/f15/lights/ca-r-bst-pmp", 1);

var ca_fuel_low  = props.globals.getNode("sim/model/f15/lights/ca-fuel-low", 1);

var ca_hyd_press_light  = props.globals.getNode("sim/model/f15/lights/ca-hydraulic", 1);

var l_eng_starter = props.globals.getNode("controls/engines/engine[0]/starter",1);
var r_eng_starter = props.globals.getNode("controls/engines/engine[1]/starter",1);

var l_eng_running = props.globals.getNode("engines/engine[0]/running",1);
var r_eng_running = props.globals.getNode("engines/engine[1]/running",1);
var ca_start_valve  = props.globals.getNode("sim/model/f15/lights/ca-start-valve", 1);
setprop("sim/model/f15/controls/hud/on-off",1);
setprop("sim/model/f15/controls/electrics/emerg-gen-switch",1);
setprop("sim/model/f15/controls/electrics/l-gen-switch",1);
setprop("sim/model/f15/controls/electrics/r-gen-switch",1);

var dlg_ground_services  = gui.Dialog.new("dialog[2]","Aircraft/F-15/Dialogs/ground-services.xml");
var dlg_lighting  = gui.Dialog.new("dialog[3]","Aircraft/F-15/Dialogs/lighting.xml");

    ## initialise the electrics / hyds
    setprop("/fdm/jsbsim/systems/electrics/ac-essential-bus1",75);
    setprop("/fdm/jsbsim/systems/electrics/ac-essential-bus2",75); 
    setprop("/fdm/jsbsim/systems/electrics/ac-left-main-bus",75);
    setprop("/fdm/jsbsim/systems/electrics/ac-right-main-bus",75);
    setprop("/fdm/jsbsim/systems/electrics/dc-essential-bus1",28);
    setprop("/fdm/jsbsim/systems/electrics/dc-essential-bus2",28);
    setprop("/fdm/jsbsim/systems/electrics/dc-main-bus",28);
    setprop("/fdm/jsbsim/systems/electrics/egenerator-kva",0);
    setprop("/fdm/jsbsim/systems/electrics/emerg-generator-status",0);
    setprop("/fdm/jsbsim/systems/electrics/lgenerator-kva",75);
    setprop("/fdm/jsbsim/systems/electrics/rgenerator-kva",75);
    setprop("/fdm/jsbsim/systems/electrics/transrect-online",2);
    setprop("fdm/jsbsim/systems/hydraulics/combined-system-psi",2398);
    setprop("fdm/jsbsim/systems/hydraulics/flight-system-psi",2396);
    setprop("engines/engine[0]/oil-pressure-psi", 28);
    setprop("engines/engine[1]/oil-pressure-psi", 28);

var runEMMISC = func {

# disable if we are in replay mode
#	if ( getprop("sim/replay/time") > 0 ) { return }

    set_console_lighting();
        
    setprop("systems/electrical/outputs/DG", getprop("/fdm/jsbsim/systems/electrics/ac-left-main-bus"));

    var masterCaution =  masterCaution_light_set.getValue();
    var master_caution_active  = 0;
    var engine_crank_switch_pos = getprop("sim/model/f15/controls/engine/engine-crank");

    if ( ((engine_crank_switch_pos == 1 or l_eng_starter.getBoolValue()) and l_eng_running.getBoolValue()) 
        or ((engine_crank_switch_pos == 2 or r_eng_starter.getBoolValue()) and r_eng_running.getBoolValue()))
    {
        if (!ca_start_valve.getBoolValue())
        {
		    ca_start_valve.setBoolValue(1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }        
    else
    {
        if (ca_start_valve.getBoolValue())
	    {
		    ca_start_valve.setBoolValue(0);
        }
    }

#
# RAMPS light on when either of the following 2 conditions met:
# 
# 1. Gear Handle Down or Inlet Ramps Switch in stow 
#    AND 
#    Ramp#2 not in stow locks OR Ramp#3 not in stow locks
#
# 2. Hydraulic shutoff value deenergized (Mach <0.35 and/or AICS failuer)
#    AND
#    Ramp#1 not in stow locks OR Ramp#3 not in stow locks
#
## ca_ramp_light on 

# INLET light:
# Indicates AICS programmer/system failure.
# AICS Failure:
# 1. < M 0.5 ramps should be restrained by actuator stow locks
# 2. > M 0.5 ramp movement is restrained by trapped hydraulic pressure and mechanical locks, depending
#   on mach when inlet light illuminates
# 3.> M 0.9 Ramp movement is minimized by actuator spool valves and the aerodynamic load profile
#  in this Mach range and a RAMP light should illuminate

    if(getprop("fdm/jsbsim/systems/hydraulics/combined-system-psi") < 2100 or 
       getprop("fdm/jsbsim/systems/hydraulics/flight-system-psi") < 2100)
    {
		if (!ca_hyd_press_light.getBoolValue())
		{
		    ca_hyd_press_light.setBoolValue(1);
            masterCaution = 1;
		}
        master_caution_active = 1;
    }
    else
    {
        ca_hyd_press_light.setBoolValue(0);
    }

	if (oil_pressure_l.getValue() < 23 or oil_pressure_r.getValue() < 23 )
    {
		if (!ca_oil_press_light.getBoolValue())
		{
		    ca_oil_press_light.setBoolValue(1);
            masterCaution = 1;
		}
        master_caution_active = 1;
	}
	else
	{
		if (ca_oil_press_light.getBoolValue())
		{
		    ca_oil_press_light.setBoolValue(0);
		}
    }

    if(oil_pressure_l.getValue() < 23)
    {
        if (!ca_l_fuel_press_light.getBoolValue())
        {
            ca_l_fuel_press_light.setBoolValue(1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        if(ca_l_fuel_press_light.getBoolValue())
        {
            ca_l_fuel_press_light.setBoolValue(0);
        }
    }
    if(oil_pressure_r.getValue() < 23)
    {
        if (!ca_r_fuel_press_light.getBoolValue())
        {
            ca_r_fuel_press_light.setBoolValue(1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        if(ca_r_fuel_press_light.getBoolValue())
        {
            ca_r_fuel_press_light.setBoolValue(0);
        }
    }

    if(getprop("/fdm/jsbsim/systems/electrics/lgenerator-kva") < 50)
    {
        if (!ca_l_gen_light.getBoolValue())
        {
            ca_l_gen_light.setBoolValue(1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        if (ca_l_gen_light.getBoolValue())
        {
            ca_l_gen_light.setBoolValue(0);
        }
    }

#
# Inlet ramps.
    if(!getprop("fdm/jsbsim/systems/hydraulics/combined-system-pressure"))
    {
        if (!ca_l_inlet_light.getBoolValue())
        {
            ca_l_inlet_light.setBoolValue(1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        if (ca_l_inlet_light.getBoolValue())
        {
            ca_l_inlet_light.setBoolValue(0);
        }
    }
    if(!getprop("fdm/jsbsim/systems/hydraulics/flight-system-pressure"))
    {
        if (!ca_r_inlet_light.getBoolValue())
        {
            ca_r_inlet_light.setBoolValue(1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        if (ca_r_inlet_light.getBoolValue())
        {
            ca_r_inlet_light.setBoolValue(0);
        }
    }

    if(getprop("/fdm/jsbsim/systems/electrics/rgenerator-kva") < 50)
    {
        if (!ca_r_gen_light.getBoolValue())
        {
            ca_r_gen_light.setBoolValue(1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        if (ca_r_gen_light.getBoolValue())
        {
            ca_r_gen_light.setBoolValue(0);
        }
    }

	if (total_lbs < bingo.getValue())
    {
		if (!ca_bingo_light.getBoolValue())
		{
		    ca_bingo_light.setBoolValue(1);
            masterCaution = 1;
		}
        master_caution_active = 1;
	}
	else
	{
		if (ca_bingo_light.getBoolValue())
		{
		    ca_bingo_light.setBoolValue(0);
		}
	}

	if (total_lbs < 1000)
    {
		if (!ca_fuel_low.getBoolValue())
		{
    	    ca_fuel_low.setBoolValue(1);
            masterCaution = 1;
        }
        master_caution_active = 1;
	}
	else
	{
		if (ca_fuel_low.getBoolValue())
		{
		    ca_fuel_low.setBoolValue(0);
		}
	}

	if (getprop("/gear/tailhook/position-norm") > 0.2)
    {
        if (!getprop("sim/model/f15/lights/ca-hook"))
        {
            setprop("sim/model/f15/lights/ca-hook",1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        if (getprop("sim/model/f15/lights/ca-hook"))
        {
            setprop("sim/model/f15/lights/ca-hook",0);
        }
    }


    if  (getprop("fdm/jsbsim/systems/ecs/oxygen-quantity-liters") < 2)
    {
        if (!getprop("sim/model/f15/lights/ca-oxygen"))
        {
            setprop("sim/model/f15/lights/ca-oxygen",1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        if (getprop("sim/model/f15/lights/ca-oxygen"))
        {
            setprop("sim/model/f15/lights/ca-oxygen",0);
        }
    }
    if  (getprop("fdm/jsbsim/systems/hydraulics/util-system-accumulator-psi") < 500)
    {
        if (!getprop("sim/model/f15/lights/ca-jfs-low"))
        {
            setprop("sim/model/f15/lights/ca-jfs-low",1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        if (getprop("sim/model/f15/lights/ca-jfs-low"))
        {
            setprop("sim/model/f15/lights/ca-jfs-low",0);
        }
    }

	if (getprop("sim/model/f15/controls/afcs/autopilot-disengage"))
    {
        if (!getprop("sim/model/f15/lights/ca-auto-plt"))
        {
            setprop("sim/model/f15/lights/ca-auto-plt",1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        if (getprop("sim/model/f15/lights/ca-auto-plt"))
        {
            setprop("sim/model/f15/lights/ca-auto-plt",0);
        }
    }


	if (getprop("/fdm/jsbsim/systems/electrics/transrect-online") < 2)
    {
        if (!getprop("sim/model/f15/lights/ca-trans-rect"))
        {
            setprop("sim/model/f15/lights/ca-trans-rect",1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        if (getprop("sim/model/f15/lights/ca-trans-rect"))
        {
            setprop("sim/model/f15/lights/ca-trans-rect",0);
        }
    }

	if (getprop("gear/launchbar/position-norm") and (getprop("controls/engines/engine[0]/throttle") < 0.95 or getprop("controls/engines/engine[1]/throttle") < 0.95 ))
    {
        if (!getprop("sim/model/f15/lights/ca-launch-bar"))
        {
            setprop("sim/model/f15/lights/ca-launch-bar",1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        if (getprop("sim/model/f15/lights/ca-launch-bar"))
        {
            setprop("sim/model/f15/lights/ca-launch-bar",0);
        }
    }
    if  (!getprop("fdm/jsbsim/fcs/yaw-damper-enable"))
    {
        if (!getprop("sim/model/f15/lights/ca-cas-yaw"))
        {
            setprop("sim/model/f15/lights/ca-cas-yaw",1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        if (getprop("sim/model/f15/lights/ca-cas-yaw"))
        {
            setprop("sim/model/f15/lights/ca-cas-yaw",0);
        }
    }

    # windshield hot if over 150deg F for any reason.
    if (getprop("fdm/jsbsim/systems/ecs/windscreen-temperature-k") > 338)
    {
        if (!getprop("sim/model/f15/lights/ca-wndshld-hot"))
        {
            setprop("sim/model/f15/lights/ca-wndshld-hot",1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        if (getprop("sim/model/f15/lights/ca-wndshld-hot"))
        {
            setprop("sim/model/f15/lights/ca-wndshld-hot",0);
        }
    }

    if  (getprop("/fdm/jsbsim/systems/cadc/roll-ratio-emergency"))
    {
        if (!getprop("sim/model/f15/lights/ca-roll-ratio"))
        {
            setprop("sim/model/f15/lights/ca-roll-ratio",1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        if (getprop("sim/model/f15/lights/ca-roll-ratio"))
        {
            setprop("sim/model/f15/lights/ca-roll-ratio",0);
        }
    }
    if  (getprop("/fdm/jsbsim/systems/cadc/pitch-ratio-emergency"))
    {
        if (!getprop("sim/model/f15/lights/ca-pitch-ratio"))
        {
            setprop("sim/model/f15/lights/ca-pitch-ratio",1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        if (getprop("sim/model/f15/lights/ca-pitch-ratio"))
        {
            setprop("sim/model/f15/lights/ca-pitch-ratio",0);
        }
    }

    if  (!getprop("fdm/jsbsim/fcs/roll-damper-enable"))
    {
        if (!getprop("sim/model/f15/lights/ca-cas-roll"))
        {
            setprop("sim/model/f15/lights/ca-cas-roll",1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        if (getprop("sim/model/f15/lights/ca-cas-roll"))
        {
            setprop("sim/model/f15/lights/ca-cas-roll",0);
        }
    }

    if  (!getprop("fdm/jsbsim/fcs/pitch-damper-enable"))
    {
        if (!getprop("sim/model/f15/lights/ca-cas-pitch"))
        {
            setprop("sim/model/f15/lights/ca-cas-pitch",1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        if (getprop("sim/model/f15/lights/ca-cas-pitch"))
        {
            setprop("sim/model/f15/lights/ca-cas-pitch",0);
        }
    }
#anti skid will indicate when the parking brake is on.
    setprop("sim/model/f15/lights/ca-anti-skid", getprop("/controls/gear/brake-parking"));

    if (canopy.getValue() > 0)
    {
		if (!ca_canopy_light.getBoolValue()){
            ca_canopy_light.setBoolValue(1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        ca_canopy_light.setBoolValue(0);
    }

    if (jettisonLeft.getValue() or jettisonRight.getValue()){
        masterCaution = 1;
        master_caution_active = 1;
        jettisonRight.setValue(0);
        jettisonLeft.setValue(0);
    }
    if (!master_caution_active){
        masterCaution_light_set.setBoolValue(0);
        masterCaution_light.setBoolValue(0);
    }
    else
    {
        if (masterCaution)
        {
            masterCaution_light.setBoolValue(1);
        }
    }
}

var master_caution_pressed = func {
    jettisonLeft.setValue(0);
    jettisonRight.setValue(0);
    masterCaution_light.setBoolValue(0);
    masterCaution_light_set.setBoolValue(0);

    setprop("sim/model/f15/controls/afcs/autopilot-disengage",0);
}

var electricsFrame = func {
    runEMMISC();
}

#
#
# hyd transfer switch - this will activate the bidi pump. 
setlistener("sim/model/f15/controls/hyds/hyd-transfer-pump-switch", func {
    var v = getprop("sim/model/f15/controls/hyds/hyd-transfer-pump-switch");
    if(v != nil)
    {
        if (v)
        {
            setprop("fdm/jsbsim/systems/hydraulics/hyd-transfer-pump-switch", 0);
        }
        else
        {
            setprop("fdm/jsbsim/systems/hydraulics/hyd-transfer-pump-switch", 1);
        }
    }
}, 1, 0);

var set_console_lighting = func
{
    var v = getprop("controls/lighting/l-console");
    setprop("controls/lighting/l-console-norm", v/10);
    if (getprop("/fdm/jsbsim/systems/electrics/dc-main-bus-powered") and v > 0)
        setprop("controls/lighting/l-console-eff-norm", v/10);
    else
        setprop("controls/lighting/l-console-eff-norm", 0);

    v = getprop("controls/lighting/r-console");
    setprop("controls/lighting/r-console-norm", v/10);
    if (getprop("/fdm/jsbsim/systems/electrics/dc-main-bus-powered") and v > 0)
        setprop("controls/lighting/r-console-eff-norm", v/10);
    else
        setprop("controls/lighting/r-console-eff-norm", 0);

}


setlistener("controls/lighting/l-console", func(prop)
            {
                set_console_lighting();
            }, 1, 0);

setlistener("controls/lighting/r-console", func(prop)
            {
                set_console_lighting();
            }, 1, 0);

#
#
# master gen panel 
setlistener("sim/model/f15/controls/electrics/l-gen-switch", func
{
    var v = getprop("sim/model/f15/controls/electrics/l-gen-switch");
    if(v != nil)
    {
        if (v)
        {
            setprop("fdm/jsbsim/systems/electrics/lgenerator-status", 1);
        }
        else
        {
            setprop("fdm/jsbsim/systems/electrics/lgenerator-status", 0);
        }
    }
}, 1, 0);

setlistener("sim/model/f15/controls/electrics/r-gen-switch", func
{
    var v = getprop("sim/model/f15/controls/electrics/r-gen-switch");
    if(v != nil)
    {
        if (v)
        {
            setprop("fdm/jsbsim/systems/electrics/rgenerator-status", 1);
        }
        else
        {
            setprop("fdm/jsbsim/systems/electrics/rgenerator-status", 0);
        }
    }
}, 1, 0);

setlistener("sim/model/f15/controls/electrics/emerg-gen-switch", func {
    var v = getprop("sim/model/f15/controls/electrics/emerg-gen-switch");
    if(v != nil)
    {
        if (v)
        {
            setprop("fdm/jsbsim/systems/electrics/emerg-generator-status", 1);
        }
        else
        {
            setprop("fdm/jsbsim/systems/electrics/emerg-generator-status", 0);
        }
    }
}, 1, 0);

setlistener("sim/model/f15/controls/electrics/emerg-flt-hyd-switch", func {
    var guard = getprop("sim/model/f15/controls/electrics/emerg-flt-hyd-guard-lever");
    var v = getprop("sim/model/f15/controls/electrics/emerg-flt-hyd-switch");

    if (!guard)
    {
        setprop("sim/model/f15/controls/electrics/emerg-flt-hyd-switch",0);
    }
    if(v != nil)
    {
        setprop("fdm/jsbsim/systems/hydraulics/emerg-flyt-hyd-switch", v);
    }
}, 1, 0);

#
# master test panel selection switch 
var master_test_select_switch = func(n) {
var curval = getprop("sim/model/f15/controls/electrics/master-test-switch");
if (curval == nil)
curval = 0;

curval = curval + n;
if (curval < 0) curval = 10;
if (curval > 10) curval = 0;

    setprop("sim/model/f15/controls/electrics/master-test-switch", curval);
if (curval == 0)
{
setprop("sim/model/f15/lights/master-test-nogo",0);
setprop("sim/model/f15/lights/master-test-go",0);
setprop("sim/model/f15/lights/master-test-lights",0);
}
else if (curval == 10)
{
setprop("sim/model/f15/lights/master-test-lights",1);
setprop("sim/model/f15/lights/master-test-nogo",0);
setprop("sim/model/f15/lights/master-test-go",1);
}
else
{
setprop("sim/model/f15/lights/master-test-lights",0);
setprop("sim/model/f15/lights/master-test-nogo",1);
setprop("sim/model/f15/lights/master-test-go",0);
}
}

#
# Use ALS secondary lighting 
# The scheme we adopt is to use both lights in one place to make the landing light brighter and spread
# them for the taxi light. These lights move with the view (as I suspect they are setup for being on the mlg
# not on the nose gear - but it is a lot better than just darkness).
# also remember that these only illuminate the runway as proper lighting calculating is not done; this is a shader
# level implementation that is fast rather than accurate.
# ref: http://wiki.flightgear.org/ALS_technical_notes#ALS_secondary_lights
var setup_als_lights = func
{
    var light_setting=getprop("sim/multiplay/generic/int[6]");

#
# gear needs to be extended (not just commanded)
# view needs to be internal (otherwise geometry of the shader is wrong).

    if (!getprop("sim/current-view/internal") or getprop("gear/gear[0]/position-norm") == nil or getprop("gear/gear[0]/position-norm") < 0.6  or !light_setting)
    {
        setprop("sim/rendering/als-secondary-lights/use-landing-light", 0);
        setprop("sim/rendering/als-secondary-lights/use-alt-landing-light", 0);
        return;
    }

    if (light_setting & 2)
    {
# put both lights at the same place and brighter for the landing light
        setprop("sim/rendering/als-secondary-lights/landing-light1-offset-deg", 0);
        setprop("sim/rendering/als-secondary-lights/landing-light2-offset-deg", 0);
        setprop("sim/rendering/als-secondary-lights/use-landing-light", 1);
        setprop("sim/rendering/als-secondary-lights/use-alt-landing-light", 1);
        return;
    }
    
    if (light_setting & 1)
    {
# spread the  lights for the taxi light
        setprop("sim/rendering/als-secondary-lights/landing-light1-offset-deg", 4);
        setprop("sim/rendering/als-secondary-lights/landing-light2-offset-deg", -4);
        setprop("sim/rendering/als-secondary-lights/use-landing-light", 1);
        setprop("sim/rendering/als-secondary-lights/use-landing-light", 1);
        setprop("sim/rendering/als-secondary-lights/use-alt-landing-light", 1);
        return;
    }
}

setlistener("sim/current-view/internal", func {
    aircraft.setup_als_lights();
}, 1, 0);

setlistener("sim/multiplay/generic/int[6]", func
{
    aircraft.setup_als_lights();

}, 1, 0);

setlistener("gear/gear[0]/position-norm", func
{
    aircraft.setup_als_lights();
}, 1, 0);

setlistener("sim/model/f15/controls/windshield-heat", func {
setprop("fdm/jsbsim/systems/ecs/windshield-heat",getprop("sim/model/f15/controls/windshield-heat"));
}, 1, 0);

