%
% This script is for generating the FFT coefficients during the neutral
% portion of testing, where there was no motor imagery and no arm
% movements. These FFT coefficient vectors are later used (in another file)
% to be subtracted from the right- and left-hand FFT coefficients in an
% attempt to get a better reading of the signal. It didn't work. Which
% actually makes a lot of sense in hindsight, but I was just trying a lot
% of things.
%


% Load raw EEG data
neutral_left = csvread('../training_data/ten_channels/neutral_left.txt');
neutral_right = csvread('../training_data/ten_channels/neutral_right.txt');

% Setting variables
totalsamples = length(neutral_left);
seconds = 500;
Fs = totalsamples/seconds; % Sampling rate
sampleseconds = 1;
T = 1/Fs;
L = Fs;
f = Fs*(0:(L/2))/L;

% Averaging across channels
neutral_left = mean(neutral_left,2);
neutral_right = mean(neutral_right,2);

nL_fft = zeros(seconds/sampleseconds, L/2+1);
nR_fft = zeros(seconds/sampleseconds, L/2+1);

for x = 1:seconds/sampleseconds
    firstindex = sampleseconds*((x-1)*L)+1;
    lastindex = sampleseconds*(x*L);
    
    nL_fft(x,:) = get_fft_coeffs(neutral_left(firstindex:lastindex), L);
    nR_fft(x,:) = get_fft_coeffs(neutral_right(firstindex:lastindex), L);
end


