###############################################################################
## $Id$
##
## Nasal for MP-passenger on the MD500E over the multiplayer network.
##
##  Copyright (C) 2009  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license version 2 or later.
##
###############################################################################

# Renaming (almost :)
var DCT = dual_control_tools;

######################################################################
# Pilot/copilot aircraft identifiers. Used by dual_control.
var pilot_type   = "Aircraft/ch53e/Models/ch53e.xml";
var copilot_type = "";

props.globals.initNode("/sim/remote/pilot-callsign", "", "STRING");

######################################################################
# MP enabled properties.
# NOTE: These must exist very early during startup - put them
#       in the -set.xml file.


######################################################################
# Useful local property paths.

######################################################################
# Slow state properties for replication.


###############################################################################
# Pilot MP property mappings and specific copilot connect/disconnect actions.


######################################################################
# Used by dual_control to set up the mappings for the pilot.
var pilot_connect_copilot = func (copilot) {
    return 
        [
         ######################################################################
         # Process received properties.
         ######################################################################
         ######################################################################
         # Process properties to send.
         ######################################################################
        ];
}

######################################################################
var pilot_disconnect_copilot = func {
}


###############################################################################
# Copilot MP property mappings and specific pilot connect/disconnect actions.


######################################################################
# Used by dual_control to set up the mappings for the copilot.
var copilot_connect_pilot = func (pilot) {
    # Initialize Nasal wrappers for copilot pick anaimations.
    set_copilot_wrappers(pilot);

    return
        [
         ######################################################################
         # Process received properties.
         ######################################################################
         ######################################################################
         # Process properties to send.
         ######################################################################
        ];
}

######################################################################
var copilot_disconnect_pilot = func {
    # Reset local sound properties.
    p = "engines/engine/rpm";
    props.globals.getNode(p).unalias();
    props.globals.getNode(p).setValue(0);
    p = "gear/gear[0]/compression-norm";
    props.globals.getNode(p).unalias();
    props.globals.getNode(p).setValue(0);
    p = "gear/gear[1]/compression-norm";
    props.globals.getNode(p).unalias();
    props.globals.getNode(p).setValue(0);
}

######################################################################
# Copilot Nasal wrappers

var set_copilot_wrappers = func (pilot) {
    # Setup aliases to animate the MP 3d model.
    var p = "instrumentation/magnetic-compass/indicated-heading-deg";
    pilot.getNode(p,1).alias(props.globals.getNode(p));

    # Setup aliases to drive local sound.
    p = "engines/engine/rpm";
    props.globals.getNode(p).alias(pilot.getNode(p));
    p = "surface-positions/flap-pos-norm";
    props.globals.getNode(p).alias(pilot.getNode(p));
    p = "gear/gear[0]/compression-norm";
    props.globals.getNode(p).alias(pilot.getNode(p));
    p = "gear/gear[1]/compression-norm";
    props.globals.getNode(p).alias(pilot.getNode(p));
}
