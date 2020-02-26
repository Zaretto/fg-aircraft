#
#
# Use to transmit events that happen at a specific place; can be used to make 
# models that are simulated locally (e.g. tankers) appear on other player's MP sessions.
var ArmamentNotification_Id = 19;

var ArmamentNotification = 
{
# new:
# _ident - the identifier for the notification. not bridged.
# _name - name of the notification, bridged.
# _kind - created, moved, deleted, impact (see notifications.nas)
# _secondary_kind - This is the entity on which the activity is being performed. See below for predefined types.
##
    new: func(_ident="none", _kind=0, _secondary_kind=0)
    {
        var new_class = emesary.Notification.new("ArmamentNotification", _ident, ArmamentNotification_Id);

        new_class.Kind = _kind;
        new_class.SecondaryKind = _secondary_kind;
        new_class.RelativeAltitude = 0;
        new_class.IsDistinct = 0;
        new_class.Distance = 0;
        new_class.Bearing = 0;
        new_class.RemoteCallsign = ""; # associated remote callsign.

        new_class.bridgeProperties = func
        {
            return 
            [ 
             {
            getValue:func{return emesary.TransferByte.encode(new_class.Kind);},
            setValue:func(v,root,pos){var dv=emesary.TransferByte.decode(v,pos);new_class.Kind=dv.value;return dv}, 
             },
             {
            getValue:func{return emesary.TransferByte.encode(new_class.SecondaryKind);},
            setValue:func(v,root,pos){var dv=emesary.TransferByte.decode(v,pos);new_class.SecondaryKind=dv.value;return dv}, 
             },
             {
            getValue:func{return emesary.TransferFixedDouble.encode(new_class.RelativeAltitude,2,10);},
            setValue:func(v,root,pos){var dv=emesary.TransferFixedDouble.decode(v,2,10,pos);new_class.RelativeAltitude=dv.value;return dv}, 
             },
             {
            getValue:func{return emesary.TransferFixedDouble.encode(new_class.Distance,2,10);},
            setValue:func(v,root,pos){var dv=emesary.TransferFixedDouble.decode(v,2,10,pos);new_class.Distance=dv.value;return dv}, 
             },
             {
            getValue:func{return emesary.TransferFixedDouble.encode(new_class.Bearing,2,10);},
            setValue:func(v,root,pos){var dv=emesary.TransferFixedDouble.decode(v,2,10,pos);new_class.Bearing=dv.value;return dv}, 
             },
             {
            getValue:func{return emesary.TransferString.encode(new_class.RemoteCallsign);},
            setValue:func(v,root,pos){var dv=emesary.TransferString.decode(v,pos);new_class.RemoteCallsign=dv.value;return dv}, 
             },
            ];
          };
        return new_class;
    },
};
