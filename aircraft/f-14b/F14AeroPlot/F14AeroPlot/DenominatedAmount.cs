using System;
using System.Xml;

namespace F14AeroPlot
{
    public class DenominatedAmount
    {
        public DenominatedAmount(double v, string u, int? decimal_places = null)
        {
            DecimalPlaces = decimal_places;
            Amount = v;
            Unit = u;
        }

        public double Amount { get; private set; }

        public int? DecimalPlaces { get; set; }

        public string Unit { get; private set; }

        internal System.Xml.XmlNode CreateXmlNode(XmlDocument doc, string id)
        {
            var node = doc.CreateElement(id);
            if (Unit != null)
                node.SetAttribute("unit", Unit);
            if (DecimalPlaces.HasValue)
            {
                var format = "{0:F" + DecimalPlaces.ToString() + "}";
                node.InnerText = String.Format(format, Amount);
            }
            else
                node.InnerText = Amount.ToString();
            return node;
        }

        internal void SetAmount(double newval)
        {
            Amount = newval;
        }
    }
}