# Maik Justus < fg # mjustus : de >, based on bo105.nas by Melchior FRANZ, < mfranz # aon : at >

animateAdfDisplay = func {
	adfFreq = getprop("/instrumentation/adf/frequencies/selected-khz");
	adfE3 = int(adfFreq/1000);
	adfE2 = int((adfFreq-(adfE3*1000))/100);
	adfE0 = adfFreq-(adfE3*1000)-(adfE2*100);
	setprop("/sim/model/ch53e/instrument-pos/ADFFreqDisp1", adfE3);
	setprop("/sim/model/ch53e/instrument-pos/ADFFreqDisp2", adfE2);
	setprop("/sim/model/ch53e/instrument-pos/ADFFreqDisp3", adfE0);
}
setlistener("/instrumentation/adf/frequencies/selected-khz", animateAdfDisplay);

watchAdfSelector = func {
	if (getprop("/instrumentation/adf/control-switch") == 0) {
		setprop("/instrumentation/adf/serviceable", 0);
	} else {
		setprop("/instrumentation/adf/serviceable", 1);
	}
}
setlistener("/instrumentation/adf/control-switch", watchAdfSelector);

setlistener("/instrumentation/adf/volume-norm", func{setprop("/instrumentation/adf/ident-audible", 1)} );

initAdf = func {
	setprop("/instrumentation/adf/control-switch", getprop("/instrumentation/adf/serviceable"));
	animateAdfDisplay();
	watchAdfSelector();
}
settimer(initAdf, 0);

################
#
# Buttons
#
################

initPanelButtons = func {
	# Global stuff
	panelRed = props.globals.getNode('controls/lighting/panel/emission/red', 1);
	panelGreen = props.globals.getNode('controls/lighting/panel/emission/green', 1);
	panelBlue = props.globals.getNode('controls/lighting/panel/emission/blue', 1);
	nvgMode = props.globals.getNode('controls/lighting/nvg-mode', 1);

	# Front panel fuel buttons
	lAuxLightRed = props.globals.getNode('sim/model/ch53e/materials/LAUXLight/emission/red', 1);
	lAuxLightGreen = props.globals.getNode('sim/model/ch53e/materials/LAUXLight/emission/green', 1);
	lAuxLightBlue = props.globals.getNode('sim/model/ch53e/materials/LAUXLight/emission/blue', 1);
	lAuxLightMode = props.globals.getNode('sim/model/ch53e/control-input/fuel-button[0]', 1);
	lAuxLight = { 'red':lAuxLightRed, 'green':lAuxLightGreen, 'blue':lAuxLightBlue, 'mode':lAuxLightMode };

	lMainLightRed = props.globals.getNode('sim/model/ch53e/materials/LMAINLight/emission/red', 1);
	lMainLightGreen = props.globals.getNode('sim/model/ch53e/materials/LMAINLight/emission/green', 1);
	lMainLightBlue = props.globals.getNode('sim/model/ch53e/materials/LMAINLight/emission/blue', 1);
	lMainLightMode = props.globals.getNode('sim/model/ch53e/control-input/fuel-button[1]', 1);
	lMainLight = { 'red':lMainLightRed, 'green':lMainLightGreen, 'blue':lMainLightBlue, 'mode':lMainLightMode };

	rMainLightRed = props.globals.getNode('sim/model/ch53e/materials/RMAINLight/emission/red', 1);
	rMainLightGreen = props.globals.getNode('sim/model/ch53e/materials/RMAINLight/emission/green', 1);
	rMainLightBlue = props.globals.getNode('sim/model/ch53e/materials/RMAINLight/emission/blue', 1);
	rMainLightMode = props.globals.getNode('sim/model/ch53e/control-input/fuel-button[2]', 1);
	rMainLight = { 'red':rMainLightRed, 'green':rMainLightGreen, 'blue':rMainLightBlue, 'mode':rMainLightMode };

	rAuxLightRed = props.globals.getNode('sim/model/ch53e/materials/RAUXLight/emission/red', 1);
	rAuxLightGreen = props.globals.getNode('sim/model/ch53e/materials/RAUXLight/emission/green', 1);
	rAuxLightBlue = props.globals.getNode('sim/model/ch53e/materials/RAUXLight/emission/blue', 1);
	rAuxLightMode = props.globals.getNode('sim/model/ch53e/control-input/fuel-button[3]', 1);
	rAuxLight = { 'red':rAuxLightRed, 'green':rAuxLightGreen, 'blue':rAuxLightBlue, 'mode':rAuxLightMode };

	refuelPwrLightRed = props.globals.getNode('sim/model/ch53e/materials/RefuelPwrLight/emission/red', 1);
	refuelPwrLightGreen = props.globals.getNode('sim/model/ch53e/materials/RefuelPwrLight/emission/green', 1);
	refuelPwrLightBlue = props.globals.getNode('sim/model/ch53e/materials/RefuelPwrLight/emission/blue', 1);
	refuelPwrLightMode = props.globals.getNode('sim/model/ch53e/control-input/refuel-pwr', 1);
	refuelPwrLight = { 'red':refuelPwrLightRed, 'green':refuelPwrLightGreen, 'blue':refuelPwrLightBlue, 'mode':refuelPwrLightMode };

	refuelProbeLightRed = props.globals.getNode('sim/model/ch53e/materials/RefuelProbeLight/emission/red', 1);
	refuelProbeLightGreen = props.globals.getNode('sim/model/ch53e/materials/RefuelProbeLight/emission/green', 1);
	refuelProbeLightBlue = props.globals.getNode('sim/model/ch53e/materials/RefuelProbeLight/emission/blue', 1);
	refuelProbeLightMode = props.globals.getNode('sim/model/ch53e/control-input/refuel-probe', 1);
	refuelProbeLight = { 'red':refuelProbeLightRed, 'green':refuelProbeLightGreen, 'blue':refuelProbeLightBlue, 'mode':refuelProbeLightMode };

	refuelPurgeLightRed = props.globals.getNode('sim/model/ch53e/materials/RefuelPurgeLight/emission/red', 1);
	refuelPurgeLightGreen = props.globals.getNode('sim/model/ch53e/materials/RefuelPurgeLight/emission/green', 1);
	refuelPurgeLightBlue = props.globals.getNode('sim/model/ch53e/materials/RefuelPurgeLight/emission/blue', 1);
	refuelPurgeLightMode = props.globals.getNode('sim/model/ch53e/control-input/refuel-purge', 1);
	refuelPurgeLight = { 'red':refuelPurgeLightRed, 'green':refuelPurgeLightGreen, 'blue':refuelPurgeLightBlue, 'mode':refuelPurgeLightMode };

	buttons = [
		lAuxLight, lMainLight, rMainLight, rAuxLight,
		refuelPwrLight, refuelProbeLight, refuelPurgeLight ];

	setButton = func(button) {
		button['red'].setDoubleValue(panelRed.getValue());
		button['green'].setDoubleValue(panelGreen.getValue());
		button['blue'].setDoubleValue(panelBlue.getValue());
		if (button['mode'].getValue()) {
			if (nvgMode.getValue() == '1') {
				button['green'].setValue(1);
			} else {
				button['red'].setValue(1);
			}
		}
	
	}

	setAllButtons = func {
		foreach (var button; buttons) {
			setButton(button);
		}
	}

	# Changes due to interior-lights.nas
	setlistener(nvgMode,    setAllButtons);
	setlistener(panelRed,   setAllButtons);
	setlistener(panelGreen, setAllButtons);
	setlistener(panelBlue,  setAllButtons);

	# Changes due to hotspot clicks or other state changes
	setlistener(lAuxLightMode,        func { setButton(lAuxLight) } );
	setlistener(lMainLightMode,       func { setButton(lMainLight) } );
	setlistener(rMainLightMode,       func { setButton(rMainLight) } );
	setlistener(rAuxLightMode,        func { setButton(rAuxLight) } );
	setlistener(refuelPwrLightMode,   func { setButton(refuelPwrLight) } );
	setlistener(refuelProbeLightMode, func { setButton(refuelProbeLight) } );
	setlistener(refuelPurgeLightMode, func { setButton(refuelPurgeLight) } );
}

################
#
# Comm
#
################

adjustCommDisplay = func(radioNumber) {
	if (getprop('/instrumentation/comm['~radioNumber~']/serviceable')) {
		freqGhz = 1000 * getprop('/instrumentation/comm['~radioNumber~']/frequencies/selected-mhz');
		# This is done in a cleaner way in the TACAN code
		digit1 = int(freqGhz/100000);
		freqGhz = freqGhz-digit1*100000;
		digit2 = int(freqGhz/10000);
		freqGhz = freqGhz-digit2*10000;
		digit3 = int(freqGhz/1000);
		freqGhz = freqGhz-digit3*1000;
		digit4 = int(freqGhz/100);
		freqGhz = freqGhz-digit4*100;
		digit5 = int(freqGhz/10);
		freqGhz = int(freqGhz-digit5*10);
		setprop('/sim/model/ch53e/instrument-pos/VHF'~radioNumber~'Display1-texture', 'LCD-'~digit1~'.rgb');
		setprop('/sim/model/ch53e/instrument-pos/VHF'~radioNumber~'Display2-texture', 'LCD-'~digit2~'.rgb');
		setprop('/sim/model/ch53e/instrument-pos/VHF'~radioNumber~'Display3-texture', 'LCD-'~digit3~'.rgb');
		setprop('/sim/model/ch53e/instrument-pos/VHF'~radioNumber~'Display4-texture', 'LCD-Period.rgb');
		setprop('/sim/model/ch53e/instrument-pos/VHF'~radioNumber~'Display5-texture', 'LCD-'~digit4~'.rgb');
		setprop('/sim/model/ch53e/instrument-pos/VHF'~radioNumber~'Display6-texture', 'LCD-'~digit5~'.rgb');
		setprop('/sim/model/ch53e/instrument-pos/VHF'~radioNumber~'Display7-texture', 'LCD-'~freqGhz~'.rgb');
	} else {
		for (i=1; i<=7; i+=1) {
			setprop('/sim/model/ch53e/instrument-pos/VHF'~radioNumber~'Display'~i~'-texture', 'transparent.rgb');
		}
	}
}

settimer(func{adjustCommDisplay(0)}, 0);
settimer(func{adjustCommDisplay(1)}, 0);
setlistener('/instrumentation/comm[0]/serviceable', func{adjustCommDisplay(0)});
setlistener('/instrumentation/comm[1]/serviceable', func{adjustCommDisplay(1)});
setlistener('/instrumentation/comm[0]/frequencies/selected-mhz', func{adjustCommDisplay(0)});
setlistener('/instrumentation/comm[1]/frequencies/selected-mhz', func{adjustCommDisplay(1)});

################
#
# EAPS
#
# Adjust animation properties based on switch positions and airspeed.
#
################

EAPSASIServicable = nil;
EAPSAirSpeed = nil;
EAPSCutoff = nil; # Airspeed above which to open EAPS doors in auto mode
EAPSSens = nil;   # To prevent banging back and forth when speed is around EAPSCutoff
EAPSNodes = [];
EAPSDoors = [];

EAPSAnimator = func {
	foreach (node; EAPSNodes) {
	}
}

EAPSAsWatcher = func {
	# Check to see that the switch positions match the status of the EAPS doors.
	# If not, adjust the status.
	foreach (node; EAPSNodes) {
		if (node.getNode('mode').getValue() == 1) {
			# Automatic mode, but only if the ASI is serviceable
			if (EAPSASIServicable.getBoolValue() == 1) {
				if (((EAPSAirSpeed.getValue() - EAPSSens.getValue()) > EAPSCutoff.getValue()) and (node.getNode('command-open').getBoolValue() != 1)) {
					node.getNode('command-open').setBoolValue(1);
					EAPSAnimator();
				} elsif (((EAPSAirSpeed.getValue() + EAPSSens.getValue()) < EAPSCutoff.getValue()) and (node.getNode('command-open').getBoolValue() != 0)) {
					node.getNode('command-open').setBoolValue(0);
					EAPSAnimator();
				}
			}
		} elsif ((node.getNode('mode').getValue() == 0) and (node.getNode('command-open').getBoolValue() != 0)) {
			# Manual close
			node.getNode('command-open').setBoolValue(0);
			EAPSAnimator();
		} elsif ((node.getNode('mode').getValue() == 2) and (node.getNode('command-open').getBoolValue() != 1)) {
			# Manual open
			node.getNode('command-open').setBoolValue(1);
			EAPSAnimator();
		}
	}
	settimer(EAPSAsWatcher, 0.05);
}

EAPSInit = func {
	EAPSASIServicable = props.globals.getNode('instrumentation/airspeed-indicator/serviceable', 1);
	EAPSAirSpeed = props.globals.getNode('instrumentation/airspeed-indicator/indicated-speed-kts', 1);
	EAPSCutoff = props.globals.getNode('sim/model/ch53e/control-input/eaps/cutoff-speed-kts', 1);
	EAPSSens = props.globals.getNode('sim/model/ch53e/control-input/eaps/sensitivity-kts', 1);
	EAPSNodes = [ props.globals.getNode('sim/model/ch53e/control-input/eaps/eaps[0]', 1), props.globals.getNode('sim/model/ch53e/control-input/eaps/eaps[1]', 1), props.globals.getNode('sim/model/ch53e/control-input/eaps/eaps[2]', 1) ];
	if (EAPSASIServicable.getValue() == nil) {
		EAPSAirSpeed.setBoolValue(1);
	}
	if (EAPSAirSpeed.getValue() == nil) {
		EAPSAirSpeed.setDoubleValue(0);
	}
	if (EAPSCutoff.getValue() == nil) {
		EAPSCutoff.setIntValue(40);
	}
	if (EAPSSens.getValue() == nil) {
		EAPSSens.setIntValue(3);
	}
	foreach (node; EAPSNodes) {
		if (node.getNode('mode').getValue() == nil) {
			node.getNode('mode').setIntValue(1);
		}
		if (node.getNode('command-open').getValue() == nil) {
			node.getNode('command-open').setBoolValue(1);
		}
		if (node.getNode('pos-norm').getValue() == nil) {
			node.getNode('pos-norm').setDoubleValue(0);
		}
		# TODO add a door.new for pos-norm to EAPSDoors
	}
	settimer(EAPSAsWatcher, 0);
	settimer(EAPSAnimator, 0);
}
settimer(EAPSInit, 0);

if (!contains(globals, "cprint")) {
	globals.cprint = func {};
}

var optarg = aircraft.optarg;
var makeNode = aircraft.makeNode;

var sin = func(a) { math.sin(a * math.pi / 180.0) }
var cos = func(a) { math.cos(a * math.pi / 180.0) }
var pow = func(v, w) { math.exp(math.ln(v) * w) }
var npow = func(v, w) { math.exp(math.ln(abs(v)) * w) * (v < 0 ? -1 : 1) }
var clamp = func(v, min = 0, max = 1) { v < min ? min : v > max ? max : v }
var normatan = func(x) { math.atan2(x, 1) * 2 / math.pi }




# timers ============================================================
var turbine_timer = aircraft.timer.new("/sim/time/hobbs/turbines", 10);
aircraft.timer.new("/sim/time/hobbs/helicopter", nil).start();

# strobes ===========================================================
var strobe_switch = props.globals.getNode("controls/lighting/strobe", 1);
aircraft.light.new("sim/model/ch53e/lighting/strobe-top", [0.05, 1.00], strobe_switch);
aircraft.light.new("sim/model/ch53e/lighting/strobe-bottom", [0.05, 1.03], strobe_switch);

# beacons ===========================================================
var beacon_switch = props.globals.getNode("controls/lighting/beacon", 1);
aircraft.light.new("sim/model/ch53e/lighting/beacon-top", [0.62, 0.62], beacon_switch);
aircraft.light.new("sim/model/ch53e/lighting/beacon-bottom", [0.63, 0.63], beacon_switch);


# nav lights ========================================================
var nav_light_switch = props.globals.getNode("controls/lighting/nav-lights", 1);
var visibility = props.globals.getNode("environment/visibility-m", 1);
var sun_angle = props.globals.getNode("sim/time/sun-angle-rad", 1);
var nav_lights = props.globals.getNode("sim/model/ch53e/lighting/nav-lights", 1);

var nav_light_loop = func {
	if (nav_light_switch.getValue()) {
		nav_lights.setValue(visibility.getValue() < 5000 or sun_angle.getValue() > 1.4);
	} else {
		nav_lights.setValue(0);
	}
	settimer(nav_light_loop, 3);
}

settimer(nav_light_loop, 0);


################
#
# Fuel system
#
################

tank0Level = '';
tank1Level = '';
tank2Level = '';
tank3Level = '';
tank4Level = '';
tank5Level = '';
totalFuel = '';
fuelTotalerInit = func {
	tank0Level = props.globals.getNode('consumables/fuel/tank[0]/level-lbs', 1);
	tank1Level = props.globals.getNode('consumables/fuel/tank[1]/level-lbs', 1);
	tank2Level = props.globals.getNode('consumables/fuel/tank[2]/level-lbs', 1);
	tank3Level = props.globals.getNode('consumables/fuel/tank[3]/level-lbs', 1);
	tank4Level = props.globals.getNode('consumables/fuel/tank[4]/level-lbs', 1);
	tank5Level = props.globals.getNode('consumables/fuel/tank[5]/level-lbs', 1);
	totalFuel = props.globals.getNode('consumables/fuel/total-fuel-lbs', 1);
	settimer(fuelTotaler, 0);
}
fuelTotaler = func {
	totalFuel.setDoubleValue(tank0Level.getValue()+tank1Level.getValue()+tank2Level.getValue()+tank3Level.getValue()+tank4Level.getValue()+tank5Level.getValue());
	settimer(fuelTotaler, 0.1);
}
settimer(fuelTotalerInit, 0);


################
#
# Landing gear animation support
#
################

# Emergency extension

emergGearActivate = func {
	setprop('/sim/model/ch53e/control-input/emergency-gear-release', 0);
	if (getprop('/sim/model/ch53e/control-pos/LandingGearEmergExt-rot-norm') == 0) {
		interpolate('/sim/model/ch53e/control-pos/LandingGearEmergExt-rot-norm', 1, 0.25);
	} elsif (getprop('/sim/model/ch53e/control-pos/LandingGearEmergExt-rot-norm') == 1) {
		interpolate('/sim/model/ch53e/control-pos/LandingGearEmergExt-pos-norm', 1, 0.25);
		# FIXME the gear should drop very quickly, not take the 6 sec cycle time
		settimer(func {controls.gearDown(1)}, 0.5);
	}
}
setlistener('/sim/model/ch53e/control-input/emergency-gear-release', emergGearActivate);

# Indicator tabs and light

turnGearLight = func(status) {
	base = "/sim/model/ch53e/instrument-pos/gearHandleGlow/";
	if (status == 'red') {
		setprop(base~"emission/red", 0.65);
		setprop(base~"emission/green", 0);
		setprop(base~"ambient/red", 0.8);
		setprop(base~"ambient/green", 0.2);
		setprop(base~"ambient/blue", 0.2);
	} elsif (status == 'green') {
		setprop(base~"emission/red", 0);
		setprop(base~"emission/green", 0.65);
		setprop(base~"ambient/red", 0.2);
		setprop(base~"ambient/green", 0.8);
		setprop(base~"ambient/blue", 0.2);
	} elsif (status == 'off') {
		setprop(base~"emission/red", 0);
		setprop(base~"emission/green", 0);
		setprop(base~"ambient/red", 0.8);
		setprop(base~"ambient/green", 0.8);
		setprop(base~"ambient/blue", 0.8);
	}
}

origGearDown = controls.gearDown;
lastGearPosition = nil;
controls.gearDown = func(position) {
	# Someone moved the gear handle. Indicate barberpole until further notice, unless the emergency release has been pulled.
	# Mode the control handle regardless
	if ((position != 0) and (position != lastGearPosition) and (getprop('/sim/model/ch53e/control-pos/LandingGearEmergExt-pos-norm') != 1)) {
		interpolate("/sim/model/ch53e/control-pos/LandingGearHandle-pos-norm", position, 0.2);
		lastGearPosition = position;
		# Turn light red right away
		turnGearLight('red');
		# Display all barber poles right away
		interpolate("/sim/model/ch53e/instrument-pos/GearIndicator0-pos", 0, 0.1);
		interpolate("/sim/model/ch53e/instrument-pos/GearIndicator1-pos", 0, 0.1);
		interpolate("/sim/model/ch53e/instrument-pos/GearIndicator2-pos", 0, 0.1);
		# Make sure these times match those in the YASim file TODO
		# Also, these interpolations don't always work right FIXME
		if (position == 1) {
			settimer(func {interpolate("/sim/model/ch53e/instrument-pos/GearIndicator0-pos", 1, 0.1)}, 6.0);
			settimer(func {interpolate("/sim/model/ch53e/instrument-pos/GearIndicator1-pos", 1, 0.1)}, 6.0);
			settimer(func {interpolate("/sim/model/ch53e/instrument-pos/GearIndicator2-pos", 1, 0.1)}, 6.0);
			settimer(func {turnGearLight('green')}, 6.0);
		} elsif (position == -1) {
			settimer(func {interpolate("/sim/model/ch53e/instrument-pos/GearIndicator0-pos", -1, 0.1)}, 6.0);
			settimer(func {interpolate("/sim/model/ch53e/instrument-pos/GearIndicator1-pos", -1, 0.1)}, 6.0);
			settimer(func {interpolate("/sim/model/ch53e/instrument-pos/GearIndicator2-pos", -1, 0.1)}, 6.0);
			settimer(func {turnGearLight('off')}, 6.0);
		}
		origGearDown(position);
	}
}

gearInit = func {
	position = getprop('/controls/gear/gear-down');
	setprop("/sim/model/ch53e/control-pos/LandingGearHandle-pos-norm", position);
	setprop("/sim/model/ch53e/instrument-pos/GearIndicator0-pos", position);
	setprop("/sim/model/ch53e/instrument-pos/GearIndicator1-pos", position);
	setprop("/sim/model/ch53e/instrument-pos/GearIndicator2-pos", position);
	if (position == 1) {
		turnGearLight('green');
	} else {
		turnGearLight('off');
	}
}
settimer(gearInit, 0);

################
#
# NVG Lighting Switch
#
# This model has a night vision mode switch which selects between two colors for the
# panel and instrument lights. Instead of just setting the desired colors for various
# lights in the -set file as would be normal with interior-lights.nas, this system
# watches the apropriate switch and then sets the instument-lights.nas input props
# based on two custom defined color schemes.
#
################

initNvgMode = func {
	adjustNvgMode = func {
		if (nvgMode.getValue()) {
			domeLightRed.setDoubleValue(domeLightRedNvg.getValue());
			domeLightGreen.setDoubleValue(domeLightGreenNvg.getValue());
			domeLightBlue.setDoubleValue(domeLightBlueNvg.getValue());
			panelLightRed.setDoubleValue(panelLightRedNvg.getValue());
			panelLightGreen.setDoubleValue(panelLightGreenNvg.getValue());
			panelLightBlue.setDoubleValue(panelLightBlueNvg.getValue());
			instrumentsLightRed.setDoubleValue(instrumentsLightRedNvg.getValue());
			instrumentsLightGreen.setDoubleValue(instrumentsLightGreenNvg.getValue());
			instrumentsLightBlue.setDoubleValue(instrumentsLightBlueNvg.getValue());
			flightInstrumentsLightRed.setDoubleValue(flightInstrumentsLightRedNvg.getValue());
			flightInstrumentsLightGreen.setDoubleValue(flightInstrumentsLightGreenNvg.getValue());
			flightInstrumentsLightBlue.setDoubleValue(flightInstrumentsLightBlueNvg.getValue());
		} else {
			domeLightRed.setDoubleValue(domeLightRedUnaided.getValue());
			domeLightGreen.setDoubleValue(domeLightGreenUnaided.getValue());
			domeLightBlue.setDoubleValue(domeLightBlueUnaided.getValue());
			panelLightRed.setDoubleValue(panelLightRedUnaided.getValue());
			panelLightGreen.setDoubleValue(panelLightGreenUnaided.getValue());
			panelLightBlue.setDoubleValue(panelLightBlueUnaided.getValue());
			instrumentsLightRed.setDoubleValue(instrumentsLightRedUnaided.getValue());
			instrumentsLightGreen.setDoubleValue(instrumentsLightGreenUnaided.getValue());
			instrumentsLightBlue.setDoubleValue(instrumentsLightBlueUnaided.getValue());
			flightInstrumentsLightRed.setDoubleValue(flightInstrumentsLightRedUnaided.getValue());
			flightInstrumentsLightGreen.setDoubleValue(flightInstrumentsLightGreenUnaided.getValue());
			flightInstrumentsLightBlue.setDoubleValue(flightInstrumentsLightBlueUnaided.getValue());
		}
	}

	domeLightRed                 = props.globals.getNode('controls/lighting/dome/color/red', 1);
	domeLightRedNvg              = props.globals.getNode('sim/model/ch53e/materials/dome-light-color/nvg/red', 1);
	domeLightRedUnaided          = props.globals.getNode('sim/model/ch53e/materials/dome-light-color/unaided/red', 1);
	domeLightGreen               = props.globals.getNode('controls/lighting/dome/color/green', 1);
	domeLightGreenNvg            = props.globals.getNode('sim/model/ch53e/materials/dome-light-color/nvg/green', 1);
	domeLightGreenUnaided        = props.globals.getNode('sim/model/ch53e/materials/dome-light-color/unaided/green', 1);
	domeLightBlue                = props.globals.getNode('controls/lighting/dome/color/blue', 1);
	domeLightBlueNvg             = props.globals.getNode('sim/model/ch53e/materials/dome-light-color/nvg/blue', 1);
	domeLightBlueUnaided         = props.globals.getNode('sim/model/ch53e/materials/dome-light-color/unaided/blue', 1);

	panelLightRed                = props.globals.getNode('controls/lighting/panel/color/red', 1);
	panelLightRedNvg             = props.globals.getNode('sim/model/ch53e/materials/panel-light-color/nvg/red', 1);
	panelLightRedUnaided         = props.globals.getNode('sim/model/ch53e/materials/panel-light-color/unaided/red', 1);
	panelLightGreen              = props.globals.getNode('controls/lighting/panel/color/green', 1);
	panelLightGreenNvg           = props.globals.getNode('sim/model/ch53e/materials/panel-light-color/nvg/green', 1);
	panelLightGreenUnaided       = props.globals.getNode('sim/model/ch53e/materials/panel-light-color/unaided/green', 1);
	panelLightBlue               = props.globals.getNode('controls/lighting/panel/color/blue', 1);
	panelLightBlueNvg            = props.globals.getNode('sim/model/ch53e/materials/panel-light-color/nvg/blue', 1);
	panelLightBlueUnaided        = props.globals.getNode('sim/model/ch53e/materials/panel-light-color/unaided/blue', 1);

	instrumentsLightRed          = props.globals.getNode('controls/lighting/instruments/color/red', 1);
	instrumentsLightRedNvg       = props.globals.getNode('sim/model/ch53e/materials/instrument-light-color/nvg/red', 1);
	instrumentsLightRedUnaided   = props.globals.getNode('sim/model/ch53e/materials/instrument-light-color/unaided/red', 1);
	instrumentsLightGreen        = props.globals.getNode('controls/lighting/instruments/color/green', 1);
	instrumentsLightGreenNvg     = props.globals.getNode('sim/model/ch53e/materials/instrument-light-color/nvg/green', 1);
	instrumentsLightGreenUnaided = props.globals.getNode('sim/model/ch53e/materials/instrument-light-color/unaided/green', 1);
	instrumentsLightBlue         = props.globals.getNode('controls/lighting/instruments/color/blue', 1);
	instrumentsLightBlueNvg      = props.globals.getNode('sim/model/ch53e/materials/instrument-light-color/nvg/blue', 1);
	instrumentsLightBlueUnaided  = props.globals.getNode('sim/model/ch53e/materials/instrument-light-color/unaided/blue', 1);

	flightInstrumentsLightRed          = props.globals.getNode('controls/lighting/flight-instruments/color/red', 1);
	flightInstrumentsLightRedNvg       = props.globals.getNode('sim/model/ch53e/materials/flight-instrument-light-color/nvg/red', 1);
	flightInstrumentsLightRedUnaided   = props.globals.getNode('sim/model/ch53e/materials/flight-instrument-light-color/unaided/red', 1);
	flightInstrumentsLightGreen        = props.globals.getNode('controls/lighting/flight-instruments/color/green', 1);
	flightInstrumentsLightGreenNvg     = props.globals.getNode('sim/model/ch53e/materials/flight-instrument-light-color/nvg/green', 1);
	flightInstrumentsLightGreenUnaided = props.globals.getNode('sim/model/ch53e/materials/flight-instrument-light-color/unaided/green', 1);
	flightInstrumentsLightBlue         = props.globals.getNode('controls/lighting/flight-instruments/color/blue', 1);
	flightInstrumentsLightBlueNvg      = props.globals.getNode('sim/model/ch53e/materials/flight-instrument-light-color/nvg/blue', 1);
	flightInstrumentsLightBlueUnaided  = props.globals.getNode('sim/model/ch53e/materials/flight-instrument-light-color/unaided/blue', 1);

	nvgMode = props.globals.getNode('controls/lighting/nvg-mode', 1);

	adjustNvgMode();
	setlistener(nvgMode, adjustNvgMode);
}

################
#
# PCL animation.
#
################

PCL1 = nil;
PCL2 = nil;
PCL3 = nil;

PCLInit = func {
	PCL1 = aircraft.door.new('sim/model/ch53e/control-pos/pcl[0]', 2.0, 0);
	PCL2 = aircraft.door.new('sim/model/ch53e/control-pos/pcl[1]', 2.0, 0);
	PCL3 = aircraft.door.new('sim/model/ch53e/control-pos/pcl[2]', 2.0, 0);
}
settimer(PCLInit, 0);

################
#
# Rotor Brake
#
################

rotorBrakeSwitch = '';
rotorBrakeIndicatorPos = '';

animateRotorBrakeIndicator = func {
	if (rotorBrakeSwitch.getValue()) {
		interpolate('sim/model/ch53e/instrument-pos/rot-brake-ind-pos-norm', 1, 0.2);
	} else {
		interpolate('sim/model/ch53e/instrument-pos/rot-brake-ind-pos-norm', 0, 0.2);
	}
}
setlistener('controls/rotor/brake', animateRotorBrakeIndicator);

initRotorBrake = func {
	rotorBrakeSwitch = props.globals.getNode('controls/rotor/brake', 1);
	rotorBrakeIndicatorPos = props.globals.getNode('sim/model/ch53e/instrument-pos/rot-brake-ind-pos-norm', 1);
	animateRotorBrakeIndicator();
}
settimer(initRotorBrake, 0);

################
#
# Stick Position
#
# This will figure out where the stick is and convert it into a discrete low-res
# value. It then sets material properties that are used to run the material animation
# for the stick position indicator instrument. There is a private intensity property.
#
################

stickPosIntensity = nil;
stickPosTest = nil;

pollStickPos = func {
	var materials = '/sim/model/ch53e/materials/stick-pos/';
	var zones = ['HSPLeft.00', 'HSPRight.00', 'VSPFore.00', 'VSPAft.00'];

	# Helper function
	turnAllDiodesOff = func {
		foreach (color; ['red','green','blue']) {
			setprop(materials~'CenterStickPos'~'/emission/'~color, '0'); 
			foreach (zone; zones) {
				for (i=1;i<=8;i+=1) {
					setprop(materials~zone~i~'/emission/'~color, '0'); 
				}
			}
		}
	}

	if (getprop('/instrumentation/stick-position-indicator/serviceable') != 1) {
		# Just quit now
		turnAllDiodesOff();
		return;
	}

	# Figure out what colors we might need
	if (getprop('controls/lighting/nvg-mode') == 1) {
		led_color = 'green';
		led_intensity = (stickPosIntensity.getValue()*0.5+0.1);
	} else {
		led_color = 'red';
		led_intensity = (stickPosIntensity.getValue()*0.9+0.1);
	}

	if (stickPosTest.getValue() == 1) {
		# Test button is pressed, turn everything on
		setprop(materials~'CenterStickPos'~'/emission/'~led_color, led_intensity); 
		foreach (zone; zones) {
			for (i=1;i<=8;i+=1) {
				setprop(materials~zone~i~'/emission/'~led_color, led_intensity);
			}
		}
	} else {
		# Normal mode, turn everything off, then selectivly turn on the right diodes
		quant_pitch = int(((getprop('/controls/flight/elevator'))+1)/0.0606060606);
		quant_roll = int(((getprop('/controls/flight/aileron'))+1)/0.0606060606);

		turnAllDiodesOff();

		# Centering
		if ((quant_roll == 16) or (quant_pitch == 16)) {
			setprop(materials~'CenterStickPos'~'/emission/'~led_color, led_intensity); 
		}

		# Pitch
		if (quant_roll == 0) {
			setprop(materials~'HSPLeft.008'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 1) {
			setprop(materials~'HSPLeft.008'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPLeft.007'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 2) {
			setprop(materials~'HSPLeft.007'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 3) {
			setprop(materials~'HSPLeft.007'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPLeft.006'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 4) {
			setprop(materials~'HSPLeft.006'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 5) {
			setprop(materials~'HSPLeft.006'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPLeft.005'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 6) {
			setprop(materials~'HSPLeft.005'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 7) {
			setprop(materials~'HSPLeft.005'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPLeft.004'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 8) {
			setprop(materials~'HSPLeft.004'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 9) {
			setprop(materials~'HSPLeft.004'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPLeft.003'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 10) {
			setprop(materials~'HSPLeft.003'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 11) {
			setprop(materials~'HSPLeft.003'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPLeft.002'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 12) {
			setprop(materials~'HSPLeft.002'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 13) {
			setprop(materials~'HSPLeft.002'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPLeft.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 14) {
			setprop(materials~'HSPLeft.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 15) {
			setprop(materials~'HSPLeft.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 17) {
			setprop(materials~'HSPRight.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 18) {
			setprop(materials~'HSPRight.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 19) {
			setprop(materials~'HSPRight.001'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPRight.002'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 20) {
			setprop(materials~'HSPRight.002'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 21) {
			setprop(materials~'HSPRight.002'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPRight.003'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 22) {
			setprop(materials~'HSPRight.003'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 23) {
			setprop(materials~'HSPRight.003'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPRight.004'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 24) {
			setprop(materials~'HSPRight.004'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 25) {
			setprop(materials~'HSPRight.004'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPRight.005'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 26) {
			setprop(materials~'HSPRight.005'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 27) {
			setprop(materials~'HSPRight.005'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPRight.006'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 28) {
			setprop(materials~'HSPRight.006'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 29) {
			setprop(materials~'HSPRight.006'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPRight.007'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 30) {
			setprop(materials~'HSPRight.007'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll == 31) {
			setprop(materials~'HSPRight.007'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'HSPRight.008'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_roll >= 32) {
			setprop(materials~'HSPRight.008'~'/emission/'~led_color, led_intensity); 
		}

		# Roll
		if (quant_pitch == 0) {
			setprop(materials~'VSPAft.008'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 1) {
			setprop(materials~'VSPAft.008'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPAft.007'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 2) {
			setprop(materials~'VSPAft.007'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 3) {
			setprop(materials~'VSPAft.007'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPAft.006'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 4) {
			setprop(materials~'VSPAft.006'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 5) {
			setprop(materials~'VSPAft.006'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPAft.005'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 6) {
			setprop(materials~'VSPAft.005'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 7) {
			setprop(materials~'VSPAft.005'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPAft.004'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 8) {
			setprop(materials~'VSPAft.004'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 9) {
			setprop(materials~'VSPAft.004'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPAft.003'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 10) {
			setprop(materials~'VSPAft.003'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 11) {
			setprop(materials~'VSPAft.003'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPAft.002'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 12) {
			setprop(materials~'VSPAft.002'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 13) {
			setprop(materials~'VSPAft.002'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPAft.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 14) {
			setprop(materials~'VSPAft.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 15) {
			setprop(materials~'VSPAft.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 17) {
			setprop(materials~'VSPFore.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 18) {
			setprop(materials~'VSPFore.001'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 19) {
			setprop(materials~'VSPFore.001'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPFore.002'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 20) {
			setprop(materials~'VSPFore.002'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 21) {
			setprop(materials~'VSPFore.002'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPFore.003'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 22) {
			setprop(materials~'VSPFore.003'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 23) {
			setprop(materials~'VSPFore.003'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPFore.004'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 24) {
			setprop(materials~'VSPFore.004'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 25) {
			setprop(materials~'VSPFore.004'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPFore.005'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 26) {
			setprop(materials~'VSPFore.005'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 27) {
			setprop(materials~'VSPFore.005'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPFore.006'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 28) {
			setprop(materials~'VSPFore.006'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 29) {
			setprop(materials~'VSPFore.006'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPFore.007'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 30) {
			setprop(materials~'VSPFore.007'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch == 31) {
			setprop(materials~'VSPFore.007'~'/emission/'~led_color, led_intensity); 
			setprop(materials~'VSPFore.008'~'/emission/'~led_color, led_intensity); 
		} elsif (quant_pitch >= 32) {
			setprop(materials~'VSPFore.008'~'/emission/'~led_color, led_intensity); 
		}
	}
	settimer(pollStickPos, 0.1);
}

initStickPos = func {
	# Just to make sure that this property exists and has a sane value.
	stickPosTest = props.globals.getNode('sim/model/ch53e/control-input/stick-pos-test', 1);
	stickPosIntensity = props.globals.getNode('sim/model/ch53e/control-input/stick-pos-bright-norm', 1);
	# We assume that instruments-norm is a proper double. Someday this will cause trouble.
	if (stickPosIntensity.getType() != 'DOUBLE') {
		stickPosIntensity.setDoubleValue(getprop('controls/lighting/instruments-norm'));
	}
	settimer(pollStickPos, 0);
}
settimer(initStickPos, 0);

################
#
# TACAN
#
################
#TODO: on off from mode switch?
tacanChan1 = '';
tacanChan2 = '';
tacanChan3 = '';
tacanInit = func {
	tacanChan1 = props.globals.getNode('/instrumentation/tacan/frequencies/selected-channel[1]', 1);
	tacanChan2 = props.globals.getNode('/instrumentation/tacan/frequencies/selected-channel[2]', 1);
	tacanChan3 = props.globals.getNode('/instrumentation/tacan/frequencies/selected-channel[3]', 1);
}
settimer(tacanInit, 0);
adjustTacanChannel = func(increment) {
	tacanChannel = tacanChan1.getValue() * 100 + tacanChan2.getValue() * 10 + tacanChan3.getValue();
	# buisiness part
	tacanChannel += increment;
	if (tacanChannel > 126) {tacanChannel = 126;}
	if (tacanChannel < 0) {tacanChannel = 0;}
	# convert back
	# TODO make these interpolate, crossing boundary condition correctly
	tacanChannel = sprintf("%03.3d", tacanChannel);
	tacanChan1.setValue(chr(tacanChannel[0]));
	tacanChan2.setValue(chr(tacanChannel[1]));
	tacanChan3.setValue(chr(tacanChannel[2]));
}
adjustTacanMode = func {
	if (getprop('/instrumentation/tacan/frequencies/selected-channel[4]') == 'X') {
		interpolate('/instrumentation/tacan/mode', 0, 0.1);
	} elsif (getprop('/instrumentation/tacan/frequencies/selected-channel[4]') == 'Y') {
		interpolate('/instrumentation/tacan/mode', 1, 0.1);
	}
}
setlistener('/instrumentation/tacan/frequencies/selected-channel[4]', adjustTacanMode);
settimer(adjustTacanMode, 0);

################
#
# Hydraulic System
#
################

# TODO simulate as a system, with PSI
# TODO switch off based on 2B pri AC bus    26v/QUAD HYDR QTY breaker   set value to -.2
hydVol0 = '';
hydVol1 = '';
hydVol2 = '';
hydVol3 = '';
hydCap0 = '';
hydCap1 = '';
hydCap2 = '';
hydCap3 = '';
initHydVolDisp = func {
	hydVol0 = props.globals.getNode('consumables/hydraulic/tank[0]/volume-gal_us', 1);
	hydVol1 = props.globals.getNode('consumables/hydraulic/tank[1]/volume-gal_us', 1);
	hydVol2 = props.globals.getNode('consumables/hydraulic/tank[2]/volume-gal_us', 1);
	hydVol3 = props.globals.getNode('consumables/hydraulic/tank[3]/volume-gal_us', 1);
	hydCap0 = props.globals.getNode('consumables/hydraulic/tank[0]/capacity-gal_us', 1);
	hydCap1 = props.globals.getNode('consumables/hydraulic/tank[1]/capacity-gal_us', 1);
	hydCap2 = props.globals.getNode('consumables/hydraulic/tank[2]/capacity-gal_us', 1);
	hydCap3 = props.globals.getNode('consumables/hydraulic/tank[3]/capacity-gal_us', 1);
	adjustHydVolDisp0();
	adjustHydVolDisp1();
	adjustHydVolDisp2();
	adjustHydVolDisp3();
}
settimer(initHydVolDisp, 0);

adjustHydVolDisp0 = func {
	reading = hydVol0.getValue() / hydCap0.getValue();
	interpolate('instrumentation/hydraulic-quantity/tank[0]/vol-norm', reading, 0.25);
}
setlistener('consumables/hydraulic/tank[0]/volume-gal_us', adjustHydVolDisp0);

adjustHydVolDisp1 = func {
	reading = hydVol1.getValue()/hydCap1.getValue();
	interpolate('instrumentation/hydraulic-quantity/tank[1]/vol-norm', reading, 0.25);
}
setlistener('consumables/hydraulic/tank[1]/volume-gal_us', adjustHydVolDisp1);

adjustHydVolDisp2 = func {
	reading = hydVol2.getValue()/hydCap2.getValue();
	interpolate('instrumentation/hydraulic-quantity/tank[2]/vol-norm', reading, 0.25);
}
setlistener('consumables/hydraulic/tank[2]/volume-gal_us', adjustHydVolDisp2);

adjustHydVolDisp3 = func {
	reading = hydVol3.getValue()/hydCap3.getValue();
	interpolate('instrumentation/hydraulic-quantity/tank[3]/vol-norm', reading, 0.25);
}
setlistener('consumables/hydraulic/tank[3]/volume-gal_us', adjustHydVolDisp3);




# engines/rotor =====================================================
var state = props.globals.getNode("sim/model/ch53e/state");
var engine = props.globals.getNode("sim/model/ch53e/engine");
var rotor = props.globals.getNode("controls/engines/engine/magnetos");
var rotor_rpm = props.globals.getNode("rotors/main/rpm");
var torque = props.globals.getNode("rotors/gear/total-torque", 1);
var collective = props.globals.getNode("controls/engines/engine[0]/throttle");
var turbine = props.globals.getNode("sim/model/ch53e/turbine-rpm-pct", 1);
var torque_pct = props.globals.getNode("sim/model/ch53e/torque-pct", 1);
var stall = props.globals.getNode("rotors/main/stall", 1);
var stall_filtered = props.globals.getNode("rotors/main/stall-filtered", 1);
var torque_sound_filtered = props.globals.getNode("rotors/gear/torque-sound-filtered", 1);
var target_rel_rpm = props.globals.getNode("controls/rotor/reltarget", 1);
var max_rel_torque = props.globals.getNode("controls/rotor/maxreltorque", 1);
var cone = props.globals.getNode("rotors/main/cone-deg", 1);
var cone1 = props.globals.getNode("rotors/main/cone1-deg", 1);
var cone2 = props.globals.getNode("rotors/main/cone2-deg", 1);
var cone3 = props.globals.getNode("rotors/main/cone3-deg", 1);
var cone4 = props.globals.getNode("rotors/main/cone4-deg", 1);

# state:
# 0 off
# 1 engine startup
# 2 engine startup with small torque on rotor
# 3 engine idle
# 4 engine accel
# 5 engine sound loop

var update_state = func {
	var s = state.getValue();
	var new_state = arg[0];
	if (new_state == (s+1)) {
		state.setValue(new_state);
		if (new_state == (1)) {
			settimer(func { update_state(2) }, 2);
			interpolate(engine, 0.03, 0.1, 0.002, 0.3, 0.02, 0.1, 0.003, 0.7, 0.03, 0.1, 0.01, 0.7);
		} else {
			if (new_state == (2)) {
				settimer(func { update_state(3) }, 3);
				rotor.setValue(1);
				max_rel_torque.setValue(0.01);
				target_rel_rpm.setValue(0.002);
				interpolate(engine, 0.05, 0.2, 0.03, 1, 0.07, 0.1, 0.04, 0.9, 0.02, 0.5);
			} else { 
				if (new_state == (3)) {
					if (rotor_rpm.getValue() > 100) {
						#rotor is running at high rpm, so accel. engine faster
						max_rel_torque.setValue(1);
						target_rel_rpm.setValue(1.03);
						state.setValue(5);
						interpolate(engine, 1.03, 10);
					} else {
						settimer(func { update_state(4) }, 7);
						max_rel_torque.setValue(0.05);
						target_rel_rpm.setValue(0.02);
						interpolate(engine, 0.07, 0.1, 0.03, 0.25, 0.075, 0.2, 0.08, 1, 0.06,2);
					}
				} else {
					if (new_state == (4)) {
						settimer(func { update_state(5) }, 30);
						max_rel_torque.setValue(0.25);
						target_rel_rpm.setValue(0.8);
					} else {
							if (new_state == (5)) {
							max_rel_torque.setValue(1);
							target_rel_rpm.setValue(1.03);
						}
					}
				}
			}
		}
	}
}

var engines = func {
	if (props.globals.getNode("sim/crashed",1).getBoolValue()) {return; }
	var s = state.getValue();
	if (arg[0] == 1) {
		if (s == 0) {
			update_state(1);
		}
	} else {
		rotor.setValue(0);				# engines stopped
		state.setValue(0);
		interpolate(engine, 0, 4);
	}
}

var update_engine = func {
	if (state.getValue() > 3 ) {
		interpolate (engine,  clamp( rotor_rpm.getValue() / 235 ,
								0.05, target_rel_rpm.getValue() ), 0.25 );
	}
}

var update_rotor_cone_angle = func {
	r = rotor_rpm.getValue();
	var f = 1 - r / 100;
	f = clamp (f, 0.1 , 1);
	c = cone.getValue();
	cone1.setDoubleValue( f *c *0.40 + (1-f) * c );
	cone2.setDoubleValue( f *c *0.35);
	cone3.setDoubleValue( f *c *0.3);
	cone4.setDoubleValue( f *c *0.25);
}

# torquemeter
var torque_val = 0;
torque.setDoubleValue(0);

var update_torque = func(dt) {
	var f = dt / (0.2 + dt);
	torque_val = torque.getValue() * f + torque_val * (1 - f);
	torque_pct.setDoubleValue(torque_val / 5300);
}




# sound =============================================================

# stall sound
var stall_val = 0;
stall.setDoubleValue(0);

var update_stall = func(dt) {
	var s = stall.getValue();
	if (s < stall_val) {
		var f = dt / (0.3 + dt);
		stall_val = s * f + stall_val * (1 - f);
	} else {
		stall_val = s;
	}
	var c = collective.getValue();
	stall_filtered.setDoubleValue(stall_val + 0.006 * (1 - c));
}


# modify sound by torque
var torque_val = 0;

var update_torque_sound_filtered = func(dt) {
	var t = torque.getValue();
	t = clamp(t * 0.000001);
	t = t*0.25 + 0.75;
	var r = clamp(rotor_rpm.getValue()*0.02-1);
	torque_sound_filtered.setDoubleValue(t*r);
}





# skid slide sound
var Skid = {
	new : func(n) {
		var m = { parents : [Skid] };
		var soundN = props.globals.getNode("sim/sound", 1).getChild("slide", n, 1);
		var gearN = props.globals.getNode("gear", 1).getChild("gear", n, 1);

		m.compressionN = gearN.getNode("compression-norm", 1);
		m.rollspeedN = gearN.getNode("rollspeed-ms", 1);
		m.frictionN = gearN.getNode("ground-friction-factor", 1);
		m.wowN = gearN.getNode("wow", 1);
		m.volumeN = soundN.getNode("volume", 1);
		m.pitchN = soundN.getNode("pitch", 1);

		m.compressionN.setDoubleValue(0);
		m.rollspeedN.setDoubleValue(0);
		m.frictionN.setDoubleValue(0);
		m.volumeN.setDoubleValue(0);
		m.pitchN.setDoubleValue(0);
		m.wowN.setBoolValue(1);
		m.self = n;
		return m;
	},
	update : func {
		me.wowN.getBoolValue() or return;
		var rollspeed = abs(me.rollspeedN.getValue());
		me.pitchN.setDoubleValue(rollspeed * 0.6);

		var s = normatan(20 * rollspeed);
		var f = clamp((me.frictionN.getValue() - 0.5) * 2);
		var c = clamp(me.compressionN.getValue() * 2);
		me.volumeN.setDoubleValue(s * f * c * 2);
		#if (!me.self) {
		#	cprint("33;1", sprintf("S=%0.3f  F=%0.3f  C=%0.3f  >>  %0.3f", s, f, c, s * f * c));
		#}
	},
};

var skid = [];
for (var i = 0; i < 3; i += 1) {
	append(skid, Skid.new(i));
}

var update_slide = func {
	forindex (var i; skid) {
		skid[i].update();
	}
}



# crash handler =====================================================
#var load = nil;
var crash = func {
	if (arg[0]) {
		# crash
		setprop("rotors/main/rpm", 0);
		setprop("rotors/main/blade[0]/flap-deg", -60);
		setprop("rotors/main/blade[1]/flap-deg", -50);
		setprop("rotors/main/blade[2]/flap-deg", -40);
		setprop("rotors/main/blade[3]/flap-deg", -30);
		setprop("rotors/main/blade[0]/incidence-deg", -30);
		setprop("rotors/main/blade[1]/incidence-deg", -20);
		setprop("rotors/main/blade[2]/incidence-deg", -50);
		setprop("rotors/main/blade[3]/incidence-deg", -55);
		setprop("rotors/tail/rpm", 0);
		strobe_switch.setValue(0);
		beacon_switch.setValue(0);
		nav_light_switch.setValue(0);
		rotor.setValue(0);
		torque_pct.setValue(torque_val = 0);
		stall_filtered.setValue(stall_val = 0);
		state.setValue(0);

	} else {
		# uncrash (for replay)
		setprop("rotors/tail/rpm", 1500);
		setprop("rotors/main/rpm", 235);
		for (i = 0; i < 4; i += 1) {
			setprop("rotors/main/blade[" ~ i ~ "]/flap-deg", 0);
			setprop("rotors/main/blade[" ~ i ~ "]/incidence-deg", 0);
		}
		strobe_switch.setValue(1);
		beacon_switch.setValue(1);
		rotor.setValue(1);
		state.setValue(5);
	}
}




# "manual" rotor animation for flight data recorder replay ============
var rotor_step = props.globals.getNode("sim/model/ch53e/rotor-step-deg");
var blade1_pos = props.globals.getNode("rotors/main/blade[0]/position-deg", 1);
var blade2_pos = props.globals.getNode("rotors/main/blade[1]/position-deg", 1);
var blade3_pos = props.globals.getNode("rotors/main/blade[2]/position-deg", 1);
var blade4_pos = props.globals.getNode("rotors/main/blade[3]/position-deg", 1);
var rotorangle = 0;

var rotoranim_loop = func {
	i = rotor_step.getValue();
	if (i >= 0.0) {
		blade1_pos.setValue(rotorangle);
		blade2_pos.setValue(rotorangle + 90);
		blade3_pos.setValue(rotorangle + 180);
		blade4_pos.setValue(rotorangle + 270);
		rotorangle += i;
		settimer(rotoranim_loop, 0.1);
	}
}

var init_rotoranim = func {
	if (rotor_step.getValue() >= 0.0) {
		settimer(rotoranim_loop, 0.1);
	}
}










# view management ===================================================

var elapsedN = props.globals.getNode("/sim/time/elapsed-sec", 1);
var flap_mode = 0;
var down_time = 0;
controls.flapsDown = func(v) {
	if (!flap_mode) {
		if (v < 0) {
			down_time = elapsedN.getValue();
			flap_mode = 1;
			dynamic_view.lookat(
					5,     # heading left
					-20,   # pitch up
					0,     # roll right
					0.2,   # right
					0.6,   # up
					0.85,  # back
					0.2,   # time
					55,    # field of view
			);
		} elsif (v > 0) {
			flap_mode = 2;
			var p = "/sim/view/dynamic/enabled";
			setprop(p, !getprop(p));
		}

	} else {
		if (flap_mode == 1) {
			if (elapsedN.getValue() < down_time + 0.2) {
				return;
			}
			dynamic_view.resume();
		}
		flap_mode = 0;
	}
}


# register function that may set me.heading_offset, me.pitch_offset, me.roll_offset,
# me.x_offset, me.y_offset, me.z_offset, and me.fov_offset
#
dynamic_view.register(func {
	var lowspeed = 1 - normatan(me.speedN.getValue() / 50);
	var r = sin(me.roll) * cos(me.pitch);

	me.heading_offset =						# heading change due to
		(me.roll < 0 ? -50 : -30) * r * abs(r);			#    roll left/right

	me.pitch_offset =						# pitch change due to
		(me.pitch < 0 ? -50 : -50) * sin(me.pitch) * lowspeed	#    pitch down/up
		+ 15 * sin(me.roll) * sin(me.roll);			#    roll

	me.roll_offset =						# roll change due to
		-15 * r * lowspeed;					#    roll
});




# main() ============================================================
var delta_time = props.globals.getNode("/sim/time/delta-realtime-sec", 1);
var adf_rotation = props.globals.getNode("/instrumentation/adf/rotation-deg", 1);
var hi_heading = props.globals.getNode("/instrumentation/heading-indicator/indicated-heading-deg", 1);

var main_loop = func {
	# adf_rotation.setDoubleValue(hi_heading.getValue());

	var dt = delta_time.getValue();
	update_torque(dt);
	update_stall(dt);
	update_torque_sound_filtered(dt);
	update_slide();
	update_engine();
	update_rotor_cone_angle();
	settimer(main_loop, 0);
}


var crashed = 0;
var variant = nil;
var doors = nil;
var config_dialog = nil;


# initialization
setlistener("sim/position-finalized", func (is_done)
#setlistener("/sim/signals/fdm-initialized", func
{
    if (is_done.getValue())
    {
        usn_init();
        init_rotoranim();
        collective.setDoubleValue(1);

        setlistener("/sim/signals/reinit", func(n) {
                        n.getBoolValue() and return;
                        cprint("32;1", "reinit");
                        turbine_timer.stop();
                        collective.setDoubleValue(1);
                        if (variant != nil)
                            variant.scan();
                        crashed = 0;
                    });

        setlistener("sim/crashed", func(n) {
                        cprint("31;1", "crashed ", n.getValue());
                        turbine_timer.stop();
                        if (n.getBoolValue()) {
                            crash(crashed = 1);
                        }
                    });

        setlistener("/sim/freeze/replay-state", func(n) {
                        cprint("33;1", n.getValue() ? "replay" : "pause");
                        if (crashed) {
                            crash(!n.getBoolValue())
                                }
                    });

# the attitude indicator needs pressure
# settimer(func { setprop("engines/engine/rpm", 3000) }, 8);

        initPanelButtons();
        initNvgMode();
        cautionInit();
        print("ch53e.nas initialized");
        main_loop();
    }
});
