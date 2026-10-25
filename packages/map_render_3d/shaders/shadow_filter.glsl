float shadowTentIntegral(float position, float radius) {
    float value = clamp(position / radius, -1.0, 1.0);
    return value <= 0.0 ? 0.5 * (value + 1.0) * (value + 1.0) : 1.0 - 0.5 * (1.0 - value) * (1.0 - value);
}

float shadowTexelWeight(float offset, float radius) {
    return shadowTentIntegral(offset + 0.5, radius) - shadowTentIntegral(offset - 0.5, radius);
}

float shadowPairWeight(float offset, float radius) {
    return shadowTexelWeight(offset, radius) + shadowTexelWeight(offset + 1.0, radius);
}

float shadowPairOffset(float offset, float radius) {
    float weight = shadowPairWeight(offset, radius);
    return weight > 0.0 ? shadowTexelWeight(offset + 1.0, radius) / weight : 0.0;
}
