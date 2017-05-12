clear all
close all
clc

%% User inputs

Site = 1;
TestFolder = '';        % Results will be saved in ./Data/Site[Site][TestFolder]/

histData = load(strcat('./Examples/Site',num2str(Site),'_hist.mat')); % Historical data
predData = load(strcat('./Examples/Site',num2str(Site),'_pred.mat')); % Data for prediction

Fs = 288;               % Sensor sampling frequency (number per day)

diurnal_lookback = 3;   % Enter one diurnal/dry-weather lookback period (in months)
hydro_lookback = 1;     % Enter one wet-weather/hydrologic lookback period (in months)
reconstruct = 0;        % Combine wastewater and stormwater predictions (1) or Just display stormwater prediction (0)
plotem = 1;             % Plot the predicted and measured storms (1) or Not (0)

%% File prep

filepath = strcat('./Data/');
mkdir(filepath);
filepath = strcat('./Data/', 'Site', num2str(Site,'%02.0f'), TestFolder, '/');
mkdir(filepath);

%% Historical data processing

nhStms = stormSectioning(Site,strcat(TestFolder,'/Hist'),histData,Fs)                   % Number of individual storm events in historical/training data

diurnalExtraction(Site,TestFolder,nhStms,diurnal_lookback,histData,histData,'Hist/',Fs) % Predict dry-weather flow component for each historical storm event
disp('Done processing historical data')

%% Predicting data processing

npStms = stormSectioning(Site,strcat(TestFolder,'/Pred'),predData,Fs)                   % Number of individual storm events in predicting/testing data

diurnalExtraction(Site,TestFolder,npStms,diurnal_lookback,histData,predData,'Pred/',Fs) % Predict dry-weather flow component for each predicting storm event
disp('Done processing data to be predicted')

%% System ID

systemIDTimeLookback(Site,hydro_lookback,TestFolder,nhStms,npStms,'Hist/','Pred/',reconstruct,Fs);                  % Predict wet-weather response for each predicting storm event
disp(strcat('Done with ',num2str(hydro_lookback),'mo',' lookback'))

[meanFits, stdFits, medianFits] = systemIDResults(Site,TestFolder,hydro_lookback,npStms,plotem,reconstruct,'Pred/') % Evaluate predicted wet-weather response (or combined flow) against measured flow
