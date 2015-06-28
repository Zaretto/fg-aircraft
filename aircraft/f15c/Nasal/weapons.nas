# F-15 Weapons system
# ---------------------------
# ---------------------------
# Richard Harrison (rjh@zaretto.com) Feb  2015 - based on F-14B version by Alexis Bory
# ---------------------------

var AcModel = props.globals.getNode("sim/model/f15");
var SwCoolOffLight   = AcModel.getNode("controls/armament/acm-panel-lights/sw-cool-off-light");
var MslPrepOffLight  = AcModel.getNode("controls/armament/acm-panel-lights/msl-prep-off-light");
var WeaponSelector    = AcModel.getNode("controls/armament/weapon-selector");
var ArmSwitch        = AcModel.getNode("controls/armament/master-arm-switch");
var GrSwitch         = AcModel.getNode("controls/armament/gun-rate-switch");
var SysRunning       = AcModel.getNode("systems/armament/system-running");
var GunRunning       = AcModel.getNode("systems/gun/running");
var GunCountAi       = props.globals.getNode("ai/submodels/submodel[3]/count");
var GunCount         = AcModel.getNode("systems/gun/rounds");
var GunReady         = AcModel.getNode("systems/gun/ready");
var GunStop          = AcModel.getNode("systems/gun/stop", 1);
var GunRateHighLight = AcModel.getNode("controls/armament/acm-panel-lights/gun-rate-high-light");


# AIM-9 stuff:
var SwCount    = AcModel.getNode("systems/armament/aim9/count");
var SWCoolOn   = AcModel.getNode("controls/armament/acm-panel-lights/sw-cool-on-light");
var SWCoolOff  = AcModel.getNode("controls/armament/acm-panel-lights/sw-cool-off-light");
var SwSoundVol = AcModel.getNode("systems/armament/aim9/sound-volume");
var aim9_count = 0;
Current_aim9   = nil;


aircraft.data.add( WeaponSelector, ArmSwitch );


# Init
var weapons_init = func()
{
	print("Initializing f15 weapons system");
	ArmSwitch.setValue(0);
	system_stop();
	SysRunning.setBoolValue(0);
	update_gun_ready();
	setlistener("controls/armament/trigger", func(Trig)
                {
# Check selected weapon type and set the trigger listeners.
                    var weapon_s = WeaponSelector.getValue();
                    print("Trigger ",weapon_s," ",Trig.getBoolValue());
                    if ( weapon_s == 0 ) {
                        update_gun_ready();
                        if ( Trig.getBoolValue())
                        {
                            GunStop.setBoolValue(0);
                            fire_gun();
                        }
                        else
                        {
                            GunStop.setBoolValue(1);
                        }
                    }
                    elsif ( weapon_s == 1 and Trig.getBoolValue())
                    {
                        release_aim9();
                    }
                }, 0, 1);
}



# Main loop
var armament_update = func {
	# Trigered each 0.1 sec by instruments.nas main_loop() if Master Arm Engaged.

	aim9_count = SwCount.getValue();
	# Turn sidewinder cooling lights On/Off.
	if ( aim9_count > 0 ) {
		SWCoolOn.setBoolValue(1);
		SWCoolOff.setBoolValue(0);
		update_sw_ready();
	} else {
		SWCoolOn.setBoolValue(0);
		SWCoolOff.setBoolValue(1);
		# Turn Current_aim9.status to stand by.
		#set_status_current_aim9(-1);
	}
}

var update_gun_ready = func()
 {
	var ready = 0;
	if ( ArmSwitch.getValue() and GunCount.getValue() > 0 )
 {
		ready = 1;
	}
	GunReady.setBoolValue(ready);
}

var fire_gun = func {
	var grun   = GunRunning.getValue();
	var gready = GunReady.getBoolValue();
	var gstop  = GunStop.getBoolValue();
	if (gstop) {
		GunRunning.setBoolValue(0);
		return;
	}
	if (gready and !grun) {
		GunRunning.setBoolValue(1);
		grun = 1;
	}
	if (gready and grun) {
		var real_gcount = GunCountAi.getValue();
		var new_gcount = real_gcount*5;
		if (new_gcount < 5 ) {
			new_gcount = 0;
			GunRunning.setBoolValue(0);
			GunReady.setBoolValue(0);
			GunCount.setValue(new_gcount);
			return;
		}
		GunCount.setValue(new_gcount);
		settimer(fire_gun, 0.1);
	}
}

var update_sw_ready = func()
{
	var sw_count = SwCount.getValue();
	if (WeaponSelector.getValue() == 1 and ArmSwitch.getValue())
    {
        var pylon = -1;
		if ((Current_aim9 == nil or Current_aim9.status == 2)  and sw_count > 0 )
        {
print("SIDEWINDER: sw_count = ", sw_count - 1);
            foreach (var S; Station.list)
            {
                if (S.get_type() == "AIM-9" and S.get_selected())
                {
print("New AIM ",S.index);
                    pylon = S.index;
                    break;
                }
            }
            if (pylon >= 0)
            {
                print("FOX2 new !! ", pylon, " sw_count - 1 = ", sw_count - 1);
                Current_aim9 = aircraft.AIM9.new(pylon);
            }
            else
                print("Error no AIM9");
		}
        elsif (Current_aim9 != nil and Current_aim9.status == -1)
        {
			Current_aim9.status = 0;	
			Current_aim9.search();	
		}
	}
    elsif (Current_aim9 != nil)
    {
		Current_aim9.status = -1;	
		SwSoundVol.setValue(0);
	}
}

var release_aim9 = func()
{
print("RELEASE AIM-9 status: ");
	if (Current_aim9 != nil) {
print(" status: ", Current_aim9.status);
		if ( Current_aim9.status == 1 ) {
			var phrase = "FOX2 at: " ~ Current_aim9.Tgt.Callsign.getValue();
			if (getprop("sim/model/f15/systems/armament/mp-messaging")) {
				setprop("/sim/multiplay/chat", phrase);
			} else {
				setprop("/sim/messages/atc", phrase);
			}
			# Set the pylon empty:
			var current_pylon = "payload/weight["~Current_aim9.ID~"]/selected";
print("Release ",current_pylon);
			setprop(current_pylon,"none");
print("currently ",getprop(current_pylon));
			armament_update();
			Current_aim9.release();
		}
	}
}

var set_status_current_aim9 = func(n)
{
	if (Current_aim9 != nil) {
		Current_aim9.status = n;	
	}
}

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
	settimer (func {
                  if (Current_aim9 != nil and WeaponSelector.getValue() and aim9_count > 0) {
                      Current_aim9.status = 0;	
                      Current_aim9.search();	
                  }
              }, 2.5);
}

var system_stop = func
{
    print("Weapons System stop");
	GunRateHighLight.setBoolValue(0);
	SysRunning.setBoolValue(0);
	foreach (var S; Station.list)
    {
		S.set_display(0); # initialize bcode (showing weapons set over MP).
	}
	if (Current_aim9 != nil)
    {
		set_status_current_aim9(-1);	
	}
	SwSoundVol.setValue(0);
	settimer (func { SwCoolOffLight.setBoolValue(0);SWCoolOn.setBoolValue(0); }, 0.6);
	settimer (func { MslPrepOffLight.setBoolValue(0); }, 1.2);
}


# Controls
setlistener("sim/model/f15/controls/armament/master-arm-switch", func(v)
{
    print("Master arm ",v.getValue());
    var a = v.getValue();
	var master_arm_switch = ArmSwitch.getValue(); 
	if (master_arm_switch)
    {
        system_start();
	}
    else
    {
        system_stop();
	}
});

var master_arm_cycle = func()
{
	var master_arm_switch = ArmSwitch.getValue();
    print("arm_cycle: master_arm_switch",master_arm_switch);
	if (master_arm_switch == 0)
    {
		ArmSwitch.setValue(1);
		system_start();
		SysRunning.setBoolValue(1);
	}
    else
    { 
		ArmSwitch.setValue(0);
		system_stop();
		SysRunning.setBoolValue(0);
	}
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
	update_gun_ready();
	var weapon_s = WeaponSelector.getValue();
    print("arm stick selector ",weapon_s);
	if ( weapon_s == 0 ) 
    {
		SwSoundVol.setValue(0);
		set_status_current_aim9(-1);
	} 
    elsif ( weapon_s == 1 )
    {
		# AIM-9: (SRM)
		if (Current_aim9 != nil and ArmSwitch.getValue() == 2 and aim9_count > 0) 
        {
			Current_aim9.status = 0;	
			Current_aim9.search();	
		}
	} 
    elsif ( weapon_s == 2 )
    {
        # MRM
		SwSoundVol.setValue(0);
        armament_update();
		set_status_current_aim9(-1);	
	} 
    else
    {
		SwSoundVol.setValue(0);
		set_status_current_aim9(-1);	
	}
    var sel=true; # only the next will be selected
	foreach (var S; Station.list)
    {
        S.set_selected(false);
        if (weapon_s == 2)
        {
            if (S.bcode == 2 or S.bcode == 3)
            {
                S.set_selected(sel);
                sel=false;
            }
        }
        else if (weapon_s == 1)
        {
            if (S.bcode == 1)
            {
                S.set_selected(sel);
                sel=false;
            }
        }
#        printf("Station %d %s:%s = %d (%d)",S.index,S.bcode, S.type.getValue(), S.get_selected(),sel);
		S.set_type(S.get_type()); # initialize bcode.
	}
}

