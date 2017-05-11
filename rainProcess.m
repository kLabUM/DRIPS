function [ rain ] = rainProcess( rain, rWind, rSig, aggregate)
% Aggregates and smooths measured precipitation data
%
% Inputs:
%   rain: Measured rain signals
%   rWind, rSig: Rain smoothing window parameters
%   aggregate: Aggregation type (sum, mean, max of rain signals)
%
% Outputs:
%   rain: Aggregated rain signals
%
    switch aggregate
        case 'sum'
            rain = sum(rain,2);
        case 'mean'
            rain = mean(rain,2);
        case 'max'
            rain = max(rain,[],2);
        otherwise
            disp('aggregate must be sum, mean or max');
    end

    rain = smoothts(rain','g',rWind,rSig)';
    
end

