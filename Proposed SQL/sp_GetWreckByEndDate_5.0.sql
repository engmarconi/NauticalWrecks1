/*
ScriptName: Stored Procedures - sp_GetWreckByEndDate
Coder: Giulia
Date: 2023-02-27

vers     Date                    Coder       Issue
1.0      2023-02-27				Giulia		sp_GetWreckByEndDate
5.0		 2023-03-10             Giulia      Reformatted for Normalized Database.
											All Fields added into the Select


-- CHECK TRINITY FROM FALL - FIX THIS AFTER NORMALIZING THE TABLES. CHECK TEST SCRIPT FOR NOTES!

*/

USE [DB_shipwreck]
GO


--- sp_GetWreckByEndDate

--exec sp_GetWreckByEndDate -50

IF OBJECT_ID('sp_GetWreckByEndDate', 'CL') IS NOT NULL

DROP PROCEDURE [dbo].[sp_GetWreckByEndDate]
GO


SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].sp_GetWreckByEndDate
 
--If you have to pass any variables in this is where they get declared.
@UserEndDate INT


AS  


BEGIN TRANSACTION
BEGIN TRY

DECLARE @EndDateResult INT = @UserEndDate

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
WHERE SW.EndDate = @EndDateResult

  
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