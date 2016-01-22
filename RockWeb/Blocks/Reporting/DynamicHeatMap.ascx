﻿<%@ Control Language="C#" AutoEventWireup="true" CodeFile="DynamicHeatMap.ascx.cs" Inherits="RockWeb.Blocks.Reporting.DynamicHeatMap" %>

<script type="text/javascript" src="https://google-maps-utility-library-v3.googlecode.com/svn/trunk/maplabel/src/maplabel-compiled.js"></script>


<asp:UpdatePanel ID="upnlContent" runat="server">
    <ContentTemplate>

        <Rock:NotificationBox ID="nbConfigurationWarning" runat="server" NotificationBoxType="Warning" Visible="false" />

        <div class="panel panel-block">
            <div class="panel-heading">
                <h1 class="panel-title"><i class="fa fa-map-marker"></i>&nbsp;Dynamic Map</h1>
                <a class="btn btn-xs btn-default pull-right margin-l-sm" onclick="javascript: toggleOptions()"><i title="Options" class="fa fa-gear"></i></a>
            </div>
            <asp:Panel ID="pnlOptions" runat="server" Title="Options" CssClass="panel-body js-options" Style="display: none">
                <div class="row">
                    <div class="col-md-6">
                        <Rock:RockDropDownList ID="ddlUserDataView" runat="server" Label="Dataview" Help="Select the dataview to use to filter the results." Required="true" />
                        <Rock:CampusesPicker ID="cpCampuses" runat="server" Label="Campus Filter" Help="Select the campuses to narrow the results down to families with that home campus." Required="false" />
                        <Rock:GroupPicker ID="gpGroupToMap" runat="server" Label="Geo-fencing Group" Help="Select a Group to show the geofences for that group and it's child groups" />
                    </div>
                    <div class="col-md-6">
                        <Rock:RockCheckBox ID="cbShowCampusLocations" runat="server" Label="Show Campus Locations On Map" Checked="true" />
                        <Rock:RangeSlider ID="rsDataPointRadius" runat="server" MinValue="0" MaxValue="128" Text="32" Label="Radius" Help="The radius of influence for each data point, in pixels" />
                    </div>
                </div>

                <div class="actions">
                    <asp:LinkButton ID="btnApplyOptions" runat="server" Text="Apply" CssClass="btn btn-primary" OnClick="btn_ApplyOptionsClick" />
                </div>
            </asp:Panel>

            <div class="margin-all-md">
                <div class="pull-right">
                    <asp:Panel ID="pnlPieSlicer" runat="server" CssClass="btn btn-default btn-xs js-createpieshape">
                        <i class='fa fa-pie-chart' title="Create pie slices from selected circle"></i>
                    </asp:Panel>
                    <div class="btn btn-danger btn-xs js-deleteshape"><i class='fa fa-times' title="Delete selected shape"></i></div>
                </div>
            </div>
            <div class="panel-body">
                <asp:Literal ID="lMapStyling" runat="server" />

                <asp:Panel ID="pnlMap" runat="server">

                    <div id="map_wrapper">
                        <div id="map_canvas" class="mapping"></div>
                    </div>
                </asp:Panel>

                <asp:Literal ID="lMessages" runat="server" />
                <asp:Literal ID="lDebug" runat="server" />
            </div>
        </div>

        <asp:HiddenField ID="hfPolygonColors" runat="server" />
        <asp:HiddenField ID="hfCenterLatitude" runat="server" />
        <asp:HiddenField ID="hfCenterLongitude" runat="server" />
        <asp:HiddenField ID="hfZoom" runat="server" />

        <%-- Configuration Panel --%>
        <asp:Panel ID="pnlConfigure" runat="server" Visible="false">
            <Rock:ModalDialog ID="mdConfigure" runat="server" ValidationGroup="vgConfigure" OnSaveClick="mdConfigure_SaveClick">
                <Content>
                    <Rock:RockDropDownList ID="ddlBlockConfigDataView" runat="server" Label="Dataview" Help="Select the dataview to use to filter the results." Required="false" ValidationGroup="vgConfigure" />
                </Content>
            </Rock:ModalDialog>
        </asp:Panel>

        <script>

            function toggleOptions() {
                $('.js-options').slideToggle();
            }
            
            Sys.Application.add_load(function () {

                // hook into rangeslider
                var rangeSlider = $('#<%=rsDataPointRadius.ClientID%>');
                rangeSlider.on("change", function(obj) {
                    var newRadius = parseInt($(this).val());
                    if (heatmap) {
                        heatmap.set('radius', newRadius);
                    }
                });

                // configure/display heatmap
                var allShapes = [];
                var selectedShape;

                var pieSlicerState = {
                    SelectedCenterPt: null,
                    SelectedRadius: null,
                    SelectedPieCuts: [],
                    CurrentPieSlices: []
                };
                
                var map;

                var heatMap;
                var drawingManager;

                var mapStyle = <%=this.StyleCode%>;
                var polygonColorIndex = 0;
                var polygonColors;

                initializeMap();

                function initializeMap() {
                    var lat = Number($('#<%=hfCenterLatitude.ClientID%>').val());
                    var long = Number($('#<%=hfCenterLongitude.ClientID%>').val());
                    var zoom = Number($('#<%=hfZoom.ClientID%>').val());
                    var centerLatLng = new google.maps.LatLng(lat,long );

                    polygonColors = $('#<%=hfPolygonColors.ClientID%>').val().split(',');
                    
                    // Set default map options
                    var mapOptions = {
                        mapTypeId: 'roadmap'
                        , styles: mapStyle
                        , center: centerLatLng
                        , zoom: zoom
                        , streetViewControl: false
                    }

                    // Display a map on the page
                    var mapCanvas = document.getElementById('map_canvas');
                    map = new google.maps.Map(mapCanvas, mapOptions);
                    map.setTilt(45);
                    map.setCenter(centerLatLng);

                    // if a GroupId was specified, show geofences
                    function addGroupGeoFence(mapItem){
                        if (typeof mapItem.PolygonPoints !== 'undefined' && mapItem.PolygonPoints.length > 0) {
                            var geoFencePath = Array();

                            $.each(mapItem.PolygonPoints, function(j, point) {
                                geoFencePath.push(new google.maps.LatLng(point.Latitude, point.Longitude));
                            });

                            var geoFencePoly = new google.maps.Polygon({
                                path: geoFencePath,
                                map: map,
                                fillColor: map.GetNextColor(),
                                fillOpacity: 0.6,
                                draggable: false,
                                editable: false,
                            });

                            geoFencePoly.Name = mapItem.Name;

                            map.AddUpdateShape(geoFencePoly);
                        }
                    }

                    var groupId = <%=this.GroupId ?? 0 %>;
                    if (groupId) {
                        $.get( Rock.settings.get('baseUrl') + 'api/Groups/GetMapInfo/' + groupId, function( mapItems ) {
                            $.each(mapItems, function (i, mapItem) {
                                addGroupGeoFence(mapItem);
                            });
                        });

                        // Get Child Groups
                        $.get( Rock.settings.get('baseUrl') + 'api/Groups/GetMapInfo/' + groupId + '/Children', function( mapItems ) {
                            $.each(mapItems, function (i, mapItem) {
                                addGroupGeoFence(mapItem);
                            });
                        });
                    }

                    //
                    var heatMapData = [
<%=this.HeatMapData%>]

                    var campusMarkersData = [
<%=this.CampusMarkersData%>]
                    
                    var pinImage = new google.maps.MarkerImage('//chart.googleapis.com/chart?chst=d_map_pin_letter&chld=%E2%80%A2|' + 'FE7569',
                        new google.maps.Size(21, 34),
                        new google.maps.Point(0,0),
                        new google.maps.Point(10, 34));

                    var pinShadow = new google.maps.MarkerImage('//chart.googleapis.com/chart?chst=d_map_pin_shadow',
                        new google.maps.Size(40, 37),
                        new google.maps.Point(0, 0),
                        new google.maps.Point(12, 35));

                    campusMarkersData.forEach( function (c) {
                        marker = new google.maps.Marker({
                            position: c.location,
                            map: map,
                            title: c.campusName,
                            icon: pinImage,
                            shadow: pinShadow
                        });
                    });

                    var heatMapBounds = new google.maps.LatLngBounds();
                    heatMapData.forEach(function (a) {
                        heatMapBounds.extend(a.location || a);
                    });

                    heatmap = new google.maps.visualization.HeatmapLayer({
                        dissipating: true,
                        data: heatMapData,
                        maxIntensity: 50,
                        radius: <%=this.DataPointRadius%>,
                    });

                    heatmap.setMap(map);

                    map.DeleteShape = function(shape) {
                        var allShapesIndex = allShapes.indexOf(shape);
                                    
                        if (allShapesIndex > -1)
                        {
                            allShapes.splice(allShapesIndex, 1);
                        }
                                    
                        shape.setMap(null);
                        shape.mapCountLabel.setMap(null);
                        if (shape == selectedShape)
                        {
                            selectedShape = null;
                        }
                        
                        shape = null;
                    };

                    map.GetNextColor = function () {
                        if (polygonColors && polygonColors.length) {
                            if (polygonColorIndex >= polygonColors.length) {
                                polygonColorIndex = 0;
                            }

                            return polygonColors[polygonColorIndex++];
                        }

                        return null;
                    }

                    map.AddUpdateShape = function AddUpdateShape(shape, justUpdate) {
                        selectedShape = shape;
                        
                        if (!justUpdate) {
                            google.maps.event.addListener(shape, 'click', function () {
                                selectedShape = shape
                            });

                            // set the color of the next shape
                            if (polygonColors && polygonColors.length) {
                                var color = map.GetNextColor();

                                drawingManager.polygonOptions.fillColor = color;
                                drawingManager.polygonOptions.strokeColor = color;
                                drawingManager.circleOptions.fillColor = color;
                                drawingManager.circleOptions.strokeColor = color;
                                drawingManager.rectangleOptions.fillColor = color;
                                drawingManager.rectangleOptions.strokeColor = color;
                            }

                            allShapes.push(shape);
                        }

                        var selectedBounds = shape.getBounds();

                        var pointCount = 0;
                        heatmap.data.forEach(function (latLng) {
                            if (latLng.location) {
                                if (selectedBounds.contains(latLng.location)) {
                                    pointCount += latLng.weight;
                                }
                            } else {
                                if (selectedBounds.contains(latLng)) {
                                    pointCount++;
                                }
                            }
                        });

                        var totalCount = pointCount;
                        var mapLabel = totalCount.toString();
                        if (selectedShape.Name){
                            mapLabel = selectedShape.Name + ': ' + mapLabel;
                        }

                        if (!selectedShape.mapCountLabel) {
                            selectedShape.mapCountLabel = new MapLabel({
                                map:map,
                                fontSize: <%=this.LabelFontSize%>,
                                text:'x',
                                position: selectedBounds.getCenter()
                            });
                        }

                        selectedShape.mapCountLabel.position = selectedBounds.getCenter();
                        selectedShape.mapCountLabel.changed('position');
                        selectedShape.mapCountLabel.text = mapLabel;
                        selectedShape.mapCountLabel.changed('text');

                        if (!justUpdate) {
                            selectedShape.addListener('bounds_changed', function (event) {
                                var resizedShape = this;
                                map.AddUpdateShape(resizedShape, true);
                            });
                        }
                    }

                    var initialColor = map.GetNextColor();

                    drawingManager = new google.maps.drawing.DrawingManager({
                        drawingMode: null,
                        drawingControl: true,
                        drawingControlOptions: {
                            position: google.maps.ControlPosition.TOP_CENTER,
                            drawingModes: [
                                google.maps.drawing.OverlayType.CIRCLE,
                                google.maps.drawing.OverlayType.POLYGON,
                                google.maps.drawing.OverlayType.RECTANGLE
                            ]
                        },
                        circleOptions: {
                            draggable: true,
                            editable: true,
                            fillColor: initialColor,
                            strokeColor: initialColor
                        },
                        polygonOptions: {
                            draggable: true,
                            editable: true,
                            fillColor: initialColor,
                            strokeColor: initialColor,
                            strokeWeight: 2
                        },
                        polylineOptions: {
                            draggable: true,
                            editable: true,
                            fillColor: initialColor,
                            strokeColor: initialColor
                        },
                        rectangleOptions: {
                            draggable: true,
                            editable: true,
                            fillColor: initialColor,
                            strokeColor: initialColor
                        }
                    });

                    drawingManager.setMap(map);

                    google.maps.event.addListener(drawingManager, 'overlaycomplete', function (event) {
                        var shape = event.overlay;
                        shape.overlayType = event.type;
                        map.AddUpdateShape(event.overlay, false);
                    });

                    google.maps.event.addListener(drawingManager, 'polygoncomplete', function (polygon) {
                        google.maps.event.addListener(polygon, 'dragend', function (a,b,c) {
                            allShapes.forEach( function(s) {
                                map.AddUpdateShape(s, true);
                            });
                        });
                        google.maps.event.addListener(polygon.getPath(), 'insert_at', function (a,b,c) {
                            allShapes.forEach( function(s) {
                                map.AddUpdateShape(s, true);
                            });
                        });
                        google.maps.event.addListener(polygon.getPath(), 'set_at', function (a,b,c) {
                            allShapes.forEach( function(s) {
                                map.AddUpdateShape(s, true);
                            });
                        });
                    });
                }

                $('.js-deleteshape').click(function () {
                    if (selectedShape) {
                        map.DeleteShape(selectedShape);
                    }
                });

                $('.js-createpieshape').click(function () {

                    // make sure drawing manager mode is the hand so that 'mousemove' will fire
                    drawingManager.setDrawingMode(null);

                    if ((selectedShape && (typeof(selectedShape.overlayType) != 'undefined') && selectedShape.overlayType == 'circle') || (pieSlicerState.SelectedCenterPt && pieSlicerState.SelectedRadius)) {

                        // if we are starting with a new shape (not a pieslice), start over with a new pieslicer
                        if (selectedShape && (typeof(selectedShape.overlayType) != 'undefined') && selectedShape.overlayType != 'pieslice') {
                            if (selectedShape.overlayType == 'circle') {
                                pieSlicerState.SelectedCenterPt = selectedShape.getCenter();
                                pieSlicerState.SelectedRadius = selectedShape.radius;
                            } else {
                                pieSlicerState.SelectedCenterPt = null;
                                pieSlicerState.SelectedRadius = null;
                            }
                            pieSlicerState.SelectedPieCuts = [];
                            pieSlicerState.CurrentPieSlices = [];
                        }

                        // map to the click event which we'll use to make the pieslice position permanent
                        if (!map.pieClickListener) {
                            map.pieClickListener = google.maps.event.addListener(map, 'click', function (event) {
                                if (selectedShape && selectedShape.isPieDrawing){
                                    pieSlicerState.SelectedPieCuts = [];
                                    pieSlicerState.CurrentPieSlices.forEach(function(ps){
                                        pieSlicerState.SelectedPieCuts.push(ps.startArc);
                                    })
                                    
                                    selectedShape.isPieDrawing = false;
                                    selectedShape.deleteOnFirstSlice = false;
                                    map.pieMouseMoveListener.remove();
                                    map.pieMouseMoveListener = null;
                                }
                            });
                        }
                        
                        // when the move moves over the map, draw the pie shapes in realtime based on the mouse position relative to the center of the orig circle
                        if (!map.pieMouseMoveListener) {
                            map.pieMouseMoveListener = google.maps.event.addListener(map, 'mousemove', function (event) {
                                if (pieSlicerState.SelectedCenterPt && pieSlicerState.SelectedRadius && selectedShape){

                                    var heading = google.maps.geometry.spherical.computeHeading(pieSlicerState.SelectedCenterPt, event.latLng);
                                    while (heading < 0)
                                    {
                                        heading += 360;
                                    }

                                    var currentPieCuts = [];
                                    currentPieCuts.push(heading);
                                    pieSlicerState.SelectedPieCuts.forEach(function(pc) {
                                        currentPieCuts.push(pc);
                                    });

                                    currentPieCuts.sort(function(a,b){
                                        return a - b;
                                    });

                                    // if we already have the pieslices, delete them all and we'll redraw them based on the currentPieCuts
                                    pieSlicerState.CurrentPieSlices.forEach(function(ps) {
                                        map.DeleteShape(ps);
                                    });

                                    pieSlicerState.CurrentPieSlices = [];

                                    // if we are starting with a circle, delete it since we are redrawing it as a big pieslice
                                    if (selectedShape && (selectedShape.isPieDrawing || selectedShape.overlayType == 'circle')){
                                        map.DeleteShape(selectedShape);
                                    }
                                    
                                    currentPieCuts.forEach(function(pc, i) {
                                        var centerPt = pieSlicerState.SelectedCenterPt;
                                        var radiusMeters = pieSlicerState.SelectedRadius;
                                        
                                        var pieSlicePath = Array();

                                        var nextRadialPoint = pc;
                                        lastRadialPoint = pc;

                                        if (i < currentPieCuts.length-1){
                                            // find the next arc starting point
                                            lastRadialPoint = currentPieCuts[i+1];
                                        }
                                        else{
                                            // use the first arc of our currentPieCuts
                                            lastRadialPoint = currentPieCuts[0];

                                            // make sure the pieshape colors don't flash to random colors as it is resized
                                            polygonColorIndex = 0;
                                        }

                                        // if the start of the arc is counterclockwise from the current, move it back 360 degrees (because it is probably the last missing piece of the circle)
                                        if (nextRadialPoint >= lastRadialPoint){
                                            nextRadialPoint -= 360;
                                        }
                                    
                                        // create a Google Map Path as an array of all the lines from the center to the outer radius for every full degree to make it look like a pie slice
                                        while (nextRadialPoint < lastRadialPoint) {
                                            pieSlicePath.push(google.maps.geometry.spherical.computeOffset(centerPt, radiusMeters, nextRadialPoint));
                                            nextRadialPoint += 1;
                                        }
                            
                                        // ensure that the last path of the pieslice is there for the last line of the path
                                        var endArc = lastRadialPoint;
                                        pieSlicePath.push(google.maps.geometry.spherical.computeOffset(centerPt, radiusMeters, endArc));
                            
                                        // put the center point to the start and end of the pieSlicePath
                                        pieSlicePath.unshift(centerPt);
                                        pieSlicePath.push(centerPt);

                                        var pieSlicePoly = new google.maps.Polygon({
                                            path: pieSlicePath,
                                            map: map,
                                            fillColor: map.GetNextColor(),
                                            fillOpacity: 0.6,
                                            draggable: false,
                                            editable: false,
                                        });

                                        pieSlicePoly.isPieDrawing = true;
                                        pieSlicePoly.startArc = pc;
                                        pieSlicePoly.overlayType = 'pieslice';
                                        while (pieSlicePoly.startArc < 0){
                                            pieSlicePoly.startArc += 360;
                                        }

                                        google.maps.event.trigger(drawingManager, 'polygoncomplete', pieSlicePoly);

                                        pieSlicerState.CurrentPieSlices.push(pieSlicePoly);

                                        map.AddUpdateShape(pieSlicePoly, false );
                                    });
                                }
                            
                            });
                        }
                    }
                });
            });

            // extend polygon to getBounds
            if (!google.maps.Polygon.prototype.getBounds) {
                google.maps.Polygon.prototype.getBounds = function(latLng) {
                    var bounds = new google.maps.LatLngBounds();
                    var paths = this.getPaths();
                    var path;
                    for (var p = 0; p < paths.getLength(); p++) {
                        path = paths.getAt(p);
                        for (var i = 0; i < path.getLength(); i++) {
                            bounds.extend(path.getAt(i));
                        }
                    }
 
                    return bounds;
                }
            } 

            // extend polygon to getBounds
            if (!google.maps.Polyline.prototype.getBounds) {
                google.maps.Polyline.prototype.getBounds = function() {
                    var bounds = new google.maps.LatLngBounds();
                    this.getPath().forEach(function(e) {
                        bounds.extend(e);
                    });
                    return bounds;
                }
            };

        </script>

    </ContentTemplate>
</asp:UpdatePanel>