float boundedGroundDepth(float depth, float target) {
    float delta = target - depth;
    float room = delta < 0.0 ? depth : 1.0 - depth;
    return room > 0.0 && delta != 0.0
        ? clamp(depth + delta * room / (room + abs(delta)), 0.0, 1.0)
        : depth;
}
