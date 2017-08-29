using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.DataVisualization.Charting;
using System.Web.UI.WebControls;

namespace F14AeroPlot
{
    public partial class F15VSP_PlotPage : Page
    {
        F15_VSPAero aero = new F15_VSPAero();

        int ChartWidth = 500;
        int ChartHeight = 750;
        protected void Page_Load(object sender, EventArgs e)
        {
            HtmlTextWriter writer = new HtmlTextWriter(Page.Response.Output);
            writer.Write(@"<!DOCTYPE html>
<html lang='en'>
<head profile='http://www.w3.org/1999/xhtml/vocab'>
  <title>{0}</title>

<link href='//maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap.min.css' rel='stylesheet'>
  </head><body>",aero.Title);
            writer.Write("<h1>{0}</h1>", aero.Title);
            writer.Write("<legend>{0}</legend>", aero.SubTitle);
            int PlotLineThickness = 2;

            foreach (var axis in aero.Data.GroupBy(xx => xx.Value.Axis))
            {
                if (!String.IsNullOrEmpty(axis.Key))
                    writer.Write("<h2>{0}</h2>", axis.Key);
                //else
                //    writer.Write("<h2>Additional</h2>" );
                foreach (var aero_element in axis)
                {
                    writer.Write("\n");
                    CreateChart(writer, PlotLineThickness, axis, aero_element.Value);

                    //                writer.Write("</div></p>");
                }
            }
            var compute = aero.GetCompute();
            foreach (var axis in compute)
            {
                writer.Write("<h3>{0} Coefficient Buildup</h3>", axis.Key[0]+axis.Key.Substring(1).ToLower());
                writer.Write("<p>{0}</p>", axis.Value);
            }
            if (aero.References.Any())
            {
                writer.Write("<hrule/><h2>References</h3>");
                writer.Write("<ol>");
                foreach (var re in aero.References)
                {
                    writer.Write("<li>");
                    writer.Write("{0}: {1}, {2}, {3}", re.Author, re.Title, re.Id, re.Date);
                    if (!String.IsNullOrEmpty(re.Url))
                        writer.Write(": <a href='{0}'>{0}</a>", re.Url);
                    writer.Write("</li>");
                }
                writer.Write("</ol>");
            }
            writer.Write("<span class='col-md-6'>");
            writer.Write("<h2>Mass and balance</h2>");
            writer.Write("<table class='table'>");
            writer.Write("<thead>");
            output_location_table_header(writer);
            writer.Write("<tr>");
            output_location(writer, aero.AERORP, "Aerodynamic Reference Point (CoP)");
            writer.Write("</tr>");

            writer.Write("<tr>");
            output_location(writer, aero.CG, "Aircraft CG");
            writer.Write("</tr>");
            writer.Write("</table>");

            writer.Write("<table class='table'>");
            writer.Write("<thead>");
            writer.Write("<tr>");
            writer.Write("<th>Element</th>");
            writer.Write("<th class='col-sm-1'></th>");
            writer.Write("<th class='col-sm-1'>Unit</th>");
            writer.Write("</tr>");
            writer.Write("</thead>");
            writer.Write("<tbody>");
            output_amount(writer, "IXX", aero.IXX);
            output_amount(writer, "IYY", aero.IYY);
            output_amount(writer, "IZZ", aero.IZZ);
            output_amount(writer, "IXZ", aero.IXZ);
            writer.Write("</tbody>");
            writer.Write("</table>");

            writer.Write("<table class='table'  width='30%'>");
            output_location_table_header(writer, "<th>Weight</th>");
            writer.Write("<tbody>");
            foreach (var g in aero.Mass)
            {
                writer.Write("<tr>");
                output_location(writer, g.Location, g.Name);
                writer.Write("<td>{0} {1}</td>", g.weight.Amount, g.weight.Unit);
            }
            writer.Write("</tbody>");
            writer.Write("</table>");
            writer.Write("</span>");

            writer.Write("<span class='col-md-4'>");
            writer.Write("<h2>Ground Reactions</h2>");
            writer.Write("<table class='table'  width='30%'>");
            output_location_table_header(writer);
            writer.Write("<tbody>");
            foreach (var g in aero.GroundReactions)
            {
                writer.Write("<tr>");
                output_location(writer, g.Location, g.Name);
                writer.Write("</tr>");
            }
            writer.Write("</table>");

            writer.Write("<h2>Metrics</h2>");
            writer.Write("<table class='table'>");
            writer.Write("<thead>");
            writer.Write("<tr>");
            writer.Write("<th>Element</th>");
            writer.Write("<th class='col-sm-1'></th>");
            writer.Write("<th class='col-sm-1'>Unit</th>");
            writer.Write("</tr>");
            writer.Write("</thead>");
            writer.Write("<tbody>");
            output_amount(writer, "Chord", aero.chord);
            output_amount(writer, "Wingspan", aero.wingspan);
            output_amount(writer, "Wing Area", aero.WingArea);
            output_amount(writer, "Wing Incidence", aero.wing_incidence);
            writer.Write("</tbody>");
            writer.Write("</table>");
            writer.Write("</span>");


            writer.Write("<span class='col-md-9'>");
            writer.Write("<h2>Propulsion</h2>");
            writer.Write("<table class='table'  width='30%'>");
            output_location_table_header(writer, "<th>Feed</th>");
            writer.Write("<tbody>");
            foreach (var g in aero.Engines)
            {
                writer.Write("<tr>");
                output_location(writer, g.Location, g.Name);
                writer.Write("<td>{0}</td>", String.Join(",", g.Feed.Select(xx=>get_tank(aero,xx))));
                writer.Write("</tr>");
            }
            writer.Write("</tbody>");
            writer.Write("</table>");
            writer.Write("</span>");

            writer.Write("<span class='col-md-6'>");
            writer.Write("<h2>Tanks</h2>");
            writer.Write("<table class='table'  width='30%'>");
            output_location_table_header(writer, "<th class='col-sm-1'>Capacity</th><th class='col-sm-1'>Id</th><th class='col-sm-1'>Priority</th><th>Standpipe</th>");
            writer.Write("<tbody>");
            foreach (var g in aero.Tanks)
            {
                writer.Write("<tr>");
                output_location(writer, g.Location, g.Name);
                writer.Write("<td>{0} {1}</td>", g.Capacity.Amount, g.Capacity.Unit);
                writer.Write("<td>{0}</td>", g.Id);
                writer.Write("<td>{0}</td>", g.Priority);
                if (g.Standpipe != null)
                    writer.Write("<td>{0} {1}</td>", g.Standpipe.Amount, g.Standpipe.Unit);
                else
                    writer.Write("<td></td>");
                writer.Write("</tr>");
            }
            writer.Write("</tbody>");
            writer.Write("</table>");
            writer.Write("</span>");

            writer.Write("</body></html>");
        }

        private void output_amount(HtmlTextWriter writer, string key, DenominatedAmount v)
        {
            writer.Write("<tr>");
            writer.Write("<td>{0}</td><td>{1:0.00}</td><td>{2}</td>", key, v.Amount, v.Unit);
            writer.Write("</tr>");
        }

        private void CreateChart(HtmlTextWriter writer, int PlotLineThickness, IGrouping<string, KeyValuePair<string, DataElement>> axis, DataElement aero_element)
        {
            if (aero_element.IndependentVars.Count == 3)
            {
                var table_data_element = aero_element.data.GroupBy(xx => xx.iv3).Select(xx => new { Key = xx.Key, Values = xx });
                foreach (var table in table_data_element)
                {
                    string base_name = String.Format(ChartFileNamePrefix + "_{0}_{1}_{2}.png", axis.Key, aero_element.Variable, table.Key).AsValidFilename();
                    System.Web.UI.DataVisualization.Charting.Chart chart = new System.Web.UI.DataVisualization.Charting.Chart();
                    chart.Width = ChartWidth * 3;
                    chart.Height = ChartHeight * 3;
                    chart.Width = ChartWidth;
                    chart.Height = ChartHeight;
                    //chart.RenderType = RenderType.ImageTag;
                    var ca1 = chart.ChartAreas.Add("chart");

                    chart.Palette = ChartColorPalette.BrightPastel;
                    chart.Palette = ChartColorPalette.None;
                    chart.PaletteCustomColors = ChartPalette.AeroPalette;// ChartColorPalette.Bright;//.Excel;//.BrightPastel;
                    if (!String.IsNullOrEmpty(aero_element.Title))
                        chart.Titles.Add(new Title(String.Format("{0}", aero_element.Title), Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105)));
                    Title t = new Title(String.Format("{0} ({1},{2},{3}[{4}])",
                            aero_element.Variable,
                            aero_element.IndependentVars[0],
                                                                aero_element.IndependentVars[1],
aero_element.IndependentVars[2],
                            table.Key),
                            Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105));
                    chart.Titles.Add(t);
                    var computeval = aero_element.GetComputeValue(aero);
                    if (!String.IsNullOrEmpty(computeval) && computeval != aero_element.Variable)
                        chart.Titles.Add(new Title(computeval, Docking.Top, new System.Drawing.Font("Trebuchet MS", 10, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105)));
                    chart.BorderSkin.SkinStyle = BorderSkinStyle.None;
                    //chart.BorderColor = System.Drawing.Color.FromArgb(26, 59, 105);
                    //chart.BorderlineDashStyle = ChartDashStyle.Solid;
                    //chart.BorderWidth = 2;
                    chart.ImageStorageMode = ImageStorageMode.UseHttpHandler;
                    chart.ImageLocation = String.Format("~/plot_{0}.png", aero_element);
                    chart.ImageStorageMode = ImageStorageMode.UseImageLocation;// ImageStorageMode.UseHttpHandler;
                    chart.ImageLocation = String.Format("~/{0}", base_name);
                    //                chart.Legends.Add("Legend1");

                    chart.Legends.Add("Legend1");
                    chart.Legends["Legend1"].Docking = Docking.Bottom;
                    chart.Legends["Legend1"].IsTextAutoFit = false;
                    chart.Legends["Legend1"].BackColor = System.Drawing.Color.Transparent;
                    chart.Legends["Legend1"].Font = new System.Drawing.Font("Trebuchet MS", 11);
                    chart.Legends["Legend1"].Alignment = System.Drawing.StringAlignment.Center;

                    var aero_data_element = table.Values.GroupBy(xx => xx.iv2).Select(xx => new { Key = xx.Key, Values = xx });

                    foreach (var iv1 in aero_data_element)
                    {
                        var ck = String.Format("{0} {1}", table.Values.First().Parent.IndependentVars[1], iv1.Key);
                        chart.Series.Add(ck);
                        chart.Series[ck].ChartType = SeriesChartType.Line;
                        chart.Series[ck].BorderWidth = PlotLineThickness;
                        //chart.Series[ck].Label = "#VALY";
                        //chart.Series[ck].LabelForeColor = System.Drawing.Color.Black;
                        foreach (var vv in iv1.Values)
                        {
                            var q = vv.Value;
                            chart.Series[ck].Points.AddXY(vv.iv1, vv.Value);
                        }

                    }
                    // Render chart control
                    chart.Page = this;
                    AddImageToHTML(writer, base_name, aero_element.Variable, chart);
                }
            }
            else if (aero_element.IndependentVars.Count == 2)
            {
                string base_name = String.Format(ChartFileNamePrefix + "_{0}_{1}_{2}.png", axis.Key, aero_element.Variable, aero_element.IndependentVars[0]).AsValidFilename();

                var aero_data_element = aero_element.data.GroupBy(xx => xx.iv2).Select(xx => new { Key = xx.Key, Values = xx });
                System.Web.UI.DataVisualization.Charting.Chart chart = new System.Web.UI.DataVisualization.Charting.Chart();
                chart.Width = ChartWidth * 3;
                chart.Height = ChartHeight * 3;
                chart.Width = ChartWidth;
                chart.Height = ChartHeight;
                //chart.RenderType = RenderType.ImageTag;
                var ca1 = chart.ChartAreas.Add("chart");

                chart.Palette = ChartColorPalette.BrightPastel;
                chart.Palette = ChartColorPalette.None;
                chart.PaletteCustomColors = ChartPalette.AeroPalette;// ChartColorPalette.Bright;//.Excel;//.BrightPastel;
                if (!String.IsNullOrEmpty(aero_element.Title))
                    chart.Titles.Add(new Title(String.Format("{0}", aero_element.Title), Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105)));
                Title t = new Title(String.Format("{0}({1},{2})", aero_element.Variable, aero_element.IndependentVars[0], aero_element.IndependentVars[1]), Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105));
                //                        Title t = new Title(String.Format("{0} (β,α)", aero_element), Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105));
                chart.Titles.Add(t);
                var computeval = aero_element.GetComputeValue(aero);
                if (!String.IsNullOrEmpty(computeval) && computeval != aero_element.Variable)
                    chart.Titles.Add(new Title(computeval, Docking.Top, new System.Drawing.Font("Trebuchet MS", 10, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105)));

                chart.BorderSkin.SkinStyle = BorderSkinStyle.None;
                //chart.BorderColor = System.Drawing.Color.FromArgb(26, 59, 105);
                //chart.BorderlineDashStyle = ChartDashStyle.Solid;
                //chart.BorderWidth = 2;
                chart.ImageStorageMode = ImageStorageMode.UseHttpHandler;
                chart.ImageLocation = String.Format("~/plot_{0}.png", aero_element);
                chart.ImageStorageMode = ImageStorageMode.UseImageLocation;// ImageStorageMode.UseHttpHandler;
                chart.ImageLocation = String.Format("~/{0}", base_name);
                //                chart.Legends.Add("Legend1");

                foreach (var alpha in aero_data_element)
                {
                    var ck = String.Format("{0} {1}", aero_element.IndependentVars[1], alpha.Key);
                    chart.Series.Add(ck);
                    chart.Series[ck].ChartType = SeriesChartType.Line;
                    chart.Series[ck].BorderWidth = PlotLineThickness;
                    //chart.Series[ck].Label = "#VALY";
                    //chart.Series[ck].LabelForeColor = System.Drawing.Color.Black;
                    foreach (var vv in alpha.Values)
                    {
                        var q = vv.Value;
                        chart.Series[ck].Points.AddXY(vv.iv1, vv.Value);
                    }
                }
                chart.Legends.Add("Legend1");
                chart.Legends["Legend1"].Docking = Docking.Bottom;
                chart.Legends["Legend1"].IsTextAutoFit = false;
                chart.Legends["Legend1"].BackColor = System.Drawing.Color.Transparent;
                chart.Legends["Legend1"].Font = new System.Drawing.Font("Trebuchet MS", 11);
                chart.Legends["Legend1"].Alignment = System.Drawing.StringAlignment.Center;

                // Render chart control
                chart.Page = this;
                AddImageToHTML(writer, base_name, aero_element.Variable, chart);
            }
            else if (aero_element.IndependentVars.Count == 1)
            {
                string base_name = String.Format(ChartFileNamePrefix + "_{0}_{1}_{2}.png", axis.Key, aero_element.Variable, aero_element.IndependentVars[0]).AsValidFilename();

                var aero_data_element = aero_element.data.Select(xx => new { Key = xx.iv1, Value = xx.Value });
                if (aero_data_element != null)
                {
                    System.Web.UI.DataVisualization.Charting.Chart chart = new System.Web.UI.DataVisualization.Charting.Chart();
                    chart.Width = ChartWidth;
                    chart.Height = ChartHeight;
                    //chart.RenderType = RenderType.ImageTag;
                    var ca1 = chart.ChartAreas.Add("chart");

                    chart.Palette = ChartColorPalette.BrightPastel;
                    chart.Palette = ChartColorPalette.None;
                    chart.PaletteCustomColors = ChartPalette.AeroPalette;// ChartColorPalette.Bright;//.Excel;//.BrightPastel;
                    if (!String.IsNullOrEmpty(aero_element.Title))
                        chart.Titles.Add(new Title(String.Format("{0}", aero_element.Title), Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105)));
                    Title t = new Title(String.Format("{0}({1})", aero_element.Variable, aero_element.IndependentVars[0]), Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105));
                    chart.Titles.Add(t);
                    var computeval = aero_element.GetComputeValue(aero);
                    if (!String.IsNullOrEmpty(computeval) && computeval != aero_element.Variable)
                        chart.Titles.Add(new Title(computeval, Docking.Top, new System.Drawing.Font("Trebuchet MS", 10, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105)));

                    chart.BorderSkin.SkinStyle = BorderSkinStyle.None;
                    //chart.BorderColor = System.Drawing.Color.FromArgb(26, 59, 105);
                    //chart.BorderlineDashStyle = ChartDashStyle.Solid;
                    //chart.BorderWidth = 2;
                    chart.ImageStorageMode = ImageStorageMode.UseImageLocation;// ImageStorageMode.UseHttpHandler;
                    chart.ImageLocation = String.Format("~/f14_aero_{0}.png", aero_element.Variable + "_" + aero_element.Description);
                    //                chart.Legends.Add("Legend1");

                    var series = "data";
                    chart.Series.Add(series);
                    chart.Series[series].ChartType = SeriesChartType.Line;
                    foreach (var q in aero_data_element)
                    {
                        chart.Series[series].Points.AddXY(q.Key, q.Value);
                    }
                    chart.Series[series].BorderWidth = 3;

                    AddImageToHTML(writer, base_name, aero_element.Variable, chart);

                }
            }
        }

        private string get_tank(Aerodata aero, int xx)
        {
            if (xx < aero.Tanks.Count)
                return string.Format("{0} [{1}]", aero.Tanks[xx].Name, xx);
            return string.Format("*UNDEF* [{1}]", aero.Tanks[xx].Name, xx);
        }

        private static void output_location_table_header(HtmlTextWriter writer, string extra=null)
        {
            writer.Write("<tr>");
            writer.Write("<th>Element</th>");
            writer.Write("<th class='col-sm-1'>X</th>");
            writer.Write("<th class='col-sm-1'>Y</th>");
            writer.Write("<th class='col-sm-1'>Z</th>");
            writer.Write("<th class='col-sm-1'>Unit</th>");
            if(!String.IsNullOrEmpty(extra))
                writer.Write(extra);
            writer.Write("</tr>");
            writer.Write("</thead>");
        }

        private void output_location(HtmlTextWriter writer, Location location, string p)
        {
            writer.Write("<td>{4}</td><td>{0:0.00}</td><td>{1:0.00}</td><td>{2:0.00}</td><td>{3}</td>", location.X, location.Y, location.Z, location.Unit, p);
        }

        private void AddImageToHTML(HtmlTextWriter writer, string base_name, string aero_element, System.Web.UI.DataVisualization.Charting.Chart chart)
        {
            chart.Page = this;
            chart.SaveImage(AeroReader.DefPath + base_name);

            //chart.RenderControl(writer);
            writer.Write("<img style='display:inline-block;width:{0}mm;height:{1}mm;border-width:0px' src='{2}' alt='{3}'/>\n",
                ChartWidth / 5, ChartHeight / 5,
                base_name, aero_element);
            //            writer.Write("<img style='display:inline-block;height:7cm;width:5cm;border-width:0px' src='{0}' alt='{1}'/>\n", base_name, aero.Description(aero_element));
        }

        public string ChartFileNamePrefix = "f15_aero";
    }
}