using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;

namespace F14AeroPlot
{
    public class Location
    {
        public Location(double x, double y, double z, string unit)
        {
            this.X = x;
            this.Y = y;
            this.Z = z;
            this.Unit = unit;
        }


        public double X { get; set; }
        public double Y { get; set; }
        public double Z { get; set; }
        public string Unit { get; set; }

        internal System.Xml.XmlNode CreateXmlNode(XmlDocument doc, string id = null, string type = "location")
        {
            var node = doc.CreateElement(type);
            if (!string.IsNullOrEmpty(Unit))
                node.SetAttribute("unit", Unit);
            if (!string.IsNullOrEmpty(id))
                node.SetAttribute("name", id);
            var sub = doc.CreateElement("x");
            sub.InnerText = X.ToString();
            node.AppendChild(sub);

            sub = doc.CreateElement("y");
            sub.InnerText = Y.ToString();
            node.AppendChild(sub);

            sub = doc.CreateElement("z");
            sub.InnerText = Z.ToString();
            node.AppendChild(sub);

            return node;
        }
        internal System.Xml.XmlNode CreateOrientXmlNode(XmlDocument doc, string id = null, string type = "location")
        {
            var node = doc.CreateElement(type);
            if (!string.IsNullOrEmpty(id))
                node.SetAttribute("name", id);
            node.SetAttribute("unit", Unit);
            var sub = doc.CreateElement("roll");
            sub.InnerText = X.ToString();
            node.AppendChild(sub);

            sub = doc.CreateElement("pitch");
            sub.InnerText = Y.ToString();
            node.AppendChild(sub);

            sub = doc.CreateElement("yaw");
            sub.InnerText = Z.ToString();
            node.AppendChild(sub);

            return node;
        }


        internal Location FromChord(DenominatedAmount chord, double percentX, double percentY, double percentZ )
        {
            if (percentX > 1) percentX /= 100;
            if (percentY > 1) percentY /= 100;
            if (percentY > 1) percentZ /= 100;
            if (chord.Unit != Unit)
                throw new Exception("Must be in same units");

            return new Location(percentX * chord.Amount + X,
                percentY * chord.Amount + Y,
                percentZ * chord.Amount + Z, 
                Unit);
        }
    }
}
