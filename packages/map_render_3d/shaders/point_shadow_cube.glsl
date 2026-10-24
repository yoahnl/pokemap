int pointShadowFace(vec3 delta) {
    vec3 magnitude = abs(delta);
    if (magnitude.x >= magnitude.y && magnitude.x >= magnitude.z) return delta.x >= 0.0 ? 0 : 1;
    if (magnitude.y >= magnitude.z) return delta.y >= 0.0 ? 2 : 3;
    return delta.z >= 0.0 ? 4 : 5;
}

vec2 pointShadowFaceUv(vec3 delta, int face) {
    vec2 projected;
    float distance;
    if (face == 0) { projected = vec2(-delta.z, -delta.y); distance = abs(delta.x); }
    else if (face == 1) { projected = vec2(delta.z, -delta.y); distance = abs(delta.x); }
    else if (face == 2) { projected = vec2(delta.x, delta.z); distance = abs(delta.y); }
    else if (face == 3) { projected = vec2(delta.x, -delta.z); distance = abs(delta.y); }
    else if (face == 4) { projected = vec2(delta.x, -delta.y); distance = abs(delta.z); }
    else { projected = vec2(-delta.x, -delta.y); distance = abs(delta.z); }
    vec2 ndc = projected / max(distance, 0.000001);
    return vec2(ndc.x * 0.5 + 0.5, 0.5 - ndc.y * 0.5);
}

vec3 pointShadowRay(vec2 uv, int face) {
    vec2 ndc = vec2(uv.x * 2.0 - 1.0, 1.0 - uv.y * 2.0);
    if (face == 0) return normalize(vec3(1.0, -ndc.y, -ndc.x));
    if (face == 1) return normalize(vec3(-1.0, -ndc.y, ndc.x));
    if (face == 2) return normalize(vec3(ndc.x, 1.0, ndc.y));
    if (face == 3) return normalize(vec3(ndc.x, -1.0, -ndc.y));
    if (face == 4) return normalize(vec3(ndc.x, -ndc.y, 1.0));
    return normalize(vec3(-ndc.x, -ndc.y, -1.0));
}
