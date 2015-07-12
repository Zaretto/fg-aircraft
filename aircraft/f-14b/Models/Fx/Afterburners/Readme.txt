Afterburner effects model
   | Richard Harrison: 2015-01 : rjh@zaretto.com based on Enqrique
   Laso's work on the F20

1. Using a cone for the flame trail rather than a billboard surface

2. The illumination factor for the flame trail is the inverse of the
available light (from rendering/scene/diffuse) - so that in full
daylight there isn't much visible in terms of light from the trial.

3. To get the flame trail to look right we control both the emissive
light and the transparency - so at noon there isn't much light
emission and it is fairly transparent.

4. Optionally use rembrandt lighting cone for each engine - positioned
roughly in the edge of the nozzles

5. ALS Thruster model used as well if available.

This model is included from the main model or effects file and the
required changes are:

1. Set the offsets on directly below Afterburners/AfterburnerL.xml Afterburners/AfterburnerR.xml

2. add the following to the set file:
    <float n="8" alias="/engines/engine[0]/afterburner" />
    <float n="9" alias="/engines/engine[1]/afterburner" />
    <float n="10" alias="/engines/engine[0]/nozzle-pos-norm" />
    <float n="11" alias="/engines/engine[1]/nozzle-pos-norm" />

3. in a Nasal module the flame rotation code below needs to be added
to the loop. This is what makes the flames wobble. Change the property
name to match the aircraft model.


var current_flame_number = 0;

var computeEngines = func {
   current_flame_number = (current_flame_number + 1);        
   if (current_flame_number > 3) current_flame_number = 0;
   setprop("sim/model/aircraft/fx/flame-number",current_flame_number);
}
