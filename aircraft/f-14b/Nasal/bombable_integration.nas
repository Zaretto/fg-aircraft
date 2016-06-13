#
# F-14 Bombable integration  Module 
# ---------------------------
# Richard Harrison (rjh@zaretto.com) 2016-01-06
#
# Notes:
#  Added Nasal from wiki to model xml. Changed agl height; the rest is currently the same
# ---------------------------
#ensure that the following are reset on an init as these are used to detect damage
#        setprop("controls/engines/engine[0]/magnetos",1);
#        setprop("controls/engines/engine[1]/magnetos",1);

var current_damage = 0;

engine_damage = func(damage,engine_number)
{
    if (!damage.getValue() and !getprop("controls/engines/engine["~engine_number~"]/cutoff"))
    {
        setprop("controls/engines/engine["~engine_number~"]/cutoff",1);
        setprop("engines/engine["~engine_number~"]/stalled",1);
        print("engine shutdown ",engine_number);
    }
}

setlistener("/bombable/attributes/damage", func(v)
{
    if (getprop("bombable/menusettings/MP-share-events"))
    {
        if (v.getValue() != current_damage)
        {
            if (v.getValue() > 0.70)
            {
                print("bombable damage ",v.getValue());
                f14.breakWing();
            }
#        if (v.getValue() >= 1)
#        {
#            setprop ("sim/model/f-14b/wings/left-wing-torn", 1);
#            setprop ("sim/model/f-14b/wings/right-wing-torn", 1);
#        }
            current_damage = v.getValue();
        }
    }
});

setlistener("controls/engines/engine[0]/magnetos", func(v)
{
    engine_damage(v, 0);
});

setlistener("controls/engines/engine[1]/magnetos", func(v)
{
    engine_damage(v, 1);
});
