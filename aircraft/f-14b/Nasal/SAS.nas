#----------------------------------------------------------------------------
# Stability Augmentation System
#----------------------------------------------------------------------------

var t_increment     = 0.0075;
var p_lo_speed      = 230;
var p_lo_speed_sqr  = p_lo_speed * p_lo_speed;
var roll_lo_speed   = 400;
var roll_lo_speed_sqr = roll_lo_speed * roll_lo_speed;
var p_kp            = -0.05;
var e_smooth_factor = 0.1;
var r_smooth_factor = 0.2;
var p_max           = 0.2;
var p_min           = -0.2;
var max_e           = 1;
var min_e           = 0.5;

# Orientation and velocities
var Roll       = props.globals.getNode("orientation/roll-deg");
var PitchRate  = props.globals.getNode("orientation/pitch-rate-degps", 1);
var YawRate    = props.globals.getNode("orientation/yaw-rate-degps", 1);
var AirSpeed   = props.globals.getNode("velocities/airspeed-kt");
# SAS and Autopilot Controls
var SasPitchOn = props.globals.getNode("sim/model/f-14b/controls/SAS/pitch");
var SasRollOn  = props.globals.getNode("sim/model/f-14b/controls/SAS/roll");
var SasYawOn   = props.globals.getNode("sim/model/f-14b/controls/SAS/yaw");
var DeadZPitch = props.globals.getNode("sim/model/f-14b/controls/AFCS/dead-zone-pitch");
var DeadZRoll  = props.globals.getNode("sim/model/f-14b/controls/AFCS/dead-zone-roll");
# Autopilot Locks
var ap_alt_lock   = props.globals.getNode("autopilot/locks/altitude");
var ap_hdg_lock   = props.globals.getNode("autopilot/locks/heading");
# Inputs
var RawElev       = props.globals.getNode("controls/flight/elevator");
var RawAileron    = props.globals.getNode("controls/flight/aileron");
var RawRudder     = props.globals.getNode("controls/flight/rudder");
var AileronTrim   = props.globals.getNode("controls/flight/aileron-trim", 1);
var ElevatorTrim  = props.globals.getNode("controls/flight/elevator-trim", 1);
var Dlc           = props.globals.getNode("controls/flight/DLC", 1);
var Flaps         = props.globals.getNode("surface-positions/aux-flap-pos-norm", 1);
var WSweep        = props.globals.getNode("surface-positions/wing-pos-norm", 1);
# Outputs
var SasRoll       = props.globals.getNode("controls/flight/SAS-roll", 1);
var SasPitch      = props.globals.getNode("controls/flight/SAS-pitch", 1);
var SasYaw        = props.globals.getNode("controls/flight/SAS-yaw", 1);

var airspeed       = 0;
var airspeed_sqr   = 0;
var last_e         = 0;
var last_p_var_err = 0;
var p_input        = 0;
var last_p_bias    = 0;
var last_a         = 0;
var last_r         = 0;
var w_sweep        = 0;
# var e_trim         = 0;
var steering       = 0;
var dt_mva_vec     = [0,0,0,0,0,0,0];


# Sets move qty for the stick to disengage the Autopilot Attitude Hold Mode.
var deadZ_pitch    = DeadZPitch.getValue();
var deadZ_roll     = DeadZRoll.getValue();
aircraft.data.add(DeadZPitch,DeadZRoll);

var AP_steering_deadZ_dlg = gui.Dialog.new("dialog[1]","Aircraft/f-14b/Dialogs/AP-steering-dead-zone.xml");

var update_steering_deadZ = func {
	deadZ_pitch = DeadZPitch.getValue();
	deadZ_roll = DeadZRoll.getValue();
}


# Elevator Trim
if ( ElevatorTrim.getValue() != nil ) { e_trim = ElevatorTrim.getValue() }

var trimUp = func {
	e_trim += (airspeed < 120.0) ? t_increment : t_increment * 14400 / airspeed_sqr;
	if (e_trim > 1) e_trim = 1;
	ElevatorTrim.setValue(e_trim);
}

var trimDown = func {
	e_trim -= (airspeed < 120.0) ? t_increment : t_increment * 14400 / airspeed_sqr;
	if (e_trim < -1) e_trim = -1;
	ElevatorTrim.setValue(e_trim);
}



# Stability Augmentation System
var computeSAS = func {
	var roll     = Roll.getValue();
	var roll_rad = roll * 0.017453293;
	airspeed     = AirSpeed.getValue();
	airspeed_sqr = airspeed * airspeed;
	var raw_e    = RawElev.getValue();
	var raw_a    = RawAileron.getValue();
	var a_trim   = AileronTrim.getValue();
	var w_sweep = WSweep.getValue();
	var o_sweep = ( w_sweep != nil and w_sweep > 1.01 ) ? 1 : 0;
	# Temporarly disengage Autopilot when control stick steering or when 7 frames average fps < 10.
	steering = ((raw_e > deadZ_pitch or -deadZ_pitch > raw_e) or (raw_a > deadZ_roll or -deadZ_roll > raw_a)) ? 1 : 0;
	var mvaf_dT = (dt_mva_vec[0]+dt_mva_vec[1]+dt_mva_vec[2]+dt_mva_vec[3]+dt_mva_vec[4]+dt_mva_vec[5]+dt_mva_vec[6])/7;
	pop(dt_mva_vec);
	dt_mva_vec = [deltaT] ~ dt_mva_vec;
	# Simple mode, Attitude: pitch and roll.
	# f14_afcs.ap_lock_att:
	# 0 = attitude not engaged (no autopilot at all).
	# 1 = attitude engaged and running.
	# 2 = attitude engaged and temporary disabled.
	# 3 = attitude engaged and temporary disabled with altitude selected.
	if ( f14_afcs.ap_lock_att > 0 ) {
		if ( f14_afcs.ap_lock_att == 1 and ( steering or mvaf_dT >= 0.1 )) {
			if (f14_afcs.ap_alt_lock.getValue() == "altitude-hold") {
				f14_afcs.ap_lock_att = 3;
			} else {
				f14_afcs.ap_lock_att = 2;
			}
			ap_alt_lock.setValue("");
			ap_hdg_lock.setValue("");
		} elsif ( f14_afcs.ap_lock_att > 1 and !steering and mvaf_dT < 0.1 ) {
			if ( f14_afcs.ap_lock_att == 3 ) {
				f14_afcs.alt_enable.setBoolValue(1);
			}
			f14_afcs.ap_lock_att = 1;
			f14_afcs.afcs_attitude_engage();
		}
	}


	if ( f14_afcs.ap_lock_att != 1 ) {

		# Roll Channel
		var sas_roll = 0;
		# Squares roll input, then applies quadratic law.
		if (SasRollOn.getValue()) {
			sas_roll = (raw_a * raw_a);
			if (raw_a < 0 ) { sas_roll *= -1 }
			sas_roll += a_trim;
			if (airspeed > roll_lo_speed) {
				sas_roll *= roll_lo_speed_sqr / airspeed_sqr;
			}
		} else {
			sas_roll = raw_a + a_trim;
		}
		SASroll = sas_roll; # Used by adverse.nas
		SasRoll.setValue(sas_roll * ! o_sweep);

		# Pitch Channel
		var pitch_rate = PitchRate.getValue();
		var yaw_rate   = YawRate.getValue();
		var p_bias     = 0;
		var smooth_e   = raw_e;
		var dlc_trim   = 0;
		if (SasPitchOn.getValue()) {
			# Exponential Filter smoothing longitudinal input.
			smooth_e = last_e + ((raw_e - last_e) * e_smooth_factor);
			last_e = smooth_e;
			if ( deltaT < 0.06 ) {
				# Proportional Bias Filter based on current attitude change rate.
				var p_var_err = - ((pitch_rate * math.cos(roll_rad)) + (yaw_rate * math.sin(roll_rad)));
				p_bias = last_p_bias + p_kp * (p_var_err - last_p_var_err);
				last_p_var_err = p_var_err;
				last_p_bias = p_bias;
				if (p_bias > p_max) { p_bias = p_max } elsif (p_bias < p_min) { p_bias = p_min }
			}
			dlc_trim = 0.08 * Dlc.getValue(); # DLC: Direct Lift Control (depends on SAS).
		}
		flaps =  Flaps.getValue();
		if ( flaps == nil) flaps = 0;
		var flaps_trim = 0.2 * flaps; # ITS: Integrated Trim System.
		p_input = smooth_e + p_bias - (flaps_trim + dlc_trim);
		# Longitudinal authority limit, mechanicaly "handled".
		if (p_input > 0) {
			p_input *= min_e;
		} else {
			p_input *= max_e;
		}
		# Quadratic Law
		if (airspeed > p_lo_speed) p_input *= p_lo_speed_sqr / airspeed_sqr;
		SasPitch.setValue(p_input * ! o_sweep);
		SASpitch = p_input; # Used by adverse.nas 

	}

	# Yaw Channel
	var raw_r    = RawRudder.getValue();
	var smooth_r = raw_r;
	if (SasYawOn.getValue()) {
		smooth_r = last_r + ((raw_r - last_r) * r_smooth_factor);
		last_r = smooth_r;
	}
	SasYaw.setValue(smooth_r);

}
