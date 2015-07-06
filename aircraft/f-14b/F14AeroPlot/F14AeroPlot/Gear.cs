using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;

namespace F14AeroPlot
{
    public class Gear: GroundReactionElement
    {
        public Gear(Aerodata a):base(a)
        {
            MaxSteer = new DenominatedAmount(0, "DEG");
            dynamic_friction = new DenominatedAmount(0.5,null);
            rolling_friction = new DenominatedAmount(0.02,null);
            static_friction = new DenominatedAmount(0.8, null);
            spring_coeff = new DenominatedAmount(a.EmptyWeight.Amount * 0.9,  "LBS/FT");
            damping_coeff = new DenominatedAmount(a.EmptyWeight.Amount * 0.05, "LBS/FT/SEC");
        }
        public DenominatedAmount MaxSteer { get; set; }

        public string BrakeGroup { get; set; }

        public bool Retractable = true;
        internal override XmlElement CreateXmlNodes(System.Xml.XmlDocument doc, System.Xml.XmlElement grnode)
        {
            var xe = base.CreateXmlNodes(doc, grnode);
            xe.SetAttribute("type", "BOGEY");
            xe.AppendChild(MaxSteer.CreateXmlNode(doc, "max_steer"));

            if (!string.IsNullOrEmpty(BrakeGroup))
            {
                XmlElement bg = doc.CreateElement("brake_group");
                xe.AppendChild(bg);
                bg.InnerText = BrakeGroup;
            }
            if (Retractable)
            {
                var re = doc.CreateElement("retractable");
                xe.AppendChild(re);
                re.InnerText = "1";
            }

            return xe;
        }
    }
}
