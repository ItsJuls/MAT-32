function noteAudio = synth_percussion_note(Fs, patch)
% SYNTH_PERCUSSION_NOTE Generate one percussive hit (cymbal, snare, etc.)
% using the real PCM sample for the strike, then EXTENDING it with a
% synthesized filtered-noise tail that continues the sample's own natural
% decay instead of restarting from arbitrary values.
%
% noteAudio = synth_percussion_note(Fs, patch)
%   Fs    - project sample rate, e.g. 44100
%   patch - struct, see fields below (unchanged from original, plus
%           optional .silenceThresholdDb / .silencePadMs -- see trim step)

% --- 1. Load the real percussive sample, exactly as recorded ---
[rawSample, sampleFs] = load_attack_sample(patch.attackSample);
if sampleFs ~= Fs
    [p, q] = rat(Fs / sampleFs, 1e-6);
    rawSample = resample(rawSample, p, q);
end

% --- 1b. Trim baked-in dead air before the crossfade window is chosen ---
% Recordings almost always have some silence/noise floor after the
% instrument has actually stopped ringing. If we crossfade against the
% raw file's last crossfadeT seconds without trimming, that window can
% land entirely inside that dead air: the result is a silent gap
% followed by the synthesized tail popping in abruptly (audible as a
% click/glitch, not a smooth continuation).
if ~isfield(patch, 'silenceThresholdDb'), patch.silenceThresholdDb = -45; end
if ~isfield(patch, 'silencePadMs'), patch.silencePadMs = 15; end
rawSample = trim_trailing_silence(rawSample, Fs, patch.silenceThresholdDb, patch.silencePadMs);

% --- 2. Synthesize a filtered-noise tail that CONTINUES the decay ---
tailNoise = gen_noise(patch.tailDuration, Fs);
ampEnv = exp_decay_envelope(patch.tailDuration, Fs, patch.tailTau, patch.tailStartLevel);
cutoffDecayShape = exp_decay_envelope(patch.tailDuration, Fs, patch.tailTau, 1);
cutoffEnv = patch.tailEndCutoff + (patch.tailStartCutoff - patch.tailEndCutoff) * cutoffDecayShape;
tailWave = apply_tvf(tailNoise, Fs, cutoffEnv, patch.resonance);
tailWave = tailWave .* ampEnv;

% --- 3. Blend the (now-trimmed) real sample into the synthesized tail ---
noteAudio = blend_attack_sustain(rawSample, tailWave, Fs, patch.crossfadeT);

% Final safety normalization
peakVal = max(abs(noteAudio));
if peakVal > 1
    noteAudio = noteAudio / peakVal;
end

end
