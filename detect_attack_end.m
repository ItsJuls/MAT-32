function [attackEndIdx, attackEndT] = detect_attack_end(wave, Fs, searchWindowT, padMs)
% DETECT_ATTACK_END  Find where a percussive sample's real "attack" ends
% and its decay begins, so you can trim a sample down to JUST the attack
% for LA-style synthesis (real PCM transient -> synthesized sustain).
%
% Definition used here (matches the ADSR convention already used in
% adsr_envelope.m): the attack phase runs from onset to the point where
% the amplitude ENVELOPE reaches its peak. For many percussive sounds
% (drum hits) that's almost instant. For a large cymbal/plate, the
% envelope keeps building for 100-250ms after the stick strike as the
% plate physically rings up -- cutting before that peak would chop off
% real, physical, unfakeable information and hand the synth engine a
% harder job than it needs.
%
%   [attackEndIdx, attackEndT] = detect_attack_end(wave, Fs, searchWindowT, padMs)
%   wave          - row vector, mono sample
%   Fs            - sample rate in Hz
%   searchWindowT - only look for the peak within this many seconds from
%                   the start (default 0.5). Prevents accidentally
%                   grabbing a later, louder moment in a long sample.
%   padMs         - milliseconds kept after the detected peak, so the
%                   trim doesn't land exactly on the sample's single
%                   loudest point (which can click). default 15.
%
%   attackEndIdx - sample index where the attack phase ends
%   attackEndT   - same, in seconds

if nargin < 3, searchWindowT = 0.5; end
if nargin < 4, padMs = 15; end

envWin = max(1, round(0.003 * Fs)); % 3ms smoothing, same as trim_trailing_silence
envelope = movmean(abs(wave), envWin);

searchSamples = min(length(wave), round(searchWindowT * Fs));
[~, peakIdx] = max(envelope(1:searchSamples));

padSamples = round(padMs / 1000 * Fs);
attackEndIdx = min(length(wave), peakIdx + padSamples);
attackEndT = attackEndIdx / Fs;

end
