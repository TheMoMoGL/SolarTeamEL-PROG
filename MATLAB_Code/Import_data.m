function [ wscdata ] = Import_data(filePath )
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

