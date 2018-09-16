#----------------------------------------------------------------------------
# Sweep angle computer     
# Original F-14B : display purposes only ! No variable sweep on YaSim
# Richard Harrison JSBSim version (rjh@zaretto.com) has sweep angle in the 
# aerodynamic data - based on NASA data (see f-14a.xml for references) and
# it makes a lot of difference to the handling.
#----------------------------------------------------------------------------


# rjh@zaretto.com: changed the following in accordance with NAVAIR 01-F14AAD-1 Figure 2-48: p. 2-87
#                : max sweep now 68 (was 65)
#                : Machlo 0.41
#	<14000 feet
# sweep  MN
# 20	0.448 
# 21	0.711
# 68	0.913
#	>20000 feet
# sweep  MN
# 20	0.448
# 21	0.632
# 68	0.913
#
# main flaps max sweep is 47.5 to 50 until MN 0.913 
# aux flaps extended limit 21 deg
# 
var MachLo = 0.632;
var MachHi = 0.973;
var MachSweepRange = MachHi - MachLo;
#
#var OverSweepAngle = 75.0;
var beforeOverSweepMode  = 0;

var SweepRate = 2.0;    # degrees per second
var SweepVsMachLo = 22.0;  # for simplicity we will ignore the 21degrees sweep
var SweepVsMachHi = 60.0;
var currentSweepMode = 0; # 0=auto,1=man,2=off,3=emer,4=over
if (usingJSBSim) setprop("/fdm/jsbsim/fcs/wing-sweep-mode",0);

var minSweep = 0.2941176470588235;
var maxSweepAuxFlaps = 0.3235294117647059;
var maxSweep = 1.0 - minSweep;
var maxSweepMach = 0.88235294117647058823529411764706; # 60 degrees normalised
var mnSweepFactor = MachHi / (maxSweepMach-minSweep);
# Functions
    
setprop("/fdm/jsbsim/fcs/wing-sweep-cmd",0.2941176470588235);
setprop("/fdm/jsbsim/fcs/wing-sweep-pilot-dmd",0.2941176470588235);

var updateSweepIndicators = func {
# 0=auto,1=man,2=off,3=emer,4=over
		setprop("sim/model/f-14b/systems/wing-sweep/mode/off", currentSweepMode==2);
		setprop("sim/model/f-14b/systems/wing-sweep/mode/auto", currentSweepMode==0);
		setprop("sim/model/f-14b/systems/wing-sweep/mode/man",  currentSweepMode==1);
		setprop("sim/model/f-14b/systems/wing-sweep/mode/emer", currentSweepMode==3);
		setprop("sim/model/f-14b/systems/wing-sweep/mode/over", currentSweepMode==4);
}

var set_sweep = func(n) {
#    print("Set sweep ",n);
    if (n == 4) 
    {
    	if ( wow )
        {
    		# Flaps/sweep interlock
    		#do not move the wings until auxiliary flaps are in.
            if (usingJSBSim)
            {
                if (getprop ("controls/flight/flaps") > 0.05) return;
            }
            else
            {
        		if (getprop ("surface-positions/aux-flap-pos-norm") > 0.05) return;
            }
#            setprop("/fdm/jsbsim/fcs/wing-sweep-cmd",1.2);
        }
        else
        {
            #
            # if we get here then it means either an oversweep has been requested when not on the ground so set sweep to auto
        	#OverSweep = false;
            currentSweepMode = 0;
        }
    }
    if (n == 1 and currentSweepMode == 0)  ## manual from auto - set to current position
    {
        setprop("fdm/jsbsim/fcs/wing-sweep-pilot-dmd", currentSweep);
    }
    currentSweepMode = n;
    AutoSweep = currentSweepMode == 0;
   	#OverSweep = currentSweepMode == 4;
    setprop("/fdm/jsbsim/fcs/wing-sweep-mode",currentSweepMode);
    updateSweepIndicators();
}

var wingsweep1Degree = 0.0147058823529412;
var maxSweepWithFlaps = 0.3235294117647059;
var maxSweepWithOnlyMainFlaps = 0.7352941176470588;

set_sweep(0);

var set_wing_sweep = func(pos){

    if(pos < 0.2941176470588235) pos = 0.2941176470588235;

    if (currentSweepMode != 1)
    {
        set_sweep(1);
    }
    if (pos > 0.2941176470588235 and pos < 1.1029411764705882352941176470588)
    {
        setprop("fdm/jsbsim/fcs/wing-sweep-pilot-dmd", pos);
    }
#    print("wingsweep ",pos," ",getprop("fdm/jsbsim/fcs/wing-sweep-pilot-dmd"));
}

var move_wing_sweep = func(delta){
    var curval = getprop("fdm/jsbsim/fcs/wing-sweep-pilot-dmd");

    if (delta < 0 and curval > 0.2941176470588235)
    {
        set_wing_sweep(curval - wingsweep1Degree);
    }
    
    if (delta > 0 and curval < 1)
    {
        curval = curval + wingsweep1Degree;
        if(curval > maxSweepWithFlaps and getprop("controls/flight/flaps") > 0.4){
            curval = maxSweepWithFlaps;
        }
        set_wing_sweep(curval);
    }
}

var toggleOversweep = func {
    if (currentSweepMode == 4)
    {
        set_sweep(beforeOverSweepMode);
    }
    else
    {
    beforeOverSweepMode = currentSweepMode ;
        set_sweep(4);
    }
}

var computeSweep = func {

# The JSBSim model includes sweep computer inside the fdm.
    if (usingJSBSim)
    {
    	if ( getprop("sim/replay/time") > 0 ) { return }

        if (currentSweepMode != 4)
            currentSweep = getprop("/fdm/jsbsim/fcs/wing-sweep-cmd");
        else
            currentSweep = 1.2;

        var cadc_sweep = getprop("fdm/jsbsim/fcs/wing-sweep-cadc-dmd");
        WingSweep = currentSweep;
#        if(currentSweepMode == 1){
#            if (currentSweep < cadc_sweep){
#                currentSweepMode = 0; 
#                updateSweepIndicators();
#                setprop("/fdm/jsbsim/fcs/wing-sweep-mode",0);
#            }
#        }
        setprop("controls/flight/wing-sweep-cadc-dmd",cadc_sweep);
        setprop("controls/flight/wing-sweep",getprop("fdm/jsbsim/fcs/wing-sweep-dmd"));
        setprop("surface-positions/wing-pos-norm", getprop("fdm/jsbsim/fcs/wing-sweep-dmd"));
        return;
    }
#
#    setprop("controls/flight/wing-sweep-cadc-dmd",getprop("fdm/jsbsim/fcs/wing-sweep-cadc-dmd"));

    current_mach = getprop ("/velocities/mach");

    if (current_mach == nil)
        return;

# Flaps/sweep interlock
# do not move the wings until auxiliary flaps are in.

    if (getprop ("surface-positions/aux-flap-pos-norm") > 0.05) return;

    if(OverSweep) return;

# Sweep vs. Mach motion
    if (current_mach <= MachLo)
    {
        WingSweep = minSweep;
    }
    else if (current_mach < MachHi)
    {
        WingSweep = minSweep + (current_mach-MachLo) * mnSweepFactor;
        if (WingSweep > maxSweepMach)
            WingSweep = maxSweepMach;
    }
    setprop("/fdm/jsbsim/fcs/wing-sweep-cmd",WingSweep);
}

setlistener("/controls/flight/wingsweep-cover", func(v) {
    if (v != nil) {
        if (v.getValue()) {
            setprop("/fdm/jsbsim/fcs/wing-sweep-mode",1);
            currentSweepMode = 1;
        } else {
            setprop("/fdm/jsbsim/fcs/wing-sweep-mode",0);
            currentSweepMode = 0;
        }
        updateSweepIndicators();
    }
}, 0, 0);

setlistener("/controls/flight/wingsweep-guard", func(v) {
    if (getprop("/controls/flight/wingsweep-cover")) {
        if (v != nil) {
            if (v.getValue()) {
                if (getprop("/controls/flight/wing-sweep-cmd") >= 1) {
                    setprop("/fdm/jsbsim/fcs/wing-sweep-mode",1);
                    currentSweepMode = 4;
                    getprop("/controls/flight/wing-sweep-cmd",1.2);
                }
            } else {
                if (currentSweepMode == 4) {
                    if (getprop("/controls/flight/wing-sweep-cmd") >= 1) {
                        setprop("/controls/flight/wing-sweep-cmd",1.0);
                    }
                    currentSweepMode = 1;
                }
            }
        }
        updateSweepIndicators();
    }
}, 0, 0);

setlistener("/controls/flight/wings", func(v) {
# rescale because 0.294118 is 20 degrees and the minimum range.
    if (v != nil)
        set_wing_sweep(v.getValue()* 0.7059 + (1/68*20) );
},0,0);
