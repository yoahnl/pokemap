#ifndef AVELUNE_ANIMA_FRAME_CLOCK_H
#define AVELUNE_ANIMA_FRAME_CLOCK_H

#include <stddef.h>

enum {
    AV_ANIMA_CLOCK_OK = 0,
    AV_ANIMA_CLOCK_INVALID = -1,
    AV_ANIMA_CLOCK_UNSUPPORTED = -2
};

int av_anima_frame_clock(const int *durations, size_t count, int playback,
                         int loop_start, int tick, size_t *frame_index,
                         int *frame_elapsed);

int av_anima_child_clock(int mode, int parent_completed, int parent_elapsed,
                         int *child_tick);

#endif
