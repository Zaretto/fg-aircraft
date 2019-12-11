var ExtTanks = props.globals.getNode("sim/model/f-14b/systems/external-loads/external-tanks");
var WeaponsSet = props.globals.getNode("sim/model/f-14b/systems/external-loads/external-load-set");
var WeaponsWeight = props.globals.getNode("sim/model/f-14b/systems/external-loads/weapons-weight", 1);
var PylonsWeight = props.globals.getNode("sim/model/f-14b/systems/external-loads/pylons-weight", 1);

var droptank_node = props.globals.getNode("sim/ai/aircraft/impact/droptank", 1);

var ext_loads_dlg = gui.Dialog.new("dialog","Aircraft/f-14b/Dialogs/external-loads.xml");


var ext_loads_init = func() {
	gui.menuBind("fuel-and-payload", "f14.ext_loads_dlg.open()");
    gui.menuEnable("fuel-and-payload", 1);
    return;
}


var ext_loads_set = func(s) {
	# Load sets: Clean, FAD, FAD light, FAD heavy, Bombcat
	# Load set defines which weapons are mounted.
	# It also defines which pylons are mounted, a pylon may
	# support several weapons.
	WeaponsSet.setValue(s);
	if ( s == "Clean" ) {
		pylons.clean(); return;
	} elsif ( s == "FAD" ) {
		pylons.fad(); return; 
	} elsif ( s == "FAD light" ) {
		pylons.fad_l(); return;
	} elsif ( s == "FAD heavy" ) {
		pylons.fad_h(); return;
	} elsif ( s == "Bombcat" ) {
		pylons.bomb(); return; 
	} elsif ( s == "Airshow" ) {
		pylons.airshow(); return; 
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
	var weap = pylons.pylon3.getWeapons();
	if (weap != nil and size(weap)) {
		setprop("controls/armament/station[2]/jettison-all", 1);
	}
	weap = pylons.pylon8.getWeapons();
	if (weap != nil and size(weap)) {
		setprop("controls/armament/station[7]/jettison-all", 1);
	}
	pylons.fcs.jettisonFuelAndAG();
	ExtTanks.setBoolValue(0);
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

Station = {
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