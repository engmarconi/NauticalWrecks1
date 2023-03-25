using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using SharpKml.Base;
using SharpKml.Dom;
using SharpKml.Engine;
using SharpKml.Dom.GX;
using GeoTools_Objects;
using System.IO;
using Octokit;
using System.Data.SqlClient;
using System.Data;
using System.Web;

/// <summary>
/// Date            Coder       Version     Comments
/// 2023-01-25      Spencer     1.0         Initial build; implemented code blocks for accessing database, 
///                                         creating placemarks from point data, and writing a new .kml file for testing.
/// 2023-01-27      Spencer     1.0.1       Updated code to test with DB_Toril from last semester while our data is being 
///                                         scrubbed & our own project database is built out. Commented out the file save 
///                                         code block here because a much simpler version is included in BasicApp.
/// 2023-02-09      Spencer     1.0.2       Modified connection string to reference our specific project DB as named in SQL. 
///                                         Changed elements of GetAllShapes() function to match our @tbl_Shipwreck structure/field mapping.
/// 2023-02-13      Spencer     1.1         Finished adjusting code to match data intake from sp_GetAllShapes and built a very limited 
///                                         placemark description/pop-up to test that the code is working correctly. This program will successufully
///                                         read our SQL database and point data (shapestrings), create placemarks, and add them to a list for the BasicApp.cs.
/// 2023-02-13      Spencer     1.1.1       Tried another method for referencing GeoTools_Objects that should work when promoting the solution on other devices.                                
/// 2023-02-21      Chido       3.1.1       Updated the fields for the pop-up/placemark information on the KML to reflect Guili's update on the Stored Procedure. 
///                                         This is to enable the required fields to be displayed as pop-ups on the map.   
/// 2023-02-27      Chido       3.2.1       Revamped the Console apps to be class libraries to enable them to be used inside the Frontend aspx app.                                   
/// 2023-03-28      Chido       3.3.1       Tried a new method to have the kml file written to a web repo (https://github.com/Dhalizm/NauticalWrecks). Implemented Code for writing KML file to a web repo to enable google maps display. 
/// 2023-03-01      Chido       3.3.2       Introduced the filters.
/// 2023-03-03      Chido       3.3.3       Added the sp_SetFilteredShapes
///                                         Generation of kml for the filters
///                                         Created 2 classes; (1) for the filters, and (2) for the records counter
///                                         
/// </summary>



namespace DataAccessLayer
{
    
    public class DataAccessTool
    {
        private static String GetConnectionString()
        {
            //Change connection string for each user, DB name to match project
            //return @"Server=DESKTOP-AH6EVAP;Database=DB_shipwreck;Trusted_Connection=Yes;";
            return @"Server=DHALIZM;Database=DB_shipwreck;Trusted_Connection=Yes;";
            //SCIPIO-AFRICANU
            //DHALIZM
            //localhost
        }

        //Creates a list of placemarks using our database. Fields from DB build the name & description info
        public List<Placemark> GetAllShapes(DataFilterModel dataFilterModel = null)
        {
            List<Placemark> Shapes = new List<Placemark>();

            System.Data.SqlClient.SqlDataReader t;

            Style s = new SharpKml.Dom.Style();
            //String text = "";
            //int ID = 0;
            try
            {
                //SP call in this line needs to match procedure written in SQL
                using (var conn = new SqlConnection(GetConnectionString()))
                {
                    using (var command = new SqlCommand("sp_GetAllShapes", conn)
                    {
                        CommandType = CommandType.StoredProcedure
                    })
                    {
                        conn.Open();
                        t = command.ExecuteReader(); // PDM.Data.SqlHelper.ExecuteReader(GetConnectionString(), "sp_GetAllShapes");
                        if (t.HasRows)
                        {
                            while (t.Read())
                            {
                                //ID = t.GetInt32(0);

                                //Make a note here of how the fields map to the data in sp_GetAllShapes results
                                //
                                //0 - ShipID                
                                //1 - Name1                 
                                //2 - Name2
                                //3 - WreckID2008
                                //4 - Latitude
                                //5 - Longitude
                                //6 - ShapeString
                                //7 - Geo
                                //8 - GeoQ
                                //9 - StartDate
                                //10 - EndDate
                                //11 - DateQ
                                //12 - YearFound
                                //13 - YearFoundQ
                                //14 - CargoID
                                //15 - TypeID
                                //16 - GearID
                                //17 - DepthID
                                //18 - EstimatedCapacity
                                //19 - Comments
                                //20 - Lngth
                                //21 - Width
                                //22 - SizeestimateQ
                                //23 - Parkerreference
                                //24 - Bibliographyandnotes

                                try
                                {
                                    //Change iteration to match database (follows the order of the SP)
                                    //String ID = t[0].ToString();
                                    String Name1 = t[0].ToString();
                                    String Name2 = t[1].ToString();
                                    String WreckID2008 = t[2].ToString();
                                    String Latitude = t[3].ToString();
                                    String Longitude = t[4].ToString();
                                    String Shape = t[5].ToString();
                                    //text = Shape;
                                    //String Geo = t[6].ToString();
                                    String GeoQ = t[7].ToString();
                                    String StartDate = t[8].ToString();
                                    String EndDate = t[9].ToString();
                                    String DateQ = t[10].ToString();
                                    String YearFound = t[11].ToString();
                                    String YearFoundQ = t[12].ToString();
                                    String CargoFK = t[13].ToString();
                                    String Cargo1 = t[14].ToString();
                                    String Cargo2 = t[15].ToString();
                                    String Cargo3 = t[16].ToString();
                                    String OtherCargo = t[17].ToString();
                                    String TypeFK = t[18].ToString();
                                    String Type1 = t[19].ToString();
                                    String Type2 = t[20].ToString();
                                    String Type3 = t[21].ToString();
                                    String GearFK = t[22].ToString();
                                    String Gear = t[23].ToString();
                                    String DepthFK = t[24].ToString();
                                    String Depth = t[25].ToString();
                                    String EstimatedCapacity = t[26].ToString();
                                    String Comments = t[27].ToString();
                                    String Length = t[28].ToString();
                                    String Width = t[29].ToString();
                                    String SizeestimateQ = t[30].ToString();
                                    String Parkerreference = t[31].ToString();
                                    String Bibliography = t[32].ToString();

                                    if (dataFilterModel != null)
                                    {
                                        if (dataFilterModel.Depth != "" && Depth == dataFilterModel.Depth)
                                            continue;

                                        if (dataFilterModel.Gear != "" && Gear == dataFilterModel.Gear)
                                            continue;

                                        if (dataFilterModel.Type1 != "" && Type1 != dataFilterModel.Type1)
                                            continue;

                                        if (dataFilterModel.Type2 != "" && Type2 != dataFilterModel.Type3)
                                            continue;

                                        if (dataFilterModel.Type3 != "" && Type3 != dataFilterModel.Type3)
                                            continue;

                                        if (dataFilterModel.Cargo1 != "" && Cargo1 != dataFilterModel.Cargo1)
                                            continue;

                                        if (dataFilterModel.Cargo2 != "" && Cargo2 != dataFilterModel.Cargo2)
                                            continue;

                                        if (dataFilterModel.Cargo3 != "" && Cargo3 != dataFilterModel.Cargo3)
                                            continue;

                                        if (dataFilterModel.OtherCargo != "" && OtherCargo != dataFilterModel.OtherCargo)
                                            continue;


                                    }

                                    //String Cargo2 = t[25].ToString();
                                    //String Cargo3 = t[26].ToString();
                                    //String OtherCargo = t[27].ToString();

                                    if (Shape.Contains("POINT"))
                                    {
                                        //Style placemark
                                        s.Icon = new IconStyle();
                                        s.Icon.Scale = 1;
                                        s.Icon.Color = new Color32(255, 255, 255, 255);
                                        s.Label = new LabelStyle();
                                        s.Label.Scale = 1;
                                        s.Label.Color = new Color32(255, 255, 255, 255);

                                        //Clean the ShapeString
                                        Shape = Shape.Replace("POINT", "");
                                        Shape = Shape.Replace("  ", " ");
                                        Shape = Shape.Replace("(", "");
                                        Shape = Shape.Replace(")", "");

                                        Shape = Shape.Trim();

                                        //Break the string up
                                        String[] b = Shape.Split(' ');

                                        //Converts string input data to usable coordinate with altitude 0
                                        Coordinate C = new Coordinate(Double.Parse(b[1]), Double.Parse(b[0]), 0);

                                        //Translates coordinate to .kml placemark
                                        Placemark P = C.ToPlaceMark();

                                        //Uses input data for additional placemark info (can be modified to begin generating pop-up data)
                                        P.Name = t[1].ToString();
                                        SharpKml.Dom.Description D = new SharpKml.Dom.Description();
                                        D.Text = "Name 1: " + Name1 + Environment.NewLine +
                                                 "Name 2: " + Name2 + Environment.NewLine +
                                                 "Start Date: " + StartDate + Environment.NewLine +
                                                 "End Date: " + EndDate + Environment.NewLine +
                                                 "Data source: " + Bibliography +
                                                 "DateQ: " + DateQ + Environment.NewLine +
                                                 "YearFound: " + YearFound + Environment.NewLine +
                                                 "Cargo1: " + Cargo1 + Environment.NewLine +
                                                 "Cargo2: " + Cargo2 + Environment.NewLine +
                                                 "Cargo3: " + Cargo3 + Environment.NewLine +
                                                 "OtherCargo: " + OtherCargo + Environment.NewLine +
                                                 "Type1: " + Type1 + Environment.NewLine +
                                                 "Type2: " + Type2 + Environment.NewLine +
                                                 "Type3: " + Type3 + Environment.NewLine +
                                                 "Width: " + Width + Environment.NewLine +
                                                 "Capacity: " + EstimatedCapacity + Environment.NewLine +
                                                 "Comments: " + Comments + Environment.NewLine +
                                                 "Length: " + Length + Environment.NewLine +
                                                 "Width: " + Width + Environment.NewLine +
                                                 "Data source: " + Bibliography;

                                        P.Description = D.Clone();
                                        P.Id = t[0].ToString();

                                        P.AddStyle(s.Clone());

                                        //Adds new placemark to Placemark List and moves on to the next record
                                        Shapes.Add(P.Clone());

                                    }
                                }
                                catch (Exception ex)
                                {
                                    //What goes here?
                                }
                            }
                        }
                    }
                }

         
            }
            catch (Exception ex)
            {
                //What goes here?
            }

            //Returns the list of created placemarks to the variable declared in BasicApp.cs (PointData)
            return Shapes;




            ///////////////Commented out for now because the file save code is included in BasicApp, but keeping this here in case we need to implement it later//////////////////

            //bool WriteKmlFile(List<Placemark> placemarks, String FileName)
            //{
            //   var Document = new Document();

            //   Document.Id = $"Nautical Wrecks Framework Build: {Environment.UserName}:{DateTime.Now}";
            //   Document.Name = $"{DateTime.Now}";

            //   Description description = new Description();
            //   description.Text = @"<h1>Shipwreck Locator Mapped Points>/h1>";

            //   foreach (Placemark placemark in placemarks)
            //   {
            //       Document.AddFeature(placemark.Clone());
            //   }

            //   var kml = new Kml();
            //   kml.Feature = Document;

            //   KmlFile kmlfile = KmlFile.Create(kml, true);

            //   using (var stream = System.IO.File.Create(FileName))
            //   {
            //       kmlfile.Save(stream);
            //   }

            //   if (placemarks.Count > 0)
            //   {
            //       return true;
            //   }
            //   else
            //   {
            //       return false;
            //   }


            ////Instantiate a new data tool variable to make database call
            //DataAccess.DataAccessTool DataImport = new DataAccessTool();

            ////Instantiate Placemark List variable to store data as it comes in from the data tool
            //List<Placemark> PointData = DataImport.GetAllShapes();

            ////Write list of created placemarks to a new .kml file (changed to a network file in the future)
            ////By default the .kml file is saved to the solution folder -> NauticalWrecks -> NauticalWrecks -> bin -> debug

            //Document document = new Document();
            //foreach (Placemark p in PointData)
            //{
            //    document.AddFeature(p);
            //}


            //KmlFile kml = KmlFile.Create(document, true);

            //using (FileStream stream = File.Create("ShipwreckPointData.kml"))
            //{
            //    kml.Save(stream);
            //}

            ////This output string is the verification that the data is writing to a new KML. It'll crash Google Earth until we can fix the SQL joins/duplicates issue.

            //Console.WriteLine("{0} data records saved to KML file.", PointData.Count);
            //Console.ReadLine();




        }

        public List<dynamic> GetDepthFilter()
        {
            List<dynamic> types = new List<dynamic>();
            types.Add(new { id = "", name = "" });
            using (var conn = new SqlConnection(GetConnectionString()))
            {
                using (var command = new SqlCommand($"select DISTINCT Depth from [DB_shipwreck].[dbo].[tbl_Depth] ORDER BY Depth", conn))
                {
                    conn.Open();
                    var t = command.ExecuteReader();
                    if (t.HasRows)
                    {
                        while (t.Read())
                        {
                            if (t[0].ToString() != null && t[0].ToString() != "")
                                types.Add(new { id = t[0].ToString(), name = t[0].ToString() });
                        }
                    }
                }
            }
            return types;
        }

        public List<dynamic> GetGearFilter()
        {
            List<dynamic> types = new List<dynamic>();
            types.Add(new { id = "", name = "" });
            using (var conn = new SqlConnection(GetConnectionString()))
            {
                using (var command = new SqlCommand($"select DISTINCT [Gear] from [DB_shipwreck].[dbo].[tbl_Gear] ORDER BY Gear", conn))
                {
                    conn.Open();
                    var t = command.ExecuteReader();
                    if (t.HasRows)
                    {
                        while (t.Read())
                        {
                            if (t[0].ToString() != null && t[0].ToString() != "")
                                types.Add(new { id = t[0].ToString(), name = t[0].ToString() });
                        }
                    }
                }
            }
            return types;
        }

        public List<dynamic> GetTypeFilterByName(string name)
        {
            List<dynamic> types = new List<dynamic>();
            types.Add(new { id = "", name = "" });
            using (var conn = new SqlConnection(GetConnectionString()))
            {
                using (var command = new SqlCommand($"select DISTINCT {name} from [DB_shipwreck].[dbo].[tbl_Type] ORDER BY {name}", conn))
                {
                    conn.Open();
                    var t = command.ExecuteReader();
                    if (t.HasRows)
                    {
                        while (t.Read())
                        {
                            if (t[0].ToString() != null && t[0].ToString() != "")
                                types.Add(new { id = t[0].ToString(), name = t[0].ToString() });
                        }
                    }
                }
            }
            return types;
        }

        public List<dynamic> GetCargoFilterByName(string name)
        {
            List<dynamic> types = new List<dynamic>();
            types.Add(new { id = "", name = "" });
            using (var conn = new SqlConnection(GetConnectionString()))
            {
                using (var command = new SqlCommand($"select DISTINCT {name} from [DB_shipwreck].[dbo].[tbl_Cargo] ORDER BY {name}", conn))
                {
                    conn.Open();
                    var t = command.ExecuteReader();
                    if (t.HasRows)
                    {
                        while (t.Read())
                        {
                            if (t[0].ToString() != null && t[0].ToString() != "")
                                types.Add(new { id = t[0].ToString(), name = t[0].ToString() });
                        }
                    }
                }
            }
            return types;
        }


        public async Task<CountValues> GetData(DataFilterModel dataFilterModel)
        {
            CountValues resp = new CountValues();
            DataAccessTool DataImport = new DataAccessTool();

            //Instantiate Placemark List variable to store data as it comes in from the data tool
            List<Placemark> PointData = DataImport.GetAllShapes(dataFilterModel);
            resp.Count = PointData.Count;

            //Write list of created placemarks to a new .kml file (changed to a network file in the future)
            //By default the .kml file is saved to the solution folder -> NauticalWrecks -> NauticalWrecks -> bin -> debug

            Document document = new Document();
            foreach (Placemark p in PointData)
            {
                document.AddFeature(p);
            }

            string name = $"ShipwreckPointData_{DateTime.Now.ToFileTime()}.kml";
            string _path = Path.Combine(System.AppDomain.CurrentDomain.BaseDirectory, name);
            KmlFile kml = KmlFile.Create(document, true);
            using (FileStream stream = File.Create(_path))
            {
                kml.Save(stream);
            }
            await UpdateKmlOnGithubAsync(_path, name);
            resp.Name = name;
            return resp;
        }

        async Task UpdateKmlOnGithubAsync(string filename, string name)
        {
            var gitHubClient = new GitHubClient(new ProductHeaderValue("NauticalWrecksApp"));
            gitHubClient.Credentials = new Credentials("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");
            var (owner, repoName, filePath, branch) = ("Dhalizm", "NauticalWrecks",
                    name, "main");

            var kmlContent = ReadKml(filename);
            try
            {
                var existingFile = await gitHubClient.Repository.Content.GetAllContentsByRef(owner, repoName, filePath, branch);
                await gitHubClient.Repository.Content.UpdateFile(owner, repoName, filePath,
               new UpdateFileRequest("kml update file-" + DateTime.UtcNow, kmlContent, existingFile.First().Sha, branch));
            }
            catch (Octokit.NotFoundException)
            {
                await gitHubClient.Repository.Content.CreateFile(
                   owner, repoName, filePath,
                   new CreateFileRequest($"First kml commit for {filePath}", kmlContent, branch));
            }
        }

        string ReadKml(string filename)
        {
            var sb = new StringBuilder("");
            using (var sr = new StreamReader(filename))
            {
                var content = sr.ReadToEnd();
                sb.Append(content);
            }
            return sb.ToString();
        }
        public async Task<CountValues> GetFilteredShapesData(List<SearchValues> searchParam, DataFilterModel dataFilterModel)
        {
            CountValues resp = new CountValues();
            DataAccessTool DataImport = new DataAccessTool();

            //Instantiate Placemark List variable to store data as it comes in from the data tool
            List<Placemark> PointData = DataImport.GetFilteredShapes(searchParam, dataFilterModel);

            //Write list of created placemarks to a new .kml file (changed to a network file in the future)
            //By default the .kml file is saved to the solution folder -> NauticalWrecks -> NauticalWrecks -> bin -> debug

            Document document = new Document();
            foreach (Placemark p in PointData)
            {
                document.AddFeature(p);
            }

            string name = $"ShipwreckFilteredPointData_{DateTime.Now.ToFileTime()}.kml";
            string _path = Path.Combine(System.AppDomain.CurrentDomain.BaseDirectory, name);
            KmlFile kml = KmlFile.Create(document, true);
            using (FileStream stream = File.Create(_path))
            {
                kml.Save(stream);
            }
            await UpdateKmlOnGithubAsync(_path, name);
            resp.Count = PointData.Count();
            resp.Name = name;
            return resp;
        }
        public List<Placemark> GetFilteredShapes(List<SearchValues> searchParam, DataFilterModel dataFilterModel = null)
        {
            DataAccessTool DataImport = new DataAccessTool();
            List<Placemark> Shapes = new List<Placemark>();
            DataTable table = new DataTable();
            System.Data.SqlClient.SqlDataReader t;

            Style s = new SharpKml.Dom.Style();
            //String text = "";
            //int ID = 0;
            try
            {
                //SP call in this line needs to match procedure written in SQL
                using (var conn = new SqlConnection(GetConnectionString()))
                {
                    string dynamicSP = string.Empty;

                    using (var command = new SqlCommand("sp_GetFilteredShapes", conn)
                    {
                        CommandType = CommandType.StoredProcedure
                    })
                    {
                        for (int i = 0; i < searchParam.Count; i++) { command.Parameters.Add(searchParam[i].Parameter, SqlDbType.VarChar).Value = searchParam[i].Value; }

                        conn.Open();
                        t = command.ExecuteReader(); // PDM.Data.SqlHelper.ExecuteReader(GetConnectionString(), "sp_GetAllShapes");
                        if (t.HasRows)
                        {
                            while (t.Read())
                            {

                                bool isBlocked = false;
                                if (searchParam.Where(p => p.Parameter == "@UserDepth").ToList().Count > 0)
                                {
                                    string val = t[25].ToString();
                                    if (searchParam.Where(p => p.Parameter == "@UserDepth").ToList().FirstOrDefault().Value != t[25].ToString()) isBlocked = true;
                                }
                                if (searchParam.Where(p => p.Parameter == "@UserGear").ToList().Count > 0)
                                {
                                    string val = t[23].ToString();
                                    if (searchParam.Where(p => p.Parameter == "@UserGear").ToList().FirstOrDefault().Value != t[23].ToString()) isBlocked = true;
                                }
                                if (searchParam.Where(p => p.Parameter == "@Type1").ToList().Count > 0)
                                {
                                    string val = t[19].ToString();
                                    if (searchParam.Where(p => p.Parameter == "@Type1").ToList().FirstOrDefault().Value != t[19].ToString()) isBlocked = true;
                                }
                                if (searchParam.Where(p => p.Parameter == "@Cargo1").ToList().Count > 0)
                                {
                                    string val = t[14].ToString();
                                    if (searchParam.Where(p => p.Parameter == "@Cargo1").ToList().FirstOrDefault().Value != t[14].ToString()) isBlocked = true;
                                }


                                if (!isBlocked)
                                //ID = t.GetInt32(0);

                                //Make a note here of how the fields map to the data in sp_GetAllShapes results
                                //
                                //0 - ShipID                
                                //1 - Name1                 
                                //2 - Name2
                                //3 - WreckID2008
                                //4 - Latitude
                                //5 - Longitude
                                //6 - ShapeString
                                //7 - Geo
                                //8 - GeoQ
                                //9 - StartDate
                                //10 - EndDate
                                //11 - DateQ
                                //12 - YearFound
                                //13 - YearFoundQ
                                //14 - CargoID
                                //15 - TypeID
                                //16 - GearID
                                //17 - DepthID
                                //18 - EstimatedCapacity
                                //19 - Comments
                                //20 - Lngth
                                //21 - Width
                                //22 - SizeestimateQ
                                //23 - Parkerreference
                                //24 - Bibliographyandnotes
                                { 
                                    try
                                    {
                                        //Change iteration to match database (follows the order of the SP)
                                        //String ID = t[0].ToString();

                                        String Name1 = t[0].ToString();
                                        String Name2 = t[1].ToString();
                                        String WreckID2008 = t[2].ToString();
                                        String Latitude = t[3].ToString();
                                        String Longitude = t[4].ToString();
                                        String Shape = t[5].ToString();
                                        //text = Shape;
                                        //String Geo = t[6].ToString();
                                        String GeoQ = t[7].ToString();
                                        String StartDate = t[8].ToString();
                                        String EndDate = t[9].ToString();
                                        String DateQ = t[10].ToString();
                                        String YearFound = t[11].ToString();
                                        String YearFoundQ = t[12].ToString();
                                        String CargoFK = t[13].ToString();
                                        String Cargo1 = t[14].ToString();
                                        String Cargo2 = t[15].ToString();
                                        String Cargo3 = t[16].ToString();
                                        String OtherCargo = t[17].ToString();
                                        String TypeFK = t[18].ToString();
                                        String Type1 = t[19].ToString();
                                        String Type2 = t[20].ToString();
                                        String Type3 = t[21].ToString();
                                        String GearFK = t[22].ToString();
                                        String Gear = t[23].ToString();
                                        String DepthFK = t[24].ToString();
                                        String Depth = t[25].ToString();
                                        String EstimatedCapacity = t[26].ToString();
                                        String Comments = t[27].ToString();
                                        String Length = t[28].ToString();
                                        String Width = t[29].ToString();
                                        String SizeestimateQ = t[30].ToString();
                                        String Parkerreference = t[31].ToString();
                                        String Bibliography = t[32].ToString();

                                        //if (dataFilterModel != null)
                                        //{
                                        //    if (dataFilterModel.Depth != "" && Depth == dataFilterModel.Depth)
                                        //        continue;

                                        //    if (dataFilterModel.Gear != "" && Gear == dataFilterModel.Gear)
                                        //        continue;

                                        //    if (dataFilterModel.Type1 != "" && Type1 != dataFilterModel.Type1)
                                        //        continue;

                                        //    if (dataFilterModel.Type2 != "" && Type2 != dataFilterModel.Type3)
                                        //        continue;

                                        //    if (dataFilterModel.Type3 != "" && Type3 != dataFilterModel.Type3)
                                        //        continue;

                                        //    if (dataFilterModel.Cargo1 != "" && Cargo1 != dataFilterModel.Cargo1)
                                        //        continue;

                                        //    if (dataFilterModel.Cargo2 != "" && Cargo2 != dataFilterModel.Cargo2)
                                        //        continue;

                                        //    if (dataFilterModel.Cargo3 != "" && Cargo3 != dataFilterModel.Cargo3)
                                        //        continue;

                                        //    if (dataFilterModel.OtherCargo != "" && OtherCargo != dataFilterModel.OtherCargo)
                                        //        continue;


                                        //}


                                        if (Shape.Contains("POINT"))
                                        {
                                            //Style placemark
                                            s.Icon = new IconStyle();
                                            s.Icon.Scale = 1;
                                            s.Icon.Color = new Color32(255, 255, 255, 255);
                                            s.Label = new LabelStyle();
                                            s.Label.Scale = 1;
                                            s.Label.Color = new Color32(255, 255, 255, 255);

                                            //Clean the ShapeString
                                            Shape = Shape.Replace("POINT", "");
                                            Shape = Shape.Replace("  ", " ");
                                            Shape = Shape.Replace("(", "");
                                            Shape = Shape.Replace(")", "");

                                            Shape = Shape.Trim();

                                            //Break the string up
                                            String[] b = Shape.Split(' ');

                                            //Converts string input data to usable coordinate with altitude 0
                                            Coordinate C = new Coordinate(Double.Parse(b[1]), Double.Parse(b[0]), 0);

                                            //Translates coordinate to .kml placemark
                                            Placemark P = C.ToPlaceMark();

                                            //Uses input data for additional placemark info (can be modified to begin generating pop-up data)
                                            P.Name = t[1].ToString();
                                            SharpKml.Dom.Description D = new SharpKml.Dom.Description();
                                            D.Text = "Name 1: " + Name1 + Environment.NewLine +
                                                     "Name 2: " + Name2 + Environment.NewLine +
                                                     "Start Date: " + StartDate + Environment.NewLine +
                                                     "End Date: " + EndDate + Environment.NewLine +
                                                     "Data source: " + Bibliography +
                                                     "DateQ: " + DateQ + Environment.NewLine +
                                                     "YearFound: " + YearFound + Environment.NewLine +
                                                     "Cargo1: " + Cargo1 + Environment.NewLine +
                                                     "Cargo2: " + Cargo2 + Environment.NewLine +
                                                     "Cargo3: " + Cargo3 + Environment.NewLine +
                                                     "OtherCargo: " + OtherCargo + Environment.NewLine +
                                                     "Type1: " + Type1 + Environment.NewLine +
                                                     "Type2: " + Type2 + Environment.NewLine +
                                                     "Type3: " + Type3 + Environment.NewLine +
                                                     "Width: " + Width + Environment.NewLine +
                                                     "Depth: " + Depth + Environment.NewLine +
                                                     "Gear: " + Gear + Environment.NewLine +
                                                     "Capacity: " + EstimatedCapacity + Environment.NewLine +
                                                     "Comments: " + Comments + Environment.NewLine +
                                                     "Length: " + Length + Environment.NewLine +
                                                     "Width: " + Width + Environment.NewLine +
                                                     "Data source: " + Bibliography;

                                            P.Description = D.Clone();
                                            P.Id = t[0].ToString();

                                            P.AddStyle(s.Clone());

                                            //Adds new placemark to Placemark List and moves on to the next record
                                            Shapes.Add(P.Clone());

                                        }
                                    }
                                    catch (Exception ex)
                                    {
                                        //What goes here?
                                    }
                            }
                            }
                        }
                    }
                }


            }
            catch (Exception ex)
            {
                //What goes here?
            }

            //Returns the list of created placemarks to the variable declared in BasicApp.cs (PointData)
            return Shapes;




        }

       

    }
    public class SearchValues
    {
        public string Parameter { get; set; }
        public string Value { get; set; }
        public SearchValues()
        {
        }
        public SearchValues(string parameter, string value)
        {
            Parameter = parameter;
            Value = value;
        }
    }
    public class CountValues
    {
        public string Name { get; set; }
        public int Count { get; set; }
        public CountValues()
        {
        }
        public CountValues(string name, int count)
        {
            Name = name;
            Count = count;
        }
    }
}
