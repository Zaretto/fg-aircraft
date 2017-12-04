###############################################################################
## $Id: f-14b-dual-control.nas,v 1.7 2010/03/16 18:32:21 abory Exp $
##
##  Nasal for dual control of the f-14b over the multiplayer network.
##
##  Copyright (C) 2009  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license version 2 or later.
##
###############################################################################

# Renaming (almost :)
var DCT = dual_control_tools;

# Pilot/copilot aircraft identifiers. Used by dual_control.
var pilot_type   = "Aircraft/f-14b/Models/f-14b.xml";
var copilot_type = "Aircraft/f-14b/Models/f-14b-bs.xml";

props.globals.initNode("/sim/remote/pilot-callsign", "", "STRING");


# MP enabled properties.
# NOTE: These must exist very early during startup - put them
#       in the -set.xml file.

# Pilot MP property mappings and specific copilot connect/disconnect actions.
#---------------------------------------------------------------------------


# Used by dual_control to set up the mappings for the pilot.
var pilot_connect_copilot = func (copilot) {
    f14.RIO = copilot.getNode("callsign").getValue();
	print("RIO callsign  : ",f14.RIO);
	return [ ];
}

var pilot_disconnect_copilot = func {
	print("######## pilot_disconnect_copilot() ########");
}

# Copilot MP property mappings and specific pilot connect/disconnect actions.
#---------------------------------------------------------------------------

# Used by dual_control to set up the mappings for the copilot.
var copilot_connect_pilot = func (pilot) {
    f14.Pilot = pilot.getNode("callsign").getValue();
	print("Pilot callsign  : ",f14.Pilot);
	# Initialize Nasal wrappers for copilot pick anaimations.
	return [
		# Process received properties.

	];

}

var copilot_disconnect_pilot = func {
    f14.copilot = nil;
	print("######## copilot_disconnect_pilot() ########");
}

