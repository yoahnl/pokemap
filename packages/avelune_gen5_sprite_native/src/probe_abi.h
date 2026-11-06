#ifndef AV_PROBE_ABI_H
#define AV_PROBE_ABI_H

#include <stddef.h>
#include <stdint.h>

#if defined(_WIN32)
#define AV_PUBLIC __declspec(dllexport)
#elif defined(__GNUC__)
#define AV_PUBLIC __attribute__((visibility("default")))
#else
#define AV_PUBLIC
#endif

typedef struct AvProbeRequest {
    const uint8_t *tiles;
    size_t tile_size;
    const uint8_t *ncer;
    size_t ncer_size;
    const uint8_t *nanr;
    size_t nanr_size;
    const uint8_t *nmcr;
    size_t nmcr_size;
    const uint8_t *nmar;
    size_t nmar_size;
    int32_t timeline;
    int32_t tick;
    int32_t min_x;
    int32_t min_y;
    int32_t width;
    int32_t height;
    int32_t child_mode;
    int32_t parent_completed;
} AvProbeRequest;

AV_PUBLIC void *av_probe_alloc(size_t size);
AV_PUBLIC void av_probe_free(void *pointer);
int av_probe_render_synthetic(const uint8_t *tiles, size_t tile_size,
                              uint8_t *output, size_t output_size, int flip_h);
AV_PUBLIC int av_probe_render_sample(const AvProbeRequest *request, uint8_t *output,
                                    size_t output_size, int32_t *details, size_t details_count);

#endif
