#Universal light systems by Tomaskom

var lightsPath = "lightpack/"; #path to the property node, where all internal values are placed

#list of switches for lights - if you don't intend to use some light, assign it nil value instead, like whateverSwitch = nil; and you don't need to care about anything else
var navSwitch = "/controls/lighting/nav-lights-switch";
var beaconSwitch = "/controls/lighting/beacon-switch";
var strobeSwitch = "/controls/lighting/strobe-switch";
var landingSwitch = "/controls/lighting/landing-lights-switch";
var taxiSwitch = "/controls/lighting/taxi-light-switch";
var probeSwitch = "/controls/lighting/probe-light-switch";
var whiteSwitch = "/controls/lighting/white-light-switch";

#switch this from 1 to 0 if you want to use advanced cyclical fading animation of the the nav lights instead of being stable on when the switch is on
navStillOn = 1;
#switch this from 0 to 1 if you want to bind the landing and taxi lights to the landing gear
gearBind = 1;



#### NAV LIGHTS ####

#class for a periodic fade in/out animation - for flashing, use rather standard aircraft.light.new(), as in Beacon and Strobe section
var lightCycle = {
	#constructor
	new: func(propSwitch, propOut) {
		m = { parents: [lightCycle] };
		props.globals.initNode(propOut, 0, "DOUBLE");
		props.globals.initNode(propSwitch, 1, "BOOL");
		m.fadeIn = 0.4; #fade in time
		m.fadeOut = 0.4; #fade out time
		m.stayOn = 1.5; #stable on period
		m.stayOff = 1; #stable off period
		m.turnOff = 0.12; #fade out time when turned off
		m.phase = 0; #phase to be run on next timer call: 0 -> fade in, 1 -> stay on, 2 -> fade out, 3 -> stay off
		m.cycleTimer = maketimer(0.1, func {
			if(getprop(propSwitch)) {
				if(m.phase == 0) {
					interpolate(propOut, 1, m.fadeIn);
					m.phase = 1;
					m.cycleTimer.restart(m.fadeIn);
				}
				else if(m.phase == 1){
					m.phase = 2;
					m.cycleTimer.restart(m.stayOn);
				}
				else if(m.phase == 2){
					interpolate(propOut, 0, m.fadeOut);
					m.phase = 3;
					m.cycleTimer.restart(m.fadeOut);
				}
				else if(m.phase == 3){
					m.phase = 0;
					m.cycleTimer.restart(m.stayOff);
				}
			}
			else {
				interpolate(propOut, 0, m.turnOff); #kills any currently ongoing interpolation
				m.phase = 0;
			}
		});
		m.cycleTimer.singleShot = 1;
		if(propSwitch==nil) {
			m.listen = nil;
			return m;
		}
		m.listen = setlistener(propSwitch, func{m.cycleTimer.restart(0);}); #handle switch changes
		m.cycleTimer.restart(0); #start the looping
		return m;
	},
	#destructor
	del: func {
		if(me.listen!=nil) removelistener(me.listen);
		me.cycleTimer.stop();
	},
};

#By default, the switch property is initialized to 1 (only if no value is already assigned). Don't change the class implementation! To override this, set the property manually. You don't need to care if any other code already does it for you. 
var navLights = nil;
if(!navStillOn) {
	navLights = lightCycle.new(navSwitch, lightsPath~"nav-lights-intensity");
	### Uncomment and tune those to customize times ###
	#navLights.fadeIn = 0.4; #fade in time 
	#navLights.fadeOut = 0.4; #fade out time
	#navLights.stayOn = 3; #stable on period
	#navLights.stayOff = 0.6; #stable off period
	#navLights.turnOff = 0.12; #fade out time when turned off
}


### BEACON ###
var beacon = nil;
if(beaconSwitch!=nil) {
	props.globals.initNode(beaconSwitch, 1, "BOOL");
	beacon = aircraft.light.new(lightsPath~"beacon-state", 
		[0.0, 1.0], beaconSwitch);
}
	
	
### STROBE ###
var strobe = nil;
if(strobeSwitch!=nil) {
	props.globals.initNode(strobeSwitch, 1, "BOOL");
	strobe = aircraft.light.new(lightsPath~"strobe-state", 
		[0.0, 0.87], strobeSwitch);
}


### LIGHT FADING ###

#class for controlling fade in/out behavior - propIn is a control property (handled as a boolean) and propOut is interpolated
#all light brightness animations in xmls depend on propOut (Rembrandt brightness, material emission, flares transparency, ...)
var lightFadeInOut = {
	#constructor
	new: func(propSwitch, propOut) {
		m = { parents: [lightFadeInOut] };
		m.fadeIn = 0.3; #some sane defaults
		m.fadeOut = 0.4;
		if(propSwitch==nil) {
			m.listen = nil;
			return m;
		}
		props.globals.initNode(propSwitch, 1, "BOOL");
		m.isOn = getprop(propSwitch);
		props.globals.initNode(propOut, m.isOn, "DOUBLE");
		m.listen = setlistener(propSwitch, 
			func {
				if(m.isOn and !getprop(propSwitch)) {
					interpolate(propOut, 0, m.fadeOut);
					m.isOn = 0;
				}
				if(!m.isOn and getprop(propSwitch)) {
					interpolate(propOut, 1, m.fadeIn);
					m.isOn = 1;
				}
			}
		);
		return m;
	},
	#destructor
	del: func {
		if(me.listen!=nil) removelistener(me.listen);
	},
};

fadeLanding = lightFadeInOut.new(landingSwitch, lightsPath~"landing-lights-intensity");
fadeTaxi = lightFadeInOut.new(taxiSwitch, lightsPath~"taxi-light-intensity");
fadeProbe = lightFadeInOut.new(probeSwitch, lightsPath~"probe-light-intensity");
fadeWhite = lightFadeInOut.new(whiteSwitch, lightsPath~"white-light-intensity");
if(navStillOn) {
	navLights = lightFadeInOut.new(navSwitch, lightsPath~"nav-lights-intensity");
	navLights.fadeIn = 0.1;
	navLights.fadeOut = 0.12;
}
#manipulate times if defaults don't fit your needs:
#fadeLanding.fadeIn = 0.5;
#fadeLanding.fadeOut = 0.8;


#enable binding to gear
if(gearBind) {
	setlistener("/controls/gear/gear-down", func {
		gearDown = getprop("/controls/gear/gear-down");
		if(gearDown) {
			if(landingSwitch!=nil) setprop(landingSwitch, 1);
			if(taxiSwitch!=nil) setprop(taxiSwitch, 1);
		}
		else{
			if(landingSwitch!=nil) setprop(landingSwitch, 0);
			if(taxiSwitch!=nil) setprop(taxiSwitch, 0);
		}
	});
}
setupALSLights = func {
    if (getprop("sim/current-view/internal"))
    {
        setprop("sim/rendering/als-secondary-lights/landing-light1-offset-deg", -2);
        setprop("sim/rendering/als-secondary-lights/landing-light2-offset-deg", 2);
        setprop("sim/rendering/als-secondary-lights/use-landing-light", 1);
        setprop("sim/rendering/als-secondary-lights/use-alt-landing-light", 1);
    }
    else
    {
        setprop("sim/rendering/als-secondary-lights/use-landing-light", 0);
        setprop("sim/rendering/als-secondary-lights/use-alt-landing-light", 0);
    }
}
setlistener("/sim/current-view/internal", setupALSLights);

print("Lightpack light system initialized");

