
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
    if (usingJSBSim)
    {
        CurrentLeftSpoiler = getprop("fdm/jsbsim/fcs/spoiler-left-outer-pos");
        CurrentInnerLeftSpoiler = getprop("fdm/jsbsim/fcs/spoiler-left-inner-pos");
        CurrentInnerRightSpoiler = getprop("fdm/jsbsim/fcs/spoiler-right-inner-pos");
        CurrentRightSpoiler = getprop("fdm/jsbsim/fcs/spoiler-right-outer-pos");
        return;
    }

	var rollCommand = - getprop("controls/flight/aileron");
	var DLC = 0.0;
	var groundSpoilersArmed = getprop("controls/flight/ground-spoilers-armed");

	# Compute a bias to reduce spoilers extension from full extension at sweep = 20deg
	# to no extension past 56 deg
	if (WingSweep >= 0.8235294117647059) {
		wingSweepBias = 0;
	} else 	if (WingSweep < 0.29411) {
		wingSweepBias = 1.0; 
	}
    else
    {
		wingSweepBias = 1.0 - ((WingSweep-0.29411) * 1.25); 
    }

	# Ground spoiler activation  
	if ((groundSpoilersArmed and !wow) or (wow and !GroundSpoilersLatchedClosed and groundSpoilersArmed)) {
		GroundSpoilersLatchedClosed = 0;
	} else {
		GroundSpoilersLatchedClosed = 1;
	}

	if (groundSpoilersArmed and ! GroundSpoilersLatchedClosed and Throttle < ThrottleIdle ) { 
		# if weight on wheels or ground spoilers deployed (in case of hard bounce)
		if (GroundSpoilersDeployed or wow)
        {
    			GroundSpoilersDeployed = 1;
    			LeftSpoilersTarget = wingSweepBias;
    			RightSpoilersTarget = wingSweepBias;
    			InnerLeftSpoilersTarget = wingSweepBias; 
    			InnerRightSpoilersTarget = wingSweepBias;
    			setprop ("controls/flight/yasim-spoilers", wingSweepBias);
    			SpoilersCmd.setDoubleValue(wingSweepBias);
			return;
		}
	}

	# If we have come this far, the ground spoilers are not armed 
	# and consquently should not be deployed. Let's make sure this is the case
    if (GroundSpoilersDeployed){
	    GroundSpoilersDeployed = 0;
    	SpoilersCmd.setDoubleValue(0);
    }
	# Compute the contribution of Direct Lift Control on spoiler extension
	# If wings are swept back, or the aircraft is on the ground, Direct Lift
	# Control is deactivated
	if (WingSweep > 0.34) {
		DLC = 0; # TODO: add a condition on weight on wheels
	} else {
		DLC = getprop("controls/flight/DLC")
	}

	#spoilers are depressed -4 degrees when flaps are out
	var fc = FlapsCmd.getValue();
	if ( fc != nil ) {
		SpoilersMinima = 0;
		if ( fc == 1 ) { # Flaps out.
			SpoilersMinima = -0.073;
		}
    		LeftSpoilersTarget = rollCommand * wingSweepBias * MaxFlightSpoilers + SpoilersMinima;
	    	RightSpoilersTarget = (-rollCommand) * wingSweepBias * MaxFlightSpoilers + SpoilersMinima;
		    if (DLCactive) {
    			InnerLeftSpoilersTarget = (DLC + rollCommand) * wingSweepBias * MaxFlightSpoilers + SpoilersMinima;
    			InnerRightSpoilersTarget = (DLC - rollCommand) * wingSweepBias * MaxFlightSpoilers + SpoilersMinima;
    		} else {
    			InnerLeftSpoilersTarget = LeftSpoilersTarget;
    			InnerRightSpoilersTarget = RightSpoilersTarget;
    		}
	    	# clip the values to in-flight maxima
    		if (LeftSpoilersTarget < SpoilersMinima) LeftSpoilersTarget = SpoilersMinima;
    		if (RightSpoilersTarget < SpoilersMinima) RightSpoilersTarget = SpoilersMinima;
	    	if (LeftSpoilersTarget > MaxFlightSpoilers) LeftSpoilersTarget = MaxFlightSpoilers;
		    if (RightSpoilersTarget > MaxFlightSpoilers) RightSpoilersTarget = MaxFlightSpoilers;
		    if (InnerLeftSpoilersTarget < SpoilersMinima) InnerLeftSpoilersTarget = SpoilersMinima;
    		if (InnerRightSpoilersTarget < SpoilersMinima) InnerRightSpoilersTarget = SpoilersMinima;
	    	if (InnerLeftSpoilersTarget > MaxFlightSpoilers) InnerLeftSpoilersTarget = MaxFlightSpoilers;
    		if (InnerRightSpoilersTarget > MaxFlightSpoilers) InnerRightSpoilersTarget = MaxFlightSpoilers;

    		setprop ("controls/flight/yasim-spoilers", (InnerRightSpoilersTarget + InnerLeftSpoilersTarget) / 2.0);
	}
}


# Controls

var toggleDLC = func {
	if ( !DLCactive and ( FlapsCmd.getValue() >= 1 ) ) {
		DLCactive = 1;
		DLC_Engaged.setBoolValue(1);
		setprop("controls/flight/DLC", 0.3);
	} else {
		DLCactive = 0;
		DLC_Engaged.setBoolValue(0);
		setprop("controls/flight/DLC", 0);
	}
}

var toggleGroundSpoilers = func {
	if (getprop ("controls/flight/ground-spoilers-armed")) {
		setprop ("controls/flight/ground-spoilers-armed", 0);
		SpoilersCmd.setDoubleValue(0.0);
        if(usingJSBSim) 	setprop ("fdm/jsbsim/fcs/spoiler-ground-brake-armed",0);
	} else {
		setprop ("controls/flight/ground-spoilers-armed", 1);
        if(usingJSBSim) 	setprop ("fdm/jsbsim/fcs/spoiler-ground-brake-armed",1);
	}
}

var set_spoiler_brake = func(v)
{
    if (v > 0)
    {
    	setprop ("controls/flight/ground-spoilers-armed", 1);
        if(usingJSBSim) 	setprop ("fdm/jsbsim/fcs/spoiler-ground-brake-armed",1);
    }
    else
    {
        setprop ("controls/flight/ground-spoilers-armed", 0);
        if(usingJSBSim) 	setprop ("fdm/jsbsim/fcs/spoiler-ground-brake-armed",0);
    	SpoilersCmd.setDoubleValue(0.0);
    }
}

