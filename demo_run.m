% DEMO_RUN  End-to-end test of the MAT-32 DSP engine.
% Requires RideCymbal.wav to already exist in this folder.

Fs = 44100;

% --- Tonal patch (sawtooth through DCO -> TVF -> TVA) ---
% TVF values tamed from earlier versions: high resonance + a wide cutoff
% sweep on a resonant filter is literally how a wah pedal works, which is
% why earlier notes sounded vocal/"meowing." Lower resonance and a
% narrower sweep keeps the "opens up, then settles" character without the
% vowel-like glide.
patch.waveform       = 'sawtooth';
patch.duration        = 1.0;
patch.attackT          = 0.02;
patch.decayT            = 0.15;
patch.sustainLvl      = 0.7;
patch.releaseT          = 0.3;
patch.attackSample    = 'placeholder_attack.wav';
patch.sampleBaseFreq = 261.63;
patch.crossfadeT      = 0.015;

patch.tvfAttackT        = 0.03;
patch.tvfDecayT         = 0.4;     % slower, less "swoopy"
patch.tvfSustainCutoff  = 1200;    % was 800 -- doesn't drop as low
patch.tvfReleaseT       = 0.3;
patch.tvfPeakCutoff     = 2500;    % was 4000 -- less extreme opening brightness
patch.tvfResonance      = 0.8;     % was 1.5 -- avoids the wah/vocal glide

% Placeholder attack, only needed because this patch has no real recorded
% attack sample. Swap for a real one (piano strike, etc.) when you have it.
attackDur = 0.03;
t = (0:round(attackDur*Fs)-1) / Fs;
placeholderAttack = randn(1, length(t)) .* linspace(1, 0, length(t));
placeholderAttack = placeholderAttack / max(abs(placeholderAttack));
audiowrite('placeholder_attack.wav', placeholderAttack, Fs);

notesHz = [261.63, 329.63, 392.00, 523.25]; % C4, E4, G4, C5
gap = 0.05;

fullMix = [];
for f = notesHz
    noteAudio = synth_note(f, Fs, patch);
    fullMix = [fullMix, noteAudio, zeros(1, round(gap*Fs))]; %#ok<AGROW>
end

% --- Percussion voice: real RideCymbal.wav + synthesized tail that ---
% --- continues its own measured decay, instead of restarting cold  ---
%
% Measured from your actual RideCymbal.wav:
%   - it decays to near-silence by ~0.5s
%   - its brightness sweeps from ~7800 Hz (the strike) down to ~5000 Hz
%     by the time it fades out
%   - the decay is roughly exponential, not linear
% The tail below picks up right where that leaves off and keeps ringing
% out further using synthesis, rather than the sample just stopping.
cymbalPatch.attackSample   = 'RideCymbal.wav';
cymbalPatch.tailDuration    = 1.2;     % extra synthesized ring-out beyond the real sample
cymbalPatch.tailStartCutoff = 5000;    % matches the real sample's brightness at handoff
cymbalPatch.tailEndCutoff   = 1200;    % settles to a dark rumble by the end of the tail
cymbalPatch.tailTau         = 0.35;    % exponential decay time constant
cymbalPatch.tailStartLevel  = 0.15;    % matches the real sample's level at handoff (not full volume)
cymbalPatch.resonance       = 0.7;     % kept low -- avoids the wah artifact from before
cymbalPatch.crossfadeT      = 0.08;    % overlap starts where the real hit is already fading, not on the loud transient

cymbalAudio = synth_percussion_note(Fs, cymbalPatch);
fullMix = [fullMix, cymbalAudio];

% --- Save and play ---
fullMix = fullMix / max(abs(fullMix));
audiowrite('mat32_demo_output.wav', fullMix, Fs);

try
    sound(fullMix, Fs);
catch ME
    fprintf('Playback unavailable in this environment (%s).\n', ME.message);
    fprintf('Download mat32_demo_output.wav from the Files panel to listen.\n');
end

fprintf('Demo complete. Wrote mat32_demo_output.wav (%.2f sec)\n', length(fullMix)/Fs);
