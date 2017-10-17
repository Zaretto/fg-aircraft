# F-15 Canvas HUD
# ---------------------------
# HUD class has dataprovider
# F-15C HUD is in two parts so we have a single class that we can instantiate
# twice on for each combiner pane
# ---------------------------
# Richard Harrison (rjh@zaretto.com) 2015-01-27  - based on F-20 HUD main module Enrique Laso (Flying toaster) 
# ---------------------------

var ht_xcf = 1024;
var ht_ycf = -1024;
var ht_xco = 0;
var ht_yco = 0;
var ht_debug = 0;

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

# paste into nasal console for debugging
#aircraft.MainHUD.canvas._node.setValues({
#                           "name": "F-15 HUD",
#                           "size": [1024,1024], 
#                           "view": [276,106],                       
#                           "mipmapping": 0     
#  });
#aircraft.MainHUD.svg.setTranslation (0, 20.0);
#aircraft.MainHUD.svg.set("clip", "rect(2,256,276,0)");
#aircraft.MainHUD.svg.setTranslation (-21.0, 37.0);
#aircraft.MainHUD.svg.set("clip", "rect(1,256,276,0)");
#aircraft.MainHUD.svg.set("clip", "rect(10,256,276,0)");
#aircraft.MainHUD.svg.set("clip-frame", canvas.Element.PARENT);

var pitch_factor=11.18;

var alt_range_factor = (9317-191) / 100000; # alt tape size and max value.
var ias_range_factor = (694-191) / 1100;

#Pinto: if you know starting x (left/right) and z (up/down), then i just do
#
#var changeViewX = -1 * (startViewX-getprop(viewX))*getprop(ghosting_x);
#var changeViewY = (startViewY-getprop(viewY))*getprop(ghosting_y);
#
#where ghosting_x and ghosting_y are parallax adjusting. about 7000
# trial and error can quickly give you the right values. Then I move the canvas elements by however much changeViewX and changeViewY are.
# calc of pitch_offset (compensates for AC3D model translated and rotated when loaded. Also semi compensates for HUD being at an angle.)
#        var Hz_b =    0.80643; # HUD position inside ac model after it is loaded translated and rotated.
#        var Hz_t =    0.96749;
#        var Vz   =    getprop("sim/current-view/y-offset-m"); # view Z position (0.94 meter per default)
#
#        var bore_over_bottom = Vz - Hz_b;
#        var Hz_height        = Hz_t-Hz_b;
#        var hozizon_line_offset_from_middle_in_svg = 0.137; #fraction up from middle
#        var frac_up_the_hud = bore_over_bottom / Hz_height - hozizon_line_offset_from_middle_in_svg;
#       var texels_up_into_hud = frac_up_the_hud * me.sy;#sy default is 260
#       var texels_over_middle = texels_up_into_hud - me.sy/2;
#
#
#        pitch_offset = -texels_over_middle;

#var changeViewX = -1 * (startViewX-getprop(viewX))*getprop(ghosting_x);
#var changeViewY = (startViewY-getprop(viewY))*getprop(ghosting_y);

var F15HUD = {
	new : func (svgname){
		var obj = {parents : [F15HUD] };

        obj.canvas= canvas.new({
                "name": "F-15 HUD",
                    "size": [1024,1024], 
                    "view": [256,296],
                    "mipmapping": 0,
                    });                          
        obj.view = [0, 1.4000051983, -5];                          
        obj.canvas.addPlacement({"node": "HUDImage1"});
        obj.canvas.addPlacement({"node": "HUDImage2"});
        obj.canvas.setColorBackground(0.36, 1, 0.3, 0.00);
        obj.FocusAtInfinity = false;
# Create a group for the parsed elements
        obj.svg = obj.canvas.createGroup();
 
# Parse an SVG file and add the parsed elements to the given group
        print("HUD Parse SVG ",canvas.parsesvg(obj.svg, svgname));

        obj.canvas._node.setValues({
                                    "name": "F-15 HUD",
                                    "size": [1024,1024], 
                                    "view": [256,296],                       
                                    "mipmapping": 0     
                    });
        obj.baseTranslation = [30,30];
        obj.svg.setTranslation (obj.baseTranslation[0], obj.baseTranslation[1]);
        obj.svg.set("clip", "rect(11,256,296,0)");
        obj.svg.set("clip-frame", canvas.Element.PARENT);
        obj.svg.setScale(0.8,1.18);

        obj.ladder = obj.get_element("ladder");
        obj.ladder.setScale(1,0.558);

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

        obj.window1.setVisible(0);

        obj.radarActiveTargetAvailable = props.globals.getNode("sim/model/f15/instrumentation/radar-awg-9/active-target-available",1);
        obj.radarActiveTargetCallsign = props.globals.getNode("sim/model/f15/instrumentation/radar-awg-9/active-target-callsign",1);
        obj.radarActiveTargetType = props.globals.getNode("sim/model/f15/instrumentation/radar-awg-9/active-target-type",1);
        obj.radarActiveTargetRange = props.globals.getNode("sim/model/f15/instrumentation/radar-awg-9/active-target-range",1);
        obj.radarActiveTargetClosure = props.globals.getNode("sim/model/f15/instrumentation/radar-awg-9/active-target-closure",1);
        obj.navRangeDisplay = props.globals.getNode("sim/model/f15/instrumentation/hud/nav-range-display",1);
        obj.navRangeETA = props.globals.getNode("sim/model/f15/instrumentation/hud/nav-range-eta",1);

        obj.radarActiveTargetAvailable.setValue(0);
        obj.radarActiveTargetCallsign.setValue("");
        obj.radarActiveTargetType.setValue("");
        obj.radarActiveTargetRange.setValue(0);
        obj.radarActiveTargetClosure.setValue(0);
        obj.navRangeDisplay.setValue("");
        obj.navRangeETA.setValue("");

        obj.symbol_reject = 0;
        obj.heading_deg=0;
        obj.roll_deg=0;
        obj.roll_rad=0;
        obj.pitch_deg=0;
        obj.VV_x=0;
        obj.VV_y=0;
        obj.mach=0;
        obj.rng=0;
        obj.eta_s=0;
#
#
# Load the target symbosl.
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
#                print("HUD: loaded ",name);
            }
            else
                print("HUD: could not locate ",name);
        }
       
            obj.dlzX      =170;
            obj.dlzY      =100;
            obj.dlzWidth  = 10;
            obj.dlzHeight = 90;
obj.dlzHeight=60;
obj.dlzY = 70;
            obj.dlzLW     =  1;
            obj.dlz      = obj.svg.createChild("group");
            obj.dlz2     = obj.dlz.createChild("group");
            obj.dlzArrow = obj.dlz.createChild("path")
                           .moveTo(0, 0)
                           .lineTo( -5, 4)
                           .moveTo(0, 0)
                           .lineTo( -5, -4)
                           .setColor(0,1,0)
                           .setStrokeLineWidth(obj.dlzLW);

        #
        #
        # using the new property manager to update items on the HUD.
        # this is more efficient as the update methods are only called whenever the property (or properties) change by more than a specified amount
        obj.update_items = [
            props.UpdateManager.FromPropertyHashList(["fdm/jsbsim/systems/electrics/ac-left-main-bus","sim/model/f15/controls/HUD/brightness"] , 0.01, func(val)
                                      {
                                          if (val.property["fdm/jsbsim/systems/electrics/ac-left-main-bus"].getValue() <= 0 
                                              or val.property["sim/model/f15/controls/HUD/brightness"].getValue() <= 0) {
                                              obj.svg.setVisible(0);
                                          } else {
                                              obj.svg.setVisible(1);
                                          }
                                      }),
            props.UpdateManager.FromProperty("instrumentation/altimeter/indicated-altitude-ft", 1, func(val)
                                             {
                                                 obj.alt_range.setTranslation(0, val * alt_range_factor);
                                             }),

            props.UpdateManager.FromProperty("velocities/airspeed-kt", 0.1, func(val)
                                      {
                                          obj.ias_range.setTranslation(0, val * ias_range_factor);
                                      }),
            props.UpdateManager.FromProperty("sim/model/f15/controls/HUD/sym-rej", 0.1, func(val)
                                             {
                                                 obj.symbol_reject = val;
                                             }),
            props.UpdateManager.FromProperty("orientation/heading-deg", 0.025, func(val)
                                      {
                                          obj.heading_deg = val;
                                          #heading tape
                                          if (val < 180)
                                            obj.heading_tape_position = -val*54/10;
                                          else
                                            obj.heading_tape_position = (360-val)*54/10;
                                          
                                          obj.heading_tape.setTranslation (obj.heading_tape_position,0);
                                      }),
            props.UpdateManager.FromPropertyHashList(["orientation/roll-deg","orientation/pitch-deg"], 0.025, func(val)
                                    {
                                        obj.roll_deg = val.property["orientation/roll-deg"].getValue();
                                        obj.roll_rad = -obj.roll_deg*3.14159/180.0;
                                        obj.roll_pointer.setRotation (obj.roll_rad);
                                        var ptx = 0;
                                        obj.pitch_deg = val.property["orientation/pitch-deg"].getValue();
                                        var pty = 392+ obj.pitch_deg * pitch_factor;

                                        obj.ladder.setRotation(obj.roll_rad);
                                        obj.ladder.setTranslation(ptx,pty);

                                        if (obj.pitch_deg>0)
                                          obj.ladder.setCenter (110,900-obj.pitch_deg*(1815/90));
                                        else
                                          obj.ladder.setCenter (110,900+obj.pitch_deg*-(1772/90));
                                    }),
                            props.UpdateManager.FromPropertyHashList(["orientation/alpha-indicated-deg", "orientation/side-slip-deg"], 0.001, func(val)
                                                                     {
                                                                         obj.VV_x = val.property["orientation/side-slip-deg"].getValue()*10; # adjust for view
                                                                         obj.VV_y = val.property["orientation/alpha-indicated-deg"].getValue()*10; # adjust for view
                                                                         obj.VV.setTranslation (obj.VV_x, obj.VV_y);
                                                                     }),
                            props.UpdateManager.FromPropertyHashList(["sim/model/f15/instrumentation/g-meter/g-max-mooving-average", "fdm/jsbsim/systems/cadc/ows-maximum-g"], 0.1, func(val)
                                                                     {
                                                                         obj.window8.setText(sprintf("%02d %02d", 
                                                                                                     val.property["sim/model/f15/instrumentation/g-meter/g-max-mooving-average"].getValue()*10, 
                                                                                                     val.property["fdm/jsbsim/systems/cadc/ows-maximum-g"].getValue()*10));
                                                                     }),
                            props.UpdateManager.FromPropertyHashList(["orientation/alpha-indicated-deg", 
                                                                      "controls/gear/brake-parking", 
                                                                      "instrumentation/airspeed-indicator/indicated-mach",
                                                                      "controls/gear/gear-down"], 0.01, func(val)
                                                                     {
                                                                         obj.alpha = val.property["orientation/alpha-indicated-deg"].getValue() or 0;
                                                                         obj.mach = val.property["instrumentation/airspeed-indicator/indicated-mach"].getValue() or 0;
                                                                         if(val.property["controls/gear/brake-parking"].getValue())
                                                                           obj.window7.setText("BRAKES");
                                                                         else if(val.property["controls/gear/gear-down"].getValue() or obj.alpha > 20)
                                                                           obj.window7.setText(sprintf("AOA %d",obj.alpha));
                                                                         else
                                                                           obj.window7.setText(sprintf(" %1.3f",obj.mach));
                                                                     }),
                            props.UpdateManager.FromPropertyHashList(["autopilot/route-manager/active",
                                                                      "autopilot/route-manager/wp/dist",
                                                                      "autopilot/route-manager/wp/eta-seconds",
                                                                      "controls/gear/gear-down"], 0.1, func(val)
                                                                     {
                                                                         if (val.property["autopilot/route-manager/active"].getValue()) {
                                                                             obj.rng = val.property["autopilot/route-manager/wp/dist"].getValue();
                                                                             obj.eta_s = val.property["autopilot/route-manager/wp/eta-seconds"].getValue();
                                                                             if (obj.rng != nil) {
                                                                                 obj.navRangeETA.setValue(sprintf("%2d MIN",obj.rng));
                                                                                 obj.navRangeDisplay.setValue(sprintf("N %4.1f", obj.rng));
                                                                             } else {
                                                                                 obj.navRangeETA.setValue("XXX");
                                                                                 obj.navRangeDisplay.setValue("N XXX");
                                                                             }

                                                                             if (obj.eta_s != nil)
                                                                               obj.navRangeETA.setValue(sprintf("%2d MIN",obj.eta_s/60));
                                                                             else
                                                                               obj.navRangeETA.setValue("XX MIN");
                                                                         } else {
                                                                             obj.navRangeDisplay.setValue("");
                                                                             obj.navRangeETA.setValue("");
                                                                         }
                                                                     }),
                            props.UpdateManager.FromPropertyHashList(["sim/model/f15/controls/armament/master-arm-switch",
                                                                      "sim/model/f15/controls/armament/weapon-selector",
                                                                      "sim/model/f15/systems/gun/rounds",
                                                                      "sim/model/f15/systems/armament/aim9/count",
                                                                      "sim/model/f15/systems/armament/aim120/count",
                                                                      "sim/model/f15/systems/armament/aim7/count",
                                                                      "sim/model/f15/instrumentation/radar-awg-9/active-target-available",
                                                                      "sim/model/f15/instrumentation/radar-awg-9/active-target-callsign",
                                                                      "sim/model/f15/instrumentation/radar-awg-9/active-target-type",
                                                                      "sim/model/f15/instrumentation/radar-awg-9/active-target-range",
                                                                      "sim/model/f15/instrumentation/radar-awg-9/active-target-closure",
                                                                      "sim/model/f15/instrumentation/hud/nav-range-display",
                                                                      "sim/model/f15/instrumentation/hud/nav-range-eta"], 0.1, func(val)
                                                                     {
                                                                         if (val.property["sim/model/f15/controls/armament/master-arm-switch"].getValue()) {
                                                                             var w_s = val.property["sim/model/f15/controls/armament/weapon-selector"].getValue();
                                                                             obj.window2.setVisible(1);
                                                                             if (w_s == 0) {
                                                                                 obj.window2.setText(sprintf("%3d",val.property["sim/model/f15/systems/gun/rounds"].getValue()));
                                                                             } else if (w_s == 1)
                                                                               {
                                                                                   obj.window2.setText(sprintf("S%dL", val.property["sim/model/f15/systems/armament/aim9/count"].getValue()));
                                                                               } else if (w_s == 2)
                                                                                 {
                                                                                     obj.window2.setText(sprintf("M%dF", val.property["sim/model/f15/systems/armament/aim120/count"].getValue()
                                                                                                                + val.property["sim/model/f15/systems/armament/aim7/count"].getValue()));
                                                                                 }
                                                                             if (val.property["sim/model/f15/instrumentation/radar-awg-9/active-target-available"].getValue() or 0) {
                                                                                 obj.window3.setText(val.property["sim/model/f15/instrumentation/radar-awg-9/active-target-callsign"].getValue());
                                                                                 var model = "XX";
                                                                                 if (val.property["sim/model/f15/instrumentation/radar-awg-9/active-target-type"].getValue() != "")
                                                                                   model = val.property["sim/model/f15/instrumentation/radar-awg-9/active-target-type"].getValue();

                                                                                 #these labels aren't correct - but we don't have a full simulation of the targetting and missiles so 
                                                                                 #have no real idea on the details of how this works.
                                                                                 obj.window4.setText(sprintf("RNG %3.1f", val.property["sim/model/f15/instrumentation/radar-awg-9/active-target-range"].getValue()));
                                                                                 obj.window5.setText(sprintf("CLO %-3d", val.property["sim/model/f15/instrumentation/radar-awg-9/active-target-closure"].getValue()));
                                                                                 obj.window6.setText(model);
                                                                                 obj.window6.setVisible(1); # SRM UNCAGE / TARGET ASPECT
                                                                             }
                                                                         } else {
                                                                             obj.window2.setVisible(0);
                                                                             if (val.property["sim/model/f15/instrumentation/hud/nav-range-display"].getValue() != "")
                                                                               obj.window3.setText("NAV");
                                                                             else
                                                                               obj.window3.setText("");
                                                                             obj.window4.setText(val.property["sim/model/f15/instrumentation/hud/nav-range-display"].getValue());
                                                                             obj.window5.setText(val.property["sim/model/f15/instrumentation/hud/nav-range-eta"].getValue());
                                                                             obj.window6.setVisible(0); # SRM UNCAGE / TARGET ASPECT
                                                                         }
                                                                     }
                                                                    ),
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
    update : func() {
        
        me.dlzArray = aircraft.getDLZ();
#me.dlzArray =[10,8,6,2,9];#test
        if (me.dlzArray == nil or size(me.dlzArray) == 0) {
                me.dlz.hide();
        } else {
            me.dlz.setTranslation(me.dlzX,me.dlzY);
            me.dlz2.removeAllChildren();
            me.dlzArrow.setTranslation(0,-me.dlzArray[4]/me.dlzArray[0]*me.dlzHeight);
            me.dlzGeom = me.dlz2.createChild("path")
                    .moveTo(0, -me.dlzArray[3]/me.dlzArray[0]*me.dlzHeight)
                    .lineTo(0, -me.dlzArray[2]/me.dlzArray[0]*me.dlzHeight)
                    .lineTo(me.dlzWidth, -me.dlzArray[2]/me.dlzArray[0]*me.dlzHeight)
                    .lineTo(me.dlzWidth, -me.dlzArray[3]/me.dlzArray[0]*me.dlzHeight)
                    .lineTo(0, -me.dlzArray[3]/me.dlzArray[0]*me.dlzHeight)
                    .lineTo(0, -me.dlzArray[1]/me.dlzArray[0]*me.dlzHeight)
                    .lineTo(me.dlzWidth, -me.dlzArray[1]/me.dlzArray[0]*me.dlzHeight)
                    .moveTo(0, -me.dlzHeight)
                    .lineTo(me.dlzWidth, -me.dlzHeight-3)
                    .lineTo(me.dlzWidth, -me.dlzHeight+3)
                    .lineTo(0, -me.dlzHeight)
                    .setStrokeLineWidth(me.dlzLW)
                    .setColor(0,1,0);
            me.dlz.show();
        }
        
        
        if(me.FocusAtInfinity)
          {
              # parallax correction
              var current_x = getprop("/sim/current-view/x-offset-m");
              var current_y = getprop("/sim/current-view/y-offset-m");
              #        var current_z = getprop("/sim/current-view/z-offset-m");
        
              var dx = me.view[0] - current_x;
              var dy = me.view[1] - current_y;
              
              me.svg.setTranslation(me.baseTranslation[0]-dx*1024, me.baseTranslation[1]+dy*1024);
          }

        if (awg_9.active_u == nil) {
            me.radarActiveTargetAvailable.setValue(0);
            me.radarActiveTargetCallsign.setValue("");
            me.radarActiveTargetType.setValue("");
            me.radarActiveTargetRange.setValue(0);
            me.radarActiveTargetClosure.setValue(0);
        } else {
            me.radarActiveTargetAvailable.setValue(1);
#print("active callsign ",awg_9.active_u.Callsign,":");
            if (awg_9.active_u.Callsign != nil)
              me.radarActiveTargetCallsign.setValue(awg_9.active_u.Callsign.getValue());
            else
              me.radarActiveTargetCallsign.setValue("XXX");

            me.radarActiveTargetType.setValue(awg_9.active_u.ModelType);
            me.radarActiveTargetRange.setValue(awg_9.active_u.get_range());
            me.radarActiveTargetClosure.setValue(awg_9.active_u.get_closure_rate());
        }

        foreach(var update_item; me.update_items)
        {
            update_item.update(me);
        }

        if (me.svg.getVisible() == 0)
          return;

     
#        if (hdp.range_rate != nil)
#        {
#            me.window1.setVisible(1);
#            me.window1.setText("");
#        }
#        else
#            me.window1.setVisible(0);
  

        var target_idx = 0;
        var designated = 0;
        me.target_locked.setVisible(0);
        foreach( u; awg_9.tgts_list ) 
        {
            var callsign = "XX";
            if(u.get_display())
            {
                if (u.Callsign != nil)
                    callsign = u.Callsign.getValue();
                var model = "XX";

                if (u.ModelType != "")
                    model = u.ModelType;

                if (target_idx < me.max_symbols)
                {
                    tgt = me.tgt_symbols[target_idx];
                    if (tgt != nil)
                    {
                        tgt.setVisible(u.get_display());
                        var u_dev_rad = (90-u.get_deviation(me.heading_deg))  * D2R;
                        var u_elev_rad = (90-u.get_total_elevation( me.pitch_deg))  * D2R;
                        var devs = aircraft.develev_to_devroll(u_dev_rad, u_elev_rad);
                        var combined_dev_deg = devs[0];
                        var combined_dev_length =  devs[1];
                        var clamped = devs[2];
                        var yc  = ht_yco + (ht_ycf * combined_dev_length * math.cos(combined_dev_deg*D2R));
                        var xc = ht_xco + (ht_xcf * combined_dev_length * math.sin(combined_dev_deg*D2R));
                        if(devs[2])
                            tgt.setVisible(getprop("sim/model/f15/lighting/hud-diamond-switch/state"));
                        else
                            tgt.setVisible(1);

                        if (awg_9.active_u != nil and awg_9.active_u.Callsign != nil and u.Callsign != nil and u.Callsign.getValue() == awg_9.active_u.Callsign.getValue())
                        {
                            me.target_locked.setVisible(1);
                            me.target_locked.setTranslation (xc, yc);
                        }
                        else
                        {
                            #
                            # if in symbol reject mode then only show the active target.
                            if(me.symbol_reject)
                                tgt.setVisible(0);
                        }
                        tgt.setTranslation (xc, yc);

                        if (ht_debug)
                            printf("%-10s %f,%f [%f,%f,%f] :: %f,%f",callsign,xc,yc, devs[0], devs[1], devs[2], u_dev_rad*D2R, u_elev_rad*D2R); 
                    }
                }
                target_idx = target_idx+1;
            }
        }
        for(var nv = target_idx; nv < me.max_symbols;nv += 1)
        {
            tgt = me.tgt_symbols[nv];
            if (tgt != nil)
            {
                tgt.setVisible(0);
            }
        }
    },
    list: [],
};

#
# The F-15C HUD is provided by 2 combiners.
# We model this accurately in the geometry by having the two glass panes 
# which are texture mapped onto a single canvas texture.two instances of the HUD
# 2016-01-06: The HUD appears slightly trapezoidal (better than previous version
#             however still could be improved possibly with a transformation matrix.

var MainHUD = nil;

var updateHUD = func ()
{  
    if (MainHUD == nil)
      MainHUD = F15HUD.new("Nasal/HUD/HUD.svg", "HUDImage1");
    MainHUD.update();
}
