# if A/G selected on right lower side then MK-83 is selected
#
# TODO:
# 
# AIM-7 on the 4 center pylons in main model AC3D is in wrong position
# AIM-54 on the 4 center pylons in main model AC3D is named wrongly. So when ACM JETT 3 & 4 it looks like 3 & 5 gets jettisoned. (MK-83 is correct)
# anti-cheat key 'a' binding do not get activated. Don't know why.
# investigate how to differentiate between firing aim-54 and aim-7. Since they share knob position. Is it up to RIO's pylon switches?

var fcs = nil;
var pylonI = nil;
var pylon1 = nil;
var pylon2 = nil;
var pylon3 = nil;
var pylon4 = nil;
var pylon5 = nil;
var pylon6 = nil;
var pylon7 = nil;
var pylon8 = nil;
var pylon9 = nil;
var pylon10 = nil;

var msgA = "If you need to repair now, then use Menu-Location-SelectAirport instead.";
var msgB = "Please land before changing payload.";
var msgC = "Please land before refueling.";

var cannon = stations.SubModelWeapon.new("20mm Cannon", 0.254, 135, [3], [2], props.globals.getNode("sim/model/f-14b/systems/gun/running",1), 0, func{return getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>=20 and getprop("fdm/jsbsim/systems/electrics/ac-essential-bus1")>=70 and getprop("fdm/jsbsim/systems/hydraulics/flight-system-pressure") and getprop("payload/armament/fire-control/serviceable");},0);
cannon.typeShort = "GUN";
cannon.brevity = "Guns guns";
var fuelTank267Left = stations.FuelTank.new("L External", "TK267", 8, 370, "sim/model/f-14b/wingtankL");
var fuelTank267Right = stations.FuelTank.new("R External", "TK267", 9, 370, "sim/model/f-14b/wingtankR");

var smokewinderWhite1 = stations.Smoker.new("Smokewinder White", "SmokeW", "sim/model/f-14b/fx/smoke-mnt-left");
var smokewinderWhite10 = stations.Smoker.new("Smokewinder White", "SmokeW", "sim/model/f-14b/fx/smoke-mnt-right");

var pylonSets = {
	empty: {name: "Empty", content: [], fireOrder: [], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},
	mm20:  {name: "20mm Cannon", content: [cannon], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},

    m83:  {name: "MK-83", content: ["MK-83"], fireOrder: [0], launcherDragArea: 0.005, launcherMass: 300, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 2},
    
    # 340 = outer pylon
	smokeWL: {name: "Smokewinder White", content: [smokewinderWhite1], fireOrder: [0], launcherDragArea: -0.05, launcherMass: 53+340, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	smokeWR: {name: "Smokewinder White", content: [smokewinderWhite10], fireOrder: [0], launcherDragArea: -0.05, launcherMass: 53+340, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},

	fuel26L: {name: "267 Gal Fuel tank", content: [fuelTank267Left], fireOrder: [0], launcherDragArea: 0.35, launcherMass: 531, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 2},
	fuel26R: {name: "267 Gal Fuel tank", content: [fuelTank267Right], fireOrder: [0], launcherDragArea: 0.35, launcherMass: 531, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 2},

    # A/A weapons on non-wing pylons:
	aim9:    {name: "AIM-9",   content: ["AIM-9"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 53, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	aim7:    {name: "AIM-7",   content: ["AIM-7"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	aim54:    {name: "AIM-54",   content: ["AIM-54"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 300, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    
    # A/A weapons on wing pylons:
    # 170 = half the outer pylon of 340
    aim9w:    {name: "AIM-9",   content: ["AIM-9"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 53+170, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    aim7w:    {name: "AIM-7",   content: ["AIM-7"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 0+170, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    aim54w:    {name: "AIM-54",   content: ["AIM-54"], fireOrder: [0], launcherDragArea: -0.025, launcherMass: 90+170, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
};

# sets. The first in the list is the default. Earlier in the list means higher up in dropdown menu.
# These are not strictly needed in F-14 beside from the Empty, since it uses a custom payload dialog, but there for good measure.
var pylon1set = [pylonSets.empty, pylonSets.aim9, pylonSets.smokeWL];
var pylon2set = [pylonSets.empty, pylonSets.aim9, pylonSets.aim7, pylonSets.aim54];
var pylon3set = [pylonSets.empty, pylonSets.fuel26L];
var pylon4set = [pylonSets.empty, pylonSets.m83, pylonSets.aim7, pylonSets.aim54];
var pylon5set = [pylonSets.empty, pylonSets.m83, pylonSets.aim7, pylonSets.aim54];
var pylon6set = [pylonSets.empty, pylonSets.m83, pylonSets.aim7, pylonSets.aim54];
var pylon7set = [pylonSets.empty, pylonSets.m83, pylonSets.aim7, pylonSets.aim54];
var pylon8set = [pylonSets.empty, pylonSets.fuel26R];
var pylon9set = [pylonSets.empty, pylonSets.aim9, pylonSets.aim7, pylonSets.aim54];
var pylon10set= [pylonSets.empty, pylonSets.aim9, pylonSets.smokeWR];

# pylons
pylonI = stations.InternalStation.new("Internal gun mount", 10, [pylonSets.mm20], props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[10]",1));
pylon1 = stations.Pylon.new("1A Pylon",      0, [0.4795,-3.6717,-1.0600], pylon1set,  0, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[0]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[0]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return getprop("sim/model/f-14b/systems/external-loads/station[0]/selected");});
pylon2 = stations.Pylon.new("1B Pylon",      1, [0.4795,-3.7800,-1.5700], pylon2set,  1, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[1]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[1]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return getprop("sim/model/f-14b/systems/external-loads/station[1]/selected");});
pylon3 = stations.Pylon.new("2 Pylon",       2, [-2,0,-1.4333],           pylon3set,  2, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[2]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[2]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return getprop("sim/model/f-14b/systems/external-loads/station[2]/selected");});
pylon4 = stations.Pylon.new("3 Pylon",       3, [-2,-1.0,-1.4333],        pylon4set,  3, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[3]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[3]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return getprop("sim/model/f-14b/systems/external-loads/station[3]/selected");});
pylon5 = stations.Pylon.new("4 Pylon",       4, [ 2,-1.0,-1.4333],        pylon5set,  4, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[4]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[4]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return getprop("sim/model/f-14b/systems/external-loads/station[4]/selected");});
pylon6 = stations.Pylon.new("5 Pylon",       5, [ 2, 0.0,-1.4333],        pylon6set,  5, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[5]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[5]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return getprop("sim/model/f-14b/systems/external-loads/station[5]/selected");});
pylon7 = stations.Pylon.new("6 Pylon",       6, [-2, 0.0,-1.4333],        pylon7set,  6, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[6]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[6]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return getprop("sim/model/f-14b/systems/external-loads/station[6]/selected");});
pylon8 = stations.Pylon.new("7 Pylon",       7, [-2,0,-1.4333],           pylon8set,  7, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[7]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[7]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return getprop("sim/model/f-14b/systems/external-loads/station[7]/selected");});
pylon9 = stations.Pylon.new("8B Pylon",      8, [0.4795,2.7800,-1.5700],  pylon9set,  8, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[8]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[8]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return getprop("sim/model/f-14b/systems/external-loads/station[8]/selected");});
pylon10= stations.Pylon.new("8A Pylon",      9, [0.4795,3.1717,-1.0600],  pylon10set, 9, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[9]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[9]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return getprop("sim/model/f-14b/systems/external-loads/station[9]/selected");});


#pylon1.forceRail = 1;# set the missiles mounted on this pylon on a rail.
#pylon9.forceRail = 1;

var pylons = [pylonI,pylon1,pylon2,pylon3,pylon4,pylon5,pylon6,pylon7,pylon8,pylon9,pylon10];

# The order of first vector in this line is the default pylon order weapons is released in.
# The order of second vector in this line is the order cycle key would cycle through the weapons (but since the f-14 dont have that the order is not important):
fcs = fc.FireControl.new(pylons, [0,1,10,2,9,4,7,5,6], ["20mm Cannon","AIM-9","AIM-7","AIM-54","MK-83"]);

if (getprop("sim/model/f-14b/systems/external-loads/external-tanks")) {
    # since this property is data saved, we might need to init with tanks
    pylon3.loadSet(pylonSets.fuel26L);
    pylon8.loadSet(pylonSets.fuel26R);
}


#print("** Pylon & fire control system started. **");
var getDLZ = func {
    if (fcs != nil and getprop("controls/armament/master-arm")) {
        var w = fcs.getSelectedWeapon();
        if (w!=nil and w.parents[0] == armament.AIM) {
            var result = w.getDLZ(1);
            if (result != nil and size(result) == 5 and result[4]<result[0]*1.5 and armament.contact != nil and armament.contact.get_display()) {
                #target is within 150% of max weapon fire range.
        	    return result;
            }
        }
    }
    return nil;
}

var reloadCannon = func {
    setprop("ai/submodels/submodel[4]/count", 100);
    setprop("ai/submodels/submodel[5]/count", 100);#flares
    cannon.reloadAmmo();
    setprop("/sim/model/f-14b/systems/gun/rounds",675);
}

# reload cannon only
var cannon_load = func {
    if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        reloadCannon();
        return 1;
    } else {
      screen.log.write(msgB);
      return 0;
    }
}

# FAD (AIM-9, AIM-7, AIM-54)
var fad = func {
    if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim9w);
        pylon2.loadSet(pylonSets.aim7w);
        pylon4.loadSet(pylonSets.aim54);
        pylon5.loadSet(pylonSets.aim54);
        pylon6.loadSet(pylonSets.aim54);
        pylon7.loadSet(pylonSets.aim54);
        pylon9.loadSet(pylonSets.aim7w);
        pylon10.loadSet(pylonSets.aim9w);
        reloadCannon();
        return 1;
    } else {
      screen.log.write(msgB);
      return 0;
    }
}

# FAD light (AIM-9, AIM-7)
var fad_l = func {
    if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim9w);
        pylon2.loadSet(pylonSets.aim9w);
        pylon4.loadSet(pylonSets.aim7);
        pylon5.loadSet(pylonSets.aim7);
        pylon6.loadSet(pylonSets.aim7);
        pylon7.loadSet(pylonSets.aim7);
        pylon9.loadSet(pylonSets.aim9w);
        pylon10.loadSet(pylonSets.aim9w);
        reloadCannon();
        return 1;
    } else {
      screen.log.write(msgB);
      return 0;
    }
}

# FAD heavy (AIM-9, AIM-54)
var fad_h = func {
    if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim9w);
        pylon2.loadSet(pylonSets.aim54w);
        pylon4.loadSet(pylonSets.aim54);
        pylon5.loadSet(pylonSets.aim54);
        pylon6.loadSet(pylonSets.aim54);
        pylon7.loadSet(pylonSets.aim54);
        pylon9.loadSet(pylonSets.aim54w);
        pylon10.loadSet(pylonSets.aim9w);
        reloadCannon();
        return 1;
    } else {
      screen.log.write(msgB);
      return 0;
    }
}

# bombcat (AIM-9, AIM-7, MK-83)
var bomb = func {
    if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.aim9w);
        pylon2.loadSet(pylonSets.aim7w);
        pylon4.loadSet(pylonSets.m83);
        pylon5.loadSet(pylonSets.m83);
        pylon6.loadSet(pylonSets.m83);
        pylon7.loadSet(pylonSets.m83);
        pylon9.loadSet(pylonSets.aim7w);
        pylon10.loadSet(pylonSets.aim9w);
        reloadCannon();
        return 1;
    } else {
      screen.log.write(msgB);
      return 0;
    }
}

# Clean configuration
var clean = func {
    if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.empty);
        pylon2.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.empty);
        pylon10.loadSet(pylonSets.empty);
        reloadCannon();
        return 1;
    } else {
      screen.log.write(msgB);
      return 0;
    }
}

# Airshow configuration (Smokewinder white)
var airshow = func {
    if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
        pylon1.loadSet(pylonSets.smokeWL);
        pylon2.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon9.loadSet(pylonSets.empty);
        pylon10.loadSet(pylonSets.smokeWR);
        reloadCannon();
        return 1;
    } else {
      screen.log.write(msgB);
      return 0;
    }
}


# the following refuel methods is not used, the exisintg methods works just fine with the new system as far as I can see, so they are never called.
# if some days they shall be used, the levels needs to be reviewed.

var refuelFull = func {
	if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
		setprop("consumables/fuel/tank[0]/level-norm", 1);#fwd
		setprop("consumables/fuel/tank[1]/level-norm", 1);#aft
		setprop("consumables/fuel/tank[2]/level-norm", 1);#beam L
		setprop("consumables/fuel/tank[3]/level-norm", 1);#sump L
		setprop("consumables/fuel/tank[4]/level-norm", 1);#beam R
		setprop("consumables/fuel/tank[5]/level-norm", 1);#sump R
		setprop("consumables/fuel/tank[6]/level-norm", 1);#wing L
		setprop("consumables/fuel/tank[7]/level-norm", 1);#wing R
		if (getprop("consumables/fuel/tank[8]/name") != "Not attached") setprop("consumables/fuel/tank[8]/level-norm", 1);#ext L
		if (getprop("consumables/fuel/tank[9]/name") != "Not attached") setprop("consumables/fuel/tank[9]/level-norm", 1);#ext R
		setprop("consumables/fuel/tank[10]/level-norm", 1);#feed L
		setprop("consumables/fuel/tank[11]/level-norm", 1);#feed R
	} else {
      screen.log.write(msgC);
    }
}

var refuel50 = func {
	if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
		setprop("consumables/fuel/tank[0]/level-norm", 0);
		setprop("consumables/fuel/tank[1]/level-norm", 0);
		setprop("consumables/fuel/tank[2]/level-norm", 0);
		setprop("consumables/fuel/tank[3]/level-norm", 1);
		setprop("consumables/fuel/tank[4]/level-norm", 0);
		setprop("consumables/fuel/tank[5]/level-norm", 1);
		setprop("consumables/fuel/tank[6]/level-norm", 0);
		setprop("consumables/fuel/tank[7]/level-norm", 0);
		if (getprop("consumables/fuel/tank[8]/name") != "Not attached") setprop("consumables/fuel/tank[8]/level-norm", 0);
		if (getprop("consumables/fuel/tank[9]/name") != "Not attached") setprop("consumables/fuel/tank[9]/level-norm", 0);
		setprop("consumables/fuel/tank[10]/level-norm", 0);
		setprop("consumables/fuel/tank[11]/level-norm", 0);
	} else {
      screen.log.write(msgC);
    }
}

var refuel11 = func {
	if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
		setprop("consumables/fuel/tank[0]/level-norm", 1);
		setprop("consumables/fuel/tank[1]/level-norm", 1);
		setprop("consumables/fuel/tank[2]/level-norm", 1);
		setprop("consumables/fuel/tank[3]/level-norm", 1);
		setprop("consumables/fuel/tank[4]/level-norm", 1);
		setprop("consumables/fuel/tank[5]/level-norm", 1);
		setprop("consumables/fuel/tank[6]/level-norm", 0);
		setprop("consumables/fuel/tank[7]/level-norm", 0);
		if (getprop("consumables/fuel/tank[8]/name") != "Not attached") setprop("consumables/fuel/tank[8]/level-norm", 0);
		if (getprop("consumables/fuel/tank[9]/name") != "Not attached") setprop("consumables/fuel/tank[9]/level-norm", 0);
		setprop("consumables/fuel/tank[10]/level-norm", 0);
		setprop("consumables/fuel/tank[11]/level-norm", 0);
	} else {
      screen.log.write(msgC);
    }
}

var refuel35 = func {
	if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
		setprop("consumables/fuel/tank[0]/level-norm", 0.3);
		setprop("consumables/fuel/tank[1]/level-norm", 0.3);
		setprop("consumables/fuel/tank[2]/level-norm", 1);
		setprop("consumables/fuel/tank[3]/level-norm", 1);
		setprop("consumables/fuel/tank[4]/level-norm", 1);
		setprop("consumables/fuel/tank[5]/level-norm", 1);
		setprop("consumables/fuel/tank[6]/level-norm", 0);
		setprop("consumables/fuel/tank[7]/level-norm", 0);
		if (getprop("consumables/fuel/tank[8]/name") != "Not attached") setprop("consumables/fuel/tank[8]/level-norm", 0);
		if (getprop("consumables/fuel/tank[9]/name") != "Not attached") setprop("consumables/fuel/tank[9]/level-norm", 0);
		setprop("consumables/fuel/tank[10]/level-norm", 0);
		setprop("consumables/fuel/tank[11]/level-norm", 0);
	} else {
      screen.log.write(msgC);
    }
}

var refuel7 = func {
	if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
		setprop("consumables/fuel/tank[0]/level-norm", 0.66);
		setprop("consumables/fuel/tank[1]/level-norm", 0.75);
		setprop("consumables/fuel/tank[2]/level-norm", 1);
		setprop("consumables/fuel/tank[3]/level-norm", 1);
		setprop("consumables/fuel/tank[4]/level-norm", 1);
		setprop("consumables/fuel/tank[5]/level-norm", 1);
		setprop("consumables/fuel/tank[6]/level-norm", 0);
		setprop("consumables/fuel/tank[7]/level-norm", 0);
		if (getprop("consumables/fuel/tank[8]/name") != "Not attached") setprop("consumables/fuel/tank[8]/level-norm", 0);
		if (getprop("consumables/fuel/tank[9]/name") != "Not attached") setprop("consumables/fuel/tank[9]/level-norm", 0);
		setprop("consumables/fuel/tank[10]/level-norm", 0);
		setprop("consumables/fuel/tank[11]/level-norm", 0);
	} else {
      screen.log.write(msgC);
    }
}

var refuelShow = func {
	if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {
		setprop("consumables/fuel/tank[0]/level-norm", 0.5);
		setprop("consumables/fuel/tank[1]/level-norm", 0.0);
		setprop("consumables/fuel/tank[2]/level-norm", 1);
		setprop("consumables/fuel/tank[3]/level-norm", 1);
		setprop("consumables/fuel/tank[4]/level-norm", 1);
		setprop("consumables/fuel/tank[5]/level-norm", 1);
		setprop("consumables/fuel/tank[6]/level-norm", 0);
		setprop("consumables/fuel/tank[7]/level-norm", 0);
		if (getprop("consumables/fuel/tank[8]/name") != "Not attached") setprop("consumables/fuel/tank[8]/level-norm", 0);
		if (getprop("consumables/fuel/tank[9]/name") != "Not attached") setprop("consumables/fuel/tank[9]/level-norm", 0);
		setprop("consumables/fuel/tank[10]/level-norm", 0);
		setprop("consumables/fuel/tank[11]/level-norm", 0);
	} else {
      screen.log.write(msgC);
    }
}

var bore_loop = func {
    #enables firing of aim9 without radar. The aim-9 seeker will be fixed 3.5 degs below bore and any aircraft the gets near that will result in lock.
    bore = 0;
    if (fcs != nil) {
        var standby = getprop("instrumentation/radar/radar-standby");
        var aim = fcs.getSelectedWeapon();
        if (aim != nil and aim.type == "AIM-9") {
            if (standby == 1) {
                #aim.setBore(1);
                aim.setContacts(awg_9.completeList);
                aim.commandDir(0,-3.5);# the real is bored to -6 deg below real bore
                bore = 1;
            } else {
                aim.commandRadar();
                aim.setContacts([]);
            }
        }
    }
    settimer(bore_loop, 0.5);
};
var bore = 0;
if (fcs!=nil) {
    bore_loop();
}
