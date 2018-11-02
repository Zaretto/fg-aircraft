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

        var pitch_offset = 12;
        var pitch_factor = 1.98;
        obj.update_items = 
          [
           props.UpdateManager.FromHashList(["pitch","roll"], 0.025, func(notification)
                                            {
                                                obj.horizon_line.setTranslation (0.0, notification.pitch * pitch_factor+pitch_offset);                                           
                                                obj.horizon_line.setRotation (notification.roll * DTOR);
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
               pitch:  "orientation/pitch-deg",
               roll:  "orientation/roll-deg",
                 #               altitude:  "position/altitude-ft",
               heading:  "orientation/heading-deg",
               target_display:  "sim/model/f15/instrumentation/radar-awg-9/hud/target-display",
               radar2_range: "instrumentation/radar/radar2-range",
#               vc_kts:  "velocities/groundspeed-kt",
               vc_kts:  "instrumentation/airspeed-indicator/true-speed-kt",
               groundspeed_kt: "velocities/groundspeed-kt"
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
     
     #        var roll_rad = -notification.roll*3.14159/180.0;

     var target_idx=1;

     # do this every fourth frame. this is primarily for optimisation however it is conceivably like this
     # in the aircraft because of the lag between the computers on the 1553 bus.
     if ( !math.mod(notifications.frameNotification.FrameCount,4)) {

         var designated = 0;
         var active_found = 0;
         foreach ( u; awg_9.tgts_list ) {
             if (u.get_display() == 1) {
                 var callsign = "XX";
                 if (u.Callsign != nil)
                   callsign = u.Callsign.getValue();
                 var model = "XX";
                 if (u.ModelType != "")
                   model = u.ModelType;
                 if (target_idx < me.max_symbols) {
                     tgt = me.tgt_symbols[target_idx];
                     if (tgt != nil) {
                         #                    if (u.airbone and !designated)
                         #                    if (target_idx == 0)
                         #                    if (awg_9.nearest_u != nil and awg_9.nearest_u.Callsign != nil and u.Callsign.getValue() == awg_9.nearest_u.Callsign.getValue())
                         if (awg_9.active_u != nil and awg_9.active_u.Callsign != nil and u.Callsign.getValue() == awg_9.active_u.Callsign.getValue())
                           #if (u == awg_9.active_u)
                           {
                               designated = 1;
                               active_found = 1;
                               tgt.setVisible(0);
                               tgt = me.tgt_symbols[0];
                               tgt.setVisible(1);
                               #                    w2 = sprintf("%-4d", u.get_closure_rate());
                               #                    w3_22 = sprintf("%3d-%1.1f %.5s %.4s",u.get_bearing(), u.get_range(), callsign, model);
                               #                    var aspect = u.get_reciprocal_bearing()/10;
                               #                   w1 = sprintf("%4d %2d%s %2d %d", u.get_TAS(), aspect, aspect < 180 ? "r" : "l", u.get_heading(), u.get_altitude());
                           }
                         if (notification.heading == nil or notification.pitch == nil)
                           print("VSD: can't display target (a) h=",notification.heading, " p=",notification.pitch);
                         else {
                             var xc = u.get_deviation(notification.heading);
                             var yc = -u.get_total_elevation(notification.pitch);
                             if (xc == nil or yc == nil)
                               print("VSD: can't display target (b) xc=",xc, " yc=",yc);
                             else {
                                 #tgt.setVisible(1);
                                 tgt.setTranslation (xc*1.55, yc*1.85); #Leto: the factors is to let display correspond to 120 degrees wide and height.
                                 tgt.setVisible(1);
                                 tgt.update();
                             }
                         }
                         #tgt.setCenter (118,830 - notification.pitch * pitch_factor-pitch_offset);
                         #tgt.setRotation (roll_rad);
                     }
                 }
                 if (!designated)
                   target_idx = target_idx+1;
                 designated = 0;
             }
         }
         if (active_found == 0) {
             me.tgt_symbols[0].setVisible(0);
         }
         for (var nv = target_idx; nv < me.max_symbols;nv += 1) {
             tgt = me.tgt_symbols[nv];
             if (tgt != nil) {
                 tgt.setVisible(0);
             }
         }
     }
     #    if ( math.mod(notifications.frameNotification.FrameCount,2)){

     # update text at the slowest rate (when frame count is 0)
     if ( !notifications.frameNotification.FrameCount) {
         #
         # need to calculate ground speed as this isn't transmitted.
         if (me.target_module_id != nil)
           calc_groundspeed_kt(me.root_node);

         var w1 = "     VS BST   MEM  ";
         var w3_22="";
         var w3_7 = sprintf("T %1.0f",notification.vc_kts);
         var w2 = "";

         if (awg_9.active_u != nil) {
             if (awg_9.active_u.Callsign != nil)
               callsign = awg_9.active_u.Callsign.getValue();

             var model = "XX";
             if (awg_9.active_u.ModelType != "")
               model = awg_9.active_u.ModelType;

             w2 = sprintf("%-4d", awg_9.active_u.get_closure_rate());
             w3_22 = sprintf("%3d-%1.1f %.5s %.4s",awg_9.active_u.get_bearing(), awg_9.active_u.get_range(), callsign, model);
             var aspect = awg_9.active_u.get_reciprocal_bearing()/10;
             w1 = sprintf("%4d %2d%s %2d %d", awg_9.active_u.get_TAS(), aspect, aspect < 180 ? "r" : "l", awg_9.active_u.get_heading(), awg_9.active_u.get_altitude());
         }
         notification.w1 = w1;
         notification.w2 = w2;
         #    window3.setText(sprintf("G%3.0f %3s-%4s%s %s %s",
         notification.w3 = sprintf("G%3.0f %s %s",
                                   notification.groundspeed_kt,
                                   w3_7 , 
                                   w3_22);
     }
     #
     # the rest we can update every frame as they use the property manager.
     foreach (var update_item; me.update_items) {
         update_item.update(notification);
     }
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

emesary.GlobalTransmitter.Register(ModelEventsRecipient.new("F15D-backseat"));
