using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.DataVisualization.Charting;
using System.Web.UI.WebControls;

namespace F14AeroPlot
{
    public partial class _Default : Page
    {
        AeroReader aero = new AeroReader();
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
            int w = 400;
            int h = 600;
            foreach (var aero_element in aero.GetElements())
            {
                if (aero.HasData(aero_element))
                {
                    if (aero.Is2d(aero_element))
                    {
                        {
                                            var aero_data_element = aero.GetValues_2dBetaAlpha(aero_element);
                        System.Web.UI.DataVisualization.Charting.Chart chart = new System.Web.UI.DataVisualization.Charting.Chart();
                        chart.Width = w * 3;
                        chart.Height = h * 3;
                        chart.Width = w;
                        chart.Height = h;
                        //chart.RenderType = RenderType.ImageTag;
                        var ca1 = chart.ChartAreas.Add("chart");

                        chart.Palette = ChartColorPalette.BrightPastel;
                        Title t = new Title(String.Format("{0} (β,α)", aero_element), Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105));
                        chart.Titles.Add(t);

                        chart.BorderSkin.SkinStyle = BorderSkinStyle.None;
                        //chart.BorderColor = System.Drawing.Color.FromArgb(26, 59, 105);
                        //chart.BorderlineDashStyle = ChartDashStyle.Solid;
                        //chart.BorderWidth = 2;
                        chart.ImageStorageMode = ImageStorageMode.UseHttpHandler;
                        chart.ImageLocation = String.Format("~/plot_{0}.png", aero_element);
                        //                chart.Legends.Add("Legend1");

                        foreach (var alpha in aero_data_element)
                        {
                            var ck = String.Format("{0}", alpha.Key);
                            chart.Series.Add(ck);
                            chart.Series[ck].ChartType = SeriesChartType.Line;
                            chart.Series[ck].BorderWidth = 3;
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
                        chart.RenderControl(writer);
                        }
                        {
                            var aero_data_element = aero.GetValues_2dAlphaBeta(aero_element);
                            System.Web.UI.DataVisualization.Charting.Chart chart = new System.Web.UI.DataVisualization.Charting.Chart();
                            chart.Width = w * 3;
                            chart.Height = h * 3;
                            chart.Width = w;
                            chart.Height = h;
                            //chart.RenderType = RenderType.ImageTag;
                            var ca1 = chart.ChartAreas.Add("chart");

                            chart.Palette = ChartColorPalette.BrightPastel;
                            Title t = new Title(String.Format("{0} (α,β)", aero_element), Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105));
                            chart.Titles.Add(t);

                            chart.BorderSkin.SkinStyle = BorderSkinStyle.None;
                            //chart.BorderColor = System.Drawing.Color.FromArgb(26, 59, 105);
                            //chart.BorderlineDashStyle = ChartDashStyle.Solid;
                            //chart.BorderWidth = 2;
                            chart.ImageStorageMode = ImageStorageMode.UseHttpHandler;
                            chart.ImageLocation = String.Format("~/plot_{0}.png", aero_element);
                            //                chart.Legends.Add("Legend1");

                            foreach (var alpha in aero_data_element)
                            {
                                var ck = String.Format("{0}", alpha.Key);
                                chart.Series.Add(ck);
                                chart.Series[ck].ChartType = SeriesChartType.Line;
                                chart.Series[ck].BorderWidth = 3;
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
                            chart.RenderControl(writer);
                        }
                    }
                    else
                    {

                        var aero_data_element = aero.GetValues_1d(aero_element);
                        System.Web.UI.DataVisualization.Charting.Chart chart = new System.Web.UI.DataVisualization.Charting.Chart();
                        chart.Width = w;
                        chart.Height = h;
                        //chart.RenderType = RenderType.ImageTag;
                        var ca1 = chart.ChartAreas.Add("chart");

                        chart.Palette = ChartColorPalette.BrightPastel;
                        Title t = new Title(String.Format("{0} (α)", aero_element), Docking.Top, new System.Drawing.Font("Trebuchet MS", 14, System.Drawing.FontStyle.Bold), System.Drawing.Color.FromArgb(26, 59, 105));
                        chart.Titles.Add(t);

                        chart.BorderSkin.SkinStyle = BorderSkinStyle.None;
                        //chart.BorderColor = System.Drawing.Color.FromArgb(26, 59, 105);
                        //chart.BorderlineDashStyle = ChartDashStyle.Solid;
                        //chart.BorderWidth = 2;
                        chart.ImageStorageMode = ImageStorageMode.UseHttpHandler;
                        chart.ImageLocation = String.Format("~/plot_{0}.png", aero_element);
                        //                chart.Legends.Add("Legend1");

                        var series = "data";
                        chart.Series.Add(series);
                        chart.Series[series].ChartType = SeriesChartType.Line;
                        foreach (var q in aero_data_element)
                        {
                            chart.Series[series].Points.AddXY(q.Key, q.Value);
                        }
                        chart.Series[series].BorderWidth = 3;
                        // Render chart control
                        chart.Page = this;
                        chart.RenderControl(writer);
                    }
                }
            }
        }
    }
    }
