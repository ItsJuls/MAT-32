function env = adsr_envelope(duration, Fs, attackT, decayT, sustainLvl, releaseT, envCurve)

% Default to linear if envCurve is not provided
if nargin < 7
    envCurve = 'linear';
end

totalSamples = round(duration * Fs);

aSamples = round(attackT * Fs);
dSamples = round(decayT * Fs);
rSamples = round(releaseT * Fs);

adrSamples = aSamples + dSamples + rSamples;
if adrSamples > totalSamples
    scale = totalSamples / adrSamples;
    aSamples = round(aSamples * scale);
    dSamples = round(dSamples * scale);
    rSamples = totalSamples - aSamples - dSamples; % absorb rounding error here
end

sSamples = totalSamples - (aSamples + dSamples + rSamples);

% --- GENERATE ATTACK ---
attack  = linspace(0, 1, aSamples);

% --- GENERATE DECAY AND RELEASE ---
if strcmpi(envCurve, 'exponential')
    t_d = linspace(0, 1, dSamples);
    decay = sustainLvl + (1 - sustainLvl) * exp(-5 * t_d);

    t_r = linspace(0, 1, rSamples);
    release = sustainLvl * exp(-5 * t_r);
else
    decay   = linspace(1, sustainLvl, dSamples);
    release = linspace(sustainLvl, 0, rSamples);
end

% --- GENERATE SUSTAIN AND CONCATENATE ---
sustain = ones(1, max(0, sSamples)) * sustainLvl;

env = [attack, decay, sustain, release];

if length(env) < totalSamples
    env = [env, zeros(1, totalSamples - length(env))];
else
    env = env(1:totalSamples);
end

end