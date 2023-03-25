/*
ScriptName: sp_GetAllShapes
Coder: Mahender
Date: 2023-02-10

vers       Date              Coder         Issue
1.0      2023-02-10		   Mahender		 Initial
2.0		 2023-02-11		   Mahender		fixed errors
-------GROUP SPLIT 
4.0		2023-02-17		    Giulia      Reformatted the document (Removed the Try / Catch)
										Removed the Left Joins
4.1		2023-02-21			Giulia		Added in the fields for tbl_Cargo, tbl_Type, tbl_Gear, and tbl_Depth
									    so that the information appears as a popup on the placemark.
5.0     2023-03-10          Giulia      Reformatted for Normalized Database.


*/
--exec sp_GetAllShapes 



USE DB_shipwreck

GO

IF OBJECT_ID('sp_GetAllShapes', 'P') IS NOT NULL

DROP PROCEDURE [dbo].[sp_GetAllShapes]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].sp_GetAllShapes

 --If you have to pass any variables in this is where they get declared.



AS  

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

SELECT SW.PrimaryName,
       SW.SecondaryName,
	   SW.WreckID2008, 
	   SW.Latitude, 
	   SW.Longitude, 
	   (GEOGRAPHY::Point(Latitude,Longitude,4326).STAsText()),
	   (GEOGRAPHY::Point(Latitude,Longitude,4326)),
	   SW.GeoQ,
	   SW.StartDate,
	   SW.EndDate,
	   SW.DateQ,
	   C.CargoName,
	   T.TypeName, 
	   G.GearName,
	   SW.Depth,
	   SW.YearFound, 
	   SW.YearFoundQ, 
	   SW.EstimatedCapacity,
	   SW.Comments,
	   SW.[Length], 
	   SW.[Width],
	   SW.SizeEstimateQ,
	   SW.ParkerReference,
	   SW.BibliographyandNotes
FROM tbl_Shipwreck SW
LEFT JOIN tbl_CargoWreck CW ON CW.ShipFK = SW.ShipID
LEFT JOIN tbl_Cargo C ON C.CargoID = CW.CargoFK
LEFT JOIN tbl_CargoType CT ON CT.ShipFK = SW.ShipID AND CT.CargoFK = C.CargoID 
LEFT JOIN tbl_Type T ON T.TypeID = CT.TypeFK
LEFT JOIN tbl_GearWreck GW ON GW.ShipFK = SW.ShipID
LEFT JOIN tbl_Gear G ON G.GearID = GW.GearFK
ORDER BY SW.ShipID
