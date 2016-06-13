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
    public partial class F15_JSBsim : System.Web.UI.Page
    {
        protected void Page_Load(object sender, EventArgs e)
        {
            var aero = new F15_VSPAero();
            Response.ContentType = "text/xml";
            var jsbsimo = new CreateJSBSimXML();
            jsbsimo.Output(Page, aero);
        }
    }
}