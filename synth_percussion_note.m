function noteAudio = synth_percussion_note(Fs, patch)
% SYNTH_PERCUSSION_NOTE  Generate one percussive hit (cymbal, snare, etc.)
% using the real PCM sample for the strike, then EXTENDING it with a
% synthesized filtered-noise tail that continues the sample's own natural
% decay instead of restarting from arbitrary values. This mirrors how the
% real MT-32 had a separate Rhythm section, architecturally distinct from
% its tonal DCO->TVF->TVA Timbres.
%
%   noteAudio = synth_percussion_note(Fs, patch)
%   Fs    - project sample rate, e.g. 44100
%   patch - struct with fields:
%       .attackSample   - path to the real percussive .wav (played as-is,
%                          never pitch-shifted -- percussion has no pitch)
%       .tailDuration    - seconds of SYNTHESIZED tail to add after the
%                          real sample (the "ring out" beyond what was
%                          actually recorded)
%       .tailStartCutoff - TVF cutoff (Hz) at the start of the synthesized
%                          tail. Set this to match the brightness of the
%                          END of your real sample (check with a spectral
%                          centroid analysis) so the handoff is seamless
%                          rather than an audible jump in tone.
%       .tailEndCutoff   - TVF cutoff (Hz) the tail decays toward
%       .tailTau         - exponential decay time constant (s) for both
%                          the tail's amplitude and its cutoff sweep --
%                          bigger = longer, slower ring out
%       .tailStartLevel  - amplitude (0-1) of the tail at the handoff
%                          point. Should roughly match the real sample's
%                          own amplitude at the moment the tail kicks in,
%                          or you'll hear a level jump.
%       .resonance       - TVF resonance/Q, > 0.5. Keep this LOW (0.6-0.9)
%                          for percussion -- high resonance on a filter
%                          sweep is what creates the "wah"/vocal artifact
%                          you heard on the tonal patches.
%       .crossfadeT      - seconds of overlap between the real sample and
%                          the synthesized tail
%
%   Returns noteAudio: a row vector, the finished percussion hit.

% --- 1. Load the real percussive sample, exactly as recorded ---
% No pitch-shifting -- a cymbal has no fundamental pitch to shift to.
[rawSample, sampleFs] = load_attack_sample(patch.attackSample);
if sampleFs ~= Fs
    [p, q] = rat(Fs / sampleFs, 1e-6);
    rawSample = resample(rawSample, p, q);
end

% --- 2. Synthesize a filtered-noise tail that CONTINUES the decay ---
% Exponential envelope (matches how real percussion actually loses
% energy) and exponential cutoff sweep (matches the sample's own
% brightness trend), both starting from the handoff values so the
% synthesized portion doesn't sound like a separate, disconnected event.
tailNoise = gen_noise(patch.tailDuration, Fs);

ampEnv = exp_decay_envelope(patch.tailDuration, Fs, patch.tailTau, patch.tailStartLevel);

cutoffDecayShape = exp_decay_envelope(patch.tailDuration, Fs, patch.tailTau, 1);
cutoffEnv = patch.tailEndCutoff + (patch.tailStartCutoff - patch.tailEndCutoff) * cutoffDecayShape;

tailWave = apply_tvf(tailNoise, Fs, cutoffEnv, patch.resonance);
tailWave = tailWave .* ampEnv;

% --- 3. Blend the real sample into the synthesized tail ---
noteAudio = blend_attack_sustain(rawSample, tailWave, Fs, patch.crossfadeT);

% Final safety normalization
peakVal = max(abs(noteAudio));
if peakVal > 1
    noteAudio = noteAudio / peakVal;
end
end
