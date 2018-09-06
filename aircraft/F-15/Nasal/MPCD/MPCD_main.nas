# F-15 Canvas MPCD (Multi-Purpose-Colour-Display)
# ---------------------------
# MPCD has many pages; the classes here support multiple pages, menu
# operation and the update loop.
# 2016-05-17: Refactor to use Nasal/canvas/MFD_Generic.nas 
# ---------------------------
# Richard Harrison: 2015-01-23 : rjh@zaretto.com
# ---------------------------

#for debug: setprop ("/sim/startup/terminal-ansi-colors",0);

var MPCD_Station =
{
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
            elsif (na == "MK-84") {
                na = "";
                mode = "";
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

var MPCD_GroundStation =
{
	new : func (svg, ident)
    {
		var obj = {parents : [MPCD_GroundStation] };

        obj.status = svg.getElementById("PACS_L_"~ident~"-g");
        if (obj.status == nil)
            print("Failed to load PACS_L_"~ident~"-g");

        obj.label = svg.getElementById("PACS_V_"~ident~"-g");
        if (obj.label == nil)
            print("Failed to load PACS_V_"~ident~"-g");

        obj.selected = svg.getElementById("PACS_R_"~ident~"-g");
        if (obj.selected == nil)
            print("Failed to load PACS_R_"~ident~"-g");

        obj.selected1 = svg.getElementById("PACS_R1_"~ident~"-g");
        if (obj.selected1 == nil)
            print("Failed to load PACS_R1_"~ident~"-g");

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

        if (na != nil and na != "none")
        {
            if (na == "MK-84")
            {
                na = "84";
                if (weapon_mode == 5)
                {
                    sel = getprop(sel_node);
                    if (sel and master_arm)
                        mode = "RDY";
                }
                else mode = "AG";
            } else {
                mode = "";
                na = "";
            }
            me.status.setText(mode);
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

var MPCD_Device =
{
#
# create new MFD device. This is the main interface (from our code) to the MFD device
# Each MFD device will contain the underlying PFD device object, the SVG, and the canvas
# Parameters
# - designation - Flightdeck Legend for this
# - model_element - name of the 3d model element that is to be used for drawing
# - model_index - index of the device
    new : func(designation, model_element, model_index=0)
    {
        var obj = {parents : [MPCD_Device] };
        obj.designation = designation;
        obj.model_element = model_element;
        var dev_canvas= canvas.new({
                "name": designation,
                           "size": [1024,1024], 
                           "view": [740,680],                       
                    "mipmapping": 1     
                    });                          

        dev_canvas.addPlacement({"node": model_element});
        dev_canvas.setColorBackground(0.003921,0.1764,0, 0);
# Create a group for the parsed elements
        obj.PFDsvg = dev_canvas.createGroup();
        var pres = canvas.parsesvg(obj.PFDsvg, "Nasal/MPCD/MPCD_0_0.svg");
# Parse an SVG file and add the parsed elements to the given group
        printf("MPCD : %s Load SVG %s",designation,pres);
        obj.PFDsvg.setTranslation (270.0, 197.0);
#
# create the object that will control all of this
        obj.num_menu_buttons = 20;
        obj.PFD = PFD_Device.new(obj.PFDsvg, obj.num_menu_buttons, "MI_", dev_canvas);
        obj.PFD._canvas = dev_canvas;
        obj.PFD.designation = designation;
        obj.mfd_device_status = 1;
        obj.model_index = model_index; # numeric index (1 to 9, left to right) used to connect the buttons in the cockpit to the display

#
# Mode switch is day/night/off. we just do on/off
        setlistener("sim/model/f15/controls/MPCD/mode", 
                    func(v)
                    {
                        if (v != nil)
                          {
                              MPCD.mpcd_mode = v.getValue();
                              #    if (!mpcd_mode)
                              #        MPCDcanvas.setVisible(0);
                              #    else
                              #        MPCDcanvas.setVisible(1);
                          }
                    });

        setlistener("instrumentation/radar/radar2-range", 
                    func(v)
                    {
                        setprop("instrumentation/mpcd-sit/inputs/range-nm", v.getValue());
                    });


        obj.addPages();
        return obj;
    },

    addPages : func
    {
        me.p1_1 = me.PFD.addPage("Aircraft Menu", "p1_1");

        me.p1_1.update = func
        {
            var sec = getprop("instrumentation/clock/indicated-sec");
            me.page1_1.time.setText(getprop("sim/time/gmt-string")~"Z");
            var cdt = getprop("sim/time/gmt");

            if (cdt != nil)
                me.page1_1.date.setText(substr(cdt,5,2)~"/"~substr(cdt,8,2)~"/"~substr(cdt,2,2)~"Z");
        };

        me.p1_1 = me.PFD.addPage("Aircraft Menu", "p1_1");
        me.p1_2 = me.PFD.addPage("Top Level PACS Menu", "p1_2");

        me.p1_3 = me.PFD.addPage("PACS Menu", "p1_3");
        me.p1_3.S0 = MPCD_Station.new(me.PFDsvg, 0);
        #1 droptank
        me.p1_3.S2 = MPCD_Station.new(me.PFDsvg, 2);
        me.p1_3.S3 = MPCD_Station.new(me.PFDsvg, 3);
        me.p1_3.S4 = MPCD_Station.new(me.PFDsvg, 4);
        #5 droptank
        me.p1_3.S6 = MPCD_Station.new(me.PFDsvg, 6);
        me.p1_3.S7 = MPCD_Station.new(me.PFDsvg, 7);
        me.p1_3.S8 = MPCD_Station.new(me.PFDsvg, 8);
        #9 droptank
        me.p1_3.S10 = MPCD_Station.new(me.PFDsvg, 10);

        me.p1_3.LBL_CHAFF = me.PFDsvg.getElementById("LBL_CHAFF");
        me.p1_3.LBL_FLARE = me.PFDsvg.getElementById("LBL_FLARE");
        me.p1_3.LBL_NONAVY = me.PFDsvg.getElementById("LBL_NONAVY");
        me.p1_3.LBL_CMD_MSS = me.PFDsvg.getElementById("LBL_CMD_MSS");

## AG page
        me.p1_4 = me.PFD.addPage("PACS Menu", "p1_4");
        me.p1_4.S0 = MPCD_GroundStation.new(me.PFDsvg, 0);
        me.p1_4.S1 = MPCD_GroundStation.new(me.PFDsvg, 1);
        me.p1_4.S2 = MPCD_GroundStation.new(me.PFDsvg, 2);
        me.p1_4.S3 = MPCD_GroundStation.new(me.PFDsvg, 3);
        me.p1_4.S4 = MPCD_GroundStation.new(me.PFDsvg, 4);
        me.p1_4.S5 = MPCD_GroundStation.new(me.PFDsvg, 5);
        me.p1_4.S6 = MPCD_GroundStation.new(me.PFDsvg, 6);
        me.p1_4.S7 = MPCD_GroundStation.new(me.PFDsvg, 7);
        me.p1_4.S8 = MPCD_GroundStation.new(me.PFDsvg, 8);
        me.p1_4.S9 = MPCD_GroundStation.new(me.PFDsvg, 9);
        me.p1_4.S10 = MPCD_GroundStation.new(me.PFDsvg, 10);

        me.p1_4.LBL_CHAFF = me.PFDsvg.getElementById("LBL_CHAFF-g");
        me.p1_4.LBL_FLARE = me.PFDsvg.getElementById("LBL_FLARE-g");
        me.p1_4.LBL_NONAVY = me.PFDsvg.getElementById("LBL_NONAVY-g");
        me.p1_4.LBL_CMD_MSS = me.PFDsvg.getElementById("LBL_CMD_MSS-g");
        me.p1_4.LBL_CBT_g = me.PFDsvg.getElementById("LBL_CBT_g");
        me.p1_4.LBL_CBT2_g = me.PFDsvg.getElementById("LBL_CBT2_g");
        me.p1_4.LBL_CBT_g.setText("A/G");
        me.p1_4.LBL_CBT2_g.setText("---");
        var oo = me;
        var update_flares = func(o) {
            v = getprop("/ai/submodels/submodel[5]/count");
            print("submodel [5]",v);
            
            o.p1_3.LBL_CHAFF.setText(sprintf("CHF %3d",v));
            o.p1_3.LBL_FLARE.setText(sprintf(" FLR %2d",v));
            o.p1_3.LBL_NONAVY.setText("GLOBAL");
            o.p1_4.LBL_CHAFF.setText(sprintf("CHF %3d",v));
            o.p1_4.LBL_FLARE.setText(sprintf(" FLR %2d",v));
            o.p1_4.LBL_NONAVY.setText("GLOBAL");
        };
        update_flares(oo);
        setlistener("ai/submodels/submodel[5]/flare-release", func {
            update_flares(oo);
        });


        me.pjitds_1 =  PFD_NavDisplay.new(me.PFD,"Situation", "mpcd-sit", "pjitds_1", "jtids_main");
        # use the radar range as the ND range.

        me.p_spin_recovery = me.PFD.addPage("Spin recovery", "p_spin_recovery");
        me.p_spin_recovery.cur_page = nil;

        me.p1_1.date = me.PFDsvg.getElementById("p1_1_date");
        me.p1_1.time = me.PFDsvg.getElementById("p1_1_time");

        me.p_spin_recovery.p_spin_cas = me.PFDsvg.getElementById("p_spin_cas");
        me.p_spin_recovery.p_spin_alt = me.PFDsvg.getElementById("p_spin_alt");
        me.p_spin_recovery.p_spin_alpha = me.PFDsvg.getElementById("p_spin_alpha");
        me.p_spin_recovery.p_spin_stick_left  = me.PFDsvg.getElementById("p_spin_stick_left");
        me.p_spin_recovery.p_spin_stick_right  = me.PFDsvg.getElementById("p_spin_stick_right");
        me.p_spin_recovery.update = func
        {
            me.p_spin_alpha.setText(sprintf("%d", getprop ("orientation/alpha-indicated-deg")));
            me.p_spin_alt.setText(sprintf("%5d", getprop ("instrumentation/altimeter/indicated-altitude-ft")));
            me.p_spin_cas.setText(sprintf("%3d", getprop ("instrumentation/airspeed-indicator/indicated-speed-kt")));

            if (math.abs(getprop("fdm/jsbsim/velocities/r-rad_sec")) > 0.52631578947368421052631578947368 
                or math.abs(getprop("fdm/jsbsim/velocities/p-rad_sec")) > 0.022)
            {
                me.p_spin_stick_left.setVisible(1);
                me.p_spin_stick_right.setVisible(0);
            }
            else
            {
                me.p_spin_stick_left.setVisible(0);
                me.p_spin_stick_right.setVisible(1);
            }
        };

        #
        # Page 1 is the time display
        me.p1_1.update = func
        {
            var sec = getprop("instrumentation/clock/indicated-sec");
            me.time.setText(getprop("sim/time/gmt-string")~"Z");
            var cdt = getprop("sim/time/gmt");

            if (cdt != nil)
                me.date.setText(substr(cdt,5,2)~"/"~substr(cdt,8,2)~"/"~substr(cdt,2,2)~"Z");
        };

        #
        # armament page gun rounds is implemented a little differently as the menu item (1) changes to show
        # the contents of the magazine.
        me.p1_3.gun_rounds = me.p1_3.addMenuItem(1, sprintf("HIGH\n%dM",getprop("sim/model/f15/systems/gun/rounds")), me.p1_3);

        setlistener("sim/model/f15/systems/gun/rounds", func(v)
                    {
                        if (v != nil) {
                            me.p1_3.gun_rounds.title = sprintf("HIGH\n%dM",v.getValue());
                            me.PFD.updateMenus();
                        }
                    }
            );
        me.p1_4.gun_rounds = me.p1_4.addMenuItem(1, sprintf("HIGH\n%dM",getprop("sim/model/f15/systems/gun/rounds")), me.p1_4);
        setlistener("sim/model/f15/systems/gun/rounds", func(v)
                    {
                        if (v != nil) {
                            me.p1_4.gun_rounds.title = sprintf("HIGH\n%dM",v.getValue());
                            me.PFD.updateMenus();
                        }
                    }
            );

        me.PFD.selectPage(me.p1_1);
        me.mpcd_button_pushed = 0;
        # Connect the buttons - using the provided model index to get the right ones from the model binding
        setlistener("sim/model/f15/controls/MPCD/button-pressed", func(v)
                    {
                        if (v != nil) {
                            if (v.getValue())
                                me.mpcd_button_pushed = v.getValue();
                            else {
                                printf("%s: Button %d",me.designation, me.mpcd_button_pushed);
                                me.PFD.notifyButton(me.mpcd_button_pushed);
                                me.mpcd_button_pushed = 0;
                            }
                        }
                    }
            );

        # Set listener on the PFD mode button; this could be an on off switch or by convention
        # it will also act as brightness; so 0 is off and anything greater is brightness.
        # ranges are not pre-defined; it is probably sensible to use 0..10 as an brightness rather
        # than 0..1 as a floating value; but that's just my view.
        setlistener("sim/model/f15/controls/PFD/mode"~me.model_index, func(v)
                    {
                        if (v != nil) {
                            me.mfd_device_status = v.getValue();
                            print("MFD Mode ",me.designation," ",me.mfd_device_status);
                            if (!me.mfd_device_status)
                                me.PFDsvg.setVisible(0);
                            else
                                me.PFDsvg.setVisible(1);
                        }
                    }
            );

        me.mpcd_button_pushed = 0;
        me.setupMenus();
        me.PFD.selectPage(me.p1_1);
    },

    # Add the menus to each page. 
    setupMenus : func
    {
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
        me.mpcd_spin_reset_time = 0;

        me.p1_1.addMenuItem(0, "ARMT", me.p1_2);
        me.p1_1.addMenuItem(1, "BIT", me.p1_2);
        me.p1_1.addMenuItem(2, "SIT", me.pjitds_1);
        me.p1_1.addMenuItem(3, "WPN", me.p1_2);
        me.p1_1.addMenuItem(4, "DTM", me.p1_2);

        me.p1_2.addMenuItem(1, "A/A", me.p1_3);
        me.p1_2.addMenuItem(2, "A/G", me.p1_4);
        me.p1_2.addMenuItem(3, "CBT JETT", me.p1_3);
        me.p1_2.addMenuItem(4, "WPN LOAD", me.p1_3);
        me.p1_2.addMenuItem(9, "M", me.p1_1);

        me.p1_3.addMenuItem(2, "SIT", me.pjitds_1);
        me.p1_3.addMenuItem(3, "A/G", me.p1_4);
        me.p1_3.addMenuItem(4, "2/2", me.p1_3);
        me.p1_3.addMenuItem(8, "TM\nPWR", me.p1_3);
        me.p1_3.addMenuItem(9, "M", me.p1_1);
        me.p1_3.addMenuItem(10, "PYLON", me.p1_3);
        me.p1_3.addMenuItem(12, "FUEL", me.p1_3);
        me.p1_3.addMenuItem(14, "PYLON", me.p1_3);
        me.p1_3.addMenuItem(15, "MODE S", me.p1_3);

        me.p1_4.addMenuItem(2, "SIT", me.pjitds_1);
        me.p1_4.addMenuItem(3, "A/A", me.p1_3);
#        me.p1_4.addMenuItem(4, "2/2", me.p1_3);
#        me.p1_4.addMenuItem(8, "TM\nPWR", me.p1_3);
        me.p1_4.addMenuItem(9, "M", me.p1_1);
#        me.p1_4.addMenuItem(10, "PYLON", me.p1_4);
#        me.p1_4.addMenuItem(12, "FUEL", me.p1_4);
#        me.p1_4.addMenuItem(14, "PYLON", me.p1_4);
#        me.p1_4.addMenuItem(15, "MODE S", me.p1_3);


        me.pjitds_1.addMenuItem(9, "M", me.p1_1);
    },

    update : func
    {
    # see if spin recovery page needs to be displayed.
    # it is displayed automatically and will remain for 5 seconds.
    # this page provides (sort of) guidance on how to recover from a spin
    # which is identified by the yar rate.
        if (!wow and math.abs(getprop("fdm/jsbsim/velocities/r-rad_sec")) > 0.52631578947368421052631578947368)
        {
            if (me.PFD.current_page != me.p_spin_recovery)
            {
                me.p_spin_recovery.cur_page = me.PFD.current_page;
                me.PFD.selectPage(me.p_spin_recovery);
            }
            me.mpcd_spin_reset_time = getprop("instrumentation/clock/indicated-sec") + 5;
        } 
        else
        {
            if (me.mpcd_spin_reset_time > 0 and getprop("instrumentation/clock/indicated-sec") > me.mpcd_spin_reset_time)
            {
                me.mpcd_spin_reset_time = 0;
                if (me.p_spin_recovery.cur_page != nil)
                {
                    me.PFD.selectPage(me.p_spin_recovery.cur_page);
                    me.p_spin_recovery.cur_page = nil;
                }
            }
        }

        if (me.mfd_device_status)
            me.PFD.update();
    },
};

#
# Create the MPCD device 
var MPCD =  nil;

var updateMPCD = func ()
{  
    if (MPCD == nil)
      MPCD = MPCD_Device.new("F15-MPCD", "MPCDImage",0);
    MPCD.update();
}


#
# Connect the radar range to the nav display range. 
setprop("instrumentation/mpcd-sit/inputs/range-nm", getprop("instrumentation/radar/radar2-range"));
