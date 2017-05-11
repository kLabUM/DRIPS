function [ predicted_flow, fit ] = reconstructFlow(predicted_hydro, storm)
% Sums the predicted dry- and wet-weather flows
%
% Inputs:
%   predicted_hydro: Predicted wet-weather response for given storm
%   storm: Storm data, including raw and predicted dry-weather flow
%
% Outputs:
%   predicted_flow: Predicted combined flow
%   fit: NRMSE fit of predicted combined flow compared to measured combined
%   flow (after low-pass filter smoothing)
%
    predicted_flow = predicted_hydro + storm.mu';
    fit = goodnessOfFit(predicted_flow',storm.no_noise','NRMSE');
end

