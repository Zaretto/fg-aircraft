
################
#
# Engine
# A sophisticated YASim style turbine simulation by Josh Babcock.
#
################

rpm0 = '';
rpm1 = '';
rpm2 = '';
rpmR = '';
engineSim =  func {
	var rpm = (rpmR.getValue() / 0.185);
	rpm0.setDoubleValue(rpm);
	rpm1.setDoubleValue(rpm);
	rpm2.setDoubleValue(rpm);
	settimer(engineSim, 0.1);
}
engineInit = func {
	rpm0 = props.globals.getNode('engines/engine[0]/rpm', 1);
	rpm1 = props.globals.getNode('engines/engine[1]/rpm', 1);
	rpm2 = props.globals.getNode('engines/engine[2]/rpm', 1);
	rpmR = props.globals.getNode('rotors/main/rpm', 1);
	rpmR.setDoubleValue(0);
	engineSim();
}
settimer(engineInit, 0);




