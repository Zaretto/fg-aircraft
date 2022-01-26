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
var ExtTankLeft =  props.globals.getNode("consumables/fuel/tank[8]/selected", 1);
var ExtTankRight =  props.globals.getNode("consumables/fuel/tank[9]/selected", 1);

var update_ext_tanks_selected = func {
	ExtTanks.setBoolValue(ExtTankLeft.getBoolValue() and ExtTankRight.getBoolValue());
}

# set the external tanks
var set_ext_tank_selected = func(v) {
	var ext_tank_left=ExtTankLeft.getBoolValue();
	var ext_tank_right=ExtTankRight.getBoolValue();
	if (!v){
		var ext_tanks = ! ExtTanks.getBoolValue();
		ExtTanks.setBoolValue( ext_tanks );
		if (ext_tanks){
			ext_tank_left = 1;
			ext_tank_right = 1;
		}
		else {
			ext_tank_left = 0;
			ext_tank_right = 0;
		}
	} else if (v == 2){
		ext_tank_left = !ext_tank_left;
	} else if (v == 7) {
		ext_tank_right = !ext_tank_right;
	}
	if ( ext_tank_left ) {
		pylons.pylon3.loadSet(pylons.pylonSets.fuel26L);
	} else {
		pylons.pylon3.loadSet(pylons.pylonSets.empty);
	}
	if ( ext_tank_right ) {
		pylons.pylon8.loadSet(pylons.pylonSets.fuel26R);
	} else {
		pylons.pylon8.loadSet(pylons.pylonSets.empty);
	}
	ExtTankLeft.setValue(ext_tank_left);
	ExtTankRight.setValue(ext_tank_right);
	update_ext_tanks_selected();
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
# Pushbutton is under ACM switch cover. In order to activate this
# jettison mode, landing gear handle and ACM guard must be up.  When
# pressed, only those stores selected on the armament control panel are
# jettisoned. To ensure release of all selected stores the ACM JETT push
# button must be depressed and held for at least 2 seconds. ACM jettison
# will not release any Sidewinder missiles even if their stations are
# selected.

var do_acm_jettison = func {
	    backseatUpdateTimer.stop(2);
	# will jettison all selected weapon pylons but never sidewinders.
	# landing gear handle up 
	if (getprop("controls/gear/gear-down"))
		return;
	var fuel_tanks = 0;
	var list = [];
	for (var i = 0;i<10;i+=1) {
		var station_selector_value = getprop("sim/model/f-14b/systems/external-loads/station["~i~"]/selected");
		var payload_selector_value = getprop("payload/weight["~i~"]/selected");
		if (payload_selector_value != "Empty" and payload_selector_value != "Released" and station_selector_value != 0) {
			append(list, i);
			if (i==2 or i==7)
			    fuel_tanks = 1;
			printf(" ++ jettison %-30s",payload_selector_value);
		}
		else
			printf(" --          %-30s",payload_selector_value);
	}
	pylons.fcs.jettisonSpecificPylons(list, 0);
	if (fuel_tanks){
		ExtTanks.setBoolValue(0);
	}
}
backseatUpdateTimer = maketimer(2, do_acm_jettison);
backseatUpdateTimer.simulatedTime = 1;

#callback from model
var acm_jettison = func {
	    backseatUpdateTimer.restart(2);
}
#RIO selective jettisoning

setlistener("sim/model/f-14b/controls/armament/sel-jett", func(v) {
    var val = v.getValue();
	if (val == 1)
	    backseatUpdateTimer.restart(2);
	else if (val == -1)
	    backseatUpdateTimer.restart(2);
	else
	    backseatUpdateTimer.stop();
}, 1, 0);

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
