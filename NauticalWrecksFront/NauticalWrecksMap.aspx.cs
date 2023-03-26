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
        FilterType selectedFilter = FilterType.Cargo;
        object selectedValue;

        protected void Page_Load(object sender, EventArgs e)
        {
            try
            {
                if (!Page.IsPostBack)
                {
                    var tool = new DataAccessTool();
                    var depth = tool.GetDepthFilter();
                    var gear = tool.GetGearFilter();
                    var type = tool.GetTypeFilterByName("type");
                    var cargo = tool.GetCargoFilterByName("cargo");
                    var startDate = tool.GetStartDateFilter();
                    var endDate = tool.GetEndDateFilter();

                    DepthDropDownList.DataSource = depth;
                    DepthDropDownList.DataValueField = "id";
                    DepthDropDownList.DataTextField = "name";
                    DepthDropDownList.DataBind();

                    TypeDropDownList.DataSource = type;
                    TypeDropDownList.DataValueField = "id";
                    TypeDropDownList.DataTextField = "name";
                    TypeDropDownList.DataBind();

                    CargoDropDownList.DataSource = cargo;
                    CargoDropDownList.DataValueField = "id";
                    CargoDropDownList.DataTextField = "name";
                    CargoDropDownList.DataBind();


                    GearDropDownList.DataSource = gear;
                    GearDropDownList.DataValueField = "id";
                    GearDropDownList.DataTextField = "name";
                    GearDropDownList.DataBind();

                    StartDateDropDownList.DataSource = startDate;
                    StartDateDropDownList.DataValueField = "id";
                    StartDateDropDownList.DataTextField = "name";
                    StartDateDropDownList.DataBind();

                    EndDateDropDownList.DataSource = endDate;
                    EndDateDropDownList.DataValueField = "id";
                    EndDateDropDownList.DataTextField = "name";
                    EndDateDropDownList.DataBind();


                    //writeResults(FormSubmit());
                }

                if (this.IsPostBack)
                {
                    //filter = new DataFilterModel
                    //{
                    //    Depth = Convert.ToDecimal(Request.Form["DepthDropDownList"]),
                    //    Gear = Request.Form["GearDropDownList"],
                    //    Type = Request.Form["TypeDropDownList"],
                    //    Cargo = Request.Form["CargoDropDownList"],
                    //    StartDate = Request.Form["Cargo3DropDownList"],
                    //    EndDate = Request.Form["Cargo3DropDownList"],
                    //    OtherCargo = Request.Form["OtherCargoDropDownList"]
                    //};
                    RegisterAsyncTask(new PageAsyncTask(LoadFilteredData));

                }
            }
            catch
            {

            }
        }

        public async System.Threading.Tasks.Task LoadSomeData()
        {
            try
            {
                CountValues resp = new CountValues();
                var tool = new DataAccessTool();
                resp = await tool.GetData();
                KmlNameProperty.Value = resp.Name;

                lblRecordsCount.Text = resp.Count.ToString();
            }
            catch
            {

            }
        }

        public async System.Threading.Tasks.Task LoadFilteredData(List<SearchValues> searchValuesList)
        {
            try
            {
                CountValues resp = new CountValues();
                var tool = new DataAccessTool();
                resp = await tool.GetFilteredShapesData(searchValuesList, filter);
                KmlNameProperty.Value = resp.Name;

                lblRecordsCount.Text = resp.Count.ToString();
            }
            catch { }
        }

        public async System.Threading.Tasks.Task LoadFilteredData()
        {
            try
            {
                if (selectedValue != null)
                {
                    CountValues resp = new CountValues();
                    var tool = new DataAccessTool();
                    resp = await tool.GetFilteredShapesData(selectedFilter, selectedValue);
                    KmlNameProperty.Value = resp.Name;
                    lblRecordsCount.Text = resp.Count.ToString();
                }
            }
            catch { }
        }

        protected async void btnSearchQuery_Click(object sender, EventArgs e)
        {
            lblRecordsCount.Text = string.Empty;
            //List<SearchValues> searchValueList = new List<SearchValues>();
            //SearchValues searchValues = new SearchValues();int i = 0;
            //if (!String.IsNullOrEmpty(DepthDropDownList.SelectedValue)) { searchValueList.Add(new SearchValues("@UserDepth", DepthDropDownList.SelectedValue));  }
            //if (!String.IsNullOrEmpty(GearDropDownList.SelectedValue)) { searchValueList.Add(new SearchValues("@UserGear", GearDropDownList.SelectedValue)); }
            //if (!String.IsNullOrEmpty(TypeDropDownList.SelectedValue)) { searchValueList.Add(new SearchValues("@Type1", TypeDropDownList.SelectedValue)); }
            //if (!String.IsNullOrEmpty(CargoDropDownList.SelectedValue)) { searchValueList.Add(new SearchValues("@Cargo1", CargoDropDownList.SelectedValue)); }
            //await LoadFilteredData(searchValueList);
            await LoadFilteredData();
        }

        protected async void btnGetAllRecords_Click(object sender, EventArgs e)
        {
            await LoadSomeData();
        }

        protected void CargoDropDownList_SelectedIndexChanged(object sender, EventArgs e)
        {
            selectedFilter = FilterType.Cargo;
            selectedValue = Request.Form["CargoDropDownList"];
            TypeDropDownList.ClearSelection();
            DepthDropDownList.ClearSelection();
            GearDropDownList.ClearSelection();
            StartDateDropDownList.ClearSelection();
            EndDateDropDownList.ClearSelection();
        }

        protected void TypeDropDownList_SelectedIndexChanged(object sender, EventArgs e)
        {
            selectedFilter = FilterType.Type;
            selectedValue = Request.Form["TypeDropDownList"];
            CargoDropDownList.ClearSelection();
            DepthDropDownList.ClearSelection();
            GearDropDownList.ClearSelection();
            StartDateDropDownList.ClearSelection();
            EndDateDropDownList.ClearSelection();
        }

        protected void GearDropDownList_SelectedIndexChanged(object sender, EventArgs e)
        {
            selectedFilter = FilterType.Gear;
            selectedValue = Request.Form["GearDropDownList"];
            TypeDropDownList.ClearSelection();
            DepthDropDownList.ClearSelection();
            CargoDropDownList.ClearSelection();
            StartDateDropDownList.ClearSelection();
            EndDateDropDownList.ClearSelection();
        }

        protected void DepthDropDownList_SelectedIndexChanged(object sender, EventArgs e)
        {
            selectedFilter = FilterType.Depth;
            selectedValue = Convert.ToDecimal(Request.Form["DepthDropDownList"]);
            TypeDropDownList.ClearSelection();
            CargoDropDownList.ClearSelection();
            GearDropDownList.ClearSelection();
            StartDateDropDownList.ClearSelection();
            EndDateDropDownList.ClearSelection();
        }

        protected void StartDateDropDownList_SelectedIndexChanged(object sender, EventArgs e)
        {
            selectedFilter = FilterType.StartDate;
            selectedValue = Convert.ToDecimal(Request.Form["StartDateDropDownList"]);
            TypeDropDownList.ClearSelection();
            DepthDropDownList.ClearSelection();
            GearDropDownList.ClearSelection();
            CargoDropDownList.ClearSelection();
            EndDateDropDownList.ClearSelection();
        }

        protected void EndDateDropDownList_SelectedIndexChanged(object sender, EventArgs e)
        {
            selectedFilter = FilterType.EndDate;
            selectedValue = Convert.ToDecimal(Request.Form["EndDateDropDownList"]);
            TypeDropDownList.ClearSelection();
            DepthDropDownList.ClearSelection();
            GearDropDownList.ClearSelection();
            StartDateDropDownList.ClearSelection();
            CargoDropDownList.ClearSelection();
        }
    }
}