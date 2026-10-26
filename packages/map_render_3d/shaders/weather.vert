#version 460 core

in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec4 vertexColor;
in vec3 vertexNormal;

#include <flame_3d/skinning.glsl>

uniform Weather {
    mat4 view;
    mat4 projection;
    vec4 anchorTime;
    vec4 motion;
    vec4 particle;
    vec4 tint;
    vec4 bounds;
    vec4 volume;
} weather;

out vec2 fragUv;
out vec4 fragTint;
out float fragShape;
out float fragVariation;

void main() {
    vec3 seed = (computeSkinMatrix() * vec4(vertexPosition, 1.0)).xyz;
    fragUv = vertexTexCoord * 2.0 - 1.0;
    fragShape = weather.motion.w;
    fragVariation = vertexNormal.y;
    fragTint = vec4(0.0);
    if (seed.x >= weather.particle.x) {
        gl_Position = vec4(2.0, 2.0, 2.0, 1.0);
        return;
    }
    float time = weather.anchorTime.w;
    if (seed.x < 0.5 && weather.volume.z > 0.001) {
        vec3 right = vec3(weather.view[0][0], weather.view[1][0], weather.view[2][0]);
        vec3 up = vec3(weather.view[0][1], weather.view[1][1], weather.view[2][1]);
        vec3 back = vec3(weather.view[0][2], 0.0, weather.view[2][2]);
        back /= max(length(back), 0.001);
        float variation = fract(sin(weather.volume.w * 17.31 + 4.19) * 43758.5453);
        vec3 world = weather.anchorTime.xyz + vec3(0.0, 7.0, 0.0)
                   - back * weather.volume.x * 0.22
                   + right * (variation - 0.5) * weather.volume.x * 0.35;
        world += right * fragUv.x * 1.2 + up * fragUv.y * 4.5;
        fragShape = 6.0;
        fragVariation = variation;
        fragTint = vec4(0.72, 0.84, 1.0, weather.volume.z * weather.tint.a);
        gl_Position = weather.projection * weather.view * vec4(world, 1.0);
        return;
    }
    vec2 wind = weather.motion.xz;
    float span = weather.volume.x;
    vec2 relative = fract(vec2(seed.y, seed.z) + (time * wind - weather.anchorTime.xz) / span) - 0.5;
    vec2 center = relative * span + weather.anchorTime.xz;
    float phase = fract(vertexNormal.x + time * max(weather.motion.y, 0.05) / weather.volume.y);
    float height = weather.volume.y * (1.0 - phase);
    float shape = weather.motion.w;
    if (shape > 0.5) {
        center += vec2(sin(time * 1.3 + vertexNormal.x * 30.0),
                       cos(time * 0.8 + vertexNormal.z * 30.0)) * (shape == 1.0 ? 0.5 : 0.2);
    }
    if (shape == 2.0 && phase > 0.92) {
        height += sin((phase - 0.92) / 0.08 * 3.14159265) * 0.35;
    }
    vec3 world = vec3(center.x, weather.anchorTime.y + height, center.y);
    vec3 right = vec3(weather.view[0][0], weather.view[1][0], weather.view[2][0]);
    vec3 up = vec3(weather.view[0][1], weather.view[1][1], weather.view[2][1]);
    vec2 corner = fragUv;
    float scale = mix(0.7, 1.3, vertexNormal.z);
    if (shape < 0.5) {
        vec3 along = normalize(vec3(-wind.x, max(weather.motion.y, 0.05), -wind.y));
        world += right * corner.x * weather.particle.y * 0.5;
        world += along * corner.y * weather.particle.z * 0.5;
    } else {
        float rotation = time * (0.3 + vertexNormal.x) + vertexNormal.z * 6.2831853;
        if (shape >= 4.0) rotation += sin(time * 2.1 + vertexNormal.x * 20.0);
        if (shape >= 5.0) corner.x *= 0.45 + 0.55 * abs(cos(time * (0.7 + vertexNormal.z) + vertexNormal.x * 20.0));
        mat2 turn = mat2(cos(rotation), sin(rotation), -sin(rotation), cos(rotation));
        corner = turn * corner;
        world += (right * corner.x + up * corner.y) * weather.particle.y * scale;
    }
    float inside = step(weather.bounds.x, center.x) * step(center.x, weather.bounds.z)
                 * step(weather.bounds.y, center.y) * step(center.y, weather.bounds.w);
    float edge = smoothstep(0.0, 0.04, phase) * (1.0 - smoothstep(0.94, 1.0, phase));
    edge *= 1.0 - smoothstep(0.4, 0.5, max(abs(relative.x), abs(relative.y)));
    fragTint = vec4(weather.tint.rgb * vertexColor.rgb,
                    weather.particle.w * weather.tint.a * inside * edge);
    gl_Position = weather.projection * weather.view * vec4(world, 1.0);
}
