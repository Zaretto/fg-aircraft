# 
#
# TODO:
# 

var fcs = nil;
var pylonI  = nil;
#var pylon1  = nil;
var pylon2a = nil;
var pylon2b = nil;
var pylon2c = nil;
var pylon3  = nil;
var pylon4  = nil;
var pylon5  = nil;
var pylon6  = nil;
var pylon7  = nil;
var pylon8a = nil;
var pylon8b = nil;
var pylon8c = nil;
#var pylon9  = nil;


var msgA = "If you need to repair now, then use Menu-Location-SelectAirport instead.";
var msgB = "Please land before changing payload.";
var msgC = "Please land before refueling.";

var cannon = stations.SubModelWeapon.new("20mm Cannon", 0.254, 135, [4], [3], props.globals.getNode("sim/model/f15/systems/gun/running",1), 0, func{return getprop("sim/model/f15/systems/gun/ready");},0);
cannon.typeShort = "GUN";
cannon.brevity = "Guns guns";

#var fuelTank600Left   = stations.FuelTank.new("L External", "TK600", 5, 600, "sim/model/f15/wingtankL");
#var fuelTank600Center = stations.FuelTank.new("C External", "TK600", 7, 600, "sim/model/f15/wingtankC");
#var fuelTank600Right  = stations.FuelTank.new("R External", "TK600", 6, 600, "sim/model/f15/wingtankR");

var smokewinderWhite2a = stations.Smoker.new("Smokewinder White", "SmokeW", "sim/model/f15/fx/smoke-mnt-left");
var smokewinderWhite8c = stations.Smoker.new("Smokewinder White", "SmokeW", "sim/model/f15/fx/smoke-mnt-right");

var pylonSets = {
	empty: {name: "Empty", content: [], fireOrder: [], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 1},
	mm20:  {name: "20mm Cannon", content: [cannon], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},

    g10:  {name: "GBU-10", content: ["GBU-10"], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 2},
    m84:  {name: "MK-84", content: ["MK-84"], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 0, category: 3},
    
    # 340 = outer pylon
	smokeWL: {name: "Smokewinder White", content: [smokewinderWhite2a], fireOrder: [0], launcherDragArea: -0.05, launcherMass: 53+340, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	smokeWR: {name: "Smokewinder White", content: [smokewinderWhite8c], fireOrder: [0], launcherDragArea: -0.05, launcherMass: 53+340, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},

#	fuel600L: {name: "Droptank", content: [fuelTank600Left], fireOrder: [0], launcherDragArea: 0.35, launcherMass: 271, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 2},
#   fuel600C: {name: "Droptank", content: [fuelTank600Center], fireOrder: [0], launcherDragArea: 0.35, launcherMass: 271, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 2},
#	fuel600R: {name: "Droptank", content: [fuelTank600Right], fireOrder: [0], launcherDragArea: 0.35, launcherMass: 271, launcherJettisonable: 1, showLongTypeInsteadOfCount: 1, category: 2},

    # A/A weapons for fuselage pylons:
	aim9:    {name: "AIM-9L Sidewinder",   content: ["AIM-9"], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 10, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	aim7:    {name: "AIM-7F Sparrow",   content: ["AIM-7"], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 30, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
	aim120:  {name: "AIM-120B AMRAAM", content: ["AIM-120"], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 30, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},

    # A/A weapons for wing pylons: (launchermass is calculated in jsbsim pointmass weight 13 & 14)
    aim9w:    {name: "AIM-9L Sidewinder",   content: ["AIM-9"], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    aim7w:    {name: "AIM-7F Sparrow",   content: ["AIM-7"], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
    aim120w:  {name: "AIM-120B AMRAAM", content: ["AIM-120"], fireOrder: [0], launcherDragArea: 0.0, launcherMass: 0, launcherJettisonable: 0, showLongTypeInsteadOfCount: 1, category: 1},
};

# sets. The first in the list is the default. Earlier in the list means higher up in dropdown menu.
# These are not strictly needed in F-15 beside from the Empty, since it uses a custom payload dialog, but there for good measure.
#var pylon1set = [pylonSets.empty];
var pylon2aset = [pylonSets.empty, pylonSets.aim9w, pylonSets.aim120w];
var pylon2bset = [pylonSets.empty, pylonSets.m84, pylonSets.g10];
var pylon2cset = [pylonSets.empty, pylonSets.aim9w, pylonSets.aim120w];
var pylon3set = [pylonSets.empty, pylonSets.m84, pylonSets.aim7, pylonSets.aim120];
var pylon4set = [pylonSets.empty, pylonSets.m84, pylonSets.aim7, pylonSets.aim120];
var pylon5set = [pylonSets.empty, pylonSets.m84, pylonSets.g10];
var pylon6set = [pylonSets.empty, pylonSets.m84, pylonSets.aim7, pylonSets.aim120];
var pylon7set = [pylonSets.empty, pylonSets.m84, pylonSets.aim7, pylonSets.aim120];
var pylon8aset = [pylonSets.empty, pylonSets.aim9w, pylonSets.aim120w];
var pylon8bset = [pylonSets.empty, pylonSets.m84, pylonSets.g10];
var pylon8cset = [pylonSets.empty, pylonSets.aim9w, pylonSets.aim120w];
#var pylon9set = [pylonSets.empty];

# pylons
pylonI = stations.InternalStation.new("Internal Gun Station", 11, [pylonSets.mm20], props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[18]",1));
#pylon1 = stations.Pylon.new("Left Wing Station 1",       0, [0,0,0],                   pylon1set,  0, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[16]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[16]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return getprop("sim/model/f-14b/systems/external-loads/station[0]/selected");});
pylon2a= stations.Pylon.new("Left Wing Station 2",       0, [1.7844, -3.8325, 0.288],  pylon2aset,  0, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[0]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[0]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return 1;});
pylon2b= stations.WPylon.new("Left Wing Station 2",      1, [1.4077, -3.3034, 1.4077], pylon2bset,  1, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs-sta-2b-weaps",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft-sta-2b-weaps",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return 1;});
pylon2c= stations.Pylon.new("Left Wing Station 2",       2, [1.7844, -3.8325, 0.288],  pylon2cset,  2, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[2]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[2]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return 1;});
pylon3 = stations.Pylon.new("Left Body Station 3",       3, [-0.3003, 1.611, 0.567],   pylon3set,  3, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[3]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[3]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return 1;});
pylon4 = stations.Pylon.new("Left Body Station 4",       4, [3.5918, 1.611, 0.567],    pylon4set,  4, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[4]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[4]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return 1;});
pylon5 = stations.WPylon.new("Center Station 5",         5, [0, 0, 0.33],              pylon5set,  5, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs-sta-5-weaps",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft-sta-5-weaps",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return 1;});
pylon6 = stations.Pylon.new("Right Body Station 6",      6, [-0.3003, 1.611, 0.567],   pylon6set,  6, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[6]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[6]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return 1;});
pylon7 = stations.Pylon.new("Right Body Station 7",      7, [3.5918, 1.611, 0.567],    pylon7set,  7, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[7]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[7]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return 1;});
pylon8a= stations.Pylon.new("Right Wing Station 8",      8, [1.7844, 3.8325, 0.288],   pylon8aset, 8, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[8]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[8]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return 1;});
pylon8b= stations.WPylon.new("Right Wing Station 8",     9, [1.4077, 3.3034, 1.407],   pylon8bset, 9, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs-sta-8b-weaps",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft-sta-8b-weaps",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return 1;});
pylon8c= stations.Pylon.new("Right Wing Station 8",     10, [1.7844, 3.8325, 0.288],   pylon8cset, 10, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[10]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[10]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return 1;});
#pylon9 = stations.Pylon.new("Right Wing Station 9",     12, [0,0,0],                   pylon9set, 12, props.globals.getNode("fdm/jsbsim/inertia/pointmass-weight-lbs[17]",1),props.globals.getNode("fdm/jsbsim/inertia/pointmass-dragarea-sqft[17]",1),func{return getprop("payload/armament/fire-control/serviceable") and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>20;},func{return getprop("sim/model/f-14b/systems/external-loads/station[9]/selected");});
#pylonCFT_L
#pylonCFT_R

pylon2a.forceRail = 1;# set the missiles mounted on these pylon always on a rail.
pylon2c.forceRail = 1;
pylon8a.forceRail = 1;
pylon8c.forceRail = 1;

var pylons = [pylonI,pylon2a,pylon2b,pylon2c,pylon3,pylon4,pylon5,pylon6,pylon7,pylon8a,pylon8b,pylon8c];

# The order of first vector in this line is the default pylon order weapons is released in.
# The order of second vector in this line is the order cycle key would cycle through the weapons (since F15 doesn't use the cycle option that order is not important):
fcs = fc.FireControl.new(pylons, [0,6,1,11,3,9,2,10,4,7,5,8], ["20mm Cannon","AIM-9","AIM-7","AIM-120","MK-84", "GBU-10"]);

var callback = func (aim = nil) {
    # after something has changed in pylon system, this will make MPCD update its A/A and A/G pages:
    setprop("sim/model/f15/controls/armament/weapons-updated", getprop("sim/model/f15/controls/armament/weapons-updated")+1);
}
var callbackClass = func (aim = nil) {
    if (aim != nil and aim.type == "AIM-120") {
        settimer(func selectNextOfSameClass("AIM-7"), 0.5);
    } elsif (aim != nil and aim.type == "AIM-7") {
        settimer(func selectNextOfSameClass("AIM-120"), 0.5);
    }
}
var callbackClassG = func (aim = nil) {
    if (aim != nil and aim.type == "GBU-10") {
        settimer(func selectNextOfSameClass("MK-84"), 0.5);
    } elsif (aim != nil and aim.type == "MK-84") {
        settimer(func selectNextOfSameClass("GBU-10"), 0.5);
    }
}

var selectNextOfSameClass = func (type) {
    # to avoid cyclic callstack this method is called delayed. Also due to callbackClass can be called before next has been selected.
    if (fcs.getSelectedWeapon() == nil) {
        fcs.selectWeapon(type);
    }
}

for (var j = 1;j<12;j+=1) {
    if (j==2 or j==6 or j==10) {
        pylons[j].setAIMListener(callbackClassG);
    } else {
        pylons[j].setAIMListener(callbackClass);
    }
    pylons[j].guiChanged();# update the pylons to whatever startup stores should be loaded.
}
fcs.setChangeListener(callback);

#print("** Pylon & fire control system started. **");
var getDLZ = func {
    if (fcs != nil and getprop("controls/armament/master-arm")) {
        var w = fcs.getSelectedWeapon();
        if (w!=nil and w.parents[0] == armament.AIM) {
            var result = w.getDLZ(0);
            if (result != nil and size(result) == 5 and result[4]<result[0]*1.5 and armament.contact != nil and armament.contact.get_display()) {
                #target is within 150% of max weapon fire range.
        	    return result;
            }
        }
    }
    return nil;
}

var getCCIP = func {
    if (fcs != nil and getprop("controls/armament/master-arm")) {
        var w = fcs.getSelectedWeapon();
        if (w!=nil and w.parents[0] == armament.AIM) {
            if (w.type=="MK-84") {
                # 20s fall time limit and calculate fall trajectory at every 0.20s on the way to ground.
                return w.getCCIPadv(20, 0.20);
            } elsif (w.type=="GBU-10") {
                # 35s fall time limit and calculate fall trajectory at every 0.30s on the way to ground.
                return w.getCCIPadv(35, 0.30);
            }
        }
    }
    return nil;
}

var reloadCannon = func {
    setprop("ai/submodels/submodel[5]/count", 100);
    setprop("ai/submodels/submodel[6]/count", 100);#flares
    cannon.reloadAmmo();
    setprop("/systems/gun/rounds",675);
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

# Clean configuration
var clean = func {
    if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {

        pylon2a.loadSet(pylonSets.empty);
        pylon2b.loadSet(pylonSets.empty);
        pylon2c.loadSet(pylonSets.empty);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8a.loadSet(pylonSets.empty);
        pylon8b.loadSet(pylonSets.empty);
        pylon8c.loadSet(pylonSets.empty);
        reloadCannon();
        return 1;
    } else {
      screen.log.write(msgB);
      return 0;
    }
}

# Standard combat configuration
var standard = func {
    if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {

        pylon2a.loadSet(pylonSets.aim120w);
        pylon2b.loadSet(pylonSets.empty);
        pylon2c.loadSet(pylonSets.aim9w);
        pylon3.loadSet(pylonSets.aim7);
        pylon4.loadSet(pylonSets.aim120);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.aim120);
        pylon7.loadSet(pylonSets.aim7);
        pylon8a.loadSet(pylonSets.aim9w);
        pylon8b.loadSet(pylonSets.empty);
        pylon8c.loadSet(pylonSets.aim120w);
        reloadCannon();
        return 1;
    } else {
      screen.log.write(msgB);
      return 0;
    }
}

var counter = func {
    if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {

        pylon2a.loadSet(pylonSets.aim9w);
        pylon2b.loadSet(pylonSets.empty);
        pylon2c.loadSet(pylonSets.aim9w);
        pylon3.loadSet(pylonSets.aim120);
        pylon4.loadSet(pylonSets.aim120);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.aim120);
        pylon7.loadSet(pylonSets.aim120);
        pylon8a.loadSet(pylonSets.aim9w);
        pylon8b.loadSet(pylonSets.empty);
        pylon8c.loadSet(pylonSets.aim9w);
        reloadCannon();
        return 1;
    } else {
      screen.log.write(msgB);
      return 0;
    }
}

var nofly = func {
    if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {

        pylon2a.loadSet(pylonSets.aim120w);
        pylon2b.loadSet(pylonSets.empty);
        pylon2c.loadSet(pylonSets.aim9w);
        pylon3.loadSet(pylonSets.aim7);
        pylon4.loadSet(pylonSets.aim7);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.aim7);
        pylon7.loadSet(pylonSets.aim7);
        pylon8a.loadSet(pylonSets.aim9w);
        pylon8b.loadSet(pylonSets.empty);
        pylon8c.loadSet(pylonSets.aim120w);
        reloadCannon();
        return 1;
    } else {
      screen.log.write(msgB);
      return 0;
    }
}

var ferry = func {
    if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {

        pylon2a.loadSet(pylonSets.empty);
        pylon2b.loadSet(pylonSets.empty);
        pylon2c.loadSet(pylonSets.empty);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8a.loadSet(pylonSets.empty);
        pylon8b.loadSet(pylonSets.empty);
        pylon8c.loadSet(pylonSets.empty);
        reloadCannon();
        return 1;
    } else {
      screen.log.write(msgB);
      return 0;
    }
}

var super = func {
    if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {

        pylon2a.loadSet(pylonSets.aim120w);
        pylon2b.loadSet(pylonSets.empty);
        pylon2c.loadSet(pylonSets.aim120w);
        pylon3.loadSet(pylonSets.aim120);
        pylon4.loadSet(pylonSets.aim120);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.aim120);
        pylon7.loadSet(pylonSets.aim120);
        pylon8a.loadSet(pylonSets.aim120w);
        pylon8b.loadSet(pylonSets.empty);
        pylon8c.loadSet(pylonSets.aim120w);
        reloadCannon();
        return 1;
    } else {
      screen.log.write(msgB);
      return 0;
    }
}

var ground = func {
    if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {

        pylon2a.loadSet(pylonSets.aim120w);
        pylon2b.loadSet(pylonSets.m84);
        pylon2c.loadSet(pylonSets.aim120w);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.m84);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8a.loadSet(pylonSets.aim120w);
        pylon8b.loadSet(pylonSets.m84);
        pylon8c.loadSet(pylonSets.aim120w);
        reloadCannon();
        return 1;
    } else {
      screen.log.write(msgB);
      return 0;
    }
}

var patrol = func {
    if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {

        pylon2a.loadSet(pylonSets.aim9w);
        pylon2b.loadSet(pylonSets.empty);
        pylon2c.loadSet(pylonSets.aim120w);
        pylon3.loadSet(pylonSets.aim120);
        pylon4.loadSet(pylonSets.aim120);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.aim120);
        pylon7.loadSet(pylonSets.aim120);
        pylon8a.loadSet(pylonSets.aim120w);
        pylon8b.loadSet(pylonSets.empty);
        pylon8c.loadSet(pylonSets.aim9w);
        reloadCannon();
        return 1;
    } else {
      screen.log.write(msgB);
      return 0;
    }
}

var train = func {
    if (fcs != nil and (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW"))) {

        pylon2a.loadSet(pylonSets.aim120w);
        pylon2b.loadSet(pylonSets.empty);
        pylon2c.loadSet(pylonSets.aim9w);
        pylon3.loadSet(pylonSets.empty);
        pylon4.loadSet(pylonSets.empty);
        pylon5.loadSet(pylonSets.empty);
        pylon6.loadSet(pylonSets.empty);
        pylon7.loadSet(pylonSets.empty);
        pylon8a.loadSet(pylonSets.aim9w);
        pylon8b.loadSet(pylonSets.empty);
        pylon8c.loadSet(pylonSets.aim120w);
        reloadCannon();
        return 1;
    } else {
      screen.log.write(msgB);
      return 0;
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
