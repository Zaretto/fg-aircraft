# F-15 Canvas MPCD (Multi-Purpose-Colour-Display)
# ---------------------------
# MPCD has many pages; the classes here support multiple pages, menu
# operation and the update loop.
# ---------------------------
# Richard Harrison: 2015-01-23 : rjh@zaretto.com
# ---------------------------

var MPCDcanvas= canvas.new({
                           "name": "F-15 MPCD",
                           "size": [1024,1024], 
                           "view": [740,680],                       
                           "mipmapping": 1     
                          });                          
                          
MPCDcanvas.addPlacement({"node": "MPCDImage"});
MPCDcanvas.setColorBackground(0.003921,0.1764,0, 0);

# Create a group for the parsed elements
var MPCDsvg = MPCDcanvas.createGroup();
 
# Parse an SVG file and add the parsed elements to the given group
print("MPCD : Load SVG ",canvas.parsesvg(MPCDsvg, "Nasal/MPCD/MPCD_0_0.svg"));
#MPCDsvg.setTranslation (-20.0, 37.0);
MPCDsvg.setTranslation (270.0, 197.0);
#print("MPCD INIT");

#
# Menu Id's
# 0           5            
# 1           6            
# 2           7            
# 3           8            
# 4           9            
#
# Top: 10 11 12 13 14 
# Bot: 15 16 17 18 19


var MPCD_Station = {
	new : func (svg, ident)
    {
		var obj = {parents : [MPCD_Station] };

        obj.status = svg.getElementById("PACS_L_"~ident);
        if (obj.status == nil)
            print("Failed to load PACS_L_"~ident);

        obj.label = svg.getElementById("PACS_V_"~ident);
        if (obj.label == nil)
            print("Failed to load PACS_V_"~ident);

        obj.selected = svg.getElementById("PACS_R_"~ident);
        if (obj.selected == nil)
            print("Failed to load PACS_R_"~ident);

        obj.selected1 = svg.getElementById("PACS_R1_"~ident);
        if (obj.selected1 == nil)
            print("Failed to load PACS_R1_"~ident);

        obj.prop = "payload/weight["~ident~"]";
        obj.ident = ident;

        setlistener(obj.prop~"/selected", func(v)
                    {
                        obj.update();
                    });
        setlistener("sim/model/f15/controls/armament/weapons-updated", func
                    {
                        obj.update();
                    });

        obj.update();
        return obj;
    },
    update: func
    {
        var weapon_mode = getprop("sim/model/f15/controls/armament/weapon-selector");
        var na = getprop(me.prop~"/selected");
        var sel = 0;
        var mode = "STBY";
        var sel_node = "sim/model/f15/systems/external-loads/station["~me.ident~"]/selected";
        var master_arm=getprop("sim/model/f15/controls/armament/master-arm-switch");
#        print("Station ",me.ident," update ",sel_node,getprop(sel_node));

        if (na != nil and na != "none")
        {
            if (na == "AIM-9")
            {
                na = "9L";
                if (weapon_mode == 1)
                {
                    sel = getprop(sel_node);
                    if (sel and master_arm)
                        mode = "RDY";
                }
                else mode = "SRM";
            }
            elsif (na == "AIM-120") 
            {
                na = "120A";
                if (weapon_mode == 2)
                {
                    sel = getprop(sel_node);
                    if (sel and master_arm)
                        mode = "RDY";
                }
                else mode = "MRM";
            }
            elsif (na == "AIM-7") 
            {
                na = "7M";
                if (weapon_mode == 2)
                {
                    sel = getprop(sel_node);
                    if (sel and master_arm)
                        mode = "RDY";
                }
                else mode = "MRM";
            }
            me.status.setText(mode);
#            print("NA ",me.ident," ",na);
            me.label.setText(na);

            me.selected1.setVisible(sel);
            if (mode == "RDY")
            {
                me.selected.setVisible(sel);
                me.status.setColor(0,1,0);
            }
            else
            {
                me.selected.setVisible(0);
                me.status.setColor(1,1,1);
            }
        }
        else
        {
            me.status.setText("");
            me.label.setText("");
            me.selected.setVisible(0);
            me.selected1.setVisible(0);
        }
    },
};

var MPCD =  PFD_Device.new(MPCDsvg,20,"MI_");

setlistener("sim/model/f15/controls/MPCD/button-pressed", func(v)
            {
                if (v != nil)
                {
                    if (v.getValue())
                        mpcd_button_pushed = v.getValue();
                    else
                    {
#                        printf("Button %d",mpcd_button_pushed);
                        MPCD.notifyButton(mpcd_button_pushed);
                        mpcd_button_pushed = 0;
                    }
                }
            });
var mpcd_mode = 1;
setlistener("sim/model/f15/controls/MPCD/mode", func(v)
            {
                if (v != nil)
                {
                    var mpcd_mode = v.getValue();
#                    print("MPCD Mode ",mpcd_mode);
#    if (!mpcd_mode)
#        MPCDcanvas.setVisible(0);
#    else
#        MPCDcanvas.setVisible(1);
                }
            });

var p1_1 = MPCD.addPage("Aircraft Menu", "p1_1");
var p1_2 = MPCD.addPage("Top Level PACS Menu", "p1_2");
var p1_3 = MPCD.addPage("PACS Menu", "p1_3");
p1_3.S0 = MPCD_Station.new(MPCDsvg, 0);
#1 droptank
p1_3.S2 = MPCD_Station.new(MPCDsvg, 2);
p1_3.S3 = MPCD_Station.new(MPCDsvg, 3);
p1_3.S4 = MPCD_Station.new(MPCDsvg, 4);
#5 droptank
p1_3.S6 = MPCD_Station.new(MPCDsvg, 6);
p1_3.S7 = MPCD_Station.new(MPCDsvg, 7);
p1_3.S8 = MPCD_Station.new(MPCDsvg, 8);
#9 droptank
p1_3.S10 = MPCD_Station.new(MPCDsvg, 10);

var pjitds_1 = MPCD.addPage("JITDS Decentered", "pjitds_1");
var p_spin_recovery = MPCD.addPage("Spin recovery", "p_spin_recovery");
p_spin_recovery.cur_page = nil;

p1_1.addMenuItem(0, "ARMT", p1_2);
p1_1.addMenuItem(1, "BIT", p1_2);
p1_1.addMenuItem(2, "SIT", pjitds_1);
p1_1.addMenuItem(3, "WPN", p1_2);
p1_1.addMenuItem(4, "DTM", p1_2);

p1_1.date = MPCDsvg.getElementById("p1_1_date");
p1_1.time = MPCDsvg.getElementById("p1_1_time");

p_spin_recovery.p_spin_cas = MPCDsvg.getElementById("p_spin_cas");
p_spin_recovery.p_spin_alt = MPCDsvg.getElementById("p_spin_alt");
p_spin_recovery.p_spin_alpha = MPCDsvg.getElementById("p_spin_alpha");
p_spin_recovery.p_spin_stick_left  = MPCDsvg.getElementById("p_spin_stick_left");
p_spin_recovery.p_spin_stick_right  = MPCDsvg.getElementById("p_spin_stick_right");
p_spin_recovery.update = func
{
    p_spin_recovery.p_spin_alpha.setText(sprintf("%d", getprop ("orientation/alpha-indicated-deg")));
    p_spin_recovery.p_spin_alt.setText(sprintf("%5d", getprop ("instrumentation/altimeter/indicated-altitude-ft")));
    p_spin_recovery.p_spin_cas.setText(sprintf("%3d", getprop ("instrumentation/airspeed-indicator/indicated-speed-kt")));

    if (math.abs(getprop("fdm/jsbsim/velocities/r-rad_sec")) > 0.52631578947368421052631578947368 or math.abs(getprop("fdm/jsbsim/velocities/p-rad_sec")) > 0.022)
    {
        p_spin_recovery.p_spin_stick_left.setVisible(1);
        p_spin_recovery.p_spin_stick_right.setVisible(0);
    }
    else
    {
        p_spin_recovery.p_spin_stick_left.setVisible(0);
        p_spin_recovery.p_spin_stick_right.setVisible(1);
    }

};

p1_1.update = func
{
    var sec = getprop("instrumentation/clock/indicated-sec");
    p1_1.time.setText(getprop("sim/time/gmt-string")~"Z");
    var cdt = getprop("sim/time/gmt");

    if (cdt != nil)
        p1_1.date.setText(substr(cdt,5,2)~"/"~substr(cdt,8,2)~"/"~substr(cdt,2,2)~"Z");
};

p1_2.addMenuItem(1, "A/A", p1_3);
p1_2.addMenuItem(2, "A/G", p1_3);
p1_2.addMenuItem(3, "CBT JETT", p1_3);
p1_2.addMenuItem(4, "WPN LOAD", p1_3);
p1_2.addMenuItem(9, "M", p1_1);

p1_3.gun_rounds = p1_3.addMenuItem(1, sprintf("HIGH\n%dM",getprop("sim/model/f15/systems/gun/rounds")), p1_3);
setlistener("sim/model/f15/systems/gun/rounds", func(v) {
                if (v != nil)
                {
                    p1_3.gun_rounds.title = sprintf("HIGH\n%dM",v.getValue());
                    MPCD.updateMenus();
                }
            });
p1_3.addMenuItem(2, "NML", p1_3);
p1_3.addMenuItem(3, "A/G", p1_3);
p1_3.addMenuItem(4, "2/2", p1_3);
p1_3.addMenuItem(8, "TM\nPWR", p1_3);
p1_3.addMenuItem(9, "M", p1_1);

p1_3.addMenuItem(10, "PYLON", p1_3);
p1_3.addMenuItem(12, "FUEL", p1_3);
p1_3.addMenuItem(14, "PYLON", p1_3);
p1_3.addMenuItem(15, "MODE S", p1_3);
p1_3.addMenuItem(18, "SIT", p1_3);

pjitds_1.addMenuItem(9, "M", p1_1);
MPCD.selectPage(p1_1);
var mpcd_button_pushed = 0;

#
# Time after which the Spin page will be hidden
var mpcd_spin_reset_time = 0;

var updateMPCD = func ()
{  
    # see if spin recovery page needs to be displayed.
    # it is displayed automatically and will remain for 5 seconds.
    # this page provides (sort of) guidance on how to recover from a spin
    # which is identified by the yar rate.
    if (!wow and math.abs(getprop("fdm/jsbsim/velocities/r-rad_sec")) > 0.52631578947368421052631578947368)
    {
        if (MPCD.current_page != p_spin_recovery)
        {
            p_spin_recovery.cur_page = MPCD.current_page;
            MPCD.selectPage(p_spin_recovery);
        }
        mpcd_spin_reset_time = getprop("instrumentation/clock/indicated-sec") + 5;
    }
    else
    {
        if (mpcd_spin_reset_time > 0 and getprop("instrumentation/clock/indicated-sec") > mpcd_spin_reset_time)
        {
            mpcd_spin_reset_time = 0;
            if (p_spin_recovery.cur_page != nil)
            {
                MPCD.selectPage(p_spin_recovery.cur_page);
                p_spin_recovery.cur_page = nil;
            }
        }
    }

    if(mpcd_mode)
        MPCD.update();
}
