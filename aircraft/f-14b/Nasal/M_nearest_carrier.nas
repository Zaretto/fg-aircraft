#
#
#

setlistener("/instrumentation/tacan/display/channel", func {
                find_carrier_by_tacan();
},0,0);
#
# Locate carrier based on TACAN. This used to be used for the ARA 63 (Carrier ILS) support - but this has
# been replaced by the Emesary based notification model. However the ground services dialog uses this
# for reposition - so replace the continual scanning (as part of the radar) with a one off method that can be
# called as needed.
find_carrier_by_tacan = func {
    var raw_list = awg_9.Mp.getChildren();
    var carrier_located = 0;
    
    foreach ( var c; raw_list ) {

        var tchan = c.getNode("navaids/tacan/channel-ID");
        if (tchan != nil and !we_are_bs) {
            tchan = tchan.getValue();
            if (tchan == getprop("/instrumentation/tacan/display/channel")) {
# Tuned into this carrier (node) so use the offset.
# Get the position of the glideslope; this is offset from the carrier position by
# a smidgen. This is measured and is a point slightly in front of the TDZ where the
# deck is marked with previous tyre marks (which seems as good a place as any to 
# aim for).
                if (c.getNode("position/global-x") != nil) {
                    var x = c.getNode("position/global-x").getValue() + 88.7713542;
                    var y = c.getNode("position/global-y").getValue() + 18.74631309;
                    var z = c.getNode("position/global-z").getValue() + 115.6574875;

                    f14.carrier_ara_63_position = geo.Coord.new().set_xyz(x, y, z);

                    var carrier_heading = c.getNode("orientation/true-heading-deg");
                    if (carrier_heading != nil) {
                        # relative offset of the course to the tdz
                        # according to my measurements the Nimitz class is 8.1362114 degrees (measured 178 vs carrier 200 allowing for local magvar -13.8637886)
                        # (i.e. this value is from tuning rather than calculation)
                        f14.carrier_heading = carrier_heading.getValue();
                        f14.carrier_ara_63_heading = carrier_heading.getValue() - 8.1362114;
                    }
                    else
                    {
                        f14.carrier_ara_63_heading = 0;
                        print("Carrier heading invalid");
                    }
                    carrier_located = 1;
                    f14.tuned_carrier_name = c.getNode("name").getValue();
                    setprop("sim/model/f-14b/tuned-carrier",f14.tuned_carrier_name);
                    return;
                }
                else
                {
                    # tuned tacan is not carrier.
                    f14.carrier_ara_63_heading = 0;
                }
            }
        }
    }
}
