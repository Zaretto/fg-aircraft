using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;

namespace F14AeroPlot
{
    public struct AeroElement
    {
        public Double[] data;
        public string description;
    }
    public class AeroReader
    {
        public static string DefPath = @"C:\Users\Richard\dev\flightgear\aircraft\f-14b\F14AeroPlot\F14AeroPlot\";
        public Dictionary<string, AeroElement> aero { get; set; }
        private Dictionary<string, bool> used { get; set; }
        
        public Dictionary<string, string> aero_extra_ivars {get;set;}

        public IEnumerable<String> GetElements()
        {
            return aero.Select(xx => xx.Key).ToList();
        }
        internal string GetDescription(string aero_element)
        {
            return aero_element;
        }
        public bool Is2d(string key)
        {
            return aero[key].data.Length > 20;
        }
        public List<string> GetExtraIndependantVariables(string key)
        {
            var v = "";
            if (aero_extra_ivars.ContainsKey(key))
                v = aero_extra_ivars[key];
            if (String.IsNullOrEmpty(v))
                return new List<string>();
            else
                return v.Split(',').ToList();
        }
        public string Description(string key)
        {
            return aero[key].description;
        }

        internal bool HasData(string key)
        {
            var dat = aero[key];
            foreach (var v in dat.data)
            {
                if (v != 0)
                    return true;
            }
            return false;
        }
        public Dictionary<int, double> GetValues_1d(string key)
        {
            var tab = aero[key]; int ix = 0;
            //
            // handle special case of extra computed vars.
            if (tab.data.Count() == 1)
                return null;

            var rd = new Dictionary<int, double>();
            for (var alpha = 0; alpha <= 55; alpha += 5)
                rd[alpha] = tab.data[ix++];
            return rd;
        }

        internal Dictionary<int, Dictionary<int, Double>> GetValues_2dBetaAlpha(string aero_element)
        {
            var tab = aero[aero_element];
            var rv = new Dictionary<int, Dictionary<int, Double>>();
            var cldata = new Dictionary<int, Dictionary<int, Double>>();
            /* For functions of α and β, β is incremented first, then α, 
             * * i.e.:
             * 1.(0,-20), (0,-15), (0,-10), (0,-5), (0,0), 
             * 2.(0,5), (0,10), (0,15), (0,20), (5,-20), 
             * ...
             * 21.(55,-15), (55,-10), (55,-5), (55,0), (55,5), 
             * 22.(55,10), (55,15), (55,20),  (0), (0)
            */
            var betaSize = 9;
            var alphaSize = 12;
            for (var betaIdx = 0; betaIdx < betaSize; betaIdx++)
            {
                var beta = (betaIdx - 4) * 5;
                cldata[beta] = new Dictionary<int, double>();
                for (var alphaIdx = 0; alphaIdx < alphaSize; alphaIdx++)
                {
                    var alpha = alphaIdx*5;
                    cldata[beta][alpha] = tab.data[betaIdx + (alphaIdx * betaSize)];
                }
            }
            return cldata;
        }
        public Dictionary<int, Dictionary<int, Double>> GetValues_2dAlphaBeta(string key)
        {
            var tab = aero[key];
            var cldata = new Dictionary<int, Dictionary<int, Double>>();

            int ix = 0;
            for (var alpha = 0; alpha <= 55; alpha += 5)
            {
                cldata[alpha] = new Dictionary<int, Double>();

                for (var beta = -20; beta <= 20; beta += 5)
                {
                    cldata[alpha][beta] = tab.data[ix++];
                }
            }
            return cldata;
        }
        public bool IsUsed(string key)
        {
            return !key.StartsWith("x") && !key.Contains(":x");
        }

        public AeroReader()
        {
            aero = new Dictionary<string, AeroElement>();
            used = new Dictionary<string, bool>();
            bool? is_used = null;
            
            var inputFilePath = @"E:\users\richard\dropbox\f14aero.txt";
            //inputFilePath = @"F14AeroPlotf14aero.txt";
            inputFilePath = DefPath + "f14aero.txt";
            //var s = File.OpenText(, );
            using (var s = new StreamReader(inputFilePath, System.Text.Encoding.Unicode, true))
            {
                string line, lc = "";
                var data = new List<Double>();
                var ivars= new List<string>();
                aero_extra_ivars = new Dictionary<string,string>();
                var description = "";

                var in_data = false;
                int lineNumber = 0;
                while ((line = s.ReadLine()) != null)
                {
                    lineNumber++;
                    var colNumber = 0;

                    if (line.StartsWith("/="))
                    {
                        is_used = true;
                        data.Clear();
                        data.Add(1);
                    }
                    else if (line.StartsWith("*+"))
                    {
                        ivars.Add(line.Replace("*+",""));
                    }
                    else if (line.StartsWith("*--- "))
                    {
                        description += line.Replace("*--- ","");
                    }
                    else if (line.StartsWith("*"))
                    {
                        var element = lc;
                        lc = line;
                        if (in_data)
                            is_used = null;
                        in_data = false;
                        if (data.Any())
                        {
                            //foreach (var v in data)
                            //{
                            //    System.Console.Write("{0,3} ", v);
                            //}
                            //System.Console.WriteLine("");
                            element = get_ivname(element);
                            aero[element] = new AeroElement
                            {
                                data = data.ToArray(),
                                description = description
                            };
                            description = "";      
                            aero_extra_ivars[element] = String.Join(",",ivars);
                            if (is_used.HasValue)
                                used[element] = is_used.Value;
                            else
                                used[element] = true;
                        }
                        ivars.Clear();
                        data.Clear();
                    }
                    else
                    {
if (!string.IsNullOrEmpty(line))
                        {
                            //Console.WriteLine(line);
                            if (!in_data)
                            {
                                Console.WriteLine("\n{0}", lc);
                                in_data = true;
                            }
                            if (in_data)
                            {
                                var dl = line.Replace("\t", ",").Replace(" ", "");
                                var vals = dl.Split(',');
                                foreach (var _v in vals)
                                {
                                    if (!string.IsNullOrEmpty(_v))
                                    {
                                        var v = _v;
                                        if (v == "0.") v = "0";
                                        else if (v.StartsWith(".")) v = "0" + v;
                                        colNumber++;
                                        Double q;
                                        try
                                        {
                                            q = Double.Parse(v, System.Globalization.NumberStyles.Float);
                                            data.Add(q);
                                        }
                                        catch (Exception ex)
                                        {
                                            System.Console.WriteLine("{0}{1}: {2} Badv {3}", lineNumber, colNumber, v, ex.Message);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        private static string get_ivname(string element)
        {
            element = element.Replace("*", "").Trim();
            var xx = element.IndexOf("(");
            if (xx > 0)
                element = element.Remove(xx);
            return element;
        }
    }
}