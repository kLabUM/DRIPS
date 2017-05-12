function [tf, bestRain, aggChoice, bestStorm, fits, results, offset] = train(rWind, rSig, storms, reconstruct)
% Learns wet-weather model for each input storm and chooses the best one
% based on cross-validation
%
% Inputs:
%   rWind, rSig: Rain smoothing window parameters
%   storms: Training data for estimating transfer function parameters
%   reconstruct: Option to reconstruct combined flow from wastewater and
%       hydrologic components
%
% Outputs:
%   tf: Learned transfer function model
%   bestRain, aggChoice: Rain permutation yielded from best model via cross-validation
%   bestStorm: Training storm from which the best model was learned
%   fits, results: Cross-validation fits and predictions
%   offset: Baseflow estimate
%
    % Rain permutations
    rperms = [1 2 3;
        1 2 0;
        1 3 0;
        2 3 0;
        1 0 0;
        2 0 0;
        3 0 0];

    aggregates = {'sum','mean','max'};
    fitP_0 = 0;
    for stmN = 1:length(storms)
        cStm = storms(stmN);
        
        %Prepare hydro
        offset = quantile(cStm.hydro,.1);
        hydro = cStm.hydro - offset;
        hydro = hydro';
        
        rains = abs([cStm.Rain1;cStm.Rain2;cStm.Rain3]');

        % Learn model for each rain input permutation
        for i = 1:length(rperms);
            for j = 1:3
                rChoice = rperms(i,:);
                rChoice = rChoice(rChoice>0);
                
                rain = rains(:,rChoice);
                
                rain = rainProcess(rain, rWind, rSig, char(aggregates(j)));
                
                % Create iddata object for system id
                data = iddata(hydro,rain,1);
                
                % Transfer function estimation testing
                np = 3;
                nz = 2;
                delay = 0;
                opt = tfestOptions('InitMethod','all','Focus','Simulation');
                tf_0 = tfest(data, np, nz,delay,opt);
                
                % Cross-validation on storms in window
                [fitTemp, res1] = evaluate(storms, tf_0, rChoice, rWind, rSig, char(aggregates(j)),reconstruct, offset);
                
                fitsEval = fitTemp;
                
                % Determine best model for prediction
                if median(fitsEval) > fitP_0
                    fitP_0 = median(fitsEval);
                    tf = tf_0;
                    bestRain = rChoice;
                    aggChoice = char(aggregates(j));
                    results = res1;
                    bestStorm = stmN;
                    fits = fitsEval;
                end
            end
        end
    end

end

