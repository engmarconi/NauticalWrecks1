<%@ Page Language="C#" AutoEventWireup="true" Async="true" CodeBehind="NauticalWrecksMap.aspx.cs" Inherits="NauticalWrecksFront.NauticalWrecksMap" %>

<!--
Date            Coder       vers		Comments
2023-02-22      Chido       3.3.1       Original  version.
2023-02-25      Chido       3.3.2       The toggle heatmap switch currently functional. Heatmap coordinates loaded and functional. Modified buttons for the toggle switches.	
2023-03-01      Chido       3.3.2       Introduced the drop down lists for searching the map.
2023-03-02      Chido       3.3.4       CHanged styling. Filters above and on same line. Toggle switches above.
2023-03-03      Chido       3.3.5       Added the control for the displayed records
										Added the button that searches the filtered records
-->


<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
     <title>Nautical Wrecks Map</title>
		<link rel="stylesheet" href="Style/NauticalWreck.css">
		<meta name="viewport" content="width=device-width">
		<meta charset="utf-8">
</head>
<body id="body">

    <form id="form1" runat="server">
	<asp:HiddenField runat="server" ID="KmlNameProperty" />
       		<div class="head">
		<div class="headerobjectswrapper">
        <header>Nautical Wrecks Maps</header>
		</div>

		<div class="subhead">
		<ul>
		<li><a href="NauticalWrecksHome.aspx">Nautical Wrecks Home</a></li>
		<%--<li><a href="NauticalWrecksMap.aspx">Nautical Wrecks</a></li>--%>
			
		</ul>
		</div>
		</div>

		<div class="halfbox_two" id="control">  
			<button type="button" onclick="LoadData('Heatmap')" type="button">Toggle Heatmap</button>	
			<button type="button" onclick="LoadData('Overlay')" type="button">Toggle Overlay</button>			
			<button type="button" onclick="LoadData('Points')"  type="button">Toggle Placemarks</button>	
		&nbsp;<span class="records"><asp:Label ID="lblRecordsCount" runat="server"  Text="0" CssClass="records"></asp:Label> &nbsp;Records Displayed!</span>
		</div>

		<div class="search_container">
			<asp:Button ID="btnGetAllRecords" runat="server" Text="View All Wrecks" CssClass="submit_btn" OnClick="btnGetAllRecords_Click" />
		  <div>
			 <label>Depth</label> <br />
		    <asp:DropDownList ID="DepthDropDownList"  CssClass="mydropdownlist" runat="server" AutoPostBack="true" OnSelectedIndexChanged="DepthDropDownList_SelectedIndexChanged" ToolTip="===Please Select Depth==="></asp:DropDownList>
		 </div>

		<div>
			<label>Gear</label>	  <br />				   
		    <asp:DropDownList ID="GearDropDownList"   CssClass="mydropdownlist" runat ="server" AutoPostBack="true" OnSelectedIndexChanged="GearDropDownList_SelectedIndexChanged" ToolTip="===Please Select Gear==="></asp:DropDownList>
		</div>
	
		<div>
			<label>Type</label> <br />				   
		   <asp:DropDownList ID="TypeDropDownList"  CssClass="mydropdownlist" runat="server" AutoPostBack="true" OnSelectedIndexChanged="TypeDropDownList_SelectedIndexChanged"></asp:DropDownList>
		</div>

		<div>
			 <label>Cargo</label>	<br />				   
		     <asp:DropDownList ID="CargoDropDownList" CssClass="mydropdownlist" runat="server" AutoPostBack="true" OnSelectedIndexChanged="CargoDropDownList_SelectedIndexChanged"></asp:DropDownList>
		</div>

		<div>
			<label>Start Date</label><br />					   
		<asp:DropDownList ID="StartDateDropDownList"  CssClass="mydropdownlist" runat="server" AutoPostBack="true" OnSelectedIndexChanged="StartDateDropDownList_SelectedIndexChanged"></asp:DropDownList>
		</div>
		<div>
			<label>End Date</label><br />					   
		<asp:DropDownList ID="EndDateDropDownList"  CssClass="mydropdownlist" runat="server" AutoPostBack="true" OnSelectedIndexChanged="EndDateDropDownList_SelectedIndexChanged"></asp:DropDownList>
		</div>
		
		
			<div>
				<asp:Button ID="btnSearchQuery" runat="server" Text="Filter Search" CssClass="submit_btn" OnClick="btnSearchQuery_Click" />
				&nbsp;
			</div>
		</div>
		
    </form>

	<div class="loading_box">
		<h2>Wait!...Loading Requested Locations on map ... Hit 'Toggle Placemearks' once loading completes</h2>
	</div>

				
		<div class="halfbox" id="map"></div> 
 
	
	
		<%--<label>Depth</label>
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
</footer>--%>
		
	
	<script src="Scripts/NauticalHome.js"></script> 
	<!--This is the call to Google to load our code from initMap See the API Key required. See the name of the function that is being called InitializeMap()-->
	<script async src="https://maps.googleapis.com/maps/api/js?key=AIzaSyAX6haxPnf_GlOOJLMl4XX-_y9id7NBzh8&libraries=visualization&callback=InitializeMap"> </script>

</body>

</html>




