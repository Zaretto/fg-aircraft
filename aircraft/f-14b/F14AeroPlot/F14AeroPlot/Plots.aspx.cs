using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.DataVisualization.Charting;
using System.Web.UI.WebControls;

namespace F14AeroPlot
{
    public partial class F15_PlotPage : Page
    {
        F15Aero aero = F15Aero.Create();

        int ChartWidth = 500;
        int ChartHeight = 750;
        protected void Page_Load(object sender, EventArgs e)
        {
            //var clbas = aero.GetValues_2d("CLBAS");
            //foreach (var alpha in clbas)
            //{
            //    var ck = String.Format("{0}", alpha.Key);
            //    Chart1.Series.Add(ck);
            //    Chart1.Series[ck].ChartType = SeriesChartType.Line;
            //    foreach (var vv in alpha.Value)
            //    {
            //        var q = vv.Value;
            //        Chart1.Series[ck].Points.AddXY(vv.Key, vv.Value);
            //    }
            //}
            HtmlTextWriter writer = new HtmlTextWriter(Page.Response.Output);
            writer.Write(@"<!DOCTYPE html>
<html lang='en'>
<head profile='http://www.w3.org/1999/xhtml/vocab'>
  <title>{0}</title>

<link href='//maxcdn.bootstrapcdn.com/bootstrap/3.3.1/css/bootstrap.min.css' rel='stylesheet'>
  </head><body>",aero.Title);
            writer.Write("<h1>{0}</h1>", aero.Title);
            int PlotLineThickness = 2;
            foreach (var aero_element in aero.Data)
            {
                writer.Write("\n");
                //                if (aero.HasData(aero_element))
                //                writer.Write("<p style='page-break-before'>\n", aero_element.Key);
                //                writer.Write("<span>{0}</span><div>\n", aero_element.Value.Title);
                {
                    if (aero_element.Value.IndependentVars.Count == 3)
                    {
                        var table_data_element = aero_element.Value.data.GroupBy(xx => xx.iv3).Select(xx => new { Key = xx.Key, Values = xx });
                        foreach (var table in table_data_element)
                        {
                            string base_name = String.Format(ChartFileNamePrefix + "_{0}_{1}.png", aero_element.Key, table.Key);
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
                            if (!String.IsNullOrEmpty(aero_element.Value.Title))
                                chart.Titles.Add(new Title(String.Format("{0}", aero_element.Value.Title), Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105)));
                            Title t = new Title(String.Format("{0} ({1},{2},{3}[{4}])",
                                    aero_element.Key,
                                    aero_element.Value.IndependentVars[0],
                                                                        aero_element.Value.IndependentVars[1],
aero_element.Value.IndependentVars[2],
                                    table.Key),
                                    Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105));
                            chart.Titles.Add(t);
                            var computeval = aero_element.Value.GetComputeValue(aero);
                            if (!String.IsNullOrEmpty(computeval) && computeval != aero_element.Value.Variable)
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
                            AddImageToHTML(writer, base_name, aero_element.Key, chart);
                        }
                    }
                    else if (aero_element.Value.IndependentVars.Count == 2)
                    {
                        string base_name = String.Format(ChartFileNamePrefix + "_{0}_alpha.png", aero_element.Key);

                        var aero_data_element = aero_element.Value.data.GroupBy(xx => xx.iv2).Select(xx => new { Key = xx.Key, Values = xx });
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
                        if (!String.IsNullOrEmpty(aero_element.Value.Title))
                            chart.Titles.Add(new Title(String.Format("{0}", aero_element.Value.Title), Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105)));
                        Title t = new Title(String.Format("{0}({1},{2})", aero_element.Key, aero_element.Value.IndependentVars[0], aero_element.Value.IndependentVars[1]), Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105));
                        //                        Title t = new Title(String.Format("{0} (β,α)", aero_element), Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105));
                        chart.Titles.Add(t);
                        var computeval = aero_element.Value.GetComputeValue(aero);
                        if (!String.IsNullOrEmpty(computeval) && computeval != aero_element.Value.Variable)
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
                            var ck = String.Format("{0} {1}", aero_element.Value.IndependentVars[1], alpha.Key);
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
                        AddImageToHTML(writer, base_name, aero_element.Key, chart);
                    }
                    else if (aero_element.Value.IndependentVars.Count == 1)
                    {
                        string base_name = String.Format(ChartFileNamePrefix + "_{0}_alpha.png", aero_element.Key);

                        var aero_data_element = aero_element.Value.data.Select(xx => new { Key = xx.iv1, Value = xx.Value });
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
                            if (!String.IsNullOrEmpty(aero_element.Value.Title))
                                chart.Titles.Add(new Title(String.Format("{0}", aero_element.Value.Title), Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105)));
                            Title t = new Title(String.Format("{0}({1})", aero_element.Key, aero_element.Value.IndependentVars[0]), Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105));
                            chart.Titles.Add(t);
                            var computeval = aero_element.Value.GetComputeValue(aero);
                            if (!String.IsNullOrEmpty(computeval) && computeval != aero_element.Value.Variable)
                                chart.Titles.Add(new Title(computeval, Docking.Top, new System.Drawing.Font("Trebuchet MS", 10, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105)));

                            chart.BorderSkin.SkinStyle = BorderSkinStyle.None;
                            //chart.BorderColor = System.Drawing.Color.FromArgb(26, 59, 105);
                            //chart.BorderlineDashStyle = ChartDashStyle.Solid;
                            //chart.BorderWidth = 2;
                            chart.ImageStorageMode = ImageStorageMode.UseImageLocation;// ImageStorageMode.UseHttpHandler;
                            chart.ImageLocation = String.Format("~/f14_aero_{0}.png", aero_element.Key + "_" + aero_element.Value.Description);
                            //                chart.Legends.Add("Legend1");

                            var series = "data";
                            chart.Series.Add(series);
                            chart.Series[series].ChartType = SeriesChartType.Line;
                            foreach (var q in aero_data_element)
                            {
                                chart.Series[series].Points.AddXY(q.Key, q.Value);
                            }
                            chart.Series[series].BorderWidth = 3;

                            AddImageToHTML(writer, base_name, aero_element.Key, chart);

                        }
                    }
                }
                //                writer.Write("</div></p>");
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
            writer.Write("</body></html>");
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