function varargout = SolarProject(varargin)
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SolarProject_OpeningFcn, ...
                   'gui_OutputFcn',  @SolarProject_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDITbtn


% --- Executes just before SolarProject is made visible.
function SolarProject_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SolarProject (see VARARGIN)

% Choose default command line output for SolarProject
handles.output = hObject;

%% Tabs Code
% Settings
TabFontSize = 10;
TabNames = {'Main','Setting','Info'};
FigWidth = 0.900;

% Figure resize
set(handles.mySerialMonitor,'Units','normalized')
pos = get(handles. mySerialMonitor, 'Position');
set(handles. mySerialMonitor, 'Position', [pos(1) pos(2) FigWidth pos(4)])

% Tabs Execution
handles = TabsFun(handles,TabFontSize,TabNames);

% Serial Manager object
handles.SerialHelper = SerialManager;

% Solar helper object
handles.SolarHelper = SolarCaller;

% Map helper object
handles.MapHelper = MapHelper;

% Battery helper object
handles.BatteryHelper = BatteryHelper;

% Update handles structure
guidata(hObject, handles);

% Move the window to center
movegui(gcf,'center')

% UIWAIT makes SolarProject wait for user response (see UIRESUME)
% uiwait(handles.mySerialMonitor);

% --- TabsFun creates axes and text objects for tabs
function handles = TabsFun(handles,TabFontSize,TabNames)

% Set the colors indicating a selected/unselected tab
handles.selectedTabColor=get(handles.tab1Panel,'BackgroundColor');
handles.unselectedTabColor=handles.selectedTabColor-0.1;

% Create Tabs
TabsNumber = length(TabNames);
handles.TabsNumber = TabsNumber;
TabColor = handles.selectedTabColor;
for i = 1:TabsNumber
    n = num2str(i);
    
    % Get text objects position
    set(handles.(['tab',n,'text']),'Units','normalized')
    pos=get(handles.(['tab',n,'text']),'Position');

    % Create axes with callback function
    handles.(['a',n]) = axes('Units','normalized',...
                    'Box','on',...
                    'XTick',[],...
                    'YTick',[],...
                    'Color',TabColor,...
                    'Position',[pos(1) pos(2) pos(3) pos(4)+0.01],...
                    'Tag',n,...
                    'ButtonDownFcn',[mfilename,'(''ClickOnTab'',gcbo,[],guidata(gcbo))']);
                    
    % Create text with callback function
    handles.(['t',n]) = text('String',TabNames{i},...
                    'Units','normalized',...
                    'Position',[pos(3),pos(2)/2+pos(4)],...
                    'HorizontalAlignment','left',...
                    'VerticalAlignment','middle',...
                    'Margin',0.001,...
                    'FontSize',TabFontSize,...
                    'Backgroundcolor',TabColor,...
                    'Tag',n,...
                    'ButtonDownFcn',[mfilename,'(''ClickOnTab'',gcbo,[],guidata(gcbo))']);

    TabColor = handles.unselectedTabColor;
end
            
% Manage panels (place them in the correct position and manage visibilities)
set(handles.tab1Panel,'Units','normalized')
pan1pos=get(handles.tab1Panel,'Position');
set(handles.tab1text,'Visible','off')
for i = 2:TabsNumber
    n = num2str(i);
    set(handles.(['tab',n,'Panel']),'Units','normalized')
    set(handles.(['tab',n,'Panel']),'Position',pan1pos)
    set(handles.(['tab',n,'Panel']),'Visible','off')
    set(handles.(['tab',n,'text']),'Visible','off')
end

% --- Callback function for clicking on tab
function ClickOnTab(hObject,~,handles)
m = str2double(get(hObject,'Tag'));

for i = 1:handles.TabsNumber;
    n = num2str(i);
    if i == m
        set(handles.(['a',n]),'Color',handles.selectedTabColor)
        set(handles.(['t',n]),'BackgroundColor',handles.selectedTabColor)
        set(handles.(['tab',n,'Panel']),'Visible','on')
    else
        set(handles.(['a',n]),'Color',handles.unselectedTabColor)
        set(handles.(['t',n]),'BackgroundColor',handles.unselectedTabColor)
        set(handles.(['tab',n,'Panel']),'Visible','off')
    end
end

% --- Outputs from this function are returned to the command line.
function varargout = SolarProject_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edit2_Callback(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit2 as text
%        str2double(get(hObject,'String')) returns contents of edit2 as a double


% --- Executes during object creation, after setting all properties.
function edit2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function txtCommand_Callback(hObject, eventdata, handles)
% hObject    handle to txtCommand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtCommand as text
%        str2double(get(hObject,'String')) returns contents of txtCommand as a double


% --- Executes during object creation, after setting all properties.
function txtCommand_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtCommand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnSendCommand.
function btnSendCommand_Callback(hObject, eventdata, handles)
% hObject    handle to btnSendCommand (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
cmdString = get(handles.txtCommand,'String');

if (~isempty(cmdString))
    serialObject = evalin('base', 'arduinoSerial');
    handles.SerialHelper.arduinoSendCommand(serialObject,upper(cmdString));
else
   
    msgbox('Please enter a command then press send','Info');
    uicontrol(txtCommand);
end


function txtSeconds_Callback(hObject, eventdata, handles)
% hObject    handle to txtSeconds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtSeconds as text
%        str2double(get(hObject,'String')) returns contents of txtSeconds as a double


% --- Executes during object creation, after setting all properties.
function txtSeconds_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSeconds (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnPullSpeed.
function btnPullSpeed_Callback(hObject, eventdata, handles)
% hObject    handle to btnPullSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% handles.output = hObject;
strinterval = get(handles.txtSeconds, 'String');
interval = 1;
if  (~isempty(strinterval))
    if isnumeric(strinterval)
        interval = str2double( strinterval);
    else
        set(handles.txtSeconds,'String','1');
    end
else
    set(handles.txtSeconds,'String','1');
end

%% Starting pulling information from Arduino
serialObject = evalin('base', 'arduinoSerial');
timerCounterStarted = evalin('base', 'timerCounterStarted');
cName = get(handles.btnPullSpeed, 'String');
if (strcmpi(cName,'Start') == 1)
    if (timerCounterStarted == 0)
        handles.SerialHelper.CreateTimeCounterTimer(1);
        handles.SerialHelper.startTimeCounterTimer();
        handles.SerialHelper.createSpeedPlot(hObject);
        handles.SerialHelper.createPlotTimer(hObject,1);
    end
    
    %drawnow('expose');
    handles.SerialHelper.startPlotTimer();
    handles.SerialHelper.pullSpeed(serialObject,'GETSP',interval,1);
    handles.SerialHelper.pullCruseControl(serialObject,'GETCC',interval,1);
    handles.SerialHelper.pullCruseControlSpeed(serialObject,'CCSP',interval,1);
    handles.SerialHelper.pullThrottle(serialObject,'GETTT',interval,1);
    handles.SerialHelper.pullCarInfo(serialObject,'CINFO',interval,1);
    
    set(handles.btnPullSpeed,'String','Stop');
else
    set(handles.btnPullSpeed,'String','Start');
    %drawnow('expose');
    handles.SerialHelper.pullSpeed(serialObject,'GETSP',interval,0);
    handles.SerialHelper.pullCruseControl(serialObject,'GETCC',interval,0);
    handles.SerialHelper.pullCruseControlSpeed(serialObject,'CCSP',interval,0);
    handles.SerialHelper.pullThrottle(serialObject,'GETTT',interval,0);
    handles.SerialHelper.pullCarInfo(serialObject,'CINFO',interval,0);
    
end
%% Start Auto plotting Speed
%speedPlotCreated = evalin('base', 'speedPlotCreated');
% plottingInterval = 1;
% %if (speedPlotCreated == 0)
%    handles.SerialHelper.createSpeedPlot(hObject, eventdata);
%    handles.SerialHelper.createPlotTimer(hObject,plottingInterval);
%end


% --- Executes on button press in pushbutton9.
function pushbutton9_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton9 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in btnUpdateSpeedGraph.
function btnUpdateSpeedGraph_Callback(hObject, eventdata, handles)
% hObject    handle to btnUpdateSpeedGraph (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
speedScale = get(handles.txtSpeedScale,'String');
speedFrom =  get(handles.txtSpeedFrom,'String');
speedTo =  get(handles.txtSpeedTo,'String');
if (isempty(speedScale) || isempty(speedFrom) || isempty(speedTo))
    msgbox('Please put a numeric value for Speed1, Speed2 and Scale','Info');
else
    assignin('base','speedScale',speedScale);
    assignin('base','speedFrom',speedFrom);
    assignin('base','speedTo',speedTo);
end




function edit5_Callback(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit5 as text
%        str2double(get(hObject,'String')) returns contents of edit5 as a double


% --- Executes during object creation, after setting all properties.
function edit5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit6_Callback(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit6 as text
%        str2double(get(hObject,'String')) returns contents of edit6 as a double


% --- Executes during object creation, after setting all properties.
function edit6_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtSpeedFrom_Callback(hObject, eventdata, handles)
% hObject    handle to txtSpeedFrom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtSpeedFrom as text
%        str2double(get(hObject,'String')) returns contents of txtSpeedFrom as a double


% --- Executes during object creation, after setting all properties.
function txtSpeedFrom_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSpeedFrom (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit8_Callback(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit8 as text
%        str2double(get(hObject,'String')) returns contents of edit8 as a double


% --- Executes during object creation, after setting all properties.
function edit8_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtSpeedTo_Callback(hObject, eventdata, handles)
% hObject    handle to txtSpeedTo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtSpeedTo as text
%        str2double(get(hObject,'String')) returns contents of txtSpeedTo as a double


% --- Executes during object creation, after setting all properties.
function txtSpeedTo_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSpeedTo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit10_Callback(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit10 as text
%        str2double(get(hObject,'String')) returns contents of edit10 as a double


% --- Executes during object creation, after setting all properties.
function edit10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function edit11_Callback(hObject, eventdata, handles)
% hObject    handle to edit11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit11 as text
%        str2double(get(hObject,'String')) returns contents of edit11 as a double


% --- Executes during object creation, after setting all properties.
function edit11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtGPSComPort_Callback(hObject, eventdata, handles)
% hObject    handle to txtGPSComPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtGPSComPort as text
%        str2double(get(hObject,'String')) returns contents of txtGPSComPort as a double


% --- Executes during object creation, after setting all properties.
function txtGPSComPort_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtGPSComPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtGPSBuadRate_Callback(hObject, eventdata, handles)
% hObject    handle to txtGPSBuadRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtGPSBuadRate as text
%        str2double(get(hObject,'String')) returns contents of txtGPSBuadRate as a double


% --- Executes during object creation, after setting all properties.
function txtGPSBuadRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtGPSBuadRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnConnectToGPS.
function btnConnectToGPS_Callback(hObject, eventdata, handles)
% hObject    handle to btnConnectToGPS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
com = get(handles.txtGPSComPort, 'String');
br = get(handles.txtGPSBuadRate, 'String');
gpsTerminatorChar = evalin('base','gpsTerminator');
gpsComPort = 'COM12';
gpsBuadRate = 4800;
gpsTerminator = 'LF';
if (isempty(com) || isempty(br))
   uiwait(msgbox('Please specify com port and buadrate for GPS!\n This window will restart atumatically.', 'Error','error'));
   SerialHelper.DoHouseKeeping();
   close all;
else
     try
        br = str2double(br);
        assignin('base','gpsBuadRate',br);
        assignin('base','gpsComPort',com);
        [gpsSerial,gpsSerialFlag] = handles.SerialHelper.setupSerial(...
            com,br,gpsTerminatorChar,...
            handles.SerialHelper.gpsCallBackFunction,handles.SerialHelper.gpsEmptyCallBackFunction);
        assignin('base','gpsSerial',gpsSerial);
        assignin('base','gpsSerialFlag',gpsSerialFlag);
        set(handles.txtGpsStatus,'String','Connected');
        msgbox('Successfully connected to GPS!', 'Info')
      catch ME
        messegToDisplay = sprintf('Something went wrong, check the warning below!\n[This window will restart atumatically]\n %s',getReport(ME));
        uiwait(msgbox(messegToDisplay, 'Error','error'));
        SerialHelper.DoHouseKeeping();
        close all;
      end
end



function txtArduinoComPort_Callback(hObject, eventdata, handles)
% hObject    handle to txtArduinoComPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtArduinoComPort as text
%        str2double(get(hObject,'String')) returns contents of txtArduinoComPort as a double


% --- Executes during object creation, after setting all properties.
function txtArduinoComPort_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtArduinoComPort (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtArduinoBuadRate_Callback(hObject, eventdata, handles)
% hObject    handle to txtArduinoBuadRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtArduinoBuadRate as text
%        str2double(get(hObject,'String')) returns contents of txtArduinoBuadRate as a double


% --- Executes during object creation, after setting all properties.
function txtArduinoBuadRate_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtArduinoBuadRate (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnConnectToArduino.
function btnConnectToArduino_Callback(hObject, eventdata, handles)
% hObject    handle to btnConnectToArduino (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
%SerialHelper = SerialManager;

% i dont do checking for com port or valid buadrate please dont be smart
% and give it invalid things (;  check your system and find out relevant
% arduino com port as well as valid buadrate to communicate with arduino,
% since it will be via xBee, current configuration works best with 9600
% according to the specification of xbee people.
com = get(handles.txtArduinoComPort, 'String');
br = get(handles.txtArduinoBuadRate, 'String');
arduinoTerminatorChar = evalin('base','arduinoTerminatorChar');
if (isempty(com) || isempty(br))
   uiwait(msgbox('Please specify com port and buadrate for Arduino!\n This window will restart atumatically.', 'Error','error'));
   SerialHelper.DoHouseKeeping();
   close all;
else
     try
        br = str2double(br);
        assignin('base','arduinoBuadRate',br);
        assignin('base','arduinoComPort',com);
        [arduinoSerial,arduinoSerialFlag] = handles.SerialHelper.setupSerial(...
            com,br,arduinoTerminatorChar,...
            handles.SerialHelper.arduinoCallBackFunction,handles.SerialHelper.arduinoEmptyCallBackFunction);
        assignin('base','arduinoSerial',arduinoSerial);
        assignin('base','arduinoSerialFlag',arduinoSerialFlag);
        set(handles.txtXbeeStatus,'String','Connected');
        msgbox('Successfully connected to Arduino!', 'Info')
      catch ME
        messegToDisplay = sprintf('Something went wrong, check the warning below!\n[This window will restart atumatically]\n %s',getReport(ME));
        uiwait(msgbox(messegToDisplay, 'Error','error'));
        SerialHelper.DoHouseKeeping();
        close all;
      end
end




% --- Executes on button press in pushbutton12.
function pushbutton12_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pushbutton13.
function pushbutton13_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function txtSpeedScale_Callback(hObject, eventdata, handles)
% hObject    handle to txtSpeedScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtSpeedScale as text
%        str2double(get(hObject,'String')) returns contents of txtSpeedScale as a double


% --- Executes during object creation, after setting all properties.
function txtSpeedScale_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSpeedScale (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnClose.
function btnClose_Callback(hObject, eventdata, handles)
% hObject    handle to btnClose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
handles.SerialHelper.DoHouseKeeping();
close all


% --- Executes on button press in btnTest.
function btnTest_Callback(hObject, eventdata, handles)
% hObject    handle to btnTest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.MapHelper.plotMap();
handles.MapHelper.createPlotPositionTimer(1);
handles.BatteryHelper.plotStateOfChargeDaily(1);
handles.BatteryHelper.createPlotCurrentSocTimer(1);
handles.BatteryHelper.createCurrentSocSimulatorTimer(1);

time = evalin('base', 'darwinTime');
longitude = evalin('base', 'darwinLongitude');
latitude = evalin('base', 'darwinLatitude');
solarPanelArea = evalin('base', 'solarPanelArea');
solarPanelEf = evalin('base', 'solarPanelEf');
scalingFactor = evalin('base', 'overalScalingFactor');
solarFluxScalingFactor = evalin('base', 'solarFluxScalingFactor');

handles.SolarHelper.PlotSolarPowerDaily(time,...
                                        longitude,latitude,...
                                        solarPanelArea,solarPanelEf,...
                                        scalingFactor,solarFluxScalingFactor)
                                    
handles.SolarHelper.PlotSolarPowerInstantaneously(5,time,...
                                        longitude,latitude,...
                                        solarPanelArea,solarPanelEf,...
                                        scalingFactor,solarFluxScalingFactor)
                                    
                                    


% --- Executes on button press in btnUpdateGPSInfo.
function btnUpdateGPSInfo_Callback(hObject, eventdata, handles)
% hObject    handle to btnUpdateGPSInfo (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.SolarHelper.ClearSolarPlot();

time = evalin('base', 'darwinTime');
timeZone = get(handles.txtTimeZone,'String');
longitude = str2double(get(handles.txtSetLongitude,'String'));
latitude = str2double(get(handles.txtSetLatitude,'String'));
solarPanelEf = str2double(get(handles.txtEfficiency, 'String'));
solarPanelArea = str2double(get(handles.txtArea, 'String'));
solarFluxScalingFactor = str2double(get(handles.txtFluxScaler,'String'));
overalScalingFactor = str2double(get(handles.txtOveralScaler,'String'));
en = get(handles.chkGetInfoFromGPS,'Value');

assignin('base','timeZoe',timeZone);
assignin('base','longitude',longitude);
assignin('base','latitude',latitude);
assignin('base','solarPanelEf',solarPanelEf);
assignin('base','solarPanelArea',solarPanelArea);
assignin('base','solarFluxScalingFactor',solarFluxScalingFactor);
assignin('base','overalScalingFactor',overalScalingFactor);
assignin('base','updateCoordinatesFromGPS',en);


time.TimeZone = timeZone;
handles.SolarHelper.PlotSolarPowerDaily(time,...
                                        longitude,latitude,...
                                        solarPanelArea,solarPanelEf,...
                                        overalScalingFactor,solarFluxScalingFactor)
                                    
handles.SolarHelper.PlotSolarPowerInstantaneously(5,time,...
                                        longitude,latitude,...
                                        solarPanelArea,solarPanelEf,...
                                        overalScalingFactor,solarFluxScalingFactor)
                                    

function txtSetLongitude_Callback(hObject, eventdata, handles)
% hObject    handle to txtSetLongitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtSetLongitude as text
%        str2double(get(hObject,'String')) returns contents of txtSetLongitude as a double


% --- Executes during object creation, after setting all properties.
function txtSetLongitude_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSetLongitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtTimeZone_Callback(hObject, eventdata, handles)
% hObject    handle to txtTimeZone (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtTimeZone as text
%        str2double(get(hObject,'String')) returns contents of txtTimeZone as a double


% --- Executes during object creation, after setting all properties.
function txtTimeZone_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtTimeZone (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtSetLatitude_Callback(hObject, eventdata, handles)
% hObject    handle to txtSetLatitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtSetLatitude as text
%        str2double(get(hObject,'String')) returns contents of txtSetLatitude as a double


% --- Executes during object creation, after setting all properties.
function txtSetLatitude_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtSetLatitude (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chkGetInfoFromGPS.
function chkGetInfoFromGPS_Callback(hObject, eventdata, handles)
% hObject    handle to chkGetInfoFromGPS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkGetInfoFromGPS
connected = get(handles.txtGpsStatus,'String');
if (strcmpi(connected,'Connected') == 1)
    %set(handles.checkbox1,'Value',1)
else
    msgbox('Connect a GPS first');
    set(handles.chkGetInfoFromGPS,'Value',0);
end


function txtArea_Callback(hObject, eventdata, handles)
% hObject    handle to txtArea (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtArea as text
%        str2double(get(hObject,'String')) returns contents of txtArea as a double


% --- Executes during object creation, after setting all properties.
function txtArea_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtArea (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtEfficiency_Callback(hObject, eventdata, handles)
% hObject    handle to txtEfficiency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtEfficiency as text
%        str2double(get(hObject,'String')) returns contents of txtEfficiency as a double


% --- Executes during object creation, after setting all properties.
function txtEfficiency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtEfficiency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtFluxScaler_Callback(hObject, eventdata, handles)
% hObject    handle to txtFluxScaler (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtFluxScaler as text
%        str2double(get(hObject,'String')) returns contents of txtFluxScaler as a double


% --- Executes during object creation, after setting all properties.
function txtFluxScaler_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtFluxScaler (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txtOveralScaler_Callback(hObject, eventdata, handles)
% hObject    handle to txtOveralScaler (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txtOveralScaler as text
%        str2double(get(hObject,'String')) returns contents of txtOveralScaler as a double


% --- Executes during object creation, after setting all properties.
function txtOveralScaler_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txtOveralScaler (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnDisconnectGPS.
function btnDisconnectGPS_Callback(hObject, eventdata, handles)
% hObject    handle to btnDisconnectGPS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
connected = get(handles.txtGpsStatus,'String');

if (strcmpi(connected,'Connected') == 1)
    serial = evalin('base','gpsSerial');
    success = handles.SerialHelper.disconnectGPS(serial);
    if (success == 1)
        set(handles.txtGpsStatus,'String','Disconnected!');
        msgbox('GPS disconnected successfully', 'Info')
    else
        msgbox('Something went wrong!', 'Info')
    end
else
    msgbox('You are already disconnected!', 'Info');
end
