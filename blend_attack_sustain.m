function blended = blend_attack_sustain(attackWave, sustainWave, Fs, crossfadeT)
crossfadeSamples = min(round(crossfadeT * Fs), min(length(attackWave), length(sustainWave)));

attackLen  = length(attackWave);
sustainLen = length(sustainWave);
totalLen   = attackLen + sustainLen - crossfadeSamples;

blended = zeros(1, totalLen);

blended(1:attackLen) = attackWave;

if crossfadeSamples > 0
    fadeOut = linspace(1, 0, crossfadeSamples);
    fadeIn  = linspace(0, 1, crossfadeSamples);

    xfadeStart = attackLen - crossfadeSamples + 1;
    blended(xfadeStart:attackLen) = ...
        attackWave(end-crossfadeSamples+1:end) .* fadeOut + ...
        sustainWave(1:crossfadeSamples) .* fadeIn;
end

blended(attackLen+1:end) = sustainWave(crossfadeSamples+1:end);
end
