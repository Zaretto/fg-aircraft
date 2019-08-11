# F-15 VSD; using Canvas
# ---------------------------
# Richard Harrison: 2015-01-23 : rjh@zaretto.com

#angular definitions
#up angle 1.73 deg
#left/right angle 5.5 deg
#down angle 10.2 deg
#total size 11x11.93 deg
#texture square 256x256
#bottom left 0,0
#viewport size  236x256
#center at 118,219
#pixels per deg = 21.458507963
var DTOR = math.pi / 180.0;

var lvx = 0;
var lvy = 0;
var lvz = 0;
var ltime = 0;
var curtimen = props.globals.getNode("/sim/time/elapsed-sec");

#
# calculate groundspeed based on vector product of ECEF 
calc_groundspeed_kt = func(node) {
    var vxn = node.getNode("position/global-x");
    var vyn = node.getNode("position/global-y");
    var vzn = node.getNode("position/global-z");
    if (vxn == nil or vyn == nil or vzn == nil or curtimen == nil){
        return;
    }
    var vx = vxn.getValue();    
    var vy = vyn.getValue();    
    var vz = vzn.getValue();    
    var curtime = curtimen.getValue();

    if (lvx != 0) {
        var nvtime = curtime - ltime;
        if (nvtime < 4)
          return;
        var nvx = vx - lvx;
        var nvy = vy - lvy;
        var nvz = vz - lvz;
        var vv = math.sqrt(nvx*nvx + nvy*nvy + nvz*nvz)/nvtime;
#        print("nvx ",nvx, " nvy ",nvy, " vv ",vv*1.94384, " (",nvtime,")");
        if (node != nil)
          node.getNode("velocities/groundspeed-kt",1).setDoubleValue(vv*1.94384);
    }
    lvx = vx;
    lvy = vy;
    lvz = vz;
    ltime=curtime;
}

var VSD_Device =
{
#
# create new VSD device. This is the main interface (from our code) to the VSD device
# Each VSD device will contain the underlying PFD device object, the SVG, and the canvas
# Parameters
# - designation - Flightdeck Legend for this
# - model_element - name of the 3d model element that is to be used for drawing
    new : func(designation, model_element, target_module_id, root_node)
    {
#print(designation," root ",root_node.getPath());
        var obj = {parents : [VSD_Device] };
        obj.designation = designation;
        obj.model_element = model_element;
        obj.root_node = root_node;
        obj.target_module_id = target_module_id;
        obj.dev_canvas= canvas.new({
                "name": designation,
                    "size": [1024,1024], 
                    "view": [276,278],                       
                    "mipmapping": 1     
            });                          
    obj.placement = nil;
    obj.bindDisplay(target_module_id, model_element);

    obj.bindProperties(designation, root_node);

        obj.dev_canvas.setColorBackground(0.0039215686274509803921568627451,0.17647058823529411764705882352941,0, 0.00);
# Create a group for the parsed elements
        obj.VSDsvg = obj.dev_canvas.createGroup();
        var pres = canvas.parsesvg(obj.VSDsvg, "Aircraft/F-15/Nasal/VSD/VSD.svg");
# Parse an SVG file and add the parsed elements to the given group
        printf("VSD : %s Load SVG %s",designation,pres);
        obj.VSDsvg.setTranslation(10,5);
#
# create the object that will control all of this
        obj.window1 = obj.VSDsvg.getElementById("window-1");
        obj.window1.setFont("condensed.txf").setFontSize(12, 1.2);
        obj.window2 = obj.VSDsvg.getElementById("window-2");
        obj.window2.setFont("condensed.txf").setFontSize(12, 1.2);
        obj.window3 = obj.VSDsvg.getElementById("window-3");
        obj.window3.setFont("condensed.txf").setFontSize(12, 1.2);
        obj.window4 = obj.VSDsvg.getElementById("window-4");
        obj.window4.setFont("condensed.txf").setFontSize(12, 1.2);
        obj.acue = obj.VSDsvg.getElementById("ACUE");
        obj.acue.setFont("condensed.txf").setFontSize(12, 1.2);
        obj.acue.setText ("A");
        obj.acue.setVisible(0);
        obj.ecue = obj.VSDsvg.getElementById("ECUE");
        obj.ecue.setFont("condensed.txf").setFontSize(12, 1.2);
        obj.ecue.setText ("E");
        obj.ecue.setVisible(0);
        obj.morhcue = obj.VSDsvg.getElementById("MORHCUE");
        obj.morhcue.setFont("condensed.txf").setFontSize(12, 1.2);
        obj.morhcue.setText ("mh");
        obj.morhcue.setVisible(0);
        obj.max_symbols = 21;
        obj.tgt_symbols =  setsize([], obj.max_symbols);
        obj.horizon_line = obj.VSDsvg.getElementById("horizon_line");
        obj.nofire_cross =  obj.VSDsvg.getElementById("nofire_cross");
        obj.target_circle = obj.VSDsvg.getElementById("target_circle");
        obj.nofire_cross.setVisible(0);
        obj.target_circle.setVisible(0);
        for (var i = 0; i < obj.max_symbols; i += 1)
        {
            var name = "target_friendly_"~i;
            var tgt = obj.VSDsvg.getElementById(name);
            if (tgt != nil)
            {
                obj.tgt_symbols[i] = tgt;
                tgt.setVisible(0);
            }
            else
              print("F-15: VSD: Missing symbol from VSD.svg: "~name);
        }

        obj.vsd_on = 1;
        obj.process_targets = PartitionProcessor.new("VSD-radar", 20, nil);
        obj.process_targets.set_max_time_usec(500);

        obj.process_display = PartitionProcessor.new("VSD-display", 100, nil);
        obj.process_display.set_max_time_usec(500);

        var pitch_offset = 12;
        var pitch_factor = 1.98;
        obj.update_items = 
          [
           props.UpdateManager.FromHashList(["OrientationPitchDeg","roll"], 0.025, func(notification)
                                            {
                                                obj.horizon_line.setTranslation (0.0, notification.OrientationPitchDeg * pitch_factor+pitch_offset);                                           
                                                obj.horizon_line.setRotation (notification.OrientationRollDeg * DTOR);
                                            }
                                           ),

           props.UpdateManager.FromHashValue("target_display", 0.025, func(target_display)
                                             {   
                                                 #       window3.setText (sprintf("%s: %3.1f", getprop("sim/model/f15/instrumentation/radar-awg-9/hud/target"), getprop("sim/model/f15/instrumentation/radar-awg-9/hud/distance")));
                                                 if (target_display) {
                                                     obj.nofire_cross.setVisible(1);
                                                     obj.target_circle.setVisible(1);
                                                 } else {
                                                     #       window3.setText ("");
                                                     obj.nofire_cross.setVisible(0);
                                                     obj.target_circle.setVisible(0);
                                                 }
                                             }
                                            ),

           props.UpdateManager.FromHashList(["radar2_range"], 0.025, func(notification)
                                            {
                                                obj.window4.setText (sprintf("%3d", notification.radar2_range));
                                            }
                                           ),
           props.UpdateManager.FromHashValue("w1", nil, func(val)
                                             {
                                                 obj.window1.setText(val);
                                             }
                                            ),
           props.UpdateManager.FromHashValue("w2", nil, func(val)
                                             {
                                                 obj.window2.setText(val);
                                             }
                                            ),
           props.UpdateManager.FromHashValue("w3", nil, func(val)
                                             {
                                                 obj.window3.setText(val);
                                             }
                                            ),
          ];
        return obj;
    },
    bindProperties: func(designation, root_node)
    {
        input = {
               OrientationHeadingDeg  : "orientation/heading-deg",
               OrientationPitchDeg    : "orientation/pitch-deg",
               OrientationRollDeg     : "orientation/roll-deg",
               GroundspeedKts         : "velocities/groundspeed-kt",
               radar2_range           : "instrumentation/radar/radar2-range",
               target_display         : "sim/model/f15/instrumentation/radar-awg-9/hud/target-display",
               vc_kts                 : "instrumentation/airspeed-indicator/true-speed-kt",
                };

        print("F-15VSD: new, using root ",root_node.getPath());
        foreach (var name; keys(input)) {
            emesary.GlobalTransmitter.NotifyAll(notifications.FrameNotificationAddProperty.new(designation, name, input[name], root_node));
        }
    },
    bindDisplay : func (target_module_id, model_element){
        if (me.placement != nil){
            var pnode = me.placement.getNode("module-id");
if (pnode == nil) return;
#            print("VSD: rebind ",pnode.getValue(), " -> ", target_module_id);
            pnode.setValue(target_module_id);
            return;
          }
        if (target_module_id != nil){
            print("Backseat VSD ",target_module_id);
            me.placement = me.dev_canvas.addPlacement({
                                     "module-id": target_module_id,
                                   type: "scenery-object",
                                     "node": model_element
                                    });
        } else {
            print("Front seat VSD");
            me.placement = me.dev_canvas.addPlacement({
                                     "node": model_element
                                    });
        }
    } ,

 addPages : func
    {
    },

 update : func(notification) {
     if (!me.vsd_on)
       return;
     
     #        var roll_rad = -notification.OrientationRollDeg*3.14159/180.0;

     if (notification["Timestamp"] != nil)
         me.process_targets.set_timestamp(notification.Timestamp);

     me.process_targets.process(me, awg_9.tgts_list, 
                                func(pp, obj, data){
                                    obj.target_idx=1;
                                    obj.designated = 0;
                                    obj.active_found = 0;
                                    obj.searchCallsign = nil;
                                    if (awg_9.active_u != nil and awg_9.active_u.Callsign != nil)
                                      obj.searchCallsign =  awg_9.active_u.Callsign.getValue();
                                }
                                ,
                                func(pp, obj, u){
                                    if (u.get_display() == 1) {
                                        if (obj.target_idx < obj.max_symbols) {
                                            obj._tgt = obj.tgt_symbols[obj.target_idx];
                                            if (obj._tgt != nil) {
                                                #                    if (u.airbone and !designated)
                                                #                    if (obj.target_idx == 0)
                                                #                    if (awg_9.nearest_u != nil and awg_9.nearest_u.Callsign != nil and u.Callsign.getValue() == awg_9.nearest_u.Callsign.getValue())
                                                if (obj.searchCallsign != nil and u.Callsign.getValue() == obj.searchCallsign)
                                                  #if (u == awg_9.active_u)
                                                  {
                                                      obj.designated = 1;
                                                      obj.active_found = 1;
                                                      obj._tgt.setVisible(0);
                                                      obj._tgt = obj.tgt_symbols[0];
                                                      obj._tgt.setVisible(1);
                                                      #                    w2 = sprintf("%-4d", u.get_closure_rate());
                                                      #                    w3_22 = sprintf("%3d-%1.1f %.5s %.4s",u.get_bearing(), u.get_range(), callsign, model);
                                                      #                    var aspect = u.get_reciprocal_bearing()/10;
                                                      #                   w1 = sprintf("%4d %2d%s %2d %d", u.get_TAS(), aspect, aspect < 180 ? "r" : "l", u.get_heading(), u.get_altitude());
                                                  }
                                                if (notification.OrientationHeadingDeg == nil or notification.OrientationPitchDeg == nil)
                                                  print("VSD: can't display target (a) h=",notification.OrientationHeadingDeg, " p=",notification.OrientationPitchDeg);
                                                else {
                                                    obj._xc = u.get_deviation(notification.OrientationHeadingDeg) or 0;
                                                    obj._yc = -u.get_total_elevation(notification.OrientationPitchDeg) or 0;
                                                    #tgt.setVisible(1);
                                                    obj._tgt.setTranslation (obj._xc*1.55, obj._yc*1.85); #Leto: the factors is to let display correspond to 120 degrees wide and height.
                                                    obj._tgt.setVisible(1);
                                                    obj._tgt.update();
                                                }
                                                #tgt.setCenter (118,830 - notification.OrientationPitchDeg * pitch_factor-pitch_offset);
                                                #tgt.setRotation (roll_rad);
                                            }
                                        }
                                        if (!obj.designated)
                                          obj.target_idx = obj.target_idx+1;
                                        obj.designated = 0;
                                    }
                                    if (obj.target_idx >= obj.max_symbols and (obj.searchCallsign == nil or obj.active_found)) { 
#                                        print("VSD: break before end of list");
                                        return 0;
                                    }
                                    return 1;
                                },
                                func(pp, obj, data)
                                {
                                    if (awg_9.active_u != nil and awg_9.active_u.Callsign != nil)
                                      obj.searchCallsign =  awg_9.active_u.Callsign.getValue();
                         
                                    if (obj.active_found == 0) {
                                        obj.tgt_symbols[0].setVisible(0);
                                    }
                                    for (var nv = obj.target_idx; nv < obj.max_symbols;nv += 1) {
                                        tgt = obj.tgt_symbols[nv];
                                        if (tgt != nil) {
                                            tgt.setVisible(0);
                                        }
                                    }
                                });
     #    if ( math.mod(notifications.frameNotification.FrameCount,2)){

     # update text at the slowest rate (when frame count is 0)
     me.notification = notification;
     if (notification["Timestamp"] != nil)
       me.process_display.set_timestamp(notification.Timestamp);
     me.process_display.process(me, me.update_items, 
                                func(pp, obj, data){
         #
         # need to calculate ground speed as this isn't transmitted.
                                    #         if (obj.target_module_id != nil)
                                    #          calc_groundspeed_kt(obj.root_node);

                                    obj._w1 = "     VS BST   MEM  ";
                                    obj._w3_22="";
                                    obj._w3_7 = sprintf("T %1.0f",obj.notification.vc_kts);
                                    obj._w2 = "";

                                    if (awg_9.active_u != nil) {
                                        if (awg_9.active_u.Callsign != nil)
                                          obj._callsign = awg_9.active_u.Callsign.getValue();
                                        
                                        obj._model = "XX";
                                        if (awg_9.active_u.ModelType != "")
                                          obj._model = awg_9.active_u.ModelType;
                                        
                                        obj._w2 = sprintf("%-4d", awg_9.active_u.get_closure_rate());
                                        obj._w3_22 = sprintf("%3d-%1.1f %.5s %.4s",awg_9.active_u.get_bearing(), awg_9.active_u.get_range(), obj._callsign, obj._model);
                                        obj._aspect = math.round(awg_9.active_u.get_aspect()/10.0);
                                        if (math.abs(obj._aspect) > 17)
                                          obj.notification.aspect_t = "H  ";
                                        else if (math.abs(obj._aspect) < 1)
                                          obj.notification.aspect_t = "T  ";
                                        else 
                                          obj.notification.aspect_t = sprintf("%2d%s", math.abs(obj._aspect), obj._aspect > 0 ? "R" : "L");
                                        obj._w1 = sprintf("%4d %3s %2d %d", awg_9.active_u.get_TAS(), obj.notification.aspect_t, awg_9.active_u.get_heading(), awg_9.active_u.get_altitude());
                                    }
                                    obj.notification.w1 = obj._w1;
                                    obj.notification.w2 = obj._w2;
                                    #    window3.setText(sprintf("G%3.0f %3s-%4s%s %s %s",
                                    obj.notification.w3 = sprintf("G%3.0f %s %s",
                                                                  obj.notification.GroundspeedKts,
                                                                  obj._w3_7 , 
                                                                  obj._w3_22);
                                }
                                ,
                                func(pp, obj, update_item){
                                    update_item.update(obj.notification);
                                    return 1;
                                }
                                ,
                                func(pp, obj, data){});
 }
};

var VSD_array = [];

# update only one display per frame to reduce load. This can easily be changed
# to update all by looping around all of the displays in the VSD_array
var VSD_frame_device_update_id = 0;

var VSD=nil;

var ModelEventsRecipient =
{
    new: func(_ident)
    {
        var new_class = emesary.Recipient.new(_ident);
        new_class.Receive = func(notification)
        {
            if (notification.NotificationType == "FrameNotification")
            {
                if (!size(VSD_array))
                  return;

                if (VSD_frame_device_update_id >= size(VSD_array))
                  VSD_frame_device_update_id = 0;

                if (VSD_frame_device_update_id < size(VSD_array))
                  VSD_array[VSD_frame_device_update_id].update(notification);

                VSD_frame_device_update_id += 1;
            }
            else if (notification.NotificationType == "F15Model")
            {
                root_node = props.globals;
                print("F15D receive model notification",notification.NotificationType," V=",notification.Ident);
                if (notification.root_node != nil) {
                    print("F-15VSD: Using path ",notification.root_node.getPath());
                    root_node = notification.root_node;
                }
                #
                # 
                # Create and append all of the VSDs in the cockpit.
                # - VSD_Device.new( Identity, Canvas3dSurface, model index)
                #                 
                var designation = "F-15 VSD";
                var textureImage = "VSDImage";
                if (!size(VSD_array)) {
                    VSD = VSD_Device.new(designation, textureImage, notification.Ident, root_node);
                    append(VSD_array, VSD);
                    print("VSD initialization finished ",notification.Ident);
                }
                else  {
                    foreach (var vsd; VSD_array) {
                        vsd.bindDisplay(notification.Ident, textureImage);
                        vsd.bindProperties(designation, root_node);
                    }
                }

                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        return new_class;
    },
};

emesary.GlobalTransmitter.Register(ModelEventsRecipient.new("F15-VSD"));
