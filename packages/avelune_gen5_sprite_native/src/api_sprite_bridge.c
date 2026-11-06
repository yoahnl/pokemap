#include "sprite_composer.h"
#include "lz.h"
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#if defined(_WIN32)
#define AV_PUBLIC __declspec(dllexport)
#elif defined(__GNUC__)
#define AV_PUBLIC __attribute__((visibility("default")))
#else
#define AV_PUBLIC
#endif

typedef struct ApiSpriteInput {
    const uint8_t *indices;
    size_t indices_size;
    const uint8_t *palette;
    size_t palette_size;
    const uint8_t *cells;
    size_t cells_size;
    const uint8_t *animations;
    size_t animations_size;
    const uint8_t *multi_cells;
    size_t multi_cells_size;
    const uint8_t *multi_animations;
    size_t multi_animations_size;
} ApiSpriteInput;

AV_PUBLIC void *av_api_allocate(size_t size) {
    return size > 0 && size <= 1048576 ? calloc(1, size) : NULL;
}

AV_PUBLIC void av_api_free(void *pointer) {
    free(pointer);
}

AV_PUBLIC int av_api_decompress(const uint8_t *input, size_t input_size,
                                uint8_t *output, size_t output_size, size_t *written) {
    if (input == NULL || input_size < 4 || input[0] != 0x11 || output == NULL || written == NULL) return -2;
    uint32_t size = (uint32_t)input[1] | ((uint32_t)input[2] << 8) | ((uint32_t)input[3] << 16);
    if (size == 0 || size > output_size || size > 1048576) return -2;
    uint8_t *decoded = NULL;
    size_t length = 0;
    CompressionType compression = COMPRESSION_NONE;
    int result = Lz_Decompress(input, input_size, &decoded, &length, &compression);
    if (result != 0 || length != size || compression != COMPRESSION_LZ11) {
        free(decoded);
        return -3;
    }
    memcpy(output, decoded, length);
    *written = length;
    free(decoded);
    return 0;
}

AV_PUBLIC int av_api_render(const ApiSpriteInput *input, int tick,
                            uint8_t *output, size_t output_size, int *out_map) {
    if (input == NULL || input->indices == NULL || input->indices_size != 256 * 128 ||
        input->palette == NULL || input->palette_size != 48 || input->cells == NULL ||
        input->animations == NULL || input->multi_cells == NULL || input->multi_animations == NULL ||
        input->cells_size == 0 || input->animations_size < 4 || input->multi_cells_size == 0 ||
        input->multi_animations_size == 0 || output == NULL || output_size != 128 * 128 ||
        out_map == NULL || tick < 0 || tick > 10000) return -2;

    uint32_t decoded_size = (uint32_t)input->animations[1] |
                            ((uint32_t)input->animations[2] << 8) |
                            ((uint32_t)input->animations[3] << 16);
    if (input->animations[0] != 0x11 || decoded_size == 0 || decoded_size > 1048576) return -2;

    uint8_t tiles[256 * 128 / 2];
    for (int tile_y = 0; tile_y < 16; tile_y++) {
        for (int tile_x = 0; tile_x < 32; tile_x++) {
            for (int y = 0; y < 8; y++) {
                for (int x = 0; x < 8; x += 2) {
                    int source = (tile_y * 8 + y) * 256 + tile_x * 8 + x;
                    uint8_t left = input->indices[source];
                    uint8_t right = input->indices[source + 1];
                    if (left > 15 || right > 15) return -2;
                    tiles[(tile_y * 32 + tile_x) * 32 + y * 4 + x / 2] = left | (right << 4);
                }
            }
        }
    }

    NcgrImage image = {.tile_data = tiles, .tile_data_size = sizeof(tiles), .bpp = 4,
                       .tile_count = 512, .width_tiles = 32, .height_tiles = 16};
    NclrPalette palette = {.color_count = 16};
    for (int i = 0; i < 16; i++) {
        palette.colors[i] = (RgbaColor){input->palette[3 * i], input->palette[3 * i + 1],
                                        input->palette[3 * i + 2], i == 0 ? 0 : 255};
    }
    NcerFile cells = {0};
    NanrFile animations = {0};
    NmcrFile maps = {0};
    NmarFile timeline = {0};
    uint8_t *decoded = NULL;
    size_t length = 0;
    CompressionType compression = COMPRESSION_NONE;
    int result = -3;
    result = -31;
    if (Lz_Decompress(input->animations, input->animations_size, &decoded, &length, &compression) != 0 ||
        length != decoded_size || compression != COMPRESSION_LZ11) goto cleanup;
    result = -32;
    if (Ncer_Parse(input->cells, input->cells_size, &cells) != 0) goto cleanup;
    result = -33;
    if (Nanr_Parse(decoded, length, &animations) != 0) goto cleanup;
    result = -34;
    if (Nmcr_Parse(input->multi_cells, input->multi_cells_size, &maps) != 0) goto cleanup;
    result = -35;
    if (Nmar_Parse(input->multi_animations, input->multi_animations_size, &timeline) != 0) goto cleanup;

    NmarFrame frame = {0};
    int map_index = Nmar_GetFrameAtTick(&timeline, 0, tick, &frame);
    result = -36;
    if (map_index < 0 || map_index >= maps.map_count) goto cleanup;
    ComposerTransform transform = {frame.rotation, frame.scale_x, frame.scale_y,
                                   frame.translate_x, frame.translate_y};
    memset(output, 0, output_size);
    result = Composer_RenderFrameIndexedWithTransform(&cells, &animations, &maps.maps[map_index],
              &image, &palette, tick, 32, -64, -64, 128, 128, 0, output, NULL, &transform);
    if (result == 0) *out_map = map_index;

cleanup:
    Nmar_Free(&timeline);
    Nmcr_Free(&maps);
    Nanr_Free(&animations);
    Ncer_Free(&cells);
    free(decoded);
    return result;
}
