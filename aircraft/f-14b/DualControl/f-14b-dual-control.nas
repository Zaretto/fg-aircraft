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

		# Process properties to send.
		DCT.SwitchEncoder.new (
			#  0 - 4: awg9 Controls
			[
				awg_9.RadarStandby,
				awg_9.WcsMode.getNode("pulse-srch"),
				awg_9.WcsMode.getNode("tws-auto")
			],
			props.globals.getNode(bs_switches1_mpp)
		),
		DCT.TDMEncoder.new (
			#  0: awg9 Range
			[
				props.globals.getNode("instrumentation/radar/radar2-range")
			],
			props.globals.getNode(bs_TDM1_mpp)

		)
	];

}

var copilot_disconnect_pilot = func {
	print("######## copilot_disconnect_pilot() ########");
}


# Copilot Nasal wrappers
var set_copilot_wrappers = func (pilot) {
	var p = "sim/current-view/name";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "instrumentation/altimeter/indicated-altitude-ft";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "instrumentation/altimeter/setting-inhg";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "orientation/heading-deg";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "orientation/heading-magnetic-deg";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "sim/model/f-14b/controls/radar-awg-9/brightness";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "sim/model/f-14b/controls/radar-awg-9/on-off";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "sim/model/f-14b/instrumentation/radar-awg-9/display-rdr";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "sim/model/f-14b/instrumentation/awg-9/sweep-factor";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "sim/model/f-14b/controls/TID/brightness";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "sim/model/f-14b/controls/TID/on-off";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "sim/model/f-14b/instrumentation/radar-awg-9/wcs-mode/pulse-srch";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "sim/model/f-14b/instrumentation/radar-awg-9/wcs-mode/tws-auto";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "instrumentation/radar/az-field";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "instrumentation/ecm/on-off";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "sim/model/f-14b/controls/rio-ecm-display/mode-ecm-nav";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "sim/model/f-14b/controls/HSD/on-off";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "sim/model/f-14b/instrumentation/hsd/needle-deflection";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "instrumentation/nav[1]/radials/selected-deg";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "instrumentation/radar/radar2-range";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
	p = "instrumentation/radar/radar-standby";
	pilot.getNode(p, 1).alias(props.globals.getNode(p));
}

