
# List of all the caution light object names
# Generated using ac3d-scan and grepping for 'Warn'
lights = [
'Warn.1antiice',   'Warn.1engbst',    'Warn.1engfltr',  'Warn.1engoph',     'Warn.1engoplow',
'Warn.1engqtylow', 'Warn.1feullow',   'Warn.1gen',      'Warn.1igvice',     'Warn.1ngbhot',
'Warn.1ngbop',     'Warn.1rec',       'Warn.1stgmr',    'Warn.1stgpr',      'Warn.1stgsb',
'Warn.1stqty',     'Warn.2engbst',    'Warn.2engfltr',  'Warn.2engoh',      'Warn.2engop',
'Warn.2engoph',    'Warn.2engqtylow', 'Warn.2fuellow',  'Warn.2gen',        'Warn.2ptflt',
'Warn.2rect',      'Warn.2stgmrsb',   'Warn.2stgoh',    'Warn.2stgpmr',     'Warn.2stgqty',
'Warn.2stgtrsb',   'Warn.3antiice',   'Warn.3engbst',   'Warn.3engfltr',    'Warn.3engop',
'Warn.3engoph',    'Warn.3engqtylow', 'Warn.3fuellow',  'Warn.3gen',        'Warn.3ngbhot',
'Warn.3ngbop',     'Warn.acchot',     'Warn.accpres',   'Warn.afcs',        'Warn.afcsdeg',
'Warn.afthook',    'Warn.alt',        'Warn.app',       'Warn.autorel',     'Warn.bim',
'Warn.blade',      'Warn.blank',      'Warn.blank.001', 'Warn.blank.002',   'Warn.blank.003',
'Warn.blank.004',  'Warn.blank.005',  'Warn.blank.006', 'Warn.blank.007',   'Warn.blank.008',
'Warn.blank.009',  'Warn.blank.010',  'Warn.blank.011', 'Warn.blank.012',   'Warn.blank.013',
'Warn.blank.014',  'Warn.cghook',     'Warn.chip',      'Warn.com1',        'Warn.comp',
'Warn.dopp',       'Warn.eaps',       'Warn.eapshp',    'Warn.engtqe',      'Warn.extpwr',
'Warn.fwdhook',    'Warn.gpwsalert',  'Warn.gpwsinop',  'Warn.gpwstacinhb', 'Warn.headpos',
'Warn.ice',        'Warn.iff',        'Warn.igbop',     'Warn.igv2ice',     'Warn.igv3ice',
'Warn.isol',       'Warn.mgbhot',     'Warn.mgblube',   'Warn.mgbop',       'Warn.park',
'Warn.purge',      'Warn.radalt1',    'Warn.radalt2',   'Warn.ramp',        'Warn.rotbrk',
'Warn.rotbrkpr',   'Warn.rotlock',    'Warn.sphook',    'Warn.start',       'Warn.tgbop',
'Warn.u1hot',      'Warn.u1press',    'Warn.u1qtytr',   'Warn.u2hot',       'Warn.u2press',
'Warn.u2pump',     'Warn.u2qty',      'Warn.utrpres'];

# These will be property nodes, anchor them in this scope
nvgMode = nil;
testButton = nil;
intensityNorm = nil;

nvgRed = nil;
nvgGreen = nil;
nvgBlue = nil;

unaidedRed = nil;
unaidedGreen = nil;
unaidedBlue = nil;

panelRed = nil;
panelGreen = nil;
panelBlue = nil;

# And a hash of nodes
lightNodes = {};

##### Helper functions

#
# Update one light to make its material reflect its status
#
updateLight = func(targetLight) {
if (!caution_initialized)
{
return;
}
	redNode = targetLight.getNode('emission/red');
	greenNode = targetLight.getNode('emission/green');
	blueNode = targetLight.getNode('emission/blue');
	status = targetLight.getNode('status');
	# FIXME, don't change the values if it will make the lights *dimmer* when they are on.
	# or better yet, add the two values and clip to 1
	if (status.getValue()) {
		if(nvgMode.getValue()) {
			var redValue = nvgRed.getValue() * intensityNorm.getValue() * 0.9 + 0.1;
			var greenValue = nvgGreen.getValue() * intensityNorm.getValue() * 0.9 + 0.1;
			var blueValue = nvgBlue.getValue() * intensityNorm.getValue() * 0.9 + 0.1;
			redNode.setDoubleValue(redValue);
			greenNode.setDoubleValue(greenValue);
			blueNode.setDoubleValue(blueValue);
		} else {
			redValue = unaidedRed.getValue() * intensityNorm.getValue() * 0.9 + 0.1;
			greenValue = unaidedGreen.getValue() * intensityNorm.getValue() * 0.9 + 0.1;
			blueValue = unaidedBlue.getValue() * intensityNorm.getValue() * 0.9 + 0.1;
			redNode.setDoubleValue(redValue);
			greenNode.setDoubleValue(greenValue);
			blueNode.setDoubleValue(blueValue);
		}
	} else {
		redNode.setDoubleValue(panelRed.getValue() * 0.4);
		greenNode.setDoubleValue(panelGreen.getValue() * 0.4);
		blueNode.setDoubleValue(panelBlue.getValue() * 0.4);
	}
}

#
# Runs updateLight() an all light nodes
#
updateAllLights = func(lights) {
	foreach(light; keys(lights)) {
		updateLight(lights[light]);
	}
}

#
# Turn off an individual light
#
turnOff = func(targetLight) {
	var status = targetLight.getNode('status');
	status.setBoolValue(0);
	updateLight(targetLight);
}

#
# Turn on an individual light
#
turnOn = func(targetLight) {
	var status = targetLight.getNode('status');
	status.setBoolValue(1);
	updateLight(targetLight);
}
var caution_initialized = 0;

#
# Initialize property nodes
#
cautionInit = func {
	# dull green for goggles, red for mark I eyeballs
	nvgMode = props.globals.getNode('controls/lighting/nvg-mode', 1);
	nvgRed = props.globals.getNode('sim/model/ch53e/materials/instrument-light-color/nvg/red');
	nvgGreen = props.globals.getNode('sim/model/ch53e/materials/instrument-light-color/nvg/green');
	nvgBlue = props.globals.getNode('sim/model/ch53e/materials/instrument-light-color/nvg/blue');
	unaidedRed = props.globals.getNode('sim/model/ch53e/materials/instrument-light-color/unaided/red');
	unaidedGreen = props.globals.getNode('sim/model/ch53e/materials/instrument-light-color/unaided/green');
	unaidedBlue = props.globals.getNode('sim/model/ch53e/materials/instrument-light-color/unaided/blue');
	panelRed = props.globals.getNode('controls/lighting/panel/emission/red');
	panelGreen = props.globals.getNode('controls/lighting/panel/emission/green');
	panelBlue = props.globals.getNode('controls/lighting/panel/emission/blue');
	intensityNorm = props.globals.getNode('sim/model/ch53e/control-input/caution-bright-norm', 1);
	# If this is not already a sane value, steal one from the panel light brightness property
	if (intensityNorm.getType() != 'DOUBLE') {
		intensityNorm.setDoubleValue(getprop('controls/lighting/instruments-norm'));
	}
	testButton =  props.globals.getNode('sim/model/ch53e/control-input/caution-test', 1);
	testButton.setBoolValue(0);
	# Make a hash of all the lights in lights[] and then make sure they are populated.
	foreach(light; lights) {
		lightNodes[light] = props.globals.getNode('sim/model/ch53e/materials/warn/'~light, 1);
		lightNodes[light].getNode('emission/red', 1);
		lightNodes[light].getNode('emission/green', 1);
		lightNodes[light].getNode('emission/blue', 1);
		lightNodes[light].getNode('status', 1);
		turnOff(lightNodes[light]);
	}
	setlistener('controls/lighting/panel/emission', func{updateAllLights(lightNodes)});
    setlistener('sim/model/ch53e/control-input/caution-test', testCaution);
print('ch53e-caution Initialization completed');
caution_initialized=1;
}

#
# Watch test button and turn on/off all lights when pressed
#
testCaution = func {
	foreach(light; keys(lightNodes)) {
		if(testButton.getValue() == 1) {
			turnOn(lightNodes[light]);
		} else {
			turnOff(lightNodes[light]);
		}
	}
}

print('ch53e-caution.nas initialized');
