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
        protected void Page_Load(object sender, EventArgs e)
        {
            F15Aero aero = F15Aero.Create();
            Response.ContentType = "text/xml";
            var jsbsimo = new CreateJSBSimXML();
            jsbsimo.Output(Page, aero);
        }
    }
}