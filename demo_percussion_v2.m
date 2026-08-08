% DEMO_PERCUSSION_V2  Cymbal through the NEW unified pipeline
% (synth_instrument_note -> generate_tail -> gen_partial_cluster), which
% is where the anti-"gong" fix actually lives. demo_run2.m / 
% synth_percussion_note.m / gen_modal_cluster.m are the OLD pipeline --
% delete or ignore them, they don't have the fix and never will.
pkg load signal;
Fs = 44100;

drumPatch.attackSample   = 'attack_only_v2.wav';  % regenerated with a longer post-peak pad --
                                                    % see message for why
drumPatch.autoTrimAttack = false;

drumPatch.family         = 'percussion';
drumPatch.tailDuration   = 13.0;   % was 8.0 -- real recording rings ~13.4s, match it
drumPatch.tailTau        = 4.5;    % was 3.2 -- slower decay to actually fill the longer duration
drumPatch.crossfadeT     = 0.10;   % was 0.04 -- attack_only_v2.wav has more real post-peak
                                    % material to blend from now, so we can afford a longer,
                                    % gentler timbral handoff instead of a hard 40ms swap

% --- The actual fix from last message ---
drumPatch.numPartials    = 150;    % was 100
drumPatch.freqSpread     = 14;     % was 6  -- wider spread breaks up the "gong" clustering
drumPatch.partialMix     = 0.45;   % was 0.85 -- more noise, less dominant tonal ring
drumPatch.ampRolloffHz   = 2500;   % was hardcoded 900 in the old file -- keeps highs audible

drumPatch.tailStartCutoff = 6000;
drumPatch.tailEndCutoff   = 2000;
drumPatch.resonance       = 1.0;   % was 1.2 -- less resonant ringing at the cutoff

noteFreq = 350; % fundamental the partial cluster is built on top of
mixAudio = synth_instrument_note(noteFreq, Fs, drumPatch);

fullMix = mixAudio / max(abs(mixAudio));
audiowrite('mat32_cymbalcrash_output_v3.wav', fullMix, Fs);

try
    sound(fullMix, Fs);
catch ME
    fprintf('Playback unavailable in this environment (%s).\n', ME.message);
end

fprintf('Demo complete. Wrote mat32_cymbalcrash_output_v3.wav (%.2f sec)\n', length(fullMix)/Fs);
