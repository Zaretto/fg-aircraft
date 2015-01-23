# F-15 TEWS


var TEWScanvas= canvas.new({
                           "name": "F-15 TEWS",
                           "size": [1024,1024], 
                           "view": [256,256],                       
                           "mipmapping": 1     
                          });                          
                          
TEWScanvas.addPlacement({"node": "TEWSImage"});
TEWScanvas.setColorBackground(0.0039215686274509803921568627451,0.17647058823529411764705882352941,0, 0.00);

# Create a group for the parsed elements
var TEWSsvg = TEWScanvas.createGroup();
 
# Parse an SVG file and add the parsed elements to the given group
print("Parse SVG ",canvas.parsesvg(TEWSsvg, "Nasal/TEWS/TEWS.svg"));
#TEWSsvg.setTranslation (-20.0, 37.0);
print("TEWS INIT");
 
#var window1 = TEWSsvg.getElementById("window-1");
#window1.setFont("condensed.txf").setFontSize(12, 1.2);
#acue.setVisible(0);

var TEWSSymbol = {
	new : func (id, svg, base){
		var obj = {parents : [TEWSSymbol] };
        var svg_idx = id+1;
        var name = base~"_"~svg_idx;
        var label_name = base~"_label_"~svg_idx;
        obj.name = base~"_"~svg_idx;
        obj.valid = 0;
        var sym = svg.getElementById(name);
        if (sym != nil)
        {
            obj.symbol = sym;
            var sym = svg.getElementById(label_name);
            if (sym != nil)
            {
                obj.label = sym;
                obj.label.setFont("condensed.txf").setFontSize(12, 1.4);
                obj.valid = 1;
            }
            else
                print("Cannot find "~label_name);
        }
        else
            print("Cannot find "~name);
        obj.id = id;
		append(TEWSSymbol.list, obj);
		return obj;
	},
    setVisible : func(vis){
        if(me.symbol != nil)
            me.symbol.setVisible(vis);
        if(me.label != nil)
            me.label.setVisible(vis);
    },
    setTranslation : func(xc,yc){
        if(me.symbol != nil)
            me.symbol.setTranslation(xc,yc);
        if(me.label != nil)
            me.label.setTranslation(xc,yc);
    },
    setRotation : func(r){
        if(me.symbol != nil)
            me.symbol.setRotation(r);
        if(me.label != nil)
            me.label.setRotation(r);
    },
    setCenter : func(xc,yc){
        if(me.symbol != nil)
            me.symbol.setCenter(xc,yc);
        if(me.label != nil)
            me.label.setCenter(xc,yc);
    },
    setText : func(t){
        if(me.label != nil)
            me.label.setText(t);
    },
    update : func(id) {
        return list[id];
    },
    list: [],
};

#        var tgt = TEWSsvg.getElementById("target_friendly_"~target_idx);
#        var tgt = TEWSsvg.getElementById("target_friendly_0");
var max_symbols = 5;
#var tgt_symbols =  setsize([], max_symbols);
for (var i = 0; i < max_symbols; i += 1)
{
var ts = TEWSSymbol.new(i, TEWSsvg, "hat");
printf("%d: %s %s",i,ts.id, ts.valid);
if (ts.valid)
    ;
}

var prop_IAS =  props.globals.getNode ("/velocities/airspeed-kt");
var prop_alpha = props.globals.getNode ("orientation/alpha-deg");
var prop_mach =  props.globals.getNode ("/velocities/mach");
var prop_altitude_ft =  props.globals.getNode ("/position/altitude-ft");
var prop_heading =  props.globals.getNode("/orientation/heading-deg");
var prop_pitch =  props.globals.getNode ("orientation/pitch-deg");
var prop_roll =  props.globals.getNode ("orientation/roll-deg");
var Nz_prop = props.globals.getNode("/fdm/jsbsim/accelerations/Nz");




var updateTEWS = func ()
{  
    var 	IAS = prop_IAS.getValue();
    var 	mach = prop_mach.getValue(); 
    var 	altitude_ft = prop_altitude_ft.getValue();
    var 	WOW = getprop ("/gear/gear[1]/wow") or getprop ("/gear/gear[2]/wow");
    var 	heading = prop_heading.getValue();	
    var 	pitch = prop_pitch.getValue();
    var 	roll = prop_roll.getValue();
    var     Nz = Nz_prop.getValue();
    var measured_altitude = getprop("/instrumentation/altimeter/indicated-altitude-ft");
    var target_idx = 0;
    var radar_range = getprop("instrumentation/radar/radar2-range");

    var  roll_rad = -roll*3.14159/180.0;

    foreach( u; awg_9.tgts_list ) 
    {
        var callsign = "XX";
        if (u.Callsign != nil)
            callsign = u.Callsign.getValue();
        var model = "XX";
        if (u.Model != nil)
            model = u.Model.getValue();
        if (target_idx < max_symbols)
        {
            var tgt = TEWSSymbol.list[target_idx];
            if (tgt != nil)
            {
                tgt.setVisible(u.get_display());
                var xc = u.get_bearing();
                var yc = (u.get_range() / radar_range);
                tgt.setVisible(1);
               printf("TEWS: %d(%d,%d): %s %s: %f %f %f", target_idx,xc,yc,
                      callsign, model, 
                      u.get_altitude(), u.get_range(), u.get_bearing());
            tgt.setCenter(80,80);
                tgt.setTranslation (xc, yc);
#tgt.setCenter (118,830 - pitch * pitch_factor-pitch_offset);
#tgt.setRotation (roll_rad);
            }
        }
        target_idx = target_idx+1;
	}
    for(var nv = target_idx; nv < max_symbols;nv += 1)
    {
        var tgt = TEWSSymbol.list[nv];
        if (tgt != nil)
        {
            tgt.setVisible(0);
        }
    }
}
