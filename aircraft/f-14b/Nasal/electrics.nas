#----------------------------------------------------------------------------
# Electrical System: Misc
# EMMISC
#----------------------------------------------------------------------------
var masterCaution_reset = props.globals.getNode("sim/model/f-14b/lights/master-caution-reset", 1);


var jettisonLeft = props.globals.getNode("controls/armament/station[2]/jettison-all", 1);
var jettisonRight = props.globals.getNode("controls/armament/station[7]/jettison-all", 1);


# Constants

setprop("sim/model/f-14b/controls/hud/on-off",1);
setprop("sim/model/f-14b/controls/electrics/emerg-gen-switch",1);
setprop("sim/model/f-14b/controls/electrics/l-gen-switch",1);
setprop("sim/model/f-14b/controls/electrics/r-gen-switch",1);

if(!usingJSBSim)
{
    #
    #
    # Set the electrics for yasim (basic electrical model)
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
}

var set_console_lighting = func
{
    var v = getprop("controls/lighting/panel-norm");

    if (getprop("/fdm/jsbsim/systems/electrics/dc-main-bus-powered") and v > 0)
        setprop("controls/lighting/panel-eff-norm", v);
    else
        setprop("controls/lighting/panel-eff-norm", 0);
}

var runEMMISC = func {

# disable if we are in replay mode
#	if ( getprop("sim/replay/time") > 0 ) { return }

    set_console_lighting();

    if(getprop("/fdm/jsbsim/systems/electrics/ac-left-main-bus") < 5)
    {
        setprop("sim/hud/visibility[1]",0);
    }
    else
    {
        setprop("sim/hud/visibility[1]",getprop("sim/model/f-14b/controls/hud/on-off"));
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
}

var master_caution_pressed = func {
    masterCaution_reset.setBoolValue(1);
    jettisonLeft.setBoolValue(0);
    jettisonRight.setBoolValue(0);
}


var electricsFrame = func {
    runEMMISC();
}

#
#
# hyd transfer switch - this will activate the bidi pump. 
setlistener("sim/model/f-14b/controls/hyds/hyd-transfer-pump-switch", func {
    var v = getprop("sim/model/f-14b/controls/hyds/hyd-transfer-pump-switch");
    if(usingJSBSim and v != nil)
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

#
#
# master gen panel 
setlistener("sim/model/f-14b/controls/electrics/l-gen-switch", func {
    var v = getprop("sim/model/f-14b/controls/electrics/l-gen-switch");
    if(usingJSBSim and v != nil)
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

setlistener("sim/model/f-14b/controls/electrics/r-gen-switch", func {
    var v = getprop("sim/model/f-14b/controls/electrics/r-gen-switch");
    if(usingJSBSim and v != nil)
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

setlistener("sim/model/f-14b/controls/electrics/emerg-gen-switch", func {
    var guard = getprop("sim/model/f-14b/controls/electrics/emerg-gen-guard-lever");
    if (!guard)
    {
        setprop("sim/model/f-14b/controls/electrics/emerg-gen-switch",1);
    }
    var v = getprop("sim/model/f-14b/controls/electrics/emerg-gen-switch");
    if(usingJSBSim and v != nil)
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

setlistener("sim/model/f-14b/controls/electrics/emerg-flt-hyd-switch", func {
    var guard = getprop("sim/model/f-14b/controls/electrics/emerg-flt-hyd-guard-lever");
    var v = getprop("sim/model/f-14b/controls/electrics/emerg-flt-hyd-switch");

    if (!guard)
    {
        setprop("sim/model/f-14b/controls/electrics/emerg-flt-hyd-switch",0);
    }
    if(usingJSBSim and v != nil)
    {
        setprop("fdm/jsbsim/systems/hydraulics/emerg-flyt-hyd-switch", v);
    }
}, 1, 0);

#
# master test panel selection switch 
var master_test_select_switch = func(n) {
var curval = getprop("sim/model/f-14b/controls/electrics/master-test-switch");
if (curval == nil)
curval = 0;

curval = curval + n;
if (curval < 0) curval = 10;
if (curval > 10) curval = 0;

    setprop("sim/model/f-14b/controls/electrics/master-test-switch", curval);
if (curval == 0)
{
setprop("sim/model/f-14b/lights/master-test-nogo",0);
setprop("sim/model/f-14b/lights/master-test-go",0);
setprop("sim/model/f-14b/lights/master-test-lights",0);
}
else if (curval == 10)
{
setprop("sim/model/f-14b/lights/master-test-lights",1);
setprop("sim/model/f-14b/lights/master-test-nogo",0);
setprop("sim/model/f-14b/lights/master-test-go",1);
}
else
{
setprop("sim/model/f-14b/lights/master-test-lights",0);
setprop("sim/model/f-14b/lights/master-test-nogo",1);
setprop("sim/model/f-14b/lights/master-test-go",0);
}
}
setlistener("sim/model/f-14b/controls/windshield-heat", func {
var v = getprop("sim/model/f-14b/controls/windshield-heat");
if (v != nil)
    setprop("fdm/jsbsim/systems/ecs/windshield-heat",v);
}, 1, 0);
