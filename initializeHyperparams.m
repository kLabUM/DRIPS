clear all;
close all;

%% User inputs

Site = 33;
diurnal_lookback = 1;
testfolder = '';

Fs = 288;	% Sensor sampling frequency (number per day)

% Threshold criteria
slope = 0.25;
timeSlack = 3;
stdMax = 0.48;
stdMin = 0.25;

% Dry-weather section for learning hyperparameters
starti = 105121;                            % Start index
chunk = round(diurnal_lookback*Fs*365/12);	% Lookback length
endi = starti+chunk;
section = starti:endi;

%% File prep

load(strcat('./RawData/', 'Site', num2str(Site),'_hist.mat')); % Historical data
filepath = strcat('./Data/');
mkdir(filepath);
filepath = strcat('./Data/', 'Site', num2str(Site,'%02.0f'), testfolder, '/');
mkdir(filepath);

all_datetime = datetime(FlowTime,'ConvertFrom','epochtime','Epoch','1970-01-01');

%% GP prep

run('./gpml-matlab-v3.6-2015-07-07/startup.m')

k2 = @covPeriodic;
k3 = @covRQard;
covfunc = {@covSum, {k2, k3}};

%% Flow filters

filter_diurnal_SOS = load('./diurn_butter_SOS.mat');
filter_diurnal_G = load('./diurn_butter_G.mat');

%% Remove high frequency noise

no_noise = smoothts(Flow,'g',300,100); 

%% Extract diurnal

diurnals = filtfilt(filter_diurnal_SOS.SOS,filter_diurnal_G.G,no_noise);

%% Data to be used

timeSection = all_datetime(section);
FlowSection = FlowTime(section);
diurnalSection = diurnals(section);

all_good = selectTrainingDays(FlowTime, diurnals, Fs, slope, timeSlack, stdMin, stdMax);
good_i = selectTrainingDays(FlowSection, diurnalSection, Fs, slope, timeSlack, stdMin, stdMax);

all_good_ind = [];
for i = 1:length(all_good)
    all_good_ind = [all_good_ind, all_good(i,1):all_good(i,2)];
end

good_ind = [];
for i = 1:length(good_i)
    good_ind = [good_ind, good_i(i,1):good_i(i,2)];
end

figure(1)
hold on
plot(all_datetime, no_noise)
plot(all_datetime, diurnals,'k')
plot(all_datetime(all_good_ind),diurnals(all_good_ind),'linewidth',4);
plot(timeSection(good_ind), diurnalSection(good_ind));
legend('filtered raw data','all diurnals','good diurnals','selection')

disp('Check good diurnals which will be used for training; adjust criteria thresholds as needed')
pause

%% Run GP

hyp = [];
hyp.cov = [0 0 1 0 0 -1]; hyp.lik = -2;

y = diurnalSection(good_ind)';
x = timeToWeekdayDecimal(timeSection(good_ind)');

step = floor(length(y)/3500);
if step == 0
    step = 1;
end

y = y(1:step:length(x));
x = x(1:step:length(x));

x_star = timeToWeekdayDecimal(timeSection)';

[hyp fX i] = minimize(hyp, @gp, -100, @infExact, [], covfunc, @likGauss, x, y);
[mu s2] = gp(hyp, @infExact, [], covfunc, @likGauss, x, y, x_star);


%% Plot results for final check

figure(1)
plot(timeSection,mu)
legend('filtered raw data','all diurnals','good diurnals','selection','results')

%% Save hyperparameters

no_noise = no_noise(section);
diurnals = diurnalSection;
all_datetime = timeSection;
FlowTime = FlowSection;

HyperFile = strcat(filepath,'HypInit',num2str(Site,'%02.0f'),'.mat');
save(HyperFile,'hyp','slope','timeSlack','stdMax','stdMin');
