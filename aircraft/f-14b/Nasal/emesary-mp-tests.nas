#
# emesary MP bridge tests.
#
# NOTES:
#       * The test incoming bridge is created manually linking directly
#         to the /sim/multiplay/ property.
#         This results in a bridge that is almost but not quite entirely
#         unlike the way that a bridge is setup in an MP environment.
#
#       * It will test the mechanism of transfer and encoding, but not
#         the bridge connection via the usual startMPbridge method.

var routedNotifications = [notifications.PropertySyncNotification.new(nil)];
var geoRoutedNotifications = [notifications.GeoEventNotification.new(nil), notifications.ArmamentNotification.new(nil)];
var bridgedTransmitter = emesary.Transmitter.new("outgoingBridge");
var outgoingBridge = emesary_mp_bridge.OutgoingMPBridge.new("F-14mp",routedNotifications, 19, "", bridgedTransmitter);
outgoingBridge.MPStringMaxLen = 110;

#emesary_mp_bridge.IncomingMPBridge.startMPBridge(routedNotifications, 19, emesary.GlobalTransmitter);

var geoBridgedTransmitter = emesary.Transmitter.new("geoOutgoingBridge");
var geooutgoingBridge = emesary_mp_bridge.OutgoingMPBridge.new("F-14mp.geo",geoRoutedNotifications, 18, "", geoBridgedTransmitter);

geooutgoingBridge.MPStringMaxLen = 730;
#emesary_mp_bridge.IncomingMPBridge.startMPBridge(geoRoutedNotifications, 18, emesary.GlobalTransmitter);

var incomingBridge = emesary_mp_bridge.ConnectIncomingBridge("/sim", routedNotifications, 19, emesary.GlobalTransmitter);

#
# This is the notification (derived from Nasal/PropertySyncNotificationBase) that will allow properties to be transmitted over MP
var f14_aircraft_notification = notifications.PropertySyncNotification.new("F-14"~getprop("/sim/multiplay/callsign"));

var debugRecipient = emesary.Recipient.new("Debug");
debugRecipient.Receive = func(notification)
{
    if (notification.NotificationType == "GeoEventNotification")
    {
        print("recv: ",notification.NotificationType, " ", notification.Ident);
		debug.dump(notification);
    }
    if (notification.NotificationType == "ArmamentNotification") {
        if (notification.FromIncomingBridge) {
            print("recv: ",notification.NotificationType, " ", notification.Ident,
                  " Kind=",notification.Kind,
                  " SecondaryKind=",notification.SecondaryKind,
                  " RelativeAltitude=",notification.RelativeAltitude,
                  " Distance=",notification.Distance,
                  " Bearing=",notification.Bearing,
                  " RemoteCallsign=",notification.RemoteCallsign);
            debug.dump(notification);
        }
    }
    return emesary.Transmitter.ReceiptStatus_NotProcessed; # we're not processing it, just looking
}
#emesary.GlobalTransmitter.Register(debugRecipient);


var msg = notifications.ArmamentNotification.new("mis", 1, 4, 20);
          msg.RelativeAltitude =19999;
          msg.Bearing = 11;
          msg.Distance = 1.2;
msg.IsDistinct =0;
          msg.RemoteCallsign = "Callsi";
print("explodeTrig");
debug.dump(msg);
          f14.geoBridgedTransmitter.NotifyAll(msg);


var m = geo.aircraft_position();
mid=33;
        var msg = notifications.GeoEventNotification.new("mis", "AIM9", 2, 20+mid);
        msg.Position.set_latlon(m.lat(), m.lon(), m.alt());
            msg.Flags = 1;
        print("sendMis");
        debug.dump(msg);
        f14.geoBridgedTransmitter.NotifyAll(msg);


msg = notifications.GeoEventNotification.new("mis", "AIM9", 2, 20+mid);
        msg.Position.set_latlon(m.lat(), m.lon(), m.alt());
            msg.Flags = 1;
        print("sendMis");
msg.UniqueIndex=2;
msg.Name="AIM120";
        
        debug.dump(msg);
f14.geoBridgedTransmitter.NotifyAll(msg);

