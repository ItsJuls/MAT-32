function blended = blend_attack_sustain(attackWave, sustainWave, Fs, crossfadeT)
% BLEND_ATTACK_SUSTAIN Crossfade a real attack sample into a synthesized
% sustain/tail. Uses an equal-power (constant-loudness) crossfade curve
% instead of a straight linear ramp -- a linear ramp makes the *sum* of
% the two signals dip in perceived loudness through the middle of the
% overlap (0.5+0.5 sounds quieter than either signal alone), which reads
% as a small "hole" even when both sides genuinely have signal in them.
%
% IMPORTANT: this only fixes the crossfade *shape*. If attackWave has
% trailing silence baked in past where the instrument actually stopped
% sounding, run it through trim_trailing_silence() first -- otherwise
% the crossfade window can still land in dead air regardless of curve.

crossfadeSamples = min(round(crossfadeT * Fs), min(length(attackWave), length(sustainWave)));

attackLen = length(attackWave);
sustainLen = length(sustainWave);
totalLen = attackLen + sustainLen - crossfadeSamples;

blended = zeros(1, totalLen);
blended(1:attackLen) = attackWave;

if crossfadeSamples > 0
    % Equal-power curve: fadeOut^2 + fadeIn^2 == 1 at every point,
    % so combined energy stays constant through the overlap.
    theta = linspace(0, pi/2, crossfadeSamples);
    fadeOut = cos(theta);
    fadeIn  = sin(theta);

    xfadeStart = attackLen - crossfadeSamples + 1;
    blended(xfadeStart:attackLen) = ...
        attackWave(end-crossfadeSamples+1:end) .* fadeOut + ...
        sustainWave(1:crossfadeSamples) .* fadeIn;
end

blended(attackLen+1:end) = sustainWave(crossfadeSamples+1:end);

end
