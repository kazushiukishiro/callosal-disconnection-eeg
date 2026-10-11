function [dwpliBand,details] = calculate_dwpli(xL,xR,fs,band)
% CALCULATE_DWPLI
% Debiased squared weighted phase lag index
%
% Inputs
%   xL, xR : paired EEG signals
%   fs     : sampling rate (Hz)
%   band   : frequency band, e.g. [4 13]
%
% Output
%   dwpliBand : mean debiased squared wPLI across frequency band
%   details   : frequency-resolved values and QC information

xL = double(xL(:));
xR = double(xR(:));

%% Basic QC
if length(xL) ~= length(xR)
    error('xL and xR must have the same length.');
end

if any(~isfinite(xL)) || any(~isfinite(xR))
    dwpliBand = NaN;
    details = struct;
    return
end

%% Spectral parameters
windowSec = 2;
overlapFraction = 0.5;

winLength = round(windowSec * fs);
overlapLength = round(winLength * overlapFraction);
stepLength = winLength - overlapLength;

win = hann(winLength,'periodic');

nfft = max(2^nextpow2(winLength),winLength);

%% Segment start positions
starts = 1:stepLength:(length(xL)-winLength+1);

nSegments = numel(starts);

if nSegments < 3
    dwpliBand = NaN;
    details = struct;
    return
end

%% Frequency axis
f = (0:nfft/2)' * fs / nfft;

bandMask = ...
    f >= band(1) & ...
    f <= band(2);

nBandFreq = sum(bandMask);

imagCross = nan(nBandFreq,nSegments);

%% FFT for each segment
for k = 1:nSegments

    idx = starts(k):(starts(k)+winLength-1);

    segL = xL(idx);
    segR = xR(idx);

    % remove segment mean
    segL = segL - mean(segL);
    segR = segR - mean(segR);

    % Hann taper
    segL = segL .* win;
    segR = segR .* win;

    XL = fft(segL,nfft);
    XR = fft(segR,nfft);

    XL = XL(1:nfft/2+1);
    XR = XR(1:nfft/2+1);

    % Cross-spectrum
    crossSpec = XL .* conj(XR);

    imagCross(:,k) = imag(crossSpec(bandMask));

end

%% Debiased squared WPLI
sumImag = sum(imagCross,2);
sumAbsImag = sum(abs(imagCross),2);
sumImagSq = sum(imagCross.^2,2);

numerator = ...
    sumImag.^2 - sumImagSq;

denominator = ...
    sumAbsImag.^2 - sumImagSq;

dwpliFreq = numerator ./ denominator;

% invalid denominators
dwpliFreq(denominator <= 0) = NaN;

%% Important:
% Debiased estimator can become slightly negative because of finite-sample
% bias correction. Do NOT force values to [0,1].

dwpliBand = mean(dwpliFreq,'omitnan');

%% Output details
details = struct;

details.Frequency = f(bandMask);
details.dwPLI = dwpliFreq;
details.NumberOfSegments = nSegments;
details.WindowSec = windowSec;
details.OverlapFraction = overlapFraction;
details.ValidFrequencyCount = sum(isfinite(dwpliFreq));

end
