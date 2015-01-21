# F-15 VSD - based on Enrique Laso (Flying toaster) F-20 HUD main module

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


var VSDcanvas= canvas.new({
                           "name": "F-15 VSD",
                           "size": [1024,1024], 
                           "view": [256,256],                       
                           "mipmapping": 1     
                          });                          
                          
VSDcanvas.addPlacement({"node": "VSDImage"});
VSDcanvas.setColorBackground(0,0.1,0, 1.00);

# Create a group for the parsed elements
var SVGfile = VSDcanvas.createGroup();
 
# Parse an SVG file and add the parsed elements to the given group
print("Parse SVG ",canvas.parsesvg(SVGfile, "Aircraft/f15c/Nasal/VSD/VSD.svg"));
SVGfile.setTranslation (-20.0, 37.0);
print("VSD INIT");
 
var window1 = SVGfile.getElementById("window-1");
window1.setFont("condensed.txf").setFontSize(14, 1.4);
var window2 = SVGfile.getElementById("window-2");
window2.setFont("condensed.txf").setFontSize(14, 1.4);
var window3 = SVGfile.getElementById("window-3");
window3.setFont("condensed.txf").setFontSize(14, 1.4);

var window4 = SVGfile.getElementById("window-4");
window4.setFont("condensed.txf").setFontSize(14, 1.4);
var acue = SVGfile.getElementById("ACUE");
acue.setFont("condensed.txf").setFontSize(14, 1.4);
var ecue = SVGfile.getElementById("ECUE");
ecue.setFont("condensed.txf").setFontSize(14, 1.4);
var morhcue = SVGfile.getElementById("MORHCUE");
morhcue.setFont("condensed.txf").setFontSize(14, 1.4);


var updateVSD = func ()
{  
window1.setText (sprintf("W1: %3.0f", getprop("/velocities/airspeed-kt")));
window2.setText (sprintf("W2: %3.0f", getprop("/velocities/airspeed-kt")));
window3.setText (sprintf("W3: %3.0f", getprop("/velocities/airspeed-kt")));
window4.setText (sprintf("W4: %3.0f", getprop("/velocities/airspeed-kt")));

}
