# The point of this file is to create a bunch of properties to drive the emission
# of various objects in the cockpit by the material animation. It takes the norm
# values for the three light switches and mixes them with each other and (if
# defined) RGB values for those lights. These should be put in:
# controls/lighting/dome/color/red
# ...
# controls/lighting/instruments/color/blue
#
# The  are affected by all three lights, the panel by the panel and dome
# lights, and the dome lights by nothing else. There are weighted values defining how much
# one light switch affects each group of objects.
#
# Values are output to:
# controls/lighting/dome/emission/red
# ...
# controls/lighting/instruments/emission/blue
#
# copyright 2006 Josh Babcock jbabcock (at) atlantech (dot) net
#
# TODO
# Make a system with a materials.showdialog() to make it easier to play with colors.

# TODO, get this from a property
shadowFactor = 0.7;

# Light color settings (input)

panelRed = nil;
panelGreen = nil;
panelBlue = nil;
panelNorm = nil;

instrumentsRed = nil;
instrumentsGreen = nil;
instrumentsBlue = nil;
instrumentsNorm = nil;
# instrumentsInput = [instrumentsRed, instrumentsGreen, instrumentsBlue, instrumentsNorm];

flightInstrumentsRed = nil;
flightInstrumentsGreen = nil;
flightInstrumentsBlue = nil;
flightInstrumentsNorm = nil;
# flightInstrumentsInput = [flightInstrumentsRed, flightInstrumentsGreen, flightInstrumentsBlue, flightInstrumentsNorm];

domeRed = nil;
domeGreen = nil;
domeBlue = nil;
domeNorm = nil;

# Actual emissive values for these models (output)

panelEmisRed = nil;
panelEmisGreen = nil;
panelEmisBlue = nil;

instrumentsEmisRed = nil;
instrumentsEmisGreen = nil;
instrumentsEmisBlue = nil;
# instrumentsOutput = [instrumentsEmisRed, instrumentsEmisGreen, instrumentsEmisBlue];

flightInstrumentsEmisRed = nil;
flightInstrumentsEmisGreen = nil;
flightInstrumentsEmisBlue = nil;
# flightInstrumentsOutput = [flightInstrumentsEmisRed, flightInstrumentsEmisGreen, flightInstrumentsEmisBlue];

domeEmisRed = nil;
domeEmisGreen = nil;
domeEmisBlue = nil;

# Utility functions

#
# Return the highest of the three values
#
maxChannel = func (r, g, b) {
	if ( r > g ) {
		max = r;
	} else {
		max = g;
	}
	if ( max > b ) {
		return(max);
	} else {
		return(b);
	}
}

# Functions to figure out what the light will actually look like after all three sources are mixed.
# The colors get averaged, the norm values get added with weights then clipped to 1.

adjustDomeColor = func {
	# Only the dome light shines on this stuff
	var red = domeRed.getValue();
	var green = domeGreen.getValue();
	var blue = domeBlue.getValue();

	var norm = domeNorm.getValue();

	domeEmisRed.setDoubleValue(red * norm);
	domeEmisGreen.setDoubleValue(green * norm);
	domeEmisBlue.setDoubleValue(blue * norm);
}

adjustPanelColor = func {
	setprop('controls/lighting/panel-eff-norm', getprop('controls/lighting/panel-norm'));

	# Mix multiple light sources
	var red   = ((
		  (panelRed.getValue() * panelNorm.getValue())
		+ (domeRed.getValue()  * domeNorm.getValue() )
		)/2);
	var green = ((
		  (panelGreen.getValue() * panelNorm.getValue())
		+ (domeGreen.getValue()  * domeNorm.getValue() )
		)/2);
	var blue  = ((
		  (panelBlue.getValue() * panelNorm.getValue())
		+ (domeBlue.getValue()  * domeNorm.getValue() )
		)/2);

	# Normalize the color down if it is greater than one
	maxColor = maxChannel(red, green, blue);
	if (maxColor > 1) {
		red = red / maxColor;
		green = green / maxColor;
		blue = blue / maxColor;
	}

	panelEmisRed.setDoubleValue(red);
	panelEmisGreen.setDoubleValue(green);
	panelEmisBlue.setDoubleValue(blue);
}

adjustInstrumentColor = func {
	# This time, we bias the instruments
	var red   = ((
		  (panelRed.getValue()       * panelNorm.getValue() * shadowFactor) 
		+ (domeRed.getValue()        * domeNorm.getValue()  * shadowFactor)
		+ (instrumentsRed.getValue() * instrumentsNorm.getValue()         )
		)/3);
	var green = ((
		  (panelGreen.getValue()       * panelNorm.getValue() * shadowFactor)
		+ (domeGreen.getValue()        * domeNorm.getValue()  * shadowFactor)
		+ (instrumentsGreen.getValue() * instrumentsNorm.getValue()         )
		)/3);
	var blue  = ((
		  (panelBlue.getValue()       * panelNorm.getValue() * shadowFactor)
		+ (domeBlue.getValue()        * domeNorm.getValue()  * shadowFactor)
		+ (instrumentsBlue.getValue() * instrumentsNorm.getValue()         )
		)/3);

	# Normalize the color down if it is greater than one
	maxColor = maxChannel(red, green, blue);
	if (maxColor > 1) {
		red = red / maxColor;
		green = green / maxColor;
		blue = blue / maxColor;
	}

	instrumentsEmisRed.setDoubleValue(red);
	instrumentsEmisGreen.setDoubleValue(green);
	instrumentsEmisBlue.setDoubleValue(blue);

	# And now the flight instruments
	var red   = ((
		  (panelRed.getValue()             * panelNorm.getValue() * shadowFactor) 
		+ (domeRed.getValue()              * domeNorm.getValue()  * shadowFactor)
		+ (flightInstrumentsRed.getValue() * flightInstrumentsNorm.getValue()   )
		)/3);
	var green = ((
		  (panelGreen.getValue()             * panelNorm.getValue() * shadowFactor)
		+ (domeGreen.getValue()              * domeNorm.getValue()  * shadowFactor)
		+ (flightInstrumentsGreen.getValue() * flightInstrumentsNorm.getValue()   )
		)/3);
	var blue  = ((
		  (panelBlue.getValue()             * panelNorm.getValue() * shadowFactor)
		+ (domeBlue.getValue()              * domeNorm.getValue()  * shadowFactor)
		+ (flightInstrumentsBlue.getValue() * flightInstrumentsNorm.getValue()   )
		)/3);

	# Normalize the color down if it is greater than one
	maxColor = maxChannel(red, green, blue);
	if (maxColor > 1) {
		red = red / maxColor;
		green = green / maxColor;
		blue = blue / maxColor;
	}

	flightInstrumentsEmisRed.setDoubleValue(red);
	flightInstrumentsEmisGreen.setDoubleValue(green);
	flightInstrumentsEmisBlue.setDoubleValue(blue);
}

init = func {
	domeRed = props.globals.getNode('controls/lighting/dome/color/red', 1);
	domeGreen = props.globals.getNode('controls/lighting/dome/color/green', 1);
	domeBlue = props.globals.getNode('controls/lighting/dome/color/blue', 1);
	domeNorm = props.globals.getNode('controls/lighting/dome-norm', 1);
	
	panelRed = props.globals.getNode('controls/lighting/panel/color/red', 1);
	panelGreen = props.globals.getNode('controls/lighting/panel/color/green', 1);
	panelBlue = props.globals.getNode('controls/lighting/panel/color/blue', 1);
	panelNorm = props.globals.getNode('controls/lighting/panel-norm', 1);

	instrumentsRed = props.globals.getNode('controls/lighting/instruments/color/red', 1);
	instrumentsGreen = props.globals.getNode('controls/lighting/instruments/color/green', 1);
	instrumentsBlue = props.globals.getNode('controls/lighting/instruments/color/blue', 1);
	instrumentsNorm = props.globals.getNode('controls/lighting/instruments-norm', 1);
	
	flightInstrumentsRed = props.globals.getNode('controls/lighting/flight-instruments/color/red', 1);
	flightInstrumentsGreen = props.globals.getNode('controls/lighting/flight-instruments/color/green', 1);
	flightInstrumentsBlue = props.globals.getNode('controls/lighting/flight-instruments/color/blue', 1);
	flightInstrumentsNorm = props.globals.getNode('controls/lighting/flight-instruments-norm', 1);
	
	domeEmisRed = props.globals.getNode('controls/lighting/dome/emission/red', 1);
	domeEmisGreen = props.globals.getNode('controls/lighting/dome/emission/green', 1);
	domeEmisBlue = props.globals.getNode('controls/lighting/dome/emission/blue', 1);

	panelEmisRed = props.globals.getNode('controls/lighting/panel/emission/red', 1);
	panelEmisGreen = props.globals.getNode('controls/lighting/panel/emission/green', 1);
	panelEmisBlue = props.globals.getNode('controls/lighting/panel/emission/blue', 1);

	instrumentsEmisRed = props.globals.getNode('controls/lighting/instruments/emission/red', 1);
	instrumentsEmisGreen = props.globals.getNode('controls/lighting/instruments/emission/green', 1);
	instrumentsEmisBlue = props.globals.getNode('controls/lighting/instruments/emission/blue', 1);

	flightInstrumentsEmisRed = props.globals.getNode('controls/lighting/flight-instruments/emission/red', 1);
	flightInstrumentsEmisGreen = props.globals.getNode('controls/lighting/flight-instruments/emission/green', 1);
	flightInstrumentsEmisBlue = props.globals.getNode('controls/lighting/flight-instruments/emission/blue', 1);

	if (domeNorm.getValue() == nil) {
		domeNorm.setDoubleValue(0);
	}

	if (panelNorm.getValue() == nil) {
		panelNorm.setDoubleValue(0);
    	setprop('controls/lighting/panel-eff-norm', getprop('controls/lighting/panel-norm'));
	}

	if (instrumentsNorm.getValue() == nil) {
		instrumentsNorm.setDoubleValue(0);
	}

	if (flightInstrumentsNorm.getValue() == nil) {
		flightInstrumentsNorm.setDoubleValue(0);
	}

	# Use an obviously wrong color for the default value.

	if (domeRed.getValue() == nil) {
		domeRed.setDoubleValue(1);
		domeGreen.setDoubleValue(0);
		domeBlue.setDoubleValue(1);
	}

	if (panelRed.getValue() == nil) {
		panelRed.setDoubleValue(1);
		panelGreen.setDoubleValue(0);
		panelBlue.setDoubleValue(1);
	}

	if (instrumentsRed.getValue() == nil) {
		instrumentsRed.setDoubleValue(1);
		instrumentsGreen.setDoubleValue(0);
		instrumentsBlue.setDoubleValue(1);
	}

	if (flightInstrumentsRed.getValue() == nil) {
		flightInstrumentsRed.setDoubleValue(1);
		flightInstrumentsGreen.setDoubleValue(0);
		flightInstrumentsBlue.setDoubleValue(1);
	}

	adjustDomeColor();
	adjustPanelColor();
	adjustInstrumentColor();

	setlistener(domeNorm, adjustDomeColor);
	setlistener(domeRed, adjustDomeColor);
	setlistener(domeGreen, adjustDomeColor);
	setlistener(domeBlue, adjustDomeColor);

	setlistener(panelNorm, adjustPanelColor);
	setlistener(panelRed, adjustPanelColor);
	setlistener(panelGreen, adjustPanelColor);
	setlistener(panelBlue, adjustPanelColor);
	setlistener(domeNorm, adjustPanelColor);
	setlistener(domeRed, adjustPanelColor);
	setlistener(domeGreen, adjustPanelColor);
	setlistener(domeBlue, adjustPanelColor);

	setlistener(instrumentsNorm, adjustInstrumentColor);
	setlistener(instrumentsRed, adjustInstrumentColor);
	setlistener(instrumentsGreen, adjustInstrumentColor);
	setlistener(instrumentsBlue, adjustInstrumentColor);
	setlistener(flightInstrumentsNorm, adjustInstrumentColor);
	setlistener(flightInstrumentsRed, adjustInstrumentColor);
	setlistener(flightInstrumentsGreen, adjustInstrumentColor);
	setlistener(flightInstrumentsBlue, adjustInstrumentColor);
	setlistener(panelNorm, adjustInstrumentColor);
	setlistener(panelRed, adjustInstrumentColor);
	setlistener(panelGreen, adjustInstrumentColor);
	setlistener(panelBlue, adjustInstrumentColor);
	setlistener(domeNorm, adjustInstrumentColor);
	setlistener(domeRed, adjustInstrumentColor);
	setlistener(domeGreen, adjustInstrumentColor);
	setlistener(domeBlue, adjustInstrumentColor);

	print("interior-lights.nas initialized");
}
settimer(init, 0);

