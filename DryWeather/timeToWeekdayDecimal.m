function [decWeek] = timeToWeekdayDecimal(time_vector)
% Converts datetime vector to decimal representing day of week and time of
% day
%
% Inputs:
%   time_vector: Datetime-format array
%
% Outputs:
%   decWeek = Number representing day of week and time of day
%   (e.g., Tues, Jan 1, 2013 06:00:00 = 3.25)
%
decWeek = (weekday(time_vector)+hour(time_vector)/24+minute(time_vector)/(24*60)+second(time_vector)/(24*60*60));

end