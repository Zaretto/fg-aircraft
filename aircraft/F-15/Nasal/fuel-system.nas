# F-15 Fuel system 
# ---------------------------
# The main fuel computations are performed in JSBSim; these are support routines
# ---------------------------
# Richard Harrison (rjh@zaretto.com) Feb  2015 - based on F-14B version by Alexis Bory

fuel.update = func{}; # disable the generic fuel updater

# Initialize internal values
# --------------------------
var fuel_system_initialized = 0; # Used to avoid spawning a bunch of new tanks each time we reset FG.
var PPG = nil;
var LBS_HOUR2GALS_SEC    = nil;
var LBS_HOUR2GALS_PERIOD = nil;
var max_flow18000        = nil;
var max_flow36000        = nil;
var max_flow45000        = nil;
var max_flow85000        = nil;
var max_refuel_flow      = nil;

var TankRightSide = 1;
var TankLeftSide = 0;
var TankBothSide = -1;

var ai_enabled = nil;
var refuelingN = nil;
var refuel_serviceable = nil;
var aimodelsN = nil;
var types = {};
var qty_refuelled_gals = nil;

var Tank1       = nil;
var Left_Feed      = nil;
var WingInternal_L          = nil;
var Right_Feed     = nil;
var WingInternal_R         = nil;
var WingExternal_L          = nil;
var WingExternal_R         = nil;
var Centre_External      = nil;
var Left_Proportioner  = nil;
var Right_Proportioner = nil;

var neg_g = nil;


var total_gals = 0;
var total_lbs  = 0;
var total_fuel_l = 0;
var total_fuel_r = 0;
var qty_sel_switch = nil;
var g_fuel_total   = props.globals.getNode("sim/model/f15/instrumentation/fuel-gauges/total", 1);
var g_fuel_WL      = props.globals.getNode("sim/model/f15/instrumentation/fuel-gauges/left-wing-display", 1);
var g_fuel_WR      = props.globals.getNode("sim/model/f15/instrumentation/fuel-gauges/right-wing-display", 1);
var g_fus_feed_L   = props.globals.getNode("sim/model/f15/instrumentation/fuel-gauges/left-fus-feed-display", 1);
var g_fus_feed_R   = props.globals.getNode("sim/model/f15/instrumentation/fuel-gauges/right-fus-feed-display", 1);
var Qty_Sel_Switch = props.globals.getNode("sim/model/f15/controls/fuel/qty-sel-switch");
var fwd = nil;
var aft = nil;
var Lg  = nil;
var Rg  = nil;
var Lw  = nil;
var Rw  = nil;
var Le  = nil;
var Re  = nil;

var fuel_time = 0;
var fuel_dt = 0;
var fuel_last_time = 0.0;

var total = 0;
var refuel_rate_gpm = 450; # max refuel rate in gallons per minute at 50 psi pressure


var left_shut_off = 0; # TODO: Engine fuel shutoff emergency handles
var right_shut_off = 0;


var LeftEngine		= props.globals.getNode("engines").getChild("engine", 0);
var RightEngine	    = props.globals.getNode("engines").getChild("engine", 1);
var LeftFuel		= LeftEngine.getNode("fuel-consumed-lbs", 1);
var RightFuel		= RightEngine.getNode("fuel-consumed-lbs", 1);

    var JSBLeftEngine		= props.globals.getNode("/fdm/jsbsim/propulsion/").getChild("engine", 0);
    var JSBRightEngine	    = props.globals.getNode("/fdm/jsbsim/propulsion/").getChild("engine", 1);
    LeftFuel		= JSBLeftEngine.getNode("fuel-used-lbs", 1);
    RightFuel		= JSBRightEngine.getNode("fuel-used-lbs", 1);

var LeftEngineRunning		= LeftEngine.getNode("running", 1);
var RightEngineRunning		= RightEngine.getNode("running", 1);
LeftEngine.getNode("out-of-fuel", 1);
RightEngine.getNode("out-of-fuel", 1);

var RprobeSw = props.globals.getNode("sim/model/f15/controls/fuel/refuel-probe-switch");
var TotalFuelLbs  = props.globals.getNode("consumables/fuel/total-fuel-lbs", 1);
var TotalFuelGals = props.globals.getNode("consumables/fuel/total-fuel-gals", 1);


var init_fuel_system = func {

#	print("Initializing f15 fuel system");


	if ( ! fuel_system_initialized ) {
		build_new_tanks();
		build_new_proportioners();
		fuel_system_initialized = 1;
	}

	#valves ("name",property, intitial status)

	neg_g = Neg_g.new(0);

	setlistener("sim/ai/enabled", func(n) { ai_enabled = n.getBoolValue() }, 1);
	refuelingN = props.globals.initNode("/systems/refuel/contact", 0, "BOOL");
	aimodelsN = props.globals.getNode("ai/models", 1);
	foreach (var t; props.globals.getNode("systems/refuel", 1).getChildren("type"))
		types[t.getValue()] = 1;
	setlistener("systems/refuel/serviceable", func(n) refuel_serviceable = n.getBoolValue(), 1);

	PPG = Tank1.ppg.getValue();
	LBS_HOUR2GALS_SEC = (1 / PPG) / 3600;

}


var build_new_tanks = func {
	#tanks ("name", number, initial connection status)
    # the order of these is significant for the set_fuel operation
	Tank1     = Tank.new("Tank 1", 2, 1, TankBothSide);
	WingInternal_L   = Tank.new("Internal Wing L", 3, 1, TankLeftSide);
	WingInternal_R   = Tank.new("Internal Wing R", 4, 1, TankRightSide);
	Left_Feed      = Tank.new("L Feed", 0, 1, TankLeftSide); 
	Right_Feed      = Tank.new("R Feed", 1, 1, TankRightSide);
	WingExternal_L   = Tank.newExternal("External Wing L", 5, 1, TankLeftSide);
	WingExternal_R   = Tank.newExternal("External Wing R", 6, 1, TankRightSide);
	Centre_External  = Tank.newExternal("Centre External", 7, 1, TankBothSide); 
}

var build_new_proportioners = func {
	#proportioners ("name", number, initial connection status, operational status)
	Left_Proportioner	= Prop.new("L feed line", 8, 1, 1); # 10 lbs
	Right_Proportioner	= Prop.new("R feed line", 9, 1, 1); # 10 lbs
}


var fuel_update = func {

	fuel_time = props.globals.getNode("/sim/time/elapsed-sec", 1).getValue();
	fuel_dt = fuel_time - fuel_last_time;
	fuel_last_time = fuel_time;
	neg_g.update();
	calc_levels();

	if ( getprop("/sim/freeze/fuel") or getprop("sim/replay/time") > 0 ) { return }

	LBS_HOUR2GALS_PERIOD = LBS_HOUR2GALS_SEC * fuel_dt;
	max_flow85000 = 85000 * LBS_HOUR2GALS_PERIOD; 
	max_flow45000 = 45000 * LBS_HOUR2GALS_PERIOD;
	max_flow36000 = 36000 * LBS_HOUR2GALS_PERIOD;
	max_flow18000 = 18000 * LBS_HOUR2GALS_PERIOD; 
	refuel_rate_gpm = 450; # max rate in gallons per minute at 50 psi pressure
}





var calc_levels = func() {
	# Calculate total fuel in tanks (not including small amount in proportioners) for use
	# in the various gauges displays.
	total_gals = total_lbs = 0;
	foreach (var t; Tank.list) {
		total_gals = total_gals + t.get_level();
		total_lbs = total_lbs + t.get_level_lbs();
	}
	fwd = Tank1.get_level_lbs();
	Lg  = Left_Feed.get_level_lbs() + WingInternal_L.get_level_lbs();
	Rg  = Right_Feed.get_level_lbs() + WingInternal_R.get_level_lbs();
	Lw  = WingExternal_L.get_level_lbs();
	Rw  = WingExternal_R.get_level_lbs();
	Le  = Centre_External.get_level_lbs();
	g_fuel_total.setDoubleValue( total_lbs );
	TotalFuelLbs.setValue(total_lbs);

    total_fuel_l = Lg + Lw;
    total_fuel_r = Rg + Rw;

    var sel_display = getprop("sim/model/f15/controls/fuel/display-selector");

# FUEL QUANTITY SELECTOR KNOB
    if (sel_display == 1)
    {
#FEED The fuel remaining in the respective engine feed tanks will be displayed.
        setprop("sim/model/f15/instrumentation/fuel-gauges/left-display", Left_Feed.get_level_lbs());
        setprop("sim/model/f15/instrumentation/fuel-gauges/right-display",Right_Feed.get_level_lbs()); 
        setprop("sim/model/f15/instrumentation/fuel-gauges/total-display",getprop("consumables/fuel/total-fuel-lbs"));
    }
    else if (sel_display == 2)
    {
#INT WING The fuel remaining in the respective internal wing tanks is displayed.
        setprop("sim/model/f15/instrumentation/fuel-gauges/left-display", WingInternal_L.get_level_lbs());
        setprop("sim/model/f15/instrumentation/fuel-gauges/right-display",WingInternal_R.get_level_lbs()); 
        setprop("sim/model/f15/instrumentation/fuel-gauges/total-display",getprop("consumables/fuel/total-fuel-lbs"));
    }
    else if (sel_display == 3)
    {
#TANK 1 The fuel remaining in tank 1 is displayed in the LEFT counter (RIGHT indicates zero).
        setprop("sim/model/f15/instrumentation/fuel-gauges/left-display", Tank1.get_level_lbs());
        setprop("sim/model/f15/instrumentation/fuel-gauges/right-display",0); 
        setprop("sim/model/f15/instrumentation/fuel-gauges/total-display",getprop("consumables/fuel/total-fuel-lbs"));
    }
    else if (sel_display == 4)
    {
#EXT WING The fuel remaining in the respective external wing tanks is displayed.
        setprop("sim/model/f15/instrumentation/fuel-gauges/left-display", WingExternal_L.get_level_lbs());
        setprop("sim/model/f15/instrumentation/fuel-gauges/right-display",WingExternal_R.get_level_lbs()); 
        setprop("sim/model/f15/instrumentation/fuel-gauges/total-display",getprop("consumables/fuel/total-fuel-lbs"));
    }
    else if (sel_display == 5)
    {
#EXT CTR The fuel remaining in the external centerline tank is displayed in the LEFT counter (RIGHT indicates zero).
        setprop("sim/model/f15/instrumentation/fuel-gauges/left-display", Centre_External.get_level_lbs());
        setprop("sim/model/f15/instrumentation/fuel-gauges/right-display",0); 
        setprop("sim/model/f15/instrumentation/fuel-gauges/total-display",getprop("consumables/fuel/total-fuel-lbs"));
    }
    else if (sel_display == 6)
    {
#CONF TANK The fuel remaining in the respective conformal tank is displayed.
        setprop("sim/model/f15/instrumentation/fuel-gauges/left-display",0); 
        setprop("sim/model/f15/instrumentation/fuel-gauges/right-display",0); 
        setprop("sim/model/f15/instrumentation/fuel-gauges/total-display",getprop("consumables/fuel/total-fuel-lbs"));
    }
    else
    {
        setprop("sim/model/f15/instrumentation/fuel-gauges/left-display", 6000);
        setprop("sim/model/f15/instrumentation/fuel-gauges/right-display",600); 
        setprop("sim/model/f15/instrumentation/fuel-gauges/total-display",6000);
    }
}


# Controls
# --------

setlistener("sim/model/f15/controls/fuel/dump-switch", func(v) {
    if (v != nil)
    {
        if (v.getValue())
        {
            print("Start  dump");
            setprop("sim/multiplay/generic/int[0]", 1);
            setprop("fdm/jsbsim/propulsion/fuel_dump",1);
        }
        else
        { 
            print("Stop dump");
            setprop("sim/multiplay/generic/int[0]", 0);
            setprop("fdm/jsbsim/propulsion/fuel_dump",0);
        } 
    }
    else 
    { 
        print("no value");
        setprop("sim/multiplay/generic/int[0]", 0);
        setprop("fdm/jsbsim/propulsion/fuel_dump",0);
    }
});


var r_probe = aircraft.door.new("sim/model/f15/refuel/", 1);
var RprobePos        = props.globals.getNode("sim/model/f15/refuel/position-norm", 1);
var RprobePosGeneric = props.globals.getNode("sim/multiplay/generic/float[6]",1);
RprobePosGeneric.alias(RprobePos);

setlistener("sim/model/f15/controls/fuel/refuel-probe-switch", func {
    var v = getprop("sim/model/f15/controls/fuel/refuel-probe-switch");
    if (v != nil)
    {
        if (v == 0)
        {
            r_probe.close();
        }
        else
            r_probe.open();
    }
});

var refuel_probe_switch_up = func() {
	var sw = RprobeSw.getValue();
	if ( sw < 2 ) {
		sw += 1;
		RprobeSw.setValue(sw);
	}
	r_probe.open();
}
var refuel_probe_switch_down = func() {
	var sw = RprobeSw.getValue();
	if ( sw > 0 ) {
		sw -= 1;
		RprobeSw.setValue(sw);
	}
	if ( sw == 0 ) { r_probe.close(); }
}
var refuel_probe_switch_cycle = func() {
	var sw = RprobeSw.getValue();
	if ( sw < 2 ) { refuel_probe_switch_up() }
	if ( sw == 2 ) {
		sw = 0;
		RprobeSw.setValue(sw);
		r_probe.close();	
	}
}


# Internaly save levels at reinit. This is a workaround:
# reinit shouldn't try to reload the levels from the -set file.
var level_list = [];

var internal_save_fuel = func() {
#	print("Saving f15 fuel levels");
	level_list = [];
	foreach (var t; Tank.list) {
    print(" -- ",t.name," = ",t.level_lbs.getValue());
		append(level_list, t.get_level());
	}
}
var internal_restore_fuel = func() {
#	print("Restoring f15 fuel levels");
	var i = 0;
	foreach (var t; Tank.list) {
#    print(" -- ",t.name," = ",t.level_lbs.getValue());
		t.set_level(level_list[i]);
		i += 1;
	}
}


# Classes
# -------

# Tank
Tank = {
	new : func (name, number, connect, side) {
		var obj = { parents : [Tank]};
        obj.external = 0;
		obj.prop = props.globals.getNode("consumables/fuel").getChild ("tank", number , 1);
#		obj.prop = props.globals.getNode("fdm/jsbsim/propulsion/tank").getChild ("tank", number , 1);
#		obj.name = obj.prop.getNode("name", 1);
        obj.side = side; # 1 is right; 0 is left.
		obj.name = name;
		obj.prop.getChild("name", 0, 1).setValue(name);
		obj.capacity = obj.prop.getNode("capacity-gal_us", 1);
		obj.ppg = obj.prop.getNode("density-ppg", 1);
		obj.level_gal_us = obj.prop.getNode("level-gal_us", 1);
		obj.level_gal_us.setValue(0);
		obj.level_lbs = obj.prop.getNode("level-lbs", 1);
		obj.level_lbs.setValue(0);
		obj.transfering = obj.prop.getNode("transfering", 1);
		obj.transfering.setBoolValue(0);
		obj.selected = obj.prop.getNode("selected", 1);
		obj.selected.setBoolValue(connect);
		obj.ppg.setDoubleValue(6.3);
		append(Tank.list, obj);
#		print("Tank.new[",number,"], ",obj.name," lbs=", obj.level_lbs.getValue());
		return obj;
	},
	newExternal : func (name, number, connect, side) {
		var obj = { parents : [Tank]};
        obj.external = 1;
		obj.prop = props.globals.getNode("consumables/fuel").getChild ("tank", number , 1);
#		obj.prop = props.globals.getNode("fdm/jsbsim/propulsion/tank").getChild ("tank", number , 1);
#		obj.name = obj.prop.getNode("name", 1);
        obj.side = side; # 1 is right; 0 is left.
		obj.name = name;
		obj.prop.getChild("name", 0, 1).setValue(name);
		obj.capacity = obj.prop.getNode("capacity-gal_us", 1);
		obj.ppg = obj.prop.getNode("density-ppg", 1);
		obj.level_gal_us = obj.prop.getNode("level-gal_us", 1);
		obj.level_gal_us.setValue(0);
		obj.level_lbs = obj.prop.getNode("level-lbs", 1);
		obj.level_lbs.setValue(0);
		obj.transfering = obj.prop.getNode("transfering", 1);
		obj.transfering.setBoolValue(0);
		obj.selected = obj.prop.getNode("selected", 1);
		obj.selected.setBoolValue(connect);
		obj.ppg.setDoubleValue(6.3);

		append(Tank.list, obj);
#		print("Tank.new[",number,"], ",obj.name," lbs=", obj.level_lbs.getValue());
		return obj;
	},
    #
    # the side of this tank (or the engine that this tank feeds) (0 = left, 1 = right) 
    get_side : func {
        return me.side;
    },
    is_external : func {
        return me.external;
    },
    is_side : func(s) {
        return me.side == s;
    },
    is_fitted : func {
        if (!me.external) return true;
        if (me.prop.getNode("selected").getValue())
            return true;
        return false;
    },

	get_capacity : func {
		return me.capacity.getValue(); 
	},
	get_capacity_lbs : func {
		return me.capacity.getValue() * me.ppg.getValue(); 
	},
	get_level : func {
		return me.level_gal_us.getValue();
	},
	get_level_lbs : func {
		return me.level_lbs.getValue();
	},
	set_level : func (gals_us){
		if(gals_us < 0) gals_us = 0;
		me.level_gal_us.setDoubleValue(gals_us);
		me.level_lbs.setDoubleValue(gals_us * me.ppg.getValue());
	},
	set_level_lbs : func (lbs){
		if(lbs < 0) lbs = 0;
		me.level_gal_us.setDoubleValue(lbs / me.ppg.getValue());
		me.level_lbs.setDoubleValue(lbs);
	},
	set_transfering : func (transfering){
		me.transfering.setBoolValue(transfering);
	},
	set_selected : func (sel){
		me.selected.setBoolValue(sel);
	},
	get_amount : func (fuel_dt, ullage) {
		var amount = (flowrate_lbs_hr / (me.ppg.getValue() * 60 * 60)) * fuel_dt;
		if(amount > me.level_gal_us.getValue()) {
			amount = me.level_gal_us.getValue();
		} 
		if(amount > ullage) {
			amount = ullage;
		} 
		var flowrate_lbs = ((amount/fuel_dt) * 60 * 60) * me.ppg.getValue();
		return amount
	},
	get_ullage : func () {
		return me.get_capacity() - me.get_level()
	},
	get_ullage_lbs : func () {
		return (me.get_capacity() - me.get_level()) * me.ppg.getValue();
	},
	get_name : func () {
		return me.name;
	},
	set_transfer_tank : func (fuel_dt, tank) {
		foreach (var t; Tank.list) {
			if(t.get_name() == tank)  {
				transfer = me.get_amount(fuel_dt, t.get_ullage());
				me.set_level(me.get_level() - transfer);
				t.set_level(t.get_level() + transfer);
			} 
		}
	},

    adjust_level_by_delta : func(side, delta)
    {
        var t = me;
        print("Processing ",t.name," is fitted ",t.is_fitted()," delta ",delta);
        if (t.is_fitted()) # true for internal; only true when external connected
        {
            if (t.is_side(side))
            {
                if (delta < 0)
                {
                    var tdelta = t.get_level_lbs() + delta;
                    if (tdelta < 0)
                    {
                        delta = delta + t.get_level_lbs();
                        print("Tank ",t.name," empty : new_delta ", delta);
                        t.set_level_lbs(0);
                    }
                    else
                    {
                        if (tdelta > t.get_capacity_lbs()) tdelta = t.get_capacity_lbs();
                        t.set_level_lbs(tdelta);
                        print("Tank(finished) ",t.name," set to  ", tdelta, " now ", t.get_level_lbs());
                        delta = delta - tdelta;
                    }
                }
                else
                {
                    var tdelta = t.get_ullage_lbs();
                    if (tdelta > delta) tdelta = delta;
#            if (tdelta > t.get_capacity_lbs()) tdelta = t.get_capacity_lbs();

                    delta = delta - tdelta;
                    t.set_level_lbs(t.get_level_lbs() + tdelta);
                    print("Tank ",t.name," increase by ", tdelta, " now ", t.get_level_lbs());
                }
            }
            else
                print("-- not adjusting ",t.name," not matched on side ",side);
        }
        return delta;
    },
	list : [],
};


# Proportioner
Prop = {
	new : func (name, number, connect, running) {
		var obj = { parents : [Prop]};
		obj.prop = props.globals.getNode("consumables/fuel").getChild ("tank", number , 1);
		obj.name = obj.prop.getNode("name", 1);
		obj.prop.getChild("name", 0, 1).setValue(name);
		obj.capacity = obj.prop.getNode("capacity-gal_us", 1);
		obj.ppg = obj.prop.getNode("density-ppg", 1);
		obj.level_gal_us = obj.prop.getNode("level-gal_us", 1);
		obj.level_lbs = obj.prop.getNode("level-lbs", 1);
		obj.dumprate = obj.prop.getNode("dump-rate-lbs-hr", 1);
		obj.running = obj.prop.getNode("running", 1);
		obj.running.setBoolValue(running);
		obj.prop.getChild("selected", 0, 1).setBoolValue(connect);
		obj.prop.getChild("dump-rate-lbs-hr", 0, 1).setDoubleValue(0);
		obj.ppg.setDoubleValue(6.3);
		append(Prop.list, obj);
#print("Name ",name,running,obj.level_lbs, obj.get_capacity());
		return obj;
	},
	
	set_level : func (gals_us){
		if(gals_us < 0) gals_us = 0;
		me.level_gal_us.setDoubleValue(gals_us);
		me.level_lbs.setDoubleValue(gals_us * me.ppg.getValue());
	},
	set_dumprate : func (dumprate){
		me.dumprate.setDoubleValue(dumprate);
	},
	get_capacity : func {
		return me.capacity.getValue();
	},
	get_level : func {
		return me.level_gal_us.getValue();
	},
	get_running : func {
		return me.running.getValue();
	},
	get_ullage : func () {
		return me.get_capacity() - me.get_level();
	},
	get_name : func () {
		return me.name.getValue();
	},
	get_lbs : func () {
		return me.level_lbs.getValue();
	},
	update : func (amount_lbs) {
		var ppg = me.ppg.getValue();
		var level = me.get_lbs();
		if (level == nil) {
print("nil level ",obj.name);
return;
        }
		if (amount_lbs == nil) {
print("nil amount_lbs level ",obj.name);
return;
        }
		if (level == 0) {
			return 1;
		} else {
			me.prop.getChild("selected").setBoolValue(1);
			me.running.setBoolValue(1);
			level = level - amount_lbs ;
			if(level <= 0) level = 0;
			me.set_level(level/ppg);
			return 0;
		}
	},
	get_amount : func (fuel_dt, ullage) {
		var amount = (dumprate_lbs_hr / (me.ppg.getValue() * 60 * 60)) * fuel_dt;
		if(amount > me.level_gal_us.getValue()) {
			amount = me.level_gal_us.getValue();
		}
		if(amount > ullage) {
			amount = ullage;
		}
		var dumprate_lbs = ((amount/fuel_dt) * 60 * 60) * me.ppg.getValue();
		return amount
	},
	set_transfer_tank : func (fuel_dt, tank) {
		foreach (var r; Recup.list) {
			if(r.get_name() == tank and me.get_running()) {
				transfer = me.get_amount(fuel_dt, r.get_ullage());
				me.set_level(me.get_level() - transfer);
				r.set_level(r.get_level() + transfer);
			}
		}
	},
	jettisonFuel : func (fuel_dt) {
		var amount = 0;
		if(me.get_level() > 0 and me.get_running()) {
			amount = (dumprate_lbs_hr / (me.ppg.getValue() * 60 * 60)) * fuel_dt;			
			if(amount > max_instant_dumprate_lbs) { # Deal with low frame rates.
				amount = max_instant_dumprate_lbs;
			}
		}
		var dumprate_lbs = ((amount/fuel_dt) * 60) * me.ppg.getValue();
		me.set_dumprate(dumprate_lbs);
		me.set_level(me.get_level() - amount);
	},
	list : [],
};




# Negative G switch

Neg_g = {
	new : func(switch) {
		var obj = { parents : [Neg_g]};
		obj.prop = props.globals.getNode("controls/fuel/neg-g",1);
		obj.switch = switch;
		obj.prop.setBoolValue(switch);
#		obj.acceleration = props.globals.getNode("accelerations/pilot-gdamped", 1);
		obj.check = props.globals.getNode("controls/fuel/recuperator-check", 1);
		return obj;
	},
	update : func() {
#		var acc = me.acceleration.getValue();
		var check = me.check.getValue();
		if (currentG < 0 or check ) {
			me.prop.setBoolValue(1);
		} else {
			me.prop.setBoolValue(0);
		}
	},
	get_neg_g : func() {
		return me.prop.getValue();
	},
};


# Fuel valves

Valve = {
	new : func (name,
				prop,
				initial_pos
				){
		var obj = {parents : [Valve] };
		obj.prop = props.globals.getNode(prop, 1);
		obj.name = name;
		obj.prop.setBoolValue(initial_pos);
		append(Valve.list, obj);
		return obj;
	},
	set : func (valve, pos) {
		foreach (var v; Valve.list) {
			if(v.get_name() == valve) {
				v.prop.setValue(pos);
			}
		}
	},
	get : func (valve) {
		var pos = 0;
		foreach (var v; Valve.list) {
			if(v.get_name() == valve) {
				pos = v.prop.getValue();
			}
		}
		return pos;
	},
	get_name : func () {
		return me.name;
	},
	list : [],
};

var toggle_fuel_freeze = func() {
    setprop("sim/freeze/fuel", 1-getprop("sim/freeze/fuel"));
}

var set_fuel = func(total) {
    var total_delta = (total - getprop("consumables/fuel/total-fuel-lbs"));

    var start = 0; 
    var end = size(Tank.list)-1;
    var inc = 1;
    if (total_delta < 0)
    {
        start = size(Tank.list)-1;
        end = -1;
        inc = -1;
    }

    print("\n set_fuel to ",total," delta ",total_delta);
    if (total_delta > 0)
    {
        total_delta = Tank1.adjust_level_by_delta(TankBothSide, total_delta);
        total_delta = Centre_External.adjust_level_by_delta(TankBothSide, total_delta);
    }

    for (var side=0; side < 2; side = side+1)
    {
        var delta = total_delta / 2;
        print ("\nDoing side ",side, " adjust by ",delta);
#	foreach (var t; Tank.list)
        for (var tank_idx=start; tank_idx != end+1; tank_idx = tank_idx + inc)
        {
            var t = Tank.list[tank_idx];
            #
# only consider non external tanks; or external tanks when connected.
delta = t.adjust_level_by_delta(side, delta);
        }
    }
    total_delta = (total - getprop("consumables/fuel/total-fuel-lbs"));
    if (total_delta < 0)
    {
        total_delta = Tank1.adjust_level_by_delta(TankBothSide, total_delta);
        total_delta = Centre_External.adjust_level_by_delta(TankBothSide, total_delta);
    }
}
