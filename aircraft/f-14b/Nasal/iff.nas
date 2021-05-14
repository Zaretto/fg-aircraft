# IFF system
# gplv2 by pinto aka Justin Nicholson
# Source from https://github.com/NikolaiVChr/OpRedFlag/blob/master/libraries/iff.nas
# Added by Megaf - https://github.com/Megaf/

var iff_refresh_rate = getprop("/instrumentation/iff/iff_refresh_rate") or 120;
var iff_unique_id = getprop("/instrumentation/iff/iff_unique_id") or "";
var iff_hash_length = getprop("/instrumentation/iff/iff_hash_length") or 3;
var iff_mp_string = getprop("/instrumentation/iff/iff_mp_string") or 4;

var node = {
    power:          props.globals.getNode(getprop("/instrumentation/iff/power_prop")),
    channel:        props.globals.getNode(getprop("/instrumentation/iff/channel_prop")),
    hash:           props.globals.initNode("/sim/multiplay/generic/string["~iff_mp_string~"]","AAA","STRING"),
    callsign:       props.globals.getNode("/sim/multiplay/callsign"),
};

var iff_hash = {
    new: func() {
        var m = {parents:[iff_hash]};
        m.int_systime = int(systime());
        m.update_time = int(math.mod(m.int_systime,iff_refresh_rate));
        m.time = m.int_systime - m.update_time; # time used in hash
        m.timer = maketimer(iff_refresh_rate - m.update_time,func(){m.loop()});
        m.callsign = node.callsign.getValue();
        return m;
    },

    loop: func() {
        if (node.power.getBoolValue()) {
            if (me.timer.isRunning == 0) {
                me.timer.start();
            }
            me.int_systime = int(systime());
            me.update_time = int(math.mod(me.int_systime,iff_refresh_rate));
            me.time = me.int_systime - me.update_time;
            node.hash.setValue(_calculate_hash(me.time, node.callsign.getValue(), node.channel.getValue()));
		} else {
            me.timer.stop();
            node.hash.setValue("");
        }
    },
};

var hash1 = "";
var hash2 = "";
var check_hash = "";

var interrogate = func(tgt) {
    if ( tgt.getChild("callsign") == nil or tgt.getNode("sim/multiplay/generic/string["~iff_mp_string~"]") == nil ) {
        return 0;
    }
    hash1 = _calculate_hash(int(systime()) - int(math.mod(int(systime()),iff_refresh_rate)), tgt.getChild("callsign").getValue(),node.channel.getValue());
    hash2 = _calculate_hash(int(systime()) - int(math.mod(int(systime()),iff_refresh_rate)) - iff_refresh_rate, tgt.getChild("callsign").getValue(),node.channel.getValue());
    check_hash = tgt.getNode("sim/multiplay/generic/string["~iff_mp_string~"]").getValue();
    if ( hash1 == check_hash or hash2 == check_hash ) {
        return 1;
    } else {
        return 0;
    }
}

var _calculate_hash = func(time, callsign, channel) {
    return left(md5(time ~ callsign ~ channel ~ iff_unique_id),iff_hash_length);
}

var new_hashing = iff_hash.new();
new_hashing.loop();
setlistener(node.channel,func(){new_hashing.loop();},nil,0);
setlistener(node.power,func(){new_hashing.loop();},nil,0);
setlistener(node.callsign,func(){new_hashing.loop();},nil,0);

