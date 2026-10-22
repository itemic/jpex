#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// A ring of water spreading out from a place on the map that has just risen a level.
/// `time` counts seconds since the mark; the wave travels at `speed` points per second
/// and settles as it goes. Its crests carry the new level's colour out across the map.
[[ stitchable ]] half4 mapRipple(float2 position, SwiftUI::Layer layer, float2 origin, float time,
                                 float amplitude, float frequency, float decay, float speed, half4 tint) {
    float distance = length(position - origin);
    float local = max(0.0, time - distance / speed);
    float wave = amplitude * sin(frequency * local) * exp(-decay * local) * step(0.0001, local);
    float2 direction = distance > 0.001 ? (position - origin) / distance : float2(0.0);
    half4 color = layer.sample(position - wave * direction);
    float crest = wave / max(amplitude, 0.001);
    color.rgb = mix(color.rgb, tint.rgb * color.a, half(max(crest, 0.0) * 0.4));
    color.rgb += half(0.08 * crest) * color.a;
    return color;
}

/// The same wave as `mapRipple` as light alone: rings of the new level's colour that carry on
/// out across the whole screen, over the panels and buttons around the map. It fades over its
/// last moments wherever the rings have reached, so it never stops short.
[[ stitchable ]] half4 screenRipple(float2 position, half4 color, float2 origin, float time,
                                    float frequency, float decay, float speed, float duration, half4 tint) {
    float distance = length(position - origin);
    float local = max(0.0, time - distance / speed);
    float wave = sin(frequency * local) * exp(-decay * local) * step(0.0001, local);
    float fade = 1.0 - smoothstep(duration * 0.65, duration, time);
    // Sharpened, so each crest reads as a ring of light rather than a broad wash.
    float crest = pow(max(wave, 0.0), 2.2) * 0.5 * fade;
    return half4(tint.rgb * half(crest), half(crest));
}
