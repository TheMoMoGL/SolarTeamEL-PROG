%%This is the serial manager all port configuration happens here

function SerialManager = SerialManager
    SerialManager.setupSerial=@setupSerial;
    SerialManager.gpsCallBackFunction=@gpsCallBackFunction;
    SerialManager.gpsEmptyCallBackFunction=@gpsEmptyCallBackFunction;
    SerialManager.gpsProcessIncomingData=@gpsProcessIncomingData;
    SerialManager.gpsGetCoordinates=@gpsGetCoordinates;
    SerialManager.gpsGetSpeed=@gpsGetSpeed;
    SerialManager.arduinoCallBackFunction=@arduinoCallBackFunction;
    SerialManager.arduinoEmptyCallBackFunction=@arduinoEmptyCallBackFunction;
    SerialManager.arduinoProcessIncomingData=@arduinoProcessIncomingData;
    SerialManager.arduinoSendCommand=@arduinoSendCommand;
    SerialManager.readTerminal=@readTerminal;
    SerialManager.updateGUItext=@updateGUItext;
    SerialManager.updateGpsRawGUItext=@updateGpsRawGUItext;
    SerialManager.updateGpsLocationGUItext=@updateGpsLocationGUItext;
    SerialManager.updateGpsSpeedGUItext=@updateGpsSpeedGUItext;
    SerialManager.updateGpsDistanceGUItext=@updateGpsDistanceGUItext;
    SerialManager.updateCarSpeedGUItext=@updateCarSpeedGUItext;
    SerialManager.updateCarThrottleGUItext=@updateCarThrottleGUItext;
    SerialManager.updateCarCCGUItext=@updateCarCCGUItext;
    SerialManager.updateCarCCSpeedGUItext=@updateCarCCSpeedGUItext;
    SerialManager.updatePIDGUItext=@updatePIDGUItext;
    SerialManager.updateGpsInfoGUItext=@updateGpsInfoGUItext;
    SerialManager.gpsGetCoordinates=@gpsGetCoordinates;
    SerialManager.gpsGetGpsInfo=@gpsGetGpsInfo;
    SerialManager.gpsGetSpeed=@gpsGetSpeed;
    SerialManager.pullSpeed=@pullSpeed;
    SerialManager.pullCarInfo=@pullCarInfo;
    SerialManager.pullCruseControl=@pullCruseControl;
    SerialManager.pullCruseControlSpeed=@pullCruseControlSpeed;
    SerialManager.pullThrottle=@pullThrottle;
    SerialManager.getAndUpdateSpeed=@getAndUpdateSpeed;
    SerialManager.getAndUpdateThrottle =@getAndUpdateThrottle;   
    SerialManager.cleanupSerial=@cleanupSerial;
    SerialManager.cleanupTimers=@cleanupTimers;
    SerialManager.DoHouseKeeping=@DoHouseKeeping;
    SerialManager.createSpeedPlot = @createSpeedPlot;
    SerialManager.createPlotTimer = @createPlotTimer;
    SerialManager.startPlotTimer = @startPlotTimer;
    SerialManager.startTimer = @startTimer;
    SerialManager.stopTimer = @stopTimer;
    SerialManager.deleteTimer = @deleteTimer;
    SerialManager.updateSpeedData = @updateSpeedData;
    SerialManager.updateSpeedData2 = @updateSpeedData2;
    SerialManager.update_display = @update_display;
    SerialManager.startTimeCounterTimer = @startTimeCounterTimer;
    SerialManager.stopTimeCounterTimer = @stopTimeCounterTimer;
    SerialManager.CreateTimeCounterTimer = @CreateTimeCounterTimer;
    SerialManager.disconnectGPS = @disconnectGPS;
end

function[obj,flag] = setupSerial(comPort,BuadRate,terminator,callBackFunc,emptyCallBackFunc)
    flag = 1;
    obj = serial(comPort);
    flushinput(obj);
    flushoutput(obj);

    if (isvalid(obj)>0)
        set(obj,'DataBits',8);
        set(obj,'StopBits',1);
        set(obj,'BaudRate',BuadRate);
        set(obj,'Parity','none');
        obj.Terminator = terminator;
        obj.BytesAvailableFcnMode = 'terminator';
        %obj.BytesAvailableFcnCount = 4; this can be for GPS bytes
        obj.BytesAvailableFcn = callBackFunc;
        obj.OutputEmptyFcn = emptyCallBackFunc;

        
        try
            fopen(obj);
        catch ME
            warning(ME);
        end
    end
end

function[out] = gpsCallBackFunction(val1, obj, eventStruct, val2)
    serialObject = evalin('base', 'gpsSerial'); %evalin(‘workspace name’, ‘variable name’)
    %[A, count] = fscanf(serialObject,'%s');
    str = fscanf(serialObject);
    %pricess incomming data
    gpsProcessIncomingData(str);
    out = str;
end

function[out] = gpsEmptyCallBackFunction(val1, obj, eventStruct, val2)
     fprintf('\nempty Called\n');
end

function[out] = gpsProcessIncomingData(incomingData)
     assignin('base','gpsData',incomingData); %assignin(‘workspace name’, ‘variable’, value)
     updateGpsRawGUItext(incomingData);
     gpsGetCoordinates(incomingData);
     %gpsGetCoordinates(incomingData);
     %gpsGetSpeed(incomingData);
     out = incomingData;    
end


function [selector,value] = parseData(incomingData)
    selector = 'NA';
    header = incomingData(1,1);
    footer = incomingData(1,end);
    value = incomingData(1,2:end-1);
   
    if  ((strcmpi(header,'S') == 1) && (strcmpi(footer,'D') == 1))%Speed msg S00D
        selector = 'Speed';
    elseif  ((strcmpi(header,'P') == 1) && (strcmpi(footer,'D') == 1))%PID P00I00I00D
        selector = 'PID';
    elseif  ((strcmpi(header,'C') == 1) && (strcmpi(footer,'S') == 1))%Cruse control speed C00S
        selector = 'CruseSpeed';
    elseif  ((strcmpi(header,'T') == 1) && (strcmpi(footer,'T') == 1))%Throttle value T00T
        selector = 'Throttle';
    elseif  ((strcmpi(header,'C') == 1) && (strcmpi(footer,'R') == 1))%All values C00I00I00I00R
        selector = 'ALL';
    elseif  ((strcmpi(header,'C') == 1) && (strcmpi(footer,'C') == 1))%Cruse control status C0C
        selector = 'Cruse';
        if ((strcmpi(value,'1') == 1))
            value = 'Enabled';
        else
            value = 'Disabled';
        end
        
    end
end

function[longitude,latitude] = gpsGetGpsInfo(rawNmeaLine)
    header = evalin('base', 'NmeaMCHeader'); %evalin(‘workspace name’, ‘variable name’)

    fields = textscan(rawNmeaLine,'%s','delimiter',',');
    fields = char(fields{1});
    test =strtrim(fields(1,:));
    
    % we found $GPGGA
    if (strcmpi(header,test) == 1)
        [data,err] = NMEAlineRead(rawNmeaLine);
        if (err == 0)
            longitude = data.longitude;
            latitude = data.latitude;
            updateGpsInfoGUItext(data.longitude,data.latitude,data.BODCTime);
        end
    end
end


function[longitude,latitude] = gpsGetCoordinates(rawNmeaLine)
    header = evalin('base', 'NmeaMCHeader'); %evalin(‘workspace name’, ‘variable name’)

    fields = textscan(rawNmeaLine,'%s','delimiter',',');
    fields = char(fields{1});
    test =strtrim(fields(1,:));
    
    % we found $GPGGA
    if (strcmpi(header,test) == 1)
        [data,err] = NMEAlineRead(rawNmeaLine);
        if (err == 0)
            longitude = data.longitude;
            latitude = data.latitude;
            en = evalin('base','updateCoordinatesFromGPS');
            if (en == 1)
                assignin('base','longitude',longitude);
                assignin('base','latitude',latitude);
            end
            updateGpsInfoGUItext(data.longitude,data.latitude,data.groundspeed.kph,data.UtcTime,data.fixmode);
        end
    end
end

function[speed] = gpsGetSpeed(rawNmeaLine)
    header = evalin('base', 'NmeaSpeedHeader'); %evalin(‘workspace name’, ‘variable name’)
    fields = textscan(rawNmeaLine,'%s','delimiter',',');
    fields = char(fields{1});
    test =strtrim(fields(1,:));
    
    % we found $GPVTG
    if (strcmpi(header,test) == 1)
        [data,err] = NMEAlineRead(rawNmeaLine);
        if (err == 0)
            speed = data.speed;
          
            updateGpsSpeedGUItext(data.speed);
        end
    end
end

function [] = updateGpsRawGUItext(value)
    % get the handle of the GUI
    hGui = findobj('Tag','mySerialMonitor');

    if ~isempty(hGui)
        % get the handles to the controls of the GUI
        handles = guidata(hGui);
    else
        handles = [];
    end
    
    % update the GUI controls
       if ~isempty(handles)

           % update the controls
           handles.txtRawGps;
           set(handles.txtRawGps, 'String', value);
       end

       % make sure that the GUI is refreshed with new content
       %drawnow();
end

function [] = updateGpsLocationGUItext(longitude,latitude,time)
    % get the handle of the GUI
    hGui = findobj('Tag','mySerialMonitor');

    if ~isempty(hGui)
        % get the handles to the controls of the GUI
        handles = guidata(hGui);
    else
        handles = [];
    end
    
    % update the GUI controls
       if ~isempty(handles)

           % update the controls;
           handles.txtLong;
           set(handles.txtLong, 'String', longitude);
           
           handles.txtLat;
           set(handles.txtLat, 'String', latitude);
           
           handles.txtTime;
           set(handles.txtTime, 'String', time);
       end

       % make sure that the GUI is refreshed with new content
       %drawnow();
end

function updateCarSpeedGUItext(speed)
    % get the handle of the GUI
    hGui = findobj('Tag','mySerialMonitor');

    if ~isempty(hGui)
        % get the handles to the controls of the GUI
        handles = guidata(hGui);
    else
        handles = [];
    end
    
    % update the GUI controls
       if ~isempty(handles)

           % update the controls
           handles.txtCarSpeed;
           set(handles.txtCarSpeed, 'String', speed);
       end

       % make sure that the GUI is refreshed with new content
       %drawnow();
end

function updateCarCCGUItext(ccStatus)
    % get the handle of the GUI
    hGui = findobj('Tag','mySerialMonitor');
    
    if ~isempty(hGui)
        % get the handles to the controls of the GUI
        handles = guidata(hGui);
    else
        handles = [];
    end
    
    % update the GUI controls
       if ~isempty(handles)

           % update the controls
           handles.txtCruseControl;
           set(handles.txtCruseControl, 'String', ccStatus);
       end

       % make sure that the GUI is refreshed with new content
       %drawnow();
end


function updateCarCCSpeedGUItext(ccSpeed)
    % get the handle of the GUI
    hGui = findobj('Tag','mySerialMonitor');
    
    if ~isempty(hGui)
        % get the handles to the controls of the GUI
        handles = guidata(hGui);
    else
        handles = [];
    end
    
    % update the GUI controls
       if ~isempty(handles)

           % update the controls
           handles.txtCCSpeed;
           set(handles.txtCCSpeed, 'String', ccSpeed);
       end

       % make sure that the GUI is refreshed with new content
       %drawnow();
end

function updateCarThrottleGUItext(throttle)
    % get the handle of the GUI
    hGui = findobj('Tag','mySerialMonitor');
    
    if ~isempty(hGui)
        % get the handles to the controls of the GUI
        handles = guidata(hGui);
    else
        handles = [];
    end
    
    % update the GUI controls
       if ~isempty(handles)

           % update the controls
           handles.txtThrottle;
           set(handles.txtThrottle, 'String', throttle);
       end

       % make sure that the GUI is refreshed with new content
       %drawnow();
end


function [] = updateGpsSpeedGUItext(speed)
    % get the handle of the GUI
    hGui = findobj('Tag','mySerialMonitor');

    if ~isempty(hGui)
        % get the handles to the controls of the GUI
        handles = guidata(hGui);
    else
        handles = [];
    end
    
    % update the GUI controls
       if ~isempty(handles)

           % update the controls
           handles.txtSpeed;
           set(handles.txtSpeed, 'String', speed);
       end

       % make sure that the GUI is refreshed with new content
       %drawnow();
end


function [] = updateGpsInfoGUItext(longitude,latitude,speed,time,gpsMode)
    % get the handle of the GUI
    hGui = findobj('Tag','mySerialMonitor');

    if ~isempty(hGui)
        % get the handles to the controls of the GUI
        handles = guidata(hGui);
    else
        handles = [];
    end
    
    % update the GUI controls
       if ~isempty(handles)

           % update the controls
           handles.txtLong;
           set(handles.txtLong, 'String', longitude);
           
           handles.txtLat;
           set(handles.txtLat, 'String', latitude);
           
           handles.txtTime;
           set(handles.txtTime, 'String', time);

           handles.txtSpeed;
           set(handles.txtSpeed, 'String', speed);

           handles.txtGpsMode;
           set(handles.txtGpsMode, 'String', gpsMode);
       end

       % make sure that the GUI is refreshed with new content
       drawnow();
end

function updatePIDGUItext(p,i,d)
    % get the handle of the GUI
    hGui = findobj('Tag','mySerialMonitor');

    if ~isempty(hGui)
        % get the handles to the controls of the GUI
        handles = guidata(hGui);
    else
        handles = [];
    end
    
    % update the GUI controls
       if ~isempty(handles)

           % update the controls
           handles.txtPIDP;
           set(handles.txtPIDP, 'String', p);
           
           handles.txtPIDI;
           set(handles.txtPIDI, 'String', i);
           
           handles.txtPIDD;
           set(handles.txtPIDD, 'String', d);
       end

       % make sure that the GUI is refreshed with new content
       drawnow();
end




function[out] = arduinoCallBackFunction(val1, obj, eventStruct, val2)
    serialObject = evalin('base', 'arduinoSerial'); %evalin(‘workspace name’, ‘variable name’)
    %[A, count] = fscanf(serialObject,'%s');
   
    str = fscanf(serialObject);
    %pricess incomming data
    arduinoProcessIncomingData(strtrim(str));
    out = str;
end

function[out] = arduinoEmptyCallBackFunction(val1, obj, eventStruct, val2)
     fprintf('\nempty Called\n');
end

function[out] = arduinoProcessIncomingData(incomingData)
    carzyRead = evalin('base', 'arduinoReadContinuely');
    
    [selector,value] = parseData(incomingData);
    cSpeed = evalin('base', 'cSpeed');
    ccSpeed = evalin('base', 'ccSpeed');
    %startTimeCounterTimer(1);
    switch (selector)
        case 'Speed'
            cSpeed = str2num(value);
            assignin('base','cSpeed',cSpeed)
            updateSpeedData(1,cSpeed,2,ccSpeed);
            updateCarSpeedGUItext(value);
        case 'Cruse'
            updateCarCCGUItext(value);
        case 'CruseSpeed'
            ccSpeed = str2num(value);
            assignin('base','ccSpeed',ccSpeed)
            updateSpeedData2(2,ccSpeed,1,cSpeed);
            updateCarCCSpeedGUItext(value);
        case 'PID'
            pid = strsplit(value,'I');
            updatePIDGUItext(pid(1),pid(2),pid(3));
        case 'Throttle'
            updateCarThrottleGUItext(value);
        case 'ALL'
            values = strsplit(value,'I');
            CarInfo = evalin('base','CarInfo');
            CarInfo.Speed = str2double(values(1));
            CarInfo.CruseSpeed = str2double(values(2));
            CarInfo.CollectedSolarPower = str2double(values(3));
            CarInfo.ChargeState = str2double(values(4));
            assignin('base','CarInfo',CarInfo);
        otherwise
            % can change carzyread to switch with more modes
            if (carzyRead == 1)
                fprintf('Arduino replys: = %s\n',incomingData);
                updateGUItext(incomingData);
            else
                assignin('base','arduinoSerialReply',incomingData); %assignin(‘workspace name’, ‘variable’, value)
            end
    end
    
    % alwayse update incoming data
    updateGUItext(incomingData);
    out = incomingData;    
end

function updateSpeedData(rowIndex,value,alternateIndex,oldValue)
    sp = evalin('base', 'speedData');
    tCounter = evalin('base', 'timeCounter');
    %tCounter = tCounter + 1;
    %assignin('base','timeCounter',tCounter)
    sp(3,tCounter) = tCounter;
    sp(rowIndex,tCounter) = value;
    sp(alternateIndex,tCounter) = oldValue;
    assignin('base','speedData',sp)
end

function updateSpeedData2(rowIndex,value,alternateIndex,oldValue)
    sp = evalin('base', 'speedData');
    tCounter = evalin('base', 'timeCounter');
    %tCounter = tCounter + 1;
    %assignin('base','timeCounter',tCounter)
    sp(3,tCounter) = tCounter;
    sp(rowIndex,tCounter) = value;
    sp(alternateIndex,tCounter) = oldValue;
    assignin('base','speedData',sp)
end

function CreateTimeCounterTimer(interval)
    timeTicker = timer;
    set(timeTicker,'executionMode','fixedRate');
    set(timeTicker,'Name','timeTicker');
    set(timeTicker,'ObjectVisibility','on');
    set(timeTicker,'StartDelay',1);
    set(timeTicker,'TimerFcn',@(~,~)increaseCounter());
    %set(timeTicker,'StartFcn',@(~,~)startTimer('speedTimer'));
    %set(timeTicker,'StopFcn',@(~,~)stopTimer('speedTimer'));
    set(timeTicker,'Period',interval);
end

function startTimeCounterTimer()
     mTimer = timerfind('Name', 'timeTicker');
    if ~isempty(mTimer) %timer exist, start or stop
        if isvalid(mTimer)
            if (strcmpi(get(mTimer,'Running'),'off') == 1)
                start(mTimer);
            else
                %stop(mTimer);
            end
        else
            fprintf('Something wrong with speedTimer\n'); 
        end
    end
end

function stopTimeCounterTimer()
    stopTimer('timeTicker');
end

function increaseCounter()
 c = evalin('base', 'timeCounter');
 c = c+1;
 assignin('base','timeCounter',c);
end

function  pullSpeed(serialObject,command , interval, stopORstart )
    mTimer = timerfind('Name', 'speedTimer');
    if ~isempty(mTimer) %timer exist, start or stop
        if isvalid(mTimer)
            if (strcmpi(get(mTimer,'Running'),'off') == 1)
                start(mTimer);
            else
                stop(mTimer);
            end
        else
            fprintf('Something wrong with speedTimer\n'); 
        end
    else %create the timer and start it
         speedTimer = timer;
         set(speedTimer,'executionMode','fixedRate');
         set(speedTimer,'Name','speedTimer');
         set(speedTimer,'ObjectVisibility','on');
         set(speedTimer,'StartDelay',1);
         set(speedTimer,'TimerFcn',@(~,~)getAndUpdateSpeed(serialObject,command));
         set(speedTimer,'StartFcn',@(~,~)startTimer('speedTimer'));
         set(speedTimer,'StopFcn',@(~,~)stopTimer('speedTimer'));
         set(speedTimer,'Period',interval);
         start(speedTimer);
    end
end

function  pullCarInfo(serialObject,command , interval, stopORstart )
    mTimer = timerfind('Name', 'carInfoTimer');
    if ~isempty(mTimer) %timer exist, start or stop
        if isvalid(mTimer)
            if (strcmpi(get(mTimer,'Running'),'off') == 1)
                start(mTimer);
            else
                stop(mTimer);
            end
        else
            fprintf('Something wrong with carInfoTimer\n'); 
        end
    else %create the timer and start it
         carInfoTimer = timer;
         set(carInfoTimer,'executionMode','fixedRate');
         set(carInfoTimer,'Name','carInfoTimer');
         set(carInfoTimer,'ObjectVisibility','on');
         set(carInfoTimer,'StartDelay',1);
         set(carInfoTimer,'TimerFcn',@(~,~)getAndUpdateCarInfo(serialObject,command));
         set(carInfoTimer,'StartFcn',@(~,~)startTimer('speedTimer'));
         set(carInfoTimer,'StopFcn',@(~,~)stopTimer('speedTimer'));
         set(carInfoTimer,'Period',interval);
         start(carInfoTimer);
    end
end


function  pullCruseControl(serialObject,command , interval, stopORstart )
    mTimer = timerfind('Name', 'ccTime');
    if ~isempty(mTimer) %timer exist, start or stop
        if isvalid(mTimer)
            if (strcmpi(get(mTimer,'Running'),'off') == 1)
                start(mTimer);
            else
                stop(mTimer);
            end
        else
            fprintf('Something wrong with ccTime\n'); 
        end
    else %create the timer and start it
        ccTime = timer;
        set(ccTime,'executionMode','fixedRate');
        set(ccTime,'Name','ccTime');
        set(ccTime,'ObjectVisibility','on');
        set(ccTime,'StartDelay',1);
        set(ccTime,'TimerFcn',@(~,~)getAndUpdateCruseControlStatus(serialObject,command));
        set(ccTime,'StartFcn',@(~,~)startTimer('ccTime'));
        set(ccTime,'StopFcn',@(~,~)stopTimer('ccTime'));
        set(ccTime,'Period',interval);
        start(ccTime);
    end
end

function  pullCruseControlSpeed(serialObject,command , interval, stopORstart )
    mTimer = timerfind('Name', 'ccSpeedTime');
    if ~isempty(mTimer) %timer exist, start or stop
        if isvalid(mTimer)
            if (strcmpi(get(mTimer,'Running'),'off') == 1)
                start(mTimer);
            else
                stop(mTimer);
            end
        else
            fprintf('Something wrong with ccSpeedTime\n'); 
        end
    else %create the timer and start it
         ccSpeedTime = timer;
         set(ccSpeedTime,'executionMode','fixedRate');
         set(ccSpeedTime,'Name','ccSpeedTime');
         set(ccSpeedTime,'ObjectVisibility','on');
         set(ccSpeedTime,'StartDelay',1);
         set(ccSpeedTime,'TimerFcn',@(~,~)getAndUpdateCCSpeed(serialObject,command));
         set(ccSpeedTime,'StartFcn',@(~,~)startTimer('ccSpeedTime'));
         set(ccSpeedTime,'StopFcn',@(~,~)stopTimer('ccSpeedTime'));
         set(ccSpeedTime,'Period',interval);
         start(ccSpeedTime);
    end
end

function  pullThrottle(serialObject,command , interval, stopORstart )
    mTimer = timerfind('Name', 'throttleTimer');
    if ~isempty(mTimer) %timer exist, start or stop
        if isvalid(mTimer)
            if (strcmpi(get(mTimer,'Running'),'off') == 1)
                start(mTimer);
            else
                stop(mTimer);
            end
        else
            fprintf('Something wrong with throttleTimer\n'); 
        end
    else %create the timer and start it
         throttleTimer = timer;
         set(throttleTimer,'executionMode','fixedRate');
         set(throttleTimer,'Name','throttleTimer');
         set(throttleTimer,'ObjectVisibility','on');
         set(throttleTimer,'StartDelay',1);
         set(throttleTimer,'TimerFcn',@(~,~)getAndUpdateThrottle(serialObject,command));
         set(throttleTimer,'StartFcn',@(~,~)startTimer('throttleTimer'));
         set(throttleTimer,'StopFcn',@(~,~)stopTimer('throttleTimer'));
         set(throttleTimer,'Period',interval);
         start(throttleTimer);
    end
end

function getAndUpdateThrottle(serialObject,command)
    fprintf(serialObject,command); 
    fprintf('getAndUpdateThrottle executed\n'); 
end

function getAndUpdateCCSpeed(serialObject,command)
    fprintf(serialObject,command); 
    fprintf('getAndUpdateCCSpeed executed\n'); 
end

function stopCCSpeedTimer(mTimer,~)
    delete(mTimer);
    fprintf('stopCCSpeedTimer Timer stopped & deleted\n'); 
end


function getAndUpdateSpeed(serialObject,command)
    fprintf(serialObject,command); 
    fprintf('getAndUpdateSpeed executed\n'); 
end

function getAndUpdateCarInfo(serialObject,command)
    fprintf(serialObject,command); 
    fprintf('getAndUpdateCarInfo executed\n'); 
end

function stopSpeedTimer(mTimer,~)
    delete(mTimer);
    fprintf('Speedometer Timer stopped & deleted\n'); 
end


function getAndUpdateCruseControlStatus(serialObject,command)
    fprintf(serialObject,command); 
    fprintf('getAndUpdateCruseControlStatus executed\n'); 
end

function stopCCTimer(mTimer,~)
    delete(mTimer);
    fprintf('Cruse Control Timer stopped & deleted\n'); 
end

function [ output ] = arduinoSendCommand( serialObject,command )
% Serial send command to Arduino
fprintf(serialObject,command);  
end

function [ output ] = readTerminal()
    output = input('Enter Serial Command:','s');
end

function [] = updateGUItext(value)
    % get the handle of the GUI
    hGui = findobj('Tag','mySerialMonitor');

    if ~isempty(hGui)
        % get the handles to the controls of the GUI
        handles = guidata(hGui);
    else
        handles = [];
    end
    
    % update the GUI controls
       if ~isempty(handles)

           % update the controls
           handles.txtIncommingDataFromXbee;
           set(handles.txtIncommingDataFromXbee, 'String', value);
       end

       % make sure that the GUI is refreshed with new content
       drawnow();
end

function createSpeedPlot(hObject)
    %create plots and graphs
    sp = evalin('base', 'speedData');
    from = evalin('base', 'timeFrom');
    to = evalin('base', 'timeTo');
    speedScale = evalin('base', 'speedScale');
    speedFrom = evalin('base', 'speedFrom');
    speedTo = evalin('base', 'speedTo');
    
     lastIndex = evalin('base', 'timeCounter');
     to = lastIndex;
    
     if (lastIndex < 30)
         from = 1;
         to = 30;
     else
         from = lastIndex - 29;
     end
     
   
    speeds = sp(1,from:to);
    cruseSpeed = sp(2,from:to);
    seconds = sp(3,from:to);
    
    x = [speeds;cruseSpeed];

    err = diff(x);
    errScaler = 1;
    err = abs(err(1:end)*errScaler);
    % get the handle of the GUI
    hGui = findobj('Tag','mySerialMonitor');
    handles = guidata(hGui);
    speedGraph = handles.accGraph;
    hold(speedGraph,'on');
    errHandle = plot(speedGraph,seconds,err,'-b','DisplayName','Error');
    %hold(speedGraph,'on');
    speedHandle = plot(speedGraph,seconds,speeds,'-or','DisplayName','Car Speed');
    %hold(speedGraph,'on');
    cruseHandle = plot(speedGraph,seconds,cruseSpeed,'-g','DisplayName','Cruse control Speed');
   
    set(errHandle,'visible','on');
    set(speedHandle,'visible','on');
    set(cruseHandle,'visible','on');
    legend(speedGraph,'show');
    xlabel(speedGraph,'Time: second');
    ylabel(speedGraph,'Speed (kh)');
    xlim(speedGraph,[from to])
    set(speedGraph, 'XTick', []);
    ylim(speedGraph,[speedFrom speedTo]);
    set(speedGraph,'YTick',[speedFrom : speedScale : speedTo]);
    grid(speedGraph,'on');
    grid(speedGraph,'minor');
   
    assignin('base','speedPlotCreated',1);
    assignin('base','timeFrom',from);
    assignin('base','timeTo',to);
    
    
    handles.varErrHandle=errHandle;
    handles.varSpeedHandle=speedHandle;
    handles.varCruseHandle=cruseHandle;

    guidata(hObject,handles);
end


function createPlotTimer(hObject,interval)
    mTimer = timerfind('Name', 'plottingTimer');
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
         plottingTimer = timer;
         set(plottingTimer,'executionMode','fixedRate');
         set(plottingTimer,'Name','plottingTimer');
         %set(plottingTimer,'StartDelay',2);
         set(plottingTimer,'ObjectVisibility','on');
         %set(plottingTimer,'TimerFcn',{@update_display,gcf});
         set(plottingTimer,'TimerFcn',@(~,~)update_display(hObject));
         %set(plottingTimer,'StartFcn',@(~,~)startTimer('plottingTimer'));
         set(plottingTimer,'StopFcn',@(~,~)disp('I got stopped'));
         set(plottingTimer,'Period',interval);
         %start(plottingTimer);
    end
end

function startPlotTimer()
     mTimer = timerfind('Name', 'plottingTimer');
    if ~isempty(mTimer) %timer exist, start or stop
        if isvalid(mTimer)
            if (strcmpi(get(mTimer,'Running'),'off') == 1)
                start(mTimer);
            else
                %stop(mTimer);
            end
        else
            fprintf('Something wrong with speedTimer\n'); 
        end
    end
end


function deleteTimer(timerName)
    tim = timerfind('Name', timerName);
    if isvalid(tim)
         %stop(tim);
         delete(tim);
         fprintf('%s Timer Timer stopped & deleted\n',timerName); 
    end
    
end

function startTimer(timerName)
    tim = timerfind('Name', timerName);
    if isvalid(tim)
        if (strcmpi(get(tim,'Running'),'off') == 1)
            start(tim);
            fprintf('%s Timer started\n',timerName); 
        else
            fprintf('%s Timer is already running\n',timerName); 
        end
    end
end
function stopTimer(timerName)
    tim = timerfind('Name', timerName);
    if isvalid(tim)
         if (strcmpi(get(tim,'Running'),'on') == 1)
            stop(tim);
            fprintf('%s Timer stopped\n',timerName); 
        else
            fprintf('%s Timer is already stopped\n',timerName); 
        end
    end
end
   


function update_display(hObject)
    % get plots handles
    fprintf('Plot timer executed\n'); 
    hGui = findobj('Tag','mySerialMonitor');
    handles = guidata(hGui);
    speedGraph = handles.accGraph;
    
    errHandle = handles.varErrHandle;
    speedHandle = handles.varSpeedHandle;
    cruseHandle = handles.varCruseHandle;


    % get data and create plots
    speedScale = evalin('base', 'speedScale');
    sp = evalin('base', 'speedData');
    timeFrom = evalin('base', 'timeFrom');
    timeTo = evalin('base', 'timeTo');
    speedFrom = evalin('base', 'speedFrom');
    speedTo = evalin('base', 'speedTo');
    xHelperCounter = evalin('base', 'xHelperCounter');
    xHelperCounter = xHelperCounter + 1;
  
    
    lastIndex = evalin('base', 'timeCounter');
    
    if (lastIndex > timeTo)
%             timeFrom = timeFrom + 1;
%             timeTo = lastIndex-timeFrom;
            
            timeFrom = timeFrom + 1;
            timeTo = lastIndex - 1;%-timeFrom;
            %timeTo = lastIndex+(lastIndex-timeTo)-1;
    end

    speeds = sp(1,timeFrom:timeTo);
    cruseSpeed = sp(2,timeFrom:timeTo);
    seconds = sp(3,timeFrom:timeTo);
    x = [speeds;cruseSpeed];

    err = diff(x);
    errScaler = 1;
    err = abs(err(1:end)*errScaler);

    set(errHandle,'Ydata',err);
    set(errHandle,'Xdata',seconds);
    set(speedHandle,'Ydata',speeds);
    set(speedHandle,'Xdata',seconds);
    set(cruseHandle,'Ydata',cruseSpeed);
    set(cruseHandle,'Xdata',seconds);
    
    xlim(speedGraph,[timeFrom timeTo]);
    ylim(speedGraph,[speedFrom speedTo]);
  
    set(speedGraph, 'XTick', []);
    %set(speedGraph, 'XTick', [timeFrom : 1: timeTo]);
    set(speedGraph,'YTick',[speedFrom : speedScale : speedTo]);
  
    assignin('base','timeFrom',timeFrom);
    assignin('base','timeTo',timeTo); 
    assignin('base','xHelperCounter',xHelperCounter); 
    
    drawnow;
    guidata(hObject,handles);
end

function [success] = disconnectGPS(serialPort)
    try
        if isvalid(serialPort)
            stat = get(serialPort, 'Status');
            if (strcmpi(stat,'open')==1)
                 fclose(serialPort);
            end
            delete(serialPort);
        end
        success = 1;
    catch
        success = 0;
    end
end

function DoHouseKeeping()
     cleanupTimers()
     W = evalin('base','whos'); %or 'caller'
     doesASerialexist = ismember('arduinoSerial',[W(:).name])
     doesGSerialexist = ismember('gpsSerial',[W(:).name])
   
    
%      if (doesASerialexist)
%          as = evalin('base', 'arduinoSerial');
%          if (isvalid(as))
%             cleanupSerial(as);
%          end
%      end
%      
%      if (doesGSerialexist)
%          gs = evalin('base', 'gpsSerial');
%          if (isvalid(gs))
%             cleanupSerial(gs);
%          end
%      end
     
     clc
     clear all;
end

function cleanupTimers()
    % Delete all timers from memory.
    listOfTimers = timerfindall;
    if ~isempty(listOfTimers)
        delete(listOfTimers(:));
    end
end

function cleanupSerial(serialObject)
    fclose(serialObject);
    delete(serialObject);
    clear serialObject;
end