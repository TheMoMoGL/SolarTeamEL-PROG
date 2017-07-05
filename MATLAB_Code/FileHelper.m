function iFileHelper = FileHelper
    iFileHelper.saveToFile=@saveToFile;
    iFileHelper.loadFromFile=@loadFromFile;
    iFileHelper.plotLoadedData=@plotLoadedData;
    iFileHelper.importData=@importData;
end

function [filePath] = saveToFile(speedData)
    [file,path] = uiputfile('*.sol','Save File As');
    filePath =strcat(path, file);
    csvwrite(filePath,speedData);
end

function [speedData] = loadFromFile()
    [file,path] = uigetfile('*.sol','Select the Solar data file');
    filePath =strcat(path, file);
    speedData = csvread(filePath);
    assignin('base','loadedSpeedData',speedData);
    fprintf('%s File loaded properly\n',filePath); 
end

function plotLoadedData(from,to,speedFrom,speedTo)
    sp = evalin('base', 'loadedSpeedData');
    speeds = sp(1,from:to);
    cruseSpeed = sp(2,from:to);
    seconds = sp(3,from:to);
    x = [speeds;cruseSpeed];

    err = diff(x);
    errScaler = 1;
    err = abs(err(1:end)*errScaler);
    hGui = findobj('Tag','mySerialMonitor');
    handles = guidata(hGui);
    plot(handles.ccGraph,seconds,err,'b')
    hold on
    plot(handles.ccGraph,seconds,speeds,'-or')
    hold on
    plot(handles.ccGraph,seconds,cruseSpeed,'g')
    hold off
    legend('Error','Car Speed','Cruse control Speed');
    title('Car Speed over time');
    xlabel('Time: second');
    ylabel('Speed (kh)');
    xlim([from to])
    set(gca,'XTick',[from : 5 : to]);
    ylim([speedFrom speedTo])
    set(gca,'YTick',[speedFrom : 1 : speedTo]);
    grid on
end

function [ wscdata ] = importData(filePath )
%UNTITLED6 Summary of this function goes here
%   Detailed explanation goes here
%% Import the data
[~, ~, raw] = xlsread(filePath,'Sheet1','A2:F204879');
raw(cellfun(@(x) ~isempty(x) && isnumeric(x) && isnan(x),raw)) = {''};

%% Replace non-numeric cells with NaN
R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),raw); % Find non-numeric cells
raw(R) = {NaN}; % Replace non-numeric cells

%% Create output variable
wscdata = reshape([raw{:}],size(raw));

%% Clear temporary variables
clearvars raw R;

end
