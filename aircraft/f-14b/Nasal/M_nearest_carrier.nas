var Mp = props.globals.getNode("ai/models");

setlistener("/ai/models/model-added", func(v){
    raw_list = Mp.getChildren();
});
setlistener("/ai/models/model-removed", func(v){
    raw_list = Mp.getChildren();
});
var nearest_carrier = nil;
raw_list = Mp.getChildren();

FindNearestCarrier = {
    new : func
    {
        var obj = {
            parents : [FindNearestCarrier],
            process_carriers : frame_utils.PartitionProcessor.new("Nearest-Carrier", 1, nil)
        };
        if (defined("obj.process_carriers.set_max_time_usec")){
            obj.process_carriers.set_max_time_usec(500);
            obj.process_carriers.set_timestamp(maketimestamp());
        }
        return obj;
    },
    update : func(notification)
    {
        # use the minimum amount of time to do this scan.
        # - this is fine because the nearest carrier will not change that often
        if (notification.FrameCount != 0) {
            return;
        }
        # scan the list if we haven't found a carrier or when the aircraft moved 1000m from the position
        # where the can was last performed.
        if (nearest_carrier != nil and !nearest_carrier.rescan()){
#            print("not scanning as within 1km of original position");
            return;
        }
        me.process_carriers.process(me, 
            raw_list, 
            func(pp, obj, data){
#                print("Carrier scan begin");
                obj.carrier_located = 0;
                obj.nearest_carrier_node = nil;
                obj.nearest_carrier_distance_meters = 40075000; # Earth's circumference
                obj.geopos =  geo.Coord.new();
                obj.aircraft_position = geo.aircraft_position();
            },                        
            func(pp, obj, c){
                if (find("carrier",c.getName()) != -1 and c.getNode("position/global-x") != nil and c.getNode("position/global-x").getValue() != nil) {
#                print("check ",c.getIndex(), " ", c.getNode("name").getValue());
                    var x = c.getNode("position/global-x").getValue();
                    var y = c.getNode("position/global-y").getValue();
                    var z = c.getNode("position/global-z").getValue();

                    obj.geopos.set_xyz(x, y, z);
                    obj.carrier_distance = obj.aircraft_position.distance_to(obj.geopos);
                    if (obj.carrier_distance >= obj.nearest_carrier_distance_meters){
#                        print("    -- ",c.getIndex()," not closer than ",obj.nearest_carrier_node.getNode("name").getValue());
                    }
                    else {
                        obj.nearest_carrier_distance_meters = obj.carrier_distance;
#                        print("    -- found ",c.getNode("name").getValue(), " dist ",obj.nearest_carrier_distance_meters*M2NM);
                        obj.nearest_carrier_node = c;
                    }
                }
                return 1;
            },
            func(pp, obj, data) {
                # print("Scan end");
                # debug.dump(obj);
                if (obj.nearest_carrier_node != nil){
#                    print("nearest carrier now ",obj.nearest_carrier_node.getNode("name").getValue());
                    nearest_carrier = {   
                        heading : obj.nearest_carrier_node.getNode("orientation/true-heading-deg"),
                        name    : obj.nearest_carrier_node.getNode("name").getValue(), 
                        x       : obj.nearest_carrier_node.getNode("position/global-x"),
                        y       : obj.nearest_carrier_node.getNode("position/global-y"),
                        z       : obj.nearest_carrier_node.getNode("position/global-z"),
                        getpos  : func {
                             pos = geo.Coord.new();
                             pos.set_xyz(me.x.getValue(), me.y.getValue(), me.z.getValue()); 
                             return pos;
                        },
                        rescan_dist : 10,
                        original_pos : obj.aircraft_position, 
                        rescan : func {
                            me.original_pos.distance_to(geo.aircraft_position()) > me.rescan_dist;
                        },
                        node    : obj.nearest_carrier_node,
                        get_heading : func {return me.heading.getValue();},
                    };                
                    setprop("sim/model/f-14b/tuned-carrier",nearest_carrier.name);
#                    debug.dump(nearest_carrier);
                }
            }
        );
    }
};

var n = {
    FrameCount : 0
};
var find_nearest_carrier = FindNearestCarrier.new();
#find_nearest_carrier.update(n);

input = {
#        name          : "/prop/name",
};

emexec.ExecModule.register("F-14-nearest-carrier", input, find_nearest_carrier,1);

