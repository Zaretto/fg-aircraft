# F-15 TEWS; Canvas
# ---------------------------
# This bears only a cosmetic relation to the real device mainly because 
# all of the document for TEWS appears to be classified and/or 
# generally unavailable. 
# ---------------------------
# Richard Harrison: 2015-01-23 : rjh@zaretto.com
# ---------------------------


var TEWScanvas= canvas.new({
                           "name": "F-15 TEWS",
                           "size": [1024,1024], 
                           "view": [326,256],                       
                           "mipmapping": 1
                          });                          
                          
TEWScanvas.addPlacement({"node": "TEWSImage"});
TEWScanvas.setColorBackground(0.0039215686274509803921568627451,0.17647058823529411764705882352941,0, 0.00);

# Create a group for the parsed elements
var TEWSsvg = TEWScanvas.createGroup();
 
# Parse an SVG file and add the parsed elements to the given group
print("TEWS : Load SVG ",canvas.parsesvg(TEWSsvg, "Nasal/TEWS/TEWS.svg"));
#TEWSsvg.setTranslation (-20.0, 37.0);
#print("TEWS INIT");
 
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
                obj.setVisible(0);
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
    setCallsign : func(t){
        if (size (t) > 2)
            me.setText(substr(t,0,2));
        else
            me.setText(t);
    },
    setGeoPosition : func (lat, lon){
        if(me.symbol != nil)
            me.symbol.setGeoPosition(lat, lon);
        if(me.label != nil)
            me.label.setGeoPosition(lat, lon);
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

var tews_on = 1;
setlistener("sim/model/f15/controls/TEWS/brightness", func(v)
            {
                if (v != nil)
                {
                    var tews_on = v.getValue();
#                    print("TEWS On ",tews_on);
                }
            });

var max_symbols = 10;
var tews_alignment_offset = -90;
for (var i = 0; i < max_symbols; i += 1)
{
    var ts = TEWSSymbol.new(i, TEWSsvg, "hat");
#    printf("TEWS Sym load: %d: %s %s",i,ts.id, ts.valid);
}

var updateTEWS = func ()
{  
if(!tews_on)
return;
    var 	heading = getprop("/orientation/heading-deg");
    var target_idx = 0;
    var radar_range = getprop("instrumentation/radar/radar2-range");

    var scale = 220/2; # horizontal / vertical scale (half resolution)

    foreach( u; awg_9.tgts_list ) 
    {
        var callsign = "XX";
        if (u.get_range() < radar_range)
        {
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
# We have a valid target - so display it. Not quite sure why we need to adjust this but we do.
#                    var bearing = u.get_deviation(heading);
                    var bearing = geo.normdeg(u.get_deviation(heading) + tews_alignment_offset);

                    tgt.setVisible(u.get_display());
                    tgt.setCallsign(callsign);
                    var r = (u.get_range()*scale) / radar_range;
                    var xc  = r * math.cos(bearing/57.29577950560105);
                    var yc = r * math.sin(bearing/57.29577950560105);

                    tgt.setVisible(1);

#                    printf("TEWS: %d(%d,%d): %s %s: :R %f B %f %f", target_idx,xc,yc,
#                           callsign, model, 
#                           u.get_altitude(), u.get_range(), u.get_bearing());

                    tgt.setTranslation (xc, yc);
                    tgt.setRotation(geo.normdeg(heading-u.get_bearing())/57.29577950560105);
                }
            }
            target_idx = target_idx+1;
        }
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
