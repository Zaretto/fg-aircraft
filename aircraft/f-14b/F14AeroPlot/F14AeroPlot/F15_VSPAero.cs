using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;

namespace F14AeroPlot
{
    public class AeroHex
    {
        public double Cd = Double.NaN;
        public double Cl = Double.NaN;
        public double Cy = Double.NaN;
        public double CL = Double.NaN;
        public double CM = Double.NaN;
        public double CN = Double.NaN;
        public string breakpoints;
    }
    public class AeroDerivative
    {
        public double CMLP = Double.NaN;
        public double CMMQ = Double.NaN;
        public double CMNP = Double.NaN;
        public double CMNR = Double.NaN;
        public double CMLR = Double.NaN;
        public double CFYR = Double.NaN;
        public double CFYP = Double.NaN;
        public string breakpoints;
    }
    /// <summary>
    /// build using VSP.
    /// </summary>
    /// <remarks>
    /// may take a while. Typically around 14hours</remarks>
    public class F15_VSPAero : Aerodata
    {
        bool can_calc = false;
        string op_dir = "F-15-calc/";
        string dir = @"C:\Users\Richard\dev\flightgear\OpenVSP-3.5.2-win32\";
        public F15_VSPAero(bool Calc=false)
        {
            can_calc = Calc;
            var aerodata = this;
            aerodata.Aliases.Add("DELEDD", "fcs/elevator-pos-deg");
            aerodata.Aliases.Add("DTALD", "fcs/differential-elevator-pos-deg"); // -ve is left.
            aerodata.Aliases.Add("DDA", "fcs/aileron-pos-deg");
            aerodata.Aliases.Add("DRUDD", "fcs/rudder-pos-deg");
            aerodata.Aliases.Add("BETA", "aero/beta-deg");
            aerodata.Aliases.Add("CEF", "aero/cadc-control-effectivity-factor");
            //            aerodata.Description = "F-15 - basic aerodynamics are the same, except for the two place canopy which is accounted for";
            //            aerodata.AircraftType = "F-15 (all variants)";
            aerodata.Systems.Add("f-15-hydraulic");
            aerodata.Systems.Add("f-15-electrics");
            aerodata.Systems.Add("catapult");
            aerodata.Systems.Add("f-15-cadc");
            aerodata.Systems.Add("f-15-apc");
            aerodata.Systems.Add("f-15-ecs");
            aerodata.Systems.Add("f-15-engines");
            aerodata.Systems.Add("hook");
            //aerodata.Systems.Add("holdback");
            aerodata.Systems.Add("flight-controls");
            //aerodata.Systems.Add("f15-config");


            aerodata.References.Add(new ReferenceDocument
            {
                Id = "ZDAT/AED/2016/01-29",
                Author = "Richard Harrison, rjh@zaretto.com",
                Date = "January, 2016",
                Title = "F-15 Aerodynamic data built from vspaero; CGx 10.5m",
                Url = "http://www.zaretto.com/sites/zaretto.com/files/F-15-data/rjh-zaretto-f-15-aerodynamic-data-vspaero.pdf",
            });
            aerodata.References.Add(new ReferenceDocument
            {
                Id = "AFIT/GAE/ENY/90D-16",
                Author = "Robert J. McDonnell, B.S., Captain, USAF",
                Date = "December 1990",
                Title = "INVESTIGATION OF THE HIGH ANGLE OF ATTACK DYNAMICS OF THE F-15B USING BIFURCATION ANALYSIS",
                Url = "http://www.zaretto.com/sites/zaretto.com/files/F-15-data/ADA230462.pdf",
            });
            aerodata.References.Add(new ReferenceDocument
            {
                Id = "AFIT/GA/ENY/91D-1",
                Author = "Richard L. Bennet, Major, USAF",
                Date = "December 1991",
                Title = "ANALYSIS OF THE EFFECTS OF REMOVING NOSE BALLAST FROM THE F-15 EAGLE",
                Url = "http://www.zaretto.com/sites/zaretto.com/files/F-15-data/ADA244044.pdf",
            });
            aerodata.References.Add(new ReferenceDocument
            {
                Id = "NASA CR-152391-VOL-1 Figure 3-2 p54",
                Author = "DR. J. R. LUMMUS, G. T. JOYCE, O C. D. O MALLEY",
                Date = "October 1980",
                Title = "ANALYSIS OF WIND TUNNEL TEST RESULTS FOR A 9.39-PER CENT SCALE MODEL OF A VSTOL FIGHTER/ATTACK AIRCRAFT : VOLUME I - STUDY OVERVIEW",
                Url = "http://www.zaretto.com/sites/zaretto.com/files/F-15-data/19810014497.pdf",
            });
            aerodata.References.Add(new ReferenceDocument
            {
                Id = "NASA TP-3627",
                Author = "Frank W. Burcham, Jr., Trindel A. Maine, C. Gordon Fullerton, and Lannie Dean Webb",
                Date = "September 1996",
                Title = "Development and Flight Evaluation of an Emergency Digital Flight Control System Using Only Engine Thrust on an F-15 Airplane",
                Url = "http://www.zaretto.com/sites/zaretto.com/files/F-15-data/88414main_H-2048.pdf",
            });
            aerodata.References.Add(new ReferenceDocument
            {
                Id = "NASA-TM-72861",
                Author = "Thomas R. Sisk and Neil W. Matheny",
                Date = "May 1979",
                Title = "Precision Controllability of the F-15 Airplane",
                Url = "http://www.zaretto.com/sites/zaretto.com/files/F-15-data/88414main_H-2048.pdf",
            });
            aerodata.References.Add(new ReferenceDocument
            {
                Id = "95-fuel-dumping-system",
                Author = "Sabc",
                Date = "08 September 2010",
                Title = "Fuel Dumping System",
                Url = "http://www.f-15e.info/joomla/technology/fuel-system/95-fuel-dumping-system",
            });
            aerodata.References.Add(new ReferenceDocument
            {
                Id = "VSPAERO",
                Author = "Brandon Litherland",
                Date = " 2015/07/01 06:56",
                Title = "Using VSPAERO",
                Url = "http://www.openvsp.org/wiki/doku.php?id=vspaerotutorial",
            });
        
            aerodata.Title = "F-15 Aerodynamic data built from vspaero; CGx 10.75m";
            aerodata.SubTitle = String.Format("Richard Harrison, rjh@zaretto.com, ZDAT/AED/2014/12-2, {0}", DateTime.Now.ToLongDateString());

            aerodata.Notes.Add(@"Built using VSPAERO. The basic form is built from a single wing with varying cambers to roughly match
the shape of the aircraft. A set of degen geometry is required for the control surfaces, flaps and tanks, together with the elevator positions. These are all then processed and this data is built from the results (together with the -stab to get the derivatives)");
            aerodata.Notes.Add(@"Aircraft origin for measurements is the nose");
            aerodata.Notes.Add(@"F-15C in the critical aft c.g. configuration has a weight of 33,467
            pounds and a c.g. location at 563.1 inches (6:12). To
            convert c.g. location in inches to percent mean aerodynamic
            chord, the following equation is used for all A through D
            models of the F-15: (measurements in inches). 
            % MAC = (xcg - 408.1 * 100) / 191.33");
            aerodata.WingArea = new DenominatedAmount(608, "FT2"); // 56.485
            aerodata.wingspan = new DenominatedAmount(42.8, "FT"); //13.04544
            aerodata.chord = new DenominatedAmount(191.3, "IN");  //4.85902
            
            aerodata.WingArea = new DenominatedAmount(72.213532 , "M2");
            aerodata.wingspan = new DenominatedAmount(11.299664 , "M");
            aerodata.chord = new DenominatedAmount(8.959206, "M");

            aerodata.wing_incidence = new DenominatedAmount(0, "DEG");
            aerodata.EyePoint = new Location(197, 0, -3.94, "IN");
            //            aerodata.VRP = new Location(386, 0, -13, "IN");
            // model is at CG
            //            aerodata.VRP = new Location(0, 0, 0, "IN");

            aerodata.VRP = new Location(386, 0, 0, "IN");

            aerodata.CG = new Location(408, 0, 0, "IN");
            aerodata.CG = new Location(10.5, 0, 0, "M");
            aerodata.AERORP = aerodata.CG.FromChord(aerodata.chord, 25.65, 0, 0);

            aerodata.IXX = new DenominatedAmount(28700, "SLUG*FT2");
            aerodata.IYY = new DenominatedAmount(165100, "SLUG*FT2");
            aerodata.IZZ = new DenominatedAmount(187900, "SLUG*FT2");
            aerodata.IXZ = new DenominatedAmount(-520, "SLUG*FT2");
            aerodata.EmptyWeight = new DenominatedAmount(28000, "LBS");

            aerodata.Mass.Add(new PointMassElement(aerodata)
            {
                Name = "Station2-1",
                Location = new Location(1.7844, -3.8325, 0.288, "M")

            });
            aerodata.Mass.Add(new PointMassElement(aerodata)
            {
                Name = "Station2-2",
                Location = new Location(1.4077, -3.3034, 1.4077, "M")
            });

            aerodata.Mass.Add(new PointMassElement(aerodata)
            {
                Name = "Station2-3",
                Location = new Location(1.7844, -3.8325, 0.288, "M"),
            });

            aerodata.Mass.Add(new PointMassElement(aerodata)
            {
                Name = "Station3",
                Location = new Location(-0.3003, -1.611, 0.567, "M"),
            });

            aerodata.Mass.Add(new PointMassElement(aerodata)
            {
                Name = "Station4",
                Location = new Location(3.5918, -1.611, 0.567, "M"),
            });

            aerodata.Mass.Add(new PointMassElement(aerodata)
            {
                Name = "Station5",
                Location = new Location(0, 0, 0.33, "M"),
            });


            aerodata.Mass.Add(new PointMassElement(aerodata)
            {
                Name = "Station6",
                Location = new Location(-0.3003, 1.611, 0.567, "M"),
            });


            aerodata.Mass.Add(new PointMassElement(aerodata)
            {
                Name = "Station7",
                Location = new Location(3.5918, 1.611, 0.567, "M"),
            });


            aerodata.Mass.Add(new PointMassElement(aerodata)
            {
                Name = "Station8",
                Location = new Location(1.7844, 3.8325, 0.288, "M"),
            });


            aerodata.Mass.Add(new PointMassElement(aerodata)
            {
                Name = "Station9",
                Location = new Location(1.4077, 3.3034, 1.407, "M"),
            });


            aerodata.Mass.Add(new PointMassElement(aerodata)
            {
                Name = "Station10",
                Location = new Location(1.7844, 3.8325, 0.288, "M"),
            });

            aerodata.GroundReactions.Add(new Gear(aerodata)
            {
                Name = "NOSE_LG",
                Location = new Location(197, 0, -77.6496063, "IN"),
                MaxSteer = new DenominatedAmount(35, "DEG"),
                BrakeGroup = "NOSE"
            });

            aerodata.GroundReactions.Add(new Gear(aerodata)
            {
                Name = "LEFT_MLG",
                Location = new Location(451, -98, -84.3385827, "IN"),
                MaxSteer = new DenominatedAmount(0, "DEG"),
                BrakeGroup = "LEFT"
            });
            aerodata.GroundReactions.Add(new Gear(aerodata)
            {
                Name = "RIGHT_MLG",
                Location = new Location(451, 98, -84.3385827, "IN"),
                MaxSteer = new DenominatedAmount(0, "DEG"),
                BrakeGroup = "RIGHT"
            }
                 );

            aerodata.GroundReactions.Add(new GroundReactionElement(aerodata)
            {
                Name = "LEFT_WING_TIP",
                Location = new Location(472, -256.8, 13, "IN")
            });

            aerodata.GroundReactions.Add(new GroundReactionElement(aerodata)
            {
                Name = "RIGHT_WING_TIP",
                Location = new Location(472, 256.8, 13, "IN")
            });


            aerodata.GroundReactions.Add(new GroundReactionElement(aerodata)
            {
                Name = "CANOPY",
                Location = new Location(214, 0, 10, "IN"),
            });
            aerodata.GroundReactions.Add(new GroundReactionElement(aerodata)
            {
                Name = "RADOME_FRONT",
                Location = new Location(20, 0, -18, "IN"),
            });
            aerodata.GroundReactions.Add(new GroundReactionElement(aerodata)
            {
                Name = "LEFT_VERTICAL_TAIL",
                Location = new Location(744, -98, 60, "IN"),
            });
            aerodata.GroundReactions.Add(new GroundReactionElement(aerodata)
            {
                Name = "RIGHT_VERTICAL_TAIL",
                Location = new Location(744, 98, 60, "IN"),
            });
            aerodata.GroundReactions.Add(new GroundReactionElement(aerodata)
            {
                Name = "REAR_BODY_LEFT",
                Location = new Location(669, -58, -12, "IN"),
            });
            aerodata.GroundReactions.Add(new GroundReactionElement(aerodata)
            {
                Name = "REAR_BODY_RIGHT",
                Location = new Location(669, 58, -12, "IN"),
            });
            aerodata.GroundReactions.Add(new GroundReactionElement(aerodata)
            {
                Name = "NOSE_CONE",
                Location = new Location(0, 0, -15, "IN")
            });
            aerodata.Engines.Add(new Engine
            {
                Name = "F100-PW-100",

                Location = new Location(682, -12, 0, "IN"),
                Orient = new Location(0, 0, 0, "DEG"),
            });
            aerodata.Engines.Add(new Engine
            {
                Name = "F100-PW-100",

                Location = new Location(682, 12, 0, "IN"),
                Orient = new Location(0, 0, 0, "DEG"),
            });
            Tank t;
            t = new Tank("Right Feed line", 489, 38, -47, "IN", 1, 10, "LBS", null);
            aerodata.AddTank(t);
            aerodata.Engines[1].AddFeed(t);

            t = new Tank("Left Feed line", 489, -38, -47, "IN", 2, 10, "LBS", null);
            aerodata.AddTank(t);
            aerodata.Engines[0].AddFeed(t);

            t = new Tank("External Tank", 386, 0, -7.83, "IN", 3, 3950, "LBS", 100);
            aerodata.AddTank(t);
            aerodata.Engines[0].AddFeed(t);
            aerodata.Engines[1].AddFeed(t);

            t = new Tank("Right External Wing Tank", 420, 108, -7.83, "IN", 4, 3950, "LBS", 100);
            aerodata.AddTank(t);
            aerodata.Engines[1].AddFeed(t);

            t = new Tank("Left External Wing Tank", 420, -108, -7.83, "IN", 5, 3950, "LBS", 100);
            aerodata.AddTank(t);
            aerodata.Engines[0].AddFeed(t);

            t = new Tank("Right Wing Tank", 457.02, 130.32, 15.35, "IN", 6, 2750, "LBS", 100);
            aerodata.AddTank(t);
            aerodata.Engines[1].AddFeed(t);

            t = new Tank("Left Wing Tank", 457.02, -130.32, 15.35, "IN", 7, 2750, "LBS", 100);
            aerodata.AddTank(t);
            aerodata.Engines[0].AddFeed(t);


            t = new Tank("Tank 1", 307.42, 7.48, 14.57, "IN", 8, 3300, "LBS", 100);
            aerodata.AddTank(t);
            aerodata.Engines[0].AddFeed(t);
            aerodata.Engines[1].AddFeed(t);

            t = new Tank("Right Engine Feed", 396.79, 7.95, -5.51, "IN", 9, 1500, "LBS", null);
            aerodata.AddTank(t);
            aerodata.Engines[1].AddFeed(t);


            t = new Tank("Left Engine Feed", 453.87, 7.83, 0.79, "IN", 10, 1200, "LBS", null);
            aerodata.AddTank(t);
            aerodata.Engines[0].AddFeed(t);

            //            aerodata.FuelDumpRate = 910;

            aerodata.ExternalReactions.Add(new ExternalForce
            {
                name = "catapult",
                frame = "BODY",
                location = new Location(667, 0, 0, "IN"),
                direction = new Location(1, 0, 0, null),
            });

            aerodata.ExternalReactions.Add(new ExternalForce
            {
                name = "holdback",
                frame = "BODY",
                location = new Location(667, 0, 0, "IN"),
                direction = new Location(-1.0, 0.0, 0.0, null)
            });


            aerodata.ExternalReactions.Add(new ExternalForce
            {
                name = "hook",
                frame = "BODY",
                location = new Location(300, 0, 0, "IN"),
                direction = new Location(-0.9995, 0.0, 0.01, null)
            });

            //aerodata.ExternalReactions.Add(new ExternalForce
            //{
            //    frame = "BODY",
            //    name = "F110-GE-400-1",
            //    location = new Location(667, 45, 10, "IN"),
            //    direction = new Location(-0.9995, 0.0, 0.01, null)
            //});

            //aerodata.ExternalReactions.Add(new ExternalForce
            //{
            //    frame = "BODY",
            //    name = "F110-GE-400-2",
            //    location = new Location(667, 45, 10, "IN"),
            //    direction = new Location(-0.9995, 0.0, 0.01, null)
            //});


            //var EPA43 = aerodata.Add("CNDR MULTIPLIER CLDR, CYDR DUE TO SPEEDBRAKE", "EPA43", "alpha", "speedbrake");
            //var EPA02S = aerodata.Add("BETA MULTIPLIER TABLE (S)", "EPA02S", "beta");
            //var EPA02L = aerodata.Add("BETA MULTIPLIER TABLE (L)", "EPA02L", "beta");

            //            var CFZ = aerodata.Add("BASIC LIFT", "CFZB", "alpha", "elevator");
            var CFZB = aerodata.Add("BASIC LIFT", "CFZB", "alpha", "beta", "elevator");
            //var CFZBt = aerodata.Add("Alt BASIC LIFT CFZB(alpha,beta)", "CFZB", "alpha", "beta");

            var CFZDF = aerodata.Add("LIFT INCREMENT DUE TO FLAPS", "CFZDF", "alpha", "beta");
            CFZDF.AddFactor("fcs/flap-pos-deg");

            var CFXB = aerodata.Add("BASIC DRAG", "CFXB", "alpha", "beta", "elevator");
            var CFXDF = aerodata.Add("DRAG INCREMENT DUE TO FLAPS", "CFXDF", "alpha", "beta");
            CFXDF.AddFactor("fcs/flap-pos-deg");

            var CFYB = aerodata.Add("BASIC SIDE FORCE", "CFYB", "alpha", "beta", "elevator");

            var CFYP = aerodata.Add("SIDE FORCE DUE TO ROLL RATE", "CFYP", "alpha");
            CFYP.AddFactor("PB");

            var CFYR = aerodata.Add("SIDE FORCE DUE TO YAW RATE", "CFYR", "alpha");
            CFYR.AddFactor("RB");

            var CYDAD = aerodata.Add("SIDE FORCE DUE TO AILERON DEFLECTION", "CYDAD", "alpha", "beta");
            CYDAD.AddFactor("DDA");

            var CYDRD = aerodata.Add("SIDE FORCE DUE TO RUDDER DEFLECTION", "CYDRD", "alpha", "beta");
            //            CYDRD.AddFactor("DRUDD,DRFLX5,EPA43");
            CYDRD.AddFactor("DRUDD");

            var CYDTD = aerodata.Add("SIDE FORCE DUE TO DIFFERENTIAL TAIL DEFLECTION - CYDTD", "CYDTD", "alpha", "elevator");
            ////            CYDTD.AddFactor("DTFLX5,0.3,DTALD");
            CYDTD.AddFactor("DTFLX5,DTALD"); // 0.3 is handling by the flight controls

            //var CYRB = aerodata.Add("ASYMMETRIC CY AT HIGH ALPHA", "CYRB", "alpha", "beta");
            // CLM
            var CML1 = aerodata.Add("BASIC ROLLING MOMENT", "CML1", "alpha", "beta");
            //            CML1.AddFactor("EPA02S");

            var CMLP = aerodata.Add("ROLL DAMPING DERIVATIVE", "CMLP", "alpha");
            CMLP.AddFactor("PB");

            var CMLR = aerodata.Add("ROLLING MOMENT DUE TO YAW RATE", "CMLR", "alpha");
            CMLR.AddFactor("RB");
            //
            var CLDAD = aerodata.Add("ROLLING MOMENT DUE TO AILERON DEFLECTION", "CMLDAD", "alpha", "beta");
            CLDAD.AddFactor("DDA");
            //
            var CLDRD = aerodata.Add("ROLLING MOMENT DUE TO RUDDER DEFLECTION -(CLD)", "CMLDRD", "alpha", "beta");
            CLDRD.AddFactor("DRUDD,DRFLX1,EPA43");
            //
            var CLDTD = aerodata.Add("ROLLING MOMENT DUE TO DIFFERENTIAL TAIL DEFLECTION", "CMLDTD", "alpha", "elevator");
            ////            CLDTD.AddFactor("DTFLX1,0.3,DTALD");
            CLDTD.AddFactor("DTFLX1,DTALD");
            //
            //            var DCLB = aerodata.Add("DELTA CLB DUE TO 2-PLACE CANOPY", "CMLDCLB", "alpha");
            //            DCLB.AddFactor("BETA");
            //            DCLB.AddFactor("metrics/two-place-canopy");
            //
            // CMM
            var CMM1 = aerodata.Add("BASIC PITCHING MOMENT", "CMM1", "alpha", "elevator");
            var CMMDF = aerodata.Add("PITCHING MOMENT DUE TO FLAPS", "CMMDF", "alpha", "beta");
            CMMDF.AddFactor("fcs/flap-pos-deg");

            var CMMQ = aerodata.Add("PITCH DAMPING DERIVATIVE", "CMMQ", "alpha");
            CMMQ.AddFactor("QB");
            //            //
            //            var CMN1 = aerodata.Add("BASIC YAWING MOMENT - CN (BETA)", "CMN1", "alpha", "beta", "elevator");
            var CMN1 = aerodata.Add("BASIC YAWING MOMENT", "CMN1", "alpha", "beta", "elevator");
            //var CMNt = aerodata.Add("ALT YAWING MOMENT - CN (BETA)", "CMN1", "alpha", "beta");
            //Gear
                        var CFXGEAR = aerodata.Add("DRAG INCREMENT DUE TO GEAR", "CFXGEAR", "alpha", "beta");
                        var CFZGEAR = aerodata.Add("LIFT INCREMENT DUE TO GEAR", "CFZGEAR", "alpha", "beta");
                        var CFYGEAR = aerodata.Add("SIDE FORCE INCREMENT DUE TO GEAR", "CFYGEAR", "alpha", "beta");
                        var CMLGEAR = aerodata.Add("ROLLING MOMENT INCREMENT DUE TO GEAR", "CMLGEAR", "alpha", "beta");
                        var CMMGEAR = aerodata.Add("PITCHING MOMENT INCREMENT DUE TO GEAR", "CMMGEAR", "alpha", "beta");
                        var CMNGEAR = aerodata.Add("YAWING MOMENT INCREMENT DUE TO GEAR", "CMNGEAR", "alpha", "beta");
                        CFXGEAR.AddFactor("gear/gear-pos-norm");
                        CFZGEAR.AddFactor("gear/gear-pos-norm");
                        CFYGEAR.AddFactor("gear/gear-pos-norm");
                        CMLGEAR.AddFactor("gear/gear-pos-norm");
                        CMMGEAR.AddFactor("gear/gear-pos-norm");
                        CMNGEAR.AddFactor("gear/gear-pos-norm");

                        //var CFYGEARA = aerodata.Add("SIDE FORCE INCREMENT DUE TO MAIN GEAR ASYMMETRY", "CFYGEARA", "alpha", "beta");
                        //var CMLGEARA = aerodata.Add("ROLLING MOMENT INCREMENT DUE TO MAIN GEAR ASYMMETRY", "CMLGEARA", "alpha", "beta");
                        //var CMMGEARA = aerodata.Add("PITCHING MOMENT INCREMENT DUE TO MAIN GEAR ASYMMETRY", "CMMGEARA", "alpha", "beta");
                        //var CMNGEARA = aerodata.Add("YAWING MOMENT INCREMENT DUE TO MAIN GEAR ASYMMETRY", "CMNGEARA", "alpha", "beta");
                        //CFYGEARA.AddFactor("gear/gear-asym");
                        //CMLGEARA.AddFactor("gear/gear-asym");
                        //CMMGEARA.AddFactor("gear/gear-asym");
                        //CMNGEARA.AddFactor("gear/gear-asym");

                        // TANKS
            var CFXTNK = aerodata.Add("DRAG INCREMENT DUE TO TANK", "CFXTNK", "alpha", "beta");
            var CFZTNK = aerodata.Add("LIFT INCREMENT DUE TO TANK", "CFZTNK", "alpha", "beta");
            var CFYTNK = aerodata.Add("SIDE FORCE INCREMENT DUE TO TANK", "CFYTNK", "alpha", "beta");
            var CMLTNK = aerodata.Add("ROLLING MOMENT INCREMENT DUE TO TANK", "CMLTNK", "alpha", "beta");
            var CMMTNK = aerodata.Add("PITCHING MOMENT INCREMENT DUE TO TANK", "CMMTNK", "alpha", "beta");
            var CMNTNK = aerodata.Add("YAWING MOMENT INCREMENT DUE TO TANK", "CMNTNK", "alpha", "beta");
            CFXTNK.AddFactor("metrics/stores-tank-factor");
            CFZTNK.AddFactor("metrics/stores-tank-factor");
            CFYTNK.AddFactor("metrics/stores-tank-factor");
            CMLTNK.AddFactor("metrics/stores-tank-factor");
            CMMTNK.AddFactor("metrics/stores-tank-factor");
            CMNTNK.AddFactor("metrics/stores-tank-factor");

            //CMN1.AddFactor("EPA02S");
            //
            var CNDRDr = aerodata.Add("YAWING MOMENT DUE TO RUDDER DEFLECTION", "CMNDRDr", "alpha", "beta");
            CNDRDr.AddFactor("DRUDD,DRFLX3,EPA43");
            //
            //var CNDRDe = aerodata.Add("YAWING MOMENT DUE TO RUDDER DEFLECTION ELEVATOR INCREMENT -CNDRe", "CMNDRDe", "alpha", "beta", "elevator");
            //CNDRDe.AddFactor("DELEDD,DRFLX3,EPA43");
            //
            var CMNP = aerodata.Add("YAWING MOMENT DUE TO ROLL RATE", "CMNP", "alpha");
            CMNP.AddFactor("PB");
            //
            var CMNR = aerodata.Add("YAW DAMPING DERIVATIVE", "CMNR", "alpha");
            CMNR.AddFactor("RB");
            //
            var CNDTD = aerodata.Add("YAWING MOMENT DUE TO DIFFERENTIAL TAIL DEFLECTION", "CMNDTD", "alpha", "elevator");
            ////            CNDTD.AddFactor("DTFLX3,0.3,DTALD");
            CNDTD.AddFactor("DTFLX3,DTALD");
            //            //            var CNDAD = aerodata.Add("", "CNDAD", "alpha", "aileron");
            var CNDAD = aerodata.Add("YAWING MOMENT DUE TO AILERON DEFLECTION", "CMNDAD", "alpha", "beta");
            CNDAD.AddFactor("DDA");
            //
            //            var CNRB = aerodata.Add("ASYMMETRIC CN AT HIGH ALPHA", "CMNRB", "alpha", "beta");

            aerodata.AddConstant("DCNB", -2.5e-4);
            aerodata.AddConstant("DTFLX1", 0.975);
            aerodata.AddConstant("DRFLX1", 0.85);
            aerodata.AddConstant("DTFLX3", 0.975);
            aerodata.AddConstant("DRFLX3", 0.89);
            aerodata.AddConstant("DTFLX5", 0.975);
            aerodata.AddConstant("DRFLX5", 0.89);
            aerodata.AddConstant("EPA43", 1.00);
            //aerodata.AddVariable("DELEDD", "0.3*DDA");

            //F15_extra.AddExtra(aerodata);
            //            aerodata.Data["ClMach"].IsFactor = true;
            //            aerodata.Data["CdMach"].IsFactor = true;
            //            aerodata.Data["CyMach"].IsFactor = true;
            //            aerodata.Data["CLMach"].IsFactor = true;
            //            aerodata.Data["CMMach"].IsFactor = true;
            //            aerodata.Data["CNMach"].IsFactor = true;
            aerodata.Compute("LIFT", new[] { CFZB,
                CFZDF,
                CFZTNK,
                CFZGEAR,
//                                             aerodata.Data["ClUC"],
//                                             aerodata.Data["ClDFM"],
//                                             aerodata.Data["ClMach"],
//                                             aerodata.Data["DClRamp"],
                                              });
            aerodata.Compute("DRAG",
                                     new[] { CFXB,
                                         CFXDF,
                                         CFXTNK,
                                         CFXGEAR,
//                                     aerodata.Data["CdUC"],
//                                     aerodata.Data["CdDBRK"],
//                                     aerodata.Data["CdDFM"],
//                                     aerodata.Data["CdMach"],
//                                     aerodata.Data["DCdRamp"],
                                       });
            aerodata.Compute("SIDE",
                                     new[] { CFYB,
                                     CYDAD,
                                     CYDRD,
                                     CYDTD,
                                     //CYRB,
                                     CFYP,
                                     CFYR,
                                     CFYTNK,
                                     CFYGEAR,
//                                     CFYGEARA,
//                                     aerodata.Data["CyMach"] 
                                     });
            aerodata.Compute("ROLL",
                                     new[] { CML1,
                                     CLDAD,
                                     CLDRD,
                                     CLDTD,
                                     CMLP,
                                     CMLR,
                                     CMLTNK,
                                     CMLGEAR,
//                                     CMLGEARA,
//                                     DCLB,
//                                     aerodata.Data["CLMach"] 
                                     });
            aerodata.Compute("ROLL", "(DLNB*BETA)");
            aerodata.Compute("PITCH",
                                    new[] { CMM1,
                                     CMMQ,
                                     CMMTNK,
                                     CMMGEAR,
                                     CMMDF,
//                                     CMMGEARA,
//                                     aerodata.Data["DCMAIM"],
//                                     aerodata.Data["CMBRK"],
//                                     aerodata.Data["CMUC"],
//                                     aerodata.Data["CMDFM"],
//                                     aerodata.Data["CMMach"] ,
//                                     aerodata.Data["DCMRamp"],

                                    });
            aerodata.Compute("YAW",
                                     new[] { CMN1,
                                     CNDAD,
//                                     CNDRDe,
                                     CNDRDr,
                                     CNDTD,
                                     CMNP,
                                     CMNR,
                                     CMNTNK,
                                     CMNGEAR,
//                                     CMNGEARA,
//                                     CNRB,
//                                     aerodata.Data["CNMach"] 
                                     });
            aerodata.Compute("YAW", "(DCNB*BETA)");
            //aero/cadc-control-effectivity-factor
            //CNDAD.AddFactor("CEF");
            //CNDRDr.AddFactor("CEF");
            //CNDTD.AddFactor("CEF");
            //CMM1.AddFactor("CEF");
            //CML1.AddFactor("CEF");
            var DTOR = 180.0 / Math.PI;
            var DEGRAD = DTOR;

            var min_DELESD = -28;
            var max_DELESD = 16;
            min_DELESD = -30;
            max_DELESD = 30;
            var min_alpha = -20;
            var max_alpha = 60;
            var min_beta = -20;
            var max_beta = 20;
            var min_speedbrake = 0;
            var max_speedbrake = 45;

            var min_rudder = -30.0;
            var max_rudder = 30.0;
            //var mn = 0.3;
            var mns = new[] { 0.3, 1.0 };
            mns = new[] { 0.6 };
            //mns = new [] {0.3,1.2};
            Directory.SetCurrentDirectory(dir);
            var betas = new[] { -20, -10, -5, 0, 5, 10, 20 };
            var alphas = new[] { -60, -10, -5, 0, 5, 10, 12, 15, 20, 30, 35, 40 };
            alphas = new[] { -5, 0, 5, 30 };
            //alphas = new [] {-30,-20,-15,-10,-5,-4,-3,-2,-1,0,1,2,3,4,5,10,15,20,25,30,35,40,45,50,55,60};
            alphas = new[] { -30, -20, -15, -10, -5, 0, 5, 10, 15, 20, 23, 25, 30, 35, 40, 50 };
            alphas = new[] { -10, -5, 0, 5, 10, 15, 20, 25, 30, 35, 40, 50 };
            betas = new[] { -10, 0, 10 };
            //betas = new [] {-50,-20,-15,-10,-5,-4,-3,-1,0,1,2,3,4,5,10,15,20,50};
            betas = new[] { -20, -15, -10, -5, 0, 5, 10, 15, 20 };

            alphas = new[] { -10, 0, 10, 20, 30, 40, 50, 60, };
            alphas = new[] { -10, 0, 10, 15, 30, 40, 50, 60, 70 };

            alphas = new[] { -20, -10, 0, 10, 20, 30, 40, 50, 60, 70 };
            betas = new[] { -10, 0, 10 };
            betas = new[] { -20, -10, 0, 10, 20 };
            //betas = new [] {0};
            alphas = new[] { -10, 0, 10, 20, 30 };
            alphas = new[] { -10, 0,2,4,6,8,10,12,14,15,17,20,25, 30 };
            betas = new[] { -10, 0,1,2,3,4,5, 10 };

            //
            // for the tailplane (stabilator) we will need to have geometries
            // at 0 -> max incidence in increments so the stall is modelled.
            var geoms = new[] {
"F-15-all-wing5",
"F-15-gear",
//"F-15-gear-noleft",
"F-15-aileron-down-40",
"F-15-rudder-right-30",
"F-15-stab-10diff",
"F-15-stab-10down",
"F-15-stab-10up",
"F-15-stab-15down",
"F-15-stab-20down",
"F-15-stab-15up",
"F-15-stab-30down",
"F-15-tanks",

//       "F-15-tanks",
//        "F-15-aileron-down-40",
//        "F-15-aileron-up-40",
//        "F-15-rudder-right-30",
//        "F-15-stab-20down",
//        "F-15-stab-20up",
};
            var calc = true;
            var total = betas.Length * alphas.Length * mns.Length * geoms.Length;
            int count = 0;
            var gen_stab = true;
            foreach (var mn in mns)
            {
                //    for(var alpha = -5; alpha <= 15; alpha+=5)
                foreach (var alpha in alphas)
                {
                    foreach (var beta in betas)
                    {
                        foreach (var geom in geoms)
                        {
                            count++;
                            if (calc)
                            {

                                System.Console.WriteLine("Geom {0} a={1} b={2} mn={3} : {4} of {5}", geom, alpha, beta, mn, count, total);
                                run_vsp(mn, alpha, beta, geom);
                            }
                        }
                        //if (beta == 0)
                            run_vsp(mn, alpha, beta, "F-15-flaps-35");

                        if (gen_stab && beta == 0)
                            run_vsp(mn, alpha, beta, geoms[0], true);
                        
                        var ah = load_tables(mn, alpha, beta, geoms[0]);
                        //var CML1 = aerodata.Add("BASIC ROLLING MOMENT - CL(BETA)", "CML1", "alpha", "beta");
                        //var CMN1 = aerodata.Add("BASIC YAWING MOMENT - CN (BETA)", "CMN1", "alpha", "beta");
                        //var CMN1 = aerodata.Add("BASIC YAWING MOMENT - CN (BETA)", "CMN1", "alpha", "beta", "elevator");
                        //var CNRB = aerodata.Add("ASYMMETRIC CN AT HIGH ALPHA", "CMNRB", "alpha", "beta");
                        //var CYRB = aerodata.Add("ASYMMETRIC CY AT HIGH ALPHA", "CYRB", "alpha", "beta");
                        //var DCLB = aerodata.Add("DELTA CLB DUE TO 2-PLACE CANOPY", "CMLDCLB", "alpha");

                        CML1.Add(alpha, beta, ah.CL);
                        //CMNt.Add(alpha, beta, ah.CN);
                        //CFZBt.Add(alpha, beta, ah.Cl); 
                        var ah_de_d10 = load_tables(mn, alpha, beta, "F-15-stab-10down");
                        var ah_de_d15 = load_tables(mn, alpha, beta, "F-15-stab-15down");
                        var ah_de_d20 = load_tables(mn, alpha, beta, "F-15-stab-20down");
                        var ah_de_d30 = load_tables(mn, alpha, beta, "F-15-stab-30down");
                        var ah_de_u10 = load_tables(mn, alpha, beta, "F-15-stab-10up");
                        var ah_de_u15 = load_tables(mn, alpha, beta, "F-15-stab-15up");

                        CFXB.Add(alpha, beta, -30, ah_de_d30.Cd);
                        CFXB.Add(alpha, beta, -20, ah_de_d20.Cd);
                        CFXB.Add(alpha, beta, -15, ah_de_d15.Cd);
                        CFXB.Add(alpha, beta, -10, ah_de_d10.Cd);
                        CFXB.Add(alpha, beta,  0, ah.Cd);
                        CFXB.Add(alpha, beta, 10, ah_de_u10.Cd);
                        CFXB.Add(alpha, beta, 15, ah_de_u15.Cd);

                        CFZB.Add(alpha, beta, -30, ah_de_d30.Cl);
                        CFZB.Add(alpha, beta, -20, ah_de_d20.Cl);
                        CFZB.Add(alpha, beta, -15, ah_de_d15.Cl);
                        CFZB.Add(alpha, beta, -10, ah_de_d10.Cl);
                        CFZB.Add(alpha, beta, 0, ah.Cl);
                        CFZB.Add(alpha, beta, 10, ah_de_u10.Cl);
                        CFZB.Add(alpha, beta, 15, ah_de_u15.Cl);

                        //var CFYB = aerodata.Add("BASIC SIDE FORCE", "CFYB", "alpha", "beta", "elevator");
                        CFYB.Add(alpha, beta, -30, ah_de_d30.Cy);
                        CFYB.Add(alpha, beta, -20, ah_de_d20.Cy);
                        CFYB.Add(alpha, beta, -15, ah_de_d15.Cy);
                        CFYB.Add(alpha, beta, -10, ah_de_d10.Cy);
                        CFYB.Add(alpha, beta, 0, ah.Cy);
                        CFYB.Add(alpha, beta, 10, ah_de_u10.Cy);
                        CFYB.Add(alpha, beta, 15, ah_de_u15.Cy);

                        //var CMM1 = aerodata.Add("BASIC PITCHING MOMENT - CM", "CMM1", "alpha", "elevator");
                        if (beta == 0)
                        {
                            CMM1.Add(alpha, -30, ah_de_d30.CM);
                            CMM1.Add(alpha, -20, ah_de_d20.CM);
                            CMM1.Add(alpha, -15, ah_de_d15.CM);
                            CMM1.Add(alpha, -10, ah_de_d10.CM);
                            CMM1.Add(alpha,  0, ah.CM);
                            CMM1.Add(alpha, 10, ah_de_u10.CM);
                            CMM1.Add(alpha, 15, ah_de_u15.CM);
                        }
                        //var CYDRD = aerodata.Add("SIDE FORCE DUE TO RUDDER DEFLECTION", "CYDRD", "alpha", "beta", "rudder");
                        //var CYDRD = aerodata.Add("SIDE FORCE DUE TO RUDDER DEFLECTION", "CYDRD", "alpha", "rudder");
                        //CYDRD.Add(alpha, beta, -20, ah_de_20d.Cy - ah.Cy);
                        //CYDRD.Add(alpha, beta, -15, ah_de_15d.Cy - ah.Cy);
                        //CYDRD.Add(alpha, beta, -10, ah_de_10d.Cy - ah.Cy);
                        //CYDRD.Add(alpha, beta, 10, ah_de_10u.Cy - ah.Cy);
                        //CYDRD.Add(alpha, beta, 20, ah_de_20u.Cy - ah.Cy);
                        //CYDRD.Add(alpha, beta, 30, ah_de_30u.Cy - ah.Cy);

                        //    if (beta == 0)
                        //    {
                        //    CLDRD.Add(alpha, -20, ah_de_20d.CL-ah.CL);
                        //    CLDRD.Add(alpha, -15, ah_de_15d.CL-ah.CL);
                        //    CLDRD.Add(alpha, -10, ah_de_10d.CL-ah.CL);
                        //    CLDRD.Add(alpha,  10, ah_de_10u.CL-ah.CL);
                        //    CLDRD.Add(alpha,  20, ah_de_20u.CL-ah.CL);
                        //    CLDRD.Add(alpha,  30, ah_de_30u.CL-ah.CL);
                        //    }
                        //var CNDRDe = aerodata.Add("YAWING MOMENT DUE TO RUDDER DEFLECTION ELEVATOR INCREMENT -CNDRe", "CMNDRDe", "alpha", "beta", "elevator");
                        CMN1.Add(alpha, beta, -30, ah_de_d30.CN);
                        CMN1.Add(alpha, beta, -20, ah_de_d20.CN);
                        CMN1.Add(alpha, beta, -15, ah_de_d15.CN);
                        CMN1.Add(alpha, beta, -10, ah_de_d10.CN);
                        CMN1.Add(alpha, beta,   0, ah.CN);
                        CMN1.Add(alpha, beta,  10, ah_de_u10.CN);
                        CMN1.Add(alpha, beta,  15, ah_de_u15.CN);

                        //var CNDRDr = aerodata.Add("YAWING MOMENT DUE TO RUDDER DEFLECTION -CNDR", "CMNDRDr", "alpha", "beta");
                        var ah_drd = load_tables(mn, alpha, beta, "F-15-rudder-right-30");
                        CNDRDr.Add(alpha, beta, (ah_drd.CN - ah.CN) / 30.0);
                        CYDRD.Add(alpha, beta, (ah_drd.Cy - ah.Cy) / 30.0);
                        CLDRD.Add(alpha, beta, (ah_drd.CL - ah.CL) / 30.0);

                        var ah_dtd_10 = load_tables(mn, alpha, beta, "F-15-stab-10diff");
                        //var CYDTD = aerodata.Add("SIDE FORCE DUE TO DIFFERETIAL TAIL DEFLECTION - CYDTD", "CYDTD", "alpha", "elevator");
                        //var CLDTD = aerodata.Add("ROLLING MOMENT DUE TO DIFFERENTIAL TAIL DEFLECTION - CLDD", "CMLDTD", "alpha", "elevator");
                        //var CNDTD = aerodata.Add("YAWING MOMENT DUE TO DIFFERENTIAL TAIL DEFLECTION - CNDDT", "CMNDTD", "alpha", "elevator");
                        CYDTD.Add(alpha, beta, (ah_dtd_10.Cy - ah.Cy) / 10.0);
                        CLDTD.Add(alpha, beta, (ah_dtd_10.CL - ah.CL) / 10.0);
                        CNDTD.Add(alpha, beta, (ah_dtd_10.CN - ah.CN) / 10.0);

                        var ahtank = load_tables(mn, alpha, beta, "F-15-tanks");
                        //var CFXTNK = aerodata.Add("DRAG INCREMENT DUE TO TANK CFXTNK(ALPHA,BETA)", "CFXTNK", "alpha", "beta");
                        //var CFYTNK = aerodata.Add("SIDE FORCE INCREMENT DUE TO TANK CFYTNK(ALPHA,BETA)", "CFYTNK", "alpha", "beta");
                        //var CFZTNK = aerodata.Add("LIFT INCREMENT DUE TO TANK CFZTNK(ALPHA,BETA)", "CFZTNK", "alpha", "beta");
                        //var CMLTNK = aerodata.Add("ROLLING MOMENT INCREMENT DUE TO TANK CMLTNK(ALPHA,BETA)", "CMLTNK", "alpha", "beta");
                        //var CMMTNK = aerodata.Add("PITCHING MOMENT INCREMENT DUE TO TANK CMMTNK(ALPHA,BETA)", "CMMTNK", "alpha", "beta");
                        //var CMNTNK = aerodata.Add("YAWING MOMENT INCREMENT DUE TO TANK CMNTNK(ALPHA,BETA)", "CMNTNK", "alpha", "beta");
                        CFXTNK.Add(alpha, beta, ahtank.Cd - ah.Cd);
                        CFYTNK.Add(alpha, beta, ahtank.Cy - ah.Cy);
                        CFZTNK.Add(alpha, beta, ahtank.Cl - ah.Cl);

                        CMLTNK.Add(alpha, beta, ahtank.CL - ah.CL);
                        CMMTNK.Add(alpha, beta, ahtank.CM - ah.CM);
                        CMNTNK.Add(alpha, beta, ahtank.CN - ah.CN);

                        if (alpha < 70) // temporary to remove the big peak at the end.
                        {
                            var ah_gear = load_tables(mn, alpha, beta, "F-15-gear");
                            CFXGEAR.Add(alpha, beta, ah_gear.Cd - ah.Cd);
                            CFYGEAR.Add(alpha, beta, ah_gear.Cy - ah.Cy);
                            CFZGEAR.Add(alpha, beta, ah_gear.Cl - ah.Cl);

                            CMLGEAR.Add(alpha, beta, ah_gear.CL - ah.CL);
                            CMMGEAR.Add(alpha, beta, ah_gear.CM - ah.CM);
                            CMNGEAR.Add(alpha, beta, ah_gear.CN - ah.CN);

                            //var ah_geara = load_tables(mn, alpha, beta, "F-15-gear-noleft");
                            ////CFXGEARA.Add(alpha, beta, ah_geara.Cd - ah.Cd);
                            //CFYGEARA.Add(alpha, beta, ah_geara.Cy - ah.Cy);
                            ////CFZGEARA.Add(alpha, beta, ah_geara.Cl - ah.Cl);

                            //CMLGEARA.Add(alpha, beta, ah_geara.CL - ah.CL);
                            //CMMGEARA.Add(alpha, beta, ah_geara.CM - ah.CM);
                            //CMNGEARA.Add(alpha, beta, ah_geara.CN - ah.CN);
                        }
                        var ah_ail_down_40 = load_tables(mn, alpha, beta, "F-15-aileron-down-40");
                        //var CNDAD = aerodata.Add("", "CNDAD", "alpha", "aileron");
                        //var CNDAD = aerodata.Add("YAWING MOMENT DUE TO AILERON DEFLECTION -CNDA", "CMNDAD", "alpha", "beta");
                        //var CYDAD = aerodata.Add("SIDE FORCE DUE TO AILERON DEFLECTION", "CYDAD", "alpha", "beta");
                        //var CLDAD = aerodata.Add("ROLLING MOMENT DUE TO AILERON DEFLECTION (CLDA)", "CMLDAD", "alpha", "beta");
                        CLDAD.Add(alpha, beta, (ah_ail_down_40.CL - ah.CL) / 40.0);
                        CYDAD.Add(alpha, beta, (ah_ail_down_40.Cy - ah.Cy) / 40.0);
                        CNDAD.Add(alpha, beta, (ah_ail_down_40.CN - ah.CN) / 40.0);

                        //var CFYP = aerodata.Add("SIDE FORCE DUE TO ROLL RATE (CYP)", "CFYP", "alpha");
                        //var CFYR = aerodata.Add("SIDE FORCE DUE TO YAW RATE (CYR)", "CFYR", "alpha");
                        //var CMLP = aerodata.Add("ROLL DAMPING DERIVATIVE - CLP", "CMLP", "alpha");
                        //var CMLR = aerodata.Add("ROLLING MOMENT DUE TO YAW RATE - CLR", "CMLR", "alpha");
                        //var CMMQ = aerodata.Add("PITCH DAMPING DERIVATIVE - CMQ", "CMMQ", "alpha");
                        //var CMNP = aerodata.Add("YAWING MOMENT DUE TO ROLL RATE - CNP", "CMNP", "alpha");
                        //var CMNR = aerodata.Add("YAW DAMPING DERIVATIVE - CMNR", "CMNR", "alpha");
                        if (beta == 0)
                        {
//                            var ad = load_deriv(0.6, alpha, beta, geoms[0]);
                            var ad = load_deriv(0.6, alpha, beta, geoms[0]);
                            CFYP.Add(alpha, ad.CFYP);
                            CFYR.Add(alpha, ad.CFYR);
                            CMLP.Add(alpha, ad.CMLP);
                            CMLR.Add(alpha, ad.CMLR);
                            CMMQ.Add(alpha, ad.CMMQ);
                            CMNR.Add(alpha, ad.CMNR);
                            CMNP.Add(alpha, ad.CMNP);

                        }
                        var ah_flaps = load_tables(mn, alpha, beta, "F-15-flaps-35");
                        CFZDF.Add(alpha, beta, ah_flaps.Cl - ah.Cl);
                        CFXDF.Add(alpha, beta, ah_flaps.Cd - ah.Cd);
                        CMMDF.Add(alpha, beta, ah_flaps.CM - ah.CM);


                    }
                }
            }
            gen_stab = false;
        }


        AeroDerivative load_deriv(double mn, double alpha, double beta, string geom)
        {

            geom = geom + "_DegenGeom";
            var bfn = string.Format("{0}_{1}_a{2}_b{3}", geom, mn, alpha, beta);
            var ofn = dir + string.Format(op_dir + "{0}", bfn);
            var lines = File.ReadAllLines(ofn + "_stab.txt");
            var idx = new Dictionary<string, int>();
            var ah = new AeroDerivative();
            //l.Dump();
            var have_coeffs = false;
            foreach (var l in lines)
            {
                if (l.Trim() == "")
                    break;
                if (l.Trim().StartsWith("#             Coef"))
                {
                    var idxl = l.Split(new[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries);
                    for (var ii = 0; ii < idxl.Length; ii++)
                        idx[idxl[ii]] = ii;
                    have_coeffs = true;
                }
                else if (have_coeffs)
                {
                    //#            0Coef        1Alpha       2Beta         3p           4q           5r          6Mach        7U    
                    //CFx      -0.0652028    9.0246182   -0.8617550    6.8750638 -106.5398688  -44.0891545    0.0041260    0.0024756 
                    //CFy       0.0017999   -7.0572033   -5.1444271   19.4916641   28.9966024  -88.7357462   -0.0228039   -0.0136824 
                    //CFz      -0.5654808   11.5603950   -1.7346100   27.9581951 -376.7536745 -113.8806966    0.0184653    0.0110792 
                    //CMx       0.0016152    7.2807800   -1.2759314   -8.3149486  -54.8442662  -55.4007156   -0.0506541   -0.0303924 
                    //CMy       0.1768580   71.6846304   -7.2444172 -562.9864641 -451.3010036 -371.3820166   -0.2637537   -0.1582522 
                    //CMz       0.0019085   -8.4409362   -0.6994245 -182.1331594  -44.4843076  -76.7317111   -0.0138352   -0.0083011 
                    //CL       -0.5682122   12.9063606   -1.8578995   28.7272896 -389.5303923 -119.8065934    0.0189013    0.0113408 
                    //CD        0.0339824    6.3344261   -0.5403012    1.9157276  -39.4987139  -23.6441701    0.0008569    0.0005141 
                    //CS        0.0017999   -7.0572033   -5.1113939   19.4916641   28.9966024  -88.7357462   -0.0228039   -0.0136824 

                    var vals = l.Split(new[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries);
                    //System.Console.WriteLine(l);
                    //if (vals[0] == "CFy")
                    if (vals[0] == "CS")
                    {
                        ah.CFYP = Double.Parse(vals[idx["p"]]);
                        ah.CFYR = Double.Parse(vals[idx["r"]]);
                    }
                    if (vals[0] == "CMx")
                    {
                        ah.CMLP = Double.Parse(vals[idx["p"]]);
                        ah.CMLR = Double.Parse(vals[idx["r"]]);
                    }
                    if (vals[0] == "CMy")
                    {
                        ah.CMMQ = Double.Parse(vals[idx["q"]]);
                    }
                    if (vals[0] == "CL")
                    {
                        ah.CMNR = Double.Parse(vals[idx["r"]]);
                        ah.CMNP = Double.Parse(vals[idx["p"]]);
                    }
                }
            }
            ah.breakpoints = string.Format("Alpha={1} Beta={2}", mn, alpha, beta);
            return ah;
        }
        AeroHex load_tables(double mn, double alpha, double beta, string geom)
        {
            geom = geom + "_DegenGeom";
            var bfn = string.Format("{0}_{1}_a{2}_b{3}", geom, mn, alpha, beta);
            var ofn = dir + string.Format(op_dir + "{0}", bfn);
            var lines = File.ReadAllLines(ofn + ".txt");
            var idx = new Dictionary<string, int>();
            var ah = new AeroHex();
            //l.Dump();
            foreach (var l in lines)
            {
                if (l.Trim() == "")
                    break;
                if (l.Trim().StartsWith("Iter"))
                {
                    var idxl = l.Split(new[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries);
                    for (var ii = 0; ii < idxl.Length; ii++)
                        idx[idxl[ii]] = ii;
                }
                else
                {
                    var vals = l.Split(new[] { ' ', '\t' }, StringSplitOptions.RemoveEmptyEntries);
                    //System.Console.WriteLine(l);
                    ah.Cl = Double.Parse(vals[idx["CL"]]);
                    ah.Cd = Double.Parse(vals[idx["CDtot"]]);
                    ah.Cy = Double.Parse(vals[idx["CS"]]);

                    //ah.Cd = Double.Parse(vals[idx["CFx"]]);
                    //ah.Cl = Double.Parse(vals[idx["CFz"]]);
                    //ah.Cy = Double.Parse(vals[idx["CFy"]]);
                    ah.CL = Double.Parse(vals[idx["CMx"]]);
                    ah.CM = Double.Parse(vals[idx["CMy"]]);
                    ah.CN = Double.Parse(vals[idx["CMz"]]);
                }
            }
            ah.breakpoints = string.Format("Mn={0} Alpha={1} Beta={2}", mn, alpha, beta);
            //ah.Dump();
            if (double.IsNaN(ah.Cl))
            {
                System.Console.WriteLine("error {0}.txt", ofn);
                System.Console.WriteLine("Cd={0} Cl={1} Cy={2} : CL={3} CM={4} CN={5}", ah.Cd, ah.Cl, ah.Cy, ah.CL, ah.CM, ah.CN);
            }
            if (beta == 0)
            {
                ah.CN = 0;
                ah.Cy = 0;
            }
            return ah;
            //idx[l.Split(),
            //var PB = aerodata.Add("Pressure at burner PB(n1,mach)", "PB", "propulsion/engines[0]/n1","mach");
            //PB.Add(0,0,1.1);
            //PB.Add(8,0,1.09966);
        }
        void run_vsp(double mn, double alpha, double beta, string geom, bool stab = false)
        {
            if (!can_calc)
                return;
            geom = geom + "_DegenGeom";
            var args = String.Format("-omp 12 -fs {0} {1} {2} {3}", mn, alpha, beta, geom);
            var stab_fn = "";
            var wake_iters = 3;
            //if (alpha > 13 || alpha < -10) wake_iters = 5;
            //wake_iters = 3;
            if (stab)
            {
                args = "-stab " + args;
                stab_fn = "_stab";
                wake_iters = 1;
            }
            var bfn = string.Format("{0}_{1}_a{2}_b{3}", geom, mn, alpha, beta);

            var ofn = dir + string.Format(op_dir + "{0}{1}.txt", bfn, stab_fn);
            if (!File.Exists(ofn))
            {
                File.WriteAllText(dir + geom + ".vspaero", string.Format(@"Sref = 72.213532 
Cref = 8.959206 
Bref = 11.299664 
X_cg = 10.5
Y_cg = 0.000000 
Z_cg = 0.0 
Mach = {0}
AoA = {1}
Beta = {2}
Vinf = 100.000000 
Rho = 0.002377 
ReCref = 10000000.000000 
ClMax = 1.73326072
MaxTurningAngle = -1.000000 
Symmetry = No 
FarDist = 31.000000 
NumWakeNodes = -1 
WakeIters = {3}
NumberOfRotors = 0 
", mn, alpha, beta, wake_iters));
                //File.WriteAllText(dir+geom+".vspaero", string.Format(@"Sref = 56.055
                //Cref = 3.514
                //Bref = 13.09
                //X_cg = 10.3632
                //Y_cg = 0 
                //Z_cg = 0
                //Mach = 0.300000 
                //AoA = {0}
                //Beta = {1}
                //Vinf = 100.000000 
                //Rho = 0.002377 
                //ReCref = 10000000.000000 
                //ClMax = 1.97452423 
                //MaxTurningAngle = -1.000000 
                //Symmetry = No 
                //FarDist = -1.000000 
                //NumWakeNodes = -1 
                //WakeIters ={2}
                //NumberOfRotors = 0 ",alpha, beta, wake_iters));
                //
                //File.WriteAllText(dir+geom+".vspaero", string.Format(@"Sref = 28.678366 
                //Cref = 4.858512
                //Bref = 13.04544
                //X_cg = 10.3632
                //Y_cg = 0 
                //Z_cg = 0
                //Mach = 0.300000 
                //AoA = {0}
                //Beta = {1}
                //Vinf = 100.000000 
                //Rho = 0.002377 
                //ReCref = 10000000.000000 
                //ClMax = 1.97452423 
                //MaxTurningAngle = -1.000000 
                //Symmetry = No 
                //FarDist = -1.000000 
                //NumWakeNodes = -1 
                //WakeIters ={2}
                //NumberOfRotors = 0 ", 
                //alpha, beta, wake_iters));
                var p = System.Diagnostics.Process.Start("vspaero.exe", args);
                p.WaitForExit();
                if (!stab)
                {
                    var lines = File.ReadAllLines(dir + geom + ".history");
                    File.WriteAllLines(ofn, lines);
                    System.Console.WriteLine("Created {0}", ofn);
                    File.Delete(op_dir + "" + bfn + stab_fn + ".adb");
                    File.Move(geom + ".adb", op_dir + "" + bfn + stab_fn + ".adb");
                }
                else
                {
                    File.Move(geom + ".stab", op_dir + "" + bfn + stab_fn + ".txt");
                    System.Console.WriteLine("Created {0}", ofn);
                }

            }
        }
    }
}