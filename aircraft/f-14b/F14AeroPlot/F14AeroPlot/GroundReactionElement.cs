using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;

namespace F14AeroPlot
{
    public class GroundReactionElement
    {
        public GroundReactionElement(Aerodata a)
        {
            spring_coeff = a.EmptyWeight;
            spring_coeff = new DenominatedAmount(a.EmptyWeight.Amount * 0.9, "LBS/FT");
            damping_coeff = new DenominatedAmount(a.EmptyWeight.Amount * 0.2, "LBS/FT/SEC");
        }

        public string Name { get; set; }

        public Location Location { get; set; }
        public DenominatedAmount static_friction = new DenominatedAmount(1.2,null);
        public DenominatedAmount dynamic_friction = new DenominatedAmount(1.212, null);
        public DenominatedAmount rolling_friction = new DenominatedAmount(1.413, null);
        public DenominatedAmount spring_coeff = new DenominatedAmount(42500, "LBS/FT");
        public DenominatedAmount damping_coeff = new DenominatedAmount(2000, "LBS/FT/SEC");

        internal virtual XmlElement CreateXmlNodes(System.Xml.XmlDocument doc, System.Xml.XmlElement grnode)
        {
            XmlElement gr = doc.CreateElement("contact");
            grnode.AppendChild(gr);
            gr.SetAttribute("type", "STRUCTURE");
            gr.SetAttribute("name", Name);

                gr.AppendChild(Location.CreateXmlNode(doc));
                gr.AppendChild(static_friction.CreateXmlNode(doc, "static_friction"));
            gr.AppendChild(dynamic_friction.CreateXmlNode(doc, "dynamic_friction"));
            gr.AppendChild(rolling_friction.CreateXmlNode(doc, "rolling_friction"));
            gr.AppendChild(spring_coeff.CreateXmlNode(doc, "spring_coeff"));
            gr.AppendChild(damping_coeff.CreateXmlNode(doc, "damping_coeff"));
            return gr;
        }
    }
}
