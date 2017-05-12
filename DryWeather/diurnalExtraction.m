function [fileCt] = diurnalExtraction(Site, testfolder, nStms, MonthsStep, trainData, valData, valPath, Fs)
% Processes storm event to isolate and predict dry-weather flow, appending the
% result in the saved storm file
%
% Inputs:
%   Site: Site number/identifier
%   testfolder: Folder name appendage (/Site[Site][testfolder])
%   nStms: Number of storms in validation data
%   MonthsStep: Diurnal/dry-weather lookback length (months)
%   trainData: Training data for GP
%   valData: Validation/prediction data for GP
%   valPath: File path for saving predicted dry-weather flows
%   Fs: Sensor sampling frequency (samples per day)
%
% Outputs:
%   fileCt: Storm number (of validation data) currently processed
%   
    filepath = strcat('./Data/', 'Site', num2str(Site,'%02.0f'), testfolder, '/');
    [hyp, timeSlack, slope, stdMax, stdMin] = initializeGPhyp(Site, testfolder);

    
    %% GP Prep

    run('./gpml-matlab-v3.6-2015-07-07/startup.m')

    k2 = @covPeriodic;
    k3 = @covRQard;
    covfunc = {@covSum, {k2, k3}};


    %% Flow Filters

    filter_diurnal_SOS = load('./Filter/diurn_butter_SOS.mat'); %diurnalSOS; %
    filter_diurnal_G = load('./Filter/diurn_butter_G.mat'); %diurnalG; %

    %% Fill in raw data
    all_datetime = datetime(trainData.FlowTime,'ConvertFrom','epochtime','Epoch','1970-01-01');

    %% Remove high frequency noise

    no_noise_train = smoothts(trainData.Flow,'g',300,100);
    no_noise_val = smoothts(valData.Flow,'g',300,100);

    %% Extract Diurnal

    diurnals = filtfilt(filter_diurnal_SOS.SOS,filter_diurnal_G.G,no_noise_train);

    %%
    lookback = round(MonthsStep*288*365/12);
    fileCt = 0;
    signal = 0;
    hypLibrary = [];

    for i = 1:nStms

        fileCt = fileCt + 1
        
        StormFile = strcat(filepath,valPath,'Stm_',num2str(Site,'%02.0f'), ...
                '_',num2str(fileCt,'%02.0f'),'.mat');
        currentStorm = load(StormFile);

        %
        start_i = length(trainData.FlowTime) - lookback;
        if start_i < 1
            start_i = 1;
        end
        range_train = start_i:length(trainData.FlowTime);
        flowtime_section = trainData.FlowTime(range_train);
        datetime_section = all_datetime(range_train);
        diurnals_section = diurnals(range_train);
        good_i = selectTrainingDays(flowtime_section, diurnals_section, Fs, ...
            slope, timeSlack, stdMin, stdMax);
       
        if isempty(good_i)
            no_noise = zeros(1,length(currentStorm.timestamps));
            mu = zeros(length(currentStorm.timestamps),1);
            s2 = zeros(length(currentStorm.timestamps),1);
            hydro = zeros(1,length(currentStorm.timestamps));
            save(StormFile,'no_noise','mu', 's2', 'hydro','-append');
            continue
        end

        timedecimal_section = timeToWeekdayDecimal(datetime_section');
        weekday_checks = zeros(1,7);

        x = [];
        y = [];
        [j,col] = size(good_i);
        
        while j >= 1 && sum(weekday_checks)<7

            day_start = good_i(j,1);
            day_end = good_i(j,2);
            day = timedecimal_section(day_start:day_end);

            day_of_week = mode(weekday(day));
            
            if weekday_checks(day_of_week) == 0 
                weekday_checks(day_of_week) = 1;
            end
            j = j - 1;
            x = [x; day];
            y = [y; diurnals_section(day_start:day_end)'];
        end
        
        step = floor(length(x)/3500);
        if step == 0
            step = 1;
        end
        x = x(1:step:length(x));
        y = y(1:step:length(y));
        
        x_star = timeToWeekdayDecimal(datetime(currentStorm.timestamps,'ConvertFrom','epochtime','Epoch','1970-01-01')');
        
        [mu s2] = gp(hyp, @infExact, [], covfunc, @likGauss, x, y, x_star);
        
        no_noise = no_noise_val(currentStorm.startIndex:currentStorm.endIndex);
        
        hydro = no_noise - mu';
              
        save(StormFile,'no_noise','mu', 's2', 'hydro','-append');
        
        

    end
end

