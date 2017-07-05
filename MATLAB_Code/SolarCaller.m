function SolarHelper = SolarCaller
    SolarHelper.PlotSolarPowerDaily = @PlotSolarPowerDaily;
    SolarHelper.PlotSolarPowerInstantaneously = @PlotSolarPowerInstantaneously;
    SolarHelper.CreateTimerForPlotSolarPowerInstantaneously = @CreateTimerForPlotSolarPowerInstantaneously;
    SolarHelper.updateDisplay = @updateDisplay;
    SolarHelper.ClearSolarPlot = @ClearSolarPlot;
end

function [] = PlotSolarPowerDaily(time, longitude,latitude,solarPanelArea,solarPanelEf,scalingFactor,solarFluxScalingFactor)
     
    HelpersFunc = SolarHelpersFunc;

    % prepare variables to hold calcualted solar powers between each two
    % hours
    solarPower = zeros(3, 15);
    time.Hour = 5; 
    time.Minute = 0;
    
    for n = 0:14
        solarPower(1,n+1) = time.Hour;
        EoT = HelpersFunc.CalculateEoT(time);
        LSTM = HelpersFunc.CalculateLSTM(longitude);
        TC1 = HelpersFunc.CalculateTC(LSTM,longitude,EoT);
        LST1 = HelpersFunc.CalculateLST(time,TC1);
        DA1 = HelpersFunc.CalculateDeclinationAngle(time);
        HA1 = HelpersFunc.CalculateHourAngle(LST1);
        zenithAngle1 = HelpersFunc.CalculateZenithAngle(latitude,DA1,HA1);
        [~,~,SolarConstantCorrectedAndScaled1] = HelpersFunc.CalculateSolarFluxConstants(solarFluxScalingFactor,time);
        insolationIntensity1 = HelpersFunc.CalculateInsolationIntensity(SolarConstantCorrectedAndScaled1,zenithAngle1);
        collectedSolarPower1 = HelpersFunc.CalculateCollectedSolarPower(insolationIntensity1,solarPanelEf,solarPanelArea,scalingFactor);

        solarPower(2,n+1) = insolationIntensity1;
        solarPower(3,n+1) = collectedSolarPower1;

        %update time and calculate again
        time.Hour = time.Hour + 1;
    end
    
    % Plot the graph
    hGui = findobj('Tag','mySerialMonitor');
    handles = guidata(hGui);
    solarGraph = handles.aSolarGraph;
    hold(solarGraph,'on');
    hours = solarPower(1,:);
    SolarAvb = solarPower(2,:);
    SolarAvbCollected = solarPower(3,:);
    
    
    solarDailyAveHandle = plot(solarGraph,hours,SolarAvb,'-b','DisplayName','Avaiable Solar');
    solarDailyCollectedHandle = plot(solarGraph,hours,SolarAvbCollected,'-g','DisplayName','Collected Solar');
   
    set(solarDailyAveHandle,'visible','on');
    set(solarDailyCollectedHandle,'visible','on');
    legend(solarGraph,'show');
    xlabel(solarGraph,'Hours: 5am to 19pm');
    ylabel(solarGraph,'Solar Power (W/m^2)');
    xlim(solarGraph,[5 20]);
    set(solarGraph,'XTick',[5 : 1 : 19]);
    ylim(solarGraph,[0 1500])
    set(solarGraph,'YTick',[0 : 200 : 1500]);
    grid(solarGraph,'on');
   
   
    handles.varsolarDailyAveHandle=solarDailyAveHandle;
    handles.varSolarAvbCollected=SolarAvbCollected;
  
    guidata(solarGraph,handles);
    drawnow(); 
end

function [avbSolarPower,collectedSolarPower] = PlotSolarPowerInstantaneously(interval,time, longitude,latitude,solarPanelArea,solarPanelEf,scalingFactor,solarFluxScalingFactor)
    HelpersFunc = SolarHelpersFunc;
    
    % prepare variables to hold calcualted solar powers between each two
    % hours
    EoT = HelpersFunc.CalculateEoT(time);
    LSTM = HelpersFunc.CalculateLSTM(longitude);
    TC1 = HelpersFunc.CalculateTC(LSTM,longitude,EoT);
    LST1 = HelpersFunc.CalculateLST(time,TC1);
    DA1 = HelpersFunc.CalculateDeclinationAngle(time);
    HA1 = HelpersFunc.CalculateHourAngle(LST1);
    zenithAngle1 = HelpersFunc.CalculateZenithAngle(latitude,DA1,HA1);
    [~,~,SolarConstantCorrectedAndScaled1] = HelpersFunc.CalculateSolarFluxConstants(solarFluxScalingFactor,time);
    insolationIntensity1 = HelpersFunc.CalculateInsolationIntensity(SolarConstantCorrectedAndScaled1,zenithAngle1);
    collectedSolarPower1 = HelpersFunc.CalculateCollectedSolarPower(insolationIntensity1,solarPanelEf,solarPanelArea,scalingFactor);

    avbSolarPower = insolationIntensity1;collectedSolarPower = collectedSolarPower1;
   
    % Plot the graph
    hGui = findobj('Tag','mySerialMonitor');
    handles = guidata(hGui);
    solarGraph = handles.aSolarGraph;
    hold(solarGraph,'on');
    time.Hour = 8; % This is just a test to alwayse start from 8 in the morning.
    x = time.Hour;
    y1 = insolationIntensity1;
    y2 = collectedSolarPower1;
    
    solarInstantaneousAveHandle = plot(solarGraph,[x y1],'*','DisplayName','Avaiable Solar Right Now');
    legend(solarGraph,'-DynamicLegend');
    solarInstantaneousCollectedHandle = plot(solarGraph,[x y2],'o','DisplayName','Collected Solar Right Now');
    legend(solarGraph,'-DynamicLegend');
   
   
    set(solarInstantaneousAveHandle,'visible','on');
    set(solarInstantaneousCollectedHandle,'visible','on');
    
    legend(solarGraph,'show');

   
    handles.varSolarInstantaneousAveHandle=solarInstantaneousAveHandle;
    handles.varSolarInstantaneousCollectedHandle=solarInstantaneousCollectedHandle;
    
    guidata(solarGraph,handles);
    drawnow();
    
    assignin('base','darwinTime',time);
    CreateTimerForPlotSolarPowerInstantaneously(interval);
end

function [] = updateDisplay(interval)

    HelpersFunc = SolarHelpersFunc;
    
    % get saved information about the location adn time
    time = evalin('base', 'darwinTime');
    longitude = evalin('base', 'longitude');
    latitude = evalin('base', 'latitude');
    solarPanelArea = evalin('base', 'solarPanelArea');
    solarPanelEf = evalin('base', 'solarPanelEf');
    scalingFactor = evalin('base', 'overalScalingFactor');
    solarFluxScalingFactor = evalin('base', 'solarFluxScalingFactor');
    
    % update time so it reflects the current passed time, MAIN CODE
%     time = time + seconds(interval);
%     minute = time.Minute;
%     integer = time.Hour; 
%     x = double( integer + (((minute * 100) / 60) / 100));
    
    
     % update time so it reflects the current passed time, TEST FOR FAST
     % FORWARD
    time = time + minutes(interval*2);
    minute = time.Minute;
    integer = time.Hour; 
    x = double( integer + (((minute * 100) / 60) / 100));
    assignin('base','darwinTime',time);
    
    
    % Stop plotting after 7 PM
    if (integer > 19)
        tim = timerfind('Name', 'solarPowerTimer');
        if (strcmpi(get(tim,'Running'),'on') == 1)
            stop(tim);
            fprintf('Solar timer stopped [End of day]\n'); 
        end
    end
    
    % prepare variables to hold calcualted solar powers between each two
    % hours
    EoT = HelpersFunc.CalculateEoT(time);
    LSTM = HelpersFunc.CalculateLSTM(longitude);
    TC1 = HelpersFunc.CalculateTC(LSTM,longitude,EoT);
    LST1 = HelpersFunc.CalculateLST(time,TC1);
    DA1 = HelpersFunc.CalculateDeclinationAngle(time);
    HA1 = HelpersFunc.CalculateHourAngle(LST1);
    zenithAngle1 = HelpersFunc.CalculateZenithAngle(latitude,DA1,HA1);
    [~,~,SolarConstantCorrectedAndScaled1] = HelpersFunc.CalculateSolarFluxConstants(solarFluxScalingFactor,time);
    insolationIntensity1 = HelpersFunc.CalculateInsolationIntensity(SolarConstantCorrectedAndScaled1,zenithAngle1);
    % IMPORTANT 
    % scalingFactor is generated randomly so mimic some real data
    collectedSolarPower1 = HelpersFunc.CalculateCollectedSolarPower(insolationIntensity1,solarPanelEf,solarPanelArea,rand);

   
    % Plot the graph
    hGui = findobj('Tag','mySerialMonitor');
    handles = guidata(hGui);
    solarGraph = handles.aSolarGraph;
    hold(solarGraph,'on');
   
    y1 = insolationIntensity1;
    y2 = collectedSolarPower1;
    
    solarInstantaneousAveHandle = handles.varSolarInstantaneousAveHandle;
    solarInstantaneousCollectedHandle = handles.varSolarInstantaneousCollectedHandle;
    
    set(solarInstantaneousAveHandle,'Xdata',x);
    set(solarInstantaneousAveHandle,'Ydata',y1);
    set(solarInstantaneousCollectedHandle,'Xdata',x);
    set(solarInstantaneousCollectedHandle,'Ydata',y2);
    
   
    handles.varSolarInstantaneousAveHandle=solarInstantaneousAveHandle;
    handles.varSolarInstantaneousCollectedHandle=solarInstantaneousCollectedHandle;
  
    guidata(solarGraph,handles);
    drawnow(); 

end

function [] = CreateTimerForPlotSolarPowerInstantaneously(interval)
    mTimer = timerfind('Name', 'solarPowerTimer');
    if ~isempty(mTimer) %timer exist, start or stop
        if isvalid(mTimer)
            if (strcmpi(get(mTimer,'Running'),'off') == 1)
                start(mTimer);
            else
                stop(mTimer);
            end
        else
            fprintf('Something wrong with plottingTimer\n'); 
        end
    else %create the timer and start it
         %Create timer
         solarPowerTimer = timer;
         set(solarPowerTimer,'executionMode','fixedRate');
         set(solarPowerTimer,'Name','solarPowerTimer');
         set(solarPowerTimer,'ObjectVisibility','on');
         set(solarPowerTimer,'TimerFcn',@(~,~)updateDisplay(interval));
         set(solarPowerTimer,'StopFcn',@(~,~)disp('Solar power timer stopped'));
         set(solarPowerTimer,'Period',interval);
         start(solarPowerTimer);
    end
end

function [] = ClearSolarPlot()
    mTimer = timerfind('Name', 'solarPowerTimer');
    if ~isempty(mTimer) %timer exist, start or stop
        if isvalid(mTimer)
            if (strcmpi(get(mTimer,'Running'),'on') == 1)
                stop(mTimer);
            end
            delete(mTimer);
        end
    end

    hGui = findobj('Tag','mySerialMonitor');
    handles = guidata(hGui);
    solarGraph = handles.aSolarGraph;
    
   
    
    if (isfield(handles,'varsolarDailyAveHandle'))
        if (ishandle(handles.varSolarAvbCollected))
            delete(handles.varSolarAvbCollected);
            delete(handles.varSolarAvbCollected);
            delete(handles.varSolarInstantaneousAveHandle);
            delete(handles.varSolarInstantaneousCollectedHandle);
        end
    end
    
    axes(solarGraph);
    cla reset;
   
end