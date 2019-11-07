# F-15 General Instrumentation related methods
# ---------------------------
# Richard Harrison (rjh@zaretto.com) Feb  2015 - based on F-14B version by Alexis Bory
# ---------------------------

var UPDATE_PERIOD = 0.05;
var main_loop_launched = 0; # Used to avoid to start the main loop twice.
var first_time_run = 0;

var Tc               = props.globals.getNode("instrumentation/tacan");
var Vtc              = props.globals.getNode("instrumentation/nav[1]");
var Hsd              = props.globals.getNode("sim/model/f15/instrumentation/hsd", 1);
var TcFreqs          = Tc.getNode("frequencies");
var TcTrueHdg        = Tc.getNode("indicated-bearing-true-deg");
var TcMagHdg         = Tc.getNode("indicated-mag-bearing-deg", 1);
var TcIdent          = Tc.getNode("ident");
var TcServ           = Tc.getNode("serviceable");
var TcXY             = Tc.getNode("frequencies/selected-channel[4]");
var VtcIdent         = Vtc.getNode("nav-id");
var VtcFromFlag      = Vtc.getNode("from-flag");
var VtcToFlag        = Vtc.getNode("to-flag");
var VtcHdgDeflection = Vtc.getNode("heading-needle-deflection");
var VtcRadialDeg     = Vtc.getNode("radials/selected-deg");
var HsdFromFlag      = Hsd.getNode("from-flag", 1);
var HsdToFlag        = Hsd.getNode("to-flag", 1);
var HsdCdiDeflection = Hsd.getNode("needle-deflection", 1);
var TcXYSwitch       = props.globals.getNode("sim/model/f15/instrumentation/tacan/xy-switch", 1);
var TcModeSwitch     = props.globals.getNode("sim/model/f15/instrumentation/tacan/mode", 1);
var ownship_pos = geo.Coord.new();
var aoa_max = props.globals.getNode("sim/model/f15/instrumentation/aoa/alpha-max-indicated-deg",1);

aircraft.data.add(VtcRadialDeg, TcModeSwitch);


var EmesaryRecipient =
{
    new: func(_ident)
    {
        var new_class = emesary.Recipient.new(_ident);
        new_class.ansn46_expiry = 0;
        new_class.Receive = func(notification)
        {
            if (notification.NotificationType == "GeoEventNotification") {
                print("received GeoNotification from ",notification.Callsign);
                print ("  pos=",notification.Position.lat(),notification.Position.lon(),notification.Position.alt());
                print ("  kind=",notification.Kind, " skind=",notification.SecondaryKind);
                if (notification.FromIncomingBridge) {
                    if (notification.Kind == 1) { # created
                        if (notification.SecondaryKind >=80 and notification.SecondaryKind <= 95) {
                            var missile = armament.AIM.new(0, "AIM-120");
                            missile.Tgt = awg_9.Target.new(props.globals.getNode("/"));
                            var tnode = props.globals.getNode("/");
                            missile.latN   = tnode.getNode("position/latitude-deg", 1);
                            missile.lonN   = tnode.getNode("position/longitude-deg", 1);
                            missile.altN   = tnode.getNode("position/altitude-ft", 1);
                            missile.hdgN   = tnode.getNode("orientation/true-heading-deg", 1);
                            missile.pitchN = tnode.getNode("orientation/pitch-deg", 1);
                            missile.rollN  = tnode.getNode("orientation/roll-deg", 1);

                            missile.s_down = getprop("velocities/speed-down-fps");
                            missile.s_east = getprop("velocities/speed-east-fps");
                            missile.s_north = getprop("velocities/speed-north-fps");

                            missile.coord = notification.Position;
                            missile.release();
                        } 
                    }
                }
                return emesary.Transmitter.ReceiptStatus_OK;
            } else if (notification.NotificationType == "AARQueryNotification") {
                notification.ProcessAircraft(geo.aircraft_position(), getprop("sim/model/f15/controls/fuel/refuel-probe-switch"));
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        new_class.Response = ANSPN46ActiveResponseNotification.new("ARA-63");
        return new_class;
    },
};



# TACAN mode switch
var set_tacan_mode = func(s) {
	var m = TcModeSwitch.getValue();
	if ( s == 1 and m < 5 ) {
		m += 1;
	} elsif ( s == -1 and m > 0 ) {
		m -= 1;
	}
	TcModeSwitch.setValue(m);
	if ( m == 0 or m == 5 ) {
		TcServ.setBoolValue(0);
	} else {
		TcServ.setBoolValue(1);
	}
}


# TACAN XY switch
var tacan_switch_init = func {
	if (TcXY.getValue() == "X") { TcXYSwitch.setValue( 0 ) } else { TcXYSwitch.setValue( 1 ) }
}

var tacan_XYtoggle = func {
	if ( TcXY.getValue() == "X" ) {
		TcXY.setValue( "Y" );
		TcXYSwitch.setValue( 1 );
	} else {
		TcXY.setValue( "X" );
		TcXYSwitch.setValue( 0 );
	}
}

# Save fuel state ###############
var bingo      = props.globals.getNode("sim/model/f15/controls/fuel/bingo", 1);

aircraft.data.add(	
    "sim/model/f15/controls/fuel/bingo",
    "consumables/fuel/tank[0]/level-lbs",
    "consumables/fuel/tank[1]/level-lbs",
    "consumables/fuel/tank[2]/level-lbs",
    "consumables/fuel/tank[3]/level-lbs",
    "consumables/fuel/tank[4]/level-lbs",
    "consumables/fuel/tank[5]/level-lbs",
    "consumables/fuel/tank[6]/level-lbs",
    "consumables/fuel/tank[7]/level-lbs",
    "consumables/fuel/tank[8]/level-lbs",
    "consumables/fuel/tank[9]/level-lbs",
    "consumables/fuel/tank[0]/level-gal_us",
    "consumables/fuel/tank[1]/level-gal_us",
    "consumables/fuel/tank[2]/level-gal_us",
    "consumables/fuel/tank[3]/level-gal_us",
    "consumables/fuel/tank[4]/level-gal_us",
    "consumables/fuel/tank[5]/level-gal_us",
    "consumables/fuel/tank[6]/level-gal_us",
    "consumables/fuel/tank[7]/level-gal_us",
    "consumables/fuel/tank[8]/level-gal_us",
    "consumables/fuel/tank[9]/level-gal_us",

    "consumables/fuel/tank[5]/selected",
    "consumables/fuel/tank[6]/selected",
    "consumables/fuel/tank[7]/selected",

    "/payload/weight[0]/selected",
    "/payload/weight[1]/selected",
    "/payload/weight[2]/selected",
    "/payload/weight[3]/selected",
    "/payload/weight[4]/selected",
    "/payload/weight[5]/selected",
    "/payload/weight[6]/selected",
    "/payload/weight[7]/selected",
    "/payload/weight[8]/selected",
    "/payload/weight[9]/selected",
    "/payload/weight[10]/selected",
    "sim/model/f15/systems/external-loads/external-load-set",
    "instrumentation/transponder/inputs/digit[0]", 
    "instrumentation/transponder/inputs/digit[1]", 
    "instrumentation/transponder/inputs/digit[2]", 
    "instrumentation/transponder/inputs/digit[3]",
    "sim/multiplay/generic/int[17]", # Radar status
    "sim/model/hide-pilot",
    "sim/model/hide-backseater",
    "sim/model/hide-pilots-auto",
"sim/model/f15/controls/VSD/brightness",
	"sim/model/f15/controls/VSD/contrast",
                  "sim/model/f15/controls/VSD/on-off",
                  "controls/lighting/anti-collision-switch",
                  "controls/lighting/aux-inst",
                  "controls/lighting/aux-instr-console",
                  "controls/lighting/beacon",
                  "controls/lighting/dome-norm",
                  "controls/lighting/eng-inst",
                  "controls/lighting/flt-inst",
                  "controls/lighting/hook-bypass",
                  "controls/lighting/index-norm",
                  "controls/lighting/instruments-norm",
                  "controls/lighting/l-console",
                  "controls/lighting/r-console",
                  "controls/lighting/l-console-eff-norm",
                  "controls/lighting/r-console-eff-norm",
                  "controls/lighting/landing-lights",
                  "controls/lighting/logo-lights",
                  "controls/lighting/nav-lights",
                  "controls/lighting/panel-norm",
                  "controls/lighting/position-flash-switch",
                  "controls/lighting/position-tail-switch",
                  "controls/lighting/position-wing-switch",
                  "controls/lighting/standby-inst",
                  "controls/lighting/stby-inst",
                  "controls/lighting/strobe",
                  "controls/lighting/taxi-light",
                  "controls/lighting/turn-off-lights",
                  "controls/lighting/warn-caution",
                  "sim/model/f15/lights/radio2-brightness",
                  "sim/multiplay/generic/int[1]", # lighting external see f15-common.xml for details
                  "sim/multiplay/generic/int[3]",
                  "sim/multiplay/generic/int[4]",
                  "sim/multiplay/generic/int[5]",
                  "sim/multiplay/generic/int[6]",
                  "sim/hud/visibility[0]",
                  "sim/hud/visibility[1]",
                  "sim/model/f15/controls/fuel/display-selector",
                  "sim/model/f15/controls/hud/on-off",
                  "sim/model/f15/controls/HSD/on-off",
                  "sim/model/f15/instrumentation/hud/mode-aa",
                  "sim/model/f15/instrumentation/hud/mode-ag",
                  "sim/model/f15/instrumentation/hud/mode-to",
                  "sim/model/f15/instrumentation/hud/mode-ldg",
                  "instrumentation/nav[0]/frequencies/selected-mhz",
                  "sim/model/f15/instrumentation/ils/volume-norm",
                  "ai/submodels/submodel[3]/count",
                  "sim/model/f15/systems/gun/rounds",
                  "sim/model/instrumentation/vhf/mode",
                  "sim/model/f15/controls/CAS/pitch-damper-enable",
                  "sim/model/f15/controls/CAS/roll-damper-enable",
                  "sim/model/f15/controls/CAS/yaw-damper-enable",
                  "sim/model/f15/controls/MPCD/mode",
                  "sim/model/f15/controls/windshield-heat",
                  "controls/pilots-displays/hsd-mode-nav",
                  "engines/engine[0]/running",
                  "engines/engine[1]/running",
# Air Speed Indicator #####
                  "sim/model/f15/instrumentation/airspeed-indicator/safe-speed-limit-bug",
# Lighting ################
                  "sim/model/f15/controls/lighting/hook-bypass",
                  "controls/lighting/instruments-norm",
                  "controls/lighting/panel-norm",
                  "sim/model/f15/controls/lighting/anti-collision-switch",
                  "sim/model/f15/controls/lighting/position-flash-switch",
                  "sim/model/f15/controls/lighting/position-wing-switch",
                  "autopilot/settings/aileron-deadzone",
                  "autopilot/settings/elevator-deadzone"
);

setlistener("/autopilot/settings/elevator-deadzone", func(v){
    if (v != nil)
      setprop("/fdm/jsbsim/fcs/elevator-deadzone",v.getValue());
}, 0, 0);

setlistener("/autopilot/settings/aileron-deadzone", func(v){
    if (v != nil)
      setprop("/fdm/jsbsim/fcs/aileron-deadzone",v.getValue());
}, 0, 0);


# Afterburners FX counter #
var burner = 0;
var BurnerN = props.globals.getNode("sim/model/f15/fx/burner", 1);
BurnerN.setValue(burner);

# Commons vars:
var Mach = props.globals.getNode("velocities/mach");
var mach = 0;

# Filters
var PitchPidPGain = props.globals.getNode("sim/model/f15/systems/afcs/pitch-pid-pgain", 1);
var PitchPidDGain = props.globals.getNode("sim/model/f15/systems/afcs/pitch-pid-dgain", 1);
var VsPidPGain    = props.globals.getNode("sim/model/f15/systems/afcs/vs-pid-pgain", 1);
var pgain = 0;

var afcs_filters = func {
	var f_mach = mach + 0.01;
	var p_gain = -0.008 / ( f_mach * f_mach * f_mach * f_mach * 1.2);
	if ( p_gain < -0.04 ) p_gain = -0.04;
	var d_gain = 0.4 * ( 2.5 - ( mach * 2 ));
	PitchPidPGain.setValue(p_gain);
	PitchPidDGain.setValue(d_gain);
	VsPidPGain.setValue(p_gain/10);
}

controls.stepSpoilers = func(s) {
        var curval = getprop("controls/flight/speedbrake");

        if (s < 0 and curval > 0)
            setprop("controls/flight/speedbrake", curval+s/5);
        else if (s > 0 and curval < 1)
            setprop("controls/flight/speedbrake", curval+s/5);
        return; 
}

var common_init = func
{
    print("Setting replay medium res to 50hz");
    setprop("sim/hud/visibility[0]",0);
    setprop("sim/hud/visibility[1]",0);
    aoa_max.setDoubleValue(0);

    setprop("sim/replay/buffer/medium-res-sample-dt", 0.02); 
    setprop("controls/flight/SAS-roll",0);
    setprop("sim/model/f15/controls/AFCS/engage",0);
    setprop("autopilot/locks/altitude","");
    setprop("autopilot/locks/heading","");
    setprop("autopilot/locks/speed","");

    if (getprop("sim/model/f15/controls/windshield-heat") != nil)
      setprop("fdm/jsbsim/systems/ecs/windshield-heat",getprop("sim/model/f15/controls/windshield-heat"));

    #
    # this is just to ensure that we start with pressure in the util hyds
    setprop("fdm/jsbsim/systems/hydraulics/util-system-preload-input",-500);
    settimer(func {
        setprop("fdm/jsbsim/systems/hydraulics/util-system-preload-input",0); 
    }, 4);
    if (getprop("fdm/jsbsim/position/h-agl-ft") != nil) {
        if (getprop("fdm/jsbsim/position/h-agl-ft") < 500) {
            print("Starting with gear down as below 500 ft");
            setprop("controls/gear/gear-down", 1);
            setprop("fdm/jsbsim/fcs/gear/gear-dmd-norm",1);

            if (getprop("fdm/jsbsim/position/h-agl-ft") < 50) {
                setprop("controls/gear/brake-parking",1);
                print("--> Set parking brake as below 50 ft");
            }
        } else {
            print("Starting with gear up as above 500 ft");
            setprop("controls/gear/gear-down", 0);
            setprop("fdm/jsbsim/fcs/gear/gear-dmd-norm",0);
            setprop("controls/gear/brake-parking",0);
        }
    }
}

# Init ####################
var init = func {
	print("Initializing f15 Systems");
    var modelNotification = emesary.Notification.new("F15Model", nil);
    modelNotification.root_node = props.globals;
    emesary.GlobalTransmitter.NotifyAll(modelNotification);
    emesary.GlobalTransmitter.NotifyAll(emesary.Notification.new("F15Init", 1));
	ext_loads_init();
	init_fuel_system();
	aircraft.data.load();
	f15_net.mp_network_init(1);
	weapons_init();
	tacan_switch_init();
	radardist.init();
	awg_9.init();
#	an_arc_182v.init();
#	an_arc_159v1.init();
    aircraft.setup_als_lights(getprop("fdm/jsbsim/systems/electrics/dc-essential-bus1-powered"));

	setprop("controls/switches/radar_init", 0);

    common_init();
     main_loop_launched = 1;
    var prop = "/instrumentation/radar";
    var actuator_radar = compat_failure_modes.set_unserviceable(prop);
    FailureMgr.add_failure_mode(prop, "Radar", actuator_radar);
}

setlistener("sim/signals/fdm-initialized", init);


setlistener("sim/position-finalized", func (is_done) {
    if (is_done.getValue())
    {
    common_init();
#        common_carrier_init();
    }
    if(first_time_run)  {
        print(">> First time run");
        setprop("consumables/fuel/tank[5]/selected",false);
        setprop("consumables/fuel/tank[6]/selected",false);
        setprop("consumables/fuel/tank[7]/selected",false);
        
        setprop("consumables/fuel/tank[5]/level-lbs",0);
        setprop("consumables/fuel/tank[6]/level-lbs",0);
        setprop("consumables/fuel/tank[7]/level-lbs",0);
    }
});
setlistener("sim/signals/reinit", func (reinit) {
    if (reinit.getValue()) {
        internal_save_fuel();
    } else {
        settimer(func { internal_restore_fuel() }, 0.6);
    }
});
# Miscelaneous definitions and tools ############

# warning lights medium speed flasher
# -----------------------------------
aircraft.light.new("sim/model/f15/lighting/warn-medium-lights-switch", [0.3, 0.2]);
setprop("sim/model/f15/lighting/warn-medium-lights-switch/enabled", 1);

#var routedNotifications = [notifications.GeoEventNotification.new(nil)];
#var incomingBridge = emesary_mp_bridge.IncomingMPBridge.startMPBridge(routedNotifications);
#var outgoingBridge = emesary_mp_bridge.OutgoingMPBridge.new("F-15mp",routedNotifications);

var INSTRUMENTS_Recipient =
{
    new: func(_ident)
    {
        var new_class = emesary.Recipient.new(_ident);
        new_class.Receive = func(notification){
            if (notification.NotificationType == "FrameNotification") {
                var frame_count = math.mod(notifications.frameNotification.FrameCount,7);
                if (main_loop_launched){
                    mach = Mach.getValue();
                    var cnt = notification.FrameCount;
                    
                    ownship_pos.set_latlon(getprop("position/latitude-deg"), getprop("position/longitude-deg"));
                    
                    burner +=1;
                    if ( burner == 3 ) { burner = 0 }
                    BurnerN.setValue(burner);
                    
                    if ( getprop("sim/replay/time") > 0 ) 
                        setprop("orientation/alpha-indicated-deg", (getprop("orientation/alpha-deg") - 0.797) / 0.8122);
                    else
                        setprop("orientation/alpha-indicated-deg", getprop("fdm/jsbsim/aero/alpha-indicated-deg"));
                    
                    if (frame_count == 0) {
                        if ((notification.Alpha or 0) > aoa_max.getValue() or 0) {
                            aoa_max.setDoubleValue(notification.Alpha);
                        }
                        f15_chronograph.update_chrono();
                    }
                    if (frame_count == 6) {
                        fuel_update();
                        cnt = 0;
                    }
                    if (frame_count == 2) {
                        awg_9.hud_nearest_tgt();
                        
                        if ( notification.ArmSysRunning ) {
                            armament_update();
                        }
                    }
                    if (frame_count == 3) {
                        afcs_filters();
                    }
                }
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        return new_class;
    },
};

emesary.GlobalTransmitter.Register(INSTRUMENTS_Recipient.new("F15-inst"));
  input = {
          Alpha                 : "orientation/alpha-indicated-deg",
          frame_rate                : "/sim/frame-rate",
          frame_rate_worst          : "/sim/frame-rate-worst",
          elapsed_seconds           : "/sim/time/elapsed-sec",
          TcFreqs          : "instrumentation/tacan/frequencies",
          TcTrueHdg        : "instrumentation/tacan/indicated-bearing-true-deg",
          TcMagHdg         : "instrumentation/tacan/indicated-mag-bearing-deg",
          TcIdent          : "instrumentation/tacan/ident",
          TcServ           : "instrumentation/tacan/serviceable",
          TcXY             : "instrumentation/tacan/frequencies/selected-channel[4]",
          VtcIdent         : "instrumentation/nav[1]/nav-id",
          VtcFromFlag      : "instrumentation/nav[1]/from-flag",
          VtcToFlag        : "instrumentation/nav[1]/to-flag",
          VtcHdgDeflection : "instrumentation/nav[1]/heading-needle-deflection",
          VtcRadialDeg     : "instrumentation/nav[1]/radials/selected-deg",
          HsdFromFlag      : "sim/model/f15/instrumentation/hsd/from-flag",
          HsdToFlag        : "sim/model/f15/instrumentation/hsd/to-flag",
          HsdCdiDeflection : "sim/model/f15/instrumentation/hsd/needle-deflection", 
          TcXYSwitch       : "sim/model/f15/instrumentation/tacan/xy-switch",
          TcModeSwitch     : "sim/model/f15/instrumentation/tacan/mode",
          MagHdg           : "orientation/heading-magnetic-deg",
          MagDev           : "orientation/local-mag-dev",
          ArmSysRunning : "sim/model/f15/systems/armament/system-running",
          };

foreach (var name; keys(input)) {
    emesary.GlobalTransmitter.NotifyAll(notifications.FrameNotificationAddProperty.new("F15-inst", name, input[name]));
}
