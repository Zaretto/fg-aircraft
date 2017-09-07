# Generic Page switching cockpit display device.
# I'm calling this a PFD as im Programmable Function Display.
# ---------------------------
# See FGAddon/Aircraft/F-15/Nasal/MPCD/MPCD_main.nas for an example usage
# ---------------------------
# This is but a straightforwards wrapper to provide the core logic that page switching displays require.
# Page switching displays
# * MFD
# * PFD
# * FMCS
# etc.
# Based on F-15 MPCD
# ---------------------------
# Richard Harrison: 2015-10-17 : rjh@zaretto.com
# ---------------------------

#
# Menu Item. There is a list of these for each page changing button per display page
# Parameters:
# menu_id : page change event id for this menu item. e.g. button number
# title   : Title Text (for display on the device)
# page    : Instance of page usually returned from PFD.addPage

var PFD_MenuItem = {
    new : func (menu_id, title, page)
    {
		var obj = {parents : [PFD_MenuItem] };
        obj.page = page;
        obj.menu_id = menu_id;
        obj.title = title;
#       printf("New MenuItem %s,%s,%s",menu_id, title, page);
        return obj;
    },
};

#
#
# Create a new PFD Page
# - related svg 
# - Title: Page title
# - SVG element for the page
# - Device to attach the page to

var PFD_Page = {
	new : func (svg, title, layer_id, device)
    {
		var obj = {parents : [PFD_Page] };
        obj.title = title;
        obj.device = device;
        obj.layer_id = layer_id;
        obj.menus = [];
#        print("Load page ",title);
        obj.svg = svg.getElementById(layer_id);
        if(obj.svg == nil)
            printf("PFD_Device: Error loading %s: svg layer %s ",title, layer_id);

        return obj;
    },
#
#
# Makes a page visible. 
# It is the responsibility of the caller to manage the visibility of pages - i.e. to 
# make a page that is currenty visible not visible before making a new page visible,
# however more than one page could be visible - but only one set of menu buttons can be active
# so if two pages are visible (e.g. an overlay) then when the overlay removed it would be necessary
# to call setVisible on the base page to ensure that the menus are seutp
    setVisible : func(vis)
    {
        if(me.svg != nil)
            me.svg.setVisible(vis);
#        print("Set visible ",me.layer_id);

        if (vis)
        {
            me.ondisplay();
            foreach(mi ;  me.menus)
            {
#                printf("load menu %s %\n",mi.title, mi);
            }
        }
        else
            me.offdisplay();
    },
#
#
# Perform action when button is pushed
    notifyButton : func(button_id) 
    {
        foreach(var mi; me.menus)
        {
            if (mi.menu_id == button_id)
            {
#                     printf("Page: found button %s, selecting page\n",mi.title);
                me.device.selectPage(mi.page);
                break;
            }
        }
    },

# 
# Add an item to a menu
# Params:
#  menu button id (that is set in controls/PFD/button-pressed by the model)
#  title of the menu for the label
#  page that will be selected when pressed
# 
# The corresponding menu for the selected page will automatically be loaded
    addMenuItem : func(menu_id, title, page)
    {
        var nm = PFD_MenuItem.new(menu_id, title, page);
#        printf("New menu %s %s on page ", menu_id, title, page.layer_id);
        append(me.menus, nm);
#        printf("Page %s: add menu %s [%s]",me.layer_id, menu_id, title);
#            foreach(mi ; me.menus)
        #            {
#                printf("--menu %s",mi.title);
        #            }
        return nm;
    },
# base method for update; this can be overriden per page instance to provide update of the
# elements on display (e.g. to display updated properties)
    update : func
    {
    },
#
# notify the page that it is being displayed. use to load any static framework or perform one
# time initialisation
    ondisplay : func
    {
    },
#
# notify the page that it is going off display; use to clean up any created elements or perform
# any other required functions

    offdisplay : func
    {
    },
};


var PFD_Device =
{
#
# create  acontainer device for pages.
# - svg is the page elements from the svg.
# - num_menu_buttons is the Number of menu buttons; starting from the bottom left then right, then top, then left.
# -  button prefix (e.g MI_) is the prefix of the labels in the SVG for the menu boxes.
    new : func(svg, num_menu_buttons, button_prefix)
    {
		var obj = {parents : [PFD_Device] };
        obj.svg = svg;
        obj.current_page = nil;
        obj.pages = [];
        obj.buttons = setsize([], num_menu_buttons);

        for(var idx = 0; idx < num_menu_buttons; idx += 1)
        {
            var label_name = sprintf(button_prefix~"%d",idx);
            var msvg = obj.svg.getElementById(label_name);
            if (msvg == nil)
                printf("PFD_Device: Failed to load  %s",label_name);
            else
            {
                obj.buttons[idx] = msvg;
                obj.buttons[idx].setText(sprintf("M",idx));
            }
        }
#        for(var idx = 0; idx < size(obj.buttons); idx += 1)
#        {
#            printf("Button %d %s",idx,obj.buttons[idx]);
#        }
        return obj;
    },
#
# called when a button is pushed
    notifyButton : func(button_id)
    {
        #
        #
# by convention the buttons we have are 0 based; however externally 0 is used
# to indicate no button pushed.
        if (button_id > 0)
        {
            button_id = button_id - 1;
            if (me.current_page != nil)
            {
#                printf("Button routing to %s",me.current_page.title);
                me.current_page.notifyButton(button_id);
            }
            else
                printf("PFD_Device: Could not locate page for button ",button_id);
        }
    },
#
#
# add a page to the device.
# - page title.
# - svg element id
    addPage : func(title, layer_id)
    {
        var np = PFD_Page.new(me.svg, title, layer_id, me);
        append(me.pages, np);
        np.setVisible(0);
        return np;
    },
#
# manage the update of the currently selected page
    update : func
    {
        if (me.current_page != nil)
            me.current_page.update();
    },
#
# select a page for display.
    selectPage : func(p)
    {
        if (me.current_page != nil)
            me.current_page.setVisible(0);
        if (me.buttons != nil)
        {
            foreach(var mb ; me.buttons)
                if (mb != nil)
                    mb.setVisible(0);

            foreach(var mi ; p.menus)
            {
#                printf("selectPage: load menu %d %s",mi.menu_id, mi.title);
                if (me.buttons[mi.menu_id] != nil)
                {
                    me.buttons[mi.menu_id].setText(mi.title);
                    me.buttons[mi.menu_id].setVisible(1);
                }
                else
                    printf("PFD_device: Menu for button not found. Menu ID '%s'",mi.menu_id);
            }
        }
        p.setVisible(1);
        me.current_page = p;
    },
};

