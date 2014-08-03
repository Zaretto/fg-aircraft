# mocks effects of acceleration and flutter on the structure (wing).
var WingBend = 0.0;
var ResidualBend = 0.0;
var MaxResidualBend = 0.3;

var MaxGreached = 0.0;
var MinGreached = 0.0;
var MaxG = 7.5;
var MinG = -3.0;
var UltimateFactor = 1.5;
var UltimateMaxG = MaxG * UltimateFactor;
var UltimateMinG = MinG * UltimateFactor;

var ResidualBendFactor = MaxResidualBend / (UltimateMaxG - MaxG);
var BendFactor = 0.66 / MaxG;

var FlutterOnsetIAS = 850.0;	#knots
var FullFlutterIAS = 950.0;		#knots
var FlutterPulsation = 2 * 3.14 * 3.0; #3 cycles per second
var FlutterMaxBendAmplitude = 0.3;
var FlutterBendFactor = FlutterMaxBendAmplitude / (FullFlutterIAS - FlutterOnsetIAS);
var FlutterPitchFactor = 0.08 / 100;
var FlutterPitch = 0.0;
var FlutterTime = 0.0;

var LeftWingTorn = false;
var RightWingTorn = false;
var FailureAileron = 0.0;

var fixAirframe = func {

	LeftWingTorn = false;
	RightWingTorn = false;
	MaxGreached = 0.0;
	MinGreached = 0.0;
	ResidualBend = 0.0;
	FailureAileron = 0.0;
	setprop ("sim/model/f-14b/wings/left-wing-torn", LeftWingTorn);
	setprop ("sim/model/f-14b/wings/right-wing-torn", RightWingTorn);
}

var computeWingBend = func {
	# Tears one wing if ultimate limits are exceeded.
	var av_currentG = getprop ("sim/model/f-14b/instrumentation/g-meter/g-max-mooving-average");   
	if (av_currentG >= UltimateMaxG or av_currentG <= UltimateMinG) {
		if (!RightWingTorn and !LeftWingTorn) {
			whichWingToTear = rand();
			if (whichWingToTear > 0.5) {
				LeftWingTorn = true;
			} else {
				RightWingTorn = true;
			}
		}
		FailureAileron = RightWingTorn - LeftWingTorn;
		setprop ("sim/model/f-14b/wings/left-wing-torn", LeftWingTorn);
		setprop ("sim/model/f-14b/wings/right-wing-torn", RightWingTorn);
	}
	#effects of normal acceleration
	var currentG = getprop ("accelerations/pilot-g");   
	if (currentG >= MaxGreached) MaxGreached = av_currentG;
	if (currentG <= MinGreached) MinGreached = av_currentG;
	if (MaxGreached > MaxG and MaxGreached < UltimateMaxG) {
		ResidualBend = ResidualBendFactor * (MaxGreached - MaxG);
	}
	if (MinGreached < MinG and MinGreached > UltimateMinG) {
		ResidualBend = ResidualBendFactor * (MaxGreached - MaxG);
	}
	if (CurrentIAS > FlutterOnsetIAS) {
		currentAmplitude = math.sin (FlutterPulsation * FlutterTime);
		FlutterPitch = FlutterPitchFactor * (CurrentIAS - FlutterOnsetIAS) * currentAmplitude;
		if (CurrentIAS < FullFlutterIAS) {
			flutterBend = FlutterBendFactor * (CurrentIAS - FlutterOnsetIAS) * currentAmplitude;
		} else {
			flutterBend = FlutterMaxBendAmplitude * currentAmplitude;
		}
		FlutterTime += deltaT;
	} else {
		FlutterTime = 0.0;
		FlutterPitch = 0.0;
		flutterBend = 0.0;
	}
	WingBend = ResidualBend + currentG * BendFactor + flutterBend;
	setprop ("surface-positions/wing-fold-pos-norm", WingBend);
}

#----------------------------------------------------------------------------
# Adverse aerodynamic phenomena simulation (spin, roll inversion ...)
#----------------------------------------------------------------------------

var computeAdverse = func {
	computeWingBend ();
	if (Alpha < 25.0) {
		setprop ("controls/flight/adverse/pitch", 0.5 * SASpitch + e_trim + FlutterPitch);
		setprop ("controls/flight/adverse/roll", 0.5 * SASroll + FailureAileron);
		#setprop ("controls/flight/adverse/roll", 0);
	} else {
		setprop ("controls/flight/adverse/pitch", - 1.0 + FlutterPitch);
		setprop ("controls/flight/adverse/roll", getprop ("/orientation/yaw-rate-degps") / 60 + FailureAileron);
		#setprop ("controls/flight/adverse/roll", 0);
	}
}
