#
# F-15 Adverse effectts.
# ---------------------------
# Models effects from acceleration and flutter on the wing.
# Residual wing bending after large G will be reatined.
# Fix airframe to reset damage.
# ---------------------------
# Richard Harrison (rjh@zaretto.com) 2014-11-23. Based on F-14b by xx
#

var WingBend = 0.0;
var ResidualBend = 0.0;
var MaxResidualBend = 0.3;

var MaxGreached = 0.0;
var MinGreached = 0.0;
var MaxG = 7.5;
var MinG = -3.0;
var UltimateFactor = 2; 
var UltimateMaxG = MaxG * UltimateFactor;
var UltimateMinG = MinG * UltimateFactor;

var ResidualBendFactor = MaxResidualBend / UltimateMaxG;
#var BendFactor = 0.66 / MaxG;
var BendFactor = 0.16 / MaxG; # degrees of rotation * 7 per G
var LeftWingTorn = false;
var RightWingTorn = false;

var fixAirframe = func {

	MaxGreached = 0.0;
	MinGreached = 0.0;
	ResidualBend = 0.0;
	FailureAileron = 0.0;
	setprop ("sim/model/f15/wings/left-wing-torn", LeftWingTorn);
	setprop ("sim/model/f15/wings/right-wing-torn", RightWingTorn);
}

var computeWingBend = func {
	var av_currentG = getprop ("sim/model/f15/instrumentation/g-meter/g-max-mooving-average") - 1.0;   # adjust to loading
    if (av_currentG == nil) return;
	#effects of normal acceleration

	if (currentG >= MaxGreached) MaxGreached = av_currentG;
	if (currentG <= MinGreached) MinGreached = av_currentG;
	if (MaxGreached > MaxG and MaxGreached < UltimateMaxG)
    {
		ResidualBend = ResidualBendFactor * (MaxGreached - MaxG);
        if (ResidualBend > MaxResidualBend)
            ResidualBend = MaxResidualBend;
	}
	else if (MinGreached < MinG and MinGreached > UltimateMinG)
    {
		ResidualBend = ResidualBendFactor * (MinGreached - MinG);
        if (ResidualBend > MaxResidualBend)
            ResidualBend = MaxResidualBend;
	}
	WingBend = ResidualBend + currentG * BendFactor;
	setprop ("surface-positions/wing-fold-pos-norm", WingBend);
}

#----------------------------------------------------------------------------
# Adverse aerodynamic phenomena simulation (spin, roll inversion ...)
#----------------------------------------------------------------------------

var computeAdverse = func {
	computeWingBend ();
}
