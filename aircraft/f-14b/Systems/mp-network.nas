###############################################################################
##  2010/03/11 alexis bory
##
##  f-14b MP properties broascast
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
# var send_wps_state = func (state) {
# 	#print("Message to send: ",state);
# 	if (typeof(broadcast) != "hash") {
# 		#print("Error: typeof(broadcast) != hash");
# 		return;
# 	}
# 	broadcast.send(message_id["ext_load_state"] ~ Binary.encodeInt(state));
# 	#print(message_id["ext_load_state"]," ",Binary.encodeInt(state));
# 	#print(message_id["ext_load_state"] ~ Binary.encodeInt(state));
# }

###############################################################################
# MP broadcast message handler.
var handle_message = func (sender, msg) {
	#print("Message from "~ sender.getNode("callsign").getValue() ~ " size: " ~ size(msg));
#	debug.dump(msg);
	#var type = msg[0];
	#if (type == message_id["ext_load_state"][0]) {
	#  var state = Binary.decodeInt(substr(msg, 1));
	#  print("ext_load_state:", msg, " ", state);
	#  update_ext_load(sender, state);
	#}
}

###############################################################################
# MP Accept and disconnect handlers.
var listen_to = func (pilot) {
	if (pilot.getNode("sim/model/path") != nil and
			streq("Aircraft/f-14b/Models/f-14b.xml",
		pilot.getNode("sim/model/path").getValue())) {
		#print("Accepted " ~ pilot.getPath());
		return 1;
	} else {
		#print("Rejected " ~ pilot.getPath());
		return 0;
	}
}

var when_disconnecting = func (pilot) {
}

###############################################################################
# Decodes wps_state
# and extract f-14b external load sheme and individual pylons state.
var update_ext_load = func(sender, state) {
	var Wnode = sender.getNode("sim/model/f-14b/systems/external-loads", 1);
	var StationList = Wnode.getChildren();
	var Station = nil;
# state will contain the value to decode.
}




###############################################################################
# Initialization.
var mp_network_init = func (active_participant) {
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
