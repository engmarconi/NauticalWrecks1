<!--
	
vers    Date            Coder       Issue
1.0     2023-02-22      Chido       Original  version
2.0		2023-02-25		Chido		The toggle heatmap switch currently functional. Heatmap coordinates loaded and functional. Modified buttons for the toggle switches

-->

<%@ Page Language="C#" AutoEventWireup="true" Async="true" CodeBehind="NauticalWrecksMap.aspx.cs" Inherits="NauticalWrecksFront.NauticalWrecksMap" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
     <title>Nautical Wrecks Map</title>
		<link rel="stylesheet" href="Style/NauticalWreck.css">
		<meta name="viewport" content="width=device-width">
		<meta charset="utf-8">
</head>
<body id="body">

    <form id="form1" runat="server" action="NauticalWrecksMap.aspx" >
	<asp:HiddenField runat="server" ID="KmlNameProperty" />
       		<div class="head">
		<div class="headerobjectswrapper">
        <header>Nautical Wrecks Maps</header>
		</div>

		<div class="subhead">
		<ul>
		<li><a href="NauticalWrecksHome.aspx">Nautical Wrecks Home</a></li>
		<li><a href="NauticalWrecksMap.aspx">Nautical Wrecks</a></li>
			
		</ul>
		</div>
		</div>
		<label>Depth</label>
		<asp:DropDownList ID="DepthDropDownList" runat="server"></asp:DropDownList><br />
		<label>Gear</label>
		<asp:DropDownList ID="GearDropDownList" runat="server"></asp:DropDownList><br />
		<label>Type 1</label>
		<asp:DropDownList ID="Type1DropDownList" runat="server"></asp:DropDownList><br />
		<label>Cargo 1</label>
		<asp:DropDownList ID="Cargo1DropDownList" runat="server"></asp:DropDownList><br />
		<label>Type 2</label>
		<asp:DropDownList ID="Type2DropDownList" runat="server"></asp:DropDownList><br />
		<label>Cargo 2</label>
		<asp:DropDownList ID="Cargo2DropDownList" runat="server"></asp:DropDownList><br />
		<label>Type 3</label>
		<asp:DropDownList ID="Type3DropDownList" runat="server"></asp:DropDownList><br />
		<label>Cargo 3</label>
		<asp:DropDownList ID="Cargo3DropDownList" runat="server"></asp:DropDownList><br />
		<label>Other Cargo</label>
		<asp:DropDownList ID="OtherCargoDropDownList" runat="server"></asp:DropDownList><br />
		<br />
		<input type="submit" value="Search Now" />
    </form>
		
				
				<div class="halfbox" id="map"></div>
				<div class="halfbox" id="control"><p><h2>Toggle Switches</h2></p>
				<button type="button" onclick="LoadData('Heatmap')" type="button">Toggle Heatmap</button>	
				<button type="button" onclick="LoadData('Overlay')" type="button">Toggle Overlay</button>			
				<button type="button" onclick="LoadData('Points')" type="button">Toggle Placemarks</button>		
					
			
</body>
<footer>
</footer>
		
	
	<script src="Scripts/NauticalHome.js"></script>
 
   
	<!--This is the call to Google to load our code from initMap See the API Key required. See the name of the function that is being called InitializeMap()-->
	<script async src="https://maps.googleapis.com/maps/api/js?key=AIzaSyAX6haxPnf_GlOOJLMl4XX-_y9id7NBzh8&libraries=visualization&callback=InitializeMap"> </script>


</html>
