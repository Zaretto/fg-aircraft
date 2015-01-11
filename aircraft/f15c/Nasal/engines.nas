var egt_norm1 = props.globals.getNode("engines/engine[0]/egt-norm", 1);
var egt_norm2 = props.globals.getNode("engines/engine[1]/egt-norm", 1);
var egt1_rankin = props.globals.getNode("engines/engine[0]/egt-degR", 1);
var egt2_rankin = props.globals.getNode("engines/engine[1]/egt-degR", 1);
var egt1 = props.globals.getNode("fdm/jsbsim/propulsion/engine[0]/EGT-R", 1);
var egt2 = props.globals.getNode("fdm/jsbsim/propulsion/engine[1]/EGT-R", 1);

var Engine1Burner = props.globals.initNode("engines/engine[0]/afterburner", 0, "DOUBLE");
var Engine2Burner = props.globals.initNode("engines/engine[1]/afterburner", 0, "DOUBLE");
var Engine1Augmentation = props.globals.getNode("engines/engine[0]/augmentation",1);
var Engine2Augmentation = props.globals.getNode("engines/engine[1]/augmentation",1);


#props.globals.getNode("sim/model/f15/fx/test1",1);
#props.globals.getNode("sim/model/f15/fx/test2",1);
setprop("sim/model/f15/gear-sound-freeze",0);
setprop("sim/model/f15/engine-sound-freeze",0);
setprop("sim/model/f15/controls/engines/switch-backup-ignition",0);

setprop("/fdm/jsbsim/propulsion/engine[0]/nozzle-pos-norm",1);
setprop("/fdm/jsbsim/propulsion/engine[1]/nozzle-pos-norm",1);

#var l_engine_pitch_n1  = props.globals.getNode("sim/model/f15/fx/engine/l-engine-pitch-n1",1);
#var l_engine_pitch_n1  = props.globals.getNode("sim/model/f15/fx/engine/l-engine-pitch-n2",1);
#var l_inlet  = props.globals.getNode("sim/model/f15/fx/engine/l-engine-inlet",1);
#var l_efflux  = props.globals.getNode("sim/model/f15/fx/engine/l-engine-efflux",1);

var l_running_prop = props.globals.getNode("engines/engine[0]/running",1);
var r_running_prop = props.globals.getNode("engines/engine[1]/running",1);
var l_n1_prop = props.globals.getNode("engines/engine[0]/n1",1);
var r_n1_prop = props.globals.getNode("engines/engine[1]/n1",1);
var l_starter_prop = props.globals.getNode("controls/engines/engine[0]/starter");
var r_starter_prop = props.globals.getNode("controls/engines/engine[1]/starter");

var engine_crank_switch_pos_prop = props.globals.getNode("sim/model/f15/controls/engine/engine-crank",1);
engine_crank_switch_pos_prop.setValue(0);
var engine_start_initiated = 0;

var jfs_start = props.globals.getNode("sim/model/f15/controls/jfs",1);
var jfs_running_lamp = props.globals.getNode("sim/model/f15/lights/jfs-ready",1);
jfs_start.setValue(0);
jfs_running_lamp.setValue(0);

var jfs_invoke_shutdown_active = 0;
var jfs_set_running_active = 0;

var GearPos   = props.globals.getNode("gear/gear[0]/position-norm", 1);


#----------------------------------------------------------------------------
# Nozzle opening
#----------------------------------------------------------------------------

# Constant
NozzleSpeed = 1.0;
var current_flame_number = 0;

var computeEngines = func {

   current_flame_number = (current_flame_number + 1);        
   if (current_flame_number > 3) current_flame_number = 0;
   setprop("sim/model/f15/fx/flame-number",current_flame_number);


	var eng1_burner = Engine1Burner.getValue();
	var eng2_burner = Engine2Burner.getValue();

    # 492 is 0 deg F in Rankin. The rankin scale starts from absolute zero.
	egt_norm1.setValue((egt1.getValue()-492)*0.000679348);
	egt_norm2.setValue((egt2.getValue()-492)*0.000679348);

    egt1_rankin.setValue(egt1.getValue());
    egt2_rankin.setValue(egt2.getValue());

    	if ( getprop("sim/replay/time") > 0 ) 
        { 
            setprop("engines/engine[0]/augmentation", getprop("engines/engine[0]/afterburner"));
            setprop("engines/engine[1]/augmentation", getprop("engines/engine[1]/afterburner"));
        }
        else
        {
            Engine1Burner.setDoubleValue(Engine1Augmentation.getValue());
            Engine2Burner.setDoubleValue(Engine2Augmentation.getValue());
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
    jfs_running_lamp.setValue(jfs_running);
    setprop("fdm/jsbsim/systems/engines/jfs-running",jfs_running);
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
    if (getprop("sim/model/f15/controls/electrics/jfs-starter")) 
        return;
    var jfs_switch_pos = getprop("sim/model/f15/controls/electrics/jfs-starter");

    # do nothing whilst not running or when the switch is still set.
    var l_running = l_running_prop.getValue();
    var r_running = r_running_prop.getValue();

#
# If neither engine running then need JFS
    if (!l_running and !r_running)
    {
        if(!jfs_running or jfs_switch_pos)
        {
            return;
        }
    }
    if (jfs_running)
    {
        jfs_start.setValue(1);
        jfs_running = 0;
        jfs_starting = 0;
jfs_running_lamp.setValue(jfs_running);
    setprop("fdm/jsbsim/systems/engines/jfs-running",jfs_running);
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

setprop("sim/model/f15/controls/electrics/jfs-starter",0);

#
#
# Switch / action callbacks
setlistener("sim/model/f15/controls/electrics/jfs-starter", func {
    var jfs_starter  = getprop("sim/model/f15/controls/electrics/jfs-starter");

    if (jfs_starter)
    {
        print("JFS Starter callback");
            var l_running = l_running_prop.getValue();
            var r_running = r_running_prop.getValue();
        if (!jfs_running)
        {

            shutdownTimer.restart(jfsShutdownTime);

            if (!jfs_starting)
            {
                jfs_starting = 1;
                jfs_start.setValue(10);
                startupTimer.restart(jfsStartupTime);
                print("Start JFS");
            }
            return;
        }
        else
        {
            print("JFS cannot start because already running or engines running");
        }
 
    }
    else
    {
        jfs_start.setValue(1);
        jfs_running = 0;
        jfs_starting = 0;
        jfs_running_lamp.setValue(jfs_running);
    setprop("fdm/jsbsim/systems/engines/jfs-running",jfs_running);
        print("Jfs shutdown");
    }
});


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
setlistener("sim/model/f15/controls/engines/l-ramp-switch", func {
    var v = getprop("sim/model/f15/controls/engines/l-ramp-switch");
    if (v != nil)
    {
        if (v == 0)
            setprop("fdm/jsbsim/propulsion/inlet/l-inlet-ramp-emerg", 1);
        else
            setprop("fdm/jsbsim/propulsion/inlet/l-inlet-ramp-emerg", 0);
    }
});
setlistener("sim/model/f15/controls/engines/r-ramp-switch", func {
    var v = getprop("sim/model/f15/controls/engines/r-ramp-switch");
    if (v != nil)
    {
        if (v == 0)
            setprop("fdm/jsbsim/propulsion/inlet/r-inlet-ramp-emerg", 1);
        else
            setprop("fdm/jsbsim/propulsion/inlet/r-inlet-ramp-emerg", 0);
    }
});
