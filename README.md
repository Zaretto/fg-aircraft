Zaretto FlightGear Aircraft Models
-----------------------------------------------

Aircraft directory contains the FlightGear aircraft models by Richard Harrison

F-14B - see http://zaretto.com/f-14. JSBSim aero model and improvements to original f-14b by xii, flying_toaster;

F-15 - C and D variants. http://zaretto.com/f-15. JSBSim aero model, external model by flying_toaster; cockpit photo textures by geneb.

-----------------------------------------------------------------
Contributions are welcomed. If there's something you want to improve or fix raise an issue here. If you know what you want to do then spell it out in the issue. https://github.com/Zaretto/fg-aircraft/issues

Branches are as follows:
* master is generally where I do most of the development. the 
* develop I use only for large changes (to keep master free from in development breaking changes). 
* flightgear-release branch is generally what I use to make the archives that are distributed on my page.

It is best if you reference the issue in the commit or pull message.

So to summarise;

- communicate by raising an issue
- contribute by making the changes to the master branch, test and then when you're happy generate a pull request
- wait for the pull request to be reviewed and accepted. 

------

V1.12 Changes

## RELEASE NOTES -  .

F-14:
* Emesary damage, weapons improvements, revised station selection and jettison
* New improved radar simulation
* Aerodynamic data improvements based on NASA TM-X-62306 for slats, flaps, aux flaps, gear, spoilers
* SAS now based on real aircraft system from NASA TM-81833
* APC rewrite based on aircraft system.
* F-110-GE-400 Engine model improved (thrust, oil simulation,
* Instrumentation improvements (models, 3d) for radalt, ASI
* DLC implemented (original and AFC MOD 735)
* Improved damage model for flaps, slats, wing bending
* IFF and Datalink

F-15:
* TEWS improvements
* VSD improvements
* MPCD SIT map rewrite
* Emesary damage
* Hyds, JFS simulation model improved
* aero model improved for flaps.
* nasal performance improvements
* weapons, radar updates.

#### Change summary for 1.12:
+ 2022-11-18  F-14: wing bend fixes
+ 2022-10-16  F-14: Sim: Fix that some callsigns could mess up emesary communications. (#164)
+ 2022-07-15  F-14: Fix bug in radar system (#163)
+ 2022-07-10  F-14: Develop: F14 and F15 weapons update (#162)
+ 2022-05-06  F-14: MP RIO Fix (#159)
+ 2022-02-21  F-14: Radar upgrade (#157)
+ 2022-02-11  F-14: Fix cockpit fuel probe switch
+ 2022-02-06  F-14: Added props Added props to define new damage.nas options
+ 2022-02-06  F-14: Updated damage files to latest
+ 2022-01-30  F-14: RIO view change sound Fixes #152
+ 2022-01-29  F-14: Fixes in air smoke/spray
+ 2022-01-26  F-14: Selective jettison and stores selection
+ 2022-01-26  F-14: rework fuel restore
+ 2022-01-22  F-14: F-15: Fix target lock over MP
+ 2022-01-03  F-14: rotate wingtip trails fixes
+ 2021-12-20  F-14: fix afterburner sounds
+ 2021-12-20  F-14: Fix initial state of lighting switches
+ 2021-11-23  F-14: Fixup initial state for fresh install
+ 2021-11-23  F-14: Fix radalt needles
+ 2021-11-03  F-14: cockpit model fixes
+ 2021-10-29  F-14: VDI brightness change
+ 2021-10-29  F-14: better VDI brightness controls
+ 2021-10-29  F-14: Fix range display on HSD and add new controls
+ 2021-10-28  F-14: fix ejection handles and nav display digit
+ 2021-10-25  F-14: flaps overspeed damage improvements
+ 2021-10-25  F-14: added RIO panels, (DDI, datalink, IFF, AAI)
+ 2021-10-07  F-14: Added missing texture for new HSD text.
+ 2021-10-06  F-14: fix DEST CRS and GS inverted display on HUD
+ 2021-10-05  F-14: cockpit improvements.
+ 2021-10-03  F-14: fix Nasal error causing inoperable payloads.
+ 2021-09-29  F-14: Rework external stores select animation. Fixes issue #149
+ 2021-09-28  F-14:; revised tyre smoke / spray system Refs #137
+ 2021-09-27  F-14: Radar altimeter redone based on NATOPSF-
+ 2021-09-27  F-14: Fix mach display on airspeed / mach indicator
+ 2021-09-27  F-14: Fix RIO TID heading indication for returns
+ 2021-09-26  F-14: Added CADC Lateral System Authority
+ 2021-09-26  F-14: fix smoke trail expresssions.
+ 2021-09-26  F-14: Prevent engagement of altitude hold unless master autopilot also engaged. Fixes #121
+ 2021-09-26  F-14: remove smoke color debug
+ 2021-09-26  F-14: change to use correct method for GUI dialogs
+ 2021-09-24  F-14A: only has compressor stall malfunction
+ 2021-09-24  F-14: Add Left/Right smoke colour selection
+ 2021-09-20  F-14: Airspeed mach instrument changes
+ 2021-09-20  F-14: Added missing external lighting models Fixes #147
+ 2021-09-19  F-14: Airspeed / Mach indicator improvements
+ 2021-09-17  F-14: Radar Altimeter correct position
+ 2021-09-17  F-14: Roll control / SAS improvement
+ 2021-09-09  F-14: keybindings for SAS channels on/off
+ 2021-08-16  F-14: F-15 F-14 remove local blackout system and use default FG blackout system instead Refs #150
+ 2021-08-15  F-14: FCS compatibility fixes
+ 2021-08-15  F-14: new blackout parameters
+ 2021-07-16  F-14: ; new simulation of the alpha measurement devices,
+ 2021-07-16  F-14: Move refuel property into jsbsim
+ 2021-07-09  F-14: SAS roll channel adjustments
+ 2021-06-05  F-14:, F-15: XML / XSLT and XSD fixes
+ 2021-05-25  F-14: F-110-GE-400 revised thrust data
+ 2021-05-22  F-14: rework oil temperature and pressure
+ 2021-05-22  F-14: Fix incorrect low fuel warning.
+ 2021-05-21  F-14: TF-30 fix channel names
+ 2021-05-21  F-14: F110-GE-400 fuel and oil pressure and temperature
+ 2021-05-21  F-14: change master caution system to run as property rules.
+ 2021-05-19  F-14: Updated damage system to emesary. 
+ 2021-05-17  F-14: Update fire-control and station-manager to latest.
+ 2021-05-15  F-14: Add DataLink. (#141)
+ 2021-05-14  F-14: Add IFF Channel Selection (#139)
+ 2021-05-14  F-14: Encapsulating IFF in <instrumentation>
+ 2021-05-14  F-14: Removed "debug" prints
+ 2021-05-14  F-14: Added IFF channel selection.
+ 2021-05-14  F-14: FCS fix p feedback into yaw channel
+ 2021-05-14  F-14: FCS : fix <clipto>
+ 2021-05-14  F-14: Damage, missile, rcs and vector upgrade to latest.
+ 2021-05-13  F-14: SAS changes for roll and yaw
+ 2021-05-12  F-14: Makes combat log window resizeable.
+ 2021-05-11  F-14: FCS SAS Roll & Yaw changes
+ 2021-05-10  F-14: SAS pitch fixes
+ 2021-05-10  F-14: FCS: Pitch SAS convert logic to work in degrees
+ 2021-05-09  F-14: FCS Use simulated sensors for angular velocities
+ 2021-05-07  F-14: FCS improvements refs #132
+ 2021-05-06  F-14: Refs #132 FCS
+ 2021-04-26  F-14: Added missing Emesary files
+ 2021-03-16  F-14: AOA Indexer - logic fixes
+ 2021-02-20  F-14: lighting rework part 1 (AOA Indexer)
+ 2021-02-20  F-14: compatibility with 2018.3
+ 2021-01-28  F-14: V2.0 RC1 changes
+ 2021-01-27  F-14:A aero release 1.2
+ 2021-01-22  F-14: aero; revised flaps/slats
+ 2021-01-22  F-14: aero: fix AUX flaps
+ 2021-01-19  F-14: Fix Radalt sound
+ 2021-01-19  F-14: Fix red flood and instruments
+ 2021-01-19  F-14: cockpit model improvements
+ 2021-01-17  F-14: 3d cockpit model fixes
+ 2021-01-17  F-14: Aero; minor fixes for property and function names
+ 2021-01-09  F-14: aero damage improvements (flaps, slats)
+ 2021-01-09  F-14: cockpit model changes
+ 2021-01-07  F-14: bad path fixes
+ 2021-01-07  F-14: fix bad filepath
+ 2021-01-07  F-14: Aero: Aux flaps, DLC, APC,
+ 2021-01-03  F-14: Added livery config support for AFC MOD 735 (DLC)
+ 2021-01-03  F-14: JSBSim refactor init
+ 2021-01-03  F-14: Remove Eagle liveries
+ 2020-12-31  F-14: APC rewrite
+ 2020-12-22  F-14: Aero; updated aerodata for landing gear
+ 2020-12-22  F-14: aero : new longitudinal data from TM-X-62306
+ 2020-12-17  F-14: FDM/FCS; new data from TM-X-62306; rework spoilers and DLC
+ 2020-12-17  F-14: aero: added missing data references
+ 2020-12-10  F-14: FCS changes
+ 2020-12-05  F-14: Implement analogue FCS from NASA TM-81833
+ 2020-11-30  F-14: Improved arrestor wire simulation
+ 2020-11-30  F-14: Added WolfPack (VF-1) livery
+ 2020-11-09  F-14: Fix missing tag
+ 2020-11-06  F-14: Missile/damage code update
+ 2020-11-03  F-14: Arms: Fixed bug in missile code if missile fired below minimum guiding speed.
+ 2020-11-01  F-14: Update missile code (emesary)
+ 2020-11-01  F-14: Update emesary missile-code.
+ 2020-10-31  F-14: Update damage and stop relying on local emesary files.
+ 2020-10-26  F-14: fresh emesary from release
+ 2020-10-26  F-14: Emesary: Bombs now do not deploy when jettisoned. Emesary: Missiles no longer make craters when not hitting ground. Emesary: Added Mirage cannon and a bomb to damage. Emesary: Sending out flare notifications is now partitioned, to avoid filling up the queue. Emesary: Less space in bridge[18] and bridge[17]. Emesary: Flare notification is now more lean. Emesary: Flare model a bit larger at medium distance.
+ 2020-10-24  F-14: Emesery: fix error in Damage
+ 2020-10-24  F-14: Emesary damage update
+ 2020-10-24  F-14: Emesary: Updated missile-code.
+ 2020-10-23  F-14: Arms: Fix me.inacc Arms: Less cm resist
+ 2020-10-23  F-14: Emesary: Better flare model.
+ 2020-10-23  F-14: Emesary: Flares are now on own bridge Fox2: {Paccalin} A recursive function to compute the closest range in the past frames.
+ 2020-10-21  F-14: Emesary: Event log only written to file if exit FG proper. Emesary: Show some CM over MP.
+ 2020-10-21  F-14: Arms: Some comment and code updates.
+ 2020-10-21  F-14: Sim: Event log now can be seen if moving slowly.
+ 2020-10-21  F-14: Emesary missile notification send rate now double of bridge rate.
+ 2020-10-21  F-14: Anim: Animate incoming notifications.
+ 2020-10-20  F-14: Update fire-control.nas and station-manager.nas
+ 2020-10-20  F-14: Emesary: Fix the log again.
+ 2020-10-20  F-14: Sim: Also send hit smoke out on mp with emesary. Sim: Transmit in flight notifications for weapons more often. Sim: Be able to see craters placed before going online with mp msg on. Sim: Change namespace for damage and GeoTransmitter to be same as other aircraft, so missile-code don't have to be custom.
+ 2020-10-19  F-14: Update damage code to latest
+ 2020-10-19  F-14: Emesary: Fix a bug in damage.nas and set damage noti. freq to 2 seconds.
+ 2020-10-19  F-14: Emesary: Update core
+ 2020-10-18  F-14: Update vector.nas Emesary bridge will now not keep hit messages in the transmit property
+ 2020-10-18  F-14: Fix MP stores sending 1 station too much.
+ 2020-10-18  F-14: Emesary: Test for fg 2020.1.1
+ 2020-10-18  F-14: Added some comments to warheads
+ 2020-10-17  F-14: Emesary: Cannon typeid is now negative numbers. Emesary: Main emesary from 2020.3.1rc with small fix.
+ 2020-10-17  F-14: Emesary cannon/rockets are now 111+id, as max is 124, consider doing those negative. Use emesary mp bridge from fgdata as its fine in 2020.3.1. Invert factor since emesary changed in fgdata for: relAlt, dist, speed and pitch. For heading and hit-bearing normalize to -180 to 180 encode, decode and renormalize to 0 to 359. Fix for a emesaryBridge change in fgdata
+ 2020-07-12  F-14: carrier approach fixes
+ 2020-07-12  F-14: carrier approach fixes
+ 2020-06-04  F-14: Craters now have their own notification.
+ 2020-06-01  F-14: Fix for processing some notifications multiple times.
+ 2020-06-01  F-14: Fix for decoding missile pitch to 25.50 degs almost always.
+ 2020-05-31  F-14: Fix typo in damage.nas Enable craters over MP. They should probably have their own notification though.
+ 2020-05-31  F-14: Make sure that hits on self gets transmitted over MP also for logging purposes.
+ 2020-05-31  F-14: Temporary on-screen MAW/MLW till a RWR is modeled in RIO seat.
+ 2020-05-31  F-14: Fix gun would not fire if all that was done was turning on master arm.
+ 2020-05-31  F-14: No missile warnings if mp msg is OFF.
+ 2020-05-31  F-14: Can now again be hit by itself.
+ 2020-05-31  F-14: Don't give launch warning for ejection seat.
+ 2020-05-30  F-14: Also mention property when detaching MP bridge.
+ 2020-05-30  F-14: Update missile-code to latest.
+ 2020-05-30  F-14: Use changed core MP emesary until FGDATA gets uptodate and people have switched over.
+ 2020-05-30  F-14: Fix missing property init.
+ 2020-05-29  F-14: Fix bug in last commit
+ 2020-05-29  F-14: New MP emesary for testing.
+ 2020-05-27  F-14: {pinto} Change sidewinder growl sound.
+ 2020-05-27  F-14: Add smoke sometimes when get hit by weapon.
+ 2020-05-27  F-14: Message in eventlog when bomb lands disarmed.
+ 2020-05-27  F-14: Arming time of mk83 reduced to 2 secs, not sure this is a good idea..
+ 2020-05-27  F-14: More continous tone from MAW.
+ 2020-05-27  F-14: {Thorsten} prettier bomb explosions.
+ 2020-05-26  F-14: Better handling of crater making and bomb explosion.
+ 2020-05-26  F-14: MLW now gets reset every 5 mins to allow for people to reload same pylon and fire it again.
+ 2020-05-26  F-14: Low speed handling; power/drag tuning
+ 2020-05-26  F-14: More solid check for aircraft being classified as ships.
+ 2020-05-26  F-14: Better check to prevent aircraft being designated as ships on low elevation airports.
+ 2020-05-26  F-14: Fix that sound propagation was running in missile thread for no reason.
+ 2020-05-26  F-14: Dont give approach warning if locked on chaff.
+ 2020-05-26  F-14: Write in eventlog what date it is started up.
+ 2020-05-26  F-14: Fixed that when hitting flares or chaff it would send a hit message.
+ 2020-05-25  F-14: Aim54 min range increased. Also the pitbull point is now 3 nm earlier.
+ 2020-05-25  F-14: Fix ejection view since a view was added its view number needed to be bumped.
+ 2020-05-25  F-14: Faster update rate of missiles at terminal phase.
+ 2020-05-25  F-14: Cleaner console for event.
+ 2020-05-25  F-14: Fix function was overwritten.
+ 2020-05-25  F-14: Add brevity fire msgs to eventlog.
+ 2020-05-25  F-14: AIM54 now breaks off its climb earlier depending on bandit distance. Same for when its cruising at high alt.
+ 2020-05-25  F-14: Fix for same again.
+ 2020-05-25  F-14: Fix for damage using old name.
+ 2020-05-25  F-14: More clarity on deletion parameter to inFlight function.
+ 2020-05-25  F-14: Better final inFlight message of missiles.
+ 2020-05-25  F-14: Now sends a final inFlight message when getting deleted. Also those messages will now only be sent when MP msgs is on.
+ 2020-05-25  F-14: Removed test properties from screen. F-14: Reverted test settings of missiles.
+ 2020-05-25  F-14: CM success rate now 13.33%
+ 2020-05-25  F-14: Made launch and approach sounds different. Launch is faster.
+ 2020-05-24  F-14: Recalculate flaps lift/drag
+ 2020-05-24  F-14: Removed screen message that gave the wrong info.
+ 2020-05-24  F-14: For wednesdays event force real time. F-14: For wednesdays event write eventlog to a file every 10 mins. F-14: Added callsigns to eventlog for wednesdays event.
+ 2020-05-22  F-14: Send missile attitude and speed over emesary. F-14: Only send in-flight updates over emesary every 0.75 seconds.
+ 2020-05-20  F-14: Reworked pitch moment due to flaps
+ 2020-05-20  F-14: Tuned engine Z position
+ 2020-05-18  F-14: SAS: roll
+ 2020-05-11  F-14: tidy up aero model tables
+ 2020-05-11  F-14: Adjusted pitching moment due to flaps.
+ 2020-05-09  F-14: Log to event log when missile target logs off inflight.
+ 2020-05-05  F-14: New notification for in flight armaments.
+ 2020-05-04  F-14: Added event log to menu. F-14: Removed arming delay for missiles for testing.
+ 2020-05-02  F-14: Stop transmitting Guns Guns.
+ 2020-05-02  F-14: Check active_u in radar for take-off/crash/landing to set appropiate type on it.
+ 2020-05-02  F-14: Made a little log for damage. F-14: Added a spike sound from rwr. F-14: Added logic to send out who we are spiking.
+ 2020-05-01  F-14: Missile will now also not name its target if lost radar lock.
+ 2020-05-01  F-14: Missile now only send callsign of target if it havent given up.
+ 2020-05-01  F-14: Made AIM54 semiradar guided until 8nm before target.
+ 2020-05-01  F-14: Cannon hit messages now work over emesary too. F-14: Cannon hit messages now transmit multiple hit over each message. F-14: MLW now registers callsign too for use in RWR. F-14: MLW now works more than 1 time.
+ 2020-05-01  F-14: Added ITS for pitch (flaps/slats)
+ 2020-04-30  F-14: Removed maddog MP message.
+ 2020-04-30  F-14: Change receipt status for hit msgs.
+ 2020-04-30  F-14: Fox2-inflight msgs now have callsign of target. F-14: Some changes to emesary debuging prints.
+ 2020-04-30  F-14: Added some props to screen for testing.
+ 2020-04-30  F-14: DIsabled MLW sound.
+ 2020-04-30  F-14: temp made missiles able to hit ground targets.
+ 2020-04-30  F-14: Stop sending out messages when fire/hit/miss.
+ 2020-04-30  F-14: Changed launch/approach warning conditions.
+ 2020-04-30  F-14: Updated damage to reflect functionality of latest non emesary version.
+ 2020-04-23  F-14: SAS roll / yaw fixes
+ 2020-04-23  F-14: Fix autopilot dialog path
+ 2020-04-18  F-14: Simplify using timers across threads in fox2.
+ 2020-04-17  F-14: use correct dialog for autopilot
+ 2020-04-16  F-14: autopilot rework.
+ 2020-04-16  F-14: Possibly fix nasal error:
+ 2020-04-15  F-14: Revised Roll SAS after flight testing
+ 2020-04-14  F-14: Fix wing sweep / flaps interaction.
+ 2020-04-14  F-14: Add roll SAS from TM-81833
+ 2020-04-05  F-14: implement YAW SAS from TM-81833
+ 2020-04-02  F-14: Fix for last last commit, forgot to run the loop.
+ 2020-04-02  F-14: Remove settimer calls across threads. Proof of concept.
+ 2020-03-31  F-14: Yaw damper tuning WIP
+ 2020-03-31  F-14: Adjusted for correct glideslope
+ 2020-03-29  F-14: Fix corrupted spoiler pitching moment table
+ 2020-03-29  F-14: Update F-14A aero from F-14B
+ 2020-03-29  F-14: Format data tables.
+ 2020-03-28  F-14:B aero / SAS
+ 2020-03-26  F-14: aero ; align data columns
+ 2020-03-26  F-14: Tuning of flaps
+ 2020-03-26  F-14: Adjust size of video camera
+ 2020-03-26  F-14: Fixed arg number in fligth msg
+ 2020-03-25  F-14: Protect flight msg args with mutex.
+ 2020-03-24  F-14: Emesary MP fixe
+ 2020-03-21  F-14: Better handling of threaded hit messages.
+ 2020-02-26  F-14: Made the craters not be HoT.
+ 2020-02-26  F-14: Move stuff out of damage.nas that dont belong there.
+ 2020-02-26  F-14: Updated damage.
+ 2020-02-25  F-14: WIP: Armament damage / inflight notifications using Emesary
+ 2020-02-24  F-14: Nasal - fix error in troll logic
+ 2020-02-23  F-14: Fix for dropping bomb on nil terrain.
+ 2020-02-23  F-14: Enabled crater system.
+ 2020-02-23  F-14: Added crater effect when bombs hit ground
+ 2019-12-19  F-14: Added ignore MP pilots dialog.
+ 2019-12-15  F-14: Arms: Fixed major multi-threading error that made missiles think they lost sight of target when they didn't. This resulted in tons of 'hit the ground' instead of splashes. Arms: Ejected powered-missiles no align more to aircraft attitude instead of airstream. Arms: Missiles will no longer lose attitude due to gravity before they have reached minimum guide speed.
+ 2019-12-15  F-14: AIM-54 and AIM-7 is now forcefully ejected from launcher.
+ 2019-12-15  F-14: Update to fire-control and pylon system.
+ 2019-12-15  F-14: Made eject handle in cockpit work.
+ 2019-12-14  F-14: Added key F6 for ejecting.
+ 2019-12-14  F-14: Removed last remnant of anti-cheat messages.
+ 2019-12-13  F-14: Fix for missile seeker head.
+ 2019-12-13  F-14: Added comment in pylons.nas
+ 2019-12-13  F-14: Weapons now gets fired/jettisoned from more accurate pylon positions.
+ 2019-12-13  F-14: Proper EMERG JETT and ACM JETT behavior.
+ 2019-12-13  F-14: Some cleanup of old properties.
+ 2019-12-13  F-14: When loading stores with masterarm ON they now get ready to fire immediatly.
+ 2019-12-12  F-14: Fixed objects references in mk-83.
+ 2019-12-12  F-14: Removed comment.
+ 2019-12-12  F-14: Made MK-83 drop and explosions be visible.
+ 2019-12-12  F-14: Rename mk83 folder. Part 2.
+ 2019-12-12  F-14: Renaming mk83 folder part 1.
+ 2019-12-12  F-14: Now only sets the store config if the change was succesful.
+ 2019-12-11  F-14: Workaround for bug in 2019.1 FailureMgr. Added some various comments.
+ 2019-12-11  F-14: When ext tanks was mounted state saved they will now be mounted again when starting up.
+ 2019-12-11  F-14: Added airshow config with smokewinders. They are now needed for smoke.
+ 2019-12-11  F-14: Replaced the voice messages at missile threat warning to a tone.
+ 2019-12-11  F-14: Fixed that the gun sound was playing when out of ammo.
+ 2019-12-11  F-14: Fixed TWS-AUTO RIO button did not work like key ctrl-n.
+ 2019-12-11  F-14: Changed GCI bools and added keys to help.
+ 2019-12-11  F-14: Added comment in pylon.nas.
+ 2019-12-11  F-14: Updated damage.
+ 2019-12-10  F-14: Fixed gun count and gun reload button.
+ 2019-12-10  F-14: Added comment
+ 2019-12-10  F-14: Fixed droptanks submodels would fire even if no tanks mounted.
+ 2019-12-10  F-14: Fixed that cannon and a sidewinder was competing for a pylon spot.
+ 2019-12-10  F-14: Preparation for CCRP. The all-cockpit.ac needs to be updated with the 3 components of CCRP before enabling this.
+ 2019-12-10  F-14: A/G button on lower right side of pilots cockpit now selects MK-83.
+ 2019-12-10  F-14: Fixed aim-9 sound.
+ 2019-12-10  F-14: Reenabled total weapon and pylon mass in dialog.
+ 2019-12-10  F-14: Removed anti-cheat messages. Added GCI support.
+ 2019-12-10  F-14: RCS data update. Mostly filled in by Jmav16.
+ 2019-12-10  F-14: Replaced fire-control and pylon-control with generic system. Updated fox2 missile code. Updates to aim-9 and aim-7. Removed MP missiles that often make FG crash. Added failure mode for fire-control.+ 2022-10-19  F-15: updated Nasal fallback readmine

+ 2022-10-19  F-15: Move revised autopilot dialog
+ 2022-10-19  F-15: Finish emexec changes
+ 2022-10-16  F-15: Sim: Fix that some callsigns could mess up emesary communications. (#164)
+ 2022-07-17  F-15: emexec changes to aircraft-main
+ 2022-07-17  F-15: TEWS improvements
+ 2022-07-17  F-15: VSD improvemets
+ 2022-07-17  F-15: change to use emexec
+ 2022-07-17  F-15: Use new Emesary Exec module (emexec)
+ 2022-07-15  F-15: Fix VSD on backseat
+ 2022-07-10  F-15: weapons update (#162)
+ 2022-02-06  F-15: MPCD SIT readability
+ 2022-02-06  F-15: Updated damage files
+ 2022-01-22  F-15: Fix target lock over MP
+ 2022-01-20  F-15: Fixes #151 : New SIT display on MPCD
+ 2021-08-16  F-15: 2018.3 compatibility
+ 2021-08-16  F-15: Fix JFS hyds
+ 2021-08-16  F-15: fix JSBSim property initialization warnings.
+ 2021-06-19  F-15: WIP Landing tutorial
+ 2021-05-27  F-15: MP animations and external stores
+ 2021-05-27  F-15: rework external stores select animations
+ 2021-05-27  F-15: prevent changing of stuff according to usual convention.
+ 2021-05-21  F-15: Forgot to commit this change to bomb weight.
+ 2021-05-21  F-15: Small change to sending spiked msg to locked aircraft.
+ 2021-05-20  F-15: Added failure mode for fire-control.
+ 2021-05-20  F-15: Added GBU-10 Paveway II laser guided bombs. Added bomb release sound.
+ 2021-05-20  F-15: Fix the ccippipper was rotating opposite.
+ 2021-05-20  F-15: Fix same bug
+ 2021-05-20  F-15: Fixed uncommmented line
+ 2021-05-20  F-15: Wing inboard station pylon/rack weight now again done in JSBSim.
+ 2021-05-15  F-15: Added training configuration (#83)
+ 2021-05-15  F-15: Added Training option (#84)
+ 2021-01-28  F-15: Remove JMaverick16 personal liveries;
+ 2021-01-28  F-15: remove userarchive from model properties.
+ 2020-10-26  F-15: Use PartitionProcessor from core libs
+ 2020-10-09  F-15: HUD fix IAS speed tape
+ 2020-09-29  F-15: Revert changes to MPCD (incorrect model saved)
+ 2020-09-03  F-15: Emesary fixes
+ 2020-09-03  F-15: Added missing aero reference
+ 2020-10-15  F-15: Adding more missiles
+ 2020-09-29  F-15: Revert changes to MPCD (incorrect model saved)
+ 2020-09-03  F-15: Emesary fixes
+ 2020-09-03  F-15: Added missing aero reference
+ 2020-03-26  F-15: Tuning of flaps
+ 2020-02-23  F-15: UV map fixes
+ 2019-12-21  F-15: latest livery version
+ 2019-11-02  F-15: Contrail now depends on weather rather than altitude


