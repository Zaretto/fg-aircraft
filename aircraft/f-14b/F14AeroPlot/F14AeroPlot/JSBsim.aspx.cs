using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Web;
using System.Web.UI;
using System.Web.UI.DataVisualization.Charting;
using System.Web.UI.WebControls;
using System.Xml;


namespace F14AeroPlot
{
    public partial class JSBsim : System.Web.UI.Page
    {
        AeroReader aero = new AeroReader();
        protected void Page_Load(object sender, EventArgs e)
        {
            F15Aero aero = F15Aero.Create();

            HtmlTextWriter writer = new HtmlTextWriter(Page.Response.Output);
//            writer.Write("<h1>F14 Aerodynamics</h1>");
            Response.ContentType = "text/xml";
            var aero_only = true;
            aero_only = false;
            if (!aero_only)
            {
                writer.Write("<?xml version=\"1.0\"?>\n");
                //writer.Write("<?xml-stylesheet type=\"text/xsl\" href=\"http://jsbsim.sourceforge.net/JSBSim.xsl\"?>");
                //            writer.Write("<?xml-stylesheet type=\"text/xsl\" href=\"http://www.zaretto.com/sites/zaretto.com/files/JSBSim.xsl\"?>");
                writer.Write("<?xml-stylesheet type=\"text/xsl\" href=\"/JSBSim.xsl\"?>\n");

                writer.Write("<fdm_config name=\"{0}\" version=\"2.0\" release=\"DEVELOPMENT\"\n",aero.AircraftType);
                writer.Write("   xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n");
                writer.Write("   xsi:noNamespaceSchemaLocation=\"http://jsbsim.sourceforge.net/JSBSim.xsd\">\n");
                writer.Write("\n");
                writer.Write("    <fileheader>\n");
                writer.Write("        <author>Richard Harrison</author>\n");
                writer.Write("        <filecreationdate>{0}</filecreationdate>", DateTime.Now.ToString("yyyy-MM-dd"));
                writer.Write("        <version>1.0</version>\n");
                writer.Write("        <description>{0}</description>\n",aero.Description);
                foreach(var n in aero.Notes)
                    writer.Write("        <note>{0}</note>\n",n);
                writer.Write("        <limitation></limitation>\n");
                foreach (var r in aero.References)
                {
                    writer.Write("        <reference \n");
                    writer.Write("            refID=\"{0}\"\n", r.Id);
                    writer.Write("            author=\"{0}\"\n", r.Author);
                    writer.Write("            title=\"{0}\"\n", r.Title);
                    writer.Write("            date=\"{0}\"\n", r.Date);
                    writer.Write("            URL=\"{0}\"\n", r.Url);
                    writer.Write("        />\n");
                }
                writer.Write("    </fileheader>\n");
                foreach (var s in aero.Systems)
                {
                    writer.Write("<system file=\"{0}\"/>\n", s);
                }

                {
                    XmlDocument doc = new XmlDocument();
                    //    XmlElement el = (XmlElement)doc.AppendChild(doc.CreateElement("Foo"));
                    //    el.SetAttribute("Bar", "some & value");
                    //    el.AppendChild(doc.CreateElement("Nested")).InnerText = "data";

                    XmlElement metrics = doc.CreateElement("metrics");
                    doc.AppendChild(metrics);
                    metrics.AppendChild(aero.WingArea.CreateXmlNode(doc, "wingarea"));
                    metrics.AppendChild(aero.wing_incidence.CreateXmlNode(doc, "wing_incidence"));
                    metrics.AppendChild(aero.wingspan.CreateXmlNode(doc, "wingspan"));
                    metrics.AppendChild(aero.chord.CreateXmlNode(doc, "chord"));
                    metrics.AppendChild(aero.EyePoint.CreateXmlNode(doc, "EYEPOINT"));
                    metrics.AppendChild(aero.VRP.CreateXmlNode(doc, "VRP"));
                    metrics.AppendChild(aero.AERORP.CreateXmlNode(doc, "AERORP"));
                    writer.Write(prettify(doc));
                }
                {
                    XmlDocument doc = new XmlDocument();

                    XmlElement mass = doc.CreateElement("mass_balance");
                    doc.AppendChild(mass);
                    mass.AppendChild(aero.CG.CreateXmlNode(doc, "CG"));
                    mass.AppendChild(aero.IXX.CreateXmlNode(doc, "ixx"));
                    mass.AppendChild(aero.IYY.CreateXmlNode(doc, "iyy"));
                    mass.AppendChild(aero.IZZ.CreateXmlNode(doc, "izz"));
                    mass.AppendChild(aero.IXZ.CreateXmlNode(doc, "ixz"));
                    mass.AppendChild(aero.EmptyWeight.CreateXmlNode(doc, "emptywt"));
                    writer.Write(prettify(doc));
                }
                {
                    XmlDocument doc = new XmlDocument();

                    XmlElement gr = doc.CreateElement("ground_reactions");
                    doc.AppendChild(gr);
                    foreach (var g in aero.GroundReactions)
                    {
                        g.CreateXmlNodes(doc, gr);
                    }
                    writer.Write(prettify(doc));
                }
                {
                    XmlDocument doc = new XmlDocument();

                    XmlElement p = doc.CreateElement("propulsion");
                    doc.AppendChild(p);
                    foreach (var g in aero.Engines)
                    {
                        g.CreateXmlNodes(doc, p);
                    }
                    foreach (var g in aero.Tanks.OrderBy(x=>x.Priority))
                    {
                        g.CreateXmlNodes(doc, p);
                    }
                    writer.Write(prettify(doc));
                }
                {
                    XmlDocument doc = new XmlDocument();

                    XmlElement p = doc.CreateElement("external_reactions");
                    doc.AppendChild(p);
                    foreach (var g in aero.ExternalReactions)
                    {
                        g.CreateXmlNodes(doc, p);
                    }
                    writer.Write(prettify(doc));
                }
                writer.Write("<flight_control name=\"FCS\"></flight_control>\n");
                writer.Write("<aerodynamics>\n");
            }
//            writer.Write("<pre>\n");
            foreach (var aero_axis in aero.Data.GroupBy(xx => xx.Value.Axis).OrderBy(xx=>xx.Key))
            {
                foreach (var aero_element_item in aero_axis.OrderBy(x=>x.Value.Variable))
                {
                    var aero_element = aero_element_item.Value;
                    var aero_variable = aero_element_item.Key;

//                    if (aero.HasData(aero_element))
                    {
                        var aerodat_item = aero_element;

                        if (!aero.IsUsed(aero_element))
                            writer.Write("    <!--\n");

                        if (aero.Is3d(aero_element))
                        {

                            writer.Write("    <function name=\"{0}\">\n", aerodat_item.GetVariable());
                            writer.Write("    <description>{0}</description>\n", aerodat_item.Title);
                            if (aero_element.Components.Any())
                            {
                                writer.Write("    <sum>\n");
                                foreach (var c in aero_element.Components)
                                    writer.Write("    <property>{0}</property>\n",c);
                            }

                            writer.Write("    <product>\n");
                            OutputExtraIndependentVariables(aero, writer, aero_element);
                            writer.Write("          <table>\n");
                            writer.Write("            <independentVar lookup=\"row\">{0}</independentVar>\n", aero.Lookup(aero_element.IndependentVars[0]));
                            writer.Write("            <independentVar lookup=\"column\">{0}</independentVar>\n", aero.Lookup(aero_element.IndependentVars[1]));
                            writer.Write("            <independentVar lookup=\"table\">{0}</independentVar>\n", aero.Lookup(aero_element.IndependentVars[2]));
                            var table_data_element = aero_element.data.GroupBy(xx => xx.iv3).Select(xx => new { Key = xx.Key, Values = xx });
                            foreach (var table in table_data_element)
                            {
                                writer.Write("              <tableData breakPoint=\"{0}\">", table.Key);
                                var leading = "                 ";
                                var aero_data_element = table.Values.GroupBy(xx => xx.iv1).Select(xx => new { Key = xx.Key, Values = xx });

                                writer.Write("\n" + leading);
                                writer.Write("{0,6}"," ");
                                foreach (var iv2 in aero_data_element.First().Values)
                                {
                                    writer.Write(FormatIntValue(iv2.iv2,10));
                                }


                                foreach (var iv1 in aero_data_element)
                                {
                                    writer.Write("\n" + leading);
                                    writer.Write(FormatIntValue(iv1.Key,6));

                                    foreach (var vv in iv1.Values)
                                    {
                                        writer.Write(FormatValue(vv.Value,10));
                                    }
                                }
                                writer.Write("\n              </tableData>\n");
                            }
                            writer.Write("          </table>\n");
                            writer.Write("       </product>\n");
                            if (aero_element.Components.Any())
                            {
                                writer.Write("    </sum>\n");
                            }
                            writer.Write("    </function>\n");

                            //                      writer.Write("<pre>\n");

                        }
                        else if (aero.Is2d(aero_element))
                        {
                            //                          writer.Write("<h2>{0}</h2>", aero_element);
                            //                          writer.Write("<pre>\n");

                            writer.Write("    <function name=\"{0}\">\n", aerodat_item.GetVariable());
                            writer.Write("    <description>{0}</description>\n", aerodat_item.Title);
                            if (aero_element.Components.Any())
                            {
                                writer.Write("    <sum>\n");
                                foreach (var c in aero_element.Components)
                                    writer.Write("    <property>{0}</property>\n",c);
                            }
                            writer.Write("    <product>\n");
                            OutputExtraIndependentVariables(aero, writer, aero_element);
                            writer.Write("          <table>\n");
                            writer.Write("            <independentVar lookup=\"row\">{0}</independentVar>\n", aero.Lookup(aero_element.IndependentVars[0]));
                            writer.Write("            <independentVar lookup=\"column\">{0}</independentVar>\n", aero.Lookup(aero_element.IndependentVars[1]));
                            writer.Write("            <tableData>");
                            var leading = "                 ";
                            var aero_data_element = aero_element.data.GroupBy(xx => xx.iv1).Select(xx => new { Key = xx.Key, Values = xx });

                            writer.Write("\n" + leading);
                            writer.Write("       ");
                            foreach (var iv2 in aero_data_element.First().Values)
                            {
                                writer.Write(" {0,10}\t", iv2.iv2);
                            }


                            foreach (var iv1 in aero_data_element)
                            {
                                writer.Write("\n{0}{1}", leading, FormatIntValue(iv1.Key, 6));
                                foreach (var vv in iv1.Values)
                                {
                                           writer.Write(FormatValue(vv.Value,10));
                                }
                            }
                            writer.Write("\n            </tableData>\n");
                            writer.Write("          </table>\n");
                            writer.Write("       </product>\n");
                            if (aero_element.Components.Any())
                            {
                                writer.Write("    </sum>\n");
                            }
                            writer.Write("    </function>\n");

                            //                      writer.Write("<pre>\n");
                        }
                        else if (aero_element.IndependentVars.Count == 1)
                        {

                            var aero_data_element = aero_element.data.Select(xx => new { Key = xx.iv1, Value = xx.Value });
                            if (aero_data_element != null)
                                if (aero_data_element != null)
                                {
                                    //                        writer.Write("<h2>{0}</h2>", aero_element);
                                    //                        writer.Write("<pre>\n");

                                    writer.Write("    <function name=\"{0}\">\n", aerodat_item.GetVariable());
                                    writer.Write("    <description>{0}</description>\n", aero_element.Title);
                                    if (aero_element.Components.Any())
                                    {
                                        writer.Write("    <sum>\n");
                                        foreach (var c in aero_element.Components)
                                            writer.Write("    <property>{0}</property>\n",c);
                                    }
                                    writer.Write("    <product>\n");
                                    OutputExtraIndependentVariables(aero, writer, aero_element);
                                    writer.Write("          <table>\n");
                                    writer.Write("            <independentVar lookup=\"row\">{0}</independentVar>\n", aero.Lookup(aero_element.IndependentVars[0]));
                                    writer.Write("            <tableData>\n");
                                    var leading = "                 ";
                                    foreach (var q in aero_data_element)
                                    {
                                        writer.Write("{0}{1}\t{2}\n", leading, FormatIntValue(q.Key,6), FormatValue(q.Value,10));
                                    }
                                    writer.Write("            </tableData>\n");
                                    writer.Write("          </table>\n");
                                    writer.Write("       </product>\n");
                                    if (aero_element.Components.Any())
                                    {
                                        writer.Write("    </sum>\n");
                                    }
                                    writer.Write("    </function>\n");
                                    //                        writer.Write("<pre>\n");
                                }
                        }
                        else
                        {
                            writer.Write("    <!-- cannot handle {0} -->", aero_element.Variable);
                        }

                        if (!aero.IsUsed(aero_element))
                            writer.Write("    -->\n");
                    }
                }

            }
            foreach (var aero_axis in aero.Data.Where(xx => !string.IsNullOrEmpty(xx.Value.Axis)).GroupBy(xx => xx.Value.Axis))
            {
                if (!String.IsNullOrEmpty(aero_axis.Key))
                {
                    writer.Write("    <function name=\"aero/coefficients/C{0}\">\n", aero_axis.Key);
                    //writer.Write("    <description>{0}</description>\n", aero.GetDescription(aerodat_item));
                    writer.Write("      <sum>\n");
                    foreach (var coeff in aero_axis.Where(xx => !xx.Value.IsFactor))
                    {
                        writer.Write("          <property>aero/coefficients/{0}</property>\n", aero.Lookup(coeff.Value.Variable));
                    }
                    writer.Write("       </sum>\n");
                    writer.Write("    </function>\n");
                }
                writer.Write("  <axis name=\"{0}\">\n", aero_axis.Key);
                writer.Write("    <function name=\"aero/force/{0}\">\n", aero_axis.Key);
                //writer.Write("    <description>{0} {1}</description>\n", aero_axis.Key, Char.IsLower(coeff.Substring(1,1).First()) ? "Force" : "Moment");
                writer.Write("    <product>\n");
                output_denormalisation(writer, aero_axis.Key);
                foreach (var coeff in aero_axis.Where(xx => xx.Value.IsFactor))
                {
                    writer.Write("        <property>aero/coefficients/{0}</property>\n", aero.Lookup(coeff.Value.Variable));
                }
                writer.Write("       </product>\n");
                writer.Write("    </function>\n");

                writer.Write("  </axis>\n");
            }
            if (!aero_only)
            {
                writer.Write("</aerodynamics>\n");
                writer.Write("</fdm_config>");
            }
//            writer.Write("</pre>\n");
        }

        private string prettify(XmlDocument doc)
        {
            String Result = "";

            MemoryStream mStream = new MemoryStream();
            XmlTextWriter writer = new XmlTextWriter(mStream, Encoding.Unicode);

            try
            {
                writer.Formatting = Formatting.Indented;

                // Write the XML into a formatting XmlTextWriter
                doc.WriteContentTo(writer);
                writer.Flush();
                mStream.Flush();

                // Have to rewind the MemoryStream in order to read
                // its contents.
                mStream.Position = 0;

                // Read MemoryStream contents into a StreamReader.
                StreamReader sReader = new StreamReader(mStream);

                // Extract the text from the StreamReader.
                String FormattedXML = sReader.ReadToEnd();

                Result = FormattedXML;
            }
            catch (XmlException)
            {
            }

            mStream.Close();
            writer.Close();

            return Result+"\n\n";
        }
        private object FormatIntValue(double p, int np)
        {
            if (p < 0)
                return String.Format("{0," + np.ToString() + "}\t", p);
            else
                return String.Format(" {0," + (np-1).ToString() + "}\t", p);
        }

        private object FormatValue(double p, int np)
        {
            if (p < 0)
                return String.Format("{0,"+np.ToString()+":0.00000000}\t",p);
            else
                return String.Format(" {0," + np.ToString() + ":0.00000000}\t", p);
        }

        private void OutputExtraIndependentVariables(Aerodata aero, HtmlTextWriter writer, DataElement aero_element)
        {
            foreach (var xx in aero_element.Factors)
            {
                var name = aero.Lookup(xx);
                var v = aero.LookupValue(name);
                if (v.HasValue)
                {
                    // use the lookup value to find out if it is numeric; but lookup will add an xml comment for constants
                    // so output with the original name, rather than v
                    writer.Write("          <value>{0}</value>\n", name);
                }
                else
                {
                    if (!name.Contains("/") && !Char.IsDigit(name[0]))
                        name = "aero/coefficients/" + name;

                    writer.Write("          <property>{0}</property>\n", name);
                }
            }
        }

        private static void output_denormalisation(HtmlTextWriter writer, string aero_axis_key)
        {
            writer.Write("          <property>aero/qbar-psf</property>\n");
            writer.Write("          <property>metrics/Sw-sqft</property>\n");
            if (aero_axis_key == "ROLL" || aero_axis_key == "YAW")
            {
                writer.Write("          <property>metrics/bw-ft</property>\n");
            }
            else if (aero_axis_key == "PITCH")
            {
                writer.Write("          <property>metrics/cbarw-ft</property>\n");
            }
            writer.Write("          <property>aero/coefficients/C{0}</property>\n", aero_axis_key);
        }

        private string GetVar(string xx)
        {
            if (xx.Contains(":"))
            {
                var v = xx.Split(':');
                if (v.Length > 1)
                    return v[1];
            }
            return xx;
        }

        private string GetAxis(string xx)
        {
            if (xx.Contains(":"))
            {
                var v = xx.Split(':');
                return v[0];
            }
            return xx;
        }
    }
}