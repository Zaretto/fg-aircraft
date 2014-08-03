# 30 - 88 Mz
# 108 - 174 Mz
# 225 - 400 Mz
# 20 preset channels

# Modes:     0= off,
#            1= T/R,
#            2= T/R+Guard,
#            3= DF,
#            4= test

# Functions: 0= Guard 243 Mhz disable all other funct,
#            1= Man: permits manual tunning.
#            2= G: should tunes to the guard freq in the band the receiver was last tuned, ATM, same as Man.
#            3= Preset: displays the selected Channel.
#            4= Read: displays the frequency instead of the preset channel number
#                    permits preset channel frequency manual tunning.
#            5= Load: place the displayed freq in the memory for the selected preset channel.

# TODO:
# - Re-organize tests in set_mode() and set_function() 
# - set = func(comm1_freq, comm1_freq_stdby, comm1_vol, nav1_freq, nav1_freq_stdby, nav1_vol) with values = numbers or "nc" for no change.
# - Some freq switch funcs.
# - set_guard = func()
# - set_test = func()
# - init() should use set_mode() and set_func()


var Radio        = props.globals.getNode("sim/model/f-14b/instrumentation/an-arc-182v");
var Pwr          = Radio.getNode("power-btn");
var Mode         = Radio.getNode("mode");
var Function     = Radio.getNode("function");
var Volume       = Radio.getNode("volume");
var Brightness   = Radio.getNode("brightness");
var Preset       = Radio.getNode("preset");
var Presets      = Radio.getNode("presets");
var Selected_F   = Radio.getNode("frequencies/selected-mhz");
var Guard_State  = Radio.getNode("guard-state", 1);
var Load_State   = Radio.getNode("load-state", 1);
var Nav1_Freq    = props.globals.getNode("instrumentation/nav[0]/frequencies/selected-mhz");
var Nav1_Freq_stdby = props.globals.getNode("instrumentation/nav[0]/frequencies/standby-mhz");
var Nav1_Volume  = props.globals.getNode("instrumentation/nav[0]/volume");
var Comm1_Volume = props.globals.getNode("instrumentation/comm[0]/volume");
var Comm1_Freq   = props.globals.getNode("instrumentation/comm[0]/frequencies/selected-mhz");
var Comm1_Freq_stdby = props.globals.getNode("instrumentation/comm[0]/frequencies/standby-mhz");

var test_stby = 0;
var function_lock = 0;

var set_mode = func(m) {
	var old_m = Mode.getValue();
	var f = Function.getValue();
	var fq = 0;
	var v = Volume.getValue();
	var p = Preset.getValue();
	var path = "frequency[" ~ p ~ "]";
	var p_freq = Presets.getNode(path).getValue();
	if ( old_m == 4 and m != 4 ) {
		# Moving out of TEST
		Selected_F.setValue(test_stby);
	}
	if ( m == 1 or m == 2 ) {
		var gs = Guard_State.getBoolValue();
		Comm1_Volume.setValue(v);
		Nav1_Volume.setValue(0);
		if ( f == 0 and ! gs ) {
			Guard_State.setBoolValue(1);
			fq = Comm1_Freq.getValue();
			Comm1_Freq.setValue(243);
			Comm1_Freq_stdby.setValue(fq);
			Selected_F.setValue(243000);
		} elsif ( f == 0 and gs ) {
			Selected_F.setValue(243000);
			Comm1_Freq.setValue(243);
		} elsif ( f == 1 or f == 2 ) {
			fq = Selected_F.getValue();
			Nav1_Freq.setValue(0);
			Comm1_Freq.setValue(fq / 1000);
		} elsif ( f == 3 or f == 4 ) {
			Selected_F.setValue(p_freq * 1000);
			fq = Selected_F.getValue();
			Nav1_Freq.setValue(0);
			Comm1_Freq.setValue(fq / 1000);
		}
	}	
	if ( m == 3 and f > 0) {
		fq = Selected_F.getValue();
		Nav1_Freq.setValue(fq / 1000);
		Comm1_Freq.setValue(0);
		Nav1_Volume.setValue(v);
		Comm1_Volume.setValue(0);
	}
	if ( m == 3 and f == 0) {
		Selected_F.setValue(243000);
		Comm1_Freq.setValue(243);
		Comm1_Volume.setValue(v);
		Nav1_Volume.setValue(0);
	}
	if ( m == 4 and old_m != 4 ) {
		test_stby = Selected_F.getValue();
		Selected_F.setValue(888888);
		Nav1_Freq.setValue(0);
		Comm1_Freq.setValue(0);
		Nav1_Volume.setValue(0);
		Comm1_Volume.setValue(0);
	}
	if ( m == 0 ) {
		Selected_F.setValue(0);
		Nav1_Freq.setValue(0);
		Nav1_Freq_stdby.setValue(0);
		Nav1_Volume.setValue(0);
		Comm1_Freq.setValue(0);
		Comm1_Freq_stdby.setValue(0);
		Comm1_Volume.setValue(0);
	}
	if (( m == 1 or m == 2 ) and old_m == 3) {
		# switches stdby freq when from DF to TR or TR&G.
		fq = Nav1_Freq_stdby.getValue();
		Nav1_Freq_stdby.setValue(0);
		Comm1_Freq_stdby.setValue(fq);
	} elsif  (( old_m == 1 or old_m == 2 ) and m == 3) {
		# switches stdby freq when from TR or TR&G to DF.
		fq = Comm1_Freq_stdby.getValue();
		Comm1_Freq_stdby.setValue(0);
		Nav1_Freq_stdby.setValue(fq);
	}
	Mode.setValue(m);
}

var adj_mode = func(s) {
	if ( function_lock == 0 ) {
		var m = Mode.getValue();
		m += s;
		if ( m > 4 ) { m = 4 } elsif ( m < 0 ) { m = 0 }
		set_mode(m);
	}
}

var set_function = func(f) {
	var old_f = Function.getValue();
	var m = Mode.getValue();
	var v = Volume.getValue();
	var gs = Guard_State.getBoolValue();
	var fq = 0;
	if ( f == 0 and old_f == 1 and ! gs and (m == 1 or m == 2 )) {
		Guard_State.setBoolValue(1);
		fq = Comm1_Freq.getValue();
		Comm1_Freq.setValue(243);
		Comm1_Freq_stdby.setValue(fq);
		Selected_F.setValue(243000);
	} elsif (f == 0 and old_f == 1 and ! gs and m == 3) {
		Guard_State.setBoolValue(1);
		fq = Nav1_Freq.getValue();
		Comm1_Freq.setValue(243);
		Nav1_Freq_stdby.setValue(fq);
		Nav1_Freq.setValue(0);
		Selected_F.setValue(243000);
	} elsif  ((f == 1 or f == 2) and old_f == 0 and m != 3) {
		Guard_State.setBoolValue(0);
		fq = Comm1_Freq_stdby.getValue();
		Comm1_Freq_stdby.setValue(243);
		Comm1_Freq.setValue(fq);
		Selected_F.setValue(fq * 1000);
		Nav1_Volume.setValue(0);
		Comm1_Volume.setValue(v);
	} elsif  ((f == 1 or f == 2) and old_f == 0 and m == 3) {
		Guard_State.setBoolValue(0);
		fq = Nav1_Freq_stdby.getValue();
		Nav1_Freq_stdby.setValue(243);
		Nav1_Freq.setValue(fq);
		Comm1_Freq.setValue(0);
		Selected_F.setValue(fq * 1000);
		Nav1_Volume.setValue(v);
		Comm1_Volume.setValue(0);
	} elsif  ((f == 3 or f == 4) and ( m == 1 or m == 2 )) {
		var p = Preset.getValue();
		var path = "frequency[" ~ p ~ "]";
		var p_freq = Presets.getNode(path).getValue();
		Selected_F.setValue(p_freq * 1000);
		fq = Selected_F.getValue();
		Nav1_Freq.setValue(0);
		Comm1_Freq.setValue(fq / 1000);
		Nav1_Volume.setValue(0);
		Comm1_Volume.setValue(v);
	} elsif  ((f == 3 or f == 4) and ( m == 3 )) {
		var p = Preset.getValue();
		var path = "frequency[" ~ p ~ "]";
		var p_freq = Presets.getNode(path).getValue();
		Selected_F.setValue(p_freq * 1000);
		fq = Selected_F.getValue();
		Comm1_Freq.setValue(0);
		Nav1_Freq.setValue(fq / 1000);
		Comm1_Volume.setValue(0);
		Nav1_Volume.setValue(v);
	} elsif ( f == 5 ) {
		function_lock = 1;
		if ( m != 0 and m != 4) {
			Guard_State.setBoolValue(0);
			load();
			Load_State.setValue(1);
			settimer(func { function_lock = 0; Load_State.setValue(0); set_function(4); }, 0.5);
		} else {
			settimer(func { function_lock = 0; set_function(4); }, 0.5);
		}
	}
	Function.setValue(f);
}

var load = func() {
	var m = Mode.getValue();
	var fq = Selected_F.getValue();
	var p = Preset.getValue();
	var path = "frequency[" ~ p ~ "]";
	Presets.getNode(path).setValue(fq / 1000);
	if ( m == 3 ) {
		Nav1_Freq.setValue(fq / 1000);
	} elsif ( m == 1 or m == 2 ) {
		Comm1_Freq.setValue(fq / 1000);
	} 
}

var adj_function = func(s) {
	var m = Mode.getValue();
	var f = Function.getValue();
	f += s;
	if ( f > 5 ) { f = 5 } elsif ( f < 0 ) { f = 0 }
	set_function(f);
}

var adj_channel = func(s) {
	var m = Mode.getValue();
	var f = Function.getValue();
	if (( m != 0 and m != 4 ) and ( f == 3 or f == 4 )) {
		var p = Preset.getValue();
		p += s;
		if ( p > 19 ) { p = 19 } elsif ( p < 0 ) { p = 0 }
		Preset.setValue(p);
		var path = "frequency[" ~ p ~ "]";
		var p_freq = Presets.getNode(path).getValue();
		Selected_F.setValue(p_freq * 1000);
		if ( m == 1 or m == 2 ) {
			Comm1_Freq.setValue(p_freq);
		} elsif ( m == 3 ) {
			Nav1_Freq.setValue(p_freq);
		}
		return(p);
	} else {
		return(0);
	}
}

var get_selected = func() {
	return(Selected_F.getValue() / 1000);
}

var set_freq = func(fq) {
	var fq = test_band(1, fq);
	Selected_F.setValue(fq);
	return(fq);
}

var adj_freq = func(s) {
	var m = Mode.getValue();
	var f = Function.getValue();
	if (( m == 1 or m == 2 or m == 3 )  and ( f == 1 or f == 4 )) {
		var fq = Selected_F.getValue() + s;
		fq = test_band(s, fq);
		Selected_F.setValue(fq);
		if ( m == 1 or m == 2 ) {
			Comm1_Freq.setValue(fq / 1000);
		} elsif ( m == 3 ) {
			Nav1_Freq.setValue(fq / 1000);
		}
	}
}


var test_band = func(s, fq) {
	if ( s > 0 ) {
		if ( fq < 30000 ) {
			fq = 30000;
		} elsif ( fq > 88000 and fq < 108000 ) {
			fq = 108000;
		} elsif ( fq > 174000 and fq < 225000 ) {
			fq = 225000;
		} elsif ( fq > 400000 ) {
			fq = 400000;
		}
	} else {
		if ( fq < 225000 and fq > 174000 ) {
			fq = 174000;
		} elsif ( fq < 108000 and fq > 88000 ) {
			fq = 88000;
		} elsif ( fq < 30000 ) {
			fq = 30000;
		}
	}
	return(fq);
}

var test_band_simple = func(fq) {
	if ( fq < 30000 ) {
		fq = 30000;
	} elsif ( fq > 88000 and fq < 108000 ) {
		fq = 108000;
	} elsif ( fq > 174000 and fq < 225000 ) {
		fq = 225000;
	} elsif ( fq > 400000 ) {
		fq = 400000;
	}
	return(fq);
}

var adj_volume = func(step) {
	var v = Volume.getValue();
	var m = Mode.getValue();
	v += step;
	if ( v < 0 ) { v = 0 }
	if ( v > 1 ) { v = 1 }
	Volume.setValue(v);
	if ( m == 3 ) {
		Nav1_Volume.setValue(v);
		Comm1_Volume.setValue(0);
	} elsif  ( m != 0 ) {
		Nav1_Volume.setValue(0);
		Comm1_Volume.setValue(v);
	} else {
		Nav1_Volume.setValue(0);
		Comm1_Volume.setValue(0);
	}
}

var init = func() {
	var m = Mode.getValue();
	var f = Function.getValue();
	var v = Volume.getValue();
	Guard_State.setBoolValue(0);
	var p = Preset.getValue();
	var path = "frequency[" ~ p ~ "]";
	var p_freq = Presets.getNode(path).getValue();
	Selected_F.setValue(0);
	Comm1_Freq.setValue(0);
	Comm1_Freq_stdby.setValue(0);
	Comm1_Volume.setValue(0);
	Nav1_Freq.setValue(0);
	Nav1_Freq_stdby.setValue(0);
	Nav1_Volume.setValue(0);
	if ( m == 1 or m == 2 ) {
		Comm1_Volume.setValue(v);
		Nav1_Volume.setValue(0);
		if ( f == 0 ) {
			Guard_State.setBoolValue(1);
			Comm1_Freq.setValue(243);
			Selected_F.setValue(243000);
		} elsif ( f == 1 or f == 2 ) {
			Selected_F.setValue(0);
			Comm1_Freq.setValue(0);
		} elsif ( f == 3 or f == 4 ) {
			Selected_F.setValue(p_freq * 1000);
			Comm1_Freq.setValue(p_freq);
		}
	} elsif ( m == 3 ) {
		Comm1_Volume.setValue(0);
		Nav1_Volume.setValue(v);
		if ( f == 0 ) {
			Comm1_Volume.setValue(v);
			Nav1_Volume.setValue(0);
			Guard_State.setBoolValue(1);
			Comm1_Freq.setValue(243);
			Selected_F.setValue(243000);
		} elsif ( f == 1 or f == 2 ) {
			Selected_F.setValue(0);
			Nav1_Freq.setValue(0);
		} elsif ( f == 3 or f == 4 ) {
			Selected_F.setValue(p_freq * 1000);
			Nav1_Freq.setValue(p_freq);
		}
	} elsif ( m == 4) {
		Selected_F.setValue(888888);
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
aircraft.data.add(Preset, Mode, Function, Comm1_Freq, Comm1_Freq_stdby, Nav1_Freq, Nav1_Freq_stdby, p0, p1, p2, p3, p4, p5,
	p6, p7, p8, p9, p10, p11, p12, p13, p14, p14, p15, p16, p17, p18, p19);


