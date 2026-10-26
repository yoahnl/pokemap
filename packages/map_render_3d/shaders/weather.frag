#version 460 core

in vec2 fragUv;
in vec4 fragTint;
in float fragShape;
in float fragVariation;

out vec4 fragColor;

void main() {
    vec2 uv = fragUv;
    float radius = length(uv);
    float alpha = 0.0;
    vec3 color = fragTint.rgb;
    if (fragShape < 0.5) {
        alpha = (1.0 - smoothstep(0.15, 1.0, abs(uv.x)))
              * (1.0 - smoothstep(0.45, 1.0, abs(uv.y)));
    } else if (fragShape < 1.5) {
        float arms = 0.84 + 0.16 * cos(atan(uv.y, uv.x) * 6.0);
        alpha = 1.0 - smoothstep(0.38, arms, radius);
        color *= 0.88 + 0.12 * (1.0 - min(radius, 1.0));
    } else if (fragShape < 2.5) {
        alpha = 1.0 - smoothstep(0.55, 0.9, abs(uv.x) + abs(uv.y));
        color *= 0.72 + 0.28 * clamp(0.5 - uv.x * 0.3 + uv.y * 0.4, 0.0, 1.0);
    } else if (fragShape < 3.5) {
        alpha = exp(-dot(uv, uv) * 3.2) * (1.0 - smoothstep(0.75, 1.0, radius));
    } else if (fragShape < 4.5) {
        vec2 petal = vec2(uv.x * (0.8 + uv.y * 0.16), uv.y * 1.15);
        alpha = 1.0 - smoothstep(0.58, 0.92, length(petal));
        color = mix(color, vec3(1.0, 0.9, 0.94), fragVariation * 0.4);
    } else {
        alpha = 1.0 - smoothstep(0.76, 1.0, abs(uv.x) * 1.25 + abs(uv.y) * 0.65);
        color *= mix(vec3(0.76, 0.92, 0.56), vec3(1.0, 0.72, 0.42), fragVariation);
        color *= 0.85 + 0.15 * smoothstep(0.01, 0.07, abs(uv.x));
    }
    alpha *= fragTint.a;
    if (alpha < 0.005) discard;
    fragColor = vec4(color * alpha, alpha);
}
