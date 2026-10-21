#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>
using namespace metal;

// A hash of a 2D point, from 0 to 1.
static float starHash(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// Smooth value noise, from 0 to 1.
static float starNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = starHash(i);
    float b = starHash(i + float2(1, 0));
    float c = starHash(i + float2(0, 1));
    float d = starHash(i + float2(1, 1));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Layered noise for soft clouds of gas. Four layers: a fifth adds detail too fine to see in a haze
// this soft, for a fifth more work at every pixel of every frame.
static float starClouds(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int octave = 0; octave < 4; octave++) {
        value += amplitude * starNoise(p);
        p = p * 2.03 + float2(1.7, 9.2);
        amplitude *= 0.5;
    }
    return value;
}

// One sheet of stars: a star at a random spot in some cells of a grid, each twinkling at its own pace.
static float starSheet(float2 p, float time, float density) {
    float2 cell = floor(p);
    float2 local = fract(p) - 0.5;
    float pick = starHash(cell);
    if (pick > density) { return 0.0; }
    float2 spot = float2(starHash(cell + 7.1), starHash(cell + 3.7)) - 0.5;
    float distance = length(local - spot * 0.7);
    float radius = mix(0.025, 0.07, starHash(cell + 1.3));
    float twinkle = 0.65 + 0.35 * sin(time * mix(0.8, 2.6, starHash(cell + 9.2)) + pick * 40.0);
    // A bright core with a faint halo around it.
    float core = smoothstep(radius, 0.0, distance);
    float halo = smoothstep(radius * 4.0, 0.0, distance) * 0.18;
    return (core + halo) * twinkle;
}

// Deep space, flown through: sheets of stars at four depths drift out from the centre as `travel`
// grows, the nearest largest and brightest, over faint clouds of violet and blue gas. `time` sets
// the twinkle; `travel` is how far the viewer has flown, so the speed can rise and fall smoothly.
[[ stitchable ]] half4 starfield(float2 position, half4 color, float2 size, float time, float travel) {
    float shortSide = max(min(size.x, size.y), 1.0);
    float2 uv = (position - size * 0.5) / shortSide;
    float radius = length(uv);

    half3 space = mix(half3(0.024, 0.035, 0.085), half3(0.004, 0.006, 0.02), half(saturate(radius * 1.15)));
    float2 drift = float2(travel * 0.035, travel * 0.012);
    float violet = smoothstep(0.48, 0.92, starClouds(uv * 1.9 + drift));
    float blue = smoothstep(0.52, 0.98, starClouds(uv * 2.7 - drift * 1.3 + 11.0));
    space += half3(0.16, 0.06, 0.24) * half(violet) * 0.55;
    space += half3(0.03, 0.10, 0.22) * half(blue) * 0.6;

    float stars = 0.0;
    for (int depth = 0; depth < 4; depth++) {
        float z = fract(travel + float(depth) * 0.25);
        float scale = mix(22.0, 1.6, z);
        float fade = smoothstep(0.0, 0.3, z) * smoothstep(1.0, 0.82, z);
        stars += starSheet(uv * scale + float(depth) * 17.3, time, 0.42) * fade;
    }
    half3 starlight = half3(0.86, 0.92, 1.0) * half(stars);
    return half4(space + starlight, 1.0) * color.a;
}
