var AcModel = props.globals.getNode("sim/model/f-14b");
var SwCoolOffLight   = AcModel.getNode("controls/armament/acm-panel-lights/sw-cool-off-light");
var SwTempTime       = AcModel.getNode("controls/armament/acm-panel-lights/sw-temp-time");
var SwTempTimeLeft   = AcModel.getNode("controls/armament/acm-panel-lights/sw-temp-time-remaining");
var MslPrepOffLight  = AcModel.getNode("controls/armament/acm-panel-lights/msl-prep-off-light");
var MslPrepOnLight   = AcModel.getNode("controls/armament/acm-panel-lights/msl-prep-on-light");
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
var SmokeActive = AcModel.getNode("fx/smoke-colors", 1);#double
var SmokeColor = AcModel.getNode("fx/smoke-colors-demand", 1);#double
var SmokeCmd = AcModel.initNode("fx/smoke-cmd", 0,"BOOL");
var SmokeMountedL = AcModel.initNode("fx/smoke-mnt-left", 0,"BOOL");
var SmokeMountedR = AcModel.initNode("fx/smoke-mnt-right", 0,"BOOL");

# AIM stuff:
var SwCount    = AcModel.getNode("systems/armament/aim9/count");
var SWCoolOn   = AcModel.getNode("controls/armament/acm-panel-lights/sw-cool-on-light");
var SWCoolOff  = AcModel.getNode("controls/armament/acm-panel-lights/sw-cool-off-light");
var AgMode     = AcModel.getNode("/controls/pilots-displays/mode/ag-bt",1);
var Aim9Volume    = props.globals.getNode("payload/armament/aim-9/sound-volume",1);
var Aim9VolumeBool= props.globals.getNode("payload/armament/aim-9/sound-on-off",1);
var Aim9SeamLight = AcModel.getNode("controls/armament/acm-panel-lights/seam-lock-light",1);
var Aim9TrackVol  = props.globals.getNode("payload/armament/aim-9/vol-track", 1);
var TriggerHotLight = AcModel.getNode("controls/armament/acm-panel-lights/hot-trig-light",1);

var aim9_count = 0;

var STATION_ID_1 = 1;
var STATION_ID_2 = 2;
var STATION_ID_3 = 3;
var STATION_ID_4 = 4;
var STATION_ID_5 = 5;
var STATION_ID_6 = 6;
var STATION_ID_7 = 7;
var STATION_ID_8 = 8;

var STICK_SELECTOR_ID_OFF = 0;
var STICK_SELECTOR_ID_GUN = 2;
var STICK_SELECTOR_ID_SW = 2;
var STICK_SELECTOR_ID_SP_PH = 3;
var mslPrep = 0;
  
# maps from selected stations to the internal payload array for the pylons.
# map members:
# - sel_type       : Stick Selector
# - selector_index : index into sim/model/f-14b/controls/armament/station-selector[#]
# - arm_index      : index into sim/model/f-14b/systems/external-loads/station[#]/selected
# - selector_value : value to match in selector_index
# - types          : string array to match against
#-----------------
# for the Sidewinders the outboard station must be the last in the list because this will be what is 
# left selected when two sidewinders are loaded onto station-1
var StationSel_map = [
 { sel_type : STICK_SELECTOR_ID_SW,    selector_index : 1, arm_index : 1, selector_value : -1, valid_types : ["AIM-9"]},
 { sel_type : STICK_SELECTOR_ID_SW,    selector_index : 1, arm_index : 0, selector_value :  1, valid_types : ["AIM-9"]},
 { sel_type : STICK_SELECTOR_ID_SW,    selector_index : 8, arm_index : 8, selector_value : -1, valid_types : ["AIM-9"]},
 { sel_type : STICK_SELECTOR_ID_SW,    selector_index : 8, arm_index : 9, selector_value :  1, valid_types : ["AIM-9"]},
 { sel_type : STICK_SELECTOR_ID_SP_PH, selector_index : 1, arm_index : 1, selector_value :  -1, valid_types : ["AIM-7", "AIM-54"]},
 { sel_type : STICK_SELECTOR_ID_SP_PH, selector_index : 3, arm_index : 3, selector_value :  -1, valid_types : ["AIM-7", "AIM-54"]},
 { sel_type : STICK_SELECTOR_ID_SP_PH, selector_index : 4, arm_index : 4, selector_value :  -1, valid_types : ["AIM-7", "AIM-54"]},
 { sel_type : STICK_SELECTOR_ID_SP_PH, selector_index : 5, arm_index : 5, selector_value :  -1, valid_types : ["AIM-7", "AIM-54"]},
 { sel_type : STICK_SELECTOR_ID_SP_PH, selector_index : 6, arm_index : 6, selector_value :  -1, valid_types : ["AIM-7", "AIM-54"]},
 { sel_type : STICK_SELECTOR_ID_SP_PH, selector_index : 8, arm_index : 8, selector_value :  -1, valid_types : ["AIM-7", "AIM-54"]},
];

aircraft.data.add( StickSelector, ArmLever, ArmSwitch );

var FALSE = 0;
var TRUE  = 1;
var stick_s = StickSelector.getValue();
var ag = 0;

# Init
var weapons_init = func() {
	print("Initializing F-14B weapons system");
	
	SwTempTimeLeft.setValue(7200);
	ArmSwitch.setValue(pylons.ARM_OFF);
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
	stick_s = StickSelector.getValue();
	ag = AgMode.getValue();
	aim9_count = 0;
	for (var i = 0;i<10;i+=1) {
		#populate the payload dialog:
		setprop("sim/model/f-14b/systems/external-loads/station["~i~"]/type", getprop("payload/weight["~i~"]/selected"));
		# Pylon lights and count of ready weapons:
		if (getprop("sim/model/f-14b/systems/external-loads/station["~i~"]/selected")) {
			var weaps = pylons.pylons[i+1].getWeapons();
			if (size(weaps) and weaps[0] != nil and weaps[0].type == "AIM-9" and stick_s == STICK_SELECTOR_ID_SW) {
				setprop("sim/model/f-14b/systems/external-loads/station["~i~"]/display",1);
				aim9_count += 1;
			} elsif (size(weaps) and weaps[0] != nil and (weaps[0].type == "AIM-7" or weaps[0].type == "AIM-54") and stick_s == STICK_SELECTOR_ID_SP_PH) {
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
	if (stick_s ==  STICK_SELECTOR_ID_SW and !ag) {
		# cool after 30 seconds
		if ( SwTempTime.getValue() >= 30) 
			mslPrep = 2;
		else
			mslPrep = 1;

		if (aim9_count > 0) {
			SWCoolOn.setBoolValue(1);
			SWCoolOff.setBoolValue(0);
		} else {
			SWCoolOn.setBoolValue(0);
			SWCoolOff.setBoolValue(1);
			mslPrep = 1;
		}
	} else {
		SWCoolOn.setBoolValue(0);
		SWCoolOff.setBoolValue(0);
		mslPrep = 0;
	}

	if (mslPrep == 1){
		MslPrepOnLight.setBoolValue(0);
		MslPrepOffLight.setBoolValue(1);
	}
	else if (mslPrep == 2){
		MslPrepOnLight.setBoolValue(1);
		MslPrepOffLight.setBoolValue(0);
	}
	else {
		MslPrepOnLight.setBoolValue(0);
		MslPrepOffLight.setBoolValue(0);
	}

	SwCount.setValue(aim9_count);
	update_gun_ready();
	setCockpitLights();
	#ccrp();
	ccip();
}

# Main loop 2
var armament_update2 = func {
	# Trigered each 0.1 sec by instruments.nas main_loop()
	
	# calculate pylon and weapon total mass:
	var wWeight = 0;
	var pWeight = 0;
	for (var i = 0;i<10;i+=1) {
		setprop("sim/model/f-14b/systems/external-loads/station["~i~"]/type", getprop("payload/weight["~i~"]/selected"));
		if (ArmSwitch.getValue() == pylons.ARM_OFF) {
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

	if (SysRunning.getBoolValue() and SwCount.getValue() > 0){
		# SwTempTimeLeft is the amount of time left. this simulates the
		# limited supply of coolant. Time based for simplicity.
		SwTempTimeLeft.setValue(math.max(0,SwTempTimeLeft.getValue() - 0.1));
		if (SwTempTimeLeft.getValue() > 0)
			SwTempTime.setValue(math.min(30,  SwTempTime.getValue() + 0.1));
	}
	else{
		# for simplicity we just count the time as it generally takes
		# 30 seconds for the missiles to be cooled.
		SwTempTime.setValue(math.max(0, SwTempTime.getValue() - 0.1));
	}
	
	# manage smoke
    if (SmokeCmd.getValue() and (SmokeMountedR.getValue() or SmokeMountedL.getValue())) {
    	SmokeActive.setIntValue(SmokeColor.getIntValue());
	} else {
		SmokeActive.setIntValue(0);
	}
	
    Aim9SeamLight.setBoolValue(SysRunning.getBoolValue() and Aim9VolumeBool.getValue() and Aim9Volume.getValue() == Aim9TrackVol.getValue());
    TriggerHotLight.setBoolValue(SysRunning.getBoolValue() and pylons.fcs.weaponHot());
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

var ccip = func {
	if (!ccipTimer.isRunning) ccipTimer.start();
}

var ccip_loop = func {
	var weap = pylons.fcs.getSelectedWeapon();
	if (weap != nil and weap.parents[0] == armament.AIM and weap.type == "MK-83") {
		var ccip_result = weap.getCCIPadv(20,0.25);# Simulate max 20s drop, with 0.25s intervals.
		if (ccip_result != nil) {
			setHUDDegPosFromGPS(ccip_result[0]);
			setprop("sim/hud/aim/show", 1);#if ccip should be displayed in HUD.		
		} else {
			setprop("sim/hud/aim/show", 0);
		}
		return;
	}
	setprop("sim/hud/aim/show", 0);
	ccipTimer.stop();
}

var ccipTimer = maketimer(0.05, ccip_loop);

setHUDDegPosFromGPS = func (gpsCoord) {
		var crft = awg_9.self.getCoord();
		var ptch = vector.Math.getPitch(crft, gpsCoord);
	    var dst  = crft.direct_distance_to(gpsCoord);
	    var brng = crft.course_to(gpsCoord);
	    var hrz  = math.cos(ptch*D2R)*dst;

	    var vel_gz = -math.sin(ptch*D2R)*dst;
	    var vel_gx = math.cos(brng*D2R) *hrz;
	    var vel_gy = math.sin(brng*D2R) *hrz;
	    

	    var yaw   = awg_9.self.getHeading() * D2R;
	    var roll  = awg_9.self.getRoll()    * D2R;
	    var pitch = awg_9.self.getPitch()   * D2R;

	    var sy = math.sin(yaw);   cy = math.cos(yaw);
	    var sr = math.sin(roll);  cr = math.cos(roll);
	    var sp = math.sin(pitch); cp = math.cos(pitch);
	 
	    var vel_bx = vel_gx * cy * cp
	               + vel_gy * sy * cp
	               + vel_gz * -sp;
	    var vel_by = vel_gx * (cy * sp * sr - sy * cr)
	               + vel_gy * (sy * sp * sr + cy * cr)
	               + vel_gz * cp * sr;
	    var vel_bz = vel_gx * (cy * sp * cr + sy * sr)
	               + vel_gy * (sy * sp * cr - cy * sr)
	               + vel_gz * cp * cr;
	 
	    var dir_y  = math.atan2(round0_(vel_bz), math.max(vel_bx, 0.001)) * R2D;
	    var dir_x  = math.atan2(round0_(vel_by), math.max(vel_bx, 0.001)) * R2D;

	    setprop("sim/hud/aim/pitch", -dir_y);
		setprop("sim/hud/aim/yaw", dir_x);
}

var round0_ = func(x) {
	return math.abs(x) > 0.01 ? x : 0;
}

var getDLZ = func {
    return pylons.getDLZ();
}

var setCockpitLights = func {
	if (ArmSwitch.getValue() != pylons.ARM_OFF and pylons.fcs.isLock()) {
		setprop("sim/model/f-14b/systems/armament/lock-light", 1);
	} else {
		setprop("sim/model/f-14b/systems/armament/lock-light", 0);
	}
	var dlzShow = 0;
	var dlzArray = getDLZ();
	if (dlzArray == nil or size(dlzArray) == 0) {
	    setprop("sim/model/f-14b/systems/armament/launch-light", 0);
	} else {
		if (dlzArray[4] < dlzArray[1]) {
			setprop("sim/model/f-14b/systems/armament/launch-light", 1);
		} else {
			setprop("sim/model/f-14b/systems/armament/launch-light", 0);
		}
		var dlzValue = 0;
		var dlzTarget = dlzArray[4];
		var dlzMax = dlzArray[0];
		var dlzOptimistic = dlzArray[1];
		var dlzNez = dlzArray[2];
		var dlzMin = dlzArray[3];
		
		if (dlzTarget < dlzMin) {
			dlzValue = 0;
		} elsif (dlzTarget < dlzNez) {
			dlzValue = extrapolate(dlzTarget, dlzMin, dlzNez, 0, 10);
		} elsif (dlzTarget < dlzOptimistic) {
			dlzValue = extrapolate(dlzTarget, dlzNez, dlzOptimistic, 10, 20);
		} elsif (dlzTarget < dlzMax) {
			dlzValue = extrapolate(dlzTarget, dlzOptimistic, dlzMax, 20, 30);
		} else {
			dlzValue = 30;
		}
		setprop("sim/hud/dlz/value", dlzValue);
		dlzShow = 1;
	}
	setprop("sim/hud/dlz/show", dlzShow);
}

var extrapolate = func (x, x1, x2, y1, y2) {
    return y1 + ((x - x1) / (x2 - x1)) * (y2 - y1);
}

var update_gun_ready = func() {
	var ready = 0;
	if ( ArmSwitch.getValue() != pylons.ARM_OFF and GunCount.getValue() > 0 and getprop("fdm/jsbsim/systems/electrics/dc-main-bus")>=20 and getprop("fdm/jsbsim/systems/electrics/ac-essential-bus1")>=70 and getprop("fdm/jsbsim/systems/hydraulics/flight-system-pressure") and getprop("payload/armament/fire-control/serviceable")) {
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
	settimer (func { MslPrepOnLight.setBoolValue(1);MslPrepOffLight.setBoolValue(0);}, 30);
	settimer (func { MslPrepOnLight.setBoolValue(0);MslPrepOffLight.setBoolValue(1); }, 0.1);
}

var system_stop = func {
	GunRateHighLight.setBoolValue(0);
	SysRunning.setBoolValue(0);
	#SwSoundVol.setValue(0);
	settimer (func { SwCoolOffLight.setBoolValue(0);SWCoolOn.setBoolValue(0); }, 0.6);
	settimer (func { MslPrepOnLight.setBoolValue(0);MslPrepOffLight.setBoolValue(0);}, 1.2);
}


# Controls
var master_arm_lever_toggle = func {
	var master_arm_lever = ArmLever.getBoolValue(); # 0 = Closed, 1 = Open.
	var master_arm_switch = ArmSwitch.getValue();
	if ( master_arm_lever and master_arm_switch == pylons.ARM_ARM ) {
		ArmSwitch.setValue(pylons.ARM_OFF);
	}
	ArmLever.setBoolValue( ! master_arm_lever );
	if (master_arm_switch == pylons.ARM_ARM) {
		ArmSwitch.setValue(pylons.ARM_OFF);
		system_stop();
	}
}

var master_arm_switch = func(a) {
	var master_arm_lever = ArmLever.getBoolValue();
	var master_arm_switch = ArmSwitch.getValue(); # 2 = On, 1 = Off, 0 = training (not operational yet).
	if (a == 1) {
		if (master_arm_switch == pylons.ARM_SIM) {
			ArmSwitch.setValue(pylons.ARM_OFF);
		} elsif (master_arm_switch == pylons.ARM_OFF and master_arm_lever) {
			ArmSwitch.setValue(pylons.ARM_ARM);
			system_start();
		}
	} else {
		if (master_arm_switch == pylons.ARM_OFF) {
			ArmSwitch.setValue(pylons.ARM_SIM);
			system_start();
		} elsif (master_arm_switch == pylons.ARM_ARM) {
			ArmSwitch.setValue(pylons.ARM_OFF);
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
		ArmSwitch.setValue(pylons.ARM_OFF);
		ArmLever.setBoolValue(0);
	} elsif (master_arm_switch == 1) {
		# Off --> 0n.
		ArmSwitch.setValue(pylons.ARM_ARM);
		ArmLever.setBoolValue(1);
		system_start();
		SysRunning.setBoolValue(1);
	} elsif (master_arm_switch == 2)  {
		# Training mode (not operational yet).
		ArmSwitch.setValue(pylons.ARM_SIM);
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
var selector = "";
var selector_state = 0;
var get_armament_selector= func(station_number){
	return "sim/model/f-14b/controls/armament/station-selector[" ~ station_number ~ "]";
}
# Station switches are sim/model/f-14b/controls/armament/station-selector[#] where # 1..8
#
# The station 1 and 8 switches have two positions which are mapped 
# to external-loads/station[#]/selected
#  1 : 0 and 1
#  8:  8 and 9
# the rest are a 1 to 1 mapping from 2..8 - so the numbers line up between stations and payload
# because 0 is before and 9 after.
#
# so the full mapping expanded is:
#
# sim/model/f-14b/controls/armament/station-selector[1] = 0
#   sim/model/f-14b/systems/external-loads/station[0]/selected -> 0
#   sim/model/f-14b/systems/external-loads/station[1]/selected -> 0
#
# sim/model/f-14b/controls/armament/station-selector[2] = 0
#   sim/model/f-14b/systems/external-loads/station[2]/selected -> 0
#
# sim/model/f-14b/controls/armament/station-selector[3] = 0
#   sim/model/f-14b/systems/external-loads/station[3]/selected -> 0
#
# sim/model/f-14b/controls/armament/station-selector[4] = 0
#   sim/model/f-14b/systems/external-loads/station[4]/selected -> 0
#
# sim/model/f-14b/controls/armament/station-selector[5] = 0
#   sim/model/f-14b/systems/external-loads/station[5]/selected -> 0
#
# sim/model/f-14b/controls/armament/station-selector[6] = 0
#   sim/model/f-14b/systems/external-loads/station[6]/selected -> 0
#
# sim/model/f-14b/controls/armament/station-selector[7] = 0
#   sim/model/f-14b/systems/external-loads/station[7]/selected -> 0
#
# sim/model/f-14b/controls/armament/station-selector[8] = 0
#   sim/model/f-14b/systems/external-loads/station[8]/selected -> 0
#   sim/model/f-14b/systems/external-loads/station[9]/selected -> 0

var station_select = func(station_number, selector_state){
	var selector = get_armament_selector(station_number);
	if (station_number == STATION_ID_1)
	{
		if (selector_state <= -1)
		{
			setprop("sim/model/f-14b/systems/external-loads/station[0]/selected", 0);
			setprop("sim/model/f-14b/systems/external-loads/station[1]/selected", 1);
		}
		else if (selector_state >= 1)
		{
			setprop("sim/model/f-14b/systems/external-loads/station[0]/selected", 1);
			setprop("sim/model/f-14b/systems/external-loads/station[1]/selected", 0);
		}
		else
		{
			setprop("sim/model/f-14b/systems/external-loads/station[0]/selected", 0);
			setprop("sim/model/f-14b/systems/external-loads/station[1]/selected", 0);
		}
	}
	else if (station_number == STATION_ID_8)
	{
		if (selector_state <= -1)
		{
			setprop("sim/model/f-14b/systems/external-loads/station[8]/selected", 1);
			setprop("sim/model/f-14b/systems/external-loads/station[9]/selected", 0);
		}
		else if (selector_state >= 1)
		{
			setprop("sim/model/f-14b/systems/external-loads/station[8]/selected", 0);
			setprop("sim/model/f-14b/systems/external-loads/station[9]/selected", 1);
		}
		else
		{
			setprop("sim/model/f-14b/systems/external-loads/station[8]/selected", 0);
			setprop("sim/model/f-14b/systems/external-loads/station[9]/selected", 0);
		}
	}
	else
	{
		setprop("sim/model/f-14b/systems/external-loads/station[" ~ station_number ~ "]/selected", selector_state);
	}
	setprop(selector, selector_state);
}

var station_selector = func(station_number) {
	# n = station number, v = up (-1) or down (1) or toggle (0) as there is two kinds of switches.
	selector = get_armament_selector(station_number);
	selector_state = getprop(selector) or 0;
	if ( station_number == STATION_ID_1 or station_number == STATION_ID_8 ) {
			# up/down/neutral
			selector_state = selector_state + 1;
			if (selector_state > 1)
				selector_state = -1;
	}
	else {
		# Only up/neutral allowed.
		# toggle value between 0 and -1
		selector_state = -(1-math.abs(selector_state));
	}
#	print(selector," set to ",selector_state);
	station_select(station_number, selector_state);
	arm_selector();
}

var laststation_selector_cycle_stick_s = -1;

var station_selector_cycle = func() {
	stick_s = StickSelector.getValue();
	var selected = -1;
		# scan all and set to zero; but also if any switch in the map is selected then set state to 0 and exit.
		# otherwise set all to selected
		for (var n = 1;n<=8;n+=1) {
			selector = "sim/model/f-14b/controls/armament/station-selector[" ~ n ~ "]";
			if (getprop(selector)){
				print("changed to disable because of ",selector);
				selected = 0;
			}
			if (n != STATION_ID_2 and n != STATION_ID_7)
				station_select(n, 0);
		}

	# if the armament selector has changed or the logic have has detected that we need to 
	# select then do this now.
	if (laststation_selector_cycle_stick_s != stick_s or selected){
		foreach (var n ; StationSel_map){
			if (n.sel_type == stick_s){
				#var selector = "sim/model/f-14b/controls/armament/station-selector[" ~ n.selector_index ~ "]";
				var selected_type = getprop("payload/weight[" ~ n.arm_index ~ "]/selected");

				foreach (vt ; n.valid_types){
					var findV = find(vt, selected_type);
					printf(" -- checking[%d] '%s' to start with '%s' %d",n.arm_index,selected_type,vt, findV);
					
					if (find(vt, selected_type) == 0){
						printf("  ++ %s ", selected_type);
						station_select(n.selector_index, n.selector_value);
						# setprop(selector, n.selector_value);
						# setprop("sim/model/f-14b/systems/external-loads/station["~n.arm_index~"]/selected", 1);
					}
				}
			}
		}
	}
	laststation_selector_cycle_stick_s = stick_s;

	arm_selector();
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
      damage.flare_released();
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