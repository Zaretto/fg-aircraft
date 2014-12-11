
#----------------------------------------------------------------------------
# Spoiler computer     
# Most of it is for display purposes only since the YaSim flight model cannot
# handle split inputs for left and right wings that are not strict opposite
# Spoilers act for roll control, ground spoiler (anti-bounce) and direct lift
# control on approach
#----------------------------------------------------------------------------

# Constants
var MaxFlightSpoilers = 0.7;
var SpoilersMinima = 0;
var SpoilersCmd     = props.globals.getNode("fdm/jsbsim/fcs/spoilers-cmd", 1);

var computeSpoilers = func {

	# disable if we are in replay mode
	if ( getprop("sim/replay/time") > 0 ) { return }

    #
    # all spoiler handling in the FDM when using JSBSim

    CurrentLeftSpoiler = getprop("fdm/jsbsim/fcs/spoiler-left-pos");
    CurrentInnerLeftSpoiler = getprop("fdm/jsbsim/fcs/spoiler-left-pos");
    CurrentInnerRightSpoiler = getprop("fdm/jsbsim/fcs/spoiler-right-pos");
    CurrentRightSpoiler = getprop("fdm/jsbsim/fcs/spoiler-right-pos");
}



var toggleGroundSpoilers = func {
	if (getprop ("controls/flight/ground-spoilers-armed")) {
		setprop ("controls/flight/ground-spoilers-armed", false);
		SpoilersCmd.setDoubleValue(0.0);
        setprop ("fdm/jsbsim/fcs/spoiler-ground-brake-armed",0);
	} else {
		setprop ("controls/flight/ground-spoilers-armed", true);
        setprop ("fdm/jsbsim/fcs/spoiler-ground-brake-armed",1);
	}
}

var set_spoiler_brake = func(v)
{
    if (v > 0)
    {
    	setprop ("controls/flight/ground-spoilers-armed", true);
        setprop ("fdm/jsbsim/fcs/spoiler-ground-brake-armed",1);
    }
    else
    {
        setprop ("controls/flight/ground-spoilers-armed", false);
        setprop ("fdm/jsbsim/fcs/spoiler-ground-brake-armed",0);
    	SpoilersCmd.setDoubleValue(0.0);
    }
}

