 #---------------------------------------------------------------------------
 #
 #	Title                : F-14 Backseat main (Emeary version)
 #
 #	File Type            : Implementation File
 #
 #	Description          : The F-14 backseat is implemented as an empty 3d model 
 #	                     : and the pilot is placed into the 3d model of the front seat
 #	                     : i.e. the other player in the MP environment.
 #	                     : There is supporting logic required to link the properties from the pilot.
 #	                     : and to transmit to the pilot model any actions made by the RIO that will
 #	                     : affect the pilot and need to be reflected back.
 #	                     : Not all actions by the copilot need to be transmitted back to the pilot model, so for example
 #	                     : adjusting the headset volume may not require transmission back.
 #                       :
 #                       : An update loop isn't required as we can rely on the incoming notifications from the 
 #                       : bridge to schedule the updates (i.e. it becomes event drive
 #
 #	Author               : Richard Harrison (richard@zaretto.com)
 #
 #	Creation Date        : 14 June 2017
 #
 #	Version              : 1.0
 #
 #  Copyright © 2016 Richard Harrison           Released under GPL V2
 #
 #---------------------------------------------------------------------------*/

print("F-14 back seat systems");
#
#
# var routedNotifications = [notifications.TacticalNotification.new(nil), PropertySyncNotification];
# var incomingBridge = emesary_mp_bridge.IncomingMPBridge.startMPBridge(routedNotifications);

# Check pilot's aircraft path from it's callsign.
var PilotCallsign = props.globals.getNode("/sim/remote/pilot-callsign");
var Pilot = nil;

var check_pilot_callsign = func() {
	r_callsign = PilotCallsign.getValue();
	if ( r_callsign ) {
		var mpplayers = props.globals.getNode("/ai/models").getChildren("multiplayer");
		foreach (var p; mpplayers) {
			if ( p.getChild("callsign").getValue() == r_callsign ) {
				Pilot = p; 
			}
		}
	} else {
		Pilot = nil;
	}
}


var select_ecm_nav = func {
	var ecm_nav_mode = Pilot.getNode("sim/model/f-14b/controls/rio-ecm-display/mode-ecm-nav");
	ecm_nav_mode.setBoolValue( ! ecm_nav_mode.getBoolValue());
}

var outgoingRoutedNotifications = [notifications.PropertySyncNotification.new(nil)];
var geoRoutedNotifications = [notifications.GeoEventNotification.new(nil)];

# To seperate out the incoming and outgoing we will have a dedicated transmitter for sending notifications over MP.
# We could bridge GlobalTransmitter - however this way allows us to control what is sent.
#var bridgedTransmitter = emesary.Transmitter.new("outgoingBridge");

#
# The bridge requires two sides; the outgoing and incoming. The outgoing will forwards all received notifications via 
# MP; and these will be received by a similarly equipped craft. All received notifications are, by default, sent via the
# global transmitter; and therefore there needs to be no differentiation (in our code) as to where the notification comes 
# from.
#var outgoingBridge = emesary_mp_bridge.OutgoingMPBridge.new("F-14mp",outgoingRoutedNotifications, 19, "", bridgedTransmitter);
var incomingBridge = emesary_mp_bridge.IncomingMPBridge.startMPBridge(outgoingRoutedNotifications, 19, emesary.GlobalTransmitter);

#var geoBridgedTransmitter = emesary.Transmitter.new("geoOutgoingBridge");
#var geooutgoingBridge = emesary_mp_bridge.OutgoingMPBridge.new("F-14mp.geo",geoRoutedNotifications, 18, "", geoBridgedTransmitter);
var geoincomingBridge = emesary_mp_bridge.IncomingMPBridge.startMPBridge(geoRoutedNotifications, 18, emesary.GlobalTransmitter);
#
# This is the notification (derived from Nasal/PropertySyncNotificationBase) that will allow properties to be transmitted over MP
var f14_aircraft_notification = notifications.PropertySyncNotification.new("F-14"~getprop("/sim/multiplay/callsign"));

#
#
# Currently we have two transmitters and three bridges
# GeoEventNotification -> geooutgoingBridge -> MP -> GlobalTransmitter
# PropertySyncNotification -> bridgedTransmitter -> MP -> GlobalTransmitter
# AircraftControlNotification -> bridgedTransmitter -> MP -> GlobalTransmitter

instruments_data_import = func {
	if ( Pilot == nil ) { return }
	PilotInstrString = Pilot.getNode("sim/multiplay/generic/string[1]", 1);
	var str = PilotInstrString.getValue();
	if ( str != nil ) {
		var l = split(";", str);
		# Todo: Create the needed nodes only at connection/de-connection time. 
		# ias, mach, fuel_total, tc_mode, tc_bearing, tc_in_range, tc_range, steer_mode_code, cdi, radial.
		if ( size(l) > 1 ) {
			Pilot.getNode("instrumentation/airspeed-indicator/indicated-speed-kt", 1).setValue( l[0] );
			Pilot.getNode("velocities/mach", 1).setValue( l[1] );
			Pilot.getNode("sim/model/f-14b/instrumentation/fuel-gauges/total", 1).setValue( l[2] );
			Pilot.getNode("sim/model/f-14b/instrumentation/tacan/mode", 1).setValue( l[3] );
			Pilot.getNode("instrumentation/tacan/indicated-mag-bearing-deg", 1).setValue( l[4] );
			Pilot.getNode("instrumentation/tacan/in-range", 1).setBoolValue( l[5] );
			Pilot.getNode("instrumentation/tacan/indicated-distance-nm", 1).setValue( l[6] );
			var SteerSubmodeCode = Pilot.getNode("sim/model/f-14b/controls/pilots-displays/steer-submode-code", 1);
			SteerSubmodeCode.setValue( l[7] );

			Pilot.getNode("sim/model/f-14b/instrumentation/hsd/needle-deflection", 1).setValue( l[8] );
			Pilot.getNode("instrumentation/nav[1]/radials/selected-deg", 1).setValue( l[9] );

			if (size(l) > 11)
			{
			    var ac_powered = l[10] != nil and l[10] == "1";
			    setprop("/fdm/jsbsim/systems/electrics/ac-essential-bus1",ac_powered);
			    setprop("/fdm/jsbsim/systems/electrics/ac-essential-bus2",ac_powered); 
			    setprop("/fdm/jsbsim/systems/electrics/ac-left-main-bus",ac_powered);
		        setprop("/fdm/jsbsim/systems/electrics/ac-right-main-bus",ac_powered);
		        setprop("/fdm/jsbsim/systems/electrics/dc-essential-bus1",ac_powered);
		        setprop("/fdm/jsbsim/systems/electrics/dc-essential-bus2",ac_powered);
		        setprop("/fdm/jsbsim/systems/electrics/dc-main-bus",ac_powered);
		    }
		}
	}
	#PilotInstrString2 = Pilot.getNode("sim/multiplay/generic/string[2]", 1);
	#var str2 = PilotInstrString2.getValue();
	#if ( str2 != nil ) {
		#Pilot.getNode("instrumentation/radar/radar2-range", 1).setValue(str2);
	#}
}

var acRoutedNotifications = [notifications.AircraftControlNotification.new(nil)];

# To seperate out the incoming and outgoing we will have a dedicated transmitter for sending notifications over MP.
# We could bridge GlobalTransmitter - however this way allows us to control what is sent.
var acBridgedTransmitter = emesary.Transmitter.new("backseatSlaveBridge");
var acOutgoingBridge = emesary_mp_bridge.OutgoingMPBridge.new("F-14backseat",acRoutedNotifications, ControlBridgeId);

var BackseatRecipient = emesary.Recipient.new("Backseat");
emesary.GlobalTransmitter.Register(BackseatRecipient);

var backseatExec = func{
	check_pilot_callsign();
    awg_9.rdr_loop();
    execTimer.restart(execRate);
    instruments_data_import(); # compatibility
};
var execRate = 0.04;
var execTimer = maketimer(execRate, backseatExec);
BackseatRecipient.Receive = func(notification)
{
    if (notification.NotificationType == "PropertySyncNotification")
    {
        if (notification.Callsign == PilotCallsign.getValue())
          {
              #print("Property update from ",notification.Callsign);
              #check_pilot_callsign();
              #instruments_data_import();
              #instruments_data_export();
          }
        return emesary.Transmitter.ReceiptStatus_OK;
    }
#     else if (notification.NotificationType == "AircraftControlNotification")
#     {
#         print("Set ",notification.EventType, " to ", notification.EventValue);
#         if (notification.EventType == altimeter_setting_inhg)
#             setprop("instrumentation/altimeter/setting-inhg", notification.EventValue);
#         else if (notification.EventType == altimeter_setting_stby)
#             setprop("instrumentation/altimeter/setting-stby", notification.EventValue);

#        return emesary.Transmitter.ReceiptStatus_OK;
#     }
    return emesary.Transmitter.ReceiptStatus_NotProcessed; # we're not processing it, just looking
}


setlistener("sim/signals/fdm-initialized", func {
	print("Initializing F-14 Back Seat Systems");

    setprop("/fdm/jsbsim/systems/electrics/ac-essential-bus1",75);
    setprop("/fdm/jsbsim/systems/electrics/ac-essential-bus2",75); 
    setprop("/fdm/jsbsim/systems/electrics/ac-left-main-bus",75);
    setprop("/fdm/jsbsim/systems/electrics/ac-right-main-bus",75);
    setprop("/fdm/jsbsim/systems/electrics/dc-essential-bus1",28);
    setprop("/fdm/jsbsim/systems/electrics/dc-essential-bus2",28);
    setprop("/fdm/jsbsim/systems/electrics/dc-main-bus",28);
    setprop("/fdm/jsbsim/systems/electrics/egenerator-kva",0);
    setprop("/fdm/jsbsim/systems/electrics/emerg-generator-status",0);
    setprop("/fdm/jsbsim/systems/electrics/lgenerator-kva",75);
    setprop("/fdm/jsbsim/systems/electrics/rgenerator-kva",75);
    setprop("/fdm/jsbsim/systems/electrics/transrect-online",2);
    setprop("fdm/jsbsim/systems/hydraulics/combined-system-psi",2398);
    setprop("fdm/jsbsim/systems/hydraulics/flight-system-psi",2396);
    setprop("engines/engine[0]/oil-pressure-psi", 28);
    setprop("engines/engine[1]/oil-pressure-psi", 28);
    setprop("sim/model/f-14b/controls/TID/brightness" ,1);
    setprop("sim/model/f-14b/controls/radar-awg-9/brightness" ,1);

	# launch
	radardist.init();
	awg_9.init();
    execTimer.start();
});

model_setprop = func(v){
    Pilot.getNode(v).setValue(getprop(v));
}

var code_ct = func () {}
var not = func () {}
