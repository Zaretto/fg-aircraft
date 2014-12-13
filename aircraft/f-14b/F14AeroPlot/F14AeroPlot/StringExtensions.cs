using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;

namespace F14AeroPlot
{
    public static class StringExtensions
    {
        public static string TruncateAt(this string value, int maxLength)
        {
            return value.Length <= maxLength ? value : value.Substring(0, maxLength);
        }
        public static string TruncateAt(this string value, string terminator)
        {
            if (value.Contains(terminator))
            {
                var idx = value.IndexOf(terminator);
                return value.Substring(0, idx);
            }
            return value;

        }
        public static string AsValidFilename(this string name)
        {
            var invchars = Path.GetInvalidFileNameChars();
            var invchars1 = new[] { '&', ' ', '`', '\'' };

            return String.Join("_",
                        String.Join("_", name.Split(invchars1)).Split(invchars)).Replace("__", "_");

        }
    }
}
