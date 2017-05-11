clear all
close all
clc

%% User inputs

Site = 33;
TestFolder = '';        % Results will be saved in ./Data/Site[Site][TestFolder]/

histData = load(strcat('./RawData/Site',num2str(Site),'_hist.mat')); % Historical data
predData = load(strcat('./RawData/Site',num2str(Site),'_pred.mat')); % Data for prediction

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

nhStms = stormSectioning(Site,strcat(TestFolder,'/Hist'),histData,Fs)

diurnalExtraction(Site,TestFolder,nhStms,diurnal_lookback,histData,histData,'Hist/',Fs)
disp('Done processing historical data')

%% Predicting data processing

npStms = stormSectioning(Site,strcat(TestFolder,'/Pred'),predData,Fs)

diurnalExtraction(Site,TestFolder,npStms,diurnal_lookback,histData,predData,'Pred/',Fs)
disp('Done processing data to be predicted')

%% System ID

systemIDTimeLookback(Site,hydro_lookback,TestFolder,nhStms,npStms,'Hist/','Pred/',reconstruct,Fs);
disp(strcat('Done with ',num2str(hydro_lookback),'mo',' lookback'))

[meanFits, stdFits, medianFits] = systemIDResults(Site,TestFolder,hydro_lookback,npStms,plotem,reconstruct,'Pred/')
