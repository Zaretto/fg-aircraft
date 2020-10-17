var AcModel = props.globals.getNode("sim/model/f-14b");
var SwCoolOffLight   = AcModel.getNode("controls/armament/acm-panel-lights/sw-cool-off-light");
var MslPrepOffLight  = AcModel.getNode("controls/armament/acm-panel-lights/msl-prep-off-light");
var StickSelector    = AcModel.getNode("controls/armament/stick-selector");
var ArmSwitch        = AcModel.getNode("controls/armament/master-arm-switch");
var ArmLever         = AcModel.getNode("controls/armament/master-arm-lever");
var GrSwitch         = AcModel.getNode("controls/armament/gun-rate-switch");
var SysRunning       = AcModel.getNode("systems/armament/system-running");
var GunRunning       = AcModel.getNode("systems/gun/running");
var GunCountAi       = props.globals.getNode("ai/submodels/submodel[3]/count");
var GunCount         = AcModel.getNode("systems/gun/rounds");
var GunReady         = AcModel.getNode("systems/gun/ready");
#var GunStop          = AcModel.getNode("systems/gun/stop", 1);
var GunRateHighLight = AcModel.getNode("controls/armament/acm-panel-lights/gun-rate-high-light");
var WeaponsWeight = props.globals.getNode("sim/model/f-14b/systems/external-loads/weapons-weight", 1);
var PylonsWeight = props.globals.getNode("sim/model/f-14b/systems/external-loads/pylons-weight", 1);

# smoke stuff:
var Smoke = props.globals.getNode("sim/model/f-14b/fx/smoke", 1);#double
var SmokeCmd = props.globals.initNode("sim/model/f-14b/fx/smoke-cmd", 0,"BOOL");
var SmokeMountedL = props.globals.initNode("sim/model/f-14b/fx/smoke-mnt-left", 0,"BOOL");
var SmokeMountedR = props.globals.initNode("sim/model/f-14b/fx/smoke-mnt-right", 0,"BOOL");

# AIM stuff:
var SwCount    = AcModel.getNode("systems/armament/aim9/count");
var SWCoolOn   = AcModel.getNode("controls/armament/acm-panel-lights/sw-cool-on-light");
var SWCoolOff  = AcModel.getNode("controls/armament/acm-panel-lights/sw-cool-off-light");
#var SwSoundVol = AcModel.getNode("systems/armament/aim9/sound-volume");

var aim9_count = 0;


aircraft.data.add( StickSelector, ArmLever, ArmSwitch );

var FALSE = 0;
var TRUE  = 1;





# Init
var weapons_init = func() {
	print("Initializing F-14B weapons system");
	ArmSwitch.setValue(1);
	ArmLever.setBoolValue(0);
	system_stop();
	SysRunning.setBoolValue(0);
	update_gun_ready();
	arm_selector();
}


# Main loop
var armament_update = func {
	# Trigered each 0.1 sec by instruments.nas main_loop() if Master Arm Engaged.

	# Check AIM-9 selected with armament panel switches 1 and 8.
	# Note in FAD light config, S1 and S8 also have AIM-9.
	var stick_s = StickSelector.getValue();
	var ag = getprop("sim/model/f-14b/controls/pilots-displays/mode/ag-bt");
	aim9_count = 0;
	for (var i = 0;i<10;i+=1) {
		#populate the payload dialog:
		setprop("sim/model/f-14b/systems/external-loads/station["~i~"]/type", getprop("payload/weight["~i~"]/selected"));
		# Pylon lights and count of ready weapons:
		if (getprop("sim/model/f-14b/systems/external-loads/station["~i~"]/selected")) {
			var weaps = pylons.pylons[i+1].getWeapons();
			if (size(weaps) and weaps[0] != nil and weaps[0].type == "AIM-9" and stick_s == 2) {
				setprop("sim/model/f-14b/systems/external-loads/station["~i~"]/display",1);
				aim9_count += 1;
			} elsif (size(weaps) and weaps[0] != nil and (weaps[0].type == "AIM-7" or weaps[0].type == "AIM-54") and stick_s == 3) {
				setprop("sim/model/f-14b/systems/external-loads/station["~i~"]/display",1);
				aim9_count += 1;
			} elsif (size(weaps) and weaps[0] != nil and weaps[0].type == "MK-83" and ag) {
				setprop("sim/model/f-14b/systems/external-loads/station["~i~"]/display",1);
				aim9_count += 1;
			} else {
				setprop("sim/model/f-14b/systems/external-loads/station["~i~"]/display",0);
			}
		} else {
			setprop("sim/model/f-14b/systems/external-loads/station["~i~"]/display",0);
		}
	}
	# Turn sidewinder cooling lights On/Off.
	if (stick_s == 2 and !ag) {
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
	update_gun_ready();
	setCockpitLights();
	#ccrp();
}

# Main loop 2
var armament_update2 = func {
	# Trigered each 0.1 sec by instruments.nas main_loop()
	
	# calculate pylon and weapon total mass:
	var wWeight = 0;
	var pWeight = 0;
	for (var i = 0;i<10;i+=1) {
		setprop("sim/model/f-14b/systems/external-loads/station["~i~"]/type", getprop("payload/weight["~i~"]/selected"));
		if (ArmSwitch.getValue() != 2) {
			setprop("sim/model/f-14b/systems/external-loads/station["~i~"]/display",0);
		}
		if (i != 2 and i != 7) {#TODO: run less often
			var mass = pylons.pylons[i+1].getMass();
			wWeight += mass[0];
			pWeight += mass[1];
		}
	}
	WeaponsWeight.setDoubleValue(wWeight);
    PylonsWeight.setDoubleValue(pWeight);
    
	# set internal master-arm.
	setprop("controls/armament/master-arm",ArmSwitch.getValue()==2);
	
	# manage smoke
    if (SmokeCmd.getValue() and (SmokeMountedR.getValue() or SmokeMountedL.getValue())) {
    	Smoke.setDoubleValue(1);
	} else {
		Smoke.setDoubleValue(0);
	}
}

var ccrp = func {
	var weap = pylons.fcs.getSelectedWeapon();
	if (weap != nil and weap.parents[0] == armament.AIM and weap.type == "MK-83") {
		var ccrp_meters = weap.getCCRP(20,0.25);#meters left to release point
		if (ccrp_meters != nil) {
			# this should make the ccrp bomb steering line and the bomb release cue.
			# 
			# the vertical steering line should have same heading deviation as the target and span entirety of HUD
			# the small horizontal cue should have same heading deviation but its vertical position should be middle of HUD when ccrp_meter is 0 and top of HUD when ccrp_meters is 1000 or larger.
			# another fixed small horizontal lines should be in middle of HUD vertical. Horizontal it should follow steering line.
			setprop("sim/model/f-14b/systems/armament/aim9/ccrp",1);#if ccrp should be displayed in HUD.
			setprop("sim/model/f-14b/systems/armament/aim9/ccrp-hud-vert", ccrp_meters);# haven't linked this to anything yet.
			return;
		}
	}
	setprop("sim/model/f-14b/systems/armament/aim9/ccrp",0);
	setprop("sim/model/f-14b/systems/armament/aim9/ccrp-hud-vert", 0);
}

var getDLZ = func {
    return pylons.getDLZ();
}

var setCockpitLights = func {
	if (ArmSwitch.getValue() > 1 and pylons.fcs.isLock()) {
		setprop("sim/model/f-14b/systems/armament/lock-light", 1);
	} else {
		setprop("sim/model/f-14b/systems/armament/lock-light", 0);
	}
	var dlzArray = getDLZ();
	if (dlzArray == nil or size(dlzArray) == 0) {
	    setprop("sim/model/f-14b/systems/armament/launch-light", 0);
	} else {
		if (dlzArray[4] < dlzArray[1]) {
			setprop("sim/model/f-14b/systems/armament/launch-light", 1);
		} else {
			setprop("sim/model/f-14b/systems/armament/launch-light", 0);
		}
	}
}

var update_gun_ready = func() {
	var ready = 0;
	if ( ArmSwitch.getValue() == 2 and GunCount.getValue() > 0 and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>=20 and getprop("fdm/jsbsim/systems/electrics/ac-essential-bus1")>=70 and getprop("fdm/jsbsim/systems/hydraulics/flight-system-pressure") and getprop("payload/armament/fire-control/serviceable")) {
		ready = 1;
	}
	GunReady.setBoolValue(ready);
	var real_gcount = GunCountAi.getValue();
	GunCount.setValue(real_gcount*5);
}

# System start and stop.
# Timers for weapons system status lights.
var system_start = func {
	settimer (func { GunRateHighLight.setBoolValue(1); }, 0.3);
	update_gun_ready();
	SysRunning.setBoolValue(1);
	settimer (func { SwCoolOffLight.setBoolValue(1); }, 0.6);
	settimer (func { MslPrepOffLight.setBoolValue(1); }, 2);
}

var system_stop = func {
	GunRateHighLight.setBoolValue(0);
	SysRunning.setBoolValue(0);
	#SwSoundVol.setValue(0);
	settimer (func { SwCoolOffLight.setBoolValue(0);SWCoolOn.setBoolValue(0); }, 0.6);
	settimer (func { MslPrepOffLight.setBoolValue(0); }, 1.2);
}


# Controls
var master_arm_lever_toggle = func {
	var master_arm_lever = ArmLever.getBoolValue(); # 0 = Closed, 1 = Open.
	var master_arm_switch = ArmSwitch.getValue();
	if ( master_arm_lever and master_arm_switch > 1 ) {
		ArmSwitch.setValue(1);
	}
	ArmLever.setBoolValue( ! master_arm_lever );
	if (master_arm_switch == 2) {
		ArmSwitch.setValue(1);
		system_stop();
	}
}

var master_arm_switch = func(a) {
	var master_arm_lever = ArmLever.getBoolValue();
	var master_arm_switch = ArmSwitch.getValue(); # 2 = On, 1 = Off, 0 = training (not operational yet).
	if (a == 1) {
		if (master_arm_switch == 0) {
			ArmSwitch.setValue(1);
		} elsif (master_arm_switch == 1 and master_arm_lever) {
			ArmSwitch.setValue(2);
			system_start();
		}
	} else {
		if (master_arm_switch == 1) {
			ArmSwitch.setDoubleValue(0);
		} elsif (master_arm_switch == 2) {
			ArmSwitch.setValue(1);
			system_stop();
		}
	}
	setCockpitLights();
}

var master_arm_cycle = func() {
	# Keyb. shorcut. Safety lever automaticly set. 
	var master_arm_lever = ArmLever.getBoolValue();
	var master_arm_switch = ArmSwitch.getValue();
	if (master_arm_switch == 0) {
		# Training --> Off.
		ArmSwitch.setValue(1);
		ArmLever.setBoolValue(0);
	} elsif (master_arm_switch == 1) {
		# Off --> 0n.
		ArmSwitch.setValue(2);
		ArmLever.setBoolValue(1);
		system_start();
		SysRunning.setBoolValue(1);
	} elsif (master_arm_switch == 2)  {
		# Training mode (not operational yet).
		ArmSwitch.setValue(0);
		ArmLever.setBoolValue(0);
		system_stop();
		SysRunning.setBoolValue(0);
	}
	setCockpitLights();
}

var arm_selector = func() {
	# Checks to do when rotating the wheel on the stick.
	update_gun_ready();
	var aa = getprop("sim/model/f-14b/controls/pilots-displays/mode/aa-bt");
	var ag = getprop("sim/model/f-14b/controls/pilots-displays/mode/ag-bt");
	if (aa) {
		var stick_s = StickSelector.getValue();
		if ( stick_s == 0 ) {
			pylons.fcs.selectNothing();
		} elsif ( stick_s == 1 ) {
			pylons.fcs.selectWeapon("20mm Cannon");
		} elsif ( stick_s == 2 ) {
			pylons.fcs.selectWeapon("AIM-9");
		} elsif ( stick_s == 3 ) {
			var p = pylons.fcs.selectWeapon("AIM-54");
			if (p == nil) {
				pylons.fcs.selectWeapon("AIM-7");
			}
		}
	} elsif (ag) {
		pylons.fcs.selectWeapon("MK-83");
	} else {
		pylons.fcs.selectNothing();
	}
	#armament_update();
	setCockpitLights();
}

# listeners that call the arm_selector
setlistener(StickSelector, arm_selector, nil, 0);
setlistener("sim/model/f-14b/controls/pilots-displays/mode/aa-bt", arm_selector, nil, 0);
setlistener("sim/model/f-14b/controls/pilots-displays/mode/ag-bt", arm_selector, nil, 0);

var station_selector = func(n, v) {
	# n = station number, v = up (-1) or down (1) or toggle (0) as there is two kinds of switches.
	if ( n == 3 or n == 4 or n == 5 or n == 6 ) {
		# Only up/neutral allowed.
		var selector = "sim/model/f-14b/controls/armament/station-selector[" ~ n ~ "]";
		var state = getprop(selector);
		if (state == -1000){
			# toggle value between 0 and -1
			state = -(-state - 1);
		}
		if (state != -1) {
			state = -1;
		} else {
			state = 0;
		}
		setprop(selector, state);
		if ( state == 0 ) {
			setprop("sim/model/f-14b/systems/external-loads/station["~(n)~"]/selected",0);
		} elsif ( state == -1 ) {
			setprop("sim/model/f-14b/systems/external-loads/station["~(n)~"]/selected",1);
		}
	}
	if ( n == 0 or n == 7 ) {
		# Only up/down allowed.
		var selector = "sim/model/f-14b/controls/armament/station-selector[" ~ n ~ "]";
		var state = getprop(selector);
		state += v;
		if ( state < -1 ) {
			state = -1;
		} elsif ( state > 1 ) {
			state = 1;
		}
		setprop(selector, state);
		if ( state == -1 ) {
			if ( n == 0 ) {
				setprop("sim/model/f-14b/systems/external-loads/station[0]/selected",0);
				setprop("sim/model/f-14b/systems/external-loads/station[1]/selected",1);
			} else {
				setprop("sim/model/f-14b/systems/external-loads/station[8]/selected",1);
				setprop("sim/model/f-14b/systems/external-loads/station[9]/selected",0);
			}
		} elsif ( state == 0 ) {
			if ( n == 0 ) {
				setprop("sim/model/f-14b/systems/external-loads/station[0]/selected",0);
				setprop("sim/model/f-14b/systems/external-loads/station[1]/selected",0);
			} else {
				setprop("sim/model/f-14b/systems/external-loads/station[8]/selected",0);
				setprop("sim/model/f-14b/systems/external-loads/station[9]/selected",0);
			}
		} elsif ( state == 1 ) {
			if ( n == 0 ) {
				setprop("sim/model/f-14b/systems/external-loads/station[0]/selected",1);
				setprop("sim/model/f-14b/systems/external-loads/station[1]/selected",0);
			} else {
				setprop("sim/model/f-14b/systems/external-loads/station[8]/selected",0);
				setprop("sim/model/f-14b/systems/external-loads/station[9]/selected",1);
			}
		}
	}
	arm_selector();
}

var station_selector_cycle = func() {
	# Fast selector, selects with one keyb shorcut all AIM-9 or nothing.
	# Only to choices ATM.
	var s = 0;
	var p0 = getprop("sim/model/f-14b/controls/armament/station-selector[0]");
	var p7 = getprop("sim/model/f-14b/controls/armament/station-selector[7]");
	if ( p0 < 1 or p7 < 1 ) { s = 1; }
	setprop("sim/model/f-14b/controls/armament/station-selector[0]", s);
	setprop("sim/model/f-14b/controls/armament/station-selector[7]", s);
	setprop("sim/model/f-14b/systems/external-loads/station[1]/selected",s);
	setprop("sim/model/f-14b/systems/external-loads/station[2]/selected",0);
	setprop("sim/model/f-14b/systems/external-loads/station[9]/selected",0);
	setprop("sim/model/f-14b/systems/external-loads/station[10]/selected",s);
	#armament_update();
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
  var phrase = typeOrd ~ " hit: " ~ hit_callsign ~ ": " ~ hits_count ~ " hits";
  if (getprop("payload/armament/msg") == TRUE) {
  	print(phrase);
  	#print("Second id: "~(151+armament.shells[typeOrd][0]));
    var msg = notifications.ArmamentNotification.new("mhit", 4, 111+armament.shells[typeOrd][0]);
		        msg.RelativeAltitude = 0;
		        msg.Bearing = 0;
		        msg.Distance = hits_count;
		        msg.RemoteCallsign = hit_callsign; # RJHTODO: maybe handle flares / chaff 
		        f14.hitBridgedTransmitter.NotifyAll(msg);
	armament.damageLog.push("You hit "~hit_callsign~" with "~typeOrd~", "~hits_count~" times.");
  } else {
    setprop("/sim/messages/atc", phrase);
  }
  hit_callsign = "";
  hit_timer = nil;
  hits_count = 0;
}

# setup impact listener
setlistener("/ai/models/model-impact3", impact_listener, 0, 0);



###################### end cannon hit stuff #########################


var flareCount = -1;
var flareStart = -1;

var flareLoop = func {
  # Flare release
  if (getprop("ai/submodels/submodel[4]/flare-release-snd") == nil) {
    setprop("ai/submodels/submodel[4]/flare-release-snd", FALSE);
    setprop("ai/submodels/submodel[4]/flare-release-out-snd", FALSE);
  }
  var flareOn = getprop("ai/submodels/submodel[4]/flare-release-cmd");
  if (flareOn == TRUE and getprop("ai/submodels/submodel[4]/flare-release") == FALSE
      and getprop("ai/submodels/submodel[4]/flare-release-out-snd") == FALSE
      and getprop("ai/submodels/submodel[4]/flare-release-snd") == FALSE) {
    flareCount = getprop("ai/submodels/submodel[4]/count");
    flareStart = getprop("sim/time/elapsed-sec");
    setprop("ai/submodels/submodel[4]/flare-release-cmd", FALSE);
    if (flareCount > 0) {
      # release a flare
      setprop("ai/submodels/submodel[4]/flare-release-snd", TRUE);
      setprop("ai/submodels/submodel[4]/flare-release", TRUE);
      setprop("rotors/main/blade[3]/flap-deg", flareStart);
      setprop("rotors/main/blade[3]/position-deg", flareStart);
    } else {
      # play the sound for out of flares
      setprop("ai/submodels/submodel[4]/flare-release-out-snd", TRUE);
    }
  }
  if (getprop("ai/submodels/submodel[4]/flare-release-snd") == TRUE and (flareStart + 1) < getprop("sim/time/elapsed-sec")) {
    setprop("ai/submodels/submodel[4]/flare-release-snd", FALSE);
    setprop("rotors/main/blade[3]/flap-deg", 0);
    setprop("rotors/main/blade[3]/position-deg", 0);
  }
  if (getprop("ai/submodels/submodel[4]/flare-release-out-snd") == TRUE and (flareStart + 1) < getprop("sim/time/elapsed-sec")) {
    setprop("ai/submodels/submodel[4]/flare-release-out-snd", FALSE);
  }
  if (flareCount > getprop("ai/submodels/submodel[4]/count")) {
    # A flare was released in last loop, we stop releasing flares, so user have to press button again to release new.
    setprop("ai/submodels/submodel[4]/flare-release", FALSE);
    flareCount = -1;
  }
  settimer(flareLoop, 0.1);
};

flareLoop();