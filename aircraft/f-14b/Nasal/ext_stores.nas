var ExtTanks = props.globals.getNode("sim/model/f-14b/systems/external-loads/external-tanks");
var WeaponsSet = props.globals.getNode("sim/model/f-14b/systems/external-loads/external-load-set");
var WeaponsWeight = props.globals.getNode("sim/model/f-14b/systems/external-loads/weapons-weight", 1);
var PylonsWeight = props.globals.getNode("sim/model/f-14b/systems/external-loads/pylons-weight", 1);

var droptank_node = props.globals.getNode("sim/ai/aircraft/impact/droptank", 1);

var ext_loads_init = func() {
	gui.menuBind("fuel-and-payload", "gui.showDialog(\"external-loads\");");
#    fgcommand("dialog-show", props.Node.new({ "dialog-name" : name }));
    gui.menuEnable("fuel-and-payload", 1);
}


var ext_loads_set = func(s) {
	# Load sets: Clean, FAD, FAD light, FAD heavy, Bombcat
	# Load set defines which weapons are mounted.
	# It also defines which pylons are mounted, a pylon may
	# support several weapons.
	var success = 0;
	if ( s == "Clean" ) {
		success = pylons.clean();
	} elsif ( s == "FAD" ) {
		success = pylons.fad();
	} elsif ( s == "FAD light" ) {
		success = pylons.fad_l();
	} elsif ( s == "FAD heavy" ) {
		success = pylons.fad_h();
	} elsif ( s == "Bombcat" ) {
		success = pylons.bomb();
	} elsif ( s == "Airshow" ) {
		success = pylons.airshow();
	}
	if (success) {
		WeaponsSet.setValue(s);
		f14.arm_selector();# in case masterarm is already on, select and start relevant weapon.
	}
}

# Empties (or loads) corresponding Yasim tanks when de-selecting (or selecting)
# external tanks in the External Loads Menu, or when jettisoning external tanks.
# See fuel-system.nas for Left_External.set_level(), Left_External.set_selected()
# and such.

var toggle_ext_tank_selected = func() {
	var ext_tanks = ! ExtTanks.getBoolValue();
	ExtTanks.setBoolValue( ext_tanks );
	if ( ext_tanks ) {
		pylons.pylon3.loadSet(pylons.pylonSets.fuel26L);
		pylons.pylon8.loadSet(pylons.pylonSets.fuel26R);
	} else {
		pylons.pylon3.loadSet(pylons.pylonSets.empty);
		pylons.pylon8.loadSet(pylons.pylonSets.empty);
	}
}

# Emergency jettison:
# -------------------

var emerg_jettison = func {
	# will jettison all A/G weapons plus fuel tanks, AIM-7 and AIM-54.
	# TODO: require no WOW.
	var weap = pylons.pylon3.getWeapons();
	if (weap != nil and size(weap)) {
		setprop("controls/armament/station[2]/jettison-all", 1);
	}
	weap = pylons.pylon8.getWeapons();
	if (weap != nil and size(weap)) {
		setprop("controls/armament/station[7]/jettison-all", 1);
	}
	pylons.fcs.jettisonAllButHeat();
	ExtTanks.setBoolValue(0);
}

# Air combat maneuver jettison:
# -----------------------------

var acm_jettison = func {
	# will jettison all selected weapon pylons but never sidewinders.
	# TODO: require landing gear lever up.
	# TODO: Figure out how the TANK JETT switches in RIO seat work.
	var list = [];
	for (var i = 0;i<10;i+=1) {
		if (i != 2 and i != 7 and getprop("sim/model/f-14b/systems/external-loads/station["~i~"]/selected")) {
			append(list, i);
		}
	}
	pylons.fcs.jettisonSpecificPylons(list, 0);
}

# Puts the jettisoned tanks models on the ground after impact (THX Vivian Mezza).

var droptanks = func(n) {
	if (wow) { setprop("sim/model/f-14b/controls/armament/tanks-ground-sound", 1) }
	var droptank = droptank_node.getValue();
	var node = props.globals.getNode(n.getValue(), 1);
	geo.put_model("Aircraft/f-14b/Models/Stores/Ext-Tanks/exttank-submodel.xml",
		node.getNode("impact/latitude-deg").getValue(),
		node.getNode("impact/longitude-deg").getValue(),
		node.getNode("impact/elevation-m").getValue()+ 0.4,
		node.getNode("impact/heading-deg").getValue(),
		0,
		0
		);
}

setlistener( "sim/ai/aircraft/impact/droptank", droptanks );

Station = {#not used anymore
	new : func (number, weight_number){
		var obj = {parents : [Station] };
		obj.prop = props.globals.getNode("sim/model/f-14b/systems/external-loads/").getChild ("station", number , 1);
		obj.index = number;
		obj.type = obj.prop.getNode("type", 1);
		obj.display = obj.prop.initNode("display", 0, "INT");

        if(usingJSBSim)
        {
            # the jsb external loads from 0-9 match the indexes used here incremented by 1 as the first element
            # in jsb sim doesn't have [0]
            var propname = sprintf( "fdm/jsbsim/inertia/pointmass-weight-lbs[%d]",number);

    		obj.weight_lb = props.globals.getNode(propname , 1);
        }
        else
        {
		    obj.weight = props.globals.getNode("sim").getChild ("weight", weight_number , 1);
    		obj.weight_lb = obj.weight.getNode("weight-lb");
        }
		obj.bcode = 0;
		obj.selected = obj.prop.getNode("selected");

		append(Station.list, obj);
		return obj;
	},
	set_type : func (t) {
		me.type.setValue(t);
		me.bcode = 0;
		if ( t == "AIM-9" ) {
			me.bcode = 1;
		} elsif ( t == "AIM-7" ) {
			me.bcode = 2;
		} elsif ( t == "AIM-54" ) {
			me.bcode = 3;
		} elsif ( t == "MK-83" ) {
			me.bcode = 4;
		} elsif ( t == "external tank" ) {
			me.bcode = 1;
		}
	},
	get_type : func () {
		return me.type.getValue();	
	},
	set_display : func (n) {
		me.display.setValue(n);
	},
	add_weight_lb : func (t) {
		w = me.weight_lb.getValue();
		me.weight_lb.setValue( w + t );
	},
	set_weight_lb : func (t) {
		me.weight_lb.setValue(t);	
	},
	get_weight_lb : func () {
		return me.weight_lb.getValue();	
	},
	get_selected : func () {
		return me.selected.getBoolValue();	
	},
	set_selected : func (n) {
		me.selected.setBoolValue(n);
	},
	toggle_selected : func () {
		me.selected.setBoolValue( !me.get_selected() );
	},
	list : [],
};