var MARKER = "Models/Geometry/box.xml";
var fdm_parts = [];

var draw_part = func(lat, lon, alt){
	var m = geo.Coord.new().set_latlon(lat, lon).set_alt(alt);
    debug.dump(m);
	append(fdm_parts, geo.put_model(MARKER, m, 0));
}
var draw_fdm_parts = func() {

    forindex (var i; fdm_parts) {
    if (fdm_parts[i] != nil)
    print("remove part",i);
        fdm_parts[i].remove();
    }
    fdm_parts = [];


draw_part(getprop("/fdm/jsbsim/position/vrp-gc-latitude_deg"), 
    getprop("/fdm/jsbsim/position/vrp-longitude_deg"),
    getprop("/fdm/jsbsim/position/h-sl-ft"));
    #getprop("/fdm/jsbsim/position/vrp-radius-ft")
}
			draw_fdm_parts();

# var fdm_init_listener = _setlistener("/sim/signals/fdm-initialized", func {
# 	removelistener(fdm_init_listener); # uninstall, so we're only called once
# 	# remove top bar unless otherwise specified

# 	setlistener("/sim/rendering/visual-fdm", func(n) {
# 		if (n.getValue()) {
# 			draw_fdm_parts();
# 		} else {
#             forindex (var i; fdm_parts) {
#                 if (fdm_parts[i] != nil) {
#                     fdm_parts[i].remove();
#                     fdm_parts[i] = nil;
#                 }
#             }
#         }
# 	}, 1);
# });


