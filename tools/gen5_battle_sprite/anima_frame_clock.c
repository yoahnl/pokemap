#include "anima_frame_clock.h"

int av_anima_frame_clock(const int *durations, size_t count, int playback,
                         int loop_start, int tick, size_t *frame_index,
                         int *frame_elapsed) {
    if (durations == NULL || frame_index == NULL || frame_elapsed == NULL ||
        count == 0 || count > 4096 || tick < 0) return AV_ANIMA_CLOCK_INVALID;
    if (playback != 2 || loop_start != 0) return AV_ANIMA_CLOCK_UNSUPPORTED;

    int total = 0;
    for (size_t i = 0; i < count; i++) {
        int duration = durations[i];
        if (duration < 0 || duration > 65535 || total > 1000000 - duration)
            return AV_ANIMA_CLOCK_INVALID;
        total += duration;
    }
    if (total == 0) return AV_ANIMA_CLOCK_INVALID;

    int position = tick % total;
    for (size_t i = 0; i < count; i++) {
        if (position < durations[i]) {
            *frame_index = i;
            *frame_elapsed = position;
            return AV_ANIMA_CLOCK_OK;
        }
        position -= durations[i];
    }
    return AV_ANIMA_CLOCK_INVALID;
}

int av_anima_child_clock(int mode, int parent_completed, int parent_elapsed,
                         int *child_tick) {
    if (child_tick == NULL || parent_completed < 0 || parent_elapsed < 0)
        return AV_ANIMA_CLOCK_INVALID;
    if (mode != 0 && mode != 1) return AV_ANIMA_CLOCK_UNSUPPORTED;
    if (parent_elapsed > 65535) return AV_ANIMA_CLOCK_UNSUPPORTED;
    if (mode == 0) {
        *child_tick = parent_elapsed;
        return AV_ANIMA_CLOCK_OK;
    }
    if (parent_completed > 65535)
        return AV_ANIMA_CLOCK_UNSUPPORTED;
    *child_tick = parent_completed + parent_elapsed;
    return AV_ANIMA_CLOCK_OK;
}
