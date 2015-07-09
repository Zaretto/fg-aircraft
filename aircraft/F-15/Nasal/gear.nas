# F-15 Nose Wheel Steering
# ---------------------------
# Interface from the JSBSim routines to the aircraft 
# ---------------------------
# Richard Harrison (rjh@zaretto.com) Feb  2015 - based on F-14B version by Alexis Bory
# ---------------------------

var NWS_light = 0;

var computeNWS = func {
  	if ( getprop("sim/replay/time") > 0 ) { 
        return;
    }

    NWS_light = getprop("fdm/jsbsim/systems/NWS/engaged");
    setprop("controls/flight/NWS", getprop("fdm/jsbsim/fcs/steer-pos-deg")/85.0);
    if(getprop("/fdm/jsbsim/systems/holdback/launchbar-engaged"))
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


# GearDown Control
# ----------------
# Hijacked Gear handling so we have a Weight on Wheel security to prevent
# undercarriage retraction when on ground.

controls.gearDown = func(v) {
    if (v < 0 and ! wow) {
        setprop("/controls/gear/gear-down", 0);
    } elsif (v > 0) {
        setprop("/controls/gear/gear-down", 1);
    }
} 


