function cutoffEnv = tvf_cutoff_envelope(duration, Fs, attackT, decayT, sustainCutoff, releaseT, peakCutoff)
% TVF_CUTOFF_ENVELOPE  Build a per-sample filter cutoff curve (in Hz) for
% apply_tvf. Reuses the same ADSR shape as the amplitude envelope, but the
% *values* represent cutoff frequency instead of amplitude -- this is what
% gives a note a "bright attack that mellows out" character, independent
% of how loud it is.
%
%   cutoffEnv = tvf_cutoff_envelope(duration, Fs, attackT, decayT, ...
%                                    sustainCutoff, releaseT, peakCutoff)
%   duration      - total note length in seconds
%   Fs            - sample rate in Hz
%   attackT       - time (s) for cutoff to rise from 0 to peakCutoff
%   decayT        - time (s) for cutoff to fall from peakCutoff to sustainCutoff
%   sustainCutoff - cutoff frequency (Hz) held during the sustain portion
%   releaseT      - time (s) for cutoff to fall from sustainCutoff toward 0
%   peakCutoff    - cutoff frequency (Hz) reached at the end of the attack
%                   (typically bright, e.g. 4000-8000 Hz, for a "pluck"-like
%                   opening before settling into sustainCutoff)

shape = adsr_envelope(duration, Fs, attackT, decayT, ...
                       sustainCutoff/peakCutoff, releaseT);
cutoffEnv = shape * peakCutoff;
end
