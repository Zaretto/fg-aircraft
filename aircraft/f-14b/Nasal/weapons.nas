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


# AIM-9 stuff:
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
		setprop("sim/model/f-14b/systems/external-loads/station["~i~"]/type", getprop("payload/weight["~i~"]/selected"));
		if (getprop("sim/model/f-14b/systems/external-loads/station["~i~"]/selected")) {
			# Check if at least one AIM present on the pylons.
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
	if (stick_s == 2) {
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
}

# Main loop 2
var armament_update2 = func {
	# Trigered each 0.1 sec by instruments.nas main_loop()
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
	setprop("controls/armament/master-arm",ArmSwitch.getValue()==2);
	
	WeaponsWeight.setDoubleValue(wWeight);
    PylonsWeight.setDoubleValue(pWeight);
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
	GunCount.setValue(real_gcount);
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

var last_impact = 0;

var hit_count = 0;

var impact_listener = func {
  if (awg_9.nearest_u != nil and (getprop("sim/time/elapsed-sec")-last_impact) > 1) {
    var ballistic_name = props.globals.getNode("/ai/models/model-impact3",1).getValue();
    var ballistic = props.globals.getNode(ballistic_name, 0);
    if (ballistic != nil and ballistic.getName() != "munition") {
      var typeNode = ballistic.getNode("impact/type");
      if (typeNode != nil and typeNode.getValue() != "terrain") {
        var lat = ballistic.getNode("impact/latitude-deg").getValue();
        var lon = ballistic.getNode("impact/longitude-deg").getValue();
        var impactPos = geo.Coord.new().set_latlon(lat, lon);

        #var track = awg_9.nearest_u.propNode;

        #var x = track.getNode("position/global-x").getValue();
        #var y = track.getNode("position/global-y").getValue();
        #var z = track.getNode("position/global-z").getValue();
        var selectionPos = awg_9.nearest_u.get_Coord();

        var distance = impactPos.distance_to(selectionPos);
        if (distance < 125) {
          last_impact = getprop("sim/time/elapsed-sec");
          var phrase =  ballistic.getNode("name").getValue() ~ " hit: " ~ awg_9.nearest_u.Callsign.getValue();
          if (getprop("payload/armament/msg")) {
            armament.defeatSpamFilter(phrase);
                  #hit_count = hit_count + 1;
          } else {
            setprop("/sim/messages/atc", phrase);
          }
        }
      }
    }
  }
}

# setup impact listener
setlistener("/ai/models/model-impact3", impact_listener, 0, 0);

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