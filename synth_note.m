function noteAudio = synth_note(freq, Fs, patch)
% SYNTH_NOTE  Generate one full LA-synthesized note. This is the function
% Kristoff's App Designer GUI should call whenever a key is pressed.
%
%   noteAudio = synth_note(freq, Fs, patch)
%   freq  - frequency of the note being played, in Hz (e.g. 440 for A4)
%   Fs    - project sample rate, e.g. 44100
%   patch - struct describing the "instrument", with fields:
%       .waveform      - 'sine' | 'square' | 'sawtooth' | 'noise'
%                        Use 'noise' for percussive/inharmonic sustains
%                        (cymbals, snares) instead of a tonal oscillator.
%       .dutyCycle     - (square only) 0-1, default 0.5
%       .duration      - total note length in seconds (sustain portion)
%       .attackT       - TVA (amplitude) ADSR attack time (s)
%       .decayT        - TVA (amplitude) ADSR decay time (s)
%       .sustainLvl    - TVA (amplitude) ADSR sustain level (0-1)
%       .releaseT      - TVA (amplitude) ADSR release time (s)
%       .tvfAttackT       - TVF (filter) attack time (s)
%       .tvfDecayT        - TVF (filter) decay time (s)
%       .tvfSustainCutoff - TVF sustain cutoff frequency (Hz)
%       .tvfReleaseT      - TVF release time (s)
%       .tvfPeakCutoff    - TVF peak cutoff frequency (Hz) at end of attack
%       .tvfResonance     - TVF resonance/Q, > 0.5 (0.707 = gentle, 1-4 = "peaky")
%       .attackSample  - path to a .wav PCM attack transient
%       .sampleBaseFreq- pitch (Hz) the .wav was recorded/played at.
%                        Ignored when .isPercussive is true.
%       .crossfadeT    - seconds of overlap between PCM attack and sustain
%       .isPercussive  - (optional, default false) true for inharmonic hits
%                        (cymbals, snares). When true, the attack sample is
%                        NOT pitch-shifted to match freq -- it's played back
%                        as-is (only resampled if its native rate differs
%                        from Fs), since a cymbal has no fundamental pitch
%                        to shift to. Pair with .waveform = 'noise'.
%
%   Returns noteAudio: a row vector containing the finished, playable note.

% --- 1. Generate the mathematically synthesized sustain waveform ---
switch lower(patch.waveform)
    case 'sine'
        sustainWave = gen_sine(freq, patch.duration, Fs);
    case 'square'
        dc = 0.5;
        if isfield(patch, 'dutyCycle')
            dc = patch.dutyCycle;
        end
        sustainWave = gen_square(freq, patch.duration, Fs, dc);
    case 'sawtooth'
        sustainWave = gen_sawtooth(freq, patch.duration, Fs);
    case 'noise'
        sustainWave = gen_noise(patch.duration, Fs);
    otherwise
        error('synth_note:unknownWaveform', 'Unknown waveform "%s"', patch.waveform);
end

% --- 2. Run the raw waveform through the TVF (Time Variant Filter) ---
% This is the piece that stops sawtooth/square from sounding flat/"8-bit" --
% it gives the sustain portion a moving, resonant character over time,
% independent of the amplitude envelope applied next.
cutoffEnv = tvf_cutoff_envelope(patch.duration, Fs, patch.tvfAttackT, ...
    patch.tvfDecayT, patch.tvfSustainCutoff, patch.tvfReleaseT, patch.tvfPeakCutoff);
sustainWave = apply_tvf(sustainWave, Fs, cutoffEnv, patch.tvfResonance);

% --- 3. Shape the (now-filtered) sustain wave with the amplitude ADSR (TVA) ---
env = adsr_envelope(patch.duration, Fs, patch.attackT, patch.decayT, ...
                     patch.sustainLvl, patch.releaseT);
sustainWave = sustainWave .* env;

% --- 4. Load and pitch-shift the PCM attack transient ---
[rawSample, sampleFs] = load_attack_sample(patch.attackSample);

isPercussive = isfield(patch, 'isPercussive') && patch.isPercussive;
if isPercussive
    % No pitch to shift to -- just resample to the project's Fs if needed,
    % and play the hit back the same regardless of which key was pressed.
    attackWave = pitch_shift_sample(rawSample, sampleFs, freq, freq, Fs);
else
    attackWave = pitch_shift_sample(rawSample, sampleFs, patch.sampleBaseFreq, freq, Fs);
end

% --- 5. Blend the PCM attack onto the synthesized sustain ---
noteAudio = blend_attack_sustain(attackWave, sustainWave, Fs, patch.crossfadeT);

% Final safety normalization to avoid clipping when patches are stacked/mixed
peakVal = max(abs(noteAudio));
if peakVal > 1
    noteAudio = noteAudio / peakVal;
end
end
