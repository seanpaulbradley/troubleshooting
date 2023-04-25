clear all

% Import data from TDT bin
tdtdata = TDTbin2mat('C:\uprojects\rlingg\07')

% Define "tdtframes" (from ephys sync TTL line) and "tdttimes" (from cue
% onset TTL line); these are times in seconds from the start of recording
% on TDT
tdtframes = tdtdata.epocs.PC0_.onset;
tdtcuetimes = tdtdata.epocs.PC1_.onset;

% Import anymaze output
anydata = readtable('C:\uprojects\rlingg\07\i7.csv')
% Find cue TTL onsets in df
anyttl = zeros(size(anydata.LoomTriggerActive));
anyttl(2:end) = diff(anydata.LoomTriggerActive);
anyoutput = table();
% Align to times
anyoutput = [anydata.Time,anyttl];
anymazetimes = anyoutput(anyoutput(:,2)==1)

% Find disparity between onset of cue TTL in anymaze vs TDT; this corrects
% for an apparent 17 second gap between the start of TDT and the start of
% any-maze, although row timestamps still don't line up well
timecomp = [anymazetimes, tdtcuetimes];
timecomparison = tdtcuetimes-anymazetimes;
cuetimes = table();
cuetimes = table(tdtcuetimes, anymazetimes, timecomparison)

%Cut off junk 0 observation on anymaze
anydata = anydata(2:end,:)
% Subtract out onset correction of about 17 seconds
syncpulsetimes_cor = tdtframes-timecomparison(1)

%%What we want to happen: an exact(ish) match of the number and timing of anymaze observations and sync pulses sent to TDT
%%What we have:

% Disparity in frame counts: Any maze has 57 more observations than TDT has
% sync pulses
framedisp = numel(syncpulsetimes_cor)-numel(anydata.Time)
%Disparity in frame timing in ms (aligning frames start to finish and cropping 58
%excess anymaze frames) averages 1s over the whole of the session,
%seemingly caused by stochastic increases in disparity (non-smooth).
anydata_crop = anydata(1:end-57,:)
differror = (syncpulsetimes_cor-anydata_crop.Time)*1000;
%Between frames ~2868 and 3000 (around 4.5s) the disparity jumps from ~70 ms to ~250 ms. 
%It doesn't make sense to me why errors would seemingly propogate in this
%fashion; in theory, this method should be resilient to dropped frames or
%other timing errors because each frame's sync pulse is generated independently.  So, I'm confused.
differrorplot = plot(differror)
hold on
xlabel("Frame")
ylabel("Disparity between Any-maze and TDT frame timing")
mean(anydata_crop.Time-syncpulsetimes_cor)
writetable(cuetimes,'cuetimes.xlsx')
writematrix(syncpulsetimes_cor,'tdt_sync_pulse_times.xlsx')
savefig(differrorplot,'differrorplot.png')
