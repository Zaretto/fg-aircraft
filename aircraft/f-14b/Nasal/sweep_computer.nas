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
var OverSweepAngle = 68.0;
var SweepRate = 2.0;    # degrees per second
var SweepVsMachLo = 22.0;  # for simplicity we will ignore the 21degrees sweep
var SweepVsMachHi = 60.0;

if (usingJSBSim) setprop("/fdm/jsbsim/fcs/wing-sweep-auto",1);

var minSweep = 0.383972435;
var maxSweep = 1.0 - minSweep;
var mnSweepFactor = (maxSweep - minSweep) / (MachHi - MachLo);
# Functions
    
var toggleOversweep = func {
	if ( wow and ! OverSweep ) {
		# Flaps/sweep interlock
		#do not move the wings until auxiliary flaps are in.
        if (usingJSBSim)
        {
            if (getprop ("fcs/aux-flap-pos-deg") > 0.05) return;
        }
        else
        {
    		if (getprop ("surface-positions/aux-flap-pos-norm") > 0.05) return;
        }

		OverSweep = true;
		AutoSweep = false;
		WingSweep = 1.2;
		setprop("sim/model/f-14b/systems/wing-sweep/mode/auto", 0);
		setprop("sim/model/f-14b/systems/wing-sweep/mode/over", 1);
	} elsif ( OverSweep ) {
		AutoSweep = true;
		WingSweep = 0.0;
		OverSweep = false;
		setprop("sim/model/f-14b/systems/wing-sweep/mode/auto", 1);
		setprop("sim/model/f-14b/systems/wing-sweep/mode/over", 0);
	}
}

var computeSweep = func {

# The JSBSim model includes sweep computer inside the fdm.
    if (usingJSBSim){
        currentSweep = getprop("/fdm/jsbsim/fcs/wing-sweep-cmd");
        return;
    }

	if (AutoSweep) {
		current_mach = getprop ("/velocities/mach");

        if (current_mach == nil)
            return;

		# Flaps/sweep interlock
		# do not move the wings until auxiliary flaps are in.

		if (getprop ("surface-positions/aux-flap-pos-norm") > 0.05) return;

		# Sweep vs. Mach motion
		if (current_mach <= MachLo) {
			WingSweep = minSweep;
		} elsif (current_mach < MachHi) {
			WingSweep = minSweep + (current_mach * mnSweepFactor); #(current_mach - MachLo) / MachSweepRange;
		} else {
			WingSweep = maxSweep;
		}
        setprop("/fdm/jsb-sim/fcs/wing-sweep-cmd",WingSweep);
	}
}
