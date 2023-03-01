



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



SELECT Name1,
       Name2,
	   SW.WreckID2008, 
	   Latitude, 
	   Longitude, 
	   (GEOGRAPHY::Point(Latitude,Longitude,4326).STAsText()),
	   (GEOGRAPHY::Point(Latitude,Longitude,4326)),
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
	   FROM tbl_Shipwreck SW 
	   JOIN tbl_Cargo C ON C.CargoID = SW.CargoFK
	   JOIN tbl_Type T ON T.TypeID = SW.TypeFK
	   JOIN tbl_Gear G ON G.GearID = SW.GearFK
	   JOIN tbl_Depth D ON D.DepthID = SW.DepthFK
	   ORDER BY ShipID




	   ---- We don't need the below ---


--BEGIN CATCH 

--DECLARE @ErMessage NVARCHAR(MAX),
--        @ErSeverity INT,
--		@ErState INT

--SELECT @ErMessage = ERROR_MESSAGE(), @ErSeverity = ERROR_SEVERITY(), @ErState = ERROR_STATE()

--IF @@TRANCOUNT > 0
--BEGIN
--ROLLBACK TRANSACTION

--END

--RAISERROR(@ErMessage,@ErSeverity,@ErState)
--END CATCH

--IF @@TRANCOUNT > 0
--BEGIN
--COMMIT TRANSACTION
--END



--EXEC sp_GetAllShapes
