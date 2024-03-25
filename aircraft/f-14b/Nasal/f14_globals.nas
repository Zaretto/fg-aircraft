## Global constants ##

var deltaT = 1.0;

var currentG = 1.0;
#----------------------------------------------------------------------------
# sweep computer
#----------------------------------------------------------------------------

#Variables

var AutoSweep = 1;
#var OverSweep = 0;
var WingSweep = 0.0; #Normalised wing sweep


#----------------------------------------------------------------------------
# Nozzle opening
#----------------------------------------------------------------------------

# Variables
var Nozzle1Target = 0.0;
var Nozzle2Target = 0.0;
var Nozzle1 = 0.0;
var Nozzle2 = 0.0;
var usingJSBSim = getprop("/sim/flight-model") == "jsb";
print ("F-14 Using jsbsim = ",usingJSBSim);

#----------------------------------------------------------------------------
# Spoilers
#----------------------------------------------------------------------------

# Variables
var LeftSpoilersTarget = 0.0;
var RightSpoilersTarget = 0.0;
var InnerLeftSpoilersTarget = 0.0;
var InnerRightSpoilersTarget = 0.0;

# create properties for ground spoilers 
#setprop ("/controls/flight/ground-spoilers-armed", 0);
var GroundSpoilersDeployed = 0;

# Latching mechanism in order not to deploy ground spoilers if the aircraft
# is on ground and the spoilers are armed
var GroundSpoilersLatchedClosed = 1;

# create a property to control spoilers in the YaSim flight model
setprop ("/controls/flight/yasim-spoilers", 0.0);


#----------------------------------------------------------------------------
# SAS
#----------------------------------------------------------------------------

var OldPitchInput = 0;
var SASpitch = 0;
var SASroll = 0;

#----------------------------------------------------------------------------
# General aircraft values
#----------------------------------------------------------------------------

# Constants
var ThrottleIdle = 0.05;

# Variables
var CurrentMach = 0;
var CurrentAlt = 0;
var CurrentIAS = 0;
var Alpha = 0;
var Throttle = 0;
var e_trim = 0;
var rudder_trim = 0;


