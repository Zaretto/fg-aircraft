var AircraftEventNotification = 
  {
   new: func(_ident="none", _name="", _kind=0, _secondary_kind=0)
   {
       var new_class = emesary.Notification.new("AircraftEventNotification", _ident);

       new_class.IsDistinct = 1;
       new_class.Kind = _kind;
       new_class.Name = _name;
       new_class.SecondaryKind = _secondary_kind;
       new_class.Callsign = nil; # populated automatically by the incoming bridge when routed

	   new_class.AuxFlaps = 0;
	   new_class.ElectricsEssentialPowered = 0;
	   new_class.ElectricsMainPowered = 0;
       new_class.ElectricsPowered = 0;
       new_class.EngineAugmentationBurnerL = 0; # 0 to 5
       new_class.EngineAugmentationBurnerR = 0; # 0 to 5
       new_class.EngineNozzleL = 0;
       new_class.EngineNozzleR = 0;
       new_class.Flaps = 0;
       new_class.FuelDump = 0;
       new_class.FuelTotal = 0;
	   new_class.GearPosition = 0;
	   new_class.GearCompression0 = 0;
	   new_class.GearCompression1 = 0;
	   new_class.GearCompression2 = 0;
       new_class.HsdNeedleDeflection = 0;
       new_class.LeftElevator = 0;
       new_class.LightingAntiCollision = 0;
       new_class.LightingFormation = 0;
       new_class.LightingPosition = 0;
       new_class.Nav1RadialSelectedDeg = 0;
       new_class.RadarMode = 0;
       new_class.Refuel = 0;
       new_class.RightElevator = 0;
	   new_class.Rudder = 0;
       new_class.Slats = 0;
       new_class.Smoke = 0;
	   new_class.SpeedBrake = 0;
       new_class.SteerSubmodeCode = 0;
	   new_class.SpoilerLeft = 0;
	   new_class.SpoilerRight = 0;
       new_class.TacanInRange = 0;
       new_class.TacanIndicatedBearing = 0;
       new_class.TacanIndicatedDistanceNm = 0;
       new_class.TacanMode = 0;
       new_class.WingDamage = 0; #0,1=l,2=r,3=both
       new_class.WingSweep = 20;

new_class.Ruddder= 0;
new_class.SpeedBrake= 0;
new_class.SpeedBrake= 0;
new_class.Launchbar= 0;
new_class.Canopy= 0;
new_class.Engine0N1= 0;
new_class.Engine0N2= 0;
new_class.Engine1N1= 0;
new_class.Engine1N2= 0;

       new_class.bridgeProperties = func()
         {
             return 
               [ 
				{ getValue:func{return emesary.TransferNorm.encode(new_class.Rudder,1);},               setValue:func(v){new_class.Rudder=emesary.TransferNorm.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.ElectricsEssentialPowered);},               setValue:func(v){new_class.ElectricsPowered=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.ElectricsMainPowered);},               setValue:func(v){new_class.ElectricsPowered=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.Engine0N1);},               setValue:func(v){new_class.Engine0N1=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.Engine0N2);},               setValue:func(v){new_class.Engine0N2=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.Engine1N1);},               setValue:func(v){new_class.Engine1N1=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.Engine1N2);},               setValue:func(v){new_class.Engine1N2=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.EngineAugmentationBurnerL,1);},               setValue:func(v){new_class.EngineAugmentationBurnerL=emesary.TransferInt.decode(v,1);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.EngineAugmentationBurnerR,1);},               setValue:func(v){new_class.EngineAugmentationBurnerR=emesary.TransferInt.decode(v,1);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.EngineNozzleL,1);},               setValue:func(v){new_class.EngineNozzleL=emesary.TransferInt.decode(v,1);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.EngineNozzleR,1);},               setValue:func(v){new_class.EngineNozzleR=emesary.TransferInt.decode(v,1);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.FuelDump,1);},               setValue:func(v){new_class.FuelDump=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.FuelTotal);},               setValue:func(v){new_class.FuelTotal=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.HsdNeedleDeflection);},               setValue:func(v){new_class.HsdNeedleDeflection=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.LightingAntiCollision);},               setValue:func(v){new_class.LightingAntiCollision=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.LightingFormation);},               setValue:func(v){new_class.LightingFormation=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.LightingPosition);},               setValue:func(v){new_class.LightingPosition=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.Nav1RadialSelectedDeg);},               setValue:func(v){new_class.Nav1RadialSelectedDeg=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.RadarMode);},               setValue:func(v){new_class.RadarMode=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.Refuel);},               setValue:func(v){new_class.Refuel=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.Smoke);},               setValue:func(v){new_class.Smoke=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.SteerSubmodeCode);},               setValue:func(v){new_class.SteerSubmodeCode=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.TacanInRange,1);},               setValue:func(v){new_class.TacanInRange=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.TacanIndicatedBearing);},               setValue:func(v){new_class.TacanIndicatedBearing=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.TacanIndicatedDistanceNm,1);},               setValue:func(v){new_class.TacanIndicatedDistanceNm=emesary.TransferInt.decode(v,1);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.TacanMode,1);},               setValue:func(v){new_class.TacanMode=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferInt.encode(new_class.WingDamage);},               setValue:func(v){new_class.WingDamage=emesary.TransferInt.decode(v);}, },
                { getValue:func{return emesary.TransferNorm.encode(new_class.AuxFlaps);},               setValue:func(v){new_class.AuxFlaps=emesary.TransferNorm.decode(v);}, },
                { getValue:func{return emesary.TransferNorm.encode(new_class.Canopy);},               setValue:func(v){new_class.Canopy=emesary.TransferNorm.decode(v);}, },
                { getValue:func{return emesary.TransferNorm.encode(new_class.Flaps);},               setValue:func(v){new_class.Flaps=emesary.TransferNorm.decode(v);}, },
                { getValue:func{return emesary.TransferNorm.encode(new_class.GearCompression0);},               setValue:func(v){new_class.GearCompression0=emesary.TransferNorm.decode(v);}, },
                { getValue:func{return emesary.TransferNorm.encode(new_class.GearCompression1);},               setValue:func(v){new_class.GearCompression1=emesary.TransferNorm.decode(v);}, },
                { getValue:func{return emesary.TransferNorm.encode(new_class.GearCompression2);},               setValue:func(v){new_class.GearCompression2=emesary.TransferNorm.decode(v);}, },
                { getValue:func{return emesary.TransferNorm.encode(new_class.GearPosition);},               setValue:func(v){new_class.GearPosition=emesary.TransferNorm.decode(v);}, },
                { getValue:func{return emesary.TransferNorm.encode(new_class.Launchbar);},               setValue:func(v){new_class.Launchbar=emesary.TransferNorm.decode(v);}, },
                { getValue:func{return emesary.TransferNorm.encode(new_class.LeftElevator);},               setValue:func(v){new_class.LeftElevator=emesary.TransferNorm.decode(v);}, },
                { getValue:func{return emesary.TransferNorm.encode(new_class.RightElevator);},               setValue:func(v){new_class.RightElevator=emesary.TransferNorm.decode(v);}, }, 
                { getValue:func{return emesary.TransferNorm.encode(new_class.Ruddder);},               setValue:func(v){new_class.Ruddder=emesary.TransferNorm.decode(v);}, },
                { getValue:func{return emesary.TransferNorm.encode(new_class.Slats);},               setValue:func(v){new_class.Slats=emesary.TransferNorm.decode(v);}, },
                { getValue:func{return emesary.TransferNorm.encode(new_class.SpeedBrake);},               setValue:func(v){new_class.SpeedBrake=emesary.TransferNorm.decode(v);}, },
                { getValue:func{return emesary.TransferNorm.encode(new_class.SpoilerLeft);},               setValue:func(v){new_class.SpoilerLeft=emesary.TransferNorm.decode(v);}, },
                { getValue:func{return emesary.TransferNorm.encode(new_class.SpoilerRight);},               setValue:func(v){new_class.SpoilerRight=emesary.TransferNorm.decode(v);}, },
                { getValue:func{return emesary.TransferNorm.encode(new_class.WingSweep,2);},               setValue:func(v){new_class.WingSweep=emesary.TransferNorm.decode(v);}, },
               ];
         };
       return new_class;
   },
  };
