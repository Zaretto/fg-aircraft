var STATION_ID_1 = 1;
var STATION_ID_2 = 2;
var STATION_ID_3 = 3;
var STATION_ID_4 = 4;
var STATION_ID_5 = 5;
var STATION_ID_6 = 6;
var STATION_ID_7 = 7;
var STATION_ID_8 = 8;

var get_armament_selector= func(station_number){
	return "sim/model/f-14b/controls/armament/station-selector[" ~ station_number ~ "]";
}

var station_selector = func(station_number) {
	# n = station number, v = up (-1) or down (1) or toggle (0) as there is two kinds of switches.
	selector = get_armament_selector(station_number);
	selector_state = getprop(selector) or 0;
	if ( station_number == STATION_ID_1 or station_number == STATION_ID_8 ) {
			# up/down/neutral
			selector_state = selector_state + 1;
			if (selector_state > 1)
				selector_state = -1;
	}
	else {
		# Only up/neutral allowed.
		# toggle value between 0 and -1
		selector_state = -(1-math.abs(selector_state));
	}
#	print(selector," set to ",selector_state);
	station_select(station_number, selector_state);
	#arm_selector();
}

var station_select = func(station_number, selector_state){
	var selector = get_armament_selector(station_number);
	setprop(selector, selector_state);
}