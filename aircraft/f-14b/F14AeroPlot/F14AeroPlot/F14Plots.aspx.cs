using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.DataVisualization.Charting;
using System.Web.UI.WebControls;

namespace F14AeroPlot
{
    public partial class F14_Default : Page
    {
        AeroReader aero = new AeroReader();
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
            writer.Write("<h1>F14 Aerodynamics</h1>");
            int PlotLineThickness = 2;
            foreach (var aero_element in aero.GetElements())
            {
                writer.Write("\n");
                writer.Write("<h2 style='page-break-before'>{0}</h2>\n", aero.Description(aero_element));
                //                if (aero.HasData(aero_element))
                writer.Write("<p>\n", aero.Description(aero_element));
                {
                    if (aero.Is2d(aero_element))
                    {
                        {
                            string base_name = String.Format("f14_aero_{0}_beta_alpha.png", aero_element.Replace(":", "_"));
                            var aero_data_element = aero.GetValues_2dBetaAlpha(aero_element);
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
                            Title t = new Title(String.Format("{0} (β,α)", aero_element), Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105));
                            chart.Titles.Add(t);

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
                                var ck = String.Format("{0}", alpha.Key);
                                chart.Series.Add(ck);
                                chart.Series[ck].ChartType = SeriesChartType.Line;
                                chart.Series[ck].BorderWidth = PlotLineThickness;
                                //chart.Series[ck].Label = "#VALY";
                                //chart.Series[ck].LabelForeColor = System.Drawing.Color.Black;
                                foreach (var vv in alpha.Value)
                                {
                                    var q = vv.Value;
                                    chart.Series[ck].Points.AddXY(vv.Key, vv.Value);
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
                            AddImageToHTML(writer, base_name, aero_element, chart);
                        }
                        {
                            string base_name = String.Format("f14_aero_{0}_alpha_beta.png", aero_element.Replace(":", "_"));
                            var aero_data_element = aero.GetValues_2dAlphaBeta(aero_element);
                            System.Web.UI.DataVisualization.Charting.Chart chart = new System.Web.UI.DataVisualization.Charting.Chart();
                            chart.Width = ChartWidth * 3;
                            chart.Height = ChartHeight * 3;
                            chart.Width = ChartWidth;
                            chart.Height = ChartHeight;
                            //chart.RenderType = RenderType.ImageTag;
                            var ca1 = chart.ChartAreas.Add("chart");

                            chart.Palette = ChartColorPalette.None;
                            chart.PaletteCustomColors = ChartPalette.AeroPalette;// ChartColorPalette.Bright;//.Excel;//.BrightPastel;
//                          chart.Palette = ChartColorPalette.BrightPastel;
                            Title t = new Title(String.Format("{0} (α,β)", aero_element), Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105));
                            chart.Titles.Add(t);

                            chart.BorderSkin.SkinStyle = BorderSkinStyle.None;
                            //chart.BorderColor = System.Drawing.Color.FromArgb(26, 59, 105);
                            //chart.BorderlineDashStyle = ChartDashStyle.Solid;
                            //chart.BorderWidth = 2;
                            chart.ImageStorageMode = ImageStorageMode.UseHttpHandler;
                            chart.ImageLocation = String.Format("~/{0}", base_name);
                            chart.ImageStorageMode = ImageStorageMode.UseImageLocation;// ImageStorageMode.UseHttpHandler;
                            //                chart.Legends.Add("Legend1");

                            foreach (var alpha in aero_data_element)
                            {
                                var ck = String.Format("{0}", alpha.Key);
                                chart.Series.Add(ck);
                                chart.Series[ck].ChartType = SeriesChartType.Line;
                                chart.Series[ck].BorderWidth = PlotLineThickness;
                                //chart.Series[ck].Label = "#VALY";
                                //chart.Series[ck].LabelForeColor = System.Drawing.Color.Black;
                                foreach (var vv in alpha.Value)
                                {
                                    var q = vv.Value;
                                    chart.Series[ck].Points.AddXY(vv.Key, vv.Value);
                                }
                            }
                            chart.Legends.Add("Legend1");
                            chart.Legends["Legend1"].Docking = Docking.Bottom;
                            chart.Legends["Legend1"].IsTextAutoFit = false;
                            chart.Legends["Legend1"].BackColor = System.Drawing.Color.Transparent;
                            chart.Legends["Legend1"].Font = new System.Drawing.Font("Trebuchet MS", 11);
                            chart.Legends["Legend1"].Alignment = System.Drawing.StringAlignment.Center;

                            // Render chart control
                            AddImageToHTML(writer, base_name, aero_element, chart);
                        }
                    }
                    else
                    {
                        string base_name = String.Format("f14_aero_{0}_alpha.png", aero_element.Replace(":", "_"));

                        var aero_data_element = aero.GetValues_1d(aero_element);
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
                            Title t = new Title(String.Format("{0} (α)", aero_element), Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105));
                            chart.Titles.Add(t);

                            chart.BorderSkin.SkinStyle = BorderSkinStyle.None;
                            //chart.BorderColor = System.Drawing.Color.FromArgb(26, 59, 105);
                            //chart.BorderlineDashStyle = ChartDashStyle.Solid;
                            //chart.BorderWidth = 2;
                            chart.ImageStorageMode = ImageStorageMode.UseImageLocation;// ImageStorageMode.UseHttpHandler;
                            chart.ImageLocation = String.Format("~/f14_aero_{0}.png", aero_element.Replace(":","_"));
                            //                chart.Legends.Add("Legend1");

                            var series = "data";
                            chart.Series.Add(series);
                            chart.Series[series].ChartType = SeriesChartType.Line;
                            foreach (var q in aero_data_element)
                            {
                                chart.Series[series].Points.AddXY(q.Key, q.Value);
                            }
                            chart.Series[series].BorderWidth = 3;

                            AddImageToHTML(writer, base_name, aero_element, chart);

                        }
                    }
                }
                writer.Write("</p>");

            }
        }

        private void AddImageToHTML(HtmlTextWriter writer, string base_name, string aero_element, System.Web.UI.DataVisualization.Charting.Chart chart)
        {
            chart.Page = this;
            chart.SaveImage(AeroReader.DefPath + base_name);

            //chart.RenderControl(writer);
            writer.Write("<img style='display:inline-block;width:{0}px;height:{1}px;border-width:0px' src='{2}' alt='{3}'/>\n", 
                ChartWidth ,ChartHeight,
                base_name, aero.Description(aero_element));
//            writer.Write("<img style='display:inline-block;height:7cm;width:5cm;border-width:0px' src='{0}' alt='{1}'/>\n", base_name, aero.Description(aero_element));
        }
    }
    }
