# 225 - 400 Mz
# 20 preset channels

# Modes:     0 = Off,
#            1 = Main, Main tranceiver is energized permitting normal transmission
#                and reception.
#            2 = Both, Energizes both the main tranceiver and the guard receiver.
#            3 = DF, Function Direction Finder not enabled on this radio.

# Functions: 0 = Preset: Enables the Chan Set Knob
#            1 = Manual: permits manual tunning. Preset selections not available.
#            2 = Guard, main tranceiver energized and shifted to guard frequency (243 Mhz)
#                permitting transmission and reception.

# Button Load: place the current tunned freq in the memory for the selected preset channel.
# Button Read: switch between frequency and preset channel number display.

# Load a freq into a channel:
#	MODE:			set MAIN or BOTH.
#	FUNCTION:		set PRESET.
#	CHAN SEL:		set desired Channel.
#	FREQ Switches:	tune for desired Frequency.
#	LOAD Button:	push to load the Frequency into the Channel memory.

var Radio        = props.globals.getNode("sim/model/f-14b/instrumentation/an-arc-159v1");
var Mode         = Radio.getNode("mode");
var Function     = Radio.getNode("function");
var Volume       = Radio.getNode("volume");
var Brightness   = Radio.getNode("brightness");
var Preset       = Radio.getNode("preset");
var Presets      = Radio.getNode("presets");
var Selected_F   = Radio.getNode("frequencies/selected-mhz");
var Load_State   = Radio.getNode("load-state", 1);
var Comm2_Volume = props.globals.getNode("instrumentation/comm[1]/volume");
var Comm2_Freq   = props.globals.getNode("instrumentation/comm[1]/frequencies/selected-mhz");
var Comm2_Freq_stdby = props.globals.getNode("instrumentation/comm[1]/frequencies/standby-mhz");

var df_lock = 0;

var turn_on = func() {
	var f = Function.getValue();
	if ( f == 0 ) {
		var p = Preset.getValue();
		var path = "frequency[" ~ p ~ "]";
		var p_freq = Presets.getNode(path).getValue();
		Selected_F.setValue(p_freq * 1000);
	} elsif ( f == 1 ) {
		Comm2_Freq.setValue(0);
	} else {
		Comm2_Freq.setValue(243);
		Selected_F.setValue(243000);
	}
	var v = Volume.getValue();
	Comm2_Volume.setValue(v);
}

var turn_off = func() {
	Selected_F.setValue(0);
	Comm2_Freq.setValue(0);
	Comm2_Volume.setValue(0);
	Comm2_Freq_stdby.setValue(0);
}

var get_selected = func() {
	return(Selected_F.getValue() / 1000);
}

var load = func() {
	var m = Mode.getValue();
	var f = Function.getValue();
	var fq = Selected_F.getValue();
	var p = Preset.getValue();
	var path = "frequency[" ~ p ~ "]";
	Presets.getNode(path).setValue(fq / 1000);
	if ( m == 1 or m == 2) {
		Comm2_Freq.setValue(fq / 1000);
	}
}

var adj_mode = func(s) {
	var m = Mode.getValue();
	var old_m = m;
	m += s;
	if ( m > 3 ) { m = 3 } elsif ( m < 0 ) { m = 0 }
	Mode.setValue(m);
	if ( m == 0 ) {
		turn_off();
	} elsif (( m == 1 and old_m == 0 )) {
		turn_on();
	} elsif (( m == 2 and old_m == 3 )) {
		Comm2_Freq.setValue(Selected_F.getValue());
	} elsif ( m == 3) {
		Comm2_Freq.setValue(0);
	}
}

var adj_function = func(s) {
	var m = Mode.getValue();
	var f = Function.getValue();
	var old_f = f;
	f += s;
	if ( f > 2 ) { f = 2 } elsif ( f < 0 ) { f = 0 }
	Function.setValue(f);
	if  ( f == 1 and old_f == 2 ) {
		# from GUARD to MANUAL 
		var comm2_f = Comm2_Freq_stdby.getValue();
		Comm2_Freq.setValue(comm2_f);
		Selected_F.setValue(comm2_f * 1000);
		Comm2_Freq_stdby.setValue(0);
	} elsif ( f == 2 and old_f == 1 and m > 0 ) {
		# from MANUAL to GUARD
		var comm2_f = Selected_F.getValue() / 1000;
		Comm2_Freq.setValue(243);
		Comm2_Freq_stdby.setValue(comm2_f);
		Selected_F.setValue(243000);
	} 
}

var adj_channel = func(s) {
	var m = Mode.getValue();
	var f = Function.getValue();
	var p = Preset.getValue();
	p += s;
	if ( p < 0 ) { p = 0 } elsif ( p > 19 ) { p = 19 }
	Preset.setValue(p);
	var path = "frequency[" ~ p ~ "]";
	var p_freq = Presets.getNode(path).getValue();
	if (( m == 1 or m == 2 ) and f == 0 ) {
		Selected_F.setValue(p_freq * 1000);
		Comm2_Freq.setValue(p_freq);
	}
	return(p);
}

var set_freq = func(fq) {
	var fq = test_band(fq);
	Selected_F.setValue(fq);
	return(fq);
}

var adj_freq = func(s) {
	var m = Mode.getValue();
	var f = Function.getValue();
	if (( m == 1 or m == 2 )  and ( f < 2 )) {
		var fq = Selected_F.getValue() + s;
		fq = test_band(fq);
		Selected_F.setValue(fq);
		Comm2_Freq.setValue(fq);
	}
}

var test_band = func(fq) {
	if ( fq < 225000 ) { fq = 225000 } elsif ( fq > 400000 ) { fq = 400000 }
	return(fq);
}

var load_freq = func() {
	var m = Mode.getValue();
	var f = Function.getValue();
	if ( f == 0 and m > 0 ) {
		load();
		Load_State.setValue(1);
		settimer(func { Load_State.setValue(0); }, 0.5);
	}
}

var set_volume = func(s) {
	var v = Volume.getValue();
	var m = Mode.getValue();
	v += s;
	if ( v < 0 ) { v = 0 } elsif ( v > 1 ) { v = 1 }
	Volume.setValue(v);
	if ( m == 1 or m == 2 ) {
		Comm2_Volume.setValue(v);
	}
}


var init = func() {
	var m = Mode.getValue();
	var f = Function.getValue();
	var p = Preset.getValue();
	var path = "frequency[" ~ p ~ "]";
	var p_freq = Presets.getNode(path).getValue();
	if ( f == 2 ) {
		Comm2_Freq.setValue(243);
		Selected_F.setValue(243000);
	} else {
		Comm2_Freq.setValue(p_freq);
		Selected_F.setValue(p_freq * 1000);
	}
	if ( m == 0 or m == 3 ) {
		Comm2_Freq.setValue(0);
		Comm2_Freq_stdby.setValue(0);
		Selected_F.setValue(0);
	}
}


var p0 = Radio.getNode("presets/frequency[0]");
var p1 = Radio.getNode("presets/frequency[1]");
var p2 = Radio.getNode("presets/frequency[2]");
var p3 = Radio.getNode("presets/frequency[3]");
var p4 = Radio.getNode("presets/frequency[4]");
var p5 = Radio.getNode("presets/frequency[5]");
var p6 = Radio.getNode("presets/frequency[6]");
var p7 = Radio.getNode("presets/frequency[7]");
var p8 = Radio.getNode("presets/frequency[8]");
var p9 = Radio.getNode("presets/frequency[9]");
var p10 = Radio.getNode("presets/frequency[10]");
var p11 = Radio.getNode("presets/frequency[11]");
var p12 = Radio.getNode("presets/frequency[12]");
var p13 = Radio.getNode("presets/frequency[13]");
var p14 = Radio.getNode("presets/frequency[14]");
var p15 = Radio.getNode("presets/frequency[15]");
var p16 = Radio.getNode("presets/frequency[16]");
var p17 = Radio.getNode("presets/frequency[17]");
var p18 = Radio.getNode("presets/frequency[18]");
var p19 = Radio.getNode("presets/frequency[19]");
aircraft.data.add(Preset, Mode, Function, Comm2_Freq, Comm2_Freq_stdby, p0, p1, p2, p3, p4, p5,
	p6, p7, p8, p9, p10, p11, p12, p13, p14, p14, p15, p16, p17, p18, p19);
