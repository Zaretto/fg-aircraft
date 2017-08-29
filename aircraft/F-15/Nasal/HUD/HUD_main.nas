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


# A 2D 3x2 matrix with six parameters a, b, c, d, e and f is equivalent to the matrix:
# a  c  0 e 
# b  d  0 f
# 0  0  1 0 

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
        if (canvas_item == "HUDImage1") {
            obj.dlzX      =170;
            obj.dlzY      =100;
            obj.dlzWidth  = 10;
            obj.dlzHeight = 90;
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
        }

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
        if (me == UpperHUD) {
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
        }


        var  roll_rad = -hdp.roll*3.14159/180.0;
        if (getprop("fdm/jsbsim/systems/electrics/ac-left-main-bus") <= 0 or getprop("sim/model/f15/controls/HUD/brightness") <= 0) {
            me.svg.setVisible(0);
            return;
        } else {
            me.svg.setVisible(1);
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
        var ptx = 0;
        var pty = 392+hdp.pitch * pitch_factor;

        me.ladder.setRotation(roll_rad);
        me.ladder.setTranslation(ptx,pty);

        if (hdp.pitch>0)
          me.ladder.setCenter (110,900-hdp.pitch*(1815/90));
        else
          me.ladder.setCenter (110,900+hdp.pitch*-(1772/90));
  
# velocity vector
        me.VV.setTranslation (hdp.VV_x, hdp.VV_y);

#Altitude
        me.alt_range.setTranslation(0, hdp.measured_altitude * alt_range_factor);

# IAS
        me.ias_range.setTranslation(0, hdp.IAS * ias_range_factor);
     
        if (hdp.range_rate != nil)
        {
            me.window1.setVisible(1);
            me.window1.setText("");
        }
        else
            me.window1.setVisible(0);
  
        if(getprop("sim/model/f15/controls/armament/master-arm-switch"))
        {
            var w_s = getprop("sim/model/f15/controls/armament/weapon-selector");
            me.window2.setVisible(1);
            var txt = "";
            if (w_s == 0)
            {
                txt = sprintf("%3d",getprop("sim/model/f15/systems/gun/rounds"));
            }
            else if (w_s == 1)
            {
                txt = sprintf("S%dL", getprop("sim/model/f15/systems/armament/aim9/count"));
            }
            else if (w_s == 2)
            {
                txt = sprintf("M%dF", getprop("sim/model/f15/systems/armament/aim120/count")+getprop("sim/model/f15/systems/armament/aim7/count"));
            }
            me.window2.setText(txt);
            if (awg_9.active_u != nil)
            {
                if (awg_9.active_u.Callsign != nil)
                    me.window3.setText(awg_9.active_u.Callsign.getValue());
                var model = "XX";
                if (awg_9.active_u.ModelType != "")
                    model = awg_9.active_u.ModelType;

#        var w2 = sprintf("%-4d", awg_9.active_u.get_closure_rate());
#        w3_22 = sprintf("%3d-%1.1f %.5s %.4s",awg_9.active_u.get_bearing(), awg_9.active_u.get_range(), callsign, model);
#
#
#these labels aren't correct - but we don't have a full simulation of the targetting and missiles so 
#have no real idea on the details of how this works.
                me.window4.setText(sprintf("RNG %3.1f", awg_9.active_u.get_range()));
                me.window5.setText(sprintf("CLO %-3d", awg_9.active_u.get_closure_rate()));
                me.window6.setText(model);
                me.window6.setVisible(1); # SRM UNCAGE / TARGET ASPECT
            }
        }
        else
        {
            me.window2.setVisible(0);
            me.window3.setText("NAV");
            if (hdp.nav_range != "")
                me.window3.setText("NAV");
            else
                me.window3.setText("");
            me.window4.setText(hdp.nav_range);
            me.window5.setText(hdp.window5);
            me.window6.setVisible(0); # SRM UNCAGE / TARGET ASPECT
        }

        me.window7.setText(hdp.window7);

#        me.window8.setText(sprintf("%02d NOWS", hdp.Nz*10));
        me.window8.setText(sprintf("%02d %02d", hdp.Nz*10, getprop("fdm/jsbsim/systems/cadc/ows-maximum-g")*10));

#heading tape
        if (hdp.heading < 180)
            me.heading_tape_position = -hdp.heading*54/10;
        else
            me.heading_tape_position = (360-hdp.heading)*54/10;
     
        me.heading_tape.setTranslation (me.heading_tape_position,0);
  
#roll pointer
#roll_pointer.setCenter (118,-50);
        me.roll_pointer.setRotation (roll_rad);

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
                        var u_dev_rad = (90-u.get_deviation(hdp.heading))  * D2R;
                        var u_elev_rad = (90-u.get_total_elevation( hdp.pitch))  * D2R;
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
                            if(hdp.symbol_reject)
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
#
# connects the properties to the HUD; did this really to save a few cycles for the two panes on the F-15
var HUD_DataProvider  = {
	new : func (){
		var obj = {parents : [HUD_DataProvider] };

        return obj;
    },
    update : func() {
        me.IAS = getprop("velocities/airspeed-kt");
        me.Nz = getprop("sim/model/f15/instrumentation/g-meter/g-max-mooving-average");
        me.WOW = getprop ("gear/gear[1]/wow") or getprop ("gear/gear[2]/wow");
        me.alpha = getprop("orientation/alpha-indicated-deg") or 0;
        me.beta = getprop("orientation/side-slip-deg") or 0;
        me.altitude_ft =  getprop ("position/altitude-ft");
        me.heading =  getprop("orientation/heading-deg") or 0;
        me.mach = getprop ("instrumentation/airspeed-indicator/indicated-mach") or 0;
        me.measured_altitude = getprop("instrumentation/altimeter/indicated-altitude-ft");
        me.pitch =  getprop ("orientation/pitch-deg");
        me.roll =  getprop ("orientation/roll-deg");
        me.speed = getprop("fdm/jsbsim/velocities/vt-fps");
        me.v = getprop("fdm/jsbsim/velocities/v-fps");
        me.w = getprop("fdm/jsbsim/velocities/w-fps");
        me.symbol_reject = getprop("sim/model/f15/controls/HUD/sym-rej");
        me.range_rate = "0";
        if (getprop("autopilot/route-manager/active"))
        {
            var rng = getprop("autopilot/route-manager/wp/dist");
            var eta_s = getprop("autopilot/route-manager/wp/eta-seconds");
            if (rng != nil)
            {
                me.window5 = sprintf("%2d MIN",rng);
                me.nav_range = sprintf("N %4.1f", rng);
            }
            else
            {
                me.window5 = "XXX";
                me.nav_range = "N XXX";
            }

            if (eta_s != nil)
                me.window5 = sprintf("%2d MIN",eta_s/60);
            else
                me.window5 = "XX MIN";
        }
        else
        {
            me.nav_range = "";
            me.window5 = "";
        }

        if(getprop("controls/gear/brake-parking"))
            me.window7 = "BRAKES";
        else if(getprop("controls/gear/gear-down") or me.alpha > 20)
            me.window7 = sprintf("AOA %d",me.alpha);
        else
            me.window7 = sprintf(" %1.3f",me.mach);

        me.roll_rad = 0.0;

        me.VV_x = me.beta*10; # adjust for view
        me.VV_y = me.alpha*10; # adjust for view

    },
};

var hud_data_provider = HUD_DataProvider.new();
#
# The F-15C HUD is provided by 2 combiners.
# We model this accurately in the geometry by having the two glass panes 
# which are texture mapped onto a single canvas texture.two instances of the HUD
# 2016-01-06: The HUD appears slightly trapezoidal (better than previous version
#             however still could be improved possibly with a transformation matrix.

var MainHUD = F15HUD.new("Nasal/HUD/HUD.svg", "HUDImage1");

var updateHUD = func ()
{  
    hud_data_provider.update();
    MainHUD.update(hud_data_provider);
}
