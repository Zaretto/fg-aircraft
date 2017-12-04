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
        new_class.addIntProperty("Engine0Afterburner", "engines/engine[0]/afterburner", 1);
        new_class.addIntProperty("Engine0Augmentation", "engines/engine[0]/augmentation-burner", 1);
        new_class.addIntProperty("Engine0AugmentationAlight", "engines/engine[0]/augmentation-alight", 1);
        new_class.addIntProperty("Engine0N1","engines/engine[0]/n1", 1);
        new_class.addIntProperty("Engine0N2","engines/engine[0]/n2", 1);

        new_class.addIntProperty("Engine1N1","engines/engine[1]/n1", 1);
        new_class.addIntProperty("Engine1N2","engines/engine[1]/n2", 1);
        new_class.addIntProperty("Engine1Afterburner", "engines/engine[1]/afterburner", 1);
        new_class.addIntProperty("Engine1Augmentation", "engines/engine[1]/augmentation-burner", 1);
        new_class.addIntProperty("Engine1AugmentationAlight", "engines/engine[1]/augmentation-alight", 1);

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
        new_class.addIntProperty("IASkt", "instrumentation/airspeed-indicator/indicated-speed-kt", 2);
        new_class.addIntProperty("FuelTotal", "sim/model/f-14b/instrumentation/fuel-gauges/total", 2);
        new_class.addIntProperty("CabinAltitde", "fdm/jsbsim/systems/ecs/cabin-altitude-ft", 2);

        new_class.addIntProperty("RadarAWG9On","sim/model/f-14b/controls/radar-awg-9/on-off",1);
        new_class.addIntProperty("RadarRange", "instrumentation/radar/radar2-range", 2);
        new_class.addIntProperty("RadarStandby", "instrumentation/radar/radar-standby", 1);
        new_class.addIntProperty("RadarWCSMode", "sim/model/f-14b/instrumentation/radar-awg-9/wcs-mode", 1);
        new_class.addIntProperty("TargetRange", "sim/model/f-14b/systems/armament/aim9/target-range-nm", 1);

        new_class.addIntProperty("StationSelector0", "sim/model/f-14b/controls/armament/station-selector[0]", 1);
        new_class.addIntProperty("StationSelector1", "sim/model/f-14b/controls/armament/station-selector[1]", 1);
        new_class.addIntProperty("StationSelector2", "sim/model/f-14b/controls/armament/station-selector[2]", 1);
        new_class.addIntProperty("StationSelector3", "sim/model/f-14b/controls/armament/station-selector[3]", 1);
        new_class.addIntProperty("StationSelector4", "sim/model/f-14b/controls/armament/station-selector[4]", 1);
        new_class.addIntProperty("StationSelector5", "sim/model/f-14b/controls/armament/station-selector[5]", 1);
        new_class.addIntProperty("StationSelector6", "sim/model/f-14b/controls/armament/station-selector[6]", 1);
        new_class.addIntProperty("StationSelector7", "sim/model/f-14b/controls/armament/station-selector[7]", 1);

        new_class.addIntProperty("StationLoad0", "sim/model/f-14b/systems/external-loads/station[0]/id", 1);
        new_class.addIntProperty("StationLoad1", "sim/model/f-14b/systems/external-loads/station[1]/id", 1);
        new_class.addIntProperty("StationLoad2", "sim/model/f-14b/systems/external-loads/station[2]/id", 1);
        new_class.addIntProperty("StationLoad3", "sim/model/f-14b/systems/external-loads/station[3]/id", 1);
        new_class.addIntProperty("StationLoad4", "sim/model/f-14b/systems/external-loads/station[4]/id", 1);
        new_class.addIntProperty("StationLoad5", "sim/model/f-14b/systems/external-loads/station[5]/id", 1);
        new_class.addIntProperty("StationLoad6", "sim/model/f-14b/systems/external-loads/station[6]/id", 1);
        new_class.addIntProperty("StationLoad7", "sim/model/f-14b/systems/external-loads/station[7]/id", 1);




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
        new_class.addStringProperty("Livery","sim/model/livery/file");

        return new_class;
    }
};

