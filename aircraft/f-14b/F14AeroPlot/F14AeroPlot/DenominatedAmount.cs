using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;

namespace F14AeroPlot
{
    public class DenominatedAmount
    {
        public DenominatedAmount(double v, string u)
        {
            Amount = v;
            Unit = u;
        }

        public double Amount { get; private set; }

        public string Unit { get; private set; }

        internal System.Xml.XmlNode CreateXmlNode(XmlDocument doc, string id)
        {
            var node = doc.CreateElement(id);
            if (Unit != null)
                node.SetAttribute("unit", Unit);
            node.InnerText = Amount.ToString();
            return node;
        }
    }
}
