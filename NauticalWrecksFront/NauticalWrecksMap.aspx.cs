using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using DataAccessLayer;
using Octokit;


/// <summary>
/// Date            Coder       Version     Comments
/// 2023-02-28      Chido       3.3.2       Original version: Filter by name. Kml file generation from sp_GetAllShapes   
/// 2023-03-03      Chido       3.3.1       Modification. Added postback to prevent the filter from clearing when it loads
///                                         Created a new control for the filter; checks the input parameters, queried db and generates kml.
///                                         Kml filter generation and loading from sp_GetFilteredShapes
///                                         

/// </summary>



namespace NauticalWrecksFront
{
    public partial class NauticalWrecksMap : System.Web.UI.Page
    {
        DataFilterModel filter = null;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                var tool = new DataAccessTool();
                var depth = tool.GetDepthFilter();
                var gear = tool.GetGearFilter();
                var type1 = tool.GetTypeFilterByName("type1");
                var type2 = tool.GetTypeFilterByName("type2");
                var type3 = tool.GetTypeFilterByName("type3");
                var cargo1 = tool.GetCargoFilterByName("cargo1");
                var cargo2 = tool.GetCargoFilterByName("cargo2");
                var cargo3 = tool.GetCargoFilterByName("cargo3");
                var otherCargo = tool.GetCargoFilterByName("OtherCargo");

                DepthDropDownList.DataSource = depth;
                DepthDropDownList.DataValueField = "id";
                DepthDropDownList.DataTextField = "name";
                DepthDropDownList.DataBind();

                Type1DropDownList.DataSource = type1;
                Type1DropDownList.DataValueField = "id";
                Type1DropDownList.DataTextField = "name";
                Type1DropDownList.DataBind();

                Type2DropDownList.DataSource = type2;
                Type2DropDownList.DataValueField = "id";
                Type2DropDownList.DataTextField = "name";
                Type2DropDownList.DataBind();

                Type3DropDownList.DataSource = type3;
                Type3DropDownList.DataValueField = "id";
                Type3DropDownList.DataTextField = "name";
                Type3DropDownList.DataBind();

                Cargo1DropDownList.DataSource = cargo1;
                Cargo1DropDownList.DataValueField = "id";
                Cargo1DropDownList.DataTextField = "name";
                Cargo1DropDownList.DataBind();

                Cargo2DropDownList.DataSource = cargo2;
                Cargo2DropDownList.DataValueField = "id";
                Cargo2DropDownList.DataTextField = "name";
                Cargo2DropDownList.DataBind();

                Cargo3DropDownList.DataSource = cargo3;
                Cargo3DropDownList.DataValueField = "id";
                Cargo3DropDownList.DataTextField = "name";
                Cargo3DropDownList.DataBind();

                OtherCargoDropDownList.DataSource = otherCargo;
                OtherCargoDropDownList.DataValueField = "id";
                OtherCargoDropDownList.DataTextField = "name";
                OtherCargoDropDownList.DataBind();

                GearDropDownList.DataSource = gear;
                GearDropDownList.DataValueField = "id";
                GearDropDownList.DataTextField = "name";
                GearDropDownList.DataBind();

                if (this.IsPostBack)
                {
                    filter = new DataFilterModel
                    {
                        Depth = Request.Form["DepthDropDownList"],
                        Gear = Request.Form["GearDropDownList"],
                        Type1 = Request.Form["Type1DropDownList"],
                        Type2 = Request.Form["Type2DropDownList"],
                        Type3 = Request.Form["Type3DropDownList"],
                        Cargo1 = Request.Form["Cargo3DropDownList"],
                        Cargo2 = Request.Form["Cargo3DropDownList"],
                        Cargo3 = Request.Form["Cargo3DropDownList"],
                        OtherCargo = Request.Form["OtherCargoDropDownList"]
                    };
                    RegisterAsyncTask(new PageAsyncTask(LoadSomeData));

                }
                //writeResults(FormSubmit());
            }
        }

        public async System.Threading.Tasks.Task LoadSomeData()
        {
            CountValues resp = new CountValues();
            var tool = new DataAccessTool();
            resp = await tool.GetData(filter);
            KmlNameProperty.Value = resp.Name;

            lblRecordsCount.Text = resp.Count.ToString();
        }
        public async System.Threading.Tasks.Task LoadFilteredData(List<SearchValues> searchValuesList)
        {
            CountValues resp = new CountValues();
            var tool = new DataAccessTool();
            resp = await tool.GetFilteredShapesData(searchValuesList, filter);
            KmlNameProperty.Value = resp.Name;

            lblRecordsCount.Text = resp.Count.ToString();
        }

        protected async void btnSearchQuery_Click(object sender, EventArgs e)
        {
            lblRecordsCount.Text = string.Empty;
            List<SearchValues> searchValueList = new List<SearchValues>();
            SearchValues searchValues = new SearchValues();int i = 0;
            if (!String.IsNullOrEmpty(DepthDropDownList.SelectedValue)) { searchValueList.Add(new SearchValues("@UserDepth", DepthDropDownList.SelectedValue));  }
            if (!String.IsNullOrEmpty(GearDropDownList.SelectedValue)) { searchValueList.Add(new SearchValues("@UserGear", GearDropDownList.SelectedValue)); }
            if (!String.IsNullOrEmpty(Type1DropDownList.SelectedValue)) { searchValueList.Add(new SearchValues("@Type1", Type1DropDownList.SelectedValue)); }
            if (!String.IsNullOrEmpty(Cargo1DropDownList.SelectedValue)) { searchValueList.Add(new SearchValues("@Cargo1", Cargo1DropDownList.SelectedValue)); }
            await LoadFilteredData(searchValueList);
        }

        protected async void btnGetAllRecords_Click(object sender, EventArgs e)
        {
            await LoadSomeData();
        }
    }
}