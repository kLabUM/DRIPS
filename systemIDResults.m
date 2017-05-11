function [meanFits, stdFits, medianFits] = systemIDResults(Site, testfolder, lookbacks, nStms, plotem, reconstruct, valPath)
% Computes average fit of predicted wet-weather (and dry-weather if
% reconstruct = 1) flow for prediction dataset and plots and saves
% resulting prediction
%
% Inputs:
%   Site: Site number/identifier
%   testfolder: Folder name appendage (/Site[Site][testfolder])
%   lookbacks: Wet-weather lookback length (months)
%   nStms: Number of storms in validation/prediction data
%   plotem: Determines if predictions will be plotted (=1) or not (=0)
%   reconstruct: Determines if dry- and wet-weather predictions will be
%   summed (=1); otherwise, computes fit and plots only the wet-weather
%   predictions (=0)
%   valPath: File path for saving prediction performance and prediction
%   plots
%
% Outputs:
%   meanFits: Mean of prediction performance (NRMSE) for prediction dataset
%   stdFits: Standard deviation of prediction performance (NRMSE) for prediction dataset
%   medianFits: Median of prediction performance (NRMSE) for prediction dataset
%  
    sitepath = strcat('./Data/', 'Site', ...
        num2str(Site,'%02.0f'), testfolder, '/',valPath);
    summaryPath = strcat(sitepath,'ResultPlots');
    mkdir(summaryPath)
    lgnd = strings(length(lookbacks)+1,1);
    for i = 1:length(lookbacks)
        lgnd(i+1) = strcat(num2str(lookbacks(i)),'mo');
    end
    lgnd(1) = {'Measured'};
    
    fits = zeros(length(lookbacks), nStms);
    meanFits = zeros(1,length(lookbacks));
    stdFits = zeros(1,length(lookbacks));
    cts = zeros(1,length(lookbacks));
    for i = 1:nStms
        used = [];
        for j = 1:length(lookbacks)
            folder = strcat('SID_',num2str(lookbacks(j)),'mo');
            respath = strcat(sitepath, folder);
            resultsFile = strcat(respath,'/',folder,'_Site',num2str(Site,'%02.0f'), ...
                '_',num2str(i,'%02.0f'),'.mat');
            stormFile = strcat(sitepath,'Stm_', num2str(Site,'%02.0f'), ...
                '_', num2str(i,'%02.0f'),'.mat');
            
            try load(char(resultsFile))
                measured = load(stormFile);
                usedRains = [];
                for k = 1:length(r)
                    if r(k) == 1
                        usedRains(k,:) = measured.Rain1;
                    elseif r(k) == 2
                        usedRains(k,:) = measured.Rain2;
                    else
                        usedRains(k,:) = measured.Rain3;
                    end
                end
                usedRain = NaN(1,length(measured.timestamps));
                for k = 1:length(r)
                    if strcmp(aggregate,'max')
                        usedRain = max(usedRain,usedRains(k,:));
                    elseif strcmp(aggregate,'mean')
                        usedRain = mean([usedRain;usedRains(k,:)],'omitnan');
                    else
                        usedRain = sum([usedRain;usedRains(k,:)],'omitnan');
                    end
                end
                
                if isempty(used) && plotem == 1
                    f1 = figure;
                    hold on;
                    yyaxis right; plot(measured.timestamps,usedRain);
                    if reconstruct == 1
                        yyaxis left; plot(measured.timestamps,measured.no_noise);
                    else
                        yyaxis left; plot(measured.timestamps,measured.hydro);
                    end
                    used = [used 1];
                end
                
                if ~isempty(valresults) 
                    if reconstruct == 1
                        valresults = valresults + offset + measured.mu';
                        t_fit = goodnessOfFit(valresults',measured.no_noise','NRMSE');
                    else
                        valresults = valresults + offset;
                        t_fit = goodnessOfFit(valresults',measured.hydro','NRMSE');
                    end
                    cts(j) = cts(j) + 1;
                    fits(j,cts(j)) = t_fit;
                    if plotem == 1
                        used = [used j+1];
                        yyaxis left; plot(measured.timestamps,valresults);
                    end
                end
            catch %Do nothing
            end
        end
        
        if  ~isempty(used) && plotem == 1
            ylabel('cfs');
            title('Measured and Predicted Hydrograph');
            legend(lgnd(used));
            figFile = strcat(sitepath,'ResultPlots/',num2str(Site,'%02.0f'),...
                '_Stm',num2str(i,'%02.0f'),'.jpg');
            saveas(f1,figFile);
            close(f1);
        end
    end
    
    for i = 1:length(lookbacks)
        meanFits(i) = mean(fits(i,1:cts(i)));
        stdFits(i) = std(fits(i,1:cts(i)));
        medianFits(i) = median(fits(i,1:cts(i)));
    end
    summaryFile = strcat(summaryPath,'/ResultsSummary',num2str(Site,'%02.0f'),'.mat');
    save(summaryFile, 'lookbacks', 'meanFits','stdFits','medianFits');
    
end

