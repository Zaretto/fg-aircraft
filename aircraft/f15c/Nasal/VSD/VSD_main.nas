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
VSDcanvas.setColorBackground(0.36, 1, 0.3, 0.00);

# Create a group for the parsed elements
var SVGfile = VSDcanvas.createGroup();
 
# Parse an SVG file and add the parsed elements to the given group
print("Parse SVG ",canvas.parsesvg(SVGfile, "Aircraft/f15c/Nasal/VSD/VSD.svg"));
SVGfile.setTranslation (-20.0, 37.0);
print("VSD INIT");
 


var updateVSD = func ()
{  

}
