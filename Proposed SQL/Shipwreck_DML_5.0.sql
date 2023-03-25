﻿/*
Scriptname: WreckDML_v3.0.sql
Coder: Mahender Amireddy
Date: 2022-01-26

Version		Date			Coder		 Comments
1.0			2023-01-26      Mahender     Initial
2.1			2023-02-01      Mahender     Changes made as discussed
2.0			2023-02-07		Full team	 Finished corrections with DDL and DML and final data scrubbing, successfully built @tbl_Load. 
										 Populated ShapeString and Geo fields for @tbl_Shipwreck and began working on other temporary tables.
										 Established next steps for completing SQL segment of the project. C# code can be further tested with
										 project data when the SQL database is built.

3.0			2023-02-09		Spencer		 Rescrubbed data and repopulated @tbl_Load with correct datatypes rather than as NVARCHAR values. Ensured that all records
										 are properly added to initial load table. One record was commented out because it contains negative lat/lng values, but still
										 exists in the second block of the @tbl_Load insert for reference.
3.1			2023-02-09		Spencer		 Finished building table variables (as per meeting on 02/07) and was able to successfully populate these tables using @tbl_Load values.
										 Tested table variables with SELECT statements and JOINS to verify data input (all good). Next steps will be to reflect DML structure
										 in DDL script and populate the database with our temporary table values and write sp_GetAllShapes (then connect C# project).
3.2			2023-02-09		Spencer		 Cleaned up DML script and organized code blocks into sections, added comments for visibility to other group members in preparation
										 for upload to FOL.

--------	2023-02-17 GROUP SPLIT EFFECTIVE --------- All future changes to this document will reflect the work of Nautical Wrecks members Giulia, Chido, and Spencer

4.0			2023-02-17		Giulia		 Began cleaning up the DML to resolve our bad join that resulted in 100k database. 
										 @tbl_Type had an incorrect PK name.
									     Fixing our JOIN issue. Attempt: Give all tables a common field (WreckID2008). Temporary fix. 
										 Error Fixed. We should now only see 1062 records. 
4.1			2023-02-22		Giulia		 Added in the updated tbl_Cargo, tbl_Type, tbl_Gear, and tbl_Depth
										 Added in the Relational Tables tbl_CargoWreck, tbl_CargoType, tbl_GearWreck, and tbl_DepthWreck
										 Insert the values for @tbl_Cargo, @tbl_Type, @tbl_Gear, and @tbl_Depth
4.2			2023-02-27		Giulia	     Creating the Relational Table Joins (tbl_CargoWreck, tbl_CargoType, tbl_GearWreck, tbl_DepthWreck)
4.3         2023-02-28      Giulia		 Fixed Values Based Insert for @tbl_Cargo, @tbl_Gear, and @tbl_Type
4.4			2023-03-02		Giulia       Joined Temporary Relational Tables
                                         Fixed the temp table fields to match the DDL tables.
										 Created the Insert into Actual Tables
4.5			2023-03-03		Giulia	     I noticed that the WreckID2008 was out of hierarchical order and there were duplicate WreckID2008s.
											Rescrubbed dataset because we need a correct WreckID2008. 
											ISSUE with the second half of insert into tbl_Load. 
											       Msg 245, Level 16, State 1, Line 707   ----this is the insert line. 
                                  Conversion failed when converting the varchar value 'ca' to data type int.

4.6			2023-03-05     Giulia		Solved the above issue. WreckID2008 had the INT 1989 going into YearFoundQ which is set to NVARCHAR
											 Fixed this issue by turning 1989 into a string value: '1989'
4.7			2023-03-07	   Giulia		 Fixed the CargoType Join
										 Attempted Creating the Full Join
4.8			2023-03-09	   Giulia		Full Join for Temp Table Fixed! :D 
										Conducted Tests to Ensure all Data Entered Correctly.
5.0			2023-03-10	   Giulia		Normalized Database Completed. Permanent tables constructed. 
                                        There is now 1,493 entries in our database. 

*/

------DECLARE ALL TABLE VARIABLES FOR DATA INSERT **NOTE DATA TYPES ARE DEFINED HERE**------

USE DB_shipwreck

DECLARE @Rowcount INT = 0
SET @Rowcount = (SELECT COUNT (ShipID) FROM tbl_Shipwreck)
IF @Rowcount = 0
BEGIN


--------------------DECLARING TEMP TABLES-----------------------

DECLARE @tbl_Load TABLE
(
ID INT IDENTITY(1,1),
PrimaryName NVARCHAR(MAX) NOT NULL,
SecondaryName NVARCHAR(MAX) NULL,
WreckID2008 INT NULL,           
Latitude DECIMAL(7,5) NULL,
Longitude DECIMAL(8,5) NULL,
GeoQ NVARCHAR(MAX) NULL,
StartDate INT NULL,
EndDate INT NULL,
DateQ NVARCHAR(MAX) NULL,
Depth DECIMAL(5,2) NULL,
DepthQ NVARCHAR(MAX) NULL,
YearFound INT NULL,
YearFoundQ NVARCHAR(MAX) NULL,
Cargo1 NVARCHAR(MAX) NULL,
Type1 NVARCHAR(MAX) NULL,
Cargo2 NVARCHAR(MAX) NULL,
Type2 NVARCHAR(MAX) NULL,
Cargo3 NVARCHAR(MAX) NULL,
Type3 NVARCHAR(MAX) NULL,
OtherCargo NVARCHAR(MAX) NULL,
Gear NVARCHAR(MAX) NULL,
EstimatedCapacity NVARCHAR(MAX) NULL,
Comments NVARCHAR(MAX) NULL,
Lngth DECIMAL(5,2) NULL,
Width DECIMAL(5,2) NULL,
SizeestimateQ NVARCHAR(MAX) NULL,
Parkerreference INT NULL,
Bibliographyandnotes NVARCHAR(MAX) NULL
);

DECLARE @tbl_Shipwreck TABLE
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
[Length] DECIMAL(5,2) NULL,
[Width] DECIMAL(5,2) NULL,
SizeEstimateQ NVARCHAR(MAX) NULL,
ParkerReference INT NULL,
BibliographyandNotes NVARCHAR(MAX) NULL
);

DECLARE @tbl_Cargo TABLE
(
CargoID INT Identity(1,1) NOT NULL,
CargoName NVARCHAR(MAX)
);

---RELATIONAL TABLE
DECLARE @tbl_CargoWreck TABLE
(
CargoShipID INT Identity(1,1) NOT NULL, 
CargoFK INT NULL,
ShipFK INT NULL     ----Associated with ShipID
);

DECLARE @tbl_Gear TABLE
(
GearID INT Identity(1,1) NOT NULL,
GearName VARCHAR(MAX) NULL
);


---RELATIONAL TABLE 
DECLARE @tbl_GearWreck TABLE
(
GearWreckID INT Identity(1,1) NOT NULL,
GearFK INT NOT NULL,
ShipFK INT NOT NULL
);

DECLARE @tbl_Type TABLE
(
TypeID INT Identity(1,1) NOT NULL,
TypeName NVARCHAR(MAX)
);

---RELATIONAL TABLE 
DECLARE @tbl_CargoType TABLE
(
CargoTypeID INT Identity(1,1) NOT NULL,
CargoFK INT NOT NULL,
TypeFK INT NOT NULL,
ShipFK INT NOT NULL
);


------INITIAL DATA INSERT INTO @tbl_Load------
                                                                                                                                                             --Cargo1 - 14th position                              
INSERT INTO @tbl_Load (PrimaryName, SecondaryName, WreckID2008, Latitude, Longitude, GeoQ, StartDate, EndDate, DateQ, Depth, DepthQ, YearFound, YearFoundQ, Cargo1, Type1, Cargo2, Type2, Cargo3, Type3, OtherCargo, Gear, EstimatedCapacity, Comments, Lngth, Width, SizeestimateQ, Parkerreference, Bibliographyandnotes)
VALUES
('Abbeville',NULL,1,50.100,1.850,NULL,1,500,NULL,NULL,NULL,1808,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Celtic or continental boat (cf. Zwammerdam?) found in the Somme river',NULL,NULL,NULL,4,NULL),
('Acquaviva',NULL,2,42.817,10.267,NULL,100,200,NULL,30.0,NULL,NULL,NULL,'amphoras','cylindrical (cf Keay 25)',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'status as wreck, rather than jettison, unclear',NULL,NULL,NULL,5,NULL),
('Acque Chiare',NULL,3,40.667,17.933,NULL,300,450,'ca / ?',6.0,NULL,NULL,NULL,'amphoras','Spanish amphoras, jars, lamp','ceramic','terracotta vaulting tubes',NULL,NULL,NULL,NULL,NULL,'300-400 m off shore; remains of wreck scattered over 50 m; looted',50.0,NULL,'remains',6,NULL),
('Agay','Camp Long',4,43.417,6.867,NULL,900,950,'ca',50.0,NULL,1963,NULL,'amphoras',NULL,'stone','at least 7 basalt grinding stones','metal','250 bronze ingots, brass ingot, copper vessels (1 with Arabic graffito)',NULL,'?ship''s boat',NULL,'skeleton of man with sword and leather sheath; dating from C10 Muslim ceramic; ship built of small timbers, skeleton first; 1 (=ship''s boat?) and possibly 2 ships nearby; possible naval battle; some of the objects point to Alicante area, Murcia',25.0,4.0,'>4',8,'http://www.culture.gouv.fr/fr/archeosm/archeosom/agay-s.htm; D. Brentchaloff and P. Sénac 1991; J.P. Joncheray 2007c.'),
('Agde 3',NULL,5,43.267,3.450,'ca',-300,500,'ca / ?',8.0,NULL,NULL,NULL,'amphoras','Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'pieces of wood, 500 m from coast',NULL,NULL,NULL,10,NULL),
('Agde 5',NULL,6,43.250,3.467,NULL,75,125,'ca',NULL,NULL,NULL,NULL,'amphoras','red lead ore','metal','copper ingot',NULL,NULL,NULL,NULL,NULL,NULL,20.0,14.0,NULL,12,NULL),
('Agde 8',NULL,7,43.267,3.450,NULL,0,0,'ca / ?',NULL,NULL,NULL,NULL,'metal',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,15,NULL),
('Agropoli',NULL,8,40.333,14.967,NULL,1,500,'ca',NULL,NULL,NULL,NULL,'marble','Pascual1 Dr37',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,18,NULL),
('Aigua Blava',NULL,9,41.933,3.217,NULL,-50,25,'ca',7.0,NULL,NULL,NULL,'amphoras','Kapitän2',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'not far from coast',NULL,NULL,NULL,21,NULL),
('Ain el Gazala',NULL,10,32.150,23.333,NULL,200,400,'ca',NULL,NULL,NULL,NULL,'amphoras','glazed ware pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,22,NULL),
('Ajaccio',NULL,11,41.917,8.733,'ca',1400,1600,'ca',NULL,NULL,NULL,NULL,'ceramic','270 Roman Rhodian of 22 and 11 liters',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'remains',23,NULL),
('Akandia 1',NULL,12,36.433,28.250,NULL,-50,100,'ca',36.0,NULL,1974,NULL,'amphoras','new type transport amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'550 m NE of bay; previously looted',15.0,11.0,NULL,24,NULL),
('Akandia 2',NULL,13,36.433,28.250,NULL,0,0,'tpq',38.0,NULL,1974,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,25,NULL),
('Alblasserdam',NULL,14,51.867,4.667,NULL,100,250,'tpq',NULL,NULL,NULL,NULL,'nothing reported','tin ingots alloyed with silver',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dugout found close to Roman-period buildings',2.3,NULL,NULL,29,NULL),
('Alcudia',NULL,15,39.767,3.167,'ca',0,0,'ca',NULL,NULL,NULL,NULL,'metal','Dr6?',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,30,NULL),
('Alexandria 1',NULL,16,31.217,29.917,'ca',1,500,'ca',NULL,NULL,NULL,NULL,'amphoras','grinding stones',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,31,NULL),
('Alexandria 2',NULL,17,31.217,29.917,'ca',0,0,'ca / ?',NULL,NULL,NULL,NULL,'stone','bricks',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,32,NULL),
('Alghero',NULL,18,40.533,8.283,NULL,1,500,'ca',NULL,NULL,1978,'?','ceramic','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,34,NULL),
('Almadraba, La',NULL,19,38.867,0.017,NULL,100,200,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,35,NULL),
('Alonessos 2',NULL,20,39.204,23.758,'ca',1100,1200,'ca',60.0,NULL,NULL,NULL,'amphoras','Dr 12 Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'only surveyed by sonar and preliminary dives. 200m N of Alonissos wreck.  This wreck has not been assigned a precise id in the publication.',NULL,NULL,NULL,NULL,'K. Delaporta, M.E. Jasinski, and F. Soreide 2006.'),
('Ametlla de Mar 1',NULL,21,40.867,0.800,NULL,-25,75,'ca',30.0,NULL,NULL,NULL,'amphoras','Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,36,NULL),
('Ametlla de Mar 3',NULL,22,40.883,0.800,'ca',1,300,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','lead objects',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,38,NULL),
('Amoladeras, Las',NULL,23,37.717,-0.700,'ca',1,500,'ca / ?',NULL,NULL,NULL,NULL,'metal',NULL,'amphoras','Dr1A','ceramic','tiles','millstones, gold phallic pendant',NULL,NULL,NULL,NULL,NULL,NULL,39,NULL),
('Ancenis',NULL,24,47.383,-1.667,NULL,100,300,'ca / ?',NULL,NULL,NULL,NULL,'nothing reported','glazed ware pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dugout 14C dated 130+-150',NULL,NULL,NULL,40,NULL),
('Anthéor',NULL,25,43.417,6.883,NULL,1400,1600,'ca',NULL,NULL,1960,'before','ceramic','large barrel-like',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,43,NULL),
('Antikythera 2',NULL,26,35.867,23.333,NULL,-100,500,'? / early medieval',50.0,'ca',NULL,NULL,'amphoras','tufa',NULL,NULL,NULL,NULL,NULL,'lead stock and reinforcement collar of anchor',NULL,NULL,NULL,NULL,NULL,45,NULL),
('Anzio',NULL,27,41.417,12.583,'ca',0,0,'ca',NULL,NULL,NULL,NULL,'stone',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,46,NULL),
('Aquileia',NULL,28,45.767,13.367,NULL,1,200,'ca',NULL,'silted',NULL,NULL,'amphoras','Dr6',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Roman context; ship was sewn',NULL,NULL,NULL,NULL,'Navis I, Aquileia, #94; L. Bertacchi 1990; C. Beltrame 1996; C. Beltrame 2000.'),
('Aragnon',NULL,29,43.317,5.067,NULL,1,50,'ca',0.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'terracotta stoppers sealed with pitch',NULL,NULL,NULL,49,NULL),
('Årby',NULL,30,59.583,16.267,NULL,800,1000,'ca',NULL,'silted',NULL,NULL,'metal','Dr14',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'No dating information provided in database. Pine, oak, oared, Viking-age working boat later used as a grave.',3.8,1.0,NULL,NULL,'Navis I, Årby #172; H. Arbman 1940; H. Arbman, B. Greenhill, and O.T.P. Roberts 1993.'),
('Ardenza',NULL,31,43.500,10.300,NULL,1,100,'ca / ?',11.0,NULL,NULL,NULL,'amphoras','armor weapons',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily looted; many amphoras; pieces of the ship present',20.0,10.0,'remains',51,NULL),
('Arenella',NULL,32,36.983,15.283,NULL,500,1500,'ca / ?',5.0,NULL,1984,NULL,'dolia','Pascual1',NULL,NULL,NULL,NULL,NULL,'iron anchor',NULL,NULL,NULL,NULL,NULL,53,NULL),
('Arenys de Mar (Spain)',NULL,33,41.567,2.550,'ca',0,0,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'identity as wreck uncertain',NULL,NULL,NULL,53,NULL),
('Argentario',NULL,34,42.417,11.083,NULL,1,500,'ca',NULL,NULL,1973,NULL,'amphoras','Pélichet47',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'2 miles off Cala Grande; 3 dolia',NULL,NULL,NULL,55,NULL),
('Arles-Rhône',NULL,35,43.617,4.667,NULL,1,100,'ca / ?',10.0,NULL,1986,NULL,'stone','rilled, pear-shaped Byzantine',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'in the river bed of the Rhone; possibly a wreck',NULL,NULL,NULL,56,NULL),
('Arwad 2',NULL,36,34.833,33.867,'ca',500,650,'ca / ?',6.0,NULL,NULL,NULL,'stone','black basalt columns',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,59,NULL),
('Arwad 3',NULL,37,34.833,33.867,'ca',0,0,'ca',20.0,NULL,NULL,NULL,'tiles','Egyptian-style porphry statue',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,60,NULL),
('Ashqelon',NULL,38,31.667,34.550,NULL,0,0,'ca / ?',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,61,NULL),
('Äskekärr 1',NULL,39,58.617,13.600,NULL,900,1000,'ca / ?',NULL,'silted',1933,NULL,'nothing reported','roofing',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'No dating info in database. Oak, sailed, cargo Nordic ship.',16.0,4.6,NULL,NULL,'Navis I, Äskekärr 1, #171; P. Humbla and H. Thomasson 1934; L.G. Engstrand and H.G. Östlund 1962; J. Bill et al. 1997; A. Bråthen 1998; P. Smolarek 2000.'),
('Aspat bay',NULL,40,37.017,27.550,'ca',0,0,'ca',43.0,NULL,1995,NULL,'metal','carrot-shaped; lentoid (Assarca Type 2); conical (Assarca Type 1); wide conical (Assarca Type 3); amphorae have rilling and brown slip. Amphoras had lids',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'B.A. Phanaeuf and D. Frey 1995.'),
('Assarca',NULL,41,15.515,39.951,'ca',400,600,'ca',4.0,'ca 4-6m',1995,NULL,'stone',NULL,'ceramics','light cream color','glass','greenish blue',NULL,'ballast; pithos; counterweight for a steelyard (made of glass)',NULL,'carrot shaped type of amphora (Ayla-Axum) which appears to be distributed around the Red Sea, southwest coast of Turkey, Spain, Carthage. Argues that the carrot shaped amphorae are from Aila and if they are from Aila (Ayla) the destination of the ship must be Adulis (Pedersen, 2008, 89).',14.0,NULL,'ca',NULL,'R.K. Pedersen 2000,  3-12; R.K. Pedersen 2008, 77-94.'),
('Atlit 2',NULL,42,32.700,34.917,NULL,1275,1300,'ca / ?',NULL,NULL,NULL,NULL,'nothing reported','70 bronze Mamluk helmets',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'frames of a ship, 14C dating',NULL,NULL,NULL,2,NULL),
('Atlit 3',NULL,43,32.700,34.917,'ca',1400,1500,'ca / ?',0.0,NULL,NULL,NULL,'nothing reported','millstones 3, conical  in shape',NULL,NULL,NULL,NULL,NULL,'bombard, swivel-gun',NULL,NULL,NULL,NULL,NULL,3,NULL),
('Avdimou bay',NULL,44,34.655,32.764,NULL,400,600,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,'amphoras','LR4, from Gaza and Ashkelon, tall narrow w/o neck, small ring handles, no rim.  traces of pitch inside the amphoras indicate containedholy land wine',NULL,NULL,NULL,'2 stone anchors in addition to another 9 already documented.',NULL,'Survey. Dating based on amphoras and anchors.  The survey mentions this site in passing.  See IJNA articles for  more details.',NULL,NULL,NULL,NULL,'J. Leidwanger and D.S. Howitt-Marshall 2006, 13-14.'),
('Avenches 2',NULL,45,46.883,7.050,NULL,45,200,'c1',0.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'caulked Roman boat, dendrodated, probably abandoned in C2',NULL,NULL,NULL,63,NULL),
('Avenches 3',NULL,46,46.883,7.050,NULL,125,200,'ca / ?',0.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'caulked Roman boat, dendrodated, probably abandoned in C2',NULL,NULL,NULL,63,NULL),
('Averno 1',NULL,47,40.783,14.067,'ca',1,500,'ca / ?',35.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,64,NULL),
('Averno 2',NULL,48,40.783,14.067,'ca',1,500,'ca',NULL,NULL,NULL,NULL,'metal',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,65,NULL),
('Averno 3',NULL,49,40.783,14.067,'ca',1,500,'ca / ?',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,66,NULL),
('Averno 4',NULL,50,40.783,14.067,'ca',1,500,'ca',25.0,NULL,NULL,NULL,'amphoras','scrap (bronze statue fragments, statuettes, tools, vessels); altar; rings; locks; tools; vessels',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,67,NULL),
('Ayia Galini',NULL,51,35.083,24.667,NULL,276,290,'ca / ?',5.0,NULL,NULL,NULL,'amphoras',NULL,'lamps','brass','coins','coin hoard closing with Probus (276-282)','mid C3 amphora','shipboard pottery',NULL,'lead from hull sheathing, 200 m from shore',NULL,NULL,NULL,68,NULL),
('Ayios Georghios',NULL,52,34.883,32.300,NULL,0,0,'ca / ?',NULL,'shallow',NULL,NULL,'amphoras','Günsenin2',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'close to shore',NULL,NULL,NULL,69,NULL),
('Ayios Ioannis Theologos',NULL,53,38.650,23.183,NULL,1000,1100,'ca',20.0,NULL,NULL,NULL,'amphoras','LRA1 and other types; LRA1 have resin lining',NULL,NULL,NULL,NULL,NULL,'2 Y-shaped iron anchors',NULL,'750 m from coast',NULL,NULL,NULL,70,NULL),
('Ayios Stefanos',NULL,54,38.467,26.150,NULL,550,650,'ca / ?',4.0,NULL,NULL,NULL,'amphoras','Dr2-4 (wine), Haltern 70, Dressel 6, Pompei 36',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'>1000 amphoras',24.0,12.0,'remains',71,NULL),
('Bacoli 1',NULL,55,40.783,14.083,NULL,-50,100,'ca / ?',32.0,NULL,NULL,NULL,'amphoras','Dr20?','ceramic','bowls (type Mayet 33), pitcher (type Marabini L)','stone','millstone (catillus)',NULL,'lead rings',NULL,'frame and planking of ship''s hull; several 1000 amphoras',NULL,NULL,NULL,73,'E. Scognamiglio 1993, 153-58.'),
('Bacoli 2',NULL,56,40.783,14.083,NULL,100,200,'ca / ?',32.0,NULL,NULL,NULL,'amphoras','Kapitän1 and 2, pear-shaped (Dr30), LR spatheiaspatheia',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,74,NULL),
('Bagaud 1',NULL,57,43.017,6.367,NULL,200,275,'ca / ?',15.0,NULL,NULL,NULL,'amphoras','Gaulish; Dr20','ceramic','including 2 mortaria','metal','lead / lead ore (?)',NULL,NULL,NULL,'The array of amphoras probably indicates another, late Roman wreck; for lead possibly from this wreck, see Parker 84',NULL,NULL,NULL,76,NULL),
('Bagaud 3',NULL,58,43.017,6.367,NULL,75,200,'ca / ?',19.0,NULL,NULL,NULL,'amphoras','Gaulish',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,78,NULL),
('Baie de Conca','calanque de Conca',59,41.550,8.783,NULL,1,100,'ca / ?',12.5,'ca (10-15 m range)',NULL,NULL,'amphoras','Dr20, 7/11, Pascual 1','dolia',NULL,NULL,NULL,NULL,NULL,NULL,'area used by dive clubs, so little found',NULL,NULL,NULL,NULL,'P. Pomey and L. Long 1993, 60.'),
('Baie de l''Amitié',NULL,60,43.267,3.467,NULL,50,100,'ca',3.0,'two to four',NULL,NULL,'amphoras','Beltran1','metal','lead ingots','ceramic','coarse cooking pots, Italian and South Gaulish terra sigillata, balsamarium','straw packing material, cages of vegetable fiber',NULL,NULL,'remains of the hull; use of plane (platanus) wood and pollen in hull pitch show ship was built and fitted in eastern Mediterranean',9.5,4.0,'remains',80,'S.D. Muller, 2004, 343-349; S.D. Muller 2005, 153.'),
('Bajo de la Barra',NULL,61,37.650,-0.667,NULL,1,100,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Beltran2B; ovoidal amphora; PE 17','ceramic','unguentaria, coarseware',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,82,NULL),
('Bajo de la Campana 2',NULL,62,37.733,-0.700,'ca',-100,0,'ca',NULL,NULL,NULL,NULL,'amphoras','Dr7-11, Dr14, Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,84,'J.P. Reyes 1996, 68 n16.'),
('Bajo de la Campana 3',NULL,63,37.733,-0.700,'ca',1,300,'ca',NULL,NULL,NULL,NULL,'amphoras','Dr2-4  Dr21',NULL,NULL,NULL,NULL,NULL,'wood fragments',NULL,NULL,NULL,NULL,NULL,NULL,'J.P. Reyes 1996, 68 n17.'),
('Balise du Prêtre 2',NULL,64,41.350,9.200,NULL,1,100,'ca / ?',17.0,NULL,NULL,NULL,'amphoras','LR','ceramic','mortaria, other pottery','metal','copper ingots',NULL,NULL,NULL,NULL,NULL,NULL,NULL,86,NULL),
('Balise du Prêtre 3',NULL,65,41.350,9.200,NULL,290,340,'ca / ?',17.0,NULL,NULL,NULL,'tiles','(?)',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'cargo comparable to Femina morta wreck',NULL,NULL,NULL,87,'(National Maritime Museum 1970)'),
('Barbate',NULL,66,36.183,-5.917,NULL,1,500,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,91,NULL),
('Bari',NULL,67,41.133,16.833,NULL,0,0,'ca / ?',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,92,NULL),
('Barland''s farm',NULL,68,51.567,2.817,'ca',200,300,'ca / ?',NULL,'in alluvium',NULL,NULL,'amphoras','tegulae, imbrices',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on oak dendrochronology. Cargo vessel. Romano-Celtic context.',12.0,3.2,NULL,NULL,'Navis I, Barland''s Farm, #24; N. Nayling and D. Maynard 1994, 596-603; S. McGrail 1997, 205-228; S.McGrail 1997, 53-54; S. McGrail and O. Roberts 1999, 133-146; P.V. Webster 1999; N. Nayling and S. McGrail 2004.'),
('Barthélemy 2',NULL,69,43.433,6.900,NULL,1,100,'ca / ?',39.0,NULL,NULL,NULL,'amphoras','pear-shaped, short neck, small round-handled','ceramic','urns, plates (Rivet 6 and 10), olpe, globular olla; casseroles','metal','lead objects (foculus, boxes) and metal tools','mineral to grind or crush, metal and wood tools','wood fragments; assembled by tying; hull, keel, sternpost, pins, clasps, nails, anchor',NULL,NULL,8.0,NULL,NULL,NULL,'A. Joncheray and J.P. Joncheray, 2004.'),
('Basiluzzo',NULL,70,38.650,15.100,'ca',900,1300,'ca / ?',NULL,'deep water',NULL,NULL,'amphoras','short and long cylindrical necks',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,93,NULL),
('Batiguier, Le',NULL,71,43.517,7.017,NULL,900,1000,'ca / ?',58.0,'60m',1973,NULL,'amphoras','Dr2-4','ceramic','jugs, flasks, strainer-jars, jars, urns, cups, saucepans with pierced covers, gargoulettes with 3 handles, Arabic graffiti jars, Cordovan lamps; some glazed ceramic','metal','copper cauldrons, bowls, dromedary-shaped lamp-filler','glass vessels, drum, millstones, ivory','handtool (perhas and awl)',NULL,'burned  hull, 3 human skeletons, Saracen ship; dated by style on decorative objects; skeleton first construction; flat-bottomed, similar to Agay and Serçe Liman',20.0,6.0,'remains 11x20m, hull 6x20m',97,'http://www.culture.gouv.fr/fr/archeosm/archeosom/bateg-AB73; J.P. Joncheray 2007a; J.P. Joncheray 2007b'),
('Ben-Afelí',NULL,72,39.950,-0.067,NULL,85,95,'ca',10.0,NULL,NULL,NULL,'nothing reported','Haltern70','ceramic','mortaria (datable)','metal','iron bars','iron bill-hook and chopper, jar, roof-tile','sounding-lead',NULL,'remains of ship include small bronze cylinders of pump, lead sheathing, rolls of lead for patching, copper nails, tapering lead pipe, bronze sheave bearing, wooden pole; 300-1200 m from shore',NULL,NULL,NULL,98,NULL),
('Benicarlo',NULL,73,40.400,0.433,NULL,1,50,'ca / ?',10.0,NULL,NULL,NULL,'coins','Dr2-4 Tarragona type','amphoras','Dr2-4','amphoras','Dr20',NULL,NULL,NULL,'remains of lead sheathing, lead anchor stocks',30.0,NULL,'remains',99,NULL),
('Berà',NULL,74,41.117,1.450,NULL,50,50,'ca / ?',50.0,NULL,NULL,NULL,'nothing reported','Haltern70',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'4 km offshore',12.0,7.0,'remains',100,NULL),
('Bergeggi',NULL,75,44.217,8.433,NULL,10,60,'ca',30.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,20.0,6.0,'remains',101,NULL),
('Bevaix',NULL,76,46.933,6.817,NULL,182,190,'ca',2.0,NULL,1970,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'7-10 tons','boat and steering oar, timbers dated by 14C to 90+-60, by dendro: 182; flat-bottomed; mast; capacity of 7-10 tons',19.4,2.9,NULL,102,NULL),
('Björke',NULL,77,57.900,15.950,NULL,320,320,'ca / ?',NULL,'silted',1947,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on one 14C sample with a 70 year margin.  Paddled? lime, pine, spruce, juniper, Nordic-type, working boat.',7.2,1.2,NULL,NULL,'Navis I, Björke, #170; P. Humbla 1949; T. Løken 1976; P. Mellander 1984.'),
----('Bolsa de Marcella',NULL,78,,,NULL,160,220,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','4000 bronze, ending 160',NULL,NULL,NULL,NULL,NULL,'5 types of wood',NULL,NULL,23.0,NULL,NULL,NULL,'A.L.M. Albarracin 1993, 92-94.'),
('Bordeaux',NULL,79,44.783,-0.500,'ca',161,161,'ca / ?',15.0,NULL,NULL,NULL,'amphoras',NULL,'ceramic','South Gaulish and Spanish ts, coarseware','amphoras',NULL,'nails, wood fragments',NULL,NULL,'vessel possibly burned',NULL,NULL,NULL,108,NULL),
('Borgo Caprile',NULL,80,44.633,12.167,NULL,500,1100,'ca / ?',NULL,NULL,NULL,NULL,'ceramic','Dr20A terracotta stoppers',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'stitched boat with flat bottom',10.0,NULL,NULL,109,NULL),
('Boulouris',NULL,81,43.400,6.817,NULL,1,250,'ca / ?',NULL,'shallow',NULL,NULL,'stone','pear-shaped, 11-15 liters',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,110,NULL),
('Bozburun','Selimiye',82,36.717,28.083,'ca',875,900,'ca',33.0,NULL,NULL,NULL,'ceramic','no handles','tiles','stone','ceramic','8 ceramic jugs, 9 ceramic pots','2 copper jugs, 3 glass goblets, one oil lamp, rope, weights',NULL,NULL,'Paleobotanical analysis of amphora contents available. Over 1000 amphoras in cargo, majority for wine. Hull dated by dendro.',15.0,5.0,NULL,111,'F.M. Hocker 1995, 12-14;  F.M. Hocker 1995, 3-8; F.M. Hocker 1998, 4-6; J. Gorham 2000, 11-17.'),
('Bozburun Armed Nave',NULL,83,36.717,28.083,'ca',1475,1575,'ca',81.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,'wrought iron guns, at least 2 metal anchors, ballast',NULL,'survey TK05-AH wreck. 2  km offshore. Authors speculate that the wreck is a possibily Italian armed merchant ship, given the size and the fact that it is armed. Dating based on material and shape of cannons, which were in use only in the 15th century, being replaced by bronze cannons in the 16th.',10.0,4.0,'ca',NULL,'J.G. Royal 2006, 3-11; J.G. Royal 2006, 195-217; J. Leidwanger 2007, 308-316.'),
('Bozburun Galley A',NULL,84,36.717,28.083,'ca',1475,1525,'ca / ?',75.0,NULL,NULL,NULL,'nothing reported','Rhodian type 1 like Lyon (Sciallano and Sibella 1994) 1BC-1CAD',NULL,NULL,NULL,NULL,NULL,'wrought iron guns, 4 metal anchors, ballast',NULL,'survey  TK05-AB wreck. Authors speculate that it''s either an Italian fusta or galliot, or a Turkish firkate or kalite. Dating based on material and shape of cannons, which were in use only in the 15th century, being replaced by bronze cannons in the 16th.',16.0,2.5,'ca',NULL,'J.G. Royal 2006, 3-11;  J.G. Royal 2006, 195-217; J. Leidwanger 2007, 308-316.'),
('Bozburun Julio-Claudian',NULL,85,36.717,28.083,'ca',-50,50,'ca / ?',83.0,NULL,NULL,NULL,'amphoras','LRA1; Type 2, (60 cm long) beehive shaped w/ ridges unidentified; 1 LRA3  (40cm long)','amphoras','Rhodian type 2 (similar to Peacock and Williams (1991) class 9 (Camulodonum 184) 2C','amphoras','Rhodian type 3 (like Antikythera wreck, citing Grace 1965, 5-7)',NULL,NULL,NULL,'survey TK05-AI. Dating based uniquely on amphora finds',15.0,2.0,'ca',NULL,'J.G. Royal 2006, 195-217.'),
('Bozburun late antique anchor wreck',NULL,86,36.717,28.083,'ca',500,600,'ca / ?',85.0,NULL,NULL,NULL,'amphoras','2 coarseware jugs, bowl',NULL,NULL,NULL,NULL,NULL,'9-11 anchors, 6 of cruciform shape, all in the same place, meaning they were stowed. One presents a 2m stock with ring attached. one has lunette shape (used in early Roman imperial period). Similar anchors found in the Dramont F wreck and Yassi Ada wreck. Stock to anchor ratio similar to Yassi Ada',NULL,'survey TK05-AD 2 km offshore. Dating based on amphoras, which resemble as a whole types in use in the 6th C. according to the authors.',9.0,3.0,'ca',NULL,'J.G. Royal 2006, 3-11;  J.G. Royal 2006, 195-217.'),
('Bozukkale',NULL,87,36.550,18.017,NULL,0,0,'ca',NULL,NULL,NULL,NULL,'metal','basalt mill-stones of Ambonne',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,112,NULL),
('Brescou',NULL,88,43.250,3.500,NULL,1,500,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','early Imperial rosso interno pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'100 m off Brescou island',NULL,NULL,NULL,114,NULL),
('Brida Marina',NULL,89,38.283,15.517,'ca',1,200,'ca',NULL,NULL,NULL,NULL,'amphoras','Günsenin1-3',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,116,NULL),
('Brindisi',NULL,90,40.617,17.950,NULL,1100,1200,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'keel and planking of large medieval ship',20.0,NULL,NULL,117,NULL),
('Bruges',NULL,91,51.217,3.233,NULL,100,250,'ca / ?',NULL,'silted',1899,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'mast-step, mast, steering oar, planking, C14 180+-80; similar to Blackfriars boat',15.0,4.5,NULL,118,NULL),
('Budva',NULL,92,36.767,19.067,NULL,0,0,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Afr1 or possibly, Afr2 Almagro50',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'J. P. Reyes 1996, 57-90.'),
('Cabo de Gata',NULL,93,36.800,-2.033,NULL,175,325,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Beltrán 2B?',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,120,NULL),
('Cabo de Mar',NULL,94,42.317,-8.667,'ca',1,300,'ca',NULL,NULL,NULL,NULL,'stone','lead ingots',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,121,NULL),
('Cabras',NULL,95,39.867,8.517,'ca',1,500,'ca / ?',NULL,NULL,NULL,NULL,'coins','Afr2B-D Almagro51C Beltran72 Almagro50 stamps',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,122,NULL),
('Cabrera 1',NULL,96,39.150,2.933,NULL,300,325,'ca / ?',22.0,NULL,1979,NULL,'amphoras','Dr20 Tejarillo1 Dr23 Beltran72 Beltran68 Afr2 Almagro 50 and 51c','ceramic','tiles',NULL,NULL,'fish preserves',NULL,NULL,'Afr 2 lined with pitch, contained mackerel skeletons; preserved hull',NULL,NULL,NULL,123,NULL),
('Cabrera 3',NULL,97,39.150,2.933,NULL,255,255,'ca',22.0,NULL,1970,NULL,'amphoras','Dr7 Dr2-4 stamps','coins','closing 253',NULL,NULL,NULL,NULL,NULL,'preserved hull',NULL,NULL,NULL,125,'F. Mayet 1987, 289.'),
('Cabrera 4',NULL,98,39.150,2.950,'ca',1,15,'ca',NULL,NULL,NULL,NULL,'stone','Dr7 Dr9','metal','lead ingots',NULL,NULL,NULL,'lead reservoir, lead jar, bronze jug-handle, terracotta tubelet, coarseware jug and jar, stamped Arretine plate 3 bronze helmets, 2 iron anchors3',NULL,'cargo probably from Baetica',NULL,NULL,NULL,126,NULL),
('Cabrera 5',NULL,99,39.150,2.917,NULL,-10,25,'ca',42.0,NULL,NULL,NULL,'amphoras','Dr20','metal','lead ingots',NULL,NULL,NULL,NULL,NULL,'pieces of  ship, three pieces of lead drainpipes',10.0,10.0,'remains',127,NULL),
('Cádiz 3','Pecio del Clavo',100,36.517,-6.333,NULL,1,250,'ca',14.0,NULL,NULL,NULL,'amphoras','Dr9 Dr12 Beltran2B','dolia',NULL,'metal','copper nail',NULL,NULL,NULL,NULL,NULL,NULL,NULL,130,NULL),
('Cádiz 4',NULL,101,36.517,-6.333,NULL,-25,25,'ca',12.0,NULL,NULL,NULL,'amphoras','2 mill-stones, 4 squared blocks','metal','lead ingot',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,131,NULL),
('Cádiz 5','Pecio de las piedras de molino',102,36.533,-6.333,NULL,1,500,'ca',10.0,NULL,NULL,NULL,'amphoras','Antoninus Pius','amphoras',NULL,'ceramic','coarseware',NULL,NULL,NULL,NULL,NULL,NULL,NULL,132,NULL),
('Caen 1',NULL,103,49.183,-6.367,NULL,150,150,'ca',NULL,'silted',NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'fragmentary boat',NULL,NULL,NULL,134,NULL),
('Caesarea 1',NULL,104,32.500,34.883,NULL,275,325,'ca',6.0,NULL,NULL,NULL,'dolia',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,136,NULL),
('Caesarea 2',NULL,105,32.500,34.883,NULL,275,325,'ca',6.0,NULL,NULL,NULL,'amphoras','squared basalt slabs',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,137,NULL),
('Caesarea 3',NULL,106,32.500,34.883,NULL,250,250,'ca / ?',7.0,NULL,NULL,NULL,'amphoras','G4','coins','bronze coins of Philip the Arab',NULL,NULL,NULL,'lead sail-rings',NULL,'lead sheathing',NULL,NULL,NULL,138,NULL),
('Cagliari 1',NULL,107,39.167,9.333,NULL,1,300,'ca',NULL,NULL,NULL,NULL,'amphoras','Afr',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,139,NULL),
('Cagliari 2',NULL,108,39.167,9.333,NULL,200,350,'ca',NULL,NULL,NULL,NULL,'amphoras','Pascual1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,140,NULL),
('Cala Cativa',NULL,109,42.350,3.217,NULL,-50,25,'ca',32.0,NULL,NULL,NULL,'ceramic','Dr20 G4; Tripolitana1',NULL,NULL,NULL,NULL,NULL,'lead anchor stock',NULL,'surviving hull; 2 km east of Port de la Selva',NULL,NULL,NULL,142,NULL),
('Cala Cupa',NULL,110,42.367,10.917,NULL,75,125,'ca',18.0,NULL,NULL,NULL,'amphoras',NULL,'ceramic','terra sigillata chiara jug',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,143,NULL),
('Cala de Sant Vicent',NULL,111,39.917,3.050,NULL,1,500,'ca',NULL,NULL,NULL,NULL,'tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'lead-sheathed timbers of Roman ship',NULL,NULL,NULL,144,NULL),
('Cala dei li Francesi',NULL,112,41.217,9.367,NULL,-100,100,'ca / ?',NULL,NULL,NULL,NULL,'tiles','LR',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,146,NULL),
('Cala Grande',NULL,113,41.383,9.083,NULL,300,400,'ca / ?',NULL,NULL,NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,147,NULL),
('Cala Levante',NULL,114,36.783,12.033,NULL,0,0,'ca / ?',30.0,NULL,NULL,NULL,'marble','small, for salted contents; non specified types',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,149,NULL),
('Cala Reona, Cartagena',NULL,115,37.635,-0.696,NULL,NULL,500,'ca',NULL,NULL,NULL,NULL,'ceramic','Dr7-11, 20 with inscriptions of mercatores, containing fish paste and wine','ceramic','terra sigillata Clara D',NULL,NULL,NULL,'wood and nails',NULL,'near Cabo de Palos',NULL,NULL,NULL,NULL,'J. P. Reyes 1996, 71 n27.'),
('Cala Rossano',NULL,116,40.783,13.417,NULL,30,60,'ca',3.5,NULL,NULL,NULL,'metal','pottery fragments','ceramic','coarse pottery, fine-wall ware','metal','lead sheet (round), lead containers, strainers; iron knife, lead finshing weights, roll of lead sheet, 126 copper nails; tin ingots','small round wood boxes containing styli or hair-pins, handles of ivory and wood, marble basin, chest lock,',NULL,NULL,'wooden pulleys, 3 m of cable, pump discs, lead tubing, bronze nails, fragmentary planking, lead sheathing, bricks',40.0,15.0,'remains',153,'F.P. Arata 1993,131-151.'),
('Cala Ustina 2',NULL,117,40.917,8.717,'ca',1,500,'ca / ?',NULL,NULL,NULL,NULL,'coins','Dr2-4; ovoidal amphora',NULL,NULL,NULL,NULL,NULL,'sounding lead (?)',NULL,NULL,NULL,NULL,NULL,156,NULL),
('Cala Vellana',NULL,118,39.950,4.267,NULL,50,60,'ca',13.0,NULL,NULL,NULL,'tiles',NULL,'ceramic','South Gaulish terra sigillata, Hispanic coarseware',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,157,NULL),
('Calanque de l''Âne',NULL,119,43.100,5.283,NULL,80,100,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','tegulae, imbrices, red or mixed yellow and red','ceramic','pottery','glass','unguentaria; pillar-moulded glass bowl',NULL,'net-sinker',NULL,'coin of Domitian in the mast-step',22.0,NULL,NULL,158,NULL),
('Calanque de l''Âne 1','Pointe Debie (earlier name)',120,43.250,5.283,NULL,100,150,'ca / ?',18.0,NULL,NULL,NULL,'amphoras',NULL,'ceramic','sigillee, Drag. 16, 27, 35, 37,','glass',NULL,'Isings 3a, 28a','two elements of lead pipes',NULL,'dated from ceramic, glass; bronze coin of Domitian for terminus post quem; S of Pointe de Pomègues; well preserved hull and deck',25.0,NULL,NULL,NULL,'P. Pomey and L. Long 1993, 20-21; S. Ximénès and M. Moerman 1998, 299-302.'),
('Calanque du Berger',NULL,121,43.250,5.350,NULL,1,500,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','glazed bowls with geometric design and flower',NULL,NULL,NULL,NULL,NULL,'lead pipe of a pump',NULL,NULL,NULL,NULL,NULL,159,NULL),
('Calvi',NULL,122,42.567,8.750,'ca',1500,1500,'ca',NULL,NULL,NULL,NULL,'lamps','giallo antico columns',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Calvi 1 dated to end of 16th C.: Villié 1989',NULL,NULL,NULL,162,NULL),
('Camarina 1',NULL,123,36.850,14.450,NULL,175,200,'ca / ?',4.0,NULL,NULL,NULL,'amphoras','African-type lamps','stone','sandstone blocks','ceramic','black-rim rilled plates and casseroles','Afr1 amphoras, bronze buckets, bronze urn, strigils, small urn, bronze herm, iron hoop from barrel','iron anchor',NULL,'preserved hull',NULL,NULL,NULL,163,NULL),
('Camarina 2',NULL,124,36.850,14.450,NULL,1,100,'ca',NULL,'shallow',NULL,NULL,'amphoras','pots of iron plates 35 cm in diameter to hold fire','metal','bronze dolphin',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,164,NULL),
('Camarina 3',NULL,125,36.850,14.450,NULL,1100,1200,'ca',5.0,NULL,NULL,NULL,'amphoras','1000 coins','metal','hammers, tongs, pliers, nails, horseshoes, chain',NULL,NULL,NULL,NULL,NULL,'wooden hull',30.0,4.0,NULL,165,NULL),
('Camarina 4',NULL,126,36.850,14.450,NULL,270,270,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','imbrices, tegulae',NULL,NULL,NULL,NULL,NULL,'chest fittings',NULL,NULL,NULL,NULL,NULL,166,NULL),
('Camerat 1',NULL,127,43.200,6.683,NULL,1,100,'ca',25.0,NULL,NULL,NULL,'amphoras','Günsenin4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dating based on decoration on tiles',NULL,NULL,NULL,NULL,'P. Pomey and L. Long 1988, 37.'),
('Camirus',NULL,128,36.333,27.950,NULL,1200,1300,'ca / ?',NULL,NULL,NULL,NULL,'ceramic','similar to RobinsonK109 and Almagro51C',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,167,NULL),
('Canarias',NULL,129,26.000,-16.000,'ca',200,300,'ca',NULL,NULL,NULL,NULL,'amphoras','Pascual1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,168,NULL),
('Cap Bear 1',NULL,130,42.517,3.133,NULL,-50,25,'ca / ?',26.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,169,NULL),
('Cap Bear 2',NULL,131,42.517,3.133,NULL,100,300,'ca',35.0,NULL,NULL,NULL,'amphoras','Beltran4B; Dressel 14; Ibizan amphora; flat-bottomed amphora',NULL,NULL,NULL,NULL,NULL,'6 iron anchors, lead anchor-stock',NULL,'hull timbers',NULL,NULL,NULL,170,NULL),
('Cap Bénat 1',NULL,132,43.083,6.367,NULL,30,50,'ca',37.0,NULL,NULL,NULL,'amphoras','Laubenheimer54 Haltern70',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,172,'F. Mayet 1987, 289.'),
('Cap Bénat 3',NULL,133,43.083,6.367,NULL,1,50,'ca',54.0,NULL,NULL,NULL,'amphoras','Almagro51C Afr2B-D Beltran72',NULL,NULL,NULL,NULL,NULL,'lead device/water heater',NULL,NULL,NULL,NULL,NULL,174,NULL),
('Cap Blanc',NULL,134,39.367,2.783,'ca',295,325,'ca / ?',50.0,NULL,NULL,NULL,'amphoras','Haltern70','ceramic','vaulting tube, plate, jar',NULL,NULL,NULL,NULL,NULL,'timbers preserved',16.0,NULL,'remains',176,NULL),
('Cap Bon 1',NULL,135,37.083,11.033,NULL,1,100,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,177,NULL),
('Cap Bon 2',NULL,136,37.083,11.033,'ca',-25,100,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Valencian cobalt blue and metallic luster bowls',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,178,NULL),
('Cap Couronne',NULL,137,43.317,5.033,NULL,1450,1500,'ca',NULL,NULL,NULL,NULL,'amphoras','Afr',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,181,NULL),
('Cap Croisette',NULL,138,43.200,5.333,NULL,200,400,'ca',NULL,NULL,NULL,NULL,'amphoras','Pascual1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,182,NULL),
('Cap de Creus',NULL,139,42.317,3.317,'ca',-50,25,'ca / ?',20.0,NULL,NULL,NULL,'ceramic','Afr2D',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,184,NULL),
('Cap de Garde',NULL,140,36.950,7.800,NULL,285,365,'ca',15.0,NULL,NULL,NULL,'amphoras','Pascual1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,185,NULL),
('Cap del Vol',NULL,141,42.350,3.167,NULL,-10,5,'ca',24.0,NULL,NULL,NULL,'amphoras','Dressel 1B and 1C','ceramic','coarseware, fine-wall jars, imitation Arretine',NULL,NULL,NULL,'pump, part of anchor',NULL,'mast-step, sternpost, planking, lead sheets, hull',19.0,NULL,NULL,186,NULL),
('Cap Gros','Collioure',142,42.517,3.100,NULL,-125,-50,'ca',54.0,NULL,1977,'ca (1977 observed 1988 excavated)','amphoras','Dr20','ceramic','cooking pots (ollae), ceramic ampuritaine','metal','copper urn',NULL,'wooden pump with discs and tubes,',NULL,'Cap Gros dated end C2 BC or first half C1 BC; Dressel 1B, 1C (proportion 20:1)',10.5,5.5,NULL,187,'J. P. Joncheray 1989.'),
('Cap Leucate 1',NULL,143,42.917,3.067,NULL,1,275,'ca / ?',NULL,NULL,NULL,NULL,'tiles','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,192,NULL),
('Cap Leucate 2',NULL,144,42.917,3.067,NULL,-50,100,'ca / ?',NULL,NULL,NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,193,NULL),
('Cap Magroua',NULL,145,36.417,0.817,NULL,1,500,'ca',NULL,NULL,NULL,NULL,'amphoras','LR cylindrical',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,194,NULL),
('Cap Roux 2',NULL,146,43.433,6.933,NULL,300,400,'ca',38.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,196,NULL),
('Cape Akritas',NULL,147,36.717,21.867,NULL,0,0,'c1 - end or c2 - beginning',10.0,NULL,NULL,NULL,'amphoras','roof tiles',NULL,NULL,NULL,NULL,NULL,'ballast',NULL,NULL,NULL,NULL,NULL,201,NULL),
('Cape Andreas 1',NULL,148,35.667,34.583,NULL,400,650,'ca',18.0,NULL,NULL,NULL,'amphoras','Riley LR13','metal','bronze fragments',NULL,NULL,NULL,'lead anchor reinforcement collar',NULL,NULL,NULL,NULL,NULL,202,NULL),
('Cape Andreas 2',NULL,149,35.667,34.583,NULL,600,700,'ca / ?',9.0,NULL,NULL,NULL,'amphoras','Riley LR1 & 1A','glass','vessels',NULL,NULL,NULL,NULL,NULL,'tiles from cabin roof',NULL,NULL,NULL,203,NULL),
('Cape Andreas 3',NULL,150,35.667,34.583,NULL,450,650,'ca / ?',10.0,NULL,NULL,NULL,'metal','Byzantine baluster-shaped',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,204,NULL),
('Cape Andreas 5',NULL,151,35.667,34.583,NULL,450,650,'ca',25.0,NULL,NULL,NULL,'amphoras',NULL,'ceramic','terracotta sarcophagi',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,206,NULL),
('Cape Andreas 6',NULL,152,35.667,34.583,NULL,1,500,'ca',20.0,NULL,NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,207,NULL),
('Cape Gelidonya 3',NULL,153,36.233,30.417,'ca',0,0,'ca / ?',46.0,NULL,NULL,NULL,'marble','Late Byz sgraffito pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'hearth tiles from galley',5.0,3.0,'remains',210,NULL),
('Cape Gelidonya 4',NULL,154,36.233,30.417,'ca',1200,1500,'ca / ?',54.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,211,NULL),
('Cape Izmetiste',NULL,155,43.158,16.347,NULL,1,100,'ca / ?',NULL,NULL,NULL,NULL,'ceramic','Byz',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'M. Juriši? 2000; A.M. McCann and J.P. Oleson 2004, 92.'),
('Cape Kiti 1',NULL,156,34.800,33.617,NULL,600,700,'c3 to c4',2.0,NULL,NULL,NULL,'marble','Dr6A',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,212,NULL),
('Cape Kiti 2',NULL,157,34.800,33.617,NULL,-10,40,'ca (end c3/beg c4AD)',NULL,'shallow',NULL,NULL,'amphoras','(?)',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,213,NULL),
('Cape Sidero 1',NULL,158,35.317,26.333,'ca',1,500,'ca / ?',NULL,NULL,NULL,NULL,'marble',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,214,NULL),
('Cape Sidero 2',NULL,159,35.317,26.333,'ca',500,1500,'undated',NULL,NULL,NULL,NULL,'amphoras','LR1 (150 necks), local, for oil, with some writings on them indicating measurements for dry goods',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,215,NULL),
('Cape Zevgari, Cyprus',NULL,160,34.567,32.929,NULL,400,600,'ca / ?',6.0,NULL,NULL,NULL,'amphoras','copper ingots',NULL,NULL,NULL,NULL,NULL,'lead block pierced twice, similar to ones foud at Dor',NULL,'Survey discovery. Likely represents cargo of a small coastal trader',35.0,15.0,'ca',NULL,'J. Leidwanger 2004, 25-26;  J. Leidwanger 2007, 308-316.'),
('Capo Bellavista',NULL,161,39.917,9.717,NULL,-25,25,'ca / ?',7.0,NULL,NULL,NULL,'amphoras','Afr1','metal','tin ingots','metal','lead ingots',NULL,NULL,NULL,NULL,NULL,NULL,NULL,218,NULL),
('Capo Carbonara 2',NULL,162,39.100,9.500,NULL,200,275,'ca',10.0,NULL,NULL,NULL,'tiles','wall tiles',NULL,NULL,NULL,NULL,NULL,'pottery vaulting tube',NULL,'500 m offshore',NULL,NULL,NULL,220,NULL),
('Capo Carbonara 3',NULL,163,39.083,9.533,NULL,30,70,'ca / ?',NULL,'shallow',NULL,NULL,'amphoras','cipollino columns','ceramic','pipes',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,221,NULL),
('Capo Cimiti',NULL,164,38.950,17.167,NULL,1,500,'ca / ?',7.0,NULL,NULL,NULL,'amphoras','pear-shaped',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,222,NULL),
('Capo di Muro',NULL,165,41.750,8.667,NULL,1,500,'ca',22.0,NULL,NULL,NULL,'amphoras','roof tiles',NULL,NULL,NULL,NULL,NULL,'lead anchor stocks',NULL,NULL,NULL,NULL,NULL,225,NULL),
('Capo Ferrato',NULL,166,39.283,9.617,NULL,1,500,'ca',3.0,NULL,NULL,NULL,'stone','Proconessian marble blocks','amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,228,NULL),
('Capo Granitola 1',NULL,167,37.550,12.667,NULL,225,275,'ca',NULL,'shallow',NULL,NULL,'marble','LR','ceramic','pottery','amphoras','Kapitän2',NULL,'iron anchor and lead stock',NULL,'150 m from shore',NULL,NULL,NULL,229,NULL),
('Capo Granitola 3',NULL,168,37.550,12.667,NULL,250,400,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Asiatic marble capitals and plinths',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,231,NULL),
('Capo Granitola 4',NULL,169,37.550,12.667,'ca',300,500,'ca / ?',NULL,NULL,NULL,NULL,'ceramic','Afr1 Afr2A',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,232,NULL),
('Capo Graziano 12',NULL,170,38.550,14.583,NULL,150,250,'ca',35.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,242,NULL),
('Capo Graziano 13',NULL,171,38.550,14.567,NULL,1,500,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Keay61',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,243,NULL),
('Capo Graziano 14',NULL,172,38.550,14.567,'ca',400,400,'ca',42.0,NULL,NULL,NULL,'metal','Dr20 Dr7 Dr2-4 horn-handled','ceramic','strainer jar',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,243,NULL),
('Capo Graziano 3',NULL,173,38.550,14.583,NULL,1,10,'ca',44.0,NULL,NULL,NULL,'marble','roof tiles',NULL,NULL,NULL,NULL,NULL,'lead anchor stock',NULL,'100 m from coast',NULL,NULL,NULL,235,NULL),
('Capo Passero',NULL,174,36.683,15.150,NULL,400,650,'ca / ?',12.0,NULL,NULL,NULL,'ceramic','Afr1 Tripolitanian','amphoras','Byzantine',NULL,NULL,NULL,NULL,NULL,NULL,20.0,36.0,'remains',245,NULL),
('Capo Plaia',NULL,175,38.017,13.933,NULL,200,275,'ca',1.0,NULL,NULL,NULL,'amphoras',NULL,'ceramic','small jug','stone','grinding stone',NULL,NULL,NULL,NULL,NULL,NULL,NULL,246,NULL),
('Capo Rizzuto',NULL,176,38.900,17.067,'ca',1,500,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','small base-ring, cf. Panella46',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,250,NULL),
('Capo San Alessio',NULL,177,37.900,15.350,NULL,100,300,'ca',50.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,251,NULL),
('Capo San Vito',NULL,178,40.417,17.217,NULL,1,500,'ca / ?',NULL,NULL,NULL,NULL,'metal',NULL,NULL,NULL,NULL,NULL,NULL,'lead-stocked anchor',NULL,NULL,NULL,NULL,NULL,252,NULL),
('Capo Sant''Elia',NULL,179,39.167,9.150,'ca',1,500,'ca / ?',NULL,NULL,NULL,NULL,'ceramic','Roman hand mills - millstones',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,255,NULL),
('Capo Schisò (Italy)',NULL,180,37.825,15.277,'ca',1,500,'ca',NULL,NULL,NULL,NULL,'ceramic','37 green marble columns, 2 blocks',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Unpublished',NULL,NULL,NULL,255,NULL),
('Capo Taormina',NULL,181,37.833,15.300,NULL,1,500,'ca / ?',28.0,NULL,NULL,NULL,'amphoras','Haltern70 Dr9',NULL,NULL,NULL,NULL,NULL,'sounding lead',NULL,'copper bolt with square plate',NULL,NULL,NULL,256,NULL),
('Capo Testa 1',NULL,182,41.233,9.133,'ca',1,75,'ca',16.0,NULL,NULL,NULL,'amphoras','pottery','ceramic','brown-glazed dish','metal','2 lead plates',NULL,NULL,NULL,NULL,NULL,NULL,NULL,257,NULL),
('Capo Vite',NULL,183,42.867,10.400,NULL,1300,1500,'ca / ?',72.0,NULL,NULL,NULL,'amphoras','wine amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'metal sheaves and timbers',NULL,NULL,NULL,259,NULL),
('Capraia 1',NULL,184,43.050,9.833,'ca',-100,100,'ca / ?',35.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,261,NULL),
('Capraia 2',NULL,185,43.067,9.817,NULL,1,500,'ca',50.0,NULL,NULL,NULL,'marble','bronze statues','ceramic','pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,262,NULL),
('Capraia 3',NULL,186,42.983,9.800,NULL,0,0,'ca',100.0,NULL,NULL,NULL,'marble','blocks','marble','statues',NULL,NULL,NULL,NULL,NULL,'timbers',NULL,NULL,NULL,263,NULL),
('Capraia 4',NULL,187,43.000,9.800,NULL,1,500,'ca',NULL,NULL,NULL,NULL,'metal','pottery bowls',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,264,NULL),
('Capraia 5',NULL,188,43.067,9.833,NULL,1000,1500,'ca',52.0,NULL,NULL,NULL,'amphoras','Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,265,NULL),
('Caprera',NULL,189,41.233,9.450,NULL,100,200,'ca',NULL,NULL,NULL,NULL,'metal',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,266,NULL),
('Carro 1',NULL,190,43.317,5.033,NULL,525,550,'ca',5.0,NULL,NULL,NULL,'amphoras','Dr20','ceramic','terra sigillata chiara dish','metal','lead bar, lead stock or ingot',NULL,NULL,NULL,NULL,NULL,NULL,NULL,268,NULL),
('Carro 3',NULL,191,43.317,5.033,NULL,1,275,'ca / ?',NULL,NULL,NULL,NULL,'ceramic','lead ingoterra sigillata',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,270,NULL),
('Cartagena 1',NULL,192,37.600,-0.983,NULL,-50,50,'ca / ?',NULL,NULL,NULL,NULL,'metal','Portugese pottery','ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,272,NULL),
('Casnewydd',NULL,193,51.588,-2.998,NULL,1400,1600,'ca / ?',NULL,'silted',NULL,NULL,'ceramic','Pisan pottery','coins','Portugese coins',NULL,NULL,'combs, gaming piece; shoes, sail cloth, woolen clothing','cannon balls',NULL,'Remains of a man under the ship. Scuttled and stripped out hull, edge-fastened  by iron nails, 10m mast step.',29.0,8.0,NULL,NULL,'O.T.P. Roberts 2004, 158-163.'),
('Castellammare del Golfo',NULL,194,38.050,12.883,'ca',1400,1500,'ca',70.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,276,NULL),
('Castelsardo',NULL,195,40.917,8.700,NULL,100,200,'ca / ?',12.0,NULL,NULL,NULL,'amphoras','Beltran2A',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,278,NULL),
('Castillo','El Pecio Castillo',196,37.800,-0.733,NULL,1,100,'imperial (?)',NULL,NULL,NULL,NULL,'amphoras','Almagro51A Dr23 cylindrical Beltran72',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,279,NULL),
('Catalans, Les',NULL,197,43.283,5.333,NULL,350,350,'ca',41.0,NULL,NULL,NULL,'amphoras','Dr2-4; 2 Spanish amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'bricks of cooking hearth',NULL,NULL,NULL,280,NULL),
('Cavallo 1',NULL,198,41.350,9.250,NULL,40,50,'ca',12.0,NULL,NULL,NULL,'amphoras','LR','glass','clear bowls with greenish rim','ceramic','mortarium, larger Italian terra sigillata plate, coarseware, terra sigillata inkwell,','bronze lamp, bronze figurine, 2 coins, ladle or strainer handle and hook, 5-pronged fishing spear, 50 iron and 50 copper nails,','sounding-lead, ballast',NULL,'preserved hull, keel, some strakes, some frames',NULL,NULL,NULL,283,NULL),
('Cavallo 2',NULL,199,41.367,9.250,NULL,275,400,'ca / ?',8.0,NULL,NULL,NULL,'amphoras','columns',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,284,NULL),
('Cavlena',NULL,200,45.100,14.450,NULL,1,500,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,'stone',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,288,NULL),
('Cavo (Italy)',NULL,201,42.865,10.437,'ca',0,0,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','lead token, silver spoon, bronze cauldron, steelyard weight, scissors, sword','metal','bronze Roma (steelyard?) weight','coins','dupondius of Antoninus Pius, bronze medallion of Marcus Aurelius',NULL,NULL,NULL,'coins: dupondius of Antoninus Pius, bronze medallion of Marcus Aurelius.',NULL,NULL,NULL,288,NULL),
('Cavoli',NULL,202,39.083,9.533,NULL,1425,1440,'ca / ?',13.0,NULL,NULL,NULL,'coins','some still corked, w/ inscriptions of content, type Riley LRA 1 = Scorpan VIII B = British Bii','ceramic','cobalt blue glazed ware','tiles',NULL,NULL,'iron anchor, 7 cannon, 16 breeches, stone and iron balls, lead shot; lead token, silver spoon, bronze cauldron, steelyard weight, scissors, cobalt blue glazed ware, tiles, sword',NULL,'ship''s planking',NULL,NULL,NULL,289,NULL),
('Cefalù',NULL,203,38.017,14.033,NULL,400,600,'ca / ?',3.0,NULL,NULL,NULL,'ceramic','copper pot','amphoras','Byzantine . For oil (type Riley LRA 2 = Scorpan VII A = British Bi)','amphoras','Scorpan 5o, 2k, 16s/Riley LRA8, 3i','amphora stores (Keay53, 54, 55, 62), terra sigillata chiara type D decorated, iron and stone utensils, domestic pottery,  axe','ballast, several iron anchors',NULL,'bricks from galley, frame timbers',35.0,6.0,'remains',292,'G. Purpura 1993, 163-184.'),
('Cervia',NULL,204,44.317,12.317,NULL,1,500,'ca / ?',NULL,'in alluvium',NULL,NULL,'dolia','Dr2-4','amphoras','fragments',NULL,NULL,NULL,'sounding lead, roof tile, iron anchor',NULL,'hull of a lagoon boat',15.0,3.0,NULL,293,NULL),
('Cervo',NULL,205,43.917,8.117,NULL,-50,100,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Roman fineware',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'less than 1 mile from shore',NULL,NULL,NULL,294,NULL),
('Chantenay',NULL,206,46.750,3.000,'ca',1,500,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,295,NULL),
('Charbrowo 1',NULL,207,54.733,17.517,NULL,920,1190,'ca',NULL,'in alluvium',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on dendro (15 samples with interval 1112-1190) and 14C (2 samples with interval 920-930).  All dating done on planks.  Discovered in 1896. Slavonic context. Oak, pine and juniper vessel, sailed/oared.',13.2,3.3,NULL,NULL,'Navis I, Charbrowo 1, #139; H. Lemcke 1898, 305-309; M. Zeylandowa 1984, 241-242; P. Smolarek 1985, 171-184; A. Pazdur et al. 1994, 127-195; W. Filipowiak 1996, 91-96; N. Bonde, T. Wazny, and A. Daly 1999; M. Krapiec and W. Ossowski 2000, 27-32.'),
('Chaudeney-sur-Moselle 1',NULL,208,47.817,5.500,NULL,1,500,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dugout, 14C 100 +/-60',NULL,NULL,NULL,296,NULL),
('Chaudeney-sur-Moselle 2',NULL,209,47.817,5.500,NULL,1,500,'ca',NULL,NULL,NULL,NULL,'amphoras','lead ingots',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dugout, 14C 200 +/-70',NULL,NULL,NULL,297,NULL),
('Cherchel 1',NULL,210,36.600,2.183,NULL,-25,75,'ca',4.0,NULL,NULL,NULL,'amphoras','pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'well-preserved hull',NULL,NULL,NULL,298,NULL),
('Cherchel 2',NULL,211,36.600,2.183,NULL,1,500,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'well-preserved hull',NULL,NULL,NULL,299,NULL),
('Chia',NULL,212,38.900,8.900,'ca',200,275,'ca',44.0,NULL,NULL,NULL,'amphoras','Beltran2A Dr20 Haltern70; 2 Ibizan amphoras, Dr2-4 amphora',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,300,NULL),
('Chiessi',NULL,213,42.750,10.100,NULL,60,85,'ca',50.0,NULL,NULL,NULL,'nothing reported','Beltran2B','metal','lead ingot','ceramic','South Gaulish terra sigillata dish, two terra sigillata bowls, terra sigillata chiara A lid and cup',NULL,'decorated lead tank',NULL,'copper nail',25.0,12.0,'remains',301,NULL),
('Chrétienne 2, La',NULL,214,43.417,6.883,NULL,50,200,'ca / ?',NULL,NULL,NULL,NULL,'coins','Almagro51C Beltran 72 cylindrical ovoid, Dr23',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,303,NULL),
('Chrétienne 4, La',NULL,215,43.417,6.883,NULL,325,375,'ca',25.0,NULL,NULL,NULL,'ceramic','Dr2-4, Dr9-10, Dr7, Dr43, Dr20 Punic Rhodian amphoras','ceramic','pottery',NULL,NULL,NULL,'2 lead anchors',NULL,'remains of hull',NULL,NULL,NULL,305,'J.P. Joncheray 1997a, 121-135.'),
('Chrétienne 8, La',NULL,216,43.417,6.883,NULL,15,20,'ca / ?',58.0,NULL,NULL,NULL,'amphoras','Dr9-10, apparently Dr26, related to Dr28','ceramic','coarseware jugs, fine-wall vessels','glass','vessels','2 axes, short sword sheath, cutlass, dagger, roll of lead','pump, 2 anchors',NULL,'well-preserved hull',15.0,5.0,NULL,307,NULL),
('Chrétienne 9, La',NULL,217,43.417,6.883,NULL,1,100,'ca / ?',53.0,NULL,NULL,NULL,'amphoras','Richborough 527',NULL,NULL,NULL,NULL,'resin','lead pipe',NULL,NULL,5.0,8.0,'remains',308,'P. Sibella 1997, 228-229.'),
('Chrétienne M-3',NULL,218,43.417,6.883,NULL,1,100,'ca',NULL,NULL,NULL,NULL,'dolia','Lam6 Dr6','ceramic','Pompeian plates, plates of open form or covered','marble','marble plaque','lead seals of merchandise, mineral objects, pumice stone, pozzolana, Egyptian blue',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'A. Joncheray and J.P. Joncheray 2002, 57-130.'),
('Cikat',NULL,219,44.517,14.450,NULL,-100,100,'late Rome',NULL,NULL,NULL,NULL,'nothing reported','coins of Saloninus-Quintillus, from 260s to early 270s',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,311,NULL),
('Ciotat 4, La',NULL,220,43.083,5.617,'ca',275,275,'ca',NULL,'considerable',NULL,NULL,'amphoras','leaf-pattern imitation ts',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,315,NULL),
('Ciovo',NULL,221,43.500,16.283,NULL,-100,200,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,316,NULL),
('Circeo 4',NULL,222,41.217,13.117,NULL,-25,25,'ca',15.0,NULL,NULL,NULL,'amphoras','Afr2B or 2D','amphoras','Dr2-4','ceramic','terra sigillata italica',NULL,NULL,NULL,NULL,NULL,NULL,NULL,320,NULL),
('Circeo 5',NULL,223,41.233,13.033,NULL,200,325,'ca',NULL,NULL,NULL,NULL,'amphoras','Halter70 Cam186',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,321,NULL),
('Circeo 6',NULL,224,41.233,13.000,'ca',0,0,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Roman',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,321,NULL),
('Ciudadela (Spain)',NULL,225,39.983,3.817,'ca',1,500,'ca / ?',NULL,NULL,NULL,NULL,'ceramic','pear-shaped',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,322,NULL),
('Civitavecchia',NULL,226,42.083,11.767,NULL,50,150,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Afr2B-D',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'keel and planking',NULL,NULL,NULL,323,NULL),
('Colonia de Sant Jordi 3',NULL,227,39.300,3.000,NULL,250,300,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,'ceramic','large plates with blackened rim',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,327,NULL),
('Colonia de Sant Jordi 4',NULL,228,39.300,3.000,NULL,0,0,'ca',NULL,NULL,NULL,NULL,'amphoras','Dr7-11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'hull',NULL,NULL,NULL,328,NULL),
('Columbretes',NULL,229,39.833,0.667,NULL,-25,75,'ca / ?',35.0,NULL,NULL,NULL,'amphoras','60 Serçe Limani type, rounded, short neck.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,332,NULL),
('Çomlek Burun',NULL,230,36.717,28.083,'ca',1000,1200,'ca',65.0,NULL,NULL,NULL,'amphoras','Beltran4B',NULL,NULL,NULL,NULL,NULL,'grapnel anchor',NULL,'Survey discovery. TK05-AC. Serçe Limani wreck is 15 km to SW. Dating of wreck based on amphora shape and size and similarity with Serçe Limani type.  In addition, grapnel anchor also provided a time frame, which is slightly wider than the amphora evidence.',10.0,3.0,'ca',NULL,'J.G. Royal 2006, 3-11; J.G. Royal 2006, 195-217; Leidwanger 2007, 308-316.'),
('Conillera','San Antonio Abad',231,38.967,1.200,NULL,30,190,'ca',30.0,NULL,NULL,NULL,'amphoras',NULL,'ceramic','Dressel 15','metal','ingots',NULL,'lead anchor stock',NULL,'extensive remains of ship; some of cargo came from Lusitania',25.0,10.0,'remains',334,'F. Mayet 1987, 289.'),
('Contarina',NULL,232,45.033,12.217,NULL,1200,1225,'ca / ?',NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'ship, stringers',21.0,NULL,NULL,335,NULL),
('Corbella',NULL,233,42.717,10.350,NULL,1,500,'ca',45.0,NULL,NULL,NULL,'amphoras','gold coins minted 270-274',NULL,NULL,NULL,NULL,NULL,'lead anchor stock',NULL,NULL,NULL,NULL,NULL,336,NULL),
('Corsica',NULL,234,41.000,9.000,'ca',274,274,'ca / ?',NULL,NULL,NULL,NULL,'amphoras',NULL,'metal','thick gold rings',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,338,NULL),
('Corte Cavanella',NULL,235,45.350,12.267,'ca',1,300,'ca / ?',NULL,'silted',NULL,NULL,'amphoras',NULL,'glass',NULL,'lamps','oil lamps','coins',NULL,NULL,'flat-bottomed boat in a cavana, a Venetian boat shelter. Left in situ.',7.5,1.9,NULL,339,NULL),
('Cortegada',NULL,236,42.500,-8.883,'ca',1,100,'ca',NULL,NULL,NULL,NULL,'amphoras','Dr1','ceramic','terra sigillata plates, native pottery','tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,340,NULL),
('Courreaux-de-Groix (France)',NULL,237,47.686,-3.369,'ca',0,0,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'No direct evidence. Only one amphora.',NULL,NULL,NULL,340,NULL),
('Cova del Infern',NULL,238,42.317,3.317,'ca',-100,150,'ca / ?',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,341,NULL),
('Cudrefin','Dugout Cudrefin VD 1871',239,46.950,7.017,NULL,-50,150,'ca',NULL,NULL,NULL,NULL,'stone','Dr20 Beltran2B',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dugout, resembles Bronze Age boat, 14C end of Iron age or early Roman period',11.3,NULL,NULL,342,NULL),
('Cueva del Jarro 2',NULL,240,36.717,-3.717,NULL,50,100,'ca / ?',30.0,NULL,NULL,NULL,'amphoras','Pascual1','metal','bronze Roman cuirass',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,343,NULL),
('Culip 1','L''Encalladora',241,42.317,3.283,NULL,-50,25,'c2 - end or c3 - beginning',12.0,NULL,NULL,NULL,'amphoras','Pascual1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,345,NULL),
('Culip 3',NULL,242,42.317,3.283,NULL,-50,25,'ca',18.0,NULL,NULL,NULL,'amphoras','Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'perhaps ship''s hull',NULL,NULL,NULL,346,NULL),
('Culip 4',NULL,243,42.317,3.283,NULL,70,80,'ca / ?',7.0,NULL,NULL,NULL,'amphoras','Beltran2A','ceramic','fine-wall cups and beakers, lamps','ceramic','South Gaulish terra sigillata plain and decorated vessels (Drag37 & 29)','amphoras, cooking pottery, two mortaria, five tiles, two lamps, glass unguentarium, three bronze rings, pottery bead or spindle whorl, stone tablets, glass and stone counters. lead fishing weights','lead ring, nail-lifter or drove, signal horn amphoras, cooking pottery, two mortaria, five tiles, two lamps, glass unguentarium, three bronze rings, pottery bead or spindle whorl, stone tablets, glass and stone counters. lead fishing weights',NULL,'small fragments of hull, frames and planking, nails, pump',10.0,3.0,NULL,347,NULL),
('Culip 5',NULL,244,42.317,3.283,NULL,50,100,'ca / ?',NULL,NULL,NULL,NULL,'masonry','pottery from Granada and Languedoc',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,348,NULL),
('Culip 6',NULL,245,42.317,3.283,NULL,1350,1400,'ca',5.0,'less than ten meters says Rieth',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,'meat; butchered sheep/goat, cattle, horse, pig, fowl',NULL,NULL,'Rieth says beginning of 14th C.; probably Catalan origin; preserved hull (11m of the bottom of hull preserved)',NULL,NULL,NULL,349,'E. Rieth 1998, 205-212.'),
('Czarnowsko 1',NULL,246,55.733,17.517,NULL,910,1174,'ca',NULL,'in alluvium',NULL,NULL,'stone',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on 14C (3 samples with interval 910-1010) and dendro (18 samples from planks with interval 1138-1174).   Pine, oak oared/sailed, oared/sailed Slavonic working boat  in Slavonic context. Discovered 1957.',13.8,3.4,NULL,NULL,'Navis I, Czarnowsko 1, #137; O. Lienau 1939, 145-150; W. Filipowiak 1957, 342-345; P. Smolarek 1957, 200-207; W. Garcznski 1958, 393-397; W. Filipowiak 1996, 91-96; N. Bonde, T. Wazny, and A. Daly 1999.'),
('Czarnowsko 2',NULL,247,55.733,17.517,NULL,860,1040,'ca',NULL,'in alluvium',NULL,NULL,'amphoras','Byzantine',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on one 14C sample with a margin of 90 yrs.  Slavonic, oak, pine working boat, in Slavonic context.',12.8,3.0,NULL,NULL,'Navis I, Czarnowsko 2, #196.'),
('Datca 1',NULL,248,36.717,27.683,'ca',400,650,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','globular baluster-shaped',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,351,NULL),
('Datca 2',NULL,249,36.650,27.667,'ca',650,725,'ca',49.0,NULL,NULL,NULL,'amphoras','Kapitän1 RobinsonK114',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'well-preserved hull',NULL,NULL,NULL,352,NULL),
('Datca 3',NULL,250,36.717,27.433,'ca',275,325,'ca / ?',37.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,353,NULL),
('De Meern 1',NULL,251,52.083,5.200,NULL,100,200,'ca / ?',NULL,'silted',2003,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,'wooden bucket','shipper''s furniture',NULL,'Cargo oak vessel, Roman, oared/sailed.  Dating based on ceramics; Jansma, Vorst & Visser date to ca. 148 AD based on dendro dating - suggest revising to more accurate date.',22.0,2.5,NULL,NULL,'Navis I, De Meern 1, #85; J. Morel 1998; E. Jansma, Y.E. Vorst, and R.M. Visser 2008, 25-26.'),
('De Meern 2',NULL,252,52.083,5.200,NULL,100,200,'ca',NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Working boat, Roman context which also provides the approximate dating. No 14C or dendro dating.',NULL,1.0,NULL,NULL,'Navis I, De Meern 2, #86; J. Morel 1998.'),
('De Meern 3',NULL,253,52.083,5.200,NULL,0,0,'ca',NULL,NULL,NULL,NULL,'ceramic','similar to RileyD377, perhaps Riley LR1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Oak cargo vessel of Roman context. No further information provided by database.',NULL,NULL,NULL,NULL,'Navis I, De Meern 3, #98; J. Morel 1998.'),
('Delphinion',NULL,254,38.483,26.117,NULL,400,600,'ca',10.0,NULL,NULL,NULL,'stone','Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,357,NULL),
('Denia 1',NULL,255,38.000,0.000,NULL,150,225,'ca',400.0,NULL,NULL,NULL,'stone','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,358,NULL),
('Denia 2',NULL,256,38.000,0.000,'ca',0,0,'ca / ?',NULL,NULL,NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,358,NULL),
('Deventer 2',NULL,257,52.250,6.167,NULL,990,990,'ca / ?',NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Cargo sailed vessel, oak dendro dated',NULL,NULL,NULL,NULL,'Navis I, Deventer 1, #71; K. Vlierman 1997, 92-95.'),
('Deventer 2',NULL,258,52.250,6.167,NULL,1047,1047,'ca',NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Cargo sailed vessel, dendro (oak) dated.',NULL,NULL,NULL,NULL,'Navis I, Deventer 2, #72; M.D. de Weerd 1987, 272-276.'),
('Deventer 3',NULL,259,52.250,6.167,NULL,913,913,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Roman-type Rhodian Nubian Coan Dr18 Dr25',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Cargo sailed vessel, dendro (oak) dated.',NULL,NULL,NULL,NULL,'Navis I, Deventer 3, #73; K. Vlierman 1997, 96-100.'),
('Dhia 1',NULL,260,35.417,25.217,'ca',1,100,'ca / ?',30.0,NULL,NULL,NULL,'amphoras','Günsenin1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,359,NULL),
('Dhia 2',NULL,261,35.417,25.217,'ca',900,1000,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Günsenin3',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,360,NULL),
('Dhia 3',NULL,262,35.417,25.217,'ca',1100,1200,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Dr2-4; Dr7-11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,361,NULL),
('Diano Marina 1',NULL,263,43.883,8.100,NULL,50,50,'ca / ?',50.0,NULL,NULL,NULL,'amphoras','Beltran2B','dolia',NULL,'ceramic','coarseware, fine-wall ware, mortarium, Italian terra sigillata, volute lamps,','lead container, glass paste counters, engraved cornelian gem, gold ring with garnet, rooftiles, fishing weights','Dr7-11 amphoras, coarseware, fine-wall ware, mortarium, Italian terra sigillata, volute lamps, lead container, glass paste counters, engraved cornelian gem, gold ring with garnet, rooftiles, fishing weights',NULL,'well-preserved hull',25.0,NULL,'remains',364,NULL),
('Diano Marina 2',NULL,264,43.883,8.100,'ca',0,0,'ca / ?',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,364,NULL),
('Dor',NULL,265,32.600,34.900,NULL,600,700,'ca / ?',2.0,NULL,NULL,NULL,'metal','Palestine',NULL,NULL,NULL,NULL,NULL,'t-shaped iron anchor',NULL,'well-preserved bottom of Byzantine ship. Further Raveh and Kingsley 1992 brief survey shows 3 or more wrecks datable to Byzantine period in the same location',NULL,NULL,NULL,367,'K. Raveh and S. Kingsley 1992, 309-315; A.D. de la Presle 1993, 580-589; S. Kingsley and K. Raveh 1994, 1-12; S. Kingsley and K. Raveh 1994, 289-295; Y. Kahanov and J.G. Royal 2001, 257-265.'),
('Dor 1','Dor A',266,32.600,34.900,NULL,600,640,'ca / ?',3.0,NULL,NULL,NULL,'amphoras','sandstone (kurkar, 80 in number) porba local',NULL,NULL,NULL,NULL,NULL,'stone ballast',NULL,'wooden planking',22.0,NULL,'?',NULL,'S. Kingsley 2002, 4-5; S. Kingsley 2004, 38.'),
('Dor 2001/1',NULL,267,32.600,34.900,NULL,420,540,'ca',1.0,NULL,NULL,NULL,'amphoras','LR4, LR5; petrology Palestine between Gaza & Ashkelon','amphoras','Yassi Ada','ceramic','Gaza ware; Byzantine cooking pots',NULL,'rope, mat on ceiling of ship',NULL,'Dating by 14C, on ten samples from planking (oak, pine, beech, christ''s thorn, tamarisk, elm, cypress)  rope and matting, averaged with OxCal method. Caulking. This is NOT Tantura: see H. Mor and Y. Kahanov 2006, Table 3; Frame first construction.',11.5,4.5,'Mor 2005 gives the dimensions of the ship as 16x6m',NULL,'H. Mor 2005, 14-16; H. Mor and Y. Kahanov 2006, 274-289.'),
('Dor 4 (D)','Dor D',268,32.600,34.900,NULL,539,621,'ca / ?',2.0,NULL,NULL,NULL,'amphoras','Palestine','metal','2 bronze steelyards, pear-shaped counterbalance lead weight sheated in copper, w/ inscription of different owners and christian sign of cross Artemon-Psates of Rhion','stone','cheap stone anchors','gear: LR1  (Paphos kiln?) LR2 ARS Keay 42D; roof tiles from Cyprus; hearth tiles seem to be from Palestine; iron pick','3 single hole cheap stone anchors, marble ballast stones, iron pick',NULL,'Dating based on 14C on plank and artefacts. 30m from shore.  14 planks remain. Treenails still used despite fact that archaeologists believe they were abandoned after early 7th C. Kingsley 2002; small coaster that had come from western Cyprus (Paphos?) on last voyage, bringing recycled empty amphoras to Palestine stone ballast; only few strakes: estimated size from well-preserved ballast deposit = 15 m: Kingsley 2002, 85.',16.0,NULL,'length can be less than 16',NULL,'K. Raveh and S. Kingsley 1992, 309-315; A.D. de la Presle 1993, 580-589; S. Kinglsey and K. Raveh 1994, 1-12; S. Kinglsey and K. Raveh 1994, 289-295; Y. Kahanov and J.G. Royal 2001, 257-265; S. Kingsley 2002, 6.'),
('Dor 5 (E)','Dor E',269,32.600,34.900,NULL,500,700,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,'stone ballast',NULL,'If Galili and Rosen 2008 are referring to this wreck and not a new one, it can be dated by hoard of 53 AE coins in lump, of which the latest dated 659–663/4 AD. Hull discernible from iron nails medium-sized ship; remains of fishing kit and ship''s carpenter''s kit. Iron remains (nails, spread over area of 15 X  25 m);  2.5-3.5 m deep. Excavated 1998-9.',NULL,NULL,NULL,NULL,'S. Kingsley & K. Raveh 1996, 66-67; S. Kingsley 2002, 4; E. Galili and B. Rosen 2008, 67-76.'),
('Dor 6 (F)','Dor F',270,32.600,34.900,NULL,600,640,'ca',2.0,NULL,NULL,NULL,'lamps','stone ballast','marble','ashlar ; mortar (unused)','metal','copper flask with iron handle, similar to one found at Yassi Ada and 4 other similar contexts in the Mediterranean.  Author claims this is feature of 7th c. Byzantine  metallurgy. Also found a copper pitcher.',NULL,'single hole stone anchor, hammer head',NULL,'hull; dating based on artefacts. Parker seems to have recorded only Dor A, which is near F.',NULL,NULL,NULL,NULL,'K. Raveh and S. Kingsley 1992, 309-315; A.D. de la Presle 1993, 580-589; S. Kinglsey and K. Raveh 1994, 1-12; S. Kingsley and K. Raveh 1994, 289-295; Y. Kahanov and S. Breitstein 1995; S. Kingsley 2002, 4.'),
('Dor 7 (G)','Dor G',271,32.600,34.900,NULL,600,640,'ca',2.2,NULL,NULL,NULL,'lamps',NULL,'masonry','ashlar blocks',NULL,NULL,NULL,NULL,NULL,NULL,9.0,NULL,'length can be 9 or less',NULL,'K. Raveh and S. Kingsley 1992, 309-315; A.D. de la Presle 1993, 580-589; S.  Kinglsey and K. Raveh 1994, 1-12; S. Kinglsey and K. Raveh 1994, 289-295; Y. Kahanov and S. Breitstein 1995.'),
('Dor O (Trench IX)',NULL,272,32.600,34.900,NULL,553,645,'ca',NULL,NULL,NULL,NULL,'amphoras','LR5','ceramic','pottery',NULL,NULL,NULL,NULL,NULL,'Dating based on 14C.',NULL,NULL,NULL,NULL,'S. Wachsmann, Y. Kahanov, and J. Hall 1997, 10; S. Kingsley 2002, 4.'),
('Dor Trench IV',NULL,273,32.600,34.900,NULL,500,700,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','quern (?)',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'unclear if different from Tantura A: Kingsley 2002, 4',NULL,NULL,NULL,NULL,'S. Wachsmann, Y. Kahanov, and J. Hall 1997, 10; S. Kingsley 2002, 4.'),
('Dorestad',NULL,274,52.967,5.333,NULL,800,900,'ca',NULL,'silted',NULL,NULL,'amphoras','Afr2A',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'oak; clinker built, many iron nails. Fragments of ship possibly used as revetment? Cargo identification of objects not certain. wicker basket with stones, unworked animal bones.',NULL,NULL,NULL,NULL,'Navis I, Dorestad 1, #65; W.A. van Es and W.J.H. Verwers 1981, 72-76; K. Vlierman 1997, 83-87; W.A. van Es, W.J.H. Verwers, and J. van Doesburg 2009, 243-256.'),
('Dragonera 1',NULL,275,39.567,2.333,NULL,200,275,'ca',30.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,368,NULL),
('Dragonera 3',NULL,276,39.567,2.350,NULL,0,0,'ca',4.0,NULL,NULL,NULL,'amphoras','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,369,NULL),
('Dramont 2',NULL,277,43.400,6.833,NULL,1,25,'ca / ?',39.0,NULL,NULL,NULL,'amphoras','Rhodian Dr2-4, [Dr45 for Type II says Carraze] Amphoras Dr2-5, probably 44-45]','ceramic','cooking ware, Arretine, and Iberian pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,372,NULL),
('Dramont 4',NULL,278,43.400,6.833,NULL,40,50,'ca',55.0,'or 53',NULL,NULL,'amphoras','large cylindrical (cf Keay 35), Keay 25, spatheia; LRA4A; Keay 52; Almagro 51C','stone','mortaria','metal','bronze pumps','lamps, lead jar, storage amphoras, cooking pots, flat dish, lids, bronze jar, bronze skillets, Arretine cups and plates, fine-wall goblet, coarseware vessels, copper nails in a basket, axe, gimlet, graver, axe-hammer, key, knife, tools, bronze inkwell','1 lead-stocked and 3 iron anchors, 2 sounding leads',NULL,'part of spar',18.0,6.0,'remains',374,NULL),
('Dramont 5','Dramont E',279,43.400,6.833,NULL,420,425,'ca',42.0,NULL,NULL,NULL,'amphoras','LR cylindrical Almagro51A Keay52','ceramic','terra sigillata chiara D (Hayes 61B, 64, 65, 50B);  jugs, platter','coins','dated 383-423','weights, rotary hand-mill of limestone, vaulting tubes','large iron anchors, sounding-lead',NULL,'mast-partners, mast foot, mast-step, pump-well; homogeneously preserved hull; dating from bronze money. Homogenous cargo of amphoras and many wares were produced in Nabeul (Neapolis); other wares produced in yet unlocalized workshop stylistically related to Sidi Khalifa: Bonifay 2004, 452-3.',18.0,6.0,NULL,375,'J.P. Joncheray 1972, 11-34; C. Santamaria 1995; S. Kingsley 2004, 25, 47; D. Pieri 2005, 42-43.'),
('Dramont 6',NULL,280,43.400,6.817,NULL,400,400,'ca',58.0,NULL,NULL,NULL,'ceramic','sigillata Drag. 18 and Ritt 8','ceramic','terra sigillata chiara D dish, terra sigillata lucente dish, coarseware','metal','bronze pitcher',NULL,'4 iron anchors',NULL,'hull',12.0,5.0,NULL,376,NULL),
('Dramont 7',NULL,281,43.400,6.817,NULL,60,70,'ca',48.0,NULL,NULL,NULL,'amphoras','blocks','tiles','roof tiles','amphoras','fragment Dr28 or Gauloise2','jars, cup, lamp, scraper, hammer, axe, harpoon, burin, large ring, iron and bronze nails; terra sigillata cups, coarseware dishes, bowls, and jars','iron anchor',NULL,'fragment of keel',11.0,NULL,NULL,377,NULL),
('Dramont 9',NULL,282,43.400,6.833,NULL,1,500,'ca',30.0,NULL,NULL,NULL,'metal','pumice stones',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,378,NULL),
('Dramont 9/I',NULL,283,43.400,6.833,NULL,25,50,'ca',33.0,NULL,NULL,NULL,'metal','color-coated pottery, red-gloss',NULL,NULL,NULL,NULL,'sapphires','cylindric part (possibly anchor)',NULL,'hull parts',NULL,NULL,NULL,NULL,'A. Joncheray and J.P. Joncheray 1997, 165-195.'),
('Druten',NULL,284,51.883,5.617,NULL,200,200,'ca / ?',NULL,'silted',NULL,NULL,'amphoras','Dr20','coins','coin dated to ca. 200','metal','axe',NULL,'pole-fitting',NULL,'remains of Roman barge',27.0,NULL,NULL,379,NULL),
('Dunas del Pinatar',NULL,285,37.800,-0.750,NULL,1,250,'ca / ?',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,380,NULL),
('Dunwich Bank',NULL,286,52.083,1.567,NULL,775,892,'ca / ?',NULL,'shallow(?)',NULL,NULL,'amphoras','Keay25',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'survey find. Dating by 14C.  Anglo-Saxon dugout',5.0,NULL,NULL,NULL,'J. Flatman and L. Blue 1999, 174-199.'),
('Eloro 1',NULL,287,36.833,15.183,'ca',300,450,'c3',57.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,'anchors',NULL,'4 km off coast',NULL,NULL,NULL,381,NULL),
('Empoli',NULL,288,43.717,10.950,NULL,1300,1400,'ca',NULL,NULL,NULL,NULL,'metal','Günsenin1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,11.0,NULL,NULL,384,NULL),
('Erdek',NULL,289,40.467,27.750,NULL,900,1200,'ca',NULL,NULL,NULL,NULL,'marble','Almagro51C',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,385,NULL),
('Escolletes 1, Los',NULL,290,37.733,-0.717,NULL,200,300,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Dr38','ceramic','fine tableware','glass',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,386,NULL),
('Escolletes 2, Los',NULL,291,37.733,-0.717,NULL,200,400,'ca',NULL,NULL,NULL,NULL,'ceramic','Dr1','ceramic','vaulting tubes or amphorisks',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,387,NULL),
('Escombreras',NULL,292,37.559,-0.941,NULL,NULL,NULL,'ca',NULL,NULL,NULL,NULL,'ceramic','Dr7-11','metal','stamped lead ingots',NULL,NULL,NULL,'wood',NULL,NULL,NULL,NULL,NULL,NULL,'J.P. Reyes 1996, 72 n30.'),
('Espines, Los',NULL,293,37.717,-0.717,NULL,-25,50,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,390,NULL),
('Est-Perduto',NULL,294,41.367,9.333,NULL,1,50,'c2 - beginning',87.0,NULL,NULL,NULL,'lamps','hundreds of bronze objects',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,10.0,NULL,'remains',392,NULL),
('Favaritx',NULL,295,40.000,4.267,NULL,450,600,'ca',22.0,NULL,NULL,NULL,'amphoras','LR','amphoras',NULL,'ceramic','coarseware',NULL,NULL,NULL,NULL,NULL,NULL,NULL,397,NULL),
('Favone (France)',NULL,296,41.783,9.400,'ca',1,500,'ca',NULL,NULL,NULL,NULL,'amphoras','Afr2B-D Keay3A sim. and 81 Almagro51C Dr23',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,397,NULL),
('Femmina Morta',NULL,297,36.800,14.483,NULL,300,325,'ca / ?',4.0,NULL,NULL,NULL,'amphoras','Roman','ceramic','terra sigillata chiara D cups, dishes, and plates; coarse pottery, vaulting tubes',NULL,NULL,'wood combs',NULL,NULL,'keep, frames, planking, and lead sheathing',NULL,NULL,NULL,398,NULL),
('Filfla',NULL,298,35.817,14.333,'ca',1,500,'ca',NULL,NULL,NULL,NULL,'nothing reported','Keay62',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,400,NULL),
('Filicudi Porto A',NULL,299,38.550,14.583,NULL,475,550,'ca / ?',40.0,NULL,NULL,NULL,'amphoras',NULL,'amphoras','Wine (type Beltran-Lloris 59), from modern Tunisia',NULL,NULL,NULL,NULL,NULL,'Bernabo-Brea (cited by Parker 1992) gives late 3rd early 4th C. date (p. 29, 95)',NULL,NULL,NULL,401,NULL),
('Fiumicino 10',NULL,300,41.767,12.233,NULL,0,0,'ca / ?',NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'boat filled with concrete, represented by concrete mold-marks in the mole',22.0,7.5,NULL,411,NULL),
('Fiumicino 11',NULL,301,41.767,12.233,NULL,42,50,'ca / ?',NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'represented by concrete mold-marks in the mole',26.0,8.0,NULL,412,NULL),
('Fiumicino 12',NULL,302,41.767,12.233,NULL,42,50,'ca',NULL,'silted',NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'concrete cast of ship used by Caligula to bring an obelisk from Egypt, set in Claudian harbor mole as base of lighthouse',104.0,20.3,NULL,413,NULL),
('Fiumicino 2',NULL,303,41.767,12.233,NULL,300,400,'ca',NULL,'silted',NULL,NULL,'coins',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'mast-step, yard, shaft of a steering oar, 14C: late 2nd C.',11.5,NULL,NULL,403,NULL),
('Fiumicino 3',NULL,304,41.767,12.233,NULL,300,400,'ca / ?',NULL,'silted',NULL,NULL,'amphoras',NULL,'metal','bronze statuette of Venus; steelyard weight, iron instrument','coins','bronze',NULL,'rigging-block, pulley, mat, lamps, bronze statuette of venus, steelyard weight, wooden box, bronze coins, iron instrument, bone netting needle',NULL,'two mast-steps, 14C: late 2nd C.',13.5,NULL,NULL,404,NULL),
('Fiumicino 4',NULL,305,41.767,12.233,NULL,200,400,'ca',NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'part of the side of a boat, 14C: 1st half, 2nd C.',NULL,NULL,NULL,405,NULL),
('Fiumicino 5',NULL,306,41.767,12.233,NULL,0,0,'ca / ?',NULL,'silted',NULL,NULL,'stone',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'part of the side of a large cargo ship',NULL,NULL,NULL,406,NULL),
('Fiumicino 6',NULL,307,41.767,12.233,NULL,300,400,'ca / ?',NULL,'silted',NULL,NULL,'amphoras',NULL,'metal','bronze plate',NULL,NULL,NULL,NULL,NULL,'remains of cargo boat with decorative bronze overlay, 14C: early-mid 2nd C.',22.0,NULL,NULL,407,NULL),
('Fiumicino 7',NULL,308,41.767,12.233,NULL,200,400,'ca / ?',NULL,'silted',NULL,NULL,'metal',NULL,NULL,NULL,NULL,NULL,'cable, wooden knife-handle',NULL,NULL,'hull of cargo boat, 14C: early-mid 2nd C.',24.0,NULL,NULL,408,NULL),
('Fiumicino 8',NULL,309,41.767,12.233,NULL,0,0,'end date is open ended',NULL,'silted',NULL,NULL,'tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'remains of boat',4.4,NULL,NULL,409,NULL),
('Fiumicino 9',NULL,310,41.767,12.233,NULL,0,0,'ca / ?',NULL,'silted',NULL,NULL,'metal',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'remains of boat',11.3,NULL,NULL,410,NULL),
('Flavigny-sur-Moselle (France)',NULL,311,48.567,6.183,'ca',0,0,'ca / ?',NULL,NULL,NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dugout once part of raft, C14: 540 AD +/-80',NULL,NULL,NULL,413,NULL),
('Fondana Amorosa',NULL,312,35.083,32.300,NULL,1,500,'ca',30.0,NULL,NULL,NULL,'amphoras','Afr2',NULL,NULL,NULL,NULL,NULL,'sounding lead',NULL,NULL,NULL,NULL,NULL,414,NULL),
('Fontanamare 1',NULL,313,39.267,8.433,NULL,290,310,'ca / ?',7.0,NULL,NULL,NULL,'amphoras',NULL,'ceramic','African coarseware of gray-walled black-rimmed type, terra sigillata chiara A/D','coins',NULL,'gold ring, bronze steelyard with weight, brooches, mirror, spatula, wooden handle',NULL,NULL,NULL,NULL,NULL,NULL,415,NULL),
('Fontanamare 3',NULL,314,39.267,8.433,'ca',0,0,'ca / ?',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,417,NULL),
('Formiche di Grosseto 1, Le',NULL,315,42.550,10.883,NULL,1,500,'ca / ?',60.0,NULL,NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,'lead anchor stock',NULL,NULL,NULL,NULL,NULL,419,NULL),
('Formiche di Grosseto 2, Le',NULL,316,42.550,10.883,NULL,1,500,'ca / ?',NULL,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,420,NULL),
('Formiche di Grosseto 3, Le',NULL,317,42.550,10.883,NULL,1,500,'ca / ?',40.0,NULL,NULL,NULL,'nothing reported','Dr6',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,421,NULL),
('Fos 2',NULL,318,43.417,4.933,NULL,1,100,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,423,NULL),
('Fotevik 1',NULL,319,55.417,12.933,NULL,900,1100,'ca / ?',NULL,'shallow',NULL,NULL,'amphoras','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on typology. Vessel was part of a blockade in the  bay. Oared, sailed?, Nordic oak military vessel',10.3,2.4,NULL,NULL,'Navis I, Fotevik 1, #173; O. Crumlin-Pedersen 1984; O. Crumlin-Pedersen 1995.'),
('Fourmigues, Les',NULL,320,43.033,6.067,NULL,50,50,'ca',54.0,NULL,NULL,NULL,'nothing reported','bowls with rosette and rays',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,426,NULL),
('Frasca, La',NULL,321,42.117,11.750,'ca',1475,1500,'ca',NULL,NULL,NULL,NULL,'ceramic','Pascual1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,427,NULL),
('Freu d''en Valento',NULL,322,41.467,2.417,NULL,-50,25,'ca',42.0,NULL,NULL,NULL,'amphoras','copper ingots',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,428,NULL),
('Frontignan',NULL,323,43.383,3.733,'ca',50,50,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','iron ore',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,429,NULL),
('Fuenterrabia',NULL,324,43.383,-1.900,NULL,100,150,'ca / ?',NULL,NULL,NULL,NULL,'amphoras',NULL,'ceramic','terra sigillata cup',NULL,NULL,NULL,NULL,NULL,NULL,25.0,15.0,'remains',430,NULL),
('Galli',NULL,325,40.567,14.417,NULL,1,500,'ca',45.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,433,NULL),
('Galtabäck 1',NULL,326,57.033,12.317,NULL,1144,1195,'ca',NULL,'silted',NULL,NULL,'amphoras','Dr14 Beltran2A Dr17',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on 4 dendro dates from plank ranging 1144-1195.',13.1,3.6,NULL,NULL,'Navis I, Galtabäck 1, #174; P. Humbla and L. von Post 1937; O. Crumlin-Pedersen and O. Olsen 1967, 73-174; A. Daly 1998;  T. Thieme 1998, 22;  T. Thieme 1999.'),
('Gandolfo',NULL,327,36.683,-2.783,NULL,90,110,'ca',10.0,NULL,NULL,NULL,'amphoras','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,435,NULL),
('Garoupe 1, La',NULL,328,43.550,7.150,NULL,10,35,'ca',12.0,NULL,NULL,NULL,'amphoras','Dr20','dolia','[dolia of capacity of 1000-2000L]','ceramic','mortarium','lead bowl, lead piping','hemispheric lead container, terra cotta',NULL,'Fiori says wreck occurred in 2nd half of C1 AD',NULL,NULL,NULL,436,'P. Fiori 1972, 35-44.'),
('Garoupe 3, La',NULL,329,43.567,7.133,NULL,140,200,'ca',NULL,'shallow',NULL,NULL,'amphoras','copper ingots',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,438,NULL),
('Getaria (Spain)',NULL,330,43.303,-2.195,'ca',0,0,'ca',NULL,NULL,NULL,NULL,'amphoras','columns, blocks',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Unpublished',NULL,NULL,NULL,442,NULL),
('Giardini',NULL,331,37.817,15.283,NULL,200,300,'ca / ?',24.0,NULL,NULL,NULL,'amphoras',NULL,'amphoras',NULL,'ceramic','mortarium',NULL,NULL,NULL,'bronze boss with ring, bronze hinge and copper and bronze nails represent fittings or furnishing of the ship',17.0,6.0,'remains',443,NULL),
('Gibraltar 1',NULL,332,36.100,-5.350,NULL,1,500,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,444,NULL),
('Gibraltar 2',NULL,333,36.100,-5.350,NULL,1,500,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,445,NULL),
('Gibraltar 3',NULL,334,36.100,-5.350,NULL,500,1500,'ca',NULL,NULL,NULL,NULL,'marble','Dr9',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,446,NULL),
('Gibraltar Strait',NULL,335,35.967,-5.500,NULL,1,100,'ca / ?',400.0,NULL,NULL,NULL,'amphoras','S Gaulish terra sigillata, Drag. 18, 27, 35, and 32/37',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,447,NULL),
('Giens 2',NULL,336,43.017,6.117,'ca',1,100,'ca',NULL,NULL,NULL,NULL,'tiles','later medieval jar',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,449,NULL),
('Giglio',NULL,337,42.317,10.883,NULL,1200,1400,'ca',18.0,NULL,NULL,NULL,'ceramic','Afr2A (1 Mauretanian)',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,450,NULL),
('Giglio Porto',NULL,338,42.350,10.917,NULL,200,225,'ca',40.0,NULL,NULL,NULL,'amphoras',NULL,'metal','iron bars, lead weights','ceramic','jug, black-rimmed cooking ware, pottery tubes','drinking glasses, lamps','lead weights',NULL,'preserved hull',30.0,8.0,NULL,453,NULL),
('Ginosar',NULL,339,32.833,35.517,NULL,50,50,'ca',NULL,NULL,NULL,NULL,'metal','Roman','ceramic','pottery',NULL,NULL,NULL,NULL,NULL,'boat excavated, 14C: 120 BC - 40 AD',9.0,2.5,NULL,454,NULL),
('Glaronissi',NULL,340,39.367,26.333,'ca',1,500,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,455,NULL),
('G??bia Gotlandzka',NULL,341,56.450,19.417,NULL,800,900,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Dr6A',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'No info on dating in database. Slavonic working boat, dugout.',4.3,NULL,NULL,NULL,'Navis I, G??bia Gotlandzka, #131; W. Ossowski 1999, 121-125.'),
('Goica',NULL,342,43.167,16.400,NULL,-25,50,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,456,NULL),
('Gokstad',NULL,343,59.139,10.249,NULL,890,900,'ca',NULL,'silted (buried)',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on dendro. Military oak and pine oared/sailed vessel, used for  (maybe royal) burial.  Riding equipment, a sled and a tent found inside as well as two human skeletons.',23.2,5.2,NULL,NULL,'Navis I, Gokstad, #182; Nicolaysen 1882; A.W. Brøgger and H. Shetelig 1951; C. Blindheim 1981; N. Bonde and A.E. Christensen 1993; N. Bonde 1994; J. Bill et al. 1997.'),
('Golfo della Stella',NULL,344,42.733,10.317,NULL,0,0,'ca',40.0,NULL,NULL,NULL,'metal',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,459,NULL),
('Golo',NULL,345,42.517,9.533,NULL,1,500,'ca',NULL,NULL,NULL,NULL,'amphoras','Dr7-11 Beltran2A',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'well-preserved boat, mast-step, deck, hull,',14.0,NULL,NULL,460,NULL),
('Gorgona 1',NULL,346,43.400,9.900,NULL,1,100,'ca / ?',55.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,461,NULL),
('Gorgona 2',NULL,347,43.400,9.900,NULL,0,0,'ca',NULL,NULL,NULL,NULL,'amphoras','Afr1 Kapitän1 Afr2A Tripolitanian horn-handled, Dressel 19, Forlimpopoli A, Cnidia; many with evidence of fish and fish paste',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,462,NULL),
('Grado',NULL,348,45.717,13.333,'ca',150,150,'ca',15.0,NULL,NULL,NULL,'ceramic','LR cylindrical','metal','bronze stands, bronze Neptune, bronze steelyard weight','glass','broken glass in a barrel - waste for recycling;  glass sherds and domestic wares',NULL,'conical sounding lead, barrel? Hydraulic pump',NULL,'lead-sheathing and frames, mortice and tenon, patched; pine, elm, rigging, part of sail; some oil amphoras recycled; at least 600 amphoras, total cargo weight 23-25 tons. Ship had been repaired more than once, and was probably fairly old (Beltrame and Gaddi 2007, 144; 146).',18.0,5.0,NULL,464,'R. Auriemma 2000, 27-51; C. Beltrame and D. Gaddi 2005, 79-87; C. Beltrame and D. Gaddi 2007, 138-147.'),
('Graham Bank 2',NULL,349,37.133,12.750,NULL,375,450,'ca',NULL,NULL,NULL,NULL,'tiles','mortaria, coarseware jug, fine-wall beaker',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,466,NULL),
('Grand Bassin 3',NULL,350,43.100,3.100,NULL,120,120,'ca',4.0,NULL,NULL,NULL,'amphoras','4000 coins ending 313','lamps',NULL,'stone','mortarium',NULL,NULL,NULL,'ship well-preserved before dredging',NULL,NULL,NULL,470,NULL),
('Grand Bassin 4',NULL,351,43.100,3.117,NULL,313,313,'ca',4.0,NULL,NULL,NULL,'stone','Dr2/4 Pascual 1 Dr9, dolia','amphoras',NULL,'metal','copper nails',NULL,NULL,NULL,NULL,NULL,NULL,NULL,471,NULL),
('Grand Ribaud D/4',NULL,352,43.017,6.133,NULL,-9,10,'ca',18.0,'(19)',NULL,NULL,'amphoras','Dr2-4',NULL,NULL,NULL,NULL,NULL,'3 pulleys, wood filoir, rings, vestiges of a deck pump, grapple',NULL,'dating based on Arretine ceramic',NULL,NULL,NULL,NULL,'A. Hesnard et al. 1988; P. Pomey and L. Long 1988, 30-32.'),
('Grand Rouveau, Le',NULL,353,43.067,5.750,NULL,50,50,'ca',35.0,NULL,NULL,NULL,'tiles','querns','metal','large leaden vessel','ceramic','small jug, mortarium, 2 Arretine plates',NULL,'iron and lead-stocked anchors, bilge pump',NULL,NULL,15.0,8.0,'remains',478,NULL),
('Graveney',NULL,354,51.317,0.933,'ca',895,944,'ca',NULL,'in alluvium',NULL,NULL,'amphoras','Dr7-11',NULL,NULL,NULL,NULL,'grain (hops)',NULL,NULL,'Dating based on 14C (944 ±30) and oak dendro (927±2 and 895±2). Unable to get dendro match in ''94.  Cargo vessel in Anglo-Saxon context',13.6,4.0,NULL,NULL,'Navis I, Graveney, #88;  W.A. Oddy 1971; V. Fenwick 1972, 119-129; W.A. Oddy 1972, 175-177; E. McKee 1973; J.M. Fletcher 1977, 335-352; V. Fenwick and A. Morley 1978;  E. McKee 1978; E. McKee 1978; J.M. Fletcher 1984, 151; E. Gifford 1986, 124-129; V. Fenwick 1997, 175-176; S. McGrail 1997, 350.'),
('Gravisca',NULL,355,42.217,11.700,NULL,1,100,'ca / ?',NULL,'shallow',NULL,NULL,'amphoras','bronze pots, box, strainer, lamp, fittings','metal','iron bars',NULL,NULL,NULL,NULL,NULL,'200 m from shore',NULL,NULL,NULL,481,NULL),
('Grazel 2',NULL,356,43.100,3.100,NULL,631,631,'ca',NULL,NULL,NULL,NULL,'amphoras','roof tiles','coins','coins ending 630-1 AD',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,483,NULL),
('Grebeni',NULL,357,44.317,14.700,'ca',1,500,'ca',NULL,NULL,NULL,NULL,'amphoras','ingots',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,484,NULL),
('Grottammare (Italy)',NULL,358,42.983,13.867,'ca',0,0,'ca',NULL,NULL,NULL,NULL,'amphoras','pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,484,NULL),
('Grscica',NULL,359,42.900,16.767,NULL,1,200,'ca',NULL,NULL,NULL,NULL,'amphoras','Dr7-11 Dr14 Dr 20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,487,NULL),
('Guardias Viejas',NULL,360,36.717,-2.883,NULL,50,125,'ca',14.0,NULL,NULL,NULL,'marble','PE25 PE41 Dr2-4 Pascual1','ceramic','conical pots',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,488,NULL),
('Guardis 2, Na',NULL,361,39.300,3.000,NULL,1,25,'ca',3.0,NULL,NULL,NULL,'amphoras',NULL,'ceramic','S Gaulish terra sigillata bowls, fine-wall beakers, coarseware',NULL,NULL,'oysters','ballast',NULL,'remains of hull',NULL,NULL,NULL,490,NULL),
('Gumusluk','Myndus',362,37.117,27.283,NULL,300,400,'ca',NULL,NULL,NULL,NULL,'tiles','pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,491,NULL),
('Gusteranski',NULL,363,43.633,15.717,NULL,1,200,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,492,NULL),
('Haderslev-Møllesstrømmen',NULL,364,55.254,9.489,NULL,1211,1240,'ca',4.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'15-20 tons','Survey find. Dendrodated cargo ship, clinker built, probably traded with Ribe where wood may be from.  15-30 tons displacement with maximum cargo of 15-20 tons. Not decorated.',15.0,5.0,'ca',NULL,'A. Englert 1999.'),
('Haghiokambos',NULL,365,39.617,23.083,'ca',0,0,'ca',6.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,493,NULL),
('Hahoterim 2',NULL,366,32.733,34.933,NULL,200,300,'ca',2.0,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'keel of a small boat',NULL,NULL,NULL,495,NULL),
('Haithabu 1',NULL,367,54.517,9.550,NULL,960,980,'ca',NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating by dendro on (local) oak plank. Military ship. Viking context, Nordic type.',30.9,2.7,NULL,NULL,'Navis I, Haithabu 1, #8; A.E. Christensen 1999, 350.'),
('Haithabu 3',NULL,368,54.517,9.550,NULL,790,1025,'ca',NULL,'silted',NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating by dendro based on oak plank and keel (hence different dates). Cargo vessel. Viking context, Nordic type.',22.1,6.3,NULL,NULL,'Navis I, Haithabu 3, #9; A.E. Christensen 1999, 350.'),
('Hardham',NULL,369,50.933,-0.517,NULL,245,345,'ca',NULL,NULL,NULL,NULL,'coins','Günsenin1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dugout, 14C: 295+/-50',3.9,NULL,NULL,497,NULL),
('Hayirsiz',NULL,370,40.633,27.450,NULL,1000,1100,'ca',22.0,NULL,NULL,NULL,'amphoras','cylindrical LR3; cf. Keay 25.1, 25.3: homogenous cargo of amphoras produced and loaded at Salakta (Sullechtum): M. Bonifay, Études sur la céramique romaine tardive d''Afrique, BAR international series 1301 (Oxford, 2004), 453',NULL,NULL,NULL,NULL,NULL,'medieval anchor',NULL,'little of hull',NULL,NULL,NULL,498,NULL),
('Heliopolis 1',NULL,371,43.017,6.417,NULL,300,400,'ca',38.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'keel, 200 m from shore; coin dated 300-310, one 5th C. amphora, 3rd C. wreck (according to Hayes) based on common wares, Joncheray dates to 4th C. like Pointe de la Luque.',14.0,NULL,NULL,499,'J.P. Joncheray 1997b, 137-164.'),
('Herculaneum',NULL,372,40.750,14.167,'ca',79,79,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'boat carbonized by volcanic mud, 500 m from modern coast',9.0,NULL,NULL,501,NULL),
('Herculaneum 2',NULL,373,40.800,14.333,NULL,1,100,'ca',NULL,'silted',NULL,NULL,'amphoras','mortaria',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Coordinates from Navis I (40 n 45, 14 e 30 are inaccurate).  Roman context, small boat',NULL,NULL,NULL,NULL,'Navis I, Herculaneum 2, #199; M. Tuccinardi 1998, 39-42.'),
('Herne Bay',NULL,374,51.367,1.100,NULL,55,85,'ca',NULL,NULL,NULL,NULL,'amphoras','(?)',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,502,NULL),
('Hof Hacarmel 1',NULL,375,32.800,34.933,NULL,160,170,'ca',4.0,NULL,NULL,NULL,'amphoras','Byzantine','metal','bronze statuettes, steelyard, neck chain; copper nails','coins','coins of Trajan, Hadrian, Antoninus Pius and Faustina the Younger',NULL,'lead anchor stock, bronze statuettes, steelyard, neck chain, coins of Trajan, Hadrian, Antoninus Pius and Faustina the Younger, copper nails',NULL,NULL,NULL,NULL,NULL,504,NULL),
('Hof Hacarmel 2',NULL,376,32.800,34.933,NULL,400,425,'ca',4.0,NULL,NULL,NULL,'amphoras','Keay35','coins','Arcadius','metal','copper nails',NULL,NULL,NULL,NULL,NULL,NULL,NULL,505,NULL),
('Hormigas, Las',NULL,377,37.650,-0.650,NULL,425,550,'ca',60.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,506,NULL),
('Iassos',NULL,378,37.233,27.617,'ca',300,700,'ca',23.0,NULL,NULL,NULL,'amphoras','Dr2-4, Pelichet 47',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'well-preserved hull',NULL,NULL,NULL,509,NULL),
('îles-Rousse',NULL,379,42.633,8.933,NULL,50,50,'ca',3.0,NULL,NULL,NULL,'amphoras','Dr2-4; horn-handled amphora','dolia',NULL,'ceramic','terra sigillata, coarseware','lead ingot, fine bronze lamp, bronze decorative plaque','pump',NULL,'ingot with Nero',NULL,NULL,NULL,510,NULL),
('Ilovik',NULL,380,44.467,14.533,NULL,120,120,'ca',30.0,NULL,NULL,NULL,'amphoras','Afr','ceramic','pottery','glass',NULL,'lamps, sestertius struck in 116, wooden combs, roof tiles, bronze jug and dish',NULL,NULL,NULL,NULL,NULL,NULL,513,NULL),
('Imera',NULL,381,38.000,13.783,NULL,285,350,'ca',32.0,NULL,NULL,NULL,'amphoras',NULL,'ceramic','coarse pottery','metal','bronze and lead objects','lamps; coins','sounding lead',NULL,NULL,NULL,NULL,NULL,514,NULL),
('Immenstaad',NULL,382,47.660,9.357,NULL,1324,1344,'ca',NULL,'shallow',NULL,NULL,'ceramic','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on dendro dates obtained on oak. Flat bottomed vessel',NULL,NULL,NULL,NULL,'D. Hakelberg 1996, 224-233.'),
('Ince Ada',NULL,383,36.683,28.217,NULL,1,100,'ca',30.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,516,NULL),
('Ionian 1',NULL,384,39.583,18.950,'ca',1,400,'ca / ?',700.0,NULL,NULL,NULL,'tiles','Keay25 Keay32 cf Keay53 [Keay 35 Tunisian]; Almagro51A',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Survey find. Dating based on anchor shape.',NULL,NULL,NULL,NULL,'B. Phaneuf et al. 2002, 28-29.'),
('Isis','Skerki',385,38.000,11.500,'ca',375,400,'ca',818.0,NULL,NULL,NULL,'amphoras','egg-shaped havit (bag-shaped), cigar-shaped from Gaza, hourglass shaped from Cyprus/Asia Minor, carrot-shaped Egyptian','ceramic','cooking pot','coins','Constantius II','lead, wood, hand-mill, lamp, cooking pot, coin of Constantius II',NULL,NULL,NULL,13.5,5.0,'length ranges from 12.5 to 15',517,'Mark 1997, 208-209; F.D. Hentschel 2004, 10-13.'),
('Iskandil Burnu 1',NULL,386,36.700,27.333,NULL,575,600,'ca',35.0,NULL,NULL,NULL,'amphoras','Roman','ceramic','coarseware jugs and plates, sealed casserole','glass','goblet',NULL,NULL,NULL,'2000+ globular amphoras. Main cargo appears to have come from Palestine.',20.0,5.0,NULL,518,NULL),
('Iskandil Burnu 2',NULL,387,36.700,27.333,NULL,200,300,'ca',10.0,NULL,NULL,NULL,'stone','fragments of late types',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,519,NULL),
('Islas Hormigas, Cartagena',NULL,388,37.654,-0.651,NULL,200,400,'ca',NULL,NULL,NULL,NULL,'marble','Haltern70','ceramic','terra sigillata Clara D',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'J.P. Reyes 1996, 70-71 n26.'),
('Isle of Wight',NULL,389,50.000,0.000,'ca',1,100,'ca',NULL,NULL,NULL,NULL,'nothing reported','blocks, perhaps Proconessian',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,521,NULL),
('Isola delle Correnti',NULL,390,36.633,15.083,NULL,200,400,'ca',9.0,NULL,NULL,NULL,'stone',NULL,'amphoras','Afr2 amphora',NULL,NULL,NULL,NULL,NULL,'piece of lead sheathing',NULL,NULL,NULL,522,NULL),
('Isola Rossa',NULL,391,41.017,8.867,NULL,100,200,'ca',NULL,NULL,NULL,NULL,'coins','tegulae, imbrices, without any apparent order or organization','ceramic','terra sigillata chiara bowl',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,524,NULL),
('Isolella 1',NULL,392,41.833,8.750,NULL,90,110,'ca',32.0,NULL,NULL,NULL,'nothing reported','pottery','amphoras','Dr20',NULL,NULL,NULL,'concretion of nails on a tile, wood fragment with concretions',NULL,'no trace of hull found',NULL,NULL,NULL,NULL,'H. Alfonsi and P. Gandolfo 1991, 199-207; P. Pomey and L. Long 1993, 60.'),
('Israel',NULL,393,32.000,34.000,NULL,500,600,'ca',40.0,NULL,NULL,NULL,'amphoras','Lam6 or Dr6',NULL,NULL,NULL,NULL,NULL,'ballast',NULL,NULL,NULL,NULL,NULL,525,NULL),
('Ist',NULL,394,44.283,14.767,NULL,-100,100,'ca',NULL,NULL,NULL,NULL,'tiles','lead ingots',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,526,NULL),
('Istria',NULL,395,44.750,13.917,'ca',1,1500,'ca',2.0,NULL,NULL,NULL,'amphoras','Roman (several thousands (?))','metal','lead anchor stocks',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,528,NULL),
('Ithaki-Kephalonia',NULL,396,38.342,20.646,'ca',-100,100,'ca',60.0,NULL,NULL,NULL,'metal','Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Only surveyed by sonar and preliminary dives. At N end of sound between Itaki and Kephalonia.  This wreck has not been assigned a precise identification in this publication.',25.0,NULL,'ca',NULL,'K. Delaporta, M.E. Jasinski, and F. Soreide 2006, 79-87.'),
('Jarre',NULL,397,43.200,5.333,NULL,10,50,'ca / ?',54.0,NULL,NULL,NULL,'amphoras','Byzantine',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,529,NULL),
('Jezirat Fara''un (Sinai)',NULL,398,33.571,35.372,NULL,500,1500,NULL,NULL,NULL,NULL,NULL,'glass','Byzantine',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Probably anchorage debris of Byzantine  amphoras. Possibility of wreck deep under sand.',NULL,NULL,NULL,531,NULL),
('Kallithea',NULL,399,40.167,23.500,'ca',500,1500,NULL,3.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,532,NULL),
('Kamie? Pomorski',NULL,400,53.617,14.783,NULL,1076,1210,NULL,NULL,'in alluvium',NULL,NULL,'nothing reported','iron ring, caulking iron, C14 130+-30',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on 12 dendro samples (mostly from planks) with interval 1076-1150; 3 14C samples (from luting and planks) with interval 1080-1140 and average margin of 45.  Oak, pine cargo vessel, sailed/oared, found in the mouth of the Dziwna river, under 1.2 m of sediment.  Sherds on the layer directly above it were dated 11-12th C.',11.6,1.7,NULL,NULL,'Navis I, Kamie? Pomorski, #138; W. Filipowiak 1986, 84-86; W. Filipowiak 1994, 83-96; M.F. Pazdur et al. 1994, 127-195; W. Filipowiak 1996, 91-96;  N. Bonde, T. Wazny, and A. Daly 1999.'),
('Kapel Avazaath',NULL,401,51.900,5.417,NULL,100,160,'ca / ?',NULL,'silted',NULL,NULL,'nothing reported','Rhodian',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'hull of barge',30.0,NULL,NULL,533,NULL),
('Karabagla',NULL,402,37.000,27.233,NULL,1,100,NULL,8.0,NULL,NULL,NULL,'nothing reported',NULL,'lamps',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,534,NULL),
('Karaca Adasi',NULL,403,36.950,28.167,NULL,0,0,NULL,10.0,NULL,NULL,NULL,'nothing reported',NULL,'ceramic','pithoi',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,535,NULL),
('Karschau',NULL,404,54.622,9.892,NULL,1145,1145,NULL,NULL,NULL,NULL,NULL,'nothing reported','late medieval',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dendro dated w/15 samples of wood, whose provenance has been ascertained to be from N. Germany and Denmark. Clinker built.',22.0,6.4,NULL,NULL,'A. Englert 2000, 34-57; H.J. Kühn et al. 2000, 42-45; A. Daly 2007, 155-156.'),
('Kas',NULL,405,36.133,29.633,'ca',1200,1400,NULL,NULL,NULL,NULL,NULL,'nothing reported','glazed pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,537,NULL),
('Kastellorizon',NULL,406,36.117,29.533,NULL,1200,1225,NULL,50.0,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,538,NULL),
('Kerme Gulf',NULL,407,36.983,27.733,'ca',300,1200,NULL,20.0,NULL,NULL,NULL,'nothing reported','(?)','amphoras',NULL,'ceramic','coarse pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,543,NULL),
('Kizil Agac Adasi',NULL,408,36.733,27.383,NULL,0,0,NULL,7.0,NULL,NULL,NULL,'amphoras','unfinished whetstones (50)',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,546,NULL),
('Klåstad',NULL,409,59.065,10.167,'ca',960,990,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on dendro on oak plank. Nordic sailed/oared cargo vessel of beech, oak and pine; in Viking context.',21.0,5.0,NULL,NULL,'Navis I, Klåstad, #180; A.E. Christensen and L. Gunnar 1976; A.E. Christensen 1980; Eriksen 1993; J. Bill et al. 1997.'),
('Knidos 4',NULL,410,36.667,27.383,'ca',1200,1400,NULL,32.0,NULL,NULL,NULL,'ceramic','roof tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,551,NULL),
('Komi 2',NULL,411,38.183,26.033,NULL,1,500,NULL,4.0,NULL,NULL,NULL,'glass',NULL,'ceramic','terra cotta pipes','amphoras','Roman amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,553,NULL),
('Kornat',NULL,412,43.733,15.383,NULL,1,100,NULL,NULL,NULL,NULL,NULL,'amphoras','Pulak1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,556,NULL),
('Kotu Burun',NULL,413,36.383,29.100,NULL,1000,1100,NULL,42.0,NULL,NULL,NULL,'amphoras','Dr2-4, pear-shaped','ceramic','large globular jars',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,557,NULL),
('Krava',NULL,414,43.067,16.217,NULL,1,200,NULL,NULL,NULL,NULL,NULL,'amphoras','Koan',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,558,NULL),
('Kvarner Gulf',NULL,415,45.000,14.000,NULL,1,100,NULL,NULL,NULL,NULL,NULL,'coins','Rhodian',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,561,NULL),
('Kythera',NULL,416,36.200,23.050,NULL,-50,110,'ca',15.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,564,NULL),
('L?d',NULL,417,52.200,17.933,NULL,810,1115,NULL,NULL,'in alluvium',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on 2 14C samples dating 900 and 970 with a margin of 90 yrs each. Dendro dating based on 7 samples of planks gave range 891-1115.  Dendro showed also origin around area of Wroclaw.  Vessel is ash and oak, cargo, Slavonic.',10.8,2.4,NULL,NULL,'Navis I, L?d, #140'),
('Ladby, Kerteminde',NULL,418,55.429,10.616,NULL,950,960,NULL,NULL,'silted',NULL,NULL,'amphoras','Dr2-4; Haltern70',NULL,NULL,NULL,NULL,NULL,'anchor and ornamental metal sculputures on the prow.',NULL,'Dating by 14C on caulking and objects found. Military boat is made of oak. Viking context, Nordic type ship.',21.5,2.9,NULL,NULL,'Navis I, Ladby, #193; Sorensen 2001.'),
('Ladispoli 1',NULL,419,41.950,12.050,NULL,1,15,'ca',12.0,NULL,NULL,NULL,'nothing reported','columns','dolia',NULL,'ceramic','Arretine ware','lead jar, volute lamps, furniture, wooden box','bilge-pump',NULL,'well-preserved hull; McCann et al say 25-100?AD',20.0,NULL,NULL,565,NULL),
('Ladispoli 2',NULL,420,41.917,12.100,NULL,25,100,'ca / ?',20.0,NULL,NULL,NULL,'stone','Afr2 pear-shaped globular Kapitän2 Riley MR4',NULL,NULL,NULL,NULL,NULL,'2 lead anchor-stocks',NULL,NULL,NULL,NULL,NULL,566,NULL),
('Lampedusa 1',NULL,421,35.483,12.600,NULL,300,350,'ca / ?',NULL,NULL,NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,567,NULL),
('Lara (Cyprus)',NULL,422,34.964,32.288,NULL,0,0,NULL,NULL,NULL,NULL,NULL,'amphoras','imbrices, tegulae, four round for use in ventilation',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'timbers with nails and lead sheathing',NULL,NULL,NULL,569,NULL),
('Lardier 4',NULL,423,43.150,6.617,NULL,50,75,NULL,22.5,NULL,NULL,NULL,'amphoras',NULL,'ceramic','Vases - rivet 17; Dragendorff 33 and 18','amphoras','gauloise 4','pipettes, casserole, balance, touchstone','iron anchor, stone moorage prototype; 25 lead rings',NULL,NULL,NULL,NULL,NULL,NULL,'A. Joncheray and J.P. Joncheray 2004, 73-117.'),
('Lastovo 1',NULL,424,42.767,16.900,'ca',400,500,NULL,NULL,NULL,NULL,NULL,'amphoras','Roman',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,570,NULL),
('Lastovo 6',NULL,425,42.767,16.900,'ca',1,500,NULL,NULL,NULL,NULL,NULL,'metal','Rhodian',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,575,NULL),
('Lastovska',NULL,426,42.783,18.517,NULL,-50,110,'ca / ?',NULL,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,576,NULL),
('Laurons 1, Les',NULL,427,43.267,5.017,NULL,200,400,'c3 to c4',2.5,NULL,NULL,NULL,'amphoras','Gaulish, African cylindrical',NULL,NULL,NULL,NULL,NULL,'ballast, wooden wedge, needle, spoon, marline-spike, bone marline spike, copper button, pottery plate, jar, pitcher',NULL,'preserved ship, 46 m from shore - Late Roman vessel repaired numerous times',13.0,4.0,'remains',577,NULL),
('Laurons 2, Les',NULL,428,43.267,5.017,NULL,175,200,'ca (end c3/beg c4AD)',2.0,NULL,NULL,NULL,'nothing reported','pottery','ceramic','terra sigillata chiara A, coarseware','coins','2 coins (1 of Divus Antoninus Pius)','wooden utensils, lamp, grain','pump-well, steering oar mountings, steering oar',NULL,'well-preserved ship; follis from end of C3, probably of Diocletian; silver denarius of Marcus Aurelius',15.0,5.0,NULL,578,NULL),
('Laurons 3, Les','Epave III',429,43.267,5.017,NULL,300,400,NULL,2.0,NULL,NULL,NULL,'ceramic','one of Constantine','amphoras','Dr20 and Pelichet47','glass','fragments','coins','ballast stones, wooden arm of anchor with lead reinforcement collar, rigging items',NULL,NULL,10.0,4.6,NULL,579,'P. Pomey and L. Long 1988, 23.'),
('Laurons 4, Les',NULL,430,43.267,5.017,NULL,310,340,'ca / ?',2.0,NULL,NULL,NULL,'marble',NULL,NULL,NULL,NULL,NULL,NULL,'wood and lead anchor',NULL,'well-preserved hull; dating based on coin of Constantine',NULL,NULL,NULL,580,NULL),
('Laurons 5, 6, 9, 10',NULL,431,43.350,5.000,NULL,NULL,NULL,'undated',NULL,NULL,NULL,NULL,'amphoras','Dr14 Dr2-4 Dr28 miniDr14 Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'P. Pomey and L. Long 1988, 23.'),
('Lavezzi (Balise)','Epave de la Balise de Lavezzi',432,41.317,9.250,NULL,45,50,'ca / ?',15.0,NULL,NULL,NULL,'amphoras','Dr20 Dr14 Dr7-11 Haltern70',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,583,NULL),
('Lavezzi 1',NULL,433,41.333,9.250,NULL,25,50,'ca / ?',13.0,NULL,NULL,NULL,'amphoras','Dr7-11 Dr9 Dr20','glass','square and round bottles','metal','copper and lead ingots','coarse pottery',NULL,NULL,'copper nails from hull',NULL,NULL,NULL,584,NULL),
('Lavezzi 2',NULL,434,41.333,9.250,NULL,40,50,'ca',19.0,NULL,NULL,NULL,'marble','Dr14 Dr17 miniDr14 Pascual 1','ceramic','S. Gaulish terra sigillata','metal','small bronze cylinder with antimony, little bronze bell, two glass bowls, lead or tin ingot',NULL,NULL,NULL,'partially-preserved hull',NULL,NULL,NULL,585,NULL),
('Lavezzi 3',NULL,435,41.317,9.250,NULL,50,100,'ca / ?',12.0,NULL,NULL,NULL,'marble','Dr20 Dr14 Beltran2B',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'1-50 AD according to Mayet',NULL,NULL,NULL,586,'F. Mayet 1987, 289.'),
('Lavezzi 4',NULL,436,41.333,9.250,NULL,100,150,'ca / ?',15.0,NULL,NULL,NULL,'amphoras','cylindrical pear-shaped small flat-bottomed',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,587,NULL),
('Lavezzi 5',NULL,437,41.333,9.250,NULL,300,325,'ca',10.0,NULL,NULL,NULL,'amphoras',NULL,'ceramic','3 pottery vaulting tubes, domestic ware',NULL,NULL,NULL,'anchor stock',NULL,NULL,NULL,NULL,NULL,588,NULL),
('Lavezzi 6',NULL,438,41.333,9.233,'ca',1,200,NULL,NULL,'shallow',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,589,NULL),
('Lavezzi 7',NULL,439,41.333,9.233,'ca',1,200,NULL,NULL,'shallow',NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,590,NULL),
('Lavezzi 8',NULL,440,41.333,9.233,'ca',1,200,NULL,NULL,'shallow',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,591,NULL),
('Lavezzi 9',NULL,441,41.333,9.233,'ca',1,200,NULL,NULL,'shallow',NULL,NULL,'amphoras','cylindrical Afr2D Almagro50 Almagro51C Dr20 Dr30',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,592,NULL),
('Lazzaretto',NULL,442,40.583,8.250,NULL,320,320,'ca',2.0,NULL,NULL,NULL,'amphoras','Dr20 (can be included in Pelichet''s 20B), form 5 of Tchernia','coins','moneybag with follis of Licinius','ceramic','mold',NULL,NULL,NULL,'hull timbers',NULL,NULL,NULL,594,NULL),
('Lérins',NULL,443,43.504,7.045,NULL,161,193,NULL,20.0,NULL,NULL,NULL,'tiles','tubi fittili: small and poorly made',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'W of the Tourelle des Moines, S of Saint-Honorat in bay of Cannes; stamps on amphoras show produced between 150-198 and 161-192',NULL,NULL,NULL,NULL,'A. Pollino 1976, 123-129.'),
('Levanzo 1',NULL,444,38.033,12.334,NULL,300,400,'ca',94.0,NULL,NULL,NULL,'coins','Rhodian',NULL,NULL,NULL,NULL,NULL,'table amphoras, table wares',NULL,NULL,NULL,NULL,NULL,NULL,'“Tradition and Transition: Maritime Studies in the Wake of the Shipwreck at Yassiada, Turkey” 2007'),
('Lindos 1',NULL,445,36.083,28.083,'ca',-50,100,'ca / ?',30.0,NULL,NULL,NULL,'coins',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,598,NULL),
('Lindos 3',NULL,446,36.083,28.083,'ca',0,0,NULL,NULL,NULL,NULL,NULL,'ceramic','roof tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,600,NULL),
('Lion de Mer, Le',NULL,447,43.400,6.767,NULL,1,200,NULL,NULL,'shallow',NULL,NULL,'coins','Beltran2B',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,601,NULL),
('Little Russel 1',NULL,448,49.450,-2.533,NULL,75,200,NULL,12.0,NULL,NULL,NULL,'amphoras','cf. Dr7-11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,602,NULL),
('Little Russel 2',NULL,449,49.450,-2.517,'ca',1,75,'ca / ?',50.0,NULL,NULL,NULL,'ceramic','4 Roman portrait busts',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,603,NULL),
('Livorno (Italy)',NULL,450,43.550,10.283,'ca',0,0,NULL,NULL,NULL,NULL,NULL,'ceramic','statues, 2 ionic capitals, 4 half-column bases',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,603,NULL),
('Lixouri',NULL,451,38.200,20.450,NULL,1,500,NULL,4.0,NULL,NULL,NULL,'marble',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'300 m from shore',NULL,NULL,NULL,604,NULL),
('Logonovo',NULL,452,44.650,12.250,NULL,1475,1500,NULL,NULL,'silted',NULL,NULL,'stone','grinding stone',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'two-masted boat',10.1,NULL,NULL,605,NULL),
('London (Blackfriars)',NULL,453,51.500,0.100,NULL,175,225,NULL,NULL,'silted',NULL,NULL,'ceramic','4 coins ending 296','ceramic','pottery','metal','tools',NULL,NULL,NULL,'mast-step, hull',15.0,NULL,NULL,606,'G. Milne 1996, 234-238.'),
('London (County Hall)',NULL,454,51.500,-0.117,NULL,275,300,NULL,NULL,'silted',NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Roman ship',20.0,NULL,NULL,607,NULL),
('London (New Guy''s House)',NULL,455,51.500,-0.083,NULL,200,200,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'carvel-built ship',15.0,NULL,NULL,608,NULL),
('Lone Mushroom',NULL,456,34.131,27.761,NULL,0,0,NULL,17.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,'stone anchor',NULL,'Sherds of pottery are similar to the ones of the Na''ama wreck.  Author does not venture to propose a date.',NULL,NULL,NULL,NULL,'A. Raban 1990, 299-306'),
('Lough Lene',NULL,457,53.665,7.237,'ca',-100,100,NULL,5.0,NULL,NULL,NULL,'amphoras','roof tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating of  oak tenon produces a date which according to author may result in early 1st C AD.   Fishing vessel, Mediterranean tradition construction.  Found on lake bed, no depth specified on db, but is 4-5m from IJNA article (1991).',8.0,1.5,NULL,NULL,'Navis I, Lough Lene, #25; R.T. Farell 1989, 223-228; A.L. Lanting and J.N. Brindley 1991, 69-70; O hEailidhe 1992, 185-190.'),
('Luque 1, La',NULL,458,43.267,5.283,NULL,150,150,'ca / ?',17.0,NULL,NULL,NULL,'amphoras','Afr ,Globe','ceramic','S Gaulish Drag. 37 bowl, coarseware','coins','coins in mast-step end with Hadrian','sword',NULL,NULL,'preserved ship',NULL,NULL,NULL,610,NULL),
('Luque 2, La',NULL,459,43.267,5.283,NULL,300,325,'ca',40.0,NULL,NULL,NULL,'amphoras','lead ingots (5)','lamps','Afr','ceramic','terra sigillata bowl',NULL,NULL,NULL,'preserved hull, mast-step',20.0,6.0,NULL,611,NULL),
('Ma''Agan Michael',NULL,460,32.556,34.914,NULL,1,100,'ca',5.0,NULL,NULL,NULL,'ceramic','Dr14, pear-shaped; flat-bottomed amphora','metal','sounding lead, 2',NULL,NULL,NULL,NULL,NULL,'Dating based on shape of ingots (compared to other finds in the Mediterranean, and inscriptions in Greek and Latin engraved on them, possibly indicating  workshop origin.',NULL,NULL,NULL,NULL,'S. Kingsley and K. Raveh 1994, 119-128.'),
('Macchia Tonda, La',NULL,461,41.983,11.950,'ca',50,100,'ca / ?',12.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,'lead anchor stock',NULL,NULL,NULL,NULL,NULL,613,NULL),
('Maddalena',NULL,462,41.250,9.417,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'amphoras','Dr8 Dr12 Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,614,NULL),
('Magnons 1, La',NULL,463,43.067,5.750,NULL,-50,50,'ca',30.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,619,NULL),
('Magor Pill 2',NULL,464,51.550,2.817,'ca',1240,1240,NULL,NULL,'silted',NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Survey find. Dating based on oak dendrodata. Information here provided by a review of nautical archaeology work in UK in 1996.',17.0,NULL,NULL,NULL,'N. Nayling 1998; L. Blue 1997, 253-255; A.J. Parker 1999, 323-342.'),
('Mainz 10',NULL,465,50.000,8.267,NULL,75,125,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'large barge',NULL,NULL,NULL,630,NULL),
('Mainz 2',NULL,466,50.000,8.267,NULL,400,425,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'single-banked galley, wood felled 376, repaired 385 and 394',8.3,NULL,NULL,623,'O. Höckmann 1993, 125-135; P. Marsden 1993, 137-141.'),
('Mainz 3',NULL,467,50.000,8.267,NULL,400,425,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'ship with cabin',14.8,NULL,NULL,624,NULL),
('Mainz 4',NULL,468,50.000,8.267,NULL,400,425,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'single-banked galley',NULL,NULL,NULL,625,NULL),
('Mainz 5',NULL,469,50.000,8.267,NULL,400,425,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'single-banked galley',10.6,NULL,NULL,626,NULL),
('Mainz 6',NULL,470,50.000,8.267,NULL,400,425,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'single-banked galley',21.0,NULL,NULL,627,NULL),
('Mainz 7',NULL,471,50.000,8.267,NULL,400,425,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dugout',NULL,NULL,NULL,628,NULL),
('Mainz 8',NULL,472,50.000,8.267,NULL,75,125,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'large barge, dendro: 81 AD',11.0,NULL,NULL,629,NULL),
('Mainz 9',NULL,473,50.000,8.267,NULL,400,425,NULL,NULL,NULL,NULL,NULL,'ceramic','Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Not in Parker 1992, received some attention in 1993.  Considered a type A lusoria ship.',21.0,2.5,'ca',NULL,'O. Höckmann 1993, 125-135; P. Marsden 1993, 137-141.'),
('Maire 2',NULL,474,43.200,5.317,NULL,100,125,NULL,40.0,NULL,NULL,NULL,'amphoras','Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,632,NULL),
('Majorca',NULL,475,39.833,3.667,NULL,100,200,NULL,NULL,NULL,NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,635,NULL),
('Majsan (Croatia)',NULL,476,42.960,17.199,NULL,0,0,NULL,NULL,'shallow',NULL,NULL,'amphoras','glazed bowls',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,635,NULL),
('Mala Jana',NULL,477,43.050,14.450,NULL,1300,1600,NULL,27.0,NULL,NULL,NULL,'amphoras','blocks',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,638,NULL),
('Malamocco',NULL,478,45.417,12.383,'ca',1400,1500,NULL,9.0,NULL,NULL,NULL,'nothing reported',NULL,'metal','falchions, swords, Turkish standard, bronze statuette',NULL,NULL,NULL,'ballast, iron breech-loading cannon, 3 large anchors',NULL,NULL,NULL,NULL,NULL,639,NULL),
('Malta',NULL,479,35.900,14.750,'ca',0,0,NULL,NULL,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,640,NULL),
('Mandalya Gulf 1',NULL,480,37.167,27.417,'ca',-50,50,'ca / ?',NULL,'shallow',NULL,NULL,'amphoras','pear-shaped Byzantine',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,642,NULL),
('Mandalya Gulf 3',NULL,481,37.167,27.417,'ca',900,1000,NULL,37.0,NULL,NULL,NULL,'amphoras','20,000 folles dated 306-312 in an amphora',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,644,NULL),
('Mangub',NULL,482,32.833,12.250,NULL,315,315,'ca',NULL,NULL,NULL,NULL,'amphoras','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,645,NULL),
('Maratea 1',NULL,483,39.917,15.767,NULL,50,50,'ca / ?',NULL,'shallow',NULL,NULL,'tiles','Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,647,NULL),
('Maratea 2',NULL,484,39.950,15.733,NULL,25,260,'ca / ?',NULL,'shallow',NULL,NULL,'amphoras','Almagro50; large-necked amphora or storage jar',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,648,NULL),
('Maratea 3',NULL,485,39.950,15.733,'ca',200,400,NULL,NULL,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,649,NULL),
('Maresquel',NULL,486,50.000,1.000,NULL,100,200,NULL,NULL,NULL,NULL,NULL,'nothing reported','blocks, columns',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'line of posts, boat',NULL,NULL,NULL,651,NULL),
('Margarina',NULL,487,44.483,14.300,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'amphoras','Byzantine  plates',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,653,NULL),
('Marmaris 1',NULL,488,36.867,28.283,'ca',700,900,NULL,NULL,NULL,NULL,NULL,'tiles','Dr2-4 cf Dr7-11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,657,NULL),
('Marritza',NULL,489,40.850,8.600,NULL,75,125,'ca',4.0,NULL,NULL,NULL,'amphoras','Riley LR8a','ceramic','terra sigillata chiara A, black-walled ware saucepan and coarseware',NULL,NULL,NULL,'4 iron anchors',NULL,'lead sheathing, large pulley, wooden beam of mast, roof tiles',NULL,NULL,NULL,659,NULL),
('Marsa Lucch',NULL,490,32.083,24.500,NULL,500,650,'ca / ?',NULL,NULL,NULL,NULL,'metal','small',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,6.0,2.0,'remains',660,NULL),
('Marsala 1',NULL,491,37.767,12.433,NULL,1150,1200,'ca',2.0,NULL,NULL,NULL,'amphoras','bronze pot with Arabic inscription','ceramic','lava mill, jug',NULL,NULL,NULL,'ballast',NULL,'well-preserved Arab ship, 40 m from beach',15.0,3.0,NULL,663,NULL),
('Marsala 2',NULL,492,37.767,12.433,NULL,1150,1200,'ca / ?',NULL,NULL,NULL,NULL,'amphoras',NULL,'ceramic','pottery',NULL,NULL,NULL,NULL,NULL,'Arabic tender or pinnace',NULL,NULL,NULL,664,NULL),
('Marsala 3',NULL,493,37.883,12.433,NULL,500,1500,NULL,NULL,NULL,NULL,NULL,'ceramic','Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'hull',NULL,NULL,NULL,665,NULL),
('Marseillan-Plage 2',NULL,494,43.300,3.550,NULL,50,100,'ca / ?',NULL,NULL,NULL,NULL,'tiles',NULL,'metal','lead and copper ingots',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,667,NULL),
('Marseille (Bourse)','L''Epave de la Bourse or du Lacydon',495,43.283,5.367,NULL,175,200,NULL,NULL,'silted',NULL,NULL,'amphoras','pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'well-preserved Roman ship',23.0,9.0,NULL,668,NULL),
('Marseille (Galère de César)',NULL,496,43.283,5.367,NULL,200,300,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'hull',NULL,NULL,NULL,669,NULL),
('Marseille 5',NULL,497,43.300,5.400,NULL,1,200,'ca',NULL,'silted',NULL,NULL,'dolia',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Found in place Jules Verne 4. Roman context.',16.0,5.0,NULL,NULL,'Navis I, Marseille 5, #47; P. Pomey 1995, 459-484.'),
('Marseille 6',NULL,498,43.300,5.400,NULL,1,200,'ca',NULL,'silted',NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Found in place Jules Verne 4.  Roman context',16.0,5.0,NULL,NULL,'Navis I, Marseille 6, #48; P. Pomey 1995, 459-484.'),
('Marseille 7',NULL,499,43.300,5.400,NULL,200,300,'ca',NULL,'silted',NULL,NULL,'amphoras','rough and worked, with evidence of chisels and inscriptions from quarry inspections, with consular date, sector of quarry and name of imperial curator; white marble columns',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Found in place Jules Verne 4.  Roman context',NULL,NULL,NULL,NULL,'Navis I, Marseille 7, #49; P. Pomey 1995, 459-484.'),
('Marseille 8',NULL,500,43.304,5.355,'ca',1,100,'ca',4.0,NULL,NULL,NULL,'amphoras','Kapitän1 and 2','amphoras','3 oil and 1 wine type Dressel20,  Dressel1A, and Dressel 2/4 from Catalonia and Gaul','glass',NULL,NULL,NULL,NULL,'amphora (under hull, type Dressel 1A) is terminus post quem. No precise petrological analysis for whole cargo available yet, but the most valuable colored marble is from Eastern quarries.',NULL,NULL,NULL,NULL,'H. Bernard 2000, 114-125.'),
('Marzamemi 1',NULL,501,36.733,15.133,NULL,200,250,'ca',7.0,NULL,NULL,NULL,'amphoras','Byzantine','marble','greyish-white blocks',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,670,NULL),
('Marzamemi 10',NULL,502,36.750,15.133,NULL,400,700,NULL,8.0,NULL,NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,678,NULL),
('Marzamemi 11',NULL,503,36.733,15.150,NULL,400,700,NULL,28.0,NULL,NULL,NULL,'amphoras','carved architectural pieces for basilica, verde antico and white Proconnesian',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,679,NULL),
('Marzamemi 2','Church Wreck of Marzamemi',504,36.750,15.133,NULL,500,540,'ca',10.0,NULL,NULL,NULL,'ceramic','red Nubian granite column','amphoras',NULL,'ceramic','terra sigillata chiara dish',NULL,NULL,NULL,NULL,NULL,NULL,NULL,671,NULL),
('Marzamemi 3',NULL,505,36.733,15.133,NULL,1,500,NULL,NULL,'shallow',NULL,NULL,'amphoras','Afr2D cylindrical',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,672,NULL),
('Marzamemi 4',NULL,506,36.750,15.133,NULL,325,350,'ca / ?',7.0,NULL,NULL,NULL,'amphoras','Almagro50 Almagro51C Afr2B-D',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,673,NULL),
('Marzamemi 6',NULL,507,36.733,15.133,NULL,275,300,'ca / ?',7.0,NULL,NULL,NULL,'metal','Schoene8',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,675,NULL),
('Matala',NULL,508,34.983,24.750,NULL,-50,110,'ca / ?',8.0,NULL,NULL,NULL,'amphoras','S. Gaulish terra sigillata bowl',NULL,NULL,NULL,NULL,NULL,'ballast',NULL,NULL,NULL,NULL,NULL,681,NULL),
('Mataró-Els Capets (Spain)',NULL,509,41.534,2.463,'ca',75,125,NULL,70.0,NULL,NULL,NULL,'amphoras','Almagro51A, pear-shaped, cylindrical',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,681,NULL),
('Mateille 1',NULL,510,43.117,3.117,NULL,400,425,'ca',3.0,NULL,NULL,NULL,'amphoras','Dr7-11','metal','iron bars, bronze objects','coins','551 coins, 4 of Theodosius','terra sigillata chiara D, coarseware, vaulting tube, iron blade, axe,  fishing weights','anchor shank, ballast, 551 coins, 4 of Theodosius, ts chiara D, coarseware, vaulting tube, iron blade, axe,  fishing weights',NULL,NULL,NULL,NULL,NULL,682,NULL),
('Mateille 2',NULL,511,43.117,3.117,NULL,1,100,NULL,4.0,NULL,NULL,NULL,'amphoras','Pascual1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'fragments of ship preserved',NULL,NULL,NULL,683,NULL),
('Medas 2',NULL,512,42.033,3.217,NULL,-50,25,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','roof tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,685,NULL),
('Medes 2, Les',NULL,513,43.017,6.233,NULL,1,100,NULL,18.0,NULL,NULL,NULL,'ceramic','gold coins','amphoras','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,687,NULL),
('Mediterranean',NULL,514,38.942,4.897,'ca',308,308,NULL,NULL,NULL,NULL,NULL,'amphoras','several hundred thousand, Mamluk of Sultan Nasser Farage (1399-1412)',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'No precise location info provided. W Mediterranean hypothesized',NULL,NULL,NULL,688,NULL),
('Megadim 2',NULL,515,32.717,34.933,NULL,1404,1404,NULL,NULL,'shallow',NULL,NULL,'amphoras',NULL,'metal','bronze torches, copper lamps, inscribed bronze plaques, copper dishes, mortars and pestles, hinges of wooden chests',NULL,NULL,NULL,'ballast',NULL,'ship''s hull',NULL,NULL,NULL,690,NULL),
('Meloria 3/C',NULL,516,43.551,10.223,NULL,NULL,NULL,'imperial (?)',NULL,NULL,NULL,NULL,'amphoras','mortaria',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'S. Bargagliotti 2002, 227-242; A.M. McCann and J.P. Oleson 2004, 92.'),
('Mellieha',NULL,517,35.967,14.367,NULL,200,250,'ca',9.0,NULL,NULL,NULL,'ceramic','4,000 bronze coins, mostly of Constantine II (346-361)','glass','vessels','amphoras','Kapitän1','additional cargo: glass cakes, blue frit, textile fragments, tin-alloy measures; stores: domestic pottery, 2 bronze vessels','ballast',NULL,'roof-tiles',NULL,NULL,NULL,691,NULL),
('Meloria (Italy)',NULL,518,43.533,10.217,NULL,0,0,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Not a wreck?',NULL,NULL,NULL,691,NULL),
('Mercury wreck',NULL,519,34.325,27.866,NULL,1350,1450,NULL,20.0,NULL,NULL,NULL,'amphoras','Roman coarseware',NULL,NULL,NULL,NULL,NULL,'2 metal anchors at 23m depth, metal and pottery utensils',NULL,'Dating based on 14C on planks and ceramic evidence. Utensils found at 28 m depth, deeper than rest of wreck. Anchors present engraved Arabic inscriptions.',NULL,NULL,NULL,NULL,'A. Raban 1990, 299-306.'),
('Mersea',NULL,520,51.800,1.033,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'amphoras','Medieval Jars',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,692,NULL),
('Methone 2',NULL,521,36.817,21.700,NULL,500,1500,NULL,30.0,NULL,NULL,NULL,'ceramic','granite columns',NULL,NULL,NULL,NULL,NULL,'ballast',NULL,NULL,NULL,NULL,NULL,694,NULL),
('Methone 3',NULL,522,36.817,21.700,NULL,200,250,'ca',10.0,NULL,NULL,NULL,'ceramic','garland sarcophagi','amphoras','Kapitän2','glass','fragment',NULL,NULL,NULL,NULL,30.0,20.0,'remains',695,NULL),
('Methone 4',NULL,523,36.817,21.700,NULL,100,300,NULL,NULL,'shallow',NULL,NULL,'ceramic','R/Byz jars','tiles','roof tiles','ceramic','pottery','glass unguent jar','ballast',NULL,NULL,NULL,NULL,NULL,696,NULL),
('Mikhmoret',NULL,524,32.400,34.867,NULL,1,1500,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,697,NULL),
('Miladou, Le',NULL,525,43.000,6.383,NULL,-200,-50,NULL,NULL,NULL,NULL,NULL,'amphoras','LR',NULL,NULL,NULL,NULL,NULL,'pump tubing',NULL,'Miladou dated end C2 or first half of C1 BC, detailed analysis Dumontier and Joncheray 1991; ?dating based on coin of Constantine',NULL,NULL,NULL,698,NULL),
('Milazzo',NULL,526,38.267,15.217,NULL,350,375,'ca / ?',NULL,NULL,NULL,NULL,'ceramic','Dr2-4, pear-shaped',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,699,NULL),
('Mlin',NULL,527,43.450,16.233,NULL,1,200,NULL,NULL,NULL,NULL,NULL,'amphoras','CP and Black Sea parallels',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,702,NULL),
('Mljet 1',NULL,528,42.717,17.683,NULL,850,1000,'ca',25.0,NULL,NULL,NULL,'metal','Dr21/22','glass','bowls and cups, flasks and goblets',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,703,NULL),
('Mljet 2',NULL,529,42.800,17.350,'ca',1,200,NULL,NULL,NULL,NULL,NULL,'amphoras','Lam2','ceramic','coarse pottery, red plates and platters',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,704,NULL),
('Moines, Les (France)',NULL,530,41.467,8.917,NULL,0,0,NULL,18.0,NULL,NULL,NULL,'amphoras','water pipes','metal','one ingot',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,704,NULL),
('Mola',NULL,531,42.750,10.400,NULL,-100,100,NULL,20.0,NULL,NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,705,NULL),
('Molara',NULL,532,40.850,9.733,NULL,-200,100,NULL,NULL,NULL,NULL,NULL,'amphoras','Lam2/Dr6',NULL,NULL,NULL,NULL,NULL,'lead anchor stock',NULL,NULL,NULL,NULL,NULL,706,NULL),
('Molat',NULL,533,44.200,14.850,'ca',-100,100,NULL,NULL,NULL,NULL,NULL,'amphoras','pear-shaped Afr.2A: mainly produced, probably, at Salakta: M. Bonifay, Études sur la céramique romaine tardive d''Afrique, BAR international series 1301 (Oxford, 2004), 454.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,707,NULL),
('Monaco 1',NULL,534,43.733,7.417,NULL,200,250,'ca / ?',3.0,NULL,NULL,NULL,'stone',NULL,'ceramic','coarseware, terra sigillata chiara HayesRS27,  later pottery','coins','Marcus Aurelius','inscribed wooden stamp',NULL,NULL,'keel',15.0,4.0,NULL,708,NULL),
('Monate, Lago di',NULL,535,44.000,8.000,NULL,0,0,NULL,NULL,NULL,NULL,NULL,'amphoras','jug, plates',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dugout, 14C: 130+/-50',NULL,NULL,NULL,712,NULL),
('Monfalcone',NULL,536,45.817,13.533,NULL,1,100,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,'wooden container, wicker basket',NULL,NULL,'Roman boat',11.0,3.8,NULL,713,NULL),
('Montecristo 2',NULL,537,42.333,10.283,NULL,1400,1500,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,716,NULL),
('Montecristo 3',NULL,538,42.333,10.283,NULL,1,500,NULL,75.0,NULL,NULL,NULL,'amphoras','pear-shaped',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,717,NULL)

INSERT INTO @tbl_Load (PrimaryName, SecondaryName, WreckID2008, Latitude, Longitude, GeoQ, StartDate, EndDate, DateQ, Depth, DepthQ, YearFound, YearFoundQ, Cargo1, Type1, Cargo2, Type2, Cargo3, Type3, OtherCargo, Gear, EstimatedCapacity, Comments, Lngth, Width, SizeestimateQ, Parkerreference, Bibliographyandnotes)
VALUES
('Montecristo 6',NULL,539,42.350,10.283,NULL,50,250,'ca / ?',55.0,NULL,NULL,NULL,'amphoras','cylindrical Afr','ceramic','jug','metal','bronze nails',NULL,NULL,NULL,NULL,NULL,NULL,NULL,720,'M. Bound 1992, 329-336.'),
('Morovnik',NULL,540,44.417,14.733,NULL,300,425,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Camulodunum186 Dr7-11 Haltern70 Dr1C',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,721,NULL),
('Mortorius, Is',NULL,541,39.183,9.317,NULL,30,55,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Spanish-Roman',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,722,NULL),
('Munxar',NULL,542,35.833,14.567,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,723,NULL),
('Na''ama',NULL,543,34.327,27.887,NULL,1100,1400,NULL,11.0,NULL,NULL,NULL,'amphoras','Afr1',NULL,NULL,NULL,NULL,NULL,'stone anchors, 2, one half the weight of the other.',NULL,'Dating based on 14C and anchor type.  Few remnants of the hull left.',NULL,NULL,NULL,NULL,'A. Raban 1990, 299-306.'),
('Napoli',NULL,544,40.500,14.250,NULL,200,250,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Afr',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,726,NULL),
('Naregno',NULL,545,42.750,10.400,NULL,200,400,NULL,7.0,NULL,NULL,NULL,'ceramic','pithoi',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,727,NULL),
('Navplion 2',NULL,546,37.567,22.800,NULL,1200,1500,NULL,NULL,NULL,NULL,NULL,'metal','Beltran2B Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,730,NULL),
('Negres, Les',NULL,547,41.967,3.233,NULL,150,150,'ca',25.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,731,NULL),
('Nemi 1',NULL,548,41.717,12.717,NULL,35,50,'ca',12.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,'pumps',NULL,'pleasure galley',NULL,NULL,NULL,732,NULL),
('Nemi 2',NULL,549,41.717,12.717,NULL,35,50,'ca',21.0,NULL,NULL,NULL,'tiles',NULL,NULL,NULL,NULL,NULL,NULL,'pumps',NULL,'pleasure galley',NULL,NULL,NULL,733,NULL),
('Nemi 3',NULL,550,41.717,12.717,NULL,35,50,'ca',NULL,NULL,NULL,NULL,'metal',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'barge',5.0,NULL,NULL,734,NULL),
('Nemi 4',NULL,551,41.717,12.717,NULL,35,50,'ca',0.0,NULL,NULL,NULL,'ceramic','Roman pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'boat',9.0,NULL,NULL,735,NULL),
('Nerezine',NULL,552,44.650,14.400,NULL,100,200,NULL,NULL,NULL,NULL,NULL,'tiles','globular',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,736,NULL),
('Neseber 2',NULL,553,42.650,27.733,NULL,500,625,'ca / ?',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,738,NULL),
('Newe Yam 2',NULL,554,32.683,34.933,NULL,300,1500,NULL,NULL,NULL,NULL,NULL,'tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,740,NULL),
('Nin 1',NULL,555,44.250,15.183,NULL,1050,1100,'ca',NULL,'shallow',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'well-preserved, 14C dating',9.0,NULL,NULL,744,NULL),
('Nin 2',NULL,556,44.250,15.183,NULL,1050,1100,'ca',NULL,'shallow',NULL,NULL,'amphoras','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'mast-step, ribs, rowlock, 14C dating',NULL,NULL,NULL,745,NULL),
('Niolon',NULL,557,43.333,5.250,NULL,1,100,NULL,10.0,NULL,NULL,NULL,'ceramic','Dr2-4','glass','vessels','metal','brail rings',NULL,'sounding lead',NULL,NULL,NULL,NULL,NULL,746,NULL),
('Noce, Fiume',NULL,558,39.917,15.750,NULL,-50,100,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Almagro50',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,747,NULL),
('Nora',NULL,559,38.967,9.017,'ca',300,400,NULL,NULL,NULL,NULL,NULL,'amphoras','roof tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,748,NULL),
('Nord-Camarat',NULL,560,43.200,6.667,NULL,1,100,NULL,25.0,NULL,NULL,NULL,'tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,749,NULL),
('Nord-Fouras',NULL,561,43.183,6.683,NULL,900,1000,NULL,NULL,NULL,NULL,NULL,'nothing reported','Dr1 Dr2-4 Afr2B-D Almagro51A Dr20 Dr23',NULL,NULL,NULL,NULL,NULL,'only millstones and nails preserved',NULL,NULL,NULL,NULL,NULL,NULL,'S. Kingsley 2009, 31-36.'),
('Nueva Tabarca (Spain)',NULL,562,38.172,-0.482,'ca',0,0,NULL,3.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'extensive field of amphoras',NULL,NULL,NULL,750,NULL),
('Nydam',NULL,563,54.967,9.733,NULL,237,293,NULL,NULL,'in alluvium',NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,'anchor, oars, prow sculptures of men with long beards',NULL,'Dating by several dendro samples on oak planks.  Environment is a peat bog.  2 other ships found with it but not cataloged by Navis I.  The description by Otto Uldum says that it has been dated by dendro to 310-320; this conflicts with the Navis I database recorded dates. Nordic type, sail/oar.',23.7,3.8,NULL,NULL,'Navis I, Nydam, #7; Englehardt 1865; A.L. Arenhold 1914, 182-185; H.P. Hanssen 1925, 110-112; H. Shetelig 1930, 1-30;  H. Åkerlund 1963; H. Åkerlund 1965, 255-258; W.Sailsbury 1965, 278-280; W. Sailsbury 1965, 359-361; M. Orsnes 1970; D. Ellmers 1988, 155-165; Bonde 1990, 157-168; W. Dammann 1990, 71; N. Bonde and C. Christensen 1991; A. Croome 1993, 178-179; O. Crumlin-Pedersen and F. Rieck 1993;  C. Rieck 1994, 45-54; F. Rieck 1994; M. Gothche 2007, 18-20.'),
('Oberstimm 1',NULL,564,48.750,11.517,NULL,100,125,NULL,NULL,'silted',NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Roman river ship, dendro: 90 +/-10',NULL,3.0,NULL,751,NULL),
('Oberstimm 2',NULL,565,48.750,11.517,NULL,100,125,NULL,NULL,'silted',NULL,NULL,'nothing reported','Afr2A',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Roman river ship, dendro: 102 +/-10',NULL,2.8,NULL,752,NULL),
('Oekhesac',NULL,566,42.800,17.667,NULL,200,400,NULL,NULL,NULL,NULL,NULL,'amphoras','roof tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,797,NULL),
('Ognina (Catania) 2',NULL,567,37.517,15.117,NULL,0,0,NULL,NULL,NULL,NULL,NULL,'amphoras','Afr1 Dr20 Beltran2B pear-shaped Kapitän1 Kapitän2 Almagro 50',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,754,NULL),
('Ognina 1',NULL,568,36.967,15.267,NULL,215,230,'ca',8.0,NULL,NULL,NULL,'amphoras',NULL,'metal','bronze statuettes','glass','glass vessels','coins dating 210-215','lead tubing, 4 bronze pulley wheels',NULL,'mosaic floor, columns with capitals flanking doorway',NULL,NULL,NULL,755,'F. Mayet 1987, 289'),
('Olbia 1',NULL,569,40.917,9.500,NULL,0,0,NULL,NULL,'silted',NULL,NULL,'amphoras','bronze broken statue scrap in 1 ship? http://www.sardiniapoint.it/4125.html',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'survey find. No dating info provided, except claim that mast found is late Roman and so large that ship would have been 30m in length.  Also mentions in passing that 9+ medieval ships were found in the area but neglected in favor of the single mast.',12.1,7.8,NULL,NULL,'E. Riccardi 2002, 268-269.'),
('Olbia R0',NULL,570,40.917,9.500,NULL,400,500,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'C5 ships all with prow facing land, probably between wooden docks, very wide mortices. Fairly frequent caulking.',NULL,NULL,NULL,NULL,'R. D’Oriano and E. Riccardi 2004, 89-95.'),
('Olbia R1',NULL,571,40.917,9.500,NULL,400,500,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,15.0,NULL,NULL,NULL,'R. D’Oriano and E. Riccardi 2004, 89-95.'),
('Olbia R1 Sud',NULL,572,40.917,9.500,NULL,400,500,NULL,NULL,'silted',NULL,NULL,'lamps',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'R. D’Oriano and E. Riccardi 2004, 89-95.'),
('Olbia R12',NULL,573,40.917,9.500,NULL,400,500,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'R. D’Oriano and E. Riccardi 2004, 89-95.'),
('Olbia R13',NULL,574,40.917,9.500,NULL,400,500,NULL,NULL,'silted',NULL,NULL,'dolia',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,30.0,NULL,'ca - length can be less than 30',NULL,'R. D’Oriano and E. Riccardi 2004, 89-95.'),
('Olbia R14',NULL,575,40.917,9.500,NULL,400,500,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'R. D’Oriano and E. Riccardi 2004, 89-95.'),
('Olbia R15',NULL,576,40.917,9.500,NULL,400,500,NULL,NULL,'silted',NULL,NULL,'marble',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'R2 R6 R15 poss from same yard',NULL,NULL,NULL,NULL,'R. D’Oriano and E. Riccardi 2004, 89-95.'),
('Olbia R2',NULL,577,40.917,9.500,NULL,400,500,NULL,NULL,'silted',NULL,NULL,'dolia',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'R2 R6 R15 poss from same yard',NULL,NULL,NULL,NULL,'R. D’Oriano and E. Riccardi 2004, 89-95.'),
('Olbia R2 Sud',NULL,578,40.917,9.500,NULL,400,500,NULL,NULL,'silted',NULL,NULL,'metal',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'R. D’Oriano and E. Riccardi 2004, 89-95.'),
('Olbia R3',NULL,579,40.917,9.500,NULL,400,500,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'R. D’Oriano and E. Riccardi 2004, 89-95.'),
('Olbia R3 Sud',NULL,580,40.917,9.500,NULL,400,500,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'R. D’Oriano and E. Riccardi 2004, 89-95.'),
('Olbia R5',NULL,581,40.917,9.500,NULL,1000,1400,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'scuttled to make bank, keel-less, local transport (inner gulf), dates ranged from 1000-1400',NULL,NULL,NULL,NULL,'E. Riccardi 2002, 1263, 1271-73; R. D’Oriano and E. Riccardi 2004, 89-95.'),
('Olbia R6',NULL,582,40.917,9.500,NULL,400,500,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'R2 R6 R15 poss from same yard',NULL,NULL,NULL,NULL,'R. D’Oriano and E. Riccardi 2004, 89-95.'),
('Olbia R7',NULL,583,40.917,9.500,NULL,400,500,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'R. D’Oriano and E. Riccardi 2004, 89-95.'),
('Olbia R8',NULL,584,40.917,9.500,NULL,1000,1400,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'scuttled to make bank, keel-less, local transport (inner gulf), dates ranged from 1000-1400',12.0,2.5,NULL,NULL,'E. Riccardi 2002, 1263, 1271-73; R. D’Oriano and E. Riccardi 2004, 89-95.'),
('Olbia R9',NULL,585,40.917,9.500,NULL,1000,1400,NULL,NULL,'silted',NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'scuttled to make bank, keel-less, local transport (inner gulf), dates ranged from 1000-1400',NULL,NULL,NULL,NULL,'E. Riccardi 2002, 1263, 1271-73; R. D’Oriano and E. Riccardi 2004, 89-95.'),
('Olbia RT',NULL,586,40.917,9.500,NULL,400,500,NULL,NULL,'silted',NULL,NULL,'ceramic','Afr',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'tender',4.0,NULL,NULL,NULL,'R. D’Oriano and E. Riccardi 2004, 89-95.'),
('Olib 1',NULL,587,44.333,14.800,'ca',300,425,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Beltran2A',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,760,NULL),
('Olib 2',NULL,588,44.333,14.800,NULL,25,125,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','mortaria',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,761,NULL),
('Ooze Deep',NULL,589,51.483,1.000,NULL,65,105,'ca',NULL,NULL,NULL,NULL,'amphoras','roof tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,763,NULL),
('Opat',NULL,590,43.733,15.467,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'amphoras','late Roman, african',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,764,NULL),
('Orlamonde 1','17',591,43.000,40.000,'7',300,500,'late Rome',92.5,'75-110',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'between port of Nice and Villefranche',NULL,NULL,NULL,NULL,'P. Pomey and L. Long 1988, 53.'),
('Orunia 1',NULL,592,52.200,17.900,NULL,1100,1200,'ca',NULL,'in alluvium',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'No dating info provided. Military vessel, oared, oak pine, Slavonic. Similarity of measurements with Lad boat are suspect.',12.8,2.4,NULL,NULL,'Navis I, Orunia 1, #130; O. Lienau 1934.'),
('Orunia 2',NULL,593,52.200,17.900,NULL,1100,1200,'ca',NULL,'in alluvium',NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'No dating info provided. Cargo vessel, oared/sailed, oak, pine, Slavonic.',11.0,2.3,NULL,NULL,'Navis I, Orunia 2, #132; O. Lienau 1934; P. Smolarek 1972.'),
('Orunia 3',NULL,594,52.200,17.900,NULL,1100,1200,'ca',NULL,'in alluvium',NULL,NULL,'amphoras','Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'No dating info provided in database. Cargo vessel, oared, oak, pine, Slavonic.',13.3,2.5,NULL,NULL,'Navis I, Orunia 3, #133; O. Lienau 1934; P. Smolarek 1972.'),
('Oscellucia',NULL,595,42.567,8.717,NULL,20,50,'ca',17.0,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,766,NULL),
('Oseberg',NULL,596,59.300,10.400,'ca',820,834,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on dendro on plank and gravechamber.  Used as boat burial.  Military Nordic vessel in Viking context.',21.4,5.1,NULL,NULL,'Navis I, Oseberg, #181; A.W.Brøgger, H. Shetelig, and H. Falk 1917; A.W. Brøgger and H. Shetelig 1951; A.E. Christensen, A.S. Ingstad, and B. Myhre 1992; N. Bonde and A.E. Christensen 1993, 575-583; N. Bonde 1994; J. Bill et al. 1997.'),
('Ostia',NULL,597,41.667,12.083,'ca',-50,50,'ca / ?',240.0,NULL,NULL,NULL,'amphoras','painted dish',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,767,NULL),
('Ostuni',NULL,598,40.783,17.583,'ca',1100,1300,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,768,NULL),
('Ovrat',NULL,599,42.783,17.400,NULL,1,100,NULL,NULL,NULL,NULL,NULL,'amphoras','Afr2A',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,770,NULL),
('Pag',NULL,600,44.500,15.000,NULL,200,300,NULL,NULL,NULL,NULL,NULL,'metal','cylindrical',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,771,NULL),
('Pag Area',NULL,601,44.000,14.000,NULL,275,300,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','coarse pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,772,NULL),
('Pakleni',NULL,602,43.150,16.383,NULL,100,200,NULL,44.0,NULL,NULL,NULL,'amphoras','Beltran2A Haltern70 Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'timbers, nails',NULL,NULL,NULL,773,NULL),
('Palagruza 2',NULL,603,42.383,16.250,NULL,75,100,NULL,NULL,NULL,NULL,NULL,'stone','bricks','ceramic','pottery','ceramic','mortaria',NULL,NULL,NULL,NULL,NULL,15.0,'remains',775,NULL),
('Palazzolo di Strella',NULL,604,45.800,13.067,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'central part of large Roman boat',NULL,NULL,NULL,777,NULL),
('Palese',NULL,605,41.150,16.767,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'stone',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,778,NULL),
('Palinuro',NULL,606,40.033,15.267,'ca',1,500,NULL,50.0,NULL,NULL,NULL,'amphoras','sulphur lead ingots',NULL,NULL,NULL,NULL,NULL,'2 lead anchor stocks',NULL,'remains of hull',NULL,NULL,NULL,779,NULL),
('Palizi Marina',NULL,607,38.867,8.850,'ca',1,500,NULL,NULL,NULL,NULL,NULL,'amphoras','Keay62 Keay 55; 2 LR 1, 3fgmts LR 2, 1 LR 4,  1 LR 5',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,780,NULL),
('Palud, La',NULL,608,43.000,6.383,'ca',540,600,NULL,5.0,NULL,NULL,NULL,'metal','cylindrical pear-shaped Almagro50 and 51C; Dr23; Beltrán 72; main cargo= Keay 25.1 and Africana 2C. This combination + petrography show they were made in workshop of Sidi Aoun at Nabeul (Neapolis): M. Bonifay, Études sur la céramique romaine tardive d''Afrique, BAR international series 1301 (Oxford, 2004), 453.','tiles','roof tiles as well','ceramic','coarseware',NULL,NULL,NULL,'frame of hull. Parker spells it La Palu, Long and Volpe identify it as La Palud on isle of Port-Cros. Dated 550-600 according to to Kingsley 2002, 79, citing Long and Volpe 1998, 338-9. Correct ref = 1998, p 339, & they propose ca. 540-560 or ca. 550-600. >90% identified amphora parts are African; 180 identifiable sherds; few eastern amphoras. Total cargo = 150-200 amphoras, each ca 80-90 liters, i.e. total cargo of 120-80 hl;  crew ware: ARS Hayes 78, 88, 104A; fine balance. Keay 55 and 62A produced in Nabeul (Neapolis) region workshops; crew''s ware came from nearby workshops at Oudha (ARS 99B) and Sidi Khalifa  (ARS 88). LRA 1, 2, 4, and 5 do not contradict this point of departure, because they are common at Nabeul: M. Bonifay 2004, 453.',NULL,NULL,NULL,782,NULL),
('Pampelonne',NULL,609,43.217,6.700,NULL,290,325,NULL,63.0,NULL,NULL,NULL,'amphoras','67 in number Dr2-4 horn-handled','metal','lead seals',NULL,NULL,NULL,NULL,NULL,NULL,6.5,3.5,'remains',783,'F. Mayet 1987, 289.'),
('Panarea (Alberti)','Relitto Alberti',610,38.617,15.083,NULL,50,100,'ca / ?',48.0,NULL,NULL,NULL,'amphoras',NULL,'amphoras','(57) Pompeii 36 type','ceramic','Gaulish terra sigillata',NULL,NULL,NULL,NULL,25.0,18.0,'remains',784,NULL),
('Pantano Longarini',NULL,611,36.667,15.117,NULL,600,650,'ca',NULL,'silted',NULL,NULL,'amphoras','late roman',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'stern, 14C: 500+/-120 and 622+/-48',30.0,NULL,NULL,787,NULL),
('Pantelleria',NULL,612,36.764,11.971,'ca',400,500,'ca',NULL,'shallow',NULL,NULL,'amphoras',NULL,'ceramic','Pantellerian wares','lamps',NULL,'sigillata africana, used by the crew, silver ring, glass bottles, game made of animal bone, pig and sheep bones',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'M.E. Chioffi and S. Tusa 2000, 14-15.'),
('Pantelleria',NULL,613,36.733,12.000,'ca',0,0,NULL,NULL,NULL,NULL,NULL,'amphoras','small jars with a short neck and one handle',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,788,NULL),
('Panxon',NULL,614,42.133,-8.833,NULL,1,300,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,789,NULL),
('Paolina, La',NULL,615,42.800,10.133,NULL,1,200,NULL,35.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,790,NULL),
('Parco di Teodorico',NULL,616,44.400,12.183,NULL,400,500,NULL,NULL,'silted sand',NULL,NULL,'amphoras','Dr6?',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'well preserved hull; 200m N of Theoderic''s mausoleum',9.0,3.1,NULL,NULL,'S. Medas 2004, 86-88.'),
('Paris 2',NULL,617,37.100,25.250,NULL,-50,150,'ca / ?',7.0,NULL,NULL,NULL,'amphoras','Coan',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,792,NULL),
('Paros 1',NULL,618,37.100,25.250,NULL,1,100,NULL,16.0,NULL,NULL,NULL,'amphoras','glazed ware',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,791,NULL),
('Pasalimani 2',NULL,619,40.500,27.617,NULL,1400,1500,NULL,15.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,20.0,15.0,'remains',794,NULL),
('Patresi (Italy)',NULL,620,42.781,10.100,'ca',1,100,NULL,50.0,NULL,NULL,NULL,'amphoras','Dr1 Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'unsure where and if there is a wreck.  Samples from C7 BC to C4 AD.  One Spanish C1 AD wreck thought to be here at 50m depth',NULL,NULL,NULL,794,NULL),
('Pedagne, Le (Italy)',NULL,621,40.656,17.993,NULL,0,0,NULL,NULL,NULL,NULL,NULL,'amphoras','Byzantine globular',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'At the mouth of the port of Brindisi. It''s likely that there is more evidence. Area was militarized until the late 90s, so no excavations possible until then.',NULL,NULL,NULL,794,NULL),
('Pefkos',NULL,622,36.067,28.050,NULL,400,700,NULL,NULL,'shallow',NULL,NULL,'tiles','glazed sgraffito ware','ceramic','pitcher base, plate with internal green glaze',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,795,NULL),
('Pelagos',NULL,623,39.250,24.017,'ca',1150,1150,'ca',40.0,NULL,NULL,NULL,'marble','Roman pottery','stone','granite mill-stones',NULL,NULL,NULL,NULL,NULL,'planking, frames',25.0,8.0,NULL,796,NULL),
('Pelosa 1',NULL,624,40.950,8.233,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'coins','glazed pottery','metal','iron bar','glass','fragments','lumps of sulfur','iron anchor?',NULL,'hull planking, deadeyes? A Roman and a medieval wreck seem to be on top of one another on this site of Pelosa; it is difficult to assign finds to one or the other.',NULL,NULL,NULL,798,NULL),
('Pelosa 2',NULL,625,40.950,8.233,NULL,500,1500,NULL,NULL,NULL,NULL,NULL,'nothing reported','Dr7-11','metal','iron bar','glass','glass fragments','lumps of sulfur','iron anchor?',NULL,'hull planking, deadeyes? A Roman and a medieval wreck seem to be on top of one another on this site of Pelosa; it is difficult to assign finds to one or the other.',NULL,NULL,NULL,799,NULL),
('Percheles',NULL,626,36.667,-2.750,NULL,1,100,NULL,12.0,NULL,NULL,NULL,'amphoras','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,800,NULL),
('Perduto',NULL,627,41.367,9.317,NULL,15,25,'ca',25.0,NULL,NULL,NULL,'amphoras','household pottery','ceramic','pottery','metal','bronze pan of candelabrum',NULL,'leaden stocks and reinforcement collar of anchors',NULL,'lead-sheathed hull',NULL,NULL,NULL,801,NULL),
('Pernat 1',NULL,628,44.950,14.317,NULL,1300,1500,NULL,31.0,NULL,NULL,NULL,'amphoras','Dr2-4 LaubenheimerG3',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,803,NULL),
('Petit Congloué, Le',NULL,629,43.167,5.383,NULL,40,50,'ca / ?',60.0,NULL,NULL,NULL,'amphoras','lead ingots','dolia',NULL,NULL,NULL,NULL,'iron anchor, galley brick, pump',NULL,NULL,23.0,NULL,NULL,806,NULL),
('Petit Rhône, Le',NULL,630,43.400,4.300,'ca',1,500,NULL,18.0,NULL,NULL,NULL,'ceramic','Keay25; Keay52',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,807,NULL),
('Pian di Spille',NULL,631,42.200,11.667,NULL,350,500,NULL,NULL,NULL,NULL,NULL,'amphoras','Dr2-4 Dr20 Beltran2B Pelichet47/LaubenheimerG4 Dr1A Afr2A',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,811,NULL),
('Pianosa 1',NULL,632,42.567,10.100,NULL,50,100,'ca',35.0,NULL,NULL,NULL,'amphoras','Roman pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,812,NULL),
('Pianosa 2',NULL,633,42.567,10.100,'ca',1,100,NULL,40.0,NULL,NULL,NULL,'amphoras','Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,813,NULL),
('Piedra Negra',NULL,634,42.317,3.317,NULL,75,150,'ca / ?',70.0,NULL,NULL,NULL,'ceramic','cylindrical',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,814,NULL),
('Pierres Plates',NULL,635,43.033,6.467,'ca',300,325,'ca / ?',NULL,NULL,NULL,NULL,'metal','sculptures',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,815,NULL),
('Piraeus 1',NULL,636,37.933,23.633,'ca',100,200,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,817,NULL),
('Piraeus 2',NULL,637,37.933,23.633,'ca',0,0,NULL,30.0,NULL,NULL,NULL,'ceramic','Gaul, Forlimpopoli',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,818,NULL),
('Pisa A',NULL,638,43.700,10.383,NULL,100,200,NULL,NULL,'silted',NULL,NULL,'ceramic','Spanish, Adriatic',NULL,NULL,NULL,NULL,NULL,'crew gear: ARS, coarseware',NULL,'last voyage was probably down the Adriatic to Africa and up the coast of Italy',NULL,NULL,NULL,NULL,'http://www.navipisa.it'),
('Pisa B',NULL,639,43.700,10.383,NULL,-30,40,NULL,NULL,'silted',NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,'stone ballast, Campania',NULL,'skeletons (probably crew member and his dog)',NULL,4.0,NULL,NULL,'http://www.navipisa.it'),
('Pisa C',NULL,640,43.700,10.383,NULL,0,0,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'oared river boat; hull sealed with encaustic (wax); Greek name? ALKDO',14.0,NULL,NULL,NULL,'http://www.navipisa.it'),
('Pisa D',NULL,641,43.700,10.383,NULL,400,500,NULL,NULL,'silted',NULL,NULL,'amphoras','Spanish, Gaul, Corsica; dolia tops',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'oak; not yet excavated wreck; had been salvaged, recycled',14.0,NULL,NULL,NULL,'http://www.navipisa.it ; S. Bruni 2000; S. Kingsley 2004, 162.'),
('Pisa E',NULL,642,43.700,10.383,NULL,-30,40,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'possibly salvaged',NULL,NULL,NULL,NULL,'http://www.navipisa.it'),
('Pisa F',NULL,643,43.700,10.383,NULL,100,300,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'boat; river? Lintres type? Oak',NULL,NULL,NULL,NULL,'http://www.navipisa.it'),
('Pisa G',NULL,644,43.700,10.383,NULL,100,300,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'boat, flat bottom',9.0,NULL,NULL,NULL,'http://www.navipisa.it'),
('Pisa H',NULL,645,43.700,10.383,NULL,1,500,NULL,NULL,'silted',NULL,NULL,'metal',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'boat, river; flat bottom',NULL,NULL,NULL,NULL,'http://www.navipisa.it'),
('Pisa I',NULL,646,43.700,10.383,NULL,0,0,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'boat',NULL,NULL,NULL,NULL,'http://www.navipisa.it'),
('Pisa P',NULL,647,43.700,10.383,NULL,-30,40,NULL,NULL,'silted',NULL,NULL,'amphoras','Dr28, 20, 8, 9, 12; Haltern 70, Punico-ebusitaines 25',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'boat, river like Pisa G',NULL,NULL,NULL,NULL,'http://www.navipisa.it'),
('Plage d''Arles 4',NULL,648,43.100,4.700,NULL,25,50,NULL,660.0,NULL,NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,'anchor stock, 2 lead pipes from deck pump',NULL,'From Betica; vestiges of ship wood; dating from Dr20 amphoras; location: several km from Farama',NULL,NULL,NULL,NULL,'P. Pomey and L. Long 1993, 14-15.'),
('Plane 3',NULL,649,43.183,5.383,NULL,900,1000,NULL,26.0,NULL,NULL,NULL,'metal','Dr2-4; Campanian Dr2-4','ceramic','jars; clay balls, glazed plate, flagon, strainer flasks, 2 jugs','lamps',NULL,'2 circular millstones, adze-hammer, double-axe, axe, hook, large gouge, burin, nail-lifter or drove, caulking tool, pick, rings, nails',NULL,NULL,'partially-preserved hull; ceramic related to 10th C. Muslim production',NULL,NULL,NULL,821,NULL),
('Planier 1',NULL,650,43.183,5.217,NULL,1,15,'ca',32.0,NULL,NULL,NULL,'amphoras','Dr20 Beltran2B','ceramic','pottery gourd, mortarium, Arretine ware',NULL,NULL,'2 wooden plates, 2 wooden figurines','lead anchor stock',NULL,'Stamped ceramics date site to 1-25 and probably 1-10AD; 2 wood statues',12.0,7.0,'remains',824,NULL),
('Planier 2',NULL,651,43.183,5.217,NULL,150,150,'ca',30.0,NULL,NULL,NULL,'amphoras','Afr2C Almagro50 Almagro51C','metal','copper ingots',NULL,NULL,NULL,NULL,NULL,'pump bearing',NULL,NULL,NULL,825,NULL),
('Planier 7',NULL,652,43.183,5.217,NULL,300,350,'ca / ?',65.0,NULL,NULL,NULL,'amphoras','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,7.0,8.0,'remains',830,NULL),
('Plavac 1',NULL,653,43.683,15.850,NULL,-25,25,NULL,33.0,NULL,NULL,NULL,'amphoras','pottery','ceramic','terra sigillata cups and jugs with floral and figural decoration; fineware plates, coarseware, storage jar','lamps',NULL,NULL,'wooden pulley, sounding lead, 2 iron anchors',NULL,'hull, lead tubing, collecting tank',30.0,8.3,NULL,831,NULL),
('Plavac 2',NULL,654,43.683,15.850,NULL,1,100,NULL,NULL,NULL,NULL,NULL,'ceramic','bronze lamps, censers, pitchers, bowls, shipyard',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,832,NULL),
('Plemmirio 1',NULL,655,37.000,15.350,NULL,300,500,NULL,NULL,NULL,NULL,NULL,'stone','Afr1 Afr2A',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,833,NULL),
('Plemmirio 2',NULL,656,36.983,15.333,NULL,200,200,'ca',47.0,NULL,NULL,NULL,'amphoras',NULL,'metal','iron bars','ceramic','coarseware cups, jugs, plates, cooking-ware','glass vessels, lamps, lead fishing weight, bronze arrowheads, scalpel handles, bronze handle of an iron cautery, stick','sounding lead, amphoras, coarseware cups, jugs, plates, cooking-ware, glass vessels, lamps, lead fishing weight, bronze arrowheads, scalpel handles, bronze handle of an iron cautery, stick',NULL,'roof-tiles, bricks, stone blocks, pottery vaulting tube, lead sheathing and iron nail concretions of hull',NULL,NULL,NULL,834,NULL),
('Plitharia',NULL,657,38.250,20.650,NULL,300,800,NULL,7.0,NULL,NULL,NULL,'amphoras','roof tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,836,NULL),
('Plocice',NULL,658,44.533,14.500,'ca',1,500,NULL,NULL,NULL,NULL,NULL,'metal','lead ingots',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,837,NULL),
('Ploumanac''h',NULL,659,48.900,-3.450,NULL,200,400,NULL,10.0,NULL,NULL,NULL,'amphoras',NULL,'tiles','roof-tiles','stone','sandstone handmill',NULL,NULL,NULL,NULL,NULL,NULL,NULL,838,NULL),
('Poel (Timmendorfer Mole) 1',NULL,660,53.996,10.802,NULL,1354,1354,NULL,2.3,NULL,NULL,NULL,'stone',NULL,NULL,NULL,NULL,NULL,NULL,'ballast','up to 200 tons','dendro dated with 30 different samples of pine. 150m north of Timmendorf strand. Could hold up to 200 tons of cargo',26.0,8.0,NULL,NULL,'T. Förster 2000.'),
('Poel (Timmendorfer Mole) 2',NULL,661,53.996,10.802,NULL,1486,1486,NULL,NULL,NULL,NULL,NULL,'stone','rounded tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dendro dated from oak planks; clinker built.',16.0,NULL,'ca',NULL,'B. Dangreaux 1997, 10; T. Förster 2000.'),
('Pointe de la Galère',NULL,662,43.017,6.400,NULL,1,50,'ca / ?',15.0,NULL,NULL,NULL,'ceramic','tegulae of pale yellow, fragile; some imbrices','amphoras','Haltern 70 (fragment)','ceramic','coarse pottery and cf. Haltern70 amphora',NULL,NULL,NULL,NULL,NULL,NULL,NULL,840,NULL),
('Pointe de l''Ilette 1',NULL,663,43.533,7.100,NULL,190,210,'c2 - end or c3 - beginning',20.0,NULL,NULL,NULL,'amphoras','Dr7-11 Beltran2B Dr2-4 Tarraconaise, Pelichet 47 Gaulish, Dr2 Gaulish Dr20','amphoras','Gauloise 4',NULL,NULL,NULL,NULL,NULL,'50m from shore',NULL,NULL,NULL,NULL,'P. Pomey and L. Long 1993, 48.'),
('Pointe Debie 1',NULL,664,43.267,5.300,NULL,1,100,NULL,28.0,NULL,NULL,NULL,'amphoras','roof tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Possibly from two wrecks: Dr7-11 usually 50-60 AD and Beltran 2B 90-150 AD',NULL,NULL,NULL,841,'J.M. Gassend 1978, 101-107.'),
('Pointe Debie 2',NULL,665,43.267,5.300,NULL,225,250,'ca',16.0,NULL,NULL,NULL,'amphoras','Dr2-4 Dr7-11 Gaulish',NULL,NULL,'coins','sestertius of Severus Alexander (225-235)',NULL,NULL,NULL,NULL,NULL,NULL,NULL,842,NULL),
('Pointe Lequin 3',NULL,666,43.017,6.217,NULL,50,70,'ca / ?',NULL,NULL,NULL,NULL,'marble','Almagro 50 and LaubenheimerG4','ceramic','Arretine pottery',NULL,NULL,NULL,NULL,NULL,'Neronian',NULL,NULL,NULL,848,NULL),
('Pomègues 1',NULL,667,43.267,5.300,NULL,200,300,NULL,7.0,NULL,NULL,NULL,'metal',NULL,'ceramic','pottery medallion','coins','sestertius of Antoninus Pius (145-161), middle bronze of Philip I (245-249)','lamps','ballast',NULL,'hull, bronze pulley disc',NULL,NULL,NULL,851,'F. Mayet 1987, 289.'),
('Pommeroeul 1',NULL,668,50.450,3.717,NULL,50,150,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'planks and rib fragments',NULL,NULL,NULL,853,NULL),
('Pommeroeul 2',NULL,669,50.450,3.717,NULL,50,150,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'extended logboat',NULL,1.0,NULL,854,NULL),
('Pommeroeul 3',NULL,670,50.450,3.717,NULL,50,150,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'log, timbers, planks',12.0,1.0,NULL,855,NULL),
('Pommeroeul 4',NULL,671,50.450,3.717,NULL,50,150,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'barge, timbers, gangplank, cabin',20.0,3.0,NULL,856,NULL),
('Pommeroeul 5',NULL,672,50.450,3.717,NULL,150,225,NULL,NULL,'silted',NULL,NULL,'metal','pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'barge, planking, timbers',NULL,NULL,NULL,857,NULL),
('Pommeroeul 6',NULL,673,50.450,3.717,NULL,0,0,NULL,NULL,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dugout',15.0,NULL,NULL,858,NULL),
('Pomonte',NULL,674,42.717,10.083,NULL,-100,100,NULL,100.0,NULL,NULL,NULL,'amphoras',NULL,'ceramic','vases, jugs',NULL,NULL,NULL,NULL,NULL,'timber',NULL,NULL,NULL,859,NULL),
('Pomorje 1',NULL,675,42.550,27.650,NULL,400,600,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,860,NULL),
('Pomorje 2',NULL,676,42.550,27.650,NULL,400,600,NULL,NULL,NULL,NULL,NULL,'marble',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,861,NULL),
('Pomposa',NULL,677,44.633,12.167,NULL,500,1500,NULL,NULL,'silted',NULL,NULL,'dolia','Dr2-4 Haltern70 Dr7-11 Camulodonum186 Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'sewn boat, rigging',50.0,10.0,NULL,862,NULL),
('Ponte d''Oro',NULL,678,42.933,10.567,NULL,50,50,'ca / ?',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,863,NULL),
('Pontelagoscuro',NULL,679,44.883,11.617,NULL,300,1100,NULL,NULL,NULL,NULL,NULL,'stone',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'planks',NULL,NULL,NULL,864,NULL),
('Ponza Porto',NULL,680,40.883,12.950,NULL,1,200,NULL,11.0,NULL,NULL,NULL,'marble',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'timbers',30.0,10.0,'remains',868,NULL),
('Populonia',NULL,681,42.983,10.483,NULL,1,200,NULL,NULL,'shallow',NULL,NULL,'amphoras','Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'floor timber',NULL,NULL,NULL,869,NULL),
('Port-la-Nouvelle',NULL,682,42.717,3.600,'ca',1,250,'ca',NULL,'deep',NULL,NULL,'amphoras','cylindrical',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,872,NULL),
('Port-Miou',NULL,683,43.200,5.500,NULL,400,425,'ca',30.0,NULL,NULL,NULL,'amphoras','Afr2D','ceramic','terra sigillata chiara D','ceramic','lamps','lead seals of commerce, mineral objects, pumice stone, pozzolana, Egyptian blue',NULL,NULL,NULL,NULL,NULL,NULL,873,NULL),
('Porto Azzurro 1',NULL,684,42.750,10.400,NULL,250,300,'ca',NULL,NULL,NULL,NULL,'nothing reported','Dr10 Dr2-4 TripolitanaI','ceramic','terra sigillata chiara',NULL,NULL,NULL,NULL,NULL,'timbers',NULL,NULL,NULL,880,NULL),
('Porto Azzurro 2',NULL,685,42.750,10.400,NULL,50,100,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','resembling Günsenin1-3','ceramic','lamps, Italian and S. Gaulish terra sigillata','coins','coins of Agrippina the elder (37-41)',NULL,NULL,NULL,NULL,NULL,NULL,NULL,881,NULL),
('Porto Cesareo',NULL,686,40.250,17.883,NULL,1100,1300,NULL,NULL,NULL,NULL,NULL,'amphoras','globular',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,883,NULL),
('Porto Cheli',NULL,687,37.300,23.183,NULL,500,600,NULL,7.0,NULL,NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,'ballast',NULL,NULL,NULL,NULL,NULL,884,NULL),
('Porto Cristo 1',NULL,688,39.533,3.333,NULL,50,70,'ca',NULL,'shallow',NULL,NULL,'amphoras','Haltern70 Dr20','ceramic','plates, pots, barbotine-decorated beaker, S. Gaulish terra sigillata','amphoras','Dr2-4','bronze keys and coins (sestertius of Caligula)',NULL,NULL,'well-preserved hull, lead sheathing',30.0,NULL,NULL,885,NULL),
('Porto Cristo 2',NULL,689,39.533,3.333,NULL,25,100,'ca / ?',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,886,NULL),
('Porto Ercole',NULL,690,42.383,11.217,'ca',1,500,NULL,NULL,NULL,NULL,NULL,'tiles','Byz',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,888,NULL),
('Porto Longo',NULL,691,36.750,21.700,NULL,400,650,'ca / ?',NULL,NULL,NULL,NULL,'ceramic','rough and worked. Origin: Chemtou,  Karystos, Synnada, Teos, Chios, Carrara, Sainte Baume',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,889,NULL),
('Porto nuovo (Bonifacio, Corsica)',NULL,692,41.389,9.155,NULL,1,100,'ca',NULL,'shallow',NULL,NULL,'amphoras',NULL,'marble','rough columns from carrara','ceramic','crustae','Gold coin of Tiberius (27/8, from Lyon); bronze oil lamp (type  Loeschcke XXVI, 1C AD)','Roman sword sheath, metal tools for marble handling and sculpting, Roman belt buckle, 3 Roman hammers, mirrors',NULL,'variety of marble indicates Rome as port of origin',NULL,NULL,NULL,NULL,'H. Bernard 2000, 114-125.'),
('Porto Paglia',NULL,693,41.133,9.533,NULL,-100,100,NULL,NULL,'shallow',NULL,NULL,'amphoras','lead ingots',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,890,NULL),
('Porto Pistis',NULL,694,39.533,8.433,NULL,117,138,NULL,6.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,892,NULL),
('Porto Santo Stefano',NULL,695,42.433,11.117,'ca',0,0,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,893,NULL),
('Portoferraio (Italy) 1',NULL,696,42.800,10.317,'ca',1,100,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'ship',NULL,NULL,NULL,894,'Canals 1993, 38.'),
('Portoferraio (Italy) 2',NULL,697,42.800,10.317,'ca',1,100,NULL,NULL,NULL,NULL,NULL,'glass','Almagro50 Almagro51C; flat-bottomed amphoras, cylindrical amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'ship',NULL,NULL,NULL,894,NULL),
('Port-Vendres 1',NULL,698,42.517,3.100,NULL,400,400,'ca',6.0,NULL,NULL,NULL,'glass','Dr20 Haltern70 Dr28 Beltran2A [Pompeii 7]','coins','68 bronze coins ending 383-392 AD','ceramic','pottery','lamp, pins, brooch, bone flute, gaming dice, counters, fish hook, fishing weight','bone marlinspike, wooden carpenter''s rule, needles',NULL,'well-preserved hull',20.0,8.0,NULL,874,NULL),
('Port-Vendres 2',NULL,699,42.517,3.100,NULL,42,50,'ca',7.0,NULL,NULL,NULL,'amphoras','LaubenheimerG4 pear-shaped','ceramic','red-varnish and fine-wall ware pottery;  terra sigillata vessel','metal','tin, copper, lead ingots;  tin cup, bronze skillets, plates and pots, 2 strigils','glass bowls, touch stone, lamps, glass, Iltirda bronze coin','3 iron anchors',NULL,'frames of hull, copper nails, lead sheathing, pulley, yard',NULL,NULL,NULL,875,NULL),
('Port-Vendres 3',NULL,700,42.517,3.100,NULL,150,150,'ca',6.0,NULL,NULL,NULL,'nothing reported','Pascual1','metal','iron blades','ceramic','terra sigillata, S. Gaulish coarseware','lamp, glass bottles, Luna marble mortar, coins of Hadrian, Faustina the Elder and Younger, bronze vase, African black rhinoceros; traces of iron barrel hoops seem to indicate barrels for some cargo (Marlière 2002, 43).',NULL,NULL,NULL,NULL,NULL,NULL,876,NULL),
('Port-Vendres 4',NULL,701,42.517,3.100,NULL,-50,25,'ca / ?',4.0,NULL,NULL,NULL,'marble','Pascual1 Dr2-4; [Oberaden 74, Dr 7/11]','dolia',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,877,NULL),
('Port-Vendres 5',NULL,702,42.517,3.100,NULL,-50,25,'ca / ?',16.0,NULL,NULL,NULL,'amphoras','bowls: cobalt and metallic luster','tiles','fragments; roof tiles','lamps','oil lamp',NULL,'[5 gray marble plaques, jug, 2 oil lamps, 2 parts of iron pipes, wood, cylindrical object]',NULL,'lead sheathing; Gallia informations says C1 BC',NULL,NULL,NULL,878,NULL),
('Port-Vendres 6',NULL,703,42.517,3.100,NULL,1450,1500,NULL,NULL,NULL,NULL,NULL,'amphoras','pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'P. Pomey and L. Long 1993, 3.'),
('Posillipo',NULL,704,40.750,14.217,'ca',1,500,NULL,5.0,NULL,NULL,NULL,'tiles','cylindrical globular Afr2A Afr2C Afr2B',NULL,NULL,NULL,NULL,NULL,'shipboard utensils',NULL,'wooden hull, bronze nails',NULL,NULL,NULL,896,NULL),
('Povile',NULL,705,45.117,14.817,NULL,275,400,NULL,19.0,NULL,NULL,NULL,'glass','Afr1 Afr2',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,897,NULL),
('Praiano',NULL,706,40.583,14.500,'ca',1,500,NULL,NULL,NULL,NULL,NULL,'marble','RileyLR2',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,899,NULL),
('Prasso',NULL,707,38.517,26.183,NULL,400,700,NULL,NULL,'shallow',NULL,NULL,'amphoras','Dr6A Lam2',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,900,NULL),
('Premuda 1',NULL,708,44.317,14.650,NULL,1,100,NULL,60.0,NULL,NULL,NULL,'amphoras','globular',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,901,NULL),
('Premuda 2',NULL,709,44.333,14.583,NULL,400,700,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,902,NULL),
('Premuda 3',NULL,710,44.333,14.583,NULL,500,1500,NULL,NULL,NULL,NULL,NULL,'amphoras','pear-shaped Afr1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'probable medieval ship',NULL,NULL,NULL,903,NULL),
('Procchio',NULL,711,42.783,10.233,NULL,160,200,'ca',2.0,NULL,NULL,NULL,'tiles',NULL,'metal','sulphur ingots','glass','shell-shaped buttons','jars, lamps, coarseware casserole, fine-wall cup fragments, ivory stopper, glass bottle or jug, mortaria, larchwood box','ropes, hawser, ballast',NULL,'roof-tiles, lead-sheathed, planking, frames',18.0,NULL,NULL,906,NULL),
('Puck 2',NULL,712,54.733,18.383,NULL,861,978,NULL,1.8,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on 9 dendro samples on oak planks, range 861-978, and 3 14C samples range 555-810, with average margin of 68 years (dismissed by excavator as well as other literature).  Slavonic, military vessel, oared/sailed, oak, pine.  Found in underwater quay, in Gdansk bay, along with another 5 wrecks.  Mast step of wreck 2 preserved very well.',18.0,2.3,NULL,NULL,'Navis I, Puck 2, #194; W. St?pie? 1983, 49-57; W. St?pie? 1984, 71-78; W. St?pie? 1984, 311-321; W. St?pie? 1987, 139-154; J. Litwin 1995.'),
('Puck 3',NULL,713,54.733,18.383,NULL,950,1155,NULL,0.5,NULL,NULL,NULL,'amphoras','terra sigillata vessels',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on 10 dendro dates from planks, with range 1079-1155 and one 14C with date 950 (no range provided).  Description said wood was felled after 1155 (not clear why the range of dates then). Slavonic, oak, pine, sailed/oared.',16.0,2.8,NULL,NULL,'Navis I, Puck 3, #195; W. St?pie? 1983, 49-57; W. St?pie? 1984, 71-78; W. St?pie? 1984, 311-321; W. St?pie? 1987; J. Litwin 1995.'),
('Pudding-Pan Rock',NULL,714,51.467,1.150,NULL,175,200,NULL,2.0,NULL,NULL,NULL,'amphoras','Dr14 Beltran2B',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,908,NULL),
('Pudrimel Norte',NULL,715,42.000,-0.700,NULL,50,150,'ca / ?',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,909,NULL),
('Puebla del Rio',NULL,716,37.250,-6.033,NULL,1000,1200,NULL,4.4,'in alluvium',NULL,NULL,'amphoras','Dr20 Afr2B-D pear-shaped',NULL,NULL,NULL,NULL,NULL,'ballast',NULL,'river-boat, keel and plans preserved',10.0,1.2,NULL,911,NULL),
('Punta Ala',NULL,717,42.783,10.733,NULL,250,250,'ca / ?',2.0,NULL,NULL,NULL,'amphoras',NULL,'dolia',NULL,'ceramic','terra sigillata chiara C, terra sigillata chiara D, rilled-bottom wear',NULL,'terracotta pipe',NULL,'3/4 hull, foremast step, foot of foremast',25.0,NULL,NULL,912,NULL),
('Punta Altarella',NULL,718,37.983,12.350,NULL,1,500,NULL,47.0,NULL,NULL,NULL,'stone','Pascual1','ceramic','pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,913,NULL),
('Punta Blanca',NULL,719,42.317,3.317,'ca',-50,25,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Afr2A pear-shaped Afr1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,914,NULL),
('Punta Cera',NULL,720,42.750,10.417,NULL,200,275,'ca / ?',25.0,NULL,NULL,NULL,'metal','tin ingots','ceramic','coarseware plate, grey-ware jug, dark-walled casserole',NULL,NULL,NULL,NULL,NULL,NULL,25.0,10.0,'remains',916,NULL),
('Punta Crapazza',NULL,721,38.433,14.950,NULL,200,300,NULL,NULL,NULL,NULL,NULL,'amphoras','Dr20','amphoras','Afr1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,918,NULL),
('Punta de la Mona',NULL,722,36.717,-3.717,NULL,175,250,'ca / ?',80.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,920,NULL),
('Punta dei Mangani',NULL,723,42.833,10.383,NULL,-100,200,NULL,55.0,NULL,NULL,NULL,'amphoras','limestone blocks',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,921,NULL),
('Punta del Diavolo',NULL,724,42.100,15.483,NULL,500,1500,NULL,21.0,NULL,NULL,NULL,'ceramic','Afr2B',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,924,NULL),
('Punta del Fenaio',NULL,725,42.383,10.867,NULL,200,325,'ca / ?',75.0,NULL,NULL,NULL,'dolia','column drums','ceramic','terracotta vaulting tubes','metal','iron nails','fishing weight',NULL,NULL,'bronze ship''s nail, hull timbers',NULL,NULL,NULL,925,NULL),
('Punta del Milagro',NULL,726,41.100,1.233,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'tiles','pear-shaped',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,926,NULL),
('Punta del Morto 2',NULL,727,42.383,10.883,NULL,70,220,'ca / ?',40.0,NULL,NULL,NULL,'amphoras','Dr7-11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,928,NULL),
('Punta del Vapor 1',NULL,728,36.717,3.717,NULL,1,100,NULL,NULL,NULL,NULL,NULL,'amphoras','lead ingots',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,929,NULL),
('Punta della Contessa 2',NULL,729,40.650,18.017,'ca',1,100,NULL,NULL,NULL,NULL,NULL,'amphoras','Dr14',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,934,NULL),
('Punta Entina',NULL,730,36.750,-2.083,NULL,1,150,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','pear-shaped',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,937,NULL),
('Punta Falconaia',NULL,731,42.817,10.350,NULL,100,300,NULL,35.0,NULL,NULL,NULL,'amphoras','pear-shaped',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,938,NULL),
('Punta Glavina 2',NULL,732,44.700,14.867,'ca',1,500,NULL,NULL,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,941,NULL),
('Punta Javana',NULL,733,36.883,-1.950,NULL,1,200,NULL,NULL,NULL,NULL,NULL,'tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,943,NULL),
('Punta le Tombe',NULL,734,42.733,10.117,NULL,1,100,NULL,50.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,945,NULL),
('Punta Nera',NULL,735,42.733,10.417,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'amphoras','Apulian/Lam2',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,948,NULL),
('Punta Patedda',NULL,736,40.667,17.917,NULL,-15,20,'ca',NULL,NULL,NULL,NULL,'metal','Pan41','ceramic','fine-wall pottery beakers, Arretine pottery; unguent flask','metal','bronze drinking cups, fish hook','ivory gaming die',NULL,NULL,NULL,NULL,NULL,NULL,950,NULL),
('Punta Penne 2',NULL,737,40.683,17.933,NULL,150,225,'ca / ?',12.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,952,NULL),
('Punta Perla',NULL,738,42.750,10.400,NULL,-100,100,NULL,35.0,NULL,NULL,NULL,'amphoras','Roman',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,953,NULL),
('Punta Polveraia',NULL,739,42.783,10.100,NULL,1,100,NULL,50.0,NULL,NULL,NULL,'amphoras','Dr10',NULL,NULL,NULL,NULL,NULL,'2 iron anchors',NULL,NULL,NULL,NULL,NULL,954,NULL),
('Punta Prima',NULL,740,41.800,3.067,NULL,70,100,'ca',18.0,NULL,NULL,NULL,'amphoras','Panella44-47','ceramic','Drag37 terra sigillata hispanica bowl',NULL,NULL,NULL,'2 lead anchor stocks',NULL,NULL,NULL,NULL,NULL,956,NULL),
('Punta Raisi',NULL,741,38.250,13.100,'ca',1,300,NULL,NULL,'deep',NULL,NULL,'lamps',NULL,'ceramic','pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,957,NULL),
('Punta Sardegna',NULL,742,41.217,9.367,NULL,1,100,NULL,NULL,NULL,NULL,NULL,'amphoras','roof tiles','stone','Capo Testa granite columns',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,959,NULL),
('Punta Scario 1',NULL,743,37.900,12.433,NULL,1,100,NULL,6.0,NULL,NULL,NULL,'stone','columns, basins, blocks, capitals, statues of Pavonazzetto, Synnada, Proconnesian',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'remains of a ship',NULL,NULL,NULL,961,NULL),
('Punta Scifo 1',NULL,744,39.000,17.183,NULL,200,225,NULL,7.0,NULL,NULL,NULL,'amphoras','7C Byzantine coin','stone','samples of slate & marble','lamps','bronze lamp',NULL,NULL,NULL,'pieces of ship, planking',35.0,NULL,NULL,965,NULL),
('Punta Secca 1',NULL,745,36.767,14.500,NULL,650,700,'ca',3.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'well-preserved hull',NULL,NULL,NULL,967,NULL),
('Punta Secca 2',NULL,746,36.767,14.500,NULL,650,700,'ca',3.0,NULL,NULL,NULL,'amphoras','Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'well-preserved hull',NULL,NULL,NULL,968,NULL),
('Puntas, Las',NULL,747,36.733,-3.683,NULL,90,140,'ca',70.0,NULL,NULL,NULL,'amphoras','Afr2A',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,972,NULL),
('Qawra',NULL,748,35.950,14.417,NULL,200,275,'ca / ?',40.0,NULL,NULL,NULL,'tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,973,NULL),
('Ralswiek 1',NULL,749,54.433,13.450,NULL,900,1000,'ca',NULL,'in alluvium',NULL,NULL,'metal',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'No info on dating or cargo in Navis database. Slavonic context',14.0,3.4,NULL,NULL,'Navis I, Ralswiek 1, #126; P. Herfert 1968, 211-222; W. Kramer and H. Schlichtherle 1995, 3-16; O. Crumlin-Pedersen 1997, 110.'),
('Ralswiek 2',NULL,750,54.433,13.450,NULL,900,1000,'ca',NULL,'in alluvium',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Cargo sail/oar vessel. No info on dating or cargo in Navis database. Slavonic context.',9.5,NULL,NULL,NULL,'Navis I, Ralswiek 2, #122; P. Herfert 1968, 211-222; W. Kramer and H. Schlichtherle 1995, 3-16; O. Crumlin-Pedersen 1997, 110.'),
('Ralswiek 4',NULL,751,54.433,13.450,NULL,900,1000,'ca',NULL,'in alluvium',NULL,NULL,'amphoras','Almagro50',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Cargo sail vessel. Slavonic context',13.0,3.3,NULL,NULL,'Navis I, Ralswiek 4, #127; P. Herfert 1968, 211-222; J. Herrmann 1981, 145-158; W. Kramer and H. Schlichtherle 1995, 110.'),
('Randello',NULL,752,36.850,14.450,NULL,300,325,NULL,3.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,'3/4 iron anchors',NULL,'copper nails',NULL,NULL,NULL,975,NULL),
('Ras Achakkar',NULL,753,35.733,-5.933,'ca',1,500,NULL,NULL,NULL,NULL,NULL,'amphoras','mortaria',NULL,NULL,NULL,NULL,'Roman bushel tap',NULL,NULL,NULL,NULL,NULL,NULL,976,NULL),
('Ras el Basit',NULL,754,35.867,35.800,NULL,250,350,NULL,NULL,NULL,NULL,NULL,'amphoras','Afr2B',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,977,NULL),
('Ratino',NULL,755,41.367,9.233,NULL,325,350,'ca / ?',6.0,NULL,NULL,NULL,'amphoras','Camulodunum186A',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,978,NULL),
('Redona, Na',NULL,756,39.167,2.983,NULL,1,100,NULL,35.0,NULL,NULL,NULL,'amphoras',NULL,'metal','copper, tin ingots',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,980,NULL),
('Rhamnous',NULL,757,38.167,24.033,NULL,0,0,NULL,NULL,NULL,NULL,NULL,'nothing reported','18 different kinds in great condition',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,981,NULL),
('Ria de Aveiro A',NULL,758,40.650,8.700,NULL,1434,1448,NULL,NULL,'shallow',NULL,NULL,'nothing reported','bronze statues; lead jar lid, Dr2-4; lead rings',NULL,NULL,NULL,NULL,'chestnuts, walnuts, grapes, fishbones',NULL,NULL,'Dating based on 4 14C samples on plank, oar, walnut and keg stave. All very reliable, with 2 sigma interval 1424-1469 and intersection in 1441. Ceramics are in perfect condition for the most part, suggesting non violent sinking.',10.5,2.5,NULL,NULL,'F. Alves et al. 2001, 12-36.'),
('Riace',NULL,759,38.383,16.533,NULL,1,100,NULL,6.0,NULL,NULL,NULL,'marble',NULL,'amphoras','Rhodian fragments',NULL,NULL,NULL,NULL,NULL,'fragment of ship''s keel',NULL,NULL,NULL,985,NULL),
('Risan',NULL,760,42.533,18.700,NULL,0,0,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,988,NULL),
('River Hamble',NULL,761,50.930,1.380,NULL,1225,1405,NULL,NULL,'shallow',NULL,NULL,'marble','pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Archaeologists agree that this is the wreck of the Grâce Dieu, of Henry V.  Dating based on C14 and construction features.',40.0,NULL,NULL,NULL,'R. Clarke et al. 1993, 21-44; I. Friel 1993, 3-19; S. McGrail 1993, 45-51.'),
('Rocca di San Nicola 1',NULL,762,37.100,13.867,NULL,1400,1500,NULL,9.0,NULL,NULL,NULL,'amphoras','C5 pottery',NULL,NULL,NULL,NULL,NULL,'bombards, cannon, lead shot',NULL,NULL,NULL,NULL,NULL,989,NULL),
('Rocca di San Nicola 2',NULL,763,37.100,13.867,NULL,300,500,NULL,9.0,NULL,NULL,NULL,'amphoras','C5 pottery',NULL,NULL,NULL,NULL,NULL,'LR/Byz anchors',NULL,NULL,NULL,NULL,NULL,990,NULL),
('Rocca di San Nicola 3',NULL,764,37.100,13.867,NULL,400,500,NULL,9.0,NULL,NULL,NULL,'amphoras','LaubenheimerG5 and G2, Dr20, Drag. 37',NULL,NULL,NULL,NULL,NULL,'Late Roman/Byzantine anchors',NULL,NULL,NULL,NULL,NULL,991,NULL),
('Roches d''Aurelle, Les',NULL,765,43.450,6.933,NULL,80,100,'ca',72.0,NULL,NULL,NULL,'marble','Dr14 Dr38 Dr20 Dr1','ceramic','Vases - coarse pottery vessels; figured lamp, fine-wall cup, Drag37 cup','tiles','roof tiles',NULL,NULL,NULL,NULL,15.0,NULL,NULL,994,NULL),
('Roquetas del Mar (Spain)',NULL,766,36.767,-2.598,'ca',0,0,NULL,NULL,NULL,NULL,NULL,'stone',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Mixture of amphoras. Possibility of wreck.',NULL,NULL,NULL,994,NULL),
('Roquetes, Les',NULL,767,41.483,2.367,NULL,1300,1600,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,995,NULL),
('Roskilde 1',NULL,768,55.650,12.079,NULL,1336,1336,NULL,1.0,NULL,NULL,NULL,'stone',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Survey find. Dating by dendro of planks. Cargo vessel in oak and pine. Nordic type. Cargo vessel. All Roskilde ships found during foundation work for the Viking ship museum.',9.8,NULL,'ca',NULL,'A. Croome 1999, 382-393.'),
('Roskilde 2',NULL,769,55.650,12.079,NULL,1200,1200,NULL,NULL,'silted',NULL,NULL,'stone',NULL,NULL,NULL,NULL,NULL,NULL,'rope, shroudpin, rigging',NULL,'Survey find. Dating by dendro on planks. Cargo vessel in oak and pine. Nordic type.',15.0,NULL,'ca',NULL,'A. Croome 1999, 382-393.'),
('Roskilde 3',NULL,770,55.650,12.079,NULL,1050,1055,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating by dendro on planks, 3 different samples. Cargo vessel. All Roskilde ships found during foundation work for the Viking ship museum. Nordic type.',18.0,4.4,NULL,NULL,'Navis I, Roskilde 3, #190; N. Bonde and A. Daly 1996-1998; N. Bonde 1997; H.M. Myrhøj and M. Gøthche 1997; J. Bill, M. Gøthche, and H.M. Myrhøj 1998; A. Croome 1999, 382-393; J. Bill, M. Gøthche, and H.M. Myrhøj 2000.'),
('Roskilde 4',NULL,771,55.650,12.079,NULL,1108,1108,NULL,NULL,'silted',NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating by dendro on planks, 3 different samples. Cargo vessel, Nordic type. Some of the information later published by Croome 1999 conflicts with what is reported by the Navis database.  Dating info here reflects Croome 1999. Cargo vessel. All Roskilde ships found during foundation work for the Viking ship museum.',20.5,6.6,NULL,NULL,'Navis I, Roskilde 4, #191; N. Bonde and A. Daly 1996-1998; N. Bonde 1997; H.M. Myrhøj and M. Gøthche 1997; J. Bill, M. Gøthche, and H.M. Myrhøj 1998; A. Croome 1999, 382-393;  J. Bill, M. Gøthche, and H.M. Myrhøj 2000;'),
('Roskilde 5',NULL,772,55.650,12.079,NULL,1090,1131,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating by dendro on planks, 3 different samples. Cargo vessel in oak and pine. Nordic type. Cargo vessel. All Roskilde ships found during foundation work for the Viking ship museum.',14.0,3.6,NULL,NULL,'Navis I, Roskilde 5, #192; N. Bonde and A. Daly 1996-1998; N. Bonde 1997; H.M. Myrhøj and M. Gøthche 1997; J. Bill, M. Gøthche, and H.M. Myrhøj 1998; A. Croome 1999, 382-393; J. Bill, M. Gøthche, and H.M. Myrhøj 2000.'),
('Roskilde 6',NULL,773,55.650,12.079,NULL,1025,1025,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating by dendro on planks, 3 different samples. Warship of oak. Viking context, Nordic type. Cargo vessel. All Roskilde ships found during foundation work for the Viking ship museum.',36.0,3.5,NULL,NULL,'Navis I, Roskilde 6, #92; N. Bonde and A. Daly 1996-1998; N. Bonde 1997; H.M. Myrhøj and M. Gøthche 1997; J. Bill, M. Gøthche, and H.M. Myrhøj 1998; A. Croome 1999, 382-393; J. Bill, M. Gøthche, and H.M. Myrhøj 2000.'),
('Roskilde 7',NULL,774,55.650,12.079,NULL,1271,1271,'ca',NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Survey find. Dating by dendro on planks. Cargo vessel in oak and pine. Nordic type. Cargo vessel. All Roskilde ships found during foundation work for the Viking ship museum.',9.5,NULL,'ca',NULL,'A. Croome 1999, 382-393.'),
('Roskilde 8',NULL,775,55.650,12.079,NULL,1248,1248,'ca',NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Survey find. Dating by dendro on planks. Cargo vessel in oak and pine. Nordic type. Cargo vessel. All Roskilde ships found during foundation work for the Viking ship museum.',10.0,NULL,'ca',NULL,'A. Croome 1999, 382-393.'),
('Roskilde 9',NULL,776,55.650,12.079,NULL,1171,1171,'ca',NULL,'silted',NULL,NULL,'amphoras','Dr 1B or 1C',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Survey find. Dating by dendro on planks. Cargo vessel in oak and pine. Nordic type. Cargo vessel. All Roskilde ships found during foundation work for the Viking ship museum.',10.0,NULL,'ca',NULL,'A. Croome 1999, 382-393.'),
('Rocher de l''Estéou 1',NULL,777,43.185,5.389,NULL,-50,10,'ca',27.0,NULL,NULL,NULL,'amphoras','Joncheray 5',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Roman amphoras under Saracen ship',NULL,NULL,NULL,NULL,'S. Ximénès 1976, 139-150.'),
('Rocher de l''Estéou 2',NULL,778,43.185,5.389,NULL,800,1000,'ca',26.0,NULL,NULL,NULL,'ceramic','similar to Dr6B','lamps','Menzel (4) 661',NULL,NULL,NULL,'iron objects',NULL,'Saracen ship',NULL,NULL,NULL,NULL,'S. Ximénès 1976, 139-150.'),
('Rovinj',NULL,779,45.083,13.617,'ca',-50,100,'ca / ?',NULL,'deep',NULL,NULL,'amphoras','lead ingots',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,996,NULL),
('Runcorn',NULL,780,53.333,-2.733,NULL,80,90,'ca / ?',NULL,NULL,NULL,NULL,'tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,997,NULL),
('S. Marco in Boccalama A',NULL,781,45.389,12.282,NULL,1300,1350,NULL,2.0,NULL,NULL,NULL,'coins',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Derelict, not shipwreck. Rascona, a cargo ship. Dating based on 14C and dendro (sample origin/quality not specified). The dendrodata is not reliable.  There is evidence of a boat storage facility on site in 1328 from archival documents.',23.6,6.0,NULL,NULL,'M. D’Agostino and S. Medas 2003, 22-28.'),
('S. Marco in Boccalama B',NULL,782,45.389,12.282,NULL,1300,1350,NULL,2.0,NULL,NULL,NULL,'amphoras','Dr7-11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'First galley ever found. Graffiti found on beams in both ships',38.0,5.0,NULL,NULL,'M. D’Agostino and S. Medas 2003, 22-28.'),
('Sagunt',NULL,783,39.667,-0.200,NULL,-25,75,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Dr30 rather than Gauloise 4',NULL,NULL,NULL,NULL,NULL,'anchor stock',NULL,NULL,NULL,NULL,NULL,998,NULL),
('Saint-Florent 1?',NULL,784,42.667,9.283,NULL,200,300,'c3',37.0,NULL,NULL,NULL,'amphoras','pitch-lined pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'not yet defined as a wreck',NULL,NULL,NULL,NULL,'P. Pomey and L. Long 1993, 58; M.P. Jézégou 1998, 343-351.'),
('Saint George''s Bay',NULL,785,35.917,14.483,NULL,0,0,NULL,18.0,NULL,NULL,NULL,'amphoras','lead ingots, iron bars',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,999,NULL),
('Saint-Gervais 1',NULL,786,43.417,4.933,NULL,140,140,'ca',7.0,NULL,NULL,NULL,'amphoras','African: Keay 61 Keay 8a; 1 spatheion.  Filled with pitch and probably recycled (Pieri)','ceramic','S Gaulish terra sigillata plate',NULL,NULL,NULL,NULL,NULL,'hull',NULL,NULL,NULL,1000,NULL),
('Saint-Gervais 2',NULL,787,43.417,4.933,NULL,600,675,'ca',2.5,NULL,NULL,NULL,'nothing reported','Dr20 Beltran2B LaubenheimerG4','ceramic','N African terra sigillata chiara D, orange-painted and orange; lead-glazed pottery; grey-ware pitchers; fine eastern ceramic, everyday ceramic 1 LR 5 amph, prob = galley stores, according to Kingsley 2002, 79, citing Jézégou 1983, p. 115, and 1998, 345; slightly different appraisal in Pieri 2005, 16-19.',NULL,NULL,'2 Merovingian broaches; barrel ; wheat','pump, galley hearth, wooden sail-ring, bone marlinspike, auger, layer of pitch from ship store, amphora LR  C5 or C6 (reused?), ARS (Hayes 108, 109), Lamp 2B, some E(?) fineware, import coarseware; coin poss intrusive: semi-follis Heraclius Carthage 611/12; pewter tokens (intrusive? Gerardo certainly!)','40-50 tons','hull; shallow: probably intrusive deposits; heavily salvaged; only object found in pitch certainly from wreck (?possibly explains survival of wheat, which was the main cargo, ca 3000 modii, dumped in rear 1/3 of ship. Triticum ?turgidum L. + Agrostemma githago L. weed); total capacity 40-50 metric tons; pitch near kitchen, probably is ship''s gear; barrel bottom preserved in pitch. African cylindrical Keay 8a. (Pieri 2005, 16, claims multiple barrels [probably in error; cf. Jézégou 1998], proposes date ca. 650-700).',18.0,6.0,NULL,1001,'M.P. Jézégou 1998, 343-351; D. Pieri 2005, 16-19.'),
('Saint-Gervais 3',NULL,788,43.417,4.933,NULL,149,154,NULL,4.0,NULL,NULL,NULL,'amphoras','Dr20 Beltran2B','ceramic','basket with 9 unguentaria',NULL,NULL,NULL,NULL,NULL,'hull, mast steps, pump well, garboards, keel, keelson',17.0,6.0,'remains of hull',1002,'F. Mayet 1987, 289.'),
('Saint-Gervais 4',NULL,789,43.417,4.933,NULL,50,150,'ca / ?',6.0,NULL,NULL,NULL,'amphoras','Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'side with lead sheathing',NULL,NULL,NULL,1003,'F. Mayet 1987, 289.'),
('Saint-Honorat','Tourelle des Moines',790,43.500,7.050,NULL,160,200,'ca',20.0,NULL,NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,'anchor stock',NULL,NULL,NULL,NULL,NULL,1004,NULL),
('Saint-Hospice',NULL,791,43.683,7.350,NULL,1,500,NULL,40.0,NULL,NULL,NULL,'tiles','pottery - various types of bowls and flagons. Types comensurate with location of wreck',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1005,NULL),
('Saint Peter Port','The Roman Guernsey Boat',792,49.450,2.533,NULL,280,290,'ca',8.0,'partially silted',1982,NULL,'ceramic','marble column drums, bases, slab, architrave','coins','80 coins','tiles','roof tiles','decorative pins and fishooks, ropes; cargo was carried in many barrels','pump bearings, sail cringles, 5 pulleys','130-160m^2','dating based on dendro (oak) as well as coins minted ca 260-80',24.5,6.0,'length is estimated based on missing bow section. Possible length from 23-25m but most likely 24-25m',1007,'M. Rule and J. Monaghan 1993; E. Marlière 2002, 52-55.'),
('Saint Tropez 1',NULL,793,43.267,6.633,NULL,100,200,NULL,6.0,NULL,NULL,NULL,'amphoras','Dr2-4 ovoid',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1008,NULL),
('Saint Tropez 2',NULL,794,43.267,6.667,NULL,-25,75,'ca / ?',30.0,NULL,NULL,NULL,'amphoras','Dr20;',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1009,NULL),
('Sainte-Marguerite 2',NULL,795,43.517,7.017,'300m N of Isle',100,120,'c2 - beginning',5.0,'five meters or less',NULL,NULL,'amphoras','copper ingots','lamps','lamps round, circular reservoir, 277 well-preserved, decorated','glass','fragments',NULL,NULL,NULL,'dated from Clo Suc and Fabric Masc lamps',NULL,NULL,NULL,NULL,'P. Pomey and L. Long 1993, 51-53.'),
('Saintes-Maries-de-la-Mer 3, Les',NULL,796,43.417,4.400,NULL,100,200,NULL,18.0,NULL,NULL,NULL,'tiles','Dr20',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1013,NULL),
('Saintes-Maries 1',NULL,797,43.417,4.433,NULL,50,50,'ca',16.0,NULL,NULL,NULL,'amphoras','marble carved blocks, architrave, pilaster and plain slabs, blocks','metal','lead ingots as produced in Britain',NULL,NULL,NULL,NULL,NULL,'facing Saintes-Maries-de-la-Mer; date from amphoras: C1, perhaps Julio-Claudian or Flavian, perhaps Vespasian',NULL,NULL,NULL,NULL,'P. Pomey and L. Long 1993, 28-30.'),
('Salakta',NULL,798,35.333,11.067,NULL,200,225,NULL,5.0,NULL,NULL,NULL,'stone','grey limestone blocks',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1014,NULL),
('Salerno',NULL,799,40.650,14.767,'ca',0,0,NULL,NULL,NULL,NULL,NULL,'metal','Roman coarse pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1015,NULL),
('Saliagos',NULL,800,37.033,25.100,'ca',1,500,NULL,3.0,NULL,NULL,NULL,'grain','Dr7-11 Dr20',NULL,NULL,NULL,NULL,NULL,'ballast',NULL,NULL,NULL,NULL,NULL,1016,NULL),
('Salines, Ses','Colonia de Santi Jordi A',801,39.300,3.000,NULL,70,80,'ca',NULL,NULL,NULL,NULL,'amphoras','Dr20','metal','lead ingots, iron helmet, iron sword blad, iron bar with ring and hooks at end, bronze vessles',NULL,NULL,NULL,NULL,NULL,'lead sheathed wood, bronze nails, keel bolt',NULL,NULL,NULL,1017,NULL),
('Salou',NULL,802,41.033,1.167,'ca',50,200,NULL,NULL,NULL,NULL,NULL,'amphoras','Dr20 Dr28',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1018,NULL),
('San Nicola',NULL,803,37.933,12.333,NULL,1,100,NULL,14.0,NULL,NULL,NULL,'amphoras','Aphrodisian marble sarcophagi',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1021,NULL),
('San Pietro',NULL,804,40.300,17.667,NULL,200,250,NULL,6.0,NULL,NULL,NULL,'ceramic','iron objects, slag','amphoras','fragments','ceramic','Late Roman pottery','lead ring, lead sheet',NULL,NULL,'frames',NULL,NULL,NULL,1022,NULL),
('San Vincenzo 1',NULL,805,43.083,10.533,NULL,1300,1300,'ca / ?',NULL,'shallow',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1023,NULL),
('San Vincenzo 2',NULL,806,43.050,10.517,'ca',-300,100,NULL,NULL,'shallow',NULL,NULL,'amphoras',NULL,'stone','millstones',NULL,NULL,NULL,'lead anchor stock',NULL,NULL,NULL,NULL,NULL,1024,NULL),
('San Vito',NULL,807,38.167,12.767,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'ceramic','grooved, 3.5 liters',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1025,NULL),
('San Vito Lo Capo',NULL,808,38.190,12.736,NULL,1100,1200,'ca',20.0,NULL,NULL,NULL,'amphoras','Rhodian',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on artefacts, grooved amphoras (height 42-53 cm) narrow neck and almond lip. Three amphoras found stoppered by a cork.   Norman ship.  Discovered in the 1990s.',NULL,NULL,NULL,NULL,'http://infcom.it/subarcheo/saing.html ; F. Faccenna 1993, 185-187; G. Boetto 1995, 165.'),
('Sancak Burun',NULL,809,37.000,27.950,NULL,-25,100,NULL,36.0,NULL,NULL,NULL,'amphoras','lead, copper ingots',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'hull timbers',NULL,NULL,NULL,1026,NULL),
('Sancti Petri','El Pecio del Cobre',810,36.400,-6.217,NULL,50,100,NULL,9.0,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,'lead anchor stock',NULL,NULL,27.0,20.0,'remains',1027,NULL),
('Sanguinet',NULL,811,44.433,-1.083,NULL,150,150,'ca / ?',6.0,NULL,NULL,NULL,'nothing reported','Dr9',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dugout',3.7,NULL,NULL,1028,NULL),
('Sant Antoni',NULL,812,38.983,1.250,NULL,1,50,'ca / ?',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1029,NULL),
('Santa Cesarea',NULL,813,40.033,18.467,NULL,0,0,NULL,NULL,NULL,NULL,NULL,'amphoras','Afr2A',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1033,NULL),
('Santa Maria',NULL,814,41.283,9.383,NULL,200,300,NULL,NULL,NULL,NULL,NULL,'ceramic','blocks',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1034,NULL),
('Santa Maria: another site',NULL,815,41.283,9.383,'ca',0,0,NULL,NULL,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'P1034a',NULL,NULL,NULL,1034,NULL),
('Santa Marinella (Italy)',NULL,816,42.017,11.833,'ca',0,0,NULL,NULL,NULL,NULL,NULL,'nothing reported','Africana grande',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'P1034b',NULL,NULL,NULL,1034,NULL),
('Sant''Antioco 1',NULL,817,38.950,8.417,NULL,275,300,NULL,NULL,NULL,NULL,NULL,'nothing reported','blocks','ceramic','terra sigillata chiara D pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1030,NULL),
('Sant''Antioco 2',NULL,818,38.950,8.417,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'transport ship',NULL,NULL,NULL,1031,NULL),
('Santo Ianni',NULL,819,39.950,15.700,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'amphoras','blocks, slabs',NULL,NULL,NULL,NULL,NULL,'lead stocked anchors',NULL,NULL,NULL,NULL,NULL,1036,NULL),
('Sapientza',NULL,820,36.750,21.700,'ca',1,500,NULL,8.0,NULL,NULL,NULL,'amphoras','Almagro50 Afr2D Dr20 pear-shaped',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1037,NULL),
('Sardinia: other sites',NULL,821,40.956,9.834,'ca',200,300,NULL,NULL,'shallow',NULL,NULL,'nothing reported','Graeco-Italian',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'P1039a Symbolic coordinates. No precise location info provided. W Mediterranean hypothesized',NULL,NULL,NULL,1039,NULL),
('Savudrija',NULL,822,45.483,13.500,NULL,-140,20,'ca / ?',22.0,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1044,NULL),
('Scedro 1',NULL,823,43.083,16.667,NULL,300,400,NULL,NULL,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1045,NULL),
('Sciacca',NULL,824,37.483,13.083,'ca',1,500,NULL,NULL,NULL,NULL,NULL,'nothing reported','Panella44-47',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1047,NULL),
('Scialandro 2','Giolandio',825,38.100,12.683,NULL,1,300,NULL,NULL,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1049,NULL),
('Scoglietto',NULL,826,42.817,10.317,NULL,0,0,NULL,72.0,NULL,NULL,NULL,'nothing reported','filter jugs',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1050,NULL),
('Scoglio della Formica 2',NULL,827,38.083,13.550,NULL,800,1100,NULL,57.0,NULL,NULL,NULL,'amphoras',NULL,'lamps',NULL,'metal','iron objects',NULL,NULL,NULL,'hull remains',NULL,NULL,NULL,1053,NULL),
('Scoglitti',NULL,828,36.867,14.417,'ca',1,500,NULL,NULL,NULL,NULL,NULL,'amphoras','cylindrical',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Roman ship',NULL,NULL,NULL,1054,NULL),
('Scole 1, Le',NULL,829,42.350,10.917,NULL,365,380,'ca',52.0,NULL,NULL,NULL,'amphoras',NULL,'coins','box of coins closing with Valens (364-378)',NULL,NULL,NULL,'lead stocked and iron anchors',NULL,'hull remains',33.0,NULL,'remains',1055,NULL),
('Scole 2, Le',NULL,830,42.350,10.917,NULL,0,0,NULL,NULL,NULL,NULL,NULL,'amphoras','roof tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1056,NULL),
('Secanion, Le','L''epave de Secanion/Sequanion',831,43.533,7.100,NULL,-10,40,'ca',26.0,NULL,NULL,NULL,'amphoras','glazed bowls','amphoras','Dr20','ceramic','mortarium, coarseware pitcher, lead lid','Sestertius of 23-17 BC',NULL,NULL,NULL,NULL,NULL,NULL,1059,NULL),
('Secca del Mignone',NULL,832,42.167,11.733,'ca',1200,1300,NULL,NULL,NULL,NULL,NULL,'amphoras','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1062,NULL),
('Secca della Croce',NULL,833,42.383,10.900,NULL,1,100,NULL,40.0,NULL,NULL,NULL,'amphoras','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1064,NULL),
('Secche di Ugento 1',NULL,834,39.817,18.150,NULL,-50,100,'ca / ?',8.0,NULL,NULL,NULL,'amphoras','globular',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1066,NULL),
('Secche di Ugento 3',NULL,835,39.817,18.150,'ca',600,700,NULL,NULL,NULL,NULL,NULL,'tiles','Keay 25',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1068,'G.F. Bass 2004.'),
('Sedot Yam',NULL,836,32.483,34.883,NULL,400,600,NULL,3.0,NULL,NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1069,NULL),
('Senigallia (Italy)',NULL,837,43.717,13.217,'ca',0,0,NULL,NULL,NULL,NULL,NULL,'amphoras','broken vessels, cullet, intact vessels; weights',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'P1069b',NULL,NULL,NULL,1069,NULL),
('Serçe Limani 1',NULL,838,36.567,28.083,NULL,1025,1025,'ca',34.0,NULL,NULL,NULL,'amphoras','vessels','ceramic','Islamic glazed bowls, pots, glazed bowls','amphoras','Byzantine','wooden combs, orpiment, glasses, coin weights balance pan weights, iron swords, wooden scabbard, lead net weights, axe, spears, javelins, chessmen, gaming table, gold pendant, silver rings, tools, nails, fishing equipment','ballast, rigging pieces, 8 y-shaped anchors',NULL,'preserved hull',15.6,5.0,NULL,1070,'G.F. Bass 1979, 36-43; G.F. Bass 1981, 96-111; J.R. Steffy 1982, 13-34; G.F. Bass 1984, 42-47; G.F. Bass 1984, 64-69; G.F. Bass, F.H. van Doorninck Jr., and J.R. Steffy 1984,161-182; C. Pulak et al. 1987, 31-57; M. Jenkins 1992, 56-66; F.H. van Doorninck Jr. 1993, 8-12; F.M. Hocker 1993, 13-21.'),
('Serçe Limani Zone',NULL,839,36.000,28.000,NULL,975,1100,NULL,36.0,NULL,NULL,NULL,'amphoras','Coan',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'hull remains, nails, caulking, 70 m off shore',NULL,NULL,NULL,1074,NULL),
('Shab Rumi',NULL,840,19.000,37.000,NULL,-50,100,'ca / ?',NULL,'shallow',NULL,NULL,'marble',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1077,NULL),
('Shiant Islands',NULL,841,57.883,-6.333,NULL,1,500,NULL,0.0,NULL,NULL,NULL,'ceramic','columns',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Roman ship',NULL,NULL,NULL,1080,NULL),
('Sidi Ahmad',NULL,842,32.167,15.167,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'amphoras','Afr',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1082,NULL),
('Silba 1',NULL,843,44.383,14.683,'ca',300,425,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Rhodian',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1084,NULL),
('Silba 2',NULL,844,44.333,14.817,NULL,1,100,NULL,NULL,NULL,NULL,NULL,'amphoras','roof tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1085,NULL),
('Silba 3',NULL,845,44.383,14.683,'ca',1,500,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1086,NULL),
('Silba 4',NULL,846,44.333,14.717,NULL,500,1500,NULL,NULL,NULL,NULL,NULL,'amphoras','columns and block of green breccia, 5 ionic capitals, column base, blocks, plaque, roughly quarried, half finished of Proconnesian, half-finished colossal statue of emperor, large female bust, sarcophagus lid, stele, 2 bowls',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1087,NULL),
('Sile',NULL,847,41.183,29.633,NULL,100,125,'ca / ?',6.0,NULL,NULL,NULL,'amphoras','Byz',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'metal objects and timber from hull',NULL,NULL,NULL,1088,NULL),
('Siracusa 2',NULL,848,37.033,15.300,NULL,400,700,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1092,NULL),
('Siracusa 3',NULL,849,37.033,15.300,NULL,400,700,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1093,NULL),
('Siracusa 4',NULL,850,37.050,15.300,'ca',1,500,NULL,NULL,NULL,NULL,NULL,'amphoras','Lam2 Dr6',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1094,NULL),
('Skarda 1',NULL,851,44.283,14.683,NULL,-100,100,NULL,NULL,NULL,NULL,NULL,'amphoras','roof tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1096,NULL),
('Skarda 2',NULL,852,44.283,14.683,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1097,NULL),
('Skerki Bank 1 (A)',NULL,853,38.000,11.000,NULL,1000,1250,'end date is open ended',766.0,NULL,NULL,NULL,'nothing reported','Tripolitanian I, Dr3, biconical, Dr2-4, AC3, Pompeii X',NULL,NULL,NULL,NULL,NULL,'ballast stones (quartz and limestone)',NULL,NULL,10.0,4.0,NULL,NULL,'R.D. Ballard et al. 2000, 1596-1599; A.M. McCann and J.P. Oleson 2004, 170-178.'),
('Skerki Bank 2 (B)',NULL,854,38.000,11.000,NULL,75,100,NULL,770.0,NULL,NULL,NULL,'amphoras','Dr2, Dr 7-11, Dr9, Werff 2, flatbottomed',NULL,NULL,NULL,NULL,'organic materials','anchor stock',NULL,NULL,40.0,NULL,NULL,NULL,'R.D. Ballard et al. 2000, 1596-1599; A.M. McCann and J.P. Oleson 2004, 170-178.'),
('Skerki Bank 6 (F)',NULL,855,38.000,11.000,NULL,50,50,NULL,765.0,NULL,NULL,NULL,'amphoras','Dr28, Dr2, Dr9, flatbottomed, Werff 3','stone','marble or granite',NULL,NULL,'wheat, beans','bronze, iron anchor, pipes from pump',NULL,NULL,20.0,5.0,NULL,NULL,'A.M. McCann and J.P. Oleson 2004, 91-117.'),
('Skerki Bank 7 (G)',NULL,856,38.000,11.000,NULL,50,50,NULL,760.0,'ca',NULL,NULL,'amphoras','Dr2-4 derivative, pear-shaped',NULL,NULL,NULL,NULL,'common wares','3 lead anchor stocks, pipe, possible pump collecting tank',NULL,NULL,15.0,NULL,'ca - length can be less than 15m',NULL,'http://www.atlantikwall-research-norway.de/Touren_03_2005_S%FCdwall.html ; A.M. McCann and J.P. Oleson 2004, 118-127.'),
('Skoljic',NULL,857,44.633,14.233,NULL,50,200,NULL,36.0,NULL,NULL,NULL,'amphoras',NULL,'ceramic','fine pottery','metal','iron fireplace','cooking equipment','2 iron anchors',NULL,NULL,NULL,NULL,NULL,1098,NULL),
('Skopelos',NULL,858,39.083,23.583,NULL,1175,1200,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,'ceramic','Aegean ware with incised geometric or animal motifs or painted ware with geometric design',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1099,NULL),
('Skuldelev 1',NULL,859,55.733,12.067,NULL,1030,1050,NULL,NULL,'shallow',NULL,NULL,'stone',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating by dendro, 3 samples from planks of oak and pine. Coordinates (55º 39''N 12º 05''E from Navis I db) inaccurate.  Viking context, Nordic type.',15.9,4.8,NULL,NULL,'Navis I, Skuldelev 1, #1; O. Crumlin-Pedersen and O. Olsen 1959, 171-174; E. Friis 1964, 24-26; O. Olsen and O. Crumlin-Pedersen 1967, 73-174; W. Dammann 1983, 106; O. Crumlin-Pedersen 1986, 209-228; R. Thorseth 1986, 78-83; O. Crumlin-Pedersen 1970; O. Olsen and O. Crumlin-Pedersen 1978; O. Crumlin-Pedersen 1994, 65-72; J. Bill 1997, 388-389; O. Crumlin-Pedersen 2002, 185.'),
('Skuldelev 2/4',NULL,860,55.733,12.067,NULL,1048,1060,NULL,NULL,'shallow',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Warship, part of the blockage in Roskilde fjord; sunk on purpose with stone cargo. Dating info on db summary says after 1055 based on dendro dates, claiming oak wood of local origin. Viking context, Nordic type sail/row.',30.0,3.7,NULL,NULL,'Navis I, Skuldelev 2/4, #2; O. Crumlin-Pedersen and O. Olsen 1959; E. Friis 1964, 24-26; O. Olsen and O. Crumlin-Pedersen 1967, 73-174; O. Crumlin-Pedersen 1970; O. Olsen and O. Crumlin-Pedersen 1978; W. Dammann 1983, 106;  O. Crumlin-Pedersen 1986, 209-228; R. Thorseth 1986, 78-83; O. Crumlin-Pedersen 1994, 65-72; J. Bill 1997, 388-389; O. Crumlin-Pedersen 2002.'),
('Skuldelev 5',NULL,861,55.733,12.067,NULL,1030,1050,NULL,NULL,'shallow',NULL,NULL,'metal',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Warship, part of the blockage in Roskilde fjord; sunk on purpose; underwent major repairs on the bow. Dating based on dendro, oak, pine, ash',17.2,2.6,NULL,NULL,'Navis I, Skuldelev 5, #4; O. Crumlin-Pedersen and O. Olsen 1959; E. Friis 1964, 24-26; O. Olsen and O. Crumlin-Pedersen 1967, 73-174; O. Crumlin-Pedersen 1970; O. Olsen and O. Crumlin-Pedersen 1978; W. Dammann 1983, 106;  O. Crumlin-Pedersen 1986, 209-228; R. Thorseth 1986, 78-83; O. Crumlin-Pedersen 1994, 65-72; J. Bill 1997, 388-389; O. Crumlin-Pedersen 2002.'),
('Skuldelev 6',NULL,862,55.733,12.067,NULL,969,1041,NULL,NULL,'silted',NULL,NULL,'amphoras','Afr cylindrical, Al50, pear-shaped',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on 7 dendro dates on planks of oak/pine. Summary claims after 1027. May have been fishing/whaling vessel. Viking context, Nordic type.',11.6,2.5,NULL,NULL,'Navis I, Skuldelev 6, #5; O. Crumlin-Pedersen and O. Olsen 1959; E. Friis 1964, 24-26; O. Olsen and O. Crumlin-Pedersen 1967, 73-174; O. Crumlin-Pedersen 1970; O. Olsen and O. Crumlin-Pedersen 1978; W. Dammann 1983, 106;  O. Crumlin-Pedersen 1986, 209-228; R. Thorseth 1986, 78-83; O. Crumlin-Pedersen 1994, 65-72; J. Bill 1997, 388-389; O. Crumlin-Pedersen 2002.'),
('Sobra',NULL,863,42.717,17.600,NULL,320,340,'ca / ?',30.0,NULL,NULL,NULL,'amphoras','iron blocks','ceramic','terra sigillata chiara D, cooking pot, jug',NULL,NULL,NULL,'2 iron anchors',NULL,'lead-sheathed',25.0,NULL,NULL,1100,NULL),
('Sorres 2, Les',NULL,864,41.283,2.000,NULL,-100,200,NULL,NULL,NULL,NULL,NULL,'amphoras','Dr2-4','ceramic','coarseware jug',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1102,NULL),
('Sorres 3, Les',NULL,865,41.283,2.000,NULL,25,100,'ca / ?',NULL,NULL,NULL,NULL,'ceramic',NULL,'dolia',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1103,NULL),
('Sorres 4, Les',NULL,866,41.283,2.000,NULL,1,500,NULL,5.0,NULL,NULL,NULL,'dolia',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1104,NULL),
('Sorres 5, Les',NULL,867,41.283,2.000,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1105,NULL),
('Sorres 6, Les',NULL,868,41.283,2.000,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'amphoras','Günsenin3',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1106,NULL),
('Sporades 2',NULL,869,39.167,23.750,'ca',1000,1200,NULL,50.0,NULL,NULL,NULL,'amphoras','Günsenin3',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,20.0,5.0,'remains',1100,NULL),
('Sporades 3',NULL,870,39.167,23.750,'ca',1000,1200,NULL,50.0,NULL,NULL,NULL,'amphoras','from LA to 15th c. spread all over the site',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,20.0,5.0,'remains',1101,NULL),
('Saint Peter port (Guernsey) 2',NULL,871,49.467,-2.527,NULL,0,0,NULL,NULL,'shallow',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'clinker built, still has keel, floor and keelson.',NULL,NULL,NULL,NULL,'J. Adams and J. Black 2004, 230-252.'),
('Saint Peter port (Guernsey) 4',NULL,872,49.467,-2.527,NULL,0,0,NULL,NULL,'shallow',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,'from LA to 15th c. spread all over the site',NULL,NULL,'dendro attempted but no results: too little of the hull left.',NULL,NULL,NULL,NULL,'J. Adams and J. Black 2004, 230-252.'),
('Saint Peter port (Guernsey) 5',NULL,873,49.467,-2.527,NULL,1200,1300,'ca',NULL,'shallow',NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,'from LA to 15th c. spread all over the site','ballast',NULL,'mortice and tenon',NULL,NULL,NULL,NULL,'J. Adams and J. Black 2004, 230-252.'),
('Saint Peter port (Guernsey) 6',NULL,874,49.467,-2.527,NULL,1229,1261,NULL,1.5,NULL,NULL,NULL,'tiles',NULL,NULL,NULL,NULL,NULL,'from LA to 15th c. spread all over the site',NULL,NULL,'dendro dated',NULL,NULL,NULL,NULL,'J. Adams and J. Black 2004, 230-252.'),
('Strasbourg (France) 1',NULL,875,48.587,7.801,'ca',1,200,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'P1114ai wooden raft',12.5,NULL,NULL,1114,NULL),
('Strasbourg (France) 2',NULL,876,48.587,7.801,'ca',1,200,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'P1114aii wooden raft',7.5,NULL,NULL,1114,NULL),
('Straton''s Tower',NULL,877,32.500,34.883,NULL,50,50,'ca / ?',3.0,NULL,NULL,NULL,'metal','roof tiles','metal','legs of folding bronze table; silver rings; balance scales',NULL,NULL,NULL,'bilge pump, sail rings, ropes',NULL,'hull, C14 mid: 1st felling',45.0,9.0,NULL,1115,NULL),
('Sud Camarat',NULL,878,43.183,6.683,'ca',1,300,NULL,NULL,NULL,NULL,NULL,'amphoras','Almagro51A flat-bottomed Almagro51C Beltran72 Dr23',NULL,NULL,NULL,NULL,NULL,'part of iron anchor',NULL,NULL,NULL,NULL,NULL,1116,NULL),
('Sud-Lavezzi 1',NULL,879,41.300,9.250,NULL,375,425,'ca / ?',36.0,NULL,NULL,NULL,'amphoras','Haltern70 Dr7-11 Dr20 Dr28',NULL,NULL,NULL,NULL,NULL,'anchors',NULL,'timbers',NULL,NULL,NULL,1117,NULL),
('Sud-Lavezzi 2',NULL,880,41.300,9.250,NULL,10,30,NULL,42.0,NULL,NULL,NULL,'amphoras','Dr2-4 Pascual1 Dr14','metal','copper, lead ingots','ceramic','Arretine pottery',NULL,'9 anchors',NULL,NULL,23.8,NULL,'or less',1118,NULL),
('Sud-Lavezzi 3',NULL,881,41.317,9.250,NULL,15,25,'ca / ?',38.0,NULL,NULL,NULL,'amphoras','Dr12',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1119,NULL),
('Sud-Perduto 1',NULL,882,41.333,9.300,NULL,-25,25,'ca / ?',70.0,NULL,NULL,NULL,'lamps','Dr7 Dr9 flat-bottomed Dr12 Longarina2 Oberaden83',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1120,NULL),
('Sud-Perduto 2',NULL,883,41.333,9.300,NULL,1,15,'ca / ?',48.0,NULL,NULL,NULL,'amphoras',NULL,'metal','lead ingots',NULL,NULL,NULL,NULL,NULL,'mast step',16.0,5.0,'remains',1121,NULL),
('Sulcis',NULL,884,39.067,8.467,NULL,1,500,NULL,NULL,'silted',NULL,NULL,'stone','roof tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'planking, keel, nails',23.0,7.0,NULL,1122,NULL),
('Susak',NULL,885,44.500,14.300,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1123,NULL),
('Sutton Hoo',NULL,886,52.080,1.325,NULL,600,700,'ca',NULL,'silted',NULL,NULL,'amphoras','Dr2-4 Richborough527',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on coin and context.  Ship is Anglo-Saxon and is situated in a graveyard, contains a burial chamber attributed to East Anglian King Raedwald.',27.0,4.5,NULL,NULL,'Navis I, Sutton Hoo, #91; C. Green 1963; P. Johnstone and P. Brand 1974, 102-114; A.C. Evans 1975; O. Crumlin-Pedersen and F. Rieck 1988, 139; A.E. Christensen 1996, 78.'),
('Sveti Andrija',NULL,887,43.017,15.750,NULL,1,150,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Arab',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1124,NULL),
('Syria',NULL,888,36.000,35.000,'ca',800,900,NULL,35.0,NULL,NULL,NULL,'amphoras','35 bronze vessels','ceramic','jars',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1125,NULL),
('Szazhalombatta',NULL,889,47.417,18.833,NULL,1,200,NULL,NULL,NULL,NULL,NULL,'tiles',NULL,'ceramic','pottery',NULL,NULL,'cooking equipment',NULL,NULL,'Roman boat',NULL,NULL,NULL,1126,NULL),
('Szczecin',NULL,890,55.500,14.467,NULL,787,891,NULL,NULL,'silted',NULL,NULL,'metal','Günsenin3',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on 15 dendro dates on oak plank, ranging 787-891.  4 early 14C dates show range 510-670 with average 65 years margin.   One later 14C sample from luting moss showed 840 with a margin of 70 years.  Slavonic, oak, pine, working boat.',8.3,2.1,NULL,NULL,'Navis I, Szczecin, #136; Wieczorowski 1962; S. Weso?owski 1963, 254-258; M. Rulewicz 1986, 48-59; W. Filipowiak 1994, 83-96; M.F. Pazdur et al. 1994, 127-195; W. Filipowiak 1996, 91-96; M. Rulewicz 1996, 79-90; N. Bonde, T. Wazny, and A. Daly 1999.'),
('Tainaron',NULL,891,36.383,22.483,NULL,1200,1300,NULL,NULL,NULL,NULL,NULL,'amphoras','Dr7-11 Dr38',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1128,NULL),
('Tanger 2',NULL,892,35.800,5.817,'ca',1,100,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1130,NULL),
('Tantura Arab',NULL,893,32.600,34.900,NULL,700,900,'ca',NULL,'shallow',NULL,NULL,'amphoras','LR5 (Byzantine bag shaped)',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Amphoras were found amidships and are basis for date.  Not clear if this wreck is related to any of the other Tantura/Dor wrecks, but authors remarked it was the last to be found among the 9 wrecks in the lagoon and was not excavated until 1999, which would suggest this is not a duplicate of any of the other wrecks.  Authors do not specify a precise wreck number or ID.',NULL,NULL,NULL,NULL,'J.G. Royal 2006, 3-11; J.G. Royal 2006, 195-217; J. Leidwanger 2007, 308-316.'),
('Tantura lagoon A (Dor J)','Dor J',894,32.610,34.916,NULL,500,600,'ca',NULL,'shallow',NULL,NULL,'amphoras','Abbasid-period oil lamp','ceramic','sherds glued to the hull with resin',NULL,NULL,NULL,'stone anchor',NULL,'25% hull of small coaster; 14C dates wreck to C6; ballast, keel, post, stakes, frames, nail and bolt attachments, caulking in seams. 7 other shipwrecks, one Roman, another a ?galley, not precisely dated are in the same area. 14C dated according to BAR publication',12.0,NULL,NULL,NULL,'G. Dahl 1915; S. Wachsmann and K. Raveh 1984, 223-241; E. Stern 1993, 22-31, 76,78; E. Stern 1993, 18-29; E. Stern 1993, 38-49; J.R. Steffy 1994; E. Stern 1994; B.M. Bryant 1995, 18-19; Y. Carmi and D. Segal 1995, 12; W.H. Charlton 1995, 17; Y.Kahanov and S. Breitstein 1995; Y. Kahanov and S. Breitstein 1995, 9-13; P. Sibella 1995, 13-16; P. Sibella 1995, 19-20; S. Wachsmann 1995; S. Wachsmann 1995, 3-20; Y. Kahanov and J.G. Royal 1996, 21-23; S. Wachsmann 1996, 17-21; S. Wachsmann 1996, 19-23; “Field Notes” 1997, 103-109; P. Sibella 1997, 16-18; S. Wachsmann and Y. Kahanov 1997, 3-18;  S. Wachsmann, Y. Kahanov, and J. Hall 1997, 3-15; S. Kampbell 2006, 7-10; S. Kingsley 2002, 4; S. Kingsley 2004, 39.'),
('Tantura Lagoon B',NULL,895,32.610,34.916,NULL,800,850,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,'rigging elements, rope',NULL,'C14 (680-850AD) done in the vicinity but not clear from which of the 7 wrecks the sample came from. Dendro is problematic',30.0,NULL,'ca',NULL,'G.F. Bass 1963, 138-156; G.F. Bass 1975; G.F. Bass and F.H. van Doorninck 1982; P. Throckmorton 1987; F.H. van Doorninck Jr. 1997, 105-120; S. Wachsmann, Y. Kahanov, and J. Hall 1997,13-15; S. Kingsley 2004, 39.'),
('Tantura Lagoon E',NULL,896,32.600,34.900,NULL,550,650,NULL,3.0,NULL,NULL,NULL,'amphoras','8 some similar to Yassiada (LR1, but one handle)',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating by C14',NULL,NULL,NULL,NULL,'S. Kampbell 2006, 7-10; O. Barkai and Y. Kahanov 2007, 21-31.'),
('Tantura Lagoon F',NULL,897,32.600,34.900,NULL,700,750,'ca',1.0,NULL,NULL,NULL,'amphoras','millstones','ceramic','20 for storage (with fish bone remnants) similar to Cesarea stratum 8, Pella, Jordan, Israeli coast from C7','ceramic','2 juglets similar to ones found at Kellia and Nile delta from C7',NULL,'two anchors, rope, reed, wooden spoon, bone needle; fish bones and food remnants (olive pits from central mountains of Israel).',NULL,'70m offshore. Dating by 14C (wood is tamarix, pinus brutia, pinus nigra; tamarix from mod. Turkey)',12.0,3.5,'ca',NULL,'S. Kampbell 2006, 7-10; O. Barkai and Y. Kahanov 2007, 21-31.'),
('Taranto 1',NULL,898,40.267,17.583,NULL,400,650,'ca / ?',NULL,NULL,NULL,NULL,'nothing reported','Coan Rhodian',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1131,NULL),
('Taranto 3',NULL,899,40.367,17.367,NULL,1,100,NULL,NULL,'shallow',NULL,NULL,'nothing reported','Dr7-11','ceramic','roof tiles',NULL,NULL,NULL,'5 lead anchor stocks',NULL,NULL,NULL,NULL,NULL,1133,NULL),
('Tarragona (Spain)',NULL,900,41.104,1.279,NULL,0,0,NULL,NULL,NULL,NULL,NULL,'marble','Günsenin3',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'The record is only for a an amphora brought back by a fishing vessel. Coordinates purely symbolic',NULL,NULL,NULL,1135,NULL),
('Tartus',NULL,901,35.900,35.883,'ca',1000,1200,NULL,NULL,NULL,NULL,NULL,'amphoras','Riley LR8b',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1136,NULL),
('Tcerny Nos',NULL,902,43.167,27.983,'ca',375,500,NULL,NULL,NULL,NULL,NULL,'marble','roof tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1137,NULL),
('Tekmezar 3','ekmezar Burnu',903,40.641,27.524,NULL,1000,1100,NULL,8.0,NULL,NULL,NULL,'amphoras','copper ingots','ceramic','glazed bowls',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1138,'N. Günsenin 2002,129 n8.'),
('Tel Kara (Israel)',NULL,904,32.767,34.950,NULL,0,0,NULL,NULL,NULL,NULL,NULL,'amphoras','Günsenin1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Unpublished. Coordinates close to Parker''s indication of Kefar Gallim, near location of the site.',NULL,NULL,NULL,1138,NULL),
('Tenedos',NULL,905,39.833,26.083,'ca',1000,1100,NULL,NULL,NULL,NULL,NULL,'amphoras','Dr8 Dr9 Camulodunum186A Haltern 70',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1139,NULL),
('Terrasini 1',NULL,906,38.150,13.083,NULL,25,50,'ca / ?',3.0,NULL,NULL,NULL,'marble','Kapitän1 Kapitän2','metal','copper ingots','marble','bowl','2 swords, hand mill, axe',NULL,NULL,'wood fragments, copper nails, lead sheathing, tiles',NULL,NULL,NULL,1141,NULL),
('Terrauzza',NULL,907,37.000,15.317,NULL,200,200,'ca',4.0,NULL,NULL,NULL,'stone','Byzantine globular','ceramic','table pottery','glass','bottle',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1143,NULL),
('Thalassinies Spilies',NULL,908,34.867,32.317,NULL,500,700,NULL,NULL,'shallow',NULL,NULL,'amphoras','LR/Byzantine',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1145,NULL),
('Thasos 1',NULL,909,40.767,24.700,NULL,400,600,NULL,NULL,'shallow',NULL,NULL,'stone','Dr20 Dr28 Dr14 Beltran2A Beltran 2B Dr2-4 LaubenheimerG4 Pelichet 47',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1146,NULL),
('Tiboulen de Maïre',NULL,910,43.200,5.317,NULL,100,100,'ca',54.0,NULL,NULL,NULL,'stone',NULL,'ceramic','coarse pottery',NULL,NULL,NULL,NULL,NULL,'remains of hull, copper keel bolt',NULL,NULL,NULL,1148,NULL),
('Tiel 1',NULL,911,51.900,5.417,NULL,900,1000,'ca',NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Cargo, sailed? oak vessel, type Utrecht 3.  Part of ship was used as revetment. Claims precise date of 980 on database but no evidence provided.',NULL,NULL,NULL,NULL,'Navis I, Tiel 1, #62; K. Vlierman 1996.'),
('Tiel 2',NULL,912,51.900,5.417,NULL,900,1000,'ca',NULL,'silted',NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Cargo sailed? oak vessel.  Part of Ship used as rivetment. Claims precise date of 991, but no evidence provided.',NULL,NULL,NULL,NULL,'Navis I, Tiel 2, #63; K. Vlierman 1996.'),
('Tiel 3',NULL,913,51.900,5.417,NULL,1000,1100,'ca',NULL,'silted',NULL,NULL,'amphoras','cf Dr9',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Cargo, Nordic type oak vessel, sailed. claims a precise date of 1008 on db, but no evidence provided.',NULL,NULL,NULL,NULL,'Navis I, Tiel 3, #64; K. Vlierman 1997'),
('Toro, El',NULL,914,39.450,2.467,NULL,1,50,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1150,NULL),
('Torre Castellucia 1',NULL,915,40.333,17.383,NULL,200,300,NULL,2.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'hull',17.0,2.4,'lenght can be less than 17',1151,NULL),
('Torre Castellucia 2',NULL,916,40.333,17.383,NULL,200,300,NULL,2.0,NULL,NULL,NULL,'amphoras','cipollino columns',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'hull',NULL,NULL,NULL,1152,NULL),
('Torre Chianca',NULL,917,40.267,17.883,NULL,250,250,'ca / ?',6.0,NULL,NULL,NULL,'amphoras','Dr41 or 42, Afr2 or cylindrical','amphoras','Dr43 derived',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1153,NULL),
('Torre dell''Orso',NULL,918,40.267,18.433,NULL,200,400,NULL,10.0,NULL,NULL,NULL,'amphoras','columns',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1154,NULL),
('Torre Flavia 1',NULL,919,41.950,12.033,NULL,1,500,NULL,5.0,NULL,NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,'lead rings',NULL,'wood, copper nails',NULL,NULL,NULL,1157,NULL),
('Torre Flavia 2',NULL,920,41.917,12.000,NULL,0,0,NULL,25.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'remains of hull',NULL,NULL,NULL,1158,NULL),
('Torre Hidalgo (Italy)',NULL,921,42.800,10.733,'ca',0,0,NULL,NULL,NULL,NULL,NULL,'tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'wooden hull',NULL,NULL,NULL,1159,NULL),
('Torre San Gennaro',NULL,922,40.533,18.050,NULL,1100,1200,NULL,16.0,NULL,NULL,NULL,'coins','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1161,NULL),
('Torre Santa Sabina',NULL,923,40.750,17.700,NULL,-25,25,NULL,6.0,NULL,NULL,NULL,'amphoras','sarcophagi, blocks, veneer','ceramic','pottery',NULL,NULL,NULL,NULL,NULL,'keel, planking',NULL,NULL,NULL,1162,NULL),
('Torre Sgarrata',NULL,924,40.317,17.400,NULL,180,205,'ca',11.0,NULL,NULL,NULL,'amphoras','Lava millstone','amphoras','Tripolitanian','ceramic','Candarli and other pottery','tile fragments, mason''s mallet, counters, glass vessel fragments, cuirass buckle, coins ending with Commodus (180-192).',NULL,NULL,'patched ship, 14C: 77 BC+/-43',30.0,NULL,NULL,1163,NULL),
('Torre Testa',NULL,925,40.683,17.867,NULL,0,0,NULL,NULL,'shallow',NULL,NULL,'amphoras','Dr2-4 Dr7-11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'frames',NULL,NULL,NULL,1164,NULL),
('Torre Valdaliga',NULL,926,42.133,11.733,NULL,1,20,'ca',10.0,NULL,NULL,NULL,'amphoras','blocks','ceramic','Arretine pottery',NULL,NULL,NULL,'lead anchor stock',NULL,NULL,NULL,NULL,NULL,1165,NULL),
('Toulon 1',NULL,927,43.117,5.933,NULL,1,100,NULL,NULL,NULL,NULL,NULL,'amphoras','blocks',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'small Roman boat',NULL,NULL,NULL,1166,NULL),
('Toulon 2',NULL,928,43.117,5.933,NULL,1,100,NULL,NULL,NULL,NULL,NULL,'nothing reported','Dr7-11 Dr12 Beltran2A Haltern70',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'small Roman boat',NULL,NULL,NULL,1167,NULL),
('Tour Sainte Marie 1',NULL,929,43.000,9.483,NULL,30,55,'ca',55.0,NULL,NULL,NULL,'amphoras','Gallo-Roman vases','ceramic','mortarium','tiles','tile fragment','part of schist flagstone',NULL,NULL,NULL,NULL,NULL,NULL,1171,NULL),
('Tours',NULL,930,47.383,0.700,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'amphoras','Panella33',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1173,NULL),
('Trapani',NULL,931,38.033,12.467,NULL,200,300,NULL,NULL,NULL,NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1175,NULL),
('Tre Fontane (Italy)',NULL,932,37.567,12.717,'ca',0,0,NULL,NULL,NULL,NULL,NULL,'tiles','spatheia cylindrical',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'ships and cargoes',NULL,NULL,NULL,1175,NULL),
('Triscina 3',NULL,933,37.567,12.783,NULL,400,500,NULL,3.0,NULL,NULL,NULL,'ceramic','Beltran2B',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1179,NULL),
('Triscina 4',NULL,934,37.567,12.783,NULL,25,125,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Beltran2B',NULL,NULL,NULL,NULL,'barrels with iron hoops',NULL,NULL,NULL,NULL,NULL,NULL,1180,NULL),
('Tuna, Sa',NULL,935,41.950,3.217,'ca',100,200,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1182,NULL),
('Tune',NULL,936,59.200,11.283,'ca',910,910,NULL,NULL,'silted',NULL,NULL,'amphoras','Kapitän1 Kapitän2',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on dendro. Military oared/sailed Nordic oak and pine ship. Later used as a burial ship.  Found in a mound on a farm.',20.0,4.4,NULL,NULL,'Navis I, Tune, #183; Shetelig 1917; A.W. Brøgger and H. Shetelig 1951; S. Marstrander 1973, 26-38; A.E. Christensen 1980; N. Bonde and A.E. Christensen 1993, 575-583; N. Bonde 1994; A. Sinclair, E. Slater, and J. Gowlett 1997.'),
('Turkey',NULL,937,36.917,27.333,'ca',200,300,NULL,NULL,NULL,NULL,NULL,'tiles',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1183,NULL),
('Tyre 2',NULL,938,33.250,35.167,NULL,1,100,NULL,NULL,'shallow',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1185,NULL),
('Tyre 3',NULL,939,33.250,35.167,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'stone','glazed pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1186,NULL),
('Tyre 7',NULL,940,33.267,35.200,'ca',500,1500,NULL,NULL,NULL,NULL,NULL,'metal','Pascual1','stone','millstones',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1191,NULL),
('Ullastres, Los',NULL,941,41.883,3.200,NULL,-50,25,'ca',52.0,NULL,NULL,NULL,'grain',NULL,NULL,NULL,NULL,NULL,NULL,'iron anchor, pump',NULL,'planking, frames',18.0,NULL,NULL,1192,NULL),
('Ulu Burun Area',NULL,942,36.133,29.683,'ca',1000,1200,NULL,42.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,'y-shaped anchor',NULL,NULL,NULL,NULL,NULL,1194,NULL),
('Utrecht 1',NULL,943,52.083,5.133,NULL,998,998,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on oak dendro dates.  Cargo, large sailed vessel.',NULL,NULL,NULL,NULL,'Navis I, Utrecht 1, #66; E. von der Porten 1963; Philipsen 1965; D. Ellmers 1972, 292-293; T. Hoekstra 1975, 390-391; Hoekstra 1976; M.D. de Weerd 1987, 147-169; R. Vlek 1987; M.D. de Weerd 1991, 5-16; M.D. de Weerd 1991, 28-31; F.M. Hocker 1997, 435; K. Vlierman 1997, 88-91.'),
('Utrecht 2',NULL,944,52.083,5.133,NULL,1100,1200,'ca',NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Type is Utrecht 1 in medieval context. Sailed? oak and pine vessel',13.0,3.0,NULL,NULL,'Navis I, Utrecht 2, #67; E. von der Porten 1963; J. Philipsen 1965; D. Ellmers 1972, 292-293; T. Hoekstra 1975, 390-391; T. Hoekstra 1976; M.D. de Weerd 1987, 147-169; R. Vlek 1987; M.D. de Weerd 1991; M.D. de Weerd 1991, 28-31; F.M Hocker 1997, 435; K. Vlierman 1997, 88-91.'),
('Utrecht 3',NULL,945,52.083,5.133,NULL,1198,1010,'ca',NULL,'silted',NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Oak sailed? Cargo vessel in medieval context. Dating method not specified on Navis db, but range given between 998 and 1010 suggesting dendro.',NULL,NULL,NULL,NULL,'Navis I, Utrecht 3, #68; E. von der Porten 1963; J. Philipsen 1965; D. Ellmers 1972; 292-293; T. Hoekstra 1975, 390-391; T. Hoekstra 1976; M.D. de Weerd 1987.147-169; R. Vlek 1987; M.D. de Weerd 1991, 5-16; M.D. de Weerd 1991, 28-31; F.M.Hocker 1997, 435; K. Vlierman 1997, 88-91.'),
('Utrecht 4',NULL,946,52.083,5.133,NULL,0,0,NULL,NULL,'silted (?)',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Oak cargo vessel in medieval context. No dating info provided in db. Construction similar to previous Utrecht types (shell first, clinker; rivet).',NULL,NULL,NULL,NULL,'Navis I, Utrecht 4, #69; E. von der Porten 1963; J. Philipsen 1965; D. Ellmers 1972, 292-293; T. Hoekstra 1975, 390-391; T. Hoekstra 1976; M.D. de Weerd 1987, 147-169; R. Vlek 1987; M.D. de Weerd 1991, 5-16; M.D. de Weerd 1991, 28-31; F.M. Hocker 1997, 435; K. Vlierman 1997, 88-91.'),
('Utrecht 5',NULL,947,52.083,5.133,NULL,1100,1200,'ca',NULL,'silted',NULL,NULL,'amphoras','coins of Constantine',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Oak sailed? cargo vessel,  Utrecht 1 type.  No precise dating available on db.',NULL,NULL,NULL,NULL,'Navis I, Utrecht 5, #70; E. von der Porten 1963; J. Philipsen 1965; D. Ellmers 1972, 292-293; T. Hoekstra 1975, 390-391; T. Hoekstra 1976; M.D. de Weerd 1987,147-169; R. Vlek 1987; M.D. de Weerd 1991, 5-16; M.D. de Weerd 1991, 28-31;   F.M. Hocker 1997, 435;  K. Vlierman 1997, 88-91.'),
('Vacchetta 2',NULL,948,41.350,9.217,NULL,320,340,'ca',NULL,NULL,NULL,NULL,'ceramic','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1198,NULL),
('Vachetta 1',NULL,949,41.350,9.217,NULL,1,75,'ca / ?',NULL,NULL,NULL,NULL,'amphoras','Dr2-4','metal','copper or bronze nails, small lead bar',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1197,NULL),
('Vada 3',NULL,950,43.333,10.350,NULL,1,100,NULL,23.0,NULL,NULL,NULL,'amphoras','Dr7-11',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1201,NULL),
('Vada 4',NULL,951,43.300,10.350,NULL,1,100,NULL,70.0,NULL,NULL,NULL,'nothing reported','(?)',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1202,NULL),
('Valencia',NULL,952,38.800,0.200,'ca',1,500,NULL,NULL,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,'lead anchor stock',NULL,'bronze nails, lead pieces',NULL,NULL,NULL,1203,NULL),
('Valle Isola 1',NULL,953,44.667,12.217,NULL,1,300,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dugout',14.7,NULL,NULL,1204,NULL),
('Valle Isola 2',NULL,954,44.667,12.217,NULL,1,300,NULL,NULL,NULL,NULL,NULL,'amphoras','large LR Zeest 80',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'dugout',12.1,NULL,NULL,1205,NULL),
('Varna',NULL,955,43.117,27.950,NULL,400,500,'ca',NULL,NULL,NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'amphoras now in Varna Archaeological Museum; from Black Sea? wine?',NULL,NULL,NULL,1208,'V.G. Swan 2007, 258 n7.'),
('Vechten',NULL,956,52.067,5.200,NULL,1,100,NULL,NULL,'silted',NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'boat',12.0,3.0,NULL,1210,NULL),
('Velsen 1',NULL,957,52.450,4.650,NULL,1050,1175,NULL,NULL,'silted',NULL,NULL,'nothing reported','Riley LR2 spatheion Keay53',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on 14C. Oak paddled vessel of Utrecht 1 type in medieval context.',6.5,NULL,NULL,NULL,'Navis I, Velsen 1, #74; D. Ellmers 1972, 294; J. Morel and M.D. de Weerd 1981, 70-71; M.D. de Weerd 1987, 147-169; M.D. de Weerd 1990, 75; B. Arnold 1996,158; K. Vlierman 1997, 100-101.'),
('Vendicari',NULL,958,36.800,15.100,NULL,375,625,'ca',7.0,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1211,NULL),
('Ventotene: other sites',NULL,959,40.793,13.434,NULL,200,300,NULL,NULL,NULL,NULL,NULL,'amphoras','Central Gaulish terra sigillata',NULL,NULL,NULL,NULL,NULL,'lead anchor stock',NULL,NULL,NULL,NULL,NULL,1213,NULL),
('Vichy',NULL,960,46.083,3.250,NULL,100,150,'ca',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'timbers',NULL,NULL,NULL,1214,NULL),
('Vieste',NULL,961,41.833,16.200,NULL,500,1500,NULL,NULL,NULL,NULL,NULL,'amphoras','Aegean pottery: casseroles, plates, frying pans, bowls, jugs, lids, grills',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1215,NULL),
('Viganj',NULL,962,42.967,17.117,NULL,100,200,NULL,30.0,NULL,NULL,NULL,'nothing reported','LR cylindrical',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'preserved hull',NULL,NULL,NULL,1216,NULL),
('Vignale',NULL,963,42.000,9.483,NULL,307,310,'ca',13.0,NULL,NULL,NULL,'nothing reported','Dr20 G4','metal','bronze pitcher handle','coins','large bronze coin hoard: mostly Maxentius, ends with Constantine',NULL,NULL,NULL,NULL,NULL,NULL,NULL,1217,NULL),
('Villepey',NULL,964,43.400,6.700,NULL,110,160,'ca / ?',NULL,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,'iron anchor',NULL,'frame with nails',NULL,NULL,NULL,1219,NULL),
('Vis 5',NULL,965,43.050,16.250,NULL,400,600,NULL,NULL,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1224,NULL),
('Vis 6',NULL,966,43.067,16.200,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1225,NULL),
('Vis 7',NULL,967,43.000,16.050,NULL,1,500,NULL,NULL,NULL,NULL,NULL,'nothing reported','millstones',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1226,NULL),
('Wantzenau',NULL,968,48.667,7.833,NULL,275,300,NULL,NULL,NULL,NULL,NULL,'amphoras','tin plates, tin sculpture of three communion wafers with images of pilgrims','metal','3 bronze vessels, axe-hammer, drill',NULL,NULL,NULL,'leaden end of sounding pole',NULL,'hull, punting, iron-mounted pole',6.5,NULL,NULL,1231,NULL),
('Wismar-Wendorf',NULL,969,53.906,11.441,NULL,1476,1476,NULL,1.5,NULL,NULL,NULL,'amphoras','grain poss= spelt; hazel nuts; weeds suggests grain came limy loam soil, e.g. from mod. Belgium or Luxemburg; had been stored for some time before shipping',NULL,NULL,NULL,NULL,NULL,'stove w/ bricks, board game',NULL,'dendro dated; wood from area around Riga.',18.0,7.0,'ca',NULL,'T. Förster 2000.'),
('Woerden 1',NULL,970,52.100,4.867,NULL,170,175,'ca',NULL,'silted',1978,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,'no sign of sacks, containers','stone with/bricks, pottery, 4 pairs of hobnailed sandals',NULL,'river boat, frames, planks, mast-step, fireplace, dendrodated: 169 AD; ceramic a bit later; sandals C3 early, and indicated at least 3 adult crew members; many repairs. Presumably grain transport for Roman fort on site.',27.0,3.0,'ca',1232,NULL),
('Woerden 2',NULL,971,52.083,4.900,NULL,0,0,NULL,NULL,'silted',1988,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Roman river boat similar to Woerden 1, oak sailed vessel in Roman context. No dating in db.',20.0,3.1,NULL,NULL,'Navis I, Woerden 2, #14; M.D. de Weerd 1988, 148-155; M.D. de Weerd 1990, 75; L.T. Lehmann 1991, 24-27; S. McGrail 1995, 139-145; J.K. Haalebos, C. van Driel Murray, and M. Neyses 1996, 498-499.'),
('Woerden 3',NULL,972,52.083,4.900,NULL,100,300,'ca',NULL,'silted',1988,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating apparently based on ceramics. Sailed Zwammerdam 3 type oak vessel, working boat?, in Roman context.',12.0,1.3,NULL,NULL,'Navis I, Woerden 3, #15; M.D. de Weerd 1988, 148-155; M.D. de Weerd 1990, 75; L.T. Lehmann 1991, 24-27; J.K. Haalebos, C. van Driel Murray, and M. Neyses 1996, 498-499; S. McGrail and O. Roberts 1999, 139-145.'),
('Woerden 5',NULL,973,52.083,4.900,NULL,1,100,'ca',NULL,'silted',1998,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating apparently based on ceramics. Towed Zwammerdam 5-type oak vessel, fishing boat, in Roman context; later reused as a fishwell.  Discovered 1998. For a possible fourth Roman wreck, see Haalebos et al 1996, 499.',NULL,0.5,NULL,NULL,'Navis I, Woerden 5, #96.'),
('Woerden 6',NULL,974,52.083,4.900,NULL,200,300,'ca',NULL,'silted',NULL,NULL,'amphoras','Carrot shaped, Byz  4th-5th c. ( particular of Sinop)',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Unpublished because of sudden death of excavator (J.-K. Haalebos).  Possibly part of Woerden 2 b/c of proximity.  Recovered fragment is 80 cm x 1.3m prow block of an oak, sailed, Roman cargo ship. Shows many similarities with De Meern 1. Dating based apparently on ceramics, according to db data.',NULL,NULL,NULL,NULL,'Navis I, Woerden 6, #97.'),
('W-Sinop A',NULL,975,42.197,34.750,NULL,300,599,'ca',101.0,NULL,NULL,NULL,'amphoras','LR1 (like Yassiada) and Carrot shaped, Byz  4th-5th c. (particular of Sinop)',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Survey. No dating beyond amphora types.',20.0,10.0,'ca',NULL,'C. Ward 2001, 15; C. Ward and R.D. Ballard 2004, 2-13.'),
('W-Sinop B',NULL,976,42.197,34.750,NULL,300,599,'ca',85.0,NULL,NULL,NULL,'tiles','Carrot shaped, Byzantine  4th-5th c. (particular of Sinop)',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Survey. No dating beyond amphora types.',24.0,12.0,'ca',NULL,'C. Ward 2001, 15; C. Ward and R.D. Ballard 2004, 2-13.'),
('W-Sinop C',NULL,977,42.197,34.750,NULL,300,599,'ca',85.0,NULL,NULL,NULL,'ceramic','one ancient jug',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Survey. No dating beyond amphora types.',NULL,NULL,NULL,NULL,'C. Ward and R.D. Ballard 2004, 2-13.'),
('W-Sinop D',NULL,978,42.197,34.750,NULL,410,520,NULL,320.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,'wooden mast 11m completely preserved most likely for lateen sail, pins',NULL,'Survey 14C date= 1610±40 (Beta-147532) calibrated to 410-520 AD from fir wood, from rudder support. Other wood also oak. Much of the hull is intact thanks to deep conditions. 25 km N of Sinop.  No evidence of how it was put together.',13.0,NULL,'ca',NULL,'C. Ward and R.D. Ballard 2004, 2-13.'),
('Xanten Lower Rhine',NULL,979,51.650,6.433,NULL,600,950,'ca',NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Survey. Carolingian riverboat, published in survey news along with the other Xanten boats.  The Carolingian boat was mentioned in passing.',NULL,NULL,NULL,NULL,'H. Schlichtherle and W. Kramer 1996, 146.'),
('Xanten-Lüttingen',NULL,980,51.650,6.433,NULL,275,275,NULL,NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on oak dendro dates. Cargo vessel. Roman context',35.0,4.9,NULL,NULL,'Navis I, Xanten-Luettingen, #123; W. Böcking 1996, 209-215; H. Schlichtherle and W. Kramer 1996, 141-151.'),
('Xanten-Wardt',NULL,981,51.650,6.433,NULL,1,100,NULL,NULL,'silted',NULL,NULL,'marble','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on dendro. Cargo vessel, Roman context',NULL,NULL,NULL,NULL,'Navis I, Xanten-Wardt, #124; W. Böcking 1996, 209-215; H. Schlichtherle and W. Kramer 1996, 141-151.'),
('Xlendi 2',NULL,982,36.017,14.200,NULL,1,100,NULL,NULL,NULL,NULL,NULL,'ceramic','Keay25',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1235,'S. van Doorninck Jr. 2004, 48.'),
('Xlendi 3',NULL,983,36.017,14.200,NULL,350,450,'ca / ?',30.0,NULL,NULL,NULL,'amphoras','coarseware jugs',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1236,NULL),
('Xlendi 4',NULL,984,36.017,14.200,NULL,0,0,NULL,30.0,NULL,NULL,NULL,'amphoras','Riley LR1 Riley LR2',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1237,NULL),
('Yassi Ada 1',NULL,985,36.983,27.183,NULL,626,626,'ca',39.0,NULL,NULL,NULL,'amphoras',NULL,'ceramic','bowls, plates, cups, cooking pots, storage jars, pitchers','stone','mortar','pipette, lamps, weights, steelyards, censer, fishing weights, glass, iron tools, 70 coins','11 iron anchors',NULL,'galley with tiled roof',20.0,5.0,NULL,1239,'G.F. Bass 1963, 138-156; G.F. Bass 1975; G.F. Bass and F.H. van Doorninck 1982; P. Throckmorton 1987; F.H. van Doorninck Jr. 1997.'),
('Yassi Ada 2',NULL,986,36.983,27.183,NULL,375,425,NULL,42.0,NULL,NULL,NULL,'amphoras',NULL,'ceramic','pottery jugs, coarse pottery, lamps, plates, terra sigillata chiara bowls','metal','steelyward and copper jugs','bronze coins, glass',NULL,NULL,'hull, planking, frames, wales, deck, bulkhead, galley',20.0,NULL,NULL,1240,NULL),
('Yenikap? 1',NULL,987,41.005,28.950,NULL,900,900,'ca',NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and outside',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 10',NULL,988,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 11',NULL,989,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 12',NULL,990,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 13',NULL,991,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 14',NULL,992,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 15',NULL,993,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 16',NULL,994,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 17',NULL,995,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 18',NULL,996,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 19',NULL,997,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 2',NULL,998,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'galley - heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 20',NULL,999,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 21',NULL,1000,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 22',NULL,1001,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 23',NULL,1002,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 24',NULL,1003,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 25',NULL,1004,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 26',NULL,1005,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 27',NULL,1006,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 3',NULL,1007,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 4',NULL,1008,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 5',NULL,1009,41.005,28.950,NULL,900,1000,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 6',NULL,1010,41.005,28.950,NULL,600,700,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'galley - heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 7',NULL,1011,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'galley - heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 8',NULL,1012,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yenikap? 9',NULL,1013,41.005,28.950,NULL,400,1400,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily pitched inside and out, shell construction',NULL,NULL,NULL,NULL,'J.P. Delgado 2007, 8-11; C. Pulak 2007.'),
('Yverdon 1',NULL,1014,46.783,6.633,NULL,75,100,NULL,0.0,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'hull, frames, planks, dendro 77',34.0,NULL,NULL,1241,NULL),
('Yverdon 2',NULL,1015,46.783,6.633,NULL,300,400,NULL,NULL,'silted',NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'boat, mast-step, planks, thwarts, oar-loops, shrouds',9.7,1.5,'ca',1242,NULL),
('Zakynthos 2',NULL,1016,37.733,20.950,NULL,400,700,NULL,NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1244,NULL),
('Zanca',NULL,1017,42.800,10.117,NULL,1,100,NULL,35.0,NULL,NULL,NULL,'amphoras','pottery',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1245,NULL),
('Zapuntel',NULL,1018,44.250,14.800,'ca',500,1500,NULL,NULL,NULL,NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1246,NULL),
('Zatoane',NULL,1019,45.250,29.500,NULL,1,500,NULL,NULL,'silted',NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Roman boat, double wooden pulley-block',NULL,NULL,NULL,1247,NULL),
('Zaton 1',NULL,1020,44.217,15.150,NULL,75,100,NULL,2.0,NULL,NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'planks, keel',NULL,NULL,NULL,1248,NULL),
('Zaton 2',NULL,1021,44.217,15.150,NULL,75,100,NULL,2.0,NULL,NULL,NULL,'nothing reported','Byzantine',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'planks, keel',NULL,NULL,NULL,1249,NULL),
('Zdrijac',NULL,1022,44.233,15.183,NULL,800,1000,NULL,4.0,NULL,NULL,NULL,'amphoras',NULL,'tiles','tegulae and imbrices','metal','copper kettle, iron axe, 2 knives, chisel, nails, 3 adzes, 2 scrapers, plough-share, spear-head, crucible','pottery jug, glass flask',NULL,NULL,NULL,NULL,NULL,NULL,1250,NULL),
('Zembretta',NULL,1023,37.133,10.783,NULL,0,0,NULL,NULL,NULL,NULL,NULL,'amphoras','Almagro50',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1251,NULL),
('Zirje',NULL,1024,43.667,15.667,'ca',250,450,'ca / ?',NULL,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,1252,NULL),
('Zwammerdam 1',NULL,1025,52.117,4.733,NULL,150,225,'ca',NULL,'silted',NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'logboat',7.0,NULL,NULL,1254,NULL),
('Zwammerdam 2',NULL,1026,52.117,4.733,NULL,150,225,'ca',NULL,'silted',NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'barge, mast-step',22.8,NULL,NULL,1255,NULL),
('Zwammerdam 3',NULL,1027,52.117,4.733,NULL,150,225,'ca',NULL,'silted',NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'logboat',10.4,NULL,NULL,1256,NULL),
('Zwammerdam 4',NULL,1028,52.117,4.733,NULL,150,225,'ca',NULL,'silted',NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'barge, mast-step',34.0,NULL,NULL,1257,'H. Berkel and J. Obladen-Kauder 1991, 74-77; M.D. de Weerd 1991, 5-16; M.D. de Weerd 1991, 28-31; B. Arnold 1992,13; S.V.E. Heal 1993, 299; H.A. Hulst 1993; M.D. de Weerd 1994, 43-44.'),
('Zwammerdam 5',NULL,1029,52.117,4.733,NULL,150,225,'ca',NULL,'silted',NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'logboat',5.5,NULL,NULL,1258,'J.P. Clerc and J.C. Negrel 1973, 61-71.'),
('Zwammerdam 6',NULL,1030,52.117,4.733,NULL,150,225,'ca',NULL,'silted',NULL,NULL,'nothing reported',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'barge, mast-step',20.3,NULL,NULL,1259,'http://www.culture.gouv.fr/culture/archeosm/fr/ ; L. Long and G. Volpe 1998, 341.'),
('Zwammerdam 7',NULL,1031,52.117,4.733,NULL,100,300,'ca',NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on stratigraphy.  Oak cargo vessel in Roman context.',5.2,1.2,NULL,NULL,'Navis I, Zwammerdam 7, #82; F.P Arata 1993, 131-151; R. D’Oriano and E. Riccardi 2004, 89-95.'),
('Pointe de la Luque 2',NULL,1032,43.271,5.309,NULL,200,400,NULL,40.0,NULL,NULL,NULL,NULL,'mostly LR1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'preserved part of hull; keel; 3 deck strips,',20.0,6.0,NULL,NULL,'J.P. Clerc and J.C. Negrel 1973, 61-71.'),
('Marsaskala',NULL,1033,35.875,14.568,NULL,475,525,NULL,8.0,NULL,NULL,NULL,'amphoras',NULL,'amphoras','large African','ceramic','sigillata',NULL,NULL,NULL,'Homogenous deposit in the port, possibly wrecked cargo or port dump (i.e. not a wreck)',NULL,NULL,NULL,NULL,'A.D. Atauz and J. McManamon 2001, 22-28.'),
('Olbia R10',NULL,1034,40.917,9.500,NULL,1400,1500,NULL,NULL,NULL,NULL,NULL,NULL,'Günsenin 4 of varying sizes (17-115 l) Greek monograms; some Günsenin 3; about 200 amphoras visible',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Pisan? Brief mention.',NULL,NULL,NULL,NULL,'R. D’Oriano and E. Riccardi 2004, 89-95.'),
('Çamalt? Burnu 1',NULL,1035,40.618,27.542,NULL,1200,1300,NULL,26.0,'ca',NULL,NULL,'amphoras','Günsenin type 1','metal','scrap - 30 broken anchors',NULL,NULL,NULL,'jars cooking pots glazed plates, sgraffito plate and cup',NULL,'scattered small fragments of hull',NULL,NULL,NULL,NULL,'http://www.nautarch.org/ ; N. Günsenin 1999, 18-23; N. Günsenin 2002, 125-135.'),
('Çamalt? Burnu 2',NULL,1036,40.618,27.542,NULL,1200,1300,NULL,40.0,'ca',NULL,NULL,'amphoras','Günsenin type 1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'http://www.nautarch.org/ ; N. Günsenin 1999, 18-23; N. Günsenin 2002, 125-135.'),
('Ocaklar Burnu',NULL,1037,40.618,27.542,NULL,1000,1100,NULL,33.0,'ca',NULL,NULL,'amphoras','Günsenin type 1',NULL,NULL,NULL,NULL,NULL,NULL,'200 tons (?)','21000 amphoras? Estimated cargo of 200 tons? Possibly a barge?',40.0,20.0,NULL,NULL,'http://www.nautarch.org/ ; N. Günsenin 1999, 18-23; N. Günsenin 2002, 125-135.'),
('Tekmezar 1',NULL,1038,40.618,27.542,NULL,1000,1100,NULL,40.0,'ca',NULL,NULL,'amphoras','about 3000 Günsenin type 1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'http://www.nautarch.org/ ; N. Günsenin 1999, 18-23; N. Günsenin 2002, 125-135.'),
('Tekmezar 2',NULL,1039,40.618,27.542,NULL,1000,1100,NULL,33.0,'ca',NULL,NULL,'amphoras','Günsenin type 1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'http://www.nautarch.org/ ; N. Günsenin 1999, 18-23; N. Günsenin 2002, 125-135.'),
('Kocayemi?lik',NULL,1040,40.618,27.542,NULL,1000,1100,NULL,25.0,NULL,NULL,NULL,'amphoras','Günsenin type 1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'http://www.nautarch.org/ ; N. Günsenin 1999, 18-23; N. Günsenin 2002, 125-135.'),
('Anata? Adac?k',NULL,1041,40.618,27.542,NULL,1000,1100,NULL,35.0,NULL,NULL,NULL,'amphoras','roofing',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'http://www.nautarch.org/ ; N. Günsenin 1999, 18-23; N. Günsenin 2002, 125-135.'),
('Kuyu Burnu',NULL,1042,40.618,27.542,NULL,1,700,NULL,25.0,NULL,NULL,NULL,'tiles','water pipes',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Anchors seem Roman to Van Doorninck: Günsenin 2002, 129n8',NULL,NULL,NULL,NULL,'http://www.nautarch.org/ ; N. Günsenin 1999, 18-23; N. Günsenin 2002, 125-135.'),
('Küçük Ada',NULL,1043,40.628,27.584,NULL,600,700,NULL,28.0,NULL,NULL,NULL,'ceramic','Ganos (Günsenin type ?)',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'An associated amphora could indicate C8: Günsenin 2002, 129',NULL,NULL,NULL,NULL,'http://www.nautarch.org/ ; N. Günsenin 1999, 18-23; N. Günsenin 2002, 125-135.'),
('Ta?ada',NULL,1044,40.628,27.584,NULL,1000,1100,NULL,22.0,NULL,NULL,NULL,'amphoras','Ganos (Günsenin type ?)',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'http://www.nautarch.org/ ; N. Günsenin 1999, 18-23; N. Günsenin 2002, 125-135.'),
('E?ek Adalar?',NULL,1045,40.639,27.635,NULL,1000,1100,NULL,22.0,NULL,NULL,NULL,'amphoras','globular like Yassi Ada, i.e. LRA2',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'N. Günsenin 1994, 208.'),
('Ç?hl? Burnu',NULL,1046,40.601,27.606,NULL,600,700,NULL,30.0,NULL,NULL,NULL,'amphoras','architectural elements: columns etc.',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'N. Günsenin 1997, 97-106.'),
('Ekinlik Adas?',NULL,1047,40.601,27.606,NULL,500,600,NULL,15.0,'ca',NULL,NULL,'marble',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'http://www.turkiye-wrecks.com/bilinmeyen.html ; N. Günsenin 1998, 295-305; http://batiklar.tr.gg/Ekinlik-Adas%26%23305%3B-Bat%26%23305%3Bklar%26%23305%3B.htm'),
('Krefeld Gellep 1','Krefeld a',1048,51.337,6.680,NULL,1000,1400,NULL,NULL,'silted',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'keelboard? Found in same layer as boat',NULL,'website picture shows it with C13-14 date',14.5,NULL,NULL,NULL,'http://www.archaeologie-krefeld.de/news/SchiffeMittelalter/schiff3karolinger.htm'),
('Krefeld Gellep 2','Krefeld b',1049,51.336,6.679,NULL,950,1010,NULL,NULL,'silted',NULL,NULL,NULL,'Kügeltopf',NULL,NULL,NULL,NULL,NULL,'pulley','4 tons','14C plus a dendrodate, found 1973 10m under ground outside of Roman port; type of punt; German Oberländer; small size and pulley for net on stern frame could indicate fishing boat; estimated 4 ton cargo capacity',5.9,2.0,NULL,NULL,'http://www.archaeologie-krefeld.de/news/SchiffeMittelalter/schiff3karolinger.htm'),
('Krefeld Gellep 3','Krefeld c',1050,51.335,6.683,NULL,800,800,NULL,NULL,'silted',NULL,NULL,'ceramic',NULL,NULL,NULL,NULL,NULL,NULL,'knee and bottom of tow mast; caulking pegs; app fitting for stern oar','ca. 8-9 tons','dated by pot; found inside Roman harbor; caulked with moss; draft 0.4 m; capacity of ca. 8-9 tons',16.0,NULL,'ca',NULL,'http://www.archaeologie-krefeld.de/news/SchiffeMittelalter/schiff3karolinger.htm'),
('Port-la-Nautique',NULL,1051,43.152,3.008,NULL,0,0,NULL,NULL,'silted',2000,NULL,NULL,'LRA1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'hull fragments in silted up harbor that was active C1 BC-C1 AD',NULL,NULL,NULL,NULL,'S.D. Muller 2004, 345.'),
('Alexandria late Roman',NULL,1052,31.218,29.887,NULL,400,700,NULL,NULL,NULL,2004,'ca','amphoras','LRA1',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'brief mention; covered with coral; <20 m; cargo of LRA1',NULL,NULL,NULL,NULL,'L. Pantalacci 2005, 427.'),
('Y?lanl? Ada','Erkut Arcak',1053,36.141,33.345,NULL,500,700,NULL,55.0,NULL,2002,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'>60 amphoras',NULL,NULL,NULL,NULL,'V. Evrin and et al. 2005.'),
('Dana Adas?',NULL,1054,36.183,33.753,NULL,0,0,NULL,NULL,NULL,2006,NULL,'amphoras','Dr2-4',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'heavily looted',NULL,NULL,NULL,NULL,'Ç. Toskay-Evrin and V. Evrin 2006.'),
('Bo?sak',NULL,1055,36.272,33.825,NULL,1,200,NULL,NULL,NULL,2006,NULL,'amphoras','Günsenin 1','ceramic','plates and bowls','ceramic','silo-like large vessels',NULL,NULL,NULL,'also Roman cooking pots',NULL,NULL,NULL,NULL,'Ç. Toskay-Evrin and V. Evrin 2006.'),
('Sudak 1',NULL,1056,44.826,34.919,NULL,800,900,NULL,NULL,NULL,1999,NULL,'amphoras',NULL,'amphoras','Günsenin 2','amphoras','pitcher amphoras - naphta?',NULL,'anchor',NULL,'Amphoras have grafitti; anchor type is early: Kapitän D, hence they date wreck C9',NULL,NULL,NULL,NULL,'S.M. Zelenko 2001, 82-92.'),
('Sudak 2',NULL,1057,44.812,35.048,NULL,900,1100,NULL,NULL,NULL,2000,NULL,'amphoras','Ganos-Günsenin 1','amphoras',NULL,NULL,NULL,NULL,'anchor',NULL,'Dated from amphoras and anchor Kapitän E of same date range.',NULL,NULL,NULL,NULL,'S.M. Zelenko 2001, 82-92.'),
('Sudak 3',NULL,1058,44.829,34.951,'ca',NULL,NULL,NULL,50.0,NULL,1980,'1989','amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Wreck discovered by fishing trawler, an amphora with Greek inscriptions, photo; localized only to Sudak Bay',NULL,NULL,NULL,NULL,'S.M. Zelenko 2001, 87-90.'),
('De Meern 4',NULL,1059,52.083,5.200,NULL,100,100,'ca',NULL,NULL,2005,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Oak cargo barge, Roman, C2, dendrodated',NULL,NULL,NULL,NULL,'E. Jansma, Y.E. Vorst, and R.M. Visser 2008, 25-26.'),
('Woerden 7',NULL,1060,52.083,4.900,NULL,163,163,'ca',NULL,NULL,2003,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Dating based on dendro (oak). Cargo vessel, Roman C2',NULL,NULL,NULL,NULL,'E. Jansma, Y.E. Vorst, and R.M. Visser 2008, 25-26.'),
('Knidos-Arslanl? Promontory',NULL,1061,36.723,27.691,NULL,600,700,'ca',33.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'A. Canbazo?lu 1982, 369-377.'),
('Knidos-Arslanl? Promontory',NULL,1062,36.723,27.691,NULL,500,600,'ca',33.0,NULL,NULL,NULL,'amphoras',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'A. Canbazo?lu 1982, 369-377.'),
('Atalanti',NULL,1063,38.417,26.250,NULL,1,100,NULL,22.0,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'lead anchor stock',NULL,NULL,NULL,NULL,NULL,62,NULL)

--SELECT * FROM @tbl_Load

------INSERTING UNIQUE VALUES INTO @tbl_Cargo

INSERT INTO @tbl_Cargo (CargoName)
SELECT DISTINCT Cargo1 FROM @tbl_Load 
UNION 
SELECT DISTINCT Cargo2 FROM @tbl_Load
UNION 
SELECT DISTINCT Cargo3 FROM @tbl_Load
UNION 
SELECT DISTINCT OtherCargo FROM @tbl_Load
ORDER BY 1 ---Cardinality. When you can't call out the columns. DON'T DO THIS IN A PROC. 

--SELECT * FROM @tbl_Cargo


------INSERTING UNIQUE VALUES INTO @tbl_Type

INSERT INTO @tbl_Type (TypeName)
SELECT DISTINCT Type1 FROM @tbl_Load 
UNION 
SELECT DISTINCT Type2 FROM @tbl_Load
UNION 
SELECT DISTINCT Type3 FROM @tbl_Load
ORDER BY 1

--SELECT * FROM @tbl_Type

------INSERTING UNIQUE VALUES INTO @tbl_Gear

INSERT INTO @tbl_Gear(GearName)
SELECT DISTINCT Gear FROM @tbl_Load

--SELECT * FROM @tbl_Gear

------INSERTING UNIQUE VALUES INTO @tbl_Shipwreck

INSERT INTO @tbl_Shipwreck (PrimaryName, SecondaryName, WreckID2008, Latitude, Longitude, ShapeString, Geo, GeoQ, StartDate, EndDate, DateQ, YearFound, YearFoundQ, Depth, EstimatedCapacity, Comments, [Length], [Width], SizeEstimateQ, ParkerReference, BibliographyandNotes)
SELECT PrimaryName, 
       SecondaryName, 
	   WreckID2008, 
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
	   Depth, 
	   EstimatedCapacity, 
	   Comments, 
	   Lngth, 
	   Width, 
	   SizeestimateQ, 
	   Parkerreference, 
	   Bibliographyandnotes FROM @tbl_Load

--SELECT * FROM @tbl_Shipwreck
--ORDER BY ShipID


----CREATING JOIN FOR @tbl_CargoType

INSERT INTO @tbl_CargoType (CargoFK, TypeFK, ShipFK)
SELECT C.CargoID, T.TypeID, L.WreckID2008 FROM @tbl_Load L
JOIN @tbl_Cargo C ON C.CargoName = L.Cargo1
JOIN @tbl_Type T ON T.TypeName = L.Type1

INSERT INTO @tbl_CargoType (CargoFK, TypeFK, ShipFK)
SELECT C.CargoID, T.TypeID, L.WreckID2008 FROM @tbl_Load L
JOIN @tbl_Cargo C ON C.CargoName = L.Cargo2
JOIN @tbl_Type T ON T.TypeName = L.Type2

INSERT INTO @tbl_CargoType (CargoFK, TypeFK, ShipFK)
SELECT C.CargoID, T.TypeID, L.WreckID2008 FROM @tbl_Load L
JOIN @tbl_Cargo C ON C.CargoName = L.Cargo3
JOIN @tbl_Type T ON T.TypeName = L.Type3

INSERT INTO @tbl_CargoType (CargoFK, TypeFK, ShipFK)
SELECT C.CargoID, T.TypeID, L.WreckID2008 FROM @tbl_Load L
JOIN @tbl_Cargo C ON C.CargoName = L.OtherCargo
JOIN @tbl_Type T ON T.TypeName = L.Type3

--SELECT * FROM @tbl_CargoType
--ORDER BY ShipFK


------CREATING JOIN FOR @tbl_CargoWreck

INSERT INTO @tbl_CargoWreck (CargoFK, ShipFK)
SELECT CT.CargoFK, CT.ShipFK FROM @tbl_CargoType CT

--SELECT * FROM @tbl_CargoWreck


------CREATING JOIN FOR @tbl_GearWreck

INSERT INTO @tbl_GearWreck (GearFK, ShipFK)
SELECT G.GearID, L.ID FROM @tbl_Load L
JOIN @tbl_Gear G ON G.GearName = L.Gear
ORDER BY L.WreckID2008

--SELECT * FROM @tbl_GearWreck 

--SELECT * FROM @tbl_Gear

--SELECT * FROM @tbl_GearWreck GW
--ORDER BY GW.ShipFK

------WRITE FULL JOIN

SELECT SW.ShipID, C.CargoID, T.TypeID, G.GearID, SW.PrimaryName, ISNULL(SecondaryName,'') AS 'Secondary Name', ISNULL(C.CargoName,'') AS 'Cargo Name', 
ISNULL(T.TypeName, '') AS 'Type Name', ISNULL(G.GearName, '') AS 'Gear Name', * 
FROM @tbl_Shipwreck SW
LEFT JOIN @tbl_CargoWreck CW ON CW.ShipFK = SW.ShipID
LEFT JOIN @tbl_Cargo C ON C.CargoID = CW.CargoFK
LEFT JOIN @tbl_CargoType CT ON CT.ShipFK = SW.ShipID AND CT.CargoFK = C.CargoID 
LEFT JOIN @tbl_Type T ON T.TypeID = CT.TypeFK
LEFT JOIN @tbl_GearWreck GW ON GW.ShipFK = SW.ShipID
LEFT JOIN @tbl_Gear G ON G.GearID = GW.GearFK
ORDER BY SW.ShipID, C.CargoName, T.TypeName 


--------TESTING THE DATABASE!!

--SELECT * FROM @tbl_Cargo 
--SELECT * FROM @tbl_Type 

--SELECT * FROM @tbl_CargoType CT
--ORDER BY CT.ShipFK

--SELECT DISTINCT SW.ShipID   ---ANSWER: 1062
--FROM @tbl_Shipwreck SW
--LEFT JOIN @tbl_CargoWreck CW ON CW.ShipFK = SW.ShipID
--LEFT JOIN @tbl_Cargo C ON C.CargoID = CW.CargoFK
--LEFT JOIN @tbl_CargoType CT ON CT.ShipFK = SW.ShipID AND CT.CargoFK = C.CargoID 
--LEFT JOIN @tbl_Type T ON T.TypeID = CT.TypeFK
--LEFT JOIN @tbl_GearWreck GW ON GW.ShipFK = SW.ShipID
--LEFT JOIN @tbl_Gear G ON G.GearID = GW.GearFK

----Testing Number of Entries with Only Cargo/Type 

--SELECT COUNT (SW.ShipID)  ---ANSWER: 1493 
--FROM @tbl_Shipwreck SW
--LEFT JOIN @tbl_CargoWreck CW ON CW.ShipFK = SW.ShipID
--LEFT JOIN @tbl_Cargo C ON C.CargoID = CW.CargoFK
--LEFT JOIN @tbl_CargoType CT ON CT.ShipFK = SW.ShipID AND CT.CargoFK = C.CargoID 
--LEFT JOIN @tbl_Type T ON T.TypeID = CT.TypeFK


---How Many Nulls are in Cargo? 

--SELECT COUNT (SW.ShipID)  ---ANSWER: 338
--FROM @tbl_Shipwreck SW
--LEFT JOIN @tbl_CargoWreck CW ON CW.ShipFK = SW.ShipID
--LEFT JOIN @tbl_Cargo C ON C.CargoID = CW.CargoFK
--LEFT JOIN @tbl_CargoType CT ON CT.ShipFK = SW.ShipID AND CT.CargoFK = C.CargoID 
--LEFT JOIN @tbl_Type T ON T.TypeID = CT.TypeFK
--WHERE CW.CargoFK IS NULL


---How Many Not Nulls in Cargo? 

--SELECT COUNT (SW.ShipID)  ---ANSWER: 1155   --the above + this should equal 1493. 
--FROM @tbl_Shipwreck SW
--LEFT JOIN @tbl_CargoWreck CW ON CW.ShipFK = SW.ShipID
--LEFT JOIN @tbl_Cargo C ON C.CargoID = CW.CargoFK
--LEFT JOIN @tbl_CargoType CT ON CT.ShipFK = SW.ShipID AND CT.CargoFK = C.CargoID 
--LEFT JOIN @tbl_Type T ON T.TypeID = CT.TypeFK
--WHERE CW.CargoFK IS NOT NULL


----Testing Number of Entries with Only Gear 

--SELECT COUNT (SW.ShipID)  ---ANSWER:  1062
--FROM @tbl_Shipwreck SW
--LEFT JOIN @tbl_GearWreck GW ON GW.ShipFK = SW.ShipID
--LEFT JOIN @tbl_Gear G ON G.GearID = GW.GearFK


---How Many Nulls are in Gear? 

--SELECT COUNT (SW.ShipID)  ---ANSWER: 874
--FROM @tbl_Shipwreck SW
--LEFT JOIN @tbl_GearWreck GW ON GW.ShipFK = SW.ShipID
--LEFT JOIN @tbl_Gear G ON G.GearID = GW.GearFK
--WHERE GW.GearFK IS NULL

---How Many Not Nulls in Gear? 

--SELECT COUNT (SW.ShipID)  ---ANSWER:  188 --- this + above should = 1062. 
--FROM @tbl_Shipwreck SW
--LEFT JOIN @tbl_GearWreck GW ON GW.ShipFK = SW.ShipID
--LEFT JOIN @tbl_Gear G ON G.GearID = GW.GearFK
--WHERE GW.GearFK IS NOT NULL


---Now I we can find the depth of the deepest amphora! 

--SELECT TOP 1 SW.PrimaryName, T.TypeName, C.CargoName, G.GearName, SW.Depth  
--FROM @tbl_Shipwreck SW
--JOIN @tbl_CargoWreck CW ON CW.ShipFK = SW.ShipID
--JOIN @tbl_Cargo C ON C.CargoID = CW.CargoFK
--JOIN @tbl_CargoType CT ON CT.ShipFK = SW.ShipID AND CT.CargoFK = C.CargoID 
--JOIN @tbl_Type T ON T.TypeID = CT.TypeFK
--JOIN @tbl_GearWreck GW ON GW.ShipFK = SW.ShipID
--JOIN @tbl_Gear G ON G.GearID = GW.GearFK
--WHERE C.CargoName LIKE '%amphora%' 
--ORDER BY SW.Depth DESC




  ------------INSERTING VALUES INTO ACTUAL TABLES-------------------------


 ---- WARNING:  MAKE SURE THE SELECTS ARE CORRECT BEFORE YOU TURN ON THE INSERT 
  

-----tbl_Shipwreck


INSERT INTO tbl_Shipwreck (PrimaryName, SecondaryName, WreckID2008, Latitude, Longitude, ShapeString, Geo, GeoQ, StartDate, EndDate, DateQ, YearFound, YearFoundQ, Depth, EstimatedCapacity, Comments, [Length], [Width], SizeEstimateQ, ParkerReference, BibliographyandNotes)
SELECT PrimaryName, 
       SecondaryName, 
	   WreckID2008, 
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
	   Depth, 
	   EstimatedCapacity, 
	   Comments, 
	   Lngth, 
	   Width, 
	   SizeestimateQ, 
	   Parkerreference, 
	   Bibliographyandnotes FROM @tbl_Load

--SELECT * FROM tbl_Shipwreck

----tbl_Type

INSERT INTO tbl_Type (TypeName)
SELECT TypeName FROM @tbl_Type 


----tbl_Cargo

INSERT INTO tbl_Cargo (CargoName)
SELECT CargoName FROM @tbl_Cargo 

----tbl_Gear

INSERT INTO tbl_Gear(GearName)
SELECT DISTINCT Gear FROM @tbl_Load

----tbl_CargoType

INSERT INTO tbl_CargoType (CargoFK, TypeFK, ShipFK)
SELECT C.CargoID, T.TypeID, L.WreckID2008 FROM @tbl_Load L
JOIN tbl_Cargo C ON C.CargoName = L.Cargo1
JOIN tbl_Type T ON T.TypeName = L.Type1

INSERT INTO tbl_CargoType (CargoFK, TypeFK, ShipFK)
SELECT C.CargoID, T.TypeID, L.WreckID2008 FROM @tbl_Load L
JOIN tbl_Cargo C ON C.CargoName = L.Cargo2
JOIN tbl_Type T ON T.TypeName = L.Type2

INSERT INTO tbl_CargoType (CargoFK, TypeFK, ShipFK)
SELECT C.CargoID, T.TypeID, L.WreckID2008 FROM @tbl_Load L
JOIN tbl_Cargo C ON C.CargoName = L.Cargo3
JOIN tbl_Type T ON T.TypeName = L.Type3

INSERT INTO tbl_CargoType (CargoFK, TypeFK, ShipFK)
SELECT C.CargoID, T.TypeID, L.WreckID2008 FROM @tbl_Load L
JOIN tbl_Cargo C ON C.CargoName = L.OtherCargo
JOIN tbl_Type T ON T.TypeName = L.Type3


----tbl_CargoWreck

INSERT INTO tbl_CargoWreck (CargoFK, ShipFK)
SELECT CT.CargoFK, CT.ShipFK FROM tbl_CargoType CT


---tbl_GearWreck
 
INSERT INTO tbl_GearWreck (GearFK, ShipFK)
SELECT G.GearID, L.ID FROM @tbl_Load L
JOIN tbl_Gear G ON G.GearName = L.Gear
ORDER BY L.WreckID2008


---FULL JOIN 

SELECT SW.ShipID, C.CargoID, T.TypeID, G.GearID, SW.PrimaryName, ISNULL(SecondaryName,'') AS 'Secondary Name', ISNULL(C.CargoName,'') AS 'Cargo Name', 
ISNULL(T.TypeName, '') AS 'Type Name', ISNULL(G.GearName, '') AS 'Gear Name', * 
FROM tbl_Shipwreck SW
LEFT JOIN tbl_CargoWreck CW ON CW.ShipFK = SW.ShipID
LEFT JOIN tbl_Cargo C ON C.CargoID = CW.CargoFK
LEFT JOIN tbl_CargoType CT ON CT.ShipFK = SW.ShipID AND CT.CargoFK = C.CargoID 
LEFT JOIN tbl_Type T ON T.TypeID = CT.TypeFK
LEFT JOIN tbl_GearWreck GW ON GW.ShipFK = SW.ShipID
LEFT JOIN tbl_Gear G ON G.GearID = GW.GearFK
ORDER BY SW.ShipID, C.CargoName, T.TypeName 

---Are there 1,493 entries? Yes! 


END
ELSE
BEGIN
RAISERROR ('DML Present in DB_shipwreck.',17,1);  
END
