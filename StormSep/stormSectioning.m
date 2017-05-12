function [mainCt] = stormSectioning(Site, testFolder, rawData, Fs)
% Parses data into individual storm events and saves storm files
%
% Inputs:
%   Site: Site number/identifier
%   testFolder: Folder name appendage (/Site[Site][testfolder])
%   rawData: Measured flow sensor data
%   Fs: Sensor sampling frequency (samples per day)
%
% Outputs:
%   mainCt: Storm number currently processed
%
    filepath = strcat('./Data/', 'Site', num2str(Site,'%02.0f'), testFolder, '/');
    mkdir(filepath)
    
    mainCt = 0;
    threshold = 0.08;   % minimum rain (inches) to be considered non-negligible at time step
        
    rain = sum([rawData.Rain1;rawData.Rain2;rawData.Rain3]);
    norain = Fs;

    storms = [];
    stormct = 0;
    i = 1;
    frontpad = norain*2;
    backpad = norain*3;


    while i < length(rain)
        if abs(rain(i)) > threshold
            starti = i;
            i = i + 1;
            endi = i;
            while i+norain < length(rain) && sum(abs(rain(i:i+norain))) > 0 && max(abs(rain(i:i+norain))) > threshold
                i = i + 1;
                endi = i;
            end
            stormct = stormct + 1;
            storms(stormct,1) = starti;
            storms(stormct,2) = endi;
        end
        i = i+1;
    end

    for i = 1:stormct
        mainCt = mainCt + 1;

        if storms(i,1) - frontpad < 1
            range1 = 1:storms(i:2)+backpad;
        elseif storms(i,2) + backpad > length(rain)
            range1 = storms(i,1)-frontpad:length(rain);
        else
            range1 = storms(i,1)-frontpad:storms(i,2)+backpad;
        end

        StormFile = strcat(filepath,'Stm_',num2str(Site,'%02.0f'), ...
            '_',num2str(mainCt,'%02.0f'),'.mat');
        Rain1 = rawData.Rain1(range1);
        Rain2 = rawData.Rain2(range1);
        Rain3 = rawData.Rain3(range1);
        startIndex = range1(1);
        endIndex = range1(end);
        timestamps = rawData.FlowTime(range1);
        rawFlow = rawData.Flow(range1);
        ID = mainCt;
        save(StormFile, 'Rain1','Rain2','Rain3', ...
        'startIndex', 'endIndex','timestamps', ...
        'rawFlow', 'ID', 'Site');

    end
end






