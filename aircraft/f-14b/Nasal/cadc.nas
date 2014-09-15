
#----------------------------------------------------------------------------
# APC - Approach Power Compensator
#----------------------------------------------------------------------------
# target:        - sim/model/f-14b/instrumentation/aoa-indexer/target-deg (11,3 deg AoA)
# engaged by:    - Throttle Mode Lever
#                - keystroke "a" (toggle)
# disengaged by: - Throttle Mode Lever
#                - keystroke "a" (toggle)
#                - WoW
#                - throttle levers at ~ idle or MIL
#                - autopilot emer disengage padle (TODO)
# Original F-14B : (YASim) APC is for display purposes only 
#                  (JSBSim) Richard Harrison  (rjh@zaretto.com) APC system in the FDM

var APCengaged = props.globals.getNode("sim/model/f-14b/systems/apc/engaged");
var engaded = 0;
var gear_down = props.globals.getNode("controls/gear/gear-down");
var disengaged_light = props.globals.getNode("sim/model/f-14b/systems/apc/self-disengaged-light");
var throttle_0 = props.globals.getNode("controls/engines/engine[0]/throttle");
var throttle_1 = props.globals.getNode("controls/engines/engine[1]/throttle");

var computeAPC = func {
	var t0 = throttle_0.getValue();
	var t1 = throttle_1.getValue();

#
#
# - nothing to do with APC - just here for convenience
	if (t0 >= 0.98 or t1 >= 0.98)
    {
        if (getprop("controls/flight/speedbrake", 0))
        {
            print("Retract speedbrake when throttles advanced to MIL");
            setprop("controls/flight/speedbrake", 0);
        }
    }
    
#
#
# disengage if not correctly setup.
	if (APCengaged.getBoolValue()) {
		# Yasim model doesn't support anything except the logic for the lights.
        # JSBSim has APC as FDM system
		if ( wow 
# gear check disabled for testing
#           or !gear_down.getBoolValue() 
            or !getprop("engines/engine[0]/running")
            or !getprop("engines/engine[1]/running")
#    		or t0 > 0.76 or t0 < 0.08
#   		or t1 > 0.76 or t1 < 0.08 
           ) 
        {
			APC_off()
		}
	}
}

var toggleAPC = func {
	engaged = APCengaged.getBoolValue();
	if ( ! engaged ){
		APC_on();
	} else {
		APC_off();
	}
}

var APC_on = func {
	if ( ! wow 
        # and gear_down.getBoolValue()
        )
    {
		APCengaged.setBoolValue(1);
		disengaged_light.setBoolValue(0);
		setprop ("autopilot/locks/aoa", "APC");
		setprop ("autopilot/locks/speed", "APC");
        if(usingJSBSim){
    		setprop ("fdm/jsbsim/systems/apc/active",1);
    		setprop ("fdm/jsbsim/systems/apc/target-vc-kts",getprop("fdm/jsbsim/velocities/vc-kts"));
    		setprop ("fdm/jsbsim/systems/apc/divergence-pid/initial-integrator-value",getprop("fdm/jsbsim/fcs/throttle-cmd-norm[1]") /  getprop("fdm/jsbsim/systems/apc/throttle-gain"));

        }
        setprop("sim/model/f-14b/controls/switch-throttle-mode", 1);

#print ("APC on", getprop ("fdm/jsbsim/systems/apc/target-vc-kts"));
	}
}

var APC_off = func {
	setprop ("autopilot/internal/target-speed", 0.0);
	APCengaged.setBoolValue(0);
	disengaged_light.setBoolValue(1);
	settimer(func { disengaged_light.setBoolValue(0); }, 10);
	setprop ("autopilot/locks/aoa", "");
	setprop ("autopilot/locks/speed", "");
    if(usingJSBSim){
        setprop ("fdm/jsbsim/systems/apc/active",0);
        setprop ("fdm/jsbsim/systems/apc/target-vc-kts",0);
    }
    setprop("sim/model/f-14b/controls/switch-throttle-mode", 0);

#print ("APC off");
}

