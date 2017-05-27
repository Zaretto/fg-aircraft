#
#
#
#
# var PropertySyncNotification = 
# {
#    new: func(_ident="none", _name="", _kind=0, _secondary_kind=0)
#    {
#        var new_class = PropertySyncNotificationBase.new(_ident, _name, _kind, _secondary_kind);
#
#        new_class.addIntProperty("consumables/fuel/total-fuel-lbs", 1);
#        new_class.addIntProperty("controls/fuel/dump-valve", 1);
#        new_class.addIntProperty("engines/engine[0]/augmentation-burner", 1);
#        new_class.addIntProperty("engines/engine[0]/n1", 1);
#        new_class.addIntProperty("engines/engine[0]/n2", 1);
#        new_class.addNormProperty("surface-positions/wing-pos-norm", 2);
#        return new_class;
#    }
#};

var PropertySyncNotificationBase = 
{
    new: func(_ident="none", _name="", _kind=0, _secondary_kind=0)
    {
        var new_class = emesary.Notification.new("PropertySyncNotification", _ident);

        new_class.IsDistinct = 1;
        new_class.Kind = _kind;
        new_class.Name = _name;
        new_class.SecondaryKind = _secondary_kind;
        new_class.Callsign = nil; # populated automatically by the incoming bridge when routed
        new_class._bridgeProperties = [];

        new_class.addIntProperty = func(property, sp)
        {
            append(me._bridgeProperties, 
                   {
                       getValue:func{return emesary.TransferInt.encode(getprop(property) or 0);},
                       setValue:func(v,bridge){setprop(bridge.PropertyRoot~property, emesary.TransferInt.decode(v))}, 
                   });
        }
        new_class.addNormProperty = func(property, precision)
        {
            var sp = math.pow(10, sp);
            append(me._bridgeProperties, 
                   {
                       getValue:func{return emesary.TransferNorm.encode(getprop(property) or 0,sp);},
                       setValue:func(v,bridge){setprop(bridge.PropertyRoot~property, emesary.TransferNorm.decode(v,sp));}, 
                   });
        }
        new_class.bridgeProperties = func()
        {
            return me._bridgeProperties;
        }
        return new_class;
    }
};

var PropertySyncNotification = 
{
    new: func(_ident="none", _name="", _kind=0, _secondary_kind=0)
    {
        var new_class = PropertySyncNotificationBase.new(_ident, _name, _kind, _secondary_kind);

        new_class.addIntProperty("consumables/fuel/total-fuel-lbs", 1);
        new_class.addIntProperty("controls/fuel/dump-valve", 1);
        new_class.addIntProperty("engines/engine[0]/augmentation-burner", 1);
        new_class.addIntProperty("engines/engine[0]/n1", 1);
        new_class.addIntProperty("engines/engine[0]/n2", 1);
        new_class.addIntProperty("engines/engine[0]/nozzle-pos-norm", 1);
        new_class.addIntProperty("engines/engine[1]/augmentation-burner", 1);
        new_class.addIntProperty("engines/engine[1]/n1", 1);
        new_class.addIntProperty("engines/engine[1]/n2", 1);
        new_class.addIntProperty("fdm/jsbsim/systems/electrics/ac-essential-bus1", 1);
        new_class.addIntProperty("fdm/jsbsim/systems/electrics/ac-essential-bus2", 1);
        new_class.addIntProperty("fdm/jsbsim/systems/electrics/ac-left-main-bus", 1);
        new_class.addIntProperty("fdm/jsbsim/systems/electrics/ac-left-main-bus-powered", 1);
        new_class.addIntProperty("fdm/jsbsim/systems/electrics/ac-main-bus1", 1);
        new_class.addIntProperty("fdm/jsbsim/systems/electrics/ac-right-main-bus", 1);
        new_class.addIntProperty("fdm/jsbsim/systems/electrics/dc-essential-bus1", 1);
        new_class.addIntProperty("fdm/jsbsim/systems/electrics/dc-essential-bus2", 1);
        new_class.addIntProperty("instrumentation/nav[1]/radials/selected-deg", 1);
        new_class.addIntProperty("instrumentation/tacan/in-range", 1);
        new_class.addIntProperty("instrumentation/tacan/indicated-distance-nm", 1);
        new_class.addIntProperty("instrumentation/tacan/indicated-mag-bearing-deg", 1);
        new_class.addIntProperty("sim/model/f-14b/controls/fuel/refuel-probe-switch", 1);
        new_class.addIntProperty("sim/model/f-14b/controls/lighting/formation", 1);
        new_class.addIntProperty("sim/model/f-14b/controls/pilots-displays/steer-submode-code", 1);
        new_class.addIntProperty("sim/model/f-14b/instrumentation/hsd/needle-deflection", 1);
        new_class.addIntProperty("sim/model/f-14b/instrumentation/tacan/mode", 1);
        new_class.addIntProperty("sim/model/f-14b/lighting/anti-collision/state", 1);
        new_class.addIntProperty("sim/model/f-14b/lighting/position/state", 1);

        new_class.addNormProperty("canopy/position-norm", 1);
        new_class.addNormProperty("engines/engine[1]/nozzle-pos-norm", 1);
        new_class.addNormProperty("gear/gear[0]/compression-norm", 1);
        new_class.addNormProperty("gear/gear[0]/position-norm", 1);
        new_class.addNormProperty("gear/gear[1]/compression-norm", 1);
        new_class.addNormProperty("gear/gear[1]/position-norm", 1);
        new_class.addNormProperty("gear/gear[2]/compression-norm", 1);
        new_class.addNormProperty("gear/gear[2]/position-norm", 1);
        new_class.addNormProperty("gear/launchbar/position-norm", 1);
        new_class.addNormProperty("gear/tailhook/position-norm", 1);
        new_class.addNormProperty("surface-positions/aux-flap-pos-norm", 1);
        new_class.addNormProperty("surface-positions/inner-left-spoilers", 1);
        new_class.addNormProperty("surface-positions/inner-right-spoilers", 1);
        new_class.addNormProperty("surface-positions/left-elevator-pos-norm", 1);
        new_class.addNormProperty("surface-positions/left-spoilers", 1);
        new_class.addNormProperty("surface-positions/main-flap-pos-norm", 1);
        new_class.addNormProperty("surface-positions/right-elevator-pos-norm", 1);
        new_class.addNormProperty("surface-positions/right-spoilers", 1);
        new_class.addNormProperty("surface-positions/rudder-pos-norm", 1);
        new_class.addNormProperty("surface-positions/slats-pos-norm", 1);
        new_class.addNormProperty("surface-positions/speedbrake-pos-norm", 1);
        new_class.addNormProperty("surface-positions/wing-pos-norm", 2);

        return new_class;
    }
};

