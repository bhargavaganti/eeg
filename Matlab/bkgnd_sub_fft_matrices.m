%
% This file takes the neutral data compiled by conc_data_bkgnd_sub.m and
% calculates the mean. This gives the average electrode values during no
% motor imagery and no arm movements. These average values were subtracted
% from the raw data values to try and subtract away background noise before
% the FFT was computed for each case. The method of doing FFT and handling
% data here are the same as in make_fft_matrices.m
%


% Load raw EEG data

session = 'four_channels';

lhlhem = csvread(['../training_data/' session '/Lhand_Lhem.txt']);
lhrhem = csvread(['../training_data/' session '/Lhand_Rhem.txt']);
rhlhem = csvread(['../training_data/' session '/Rhand_Lhem.txt']);
rhrhem = csvread(['../training_data/' session '/Rhand_Rhem.txt']);
neutral_left = csvread(['../training_data/' session '/neutral_left.txt']);
neutral_right = csvread(['../training_data/' session '/neutral_right.txt']);
%}

% Calculate average neutral background level
avg_bg_l = mean(neutral_left);
avg_bg_r = mean(neutral_right);

% Subtract each electrode's average background value from each observation
% of the actual data. 
for x = 1:length(lhlhem)
    lhlhem(x,:) = lhlhem(x,:) - avg_bg_l;
    lhrhem(x,:) = lhrhem(x,:) - avg_bg_r;
    rhlhem(x,:) = rhlhem(x,:) - avg_bg_l;
    rhrhem(x,:) = rhrhem(x,:) - avg_bg_r;
end


% Setting variables
totalsamples = length(lhlhem);
seconds = 500;
Fs = totalsamples/seconds; % Sampling rate
sampleseconds = 1;
T = 1/Fs;
L = Fs;
f = Fs*(0:(L/2))/L;

% Averaging across channels
lhlhem = mean(lhlhem,2);
lhrhem = mean(lhrhem,2);
rhlhem = mean(rhlhem,2);
rhrhem = mean(rhrhem,2);

lhlhem_fft = zeros(seconds/sampleseconds, L/2+1);
lhrhem_fft = zeros(seconds/sampleseconds, L/2+1);
rhlhem_fft = zeros(seconds/sampleseconds, L/2+1);
rhrhem_fft = zeros(seconds/sampleseconds, L/2+1);

for x = 1:seconds/sampleseconds
    firstindex = sampleseconds*((x-1)*L)+1;
    lastindex = sampleseconds*(x*L);
    
    lhlhem_fft(x,:) = get_fft_coeffs(lhlhem(firstindex:lastindex), L);
    lhrhem_fft(x,:) = get_fft_coeffs(lhrhem(firstindex:lastindex), L);
    rhlhem_fft(x,:) = get_fft_coeffs(rhlhem(firstindex:lastindex), L);
    rhrhem_fft(x,:) = get_fft_coeffs(rhrhem(firstindex:lastindex), L);
end







