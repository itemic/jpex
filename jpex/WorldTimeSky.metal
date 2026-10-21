#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// A hash of a 2D point, from 0 to 1.
static float skyHash(float2 p) {
    p = fract(p * float2(233.34, 851.73));
    p += dot(p, p + 23.45);
    return fract(p.x * p.y);
}

// One sheet of stars: some cells of a grid hold a star at a random spot, each twinkling at its own pace.
static float skySheet(float2 p, float time, float density) {
    float2 cell = floor(p);
    float pick = skyHash(cell);
    if (pick > density) { return 0.0; }
    float2 spot = float2(skyHash(cell + 4.7), skyHash(cell + 9.1)) * 0.8 + 0.1;
    float distance = length(fract(p) - spot);
    float radius = mix(0.03, 0.08, skyHash(cell + 2.3));
    float twinkle = 0.6 + 0.4 * sin(time * mix(0.7, 2.3, skyHash(cell + 5.5)) + pick * 50.0);
    // A bright core with a faint halo around it.
    float core = smoothstep(radius, 0.0, distance);
    float halo = smoothstep(radius * 3.5, 0.0, distance) * 0.2;
    return (core + halo) * twinkle;
}

// The night sky's stars behind World Time: three sheets of them, the nearest fewest and brightest,
// thinning towards the horizon at the foot of the screen. `amount` runs from 0 by day to 1 once
// it's properly dark; `time` sets the twinkle.
[[ stitchable ]] half4 skyStars(float2 position, half4 color, float2 size, float time, float amount) {
    float shortSide = max(min(size.x, size.y), 1.0);
    float2 uv = position / shortSide;
    float stars = skySheet(uv * 38.0, time, 0.18) * 0.7
        + skySheet(uv * 21.0 + 13.7, time, 0.2) * 0.95
        + skySheet(uv * 11.0 + 41.3, time, 0.1) * 1.1;
    float overhead = 1.0 - smoothstep(0.45, 1.0, position.y / max(size.y, 1.0));
    float alpha = saturate(stars) * amount * mix(0.3, 1.0, overhead);
    return half4(half3(0.86, 0.91, 1.0) * half(alpha), half(alpha)) * color.a;
}
