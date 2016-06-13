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
//Tire on concrete 1.00, ref: http://ffden-2.phys.uaf.edu/211_fall2002.web.dir/ben_townsend/staticandkineticfriction.htm
//also refs: http://www.altraliterature.com/pdfs/P-1648-pages41-44.pdf http://seniorphysics.com/physics/static_friction_time_dependence.pdf
            static_friction = new DenominatedAmount(1.0, null, 1);
            rolling_friction = new DenominatedAmount(0.02, null, 2);
            dynamic_friction = new DenominatedAmount(0.5, null, 1);
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
