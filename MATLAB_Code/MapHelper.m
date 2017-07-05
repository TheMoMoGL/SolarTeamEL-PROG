function MapHelper = MapHelper
    MapHelper.plotMap = @plotMap;
    MapHelper.plotCurrentPosition = @plotCurrentPosition;
    MapHelper.createPlotPositionTimer = @createPlotPositionTimer;
end

function plotMap()

    wscdata = evalin('base','wscdata');
    
    % Plot the graph
    hGui = findobj('Tag','mySerialMonitor');
    handles = guidata(hGui);
    gpsGraph = handles.aMapGraph;
    axes(gpsGraph);
    hold(gpsGraph,'on');
    h = worldmap('Australia');
    hold(h,'on');
    getm(h,'MapProjection');
    geoshow(gpsGraph,'landareas.shp', 'FaceColor', [0.15 0.5 0.15])
    geoshow(gpsGraph,'worldlakes.shp', 'FaceColor', 'cyan')
    geoshow(gpsGraph, wscdata(:,2),wscdata(:,1))
    
    StopIndex = find(wscdata(:,6));
    geoshow(gpsGraph,wscdata(StopIndex,2), wscdata(StopIndex,1), 'DisplayType', 'Point', 'Marker', 'O', 'Color', 'red');
        
end

function plotCurrentPosition()
    
    % TODO: Simulation, just read the longidue and latidue from a file
    
    longitude = evalin('base','longitude');
    latitude = evalin('base','latitude');
    
    hGui = findobj('Tag','mySerialMonitor');
    handles = guidata(hGui);
    gpsGraph = handles.aMapGraph;
    %axes(gpsGraph);
    hold(gpsGraph,'on');
    
    geoshow(gpsGraph,latitude, longitude, 'DisplayType', 'Point', 'Marker', '*', 'Color', 'black');
end

function createPlotPositionTimer(interval)
     mTimer = timerfind('Name', 'postionTimer');
    if ~isempty(mTimer) %timer exist, start or stop
        if isvalid(mTimer)
            if (strcmpi(get(mTimer,'Running'),'off') == 1)
                start(mTimer);
            else
                stop(mTimer);
            end
        else
            fprintf('Something wrong with postionTimer\n'); 
        end
    else %create the timer and start it
         %Create timer
         postionTimer = timer;
         set(postionTimer,'executionMode','fixedRate');
         set(postionTimer,'Name','postionTimer');
         set(postionTimer,'ObjectVisibility','on');
         set(postionTimer,'TimerFcn',@(~,~)plotCurrentPosition());
         set(postionTimer,'StopFcn',@(~,~)disp('postionTimer stopped'));
         set(postionTimer,'Period',interval);
         start(postionTimer);
    end
end