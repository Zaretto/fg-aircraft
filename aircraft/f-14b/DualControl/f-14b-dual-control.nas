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
var bs_switches1_mpp = "sim/multiplay/generic/int[0]";
var bs_TDM1_mpp      = "sim/multiplay/generic/string[0]";


# Useful local property paths.
var WcsModeList = awg_9.WcsMode.getChildren();
var RangeRadar2 = props.globals.getNode("instrumentation/radar/radar2-range");

# Slow state properties for replication.


# Pilot MP property mappings and specific copilot connect/disconnect actions.
#---------------------------------------------------------------------------


# Used by dual_control to set up the mappings for the pilot.
var pilot_connect_copilot = func (copilot) {
	print("######## pilot_connect_copilot() ########");
	# Lock awg_9 controls for the pilot.
	awg_9.pilot_lock = 1;
	return [
		# Process received properties.
		DCT.SwitchDecoder.new (
			copilot.getNode(bs_switches1_mpp),
			[
				func (b) {
					awg_9.RadarStandby.setBoolValue(b);
				},
				func (b) {
					awg_9.WcsMode.getNode("pulse-srch").setBoolValue(b);
				},
				func (b) {
					awg_9.WcsMode.getNode("tws-auto").setBoolValue(b);
					awg_9.wcs_mode_update();
				}
			]
		),
		DCT.TDMDecoder.new
			(copilot.getNode(bs_TDM1_mpp),
			[
				func (b) {
					RangeRadar2.setValue(b);
				}
			]
		)
	];

}

var pilot_disconnect_copilot = func {
	print("######## pilot_disconnect_copilot() ########");
	# Unlock awg_9 controls for the pilot.
	awg_9.pilot_lock = 0;
}

# Copilot MP property mappings and specific pilot connect/disconnect actions.
#---------------------------------------------------------------------------

# Used by dual_control to set up the mappings for the copilot.
var copilot_connect_pilot = func (pilot) {
	print("######## copilot_connect_pilot() ########");
	# Initialize Nasal wrappers for copilot pick anaimations.
	set_copilot_wrappers(pilot);

	return [
		# Process received properties.

	];

}

var copilot_disconnect_pilot = func {
	print("######## copilot_disconnect_pilot() ########");
}


# Copilot Nasal wrappers
var set_copilot_wrappers = func (pilot) {
	pilot.getNode("sim/model/f-14b/controls/TID/brightness", 1).setValue(1);
	pilot.getNode("sim/model/f-14b/controls/radar-awg-9/brightness", 1).setValue(1);
	pilot.getNode("sim/model/f-14b/controls/TID/on-off", 1).setValue(1);
	pilot.getNode("sim/model/f-14b/controls/radar-awg-9/on-off", 1).setValue(1);
}

