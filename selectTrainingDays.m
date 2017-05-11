function [indices_good] = selectTrainingDays(flowtime, flow, Fs, slope, timeSlack, stdMin, stdMax)
% Selects dry-weather training data for GP based on threshold criteria
% provided
%
% Inputs:
%   flowtime: Timestamps corresponding to flow data
%   flow: Flow data
%   Fs: Sensor sampling frequency (samples per day)
%   slope: Threshold for slope of a dry-weather diurnal pattern
%   (trough-to-trough)
%   timeSlack: Threshold for length of a dry-weather diurnal pattern
%   stdMax: Threshold for maximum standard deviation of a dry-weather
%   diurnal pattern
%   stdMin: Threshold for minimum standard deviation of a dry-weather
%   diurnal pattern
%
% Outputs:
%   indices_good: Array indices of training data to be used
%
secondsInDay = 60*60*24;
samples = length(flow);
samplesPerDay = Fs;
days = samples/samplesPerDay;
last = samples - 5/4*samplesPerDay;
trough2 = 0;

%+/- 2 hours
timeChanging = samplesPerDay/(24/timeSlack);

shifts = [];

nf = 0;
nsat = 0;
nsun = 0;
nw = 0;

[mt1, i] = min(flow(1:samplesPerDay));
mins = [flowtime(i) mt1];
lengths = [];

indices_good = [];

while i < last
    
    
    trough2 = flow(i+3/4*samplesPerDay:i+5/4*samplesPerDay);
    
    
    [mt2, mt2_i] = min(trough2);
    dEnd = i+3/4*samplesPerDay+mt2_i-1;
    len = dEnd-i+1;
    mins = [mins; [flowtime(dEnd) mt2]];
    lengths = [lengths; [flowtime(dEnd) len]];
    
    if abs(mt1-mt2) < slope && abs(len-samplesPerDay) < timeChanging ...
            && std(flow(i:dEnd)) < stdMax && std(flow(i:dEnd)) > stdMin
        
        y = linspace(mt1,mt2,len);
        values = flow(i:dEnd)-y;
        indices_good = [indices_good; [i, dEnd]];
        GP_time = linspace(0,secondsInDay,len);
        true_time = flowtime(i:dEnd);
        datetimes = datetime(true_time,'ConvertFrom','epochtime','Epoch','1970-01-01');
        day = mode(weekday(datetimes));
        
        shiftC = mod(flowtime(dEnd),secondsInDay);
        if shiftC < secondsInDay/2
            shiftC = -1*shiftC;
        else
            shiftC = secondsInDay - shiftC;
        end
        shifts = [shifts; [flowtime(dEnd) shiftC]];
        
    end
    i = dEnd;
    mt1 = mt2;
    
end

end
        

