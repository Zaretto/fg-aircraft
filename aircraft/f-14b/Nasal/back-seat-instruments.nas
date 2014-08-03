var UPDATE_PERIOD = 0.05;

# Check pilot's aircraft path from it's callsign.
var PilotCallsign = props.globals.getNode("/sim/remote/pilot-callsign");
var Pilot = nil;

var check_pilot_callsign = func() {
	r_callsign = PilotCallsign.getValue();
	if ( r_callsign ) {
		var mpplayers = props.globals.getNode("/ai/models").getChildren("multiplayer");
		foreach (var p; mpplayers) {
			if ( p.getChild("callsign").getValue() == r_callsign ) {
				Pilot = p; 
			}
		}
	} else {
		Pilot = nil;
	}
}


var select_ecm_nav = func {
	var ecm_nav_mode = Pilot.getNode("sim/model/f-14b/controls/rio-ecm-display/mode-ecm-nav");
	ecm_nav_mode.setBoolValue( ! ecm_nav_mode.getBoolValue());
}

##

# Receive basic instruments data over MP from pilot's aircraft.
var PilotInstrString = nil;
instruments_data_import = func {
	if ( Pilot == nil ) { return }
	PilotInstrString = Pilot.getNode("sim/multiplay/generic/string[1]", 1);
	var str = PilotInstrString.getValue();
	if ( str != nil ) {
		var l = split(";", str);
		# Todo: Create the needed nodes only at connection/de-connection time. 
		# ias, mach, fuel_total, tc_mode, tc_bearing, tc_in_range, tc_range, steer_mode_code, cdi, radial.
		if ( size(l) > 1 ) {
			Pilot.getNode("instrumentation/airspeed-indicator/indicated-speed-kt", 1).setValue( l[0] );
			Pilot.getNode("velocities/mach", 1).setValue( l[1] );
			Pilot.getNode("sim/model/f-14b/instrumentation/fuel-gauges/total", 1).setValue( l[2] );
			Pilot.getNode("sim/model/f-14b/instrumentation/tacan/mode", 1).setValue( l[3] );
			Pilot.getNode("instrumentation/tacan/indicated-mag-bearing-deg", 1).setValue( l[4] );
			Pilot.getNode("instrumentation/tacan/in-range", 1).setBoolValue( l[5] );
			Pilot.getNode("instrumentation/tacan/indicated-distance-nm", 1).setValue( l[6] );
			var SteerSubmodeCode = Pilot.getNode("sim/model/f-14b/controls/pilots-displays/steer-submode-code", 1);
			SteerSubmodeCode.setValue( l[7] );

			Pilot.getNode("sim/model/f-14b/instrumentation/hsd/needle-deflection", 1).setValue( l[8] );
			Pilot.getNode("instrumentation/nav[1]/radials/selected-deg", 1).setValue( l[9] );

		}
	}
	#PilotInstrString2 = Pilot.getNode("sim/multiplay/generic/string[2]", 1);
	#var str2 = PilotInstrString2.getValue();
	#if ( str2 != nil ) {
		#Pilot.getNode("instrumentation/radar/radar2-range", 1).setValue(str2);
	#}
}

# Send a/c type over MP for pilot.
var InstrString = props.globals.getNode("sim/multiplay/generic/string[1]", 1);
var ACString = props.globals.getNode("sim/aircraft");
instruments_data_export = func {
	# Aircraft variant
	var ac_string = ACString.getValue();
	var l_s = [ac_string];
	var str = "";
	foreach( s ; l_s ) {
		str = str ~ s ~ ";";
	}
	InstrString.setValue(str);
}

# Main loop ###############
var cnt = 0;

var main_loop = func {
	cnt += 1;
	# done each 0.05 sec.
	awg_9.rdr_loop();
	var a = cnt / 2;
	if ( ( a ) == int( a )) {
		# done each 0.1 sec, cnt even.
		#if (( cnt == 6 ) or ( cnt == 12 )) {
			# done each 0.3 sec.
			#if ( cnt == 12 ) {
				# done each 0.6 sec.
				#cnt = 0;
			#}
		#}
	} else {
		# done each 0.1 sec, cnt odd.
		check_pilot_callsign();
		instruments_data_import();
		instruments_data_export();
		#if (( cnt == 5 ) or ( cnt == 11 )) {
			# done each 0.3 sec.
			#if ( cnt == 11 ) {
				# done each 0.6 sec.

			#}
		#}
	}
	settimer(main_loop, UPDATE_PERIOD);
}


# Init ####################
var init = func {
	print("Initializing F-14B Back Seat Systems");
	# launch
	check_pilot_callsign();
	radardist.init();
	awg_9.init();
	settimer(main_loop, 0.5);
}

setlistener("sim/signals/fdm-initialized", init);





