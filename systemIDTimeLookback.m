function [] = systemIDTimeLookback( Site, lookback, testfolder, ntrainStms, nvalStms, trainPath, valPath, reconstruct, Fs)
% Processes wet-weather model re-calibration scheme, evaluating over each
% training storm
%
% Inputs:
%   Site: Site number/identifier
%   lookback: Wet-weather lookback length (months)
%   testfolder: Folder name appendage (/Site[Site][testfolder])
%   ntrainStms: Number of training storms
%   nvalStms: Number of validation/prediction storms
%   trainPath: File path for loading training storms
%   valPath: File path for loading and saving validating/predicted storms
%   reconstruct: Determines if dry- and wet-weather predictions will be
%   summed (=1); otherwise, computes fit and plots only the wet-weather
%   predictions (=0)
%   Fs: Sensor sampling frequency (samples per day)
%  
    sitepath = strcat('./Data/', 'Site', ...
        num2str(Site,'%02.0f'), testfolder, '/');
    
    tstd = zeros(1,ntrainStms);
    for stmCt = 1:ntrainStms
        StormFile = strcat(sitepath,trainPath,'Stm_',num2str(Site,'%02.0f'), ...
                '_',num2str(stmCt,'%02.0f'),'.mat');
        try
            storm = load(StormFile);
        catch
            continue
        end
        tstd(stmCt) = std(storm.hydro);
    end
    
    stormLib = [];
    for stmCt = 1:ntrainStms
        StormFile = strcat(sitepath,trainPath,'Stm_',num2str(Site,'%02.0f'), ...
                '_',num2str(stmCt,'%02.0f'),'.mat');
        try
            storm = load(StormFile);
        catch
            continue
        end
        if std(storm.hydro) > median(tstd)
            stormLib = [stormLib storm];
        end
    end

    ntrainStms = length(stormLib);
    folder = strcat('SID_',num2str(lookback),'mo');
    rWind = Fs/6;
    rSig = rWind/4;
    
    timedist = 60*60*24*365/12*lookback;
    
    filepath = strcat(sitepath,valPath,folder);
    mkdir(filepath);
    
    for k = 1:nvalStms
        valStmFile = strcat(sitepath,valPath,'Stm_',num2str(Site,'%02.0f'), ...
                '_',num2str(k,'%02.0f'),'.mat');
        valStm = load(valStmFile);
        
        trainStms = [];
        for i = 1:ntrainStms
            cStm = stormLib(i);
            if (valStm.timestamps(1) - cStm.timestamps(1)) < timedist
                trainStms = [trainStms cStm];
            end
        end
        if ~isempty(trainStms)
            [tf, r, aggregate,bestStorm,trainfits, trainresults, offset] = train(rWind, rSig, trainStms, reconstruct);
            [valfits, valresults] = evaluate(valStm, tf, r, rWind, rSig, aggregate, reconstruct, offset);
        else
            tf = [];
            r = [];
            aggregate = [];
            bestStorm = [];
            trainfits = [];
            trainresults = [];
            valfits = [];
            valresults = [];
            offset = 0;
        end
        filename = strcat(filepath,'/',folder,'_Site',num2str(Site,'%02.0f'),...
            '_',num2str(valStm.ID,'%02.0f'));
        save(filename,'tf','aggregate','bestStorm','trainfits','trainresults','offset','r',...
            'valfits','valresults','trainStms','valStm');
        if j == 1
            break;
        end
    end
    
end

