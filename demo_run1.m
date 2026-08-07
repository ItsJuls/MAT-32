% DEMO_RUN  End-to-end test of the MAT-32 percussion voice.
% Requires RideCymbal.wav to already exist in this folder.
Fs = 44100;

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
cymbalPatch.tailStartLevel  = 0.08;    % re-measured at the -30dB splice point (~0.27s).
                                        % NOTE: the recording's audible ring genuinely dies
                                        % by ~0.5s, so matching the tail level THERE (0.025,
                                        % previous value) made the whole synthesized tail
                                        % inaudible -- technically seamless, but silent.
                                        % Splicing earlier, while the real hit is still
                                        % audibly ringing, trades a little bit of splice
                                        % purity for a tail you can actually hear.
cymbalPatch.silenceThresholdDb = -30;  % was -45 (default in synth_percussion_note.m).
                                        % Less negative = trims more = splices earlier/louder.
                                        % Tune this to taste: -45 is quietest/most "honest",
                                        % -25 is loudest/most obvious swell at the handoff.
cymbalPatch.resonance       = 0.7;     % kept low -- avoids the wah artifact from before
cymbalPatch.crossfadeT      = 0.08;    % overlap starts where the real hit is already fading, not on the loud transient

cymbalAudio = synth_percussion_note(Fs, cymbalPatch);

% --- Save and play ---
fullMix = cymbalAudio / max(abs(cymbalAudio));
audiowrite('mat32_demo_output.wav', fullMix, Fs);
try
    sound(fullMix, Fs);
catch ME
    fprintf('Playback unavailable in this environment (%s).\n', ME.message);
    fprintf('Download mat32_demo_output.wav from the Files panel to listen.\n');
end
fprintf('Demo complete. Wrote mat32_demo_output.wav (%.2f sec)\n', length(fullMix)/Fs);
