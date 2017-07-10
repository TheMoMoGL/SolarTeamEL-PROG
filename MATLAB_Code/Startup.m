%% This is the main workspace, all the variables that needed to be accessed application wide need to be delacred here
%% Adding sub directories path for serial, solar, GUI and power mangments
%addpath(genpath('SerialManagment/'));
%addpath(genpath('SolarPower/'));
%% Cleanup worksapce and decalre helpers
clc
instrreset(); %reset all instrumentss interfaces attached. Becareful if you are using other comports 
clear all; %igonre compilers warning we need it.
SerialHelper =  SerialManager;
SolarHelper =  SolarHelpersFunc;
FileHelper = FileHelper;
%GuiHelper = SolarProject;
%% Variables for MAP
coordinateFile = 'wsc_data.xlsx';
wscdata = FileHelper.importData(coordinateFile);
%% Variables for Battry 
stateOfChargeDailyUsage = [0.85, 0.70, 0.55, 0.40, 0.25, 0.00];
isFirstSoC = 0;
%% Variables for plotting velocity realtime graph
timeFrom = 1;
timeTo = 31;
speedFrom = 0;
speedTo = 100;
speedScale = 10;
lastIndex = 0;
speedPlotCreated = 0;
xHelperCounter = 0;
timerCounterStarted = 0;
%% Arduino port configuration
% Variables for Arduino serial port. 
% Data format to be sent to Arduino should have this format: %s\r
arduinoComPort = 'COM5';
arduinoBuadRate = 9600;
arduinoTerminatorChar = 'CR';
serial arduinoSerial; %if you change this make sure change the subsequent function in serial manager to reflect the same name
arduinoSerialReply = [];%if you change this make sure change the subsequent function in serial manager to reflect the same name
% Arduino commands,
% make sure these command sets are the same in Arduino as well.
CmdOn = 'ON';
CmdOff = 'OFF';
cmdStart = 'START';
cmdStop = 'STOP';
ArduinoHandShake = 'HS';
arduinoReadContinuely = 0;
timeCounter = 30;
cSpeed = 0;
ccSpeed = 0;
maxTimeToLog = 18000; % 5 hours
speedData = zeros(3, maxTimeToLog);
loadedSpeedData = zeros(3, maxTimeToLog);
CarInfo = struct('Speed',0,'CruseSpeed',0,'CollectedSolarPower',0,'ChargeState',1);

%Create Arduino serial connection if does not exist
% if(~exist('arduinoSerialFlag','var'))
%     [arduinoSerial,arduinoSerialFlag] = SerialHelper.setupSerial(arduinoComPort,arduinoBuadRate,arduinoTerminatorChar,SerialHelper.arduinoCallBackFunction,SerialHelper.arduinoEmptyCallBackFunction);
% end
%pause(2)%wait 2 seconds for everthing to initialize
%% GPS port configuration
% Variables for GPS serial port. 
% currently GPS (G-STAR IV) default configuration is used
% one can change its baudrate and other configuration via some
% text based command. defualt Buadrate is 4800

NmeaLocationHeader = '$GPGGA';
NmeaSpeedHeader = '$GPVTG';
NmeaMCHeader = '$GPRMC';
gpsComPort = 'COM5';
gpsBuadRate = 4800;
gpsTerminator = 'LF';
gpsSeperator = ',';
gpsStartLine = '$';
serial gpsSerial;%if you change this make sure change the subsequent function in serial manager to reflect the same name
gpsData = [];%if you change this make sure change the subsequent function in serial manager to reflect the same name

% Create GPS serial connection if does not exist
% if(~exist('gpsSerialFlag','var'))
%     [gpsSerial,gpsSerialFlag] = SerialHelper.setupSerial(gpsComPort,gpsBuadRate,gpsTerminator,SerialHelper.gpsCallBackFunction,SerialHelper.gpsEmptyCallBackFunction);
% end
% pause(2);

%% Solar power variables
solarPanelEf = 0.229; % 22.9% of effeciency
solarPanelArea = 4.0; % 4 meter squred
solarFluxScalingFactor = 0.75; % the atmosther will transmit a fraction (75%) of solar radiotion
overalScalingFactor = 1; 
% Important :
% radiation input for 1 sq.m area expressed in Joules/sec = W/m2
% so to conver to kWh or Joules/sec = kWh/m2 we use this formula
ConvertToKwH = @(x) (x/1000) / (60*60);
vasterasLongitude = 16.32;
vasterasLatitude = 59.36;
darwinLongitude = 130.833;
darwinLatitude = -12.4667;
vaterasUTCoffset = +1;
darwinUTCoffset = 9.3;
vasterasTimeZoneName = 'Europe/Stockholm';
darwinTimeZoneName = 'Australia/Darwin';
vaterasTime = datetime('now','TimeZone','Europe/Stockholm','Format','yyyy-MM-dd HH:mm');
darwinTime = datetime('now','TimeZone','Australia/Darwin','Format','yyyy-MM-dd HH:mm');
gmtTime = datetime('now','TimeZone','GMT','Format','HH:mm');
timeZoe = 'Australia/Darwin';
longitude = 130.833;
latitude = -12.4667;
updateCoordinatesFromGPS = 0;

%% This is where we call GUI 

run SolarProject;
drawnow();