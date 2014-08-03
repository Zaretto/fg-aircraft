#----------------------------------------------------------------------------
# Sweep angle computer     
# For display purposes only ! No variable sweep on YaSim
#----------------------------------------------------------------------------

#Constants
var MachLo = 0.7;
var MachHi = 1.4;
var MachSweepRange = MachHi - MachLo;
var OverSweepAngle = 65.0;
var SweepRate = 2.0;    # degrees per second
var SweepVsMachLo = 20.0; 
var SweepVsMachHi = 60.0;

# Functions

var toggleOversweep = func {
	if ( wow and ! OverSweep ) {
		# Flaps/sweep interlock
		#do not move the wings until auxiliary flaps are in.
		if (getprop ("surface-positions/aux-flap-pos-norm") > 0.05) return;
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
	if (AutoSweep) {
		current_mach = getprop ("/velocities/mach");
		# Flaps/sweep interlock
		# do not move the wings until auxiliary flaps are in.
		if (getprop ("surface-positions/aux-flap-pos-norm") > 0.05) return;
		# Sweep vs. Mach motion
		if (current_mach <= MachLo) {
			WingSweep = 0.0;
		} elsif (current_mach < MachHi) {
			WingSweep = (current_mach - MachLo) / MachSweepRange;
		} else {
			WingSweep = 1.0;
		}
	}

}
