var egt_norm1 = props.globals.getNode("engines/engine[0]/egt-norm", 1);
var egt_norm2 = props.globals.getNode("engines/engine[1]/egt-norm", 1);
var egt1_rankin = props.globals.getNode("engines/engine[0]/egt-degR", 1);
var egt2_rankin = props.globals.getNode("engines/engine[1]/egt-degR", 1);
var egt1 = props.globals.getNode("fdm/jsbsim/propulsion/engine[0]/EGT-R", 1);
var egt2 = props.globals.getNode("fdm/jsbsim/propulsion/engine[1]/EGT-R", 1);

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

if(!usingJSBSim)
{
    egt1 = props.globals.getNode("engines/engine[0]/egt-degf", 1);
    egt2 = props.globals.getNode("engines/engine[1]/egt-degf", 1);
    setprop("controls/engines/engine[0]/cutoff", 0);
    setprop("controls/engines/engine[1]/cutoff", 0);
    Engine1Augmentation = Engine1Burner;
    Engine2Augmentation = Engine2Burner;
    setprop("engines/engine[0]/augmentation-burner", getprop("engines/engine[0]/afterburner")*5);
    setprop("engines/engine[1]/augmentation-burner", getprop("engines/engine[1]/afterburner")*5);

}

#props.globals.getNode("sim/model/f-14b/fx/test1",1);
#props.globals.getNode("sim/model/f-14b/fx/test2",1);
setprop("sim/model/f-14b/gear-sound-freeze",0);
setprop("sim/model/f-14b/engine-sound-freeze",0);
setprop("sim/model/f-14b/controls/switch-backup-ignition",0);

setprop("/fdm/jsbsim/propulsion/engine[0]/nozzle-pos-norm",1);
setprop("/fdm/jsbsim/propulsion/engine[1]/nozzle-pos-norm",1);

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
var engine_start_initiated = 0;

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
var current_flame_number = 0;

var computeNozzles = func {

   current_flame_number = (current_flame_number + 1);        
   if (current_flame_number > 3) current_flame_number = 0;
   setprop("sim/model/f-14b/fx/flame-number",current_flame_number);

	var eng1_burner = Engine1Burner.getValue();
	var eng2_burner = Engine2Burner.getValue();

    # 492 is 0 deg F in Rankin. The rankin scale starts from absolute zero.
	egt_norm1.setValue((egt1.getValue()-492)*0.000679348);
	egt_norm2.setValue((egt2.getValue()-492)*0.000679348);

    egt1_rankin.setValue(egt1.getValue());
    egt2_rankin.setValue(egt2.getValue());

    if (usingJSBSim)
    {
    	if ( getprop("sim/replay/time") > 0 ) 
        { 
            setprop("engines/engine[0]/augmentation", getprop("engines/engine[0]/afterburner"));
            setprop("engines/engine[1]/augmentation", getprop("engines/engine[1]/afterburner"));
        }
        else
        {
# not in replay so copy the properties;
# 
            setprop("engines/engine[0]/afterburner", getprop("/fdm/jsbsim/propulsion/engine[0]/augmentation-alight"));
            setprop("engines/engine[1]/afterburner", getprop("/fdm/jsbsim/propulsion/engine[1]/augmentation-alight"));
            setprop("engines/engine[0]/augmentation-burner", getprop("/fdm/jsbsim/propulsion/engine[0]/augmentation-burner"));
            setprop("engines/engine[1]/augmentation-burner", getprop("/fdm/jsbsim/propulsion/engine[1]/augmentation-burner"));
        }
    }
    else
    {
        var maxSeaLevelIdlenozzle = 0;
        var idleNozzleTarget = 0;


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
# throttle not at idle so the nozzle will be open only when augmentation is active.
            Nozzle1Target = eng1_burner;
            Nozzle2Target = eng2_burner;
        }
        setprop("engines/engine[0]/augmentation-burner", (int)(getprop("engines/engine[0]/afterburner")+0.98));
        setprop("engines/engine[1]/augmentation-burner", (int)(getprop("engines/engine[1]/afterburner")+0.99));
#
#stage is from 0-5 so scale it
        setprop("engines/engine[0]/afterburner-stage", (int)(getprop("engines/engine[0]/afterburner")*5+0.99));
        setprop("engines/engine[1]/afterburner-stage", (int)(getprop("engines/engine[1]/afterburner")*5+0.99));
    }
}

# JFS Startup / running noises
# jfs_start 0 - no noise
#           1 - shutdown
#           10 - starting
#           11 - running
#           12 - engine turning
var engineControls = func {

    if (!engine_start_initiated) return;

    var l_starter = l_starter_prop.getValue();
    var r_starter = r_starter_prop.getValue();

    var l_running = l_running_prop.getValue();
    var r_running = r_running_prop.getValue();

    if (!l_running or !r_running)
    {
        var r_n1 = l_n1_prop.getValue();
        var l_n1 = r_n1_prop.getValue();
        #
        # need to use JFS when no external air.
        if (!(l_running or r_running or getprop("/fdm/jsbsim/systems/electrics/ground-air")))
        {
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
        }
#        if ( ((l_n1 > 1 and l_n1 < 20) 
#             or  (r_n1 > 1 and r_n1 < 20))
#             and (l_starter or r_starter)
#             and jfs_start.getValue() == 11)
#        {
#engine turning
#            jfs_start.setValue(12);
#        }
#        if ( ((l_n1 > 19 and l_n1 < 30) 
#               and (r_n1 > 19 and r_n1 < 30))
#             and (!l_starter and !r_starter)
#             and jfs_start.getValue() == 12)
#        {
#                jfs_start.setValue(1);
#        }
    }
    else
    {
        if (l_running or r_running and jfs_start.getValue() >= 10)
        {
            jfs_start.setValue(1);
        }
        if (jfs_start.getValue() < 10)
        {
            jfs_start.setValue(0);
        }
    }

    var bleed_air_available = jfs_running or l_running or r_running or getprop("/fdm/jsbsim/systems/electrics/ground-air");

    if (engine_crank_switch_pos_prop.getValue() > 0 
            and l_starter == 0 
            and r_starter == 0
            and engine_start_initiated
            and bleed_air_available)
    {
        engine_start_initiated = 0;
    	engine_crank_switch_pos_prop.setIntValue(0);
    }
}

#
#
# callback to manage the start after JFS has come online
var jfs_set_running = func{

    var engine_crank_switch_pos = engine_crank_switch_pos_prop.getValue();

#    print("Jfs set running callback");
    if (jfs_running)
    {
        return;
    }
    jfs_start.setValue(11);
    jfs_running = 1;
    jfs_starting = 0;

    if (engine_crank_switch_pos == 1) {
#        print("JFS: Now set starter L");
        setprop("controls/engines/engine[0]/starter",1);
    }
    if (engine_crank_switch_pos == 2) {
#        print("JFS: Now set starter R");
        setprop("controls/engines/engine[1]/starter",1);
    }
    startupTimer.stop();
}

#
#
# Manage the automatic shutdown of JFS
var jfs_invoke_shutdown = func{

#    print("Jfs invoke shutdown  callback");
    var engine_crank_switch_pos = engine_crank_switch_pos_prop.getValue();

    # do nothing whilst not running or when the switch is still set.
    var l_running = l_running_prop.getValue();
    var r_running = r_running_prop.getValue();

#
# If neither engine running then need JFS
    if (!l_running and !r_running)
    {
        if(!jfs_running or engine_crank_switch_pos)
        {
            return;
        }
    }
    if (jfs_running)
    {
        jfs_start.setValue(1);
        jfs_running = 0;
        jfs_starting = 0;
    }
    print("Jfs invoke shutdown cancel callback");
    shutdownTimer.stop();
}

var jfs_running = 0;
var jfs_starting = 0;
var jfs_shutdown_timer = 0;

var shutdownTimer = maketimer(6, jfs_invoke_shutdown);
var startupTimer = maketimer(11, jfs_set_running);
#startupTimer.singleShot=1;
var jfsShutdownTime = 55; # time after crank switch set to centre that the JFS will turn off.
var jfsStartupTime = 10; # amount of time it takes JFS to be ready - before the start will be able to turn the engine (i.e. how long before starter_cmd is set)

#
#
# Switch / action callbacks

var engine_crank_switch = func(n) {
    var engine_crank_switch_pos = engine_crank_switch_pos_prop.getValue();

    var l_running = l_running_prop.getValue();
    var r_running = r_running_prop.getValue();


    if (engine_crank_switch_pos == nil)
    {
        engine_crank_switch_pos_prop.setIntValue(0);
    }
    if (engine_crank_switch_pos != 0) {
        setprop("controls/engines/engine[0]/starter",0);
        setprop("controls/engines/engine[1]/starter",0);
		engine_crank_switch_pos_prop.setIntValue(0);

        if(jfs_starting){
            jfs_starting = 0;
            jfs_running = 1; # not really but just to get the sounds right.
            startupTimer.stop();
            engine_start_initiated = 0;
        }
        return;
    }

#
# if both running then just set the switch
    if (l_running and r_running)
    {
        if(n==0) 
            engine_crank_switch_pos_prop.setIntValue(1);

        if(n==1) 
            engine_crank_switch_pos_prop.setIntValue(2);

        shutdownTimer.stop();
        startupTimer.stop();
        engine_start_initiated = 0;
        return;
    }

#
#
# reset the timer.
    shutdownTimer.restart(jfsShutdownTime);

#
# If no source of bleed air (external or other engine running) then fire up JFS

    var bleed_air_available = jfs_running or l_running or r_running or getprop("/fdm/jsbsim/systems/electrics/ground-air");

    engine_start_initiated = 1;

    if (!bleed_air_available)
    {
        if (!jfs_running)
        {
            if (!jfs_starting)
            {
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
    }

	if (n == 0) {
		if (engine_crank_switch_pos == 0) {
            if (bleed_air_available){
                setprop("controls/engines/engine[0]/starter",1);
            }
			engine_crank_switch_pos_prop.setIntValue(1);
		} elsif (engine_crank_switch_pos == 1) {
			engine_crank_switch_pos_prop.setIntValue(0);
            setprop("controls/engines/engine[0]/starter",0);
		}
	}
    else 
    {
		if (engine_crank_switch_pos == 0) {
			engine_crank_switch_pos_prop.setIntValue(2);
            if (bleed_air_available){
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
# - not currently modelling fire extinguishers. We need the cutoff
#   for the engine start to work.
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

#
# engine controls panel - R RAMP switch
var econt_r_ramp = func(n) {
    setprop("sim/model/f-14b/controls/switch-r-ramp", n);
    if (n)
    {
    	Ramp1r.setValue(0);
    	Ramp2r.setValue(0);
    	Ramp3r.setValue(0);
    }
}

#
# engine controls panel - L RAMP switch
var econt_l_ramp = func(n) {

    setprop("sim/model/f-14b/controls/switch-l-ramp", n);

    if (n)
    {
    	Ramp1l.setValue(0);
    	Ramp2l.setValue(0);
    	Ramp3l.setValue(0);
    }
}

#
# engine controls panel - throttle mode
var econt_throttle_mode = func(n) {
    setprop("sim/model/f-14b/controls/switch-throttle-mode", n);
    if(n == 1) # Auto - APC
    {
        APC_on();
    }
    else
    {
    APC_off();
    }
}

#
# engine controls panel - backup ignition
var econt_backup_ignition_toggle = func {
    setprop("sim/model/f-14b/controls/switch-backup-ignition", 1 - getprop("sim/model/f-14b/controls/switch-backup-ignition"));
}

#
# engine controls panel - temperature switch
var econt_temp = func(n) {
    setprop("sim/model/f-14b/controls/switch-temp", n);
}

