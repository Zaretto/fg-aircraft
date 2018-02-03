# F-15 Nose Wheel Steering
# ---------------------------
# Interface from the JSBSim routines to the aircraft 
# ---------------------------
# Richard Harrison (rjh@zaretto.com) Feb  2015 - based on F-14B version by Alexis Bory
# ---------------------------

var NWS_light = 0;
var gear0 = props.globals.getNode("gear/gear[0]/position-norm");
var gear1 = props.globals.getNode("gear/gear[1]/position-norm");
var gear2 = props.globals.getNode("gear/gear[2]/position-norm");
var gear0damaged = props.globals.getNode("fdm/jsbsim/gear/unit[0]/damaged");
var gear1damaged = props.globals.getNode("fdm/jsbsim/gear/unit[1]/damaged");
var gear2damaged = props.globals.getNode("fdm/jsbsim/gear/unit[2]/damaged");
var gear0pos  = props.globals.getNode("fdm/jsbsim/gear/unit[0]/pos-norm");
var gear1pos  = props.globals.getNode("fdm/jsbsim/gear/unit[1]/pos-norm");
var gear2pos  = props.globals.getNode("fdm/jsbsim/gear/unit[2]/pos-norm");

var gearpos_norm = props.globals.getNode("fdm/jsbsim/gear/gear-pos-norm");

var computeNWS = func {
  	if ( getprop("sim/replay/time") > 0 ) { 
        return;
    }
    if (gear0damaged.getValue() and gear0pos.getValue() > 0.6)
      gear0.setValue(0.5);
    else
      gear0.setValue(gearpos_norm.getValue());

    if (gear1damaged.getValue() and gear1pos.getValue() > 0.6)
      gear1.setValue(0.5);
    else
      gear1.setValue(gearpos_norm.getValue());

    if (gear2damaged.getValue() and gear2pos.getValue() > 0.6)
      gear2.setValue(0.5);
    else
      gear2.setValue(gearpos_norm.getValue());

    NWS_light = getprop("fdm/jsbsim/systems/NWS/engaged");
    setprop("controls/flight/NWS", getprop("fdm/jsbsim/fcs/steer-pos-deg")/85.0);
    if(getprop("fdm/jsbsim/systems/holdback/launchbar-engaged"))
    {
        setprop("gear/launchbar/position-norm",1);
        setprop("gear/launchbar/state","Engaged");
        setprop("models/carrier/controls/jbd",1);
    }
    else
    {
        setprop("gear/launchbar/position-norm",0);
        setprop("gear/launchbar/state","Disengaged");
        setprop("models/carrier/controls/jbd",0);
    }
    setprop("sim/model/f15/instrumentation/gears/nose-wheel-steering-warnlight", NWS_light);
}

setlistener("/gear/serviceable", func(v) { setprop("/fdm/jsbsim/gear/serviceable",v.getValue());});
# GearDown Control
# ----------------
# Hijacked Gear handling so we have a Weight on Wheel security to prevent
# undercarriage retraction when on ground.

controls.gearDown = func(v) {
    if (v < 0 and ! wow) {
        setprop("controls/gear/gear-down", 0);
    } elsif (v > 0) {
        setprop("controls/gear/gear-down", 1);
    }
} 


