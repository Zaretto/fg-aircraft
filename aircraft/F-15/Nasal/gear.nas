# F-15 Nose Wheel Steering
# ---------------------------
# Interface from the JSBSim routines to the aircraft 
# ---------------------------
# Richard Harrison (rjh@zaretto.com) Feb  2015 - based on F-14B version by Alexis Bory
# ---------------------------


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


