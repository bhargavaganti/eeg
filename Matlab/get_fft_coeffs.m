%% Get FFT Coeffs
% by Keaton Armentrout

% This function gets one-sided coefficients from performing the FFT on the
% data in samples.

% Inputs
%   # samples - raw electrode data recorded from EEG headset, averaged over
%       channels
%   # L - sampling rate

% Outputs
%   # coeffs - vector of FFT coefficients

function [ coeffs ] = get_fft_coeffs( samples, L )
    data_fft = fft(samples);

    P2 = abs(data_fft/L);
    P1 = P2(1:L/2+1,:);
    P1(2:end-1,:) = 2*P1(2:end-1,:);

    coeffs = P1;
end

