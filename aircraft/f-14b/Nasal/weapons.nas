# F-14 Weapons system
# ---------------------------
# ---------------------------
# Created: Alexis Bory
# Revised for F-15: Richard Harrison (rjh@zaretto.com) Feb  2015
# backported to F-14: Richard Harrison (rjh@zaretto.com) Jan 2016
# ---------------------------
var ac_sim_prop_root = "sim/model/f-14b/";
var AcModel = props.globals.getNode("sim/model/f-14b");
var SwCoolOffLight   = AcModel.getNode("controls/armament/acm-panel-lights/sw-cool-off-light");
var MslPrepOffLight  = AcModel.getNode("controls/armament/acm-panel-lights/msl-prep-off-light");
var WeaponSelector    = AcModel.getNode("controls/armament/stick-selector");
var ArmSwitch        = AcModel.getNode("controls/armament/master-arm-switch");
var ArmLever         = AcModel.getNode("controls/armament/master-arm-lever");
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
var Current_srm   = nil;
var Current_mrm   = nil;
var Current_missile   = nil;
var sel_missile_count = 0;

aircraft.data.add( WeaponSelector, ArmSwitch, ArmLever);


# Init
var weapons_init = func() {
	print("Initializing F-14B weapons system");
	ArmSwitch.setValue(1);
	ArmLever.setBoolValue(0);
	system_stop();
	SysRunning.setBoolValue(0);
	update_gun_ready();
	setlistener("controls/armament/trigger", func(Trig)
                {
		# Check selected weapon type and set the trigger listeners.
                    var weapon_s = WeaponSelector.getValue();
                    print("Trigger ",weapon_s," ",Trig.getBoolValue());
                    if ( weapon_s == 1 ) {
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
                    elsif ( weapon_s == 2 and Trig.getBoolValue())
                    {
                        release_aim9();
                    }
                    elsif ( weapon_s == 3 and Trig.getBoolValue())
                    {
			release_aim9();
		}
	}, 0, 1);
}



# Main loop
var armament_update = func {
	# Trigered each 0.1 sec by instruments.nas main_loop() if Master Arm Engaged.

    print("armament upate ",sel_missile_count);
    sel_missile_count = get_sel_missile_count();
	# Turn sidewinder cooling lights On/Off.
	if ( sel_missile_count > 0 ) {
		SWCoolOn.setBoolValue(1);
		SWCoolOff.setBoolValue(0);
		update_sw_ready();
	} else {
		SWCoolOn.setBoolValue(0);
		SWCoolOff.setBoolValue(1);
		# Turn Current_srm.status to stand by.
		#set_status_current_aim9(-1);
	}
}

var update_gun_ready = func()
 {
	var ready = 0;
	if ( ArmSwitch.getValue() == 2 and GunCount.getValue() > 0 ) {
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

var missile_code_from_ident= func(mty)
{
        if (mty == "AIM-9")
            return "aim9";
        else if (mty == "AIM-7")
            return "aim7";
        else if (mty == "AIM-120")
            return "aim120";
        else if (mty == "AIM-54")
            return "aim54";
}
var get_sel_missile_count = func()
{
    var rv = 0;
        if (WeaponSelector.getValue() == 2)
        {
            Current_missile = Current_srm;
            rv = getprop(ac_sim_prop_root~"systems/armament/aim9/count");
        }
        else if (WeaponSelector.getValue() == 3)
        {
            Current_missile = Current_mrm;
            rv = getprop(ac_sim_prop_root~"systems/armament/aim7/count")+getprop(ac_sim_prop_root~"systems/armament/aim54/count");
		}
        setprop(ac_sim_prop_root~"systems/armament/selected-missile-count",rv);
        return rv;
}
var update_sw_ready = func()
{
	if (WeaponSelector.getValue() > 1 and ArmSwitch.getValue())
    {
    	sel_missile_count = get_sel_missile_count();
        var pylon = -1;
		if ( (WeaponSelector.getValue() == 2 and (Current_srm == nil or Current_srm.status == 2)  and sel_missile_count > 0 )
             or (WeaponSelector.getValue() == 3 and (Current_mrm == nil or Current_mrm.status == 2)  and sel_missile_count > 0 ))
        {
            print("Missile: sel_missile_count = ", sel_missile_count - 1);
            foreach (var S; Station.list)
            {
#                if (S.get_type() == "AIM-9" and S.get_selected())
                if (S.get_selected())
                {
                    printf("AIM[%d]: %s, %s",S.index, S.get_type(), S.get_selected());
                    var match = 0;
                    if (WeaponSelector.getValue() == 2)
                    {
                        if (S.get_type() == "AIM-9")
                        {
                            match = 1;
                        }
                    }
                    else if (WeaponSelector.getValue() == 3)
                    {
                        if (S.get_type() == "AIM-7" or S.get_type() == "AIM-54" or S.get_type() == "AIM-120")
                            match = 1;
                    }
                    if (match)
                    {
                        print("New AIM idx=",S.index);
                        pylon = S.index;
                        break;
                    }
                }
                else
                    printf("AIM[%d] *NOT SELECTED IN COCKPIT*: %s, %s",S.index, S.get_type(), S.get_selected());

            }
            if (pylon >= 0)
            {
                if (S.get_type() == "AIM-9" or S.get_type() == "AIM-7" or S.get_type() == "AIM-120" or S.get_type() == "AIM-54")
                {
                    print(S.get_type()," new !! ", pylon, " sel_missile_count - 1 = ", sel_missile_count - 1);
                    if (WeaponSelector.getValue() == 2)
                        Current_srm = f14.AIM9.new(pylon, S.get_type());
                    else if (WeaponSelector.getValue() == 3)
                        Current_mrm = f14.AIM9.new(pylon, S.get_type());
                }
                else
                    print ("Cannot locate ",S.get_type());

            }
            else
                print("Error no missile available");
        }
        elsif (Current_missile != nil and Current_missile.status == -1)
        {
            Current_missile.status = 0;	
            Current_missile.search();	
        }
    }
    elsif (Current_missile != nil)
    {
		Current_missile.status = -1;	
		SwSoundVol.setValue(0);
	}
}

var release_aim9 = func()
{
print("RELEASE AIM-9 status: ");
	if (Current_missile != nil) {
print(" status: ", Current_missile.status);
		if ( Current_missile.status == 1 ) {
			var phrase = Current_missile.type~" at: " ~ Current_missile.Tgt.Callsign.getValue();
			if (getprop(ac_sim_prop_root~"systems/armament/mp-messaging")) {
				setprop("/sim/multiplay/chat", phrase);
			} else {
				setprop("/sim/messages/atc", phrase);
			}
			# Set the pylon empty:
			var current_pylon = "payload/weight["~Current_missile.ID~"]/selected";
print("Release ",current_pylon);
			setprop(current_pylon,"none");
print("currently ",getprop(current_pylon));
			armament_update();
setprop(ac_sim_prop_root~"systems/armament/launch-light",false);
			Current_missile.release();
            arm_selector();
		}
	}
}

var set_status_current_aim9 = func(n)
{
	if (Current_missile != nil) {
		Current_missile.status = n;	
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
                  if (Current_missile != nil and WeaponSelector.getValue() and sel_missile_count > 0) {
                      Current_missile.status = 0;	
                      Current_missile.search();	
		}
	}, 2.5);
}

var system_stop = func
{
    print("Weapons System stop");
	GunRateHighLight.setBoolValue(0);
	SysRunning.setBoolValue(0);

    setprop(ac_sim_prop_root~"systems/armament/launch-light",false);
	foreach (var S; Station.list)
    {
		S.set_display(0); # initialize bcode (showing weapons set over MP).
	}
	if (Current_missile != nil)
    {
		set_status_current_aim9(-1);	
	}
	SwSoundVol.setValue(0);
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
print("master arm ",a);
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
}

var demand_weapons_refresh = func {
    setprop(ac_sim_prop_root~"controls/armament/weapons-updated", getprop(ac_sim_prop_root~"controls/armament/weapons-updated")+1);
}
#
#
var arm_selector = func() {

	# Checks to do when rotating the wheel on the stick.
	update_gun_ready();
	var weapon_s = WeaponSelector.getValue();
    print("arm stick selector ",weapon_s);
    setprop(ac_sim_prop_root~"systems/armament/launch-light",false);
	if ( weapon_s == 0 ) 
    {
		SwSoundVol.setValue(0);
		set_status_current_aim9(-1);
    }
    elsif ( weapon_s == 2 )
    {
		# AIM-9: (SRM)
		if (Current_srm != nil and ArmSwitch.getValue() == 2 and sel_missile_count > 0) 
        {
            Current_missile = Current_srm;
			Current_missile.status = 0;	
			Current_missile.search();	
            SwSoundVol.setValue(0);
            set_status_current_aim9(-1);	
        }
    }
    elsif ( weapon_s == 3 )
    {
        # MRM
		if (Current_mrm != nil and ArmSwitch.getValue() == 2 and sel_missile_count > 0) 
        {
            Current_missile = Current_mrm;
			Current_missile.status = 0;	
			Current_missile.search();	
		}
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
        if (weapon_s == 3)
        {
            if (S.bcode == 2 or S.bcode == 3 or S.bcode == 6)
            {
                S.set_selected(sel);
                sel=false;
            }
        }
        else if (weapon_s == 2)
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
    setprop(ac_sim_prop_root~"controls/armament/weapons-updated", getprop(ac_sim_prop_root~"controls/armament/weapons-updated")+1);
}

var station_selector = func(n, v) {
	# n = station number, v = up (-1) or down (1) or toggle (0) as there is two kinds of switches.
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
				f14.S0.set_selected(0);
				f14.S1.set_selected(1);
			} else {
				f14.S8.set_selected(1);
				f14.S9.set_selected(0);
			}
		} elsif ( state == 0 ) {
			if ( n == 0 ) {
				f14.S0.set_selected(0);
				f14.S1.set_selected(0);
			} else {
				f14.S8.set_selected(0);
				f14.S9.set_selected(0);
			}
		} elsif ( state == 1 ) {
			if ( n == 0 ) {
				f14.S0.set_selected(1);
				f14.S1.set_selected(0);
			} else {
				f14.S8.set_selected(0);
				f14.S9.set_selected(1);
			}
		}
	}
	armament_update();
}

var station_selector_cycle = func() {
print("Station selector cycle");
	# Fast selector, selects with one keyb shorcut all AIM-9 or nothing.
	# Only to choices ATM.
	var s = 0;
    if (WeaponSelector.getValue() == 2)
    {
        var p0 = getprop("sim/model/f-14b/controls/armament/station-selector[0]");
        var p7 = getprop("sim/model/f-14b/controls/armament/station-selector[7]");
        if ( !(p0 or p7)) { s = 1; }
        setprop("sim/model/f-14b/controls/armament/station-selector[0]", s);
        setprop("sim/model/f-14b/controls/armament/station-selector[7]", s);
        f14.S0.set_selected(s);
        f14.S1.set_selected(0);

        f14.S3.set_selected(0);
        f14.S4.set_selected(0);
        f14.S5.set_selected(0);
        f14.S6.set_selected(0);

        f14.S8.set_selected(0);
        f14.S9.set_selected(s);	
    }
    elsif (WeaponSelector.getValue() == 3)
    {
        var p0 = getprop("sim/model/f-14b/controls/armament/station-selector[0]");
        var p3 = getprop("sim/model/f-14b/controls/armament/station-selector[3]");
        var p4 = getprop("sim/model/f-14b/controls/armament/station-selector[4]");
        var p5 = getprop("sim/model/f-14b/controls/armament/station-selector[5]");
        var p6 = getprop("sim/model/f-14b/controls/armament/station-selector[6]");
        var p7 = getprop("sim/model/f-14b/controls/armament/station-selector[7]");
        if ( !(p0 or p3 or p4 or p5 or p6 or p7)) { s = 1; }
        setprop("sim/model/f-14b/controls/armament/station-selector[0]", s);
        setprop("sim/model/f-14b/controls/armament/station-selector[3]", s);
        setprop("sim/model/f-14b/controls/armament/station-selector[4]", s);
        setprop("sim/model/f-14b/controls/armament/station-selector[5]", s);
        setprop("sim/model/f-14b/controls/armament/station-selector[6]", s);
        setprop("sim/model/f-14b/controls/armament/station-selector[7]", s);
#
#
# need to do logic with the SP / PH missile switch
        f14.S0.set_selected_if_mrm(s);
        f14.S1.set_selected_if_mrm(0);

        f14.S3.set_selected_if_mrm(s);
        f14.S4.set_selected_if_mrm(s);
        f14.S5.set_selected_if_mrm(s);
        f14.S6.set_selected_if_mrm(s);

        f14.S8.set_selected_if_mrm(0);
        f14.S9.set_selected_if_mrm(s);	
    }
	armament_update();
}



setlistener("/payload/weight[0]/selected", func(v)
{
    demand_weapons_refresh();
    arm_selector();
});
setlistener("/payload/weight[1]/selected", func(v)
{
    demand_weapons_refresh();
    arm_selector();
});
setlistener("/payload/weight[2]/selected", func(v)
{
    demand_weapons_refresh();
    arm_selector();
});
setlistener("/payload/weight[3]/selected", func(v)
{
    demand_weapons_refresh();
    arm_selector();
});
setlistener("/payload/weight[4]/selected", func(v)
{
    demand_weapons_refresh();
    arm_selector();
});
setlistener("/payload/weight[5]/selected", func(v)
{
    demand_weapons_refresh();
    arm_selector();
});
setlistener("/payload/weight[6]/selected", func(v)
{
    demand_weapons_refresh();
    arm_selector();
});
setlistener("/payload/weight[7]/selected", func(v)
{
    demand_weapons_refresh();
    arm_selector();
});
setlistener("/payload/weight[8]/selected", func(v)
{
    demand_weapons_refresh();
    arm_selector();
});
setlistener("/payload/weight[9]/selected", func(v)
{
    demand_weapons_refresh();
    arm_selector();
});
