using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;

namespace F14AeroPlot
{
    public class ExternalForce
    {
        public string name { get; set; }
        public string frame { get; set; }

        public Location location { get; set; }
        public Location direction { get; set; }

        internal virtual XmlElement CreateXmlNodes(System.Xml.XmlDocument doc, System.Xml.XmlElement grnode)
        {
            XmlElement gr = doc.CreateElement("force");
            grnode.AppendChild(gr);
            gr.SetAttribute("name", name);
            gr.SetAttribute("frame", frame);

            gr.AppendChild(location.CreateXmlNode(doc));
            gr.AppendChild(direction.CreateXmlNode(doc, null, "direction"));
            return gr;
        }
    }
}