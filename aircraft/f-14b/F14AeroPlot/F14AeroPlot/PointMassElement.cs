using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;

namespace F14AeroPlot
{
    public class PointMassElement
    {
        public PointMassElement(Aerodata a)
        {
        }

        public string Name { get; set; }

        public Location Location { get; set; }
        public DenominatedAmount weight = new DenominatedAmount(0, "LBS");

        internal virtual XmlElement CreateXmlNodes(System.Xml.XmlDocument doc, System.Xml.XmlElement grnode)
        {
            XmlElement gr = doc.CreateElement("pointmass");
            grnode.AppendChild(gr);
            gr.SetAttribute("name", Name);
                gr.AppendChild(Location.CreateXmlNode(doc, "Pointmass "+Name));
                gr.AppendChild(weight.CreateXmlNode(doc, "weight"));
            return gr;
        }
    }
}
