using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml;

namespace F14AeroPlot
{
    public class Engine
    {
        public string Name { get; set; }

        public List<int> Feed = new List<int>();

        public Location Location { get; set; }

        public Location Orient { get; set; }

        internal XmlElement CreateXmlNodes(System.Xml.XmlDocument doc, System.Xml.XmlElement grnode)
        {
            XmlElement gr = doc.CreateElement("engine");
            grnode.AppendChild(gr);
            gr.SetAttribute("file", Name);

            gr.AppendChild(Location.CreateXmlNode(doc));
            gr.AppendChild(Orient.CreateOrientXmlNode(doc,null,"orient"));
            foreach (var f in Feed)
            {
                XmlElement feed = doc.CreateElement("feed");
                gr.AppendChild(feed);
                feed.InnerText = f.ToString();

            }
            XmlElement th = doc.CreateElement("thruster");
            gr.AppendChild(th);
            th.SetAttribute("file", "direct");
            th.AppendChild(Location.CreateXmlNode(doc));
            th.AppendChild(Orient.CreateOrientXmlNode(doc, null, "orient"));
            return gr;
        }

        internal void AddFeed(Tank t)
        {
            Feed.Add(t.Id);
        }
    }
}
