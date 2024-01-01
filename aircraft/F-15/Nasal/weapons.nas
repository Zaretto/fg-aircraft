# F-15 Weapons system
# ---------------------------
# ---------------------------
# Richard Harrison (rjh@zaretto.com) Feb  2015 - based on F-14B version by Alexis Bory
# ---------------------------

var AcModel = props.globals.getNode("sim/model/f15");
var SwCoolOffLight   = AcModel.getNode("controls/armament/acm-panel-lights/sw-cool-off-light");
var MslPrepOffLight  = AcModel.getNode("controls/armament/acm-panel-lights/msl-prep-off-light");
var WeaponSelector    = AcModel.getNode("controls/armament/weapon-selector");# 0: gun 1:aim9 2:aim7/aim120 5:mk84
var ArmSwitch        = AcModel.getNode("controls/armament/master-arm-switch");# 0:off 1:armed
var GrSwitch         = AcModel.getNode("controls/armament/gun-rate-switch");
var SysRunning       = AcModel.getNode("systems/armament/system-running");
var GunRunning       = AcModel.getNode("systems/gun/running");
var GunCountAi       = props.globals.getNode("ai/submodels/submodel[4]/count");
var GunCount         = AcModel.getNode("systems/gun/rounds");
var GunReady         = AcModel.getNode("systems/gun/ready");
#var GunStop          = AcModel.getNode("systems/gun/stop", 1);
var GunRateHighLight = AcModel.getNode("controls/armament/acm-panel-lights/gun-rate-high-light");
var WeaponsWeight = props.globals.getNode("sim/model/f15/systems/external-loads/weapons-weight", 1);
var PylonsWeight = props.globals.getNode("sim/model/f15/systems/external-loads/pylons-weight", 1);
var TankssWeight = props.globals.getNode("sim/model/f15/systems/external-loads/tankss-weight", 1);

# smoke stuff:
var Smoke = props.globals.getNode("sim/model/f15/fx/smoke", 1);#double
var SmokeCmd = props.globals.initNode("sim/model/f15/fx/smoke-cmd", 0,"BOOL");
var SmokeMountedL = props.globals.initNode("sim/model/f15/fx/smoke-mnt-left", 0,"BOOL");
var SmokeMountedR = props.globals.initNode("sim/model/f15/fx/smoke-mnt-right", 0,"BOOL");

var Count9 = props.globals.initNode("sim/model/f15/systems/armament/aim9/count", 0,"INT");
var Count7 = props.globals.initNode("sim/model/f15/systems/armament/aim7/count", 0,"INT");
var Count120 = props.globals.initNode("sim/model/f15/systems/armament/aim120/count", 0,"INT");
var Count84 = props.globals.initNode("sim/model/f15/systems/armament/agm/count", 0,"INT");
var CountG = props.globals.initNode("sim/model/f15/systems/gun/rounds", 0,"INT");

# AIM-9 stuff:
var SwCount    = AcModel.getNode("systems/armament/aim9/count");
var SWCoolOn   = AcModel.getNode("controls/armament/acm-panel-lights/sw-cool-on-light");
var SWCoolOff  = AcModel.getNode("controls/armament/acm-panel-lights/sw-cool-off-light");

var Current_srm   = nil;
var Current_agm   = nil;
var Current_mrm   = nil;
var Current_missile   = nil;
var sel_missile_count = 0;

aircraft.data.add( WeaponSelector, ArmSwitch );

var FALSE = 0;
var TRUE  = 1;

setlistener("sim/model/f15/controls/armament/weapon-selector", func(v)
{
    aircraft.arm_selector();
});

var getDLZ = func {
    return pylons.getDLZ();
}

var ccrp = func {
    var weap = pylons.fcs.getSelectedWeapon();
    if (weap != nil and weap.parents[0] == armament.AIM and (weap.type == "MK-84" or weap.type == "GBU-10")) {
        var ccrp_meters = weap.getCCRP(20,0.25);#meters left to release point
        if (ccrp_meters != nil) {
            # this should make the ccrp bomb steering line and the bomb release cue.
            # 
            # the vertical steering line should have same heading deviation as the target and span entirety of HUD
            # the small horizontal cue should have same heading deviation but its vertical position should be middle of HUD when ccrp_meter is 0 and top of HUD when ccrp_meters is 1000 or larger.
            # another fixed small horizontal lines should be in middle of HUD vertical. Horizontal it should follow steering line.
            setprop("sim/model/f15/systems/armament/aim9/ccrp",1);#if ccrp should be displayed in HUD.
            setprop("sim/model/f15/systems/armament/aim9/ccrp-hud-vert", ccrp_meters);# haven't linked this to anything yet.
            return;
        }
    }
    setprop("sim/model/f15/systems/armament/aim9/ccrp",0);
    setprop("sim/model/f15/systems/armament/aim9/ccrp-hud-vert", 0);
}

# Init
var weapons_init = func() {
    print("Initializing F-15 weapons system");

    masw(ArmSwitch);
    update_gun_ready();
    arm_selector();
}

# Main loop
var armament_update = func {
    # Trigered each 0.1 sec by instruments.nas main_loop() if Master Arm Engaged.

    var stick_s = WeaponSelector.getValue();
    
    for (var i = 0;i<10;i+=1) {
        # Pylon lights and count of ready weapons:
        var p = pylons.pylons[i+1];
        var weaps = p.getWeapons();
        if (size(weaps) and weaps[0] != nil) {
            setprop("sim/model/f15/systems/external-loads/station["~p.guiID ~"]/display",1);
        } else {
            setprop("sim/model/f15/systems/external-loads/station["~p.guiID~"]/display",0);
        }
        #populate the payload dialog:
        setprop("sim/model/f15/systems/external-loads/station["~p.guiID~"]/type", getprop("payload/weight["~p.guiID~"]/selected"));
    }
    # Turn sidewinder cooling lights On/Off.
    var aim9_count = pylons.fcs.getAmmoOfType("AIM-9");
    if (stick_s == 1) {
        if (aim9_count > 0) {
            SWCoolOn.setBoolValue(1);
            SWCoolOff.setBoolValue(0);
        } else {
            SWCoolOn.setBoolValue(0);
            SWCoolOff.setBoolValue(1);
        }
    } else {
        SWCoolOn.setBoolValue(0);
        SWCoolOff.setBoolValue(0);
    }
    
    SwCount.setValue(aim9_count);
    Count9.setValue(aim9_count);
    Count7.setValue(pylons.fcs.getAmmoOfType("AIM-7"));
    Count120.setValue(pylons.fcs.getAmmoOfType("AIM-120"));
    Count84.setValue(pylons.fcs.getAmmoOfType("MK-84")+pylons.fcs.getAmmoOfType("GBU-10"));

    update_gun_ready();
    setCockpitLights();
    #ccrp();
}

# Main loop 2
var armament_update2 = func {
    # Trigered each 0.1 sec by instruments.nas main_loop()
    
    # calculate pylon and weapon total mass:
    var pw = getprop("fdm/jsbsim/inertia/pointmass-weight-lbs[13]") + getprop("fdm/jsbsim/inertia/pointmass-weight-lbs[14]");
    var wWeight = 0;
    var pWeight = pw;
    var tWeight = 0;
    var updatePayload = 0;
    for (var i = 0;i<11;i+=1) {
        var ws = pylons.pylons[i+1].getWeapons();
        if ((i == 1 or i==5 or i==9) and (getprop("payload/weight["~i~"]/selected") == "MK-84" or getprop("payload/weight["~i~"]/selected") == "GBU-10") and size(ws) > 0 and ws[0] == nil) {
            # the MK-84 on this station has been released
            setprop("payload/weight["~i~"]/selected","none");
            updatePayload = 1;
        }
        setprop("sim/model/f15/systems/external-loads/station["~i~"]/type", getprop("payload/weight["~i~"]/selected"));
        var mass = pylons.pylons[i+1].getMass();
        wWeight += mass[0];
        pWeight += mass[1];
    }
    if (updatePayload) {
        payload_dialog_reload("update_stores_bombs "~i);
        arm_selector();# because the fire-control.nas will deselect all weapons when the GUI is set to "none" or "Droptank".
    }
    if (aircraft.Centre_External.is_fitted()) {
        tWeight += getprop("payload/weight[5]/weight-lb");
    }
    if (aircraft.WingExternal_L.is_fitted()) {
        tWeight += getprop("payload/weight[1]/weight-lb");
    }
    if (aircraft.WingExternal_R.is_fitted()) {
        tWeight += getprop("payload/weight[9]/weight-lb");
    }

    WeaponsWeight.setDoubleValue(wWeight);
    PylonsWeight.setDoubleValue(pWeight);
    TankssWeight.setDoubleValue(tWeight);
    
    # set internal master-arm.
    setprop("controls/armament/master-arm", ArmSwitch.getValue()>0);
    
    # manage smoke
    if (SmokeCmd.getValue() and (SmokeMountedR.getValue() or SmokeMountedL.getValue())) {
        Smoke.setDoubleValue(1);
    } else {
        Smoke.setDoubleValue(0);
    }
}

var setCockpitLights = func {
    if (ArmSwitch.getValue() > 0 and pylons.fcs.isLock()) {
        setprop("sim/model/f15/systems/armament/lock-light", 1);
    } else {
        setprop("sim/model/f15/systems/armament/lock-light", 0);
    }

    var dlzArray = getDLZ();
    if (dlzArray == nil or size(dlzArray) == 0) {
        setprop("sim/model/f15/systems/armament/launch-light", 0);
    } else {
        if (dlzArray[4] < dlzArray[1]) {
            setprop("sim/model/f15/systems/armament/launch-light", 1);
        } else {
            setprop("sim/model/f15/systems/armament/launch-light", 0);
        }
    }
}


var update_gun_ready = func() {
    var ready = 0;
    if ( ArmSwitch.getValue() and GunCount.getValue() > 0 and getprop("payload/armament/fire-control/serviceable")) {#todo: add elec/hydr requirements here too
        ready = 1;
    }
    GunReady.setBoolValue(ready);
    var real_gcount = GunCountAi.getValue();
    GunCount.setIntValue(real_gcount*5);
    CountG.setIntValue(real_gcount*5);
}

var missile_code_from_ident= func(mty)
{
        if (mty == "AIM-9")
            return "aim9";
        else if (mty == "AIM-7")
            return "aim7";
        else if (mty == "MK-82")
            return "mk82";
        else if (mty == "MK-83")
            return "mk83";
        else if (mty == "MK-84")
            return "mk84";
        else if (mty == "GBU-10")
            return "gbu10";
        else if (mty == "AIM-120")
            return "aim120";
}
var get_sel_missile_count = func()
{
    if (WeaponSelector.getValue() == 5)
    {
        return pylons.fcs.getAmmoOfType("MK-84")+pylons.fcs.getAmmoOfType("GBU-10");
    }
    else if (WeaponSelector.getValue() == 1)
    {
        return pylons.fcs.getAmmoOfType("AIM-9");
    }
    else if (WeaponSelector.getValue() == 2)
    {
        return pylons.fcs.getAmmoOfType("AIM-7")+pylons.fcs.getAmmoOfType("AIM-120");
    }
    return 0;
}



#
#
# F-15 throttle has weapons selector switch with
# (AFT)
# GUN
# SRM = AIM-9 (Sidewinder)
# MRM = AIM-120, AIM-7
# (FWD)

var arm_selector = func() {
    # Checks to do when changing weapons selector
    update_gun_ready();

    var stick_s = WeaponSelector.getValue();
    if ( stick_s == 0 ) {
        pylons.fcs.selectWeapon("20mm Cannon");
    } elsif ( stick_s == 1 ) {
        pylons.fcs.selectWeapon("AIM-9");
    } elsif ( stick_s == 2 ) {
        var p = pylons.fcs.selectWeapon("AIM-120");
        if (p == nil) {
            pylons.fcs.selectWeapon("AIM-7");
        }
    } elsif ( stick_s == 5 ) {
        var p = pylons.fcs.selectWeapon("GBU-10");
        if (p == nil) {
            pylons.fcs.selectWeapon("MK-84");
        }
    } else {
        pylons.fcs.selectNothing();
    }
    setCockpitLights();
}
setlistener(WeaponSelector, arm_selector, nil, 0);

# System start and stop.
# Timers for weapons system status lights.
var system_start = func
{
    print("Weapons System start");
	settimer (func { GunRateHighLight.setBoolValue(1); }, 0.3);
	update_gun_ready();
	SysRunning.setBoolValue(1);
	settimer (func { SwCoolOffLight.setBoolValue(1); }, 0.6);
	settimer (func { MslPrepOffLight.setBoolValue(1); }, 2);
}

var system_stop = func
{
    print("Weapons System stop");
	GunRateHighLight.setBoolValue(0);
	SysRunning.setBoolValue(0);
    setprop("sim/model/f15/systems/armament/launch-light",0);
	
	settimer (func { SwCoolOffLight.setBoolValue(0);SWCoolOn.setBoolValue(0); }, 0.6);
	settimer (func { MslPrepOffLight.setBoolValue(0); }, 1.2);
}


# Controls
var masw = func(v)
{
    logprint(2,"Master arm ",v.getValue());

    if (v.getValue())
    {
        system_start();
    }
    else
    {
        system_stop();
    }
};
setlistener("sim/model/f15/controls/armament/master-arm-switch", masw);

var master_arm_cycle = func()
{
	var master_arm_switch = ArmSwitch.getValue();
    print("arm_cycle: master_arm_switch",master_arm_switch);
	if (master_arm_switch == 0)
    {
		ArmSwitch.setValue(1);
	}
    else
    { 
		ArmSwitch.setValue(0);
	}
}



  ############ Cannon impact messages #####################

var hits_count = 0;
var hit_timer = nil;
var hit_callsign = "";

var Mp = props.globals.getNode("ai/models");
var valid_mp_types = {
  multiplayer: 1, tanker: 1, aircraft: 1, ship: 1, groundvehicle: 1,
};

# Find a MP aircraft close to a given point (code from the Mirage 2000)
var findmultiplayer = func(targetCoord, dist) {
  if(targetCoord == nil) return nil;

  var raw_list = Mp.getChildren();
  var SelectedMP = nil;
  foreach(var c ; raw_list)
  {    
    var is_valid = c.getNode("valid");
    if(is_valid == nil or !is_valid.getBoolValue()) continue;
    
    var type = c.getName();
    
    var position = c.getNode("position");
    var name = c.getValue("callsign");
    if(name == nil or name == "") {
      # fallback, for some AI objects
      var name = c.getValue("name");
    }
    if(position == nil or name == nil or name == "" or !contains(valid_mp_types, type)) continue;

    var lat = position.getValue("latitude-deg");
    var lon = position.getValue("longitude-deg");
    var elev = position.getValue("altitude-ft") * FT2M;

    if(lat == nil or lon == nil or elev == nil) continue;

    var MpCoord = geo.Coord.new().set_latlon(lat, lon, elev);
    var tempoDist = MpCoord.direct_distance_to(targetCoord);
    if(dist > tempoDist) {
      dist = tempoDist;
      SelectedMP = name;
    }
  }
  return SelectedMP;
}

var impact_listener = func {
  var ballistic_name = getprop("/ai/models/model-impact3");
  var ballistic = props.globals.getNode(ballistic_name, 0);
  if (ballistic != nil and ballistic.getName() != "munition") {
    var typeNode = ballistic.getNode("impact/type");
    if (typeNode != nil and typeNode.getValue() != "terrain") {
      var lat = ballistic.getNode("impact/latitude-deg").getValue();
      var lon = ballistic.getNode("impact/longitude-deg").getValue();
      var elev = ballistic.getNode("impact/elevation-m").getValue();
      var impactPos = geo.Coord.new().set_latlon(lat, lon, elev);
      var target = findmultiplayer(impactPos, 80);

      if (target != nil) {
        var typeOrd = ballistic.getNode("name").getValue();

        if(target == hit_callsign) {
          # Previous impacts on same target
          hits_count += 1;
        } else {
          if(hit_timer != nil) {
            # Previous impacts on different target, flush them first
            hit_timer.stop();
            hitmessage(typeOrd);
          }
          hits_count = 1;
          hit_callsign = target;
          hit_timer = maketimer(1, func{hitmessage(typeOrd);});
          hit_timer.singleShot = 1;
          hit_timer.start();
        }
      }
    }
  }
}

var hitmessage = func(typeOrd) {
  #print("inside hitmessage");
  var phrase = typeOrd ~ " hit: " ~ hit_callsign ~ ": " ~ (hits_count*5) ~ " hits";
  if (getprop("payload/armament/msg") == TRUE) {
    print(phrase);
    #print("Second id: "~(151+armament.shells[typeOrd][0]));
    var msg = notifications.ArmamentNotification.new("mhit", 4, -1*(damage.shells[typeOrd][0]+1));
                msg.RelativeAltitude = 0;
                msg.Bearing = 0;
                msg.Distance = hits_count*5;
                msg.RemoteCallsign = hit_callsign; # RJHTODO: maybe handle flares / chaff 
                notifications.hitBridgedTransmitter.NotifyAll(msg);
    damage.damageLog.push("You hit "~hit_callsign~" with "~typeOrd~", "~(hits_count*5)~" times.");
  } else {
    setprop("/sim/messages/atc", phrase);
  }
  hit_callsign = "";
  hit_timer = nil;
  hits_count = 0;
}

# setup impact listener
setlistener("/ai/models/model-impact3", impact_listener, 0, 0);


var flareCount = -1;
var flareStart = -1;

var flareLoop = func {
  # Flare release
  if (getprop("ai/submodels/submodel[5]/flare-release-snd") == nil) {
    setprop("ai/submodels/submodel[5]/flare-release-snd", FALSE);
    setprop("ai/submodels/submodel[5]/flare-release-out-snd", FALSE);
  }
  var flareOn = getprop("ai/submodels/submodel[5]/flare-release-cmd");
  if (flareOn == TRUE and getprop("ai/submodels/submodel[5]/flare-release") == FALSE
      and getprop("ai/submodels/submodel[5]/flare-release-out-snd") == FALSE
      and getprop("ai/submodels/submodel[5]/flare-release-snd") == FALSE) {
    flareCount = getprop("ai/submodels/submodel[5]/count");
    flareStart = getprop("sim/time/elapsed-sec");
    setprop("ai/submodels/submodel[5]/flare-release-cmd", FALSE);
    if (flareCount > 0) {
      # release a flare
      setprop("ai/submodels/submodel[5]/flare-release-snd", TRUE);
      setprop("ai/submodels/submodel[5]/flare-release", TRUE);
      setprop("rotors/main/blade[3]/flap-deg", flareStart);
      setprop("rotors/main/blade[3]/position-deg", flareStart);
      damage.flare_released();
    } else {
      # play the sound for out of flares
      setprop("ai/submodels/submodel[5]/flare-release-out-snd", TRUE);
    }
  }
  if (getprop("ai/submodels/submodel[5]/flare-release-snd") == TRUE and (flareStart + 1) < getprop("sim/time/elapsed-sec")) {
    setprop("ai/submodels/submodel[5]/flare-release-snd", FALSE);
    setprop("rotors/main/blade[3]/flap-deg", 0);
    setprop("rotors/main/blade[3]/position-deg", 0);
  }
  if (getprop("ai/submodels/submodel[5]/flare-release-out-snd") == TRUE and (flareStart + 1) < getprop("sim/time/elapsed-sec")) {
    setprop("ai/submodels/submodel[5]/flare-release-out-snd", FALSE);
  }
  if (flareCount > getprop("ai/submodels/submodel[5]/count")) {
    # A flare was released in last loop, we stop releasing flares, so user have to press button again to release new.
    setprop("ai/submodels/submodel[5]/flare-release", FALSE);
    flareCount = -1;
  }
  settimer(flareLoop, 0.1);
};

flareLoop();

# damage already listens to this, but wont work since its aliased, so we gotta listen to what its aliased to also:
setlistener("sim/model/f15/systems/armament/mp-messaging", func {damage.damageLog.push("Damage is now "~(getprop("sim/model/f15/systems/armament/mp-messaging")?"ON.":"OFF."));}, 1, 0);