var aircraftControlRecipient = emesary.Recipient.new("aircraftControl");
emesary.GlobalTransmitter.Register(aircraftControlRecipient);

aircraftControlRecipient.Receive = func(notification)
{
    if (notification.NotificationType == "AircraftControlNotification")
    {
print("Set ",notification.EventType, " to ", notification.EventValue);
        if (notification.EventType == altimeter_setting_inhg)
            setprop("instrumentation/altimeter/setting-inhg", notification.EventValue);
        else if (notification.EventType == altimeter_setting_stby)
            setprop("instrumentation/altimeter/setting-stby", notification.EventValue);
        else if (notification.EventType == set_radar_range)
            setprop("instrumentation/radar/radar2-range", notification.EventValue);
        else if (notification.EventType == set_radar_mode)
            awg_9.wcs_mode_sel(notification.EventValue);
        else if (notification.EventType >= station_selector_0 and notification.EventType <= station_selector_8)
            f14.station_selector(notification.EventType - station_selector_0, notification.EventValue);

       return emesary.Transmitter.ReceiptStatus_OK;
    }
    return emesary.Transmitter.ReceiptStatus_NotProcessed; # we're not processing it, just looking
}
var controlNotifications = [notifications.AircraftControlNotification.new(nil)];
var controlIncomingBridge = emesary_mp_bridge.IncomingMPBridge.startMPBridge(controlNotifications, ControlBridgeId, emesary.GlobalTransmitter);
