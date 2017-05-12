function [ hyp, timeSlack, slope, stdMax, stdMin ] = initializeGPhyp( Site, testfolder )
% Loads GP hyperparameters previously saved
%
% Inputs:
%   Site: Site number/identifier
%   testfolder: Folder name appendage (/Site[Site][testfolder])
%
% Outputs:
%   hyp: GP hyperparameters
%   timeSlack: Threshold for length of a dry-weather diurnal pattern
%   slope: Threshold for slope of a dry-weather diurnal pattern
%   (trough-to-trough)
%   stdMax: Threshold for maximum standard deviation of a dry-weather
%   diurnal pattern
%   stdMin: Threshold for minimum standard deviation of a dry-weather
%   diurnal pattern
%
    initFile = strcat('./Data/Site',num2str(Site,'%02.0f'),...
         testfolder,'/HypInit',num2str(Site,'%02.0f'), '.mat');
    base = load(initFile);
    timeSlack = base.timeSlack;
    slope = base.slope;
    stdMax = base.stdMax;
    stdMin = base.stdMin;
    hyp = base.hyp;
end

