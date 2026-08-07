function trimmed = trim_trailing_silence(wave, Fs, thresholdDb, padMs)
% TRIM_TRAILING_SILENCE Cut off dead air at the end of a recorded sample.
%
% Real recordings almost always have some silence/noise-floor tail past
% where the instrument actually stops ringing. If you crossfade against
% the last N seconds of the raw file, that window can land entirely
% inside that dead air -- the result is a silent gap followed by the
% next sound source (e.g. a synthesized tail) popping in abruptly,
% which reads to the ear as a click/glitch rather than a smooth handoff.
%
% This finds the last point where the smoothed envelope is still above
% thresholdDb relative to the sample's peak, and trims everything after
% that (plus a small pad so we don't cut off a still-decaying edge).
%
% trimmed = trim_trailing_silence(wave, Fs, thresholdDb, padMs)
%   wave        - row vector, mono sample
%   Fs          - sample rate in Hz
%   thresholdDb - level (dB below peak) considered "still sounding".
%                 default -45. Raise (e.g. -35) if a sample has audible
%                 hiss/hum at the tail; lower if you're cutting off
%                 real decay.
%   padMs       - milliseconds kept after the detected point, so the
%                 trim doesn't land mid-decay. default 15.

if nargin < 3, thresholdDb = -45; end
if nargin < 4, padMs = 15; end

peakVal = max(abs(wave));
if peakVal == 0
    trimmed = wave;
    return;
end

% Smooth envelope (3ms window) so we don't trigger on a single noisy
% sample right at the edge of the noise floor.
envWin = max(1, round(0.003 * Fs));
envelope = movmean(abs(wave), envWin);

thresholdLin = peakVal * 10^(thresholdDb / 20);
lastIdx = find(envelope > thresholdLin, 1, 'last');

if isempty(lastIdx)
    trimmed = wave; % never crosses threshold -- leave it alone
    return;
end

padSamples = round(padMs / 1000 * Fs);
endIdx = min(length(wave), lastIdx + padSamples);
trimmed = wave(1:endIdx);

end
