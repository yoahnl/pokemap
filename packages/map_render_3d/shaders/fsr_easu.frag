#version 460 core

in vec2 textureCoordinate;
out vec4 outColor;
uniform sampler2D inputTexture;
uniform Easu {
    vec4 sizes;
} easu;

vec4 easuTap(vec2 texel) {
    vec2 inputSize = easu.sizes.xy;
    return texture(inputTexture, (clamp(texel, vec2(0.0), inputSize - 1.0) + 0.5) / inputSize);
}

float easuLuma(vec3 color) {
    return color.b * 0.5 + (color.r * 0.5 + color.g);
}

float easuRcp(float value) {
    return 1.0 / max(value, 1.0e-20);
}

void easuSet(inout vec2 dir, inout float len, float w, float lA, float lB, float lC, float lD, float lE) {
    float lenX = easuRcp(max(abs(lD - lC), abs(lC - lB)));
    float dirX = lD - lB;
    dir.x += dirX * w;
    lenX = clamp(abs(dirX) * lenX, 0.0, 1.0);
    len += lenX * lenX * w;
    float lenY = easuRcp(max(abs(lE - lC), abs(lC - lA)));
    float dirY = lE - lA;
    dir.y += dirY * w;
    lenY = clamp(abs(dirY) * lenY, 0.0, 1.0);
    len += lenY * lenY * w;
}

void easuAccumulate(inout vec3 aC, inout float aW, vec2 off, vec2 dir, vec2 len, float lob, float clp, vec3 color) {
    vec2 v = vec2(off.x * dir.x + off.y * dir.y, off.x * -dir.y + off.y * dir.x) * len;
    float d2 = min(v.x * v.x + v.y * v.y, clp);
    float wB = 2.0 / 5.0 * d2 - 1.0;
    float wA = lob * d2 - 1.0;
    wB *= wB;
    wA *= wA;
    wB = 25.0 / 16.0 * wB - (25.0 / 16.0 - 1.0);
    float w = wB * wA;
    aC += color * w;
    aW += w;
}

void main() {
    vec2 pp = textureCoordinate * easu.sizes.xy - 0.5;
    vec2 fp = floor(pp);
    pp -= fp;
    vec4 b = easuTap(fp + vec2(0.0, -1.0));
    vec4 c = easuTap(fp + vec2(1.0, -1.0));
    vec4 e = easuTap(fp + vec2(-1.0, 0.0));
    vec4 f = easuTap(fp);
    vec4 g = easuTap(fp + vec2(1.0, 0.0));
    vec4 h = easuTap(fp + vec2(2.0, 0.0));
    vec4 i = easuTap(fp + vec2(-1.0, 1.0));
    vec4 j = easuTap(fp + vec2(0.0, 1.0));
    vec4 k = easuTap(fp + vec2(1.0, 1.0));
    vec4 l = easuTap(fp + vec2(2.0, 1.0));
    vec4 n = easuTap(fp + vec2(0.0, 2.0));
    vec4 o = easuTap(fp + vec2(1.0, 2.0));
    float bL = easuLuma(b.rgb);
    float cL = easuLuma(c.rgb);
    float eL = easuLuma(e.rgb);
    float fL = easuLuma(f.rgb);
    float gL = easuLuma(g.rgb);
    float hL = easuLuma(h.rgb);
    float iL = easuLuma(i.rgb);
    float jL = easuLuma(j.rgb);
    float kL = easuLuma(k.rgb);
    float lL = easuLuma(l.rgb);
    float nL = easuLuma(n.rgb);
    float oL = easuLuma(o.rgb);
    vec2 dir = vec2(0.0);
    float len = 0.0;
    easuSet(dir, len, (1.0 - pp.x) * (1.0 - pp.y), bL, eL, fL, gL, jL);
    easuSet(dir, len, pp.x * (1.0 - pp.y), cL, fL, gL, hL, kL);
    easuSet(dir, len, (1.0 - pp.x) * pp.y, fL, iL, jL, kL, nL);
    easuSet(dir, len, pp.x * pp.y, gL, jL, kL, lL, oL);
    vec2 dir2 = dir * dir;
    float dirR = dir2.x + dir2.y;
    bool zero = dirR < 1.0 / 32768.0;
    dirR = zero ? 1.0 : inversesqrt(dirR);
    dir.x = zero ? 1.0 : dir.x;
    dir *= dirR;
    len = len * 0.5;
    len *= len;
    float stretch = (dir.x * dir.x + dir.y * dir.y) * easuRcp(max(abs(dir.x), abs(dir.y)));
    vec2 len2 = vec2(1.0 + (stretch - 1.0) * len, 1.0 - 0.5 * len);
    float lob = 0.5 + ((1.0 / 4.0 - 0.04) - 0.5) * len;
    float clp = easuRcp(lob);
    vec3 min4 = min(min(f.rgb, g.rgb), min(j.rgb, k.rgb));
    vec3 max4 = max(max(f.rgb, g.rgb), max(j.rgb, k.rgb));
    vec3 aC = vec3(0.0);
    float aW = 0.0;
    easuAccumulate(aC, aW, vec2(0.0, -1.0) - pp, dir, len2, lob, clp, b.rgb);
    easuAccumulate(aC, aW, vec2(1.0, -1.0) - pp, dir, len2, lob, clp, c.rgb);
    easuAccumulate(aC, aW, vec2(-1.0, 1.0) - pp, dir, len2, lob, clp, i.rgb);
    easuAccumulate(aC, aW, vec2(0.0, 1.0) - pp, dir, len2, lob, clp, j.rgb);
    easuAccumulate(aC, aW, vec2(0.0, 0.0) - pp, dir, len2, lob, clp, f.rgb);
    easuAccumulate(aC, aW, vec2(-1.0, 0.0) - pp, dir, len2, lob, clp, e.rgb);
    easuAccumulate(aC, aW, vec2(1.0, 1.0) - pp, dir, len2, lob, clp, k.rgb);
    easuAccumulate(aC, aW, vec2(2.0, 1.0) - pp, dir, len2, lob, clp, l.rgb);
    easuAccumulate(aC, aW, vec2(2.0, 0.0) - pp, dir, len2, lob, clp, h.rgb);
    easuAccumulate(aC, aW, vec2(1.0, 0.0) - pp, dir, len2, lob, clp, g.rgb);
    easuAccumulate(aC, aW, vec2(1.0, 2.0) - pp, dir, len2, lob, clp, o.rgb);
    easuAccumulate(aC, aW, vec2(0.0, 2.0) - pp, dir, len2, lob, clp, n.rgb);
    float alpha = mix(mix(f.a, g.a, pp.x), mix(j.a, k.a, pp.x), pp.y);
    vec3 color = min(max4, max(min4, aC / aW));
    outColor = vec4(min(color, vec3(alpha)), alpha);
}
