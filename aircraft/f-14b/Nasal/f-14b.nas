# Utilities #########
# Version checking based on the work of Joshua Davidson
if (num(string.replace(getprop("/sim/version/flightgear"),".","")) < 201620) {
    gui.showDialog("fg-version");
}

# Lighting 
#setprop("sim/model/path","data/Aircraft/f-14b/F-14B.xml");

# Collision lights flasher
var anti_collision_switch = props.globals.getNode("sim/model/f-14b/controls/lighting/anti-collision-switch");
aircraft.light.new("sim/model/f-14b/lighting/anti-collision", [0.09, 1.20], anti_collision_switch);

# Navigation lights steady/flash dimmed/bright
var position_flash_sw = props.globals.getNode("sim/model/f-14b/controls/lighting/position-flash-switch");
var position = aircraft.light.new("sim/model/f-14b/lighting/position", [0.08, 1.15]);
setprop("/sim/model/f-14b/lighting/position/enabled", 1);
#setprop("sim/model/f-14b/fx/smoke-colors-demand",0);

var lighting_taxi  = props.globals.getNode("controls/lighting/taxi-light", 1);

getprop("fdm/jsbsim/fcs/flap-pos-norm",0);
var sw_pos_prop = props.globals.getNode("sim/model/f-14b/controls/lighting/position-wing-switch", 1);
var position_intens = 0;
setprop("fdm/jsbsim/Factor1",1);
setprop("sim/fdm/surface/override-level", 0);

aircraft.tyresmoke_system.new(0, 1, 2);
aircraft.rain.init();

#
# 2017.3 or earlier FG compatibility fixes
# Remove after 2017.4
string.truncateAt = func(src, match){
    var rv = nil;
    call(func {
        if (src != nil and match !=nil) {
            var pos = find(match,src);
            if (pos>=0)
              src=substr(src,0,pos);
        }
    }, nil, var err = []);
    return src;
}
setprop("controls/lighting/white-flood-dim-red", getprop("controls/lighting/white-flood-red")/2.0);
setprop("controls/lighting/white-flood-dim-green", getprop("controls/lighting/white-flood-green")/2.0);
setprop("controls/lighting/white-flood-dim-blue", getprop("controls/lighting/white-flood-blue")/2.0);
setprop("controls/lighting/white-flood-off-red", 0);
setprop("controls/lighting/white-flood-off-green", 0);
setprop("controls/lighting/white-flood-off-blue", 0);
setprop("controls/lighting/white-flood-brt-red", getprop("controls/lighting/white-flood-red"));
setprop("controls/lighting/white-flood-brt-green", getprop("controls/lighting/white-flood-green"));
setprop("controls/lighting/white-flood-brt-blue", getprop("controls/lighting/white-flood-blue"));


var white_flood_switch_prop = props.globals.getNode("sim/model/f-14b/controls/lighting/white-flood-light-switch", 1);
var white_flood = props.globals.getNode("controls/lighting/dome-norm", 1);

white_flood_switch = func{
	set_flood_lighting_colour();
}
var red_flood_switch_prop = props.globals.getNode("sim/model/f-14b/controls/lighting/red-flood-light-switch", 1);
var red_flood = props.globals.getNode("controls/lighting/dome-red-norm", 1);

red_flood_switch = func{
	set_flood_lighting_colour();
}

setlistener("controls/lighting/instruments-norm", func(v){
    set_flood_lighting_colour();
},0,0);
var color_encode_factors = [
    1073741824, # 0
    33554432,   # 1
    1048576,    # 2
    32768,      # 3
    1024,       # 4
    32,         # 5
    1           # 6  
];

var color_encode_props = [
    props.getNode("sim/model/f-14b/fx/vapour-color-left-r" , 1),
    props.getNode("sim/model/f-14b/fx/vapour-color-left-g" , 1),
    props.getNode("sim/model/f-14b/fx/vapour-color-left-b" , 1),
    props.getNode("sim/model/f-14b/fx/vapour-color-right-r", 1),
    props.getNode("sim/model/f-14b/fx/vapour-color-right-g", 1),
    props.getNode("sim/model/f-14b/fx/vapour-color-right-b", 1)
];
smoke_vv = 0;
smoke_v = 0;
var smokeNode = props.getNode("/sim/model/f-14b/fx/smoke-colors-demand",1);
set_smoke_color = func{

    #r1 << 25 | g1 << 20 | b1 << 15  | r2 << 10 | g2 << 5 | b2
    smoke_v = 0;
#    print("set_smoke_color");
    for (var i = 0; i < 6; i = i+1)
    {
        smoke_v0 = int(math.min(color_encode_props[i].getValue()*31,31));
        smoke_vv = int(smoke_v0 * color_encode_factors[i+1]);
#        printf(" -- %d => %2d %8x",i,smoke_v0,smoke_vv);
        smoke_v = smoke_v + smoke_vv;
    }
#    printf("set smoke colour to %x",smoke_v);
    smokeNode.setIntValue(smoke_v);
}

setlistener("sim/model/f-14b/fx/vapour-color-left-r" , func(n) {set_smoke_color();});
setlistener("sim/model/f-14b/fx/vapour-color-left-g" , func(n) {set_smoke_color();});
setlistener("sim/model/f-14b/fx/vapour-color-left-b" , func(n) {set_smoke_color();});
setlistener("sim/model/f-14b/fx/vapour-color-right-r", func(n) {set_smoke_color();});
setlistener("sim/model/f-14b/fx/vapour-color-right-g", func(n) {set_smoke_color();});
setlistener("sim/model/f-14b/fx/vapour-color-right-b", func(n) {set_smoke_color();});

# now ensure that the initial colour for smoke is set.
set_smoke_color ();

# sets the flood lighting and instrument lighting illuminations
# based on the setting of
# - donme flood white switch (dim,off,bright)
# - red flood switch (dim, med, bright)
# - instrument lighting wheel

set_flood_lighting_colour = func
{
	var red_pos = red_flood_switch_prop.getValue();
	var red_prop = "";
    if (red_pos == 1)
	{
		red_prop = "controls/lighting/red-flood-med";
	}
	else if (red_pos == 2)
	{
		red_prop = "controls/lighting/red-flood-brt";
	}
	else 
	{
		red_prop = "controls/lighting/red-flood-dim";
	}
    var r = getprop(red_prop ~ "-red");
	var g = getprop(red_prop ~ "-green");
	var b = getprop(red_prop ~ "-blue");

	var white_prop = "";
	var white_pos = white_flood_switch_prop.getValue();
	if (white_pos == 0)
	{
		white_prop = "controls/lighting/white-flood-dim";
	}
	else if (white_pos == 2)
	{
		white_prop = "controls/lighting/white-flood-brt";
	}
	else
	{
		white_prop = "controls/lighting/white-flood-off";
	}
    if (red_pos == 0 and white_pos == 1)
        white_flood.setValue(0);
    else
        white_flood.setValue(1);

	var white_r = getprop(white_prop~"-red");
	var white_g = getprop(white_prop~"-green");
	var white_b = getprop(white_prop~"-blue");

	if (white_flood_switch_prop.getValue() != 1)
	{
		r = math.min(1.0,r + white_r);
		g = math.min(1.0,g + white_g);
		b = math.min(1.0,b + white_b);
	}

	setprop("controls/lighting/dome-red",r);
	setprop("controls/lighting/dome-green",g);
	setprop("controls/lighting/dome-blue",b);

# now blend the red/dome light and the instrument lights; this used to be 
# done via conditions in the cockpit model emissions however when I added
# support for the red flood we need to be a bit more sophisticated in 
# how we blend the lights - so that the insruments will be displayed in red
# unless the instrument lighing is bright enough to shine through.
    var instrument_norm = getprop("controls/lighting/instruments-norm");
    inst_prop = "controls/lighting/white-flood-brt";
    var inst_r = math.min(1.0,r + getprop(inst_prop~"-red") * instrument_norm);
    var inst_g = math.min(1.0,g + getprop(inst_prop~"-green") * instrument_norm);
    var inst_b = math.min(1.0,b + getprop(inst_prop~"-blue") * instrument_norm);
    setprop("controls/lighting/instrument-red", inst_r);
    setprop("controls/lighting/instrument-green", inst_g);
    setprop("controls/lighting/instrument-blue", inst_b);
}


position_switch = func(n) {
	var sw_pos = sw_pos_prop.getValue();
    print("position switch ",n," -> ",sw_pos);
    if (sw_pos == 0){
              position.switch(1);
                position_intens = 3;
    } else if (sw_pos == 1){
                position.switch(0);
                position_intens = 0;
    } else if (sw_pos == 2){
                position.switch(1);
                position_intens = 6;
    }
}

position_flash_switch = func {
	if (! position_flash_sw.getBoolValue() ) {
		position_flash_sw.setBoolValue(1);
		position.blink();
	} else {
		position_flash_sw.setBoolValue(0);
		position.cont();
	}
}

var position_flash_init  = func {
	if (position_flash_sw.getBoolValue() ) {
		position.blink();
	} else {
		position.cont();
	}
	var sw_pos = sw_pos_prop.getValue();
	if (sw_pos == 0 ) {
		position_intens = 3;
		position.switch(1);
	} elsif (sw_pos == 1 ) {
		position_intens = 0;
		position.switch(0);
	} elsif (sw_pos == 2 ) {
		position_intens = 6;
		position.switch(1);
	}
}


# Canopy switch animation and canopy move. Toggle keystroke and 2 positions switch.
var cnpy = aircraft.door.new("canopy", 3.9);
#
#
# 
setprop("sim/model/f-14b/controls/canopy/canopy-switch", 0);
var pos = props.globals.getNode("canopy/position-norm");

setlistener("sim/model/f-14b/config/mod-AFC-735", func(v) {
#    print("AFC-735 active=",v.getValue());
    setprop("/fdm/jsbsim/fcs/mod-dlc-AFC-735-active",v.getValue());
}, 1, 0);

#
#
# cockpit will simply toggle the value of this.
setlistener("sim/model/f-14b/controls/canopy/canopy-switch", func(v) {
	if (v.getValue()) 
        cnpy.open();
    else
		cnpy.close();

}, 1, 0);
#
#
# canopy switch toggle (from keyboard).
var canopyswitch = func(v) {
    var cp = getprop("sim/model/f-14b/controls/canopy/canopy-switch");

    setprop("sim/model/f-14b/controls/canopy/canopy-switch", 1 - cp);
}


# Flight control system ######################### 

# timedMotions

var CurrentLeftSpoiler = 0.0;
var CurrentRightSpoiler = 0.0;
var CurrentInnerLeftSpoiler = 0.0;
var CurrentInnerRightSpoiler = 0.0;
var SpoilerSpeed = 1.0; # full extension in 1 second
var currentSweep = 0.0;
var SweepSpeed = 0.3;


# Properties used for multiplayer syncronization.
var main_flap_output   = props.globals.getNode("surface-positions/main-flap-pos-norm", 1);
var aux_flap_output    = props.globals.getNode("surface-positions/aux-flap-pos-norm", 1);
var slat_output        = props.globals.getNode("surface-positions/slats-pos-norm", 1);

if (usingJSBSim){
    aux_flap_output    = props.globals.getNode("/fdm/jsbsim/fcs/aux-flap-pos-norm", 1);
    aux_flap_output.setDoubleValue(0);
var slat_output     = props.globals.getNode("/fdm/jsbsim/fcs/slat-cmd-norm", 1);
}
else
{
    slat_output        = props.globals.getNode("surface-positions/slats-pos-norm", 1);
}
aux_flap_output.setDoubleValue(0);


var left_elev_output   = props.globals.getNode("surface-positions/left-elevator-pos-norm", 1);
var right_elev_output  = props.globals.getNode("surface-positions/right-elevator-pos-norm", 1);
var elev_output   = props.globals.getNode("surface-positions/elevator-pos-norm", 1);
var aileron = props.globals.getNode("surface-positions/left-aileron-pos-norm", 1);

var lighting_collision = props.globals.getNode("sim/model/f-14b/lighting/anti-collision/state", 1);
var lighting_position  = props.globals.getNode("sim/model/f-14b/lighting/position/state", 1);
var left_wing_torn     = props.globals.getNode("sim/model/f-14b/wings/left-wing-torn");
var right_wing_torn    = props.globals.getNode("sim/model/f-14b/wings/right-wing-torn");

#var wing_sweep_generic  = props.globals.getNode("sim/multiplay/generic/float[0]",1);
var main_flap_generic  = props.globals.getNode("sim/multiplay/generic/float[1]",1);
var aux_flap_generic   = props.globals.getNode("sim/multiplay/generic/float[2]",1);
var slat_generic       = props.globals.getNode("sim/multiplay/generic/float[3]",1);
var left_elev_generic  = props.globals.getNode("sim/multiplay/generic/float[4]",1);
var right_elev_generic = props.globals.getNode("sim/multiplay/generic/float[5]",1);
var fuel_dump_generic  = props.globals.getNode("sim/multiplay/generic/int[0]",1);
# sim/multiplay/generic/int[1] used by formation slimmers.
# sim/multiplay/generic/int[2] used by radar standby.
var lighting_collision_generic = props.globals.getNode("sim/multiplay/generic/int[3]",1);
var lighting_position_generic  = props.globals.getNode("sim/multiplay/generic/int[4]",1);
var left_wing_torn_generic     = props.globals.getNode("sim/multiplay/generic/int[5]",1);
var right_wing_torn_generic    = props.globals.getNode("sim/multiplay/generic/int[6]",1);
var lighting_taxi_generic       = props.globals.getNode("sim/multiplay/generic/int[7]",1);
# sim/multiplay/generic/string[0] used by external loads, see ext_stores.nas.

var timedMotions = func {

	# disable if we are in replay mode
	if ( getprop("sim/replay/time") > 0 ) { return }

	if (deltaT == nil) deltaT = 0.0;

    if (!usingJSBSim){
    	# Outboard Spoilers
    	if (CurrentLeftSpoiler > LeftSpoilersTarget ) {
    		CurrentLeftSpoiler -= SpoilerSpeed * deltaT;
    		if (CurrentLeftSpoiler < LeftSpoilersTarget) {
    			CurrentLeftSpoiler = LeftSpoilersTarget;
    		}
    	} elsif (CurrentLeftSpoiler < LeftSpoilersTarget) {
    		CurrentLeftSpoiler += SpoilerSpeed * deltaT;
    		if (CurrentLeftSpoiler > LeftSpoilersTarget) {
    			CurrentLeftSpoiler = LeftSpoilersTarget;
    		}
    	}
    
    	if (CurrentRightSpoiler > RightSpoilersTarget ) {
    		CurrentRightSpoiler -= SpoilerSpeed * deltaT;
    		if (CurrentRightSpoiler < RightSpoilersTarget) {
    			CurrentRightSpoiler = RightSpoilersTarget;
    		}
    	} elsif (CurrentRightSpoiler < RightSpoilersTarget) {
    		CurrentRightSpoiler += SpoilerSpeed * deltaT;
    		if (CurrentRightSpoiler > RightSpoilersTarget) {
    			CurrentRightSpoiler = RightSpoilersTarget;
    		}
    	}
    
    	# Inboard Spoilers
    	if (CurrentInnerLeftSpoiler > InnerLeftSpoilersTarget ) {
    		CurrentInnerLeftSpoiler -= SpoilerSpeed * deltaT;
    		if (CurrentInnerLeftSpoiler < InnerLeftSpoilersTarget) {
    			CurrentInnerLeftSpoiler = InnerLeftSpoilersTarget;
    		}
    	} elsif (CurrentInnerLeftSpoiler < InnerLeftSpoilersTarget) {
    		CurrentInnerLeftSpoiler += SpoilerSpeed * deltaT;
    		if (CurrentInnerLeftSpoiler > InnerLeftSpoilersTarget) {
    			CurrentInnerLeftSpoiler = InnerLeftSpoilersTarget;
    		}
    	}
    
    	if (CurrentInnerRightSpoiler > InnerRightSpoilersTarget ) {
    		CurrentInnerRightSpoiler -= SpoilerSpeed * deltaT;
    		if (CurrentInnerRightSpoiler < InnerRightSpoilersTarget) {
    			CurrentInnerRightSpoiler = InnerRightSpoilersTarget;
    		}
    	} elsif (CurrentInnerRightSpoiler < InnerRightSpoilersTarget) {
    		CurrentInnerRightSpoiler += SpoilerSpeed * deltaT;
    		if (CurrentInnerRightSpoiler > InnerRightSpoilersTarget) {
    			CurrentInnerRightSpoiler = InnerRightSpoilersTarget;
    		}
    	}

# Engine nozzles
        if (Nozzle1 > Nozzle1Target) {
            Nozzle1 -= NozzleSpeed * deltaT;
            if (Nozzle1 < Nozzle1Target) {
                Nozzle1 = Nozzle1Target;
            }
        } elsif (Nozzle1 < Nozzle1Target) {
            Nozzle1 += NozzleSpeed * deltaT;
            if (Nozzle1 > Nozzle1Target) {
                Nozzle1 = Nozzle1Target;
            }
        }

        if (Nozzle2 > Nozzle2Target) {
            Nozzle2 -= NozzleSpeed * deltaT;
            if (Nozzle2 < Nozzle2Target) {
                Nozzle2 = Nozzle2Target;
            }
        } elsif (Nozzle2 < Nozzle2Target) {
            Nozzle2 += NozzleSpeed * deltaT;
            if (Nozzle2 > Nozzle2Target) {
                Nozzle2 = Nozzle2Target;
            }
        }

# Wing Sweep
    	if (currentSweep > WingSweep) {
    		currentSweep -= SweepSpeed * deltaT;
    		if (currentSweep < WingSweep) {
    			currentSweep = WingSweep;
    		}
    	} elsif (currentSweep < WingSweep) {
    		currentSweep += SweepSpeed * deltaT;
    		if (currentSweep > WingSweep) {
    			currentSweep = WingSweep;
    		}
	    }
    }

	setprop ("surface-positions/left-spoilers", CurrentLeftSpoiler);
	setprop ("surface-positions/right-spoilers", CurrentRightSpoiler);
	setprop ("surface-positions/inner-left-spoilers", CurrentInnerLeftSpoiler);
	setprop ("surface-positions/inner-right-spoilers", CurrentInnerRightSpoiler);
	setprop ("surface-positions/wing-pos-norm", currentSweep);
	setprop ("/fdm/jsbsim/fcs/wing-sweep", currentSweep);

	# Copy surfaces animations properties so they are transmited via multiplayer.
    if (usingJSBSim)
    {
        if (main_flap_generic != nil)
        {    
    	    #main_flap_generic.setDoubleValue(getprop("fdm/jsbsim/fcs/flap-pos-norm"));
        } 

        if (aux_flap_generic != nil)
        {
            aux_flap_generic.setDoubleValue(aux_flap_output.getValue());
        }

        # the F14 FDM has a combined aileron deflection so split this for animation purposes.
        var current_aileron = aileron.getValue();
        if (getprop("/autopilot/locks/heading") == "wing-leveler" and abs(getprop("fdm/jsbsim/fcs/aileron-cmd-norm")) > deadZ_roll)
        {
            setprop("autopilot/settings/target-roll-deg", getprop("orientation/roll-deg"));
        }
        if (getprop("/autopilot/locks/altitude") == "pitch-hold" and abs(getprop("fdm/jsbsim/fcs/elevator-cmd-norm")) > deadZ_pitch)
        {
            setprop("autopilot/settings/target-pitch-deg", getprop("orientation/pitch-deg"));
        }
        var elevator_deflection_due_to_aileron_deflection =  current_aileron / 2.0;
    	left_elev_generic.setDoubleValue(elev_output.getValue() + elevator_deflection_due_to_aileron_deflection);
    	right_elev_generic.setDoubleValue(elev_output.getValue() - elevator_deflection_due_to_aileron_deflection);

    }
    else
    {
    	setprop ("engines/engine[0]/nozzle-pos-norm", Nozzle1);
    	setprop ("engines/engine[1]/nozzle-pos-norm", Nozzle2);
    	aux_flap_generic.setDoubleValue(aux_flap_output.getValue());
    	slat_generic.setDoubleValue(slat_output.getValue());
    	left_elev_generic.setDoubleValue(left_elev_output.getValue());
    	right_elev_generic.setDoubleValue(right_elev_output.getValue());
    }
	slat_generic.setDoubleValue(slat_output.getValue());
    #wing_sweep_generic.setDoubleValue(currentSweep);
	lighting_collision_generic.setIntValue(lighting_collision.getValue());
	lighting_position_generic.setIntValue(lighting_position.getValue() * position_intens);
	left_wing_torn_generic.setIntValue(left_wing_torn.getValue());
	right_wing_torn_generic.setIntValue(right_wing_torn.getValue());
	lighting_taxi_generic.setIntValue(lighting_taxi.getValue());

setprop("/sim/multiplay/generic/float[8]", getprop("/engines/engine[0]/augmentation-burner" ));
setprop("/sim/multiplay/generic/float[9]", getprop("/engines/engine[1]/augmentation-burner" ));
setprop("/sim/multiplay/generic/float[10]", getprop("/fdm/jsbsim/propulsion/engine[0]/alt/nozzle-pos-norm" ));
setprop("/sim/multiplay/generic/float[11]", getprop("/fdm/jsbsim/propulsion/engine[1]/alt/nozzle-pos-norm" ));
#setprop("/sim/multiplay/generic/int[8]", getprop("/engines/engine[0]/afterburner" ));
#setprop("/sim/multiplay/generic/int[9]", getprop("/engines/engine[1]/afterburner" ));

    # ejection seat
    if (getprop("payload/armament/es/flags/deploy-id-11") != nil) {
        setprop("f14/force", 7-5*getprop("payload/armament/es/flags/deploy-id-11"));
    } else {
        setprop("f14/force", 7);
    }
}



#----------------------------------------------------------------------------
# FCS update
#----------------------------------------------------------------------------
var wow = 1;
setprop("/fdm/jsbsim/fcs/roll-trim-actuator",0) ;
setprop("/controls/flight/SAS-roll",0);

var ownship_pos = geo.Coord.new();
var ownshipLat = props.globals.getNode("position/latitude-deg");
var ownshipLon = props.globals.getNode("position/longitude-deg");
var ownshipAlt = props.globals.getNode("position/altitude-ft");

var F14_exec = {
	new : func (_ident){
#        print("F14_exec: init");
        var obj = { parents: [F14_exec]};
#        input = {
#               name : "property",
#        };
#
#        foreach (var name; keys(input)) {
#            emesary.GlobalTransmitter.NotifyAll(notifications.FrameNotificationAddProperty.new(_ident, name, input[name]));
#        }

        #
        # recipient that will be registered on the global transmitter and connect this
        # subsystem to allow subsystem notifications to be received
        obj.recipient = emesary.Recipient.new(_ident~".Subsystem");
        obj.recipient.F14_exec = obj;

        input = {
                 FrameRate                 : "/sim/frame-rate",
                 frame_rate                : "/sim/frame-rate",
                 frame_rate_worst          : "/sim/frame-rate-worst",
                 ElapsedSeconds            : "/sim/time/elapsed-sec",
                };

        foreach (var name; keys(input)) {
            emesary.GlobalTransmitter.NotifyAll(notifications.FrameNotificationAddProperty.new(_ident,name, input[name]));
        }

        obj.recipient.Receive = func(notification)
        {
            if (notification.NotificationType == "FrameNotification")
            {
                # this needs to be executed before the radar.
                me.F14_exec.update(notification);
                ownship_pos.set_latlon(ownshipLat.getValue(), ownshipLon.getValue());
                notification.ownship_pos = ownship_pos;
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };

        emesary.GlobalTransmitter.Register(obj.recipient);

		return obj;
	},
    update : func(notification) {
        aircraft.rain.update();

        if(usingJSBSim){
            if ( math.mod(notifications.frameNotification.FrameCount,2)){
                setprop("environment/aircraft-effects/frost-level", getprop("/fdm/jsbsim/systems/ecs/windscreen-frost-amount"));
            }
        }

        #Fectch most commonly used values
        CurrentIAS = getprop ("/velocities/airspeed-kt");
        CurrentMach = getprop ("/velocities/mach");
        CurrentAlt = getprop ("/position/altitude-ft");
        wow = getprop ("/gear/gear[1]/wow") or getprop ("/gear/gear[2]/wow");

        Alpha = getprop ("/orientation/alpha-indicated-deg");
        Throttle = getprop ("/controls/engines/engine/throttle");
        e_trim = getprop ("/controls/flight/elevator-trim");
        deltaT = getprop ("sim/time/delta-sec");

        if (usingJSBSim) {
            currentG = getprop ("accelerations/pilot-gdamped");
            # use interpolate to make it take 1.2seconds to affect the demand

            var dmd_afcs_roll = getprop("/controls/flight/SAS-roll");
            var roll_mode = getprop("autopilot/locks/heading");

            if (roll_mode != "dg-heading-hold" and roll_mode != "wing-leveler" and roll_mode != "true-heading-hold" )
              setprop("fdm/jsbsim/fcs/roll-trim-sas-cmd-norm",0);
            else {
                var roll = getprop("orientation/roll-deg");
                if (dmd_afcs_roll < -0.11) dmd_afcs_roll = -0.11;
                else if (dmd_afcs_roll > 0.11) dmd_afcs_roll = 0.11;

                #print("AFCS ",roll," DMD ",dmd_afcs_roll, " SAS=", getprop("/controls/flight/SAS-roll"), " cur=",getprop("fdm/jsbsim/fcs/roll-trim-cmd-norm"));
                if (roll < -45 and dmd_afcs_roll < 0) dms_afcs_roll = 0;
                if (roll > 45 and dmd_afcs_roll > 0) dms_afcs_roll = 0;

                interpolate("fdm/jsbsim/fcs/roll-trim-sas-cmd-norm",dmd_afcs_roll,0.1);
            }
        } else {
            currentG = getprop ("accelerations/pilot-g");
            setprop("engines/engine[0]/augmentation", getprop("engines/engine[0]/afterburner"));
            setprop("engines/engine[1]/augmentation", getprop("engines/engine[1]/afterburner"));
            setprop("engines/engine[0]/fuel-flow_pph",getprop("engines/engine[0]/fuel-flow-gph")*1.46551724137931);
            setprop("engines/engine[1]/fuel-flow_pph",getprop("engines/engine[1]/fuel-flow-gph")*1.46551724137931);

        }

        #update functions
        f14.computeSweep ();
        f14.computeFlaps ();
        f14.computeSpoilers ();
        f14.computeNozzles ();
        if (!usingJSBSim) {
            f14.computeSAS ();
        }
#        f14.computeAdverse ();
        f14.computeNWS ();
        f14.computeAICS ();
        f14.computeAPC ();
        f14.engineControls();
        f14.timedMotions ();
        f14.electricsFrame();
    },
};

subsystem = F14_exec.new("F14_exec");

position_flash_init();
slat_output.setDoubleValue(0);

#----------------------------------------------------------------------------
# View change: Ctrl-V switchback to view #0 but switch to Rio view when already
# in view #0.
#----------------------------------------------------------------------------

var CurrentView_Num = props.globals.getNode("sim/current-view/view-number");
var rio_view_num = view.indexof("RIO View");

var toggle_cockpit_views = func() {
	cur_v = CurrentView_Num.getValue();
	if (cur_v != 0 ) {
		CurrentView_Num.setValue(0);
	} else {
		CurrentView_Num.setValue(rio_view_num);
	}
}


var quickstart = func() {

    fixAirframe();

#    setprop("controls/electric/engine[0]/generator",1);
#    setprop("controls/electric/engine[1]/generator",1);
#    setprop("controls/electric/engine[0]/bus-tie",1);
#    setprop("controls/electric/engine[1]/bus-tie",1);
#    setprop("systems/electrical/outputs/avionics",1);
#    setprop("controls/electric/inverter-switch",1);
    if(total_lbs < 400)
        set_fuel(5500);

    set_sweep(0);

    setprop("sim/model/f-14b/controls/hud/on-off",1);
    setprop("sim/model/f-14b/controls/VDI/on-off",1);
    setprop("sim/model/f-14b/controls/HSD/on-off",1);

    setprop("sim/model/f-14b/controls/electrics/emerg-flt-hyd-switch",0);
    setprop("sim/model/f-14b/controls/electrics/emerg-gen-guard-lever",0);
	setprop("sim/model/f-14b/controls/electrics/emerg-gen-switch",1);
    setprop("sim/model/f-14b/controls/electrics/l-gen-switch",1);
    setprop("sim/model/f-14b/controls/electrics/master-test-switch",0);
	setprop("sim/model/f-14b/controls/electrics/r-gen-switch",1);

    setprop("sim/model/f-14b/controls/SAS/yaw", 1);
    setprop("sim/model/f-14b/controls/SAS/roll", 1);
    setprop("sim/model/f-14b/controls/SAS/pitch", 1);
#
# Richard's quickstart method
    setprop("controls/engines/engine[0]/cutoff",0);
    setprop("controls/engines/engine[1]/cutoff",0);
    setprop("engines/engine[0]/out-of-fuel",0);
    setprop("engines/engine[1]/out-of-fuel",0);
    setprop("engines/engine[1]/run",1);
    setprop("engines/engine[1]/run",1);

    setprop("/engines/engine[1]/cutoff",0);
    setprop("/engines/engine[0]/cutoff",0);

    setprop("/fdm/jsbsim/propulsion/starter_cmd",1);
    setprop("/fdm/jsbsim/propulsion/cutoff_cmd",1);
    setprop("/fdm/jsbsim/propulsion/set-running",1);
    setprop("/fdm/jsbsim/propulsion/set-running",0);

}
var cold_and_dark = func()
{
    set_sweep(4);
    setprop("sim/model/f-14b/controls/hud/on-off",0);
    setprop("sim/model/f-14b/controls/VDI/on-off",0);
    setprop("sim/model/f-14b/controls/HSD/on-off",0);

    setprop("sim/model/f-14b/controls/electrics/emerg-flt-hyd-switch",0);
    setprop("sim/model/f-14b/controls/electrics/emerg-gen-guard-lever",0);
	setprop("sim/model/f-14b/controls/electrics/emerg-gen-switch",0);
    setprop("sim/model/f-14b/controls/electrics/l-gen-switch",0);
    setprop("sim/model/f-14b/controls/electrics/master-test-switch",0);
	setprop("sim/model/f-14b/controls/electrics/r-gen-switch",0);
	setprop("sim/model/f-14b/controls/electrics/emerg-gen-switch",0);
	setprop("sim/model/f-14b/controls/electrics/r-gen-switch",0);

    setprop("controls/engines/engine[0]/cutoff",1-getprop("controls/engines/engine[0]/cutoff"));
    setprop("controls/engines/engine[1]/cutoff",1-getprop("controls/engines/engine[1]/cutoff"));
    
    setprop("controls/lighting/aux-inst", 0);
    setprop("controls/lighting/eng-inst", 0);
    setprop("controls/lighting/flt-inst", 0);
    setprop("controls/lighting/instruments-norm",0);
    setprop("controls/lighting/l-console", 0);
    setprop("controls/lighting/panel-norm", 0);
    setprop("controls/lighting/panel-norm",0);
    setprop("controls/lighting/r-console", 0);
    setprop("controls/lighting/stby-inst", 0);
    setprop("controls/lighting/warn-caution", 0);

    setprop("sim/model/f-14b/controls/lighting/hook-bypass-field",0);
    setprop("controls/lighting/instruments-norm",0);
    setprop("controls/lighting/panel-norm",0);
    setprop("sim/model/f-14b/controls/lighting/anti-collision-switch",0);
    setprop("sim/model/f-14b/controls/lighting/position-flash-switch",0);
    setprop("sim/model/f-14b/controls/lighting/position-wing-switch",0);
    setprop("controls/lighting/taxi-light",0);
    setprop("sim/model/f-14b/controls/SAS/yaw", 0);
    setprop("sim/model/f-14b/controls/SAS/roll", 0);
    setprop("sim/model/f-14b/controls/SAS/pitch", 0);


    setprop("/controls/gear/brake-parking",1);
    setprop("sim/model/f-14b/controls/HUD/brightness",0);
    setprop("sim/model/f-14b/controls/HUD/on-off",0);
    setprop("sim/model/f-14b/controls/MPCD/brightness",0);
    setprop("sim/model/f-14b/controls/MPCD/on-off",0);
    setprop("sim/model/f-14b/controls/TEWS/brightness",0);
    setprop("sim/model/f-14b/controls/VSD/on-off",0);
    setprop("sim/model/f-14b/controls/VSD/brightness",0);

    setprop("sim/model/f-14b/controls/electrics/emerg-flt-hyd-switch",0);
    setprop("sim/model/f-14b/controls/electrics/emerg-gen-guard-lever",0);
    setprop("sim/model/f-14b/controls/electrics/l-gen-switch",0);
    setprop("sim/model/f-14b/controls/electrics/master-test-switch",0);

    setprop("sim/model/f-14b/lights/master-test-lights", 0);
    setprop("sim/model/f-14b/lights/radio2-brightness",0);

    setprop("sim/model/f-14b/controls/windshield-heat",0);

    setprop("sim/model/f-14b/controls/fuel/dump-switch",0);
    setprop("sim/model/f-14b/controls/fuel/refuel-probe-switch",0);
    refuel_probe_switch_down();
    refuel_probe_switch_down();

    setprop("sim/model/f-14b/controls/engines/l-eec-switch",0);
    setprop("sim/model/f-14b/controls/engines/r-eec-switch",0);
    setprop("sim/model/f-14b/controls/electrics/emerg-gen-switch",0);
    setprop("sim/model/f-14b/controls/engs/l-eng-master-guard",1);
    setprop("sim/model/f-14b/controls/engs/r-eng-master-guard",1);
    setprop("sim/model/f-14b/controls/electrics/jfs-starter",0);

    setprop("fdm/jsbsim/systems/electrics/ground-power",0);

}


# set the splash vector for the new canopy rain.

# for tuning the vector; these will be baked in once finished
setprop("/sim/model/f-14b/sfx1",-0.1);
setprop("/sim/model/f-14b/sfx2",4);
setprop("/sim/model/f-14b/sf-x-max",400);
setprop("/sim/model/f-14b/sfy1",0);
setprop("/sim/model/f-14b/sfy2",0.1);
setprop("/sim/model/f-14b/sfz1",1);
setprop("/sim/model/f-14b/sfz2",-0.1);

#var vl_x = 0;
#var vl_y = 0;
#var vl_z = 0;
#var vsplash_precision = 0.001;
var splash_vec_loop = func
{
    var v_x = 0;
    var v_y = 0;
    var v_z = 0;
    var v_x_max = getprop("/sim/model/f-14b/sf-x-max");
    if(!usingJSBSim)
    {
        v_x = getprop("/velocities/uBody-fps");
        v_y = getprop("/velocities/vBody-fps");
        v_z = getprop("/velocities/wBody-fps");
    }
    else
    {
        v_x = getprop("/fdm/jsbsim/velocities/u-aero-fps");
        v_y = getprop("/fdm/jsbsim/velocities/v-aero-fps");
        v_z = getprop("/fdm/jsbsim/velocities/w-aero-fps");
    }
 
    if (v_x > v_x_max) 
        v_x = v_x_max;
 
    if (v_x > 1)
        v_x = math.sqrt(v_x/v_x_max);

    var splash_x = getprop("/sim/model/f-14b/sfx1") - getprop("/sim/model/f-14b/sfx2") * v_x;
    var splash_y = getprop("/sim/model/f-14b/sfy1") - getprop("/sim/model/f-14b/sfy2") * v_y;
    var splash_z = getprop("/sim/model/f-14b/sfz1") - getprop("/sim/model/f-14b/sfz2") * v_z;

    setprop("/environment/aircraft-effects/splash-vector-x", splash_x);
    setprop("/environment/aircraft-effects/splash-vector-y", splash_y);
    setprop("/environment/aircraft-effects/splash-vector-z", splash_z);

    settimer( func {splash_vec_loop() },0.5);
}

splash_vec_loop();

var resetView = func () {
  setprop("sim/current-view/field-of-view", getprop("sim/current-view/config/default-field-of-view-deg"));
  setprop("sim/current-view/heading-offset-deg", getprop("sim/current-view/config/heading-offset-deg"));
  setprop("sim/current-view/pitch-offset-deg", getprop("sim/current-view/config/pitch-offset-deg"));
  setprop("sim/current-view/roll-offset-deg", getprop("sim/current-view/config/roll-offset-deg"));
}

dynamic_view.register(func {
              me.default_plane(); 
   });

var fixAirframe = func {
    if (!getprop("payload/armament/msg") or getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        setprop ("fdm/jsbsim/systems/flyt/damage-reset", 1);
        repairMe();
    } else {
        screen.log.write("Please land or relocate to an airport before repair");
    }
}

setlistener("sim/model/f-14b/controls/damage-enabled", func(v){
    if (v.getValue())
      setprop("fdm/jsbsim/systems/flyt/damage-enabled",1);
    else
      setprop("fdm/jsbsim/systems/flyt/damage-enabled",0);
});

var esRIO = nil;

var eject = func{
  if (getprop("f14/done")==1) {# or !getprop("controls/seat/ejection-safety-lever")
      return;
  }
  setprop("f14/done",1);
  var es = armament.AIM.new(11, "es","Pilot", nil ,nil);
  esRIO = armament.AIM.new(12, "es","Rio", nil ,nil);
  #setprop("fdm/jsbsim/fcs/canopy/hinges/serviceable",0);
  es.releaseAtNothing();
  var n = props.globals.getNode("ai/models", 1);
  for (i = 0; 1==1; i += 1) {
    if (n.getChild("es", i, 0) == nil) {
      break;
    }
  }
    
  # set the view to follow pilot:
  setprop("sim/view[115]/config/eye-lat-deg-path","/ai/models/es["~(i-2)~"]/position/latitude-deg");
  setprop("sim/view[115]/config/eye-lon-deg-path","/ai/models/es["~(i-2)~"]/position/longitude-deg");
  setprop("sim/view[115]/config/eye-alt-ft-path","/ai/models/es["~(i-2)~"]/position/altitude-ft");
  setprop("sim/view[115]/config/target-lat-deg-path","/ai/models/es["~(i-2)~"]/position/latitude-deg");
  setprop("sim/view[115]/config/target-lon-deg-path","/ai/models/es["~(i-2)~"]/position/longitude-deg");
  setprop("sim/view[115]/config/target-alt-ft-path","/ai/models/es["~(i-2)~"]/position/altitude-ft");
  setprop("sim/view[115]/enabled", 1);
  if(view["setViewByIndex"] == nil)
    setprop("sim/current-view/view-number", 13);# add 2 since walker uses 2
  else
    view.setViewByIndex(115);

  settimer(eject2, 0.20)
}

var eject2 = func {
  esRIO.releaseAtNothing();
  
  #setprop("sim/view[0]/enabled",0); #disabled since it might get saved so user gets no pilotview in next aircraft he flies in.
  settimer(func {f14.exp();},3.5);
}

## Following code adapted from script shared by Warty at https://forum.flightgear.org/viewtopic.php?f=10&t=28665
## (C) pinto aka Justin Nicholson - 2016
## GPL v2

var updateRater = 2;

var ignoreLoop = func () {
  if (getprop("sim/multiplay/txhost") != "mpserver.opredflag.com") {
    var trolls = [
                  getprop("ignore-list/troll-1"),
                  getprop("ignore-list/troll-2"),
                  getprop("ignore-list/troll-3"),
                  getprop("ignore-list/troll-4"),
                  getprop("ignore-list/troll-5"),
                  getprop("ignore-list/troll-6"),
                  getprop("ignore-list/troll-7"),
                  getprop("ignore-list/troll-8"),
                  getprop("ignore-list/troll-9")];
    var listMP = props.globals.getNode("ai/models/").getChildren("multiplayer");
    foreach (m; listMP) {
      var thisCallsign = m.getValue("callsign");
      foreach(csToIgnore; trolls){
        if(thisCallsign == csToIgnore){
          setInvisible(m);
        }
      }
    }
  }
  settimer( func { ignoreLoop(); }, updateRater);
}

var setInvisible = func (m) {
  var currentlyInvisible = m.getValue("controls/invisible");
  if(!currentlyInvisible){
    var thisCallsign = m.getValue("callsign");
    if (thisCallsign != "" and thisCallsign != nil) {
      multiplayer.dialog.toggle_ignore(thisCallsign);
      m.setValue("controls/invisible",1);
      screen.log.write("Automatically ignoring " ~ thisCallsign ~ ".");
    }
  }
}

settimer( func { ignoreLoop(); }, 5);


var code_ct = func () {
  #ANTIC
  if (getprop("payload/armament/msg")) {
      setprop("sim/rendering/redout/enabled", TRUE);
      #call(func{fgcommand('dialog-close', multiplayer.dialog.dialog.prop())},nil,var err= []);# props.Node.new({"dialog-name": "location-in-air"}));
      call(func{multiplayer.dialog.del();},nil,var err= []);
      if (!getprop("fdm/jsbsim/gear/unit[0]/WOW")) {
        call(func{fgcommand('dialog-close', props.Node.new({"dialog-name": "WeightAndFuel"}))},nil,var err2 = []);
        call(func{fgcommand('dialog-close', props.Node.new({"dialog-name": "system-failures"}))},nil,var err2 = []);
        call(func{fgcommand('dialog-close', props.Node.new({"dialog-name": "instrument-failures"}))},nil,var err2 = []);
      }      
      setprop("sim/freeze/fuel",0);
      setprop("/sim/speed-up", 1);
      setprop("/gui/map/draw-traffic", 0);
      setprop("/sim/gui/dialogs/map-canvas/draw-TFC", 0);
      #setprop("/sim/rendering/als-filters/use-filtering", 1);
      call(func{var interfaceController = fg1000.GenericInterfaceController.getOrCreateInstance();
      interfaceController.stop();},nil,var err2=[]);
  }  
}
code_ctTimer = maketimer(1, code_ct);
code_ctTimer.simulatedTime = 1;

code_ctTimer.start();
