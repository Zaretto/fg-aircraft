
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

var APCengaged = props.globals.getNode("fdm/jsbsim/systems/apc/active");
var DLCengaged = props.globals.getNode("fdm/jsbsim/fcs/dlc-active");
var engaded = 0;
var gear_down = props.globals.getNode("controls/gear/gear-down");
var disengaged_light = props.globals.getNode("sim/model/f-14b/systems/apc/self-disengaged-light");
var throttle_0 = props.globals.getNode("controls/engines/engine[0]/throttle");
var throttle_1 = props.globals.getNode("controls/engines/engine[1]/throttle");
var flap_pos = props.globals.getNode("fdm/jsbsim/fcs/flap-pos-deg");
#var apc_disengage_throttle = props.globals.getNode("/fdm/jsbsim/systems/apc/disengage");

setlistener("fdm/jsbsim/fcs/dlc-active", func(v){
    # when turning dlc on/off ensure that the
    # thumbwheel is centered
    setprop("/controls/flight/DLC",0);
},0,0);

setlistener("sim/model/f-14b/controls/switch-throttle-mode", func(v){
    #
    # throttle mode cockpit switch has three positions
    # -1 MAN
    #  0 BOOST
    #  1 AUTO (APC)
    if (v.getValue() == 1)
        APC_on();
    else if (v.getValue() == 0)
        APC_off();
},0,0);


var computeAPC = func {
    # When throttles advanced to MIL retract speedbrake and disengage APC and DLC
    if (flap_pos.getValue() < 25)
    {
        if (APCengaged.getBoolValue()){
                print("APC Disengage");
                APC_off();
        }
        if ( DLCengaged.getBoolValue()){
            print("DLC Disengage");
             DLCengaged.setValue(0);
        }
        return;
    }
	if (throttle_0.getValue() >= 0.91 or throttle_1.getValue() >= 0.91)
    {
        if (APCengaged.getBoolValue()){
            print("APC Disengage");
			APC_off();
        }
        if ( DLCengaged.getBoolValue()){
            print("DLC Disengage");
             DLCengaged.setValue(0);
        }
        if (getprop("controls/flight/speedbrake", 0))
        {
            print("Retract speedbrake when throttles advanced to MIL");
            setprop("controls/flight/speedbrake", 0);
        }
    }

    # disengage when on ground or any engine out
	if (APCengaged.getBoolValue()) {
		if ( wow 
            or !gear_down.getBoolValue() 
            or !getprop("engines/engine[0]/running")
            or !getprop("engines/engine[1]/running")
           ) 
        {
            print("APC Disengage");
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
	if (!wow  and gear_down.getBoolValue() )
    {
		APCengaged.setBoolValue(1);
		disengaged_light.setBoolValue(0);
        if(usingJSBSim){
    		setprop ("fdm/jsbsim/systems/apc/active",1);
        }
        setprop("sim/model/f-14b/controls/switch-throttle-mode", 1);
	}
}

var APC_off = func {
	APCengaged.setBoolValue(0);
	disengaged_light.setBoolValue(1);
	settimer(func { disengaged_light.setBoolValue(0); }, 10);
    if(usingJSBSim){
        setprop ("fdm/jsbsim/systems/apc/active",0);
    }
    setprop("sim/model/f-14b/controls/switch-throttle-mode", 0);
}

