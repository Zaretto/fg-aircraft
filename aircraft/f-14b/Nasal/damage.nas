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
    "KN-06":              315.00,
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
      } elsif (getprop("sim/model/f-14b/systems/armament/mp-messaging") == 1) { # mirage: getprop("/controls/armament/mp-messaging")
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
              distance = clamp(distance-3, 0, 1000000);
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
              nearby_explosion();
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
            nearby_explosion();
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

var nearby_explosion = func {
  setprop("damage/sounds/nearby-explode-on", 0);
  settimer(nearby_explosion_a, 0);
}

var nearby_explosion_a = func {
  setprop("damage/sounds/nearby-explode-on", 1);
  settimer(nearby_explosion_b, 0.5);
}

var nearby_explosion_b = func {
  setprop("damage/sounds/nearby-explode-on", 0);
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

var ct = func (type) {
  if (type == "c-u") {
    setprop("sim/ct/c-u", 1);
  }
  if (type == "rl" and getprop("fdm/jsbsim/gear/unit[0]/WOW") != TRUE) {
    setprop("sim/ct/rl", 1);
  }
  if (type == "rp" and getprop("fdm/jsbsim/gear/unit[0]/WOW") != TRUE) {
    setprop("sim/ct/rp", 1);
  }
  if (type == "a") {
    setprop("sim/ct/a", 1);
  }
  if (type == "lst") {
    setprop("sim/ct/list", 1);
  }
  if (type == "ifa" and getprop("fdm/jsbsim/gear/unit[0]/WOW") != TRUE) {
    setprop("sim/ct/ifa", 1);
  }
  if (type == "sf" and getprop("fdm/jsbsim/gear/unit[0]/WOW") != TRUE) {
    setprop("sim/ct/sf", 1);
  }
}

var lf = -1;
var ll = 0;

var code_ct = func () {
  var cu = getprop("sim/ct/c-u");
  if (cu == nil or cu != 1) {
    cu = 0;
  }
  var a = getprop("sim/ct/a");
  if (a == nil or a != 1) {
    a = 0;
  }
  var ff = getprop("sim/freeze/fuel");
  if (ff == nil) {
    ff = 0;
  } elsif (ff == 1) {
    setprop("sim/ct/ff", 1);
  }
  ff = getprop("sim/ct/ff");
  if (ff == nil or ff != 1) {
    ff = 0;
  }
  var cl =  getprop("fdm/jsbsim/inertia/pointmass-weight-lbs[0]")+getprop("fdm/jsbsim/inertia/pointmass-weight-lbs[1]")
           +getprop("fdm/jsbsim/inertia/pointmass-weight-lbs[2]")+getprop("fdm/jsbsim/inertia/pointmass-weight-lbs[3]")
           +getprop("fdm/jsbsim/inertia/pointmass-weight-lbs[4]")+getprop("fdm/jsbsim/inertia/pointmass-weight-lbs[5]")
           +getprop("fdm/jsbsim/inertia/pointmass-weight-lbs[6]")+getprop("fdm/jsbsim/inertia/pointmass-weight-lbs[7]")
           +getprop("fdm/jsbsim/inertia/pointmass-weight-lbs[8]")+getprop("fdm/jsbsim/inertia/pointmass-weight-lbs[9]");
  if (cl > (ll*1.05) and getprop("fdm/jsbsim/gear/unit[0]/WOW") != TRUE) {
    setprop("sim/ct/rl", 1);
  }
  ll = cl;
  var rl = getprop("sim/ct/rl");
  if (rl == nil or rl != 1) {
    rl = 0;
  }
  var rp = getprop("sim/ct/rp");
  if (rp == nil or rp != 1) {
    rp = 0;
  }
  var cf =   getprop("/consumables/fuel/tank[0]/level-gal_us")
            +getprop("/consumables/fuel/tank[1]/level-gal_us")
            +getprop("/consumables/fuel/tank[2]/level-gal_us")
            +getprop("/consumables/fuel/tank[3]/level-gal_us")
            +getprop("/consumables/fuel/tank[4]/level-gal_us")
            +getprop("/consumables/fuel/tank[5]/level-gal_us")
            +getprop("/consumables/fuel/tank[6]/level-gal_us")
            +getprop("/consumables/fuel/tank[7]/level-gal_us")
            +getprop("/consumables/fuel/tank[8]/level-gal_us")
            +getprop("/consumables/fuel/tank[9]/level-gal_us")
            +getprop("/consumables/fuel/tank[10]/level-gal_us")
            +getprop("/consumables/fuel/tank[11]/level-gal_us");
  if (cf != nil and lf != -1 and cf > (lf*1.1) and getprop("fdm/jsbsim/gear/unit[0]/WOW") != TRUE) {
    setprop("sim/ct/rf", 1);
  }
  var rf = getprop("sim/ct/rf");
  if (rf == nil or rf != 1) {
    rf = 0;
  }
  lf = cf == nil?0:cf;
  var dm = !getprop("sim/model/f-14b/systems/armament/mp-messaging");
  if (dm == nil or dm != 1) {
    dm = 0;
  }
  var tm = 0;#getprop("sim/ja37/radar/look-through-terrain");
  if (tm == nil or tm != 1) {
    tm = 0;
  }
  var rd = 0;#!getprop("sim/ja37/radar/doppler-enabled");
  if (rd == nil or rd != 1) {
    rd = 0;
  }  
  var ml = getprop("sim/ct/list");
  if (ml == nil or ml != 1) {
    ml = 0;
  }
  var sf = getprop("sim/ct/sf");
  if (sf == nil or sf != 1) {
    sf = 0;
  }
  var ifa = getprop("sim/ct/ifa");
  if (ifa == nil or ifa != 1) {
    ifa = 0;
  }
  var final = "ct"~cu~ff~rl~rf~rp~a~dm~tm~rd~ml~sf~ifa;
  setprop("sim/multiplay/generic/string[15]", final);
  settimer(code_ct, 2);
}

var not = func {
  if (getprop("sim/model/f-14b/systems/armament/mp-messaging") == TRUE and getprop("fdm/jsbsim/gear/unit[0]/WOW") != TRUE) {
    var ct = getprop("sim/multiplay/generic/string[15]") ;
    var msg = "I might be chea"~"ting..";
    if (ct != nil) {
      msg = "I might be chea"~"ting.."~ct;
      var spl = split("ct", ct);
      if (size(spl) > 1) {
        var bits = spl[1];
        msg = "I ";
        if (bits == "000000000000") {
          settimer(not, 60);
          return;
        }
        if (substr(bits,0,1) == "1") {
          msg = msg~"Used CT"~"RL-U..";
        }
        if (substr(bits,1,1) == "1") {
          msg = msg~"Use fuelf"~"reeze..";
        }
        if (substr(bits,2,1) == "1") {
          msg = msg~"Relo"~"aded in air..";
        }
        if (substr(bits,3,1) == "1") {
          msg = msg~"Refue"~"led in air..";
        }
        if (substr(bits,4,1) == "1") {
          msg = msg~"Repa"~"ired not on ground..";
        }
        if (substr(bits,5,1) == "1") {
          msg = msg~"Used time"~"warp..";
        }
        if (substr(bits,6,1) == "1") {
          msg = msg~"Have dam"~"age off..";
        }
        if (substr(bits,7,1) == "1") {
          msg = msg~"Have Ter"~"rain mask. off..";
        }
        if (substr(bits,8,1) == "1") {
          msg = msg~"Have Dop"~"pler off..";
        }
        if (substr(bits,9,1) == "1") {
          msg = msg~"Had mp-l"~"ist on..";
        }
        if (substr(bits,10,1) == "1") {
          msg = msg~"Had s-fai"~"lures open..";
        }
        if (substr(bits,11,1) == "1") {
          msg = msg~"Had i-fa"~"ilures open..";
        }
      }
    }
    setprop("/sim/multiplay/chat", msg);
  }
  settimer(not, 60);
}

var changeGuiLoad = func()
{#return;
    var searchname1 = "mp-list";
    var searchname2 = "instrument-failures";
    var searchname3 = "system-failures";
    var state = 0;
    
    foreach(var menu ; props.globals.getNode("/sim/menubar/default").getChildren("menu")) {
        foreach(var item ; menu.getChildren("item")) {
            foreach(var name ; item.getChildren("name")) {
                if(name.getValue() == searchname1) {
                    #var e = item.getNode("enabled").getValue();
                    #var path = item.getPath();
                    #item.remove();
                    #item = props.globals.getNode(path,1);
                    #item.getNode("enabled",1).setBoolValue(FALSE);
                    #item.getNode("binding").remove();
                    #item.getNode("name",1).setValue(searchname1);
                    item.getNode("binding/command").setValue("nasal");
                    item.getNode("binding/script").setValue("fox2.loadMPList()");
                    #item.getNode("enabled",1).setBoolValue(TRUE);
                }
                if(name.getValue() == searchname2) {
                    item.getNode("binding/command").setValue("nasal");
                    item.getNode("binding/dialog-name").remove();
                    item.getNode("binding/script",1).setValue("fox2.loadIFail()");
                }
                if(name.getValue() == searchname3) {
                    item.getNode("binding/command").setValue("nasal");
                    item.getNode("binding/dialog-name").remove();
                    item.getNode("binding/script",1).setValue("fox2.loadSysFail()");
                }
            }
        }
    }
    fgcommand("reinit", props.Node.new({"subsystem":"gui"}));
}

var loadMPList = func () {
  ct("lst");multiplayer.dialog.show();
}

var loadSysFail = func () {
  ct("sf");fgcommand("dialog-show", props.Node.new({"dialog-name":"system-failures"}));
}

var loadIFail = func () {
  ct("ifa");fgcommand("dialog-show", props.Node.new({"dialog-name":"instrument-failures"}));
}

setlistener("/sim/multiplay/chat-history", incoming_listener, 0, 0);

setprop("/sim/failure-manager/display-on-screen", FALSE);

changeGuiLoad();
settimer(code_ct, 10);
settimer(not, 11);

var re_init = func {
  # repair the aircraft

  var failure_modes = FailureMgr._failmgr.failure_modes;
  var mode_list = keys(failure_modes);

  foreach(var failure_mode_id; mode_list) {
    FailureMgr.set_failure_level(failure_mode_id, 0);
  }
}

setlistener("/sim/signals/reinit", re_init, 0, 0);