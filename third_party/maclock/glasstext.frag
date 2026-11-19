#version 440

// MacSDDM — Liquid Glass Typography
// Soft refraction, frosted volume and directional specular highlights.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 itemSize;
    vec2 srcSize;
    vec2 srcOffset;
    float mode;
    float intensity;
    float refract;
    float bevel;
    vec4 tint;
    vec2 lightDir;
};

layout(binding = 1) uniform sampler2D src;
layout(binding = 2) uniform sampler2D mask;
layout(binding = 3) uniform sampler2D hmap;

float H(vec2 uv)
{
    return texture(
        hmap,
        clamp(uv, vec2(0.001), vec2(0.999))
    ).a;
}

vec3 bgAt(vec2 p, float lod)
{
    return textureLod(
        src,
        clamp(p / srcSize, vec2(0.001), vec2(0.999)),
        lod
    ).rgb;
}

void main()
{
    vec2 uv = qt_TexCoord0;

    float a = texture(mask, uv).a;

    if (a <= 0.002) {
        fragColor = vec4(0.0);
        return;
    }

    vec2 p = uv * itemSize + srcOffset;
    vec3 tintC = tint.rgb;

    // Solid / vibrancy mode.
    vec3 bgS = bgAt(p, 2.0);
    float ls = dot(bgS, vec3(0.299, 0.587, 0.114));
    bgS = mix(vec3(ls), bgS, 1.25);

    vec3 solid =
        mix(bgS, tintC, clamp(intensity, 0.0, 1.0)) + 0.035;

    // Height field: surface curvature of each glyph.
    vec2 d = vec2(2.0) / max(itemSize, vec2(1.0));

    vec2 g = vec2(
        H(uv + vec2(d.x, 0.0)) -
        H(uv - vec2(d.x, 0.0)),

        H(uv + vec2(0.0, d.y)) -
        H(uv - vec2(0.0, d.y))
    ) * 0.5;

    float slope = length(g) * bevel;
    float s = clamp(slope, 0.0, 1.0);

    vec2 normal2 =
        slope > 1e-6
        ? -g / max(length(g), 1e-6)
        : vec2(0.0);

    // Directional light.
    vec2 L = normalize(lightDir);
    float facing = dot(normal2, L);

    float lit = max(facing, 0.0);
    float shade = max(-facing, 0.0);

    // Convex glass refraction.
    float bend = s * s * (3.0 - 2.0 * s);

    vec2 shift = normal2 * refract * (
        0.30 * s + 0.70 * bend
    );

    float lod = 0.25 + 1.6 * clamp(intensity, 0.0, 1.0);

    // Very subtle chromatic dispersion.
    vec3 bg;

    bg.r = bgAt(p - shift * 0.96, lod).r;
    bg.g = bgAt(p - shift,        lod).g;
    bg.b = bgAt(p - shift * 1.04, lod).b;

    float lum = dot(bg, vec3(0.299, 0.587, 0.114));
    bg = mix(vec3(lum), bg, 1.18);

    // Main glass body.
    vec3 glass = bg * 1.035 + vec3(0.025);

    // Controlled frost: visible but not opaque.
    float frost = clamp(intensity, 0.0, 1.0);

    vec3 milk = mix(
        vec3(0.82, 0.86, 0.91),
        tintC,
        0.84
    );

    glass = mix(glass, milk, 0.08 + 0.28 * frost);

    // Soft inner shading.
    float edge = smoothstep(0.025, 0.58, s);

    glass *=
        1.0 - 0.11 * pow(shade, 1.7) * edge;

    // Broad reflected light.
    float broad = pow(lit, 1.65) * edge;

    glass +=
        vec3(0.055, 0.062, 0.070) * broad;

    // Fine specular highlight.
    float specular = pow(lit, 9.0) * edge;

    glass +=
        vec3(0.20, 0.22, 0.25) * specular;

    // Secondary soft reflection along the curved edge.
    float band = exp(
        -pow((s - 0.46) / 0.22, 2.0)
    ) * pow(lit, 1.35) * edge;

    glass +=
        vec3(0.045, 0.052, 0.062) * band;

    // Very subtle cool-white glass contour.
    float fresnel = pow(edge, 1.6);

    glass = mix(
        glass,
        vec3(0.92, 0.95, 1.0),
        fresnel * 0.060
    );

    vec3 col = mix(
        solid,
        glass,
        clamp(mode, 0.0, 1.0)
    );

    fragColor =
        vec4(clamp(col, 0.0, 1.0) * a, a)
        * qt_Opacity;
}
