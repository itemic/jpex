#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

/// Ripples a flag that hangs from a pole along its leading edge.
/// `strength` runs from 0, hanging still, to 1, a steady wave.
[[ stitchable ]] half4 flagWave(float2 position, SwiftUI::Layer layer, float4 bounds, float time, float strength) {
    float progress = clamp((position.x - bounds.x) / max(bounds.z, 1.0), 0.0, 1.0);
    // The pole holds the hoist still; the fly end moves the most.
    float reach = 7.0 * strength * smoothstep(0.0, 0.4, progress) * (0.55 + 0.45 * progress);
    float phase = progress * 9.0 - time * 3.0;
    float ripple = phase * 1.7 + 1.3;
    float lift = (sin(phase) + 0.35 * sin(ripple)) / 1.35 * reach;
    half4 color = layer.sample(float2(position.x, position.y - lift));
    // Each fold catches the light on one side and falls into shadow on the other.
    float slope = (cos(phase) + 0.6 * cos(ripple)) / 1.6;
    half light = half(1.0 + slope * 0.1 * (reach / 7.0));
    return half4(min(color.rgb * light, half3(color.a)), color.a);
}
