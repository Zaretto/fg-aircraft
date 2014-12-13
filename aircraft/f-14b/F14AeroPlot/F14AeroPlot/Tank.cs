using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;

namespace F14AeroPlot
{
    public class Tank
    {
        public Location Location;
        public int Priority;
        public DenominatedAmount Capacity;

        public Tank(string name, double p1, double p2, double p3, string units, int p4, int capacity,string fuel_units )
        {
            Name = name;
            Location = new Location(p1, p2, p3, units);
            Priority = p4;
            Capacity = new DenominatedAmount(capacity, fuel_units);
        }

        public string Name { get; set; }
        public DenominatedAmount Contents
        {
            get
            {
                return new DenominatedAmount(Capacity.Amount, Capacity.Unit);
            }
        }
        internal XmlElement CreateXmlNodes(System.Xml.XmlDocument doc, System.Xml.XmlElement grnode)
        {
            XmlElement gr = doc.CreateElement("tank");
            gr.AppendChild(doc.CreateComment(String.Format("{0}: {1}",Id,Name)));
            grnode.AppendChild(gr);
            gr.SetAttribute("type", "FUEL");

            gr.AppendChild(Location.CreateXmlNode(doc));
            gr.AppendChild(Capacity.CreateXmlNode(doc, "capacity"));
            gr.AppendChild(Capacity.CreateXmlNode(doc, "contents"));
            {
                XmlElement p = doc.CreateElement("priority");
                p.InnerText = Priority.ToString();
                gr.AppendChild(p);
            }
            return gr;
        }

        public int Id { get; set; }
    }
}
