/*
ScriptName: DB_shipwreck
Coder: Mahender Amireddy
Date: 2023-01-26

vers     Date                Coder					Issue
1.0      2023-01-26          Mahender Amireddy      Initial

1.1      2023-02-01          Mahender Amireddy      Changes made as per discussion

2.0		 2023-02-07			 Full team				Made corrections to DDL structure and creation of tables (added Cargo, Type, Gear, Depth as separate).
													Created foreign key references for new tables in tbl_Shipwreck.

2.0		 2023-02-09			 Spencer Greason		Cleaned up DDL script, organized table alterations & references. Added comments for visibility.

3.1      2023-02-11          Mahender Amireddy      changed depth datatype

-------- 2023-02-17 GROUP SPLIT EFFECTIVE --------- All future changes to this document will reflect the work of Nautical Wrecks members Giulia, Chido, and Spencer

4.0      2023-02-17          Giulia                 Added WreckID2008 to all tables. Need this as a common field for joins. 
4.1		 2023-02-22			 Giulia				    Normalized the data by creating tbl_CargoWreck, tbl_CargoType, tbl_GearWreck, and tbl_DepthWreck.
4.2		 2023-03-02          Giulia					Reconfigured the DDL so it works!
													In tbl_Shipwreck, 
													    Changed Name1, Name2 to PrimaryName, Secondary Name
														Removed CargoFK, TypeFK, GearFK, and DepthFK
														Added Depth as a DECIMAL(5,2)
														Changed Lngth to [Length] and Width to [Width]
														SizeestimateQ is now SizeEstimateQ, 
														Parkerreference is now ParkerReference,
														Bibliographyandnotes is now BibliographyandNotes 
													All Foreign Key References now occur at the bottom of the script

*/


USE master
GO


IF EXISTS(SELECT * FROM sys.databases WHERE name='DB_shipwreck')
DROP DATABASE DB_shipwreck

CREATE DATABASE DB_shipwreck
GO
USE DB_shipwreck

------BUILD tbl_Shipwreck

CREATE TABLE tbl_Shipwreck
(
ShipID INT Identity(1,1) NOT NULL,
PrimaryName NVARCHAR(MAX) NOT NULL,      
SecondaryName NVARCHAR(MAX) NULL,                
WreckID2008 INT NOT NULL,
Latitude DECIMAL(7,5) NULL,
Longitude DECIMAL(8,5) NULL,
ShapeString NVARCHAR(MAX) NULL,
Geo GEOGRAPHY NULL,
GeoQ NVARCHAR(MAX) NULL,
StartDate INT NULL,
EndDate INT NULL,
DateQ NVARCHAR(MAX) NULL,
Depth DECIMAL(5,2) NULL,
YearFound INT NULL,
YearFoundQ NVARCHAR(MAX) NULL,
EstimatedCapacity NVARCHAR(MAX) NULL,
Comments NVARCHAR(MAX) NULL,
[Length] Decimal(5,2) NULL,
[Width] Decimal(5,2) NULL,
SizeEstimateQ NVARCHAR(MAX) NULL,
ParkerReference INT NULL,
BibliographyandNotes NVARCHAR(MAX) NULL
);

ALTER TABLE tbl_Shipwreck ADD PRIMARY KEY (ShipID)
ALTER TABLE tbl_Shipwreck ADD CHECK (Latitude>=-90 AND Latitude<=90 AND Longitude <=180 AND Longitude >=-180); 


------BUILD tbl_Cargo

CREATE TABLE tbl_Cargo
(
CargoID INT Identity(1,1) NOT NULL,
CargoName NVARCHAR(MAX)
);

ALTER TABLE tbl_Cargo ADD PRIMARY KEY (CargoID)

------BUILD tbl_Type

CREATE TABLE tbl_Type
(
TypeID INT Identity(1,1) NOT NULL,
TypeName NVARCHAR(MAX)
);


ALTER TABLE tbl_Type ADD PRIMARY KEY (TypeID)

------BUILD tbl_Gear


CREATE TABLE tbl_Gear
(
GearID INT Identity(1,1) NOT NULL,
GearName VARCHAR(MAX) NULL
);

ALTER TABLE tbl_Gear ADD PRIMARY KEY (GearID)

---- Build NORMALIZATION

CREATE TABLE tbl_CargoWreck
(
CargoShipID INT Identity(1,1) NOT NULL, 
CargoFK INT NULL,
ShipFK INT NULL     ----Associated with ShipID
);

ALTER TABLE tbl_CargoWreck ADD PRIMARY KEY (CargoShipID)



CREATE TABLE tbl_CargoType
(
CargoTypeID INT Identity(1,1) NOT NULL,
CargoFK INT NOT NULL,
TypeFK INT NOT NULL,
ShipFK INT NOT NULL
);

ALTER TABLE tbl_CargoType ADD PRIMARY KEY (CargoTypeID)

CREATE TABLE tbl_GearWreck
(
GearWreckID INT Identity(1,1) NOT NULL,
GearFK INT NOT NULL,
ShipFK INT NOT NULL
);


------ADD FOREIGN KEY REFERENCES TO tbl_CargoWreck
ALTER TABLE tbl_CargoWreck ADD FOREIGN KEY (ShipFK) REFERENCES tbl_Shipwreck (ShipID)
ALTER TABLE tbl_CargoWreck ADD FOREIGN KEY (CargoFK) REFERENCES tbl_Cargo (CargoID)


------ADD FOREIGN KEY REFERENCES TO tbl_CargoType
ALTER TABLE tbl_CargoType ADD FOREIGN KEY (CargoFK) REFERENCES tbl_Cargo (CargoID)
ALTER TABLE tbl_CargoType ADD FOREIGN KEY (TypeFK) REFERENCES tbl_Type (TypeID)


------ADD FOREIGN KEY REFERENCES TO tbl_GearWreck
ALTER TABLE tbl_GearWreck ADD FOREIGN KEY (GearFK) REFERENCES tbl_Gear (GearID)
ALTER TABLE tbl_GearWreck ADD FOREIGN KEY (ShipFK) REFERENCES tbl_Shipwreck (ShipID)





GO