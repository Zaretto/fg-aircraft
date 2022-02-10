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

var esRIO = nil;

var eject = func{
  if (getprop("f14/done")==1) {# or !getprop("controls/seat/ejection-safety-lever")
      return;
  }
  setprop("f14/done",1);
  var es = armament.AIM.new(11, "es","Pilot", nil ,nil);
  esRIO = armament.AIM.new(12, "es","Rio", nil ,nil);
  #setprop("fdm/jsbsim/fcs/canopy/hinges/serviceable",0);
  es.releaseAtNothing();
  var n = props.globals.getNode("ai/models", 1);
  for (i = 0; 1==1; i += 1) {
    if (n.getChild("es", i, 0) == nil) {
      break;
    }
  }
    
  # set the view to follow pilot:
  setprop("sim/view[115]/config/eye-lat-deg-path","/ai/models/es["~(i-2)~"]/position/latitude-deg");
  setprop("sim/view[115]/config/eye-lon-deg-path","/ai/models/es["~(i-2)~"]/position/longitude-deg");
  setprop("sim/view[115]/config/eye-alt-ft-path","/ai/models/es["~(i-2)~"]/position/altitude-ft");
  setprop("sim/view[115]/config/target-lat-deg-path","/ai/models/es["~(i-2)~"]/position/latitude-deg");
  setprop("sim/view[115]/config/target-lon-deg-path","/ai/models/es["~(i-2)~"]/position/longitude-deg");
  setprop("sim/view[115]/config/target-alt-ft-path","/ai/models/es["~(i-2)~"]/position/altitude-ft");
  setprop("sim/view[115]/enabled", 1);
  view.setViewByIndex(115);

  settimer(eject2, 0.20)
}

var eject2 = func {
  esRIO.releaseAtNothing();
  
  #setprop("sim/view[0]/enabled",0); #disabled since it might get saved so user gets no pilotview in next aircraft he flies in.
  settimer(func {f14.exp();},3.5);
}