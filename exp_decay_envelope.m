function env = exp_decay_envelope(duration, Fs, tau, startLevel)
% EXP_DECAY_ENVELOPE  Build an exponentially-decaying envelope.
% Real percussive sounds (cymbals, drums, plucks) lose energy roughly
% exponentially, not in straight lines -- adsr_envelope's linear decay/
% release segments are a reasonable approximation for tonal instruments,
% but for a cymbal tail they read as artificial. This gives a natural
% "ring out" curve instead.
%
%   env = exp_decay_envelope(duration, Fs, tau, startLevel)
%   duration   - length in seconds
%   Fs         - sample rate in Hz
%   tau        - decay time constant in seconds (bigger = slower decay/
%                longer ring; roughly, level drops to ~37% of startLevel
%                after "tau" seconds)
%   startLevel - amplitude at t=0 (0-1), default 1

if nargin < 4
    startLevel = 1;
end
t = (0:round(duration*Fs)-1) / Fs;
env = startLevel * exp(-t / tau);
end
