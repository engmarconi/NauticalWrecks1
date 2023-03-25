/*
ScriptName: DB_shipwreck
Coder: Chido
Date: 2023-03-03

vers     Date                Coder					Issue
3.0      2023-03-03          Chido					sp_GetFileteredShapes for all the filters and applied first level filtering

*/

USE [DB_shipwreck]
GO


IF OBJECT_ID('[sp_GetFilteredShapes]', 'CL') IS NOT NULL

DROP PROCEDURE [dbo].[sp_GetFilteredShapes]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/* Filtering*/
CREATE PROCEDURE [dbo].[sp_GetFilteredShapes] 
--If you have to pass any variables in this is where they get declared.
@UserDepth DECIMAL (6,3) = NULL,
@UserGear NVARCHAR(MAX)  = NULL,
@Cargo1 NVARCHAR(MAX)  = NULL,
@Type1 NVARCHAR(MAX)  = NULL

AS
BEGIN TRANSACTION
BEGIN TRY

	SELECT Name1,
       Name2,
	   SW.WreckID2008, 
	   Latitude, 
	   Longitude, 
	   (GEOGRAPHY::Point(Latitude,Longitude,4326).STAsText()) AS Geo1,
	   (GEOGRAPHY::Point(Latitude,Longitude,4326)) AS Geo2,
	   GeoQ,
	   StartDate,
	   EndDate,
	   DateQ, 
	   YearFound, 
	   YearFoundQ, 
	   CargoFK,
	   C.Cargo1,
	   C.Cargo2,
	   C.Cargo3,
	   C.OtherCargo,
	   TypeFK,
	   T.Type1,
	   T.Type2,
	   T.Type3,
	   GearFK,
	   G.Gear,
	   DepthFK, 
	   D.Depth,
	   EstimatedCapacity,
	   Comments,
	   Lngth, 
	   Width,
	   SizeestimateQ,
	   Parkerreference,
	   Bibliographyandnotes

/*Filtering*/
	   FROM tbl_Shipwreck SW 
	   JOIN tbl_Cargo C ON C.CargoID = SW.CargoFK
	   JOIN tbl_Type T ON T.TypeID = SW.TypeFK
	   JOIN tbl_Gear G ON G.GearID = SW.GearFK
	   JOIN tbl_Depth D ON D.DepthID = SW.DepthFK
	   WHERE (D.Depth = @UserDepth OR C.Cargo1 LIKE @Cargo1 OR T.Type1 LIKE @Type1 OR G.Gear LIKE @UserGear)
	 

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


END
GO