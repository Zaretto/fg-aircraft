#----------------------------------------------------------------------------
# Electrical System: Misc
# EMMISC
#----------------------------------------------------------------------------

# Constants

var oil_pressure_l = props.globals.getNode("engines/engine[0]/oil-pressure-psi", 1);
var oil_pressure_r = props.globals.getNode("engines/engine[1]/oil-pressure-psi", 1);
var ca_oil_press_light  = props.globals.getNode("sim/model/f-14b/lights/ca-oil-press", 1);

var bingo      = props.globals.getNode("sim/model/f-14b/controls/fuel/bingo", 1);
var ca_bingo_light  = props.globals.getNode("sim/model/f-14b/lights/ca-bingo", 1);

var ca_canopy_light = props.globals.getNode("sim/model/f-14b/lights/ca-lad-canopy", 1);
var canopy = props.globals.getNode("canopy/position-norm", 1);

var masterCaution_light = props.globals.getNode("sim/model/f-14b/instrumentation/warnings/master-caution", 1);
var masterCaution_light_set = props.globals.getNode("sim/model/f-14b/controls/master-caution-set", 1);
masterCaution_light_set.setBoolValue(0);

var jettisonLeft = props.globals.getNode("controls/armament/station[2]/jettison-all", 1);
var jettisonRight = props.globals.getNode("controls/armament/station[7]/jettison-all", 1);

var ca_l_gen_light  = props.globals.getNode("sim/model/f-14b/lights/ca-l-gen", 1);
var ca_r_gen_light  = props.globals.getNode("sim/model/f-14b/lights/ca-r-gen", 1);

var ca_l_fuel_press_light  = props.globals.getNode("sim/model/f-14b/lights/ca-l-fuel-press", 1);
var ca_r_fuel_press_light  = props.globals.getNode("sim/model/f-14b/lights/ca-r-fuel-press", 1);

var ca_l_fuel_low  = props.globals.getNode("sim/model/f-14b/lights/ca-l-fuel-low", 1);
var ca_r_fuel_low  = props.globals.getNode("sim/model/f-14b/lights/ca-r-fuel-low", 1);

var ca_hyd_press_light  = props.globals.getNode("sim/model/f-14b/lights/ca-hyd-press", 1);

var l_eng_starter = props.globals.getNode("controls/engines/engine[0]/starter",1);
var r_eng_starter = props.globals.getNode("controls/engines/engine[1]/starter",1);

var l_eng_running = props.globals.getNode("engines/engine[0]/running",1);
var r_eng_running = props.globals.getNode("engines/engine[0]/running",1);
var ca_start_valve  = props.globals.getNode("sim/model/f-14b/lights/start-valve", 1);

var runEMMISC = func {

# disable if we are in replay mode
#	if ( getprop("sim/replay/time") > 0 ) { return }

    var masterCaution =  masterCaution_light_set.getValue();
var master_caution_active  = 0;

    if ( (l_eng_starter.getBoolValue() and l_eng_running.getBoolValue()) 
        or (r_eng_starter.getBoolValue() and r_eng_running.getBoolValue()))
    {
        if (!ca_start_valve.getBoolValue()){
		    ca_start_valve.setBoolValue(1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }        
    else
    {
        if (ca_start_valve.getBoolValue())
	    {
		    ca_start_valve.setBoolValue(0);
        }
    }

	if (oil_pressure_l.getValue() < 23 or oil_pressure_r.getValue() < 23 ){
		if (!ca_oil_press_light.getBoolValue())
		{
		    ca_oil_press_light.setBoolValue(1);
            ca_hyd_press_light.setBoolValue(1);
            masterCaution = 1;
		}
        if(oil_pressure_l.getValue() < 23){
    		if (!ca_l_gen_light.getBoolValue())
            {
        	    ca_l_gen_light.setBoolValue(1);
                ca_l_fuel_press_light.setBoolValue(1);
                masterCaution = 1;
            }
        }
        if(oil_pressure_r.getValue() < 23){
    		if (!ca_r_gen_light.getBoolValue())
            {
        	    ca_r_gen_light.setBoolValue(1);
                ca_r_fuel_press_light.setBoolValue(1);
                masterCaution = 1;
            }
        }
        master_caution_active = 1;
	}
	else
	{
		if (ca_oil_press_light.getBoolValue())
		{
		    ca_oil_press_light.setBoolValue(0);
            ca_hyd_press_light.setBoolValue(0);
		}
    }
    if(oil_pressure_l.getValue() > 23){
 	    ca_l_gen_light.setBoolValue(0);
        ca_l_fuel_press_light.setBoolValue(0);
    }

    if(oil_pressure_r.getValue() > 23){
 	    ca_r_gen_light.setBoolValue(0);
        ca_r_fuel_press_light.setBoolValue(0);
	}

	if (total_lbs < bingo.getValue()){
		if (!ca_bingo_light.getBoolValue())
		{
		    ca_bingo_light.setBoolValue(1);
            masterCaution = 1;
		}
        master_caution_active = 1;
	}
	else
	{
		if (ca_bingo_light.getBoolValue())
		{
		    ca_bingo_light.setBoolValue(0);
		}
	}

	if (total_fuel_l < 1000){
		if (!ca_l_fuel_low.getBoolValue())
		{
    	    ca_l_fuel_low.setBoolValue(1);
            masterCaution = 1;
        }
        master_caution_active = 1;
	}
	else
	{
		if (ca_l_fuel_low.getBoolValue())
		{
		    ca_l_fuel_low.setBoolValue(0);
		}
	}

	if (total_fuel_r < 1000){
		if (!ca_r_fuel_low.getBoolValue())
		{
    	    ca_r_fuel_low.setBoolValue(1);
            masterCaution = 1;
        }
        master_caution_active = 1;
	}
	else
	{
		if (ca_r_fuel_low.getBoolValue())
		{
		    ca_r_fuel_low.setBoolValue(0);
		}
	}

    if (canopy.getValue() > 0){
		if (!ca_canopy_light.getBoolValue()){
            ca_canopy_light.setBoolValue(1);
            masterCaution = 1;
        }
        master_caution_active = 1;
    }
    else
    {
        ca_canopy_light.setBoolValue(0);
    }

    if (jettisonLeft.getValue() or jettisonRight.getValue()){
        masterCaution = 1;
        master_caution_active = 1;
    }
    if (!master_caution_active){
        masterCaution_light_set.setBoolValue(0);
        masterCaution_light.setBoolValue(0);
    }
    else
    {
        if (masterCaution)
        {
            masterCaution_light.setBoolValue(1);
        }
    }
}

var master_caution_pressed = func {
    jettisonLeft.setValue(0);
    jettisonRight.setValue(0);
    masterCaution_light.setBoolValue(0);
    masterCaution_light_set.setBoolValue(0);
}

var electricsFrame = func {
    runEMMISC();
}

