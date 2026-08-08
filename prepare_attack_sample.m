function [rawSample, tailStartLevel] = prepare_attack_sample(patch, Fs)
% PREPARE_ATTACK_SAMPLE  Load, resample, and trim a real PCM attack
% transient down to just its attack phase, and measure the level the
% tail synthesis should pick up at. This is the ONE place this logic
% lives -- every instrument (cymbal, piano, snare, whatever) goes
% through the same steps, instead of each synth_*_note.m re-implementing
% its own version of "load + trim + measure."
%
%   [rawSample, tailStartLevel] = prepare_attack_sample(patch, Fs)
%   patch fields used:
%       .attackSample      - path to the .wav
%       .autoTrimAttack    - (default true) if true, trims to just the
%                             real attack using detect_attack_end.m.
%                             Set false if you want to hand-supply an
%                             already-trimmed file and skip detection.
%       .attackSearchT     - search window (s) passed to detect_attack_end,
%                             default 0.5
%       .attackPadMs       - pad (ms) passed to detect_attack_end, default 15
%       .tailStartLevel    - optional manual override; if present, skips
%                             the automatic RMS measurement

[rawSample, sampleFs] = load_attack_sample(patch.attackSample);
if sampleFs ~= Fs
    [p, q] = rat(Fs / sampleFs, 1e-6);
    rawSample = resample(rawSample, p, q);
end

autoTrim = true;
if isfield(patch, 'autoTrimAttack')
    autoTrim = patch.autoTrimAttack;
end
if autoTrim
    searchT = 0.5; if isfield(patch, 'attackSearchT'), searchT = patch.attackSearchT; end
    padMs   = 15;  if isfield(patch, 'attackPadMs'),   padMs   = patch.attackPadMs;   end
    endIdx = detect_attack_end(rawSample, Fs, searchT, padMs);
    rawSample = rawSample(1:endIdx);
end

if isfield(patch, 'tailStartLevel')
    tailStartLevel = patch.tailStartLevel;
else
    measureWin = min(length(rawSample), round(0.03 * Fs));
    tailStartLevel = sqrt(mean(rawSample(end-measureWin+1:end).^2)) * sqrt(2);
end
end
