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

        public Tank(string name, double p1, double p2, double p3, string units, int pri, int capacity,string fuel_units, double? standpipe )
        {
            Name = name;
            Priority = pri;
            Location = new Location(p1, p2, p3, units);
            Capacity = new DenominatedAmount(capacity, fuel_units);

            if (standpipe.HasValue)
                Standpipe = new DenominatedAmount(standpipe.Value, fuel_units);
        }

        public string Name { get; set; }
        public DenominatedAmount Contents
        {
            get
            {
                return new DenominatedAmount(Capacity.Amount, Capacity.Unit);
            }
        }
        internal XmlElement CreateXmlNodes(System.Xml.XmlDocument doc, System.Xml.XmlElement grnode, int tank_index)
        {
            XmlElement gr = doc.CreateElement("tank");
            gr.AppendChild(doc.CreateComment(String.Format("{0}: {1}", tank_index, Name)));
            grnode.AppendChild(gr);
            gr.SetAttribute("type", "FUEL");

            gr.AppendChild(Location.CreateXmlNode(doc));
            gr.AppendChild(Capacity.CreateXmlNode(doc, "capacity"));
            
            if (Standpipe != null)
                gr.AppendChild(Standpipe.CreateXmlNode(doc, "standpipe"));

            gr.AppendChild(Capacity.CreateXmlNode(doc, "contents"));
            {
                XmlElement p = doc.CreateElement("priority");
                p.InnerText = Priority.ToString();
                gr.AppendChild(p);
            }
            return gr;
        }

        public int Id = 0;
        //{
        //    get
        //    {
        //        return Priority;
        //    }
        //    set
        //    {
        //        Priority = value;
        //    }
        //}

        public DenominatedAmount Standpipe { get; set; }
    }
}
