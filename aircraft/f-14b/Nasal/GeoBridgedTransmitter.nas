# Emesary bridged transmitter for armament notifications.
# 
# Richard Harrison 2017
#
# NOTES:
# 1.The incoming bridges that is defined here will apply to all models that 
#   are loaded over MP; it is better to create the bridges here rather than in the model.xml
#   So given that we don't want a bridge on all MP models only those that are on OPRF
#   aircraft that want to receive notifications we will create the incoming bridge here
#   and thus only an OPRF model will receive notifications from another OPRF model.
#
# 2. The Emesary MP bridge requires two sides; the outgoing and incoming. 
#    - The outgoing aircraft will forwards all received notifications via MP;
#      and these will be received by a similarly equipped craft.
#    - The receiving aircraft will receive all notifications from other MP craft via
#      the globalTransmitter - which is bridged via property #18 /sim/multiplay/emesary/bridge[18]
#------------------------------------------------------------------------------------------

# Setup the bridge
# armament notification 24 bytes
# geoEventNotification - 34 bytes + the length of the RemoteCallsign and Name fields.
var geoRoutedNotifications = [notifications.GeoEventNotification.new(nil), notifications.ArmamentNotification.new(nil)];
var geoBridgedTransmitter = emesary.Transmitter.new("geoOutgoingBridge");
var geooutgoingBridge = emesary_mp_bridge.OutgoingMPBridge.new("F-14mp.geo",geoRoutedNotifications, 18, "", geoBridgedTransmitter);

# This should be tuned to be 2/3 of the current spare space in the MP packet to allow as many notifications
# to be sent as possible.
geooutgoingBridge.MPStringMaxLen = 230;
emesary_mp_bridge.IncomingMPBridge.startMPBridge(geoRoutedNotifications, 18, emesary.GlobalTransmitter);

#
# debug all messages.
var debugRecipient = emesary.Recipient.new("Debug");
debugRecipient.Receive = func(notification)
{
    if (notification.NotificationType == "GeoEventNotification")
    {
        print("recv(1): ",notification.NotificationType, " ", notification.Ident);
		debug.dump(notification);
    }
    else if (notification.NotificationType == "ArmamentNotification") {
        if (notification.FromIncomingBridge) {
            print("recv(2): ",notification.NotificationType, " ", notification.Ident,
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
emesary.GlobalTransmitter.Register(debugRecipient);

