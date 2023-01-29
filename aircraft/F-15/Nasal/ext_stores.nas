#
# F-15 External stores 
# ---------------------------
# Manages the external stores; pylons etc.
# ---------------------------
# Richard Harrison (rjh@zaretto.com) Feb  2015 - based on F-14B version by Alexis Bory

var ExtTanks = props.globals.getNode("sim/model/f15/systems/external-loads/external-tanks");
var WeaponsSet = props.globals.getNode("sim/model/f15/systems/external-loads/external-load-set");
var WeaponsWeight = props.globals.getNode("sim/model/f15/systems/external-loads/weapons-weight", 1);
var PylonsWeight = props.globals.getNode("sim/model/f15/systems/external-loads/pylons-weight", 1);#these are calculated in weapons.nas
var TanksWeight = props.globals.getNode("sim/model/f15/systems/external-loads/tankss-weight", 1);
var S0 = nil;
var S1 = nil;
var S2 = nil;
var S3 = nil;
var S4 = nil;
var S5 = nil;
var S6 = nil;
var S7 = nil;
var S8 = nil;
var S9 = nil;
var S10 = nil;

var droptank_node = props.globals.getNode("sim/ai/aircraft/impact/droptank", 1);

var ext_loads_dlg = gui.Dialog.new("dialog","Aircraft/F-15/Dialogs/external-loads.xml");

Station =
{
   new : func (number)
    {
       var obj = {parents : [Station] };
       obj.prop = props.globals.getNode("sim/model/f15/systems/external-loads/").getChild ("station", number , 1);
       obj.index = number;
       obj.type = obj.prop.getNode("type", 1);
       obj.bcode = 0;
       obj.xbcode = 0;
        obj.set_type(getprop("payload/weight["~number~"]/selected"));
        obj.encode_length = 3; # bits for transmit
       obj.display = obj.prop.initNode("display", 0, "INT");

        # the jsb external loads from 0-9 match the indexes used here incremented by 1 as the first element
        # in jsb sim doesn't have [0]
        var propname = sprintf( "fdm/jsbsim/inertia/pointmass-weight-lbs[%d]",number);

       obj.weight_lb = props.globals.getNode(propname , 1);

       obj.selected = obj.prop.getNode("selected",1);
       append(Station.list, obj);
        #
# set listener to detect when stores changed and update
        setlistener("payload/weight["~obj.index~"]/selected", func(prop){
                        var v = prop.getValue();
                        obj.set_type(v);
                        if (v == "AIM-9")
                            prop.getParent().getNode("weight-lb").setValue(190);
                        elsif (v == "AIM-7")
                        prop.getParent().getNode("weight-lb").setValue(510);
                        elsif (v == "AIM-120")
                        prop.getParent().getNode("weight-lb").setValue(335);
                        elsif (v == "MK-84")
                        prop.getParent().getNode("weight-lb").setValue(2039);
                        elsif (v == "GBU-10")
                        prop.getParent().getNode("weight-lb").setValue(2039);
                        elsif (v == "Droptank")
                        {
                            prop.getParent().getNode("weight-lb").setValue(271);
                        }
                        else
                            prop.getParent().getNode("weight-lb").setValue(0);
                        calculate_weights();
                        update_wpstring();
                    },0,0);

       return obj;
   },
    set_type : func (t) 
    {
       me.type.setValue(t);
       me.bcode = 0;
       me.xbcode = 0;
       if ( t == "AIM-9" )
        {
           me.bcode = 1;
            me.xbcode = 1;
       }
        elsif ( t == "AIM-7" )
        {
           me.bcode = 2;
            me.xbcode = 2;
       } 
        elsif ( t == "AIM-120" )
        {
           me.bcode = 3;
            me.xbcode = 3;
       } 
        elsif ( t == "MK-84" )
        {
           me.bcode = 4;
            me.xbcode = 2;
       } 
        elsif ( t == "Droptank" )
        {
           me.bcode = 5; # although 5 only bit 0 will be used
            me.xbcode = 1;

       }
   },
    get_type : func ()
    {
       return me.type.getValue();  
   },
    set_display : func (n)
    {
       me.display.setValue(n);
   },
    add_weight_lb : func (t)
    {
       w = me.weight_lb.getValue();
       me.weight_lb.setValue( w + t );
   },
    set_weight_lb : func (t)
    {
       me.weight_lb.setValue(t);   
   },
    get_weight_lb : func ()
    {
       return me.weight_lb.getValue(); 
   },
    get_selected : func ()
    {
       return me.selected.getBoolValue();  
   },
    set_selected : func (n)
    {
       me.selected.setBoolValue(n);
   },
    toggle_selected : func ()
    {
       me.selected.setBoolValue( !me.get_selected() );
   },
    list : [],
};

var ext_loads_init = func() {
    print("F-15 External loads init");

#    if (S0 == nil)
#        S0 = Station.new(0);
#    if (S1 == nil)
#    {
#        S1 = Station.new(1);
#        S1.encode_length=2;
#    }
#    if (S2 == nil)
#        S2 = Station.new(2);
#    if (S3 == nil)
#        S3 = Station.new(3);
#    if (S4 == nil)
#        S4 = Station.new(4);
#    if (S5 == nil)
#    {
#        S5 = Station.new(5);
#        S5.encode_length=2;
#    }
#    if (S6 == nil)
#        S6 = Station.new(6);
#    if (S7 == nil)
#        S7 = Station.new(7);
#    if (S8 == nil)
#        S8 = Station.new(8);
#    if (S9 == nil)
#    {
#        S9 = Station.new(9);
#        S9.encode_length=2;
#    }
#    if (S10 == nil)
#        S10 = Station.new(10);
#
##  foreach (var S; Station.list)
##    {
##      S.set_type(S.get_type()); # initialize bcode.
##  }

    if (getprop("sim/model/f15/systems/external-loads/external-load-set") == "clean")  {
#        print(" --> First run: reload Clean");
        first_time_run = 1;
        ext_loads_set("Clean");
    }
    
    update_wpstring();
}
var update_dialog_checkboxes = func
{
    if (getprop("consumables/fuel/tank[5]/selected") != nil)
    {
        setprop ("sim/model/f15/systems/external-loads/external-wing-tanks", getprop("consumables/fuel/tank[5]/selected") or getprop("consumables/fuel/tank[6]/selected"));
        setprop ("sim/model/f15/systems/external-loads/external-centre-tank", getprop("consumables/fuel/tank[7]/selected"));
    }
}

var b_set = 0;
setlistener("sim/model/f15/systems/external-loads/reload-demand", func {
    var v = getprop("sim/model/f15/systems/external-loads/external-load-set");
    if (v != nil) {
        # reload the current set
        ext_loads_set(v);

    }
},0,0);

var ext_loads_set = func(s) {
    # Load sets: Clean, standard combat
    # Load set defines which weapons are mounted.
    # It also defines which pylons are mounted, a pylon may
    # support several weapons.
    var success = 0;
    if ( s == "Clean" ) {
        success = pylons.clean();
    } elsif ( s == "Standard Combat" ) {
        success = pylons.standard();
    } elsif ( s == "Offensive Counter Air" ) {
        success = pylons.counter();
    } elsif ( s == "No Fly Zone" ) {
        success = pylons.nofly();
    } elsif ( s == "Ferry Flight" ) {
        success = pylons.ferry();
    } elsif ( s == "Air Superiority" ) {
        success = pylons.super();
    } elsif ( s == "Ground Attack" ) {
        success = pylons.ground();
    } elsif ( s == "Combat Air Patrol" ) {
        success = pylons.patrol();
    } elsif ( s == "Training" ) {
        success = pylons.train();
    }
    if (success) {
        ext_loads_set2(s);
    }
}

var ext_loads_set2 = func(s)
{
# Load sets: Clean, FAD, FAD light, FAD heavy, Bombcat
# Load set defines which weapons are mounted.
# It also defines which pylons are mounted, a pylon may
# support several weapons.
    WeaponsSet.setValue(s);
    if ( s == "Clean" )
    {
        b_set = 0;
        setprop("payload/weight[1]/selected","none");
        setprop("payload/weight[5]/selected","none");
        setprop("payload/weight[9]/selected","none");

        setprop("consumables/fuel/tank[5]/selected",0);
        setprop("consumables/fuel/tank[6]/selected",0);
        setprop("consumables/fuel/tank[7]/selected",0);

        setprop("consumables/fuel/tank[5]/level-lbs",0);
        setprop("consumables/fuel/tank[6]/level-lbs",0);
        setprop("consumables/fuel/tank[7]/level-lbs",0);

    } 
    elsif ( s == "Standard Combat" )
    {
        b_set = 1;
        setprop("payload/weight[1]/selected","Droptank");
        setprop("payload/weight[5]/selected","none");
        setprop("payload/weight[9]/selected","Droptank");
        setprop("consumables/fuel/tank[5]/selected",1);
        setprop("consumables/fuel/tank[6]/selected",1);
        setprop("consumables/fuel/tank[7]/selected",0);
    } 
    elsif ( s == "Offensive Counter Air" ) 
    {
        b_set = 2;
        setprop("payload/weight[1]/selected","Droptank");
        setprop("payload/weight[5]/selected","none");
        setprop("payload/weight[9]/selected","Droptank");
        setprop("consumables/fuel/tank[5]/selected",1);
        setprop("consumables/fuel/tank[6]/selected",1);
        setprop("consumables/fuel/tank[7]/selected",0);
    } 
    elsif ( s == "No Fly Zone" ) 
    {
        b_set = 3;
        setprop("payload/weight[1]/selected","Droptank");
        setprop("payload/weight[5]/selected","none");
        setprop("payload/weight[9]/selected","Droptank");
        setprop("consumables/fuel/tank[5]/selected",1);
        setprop("consumables/fuel/tank[6]/selected",1);
        setprop("consumables/fuel/tank[7]/selected",0);
    } 
    elsif ( s == "Ferry Flight" ) 
    {
        b_set = 4;
        setprop("payload/weight[1]/selected","Droptank");
        setprop("payload/weight[5]/selected","Droptank");
        setprop("payload/weight[9]/selected","Droptank");
        setprop("consumables/fuel/tank[5]/selected",1);
        setprop("consumables/fuel/tank[6]/selected",1);
        setprop("consumables/fuel/tank[7]/selected",1);
    }
    elsif ( s == "Air Superiority" ) 
    {
        b_set = 5;
        setprop("payload/weight[1]/selected","Droptank");
        setprop("payload/weight[5]/selected","none");
        setprop("payload/weight[9]/selected","Droptank");
        setprop("consumables/fuel/tank[5]/selected",1);
        setprop("consumables/fuel/tank[6]/selected",1);
        setprop("consumables/fuel/tank[7]/selected",0);
    } 
    elsif ( s == "Ground Attack" ) 
    {
        b_set = 6;
        setprop("payload/weight[1]/selected","MK-84");
        setprop("payload/weight[5]/selected","MK-84");
        setprop("payload/weight[9]/selected","MK-84");
        setprop("consumables/fuel/tank[5]/selected",0);
        setprop("consumables/fuel/tank[6]/selected",0);
        setprop("consumables/fuel/tank[7]/selected",0);
    } 
    elsif ( s == "Combat Air Patrol" ) 
    {
        b_set = 7;
        setprop("payload/weight[1]/selected","Droptank");
        setprop("payload/weight[5]/selected","none");
        setprop("payload/weight[9]/selected","Droptank");
        setprop("consumables/fuel/tank[5]/selected",1);
        setprop("consumables/fuel/tank[6]/selected",1);
        setprop("consumables/fuel/tank[7]/selected",0);
    } 
    elsif ( s == "Training" ) 
    {
        b_set = 8;
        setprop("payload/weight[1]/selected","none");
        setprop("payload/weight[5]/selected","Droptank");
        setprop("payload/weight[9]/selected","none");
        setprop("consumables/fuel/tank[5]/selected",0);
        setprop("consumables/fuel/tank[6]/selected",0);
        setprop("consumables/fuel/tank[7]/selected",1);
    } 
    update_dialog_checkboxes();
    update_wpstring();
    arm_selector();
    payload_dialog_reload("ext_loads_set");
}


# Empties (or loads) corresponding Yasim tanks when de-selecting (or selecting)
# external tanks in the External Loads Menu, or when jettisoning external tanks.
# See fuel-system.nas for Left_External.set_level(), Left_External.set_selected()
# and such.

var toggle_ext_tank_selected = func() {
	var ext_tanks = ! ExtTanks.getBoolValue();
	ExtTanks.setBoolValue( ext_tanks );
	if ( ext_tanks ) {
		S2.set_type("external tank");
		S7.set_type("external tank");
		S2.set_weight_lb(250);            # lbs, empty tank weight.
		S7.set_weight_lb(250);
		Left_External.set_level(267);     # US gals, tank fuel contents.
		Right_External.set_level(267);
		Left_External.set_selected(1);
		Right_External.set_selected(1);
	} else {
		S2.set_type("-");
		S7.set_type("-");
		S2.set_weight_lb(0);
		S7.set_weight_lb(0);
		Left_External.set_level(0);
		Right_External.set_level(0);
		Left_External.set_selected(0);
		Right_External.set_selected(0);
	}
    update_wpstring();
}

var update_wp_requested = 0;
var update_wp_next = 0;
var update_wp_frequency_s = 15;
var update_wpstring = func
{
    update_wp_requested = 1;
}

var update_weapons_over_mp = func
{
    var cur_time = getprop("/sim/time/elapsed-sec");
    if (update_wp_requested or cur_time > update_wp_next)
    {
#        printf("Update WP %d, %d : %d",update_wp_next, cur_time, update_wp_requested);
        var b_wpstring = "";
        var aim9_count = 0;
        var aim7_count = 0;
        var aim120_count = 0;
        var agm_count = 0;

        update_wp_next = cur_time + update_wp_frequency_s;
        update_wp_requested = 0;

        foreach (var S; Station.list)
        {
# Use 3 bits per weapon pylon (3 free additional wps types).
# Use 1 bit per fuel tank.
# Use 3 bits for the load sheme (3 free additional shemes).
            var b = "0";
            var s = S.index;
            b = bits.string(S.xbcode,S.encode_length);
            b = substr(b, size(b)-S.encode_length, S.encode_length);
            b_wpstring = b_wpstring ~ b;
#printf("%-5s: %2d(%d): %-4s = %-32s (%d)    ",S.get_type(),S.index,S.encode_length,b, b_wpstring, size(b_wpstring));
            if (S.get_type() == "AIM-9")
                aim9_count = aim9_count+1;
            elsif (S.get_type() == "AIM-7")
                aim7_count = aim7_count+1;
            elsif (S.get_type() == "AIM-120")
                aim120_count = aim120_count+1;
            elsif (S.get_type() == "MK-84")
                agm_count = agm_count+1;
        }
#    print("count ",aim9_count, aim7_count, aim120_count);
        setprop("sim/model/f15/systems/armament/aim9/count",aim9_count);
        setprop("sim/model/f15/systems/armament/aim7/count",aim7_count);
        setprop("sim/model/f15/systems/armament/aim120/count",aim120_count);
        setprop("sim/model/f15/systems/armament/agm/count",agm_count);

        var set = WeaponsSet.getValue();
        b_wpstring = b_wpstring;
# Send the bits string as INT over MP.
        f15_net.send_wps_state(b_wpstring);
#        print("MP String ",b_wpstring,":",b_stores);

    }
}

# Emergency jettison:
# -------------------
setlistener("controls/armament/emergency-jettison", func(v) {
    if (v.getValue() > 0.8) {
        foreach (var T; Tank.list) {
            if (T.is_external())
              T.set_level_lbs(0);
            #                        printf("Set %s to 0",T.get_name());
        }
        setprop("controls/armament/station[1]/jettison-all",1);
        setprop("controls/armament/station[5]/jettison-all",1);
        setprop("controls/armament/station[9]/jettison-all",1);
        setprop("payload/weight[1]/selected","none");
        setprop("payload/weight[5]/selected","none");
        setprop("payload/weight[9]/selected","none");
        setprop("consumables/fuel/tank[5]/selected",0);
        setprop("consumables/fuel/tank[6]/selected",0);
        setprop("consumables/fuel/tank[7]/selected",0);

        foreach (var S; Station.list) {
            setprop("payload/weight["~S.index~"]/selected","none");
        }
        pylons.fcs.jettisonAll();
        update_wpstring();
    }
},0,0);

# Puts the jettisoned tanks models on the ground after impact (THX Vivian Mezza).

var droptanks = func(n) {
	if (wow) { setprop("sim/model/f15/controls/armament/tanks-ground-sound", 1) }
	var droptank = droptank_node.getValue();
	var node = props.globals.getNode(n.getValue(), 1);
	geo.put_model("Aircraft/F-15/Models/Stores/Ext-Tanks/exttank-submodel.xml",
		node.getNode("impact/latitude-deg").getValue(),
		node.getNode("impact/longitude-deg").getValue(),
		node.getNode("impact/elevation-m").getValue()+ 0.4,
		node.getNode("impact/heading-deg").getValue(),
		0,
		0
		);
}

setlistener( "sim/ai/aircraft/impact/droptank", droptanks );

update_dialog_checkboxes();

update_stores_tanks = func(payload_idx){
    payload_stores_node = sprintf("payload/weight[%d]/",payload_idx);
    dialog_stores_node = sprintf("consumables/fuel/tank[%d]/selected",getprop(payload_stores_node~"tank"));
    v = !getprop(dialog_stores_node~"selected");
#    print("update_stores_tanks: ", payload_stores_node, " -> ", dialog_stores_node, " = ",v);
    setprop(dialog_stores_node~"selected", v);
    if (v)      {  
        setprop(payload_stores_node~"selected","Droptank");
    }
    else      {
        setprop(payload_stores_node~"selected","none");
    }
    payload_dialog_reload("update_stores_tanks "~payload_idx);
}

setlistener("sim/model/f15/systems/external-loads/left-wing-tank-demand", func(v) {
    update_stores_tanks(1);
});

setlistener("sim/model/f15/systems/external-loads/right-wing-tank-demand", func(v) {
    update_stores_tanks(9);
});

setlistener("sim/model/f15/systems/external-loads/external-centre-tank-demand", func            {
    update_stores_tanks(5);
});

setlistener("sim/model/f15/systems/external-loads/external-load-set", func(v)            {
#    print("External load set ",v.getValue());
    ext_loads_set(v.getValue());
},0,0);
