#include "anima_frame_clock.h"

#include <limits.h>
#include <stdio.h>

static int check(int condition, const char *message) {
    if (!condition) fprintf(stderr, "FAIL: %s\n", message);
    return condition;
}

int main(void) {
    const int durations[] = {3, 5, 2};
    const struct {
        int tick;
        size_t frame;
        int elapsed;
    } cases[] = {
        {0, 0, 0}, {2, 0, 2}, {3, 1, 0}, {7, 1, 4},
        {8, 2, 0}, {9, 2, 1}, {10, 0, 0}, {13, 1, 0},
        {1000003, 1, 0}, {INT_MAX, 1, 4},
    };
    int failures = 0;
    for (size_t i = 0; i < sizeof(cases) / sizeof(cases[0]); i++) {
        size_t index = 999;
        int elapsed = 999;
        int result = av_anima_frame_clock(durations, 3, 2, 0, cases[i].tick,
                                          &index, &elapsed);
        failures += !check(result == AV_ANIMA_CLOCK_OK, "valid timeline rejected");
        failures += !check(index == cases[i].frame, "wrong parent frame");
        failures += !check(elapsed == cases[i].elapsed, "wrong elapsed tick");
    }

    size_t index = 999;
    int elapsed = 999;
    const int zero_duration[] = {2, 0};
    const int long_duration[] = {65536};
    const int excessive_total[] = {
        65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535,
        65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535,
    };
    failures += !check(av_anima_frame_clock(durations, 3, 1, 0, 0, &index, &elapsed)
                       == AV_ANIMA_CLOCK_UNSUPPORTED, "unsupported playback accepted");
    failures += !check(av_anima_frame_clock(durations, 3, 2, 1, 0, &index, &elapsed)
                       == AV_ANIMA_CLOCK_UNSUPPORTED, "nonzero loop start accepted");
    failures += !check(av_anima_frame_clock(zero_duration, 2, 2, 0, 0, &index, &elapsed)
                       == AV_ANIMA_CLOCK_INVALID, "zero duration accepted");
    failures += !check(av_anima_frame_clock(long_duration, 1, 2, 0, 0, &index, &elapsed)
                       == AV_ANIMA_CLOCK_INVALID, "oversized duration accepted");
    failures += !check(av_anima_frame_clock(excessive_total, 16, 2, 0, 0, &index, &elapsed)
                       == AV_ANIMA_CLOCK_INVALID, "oversized duration sum accepted");
    failures += !check(av_anima_frame_clock(durations, 0, 2, 0, 0, &index, &elapsed)
                       == AV_ANIMA_CLOCK_INVALID, "empty timeline accepted");
    failures += !check(av_anima_frame_clock(durations, 4097, 2, 0, 0, &index, &elapsed)
                       == AV_ANIMA_CLOCK_INVALID, "oversized timeline accepted");
    failures += !check(av_anima_frame_clock(durations, 3, 2, 0, -1, &index, &elapsed)
                       == AV_ANIMA_CLOCK_INVALID, "negative tick accepted");
    failures += !check(av_anima_frame_clock(NULL, 3, 2, 0, 0, &index, &elapsed)
                       == AV_ANIMA_CLOCK_INVALID, "null durations accepted");
    failures += !check(av_anima_frame_clock(durations, 3, 2, 0, 0, NULL, &elapsed)
                       == AV_ANIMA_CLOCK_INVALID, "null index accepted");
    failures += !check(av_anima_frame_clock(durations, 3, 2, 0, 0, &index, NULL)
                       == AV_ANIMA_CLOCK_INVALID, "null elapsed accepted");
    failures += !check(index == 999 && elapsed == 999, "failure modified output");

    int bounded_total[16];
    for (size_t i = 0; i < 16; i++) bounded_total[i] = 62500;
    index = 999;
    elapsed = 999;
    failures += !check(av_anima_frame_clock(bounded_total, 16, 2, 0, 999999,
                                           &index, &elapsed) == AV_ANIMA_CLOCK_OK,
                       "maximum duration sum rejected");
    failures += !check(index == 15 && elapsed == 62499, "maximum duration sum resolved incorrectly");

    int checked = 0;
    for (size_t count = 1; count <= 4; count++) {
        int combinations = 1;
        for (size_t i = 0; i < count; i++) combinations *= 4;
        for (int variant = 0; variant < combinations; variant++) {
            int generated[4];
            int remaining = variant;
            for (size_t i = 0; i < count; i++) {
                generated[i] = remaining % 4 + 1;
                remaining /= 4;
            }
            size_t expected_index = 0;
            int expected_elapsed = 0;
            for (int tick = 0; tick <= 128; tick++) {
                size_t actual_index = 999;
                int actual_elapsed = 999;
                if (av_anima_frame_clock(generated, count, 2, 0, tick,
                                         &actual_index, &actual_elapsed) != AV_ANIMA_CLOCK_OK ||
                    actual_index != expected_index || actual_elapsed != expected_elapsed) {
                    fprintf(stderr, "FAIL: generated timeline %zu/%d tick %d\n", count, variant, tick);
                    return 1;
                }
                checked++;
                expected_elapsed++;
                if (expected_elapsed == generated[expected_index]) {
                    expected_elapsed = 0;
                    expected_index = (expected_index + 1) % count;
                }
            }
        }
    }
    if (failures != 0) return 1;
    printf("anima frame clock: boundary, looping, rejection and %d generated cases passed\n", checked);
    return 0;
}
