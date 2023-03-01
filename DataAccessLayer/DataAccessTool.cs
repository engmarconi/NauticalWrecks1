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

namespace DataAccessLayer
{
    
    public class DataAccessTool
    {
        private static String GetConnectionString()
        {
            //Change connection string for each user, DB name to match project
            //return @"Server=DESKTOP-AH6EVAP;Database=DB_shipwreck;Trusted_Connection=Yes;";
            return @"Server=.\SQLEXPRESS;Database=DB_shipwreck;Trusted_Connection=Yes;";
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

                                        if (dataFilterModel.Gear != "" && Depth == dataFilterModel.Gear)
                                            continue;

                                        if (dataFilterModel.Type1 != "" && Type1 != dataFilterModel.Type1)
                                            continue;

                                        if (dataFilterModel.Type2 != "" && Type1 != dataFilterModel.Type3)
                                            continue;

                                        if (dataFilterModel.Type3 != "" && Type1 != dataFilterModel.Type3)
                                            continue;

                                        if (dataFilterModel.Cargo1 != "" && Type1 != dataFilterModel.Cargo1)
                                            continue;

                                        if (dataFilterModel.Cargo2 != "" && Type1 != dataFilterModel.Cargo2)
                                            continue;

                                        if (dataFilterModel.Cargo3 != "" && Type1 != dataFilterModel.Cargo3)
                                            continue;

                                        if (dataFilterModel.OtherCargo != "" && Type1 != dataFilterModel.OtherCargo)
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
             
        }

        public List<dynamic> GetDepthFilter()
        {
            List<dynamic> types = new List<dynamic>();
            types.Add(new { id = "", name = "" });
            using (var conn = new SqlConnection(GetConnectionString()))
            {
                using (var command = new SqlCommand($"select DISTINCT Depth from [DB_shipwreck].[dbo].[tbl_Depth]", conn))
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
                using (var command = new SqlCommand($"select DISTINCT [Gear] from [DB_shipwreck].[dbo].[tbl_Gear]", conn))
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
                using (var command = new SqlCommand($"select DISTINCT {name} from [DB_shipwreck].[dbo].[tbl_Type]", conn))
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
                using (var command = new SqlCommand($"select DISTINCT {name} from [DB_shipwreck].[dbo].[tbl_Cargo]", conn))
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


        public async Task<string> GetData(DataFilterModel dataFilterModel)
        {
            DataAccessTool DataImport = new DataAccessTool();

            //Instantiate Placemark List variable to store data as it comes in from the data tool
            List<Placemark> PointData = DataImport.GetAllShapes(dataFilterModel);

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
            return name;
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
    }
}
