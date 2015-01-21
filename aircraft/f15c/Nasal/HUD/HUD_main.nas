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


var HUDcanvas= canvas.new({
                           "name": "F-15 HUD",
                           "size": [1024,1024], 
                           "view": [256,256],                       
                           "mipmapping": 1     
                          });                          
                          
HUDcanvas.addPlacement({"node": "HudImage"});
HUDcanvas.setColorBackground(0.36, 1, 0.3, 0.00);

# Create a group for the parsed elements
var SVGfile = HUDcanvas.createGroup();
 
# Parse an SVG file and add the parsed elements to the given group
print("Parse SVG ",canvas.parsesvg(SVGfile, "Aircraft/f15c/Nasal/HUD/HUD.svg"));
SVGfile.setTranslation (-20.0, 37.0);
print("HUD INIT");
 
var ladder = SVGfile.getElementById("ladder");
var VV = SVGfile.getElementById("VelocityVector");
var KIAS = SVGfile.getElementById("KIAS");
KIAS.setFont("condensed.txf").setFontSize(14, 1.4);
var Alt = SVGfile.getElementById("Alt");
Alt.setFont("condensed.txf").setFontSize(11, 1.4);
var AltThousands = SVGfile.getElementById("AltThousands");
AltThousands.setFont("condensed.txf").setFontSize(14, 1.4);
var AlphaValue = SVGfile.getElementById("alpha");
AlphaValue.setFont("condensed.txf").setFontSize(9, 1.4);
var gValue = SVGfile.getElementById("G-value");
gValue.setFont("condensed.txf").setFontSize(9, 1.4);
var MachValue = SVGfile.getElementById("Mach");
MachValue.setFont("condensed.txf").setFontSize(9, 1.4);
var heading_tape = SVGfile.getElementById("heading-scale");
var roll_pointer = SVGfile.getElementById("roll-pointer");

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


var updateHud = func ()
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
  
  

}
