%
% This script is the first step in data analysis. It first loads the 
% concatenated electrode data that was complied by conc_data.m and 
% separated by hand activity and brain hemisphere. Then it computes the FFT
% coefficients on each 1-second interval of the data, ending up with 500
% vectors of coefficients for each hand movement.
% The results are saved as four matrices labeled [condition]_fft
%

% Load raw EEG data
session = 'four_channels_timed';

lhlhem = csvread(['../training_data/' session '/Lhand_Lhem.txt']);
lhrhem = csvread(['../training_data/' session '/Lhand_Rhem.txt']);
rhlhem = csvread(['../training_data/' session '/Rhand_Lhem.txt']);
rhrhem = csvread(['../training_data/' session '/Rhand_Rhem.txt']);

% Setting variables
totalsamples = length(lhlhem);
seconds = 500;
Fs = totalsamples/seconds; % Sampling rate
sampleseconds = 1;
T = 1/Fs;
L = Fs;
f = Fs*(0:(L/2))/L;

% Averaging across channels
% Necessary for the FFT
lhlhem = mean(lhlhem,2);
lhrhem = mean(lhrhem,2);
rhlhem = mean(rhlhem,2);
rhrhem = mean(rhrhem,2);

lhlhem_fft = zeros(seconds/sampleseconds, L/2+1);
lhrhem_fft = zeros(seconds/sampleseconds, L/2+1);
rhlhem_fft = zeros(seconds/sampleseconds, L/2+1);
rhrhem_fft = zeros(seconds/sampleseconds, L/2+1);

% Make FFT matrices for 1-second intervals of the data
for x = 1:seconds/sampleseconds
    firstindex = sampleseconds*((x-1)*L)+1;
    lastindex = sampleseconds*(x*L);
    
    lhlhem_fft(x,:) = get_fft_coeffs(lhlhem(firstindex:lastindex), L);
    lhrhem_fft(x,:) = get_fft_coeffs(lhrhem(firstindex:lastindex), L);
    rhlhem_fft(x,:) = get_fft_coeffs(rhlhem(firstindex:lastindex), L);
    rhrhem_fft(x,:) = get_fft_coeffs(rhrhem(firstindex:lastindex), L);
end



%%
% The rest is just data manipulation and plotting so that at the beginning
% of the study I was able to see the differences across conditions (e.g.
% differences in FFT power between right and left hand movement across
% different sides of the brain, etc.) The important output of this file is
% above in the [condition]_fft matrices.
%

% Average across intervals
lhlhem_v = mean(lhlhem_fft,1);
lhrhem_v = mean(lhrhem_fft,1);
rhlhem_v = mean(rhlhem_fft,1);
rhrhem_v = mean(rhrhem_fft,1);

% Figure out difference between eyes open and closed in alpha band
% This was only when the eyes_open and eyes_closed data files are loaded
%{
avg_rhand_v = mean([rhlhem_v; rhrhem_v],1);
avg_lhand_v = mean([lhlhem_v; lhrhem_v],1);

alpha_open = avg_lhand_v(find(f >= 8 & f <= 15));
alpha_closed = avg_rhand_v(find(f >= 8 & f <= 15));

eyes_diff = alpha_closed - alpha_open;
avg_eyes_diff = mean(eyes_diff,2);
%}

% Plotting to visualize differences across conditions

%{
figure;
plot(f(1:end),lhlhem_v(1:end,:));
hold on;
plot(f(1:end),lhrhem_v(1:end,:));
title('Single-Sided Amplitude Spectrum During Left Hand MI');
xlabel('f (Hz)');
ylabel('|P1(f)| Averaged Over Intervals');
legend('Left Hemisphere', 'Right Hemisphere');
xlim([5 30]);
%ylim([10 40]);

figure;
plot(f(1:end),rhlhem_v(1:end,:));
hold on;
plot(f(1:end),rhrhem_v(1:end,:));
title('Single-Sided Amplitude Spectrum During Right Hand MI');
xlabel('f (Hz)');
ylabel('|P1(f)| Averaged Over Intervals');
legend('Left Hemisphere', 'Right Hemisphere');
xlim([5 30]);
%ylim([10 40]);


avg_rhand_v = mean([rhlhem_v; rhrhem_v],1);
avg_lhand_v = mean([lhlhem_v; lhrhem_v],1);

figure;
plot(f(1:end),avg_lhand_v(1:end,:));
hold on;
plot(f(1:end),avg_rhand_v(1:end,:));
title('Full Brain Activity');
xlabel('f (Hz)');
ylabel('|P1(f)| Averaged Over Intervals');
legend('Left Hand', 'Right Hand');
xlim([5 30]);
ylim([10 40]);



lhem_diff = rhlhem_v - lhlhem_v;
rhem_diff = rhrhem_v - lhrhem_v;

figure;
plot(lhem_diff);
title('rhlhem - lhlhem');
%ylim([-0.4 0.4]);
xlim([5 20]);

figure;
plot(rhem_diff);
title('rhrhem - lhrhem');
%ylim([-0.4 0.4]);
xlim([5 20]);


lhand_diff = lhrhem_v - lhlhem_v;
rhand_diff = rhrhem_v - rhlhem_v;

figure;
plot(lhand_diff);
title('lhrhem - lhlhem');
ylim([-0.4 3]);

figure;
plot(rhand_diff);
title('rhrhem - rhlhem');
ylim([-0.4 3]);

%}






