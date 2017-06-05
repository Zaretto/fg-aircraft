#
# Uses PropertySyncNotificationBase to allow properties to be transmitted and received over MP.
# --
# PropertySyncNotificationBase is a shortcut notification; as it doesn't need to received and all
# of the properties are simply set when the notification is unpacked over MP.
var PropertySyncNotification = 
{
    new: func(_ident="none", _name="", _kind=0, _secondary_kind=0)
    {
        var new_class = notifications.PropertySyncNotificationBase.new(_ident, _name, _kind, _secondary_kind);

        new_class.addIntProperty("TotalFuelLbs", "consumables/fuel/total-fuel-lbs", 2);
        new_class.addIntProperty("FuelDumpValue", "controls/fuel/dump-valve", 1);
        new_class.addIntProperty("Engine0Augmentation", "engines/engine[0]/augmentation-burner", 1);
        new_class.addIntProperty("Engine0N1","engines/engine[0]/n1", 1);
        new_class.addIntProperty("Engine0N2","engines/engine[0]/n2", 1);
        new_class.addIntProperty("Engine1N1","engines/engine[1]/n1", 1);
        new_class.addIntProperty("Engine1N2","engines/engine[1]/n2", 1);
        new_class.addIntProperty("Engine1Augmentation", "engines/engine[1]/augmentation-burner", 1);
        new_class.addIntProperty("ElectricsAcEssentialBus1", "fdm/jsbsim/systems/electrics/ac-essential-bus1", 1);
        new_class.addIntProperty("ElectricsAcEssentialBus2", "fdm/jsbsim/systems/electrics/ac-essential-bus2", 1);
        new_class.addIntProperty("ElectricsAcLeftMainBus", "fdm/jsbsim/systems/electrics/ac-left-main-bus", 1);
        new_class.addIntProperty("ElectricsAcLeftMainBusPowered", "fdm/jsbsim/systems/electrics/ac-left-main-bus-powered", 1);
        new_class.addIntProperty("ElectricsAcMainBus1", "fdm/jsbsim/systems/electrics/ac-main-bus1", 1);
        new_class.addIntProperty("ElectricsAcRightMainBus", "fdm/jsbsim/systems/electrics/ac-right-main-bus", 1);
        new_class.addIntProperty("ElectricsDcEssentialBus1", "fdm/jsbsim/systems/electrics/dc-essential-bus1", 1);
        new_class.addIntProperty("ElectricsDcEssentialBus2", "fdm/jsbsim/systems/electrics/dc-essential-bus2", 1);
        new_class.addIntProperty("NavRadialSelected", "instrumentation/nav[1]/radials/selected-deg", 2);
        new_class.addIntProperty("TacanInRange", "instrumentation/tacan/in-range", 1);
        new_class.addIntProperty("TacanDistanceNm", "instrumentation/tacan/indicated-distance-nm", 1);
        new_class.addIntProperty("TacanIndicatedBearingDeg", "instrumentation/tacan/indicated-mag-bearing-deg", 2);
        new_class.addNormProperty("RefuelProbe", "sim/model/f-14b/refuel/position-norm", 1);
        new_class.addIntProperty("LightingFormation", "sim/model/f-14b/controls/lighting/formation", 1);
        new_class.addIntProperty("SteerSubmodeCode", "sim/model/f-14b/controls/pilots-displays/steer-submode-code", 1);
        new_class.addIntProperty("HSDNeedleDeflection", "sim/model/f-14b/instrumentation/hsd/needle-deflection", 1);
        new_class.addIntProperty("TacanMode", "sim/model/f-14b/instrumentation/tacan/mode", 1);
        new_class.addIntProperty("LightingAntiCollision", "sim/model/f-14b/lighting/anti-collision/state", 1);
        new_class.addIntProperty("LightingPosition", "sim/model/f-14b/lighting/position/state", 1);

        new_class.addNormProperty("Canopy", "canopy/position-norm", 1);
        new_class.addNormProperty("Engine0NozzlePosNorm", "engines/engine[0]/nozzle-pos-norm", 1);
        new_class.addNormProperty("Engine1NozzlePosNorm", "engines/engine[1]/nozzle-pos-norm", 1);
        new_class.addNormProperty("Gear0CompressionNorm", "gear/gear[0]/compression-norm", 1);
        new_class.addNormProperty("Gear0PositionNorm", "gear/gear[0]/position-norm", 1);
        new_class.addNormProperty("Gear1CompressionNorm", "gear/gear[1]/compression-norm", 1);
        new_class.addNormProperty("Gear1PositionNorm", "gear/gear[1]/position-norm", 1);
        new_class.addNormProperty("Gear2CompressionNorm", "gear/gear[2]/compression-norm", 1);
        new_class.addNormProperty("Gear2PositionNorm", "gear/gear[2]/position-norm", 1);
        new_class.addNormProperty("LaunchbarPositionNorm", "gear/launchbar/position-norm", 1);
        new_class.addNormProperty("TailhookPositionNorm", "gear/tailhook/position-norm", 1);
        new_class.addNormProperty("AuxFlapPosNorm","surface-positions/aux-flap-pos-norm", 1);
        new_class.addNormProperty("InnerLeftSpoilersPosNorm","surface-positions/inner-left-spoilers", 1);
        new_class.addNormProperty("InnerRightSpoilersPosNorm","surface-positions/inner-right-spoilers", 1);
        new_class.addNormProperty("LeftElevatorPosNorm","surface-positions/left-elevator-pos-norm", 1);
        new_class.addNormProperty("LeftSpoilersPosNorm","surface-positions/left-spoilers", 1);
        new_class.addNormProperty("FlapPosNorm","surface-positions/flap-pos-norm", 1);
        new_class.addNormProperty("RightElevatorPosNorm","surface-positions/right-elevator-pos-norm", 1);
        new_class.addNormProperty("RightSpoilersPosNorm","surface-positions/right-spoilers", 1);
        new_class.addNormProperty("RudderPosNorm","surface-positions/rudder-pos-norm", 1);
        new_class.addNormProperty("SlatsPosNorm","surface-positions/slats-pos-norm", 1);
        new_class.addNormProperty("SpeedbrakePosNorm","surface-positions/speedbrake-pos-norm", 1);
        new_class.addNormProperty("WingPosNorm","surface-positions/wing-pos-norm", 1);

        return new_class;
    }
};

