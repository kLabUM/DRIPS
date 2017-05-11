function [ fits, results ] = evaluate( storms, tf, rChoice, rWind, rSig, aggregate, reconstruct, offset)
% Evaluates fit of predicted wet-weather flow
%
% Inputs:
%   storms: Validation storm(s)
%   tf: Transfer function to evaluate
%   rChoice, aggregate: Rain permutation
%   rWind, rSig: Rain smoothing window parameters
%   reconstruct: Option to reconstruct combined flow from wastewater and
%       hydrologic components
%   offset: Baseflow estimate
%
% Outputs:
%   fits, results: Validation fit(s) and prediction(s)
%    
    fits = zeros(1,length(storms));

    results = [];
    for i = 1:length(storms)
        Current = storms(i);
        hEval = Current.hydro';
        hEval = hEval - offset;
        rEval = abs([Current.Rain1;Current.Rain2;Current.Rain3]');
        rEval = rEval(:,rChoice);
        rEval = rainProcess(rEval, rWind, rSig, aggregate);
        dataEval = iddata(hEval,rEval,1);
        [res1,hydro_fit,~] = compare(dataEval,tf);
        if reconstruct == 1
            predictedHydro = res1.OutputData' + offset;
            [predicted_flow, flow_fit] = reconstructFlow(predictedHydro, Current);
            fits(i) = flow_fit;
            results(i,1:length(res1.OutputData)) = predicted_flow;
        else
            fits(i) = hydro_fit;
            results(i,1:length(res1.OutputData)) = res1.OutputData';
        end
    end
end

