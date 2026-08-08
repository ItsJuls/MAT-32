function noteAudio = synth_instrument_note(freq, Fs, patch)
% SYNTH_INSTRUMENT_NOTE  Generate one LA-synthesized note for ANY of the
% 6 supported families (see generate_tail.m). Single entry point --
% instrument differences live entirely in the patch struct + the family
% dispatch, not in this function.
%
%   noteAudio = synth_instrument_note(freq, Fs, patch)
%   freq  - note frequency in Hz (ignored for fully-unpitched percussion)
%   patch - struct. Common to every family:
%       .attackSample   - path to real PCM attack .wav
%       .family         - see generate_tail.m
%       .tailDuration   - synthesized tail length (s). For sustained
%                          families this should cover however long you
%                          intend to hold the note.
%       .tailStartCutoff / .tailEndCutoff / .resonance
%       .crossfadeT
%       For ONE-SHOT families (keyboard/pluckedString/percussion):
%       .tailTau        - decay time constant
%       For SUSTAINED families (bowedString/woodwind/brass):
%       .attackT/.decayT/.sustainLvl/.releaseT
%                       - real ADSR: how long to reach sustain level,
%                         how long that level is held is up to how long
%                         .tailDuration is, and how it releases at the end

% --- 1. Load + trim the real attack transient, measure handoff level ---
[rawSample, tailStartLevel] = prepare_attack_sample(patch, Fs);

% --- 2. Synthesize the raw tail (dispatches by patch.family) ---
[rawTail, isSustained] = generate_tail(patch, freq, Fs);

% --- 3. Shape the tail ---
if isSustained
    % Continuously-energized instrument: use a REAL ADSR with a held
    % sustain level, not an always-decaying exponential -- otherwise a
    % bowed/blown note would die out even while the patch says it's
    % being sustained.
    attackT    = getf(patch, 'attackT', 0.05);
    decayT     = getf(patch, 'decayT', 0.15);
    sustainLvl = getf(patch, 'sustainLvl', 0.75);
    releaseT   = getf(patch, 'releaseT', 0.2);

    ampEnv = adsr_envelope(patch.tailDuration, Fs, attackT, decayT, sustainLvl, releaseT) * tailStartLevel;
    cutoffEnv = tvf_cutoff_envelope(patch.tailDuration, Fs, attackT, decayT, ...
        patch.tailEndCutoff, releaseT, patch.tailStartCutoff);
else
    % One-shot instrument: energy only at the strike, so a pure
    % exponential decay is physically correct -- there's nothing to hold.
    ampEnv = exp_decay_envelope(patch.tailDuration, Fs, patch.tailTau, tailStartLevel);
    cutoffShape = exp_decay_envelope(patch.tailDuration, Fs, patch.tailTau, 1);
    cutoffEnv = patch.tailEndCutoff + (patch.tailStartCutoff - patch.tailEndCutoff) * cutoffShape;
end

tailWave = apply_tvf(rawTail, Fs, cutoffEnv, patch.resonance);

% Lock the very start of the tail to a known level before applying the
% amplitude envelope, so the filter's own gain doesn't fight ampEnv.
measureWin = min(length(tailWave), round(0.01 * Fs));
peakStart = max(abs(tailWave(1:measureWin)));
if peakStart > 0
    tailWave = tailWave / peakStart;
end
tailWave = tailWave .* ampEnv;

% --- 4. Blend the real attack into the synthesized tail ---
noteAudio = blend_attack_sustain(rawSample, tailWave, Fs, patch.crossfadeT);

% Final safety normalization
peakVal = max(abs(noteAudio));
if peakVal > 1
    noteAudio = noteAudio / peakVal;
end
end

function v = getf(s, field, default)
if isfield(s, field)
    v = s.(field);
else
    v = default;
end
end