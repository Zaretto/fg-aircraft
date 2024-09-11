var MARKER = "Models/Geometry/box.xml";
var fdm_parts = [];

var draw_part = func(lat, lon, alt){
	var m = geo.Coord.new().set_latlon(lat, lon).set_alt(alt);
    m = geo.aircraft_position();
    debug.dump(m);
	append(fdm_parts, geo.put_model(MARKER, m, 0));
}

draw_part(getprop("/fdm/jsbsim/position/vrp-gc-latitude_deg"), 
    getprop("/fdm/jsbsim/position/vrp-longitude_deg"),
    getprop("/fdm/jsbsim/position/h-sl-ft"));
    #getprop("/fdm/jsbsim/position/vrp-radius-ft")


    
var MARKER = "Models/Geometry/box.xml";
#var fdm_parts = [];

var draw_part = func(lat, lon, alt){
	var m = geo.Coord.new().set_latlon(lat, lon).set_alt(alt);
    m = geo.aircraft_position();
    debug.dump(m);
	append(fdm_parts, geo.put_model(MARKER, m, 0));
}
    forindex (var i; fdm_parts) {
    if (fdm_parts[i] != nil)
    print("remove part",i);
        fdm_parts[i].remove();
    }
    fdm_parts = [];

debug.dump(fdm_parts);
draw_part(getprop("/fdm/jsbsim/position/vrp-gc-latitude_deg"), 
    getprop("/fdm/jsbsim/position/vrp-longitude_deg"),
    getprop("/fdm/jsbsim/position/h-sl-ft"));
    #getprop("/fdm/jsbsim/position/vrp-radius-ft")


