###############################################################################
##  2010/03/11 alexis bory
##
##  f15 MP properties broascast
##
##  Copyright (C) 2007 - 2009  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license v2 or later.
##
###############################################################################

var Binary = nil;
var broadcast = nil;
var message_id = nil;

###############################################################################
# Send message wrappers.
var send_wps_state = func (state) {
	#print("Message to send: ",state);
	if (typeof(broadcast) != "hash") {
		#print("Error: typeof(broadcast) != hash");
		return;
	}
	broadcast.send(message_id["ext_load_state"] ~ Binary.encodeInt(state));
	#print(message_id["ext_load_state"]," ",Binary.encodeInt(state));
	#print(message_id["ext_load_state"] ~ Binary.encodeInt(state));
}

###############################################################################
# MP broadcast message handler.
var handle_message = func (sender, msg) {
#	print("Message from "~ sender.getNode("callsign").getValue() ~ " size: " ~ size(msg));
#	debug.dump(msg);
	var type = msg[0];
	if (type == message_id["ext_load_state"][0]) {
		var state = Binary.decodeInt(substr(msg, 1));
#	print("ext_load_state:", msg, " ", state);
	update_ext_load(sender, state);
	}
}

###############################################################################
# MP Accept and disconnect handlers.
var listen_to = func (pilot) {
	if (pilot.getNode("sim/model/path") != nil and
			streq("Aircraft/F-15/Models/F-15D.xml",
		pilot.getNode("sim/model/path").getValue())) {
#		print("Accepted ",  pilot.getNode("sim/model/path").getValue());
		return 1;
	} else {
#		print("Not listening to ", pilot.getNode("sim/model/path").getValue());
		return 0;
	}
}

var when_disconnecting = func (pilot) {
}

###############################################################################
# Decodes wps_state
# and extract f15 external load sheme and individual pylons state.
# this is encoded in ext_stores.nas into a bitfield
# the decode must match the encoding scheme.
# -
# I've followed the way that xii did this; I can't help thinking
# that this would be better implemented with some bit shifting
# but this way at least works and isn't in the main loop so any performance issues
# will be hidden by the network latency. Richard - 2015-06-30
var update_ext_load = func(sender, state)
{
	var Wnode = sender.getNode("sim/model/f15/systems/external-loads", 1);
	var PayloadNode = sender.getNode("payload", 1);
	var FuelNode = sender.getNode("consumables/fuel", 1);
	var StationList = Wnode.getChildren();
	var Station = nil;
	var wpstr = bits.string(state, 32);
#printf("WPSTR : %s",wpstr);

	var c = 31;
	var o = "";
	var str = chr(wpstr[29]) ~ chr(wpstr[30]) ~ chr(wpstr[31]);
	if ( str == "000" ) { o = "Clean" }
	elsif ( str == "001") { o = "Standard Combat" }
	elsif ( str == "010") { o = "Offensive Counter Air" }
	elsif ( str == "011") { o = "No Fly Zone" }
	elsif ( str == "100") { o = "Ferry Flight" }
#print("Arm set ",o);

	Wnode.getNode("external-load-set", 1).setValue(o);
	c -= 3;
	var s = 10;

	while (s >= 0) 
    {
# fuel tanks only take one bit.
        Station = Wnode.getChild ("station", s , 1);
        Station.getNode("type", 1).setValue(o);
        Station.getNode("selected", 1).setBoolValue(1);
        var payload = PayloadNode.getChild ("weight", s , 1);
		if ( s != 1 and s != 5 and s != 9) 
        {
			var ccc = c-2;
			var cc = c-1;
			str = chr(wpstr[ccc]) ~ chr(wpstr[cc]) ~ chr(wpstr[c]);
			if ( str == "001" ) { o = "AIM-9" }
			elsif ( str == "010") { o = "AIM-7" }
			elsif ( str == "011") { o = "AIM-120" }
			elsif ( str == "100") { o = "MK-83" }
			elsif ( str == "000") { o = "none" }
			Station = Wnode.getChild ("station", s , 1);
			Station.getNode("type", 1).setValue(o);
			Station.getNode("selected", 1).setBoolValue(1);

			c -= 3;
#			print("arm ",str," ",s," ",o);
		}
        else 
        {
            var tank_sel = 0;
            var fuel_idx = 5;

# Stations 1,5,7
# Tanks    5,7,6
            if (s == 5) 
                fuel_idx = 7;
            if (s == 9)
                fuel_idx = 6;

			o = "none";
			str = chr(wpstr[c]);
			if ( str == "1" ) { o = "Droptank"; tank_sel = 1; }
			Station = Wnode.getChild ("station", s , 1);
			Station.getNode("type", 1).setValue(o);
			Station.getNode("selected", 1).setBoolValue(0);
			c -= 1;
            var fuel_n = FuelNode.getChild ("tank", fuel_idx, 1);
            fuel_idx = fuel_idx + 1;
            fuel_n.getNode("selected", 1).setBoolValue(tank_sel);
#			print("tank ",str," ",s," ",o," ",tank_sel);
		}
    	payload.getNode("selected", 1).setValue(o);
		s -= 1 ;
	}
}




###############################################################################
# Initialization.
var mp_network_init = func (active_participant) {
print("F-15 MP network broadcast init");
	Binary = mp_broadcast.Binary;
	broadcast =
		mp_broadcast.BroadcastChannel.new
			("sim/multiplay/generic/string[0]",
			handle_message,
			0,
			listen_to,
			when_disconnecting,
			active_participant);
	# Set up the recognized message types.
	message_id = { ext_load_state : Binary.encodeByte(1),
	};
}
