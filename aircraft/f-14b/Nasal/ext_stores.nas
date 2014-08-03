var ExtTanks = props.globals.getNode("sim/model/f-14b/systems/external-loads/external-tanks");
var WeaponsSet = props.globals.getNode("sim/model/f-14b/systems/external-loads/external-load-set");
var WeaponsWeight = props.globals.getNode("sim/model/f-14b/systems/external-loads/weapons-weight", 1);
var PylonsWeight = props.globals.getNode("sim/model/f-14b/systems/external-loads/pylons-weight", 1);
var S0 = nil;
var S1 = nil;
var S2 = nil;
var S3 = nil;
var S4 = nil;
var S5 = nil;
var S6 = nil;
var S7 = nil;
var S8 = nil;
var S9 = nil;
var droptank_node = props.globals.getNode("sim/ai/aircraft/impact/droptank", 1);

var ext_loads_dlg = gui.Dialog.new("dialog","Aircraft/f-14b/Dialogs/external-loads.xml");


var ext_loads_init = func() {
	S0 = Station.new(0, 0);
	S1 = Station.new(1, 0);
	S2 = Station.new(2, 1);
	S3 = Station.new(3, 2);
	S4 = Station.new(4, 3);
	S5 = Station.new(5, 4);
	S6 = Station.new(6, 5);
	S7 = Station.new(7, 6);
	S8 = Station.new(8, 7);
	S9 = Station.new(9, 7);
# Disable the menu item "Equipment > Fuel & Payload" so we use our own gui: "Tomcat Controls > Fuel & Stores".
	gui.menuEnable("fuel-and-payload", false);
	foreach (var S; Station.list) {
		S.set_type(S.get_type()); # initialize bcode.
	}
	update_wpstring();
}


var ext_loads_set = func(s) {
	# Load sets: Clean, FAD, FAD light, FAD heavy, Bombcat
	# Load set defines which weapons are mounted.
	# It also defines which pylons are mounted, a pylon may
	# support several weapons.
	WeaponsSet.setValue(s);
	if ( s == "Clean" ) {
		PylonsWeight.setValue(0);
		WeaponsWeight.setValue(0);
		S0.set_type("-");
		S1.set_type("-");
		S1.set_weight_lb(0);
		S3.set_type("-");
		S3.set_weight_lb(0);
		S4.set_type("-");
		S4.set_weight_lb(0);
		S5.set_type("-");
		S5.set_weight_lb(0);
		S6.set_type("-");
		S6.set_weight_lb(0);
		S8.set_type("-");
		S9.set_type("-");
		S9.set_weight_lb(0);
	} elsif ( s == "FAD" ) {
		PylonsWeight.setValue(53 + 340 + 1200 + 53 + 340);
		WeaponsWeight.setValue(191 + 510 + 1020 + 1020 + 1020 + 1020 + 510 + 191);
		S0.set_type("AIM-9");
		S1.set_type("AIM-7");
		S1.set_weight_lb(53 + 340 + 191 + 510); # AIM-9rail, wing pylon, AIM-9M, AIM-7M 
		S3.set_type("AIM-54");
		S3.set_weight_lb(300 + 1020); # central pylon, AIM-54 
		S4.set_type("AIM-54");
		S4.set_weight_lb(300 + 1020); # central pylon, AIM-54 
		S5.set_type("AIM-54");
		S5.set_weight_lb(300 + 1020); # central pylon, AIM-54 
		S6.set_type("AIM-54");
		S6.set_weight_lb(300 + 1020); # central pylon, AIM-54 
		S8.set_type("AIM-7");
		S9.set_type("AIM-9");
		S9.set_weight_lb(53 + 340 + 191 + 510); # AIM-9rail, wing pylon, AIM-9M, AIM-7M 
	} elsif ( s == "FAD light" ) {
		PylonsWeight.setValue(53 + 340 + 53 + 53 + 53 + 340);
		WeaponsWeight.setValue(191 + 510 + 510 + 510 + 510 + 510 + 510 + 191);
		S0.set_type("AIM-9");
		S1.set_type("AIM-9");
		S1.set_weight_lb(53 + 340 + 191 + 53 + 191); # AIM-9rail, wing pylon, AIM-9M, AIM-9rail, AIM-9M 
		S3.set_type("AIM-7");
		S3.set_weight_lb(510); # AIM-7 
		S4.set_type("AIM-7");
		S4.set_weight_lb(510); # AIM-7 
		S5.set_type("AIM-7");
		S5.set_weight_lb(510); # AIM-7 
		S6.set_type("AIM-7");
		S6.set_weight_lb(510); # AIM-7 
		S8.set_type("AIM-9");
		S9.set_type("AIM-9");
		S9.set_weight_lb(53 + 340 + 191 + 53 + 191); # AIM-9rail, wing pylon, AIM-9M, AIM-9rail, AIM-9M 
	} elsif ( s == "FAD heavy" ) {
		PylonsWeight.setValue(53 + 340 + 90 + 1200 + 53 + 340 + 90);
		WeaponsWeight.setValue(191 + 1020 + 1020 + 1020 + 1020 + 1020 + 1020 + 191);
		S0.set_type("AIM-9");
		S1.set_type("AIM-54");
		S1.set_weight_lb(53 + 340 + 191 + 90 + 1020); # AIM-9rail, wing pylon, AIM-9M, AIM-54launcher, AIM-54 
		S3.set_type("AIM-54");
		S3.set_weight_lb(300 + 1020); # central pylon, AIM-54 
		S4.set_type("AIM-54");
		S4.set_weight_lb(300 + 1020); # central pylon, AIM-54 
		S5.set_type("AIM-54");
		S5.set_weight_lb(300 + 1020); # central pylon, AIM-54 
		S6.set_type("AIM-54");
		S6.set_weight_lb(300 + 1020); # central pylon, AIM-54 
		S8.set_type("AIM-54");
		S9.set_type("AIM-9");
		S9.set_weight_lb(53 + 340 + 191 + 90 + 1020); # AIM-9rail, wing pylon, AIM-9M, AIM-54launcher, AIM-54 
	} elsif ( s == "Bombcat" ) {
		PylonsWeight.setValue(53 + 340 + 90 + 1200 + 53 + 340 + 90);
		WeaponsWeight.setValue(191 + 510 + 1000 + 1000 + 1000 + 1000 + 510 + 191);
		S0.set_type("AIM-9");
		S1.set_type("AIM-7");
		S1.set_weight_lb(53 + 340 + 191 + 510); # AIM-9rail, wing pylon, AIM-9M, AIM-7M 
		S3.set_type("MK-83");
		S3.set_weight_lb(300 + 1000); # central pylon, MK-83 
		S4.set_type("MK-83");
		S4.set_weight_lb(300 + 1000); # central pylon, MK-83 
		S5.set_type("MK-83");
		S5.set_weight_lb(300 + 1000); # central pylon, MK-83 
		S6.set_type("MK-83");
		S6.set_weight_lb(300 + 1000); # central pylon, MK-83 
		S8.set_type("AIM-7");
		S9.set_type("AIM-9");
		S9.set_weight_lb(53 + 340 + 191 + 510); # AIM-9rail, wing pylon, AIM-9M, AIM-7M 
	}
	update_wpstring();
}

# Empties (or loads) corresponding Yasim tanks when de-selecting (or selecting)
# external tanks in the External Loads Menu, or when jettisoning external tanks.
# See fuel-system.nas for Left_External.set_level(), Left_External.set_selected()
# and such.

var toggle_ext_tank_selected = func() {
	var ext_tanks = ! ExtTanks.getBoolValue();
	ExtTanks.setBoolValue( ext_tanks );
	if ( ext_tanks ) {
		S2.set_type("external tank");
		S7.set_type("external tank");
		S2.set_weight_lb(250);            # lbs, empty tank weight.
		S7.set_weight_lb(250);
		Left_External.set_level(267);     # US gals, tank fuel contents.
		Right_External.set_level(267);
		Left_External.set_selected(1);
		Right_External.set_selected(1);
	} else {
		S2.set_type("-");
		S7.set_type("-");
		S2.set_weight_lb(0);
		S7.set_weight_lb(0);
		Left_External.set_level(0);
		Right_External.set_level(0);
		Left_External.set_selected(0);
		Right_External.set_selected(0);
	}
	update_wpstring();
}

var update_wpstring = func {
	var b_wpstring = "";
	foreach (var S; Station.list) {
		# Use 3 bits per weapon pylon (3 free additional wps types).
		# Use 1 bit per fuel tank.
		# Use 3 bits for the load sheme (3 free additional shemes).
		var b = "0";
		var s = S.index;
		if ( s != 2 and s != 7) {
			b = bits.string(S.bcode,3);
		} else {
			b = S.bcode;
		}
		b_wpstring = b_wpstring ~ b;
	}
	var set = WeaponsSet.getValue();
	var b_set = 0;
	if ( set == "FAD" ) {
		b_set = 1;
	} elsif ( set == "FAD light" ) {
		b_set = 2;
	} elsif ( set == "FAD heavy" ) {
		b_set = 3;
	} elsif ( set == "Bombcat" ) {
		b_set = 4;
	}
	b_wpstring = b_wpstring ~ bits.string(b_set,3);
	# Send the bits string as INT over MP.
	var b_stores = bits.value(b_wpstring);
	f14_net.send_wps_state(b_stores);
}

# Emergency jettison:
# -------------------

var emerg_jettison = func {
	setprop("sim/model/f-14b/instrumentation/warnings/master-caution", 1);
	if (S2.get_type() == "external tank") {
		S2.set_type("-");
		S2.set_weight_lb(0);
		setprop("controls/armament/station[2]/jettison-all", 1);
		Left_External.set_level(0);
		Left_External.set_selected(0);
	}
	if (S7.get_type() == "external tank") {
		S7.set_type("-");
		S7.set_weight_lb(0);
		setprop("controls/armament/station[7]/jettison-all", 1);
		Right_External.set_level(0);
		Right_External.set_selected(0);
	}
	ExtTanks.setBoolValue(0);
	update_wpstring();
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

var external_load_loop = func() {
	# Whithout this periodic update the MP AI model wont have its external load
	# uptodate before being manually updated by the pilot *when* in range of
	# the observer.
	var mp_nbr = size(props.globals.getNode("/ai/models").getChildren("multiplayer"));
	if ( mp_nbr != nil ) {
		if ( mp_nbr > 0 ) {
			update_wpstring();
		}
	}
	settimer(external_load_loop, 10);
}

Station = {
	new : func (number, weight_number){
		var obj = {parents : [Station] };
		obj.prop = props.globals.getNode("sim/model/f-14b/systems/external-loads/").getChild ("station", number , 1);
		obj.index = number;
		obj.type = obj.prop.getNode("type", 1);
		obj.display = obj.prop.initNode("display", 0, "INT");
		obj.weight = props.globals.getNode("sim").getChild ("weight", weight_number , 1);
		obj.weight_lb = obj.weight.getNode("weight-lb");
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








