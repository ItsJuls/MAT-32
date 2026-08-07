function env = adsr_envelope(duration, Fs, attackT, decayT, sustainLvl, releaseT)

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

attack  = linspace(0, 1, aSamples);
decay   = linspace(1, sustainLvl, dSamples);
sustain = ones(1, max(0, sSamples)) * sustainLvl;
release = linspace(sustainLvl, 0, rSamples);


env = [attack, decay, sustain, release];
if length(env) < totalSamples
    env = [env, zeros(1, totalSamples - length(env))];
else
    env = env(1:totalSamples);
end

end