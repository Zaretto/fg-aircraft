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

var ll = nil;
# Used by dual_control to set up the mappings for the pilot.
var pilot_connect_copilot = func (copilot) {
	print("######## pilot_connect_copilot() ########");
	# Lock awg_9 controls for the pilot.
	awg_9.pilot_lock = 1;
	awg_9.awg9Radar.currentMode.priorityTarget = nil;
	ll = setlistener(copilot.getNode("sim/multiplay/generic/string[11]"),func (prop) {if (!awg_9.pilot_lock) return; var hk = prop.getValue(); if (hk == nil) return; awg_9.awg9Radar.designateMPCallsign(hk);awg_9.Hook.setValue(hk)},1,0);
	#awg_9.Hook.alias(copilot.getNode("sim/multiplay/generic/string[11]"));
	return [
		# Process received properties.
		DCT.SwitchDecoder.new (
			copilot.getNode(bs_switches1_mpp),
			[
				func (b) {
					awg_9.RadarStandby.setBoolValue(b);
				},
				func (b) {
					f14.station_select(2,b);
					f14.arm_selector();
				},
				func (b) {
					f14.station_select(3,b);
					f14.arm_selector();
				},
				func (b) {
					f14.station_select(4,b);
					f14.arm_selector();
				},
				func (b) {
					f14.station_select(5,b);
					f14.arm_selector();
				},
				func (b) {
					f14.station_select(6,b);
					f14.arm_selector();
				},
				func (b) {
					f14.station_select(7,b);
					f14.arm_selector();
				},
			]
		),
		DCT.TDMDecoder.new
			(copilot.getNode(bs_TDM1_mpp),
			[
				func (b) {
					RangeRadar2.setValue(b);
				},
				func (b) {
					awg_9.WcsMode.setIntValue(b);
				},
				func (b) {
					f14.station_select(1,b);
					f14.arm_selector();
				},
				func (b) {
					f14.station_select(8,b);
					f14.arm_selector();
				},
				func (b) {
					awg_9.antennae_knob_prop.setDoubleValue(b);
				},
				func (b) {
					awg_9.antennae_az_knob_prop.setValue(b);
				},
				func (b) {
					awg_9.barsIndexChange(b);
				},
				func (b) {
					awg_9.azFieldChange(b);
				},
			]
		)
	];

}

var pilot_disconnect_copilot = func {
	print("######## pilot_disconnect_copilot() ########");
	# Unlock awg_9 controls for the pilot.
	awg_9.pilot_lock = 0;
	#awg_9.Hook.unalias();
	if (ll != nil) {
		removelistener(ll);
		ll = nil;
	}
}

# Copilot MP property mappings and specific pilot connect/disconnect actions.
#---------------------------------------------------------------------------

# Used by dual_control to set up the mappings for the copilot.
var copilot_connect_pilot = func (pilot) {
	print("######## copilot_connect_pilot() ########");
	# Initialize Nasal wrappers for copilot pick anaimations.
	set_copilot_wrappers(pilot);
	awg_9.xmlDisplays.initDualTgts(pilot);
	return [
		# Process received properties.

		# Process properties to send.
		DCT.SwitchEncoder.new (
			#  0 - 4: awg9 Controls
			[
				awg_9.RadarStandby,
				props.globals.getNode("sim/model/f-14b/controls/armament/station-selector[2]"),
				props.globals.getNode("sim/model/f-14b/controls/armament/station-selector[3]"),
				props.globals.getNode("sim/model/f-14b/controls/armament/station-selector[4]"),
				props.globals.getNode("sim/model/f-14b/controls/armament/station-selector[5]"),
				props.globals.getNode("sim/model/f-14b/controls/armament/station-selector[6]"),
				props.globals.getNode("sim/model/f-14b/controls/armament/station-selector[7]")
			],
			props.globals.getNode(bs_switches1_mpp)
		),
		DCT.TDMEncoder.new (
			#  0: awg9 Range
			[
				props.globals.getNode("instrumentation/radar/radar2-range"),
				awg_9.WcsMode,
				props.globals.getNode("sim/model/f-14b/controls/armament/station-selector[1]"),
				props.globals.getNode("sim/model/f-14b/controls/armament/station-selector[8]"),
				awg_9.antennae_knob_prop,
				awg_9.antennae_az_knob_prop,
				awg_9.bars_index,
				awg_9.az_field,
			],
			props.globals.getNode(bs_TDM1_mpp)

		)
	];

}

var copilot_disconnect_pilot = func {
	print("######## copilot_disconnect_pilot() ########");
	unset_copilot_wrappers();
}

var prev_pilot = nil;

# Copilot Nasal wrappers
var set_copilot_wrappers = func (pilot) {
	prev_pilot = pilot;
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
	#p = "sim/model/f-14b/instrumentation/radar-awg-9/wcs-mode/pulse-srch";
	#pilot.getNode(p, 1).alias(props.globals.getNode(p));
	#p = "sim/model/f-14b/instrumentation/radar-awg-9/wcs-mode/tws-auto";
	#pilot.getNode(p, 1).alias(props.globals.getNode(p));
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

var unset_copilot_wrappers = func {
	if (prev_pilot == nil) return;
	var p = "sim/current-view/name";
	prev_pilot.getNode(p, 1).unalias();
	p = "instrumentation/altimeter/indicated-altitude-ft";
	prev_pilot.getNode(p, 1).unalias();
	p = "instrumentation/altimeter/setting-inhg";
	prev_pilot.getNode(p, 1).unalias();
	p = "orientation/heading-deg";
	prev_pilot.getNode(p, 1).unalias();
	p = "orientation/heading-magnetic-deg";
	prev_pilot.getNode(p, 1).unalias();
	p = "sim/model/f-14b/controls/radar-awg-9/brightness";
	prev_pilot.getNode(p, 1).unalias();
	p = "sim/model/f-14b/controls/radar-awg-9/on-off";
	prev_pilot.getNode(p, 1).unalias();
	p = "sim/model/f-14b/instrumentation/radar-awg-9/display-rdr";
	prev_pilot.getNode(p, 1).unalias();
	p = "sim/model/f-14b/instrumentation/awg-9/sweep-factor";
	prev_pilot.getNode(p, 1).unalias();
	p = "sim/model/f-14b/controls/TID/brightness";
	prev_pilot.getNode(p, 1).unalias();
	p = "sim/model/f-14b/controls/TID/on-off";
	prev_pilot.getNode(p, 1).alias(props.globals.getNode(p));
	#p = "sim/model/f-14b/instrumentation/radar-awg-9/wcs-mode/pulse-srch";
	#prev_pilot.getNode(p, 1).alias(props.globals.getNode(p));
	#p = "sim/model/f-14b/instrumentation/radar-awg-9/wcs-mode/tws-auto";
	#prev_pilot.getNode(p, 1).unalias();
	p = "instrumentation/radar/az-field";
	prev_pilot.getNode(p, 1).unalias();
	p = "instrumentation/ecm/on-off";
	prev_pilot.getNode(p, 1).unalias();
	p = "sim/model/f-14b/controls/rio-ecm-display/mode-ecm-nav";
	prev_pilot.getNode(p, 1).unalias();
	p = "sim/model/f-14b/controls/HSD/on-off";
	prev_pilot.getNode(p, 1).unalias();
	p = "sim/model/f-14b/instrumentation/hsd/needle-deflection";
	prev_pilot.getNode(p, 1).unalias();
	p = "instrumentation/nav[1]/radials/selected-deg";
	prev_pilot.getNode(p, 1).unalias();
	p = "instrumentation/radar/radar2-range";
	prev_pilot.getNode(p, 1).unalias();
	p = "instrumentation/radar/radar-standby";
	prev_pilot.getNode(p, 1).unalias();
}

