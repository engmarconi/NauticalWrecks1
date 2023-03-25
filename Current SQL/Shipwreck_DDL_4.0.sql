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
*/


USE master
GO


IF EXISTS(SELECT * FROM sys.databases WHERE name='DB_shipwreck')
DROP DATABASE DB_shipwreck

CREATE DATABASE DB_shipwreck
GO
USE DB_shipwreck

------BUILD tbl_Shipwreck AND ADD CHECKS, FK REFERENCES------

CREATE TABLE tbl_Shipwreck
(
ShipID INT Identity(1,1) NOT NULL,
Name1 NVARCHAR(MAX) NOT NULL,
Name2 NVARCHAR(MAX) NULL,
WreckID2008 INT NOT NULL,
Latitude DECIMAL(7,5) NULL,
Longitude DECIMAL(8,5) NULL,
ShapeString NVARCHAR(MAX) NULL,
Geo GEOGRAPHY NULL,
GeoQ NVARCHAR(MAX) NULL,
StartDate INT NULL,
EndDate INT NULL,
DateQ NVARCHAR(MAX) NULL,
YearFound INT NULL,
YearFoundQ NVARCHAR(MAX) NULL,
CargoFK INT NULL,
TypeFK INT NULL,
GearFK INT NULL,
DepthFK INT NULL,
EstimatedCapacity NVARCHAR(MAX) NULL,
Comments NVARCHAR(MAX) NULL,
Lngth Decimal(5,2) NULL,
Width Decimal(5,2) NULL,
SizeestimateQ NVARCHAR(MAX) NULL,
Parkerreference INT NULL,
Bibliographyandnotes NVARCHAR(MAX) NULL
);

ALTER TABLE tbl_Shipwreck ADD PRIMARY KEY (ShipID)
ALTER TABLE tbl_Shipwreck ADD CHECK (Latitude>=-90 AND Latitude<=90 AND Longitude <=180 AND Longitude >=-180); 

------BUILD tbl_Cargo & FK REFERENCES------

CREATE TABLE tbl_Cargo
(
CargoID INT Identity(1,1) NOT NULL,
WreckID2008 INT NOT NULL,
Cargo1 NVARCHAR(MAX) NULL,
Cargo2 NVARCHAR(MAX) NULL,
Cargo3 NVARCHAR(MAX) NULL,
OtherCargo NVARCHAR(MAX) NULL
);

ALTER TABLE tbl_Cargo ADD PRIMARY KEY (CargoID)

------BUILD tbl_Type & FK REFERENCES------

CREATE TABLE tbl_Type
(
TypeID INT Identity(1,1) NOT NULL,
WreckID2008 INT NOT NULL,
Type1 NVARCHAR(MAX) NULL,
Type2 NVARCHAR(MAX) NULL,
Type3 NVARCHAR(MAX) NULL
);

ALTER TABLE tbl_Type ADD PRIMARY KEY (TypeID)

------BUILD tbl_Gear & FK REFERENCES------

CREATE TABLE tbl_Gear
(
GearID INT Identity(1,1) NOT NULL,
WreckID2008 INT NOT NULL,
Gear VARCHAR(MAX) NULL,
);

ALTER TABLE tbl_Gear ADD PRIMARY KEY (GearID)

------BUILD tbl_Depth & FK REFERENCES------

CREATE TABLE tbl_Depth
(
DepthID INT Identity(1,1) NOT NULL,
WreckID2008 INT NOT NULL,
Depth Decimal(6,3) NULL,
DepthQ NVARCHAR(MAX) NULL,
);

ALTER TABLE tbl_Depth ADD PRIMARY KEY (DepthID)

------ADD FOREIGN KEY REFERENCES TO @tbl_Shipwreck

ALTER TABLE tbl_Shipwreck ADD FOREIGN KEY (CargoFK) REFERENCES tbl_Cargo
ALTER TABLE tbl_Shipwreck ADD FOREIGN KEY (TypeFK) REFERENCES tbl_Type
ALTER TABLE tbl_Shipwreck ADD FOREIGN KEY (GearFK) REFERENCES tbl_Gear
ALTER TABLE tbl_Shipwreck ADD FOREIGN KEY (DepthFK) REFERENCES tbl_Depth

------

GO