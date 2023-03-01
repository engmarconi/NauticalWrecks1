<!--
	
vers    Date            Coder       Issue
1.0     2023-02-22      Chido       Original  version
2.0		2023-02-25		Chido		'Heat Map Footprint' link to the Map page currently working. Modified the names web page and button names.

-->

<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="NauticalWrecksHome.aspx.cs" Inherits="NauticalWrecksFront.WebTemplate" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>Nautical Wrecks Project</title>
    <link href="Style/NauticalWreck.css" rel="stylesheet"/>
    <meta name="viewport" content="width=device-width">
		<meta charset="utf-8">
</head>
<body>
    <form id="form1" runat="server">
       <div class="head">
		<div class="headerobjectswrapper">
        
        <header>Nautical Wrecks</header>
		</div>

		<div class="subhead">
		<ul>
		<li><a href="#">Nautical Wrecks Map Locations</a></li>
		<li><a href="#">Wreckage Pictures</a></li>
		<li><a href="NauticalWrecksMap.aspx">Heat Map Footprint</a></li>	
		</ul>
		</div>
		</div>
		
		
		<div class="content">
		<div class="collumns">
			
		<div class="collumn">
		
				<!--This is the bit that holds the map.
				Yup. Pretty small. But that is it. The magic is in the code
				<div id="map" style="height: 100%;width:100%;"></div>.-->
				
				<p><h2>Summary of Nautical Wrecks</h2></p>

				<p> The <i>Nautical Wrecks™</i> solution is made up of 1062 distinct ship wrecks whoich occured around the mediterenean. This solution allows users to view several important details related to each shipwreck and make searches based on certain important fields. <i>...to be continued</i>
				</p>
				
				<div class="box" id="map"></div>				
				
				
		</div>
		<div class="collumn">
		
		<p><h2>Vision Statement</h2></p>
		
		<p><i>Nautical Wrecks™</i> is a web application that will bring ancient history right to your fingertips wherever you are in the world! This is done by transforming a boring, static spreadsheet into a visual, interactive, and informative spatial display. It is designed with a wide range of individuals in mind! Are you an early career scholar, maritime archaeologist, or scuba diver? Our application will be able to show you the locations of all nautical wrecks discovered around Europe and the Mediterranean Basin! Our application is infinitely scalable, can be queried to extract the locations of specific shipwrecks by Cargo type and time-period, and will be able to tell you the depth of the wrecks where records are available! In the future, Nautical Wrecks™ aims to become the go-to source for visualizing and analyzing the spatial patterns of shipwreck data on a global scale. 
		</p>
		
		
		
		
		<h2><p>Developers</p></h2>
		
		<p>GIS Students of Fanshawe College.</p>
		</div>
		
		<div class="collumn">
		<h2><p>Visit the Wrecks</p></h2>
		<!-- <img src="Images/GeoSpatialAnalysis.png" alt="Inspirational Art"> -->
		</div>
		
		</div>
		</div>
    </form>
</body>

<footer></footer>

	<script src="Scripts/Mockup.js">
        
    </script>


		<!--This is the call to Google to load our code from initMap See the API Key required. See the name of the function that is being called initMap()-->
  
	<script async src="https://maps.googleapis.com/maps/api/js?key=AIzaSyAX6haxPnf_GlOOJLMl4XX-_y9id7NBzh8&libraries=visualization&callback=initMap"> </script>


</html>
