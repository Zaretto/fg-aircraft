# F-15 HUD - based on Enrique Laso (Flying toaster) F-20 HUD main module

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

var prop_v = props.globals.getNode("/fdm/jsbsim/velocities/v-fps");
var prop_w = props.globals.getNode("/fdm/jsbsim/velocities/w-fps");
var prop_speed = props.globals.getNode("/fdm/jsbsim/velocities/vt-fps");

# paste into nasal console for debugging
#aircraft.HUDcanvas._node.setValues({
#                           "name": "F-15 HUD",
#                           "size": [1024,1024], 
#                           "view": [256,256],                       
#                           "mipmapping": 0     
#  });
#aircraft.HUDsvg.setTranslation (-6.0, 37.0);

var HUDcanvas= canvas.new({
                           "name": "F-15 HUD",
                           "size": [1024,1024], 
                           "view": [276,256],
                           "mipmapping": 1     
                          });                          
                          
HUDcanvas.addPlacement({"node": "HUDImage1"});
HUDcanvas.setColorBackground(0.36, 1, 0.3, 0.00);

# Create a group for the parsed elements
var HUDsvg = HUDcanvas.createGroup();
 
# Parse an SVG file and add the parsed elements to the given group
print("Parse SVG ",canvas.parsesvg(HUDsvg, "Nasal/HUD/HUD.svg"));
HUDsvg.setTranslation (-20.0, 37.0);

var HUDLowercanvas= canvas.new({
                           "name": "F-15 HUDLower",
                           "size": [1024,1024], 
                           "view": [276,256],
                           "mipmapping": 1     
                          });                          
                          
HUDLowercanvas.addPlacement({"node": "HUDImage2"});
HUDLowercanvas.setColorBackground(0.36, 1, 0.3, 0.00);

# Create a group for the parsed elements
var HUDLowersvg = HUDLowercanvas.createGroup();
 
# Parse an SVG file and add the parsed elements to the given group
print("Parse SVG ",canvas.parsesvg(HUDLowersvg, "Nasal/HUD/HUD.svg"));
HUDLowersvg.setTranslation (-20.0, 37.0);

print("HUD INIT");
 
aircraft.HUDcanvas._node.setValues({
                           "name": "F-15 HUD",
                           "size": [1024,1024], 
                           "view": [276,106],                       
                           "mipmapping": 0     
  });
aircraft.HUDsvg.setTranslation (0, 0);

aircraft.HUDLowercanvas._node.setValues({
                           "name": "F-15 HUD",
                           "size": [1024,1024], 
                           "view": [276,206],                       
                           "mipmapping": 0     
  });
aircraft.HUDLowersvg.setTranslation (0, -106);
#aircraft.HUDsvg.setTranslation (0, 0);

aircraft.HUDLowercanvas._node.setValues({
                           "name": "F-15 HUD",
                           "size": [1024,1024], 
                           "view": [276,106],
                           "mipmapping": 0     
  });

#aircraft.HUDLowersvg.createTransform([0.9, -0.38414, 164.15, -0.002, 0.9, 0.5, 0,0,1]).setTranslation (0,0);
#aircraft.HUDLowersvg.createTransform([1, -0.30206, 0, -0, 0.71700, 0, 0,0,1]).setTranslation (0, 0);
#aircraft.HUDLowersvg.createTransform([1, -0.42997, 0, -0, 0.60788, 0, 0,0,1]).setTranslation (0, 0);
#aircraft.HUDLowersvg.createTransform([1,  -0.50180, 0, -0, 0.56030, 0, 0,0,1]).setTranslation (0, 0);
# aircraft.HUDsvg.createTransform([1,  -0.30410, 0, -0, 0.77314, 0, 0,0,1]).setTranslation (0, 0);
# aircraft.HUDLowersvg.createTransform([1,  -0.42157, 0, -0, 0.53375, 0, 0,0,1]).setTranslation (0, 0);

#aircraft.HUDsvg.createTransform([0.77759,  -0.21674, 101, -0.01324, 0.74216, 30, 0,-0.00042,1]).setTranslation (0, 0);
#aircraft.HUDLowersvg.createTransform([0.85662,  -0.28115, 217.89, 0.00954, 0.64590, 153, 0,0-0.00050,1.23014]).setTranslation (0, 0);
#aircraft.HUDsvg.createTransform([1,  -0.28344, 0, 0, 0.85033, 0, 0,0,1]).setTranslation (0, 0);
#aircraft.HUDsvg.createTransform([1,  1.04540, 0, 0, 2.03830, 0, 0,0,1]).setTranslation (0, 0);

 #ircraft.HUDsvg.createTransform([0.6,  -0.44, 207, 0, 0.61632, 2, 0,0,1]).setTranslation (0, 0);
#aircraft.HUDLowersvg.createTransform([1.30765,  -0.34402, -161, 0.0009, 1.30765, -1, 0,0,1]).setTranslation (0, 0);
#aircraft.HUDsvg.createTransform([1,  -0.71193, 0, 0, 0.36162, 0, 0,-0.001380,1]).setTranslation (0, 0);
#aircraft.HUDsvg.createTransform([0.59653,  -0.46510, 86.5, -0.01713, 0.55975, 17.5, -0.00013,-0.00187,1]).setTranslation (0, 0);
#aircraft.HUDsvg.createTransform([0.50115,  -0.46510, 86.5, -0.01713, 0.55975, 17.5, -0.00013,-0.00187,1]).setTranslation (0, 0);
#aircraft.HUDsvg.createTransform([0.50115,  -0.63290, 416.5, -0.01431, 0.4325, 321, -0.00011,-0.00245,1]).setTranslation (0, 0);
#0.95330 -0.21140 58.13402 0.01928 0.26370 171.43 0.00005 -0.00093 1.17924


# A 2D 3x2 matrix with six parameters a, b, c, d, e and f is equivalent to the matrix:
# a  c  0 e 
# b  d  0 f
# 0  0  1 0 

var ladder = HUDsvg.getElementById("ladder");
var VV = HUDsvg.getElementById("VelocityVector");
var KIAS = HUDsvg.getElementById("KIAS");
KIAS.setFont("condensed.txf").setFontSize(14, 1.4);
var Alt = HUDsvg.getElementById("Alt");
Alt.setFont("condensed.txf").setFontSize(11, 1.4);
var AltThousands = HUDsvg.getElementById("AltThousands");
AltThousands.setFont("condensed.txf").setFontSize(14, 1.4);
var AlphaValue = HUDsvg.getElementById("alpha");
AlphaValue.setFont("condensed.txf").setFontSize(9, 1.4);
var gValue = HUDsvg.getElementById("G-value");
gValue.setFont("condensed.txf").setFontSize(9, 1.4);
var MachValue = HUDsvg.getElementById("Mach");
MachValue.setFont("condensed.txf").setFontSize(9, 1.4);
var heading_tape = HUDsvg.getElementById("heading-scale");
var roll_pointer = HUDsvg.getElementById("roll-pointer");

var lower_ladder = HUDLowersvg.getElementById("ladder");
var lower_VV = HUDLowersvg.getElementById("VelocityVector");
var lower_KIAS = HUDLowersvg.getElementById("KIAS");
KIAS.setFont("condensed.txf").setFontSize(14, 1.4);
var lower_Alt = HUDLowersvg.getElementById("Alt");
Alt.setFont("condensed.txf").setFontSize(11, 1.4);
var lower_AltThousands = HUDLowersvg.getElementById("AltThousands");
AltThousands.setFont("condensed.txf").setFontSize(14, 1.4);
var lower_AlphaValue = HUDLowersvg.getElementById("alpha");
AlphaValue.setFont("condensed.txf").setFontSize(9, 1.4);
var lower_gValue = HUDLowersvg.getElementById("G-value");
gValue.setFont("condensed.txf").setFontSize(9, 1.4);
var lower_MachValue = HUDLowersvg.getElementById("Mach");
MachValue.setFont("condensed.txf").setFontSize(9, 1.4);
var lower_heading_tape = HUDLowersvg.getElementById("heading-scale");
var lower_roll_pointer = HUDLowersvg.getElementById("roll-pointer");

var roll_rad = 0.0;
var pitch_offset = 12;
var f1 = 0.0;
#var pitch_factor = 21.458507963;
var pitch_factor = 19.8;
var pitch_factor_2 = pitch_factor * 180.0 / 3.14159;
var VV_y = 0;
var sin_x = 0;
var sin_y = 0;
var VV_x = 0;
var true_speed = 0;
var altitude_hundreds = 0;
var heading_tape_position = 0;

var prop_IAS =  props.globals.getNode ("/velocities/airspeed-kt");
var prop_alpha = props.globals.getNode ("orientation/alpha-deg");
var prop_mach =  props.globals.getNode ("/velocities/mach");
var prop_altitude_ft =  props.globals.getNode ("/position/altitude-ft");
var prop_heading =  props.globals.getNode("/orientation/heading-deg");
var prop_pitch =  props.globals.getNode ("orientation/pitch-deg");
var prop_roll =  props.globals.getNode ("orientation/roll-deg");
var Nz_prop = props.globals.getNode("/fdm/jsbsim/accelerations/Nz");



var updateHUD = func ()
{  
    var 	IAS = prop_IAS.getValue();
    var 	mach = prop_mach.getValue(); 
    var 	altitude_ft = prop_altitude_ft.getValue();
    var 	WOW = getprop ("/gear/gear[1]/wow") or getprop ("/gear/gear[2]/wow");
    var 	heading = prop_heading.getValue();	
    var 	pitch = prop_pitch.getValue();
    var 	roll = prop_roll.getValue();
    var     Nz = Nz_prop.getValue();
    var measured_altitude = getprop("/instrumentation/altimeter/indicated-altitude-ft");


    var  roll_rad = -roll*3.14159/180.0;
  
    #ladder
    ladder.setTranslation (0.0, pitch * pitch_factor+pitch_offset);                                           
    ladder.setCenter (118,830 - pitch * pitch_factor-pitch_offset);
    ladder.setRotation (roll_rad);
  
    #velocity vector 
    true_speed = prop_speed.getValue();
    sin_x = prop_v.getValue()/true_speed;
    if (sin_x < -1) sin_x = -1;
    if (sin_x > 1) sin_x = 1;
    sin_y = prop_w.getValue()/true_speed;
    if (sin_y < -1) sin_y = -1;
    if (sin_y > 1) sin_y = 1;
    VV_x = math.asin (sin_x) * pitch_factor_2;
    VV_y = math.asin (sin_y) * pitch_factor_2;
    VV.setTranslation (VV_x, VV_y+pitch_offset);
  
    #KIAS
    if (IAS > 40)
        KIAS.setText (sprintf("%3.0f",IAS));
    else 
        KIAS.setText ("");
  
    #Altitude
    altitude_hundreds = measured_altitude-int(measured_altitude/1000.0)*1000.0;
    if (altitude_hundreds < 10)
        Alt.setText (sprintf("00%1.0f",altitude_hundreds));
    else if (altitude_hundreds < 100)
        Alt.setText (sprintf("0%2.0f",altitude_hundreds));
    else
        Alt.setText (sprintf("%3.0f",altitude_hundreds));
     
    if (measured_altitude < 1000.0)
        AltThousands.setText ("");
    else
        AltThousands.setText (sprintf("%2.0f",measured_altitude/1000.0));     
     
    #readouts
    if (IAS > 10.0) AlphaValue.show(); else AlphaValue.hide();
    AlphaValue.setText (sprintf("%2.1f",Alpha));
    gValue.setText (sprintf("%1.1f",Nz));
    MachValue.setText (sprintf("%1.2f",mach));  
  
    #heading tape
    if (heading < 180)
        heading_tape_position = -heading*54/10;
    else
        heading_tape_position = (360-heading)*54/10;
     
    heading_tape.setTranslation (heading_tape_position,0);
  
    #roll pointer
    #roll_pointer.setCenter (118,-50);
    roll_pointer.setRotation (roll_rad);

# Lower hud  
    #ladder
    lower_ladder.setTranslation (0.0, pitch * pitch_factor+pitch_offset);                                           
    lower_ladder.setCenter (118,830 - pitch * pitch_factor-pitch_offset);
    lower_ladder.setRotation (roll_rad);
  
    #velocity vector 
    true_speed = prop_speed.getValue();
    sin_x = prop_v.getValue()/true_speed;
    if (sin_x < -1) sin_x = -1;
    if (sin_x > 1) sin_x = 1;
    sin_y = prop_w.getValue()/true_speed;
    if (sin_y < -1) sin_y = -1;
    if (sin_y > 1) sin_y = 1;
    VV_x = math.asin (sin_x) * pitch_factor_2;
    VV_y = math.asin (sin_y) * pitch_factor_2;
    lower_VV.setTranslation (VV_x, VV_y+pitch_offset);
  
    #KIAS
    if (IAS > 40)
        lower_KIAS.setText (sprintf("%3.0f",IAS));
    else 
        lower_KIAS.setText ("");
  
    #Altitude
    altitude_hundreds = measured_altitude-int(measured_altitude/1000.0)*1000.0;
    if (altitude_hundreds < 10)
        lower_Alt.setText (sprintf("00%1.0f",altitude_hundreds));
    else if (altitude_hundreds < 100)
        lower_Alt.setText (sprintf("0%2.0f",altitude_hundreds));
    else
        lower_Alt.setText (sprintf("%3.0f",altitude_hundreds));
     
    if (measured_altitude < 1000.0)
        lower_AltThousands.setText ("");
    else
        lower_AltThousands.setText (sprintf("%2.0f",measured_altitude/1000.0));     
     
    #readouts
    if (IAS > 10.0) 
        lower_AlphaValue.show(); 
    else 
        lower_AlphaValue.hide();
    lower_AlphaValue.setText (sprintf("%2.1f",Alpha));
    gValue.setText (sprintf("%1.1f",Nz));
    lower_MachValue.setText (sprintf("%1.2f",mach));  
  
    #heading tape
    if (heading < 180)
        heading_tape_position = -heading*54/10;
    else
        heading_tape_position = (360-heading)*54/10;
     
    lower_heading_tape.setTranslation (heading_tape_position,0);
  
    #roll pointer
    #roll_pointer.setCenter (118,-50);
    lower_roll_pointer.setRotation (roll_rad);

}
