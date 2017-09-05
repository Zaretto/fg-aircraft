{
dt = $1+30
    elev_cmd = -($2*0.028571429)
print "    <event name=\""dt" second control surface setting to "$2"\">"
print "      <condition> simulation/sim-time-sec >= "dt" </condition>"
print "     <set name=\"fcs/elevator-cmd-norm\" value=\""elev_cmd"\" tc='1' action='FG_RAMP'/>"
print "      <notify>"
print "        <property>aero/alpha-deg</property>"
print "        <property>fcs/elevator-pos-deg</property>"
print "        <property>velocities/mach</property>"
print "        </notify>"
print "    </event>"
    }



