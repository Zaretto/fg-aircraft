#
# F-15D Backseat routines
# ---------------------------
# Richard Harrison (rjh@zaretto.com) 2014-11-23. Based on F-14b by xii
#

var UPDATE_PERIOD = 0.03;
var acLat = props.getNode("/position/latitude-deg",1);
var acLon = props.getNode("/position/longitude-deg",1);
var acAlt = props.getNode("/position/altitude-ft",1);

# Check pilot's aircraft path from it's callsign.
var PilotCallsign = props.globals.getNode("/sim/remote/pilot-callsign");
var Pilot = nil;

var set_node_from = func(Pilot, target, source)
{
      var n = Pilot.getNode(source);
      if (n != nil)
      {
          var v = n.getValue();
          Pilot.getNode(target,1).setDoubleValue(v);
      }
}

var check_pilot_callsign = func() 
{
    r_callsign = PilotCallsign.getValue();
    if ( r_callsign )
    {
        var mpplayers = props.globals.getNode("/ai/models").getChildren("multiplayer");
        foreach (var p; mpplayers) 
        {
            if ( p.getChild("callsign").getValue() == r_callsign ) 
            {
                Pilot = p; 
            }
        }
    } 
    else 
    {
        Pilot = nil;
    }
}

var two_seater = 1;

var select_ecm_nav = func
{
	var ecm_nav_mode = Pilot.getNode("sim/model/f15/controls/rio-ecm-display/mode-ecm-nav");
	ecm_nav_mode.setBoolValue( ! ecm_nav_mode.getBoolValue());
}

##
# Receive basic instruments data over MP from pilot's aircraft.
instruments_data_import = func
{
    if (Pilot == nil)
        return;
    Pilot.getNode("sim/model/f15/variant",1).setValue("D");

    aircraft.ownship_pos.set_latlon(Pilot.getNode("position/latitude-deg").getValue(), Pilot.getNode("position/longitude-deg").getValue());

    if (getprop("/sim/walker/outside"))
    {
        Pilot.getNode("sim/model/hide-pilot",1).setValue(0);
        Pilot.getNode("sim/model/hide-backseater",1).setValue(0);
    }
    else
    {
        Pilot.getNode("sim/model/hide-pilot",1).setValue(0);
        Pilot.getNode("sim/model/hide-backseater",1).setValue(1);
    }

    var total_fuel_lbs = Pilot.getNode("sim/multiplay/generic/int[8]",1).getValue();
    var engines_engine0_egt_degC = Pilot.getNode("sim/multiplay/generic/int[9]",1).getValue();
    var engines_engine0_fuel_flow_pph = Pilot.getNode("sim/multiplay/generic/int[10]",1).getValue();
    var engines_engine1_egt_degC = Pilot.getNode("sim/multiplay/generic/int[11]",1).getValue();
    var engines_engine1_fuel_flow_pph = Pilot.getNode("sim/multiplay/generic/int[12]",1).getValue();
    var instrumentation_asi_ias = Pilot.getNode("sim/multiplay/generic/int[13]",1).getValue();
    var instrumentation_radar_radar2_range = Pilot.getNode("sim/multiplay/generic/int[14]",1).getValue();
    var fuel_gauges_total = Pilot.getNode("sim/multiplay/generic/int[15]",1).getValue();
    var velocities_mach = Pilot.getNode("sim/multiplay/generic/int[16]",1).getValue();

    if (instrumentation_asi_ias != nil)
    {
        Pilot.getNode("instrumentation/airspeed-indicator/indicated-speed-kt", 1).setDoubleValue(instrumentation_asi_ias);
        Pilot.getNode("fdm/jsbsim/velocities/vtrue-kts",1).setDoubleValue( instrumentation_asi_ias);
    }
    if (velocities_mach != nil)
        Pilot.getNode("velocities/mach", 1).setDoubleValue(velocities_mach);
    if (fuel_gauges_total != nil)
        Pilot.getNode("sim/model/f15/instrumentation/fuel-gauges/total", 1).setDoubleValue( fuel_gauges_total);

    var ac_essential = Pilot.getNode("sim/multiplay/generic/float[14]",1).getValue();
#    print("Ac_essential ",ac_essential," EGT ",engines_engine0_egt_degC," FF ",engines_engine0_fuel_flow_pph);

    if (ac_essential != nil) {
        Pilot.getNode("fdm/jsbsim/systems/electrics/ac-essential-bus1",1).setValue(ac_essential);
        Pilot.getNode("fdm/jsbsim/systems/electrics/ac-essential-bus2",1).setValue(ac_essential); 
        Pilot.getNode("fdm/jsbsim/systems/electrics/dc-essential-bus1",1).setValue(ac_essential);
        Pilot.getNode("fdm/jsbsim/systems/electrics/dc-essential-bus2",1).setValue(ac_essential);
    }
    var ac_main = Pilot.getNode("sim/multiplay/generic/float[15]",1).getValue();
    if (ac_main != nil) {
        Pilot.getNode("fdm/jsbsim/systems/electrics/ac-left-main-bus",1).setValue(ac_main);
        Pilot.getNode("fdm/jsbsim/systems/electrics/ac-right-main-bus",1).setValue(ac_main);
        Pilot.getNode("fdm/jsbsim/systems/electrics/dc-main-bus",1).setValue(ac_main);
        setprop("/instrumentation/radar/serviceable",1);
    }
    if (engines_engine0_egt_degC != nil)
      Pilot.getNode("engines/engine[0]/egt-degC",1).setDoubleValue(engines_engine0_egt_degC);
    if (engines_engine1_egt_degC != nil)
      Pilot.getNode("engines/engine[1]/egt-degC",1).setDoubleValue(engines_engine1_egt_degC);
    if (engines_engine0_fuel_flow_pph != nil)
      Pilot.getNode("engines/engine[0]/fuel-flow_pph",1).setDoubleValue(engines_engine0_fuel_flow_pph);
    if (engines_engine1_fuel_flow_pph != nil)
      Pilot.getNode("engines/engine[1]/fuel-flow_pph",1).setDoubleValue(engines_engine1_fuel_flow_pph);
    if (total_fuel_lbs != nil)
      Pilot.getNode("consumables/fuel/total-fuel-lbs",1).setDoubleValue(total_fuel_lbs);

    set_node_from(Pilot, "instrumentation/attitude-indicator/indicated-roll-deg", "orientation/roll-deg");
    set_node_from(Pilot, "instrumentation/attitude-indicator/indicated-roll-deg", "orientation/roll-deg");
    set_node_from(Pilot, "instrumentation/attitude-indicator/indicated-pitch-deg", "orientation/pitch-deg");
    set_node_from(Pilot, "instrumentation/heading-indicator-fg/indicated-heading-deg", "orientation/heading-deg");
    set_node_from(Pilot, "instrumentation/magnetic-compass/indicated-heading-deg", "orientation/heading-deg");

    var transponder_id =sprintf("%4d",Pilot.getNode("instrumentation/transponder/transmitted-id",1).getValue());
    if (transponder_id != nil)
    {
        Pilot.getNode("instrumentation/transponder/inputs/digit[0]", 1).setValue( substr(transponder_id,3,1) );
        Pilot.getNode("instrumentation/transponder/inputs/digit[1]", 1).setValue( substr(transponder_id,2,1) );
        Pilot.getNode("instrumentation/transponder/inputs/digit[2]", 1).setValue( substr(transponder_id,1,1) );
        Pilot.getNode("instrumentation/transponder/inputs/digit[3]", 1).setValue( substr(transponder_id,0,1) );
    }
    # need to set these for the radar.
    acLat.setValue(Pilot.getNode("/position/latitude-deg",1).getValue());
    acLon.setValue(Pilot.getNode("/position/longitude-deg",1).getValue());
    acAlt.setValue(Pilot.getNode("/position/altitude-ft",1).getValue());
    Pilot.getNode("instrumentation/airspeed-indicator/true-speed-kt",1).setValue(Pilot.getNode("velocities/true-airspeed-kt",1).getValue());

#			Pilot.getNode("sim/model/f15/instrumentation/tacan/mode", 1)
#			Pilot.getNode("instrumentation/tacan/indicated-mag-bearing-deg", 1).setValue( l[4] );
#			Pilot.getNode("instrumentation/tacan/in-range", 1).setBoolValue( l[5] );
#			Pilot.getNode("instrumentation/tacan/indicated-distance-nm", 1).setValue( l[6] );
#			var SteerSubmodeCode = Pilot.getNode("sim/model/f15/controls/pilots-displays/steer-submode-code", 1);
#			SteerSubmodeCode.setValue( l[7] );
#			Pilot.getNode("sim/model/f15/instrumentation/hsd/needle-deflection", 1).setValue( l[8] );
#			Pilot.getNode("instrumentation/nav[1]/radials/selected-deg", 1).setValue( l[9] );
#			Pilot.getNode("instrumentation/nav[1]/radials/selected-deg", 1).setValue( l[9] );
}

# Main loop ###############

var backseat_update = maketimer(UPDATE_PERIOD, func
{
	awg_9.rdr_loop();
    check_pilot_callsign();
    instruments_data_import();
#    emesary.GlobalTransmitter.NotifyAll(notificationUpdate4);

    #		instruments_data_export();
});


# Init ####################
var init = func {
	print("Initializing f15 Back Seat Systems");
    setprop("/sim/walker/outside",1);
    #
    #
    # Set the electrics for yasim (basic electrical model)
    setprop("fdm/jsbsim/systems/electrics/ac-essential-bus1",75);
    setprop("fdm/jsbsim/systems/electrics/ac-essential-bus2",75); 
    setprop("fdm/jsbsim/systems/electrics/ac-left-main-bus",75);
    setprop("fdm/jsbsim/systems/electrics/ac-right-main-bus",75);
    setprop("fdm/jsbsim/systems/electrics/dc-essential-bus1",28);
    setprop("fdm/jsbsim/systems/electrics/dc-essential-bus2",28);
    setprop("fdm/jsbsim/systems/electrics/dc-main-bus",28);
    setprop("fdm/jsbsim/systems/electrics/egenerator-kva",0);
    setprop("fdm/jsbsim/systems/electrics/emerg-generator-status",0);
    setprop("fdm/jsbsim/systems/electrics/lgenerator-kva",75);
    setprop("fdm/jsbsim/systems/electrics/rgenerator-kva",75);
    setprop("fdm/jsbsim/systems/electrics/transrect-online",2);
    setprop("fdm/jsbsim/systems/hydraulics/combined-system-psi",2398);
    setprop("fdm/jsbsim/systems/hydraulics/flight-system-psi",2396);
    setprop("engines/engine[0]/oil-pressure-psi", 28);
    setprop("engines/engine[1]/oil-pressure-psi", 28);

	# launch
    aircraft.ownship_pos = geo.Coord.new();
	check_pilot_callsign();
	radardist.init();
	awg_9.init();
    backseat_update.restart(UPDATE_PERIOD);
}

setlistener("sim/signals/fdm-initialized", init);

