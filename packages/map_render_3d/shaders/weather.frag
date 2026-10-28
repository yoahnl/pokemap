#version 460 core

in vec2 fragUv;
in vec4 fragTint;
in float fragShape;
in float fragVariation;

layout(location = 0) out vec4 fragColor;
layout(location = 1) out vec4 outDepth;

vec2 momiji(vec2 point) {
    vec2 hub = point - vec2(0.0, -0.32);
    float distance = length(hub) - 0.3;
    float veins = 0.0;
    for (int index = 0; index < 7; index++) {
        float offset = float(index) - 3.0;
        float angle = 1.5707963 + offset * 0.6283185;
        vec2 direction = vec2(cos(angle), sin(angle));
        vec2 local = vec2(dot(hub, vec2(direction.y, -direction.x)), dot(hub, direction));
        float bladeLength = 1.22 - offset * offset * 0.075;
        float along = clamp(local.y / bladeLength, 0.0, 1.0);
        float width = min(along / 0.28, (1.0 - along) / 0.72) * (0.22 - abs(offset) * 0.015);
        width += sin(local.y * 78.0) * 0.009 * sin(along * 3.14159265);
        float blade = max(abs(local.x) - width, max(-local.y, local.y - bladeLength));
        distance = min(distance, blade);
        float middle = 1.0 - smoothstep(0.005, 0.017, abs(local.x));
        float branches = 1.0 - smoothstep(0.015, 0.05, abs(fract(local.y * 9.0 - abs(local.x) * 5.0) - 0.5));
        float inside = step(0.0, local.y) * step(local.y, bladeLength) * (1.0 - smoothstep(0.0, 0.015, blade));
        veins = max(veins, (middle + branches * 0.3) * inside);
    }
    float stem = max(abs(point.x + sin((point.y + 0.95) * 4.0) * 0.025) - 0.014,
                     max(-0.95 - point.y, point.y + 0.3));
    return vec2(min(distance, stem), clamp(veins, 0.0, 1.0));
}

vec3 momijiPigment(float variation) {
    if (variation < 0.28) return vec3(0.969, 0.839, 0.192);
    if (variation < 0.51) return vec3(0.969, 0.710, 0.259);
    if (variation < 0.75) return vec3(0.937, 0.482, 0.063);
    if (variation < 0.92) return vec3(0.839, 0.220, 0.086);
    return vec3(0.647, 0.388, 0.031);
}

void main() {
    vec2 uv = fragUv;
    float radius = length(uv);
    float alpha = 0.0;
    vec3 color = fragTint.rgb;
    if (fragShape < 0.5) {
        alpha = (1.0 - smoothstep(0.05, 1.0, abs(uv.x)))
              * (1.0 - smoothstep(0.35, 1.0, abs(uv.y)));
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
    } else if (fragShape < 5.5) {
        vec2 leaf = momiji(uv);
        float edge = max(0.004, fwidth(leaf.x));
        alpha = 1.0 - smoothstep(-edge, edge, leaf.x);
        vec3 pigment = momijiPigment(fragVariation);
        pigment *= 0.9 + 0.1 * fract(fragVariation * 17.13);
        color = pigment * max(fragTint.r, fragTint.g);
        color *= 0.88 + 0.12 * (uv.y * 0.5 + 0.5);
        color = mix(color, color * 0.55, leaf.y * 0.45);
    }
    alpha *= fragTint.a;
    if (alpha < 0.005) discard;
    fragColor = vec4(color * alpha, alpha);
    outDepth = vec4(0.0);
}
