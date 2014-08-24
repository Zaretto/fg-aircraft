using System;
using System.Collections.Generic;
using System.Drawing;
using System.Linq;
using System.Web;

namespace F14AeroPlot
{
    public class ChartPalette
    {
        // see http://blogs.msdn.com/b/alexgor/archive/2009/10/06/setting-chart-series-colors.aspx
        // http://support2.dundas.com/Default.aspx?article=743
        // http://support2.dundas.com/Articles/743/palette.zip
        public static Color[] AeroPalette =
        {
	        Color.MediumOrchid,
	        Color.LightCoral,
	        Color.SteelBlue,
	        Color.YellowGreen,
	        Color.Turquoise,
	        Color.HotPink,
	        Color.CornflowerBlue,
	        Color.Plum,
	        Color.CadetBlue,
	        Color.FromArgb(255, 128, 0),

	        Color.DarkGoldenrod,
	        Color.FromArgb(192, 64, 0),
	        Color.OliveDrab,
	        Color.Peru,
	        Color.FromArgb(192, 192, 0),
	        Color.ForestGreen,
	        Color.Chocolate,
	        Color.Olive,
	        Color.LightSeaGreen,
	        Color.SandyBrown,
	        Color.FromArgb(0, 192, 0),
	        Color.DarkSeaGreen,
	        Color.Firebrick,
	        Color.SaddleBrown,
	        Color.FromArgb(192, 0, 0),

	        Color.SkyBlue,
	        Color.LimeGreen,

            Color.Green,
	        Color.Blue,
	        Color.Purple,
	        Color.Lime,
	        Color.Fuchsia,
	        Color.Teal,
	        Color.Yellow,
	        Color.Gray,
	        Color.Aqua,
	        Color.Navy,
	        Color.Maroon,
	        Color.Red,
	        Color.Olive,
	        Color.Silver,
	        Color.Tomato,

	        Color.Moccasin,

	        Color.FromArgb(150, 255, 0, 0),

	        Color.FromArgb(150, 0, 255, 0),
	        Color.FromArgb(150, 0, 0, 255),
	        Color.FromArgb(150, 255, 255, 0),
	        Color.FromArgb(150, 0, 255, 255),
	        Color.FromArgb(150, 255, 0, 255),
	        Color.FromArgb(150, 170, 120, 20),
	        Color.FromArgb(80, 255, 0, 0),
	        Color.FromArgb(80, 0, 255, 0),
	        Color.FromArgb(80, 0, 0, 255),
	        Color.FromArgb(80, 255, 255, 0),
	        Color.FromArgb(80, 0, 255, 255),
	        Color.FromArgb(80, 255, 0, 255),
	        Color.FromArgb(80, 170, 120, 20),
	        Color.FromArgb(150, 100, 120, 50),
	        Color.FromArgb(150, 40, 90, 150),

	        Color.Lavender,
	        Color.LavenderBlush,
	        Color.PeachPuff,
	        Color.LemonChiffon,
	        Color.MistyRose,
	        Color.Honeydew,
	        Color.AliceBlue,
	        Color.WhiteSmoke,
	        Color.AntiqueWhite,

	        Color.LightCyan,

	        Color.FromArgb(153,153,255),

	        Color.FromArgb(153,51,102),
	        Color.FromArgb(255,255,204),
	        Color.FromArgb(204,255,255),
	        Color.FromArgb(102,0,102),
	        Color.FromArgb(255,128,128),
	        Color.FromArgb(0,102,204),
	        Color.FromArgb(204,204,255),
	        Color.FromArgb(0,0,128),
	        Color.FromArgb(255,0,255),
	        Color.FromArgb(255,255,0),
	        Color.FromArgb(0,255,255),
	        Color.FromArgb(128,0,128),
	        Color.FromArgb(128,0,0),
	        Color.FromArgb(0,128,128),
	        Color.FromArgb(0,0,255),

	        Color.BlueViolet,
	        Color.MediumOrchid,
	        Color.RoyalBlue,
	        Color.MediumVioletRed,
	        Color.Blue,
	        Color.BlueViolet,
	        Color.Orchid,
	        Color.MediumSlateBlue,
	        Color.FromArgb(192, 0, 192),
	        Color.MediumBlue,

	        Color.Purple,

	        Color.Sienna,

	        Color.Chocolate,
	        Color.DarkRed,
	        Color.Peru,
	        Color.Brown,
	        Color.SandyBrown,
	        Color.SaddleBrown,
	        Color.FromArgb(192, 64, 0),
	        Color.Firebrick,
	        Color.FromArgb(182, 92, 58),

	        Color.Gold,
	        Color.Red,
	        Color.DeepPink,
	        Color.Crimson,
	        Color.DarkOrange,
	        Color.Magenta,
	        Color.Yellow,
	        Color.OrangeRed,
	        Color.MediumVioletRed,
	        Color.FromArgb(221, 226, 33),

	        Color.SeaGreen,
	        Color.MediumAquamarine,
	        Color.SteelBlue,
	        Color.DarkCyan,
	        Color.CadetBlue,
	        Color.MediumSeaGreen,
	        Color.MediumTurquoise,
	        Color.LightSteelBlue,
	        Color.DarkSeaGreen,

	        Color.SkyBlue,

            Color.FromArgb(65, 140, 240),

            Color.FromArgb(252, 180, 65),
            Color.FromArgb(224, 64, 10),
            Color.FromArgb(5, 100, 146),
            Color.FromArgb(191, 191, 191),
            Color.FromArgb(26, 59, 105),
            Color.FromArgb(255, 227, 130),
            Color.FromArgb(18, 156, 221),
            Color.FromArgb(202, 107, 75),
            Color.FromArgb(0, 92, 219),
            Color.FromArgb(243, 210, 136),
            Color.FromArgb(80, 99, 129),
            Color.FromArgb(241, 185, 168),
            Color.FromArgb(224, 131, 10),
            Color.FromArgb(120, 147, 190)
        };
    }
}