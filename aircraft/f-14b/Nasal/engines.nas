var egt_norm1 = props.globals.getNode("engines/engine[0]/egt-norm", 1);
var egt_norm2 = props.globals.getNode("engines/engine[1]/egt-norm", 1);
var egt1_rankin = props.globals.getNode("engines/engine[0]/egt-degR", 1);
var egt2_rankin = props.globals.getNode("engines/engine[1]/egt-degR", 1);
var egt1 = props.globals.getNode("fdm/jsbsim/propulsion/engine[0]/EGT-R", 1);
var egt2 = props.globals.getNode("fdm/jsbsim/propulsion/engine[1]/EGT-R", 1);
#var egt1      = props.globals.getNode("engines/engine[0]/egt-degf", 1);
#var egt2      = props.globals.getNode("engines/engine[1]/egt-degf", 1);
var Ramp1l     = props.globals.getNode("engines/AICS/ramp1l", 1);
var Ramp2l     = props.globals.getNode("engines/AICS/ramp2l", 1);
var Ramp3l     = props.globals.getNode("engines/AICS/ramp3l", 1);
var Ramp1r     = props.globals.getNode("engines/AICS/ramp1r", 1);
var Ramp2r     = props.globals.getNode("engines/AICS/ramp2r", 1);
var Ramp3r     = props.globals.getNode("engines/AICS/ramp3r", 1);
var Engine1Burner = props.globals.initNode("engines/engine[0]/afterburner", 0, "DOUBLE");
var Engine2Burner = props.globals.initNode("engines/engine[1]/afterburner", 0, "DOUBLE");
var Engine1Augmentation = props.globals.getNode("engines/engine[0]/augmentation",1);
var Engine2Augmentation = props.globals.getNode("engines/engine[1]/augmentation",1);
var Engine2Augmentation = props.globals.getNode("engines/engine[1]/augmentation",1);

#props.globals.getNode("sim/model/f-14b/fx/test1",1);
#props.globals.getNode("sim/model/f-14b/fx/test2",1);
setprop("sim/model/f-14b/gear-sound-freeze",0);
setprop("sim/model/f-14b/engine-sound-freeze",0);
setprop("sim/model/f-14b/controls/switch-backup-ignition",0);

#var l_engine_pitch_n1  = props.globals.getNode("sim/model/f-14b/fx/engine/l-engine-pitch-n1",1);
#var l_engine_pitch_n1  = props.globals.getNode("sim/model/f-14b/fx/engine/l-engine-pitch-n2",1);
#var l_inlet  = props.globals.getNode("sim/model/f-14b/fx/engine/l-engine-inlet",1);
#var l_efflux  = props.globals.getNode("sim/model/f-14b/fx/engine/l-engine-efflux",1);

var l_running_prop = props.globals.getNode("engines/engine[0]/running",1);
var r_running_prop = props.globals.getNode("engines/engine[1]/running",1);
var l_n1_prop = props.globals.getNode("engines/engine[0]/n1",1);
var r_n1_prop = props.globals.getNode("engines/engine[1]/n1",1);
var l_starter_prop = props.globals.getNode("controls/engines/engine[0]/starter");
var r_starter_prop = props.globals.getNode("controls/engines/engine[1]/starter");

var engine_crank_switch_pos_prop = props.globals.getNode("sim/model/f-14b/controls/engine/engine-crank");
engine_crank_switch_pos_prop.setValue(0);

var jfs_start = props.globals.getNode("sim/model/f-14b/controls/jfs",1);
jfs_start.setValue(0);

var jfs_invoke_shutdown_active = 0;
var jfs_set_running_active = 0;

var GearPos   = props.globals.getNode("gear/gear[0]/position-norm", 1);

#----------------------------------------------------------------------------
# AICS (Air Inlet Control System)
#----------------------------------------------------------------------------

var computeAICS = func {

	if (CurrentMach < 0.5) {
		ramp1 = 0.0;
		ramp3 = 0.0;
		ramp2 = 0.0;
	} elsif (CurrentMach < 1.2) {
		ramp1 = (CurrentMach - 0.5) * 0.4285;
		ramp3 = (CurrentMach - 0.5) * 0.2857;
		ramp2 = 0.0;
	} elsif (CurrentMach < 2.0) {
		ramp1 = (CurrentMach - 1.2) * 0.875 + 0.3;
		ramp3 = (CurrentMach - 1.2) + 0.2;
		ramp2 = (CurrentMach - 1.2) / 0.8;
	} else {
		ramp1 = 1.0;
		ramp3 = 1.0;
		ramp2 = 1.0;
	}

    if(!getprop("sim/model/f-14b/controls/switch-l-ramp"))
    {
    	Ramp1l.setValue(ramp1);
    	Ramp2l.setValue(ramp2);
    	Ramp3l.setValue(ramp3);
    }

    if(!getprop("sim/model/f-14b/controls/switch-r-ramp"))
    {
    	Ramp1r.setValue(ramp1);
    	Ramp2r.setValue(ramp2);
    	Ramp3r.setValue(ramp3);
    }
}

#----------------------------------------------------------------------------
# Nozzle opening
#----------------------------------------------------------------------------

# Constant
NozzleSpeed = 1.0;

var computeNozzles = func {

	var maxSeaLevelIdlenozzle = 0;
	var idleNozzleTarget = 0;

	var eng1_burner = Engine1Burner.getValue();
	var eng2_burner = Engine1Burner.getValue();

    # 492 is 0 deg F in Rankin. The rankin scale starts from absolute zero.
	egt_norm1.setValue((egt1.getValue()-492)*0.000679348);
	egt_norm2.setValue((egt2.getValue()-492)*0.000679348);

    egt1_rankin.setValue(egt1.getValue());
    egt2_rankin.setValue(egt2.getValue());


	if (CurrentMach < 0.45) {
		maxSeaLevelIdlenozzle = 1;
	} elsif (CurrentMach >= 0.45 and CurrentMach < 0.8) {
		maxSeaLevelIdlenozzle = (0.8 - CurrentMach) / 0.35;
	}

	if (Throttle < ThrottleIdle) {
		var gear_pos = GearPos.getValue();
		if (gear_pos == 1.0) {
		#gear down
			if (wow) {
				idleNozzleTarget = 1;
			} else {
				idleNozzleTarget = 0.26;
			}
		} else {
		# gear not down
			if (CurrentAlt <= 30000) {
				idleNozzleTarget = 1 + (0.15 - maxSeaLevelIdlenozzle) * CurrentAlt / 30000.0;
			} else {
				idleNozzleTarget = 0.15;
			}
		}
		Nozzle1Target = idleNozzleTarget;
		Nozzle2Target = idleNozzleTarget;
	} else {
	# throttle idle
		Nozzle1Target = eng1_burner;
		Nozzle2Target = eng2_burner;
	}
    if (Engine1Augmentation.getValue())
    {  
        Engine1Burner.setDoubleValue(1);
    }
    if (Engine2Augmentation.getValue())
    {
        Engine2Burner.setDoubleValue(1);
    }
}

#----------------------------------------------------------------------------
# APC - Approach Power Compensator
#----------------------------------------------------------------------------
# target:        - sim/model/f-14b/instrumentation/aoa-indexer/target-deg (11,3 deg AoA)
# engaged by:    - Throttle Mode Lever
#                - keystroke "a" (toggle)
# disengaged by: - Throttle Mode Lever
#                - keystroke "a" (toggle)
#                - WoW
#                - throttle levers at ~ idle or MIL
#                - autopilot emer disengage padle (TODO)

var APCengaged = props.globals.getNode("sim/model/f-14b/systems/apc/engaged");
var engaded = 0;
var gear_down = props.globals.getNode("controls/gear/gear-down");
var disengaged_light = props.globals.getNode("sim/model/f-14b/systems/apc/self-disengaged-light");
var throttle_0 = props.globals.getNode("controls/engines/engine[0]/throttle");
var throttle_1 = props.globals.getNode("controls/engines/engine[1]/throttle");

var computeAPC = func {
	var t0 = throttle_0.getValue();
	var t1 = throttle_1.getValue();
	if (APCengaged.getBoolValue()) {
		# TODO override throttles
		if ( wow or !gear_down.getBoolValue()
		or t0 > 0.76 or t0 < 0.08
		or t1 > 0.76 or t1 < 0.08 ) {
			APC_off()
		}
	} else {
		# TODO duplicate throttles
	}
}

var toggleAPC = func {
	engaged = APCengaged.getBoolValue();
	if ( ! engaged ){
		APC_on();
	} else {
		APC_off();
	}
}

var APC_on = func {
	if ( ! wow and gear_down.getBoolValue()) {
		APCengaged.setBoolValue(1);
		disengaged_light.setBoolValue(0);
		setprop ("autopilot/locks/aoa", "APC");
		setprop ("autopilot/locks/speed", "APC");
		#print ("APC on()");
	}
}

var APC_off = func {
	setprop ("autopilot/internal/target-speed", 0.0);
	APCengaged.setBoolValue(0);
	disengaged_light.setBoolValue(1);
	settimer(func { disengaged_light.setBoolValue(0); }, 10);
	setprop ("autopilot/locks/aoa", "");
	setprop ("autopilot/locks/speed", "");
	#print ("APC off()");
}

#
#
#
var engineControls = func {

#
# 
# JFS Startup / running noises
# jfs_start 0 - no noise
#           1 - shutdown
#           10 - starting
#           11 - running
#           12 - engine turning
var l_starter = l_starter_prop.getValue();
var r_starter = r_starter_prop.getValue();

var l_running = l_running_prop.getValue();
var r_running = r_running_prop.getValue();

    if (!l_running or !r_running)
    {
        var r_n1 = l_n1_prop.getValue();
        var l_n1 = r_n1_prop.getValue();
        if (l_starter or r_starter){
            if (jfs_start.getValue() <= 1)
            {
                jfs_start.setValue(10);
            }
            if (jfs_start.getValue() == 10)
            {
                jfs_start.setValue(11);
            }  
        }
        if ( ((l_n1 > 1 and l_n1 < 20) 
             or  (r_n1 > 1 and r_n1 < 20))
             and (l_starter or r_starter)
             and jfs_start.getValue() == 11)
        {
#engine turning
            jfs_start.setValue(12);
        }
        if ( ((l_n1 > 19 and l_n1 < 30) 
               and (r_n1 > 19 and r_n1 < 30))
             and (!l_starter and !r_starter)
             and jfs_start.getValue() == 12)
        {
                jfs_start.setValue(1);
        }
    }
    else{
        if (l_running and r_running and jfs_start.getValue() >= 10)
        {
            jfs_start.setValue(1);
        }
        if (jfs_start.getValue() < 10)
        {
            jfs_start.setValue(0);
        }
    }

    if (engine_crank_switch_pos_prop.getValue() > 0 
            and l_starter == 0 
            and r_starter == 0
            and jfs_running)
    {
    	engine_crank_switch_pos_prop.setIntValue(0);
    }
     if (jfs_running and l_running and r_running){
        jfs_running = 0;
        jfs_start.setValue(1);
    }
}
var jfs_set_running = func{

    var engine_crank_switch_pos = engine_crank_switch_pos_prop.getValue();

    print("Jfs set running callback");
    if (jfs_running){
        return;
    }
    jfs_start.setValue(11);
    jfs_running = 1;
    jfs_starting = 0;

    if (engine_crank_switch_pos == 1) {
        print("JFS: Now set starter L");
        setprop("controls/engines/engine[0]/starter",1);
    }
    if (engine_crank_switch_pos == 2) {
        print("JFS: Now set starter R");
        setprop("controls/engines/engine[1]/starter",1);
    }
    startupTimer.stop();
}
var jfs_invoke_shutdown = func{

    print("Jfs invoke shutdown  callback");
    var engine_crank_switch_pos = engine_crank_switch_pos_prop.getValue();

    # do nothing whilst not running or when the switch is still set.
    if(!jfs_running or engine_crank_switch_pos)
    {
        return;
    }

    if (jfs_running){
        jfs_start.setValue(1);
        jfs_running = 0;
        jfs_starting = 0;
    }
#    settimer(f14., 999999); # turn off timer.
shutdownTimer.stop();
}

var jfs_running = 0;
var jfs_starting = 0;
var jfs_shutdown_timer = 0;

var shutdownTimer = maketimer(6, jfs_invoke_shutdown);
shutdownTimer.singleShot=1;
var startupTimer = maketimer(11, jfs_set_running);
startupTimer.singleShot=1;
var jfsShutdownTime = 5; # time after crank switch set to centre that the JFS will turn off.
var jfsStartupTime = 10; # amount of time it takes JFS to be ready - before the start will be able to turn the engine (i.e. how long before starter_cmd is set)

#
#
# Switch / action callbacks

var engine_crank_switch = func(n) {
var engine_crank_switch_pos = engine_crank_switch_pos_prop.getValue();

    if (engine_crank_switch_pos == nil){
        engine_crank_switch_pos_prop.setIntValue(0);
    }
#
#
# reset the timer.
    shutdownTimer.restart(jfsShutdownTime);

    if (engine_crank_switch_pos != 0) {
        setprop("controls/engines/engine[0]/starter",0);
        setprop("controls/engines/engine[1]/starter",0);
		engine_crank_switch_pos_prop.setIntValue(0);

        if(jfs_starting){
            jfs_starting = 0;
            jfs_running = 1; # not really but just to get the sounds right.
            startupTimer.stop();
            return;
        }
    }
    if (!jfs_running){
        if (!jfs_starting){
            jfs_starting = 1;
            jfs_start.setValue(10);
            startupTimer.restart(jfsStartupTime);
            print("Start JFS");
        }
	    if (n == 0) {
			engine_crank_switch_pos_prop.setIntValue(1);
		} 
	    if (n == 1) {
			engine_crank_switch_pos_prop.setIntValue(2);
		} 
        return;
    }
	if (n == 0) {
		if (engine_crank_switch_pos == 0) {
            if (jfs_running){
                setprop("controls/engines/engine[0]/starter",1);
            }
			engine_crank_switch_pos_prop.setIntValue(1);
		} elsif (engine_crank_switch_pos == 1) {
			engine_crank_switch_pos_prop.setIntValue(0);
            setprop("controls/engines/engine[0]/starter",0);
		}
	} else {
		if (engine_crank_switch_pos == 0) {
			engine_crank_switch_pos_prop.setIntValue(2);
            if (jfs_running){
                setprop("controls/engines/engine[1]/starter",1);
            }
		} elsif (engine_crank_switch_pos == 2) {
            setprop("controls/engines/engine[1]/starter",0);
			engine_crank_switch_pos_prop.setIntValue(0);
		}
	}	
}
#
# 0 = L
# 1 = R
# The fire handle does two things; firstly when pulled it cuts
# off fuel. then when turned it deploys the fire extinguisher
# - not currently modelling fire extinguishers.
var fire_handle = func(n) {
    if (n==0)
    {
        if (getprop("controls/engines/engine[0]/cutoff"))
        {
            setprop("controls/engines/engine[0]/cutoff", 0);
        }
        else
        {
            setprop("controls/engines/engine[0]/cutoff", 1);
        }
    }
    if (n==1)
    {
        if (getprop("controls/engines/engine[1]/cutoff"))
        {
            setprop("controls/engines/engine[1]/cutoff", 0);
        }
        else
        {
            setprop("controls/engines/engine[1]/cutoff", 1);
        }
    }
}

var econt_r_ramp = func(n) {
setprop("sim/model/f-14b/controls/switch-r-ramp", n);
    if (n)
    {
    	Ramp1r.setValue(0);
    	Ramp2r.setValue(0);
    	Ramp3r.setValue(0);
    }
}

var econt_throttle_mode = func(n) {
setprop("sim/model/f-14b/controls/switch-throttle-mode", n);
}

var econt_backup_ignition_toggle = func {
setprop("sim/model/f-14b/controls/switch-backup-ignition", 1 - getprop("sim/model/f-14b/controls/switch-backup-ignition"));
}

var econt_l_ramp = func(n) {
setprop("sim/model/f-14b/controls/switch-l-ramp", n);
    if (n)
    {
    	Ramp1l.setValue(0);
    	Ramp2l.setValue(0);
    	Ramp3l.setValue(0);
    }
}

var econt_temp = func(n) {
setprop("sim/model/f-14b/controls/switch-temp", n);
}

