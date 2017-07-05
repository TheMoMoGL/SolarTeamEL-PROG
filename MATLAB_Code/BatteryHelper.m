function BatteryHelper = BatteryHelper
    BatteryHelper.plotStateOfChargeDaily = @plotStateOfChargeDaily;
    BatteryHelper.createPlotCurrentSocTimer = @createPlotCurrentSocTimer;
    BatteryHelper.plotCurrentStateOfCharge = @plotCurrentStateOfCharge;
    BatteryHelper.createCurrentSocSimulatorTimer = @createCurrentSocSimulatorTimer;
end


function plotStateOfChargeDaily(dayNumber)
    stateOfChargeDailyUsage = evalin('base','stateOfChargeDailyUsage');
    hGui = findobj('Tag','mySerialMonitor');
    handles = guidata(hGui);
    chargeGraph = handles.aChargeGraph;
    hold(chargeGraph,'on');
    
    upperMax = stateOfChargeDailyUsage(dayNumber);
    
    
    xValues = [8 17]; % Houser
    yValues = [1 upperMax]; % from empty[0] to full[1]
    stateOfChargeDaily = plot(chargeGraph,xValues,yValues,'-b','DisplayName','Predicted Discharge');
    set(stateOfChargeDaily,'visible','on');
    legend(chargeGraph,'-DynamicLegend');
    legend(chargeGraph,'show');
    xlabel(chargeGraph,'Hours: 5am to 17pm');
    ylabel(chargeGraph,sprintf('State of Charge Day [%d]',dayNumber));
    xlim(chargeGraph,[8 17]);
    %set(chargeGraph,'XTick',[5 : 1 : 19]);
    ylim(chargeGraph,[0 1])
    set(chargeGraph,'YTick',[0 : 0.1 : 1]);
    grid(chargeGraph,'on');
   
   
    handles.varstateOfChargeDailyHandle=stateOfChargeDaily;
    
    guidata(chargeGraph,handles);
    drawnow(); 
end

function plotCurrentStateOfCharge()
    % TODO make sure the time zone is correct otherwise you will get wrong
    % values
    carInfo = evalin('base','CarInfo');
    cstateOfCharge = carInfo.ChargeState;
    time = datetime('now');
    integer = time.Hour;
    minute = time.Minute;
    xValue  = double( integer + (((minute * 100) / 60) / 100));
    
    
    hGui = findobj('Tag','mySerialMonitor');
    handles = guidata(hGui);
    chargeGraph = handles.aChargeGraph;
    hold(chargeGraph,'on');
     
    currentStateOfCharge = plot(chargeGraph,xValue,cstateOfCharge,'r*','DisplayName','Current SoC');
    isFirstSoC = evalin('base','isFirstSoC');
    if (isFirstSoC == 0)
        isFirstSoC = 1;
        assignin('base','isFirstSoC',isFirstSoC);
        legend(chargeGraph,'-DynamicLegend');
        set(currentStateOfCharge,'visible','on');
        legend(chargeGraph,'show');
    end
    
   
    handles.varcurrentStateOfCharge=currentStateOfCharge;
    guidata(chargeGraph,handles);
    drawnow(); 

end

function createPlotCurrentSocTimer(interval)
     mTimer = timerfind('Name', 'currentSocTimer');
    if ~isempty(mTimer) %timer exist, start or stop
        if isvalid(mTimer)
            if (strcmpi(get(mTimer,'Running'),'off') == 1)
                start(mTimer);
            else
                stop(mTimer);
            end
        else
            fprintf('Something wrong with currentSocTimer\n'); 
        end
    else %create the timer and start it
         %Create timer
         currentSocTimer = timer;
         set(currentSocTimer,'executionMode','fixedRate');
         set(currentSocTimer,'Name','currentSocTimer');
         set(currentSocTimer,'ObjectVisibility','on');
         set(currentSocTimer,'TimerFcn',@(~,~)plotCurrentStateOfCharge());
         set(currentSocTimer,'StopFcn',@(~,~)disp('currentSocTimer stopped'));
         set(currentSocTimer,'Period',interval);
         start(currentSocTimer);
    end
end

function createCurrentSocSimulatorTimer(interval)
    mTimer = timerfind('Name', 'currentSocSimulatorTimer');
    if ~isempty(mTimer) %timer exist, start or stop
        if isvalid(mTimer)
            if (strcmpi(get(mTimer,'Running'),'off') == 1)
                start(mTimer);
            else
                stop(mTimer);
            end
        else
            fprintf('Something wrong with currentSocSimulatorTimer\n'); 
        end
    else %create the timer and start it
         %Create timer
         currentSocSimulatorTimer = timer;
         set(currentSocSimulatorTimer,'executionMode','fixedRate');
         set(currentSocSimulatorTimer,'Name','currentSocSimulatorTimer');
         set(currentSocSimulatorTimer,'ObjectVisibility','on');
         set(currentSocSimulatorTimer,'TimerFcn',@(~,~)manipulateSoc());
         set(currentSocSimulatorTimer,'StopFcn',@(~,~)disp('currentSocSimulatorTimer stopped'));
         set(currentSocSimulatorTimer,'Period',interval);
         start(currentSocSimulatorTimer);
    end
end

function manipulateSoc()
    carInfo = evalin('base','CarInfo');
    rng shuffle;
    carInfo.ChargeState = carInfo.ChargeState - ((rand()-0.5));
    
    assignin('base','CarInfo',carInfo);
end