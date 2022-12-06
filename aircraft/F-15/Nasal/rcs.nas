#
# Radar Cross-section calculation for radars
# 
# Main author: Pinto
#
# License: GPL 2
#
# The file vector.nas needs to be available in namespace 'vector'.
#

var test = func (echoHeading, echoPitch, echoRoll, bearing, frontRCS) {
  var myCoord = geo.aircraft_position();
  var echoCoord = geo.Coord.new(myCoord);
  echoCoord.apply_course_distance(bearing, 1000);#1km away
  echoCoord.set_alt(echoCoord.alt()+1000);#1km higher than me
  print("RCS final: "~getRCS(echoCoord, echoHeading, echoPitch, echoRoll, myCoord, frontRCS));
};

var rcs_database = {
    #Revision DEC 06 2022
    # This list contains the mandatory RCS frontal values for OPRF (anno 1997), feel free to add non-OPRF to your aircraft, we don't care.
    "default":                  150,    #default value if target's model isn't listed
    "f-14b":                    12,     
    "F-14D":                    12,     
    "f-14b-bs":                 0.0001, #low so it doesn't show up on radar
    "F-15C":                    10,     #low end of sources
    "F-15D":                    11,     #low end of sources
    "f15-bs":                   0.0001,
    "F-16":                     2,
    "JA37-Viggen":              3,      
    "AJ37-Viggen":              3,      #gone
    "AJS37-Viggen":             3,      
    "JA37Di-Viggen":            3,
    "m2000-5":                  1,      
    "m2000-5B":                 1,
    "m2000-5B-backseat":        0.0001,
    "Blackbird-SR71A":          0.25,
    "Blackbird-SR71B":          0.30,
    "Blackbird-SR71A-BigTail":  0.30,
    "MiG-21bis":                3.5,
    "MiG-21MF-75":              3.5,
    "Typhoon":                  0.5,
    "B-1B":                     6,
    "707":                      100,
    "707-TT":                   100,
    "EC-137D":                  110,
    "KC-137R":                  100,
    "KC-137R-RT":               100,
    "C-137R":                   100,
    "RC-137R":                  100,
    "EC-137R":                  110,
    "E-8R":                     100,
    "KC-10A":                   90,
    "KC-10A-GE":                90,
    "KC-30A":                   75,
    "Voyager-KC":               75,
    "c130":                     80,   
    "Jaguar-GR1":               6,
    "Jaguar-GR3":               6,
    "A-10":                     23.5,
    "A-10-model":               23.5,
    "A-10-modelB":              23.5,
# Drones:
    "QF-4E":                    1,
    "MQ-9":                     1,
    "MQ-9-2":                   1,
# Helis:
    "SH-60J":                   20,      
    "UH-60J":                   20,     
    "uh1":                      20,     
    "212-TwinHuey":             19,     
    "412-Griffin":              19,     
    "ch53e":                    30,
    "Mil-Mi-8":                 25,     #guess, Hunter
    "CH47":                     25,     #guess, Hunter
    "mi24":                     25,     #guess, Hunter
    "tigre":                    6,      #guess, Hunter
# OPRF assets:
# Notice that the non-SEA of these have been very reduced to simulate hard to find in ground clutter
    "depot":                    1,
    "ZSU-23-4M":                0.04,
    "SA-6":                     0.10,
    "buk-m2":                   0.08,
    "S-75":                     0.12,
    "s-200":                    0.14,
    "s-300":                    0.16,
    "MIM104D":                  0.15,
    "truck":                    0.02,
    "missile_frigate":          450, 
    "frigate":                  450,
    "tower":                    0.25,   #gone
    "gci":                      0.50,
    "struct":                   1,
    "rig":                      500,
    "point":                    0.7,
    "hunter":                   0.10,    #sea assets, Hunter
# Automats:
    "MiG-29":                   6,
    "SU-27":                    15,
    "daVinci_SU-34":            8,
    "A-50":                     150,
# Hunter ships
    "USS-NORMANDY":             450,    
    "USS-LakeChamplain":        450,    
    "USS-OliverPerry":          450,    
    "USS-SanAntonio":           450,    
};

var prevVisible = {};

var inRadarRange = func (contact, myRadarDistance_nm, myRadarStrength_rcs) {
    return rand() < 0.05?rcs.isInRadarRange(contact, myRadarDistance_nm, myRadarStrength_rcs) == 1:rcs.wasInRadarRange(contact, myRadarDistance_nm, myRadarStrength_rcs);
}

var wasInRadarRange = func (contact, myRadarDistance_nm, myRadarStrength_rcs) {
    var sign = contact.get_Callsign();
    if (sign != nil and contains(prevVisible, sign)) {
        return prevVisible[sign];
    } else {
        return isInRadarRange(contact, myRadarDistance_nm, myRadarStrength_rcs);
    }
}

var isInRadarRange = func (contact, myRadarDistance_nm, myRadarStrength_rcs) {
    if (contact != nil and contact.get_Coord() != nil) {
        var value = 1;
        call(func {value = targetRCSSignal(contact.get_Coord(), contact.get_model(), contact.get_heading(), contact.get_Pitch(), contact.get_Roll(), geo.aircraft_position(), myRadarDistance_nm*NM2M, myRadarStrength_rcs)},nil, var err = []);
        if (size(err)) {
            foreach(line;err) {
                print(line);
            }
            # open radar for one will make this happen.
            return value;
        }
        prevVisible[contact.get_Callsign()] = value;
        return value;
    }
    return 0;
};

#most detection ranges are for a target that has an rcs of 5m^2, so leave that at default if not specified by source material

var targetRCSSignal = func(targetCoord, targetModel, targetHeading, targetPitch, targetRoll, myCoord, myRadarDistance_m, myRadarStrength_rcs = 5) {
    #print(targetModel);
    var target_front_rcs = nil;
    if ( contains(rcs_database,targetModel) ) {
        target_front_rcs = rcs_database[targetModel];
    } else {
        return 1;
        target_front_rcs = rcs_database["default"];
    }
    var target_rcs = getRCS(targetCoord, targetHeading, targetPitch, targetRoll, myCoord, target_front_rcs);
    var target_distance = myCoord.direct_distance_to(targetCoord);

    # standard formula
    var currMaxDist = myRadarDistance_m/math.pow(myRadarStrength_rcs/target_rcs, 1/4);
    return currMaxDist > target_distance;
}

var getRCS = func (echoCoord, echoHeading, echoPitch, echoRoll, myCoord, frontRCS) {
    var sideRCSFactor  = 2.50;
    var rearRCSFactor  = 1.75;
    var bellyRCSFactor = 3.50;
    #first we calculate the 2D RCS:
    var vectorToEcho   = vector.Math.eulerToCartesian2(myCoord.course_to(echoCoord), vector.Math.getPitch(myCoord,echoCoord));
    var vectorEchoNose = vector.Math.eulerToCartesian3X(echoHeading, echoPitch, echoRoll);
    var vectorEchoTop  = vector.Math.eulerToCartesian3Z(echoHeading, echoPitch, echoRoll);
    var view2D         = vector.Math.projVectorOnPlane(vectorEchoTop,vectorToEcho);
    #print("top  "~vector.Math.format(vectorEchoTop));
    #print("nose "~vector.Math.format(vectorEchoNose));
    #print("view "~vector.Math.format(vectorToEcho));
    #print("view2D "~vector.Math.format(view2D));
    var angleToNose    = geo.normdeg180(vector.Math.angleBetweenVectors(vectorEchoNose, view2D)+180);
    #print("horz aspect "~angleToNose);
    var horzRCS = 0;
    if (math.abs(angleToNose) <= 90) {
      horzRCS = extrapolate(math.abs(angleToNose), 0, 90, frontRCS, sideRCSFactor*frontRCS);
    } else {
      horzRCS = extrapolate(math.abs(angleToNose), 90, 180, sideRCSFactor*frontRCS, rearRCSFactor*frontRCS);
    }
    #print("RCS horz "~horzRCS);
    #next we calculate the 3D RCS:
    var angleToBelly    = geo.normdeg180(vector.Math.angleBetweenVectors(vectorEchoTop, vectorToEcho));
    #print("angle to belly "~angleToBelly);
    var realRCS = 0;
    if (math.abs(angleToBelly) <= 90) {
      realRCS = extrapolate(math.abs(angleToBelly),  0,  90, bellyRCSFactor*frontRCS, horzRCS);
    } else {
      realRCS = extrapolate(math.abs(angleToBelly), 90, 180, horzRCS, bellyRCSFactor*frontRCS);
    }
    return realRCS;
};

var extrapolate = func (x, x1, x2, y1, y2) {
    return y1 + ((x - x1) / (x2 - x1)) * (y2 - y1);
};

var getAspect = func (echoCoord, myCoord, echoHeading) {# ended up not using this
    # angle 0 deg = view of front
    var course = echoCoord.course_to(myCoord);
    var heading_offset = course - echoHeading;
    return geo.normdeg180(heading_offset);
};
