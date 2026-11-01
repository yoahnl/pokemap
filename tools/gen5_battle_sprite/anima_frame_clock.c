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
        if (duration <= 0 || duration > 65535 || total > 1000000 - duration)
            return AV_ANIMA_CLOCK_INVALID;
        total += duration;
    }

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
