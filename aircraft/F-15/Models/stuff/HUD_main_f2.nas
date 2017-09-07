# Canvas HUD
# ---------------------------
# HUD uses data in the frame notification
# HUD is in two parts so we have a single class that we can instantiate
# twice on for each combiner pane
# ---------------------------
# Richard Harrison (rjh@zaretto.com) 2017-17-01  
# ---------------------------

var ht_xcf = 1024;
var ht_ycf = -1024;
var ht_xco = 0;
var ht_yco = -30;
var ht_debug = 0;

var pitch_offset = 12;
var pitch_factor = 19.8;
var pitch_factor_2 = pitch_factor * 180.0 / 3.14159;
var alt_range_factor = (9317-191) / 100000; # alt tape size and max value.
var ias_range_factor = (694-191) / 1100;

var TORNADO_HUD = {
	new : func (svgname, canvas_item, sx, sy, tran_x,tran_y){
		var obj = {parents : [TORNADO_HUD] };

        obj.canvas= canvas.new({
                "name": "Tornado HUD",
                    "size": [1024,1024], 
                    "view": [sx,sy],
                    "mipmapping": 1     
                    });                          
                          
        obj.canvas.addPlacement({"node": canvas_item});
        obj.canvas.setColorBackground(0.36, 1, 0.3, 0.00);

# Create a group for the parsed elements
        obj.svg = obj.canvas.createGroup();
 
# Parse an SVG file and add the parsed elements to the given group
        print("HUD Parse SVG ",canvas.parsesvg(obj.svg, svgname));

        obj.canvas._node.setValues({
                "name": "Tornado HUD",
                    "size": [1024,1024], 
                    "view": [sx,sy],
                    "mipmapping": 0     
                    });

        obj.svg.setTranslation (tran_x,tran_y);

        obj.ladder = obj.get_element("ladder");
        obj.VV = obj.get_element("VelocityVector");
        obj.heading_tape = obj.get_element("heading-scale");
        obj.roll_pointer = obj.get_element("roll-pointer");
        obj.alt_range = obj.get_element("alt_range");
        obj.ias_range = obj.get_element("ias_range");

        obj.target_locked = obj.get_element("target_locked");
        obj.target_locked.setVisible(0);

        obj.window1 = obj.get_text("window1", "condensed.txf",9,1.4);
        obj.window2 = obj.get_text("window2", "condensed.txf",9,1.4);
        obj.window3 = obj.get_text("window3", "condensed.txf",9,1.4);
        obj.window4 = obj.get_text("window4", "condensed.txf",9,1.4);
        obj.window5 = obj.get_text("window5", "condensed.txf",9,1.4);
        obj.window6 = obj.get_text("window6", "condensed.txf",9,1.4);
        obj.window7 = obj.get_text("window7", "condensed.txf",9,1.4);
        obj.window8 = obj.get_text("window8", "condensed.txf",9,1.4);
        obj.window9 = obj.get_text("window9", "condensed.txf",9,1.4);

        obj.window2.setVisible(0);
        obj.window3.setText("");
        obj.window4.setText("");
        obj.window6.setVisible(0);

        obj.max_symbols = 10;
        obj.tgt_symbols =  setsize([],obj.max_symbols);

        for (var i = 0; i < obj.max_symbols; i += 1)
        {
            var name = "target_"~i;
            var tgt = obj.svg.getElementById(name);
            if (tgt != nil)
            {
                obj.tgt_symbols[i] = tgt;
                tgt.setVisible(0);
            }
            else
                print("HUD: could not locate ",name);
        }
        #
        # set the update list - using the update manager to improve the performance
        # of the HUD update - without this there was a drop of 20fps (when running at 60fps)
        obj.update_items = [
            PropertyUpdateManager.newFromHashList(["VV_x","VV_y"], 0.01, func(val)
                                      {
                                        obj.VV.setTranslation (val.VV_x, val.VV_y + pitch_offset);
                                      }),
            PropertyUpdateManager.newFromHashList(["pitch","roll"], 0.025, func(hdp)
                                      {
                                          obj.ladder.setTranslation (0.0, hdp.pitch * pitch_factor+pitch_offset);                                           
                                          obj.ladder.setCenter (118,830 - hdp.pitch * pitch_factor-pitch_offset);
                                          obj.ladder.setRotation (-hdp.roll_rad);
                                          obj.roll_pointer.setRotation (hdp.roll_rad);
                                      }),
#            PropertyUpdateManager.newFromHashValue("roll_rad", 1.0, func(roll_rad)
#                                      {
#                                      }),
            PropertyUpdateManager.newFromHashValue("measured_altitude", 1.0, func(measured_altitude)
                                      {
                                          obj.alt_range.setTranslation(0, measured_altitude * alt_range_factor);
                                      }),
            PropertyUpdateManager.newFromHashValue("IAS", 0.1, func(IAS)
                                      {
                                          obj.ias_range.setTranslation(0, IAS * ias_range_factor);
                                      }),
            PropertyUpdateManager.newFromHashValue("range_rate", 0.01, func(range_rate)
                                      {
                                          if (range_rate != nil) {
                                              obj.window1.setVisible(1);
                                              obj.window1.setText("");
                                          } else
                                            obj.window1.setVisible(0);
                                      }
                                             ),
            PropertyUpdateManager.newFromHashValue("Nz", 0.1, func(Nz)
                                      {
                                            obj.window8.setText(sprintf("%02d", Nz*10));
                                      }),
            PropertyUpdateManager.newFromHashValue("heading", 0.1, func(heading)
                                      {
                                          if (heading < 180)
                                              obj.heading_tape_position = -heading*5.4;
                                          else
                                              obj.heading_tape_position = (360-heading)*5.4;
     
                                          obj.heading_tape.setTranslation (obj.heading_tape_position,0);
                                      }),
            PropertyUpdateManager.newFromHashList(["brake_parking", "gear_down", "flap_pos_deg"], 0.1, func(hdp)
                                      {
                                          if(hdp.brake_parking)
                                          {
                                              obj.window7.setVisible(1);
                                              obj.window7.setText("BRAKES");
                                          }
                                          else if (hdp.flap_pos_deg > 0 or hdp.gear_down)
                                          {
                                              obj.window7.setVisible(1);
                                              var gd = "";
                                              if (hdp.gear_down)
                                                  gd = " G";
                                              obj.window7.setText(sprintf("F %d %s",hdp.flap_pos_deg,gd));
                                          } else
                                              obj.window7.setVisible(0);
                                      }),
            PropertyUpdateManager.newFromHashValue("alpha", 1, func(alpha)
                                      {
                                          obj.window9.setText(sprintf("AOA %d",alpha));
                                      }),
            PropertyUpdateManager.newFromHashValue("nav_range", nil, func(nav_range)
                                      {
                                        if (nav_range != "")
                                            obj.window3.setText("NAV");
                                        else
                                            obj.window3.setText("");
                                        obj.window4.setText(nav_range);
                                      }),
            PropertyUpdateManager.newFromHashValue("hud_window5", nil, func(hud_window5)
                                      {
                                          obj.window5.setText(hud_window5);
                                      }),

        ];
		return obj;
	},
#
#
# get a text element from the SVG and set the font / sizing
    get_text : func(id, font, size, ratio)
    {
        var el = me.svg.getElementById(id);
        el.setFont(font).setFontSize(size,ratio);
        return el;
    },

#
#
# Get an element from the SVG; handle errors; and apply clip rectangle
# if found (by naming convention : addition of _clip to object name).
    get_element : func(id) {
        var el = me.svg.getElementById(id);
        if (el == nil)
        {
            print("Failed to locate ",id," in SVG");
            return el;
        }
        var clip_el = me.svg.getElementById(id ~ "_clip");
        if (clip_el != nil)
        {
            clip_el.setVisible(0);
            var tran_rect = clip_el.getTransformedBounds();

            var clip_rect = sprintf("rect(%d,%d, %d,%d)", 
                                   tran_rect[1], # 0 ys
                                   tran_rect[2],  # 1 xe
                                   tran_rect[3], # 2 ye
                                   tran_rect[0]); #3 xs
#            print(id," using clip element ",clip_rect, " trans(",tran_rect[0],",",tran_rect[1],"  ",tran_rect[2],",",tran_rect[3],")");
#   see line 621 of simgear/canvas/CanvasElement.cxx
#   not sure why the coordinates are in this order but are top,right,bottom,left (ys, xe, ye, xs)
            el.set("clip", clip_rect);
            el.set("clip-frame", canvas.Element.PARENT);
        }
        return el;
    },

#
#
#
    update : func(hdp) {
        foreach(var update_item; me.update_items)
        {
            update_item.update(hdp);
        }
    },
    list: [],
};

#
# The Tornado HUD is provided by 2 combiners.
# We model this accurately by having two instances of the HUD
# 2015-01-27: Note that the geometry isn't right and the projection needs to be adjusted (somehow) as the
# image elements in the 3d model are correctly angled and this results in trapezoidal distortion

#aircraft.UpperHUD.svg.setTranslation (-21.0, 37.0);
#aircraft.LowerHUD.svg.setTranslation (-21.0, -106);
#aircraft.tornado_hud.UpperHUD.canvas._node.setValues({
#                           "name": "Tornado HUD",
#                           "size": [1024,1024], 
#                           "view": [238,100],                       
#                           "mipmapping": 10  
#  });
#aircraft.tornado_hud.LowerHUD.canvas._node.setValues({
#                           "name": "Tornado HUD",
#                           "size": [1024,1024], 
#                           "view": [260,216],                       
#                          "mipmapping": 10  
#  });
#aircraft.tornado_hud.UpperHUD.svg.setTranslation (-35, 25);
#aircraft.tornado_hud.LowerHUD.svg.setTranslation (-27,-0);
var TornadoHudRecipient = 
{
    new: func(_ident)
    {
        var new_class = emesary.Recipient.new(_ident~".HUD");
#        new_class.UpperHUD = TORNADO_HUD.new("Nasal/HUD/HUD.svg", "HUDImage1", 238,100, -35, 25);
        new_class.LowerHUD = TORNADO_HUD.new("Nasal/HUD/HUD.svg", "HUDImage", 256, 260, 10,50);

        new_class.Receive = func(notification)
        {
            if (notification == nil)
            {
                print("bad notification nil");
                return emesary.Transmitter.ReceiptStatus_NotProcessed;
            }

            if (notification.NotificationType == "FrameNotification")
            {
                me.LowerHUD.update(notification);
                return emesary.Transmitter.ReceiptStatus_OK;
            }
            return emesary.Transmitter.ReceiptStatus_NotProcessed;
        };
        return new_class;
    },
};
#TornadoHudRecipient.new("Panavia-Tornado-HUD");
tornado_hud = TornadoHudRecipient.new("Panavia-Tornado-HUD");
LowerHUD = tornado_hud.LowerHUD;

emesary.GlobalTransmitter.Register(tornado_hud);
