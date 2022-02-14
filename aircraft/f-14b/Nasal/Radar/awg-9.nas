




############# BEGIN SOMEWHAT GENERIC CLASSES ###########################################



# Field of regard requests
var FOR_ROUND  = 0;# TODO: be able to ask noseradar for round field of regard.
var FOR_SQUARE = 1;
#Pulses
var DOPPLER = 1;
var MONO = 0;

var overlapHorizontal = 1.5;


#   █████  ██ ██████  ██████   ██████  ██████  ███    ██ ███████     ██████   █████  ██████   █████  ██████  
#  ██   ██ ██ ██   ██ ██   ██ ██    ██ ██   ██ ████   ██ ██          ██   ██ ██   ██ ██   ██ ██   ██ ██   ██ 
#  ███████ ██ ██████  ██████  ██    ██ ██████  ██ ██  ██ █████       ██████  ███████ ██   ██ ███████ ██████  
#  ██   ██ ██ ██   ██ ██   ██ ██    ██ ██   ██ ██  ██ ██ ██          ██   ██ ██   ██ ██   ██ ██   ██ ██   ██ 
#  ██   ██ ██ ██   ██ ██████   ██████  ██   ██ ██   ████ ███████     ██   ██ ██   ██ ██████  ██   ██ ██   ██ 
#                                                                                                            
#                                                                                                            
var AirborneRadar = {
	#
	# This is an base class for an airborne forward looking radar
	# The class RadarMode uses this. Subclass as needed.
	#
	# TODO: Cleaner calls to optional ground mapper
	#
	fieldOfRegardType: FOR_SQUARE,
	fieldOfRegardMaxAz: 60,
	fieldOfRegardMaxElev: 60,
	fieldOfRegardMinElev: -60,
	currentMode: nil, # vector of cascading modes ending with current submode
	currentModeIndex: 0,
	rootMode: 0,
	mainModes: nil,
	instantFoVradius: 2.0,#average of horiz/vert radius
	instantVertFoVradius: 2.5,# real vert radius (could be used by ground mapper)
	instantHoriFoVradius: 1.5,# real hori radius (not used)
	rcsRefDistance: 70,
	rcsRefValue: 3.2,
	#closureReject: -1, # The minimum kt closure speed it will pick up, else rejected.
	#positionEuler: [0,0,0,0],# euler direction
	positionDirection: [1,0,0],# vector direction
	positionCart: [0,0,0,0],
	eulerX: 0,
	eulerY: 0,
	horizonStabilized: 1, # When true antennae ignore roll (and pitch until its high)
	vector_aicontacts_for: [],# vector of contacts found in field of regard
	vector_aicontacts_bleps: [],# vector of not timed out bleps
	chaffList: [],
	chaffSeenList: [],
	chaffFilter: 0.60,# 1=filters all chaff, 0=sees all chaff all the time
	timer: nil,
	timerMedium: nil,
	timerSlow: nil,
	timeToKeepBleps: 13,
	elapsed: elapsedProp.getValue(),
	lastElapsed: elapsedProp.getValue(),
	debug: 0,
	newAirborne: func (mainModes, child) {
		var rdr = {parents: [child, AirborneRadar, Radar]};

		rdr.mainModes = mainModes;
		
		foreach (modes ; mainModes) {
			foreach (mode ; modes) {
				# this needs to be set on submodes also...hmmm
				mode.radar = rdr;
			}
		}

		rdr.setCurrentMode(rdr.mainModes[0][0], nil);

		rdr.SliceNotification = SliceNotification.new();
		rdr.ContactNotification = VectorNotification.new("ContactNotification");
		rdr.ActiveDiscRadarRecipient = emesary.Recipient.new("ActiveDiscRadarRecipient");
		rdr.ActiveDiscRadarRecipient.radar = rdr;
		rdr.ActiveDiscRadarRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "FORNotification") {
	        	#printf("DiscRadar recv: %s", notification.NotificationType);
	            #if (rdr.enabled == 1) { no, lets keep this part running, so we have fresh data when its re-enabled
	    		    rdr.vector_aicontacts_for = notification.vector;
	    		    rdr.purgeBleps();
	    		    #print("size(rdr.vector_aicontacts_for)=",size(rdr.vector_aicontacts_for));
	    	    #}
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        if (notification.NotificationType == "ChaffReleaseNotification") {
	    		rdr.chaffList ~= notification.vector;
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(rdr.ActiveDiscRadarRecipient);
		rdr.timer = maketimer(scanInterval, rdr, func rdr.loop());
		rdr.timerSlow = maketimer(0.75, rdr, func rdr.loopSlow());
		rdr.timerMedium = maketimer(0.25, rdr, func rdr.loopMedium());
		rdr.timerMedium.start();
		rdr.timerSlow.start();
		rdr.timer.start();
    	return rdr;
	},
	getTiltKnob: func {
		me.theKnob = antennae_knob_prop.getValue();
		if (math.abs(me.theKnob) < 0.01) {
			antennae_knob_prop.setValue(0);
			me.theKnob = 0;
		}
		return me.theKnob*60;
	},
	increaseRange: func {
		if (me["gmapper"] != nil) me.gmapper.clear();
		me.currentMode.increaseRange();
	},
	decreaseRange: func {
		if (me["gmapper"] != nil) me.gmapper.clear();
		me.currentMode.decreaseRange();
	},
	designate: func (designate_contact) {
		me.currentMode.designate(designate_contact);
	},
	designateRandom: func {
		# Use this method mostly for testing
		if (size(me.vector_aicontacts_bleps) > 0) {
			me.designate(me.vector_aicontacts_bleps[size(me.vector_aicontacts_bleps)-1]);
		}
	},
	undesignate: func {
		me.currentMode.undesignate();
	},
	getPriorityTarget: func {
		if (!me.enabled) return nil;
		return me.currentMode.getPriority();
	},
	cycleDesignate: func {
		me.currentMode.cycleDesignate();
		if (me.getPriorityTarget() != nil) {#F14 custom
			print("Hooked ",me.getPriorityTarget().get_Callsign());
			if (we_are_bs) Hook.setValue(left(md5(me.getPriorityTarget().getCallsign()),7));
		} else {
			print("Nothing designated");
			if (we_are_bs) Hook.setValue("");
		}
	},
	cycleMode: func {
		me.currentModeIndex += 1;
		if (me.currentModeIndex >= size(me.mainModes[me.rootMode])) {
			me.currentModeIndex = 0;
		}
		me.newMode = me.mainModes[me.rootMode][me.currentModeIndex];
		me.newMode.setRange(me.currentMode.getRange());
		me.oldMode = me.currentMode;
		me.setCurrentMode(me.newMode, me.oldMode["priorityTarget"]);
	},
	cycleRootMode: func {
		me.rootMode += 1;
		if (me.rootMode >= size(me.mainModes)) {
			me.rootMode = 0;
		}
		me.currentModeIndex = 0;
		me.newMode = me.mainModes[me.rootMode][me.currentModeIndex];
		#me.newMode.setRange(me.currentMode.getRange());
		me.oldMode = me.currentMode;
		me.setCurrentMode(me.newMode, me.oldMode["priorityTarget"]);
	},
	cycleAZ: func {
		if (me["gmapper"] != nil) me.gmapper.clear();
		me.clearShowScan();
		me.currentMode.cycleAZ();
	},
	cycleBars: func {
		me.currentMode.cycleBars();
		me.clearShowScan();
	},
	getDeviation: func {
		return me.currentMode.getDeviation();
	},
	setCursorDeviation: func (cursor_az) {
		return me.currentMode.setCursorDeviation(cursor_az);
	},
	getCursorDeviation: func {
		return me.currentMode.getCursorDeviation();
	},
	setCursorDistance: func (nm) {
		# Return if the cursor should be distance zeroed.
		return me.currentMode.setCursorDistance(nm);;
	},
	getCursorAltitudeLimits: func {
		if (!me.enabled) return nil;
		return me.currentMode.getCursorAltitudeLimits();
	},	
	getBars: func {
		return me.currentMode.getBars();
	},
	getAzimuthRadius: func {
		return me.currentMode.getAz();
	},
	getMode: func {
		return me.currentMode.shortName;
	},
	setCurrentMode: func (new_mode, priority = nil) {
		me.olderMode = me.currentMode;
		me.currentMode = new_mode;
		new_mode.radar = me;
		#new_mode.setCursorDeviation(me.currentMode.getCursorDeviation()); # no need since submodes don't overwrite this
		new_mode.designatePriority(priority);
		if (me.olderMode != nil) me.olderMode.leaveMode();
		new_mode.enterMode();
		me.modeSwitch();#F14 custom
		settimer(func me.clearShowScan(), 0.5);
	},
	setRootMode: func (mode_number, priority = nil) {
		me.rootMode = mode_number;
		if (me.rootMode >= size(me.mainModes)) {
			me.rootMode = 0;
		}
		me.currentModeIndex = 0;
		me.newMode = me.mainModes[me.rootMode][me.currentModeIndex];
		#me.newMode.setRange(me.currentMode.getRange());
		me.oldMode = me.currentMode;
		me.setCurrentMode(me.newMode, priority);
	},
	getRange: func {
		return me.currentMode.getRange();
	},
	getCaretPosition: func {
		if (me["eulerX"] == nil or me["eulerY"] == nil) {
			return [0,0];
		} elsif (me.horizonStabilized) {
			return [me.eulerX/me.fieldOfRegardMaxAz,me.eulerY/me.fieldOfRegardMaxElev];
		} else {
			return [me.eulerX/me.fieldOfRegardMaxAz,me.eulerY/me.fieldOfRegardMaxElev];
		}
	},
	setAntennae: func (local_dir) {
		# remember to set horizonStabilized when calling this.

		# convert from coordinates to polar
		me.eulerDir = vector.Math.cartesianToEuler(local_dir);

		# Make sure if pitch is 90 or -90 that heading gets set to something sensible
		me.eulerX = me.eulerDir[0]==nil?0:geo.normdeg180(me.eulerDir[0]);
		me.eulerY = me.eulerDir[1];

		# Make array: [heading_degs, pitch_degs, heading_norm, pitch_norm], for convinience, not used atm.
		#me.positionEuler = [me.eulerX,me.eulerDir[1],me.eulerX/me.fieldOfRegardMaxAz,me.eulerDir[1]/me.fieldOfRegardMaxElev];

		# Make the antennae direction-vector be length 1.0
		me.positionDirection = vector.Math.normalize(local_dir);

		# Decompose the antennae direction-vector into seperate angles for Azimuth and Elevation
		me.posAZDeg = -90+R2D*math.acos(vector.Math.normalize(vector.Math.projVectorOnPlane([0,0,1],me.positionDirection))[1]);
		me.posElDeg = R2D*math.asin(vector.Math.normalize(vector.Math.projVectorOnPlane([0,1,0],me.positionDirection))[2]);

		# Make an array that holds: [azimuth_norm, elevation_norm, azimuth_deg, elevation_deg]
		me.positionCart = [me.posAZDeg/me.fieldOfRegardMaxAz, me.posElDeg/me.fieldOfRegardMaxElev,me.posAZDeg,me.posElDeg];
		
		# Note: that all these numbers can be either relative to aircraft or relative to scenery.
		# Its the modes responsibility to call this method with antennae local_dir that is either relative to
		# aircraft, or to landscape so that they match how scanFOV compares the antennae direction to target positions.
		#
		# Make sure that scanFOV() knows what coord system you are operating in. By setting me.horizonStabilized.
	},
	installMapper: func (gmapper) {
		me.gmapper = gmapper;
	},
	isEnabled: func {
		return 1;
	},
	loop: func {
		me.enabled = me.isEnabled();
		me.checks();#F14 custom
		# calc dt here, so we don't get a massive dt when going from disabled to enabled:
		me.elapsed = elapsedProp.getValue();
		me.dt = me.elapsed - me.lastElapsed;
		me.lastElapsed = me.elapsed;
		if (me.enabled) {
			if (me.currentMode.painter and me.currentMode.detectAIR) {
				# We need faster updates to not lose track of oblique flying locks close by when in STT.
				me.ContactNotification.vector = [me.getPriorityTarget()];
				emesary.GlobalTransmitter.NotifyAll(me.ContactNotification);
			}

			while (me.dt > 0.001) {
				# mode tells us how to move disc and to scan
				me.dt = me.currentMode.step(me.dt);# mode already knows where in pattern we are and AZ and bars.

				# we then step to the new position, and scan for each step
				me.scanFOV();
				me.showScan();
			}

		} elsif (size(me.vector_aicontacts_bleps)) {
			# So that when radar is restarted there is not old bleps.
			me.purgeAllBleps();
		}
	},
	loopMedium: func {
		me.loopSpecific(); #F14 custom
		if (we_are_bs) {
			stbySend.setIntValue(1);
			return; #F14 custom
		}
		#
		# It send out what target we are Single-target-track locked onto if any so the target get RWR warning.
		# It also sends out on datalink what we are STT/SAM/TWS locked onto.
		# In addition it notifies the weapons what we have targeted.
		# Plus it sets the MP property for radar standby so others can see us on RWR.
		if (me.enabled) {
			me.focus = me.getPriorityTarget();
			if (me.focus != nil and me.focus.callsign != "") {
				if (me.currentMode.painter) sttSend.setValue(left(md5(me.focus.callsign), 4));
				else sttSend.setValue("");
				#if (steerpoints.sending == nil) {#F14 custom
			        datalink.send_data({"contacts":[{"callsign":me.focus.callsign,"iff":0}]});
			    #}
			} else {
				sttSend.setValue("");
				#if (steerpoints.sending == nil) {#F14 custom
		            datalink.clear_data();
		        #}
			}
			if (me.currentMode.painter or me.currentMode.shortName == "TWS") {#F14 custom
				armament.contact = me.focus;
			} else {
				armament.contact = nil;
			}
			stbySend.setIntValue(0);
		} else {
			armament.contact = nil;
			sttSend.setValue("");
			stbySend.setIntValue(1);
			#if (steerpoints.sending == nil) {#F14 custom
	            datalink.clear_data();
	        #}
		}
		
		me.debug = getprop("debug-radar/debug-main");
	},
	loopSlow: func {
		#
		# Here we ask the NoseRadar for a slice of the sky once in a while.
		#
		if (me.debug > 0) setprop("debug-radar/mode",me.currentMode.longName);#F14 custom
		if (me.enabled and !(me.currentMode.painter and me.currentMode.detectAIR)) {
			emesary.GlobalTransmitter.NotifyAll(me.SliceNotification.slice(self.getPitch(), self.getHeading(), math.min(89.9,math.max(-me.fieldOfRegardMinElev, me.fieldOfRegardMaxElev)*1.414), math.min(89.9,me.fieldOfRegardMaxAz*1.414), me.getRange()*NM2M, !me.currentMode.detectAIR, !me.currentMode.detectSURFACE, !me.currentMode.detectMARINE));
		}
	},
	scanFOV: func {
		#
		# Here we test for IFF and test the radar beam against targets to see if the radar picks them up.
		#
		# Note that this can happen in aircraft coords (ACM modes) or in landscape coords (the other modes).
		me.doIFF = getprop("instrumentation/radar/iff");
    	setprop("instrumentation/radar/iff",0);
    	if (me.doIFF) iff.last_interogate = systime();
    	if (me["gmapper"] != nil) me.gmapper.scanGM(me.eulerX, me.eulerY, me.instantVertFoVradius, me.instantFoVradius,
    		 me.currentMode.bars == 1 or (me.currentMode.bars == 4 and me.currentMode["nextPatternNode"] == 0) or (me.currentMode.bars == 3 and me.currentMode["nextPatternNode"] == 7) or (me.currentMode.bars == 2 and me.currentMode["nextPatternNode"] == 1),
    		 me.currentMode.bars == 1 or (me.currentMode.bars == 4 and me.currentMode["nextPatternNode"] == 2) or (me.currentMode.bars == 3 and me.currentMode["nextPatternNode"] == 3) or (me.currentMode.bars == 2 and me.currentMode["nextPatternNode"] == 3));# The last two parameter is hack

    	# test for passive ECM (chaff)
		# 
		me.closestChaff = 1000000;# meters
		if (size(me.chaffList)) {
			if (me.horizonStabilized) {
				me.globalAntennaeDir = vector.Math.yawVector(-self.getHeading(), me.positionDirection);
			} else {
				me.globalAntennaeDir = vector.Math.rollPitchYawVector(self.getRoll(), self.getPitch(), -self.getHeading(), me.positionDirection);
			}
			
			foreach (me.chaff ; me.chaffList) {
				if (rand() < me.chaffFilter or me.chaff.meters < 10000+10000*rand()) continue;# some chaff are filtered out.
				me.globalToTarget = vector.Math.pitchYawVector(me.chaff.pitch, -me.chaff.bearing, [1,0,0]);
				
				# Degrees from center of radar beam to center of chaff cloud
				me.beamDeviation = vector.Math.angleBetweenVectors(me.globalAntennaeDir, me.globalToTarget);

				if (me.beamDeviation < me.instantFoVradius) {
					if (me.chaff.meters < me.closestChaff) {
						me.closestChaff = me.chaff.meters;
					}
					me.registerChaff(me.chaff);# for displays
					#print("REGISTER CHAFF");
				}# elsif(me.debug > -1) {
					# This is too detailed for most debugging, remove later
				#	setprop("debug-radar/main-beam-deviation-chaff", me.beamDeviation);
				#}
			}
		}

    	me.testedPrio = 0;
		foreach(contact ; me.vector_aicontacts_for) {
			if (me.doIFF == 1) {
	            me.iffr = iff.interrogate(contact.prop);
	            if (me.iffr) {
	                contact.iff = me.elapsed;
	            } else {
	                contact.iff = -me.elapsed;
	            }
	        }
			if (me.elapsed - contact.getLastBlepTime() < me.currentMode.minimumTimePerReturn) {
				if(me.debug > 1 and me.currentMode.painter and contact == me.getPriorityTarget()) {
					me.testedPrio = 1;
				}
				continue;# To prevent double detecting in overlapping beams
			}

			me.dev = contact.getDeviationStored();

			if (me.horizonStabilized) {
				# ignore roll and pitch

				# Vector that points to target in radar coordinates as if aircraft it was not rolled or pitched.
				me.globalToTarget = vector.Math.eulerToCartesian3X(-me.dev.bearing,me.dev.elevationGlobal,0);

				# Vector that points to target in radar coordinates as if aircraft it was not yawed, rolled or pitched.
				me.localToTarget = vector.Math.yawVector(self.getHeading(), me.globalToTarget);
				#if (contact == me.vector_aicontacts_for[0]) print(math.round(self.getHeading())," vs ",math.round(me.dev.bearing)," at ",math.round(me.dev.elevationGlobal)," for ",contact.get_Callsign());
			} else {
				# Vector that points to target in local radar coordinates.
				me.localToTarget = vector.Math.eulerToCartesian3X(-me.dev.azimuthLocal,me.dev.elevationLocal,0);
			}

			# Degrees from center of radar beam to target, note that positionDirection must match the coord system defined by horizonStabilized.
			me.beamDeviation = vector.Math.angleBetweenVectors(me.positionDirection, me.localToTarget);

			if(me.debug > 1 and me.currentMode.painter and contact == me.getPriorityTarget()) {
				# This is too detailed for most debugging, remove later
				setprop("debug-radar/main-beam-deviation", me.beamDeviation);
				me.testedPrio = 1;
			}
			if (me.beamDeviation < me.instantFoVradius and (me.dev.rangeDirect_m < me.closestChaff or rand() < me.chaffFilter) ) {#  and (me.closureReject == -1 or me.dev.closureSpeed > me.closureReject)
				# TODO: Refine the chaff conditional (ALOT)
				me.registerBlep(contact, me.dev, me.currentMode.painter, me.currentMode.pulse);
				#print("REGISTER BLEP");

				# Return here, so that each instant FoV max gets 1 target:
				# TODO: refine by testing angle between contacts seen in this FoV
				break;
			}
			#if (contact == me.vector_aicontacts_for[0]) print(me.horizonStabilized," debug-radar/main-beam-deviation", me.beamDeviation);
		}

		if(me.debug > 1 and me.currentMode.painter and !me.testedPrio) {
			setprop("debug-radar/main-beam-deviation", "--unseen-lock--");
		}
	},
	registerBlep: func (contact, dev, stt, doppler = 1) {
		if (!contact.isVisible()) {return 0;}
		if (doppler) {
			if (contact.isHiddenFromDoppler()) {
				return 0;
			}
			if (math.abs(dev.closureSpeed) < me.currentMode.minClosure) {
				return 0;
			}
		}

		me.maxDistVisible = me.currentMode.rcsFactor * me.targetRCSSignal(self.getCoord(), dev.coord, contact.model, dev.heading, dev.pitch, dev.roll,me.rcsRefDistance*NM2M,me.rcsRefValue);

		if (me.maxDistVisible > dev.rangeDirect_m) {
			me.extInfo = me.currentMode.getSearchInfo(contact);# if the scan gives heading info etc..

			if (me.extInfo == nil) {
				return 0;
			}
			contact.blep(me.elapsed, me.extInfo, me.maxDistVisible, stt);
			if (!me.containsVectorContact(me.vector_aicontacts_bleps, contact)) {
				append(me.vector_aicontacts_bleps, contact);
			}
			return 1;
		}
		return 0;
	},
	registerChaff: func (chaff) {
		chaff.seenTime = me.elapsed;
		if (!me.containsVector(me.chaffSeenList, chaff)) {
			append(me.chaffSeenList, chaff);
		}
	},
	purgeBleps: func {
		#ok, lets clean up old bleps:
		me.vector_aicontacts_bleps_tmp = [];
		me.elapsed = elapsedProp.getValue();
		foreach(contact ; me.vector_aicontacts_bleps) {
			me.bleps_cleaned = [];
			foreach (me.blep;contact.getBleps()) {
				if (me.elapsed - me.blep.getBlepTime() < me.currentMode.timeToFadeBleps) {# F14 custom
					append(me.bleps_cleaned, me.blep);
				}
			}
			contact.setBleps(me.bleps_cleaned);
			if (size(me.bleps_cleaned)) {
				append(me.vector_aicontacts_bleps_tmp, contact);
				me.currentMode.testContact(contact);# TODO: do this smarter
			} else {
				me.currentMode.prunedContact(contact);
			}
		}
		#print("Purged ", size(me.vector_aicontacts_bleps) - size(me.vector_aicontacts_bleps_tmp), " bleps   remains:",size(me.vector_aicontacts_bleps_tmp), " orig ",size(me.vector_aicontacts_bleps));
		me.vector_aicontacts_bleps = me.vector_aicontacts_bleps_tmp;

		#lets purge the old chaff also, both seen and unseen
		me.wnd = wndprop.getValue();
		me.chaffLifetime = math.max(0, me.wnd==0?25:25*(1-me.wnd/50));
		me.chaffList_tmp = [];
		foreach(me.evilchaff ; me.chaffList) {
			if (me.elapsed - me.evilchaff.releaseTime < me.chaffLifetime) {
				append(me.chaffList_tmp, me.evilchaff);
			}
		}
		me.chaffList = me.chaffList_tmp;

		me.chaffSeenList_tmp = [];
		foreach(me.evilchaff ; me.chaffSeenList) {
			if (me.elapsed - me.evilchaff.releaseTime < me.chaffLifetime or me.elapsed - me.evilchaff.seenTime < me.timeToKeepBleps) {
				append(me.chaffSeenList_tmp, me.evilchaff);
			}
		}
		me.chaffSeenList = me.chaffSeenList_tmp;
	},
	purgeAllBleps: func {
		#ok, lets delete all bleps:
		foreach(contact ; me.vector_aicontacts_bleps) {
			contact.setBleps([]);
		}
		me.vector_aicontacts_bleps = [];
		me.chaffSeenList = [];
	},
	targetRCSSignal: func(aircraftCoord, targetCoord, targetModel, targetHeading, targetPitch, targetRoll, myRadarDistance_m = 74000, myRadarStrength_rcs = 3.2) {
		#
		# test method. Belongs in rcs.nas.
		#
	    me.target_front_rcs = nil;
	    if ( contains(rcs.rcs_oprf_database,targetModel) ) {
	        me.target_front_rcs = rcs.rcs_oprf_database[targetModel];
	    } elsif ( contains(rcs.rcs_database,targetModel) ) {
	        me.target_front_rcs = rcs.rcs_database[targetModel];
	    } else {
	        # GA/Commercial return most likely
	        me.target_front_rcs = rcs.rcs_oprf_database["default"];
	    }	    
	    me.target_rcs = rcs.getRCS(targetCoord, targetHeading, targetPitch, targetRoll, aircraftCoord, me.target_front_rcs);

	    # standard formula
	    return myRadarDistance_m/math.pow(myRadarStrength_rcs/me.target_rcs, 1/4);
	},
	getActiveBleps: func {
		return me.vector_aicontacts_bleps;
	},
	getActiveChaff: func {
		return me.chaffSeenList;
	},
	showScan: func {
		if (me.debug > 0) {
			if (me["canvas2"] == nil) {
	            me.canvas2 = canvas.Window.new([512,512],"dialog").set('title',"Scan").getCanvas(1);
				me.canvas_root2 = me.canvas2.createGroup().setTranslation(256,256);
				me.canvas2.setColorBackground(0.25,0.25,1);
			}

			if (me.elapsed - me.currentMode.lastFrameStart < 0.1) {
				me.clearShowScan();
			}
			me.canvas_root2.createChild("path")
				.setTranslation(256*me.eulerX/60, -256*me.eulerY/60)
				.moveTo(0, 256*me.instantFoVradius/60)
				.lineTo(0, -256*me.instantFoVradius/60)
				.setColor(1,1,1);
		}
	},
	clearShowScan: func {
		if (me["canvas2"] == nil or me.debug < 1) return;
		me.canvas_root2.removeAllChildren();
		if (me.horizonStabilized) {
			me.canvas_root2.createChild("path")
				.moveTo(-250, 0)
				.lineTo(250, 0)
				.setColor(1,1,0)
				.setStrokeLineWidth(4);
		} else {
			me.canvas_root2.createChild("path")
				.moveTo(256*-5/60, 256*-1.5/60)
				.lineTo(256*5/60, 256*-1.5/60)
				.lineTo(256*5/60,  256*15/60)
				.lineTo(256*-5/60,  256*15/60)
				.lineTo(256*-5/60, 256*-1.5/60)
				.setColor(1,1,0)
				.setStrokeLineWidth(4);
		}
	},
	containsVector: func (vec, item) {
		foreach(test; vec) {
			if (test == item) {
				return 1;
			}
		}
		return 0;
	},

	containsVectorContact: func (vec, item) {
		foreach(test; vec) {
			if (test.equals(item)) {
				return 1;
			}
		}
		return 0;
	},

	vectorIndex: func (vec, item) {
		me.i = 0;
		foreach(test; vec) {
			if (test == item) {
				return me.i;
			}
			me.i += 1;
		}
		return -1;
	},
	del: func {
        emesary.GlobalTransmitter.DeRegister(me.ActiveDiscRadarRecipient);
    },
};










var SPOT_SCAN = -1; # must be -1





#  ██████   █████  ██████   █████  ██████      ███    ███  ██████  ██████  ███████ 
#  ██   ██ ██   ██ ██   ██ ██   ██ ██   ██     ████  ████ ██    ██ ██   ██ ██      
#  ██████  ███████ ██   ██ ███████ ██████      ██ ████ ██ ██    ██ ██   ██ █████   
#  ██   ██ ██   ██ ██   ██ ██   ██ ██   ██     ██  ██  ██ ██    ██ ██   ██ ██      
#  ██   ██ ██   ██ ██████  ██   ██ ██   ██     ██      ██  ██████  ██████  ███████ 
#                                                                                  
#                                                                                  
var RadarMode = {
	#
	# Subclass and modify as needed.
	#
	radar: nil,
	range: 40,
	minRange: 5,
	maxRange: 160,
	az: 60,
	bars: 1,
	azimuthTilt: 0,# modes set these depending on where they want the pattern to be centered.
	elevationTilt: 0,
	barHeight: 0.80,# multiple of instantFoVradius
	barPattern:  [ [[-1,0],[1,0]] ],     # The second is multitude of instantFoVradius, the first is multitudes of me.az
	barPatternMin: [0],
	barPatternMax: [0],
	nextPatternNode: 0,
	scanPriorityEveryFrame: 0,# Related to SPOT_SCAN.
	timeToFadeBleps: 13,
	rootName: "Base",
	shortName: "",
	longName: "",
	superMode: nil,
	minimumTimePerReturn: 0.5,
	rcsFactor: 0.9,
	lastFrameStart: -1,
	lastFrameDuration: 5,
	detectAIR: 1,
	detectSURFACE: 0,
	detectMARINE: 0,
	pulse: DOPPLER, # MONO or DOPPLER
	minClosure: 0, # kt
	cursorAz: 0,
	cursorNm: 20,
	upperAngle: 10,
	lowerAngle: 10,
	painter: 0, # if the mode when having a priority target will produce a hard lock on target.
	mapper: 0,
	discSpeed_dps: 1,# current disc speed. Must never be zero.
	setRange: func (range) {
		me.testMulti = me.maxRange/range;
		if (int(me.testMulti) != me.testMulti) {
			# max range is not dividable by range, so we don't change range
			return 0;
		}
		me.range = math.min(me.maxRange, range);
		me.range = math.max(me.minRange, me.range);
		return range == me.range;
	},
	getRange: func {
		return me.range;
	},
	_increaseRange: func {
		me.range*=2;
		if (me.range>me.maxRange) {
			me.range*=0.5;
			return 0;
		}
		return 1;
	},
	_decreaseRange: func {
		me.range *= 0.5;
		if (me.range < me.minRange) {
			me.range *= 2;
			return 0;
		}
		return 1;
	},
	getDeviation: func {
		# how much the pattern is deviated from straight ahead in azimuth
		return me.azimuthTilt;
	},
	getBars: func {
		return me.bars;
	},
	getAz: func {
		return me.az;
	},
	constrainAz: func () {
		# Convinience method that the modes can use.
		if (me.az == me.radar.fieldOfRegardMaxAz) {
			me.azimuthTilt = 0;
		} elsif (me.azimuthTilt > me.radar.fieldOfRegardMaxAz-me.az) {
			me.azimuthTilt = me.radar.fieldOfRegardMaxAz-me.az;
		} elsif (me.azimuthTilt < -me.radar.fieldOfRegardMaxAz+me.az) {
			me.azimuthTilt = -me.radar.fieldOfRegardMaxAz+me.az;
		}
	},
	getPriority: func {
		return me["priorityTarget"];
	},
	computePattern: func {
		# Translate the normalized pattern nodes into degrees. Since me.az or maybe me.bars have tendency to change rapidly
		# We do this every step. Its fast anyway.
		me.currentPattern = [];
		foreach (me.eulerNorm ; me.barPattern[me.bars-1]) {
			me.patternNode = [me.eulerNorm[0]*me.az, me.eulerNorm[1]*me.radar.instantFoVradius*me.barHeight];
			append(me.currentPattern, me.patternNode);
		}
		return me.currentPattern;
	},
	step: func (dt) {
		me.radar.horizonStabilized = 1;# Might be unset inside preStep()

		# Individual modes override this method and get ready for the step.
		# Inside this they typically set 'azimuthTilt' and 'elevationTilt' for moving the pattern around.
		me.preStep();
		
		# Lets figure out the desired antennae tilts
	 	me.azimuthTiltIntern = me.azimuthTilt;
	 	me.elevationTiltIntern = me.elevationTilt;
		if (me.nextPatternNode == SPOT_SCAN and me.priorityTarget != nil) {
			# We never do spot scans in ACM modes so no check for horizonStabilized here.
			me.lastBlep = me.priorityTarget.getLastBlep();
			if (me.lastBlep != nil) {
				me.azimuthTiltIntern = me.lastBlep.getAZDeviation();
				me.elevationTiltIntern = me.lastBlep.getElev();
			} else {
				me.priorityTarget = nil;
				me.undesignate();
				me.nextPatternNode == 0;
			}
		} elsif (me.nextPatternNode == SPOT_SCAN) {
			# We cannot do spot scan on stuff we cannot see, reverting back to pattern
			me.nextPatternNode = 0;
		}

		# now lets check where we want to move the disc to
		me.currentPattern      = me.computePattern();
		me.targetAzimuthTilt   = me.azimuthTiltIntern+(me.nextPatternNode!=SPOT_SCAN?me.currentPattern[me.nextPatternNode][0]:0);
		me.targetElevationTilt = me.elevationTiltIntern+(me.nextPatternNode!=SPOT_SCAN?me.currentPattern[me.nextPatternNode][1]:0);

		# The pattern min/max pitch when not tilted.
		me.min = me.barPatternMin[me.bars-1]*me.barHeight*me.radar.instantFoVradius;
		me.max = me.barPatternMax[me.bars-1]*me.barHeight*me.radar.instantFoVradius;

		# We check if radar gimbal mount can turn enough.
		me.gimbalInBounds = 1;
		if (me.radar.horizonStabilized) {
			# figure out if we reach the gimbal limit
	 		me.actualMin = self.getPitch()+me.radar.fieldOfRegardMinElev;
	 		me.actualMax = self.getPitch()+me.radar.fieldOfRegardMaxElev;
	 		if (me.targetElevationTilt < me.actualMin) {
	 			me.gimbalInBounds = 0;
	 		} elsif (me.targetElevationTilt > me.actualMax) {
	 			me.gimbalInBounds = 0;
	 		}
 		}
 		if (!me.gimbalInBounds) {
 			# Don't move the antennae if it cannot reach whats requested.
 			# This basically stop the radar from working while still not on standby
 			# until better attitude is reached.
 			#
 			# It used to attempt to scan in edge of FoR but thats not really helpful to a pilot.
 			# If need to scan while extreme attitudes then the are specific modes for that (in some aircraft).
 			me.radar.setAntennae(me.radar.positionDirection);
 			#print("db-Out of gimbal bounds");
	 		return 0;
	 	}

	 	# For help with cursor limits we need to compute these
		if (me.radar.horizonStabilized and me.gimbalInBounds) {
			me.lowerAngle = me.min+me.elevationTiltIntern;
			me.upperAngle = me.max+me.elevationTiltIntern;
		} else {
			me.lowerAngle = 0;
			me.upperAngle = 0;
		}

	 	# Lets get a status for where we are in relation to where we are going
		me.targetDir = vector.Math.pitchYawVector(me.targetElevationTilt, -me.targetAzimuthTilt, [1,0,0]);# A vector for where we want the disc to go
		me.angleToNextNode = vector.Math.angleBetweenVectors(me.radar.positionDirection, me.targetDir);# Lets test how far from the target tilts we are.
		
		# Move the disc
		if (me.angleToNextNode < me.radar.instantFoVradius) {
			# We have reached our target
			me.radar.setAntennae(me.targetDir);
			me.nextPatternNode += 1;
			if (me.nextPatternNode >= size(me.currentPattern)) {
				me.nextPatternNode = (me.scanPriorityEveryFrame and me.priorityTarget!=nil)?SPOT_SCAN:0;
				me.frameCompleted();
			}
			#print("db-node:", me.nextPatternNode);
			# Now the antennae has been moved and we return how much leftover dt there is to the main radar.
			return dt-me.angleToNextNode/me.discSpeed_dps;# Since we move disc seperately in axes, this is not strictly correct, but close enough.
		}

		# Lets move each axis of the radar seperate, as most radars likely has 2 joints anyway.
		me.maxMove = math.min(me.radar.instantFoVradius*overlapHorizontal, me.discSpeed_dps*dt);# 1.75 instead of 2 is because the FoV is round so we overlap em a bit

		# Azimuth
		me.distance_deg = me.targetAzimuthTilt - me.radar.eulerX;
		if (me.distance_deg >= 0) {
			me.moveX =  math.min(me.maxMove, me.distance_deg);
		} else {
			me.moveX = math.max(-me.maxMove, me.distance_deg);
		}
		me.newX = me.radar.eulerX + me.moveX;

		# Elevation
		me.distance_deg = me.targetElevationTilt - me.radar.eulerY;
		if (me.distance_deg >= 0) {
			me.moveY =  math.min(me.maxMove, me.distance_deg);
		} else {
			me.moveY =  math.max(-me.maxMove, me.distance_deg);
		}
		me.newY = me.radar.eulerY + me.moveY;

		# Convert the angles to a vector and set the new antennae position
		me.newPos = vector.Math.pitchYawVector(me.newY, -me.newX, [1,0,0]);
		me.radar.setAntennae(me.newPos);

		# As the two joins move at the same time, we find out which moved the most
		me.movedMax = math.max(math.abs(me.moveX), math.abs(me.moveY));
		if (me.movedMax == 0) {
			# This should really not happen, we return 0 to make sure the while loop don't get infinite.
			print("me.movedMax == 0");
			return 0;
		}
		if (me.movedMax > me.discSpeed_dps) {
			print("me.movedMax > me.discSpeed_dps");
			return 0;
		}
		return dt-me.movedMax/me.discSpeed_dps;
	},
	frameCompleted: func {
		if (me.lastFrameStart != -1) {
			me.lastFrameDuration = me.radar.elapsed - me.lastFrameStart;
		}
		me.lastFrameStart = me.radar.elapsed;
	},
	setCursorDeviation: func (cursor_az) {
		me.cursorAz = cursor_az;
	},
	getCursorDeviation: func {
		return me.cursorAz;
	},
	setCursorDistance: func (nm) {
		# Return if the cursor should be distance zeroed.
		return 0;
	},
	getCursorAltitudeLimits: func {
		# Used in F-16 with two numbers next to cursor that indicates min/max for radar pattern in altitude above sealevel.
		# It needs: me.lowerAngle, me.upperAngle and me.cursorNm
		me.vectorToDist = [math.cos(me.upperAngle*D2R), 0, math.sin(me.upperAngle*D2R)];
		me.selfC = self.getCoord();
		me.geo = vector.Math.vectorToGeoVector(me.vectorToDist, me.selfC);
		me.geo = vector.Math.product(me.cursorNm*NM2M, vector.Math.normalize(me.geo.vector));
		me.up = geo.Coord.new();
		me.up.set_xyz(me.selfC.x()+me.geo[0],me.selfC.y()+me.geo[1],me.selfC.z()+me.geo[2]);
		me.vectorToDist = [math.cos(me.lowerAngle*D2R), 0, math.sin(me.lowerAngle*D2R)];
		me.geo = vector.Math.vectorToGeoVector(me.vectorToDist, me.selfC);
		me.geo = vector.Math.product(me.cursorNm*NM2M, vector.Math.normalize(me.geo.vector));
		me.down = geo.Coord.new();
		me.down.set_xyz(me.selfC.x()+me.geo[0],me.selfC.y()+me.geo[1],me.selfC.z()+me.geo[2]);
		return [me.up.alt()*M2FT, me.down.alt()*M2FT];
	},
	leaveMode: func {
		# Warning: In this method do not set anything on me.radar only on me.
		me.lastFrameStart = -1;
	},
	enterMode: func {
		
	},
	designatePriority: func (contact) {},
	cycleDesignate: func {},
	testContact: func (contact) {},
	prunedContact: func (c) {
		if (c.equalsFast(me["priorityTarget"])) {
			me.priorityTarget = nil;
		}
	},
};#                                    END Radar Mode class






#  ██████   █████  ████████  █████  ██      ██ ███    ██ ██   ██ 
#  ██   ██ ██   ██    ██    ██   ██ ██      ██ ████   ██ ██  ██  
#  ██   ██ ███████    ██    ███████ ██      ██ ██ ██  ██ █████   
#  ██   ██ ██   ██    ██    ██   ██ ██      ██ ██  ██ ██ ██  ██  
#  ██████  ██   ██    ██    ██   ██ ███████ ██ ██   ████ ██   ██ 
#                                                                
#                                                                
DatalinkRadar = {
	# I check the sky 360 deg for anything on datalink
	#
	# I will set 'blue' and 'blueIndex' on contacts.
	# blue==1: On our datalink
	# blue==2: Targeted by someone on our datalink
	#
	# Direct line of sight required for ~1000MHz signal.
	#
	# This class is only semi generic!
	new: func (rate, max_dist_nm) {
		var dlnk = {parents: [DatalinkRadar, Radar]};
		
		dlnk.max_dist_nm = max_dist_nm;
		dlnk.index = 0;
		dlnk.vector_aicontacts = [];
		dlnk.vector_aicontacts_for = [];
		dlnk.timer          = maketimer(rate, dlnk, func dlnk.scan());

		dlnk.DatalinkRadarRecipient = emesary.Recipient.new("DatalinkRadarRecipient");
		dlnk.DatalinkRadarRecipient.radar = dlnk;
		dlnk.DatalinkRadarRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "AINotification") {
	        	#printf("DLNKRadar recv: %s", notification.NotificationType);
    		    me.radar.vector_aicontacts = notification.vector;
    		    me.radar.index = 0;
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(dlnk.DatalinkRadarRecipient);
		dlnk.DatalinkNotification = VectorNotification.new("DatalinkNotification");
		dlnk.DatalinkNotification.updateV(dlnk.vector_aicontacts_for);
		dlnk.timer.start();
		return omni;
	},

	scan: func () {
		if (!me.enabled) return;
		
		#this loop is really fast. But we only check 1 contact per call
		if (me.index >= size(me.vector_aicontacts)) {
			# will happen if there is no contacts or if contact(s) went away
			me.index = 0;
			return;
		}
		me.contact = me.vector_aicontacts[me.index];
		me.wasBlue = me.contact["blue"];
		me.cs = me.contact.get_Callsign();
		if (me.wasBlue == nil) me.wasBlue = 0;

		if (!me.contact.isValid()) {
			me.contact.blue = 0;
			if (me.wasBlue > 0) {
				#print(me.cs," is invalid and purged from Datalink");
				me.new_vector_aicontacts_for = [];
				foreach (me.c ; me.vector_aicontacts_for) {
					if (!me.c.equals(me.contact) and !me.c.equalsFast(me.contact)) {
						append(me.new_vector_aicontacts_for, me.c);
					}
				}
				me.vector_aicontacts_for = me.new_vector_aicontacts_for;
			}
		} else {
			

			if (me.contact.getRangeDirect()*M2NM > me.max_dist_nm) {me.index += 1;return;}
			

	        me.lnk = datalink.get_data(me.cs);
	        if (!me.contact.isValid()) {
	        	me.lnk = nil;
	        }
	        if (me.lnk != nil and me.lnk.on_link() == 1) {
	            me.blue = 1;
	            me.blueIndex = me.lnk.index()+1;
	        } elsif (me.cs == getprop("link16/wingman-4")) { # Hack that the F16 need. Just ignore it, as nil wont cause expection.
	            me.blue = 1;
	            me.blueIndex = 0;
	        } else {
	        	me.blue = 0;
	            me.blueIndex = -1;
	        }
	        if (!me.blue and me.lnk != nil and me.lnk.tracked() == 1) {
	            me.blue = 2;
	            me.blueIndex = me.lnk.tracked_by_index()+1;
	        }

	        me.contact.blue = me.blue;
	        if (me.blue > 0) {
	        	me.contact.blueIndex = me.blueIndex;
				if (!AirborneRadar.containsVectorContact(me.vector_aicontacts_for, me.contact)) {
					append(me.vector_aicontacts_for, me.contact);
					emesary.GlobalTransmitter.NotifyAll(me.DatalinkNotification.updateV(me.vector_aicontacts_for));
				}
			} elsif (me.wasBlue > 0) {
				me.new_vector_aicontacts_for = [];
				foreach (me.c ; me.vector_aicontacts_for) {
					if (!me.c.equals(me.contact) and !me.c.equalsFast(me.contact)) {
						append(me.new_vector_aicontacts_for, me.c);
					}
				}
				me.vector_aicontacts_for = me.new_vector_aicontacts_for;
			}
		}
		me.index += 1;
        if (me.index > size(me.vector_aicontacts)-1) {
        	me.index = 0;
        	emesary.GlobalTransmitter.NotifyAll(me.DatalinkNotification.updateV(me.vector_aicontacts_for));
        }
	},
	del: func {
        emesary.GlobalTransmitter.DeRegister(me.DatalinkRadarRecipient);
    },
};










########################### BEGIN NON-GENERIC CLASSES ##########################






#   █████  ██     ██  ██████         █████  
#  ██   ██ ██     ██ ██             ██   ██ 
#  ███████ ██  █  ██ ██   ███ █████  ██████ 
#  ██   ██ ██ ███ ██ ██    ██            ██ 
#  ██   ██  ███ ███   ██████         █████  
#                                           
#                                           
var AWG9 = {
	#
	# Root modes is  0: CRM  1: ACM
	#
	fieldOfRegardMaxAz: 60,
	fieldOfRegardMaxElev: 60,
	fieldOfRegardMinElev: -80,
	instantFoVradius: 2.2*0.5,#
	instantVertFoVradius: 2.2*0.5,# real vert radius (used by ground mapper)
	instantHoriFoVradius: 2.2*0.5,# (not used)
	rcsRefDistance: 89,
	rcsRefValue: 3.2,
	targetHistory: 3,# Not used in F-14
	isEnabled: func {
		me.e = RadarServicable.getBoolValue() and DisplayRdr.getBoolValue() and RadarStandby.getValue() != 1;# and !getprop("/fdm/jsbsim/gear/unit[0]/WOW")
		return me.e;
	},
	loopSpecific: func {
		me.updateDisplays();
	},
	setAAMode: func {
		if (me.rootMode != 0) {
			me.rootMode = 0;
			me.oldMode = me.currentMode;
			me.currentModeIndex = 0;
			me.newMode = me.mainModes[me.rootMode][me.currentModeIndex];
			me.setCurrentMode(me.newMode, me.oldMode["priorityTarget"]);
		}
	},
	setAirMode: func (currentModeIndex) {
		if (currentModeIndex == me.currentModeIndex) return 0;
		if (currentModeIndex == -1) return 0;
		
		
		me.newMode = me.mainModes[me.rootMode][currentModeIndex];
		me.oldMode = me.currentMode;
		if (me.currentModeIndex != 4 and me.currentModeIndex != 5 and (currentModeIndex == 4 or currentModeIndex == 5)) {
			me.newMode.superMode  = me.oldMode;
			me.newMode.superIndex = me.currentModeIndex;
		}
		if (me.oldMode.shortName == PSTTMode.shortName and me.newMode.shortName == PDSTTMode.shortName) {
			me.newMode.superMode  = me.oldMode["superMode"];
			me.newMode.superIndex = me.oldMode["superIndex"];
		}
		if (me.oldMode.shortName == PDSTTMode.shortName and me.newMode.shortName == PSTTMode.shortName) {
			me.newMode.superMode  = me.oldMode["superMode"];
			me.newMode.superIndex = me.oldMode["superIndex"];
		}
		me.currentModeIndex = currentModeIndex;
		me.setCurrentMode(me.newMode, me.oldMode["priorityTarget"]);
		return 1;
	},
	toggleAirMode: func {
		currentModeIndex = me.currentModeIndex+1;
		if (currentModeIndex > 3) currentModeIndex = 0;

		me.newMode = me.mainModes[me.rootMode][currentModeIndex];
		me.oldMode = me.currentMode;
		me.currentModeIndex = currentModeIndex;
		me.setCurrentMode(me.newMode, me.oldMode["priorityTarget"]);
		return 1;
	},
	showAZ: func {
		me.currentMode.showAZ();
	},
	getTiltKnob: func {
		me.theKnob = antennae_knob_prop.getValue();
		if (math.abs(me.theKnob) < 1) {
			antennae_knob_prop.setValue(0);
			me.theKnob = 0;
		}
		if (me.theKnob > me.fieldOfRegardMaxElev-10) {
			me.theKnob = me.fieldOfRegardMaxElev-10;
		} elsif (me.theKnob < me.fieldOfRegardMinElev+10) {
			me.theKnob = me.fieldOfRegardMinElev+10;
		}
		return me.theKnob;
	},
	getSideKnob: func {
		me.theKnob = antennae_az_knob_prop.getValue();# -60 to 60
		if (math.abs(me.theKnob) < 2.5) {
			antennae_az_knob_prop.setValue(0);
			me.theKnob = 0;
		}
		if (me.theKnob > me.fieldOfRegardMaxAz) {
			me.theKnob = me.fieldOfRegardMaxAz;
		} elsif (me.theKnob < -me.fieldOfRegardMaxAz) {
			me.theKnob = -me.fieldOfRegardMaxAz;
		}
		return me.theKnob;
	},
	checks: func {
		me.cycleField();
		me.selectHookCheck();
		antennae_deg_prop.setValue(me.eulerY);
		RangeActualRadar2.setValue(me.getRange());
	},
	updateDisplays: func {
		me.updateTID();
		xmlDisplays.updateTgts();
		az_field_on_off.setBoolValue(!me.currentMode.painter);
		if (!me.currentMode.painter) {
			az_field_left.setDoubleValue(me.currentMode.azimuthTilt-me.currentMode.az);
			az_field_right.setDoubleValue(me.currentMode.azimuthTilt+me.currentMode.az);
		}
	},
	updateDDD: func {
		me.caretPosition = me.getCaretPosition();
		SwpFac.setValue(me.caretPosition[0]);
	},
	updateTID: func {
		# Keep the 120 az for now, as the smaller az's can be rotated from side to side
		# That needs to be done in xml first. Need 20 deg, 40 deg, 80 deg and 120 deg.
	},
	selectHookCheck: func {
	    me.tgt_cmd = SelectTargetCommand.getValue();
	    SelectTargetCommand.setIntValue(0);
	    if (me.tgt_cmd == 0) {
	    	me.tgt_cmd = SelectTargetCommandJoy.getValue();
	    }
	    SelectTargetCommandJoy.setIntValue(0);
	    if (pilot_lock and me.tgt_cmd != 0) {
	    	me.hk = Hook.getValue();
	    	if (me.hk == nil or me.hk == "") return;
	    	me.designateMPCallsign(me.hk);
	    	return;
	    }
		if (me.tgt_cmd != 0 and !pilot_lock) {
			me.cycleDesignate();# for now only 1 direction
			me.prio = awg9Radar.getPriorityTarget();
			if (me.prio != nil) {
				screen.log.write("RIO: Selected "~me.prio.get_Callsign()~".", 1,1,0);
			} elsif (me.currentMode.shortName == PulseDMode.shortName) {
				screen.log.write("RIO: Cannot select in this mode.", 1,1,0);
			} else {
				screen.log.write("RIO: Nothing to select.", 1,1,0);
			}
		}
		if (we_are_bs and me.getPriorityTarget() == nil) Hook.setValue("");
	},
	cycleField: func {
		me.b_cmd = BarsCommand.getValue();
	    BarsCommand.setIntValue(0);
		if (me.b_cmd != 0 and !me.currentMode.painter) {
			me.cycleBars();
			me.rioRadar();
		}
		me.a_cmd = AzCommand.getValue();
	    AzCommand.setIntValue(0);
		if (me.a_cmd != 0 and !me.currentMode.painter) {
			me.cycleAZ();
			me.rioRadar();
		}
		me.updateDDD();
	},
	rioRadar: func {
		screen.log.write(sprintf("RIO: Scanning %d bars and %d degrees.",bars2bars[me.currentMode.bars-1],me.currentMode.az*2), 1,1,0);
		if (we_are_bs) {
			az_field.setIntValue(me.currentMode.az);
			bars_index.setIntValue(me.currentMode.bars);
		}
	},
	modeSwitch: func {
		me.md = me.currentMode;
		if (me.md.shortName == PDSTTMode.shortName) {
			if(!pilot_lock or we_are_bs) WcsMode.setValue(2);
			AntTrk.setBoolValue(1);
		} elsif (me.md.shortName == PSTTMode.shortName) {
			if(!pilot_lock or we_are_bs) WcsMode.setValue(1);
			AntTrk.setBoolValue(1);
		} else {
			if(!pilot_lock or we_are_bs) WcsMode.setValue(mode2wcs[me.currentModeIndex]);
			AntTrk.setBoolValue(0);
		}
		if (we_are_bs) {
			az_field.setIntValue(me.currentMode.az);
			bars_index.setIntValue(me.currentMode.bars);
		}
	},
	designateMPCallsign: func (mp) {
		# Doesn't really work well for AI, if even RIO and Pilot has the same AI locally..
		if (mp == "" and Hook.getValue() == "") return;
		foreach (me.u; me.vector_aicontacts_for) {
			if (left(md5(me.u.getCallsign()),7) == mp) {
				me.registerBlep(me.u, me.u.getDeviationStored(), me.currentMode.painter, me.currentMode.pulse);# In case RIO's radar has seen him, but pilots radar has not.
				me.currentMode.designatePriority(me.u);
				screen.log.write("RIO: Selected "~me.u.get_Callsign(), 1,1,0);
				print("DualControl: RIO hooked "~me.u.get_Callsign());
				return;
			}
		}
		me.currentMode.designatePriority(nil);
		screen.log.write("RIO: Selection failed handover. Try press 'y' to repeat it.", 1,1,0);
		print("RIO Dual Control: Selection failed handover.");
	},
};

















#   █████  ██     ██  ██████         █████      ███    ███  █████  ██ ███    ██     ███    ███  ██████  ██████  ███████ 
#  ██   ██ ██     ██ ██             ██   ██     ████  ████ ██   ██ ██ ████   ██     ████  ████ ██    ██ ██   ██ ██      
#  ███████ ██  █  ██ ██   ███ █████  ██████     ██ ████ ██ ███████ ██ ██ ██  ██     ██ ████ ██ ██    ██ ██   ██ █████   
#  ██   ██ ██ ███ ██ ██    ██            ██     ██  ██  ██ ██   ██ ██ ██  ██ ██     ██  ██  ██ ██    ██ ██   ██ ██      
#  ██   ██  ███ ███   ██████         █████      ██      ██ ██   ██ ██ ██   ████     ██      ██  ██████  ██████  ███████ 
#                                                                                                                       
#                                                                                                                       
var AWG9Mode = {
	minRange: 5,
	maxRange: 200,
	bars: 3,
	az: 60,
	barHeight: 1.00,
	barPattern:  [ [[-1,0],[1,0]],     # 1, 2, 4, 8               # These are multitudes of [me.az, instantFoVradius]
	               [[-1,-0.785],[1,-0.785],[1,0.785],[-1,0.785]],
	               [[1,-3*0.685],[1,3*0.685],[-1,3*0.685],[-1,1*0.685],[1,1*0.685],[1,-1*0.685],[-1,-1*0.685],[-1,-3*0.685]],
	               [[1,-7*0.625],[1,7*0.625],[-1,7*0.625],[-1,5*0.625],[1,5*0.625],[1,3*0.625],[-1,3*0.625],[-1,1*0.625],[1,1*0.625],[1,-1*0.625],[-1,-1*0.625],[-1,-3*0.625],[1,-3*0.625],[1,-5*0.625],[-1,-5*0.625],[-1,-7*0.625]] ],
	barPatternMin: [0, -0.785, -3*0.685, -7*0.625],
	barPatternMax: [0,  0.785,  3*0.685,  7*0.625],
	rootName: "AIR",
	shortName: "",
	longName: "",
	minTimeToFadeBleps: 10,
	cycleAZ: func {
		if (me.az == 10) me.az = 20;
		elsif (me.az == 20) me.az = 40;
		elsif (me.az == 40) me.az = AWG9.fieldOfRegardMaxAz;
		elsif (me.az == AWG9.fieldOfRegardMaxAz) me.az = 10;
		else me.az = 10;
		me.nextPatternNode = 0;
	},
	setAz: func (newAz) {
		if (newAz != me.az and (newAz == 10 or newAz == 20 or newAz == 40 or newAz == 80 or newAz == AWG9.fieldOfRegardMaxAz)) {
			me.az = newAz;
			me.nextPatternNode = 0;
		}
	},
	setBarsIndex: func (newBars) {
		if (newBars != me.bars and newBars >= 0 and newBars <= 4) {
			me.bars = newBars;
			me.nextPatternNode = 0;
		}
	},
	showAZ: func {
		return 1;
	},
	showBars: func {
		return 1;
	},
	setRange: func (range) {
		return 0;
	},
	getRange: func {
		return RangeRadar2.getValue();
	},
	cycleDesignate: func {
		if (!size(me.radar.vector_aicontacts_bleps)) {
			me.priorityTarget = nil;
			return;
		}
		if (me.priorityTarget == nil) {
			me.testIndex = -1;
		} else {
			me.testIndex = me.radar.vectorIndex(me.radar.vector_aicontacts_bleps, me.priorityTarget);
		}
		for(me.i = me.testIndex+1;me.i<size(me.radar.vector_aicontacts_bleps);me.i+=1) {
			me.priorityTarget = me.radar.vector_aicontacts_bleps[me.i];
			return;
		}
		for(me.i = 0;me.i<=me.testIndex;me.i+=1) {
			me.priorityTarget = me.radar.vector_aicontacts_bleps[me.i];
			return;
		}
	},
	frameCompleted: func {
		if (me.lastFrameStart != -1) {
			me.lastFrameDuration = me.radar.elapsed - me.lastFrameStart;
			me.timeToFadeBleps = math.max(1.2*me.lastFrameDuration, me.minTimeToFadeBleps);
		}
		me.lastFrameStart = me.radar.elapsed;
	},
};#                                    END AWG-9 Mode base class








#  ██████  ██     ██ ███████ 
#  ██   ██ ██     ██ ██      
#  ██████  ██  █  ██ ███████ 
#  ██   ██ ██ ███ ██      ██ 
#  ██   ██  ███ ███  ███████ 
#                            
#                            
var RWSMode = {
	radar: nil,
	shortName: "RWS",
	longName: "Range While Search",
	superMode: nil,
	subMode: nil,
	discSpeed_dps: 50,
	rcsFactor: 1.0,
	priorityTarget: nil,
	pulse: DOPPLER,
	new: func (subMode, radar = nil) {
		var mode = {parents: [RWSMode, AWG9Mode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		subMode.superMode = mode;
		#subMode.shortName = mode.shortName;
		return mode;
	},
	cycleBars: func {
		me.bars += 1;
		if (me.bars == 5) me.bars = 1;
		me.nextPatternNode = 0;
	},
	designate: func (designate_contact) {
		if (designate_contact == nil) return;
		me.subMode.superIndex = me.radar.currentModeIndex;
		me.radar.setCurrentMode(me.subMode, designate_contact);
		me.subMode.radar = me.radar;# find some smarter way of setting it.
	},
	undesignate: func {},
	designatePriority: func (contact) {
		me.priorityTarget = contact;
	},
	preStep: func {
		var dev_tilt_deg = me.radar.getSideKnob();
		me.elevationTilt = me.radar.getTiltKnob();
		if (me.az == AWG9.fieldOfRegardMaxAz) {
			dev_tilt_deg = 0;
		}
		me.azimuthTilt = dev_tilt_deg;
		if (me.azimuthTilt > me.radar.fieldOfRegardMaxAz-me.az) {
			me.azimuthTilt = me.radar.fieldOfRegardMaxAz-me.az;
		} elsif (me.azimuthTilt < -me.radar.fieldOfRegardMaxAz+me.az) {
			me.azimuthTilt = -me.radar.fieldOfRegardMaxAz+me.az;
		}
		if (me.priorityTarget != nil) {
			if (!size(me.priorityTarget.getBleps())) {
				me.priorityTarget = nil;
				me.undesignate();
			}
		}
	},
	increaseRange: func {
		me._increaseRange();
	},
	decreaseRange: func {
		me._decreaseRange();
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		return [1,0,1,0,0,1];
	},
};





#  ██████  ██    ██ ██      ███████ ███████     ██████   ██████  ██████  ██████  ██      ███████ ██████      ███████ ███████  █████  ██████   ██████ ██   ██ 
#  ██   ██ ██    ██ ██      ██      ██          ██   ██ ██    ██ ██   ██ ██   ██ ██      ██      ██   ██     ██      ██      ██   ██ ██   ██ ██      ██   ██ 
#  ██████  ██    ██ ██      ███████ █████       ██   ██ ██    ██ ██████  ██████  ██      █████   ██████      ███████ █████   ███████ ██████  ██      ███████ 
#  ██      ██    ██ ██           ██ ██          ██   ██ ██    ██ ██      ██      ██      ██      ██   ██          ██ ██      ██   ██ ██   ██ ██      ██   ██ 
#  ██       ██████  ███████ ███████ ███████     ██████   ██████  ██      ██      ███████ ███████ ██   ██     ███████ ███████ ██   ██ ██   ██  ██████ ██   ██ 
#                                                                                                                                                            
#                                                                                                                                                            
var PulseDMode = {
	shortName: "PD Search",
	longName: "Pulse Doppler Search",
	discSpeed_dps: 40,
	maxScanIntervalForVelocity: 12,
	minClosure: 115, # kt
	rcsFactor: 1.1,
	pulse: DOPPLER,
	new: func (subMode, radar = nil) {
		var mode = {parents: [PulseDMode, RWSMode, AWG9Mode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		subMode.superMode = mode;
		#subMode.shortName = mode.shortName;
		return mode;
	},
	designate: func (designate_contact) {
		return;
		if (designate_contact == nil) return;
		me.subMode.superIndex = me.radar.currentModeIndex;
		me.radar.setCurrentMode(me.subMode, designate_contact);
		me.subMode.radar = me.radar;# find some smarter way of setting it.
		me.radar.registerBlep(designate_contact, designate_contact.getDeviationStored(), 0);
	},
	designatePriority: func {
		# NOP
	},
	undesignate: func {
		# NOP
	},
	preStep: func {
		me.elevationTilt = me.radar.getTiltKnob();
		var dev_tilt_deg = me.radar.getSideKnob();
		if (me.az == AWG9.fieldOfRegardMaxAz) {
			dev_tilt_deg = 0;
		}
		me.azimuthTilt = dev_tilt_deg;
		if (me.azimuthTilt > me.radar.fieldOfRegardMaxAz-me.az) {
			me.azimuthTilt = me.radar.fieldOfRegardMaxAz-me.az;
		} elsif (me.azimuthTilt < -me.radar.fieldOfRegardMaxAz+me.az) {
			me.azimuthTilt = -me.radar.fieldOfRegardMaxAz+me.az;
		}
		if (me.priorityTarget != nil) {
			if (!size(me.priorityTarget.getBleps())) {
				me.priorityTarget = nil;
				me.undesignate();
			}
		}
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		#print(me.currentTracked,"   ",(me.radar.elapsed - contact.blepTime));
		if (((me.radar.elapsed - contact.getLastBlepTime()) < me.maxScanIntervalForVelocity) and contact.getLastClosureRate() > 0) {
			#print("VELOCITY");
			return [0,0,1,1,1,0];
		}
		#print("  EMPTY");
		return [0,0,0,0,1,0];
	},
	cycleDesignate: func {
	},
};



#  ██████  ██    ██ ██      ███████ ███████     ███████ ███████  █████  ██████   ██████ ██   ██ 
#  ██   ██ ██    ██ ██      ██      ██          ██      ██      ██   ██ ██   ██ ██      ██   ██ 
#  ██████  ██    ██ ██      ███████ █████       ███████ █████   ███████ ██████  ██      ███████ 
#  ██      ██    ██ ██           ██ ██               ██ ██      ██   ██ ██   ██ ██      ██   ██ 
#  ██       ██████  ███████ ███████ ███████     ███████ ███████ ██   ██ ██   ██  ██████ ██   ██ 
#                                                                                               
#                                                                                               
var PulseMode = {
	shortName: "P Search",
	longName: "Pulse Search",
	discSpeed_dps: 45,
	rcsFactor: 1.0,
	detectMARINE: 1,
	detectSURFACE: 1,
	detectAIR: 0,
	pulse: MONO,
	new: func (subMode, radar = nil) {
		var mode = {parents: [PulseMode, RWSMode, AWG9Mode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		subMode.superMode = mode;
		#subMode.shortName = mode.shortName;
		return mode;
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		#print(me.currentTracked,"   ",(me.radar.elapsed - contact.blepTime));
		return [1,0,1,1,0,1];
	},
};




#  ████████ ██     ██ ███████ 
#     ██    ██     ██ ██      
#     ██    ██  █  ██ ███████ 
#     ██    ██ ███ ██      ██ 
#     ██     ███ ███  ███████ 
#                             
#                             
var TWSMode = {
	radar: nil,
	shortName: "TWS",
	longName: "Track While Scan",
	superMode: nil,
	subMode: nil,
	maxRange: 80,
	discSpeed_dps: 45,
	rcsFactor: 0.9,
	timeToBlinkTracks: 8,
	maxScanIntervalForTrack: 9,
	priorityTarget: nil,
	currentTracked: [],
	maxTracked: 10,
	az: 40,# slow scan, so default is 25 to get those double taps in there.
	bars: 2,# default is less due to need 2 scans of target to get groundtrack
	pulse: DOPPLER,
	new: func (subMode, radar = nil) {
		var mode = {parents: [TWSMode, AWG9Mode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		subMode.superMode = mode;
		#subMode.shortName = mode.shortName;
		return mode;
	},
	cycleAZ: func {
		if (me.az <= 20) {
			me.az = 40;
			me.bars = 2;#2 scan lines
		} else {
			me.az = 20;
			me.bars = 3;#4 scan lines
		}
		me.nextPatternNode = 0;
	},
	cycleBars: func {
		me.bars += 1;
		if (me.bars > 3) {
			me.bars = 2;
			me.az = 40;
		} else {
			me.bars = 3;
			me.az = 20;
		}
		me.nextPatternNode = 0;
	},
	setBarsIndex: func (newBars) {
		if (newBars != me.bars and (newBars == 3 or newBars == 2)) {
			me.bars = newBars;
			if (me.bars == 2) {
				me.az = 40;
			} else {
				me.az = 20;
			}
			me.nextPatternNode = 0;
		}
	},
	setAz: func (newAz) {
		if (newAz != me.az and (newAz == 20 or newAz == 40)) {
			me.az = newAz;
			if (me.az == 20) {
				me.bars = 3;
			} else {
				me.bars = 2;
			}
			me.nextPatternNode = 0;
		}
	},
	designate: func (designate_contact) {
		if (designate_contact != nil) {
			me.subMode.superIndex = me.radar.currentModeIndex;
			me.radar.setCurrentMode(me.subMode, designate_contact);
			me.subMode.radar = me.radar;# find some smarter way of setting it.
		} else {
			me.priorityTarget = nil;
		}
	},
	designatePriority: func (contact) {
		me.priorityTarget = contact;
	},
	getPriority: func {
		return me.priorityTarget;
	},
	undesignate: func {
		me.priorityTarget = nil;
	},
	preStep: func {
	 	me.azimuthTilt = me.radar.getSideKnob();
	 	me.elevationTilt = me.radar.getTiltKnob();
		if (me.priorityTarget != nil) {
			if (!size(me.priorityTarget.getBleps()) or !me.radar.containsVectorContact(me.radar.vector_aicontacts_bleps, me.priorityTarget) or me.radar.elapsed - me.priorityTarget.getLastBlepTime() > me.radar.timeToKeepBleps) {
				me.priorityTarget = nil;
				me.undesignate();
				return;
			}
			
			me.lastBlep = me.priorityTarget.getLastBlep();
			if (me.lastBlep != nil) {
				me.centerTilt = me.lastBlep.getAZDeviation();
				if (me.centerTilt > me.azimuthTilt+me.az) {
					me.azimuthTilt = me.centerTilt-me.az;
				} elsif (me.centerTilt < me.azimuthTilt-me.az) {
					me.azimuthTilt = me.centerTilt+me.az;
				}
				me.elevationTilt = me.lastBlep.getElev();
			} else {
				me.priorityTarget = nil;
				me.undesignate();
				return;
			}
			#me.prioRange_nm = me.priorityTarget.getLastRangeDirect()*M2NM;
			#if (me.prioRange_nm < 0.40 * me.getRange()) {
			#	me._decreaseRange();
			#} elsif (me.prioRange_nm > 0.90 * me.getRange()) {
			#	me._increaseRange();
			#} elsif (me.prioRange_nm < 3) {
				# auto go to STT when target is very close
			#	me.designate(me.priorityTarget);
			#}
			# Source MLU Tape 1:
			#me.bars = math.min(3, me.bars);
			#me.az = math.min(25, me.az);
		} else {
			me.undesignate();
		}
		me.constrainAz();
	},
	frameCompleted: func {
		if (me.lastFrameStart != -1) {
			me.lastFrameDuration = me.radar.elapsed - me.lastFrameStart;
		}
		me.lastFrameStart = me.radar.elapsed;
	},
	enterMode: func {
		me.currentTracked = [];
		foreach(c;me.radar.vector_aicontacts_bleps) {
			c.ignoreTrackInfo();# Kind of a hack to make it give out false info. Bypasses hadTrackInfo() but not hasTrackInfo().
		}
		set54ToPitbull();
	},
	leaveMode: func {
		me.priorityTarget = nil;
		me.lastFrameStart = -1;
		set54ToNormal();
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		#print(me.currentTracked,"   ",(me.radar.elapsed - contact.blepTime));
		me.scanInterval = (me.radar.elapsed - contact.getLastBlepTime()) < me.maxScanIntervalForTrack;
		me.isInCurrent = me.radar.containsVectorContact(me.currentTracked, contact);
		if (size(me.currentTracked) < me.maxTracked and me.scanInterval) {
			#print("  TWICE    ",(me.radar.elapsed - contact.getLastBlepTime()));
			#print(me.radar.containsVectorContact(me.radar.vector_aicontacts_bleps, contact),"   ",me.radar.elapsed - contact.blepTime);			
			if (!me.isInCurrent) append(me.currentTracked, contact);
			return [1,1,1,1,1,1];
		} elsif (me.isInCurrent and me.scanInterval) {
			return [1,1,1,1,1,1];
		} elsif (me.isInCurrent) {
			me.tmp = [];
			foreach (me.cc ; me.currentTracked) {
				if(!me.cc.equals(contact)) {
					append(me.tmp, me.cc);
				}
			}
			me.currentTracked = me.tmp;
		}
		#print("  ONCE    ",me.currentTracked);
		return [1,0,1,0,0,1];
	},
	prunedContact: func (c) {
		if (c.equals(me.priorityTarget)) {
			me.priorityTarget = nil;# this might have fixed the nil exception
		}
		if (c.hadTrackInfo()) {
			me.del = me.radar.containsVectorContact(me.currentTracked, c);
			if (me.del) {
				me.tmp = [];
				foreach (me.cc ; me.currentTracked) {
					if(!me.cc.equals(c)) {
						append(me.tmp, me.cc);
					}
				}
				me.currentTracked = me.tmp;
			}
		}
	},
	testContact: func (contact) {
		#if (me.radar.elapsed - contact.getLastBlepTime() > me.maxScanIntervalForTrack and contact.azi == 1) {
		#	contact.azi = 0;
		#	me.currentTracked -= 1;
		#}
	},
	cycleDesignate: func {
		if (!size(me.radar.vector_aicontacts_bleps)) {
			me.priorityTarget = nil;
			return;
		}
		if (me.priorityTarget == nil) {
			me.testIndex = -1;
		} else {
			me.testIndex = me.radar.vectorIndex(me.radar.vector_aicontacts_bleps, me.priorityTarget);
		}
		for(me.i = me.testIndex+1;me.i<size(me.radar.vector_aicontacts_bleps);me.i+=1) {
			#if (me.radar.vector_aicontacts_bleps[me.i].hadTrackInfo()) {
				me.priorityTarget = me.radar.vector_aicontacts_bleps[me.i];
				return;
			#}
		}
		for(me.i = 0;me.i<=me.testIndex;me.i+=1) {
			#if (me.radar.vector_aicontacts_bleps[me.i].hadTrackInfo()) {
				me.priorityTarget = me.radar.vector_aicontacts_bleps[me.i];
				return;
			#}
		}
	},
};









#  ██████   █████  ██      
#  ██   ██ ██   ██ ██      
#  ██████  ███████ ██      
#  ██      ██   ██ ██      
#  ██      ██   ██ ███████ 
#                          
#                          
var PalMode = {
	radar: nil,
	#rootName: "ACM",
	shortName: "PAL",
	longName: "Pilot Automatic Lockon",
	superMode: nil,
	subMode: nil,
	range: 10,
	minRange: 10,
	maxRange: 10,
	discSpeed_dps: 70,
	rcsFactor: 1.0,
	timeToFadeBleps: 1,# TODO
	bars: 4,
	az: 20,
	pulse: MONO,
	new: func (subMode, radar = nil) {
		var mode = {parents: [PalMode, AWG9Mode, RadarMode]};
		mode.radar = radar;
		mode.subMode = subMode;
		mode.subMode.superMode = mode;
		#mode.subMode.shortName = mode.shortName;
		return mode;
	},
	showBars: func {
		return 0;
	},
	cycleAZ: func {	},
	cycleBars: func { },
	designate: func (designate_contact) {
		if (designate_contact == nil) {
			acmLockSound.setBoolValue(0);
			return;
		}
		acmLockSound.setBoolValue(1);
		me.subMode.superIndex = me.radar.currentModeIndex;
		me.radar.setCurrentMode(me.subMode, designate_contact);
		me.subMode.radar = me.radar;
	},
	designatePriority: func (contact) {
	},
	getPriority: func {
		return nil;
	},
	undesignate: func {
	},
	preStep: func {
		me.radar.horizonStabilized = 0;
		me.elevationTilt = 0;
		me.azimuthTilt = 0;
	},
	getRange: func {
		return me.range;
	},
	increaseRange: func {
		return 0;
	},
	decreaseRange: func {
		return 0;
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		me.designate(contact);
		return [1,1,1,1,1,1];
	},
	testContact: func (contact) {
	},
	cycleDesignate: func {
	},
	getCursorAltitudeLimits: func {
		return nil;
	},
};





#  ███████ ████████ ████████ 
#  ██         ██       ██    
#  ███████    ██       ██    
#       ██    ██       ██    
#  ███████    ██       ██    
#                            
#                            
var STTMode = {
	radar: nil,
	shortName: "STT",
	longName: "Single Target Track",
	superMode: nil,
	discSpeed_dps: 70,
	rcsFactor: 1,
	maxRange: 160,
	priorityTarget: nil,
	az: AWG9.instantFoVradius*0.8,
	barHeight: 0.90,# multiple of instantFoVradius
	bars: 2,
	minimumTimePerReturn: 0.10,
	timeToFadeBleps: 13, # F14 custom # Need to have time to move disc to the selection from wherever it was before entering STT. Plus already faded bleps from superMode will get pruned if this is to low.
	debug: 1,
	painter: 1,
	debug: 0,
	new: func (radar = nil) {
		var mode = {parents: [STTMode, AWG9Mode, RadarMode]};
		mode.radar = radar;
		return mode;
	},
	showAZ: func {
		return 0;
	},
	showAZinHSD: func {
		return 0;
	},
	showBars: func {
		return me.superMode.showBars();
	},
	showRangeOptions: func {
		return 0;
	},
	getBars: func {
		return me.superMode.getBars();
	},
	getAz: func {
		# We return the parents mode AZ and bars in this class, so they are shown in radar display as B4 A4 etc etc.
		return me.superMode.getAz();
	},
	preStep: func {
		me.debug = getprop("debug-radar/debug-stt");
		if (me.priorityTarget != nil and size(me.priorityTarget.getBleps())) {
			me.lastBlep = me.priorityTarget.getLastBlep();
			if (me.debug > 0) {
				setprop("debug-radar/STT-bleps", size(me.priorityTarget.getBleps()));
			}
			if (me.lastBlep != nil) {
				me.azimuthTilt = me.lastBlep.getAZDeviation();
				me.elevationTilt = me.lastBlep.getElev(); # tilt here is in relation to horizon
			} else {
				me.lostLock();
				me.priorityTarget = nil;
				me.undesignate();
				return;
			}
			if (!size(me.priorityTarget.getBleps()) or !me.radar.containsVectorContact(me.radar.vector_aicontacts_bleps, me.priorityTarget)) {
				me.priorityTarget = nil;
				me.undesignate();
				me.lostLock();
				return;
			} elsif (me.azimuthTilt > me.radar.fieldOfRegardMaxAz-me.az) {
				me.azimuthTilt = me.radar.fieldOfRegardMaxAz-me.az;
			} elsif (me.azimuthTilt < -me.radar.fieldOfRegardMaxAz+me.az) {
				me.azimuthTilt = -me.radar.fieldOfRegardMaxAz+me.az;
			}
			if (me.priorityTarget.getRangeDirect()*M2NM < 0.40 * me.getRange()) {
				me._decreaseRange();
			}
			if (me.priorityTarget.getRangeDirect()*M2NM > 0.90 * me.getRange()) {
				me._increaseRange();
			}
			if (me.debug > 0) {
				setprop("debug-radar/STT-focused", me.priorityTarget.get_Callsign());
			}
		} else {
			if (me.debug > 0) {
				setprop("debug-radar/STT-focused", "--none--");
			}
			if (me.debug > 0) {
				setprop("debug-radar/STT-bleps", -1);
			}
			me.priorityTarget = nil;
			me.undesignate();
		}
	},
	lostLock: func {
		screen.log.write("RIO: Lost lock.", 1,0.5,0);
	},
	designatePriority: func (prio) {
		me.priorityTarget = prio;
	},
	undesignate: func {
		me.radar.setCurrentMode(me.superMode, me.priorityTarget);
		me.priorityTarget = nil;
		#var log = caller(1); foreach (l;log) print(l);
	},
	designate: func {},
	cycleBars: func {},
	cycleAZ: func {},
	increaseRange: func {# Range is auto-set in STT
		return 0;
	},
	decreaseRange: func {# Range is auto-set in STT
		return 0;
	},
	setRange: func {# Range is auto-set in STT
	},
	leaveMode: func {
		me.priorityTarget = nil;
		me.lastFrameStart = -1;
		me.timeToFadeBleps = 13;# F14 custom # Reset to 5, since frameCompleted might have lowered it.
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		if (me.priorityTarget != nil and contact.equals(me.priorityTarget)) {
			me.timeToFadeBleps = 1.5;
			return [1,1,1,1,1,1];
		}
		return nil;
	},
	getCursorAltitudeLimits: func {
		return nil;
	},
	frameCompleted: func {
		if (me.lastFrameStart != -1) {
			me.lastFrameDuration = me.radar.elapsed - me.lastFrameStart;
		}
		me.lastFrameStart = me.radar.elapsed;
	},
};

var PDSTTMode = {
	rootName: "AIR",
	shortName: "PD STT",
	longName: "Pulse Doppler - Single Target Track",
	pulse: DOPPLER,
	new: func (radar = nil) {
		var mode = {parents: [PDSTTMode, STTMode, AWG9Mode, RadarMode]};
		mode.radar = radar;
		return mode;
	},
	undesignate: func {
		if (me["superIndex"] != nil) me.radar.currentModeIndex = me.superIndex;
		me.radar.setCurrentMode(me.superMode, me.priorityTarget);
		me.priorityTarget = nil;
		#var log = caller(1); foreach (l;log) print(l);
	},
};

var PSTTMode = {
	rootName: "AIR",
	shortName: "Pulse STT",
	longName: "Pulse - Single Target Track",
	pulse: MONO, # MONO or DOPPLER
	new: func (radar = nil) {
		var mode = {parents: [PSTTMode, STTMode, AWG9Mode, RadarMode]};
		mode.radar = radar;
		return mode;
	},
	undesignate: func {
		if (me["superIndex"] != nil) me.radar.currentModeIndex = me.superIndex;
		me.radar.setCurrentMode(me.superMode, me.priorityTarget);
		me.priorityTarget = nil;
		#var log = caller(1); foreach (l;log) print(l);
	},
	getSearchInfo: func (contact) {
		# searchInfo:               dist, groundtrack, deviations, speed, closing-rate, altitude
		if (me.priorityTarget != nil and contact.equals(me.priorityTarget)) {
			me.timeToFadeBleps = 1.5;
			return [1,1,1,1,0,1];
		}
		return nil;
	},
};













#   █████  ███    ██     ██  █████  ██      ██████        ███████  ██████  
#  ██   ██ ████   ██    ██  ██   ██ ██      ██   ██       ██      ██  ████ 
#  ███████ ██ ██  ██   ██   ███████ ██      ██████  █████ ███████ ██ ██ ██ 
#  ██   ██ ██  ██ ██  ██    ██   ██ ██      ██   ██            ██ ████  ██ 
#  ██   ██ ██   ████ ██     ██   ██ ███████ ██   ██       ███████  ██████  
#                                                                          
#                                                                          
var RWR = {
	# inherits from Radar
	# will check radar/transponder and ground occlusion.
	# will sort according to threat level
	new: func () {
		var rr = {parents: [RWR, Radar]};

		rr.vector_aicontacts = [];
		rr.vector_aicontacts_threats = [];
		#rr.timer          = maketimer(2, rr, func rr.scan());

		rr.RWRRecipient = emesary.Recipient.new("RWRRecipient");
		rr.RWRRecipient.radar = rr;
		rr.RWRRecipient.Receive = func(notification) {
	        if (notification.NotificationType == "OmniNotification") {
	        	#printf("RWR recv: %s", notification.NotificationType);
	            if (me.radar.enabled == 1) {
	    		    me.radar.vector_aicontacts = notification.vector;
	    		    me.radar.scan();
	    	    }
	            return emesary.Transmitter.ReceiptStatus_OK;
	        }
	        return emesary.Transmitter.ReceiptStatus_NotProcessed;
	    };
		emesary.GlobalTransmitter.Register(rr.RWRRecipient);
		#nr.FORNotification = VectorNotification.new("FORNotification");
		#nr.FORNotification.updateV(nr.vector_aicontacts_for);
		#rr.timer.start();
		return rr;
	},
	heatDefense: 0,
	scan: func {
		# sort in threat?
		# run by notification
		# mock up code, ultra simple threat index, is just here cause rwr have special needs:
		# 1) It has almost no range restriction
		# 2) Its omnidirectional
		# 3) It might have to update fast (like 0.25 secs)
		# 4) To build a proper threat index it needs at least these properties read:
		#       model type
		#       class (AIR/SURFACE/MARINE)
		#       lock on myself
		#       missile launch
		#       transponder on/off
		#       bearing and heading
		#       IFF info
		#       ECM
		#       radar on/off
		if (!EcmOn.getBoolValue()) {
            setprop("sound/rwr-lck", 0);
            setprop("ai/submodels/submodel[0]/flare-auto-release-cmd", 0);
            return;
        }
        me.vector_aicontacts_threats = [];
		me.fct = 10*2.0;
        me.myCallsign = self.getCallsign();
        me.myCallsign = size(me.myCallsign) < 8 ? me.myCallsign : left(me.myCallsign,7);
        me.act_lck = 0;
        me.autoFlare = 0;
        me.closestThreat = 0;
        me.elapsed = elapsedProp.getValue();
        foreach(me.u ; me.vector_aicontacts) {
        	# [me.ber,me.head,contact.getCoord(),me.tp,me.radar,contact.getDeviationHeading(),contact.getRangeDirect()*M2NM, contact.getCallsign()]
        	me.threatDB = me.u.getThreatStored();
            me.cs = me.threatDB[7];
            me.rn = me.threatDB[6];
            if ((me.u["blue"] != nil and me.u.blue == 1 and !me.threatDB[10]) or me.rn > 150) {
                continue;
            }
            me.bearing = me.threatDB[0];
            me.trAct = me.threatDB[3];
            me.show = 1;
            me.heading = me.threatDB[1];
            me.inv_bearing =  me.bearing+180;#bearing from target to me
            me.deviation = me.inv_bearing - me.heading;# bearing deviation from target to me
            me.dev = math.abs(geo.normdeg180(me.deviation));# my degrees from opponents nose
            
            if (me.show == 1) {
                if (me.dev < 30 and me.rn < 7 and me.threatDB[8] > 60) {
                    # he is in position to fire heatseeker at me
                    me.heatDefenseNow = me.elapsed + me.rn*1.5;
                    if (me.heatDefenseNow > me.heatDefense) {
                        me.heatDefense = me.heatDefenseNow;
                    }
                }
                me.threat = 0;
                if (me.u.getModel() != "missile_frigate" and me.u.getModel() != "S-75" and me.u.getModel() != "buk-m2" and me.u.getModel() != "MIM104D" and me.u.getModel() != "s-300" and me.u.getModel() != "fleet" and me.u.getModel() != "ZSU-23-4M") {
                    me.threat += ((180-me.dev)/180)*0.30;# most threat if I am in front of his nose
                    me.spd = (60-me.threatDB[8])/60;
                    #me.threat -= me.spd>0?me.spd:0;# if his speed is lower than 60kt then give him minus threat else positive
                } elsif (me.u.getModel == "missile_frigate" or me.u.getModel() == "fleet") {
                    me.threat += 0.30;
                } else {
                    me.threat += 0.30;
                }
                me.danger = 50;# within this range he is most dangerous
                if (me.u.getModel() == "missile_frigate" or me.u.getModel() == "fleet" or me.u.getModel() == "s-300") {
                    me.danger = 80;
                } elsif (me.u.getModel() == "buk-m2" or me.u.getModel() == "S-75") {
                    me.danger = 35;
                } elsif (me.u.getModel() == "MIM104D") {
                    me.danger = 45;
                } elsif (me.u.getModel() == "ZSU-23-4M") {
                    me.danger = 7.5;
                }
                if (me.threatDB[10]) me.threat += 0.30;# has me locked
                me.threat += ((me.danger-me.rn)/me.danger)>0?((me.danger-me.rn)/me.danger)*0.60:0;# if inside danger zone then add threat, the closer the more.
                me.threat += me.threatDB[9]>0?(me.threatDB[9]/500)*0.10:0;# more closing speed means more threat.
                if (me.threat > me.closestThreat) me.closestThreat = me.threat;
                #printf("A %s threat:%.2f range:%d dev:%d", me.u.get_Callsign(),me.threat,me.u.get_range(),me.deviation);
                if (me.threat > 1) me.threat = 1;
                me.u.threat = me.threat;
                if (me.threat <= 0) continue;
                #printf("B %s threat:%.2f range:%d dev:%d", me.u.get_Callsign(),me.threat,me.u.get_range(),me.deviation);
                append(me.vector_aicontacts_threats, me.u);# [me.u,me.threat, me.threatDB[5]]
            } else {
#                printf("%s ----", me.u.get_Callsign());
            }
        }
        if (!we_are_bs) {
	        me.launchClose = getprop("payload/armament/MLW-launcher") != "";
	        me.incoming = getprop("payload/armament/MAW-active") or me.heatDefense > me.elapsed;
	        me.spike = getprop("payload/armament/spike")*(getprop("ai/submodels/submodel[0]/count")>15);
	        me.autoFlare = me.spike?math.max(me.closestThreat*0.25,0.05):0;

	        if (0 and getprop("f16/avionics/ew-mode-knob") == 2)
	        	print("wow: ", getprop("/fdm/jsbsim/gear/unit[0]/WOW"),"  spiked: ",me.spike,"  incoming: ",me.incoming, "  launch: ",me.launchClose,"  spikeResult:", me.autoFlare,"  aggresive:",me.launchClose * 0.85 + me.incoming * 0.85,"  total:",me.launchClose * 0.85 + me.incoming * 0.85+me.autoFlare);

	        me.autoFlare += me.launchClose * 0.85 + me.incoming * 0.85;

	        me.autoFlare *= 0.1 * 2.5 * !getprop("/fdm/jsbsim/gear/unit[0]/WOW");#0.1 being the update rate for flare dropping code.

	        setprop("ai/submodels/submodel[0]/flare-auto-release-cmd", me.autoFlare * (getprop("ai/submodels/submodel[0]/count")>0));
	        if (me.autoFlare > 0.80 and rand()>0.99 and getprop("ai/submodels/submodel[0]/count") < 1) {
	            setprop("ai/submodels/submodel[0]/flare-release-out-snd", 1);
	        }
	    }
	},
	del: func {
        emesary.GlobalTransmitter.DeRegister(me.RWRRecipient);
    },
};






































var scanInterval = 0.05;# 20hz for main radar
var ddd_screen_width = 0.0844;#use the maximum here
laserOn = props.globals.getNode("controls/armament/laser-arm-dmd",1);#don't put 'var' keyword in front of this.
var datalink_power = props.globals.getNode("fdm/jsbsim/systems/electrics/ac-essential-bus1-powered",0);
enable_tacobject = 0;
var wndprop = props.globals.getNode("environment/wind-speed-kt",0);



var acmLockSound = props.globals.getNode("sound/acm-lock",1);

var getCompleteList = func {
	return baser.vector_aicontacts_last;
}


var this_model = "f-14b";
var we_are_bs = 0;# RIO
var pilot_lock        = 0;
var cockpitNotifier = nil;

# RWR
var EcmOn                = props.globals.getNode("instrumentation/ecm/on-off", 1);
# HUD
var HudTgtHDisplay       = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/hud/target-display", 1);
var HudTgt               = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/hud/target", 1);
var HudTgtTDev           = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/hud/target-total-deviation", 1);
var HudTgtTDeg           = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/hud/target-total-angle", 1);
var HudTgtClosureRate    = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/hud/closure-rate", 1);
var HudTgtDistance       = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/hud/distance", 1);
var SWTgtRange           = props.globals.getNode("sim/model/"~this_model~"/systems/armament/aim9/target-range-nm",1);
# Field
var antennae_knob_prop   = props.globals.getNode("controls/radar/elevation-deg",1);# tilt scan field up or down # joystick binding
var antennae_az_knob_prop= props.globals.getNode("controls/radar/azimuth-deg",1);# -60 to 60, tilt scan field left or right (when not 120). # joystick binding
var antennae_deg_prop    = props.globals.getNode("instrumentation/radar/antennae-deg",1);#actual current radar tilt 
var bars_index           = props.globals.getNode("instrumentation/radar/rio-dualcontrol-bars-index",1);#actual current radar bars index
var az_field             = props.globals.getNode("instrumentation/radar/rio-dualcontrol-azimuth-field",1);#actual current radar az field. On purpose not the same as the old property used in xml model.
var az_field_on_off      = props.globals.getNode("instrumentation/radar/az-field",1);
var az_field_left        = props.globals.getNode("instrumentation/radar/az-field-left",1);
var az_field_right       = props.globals.getNode("instrumentation/radar/az-field-right",1);
# Radar
var cycle_range          = getprop("instrumentation/radar/cycle-range");# if range should be cycled or only go up/down.
var RangeRadar2          = props.globals.getNode("instrumentation/radar/radar2-range",1);
var RangeActualRadar2    = props.globals.getNode("instrumentation/radar/radar2-range-actual",1);
var RadarServicable      = props.globals.getNode("instrumentation/radar/serviceable",1);
var RadarStandby         = props.globals.getNode("instrumentation/radar/radar-standby",1);
var Hook                 = props.globals.getNode("instrumentation/radar/selection",1);
var DisplayRdr           = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/display-rdr",1);
var AntTrk               = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/ant-trk-light",1);
var SwpFac               = props.globals.getNode("sim/model/"~this_model~"/instrumentation/awg-9/sweep-factor", 1);
var SelectTargetCommand  = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/select-target",1);
var SelectTargetCommandJoy= props.globals.getNode("controls/armament/target-selected",1);# joystick binding
var BarsCommand          = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/cycleBars",1);
var AzCommand            = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/cycleAz",1);
var WcsMode              = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/wcs-mode",1);
Hook.setValue("");
RangeActualRadar2.setIntValue(50);
antennae_deg_prop.setDoubleValue(0);
antennae_knob_prop.setDoubleValue(0);
antennae_az_knob_prop.setDoubleValue(0);
SelectTargetCommand.setIntValue(0);
SelectTargetCommandJoy.setIntValue(0);
BarsCommand.setBoolValue(0);
AzCommand.setBoolValue(0);
AntTrk.setBoolValue(0);

var bars2bars    = [1,2,4,8];
var wcs2mode     = [nil,5,4,3,0,1,-1,2,6];
var mode2wcs     = [4,5,7,3,2,1,8];
var radar_ranges = [5,10,20,50,100,200];

# Controls
# ---------------------------------------------------------------------
var toggle_radar_standby = func() {
	if ( pilot_lock and ! we_are_bs ) { return }
	RadarStandby.setBoolValue(!RadarStandby.getBoolValue());
}
var wcs_mode_sel = func (wcsMode) {
	if ( pilot_lock and ! we_are_bs ) { return }
	# WCS property values:
	# 1 STT P
	# 2 STT PD
	# 3 P search
	# 4 PD Search
	# 5 RWS
	# 6 TWS AUTO
	# 7 TWS MAN
	# 8 PAL
	
	# Mode nasal values:
	# 0 pulseDSMode
	# 1 rwsMode
	# 2 twsMode
	# 3 pulseMode
	# 4 PD STT     (these 2 stt modes is only used when commanding directly into them, else submodes is used, when just pressing key "r".)
	# 5 P STT
	# 6 PAL

	var result = awg9Radar.setAirMode(wcs2mode[wcsMode]);

	if (result == 0) return;
	#print("wcs2mode[",wcsMode,"] = ", wcs2mode[wcsMode]);
	WcsMode.setValue(wcsMode);
}
var wcs_mode_toggle = func {
	if ( pilot_lock and ! we_are_bs ) { return }
	awg9Radar.toggleAirMode();
	screen.log.write("RIO: Switched to "~awg9Radar.currentMode.shortName~" mode.", 1,1,0);
}
var barsIndexChange = func (b) {
	if (!pilot_lock) return;
	var oldBarsIndex = awg9Radar.getBars();
	if (oldBarsIndex != b and !awg9Radar.currentMode.painter) {
		#print("Bars ",oldBarsIndex," new: ",b);
		awg9Radar.currentMode.setBarsIndex(b);
		#awg9Radar.rioRadar();
	}
}

var azFieldChange = func (b) {
	if (!pilot_lock) return;
	var oldAz = awg9Radar.getAzimuthRadius();
	if (oldAz != b and !awg9Radar.currentMode.painter) {
		#print("Az ",oldAz," new: ",b);
		awg9Radar.currentMode.setAz(b);
		#awg9Radar.rioRadar();
	}
}

var lock = func {
	if ( pilot_lock and ! we_are_bs ) { return }
	print("RIO request STT mode");
	var tgt = awg9Radar.getPriorityTarget();
	if (tgt == nil) {
		print("  but there is nothing selected.");
		return;
	}
	awg9Radar.designate(tgt);
	screen.log.write("RIO: Switched to "~awg9Radar.currentMode.shortName~" mode.", 1,1,0);
}
var des = func {
	if ( pilot_lock and ! we_are_bs ) { return }# for simplicity we let RIO control this.
	# The button/knob is called DES, the mode "Pilot automatic lockon".
	print("Pilot request PAL mode");
	awg9Radar.setAirMode(6);
}
var range_control = func(n) {
	if ( pilot_lock and ! we_are_bs ) { return }
	var range_radar = RangeRadar2.getValue();
    newri = 0;
    forindex(ri; radar_ranges){
        if (radar_ranges[ri] == range_radar) {
            newri = ri + n;
            break;
		}
    }
    if (newri < 0) {
    	if (!cycle_range) {return;}
    	newri = size(radar_ranges) - 1;
    } elsif (newri >= size(radar_ranges)) {
    	if (!cycle_range) {return;}
    	newri = 0;
	}

    RangeRadar2.setValue(radar_ranges[newri]);

    if (cockpitNotifier != nil)
      	cockpitNotifier.notify_value(cockpitNotifier.set_radar_range, range_radar);
}
init = func() {
	var our_ac_name = getprop("sim/aircraft");
    # map variants to the base
    if(our_ac_name == "f-14a") our_ac_name = "f-14b";
	if (our_ac_name == "f-14b-bs") {
		we_are_bs = 1;
		# Backseater need these for displays to run
		RadarServicable.setBoolValue(1);
	}
}
init();

# When dualcontrol backseater controls radar:
if (!we_are_bs) {
	setlistener(antennae_knob_prop,func (prop) {if (!pilot_lock) return; screen.log.write("RIO: Tilted radar to "~sprintf("%.1f",prop.getValue()), 1,1,0);},0,0);
	setlistener(RangeRadar2,func (prop) {if (!pilot_lock) return; screen.log.write("RIO: Changed radar range to "~prop.getValue(), 1,1,0);},0,0);
	setlistener(RadarStandby,func (prop) {if (!pilot_lock) return; screen.log.write("RIO: Switched radar standby state.", 1,1,0);},0,0);
	setlistener(WcsMode,func (prop) {if (!pilot_lock) return; awg9Radar.setAirMode(wcs2mode[prop.getIntValue()]); screen.log.write("RIO: Radar is now in "~awg9Radar.currentMode.shortName~" mode.", 1,1,0);},0,0);
};

# Set AIM-54 to go active directly off the rails
var set54ToPitbull = func {
	if (we_are_bs) return;
	var all = pylons.fcs.getAllOfType("AIM-54");
	foreach (ph ; all) {
		ph.guidance = "radar";
		ph.max_fire_range_nm = 11;
	}
}
var set54ToNormal = func {
	if (we_are_bs) return;
	var all = pylons.fcs.getAllOfType("AIM-54");
	foreach (ph ; all) {
		ph.guidance = "semi-radar";
		ph.max_fire_range_nm = 80;
	}
}

# XML Display properties control
var TgtProp = {
    "bearing-deg": nil,
    "true-heading-deg": nil,
    "range-score": nil,
    "ddd-relative-bearing": nil,
    "carrier": nil,
    "ecm-signal": nil,# if shown on rwr
    "ecm-signal-norm": nil,#not used
    "ecm_type_num": nil,#not used
    "display": nil,
    "visible": nil,
    "behind-terrain": nil,#probably not used
    "rwr-visible": nil,#not used
    "ddd-echo-fading": nil,
    "ddd-draw-range-nm": nil,
    "tid-draw-range-nm": nil,
    "rounded-alt-ft": nil,
    "closure-last-time": nil,#probably not used
    "closure-last-range-nm": nil,#probably not used
    "closure-rate-kts": nil,
};

var ddd_m_per_deg = 0.5 * ddd_screen_width / AWG9.fieldOfRegardMaxAz;
var number_of_xml_mp_symbols = 18;#zero-based. So plus one. There is AI and carrier symbols also in xml, those we keep turned off, don't really need more than 19 anyway.

var xmlDisplays = {
	#
	#  This is perhaps the heaviest part of the radar, so lets not run this more often that we need to.
	#  
	#  TODO: Partition the code, avoid running all 18 at once.
	#
	tgts: [],
	updateTgts: func {
		if (!size(me.tgts)) return;
		me.actives = awg9Radar.getActiveBleps();
		me.i = 0;
		me.shown = [];
		foreach (me.active_u ; me.actives) {
			# Here we send the contacts to xml that has been seen by our radar.
			me.blep = me.active_u.getLastBlep();
			if (me.blep == nil) {
				continue;
			}
			me.sinceBlep = awg9Radar.elapsed - me.blep.getBlepTime();
			if (me.sinceBlep > awg9Radar.currentMode.timeToFadeBleps) {
				continue;
			}
			if (math.abs(me.blep.getAZDeviation())>AWG9.fieldOfRegardMaxAz) {
				continue;
			}
			me.threat = me.active_u["threat"] != nil and me.active_u["threat"] > 0 and me.active_u["blue"] != 1;
			me.tgts[me.i]["bearing-deg"].setDoubleValue(me.blep.getBearing());
			me.tgts[me.i]["true-heading-deg"].setDoubleValue(me.blep.getHeading()==nil?-2:me.blep.getHeading());
			me.tgts[me.i]["ddd-relative-bearing"].setDoubleValue(ddd_m_per_deg * me.blep.getAZDeviation());
			me.tgts[me.i]["carrier"].setBoolValue(me.active_u.isCarrier());
			me.tgts[me.i]["display"].setBoolValue(1);
			me.tgts[me.i]["visible"].setBoolValue(1);
			me.tgts[me.i]["behind-terrain"].setBoolValue(0);
			me.tgts[me.i]["rwr-visible"].setBoolValue(me.threat);
			#if (me.threat) {
				me.tgts[me.i]["ecm-signal"].setDoubleValue(me.threat);#?(active_u.threat>0.7?0.95:0.87):0);
			#	me.tgts[me.i]["ecm-signal-norm"].setDoubleValue(active_u.threat);
			#	me.tgts[me.i]["ecm_type_num"].setValue("29");
			#}
			me.tgts[me.i]["ddd-echo-fading"].setDoubleValue(me.sinceBlep/awg9Radar.currentMode.timeToFadeBleps);#TODO: The alpha only seems to work when 1.
			me.tgts[me.i]["ddd-draw-range-nm"].setDoubleValue((0.0657/awg9Radar.getRange())*me.blep.getRangeNow()*M2NM);
			me.tgts[me.i]["tid-draw-range-nm"].setDoubleValue((0.15/awg9Radar.getRange())*me.blep.getRangeNow()*M2NM);
			me.tgts[me.i]["rounded-alt-ft"].setIntValue(me.blep.getAltitude()==nil?-1001:math.round((me.blep.getAltitude()+1)*0.001));# the plus one is due to fluctations of AI aircraft

			#me.tgts[me.i]["closure-last-time"].setDoubleValue(blep.getBlepTime());#TODO
			#me.tgts[me.i]["closure-last-range-nm"].setDoubleValue(blep.getRangeNow()*M2NM);#TODO
			me.tgts[me.i]["closure-rate-kts"].setDoubleValue(me.blep.getClosureRate());
			append(me.shown, me.active_u);
			me.i += 1;
			if (me.i > number_of_xml_mp_symbols) break;
		}
		foreach (me.active_dl ; dlnkRadar.vector_aicontacts_for) {
			# Here we send the contacts to xml that has not been seen by our radar but is on datalink.
			if (me.i > number_of_xml_mp_symbols) break;
			if (me.active_dl["blue"] != 1) {
				continue;
			}
			me.discard = awg9Radar.containsVector(me.shown, me.active_dl);
			if (me.discard) {
				continue;
			}
			if (math.abs(geo.normdeg180(me.active_dl.getBearing()-self.getHeading()))>AWG9.fieldOfRegardMaxAz or me.active_dl.getRange()*M2NM > awg9Radar.getRange()) {
				# To avoid datalink contacts from being painted outside the display
				continue;
			}
			me.tgts[me.i]["bearing-deg"].setDoubleValue(me.active_dl.getBearing());
			me.tgts[me.i]["true-heading-deg"].setDoubleValue(me.active_dl.getHeading());
			me.tgts[me.i]["ddd-relative-bearing"].setDoubleValue(0);
			me.tgts[me.i]["carrier"].setBoolValue(me.active_dl.isCarrier());
			me.tgts[me.i]["display"].setBoolValue(1);
			me.tgts[me.i]["visible"].setBoolValue(1);
			me.tgts[me.i]["behind-terrain"].setBoolValue(0);
			me.tgts[me.i]["rwr-visible"].setBoolValue(0);
			me.tgts[me.i]["ecm-signal"].setDoubleValue(0);
			me.tgts[me.i]["ddd-echo-fading"].setDoubleValue(0);# Don't show dlnk on ddd
			me.tgts[me.i]["ddd-draw-range-nm"].setDoubleValue(0);
			me.tgts[me.i]["tid-draw-range-nm"].setDoubleValue((0.15/awg9Radar.getRange())*me.active_dl.getRange()*M2NM);
			me.tgts[me.i]["rounded-alt-ft"].setIntValue(math.round(me.active_dl.getAltitude()*0.001));
			#me.tgts[me.i]["closure-last-time"].setDoubleValue(awg9Radar.elapsed);#TODO
			#me.tgts[me.i]["closure-last-range-nm"].setDoubleValue(active_dl.getRange()*M2NM);#TODO
			me.tgts[me.i]["closure-rate-kts"].setDoubleValue(0);
			append(me.shown, me.active_dl);
			me.i += 1;
		}
		foreach (me.active_t ; f14_rwr.vector_aicontacts_threats) {
			# Here we send the contacts to xml that has not been seen by our radar but should show up on rwr.
			if (me.i > number_of_xml_mp_symbols) break;
			me.discard = awg9Radar.containsVector(me.shown, me.active_t);
			if (me.discard) {
				continue;
			}
			me.tgts[me.i]["bearing-deg"].setDoubleValue(me.active_t.getBearing());
			me.tgts[me.i]["true-heading-deg"].setDoubleValue(me.active_t.getHeading());
			#me.tgts[me.i]["ddd-relative-bearing"].setDoubleValue(ddd_m_per_deg * geo.normdeg180(active_u.getHeading() - self.getHeading()) );
			#me.tgts[me.i]["carrier"].setBoolValue(active_u.isCarrier());
			me.tgts[me.i]["ecm-signal"].setDoubleValue(1);#active_t.threat>0.7?0.95:0.87);
			me.tgts[me.i]["display"].setBoolValue(0);
			me.tgts[me.i]["visible"].setBoolValue(1);
			me.tgts[me.i]["behind-terrain"].setBoolValue(0);
			me.tgts[me.i]["rwr-visible"].setBoolValue(1);
			#me.tgts[me.i]["ddd-echo-fading"].setDoubleValue(sinceBlep/awg9Radar.currentMode.timeToFadeBleps < 0.5);#TODO: The alpha only seems to work when 1.
			#me.tgts[me.i]["ddd-draw-range-nm"].setDoubleValue((0.0657/awg9Radar.getRange())*blep.getRangeNow()*M2NM);
			#me.tgts[me.i]["tid-draw-range-nm"].setDoubleValue((0.15/awg9Radar.getRange())*blep.getRangeNow()*M2NM);
			#me.tgts[me.i]["rounded-alt-ft"].setIntValue(blep.getAltitude()==nil?0:math.round(blep.getAltitude()*0.001));
			#me.tgts[me.i]["closure-last-time"].setDoubleValue(blep.getBlepTime());#TODO
			#me.tgts[me.i]["closure-last-range-nm"].setDoubleValue(blep.getRangeNow()*M2NM);#TODO
			#me.tgts[me.i]["closure-rate-kts"].setDoubleValue(blep.getClosureRate());
			me.i += 1;
		}
		for (;me.i<=number_of_xml_mp_symbols;me.i+=1) {
			# The remaining contacts up to 18 we don't show
			me.tgts[me.i]["display"].setBoolValue(0);
			me.tgts[me.i]["visible"].setBoolValue(0);
			me.tgts[me.i]["rwr-visible"].setBoolValue(0);
			me.tgts[me.i]["ecm-signal"].setBoolValue(0);
		}
	},
	initDualTgts: func (pilot) {
		# Local back-seater has a different radar-awg-9 folder and shall not see its pilot's aircraft.
		if  ( pilot != nil ) {
			# Use a different radar-awg-9 folder.
			me.InstrTgts = pilot.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/targets", 1);
			# Do not see our pilot's aircraft.
			#var target_callsign = self.getCallsign();
			#var p_callsign = BS_instruments.Pilot.getNode("callsign").getValue();
			#if ( target_callsign == p_callsign ) {
			#	obj.not_acting = 1;
			#}
		}
		me.tgts = [];
		for (me.i = 0; me.i <= number_of_xml_mp_symbols; me.i += 1) {
		    me.TgtsFiles = me.InstrTgts.getNode("multiplayer["~me.i~"]", 1);
		    me.myTgt = {parents:[TgtProp]};
		    foreach(me.key ; keys(TgtProp)) {
		    	me.myTgt[me.key] = me.TgtsFiles.getNode(me.key, 1);
		    }
		    me.myTgt.visible.setBoolValue(0);
		    me.myTgt.display.setBoolValue(0);
		    append(me.tgts, me.myTgt);
		}
	},
	initPilotTgts: func {
		me.InstrTgts = props.globals.getNode("sim/model/"~this_model~"/instrumentation/radar-awg-9/targets", 1);
		
		me.tgts = [];
		for (me.i = 0; me.i <= number_of_xml_mp_symbols; me.i += 1) {
		    me.TgtsFiles = me.InstrTgts.getNode("multiplayer["~me.i~"]", 1);
		    me.myTgt = {parents:[TgtProp]};
		    foreach(me.key ; keys(TgtProp)) {
		    	me.myTgt[me.key] = me.TgtsFiles.getNode(me.key, 1);
		    }
		    me.myTgt.visible.setBoolValue(0);
		    me.myTgt.display.setBoolValue(0);
		    append(me.tgts, me.myTgt);
		}
	},
};

var eye_hud_m          = 0.6;#pilot: -3.30  hud: -3.9
var hud_radius_m       = 0.100;

var hud = {
	hud_nearest_tgt: func() {
		# Computes nearest_u position in the HUD
		me.active_u = awg9Radar.getPriorityTarget();
		if ( me.active_u != nil and (awg9Radar.currentMode.painter or awg9Radar.currentMode.shortName == "TWS") and me.active_u.getLastBlep() != nil) {
			me.lstR = me.active_u.getLastRangeDirect();
			if (me.lstR!=nil) SWTgtRange.setValue(me.lstR*M2NM);
			else SWTgtRange.setValue(0);

			#if(awg9_trace)
			#	print("active_u ",wcs_mode, active_u.get_range()," Display", active_u.get_display(), "dev ",active_u.deviation," ",l_az_fld," ",r_az_fld);
			me.devs = me.develev_to_devroll(me.active_u.getLastBlep().getPilotDeviations());
			me.combined_dev_deg = me.devs[0];
			me.combined_dev_length =  me.devs[1];
			me.clamped = me.devs[2];
			if ( me.clamped ) {
				me.Diamond_Blinker.blink();
			} else {
				me.Diamond_Blinker.cont();
			}

			# Clamp closure rate from -200 to +1,000 Kts.
			me.cr = me.active_u.getLastClosureRate();
	        
			if (me.cr != nil)
	        {
	            if (me.cr < -200) 
	                me.cr = 200;
	            else if (me.cr > 1000) 
	                me.cr = 1000;
				HudTgtClosureRate.setValue(me.cr);
	        }

			HudTgtTDeg.setValue(me.combined_dev_deg);
			HudTgtTDev.setValue(me.combined_dev_length);
			
			me.range = me.active_u.getLastRangeDirect();
			if (me.range == nil) {
				HudTgtHDisplay.setBoolValue(0);
				return;
			}
	        HudTgtDistance.setValue(me.range*M2NM);
	        HudTgtHDisplay.setBoolValue(1);

	        me.callsign = me.active_u.getCallsign();
	        me.model = me.active_u.getModel();

	        me.target_id = "";
	        if(me.callsign != nil)
	            me.target_id = me.callsign;
	        else
	            me.target_id = me.active_u.prop.getName() ~ "[" ~ me.active_u.prop.getIndex() ~ "]";
	        if (me.model != nil and me.model != "")
	            me.target_id = me.target_id ~ " " ~ me.model;

	        HudTgt.setValue(me.target_id);
			return;
		}
		SWTgtRange.setValue(0);
		HudTgtClosureRate.setValue(0);
		HudTgtTDeg.setValue(0);
		HudTgtTDev.setValue(0);
		HudTgtHDisplay.setBoolValue(0);
	},
	
	develev_to_devroll: func(dev_) {
		dev_[0] = 90-dev_[0];
		dev_[1] = 90-dev_[1];
		dev_[0] *= D2R;
		dev_[1] *= D2R;
		if (math.sin(dev_[0]) == 0 or math.sin(dev_[1]) == 0) return [0,0,0];
		if (math.cos(dev_[0]) == 0 or math.cos(dev_[1]) == 0) return [0,20,1];
		me.clamped = 0;
		# Deviation length on the HUD (at level flight),
		# 0.6686m = distance eye <-> virtual HUD screen.
		me.h_dev = eye_hud_m / ( math.sin(dev_[0]) / math.cos(dev_[0]) );
		me.v_dev = eye_hud_m / ( math.sin(dev_[1]) / math.cos(dev_[1]) );
		# Angle between HUD center/top <-> HUD center/symbol position.
		# -90° left, 0° up, 90° right, +/- 180° down. 
		me.dev_deg =  math.atan2( me.h_dev, me.v_dev ) * R2D;
		# Correction with own a/c roll.
		me.combined_dev_deg = me.dev_deg;
		# Lenght HUD center <-> symbol pos on the HUD:
		me.combined_dev_length = math.sqrt((me.h_dev*me.h_dev)+(me.v_dev*me.v_dev));
		# clamp and squeeze the top of the display area so the symbol follow the egg shaped HUD limits.
		me.abs_combined_dev_deg = math.abs( me.combined_dev_deg );
		me.clamp = hud_radius_m;
		if ( me.abs_combined_dev_deg >= 0 and me.abs_combined_dev_deg < 90 ) {
			me.coef = ( 90 - me.abs_combined_dev_deg ) * 0.00075;
			if ( me.coef > 0.050 ) { me.coef = 0.050 }
			me.clamp -= me.coef; 
		}
		if ( me.combined_dev_length > me.clamp ) {
			me.combined_dev_length = me.clamp;
			me.clamped = 1;
		}
		me.v = [me.combined_dev_deg, me.combined_dev_length, me.clamped];
		return me.v;
	},
	# HUD clamped target blinker
	Diamond_Blinker: aircraft.light.new("sim/model/"~this_model~"/lighting/hud-diamond-switch", [0.1, 0.1]),
};

setprop("sim/model/"~this_model~"/lighting/hud-diamond-switch/enabled", 1);







# start generic radar system
var baser       = AIToNasal.new();
var partitioner = NoseRadar.new();
var omni        = OmniRadar.new(1.0, 150, 55);
var terrain     = TerrainChecker.new(0.05, 1, 45);# 0.05 or 0.10 is fine here
var dlnkRadar   = DatalinkRadar.new(0.03, 110);# 3 seconds because cannot be too slow for DLINK targets
var ecm         = ECMChecker.new(0.05, 6);

# start specific radar system
var rwsMode     = RWSMode.new(PDSTTMode.new());
var twsMode     = TWSMode.new(PDSTTMode.new());
var pulseDSMode = PulseDMode.new(PDSTTMode.new());
var pulseMode   = PulseMode.new(PSTTMode.new());
var palMode     = PalMode.new(PSTTMode.new());
var awg9Radar   = AirborneRadar.newAirborne([[pulseDSMode, rwsMode, twsMode, pulseMode, PDSTTMode.new(), PSTTMode.new(), palMode]], AWG9);
var f14_rwr     = RWR.new();

wcs_mode_sel(4);

if (!we_are_bs) {
	xmlDisplays.initPilotTgts();
} else {
	# Calling this to make sure the az/bars properties are populated.
	awg9Radar.rioRadar();
}

#should probably not be in this file, this is due to people that don't set it, they are all gonna fly around with 00 elsewise and always see each other
#setprop("instrumentation/datalink/channel", int(rand()*33)); Not needed, since 00 means datalink is off

#Used for xml rio rwr display. Is a hack until fixed in model xml and ac3d.
setprop("orientation/opposite",180);

# TODO
#+ Inputs/Controls
#+ Displays
#+ RWR
#+ make dual seater not see each other on radar
#+ hook target beside TWS
#  show encircled target on TID (Richard)
#+ Pilot mode(s)
#+ Ask Richard how/if ecm works.
#+ Move most methods into classes
#+ Datalink
#+ Ask Richard about "closure-last-x"
#+ Enable master-arm SIM
#+ PAL range range on TID
#+ STT auto switch error
#+ DDD range buttons
#+ DDD elev setting and caret setting right of display
#+ datalink random startup
#+ rio setfile Nasal
#+ ejection view
#+ tons of rio errors
#+ tab controls bars
#+ dual seat rio mode transfer
#+ make aim-54 be able to fire on only tws selection
#+ no ejection for dual rio
#+ Switch to EDMD dual rio dont work
#+ Sidewinder on and off
#+ Standard joystick bindings for radar.
#  review discspeeds
#+ Handover dual control az and bars setting.
#  aim9 non radar test
#? aim7 lock test above 10nm