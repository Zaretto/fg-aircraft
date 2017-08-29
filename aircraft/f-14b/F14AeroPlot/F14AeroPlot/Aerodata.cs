using System;
using System.Collections.Generic;
using System.Linq;

namespace F14AeroPlot
{
    public class Aerodata
    {
        public Dictionary<string, List<DataElement>> ComputeElems = new Dictionary<string, List<DataElement>>();

        public Dictionary<string, List<string>> ComputeExtra = new Dictionary<string, List<string>>();

        public Dictionary<String, double> Constants = new Dictionary<string, double>();

        public Dictionary<string, DataElement> Data = new Dictionary<string, DataElement>();

        public List<Engine> Engines = new List<Engine>();

        public List<ExternalForce> ExternalReactions = new List<ExternalForce>();

        public List<GroundReactionElement> GroundReactions = new List<GroundReactionElement>();

        public List<PointMassElement> Mass = new List<PointMassElement>();

        public List<string> Notes = new List<string>();

        public List<ReferenceDocument> References = new List<ReferenceDocument>();

        public List<string> Systems = new List<string>();

        public List<Tank> Tanks = new List<Tank>();

        public Dictionary<String, String> Variables = new Dictionary<string, String>();

        public Aerodata()
        {
            Aliases = new Dictionary<string, string>();
            Aliases.Add("P", "velocities/p-aero-rad_sec");
            Aliases.Add("Q", "velocities/q-aero-rad_sec");
            Aliases.Add("R", "velocities/r-aero-rad_sec");

            Aliases.Add("PB", "aero/pb");
            Aliases.Add("QB", "aero/qb");
            Aliases.Add("RB", "aero/rb");

            Aliases.Add("alpha", "aero/alpha-deg");
            Aliases.Add("beta", "aero/beta-deg");
            Aliases.Add("elevator", "fcs/elevator-pos-deg");
            Aliases.Add("rudder", "fcs/rudder-pos-deg");
            Aliases.Add("aileron", "fcs/aileron-pos-deg");
            Aliases.Add("mach", "velocities/mach");
            Aliases.Add("slats", "fcs/slat-pos-norm-deg");
            Aliases.Add("flaps", "fcs/flap-pos-deg");
            Aliases.Add("speedbrake", "fcs/speedbrake-pos-norm");
            Aliases.Add("gear", "gear/gear-pos-norm");
        }
        public Location AERORP { get; set; }

        public string AircraftType { get; set; }

        public Dictionary<string, string> Aliases { get; set; }

        public Location CG { get; set; }

        public DenominatedAmount chord { get; set; }

        public string Description { get; set; }

        public DenominatedAmount EmptyWeight { get; set; }

        public Location EyePoint { get; set; }

        public decimal? FuelDumpRate { get; set; }

        public DenominatedAmount IXX { get; set; }

        public DenominatedAmount IXZ { get; set; }

        public DenominatedAmount IYY { get; set; }

        public DenominatedAmount IZZ { get; set; }

        public string SubTitle { get; set; }

        public string Title { get; set; }

        public Location VRP { get; set; }

        public DenominatedAmount wing_incidence { get; set; }

        public DenominatedAmount WingArea { get; set; }
        public DenominatedAmount wingspan { get; set; }
        public DataElement Add(string title, string element, string iv1, string iv2 = null, string iv3 = null)
        {
            var ne = new DataElement(iv1, iv2, iv3)
            {
                Title = title,
                Variable = element,
            };
            Data[element] = ne;
            return ne;
        }

        public void AddConstant(string p1, double val)
        {
            Constants[p1] = val;
        }

        public void AddDataPoint(string element, double iv1, double iv2, double iv3, double v)
        {
            Data[element].Add(iv1, iv2, iv3, v);
        }

        public void AddTank(Tank t)
        {
            t.Id = Tanks.Count;
            Tanks.Add(t);
        }

        public void AddVariable(string p1, string p2)
        {
            Variables[p1] = p2;
        }

        public void Compute(string axis, DataElement[] dataElement)
        {
            if (!ComputeElems.ContainsKey(axis))
                ComputeElems[axis] = new List<DataElement>();
            foreach (var el in dataElement)
            {
                ComputeElems[axis].Add(el);
                el.Axis = axis;
            }
            // Add list of elements to axis
        }

        public void Compute(string axis, string p2)
        {
            foreach (var el in p2.Split(','))
            {
                ComputeExtra[axis] = new List<string>();
                ComputeExtra[axis].Add(el);
            }
        }
        public string GetCompute(string axis)
        {
            var s1 = axis + "=" + String.Join("+", ComputeElems[axis].Where(xx => !xx.IsFactor).Select(xx => xx.GetComputeValue(this)));
            var factors = ComputeElems[axis].Where(xx => xx.IsFactor);
            if (factors.Any())
                s1 = s1 + " *" + String.Join("*", factors.Select(xx => xx.GetComputeValue(this)));
            string s2 = "";
            if (ComputeExtra.ContainsKey(axis))
                s2 = String.Join("+", ComputeExtra[axis]);
            if (!String.IsNullOrEmpty(s2))
                return s1 + " + " + s2;
            return s1;
        }

        public Dictionary<string, string> GetCompute()
        {
            var rv = new Dictionary<string, string>();
            foreach (var axis in ComputeElems)
            {
                rv[axis.Key] = GetCompute(axis.Key);
            }
            return rv;
        }
        public bool Is2d(DataElement aero_element)
        {
            return aero_element.IndependentVars.Count == 2;
        }

        public bool Is3d(DataElement aero_element)
        {
            return aero_element.IndependentVars.Count == 3;
        }

        public bool IsUsed(DataElement aero_element)
        {
            return aero_element.data.Any();
        }

        public string Lookup(string coeff)
        {
            if (Constants.ContainsKey(coeff))
                return Constants[coeff].ToString() + String.Format(" <!-- {0} -->", coeff);
            if (Variables.ContainsKey(coeff))
                coeff = Variables[coeff];
            if (Aliases.ContainsKey(coeff))
                coeff = Aliases[coeff];
            return coeff;
        }
        /// <summary>
        /// If the value looked up is a numeric constant then convert and return as a double
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>

        internal double? LookupValue(string name)
        {
            double v;
            if (Char.IsDigit(name.Trim()[0]))
            {
                if (Double.TryParse(name.TruncateAt(" "), out v))
                    return v;
                else
                    return null;
            }
            return null;
        }
    }

    public class BreakPoint
    {
        //    const int MaxDimensions = 3;
        public Double[] data;

        public string description;

        public Double iv1, iv2, iv3;

        public Double Value;

        public BreakPoint(DataElement parent, double iv1, double v)
        {
            Parent = parent;
            data = new Double[1];
            data[0] = iv1;
            this.iv1 = iv1;
            Value = v;
        }

        public BreakPoint(DataElement parent, double iv1, double iv2, double v)
        {
            Parent = parent;
            data = new Double[2];
            data[0] = iv1;
            data[1] = iv2;
            this.iv1 = iv1;
            this.iv2 = iv2;
            Value = v;
        }

        public BreakPoint(DataElement parent, double iv1, double iv2, double iv3, double v)
        {
            Parent = parent;
            data = new Double[3];
            data[0] = iv1;
            data[1] = iv2;
            data[2] = iv3;
            this.iv1 = iv1;
            this.iv2 = iv2;
            this.iv3 = iv3;
            Value = v;
        }
        public DataElement Parent { get; set; }
    }

    public class DataElement
    {
        public string Axis;

        public List<String> Components = new List<string>();

        public List<BreakPoint> data = new List<BreakPoint>();

        public string description;

        public List<String> Factors = new List<string>();

        public List<String> IndependentVars = new List<string>();

        public DataElement(string iv1, string iv2 = null, string iv3 = null)
        {
            IndependentVars.Add(iv1);
            if (iv2 != null)
                IndependentVars.Add(iv2);
            if (iv3 != null)
                IndependentVars.Add(iv3);
        }
        public string Description
        {
            get
            {
                if (!String.IsNullOrEmpty(description)) return description;
                return string.Join(" ", IndependentVars);
            }
        }

        public bool Is2d { get { return IndependentVars.Count == 2; } }

        public bool IsFactor { get; set; }

        public string Title { get; set; }

        public string Variable { get; set; }

        public void Add(double iv1, double v)
        {
            data.Add(new BreakPoint(this, iv1, v));
        }

        public void Add(double iv1, double iv2, double v)
        {
            data.Add(new BreakPoint(this, iv1, iv2, v));
        }

        public void Add(double iv1, double iv2, double iv3, double v)
        {
            data.Add(new BreakPoint(this, iv1, iv2, iv3, v));
        }

        public string GetComputeValue(Aerodata aero)
        {
            var vals = new List<String>();
            vals.Add(Variable);
            foreach (var xx in Factors)
            {
                if (aero != null)
                {
                    var name = aero.Lookup(xx);
                    var v = aero.LookupValue(xx);
                    if (v.HasValue)
                    {
                        vals.Add(v.ToString());
                    }
                    else
                    {
                        vals.Add(xx);
                    }
                }
                else
                    vals.Add(xx);
            }
            return string.Join("*", vals);
        }

        public object TwoD()
        {
            return data.GroupBy(xx => xx.iv1).Select(xx => new { xx.Key, Val = String.Join(",", xx.Select(yy => yy.Value)) });
        }
        internal void AddComponent(string p)
        {
            foreach (var f in p.Split(','))
                Components.Add(f);
        }

        internal void AddFactor(string p)
        {
            foreach (var f in p.Split(','))
                Factors.Add(f);
        }
        internal string GetVariable()
        {
            if (Variable.Contains("/"))
                return Variable;
            else return "aero/coefficients/" + Variable;
        }
    }

    public class ReferenceDocument
    {
        public string Author { get; set; }

        public string Date { get; set; }

        public string Id { get; set; }
        public string Title { get; set; }
        public string Url { get; set; }
    };
}