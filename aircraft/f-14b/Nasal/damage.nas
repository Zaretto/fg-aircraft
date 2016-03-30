var clamp = func(v, min, max) { v < min ? min : v > max ? max : v }

var TRUE  = 1;
var FALSE = 0;

var warhead_lbs = {
    "aim-120":              44.0,
    "AIM120":               44.0,
    "RB-99":                44.0,
    "aim-7":                88.0,
    "RB-71":                88.0,
    "aim-9":                20.8,
    "RB-24J":               20.8,
    "RB-74":                20.8,
    "R74":                  16.0,
    "MATRA-R530":           55.0,
    "Meteor":               55.0,
    "AIM-54":              135.0,
    "Matra R550 Magic 2":   27.0,
    "Matra MICA":           30.0,
    "RB-15F":             440.92,
    "SCALP":              992.00,
};

var incoming_listener = func {
  var history = getprop("/sim/multiplay/chat-history");
  var hist_vector = split("\n", history);
  if (size(hist_vector) > 0) {
    var last = hist_vector[size(hist_vector)-1];
    var last_vector = split(":", last);
    var author = last_vector[0];
    var callsign = getprop("sim/multiplay/callsign");
    if (size(last_vector) > 1 and author != callsign) {
      # not myself
      #print("not me");
      var m2000 = FALSE;
      if (find(" at " ~ callsign ~ ". Release ", last_vector[1]) != -1) {
        # a m2000 is firing at us
        m2000 = TRUE;
      }
      if (last_vector[1] == " FOX2 at" or last_vector[1] == " aim7 at" or last_vector[1] == " aim9 at"
          or last_vector[1] == " aim120 at" or last_vector[1] == " RB-24J fired at" or last_vector[1] == " RB-74 fired at"
          or last_vector[1] == " RB-71 fired at" or last_vector[1] == " RB-15F fired at"
          or last_vector[1] == " RB-99 fired at" or m2000 == TRUE) {
        # air2air being fired
        if (size(last_vector) > 2 or m2000 == TRUE) {
          #print("Missile launch detected at"~last_vector[2]~" from "~author);
          if (m2000 == TRUE or last_vector[2] == " "~callsign) {
            # its being fired at me
            #print("Incoming!");
            var enemy = getCallsign(author);
            if (enemy != nil) {
              #print("enemy identified");
              var bearingNode = enemy.getNode("radar/bearing-deg");
              if (bearingNode != nil) {
                #print("bearing to enemy found");
                var bearing = bearingNode.getValue();
                var heading = getprop("orientation/heading-deg");
                var clock = bearing - heading;
                while(clock < 0) {
                  clock = clock + 360;
                }
                while(clock > 360) {
                  clock = clock - 360;
                }
                #print("incoming from "~clock);
                if (clock >= 345 or clock < 15) {
                  playIncomingSound("12");
                } elsif (clock >= 15 and clock < 45) {
                  playIncomingSound("1");
                } elsif (clock >= 45 and clock < 75) {
                  playIncomingSound("2");
                } elsif (clock >= 75 and clock < 105) {
                  playIncomingSound("3");
                } elsif (clock >= 105 and clock < 135) {
                  playIncomingSound("4");
                } elsif (clock >= 135 and clock < 165) {
                  playIncomingSound("5");
                } elsif (clock >= 165 and clock < 195) {
                  playIncomingSound("6");
                } elsif (clock >= 195 and clock < 225) {
                  playIncomingSound("7");
                } elsif (clock >= 225 and clock < 255) {
                  playIncomingSound("8");
                } elsif (clock >= 255 and clock < 285) {
                  playIncomingSound("9");
                } elsif (clock >= 285 and clock < 315) {
                  playIncomingSound("10");
                } elsif (clock >= 315 and clock < 345) {
                  playIncomingSound("11");
                } else {
                  playIncomingSound("");
                }
                return;
              }
            }
          }
        }
      } elsif (1 == 1) { # mirage: getprop("/controls/armament/mp-messaging")
        # latest version of failure manager and taking damage enabled
        #print("damage enabled");
        var last1 = split(" ", last_vector[1]);
        if(size(last1) > 2 and last1[size(last1)-1] == "exploded" ) {
          #print("missile hitting someone");
          if (size(last_vector) > 3 and last_vector[3] == " "~callsign) {
            #print("that someone is me!");
            var type = last1[1];
            if (type == "Matra") {
              for (var i = 2; i < size(last1)-1; i += 1) {
                type = type~" "~last1[i];
              }
            }
            var number = split(" ", last_vector[2]);
            var distance = num(number[1]);
            #print(type~"|");
            if(distance != nil) {
              var maxDist = 0;

              if (contains(warhead_lbs, type)) {
                maxDist = maxDamageDistFromWarhead(warhead_lbs[type]);
              } else {
                return;
              }

              var diff = maxDist-distance;
              if (diff < 0) {
                diff = 0;
              }
              
              diff = diff * diff;
              
              var probability = diff / (maxDist*maxDist);

              var failed = fail_systems(probability);
              var percent = 100 * probability;
              print("Took "~percent~"% damage from "~type~" missile at "~distance~" meters distance! "~failed~" systems was hit.");
            }
          } 
        } elsif (last_vector[1] == " M70 rocket hit" or last_vector[1] == " KCA cannon shell hit" or last_vector[1] == " Gun Splash On " or last_vector[1] == " M61A1 shell hit") {
          # cannon hitting someone
          #print("cannon");
          if (size(last_vector) > 2 and last_vector[2] == " "~callsign) {
            # that someone is me!
            #print("hitting me");

            var probability = 0.20; # take 20% damage from each hit
            if (last_vector[1] == " M70 rocket hit" or last_vector[1] == " Gun Splash On ") {
              probability = 0.30;
            }
            var failed = fail_systems(probability);
            print("Took "~probability*100~"% damage from cannon! "~failed~" systems was hit.");
          }
        }
      }
    }
  }
}

var maxDamageDistFromWarhead = func (lbs) {
  # very simple
  var dist = 3*math.sqrt(lbs);

  return dist;
}

var fail_systems = func (probability) {
    var failure_modes = FailureMgr._failmgr.failure_modes;
    var mode_list = keys(failure_modes);
    var failed = 0;
    foreach(var failure_mode_id; mode_list) {
        if (rand() < probability) {
            FailureMgr.set_failure_level(failure_mode_id, 1);
            failed += 1;
        }
    }
    return failed;
};

var playIncomingSound = func (clock) {
  setprop("sound/incoming"~clock, 1);
  settimer(func {stopIncomingSound(clock);},3);
}

var stopIncomingSound = func (clock) {
  setprop("sound/incoming"~clock, 0);
}

var callsign_struct = {};
var getCallsign = func (callsign) {
  var node = callsign_struct[callsign];
  return node;
}

var processCallsigns = func () {
  callsign_struct = {};
  var players = props.globals.getNode("ai/models").getChildren();
  foreach (var player; players) {
    if(player.getChild("valid") != nil and player.getChild("valid").getValue() == TRUE and player.getChild("callsign") != nil and player.getChild("callsign").getValue() != "" and player.getChild("callsign").getValue() != nil) {
      var callsign = player.getChild("callsign").getValue();
      callsign_struct[callsign] = player;
    }
  }
  settimer(processCallsigns, 1.5);
}

processCallsigns();


#f14b
var sendMis = func () {
  var mkeys = keys(fox2.AIM9.active);
  var str = "";
  foreach(var m; mkeys) {
    var mid = m;
    m = fox2.AIM9.active[m];
    if (m.status == 2) {
      var lat = m.latN.getValue();
      var lon = m.lonN.getValue();
      var alt = m.altN.getValue();
      #print();
      #print(mid);
      #print(lat);
      #print(lon);
      #print(alt);
      str = str~mid~";"~lat~";"~lon~";"~alt~":";
    }
  }
  setprop("sim/multiplay/generic/string[13]", str);
  settimer(sendMis,0.05);
}


var logTime = func{
  #log time and date for outputing ucsv files for converting into KML files for google earth.
  if (getprop("logging/log[0]/enabled") == TRUE and getprop("sim/time/utc/year") != nil) {
    var date = getprop("sim/time/utc/year")~"/"~getprop("sim/time/utc/month")~"/"~getprop("sim/time/utc/day");
    var time = getprop("sim/time/utc/hour")~":"~getprop("sim/time/utc/minute")~":"~getprop("sim/time/utc/second");

    setprop("logging/date-log", date);
    setprop("logging/time-log", time);
  }
}

sendMis();

setlistener("/sim/multiplay/chat-history", incoming_listener, 0, 0);