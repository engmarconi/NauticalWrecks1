/*
ScriptName: Stored Procedures - sp_GetWreckByType
Coder: Giulia
Date: 2023-02-21

vers     Date                    Coder       Issue
1.0      2023-02-23				Giulia		sp_GetWreckByType1
5.0		 2023-03-10             Giulia      Reformatted for Normalized Database.
                                            Changed name to sp_GetWreckByType
											All Fields added into the Select

-- CHECK TRINITY FROM FALL - FIX THIS AFTER NORMALIZING THE TABLES. CHECK TEST SCRIPT FOR NOTES!

*/

USE [DB_shipwreck]
GO


--- sp_GetWreckByType

--exec sp_GetWreckByType Afr

IF OBJECT_ID('sp_GetWreckByType', 'CL') IS NOT NULL

DROP PROCEDURE [dbo].[sp_GetWreckByType]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].sp_GetWreckByType
 
--If you have to pass any variables in this is where they get declared.
@Type NVARCHAR(MAX)


AS  


BEGIN TRANSACTION
BEGIN TRY

DECLARE @TypeResult NVARCHAR (MAX) = '%' + @Type + '%'


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
WHERE T.TypeName LIKE @TypeResult

  
SET NOCOUNT ON  
SET ANSI_WARNINGS OFF  
--SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  

--This is where your SQL goes.

END TRY

BEGIN CATCH

DECLARE @ErMessage NVARCHAR(MAX),
        @ErSeverity INT,
		@ErState INT

SELECT @ErMessage = ERROR_MESSAGE(), @ErSeverity = ERROR_SEVERITY(), @ErState = ERROR_STATE()

IF @@TRANCOUNT > 0
BEGIN
ROLLBACK TRANSACTION

END
RAISERROR(@ErMessage,@ErSeverity,@ErState)

END CATCH

IF @@TRANCOUNT > 0
BEGIN
COMMIT TRANSACTION

SELECT * FROM tbl_Shipwreck 

END
GO