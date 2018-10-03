ControlBridgeId = 5; # property to use for control bridge.

var aircraftControlEventNotification = notifications.AircraftControlNotification.new("s2m");
altimeter_setting_inhg = 1;
altimeter_setting_stby = 2;
set_radar_range = 3;
set_radar_mode = 4;
set_radar_DDD_brightness = 5;
set_radar_TID_brightness = 6;
station_selector_0 = 7;
station_selector_1 = 8;
station_selector_2 = 9;
station_selector_3 = 10;
station_selector_4 = 11;
station_selector_5 = 12;
station_selector_6 = 13;
station_selector_7 = 14;
station_selector_8 = 15;


#	var p = "sim/current-view/name";
#	p = "instrumentation/altimeter/indicated-altitude-ft";
#	p = "instrumentation/altimeter/setting-inhg";
#	p = "orientation/heading-deg";
#	p = "orientation/heading-magnetic-deg";
#	p = "sim/model/f-14b/controls/radar-awg-9/brightness";
#	p = "sim/model/f-14b/controls/radar-awg-9/on-off";
#p = "sim/model/f-14b/instrumentation/radar-awg-9/display-rdr";
#	p = "sim/model/f-14b/instrumentation/awg-9/sweep-factor";
#	p = "sim/model/f-14b/controls/TID/brightness";
#	p = "sim/model/f-14b/controls/TID/on-off";
#	p = "sim/model/f-14b/instrumentation/radar-awg-9/wcs-mode/pulse-srch";
#	p = "sim/model/f-14b/instrumentation/radar-awg-9/wcs-mode/tws-auto";
#	p = "instrumentation/radar/az-field";
#	p = "instrumentation/ecm/on-off";
#	p = "sim/model/f-14b/controls/rio-ecm-display/mode-ecm-nav";
#	p = "sim/model/f-14b/controls/HSD/on-off";
#	p = "sim/model/f-14b/instrumentation/hsd/needle-deflection";
#	p = "instrumentation/nav[1]/radials/selected-deg";
#	p = "instrumentation/radar/radar2-range";
#	p = "instrumentation/radar/radar-standby";

notify_prop = func(id, prop){
#    print("Notify ",id," ",prop," ",getprop(prop));
    aircraftControlEventNotification.EventType = id;
    aircraftControlEventNotification.EventValue = getprop(prop);
    emesary.GlobalTransmitter.NotifyAll(aircraftControlEventNotification);
}
notify_value = func(id, value){
#    print("Notify ",id," ",prop," ",getprop(prop));
    aircraftControlEventNotification.EventType = id;
    aircraftControlEventNotification.EventValue = value;
    emesary.GlobalTransmitter.NotifyAll(aircraftControlEventNotification);
}
