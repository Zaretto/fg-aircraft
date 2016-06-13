########
#
# ADI
#
########

initAdi = func {

	var adiAttState = props.globals.getNode('sim/model/jrb-usn/ATTFlag-state', 1);
	adiAttState.setIntValue(0);
	# 0 Off
	# 1 On, timer running, do nothing
	# 2 On, time up
	# 3 On, insufficient spin

	var adiServiceable = props.globals.getNode('instrumentation/attitude-indicator/serviceable', 1);
	adiServiceable.setBoolValue(1);

	var adiSpin = props.globals.getNode('instrumentation/attitude-indicator/spin', 1);
	adiSpin.setDoubleValue(0);

	var adiFlagPosNorm = props.globals.getNode('sim/model/jrb-usn/ATTFlag-pos-norm', 1);
	adiFlagPosNorm.setDoubleValue(0);

	# TODO add a test for the elecrical bus here
	adiIsPowered = func {
		if (adiServiceable.getValue()) {
			return(1);
		} else {
			return(0);
		}
	}

	adiIsSpun = func {
		if (adiSpin.getValue() > 0.85) {
			return(1);
		} else {
			return(0);
		}
	}

	adiWatchAttState = func {
		if (adiIsPowered()){
			if (adiAttState.getValue() == 0 ) {
				# Start Timer only if it has not yet been started
				adiAttState.setIntValue(1);
				settimer( func { adiAttState.setIntValue(2) }, 60);
			} elsif (adiAttState.getValue() == 2) {
				if (!adiIsSpun()) {
					adiAttState.setIntValue(3);
				}
			} elsif (adiAttState.getValue() == 3) {
				if (adiIsSpun()) {
					adiAttState.setIntValue(2);
				}
			}
		} else {
			# Reset timer on pawer loss
			if (adiAttState.getValue() != 0) {
				adiAttState.setIntValue(0);
			}
		}
		settimer(adiWatchAttState, 1);
	}
	settimer(adiWatchAttState, 0);

	adiAnimateAttFlag = func {
		var target = 1;
		if (adiAttState.getValue() == 2) {
			target = 0;
		}
		var delta = (0.15 * abs(target - adiFlagPosNorm.getValue()));
		interpolate(adiFlagPosNorm, target, delta);
	}
	setlistener(adiAttState, adiAnimateAttFlag);
}


########
#
# Gyro Compass
#
########

	var gyroNeedle1 = props.globals.getNode('sim/model/jrb-usn/gyro-needle-heading[0]', 1);
	var gyroNeedle2 = props.globals.getNode('sim/model/jrb-usn/gyro-needle-heading[1]', 1);
	var source1 = props.globals.getNode('sim/model/jrb-usn/gyro-needle-source[0]', 1);
	var source2 = props.globals.getNode('sim/model/jrb-usn/gyro-needle-source[1]', 1);
	var nav1Heading = props.globals.getNode('instrumentation/nav[0]/heading-deg');
	var nav2Heading = props.globals.getNode('instrumentation/nav[1]/heading-deg');
	var adfHeading = props.globals.getNode('instrumentation/adf/indicated-bearing-deg');
	var tacanHeading = props.globals.getNode('instrumentation/tacan/indicated-bearing-true-deg');

    initGyroCompass = func
    {
# TODO
# gpsHeading = props.globals.getNode('');

        foreach (node; [source1, source2]){
            if (node.getValue() == nil) {
                node.setValue('');
            }
        }
        foreach (node; [gyroNeedle1, gyroNeedle2, source1, source2, nav1Heading, nav2Heading, adfHeading, tacanHeading]){
            if (node.getValue() == nil) {
                node.setValue(0);
            }
        }

        foreach (node; [gyroNeedle1, gyroNeedle2, nav1Heading, nav2Heading, adfHeading, tacanHeading]){
            if (node.getValue() == nil) {
                node.setDoubleValue(0);
            }
        }

    };

    updateGyroNeedles = func
    {
        if (source1.getValue() == 'nav1') {
            gyroNeedle1.setDoubleValue(nav1Heading.getValue());
        } elsif (source1.getValue() == 'nav2') {
            gyroNeedle1.setDoubleValue(nav2Heading.getValue());
        } elsif (source1.getValue(adfHeading.getValue()) == 'adf') {
            gyroNeedle1.setDoubleValue();
        } elsif (source1.getValue(tacanHeading.getValue()) == 'tacan') {
            gyroNeedle1.setDoubleValue();
        }

        if (source2.getValue() == 'nav1') {
            gyroNeedle2.setDoubleValue(nav1Heading.getValue());
        } elsif (source2.getValue() == 'nav2') {
            gyroNeedle2.setDoubleValue(nav2Heading.getValue());
        } elsif (source2.getValue(adfHeading.getValue()) == 'adf') {
            gyroNeedle2.setDoubleValue();
        } elsif (source2.getValue(tacanHeading.getValue()) == 'tacan') {
            gyroNeedle2.setDoubleValue();
        }
    }

################
#
# ID-249 (Tacan course deviation indicator)
#
################

initId249 = func {
   var deviationFlagPos = props.globals.getNode('sim/model/jrb-usn/id-249-deviation-flag-pos-norm', 1);
   var tacanInRange = props.globals.getNode('instrumentation/tacan/in-range', 1);

	var markerBeacon = props.globals.getNode('instrumentation/marker-beacon/middle', 1);
	var markerSwitch = props.globals.getNode('sim/model/jrb-usn/id-249-blink', 1);
	var markerLightState = markerSwitch.getNode('state', 1);
	var markerRed = props.globals.getNode('sim/model/jrb-usn/material/id-249-emis-red', 1);
	var markerGreen = props.globals.getNode('sim/model/jrb-usn/material/id-249-emis-green', 1);
	var markerBlue = props.globals.getNode('sim/model/jrb-usn/material/id-249-emis-blue', 1);
	
	# These are supplied by interior-lights.nas, reflected light from various sources in the cockpit
	var panelRed = props.globals.getNode('controls/lighting/panel/emission/red', 1);
	var panelGreen = props.globals.getNode('controls/lighting/panel/emission/green', 1);
	var panelBlue = props.globals.getNode('controls/lighting/panel/emission/blue', 1);

	var pattern = [0.33,0.22];
	var markerBlinker = aircraft.light.new(markerSwitch, pattern);

	foreach (node; [tacanInRange, markerBeacon, markerSwitch, markerLightState]){
		if (node.getValue() == nil) {
			node.setBoolValue(0);
		}
	}

	foreach (node; [deviationFlagPos, markerRed, markerGreen, markerBlue, panelRed, panelGreen, panelBlue]){
		if (node.getValue() == nil) {
			node.setDoubleValue(0);
		}
	}

	# TODO make a door object
   animateDeviationFlag = func {
      if (tacanInRange.getValue()) {
         interpolate(deviationFlagPos, 1, 0.25);
      } else {
         interpolate(deviationFlagPos, 0, 0.25);
      }
   }

	blinkMarkerLight = func {
		if (markerBeacon.getValue()) {
			markerBlinker.switch(1);
		} else {
			markerBlinker.switch(0);
		}
	}

	animateMarkerLight = func {
		if (markerLightState.getValue()) {
			markerRed.setDoubleValue(1);
			markerGreen.setDoubleValue(1);
			markerBlue.setDoubleValue(1);
		} else {
			markerRed.setDoubleValue(panelRed.getValue());
			markerGreen.setDoubleValue(panelGreen.getValue());
			markerBlue.setDoubleValue(panelBlue.getValue());
		}
	}

   setlistener(tacanInRange, animateDeviationFlag);
	# FIXME HERE
	setlistener(markerBeacon,     blinkMarkerLight);
	setlistener(panelRed,         animateMarkerLight);
	setlistener(panelGreen,       animateMarkerLight);
	setlistener(panelBlue,        animateMarkerLight);
	setlistener(markerLightState, animateMarkerLight);

	animateDeviationFlag();
}

########
#
# Radar Altimeter
#
# watchen das blinkenlights
# TODO turn it off when the power is off.
#
########

initRadAlt = func {
	var alt = props.globals.getNode('position/gear-agl-ft', 1);
	var dh = props.globals.getNode('sim/model/jrb-usn/radar-altitude-decision-height', 1);
	var animProp = props.globals.getNode('sim/model/jrb-usn/radar-altitude-warning', 1);
	var state = animProp.getNode('state', 1);

	# These are supplied by interior-lights.nas, reflected light from various sources
	# in the cockpit
	var panelRed = props.globals.getNode('controls/lighting/panel/emission/red', 1);
	var panelGreen = props.globals.getNode('controls/lighting/panel/emission/green', 1);
	var panelBlue = props.globals.getNode('controls/lighting/panel/emission/blue', 1);

	# These are what the material animation is going to use
	var warnRed = animProp.getNode('emission/red', 1);
	var warnGreen = animProp.getNode('emission/green', 1);
	var warnBlue = animProp.getNode('emission/blue', 1);
	
	var pattern = [0.25,0.25,   0.25,0.25,   0.25,0.75];
	var light = aircraft.light.new(animProp, 0.75, pattern);

	foreach (node; [state]) {
		if (node.getValue() == nil) {
			node.setBoolValue(0);
		}
	}

	foreach (node; [dh, animProp]) {
		if (node.getValue() == nil) {
			node.setIntValue(0);
		}
	}

	foreach (node; [alt, panelRed, panelGreen, panelBlue, warnRed, warnGreen, warnBlue]) {
		if (node.getValue() == nil) {
			node.setDoubleValue(0);
		}
	}

	watchRadAlt = func {
		if (alt.getValue() < dh.getValue()) {
			light.switch(1);
		} else {
			light.switch(0);
		}
		settimer(watchRadAlt, 0.1);
	}

	animateRadAlt = func {
		warnGreen.setDoubleValue(panelGreen.getValue());
		warnBlue.setDoubleValue(panelBlue.getValue());
		if (state.getValue()) {
			warnRed.setDoubleValue(1);
		} else {
			warnRed.setDoubleValue(panelRed.getValue());
		}
	}

	setlistener(warnRed, animateRadAlt);
	setlistener(warnGreen, animateRadAlt);
	setlistener(warnBlue, animateRadAlt);
	setlistener(state, animateRadAlt);
	watchRadAlt();
}

usn_init = func {
	# Some globally used properties

	# These are supplied by interior-lights.nas, reflected light from various sources
	# in the cockpit
	# var panelRed = props.globals.getNode('controls/lighting/panel/emission/red', 1);
	# var panelGreen = props.globals.getNode('controls/lighting/panel/emission/green', 1);
	# var panelBlue = props.globals.getNode('controls/lighting/panel/emission/blue', 1);

	# Comment out instruments that you are not using here.
	initAdi();
	initGyroCompass();
	initId249();
	initRadAlt();

	print("jrb-usn.nas initialized");
}

adjustATTFlag = func {
	if (getprop('instrumentation/attitude-indicator/serviceable') and (getprop('instrumentation/attitude-indicator/spin') > 0.99)) {
		interpolate('sim/model/jrb-usn-adi/ATTFlag-pos-norm', 1, 0.25);
	} else {
		interpolate('sim/model/jrb-usn-adi/ATTFlag-pos-norm', 0, 0.25);
	}
}
setlistener('instrumentation/attitude-indicator/serviceable', adjustATTFlag);
setlistener('instrumentation/attitude-indicator/spin', adjustATTFlag);
