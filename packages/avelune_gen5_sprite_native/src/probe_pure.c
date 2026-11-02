#include "sprite_composer.h"
#include "probe_abi.h"
#include "lz.h"
#include "file_util.h"
#include "nitro_util.h"
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#if defined(__GNUC__)
#define AV_PUBLIC __attribute__((visibility("default")))
#else
#define AV_PUBLIC
#endif

AV_PUBLIC void *av_probe_alloc(size_t size) {
    return size > 0 && size <= 1048576 ? malloc(size) : NULL;
}

AV_PUBLIC void av_probe_free(void *pointer) {
    free(pointer);
}

static int valid_input(const uint8_t *data, size_t size, const char *magic) {
    return data != NULL && size >= 16 && size <= 1048576 && memcmp(data, magic, 4) == 0;
}

static int valid_sections(const uint8_t *data, size_t size) {
    size_t position = 16;
    while (size - position >= 8) {
        size_t section_size = ReadU32LE(data + position + 4);
        if (section_size < 8 || section_size > size - position) return 0;
        position += section_size;
    }
    return 1;
}

static int valid_index_budget(const uint8_t *data, size_t size,
                              const char *magic, size_t minimum_size,
                              size_t record_size) {
    size_t section;
    u32 length;
    if (!valid_sections(data, size) ||
        Nitro_FindSection(data, size, magic, &section, &length) != 0 ||
        length < minimum_size) return 0;
    size_t count = ReadU16LE(data + section + 8);
    size_t offset = ReadU32LE(data + section + 12);
    if (offset > length - 8) return 0;
    size_t table = 8 + offset;
    if (count == 0 || count > (length - table) / 8) return 0;
    size_t base = table + count * 8;
    size_t total = 0;
    for (size_t i = 0; i < count; i++) {
        const uint8_t *entry = data + section + table + i * 8;
        size_t records = ReadU16LE(entry);
        size_t record_offset = ReadU32LE(entry + 4);
        if (records > 8192 - total || record_offset > length - base ||
            records > (length - base - record_offset) / record_size) return 0;
        total += records;
    }
    return 1;
}

static int valid_animation_budget(const uint8_t *data, size_t size, int parent) {
    size_t section;
    u32 length;
    if (!valid_sections(data, size)) return 0;
    if (parent) {
        size_t ignored_offset;
        u32 ignored_length;
        if (Nitro_FindSection(data, size, "KNMA", &ignored_offset, &ignored_length) == 0 ||
            Nitro_FindSection(data, size, "KNAM", &ignored_offset, &ignored_length) == 0) return 0;
    }
    if (Nitro_FindSection(data, size, "KNBA", &section, &length) != 0 || length < 24) return 0;
    size_t count = ReadU16LE(data + section + 8);
    size_t table_offset = ReadU32LE(data + section + 12);
    size_t frame_offset = ReadU32LE(data + section + 16);
    size_t element_offset = ReadU32LE(data + section + 20);
    if (table_offset > length - 8 || frame_offset > length - 8 ||
        element_offset > length - 8) return 0;
    size_t table = 8 + table_offset;
    size_t frames = 8 + frame_offset;
    size_t elements = 8 + element_offset;
    if (count == 0 || count > (length - table) / 16) return 0;
    size_t total = 0;
    for (size_t i = 0; i < count; i++) {
        const uint8_t *entry = data + section + table + i * 16;
        size_t frame_count = ReadU16LE(entry);
        size_t offset = ReadU32LE(entry + 12);
        if (frame_count > 8192 - total || offset > length - frames ||
            frame_count > (length - frames - offset) / 8) return 0;
        total += frame_count;
        int format = ReadU16LE(entry + 4);
        size_t required = !parent || format == 0 ? 2 :
            format == 1 ? 16 : format == 2 ? 8 : format == 3 ? 4 : 2;
        for (size_t j = 0; j < frame_count; j++) {
            size_t element = ReadU32LE(data + section + frames + offset + j * 8);
            if (element > length - elements ||
                required > length - elements - element) return 0;
        }
    }
    return 1;
}

static int valid_lz11(const uint8_t *data, size_t size, size_t *decoded_size) {
    if (data == NULL || size < 4 || size > 1048576 || data[0] != 0x11) return 0;
    size_t length = (size_t)data[1] | ((size_t)data[2] << 8) | ((size_t)data[3] << 16);
    if (length == 0 || length > 1048576) return 0;
    *decoded_size = length;
    return 1;
}

AV_PUBLIC int av_pure_decode(const uint8_t *ncgr_data, size_t ncgr_size,
                             const uint8_t *nanr_data, size_t nanr_size,
                             uint8_t *tiles, size_t tiles_capacity,
                             uint8_t *nanr_output, size_t nanr_capacity,
                             size_t *nanr_output_size) {
    size_t expected_ncgr = 0, expected_nanr = 0;
    if (!valid_lz11(ncgr_data, ncgr_size, &expected_ncgr) ||
        !valid_lz11(nanr_data, nanr_size, &expected_nanr) ||
        expected_ncgr < 16 || expected_nanr < 16 ||
        tiles == NULL || tiles_capacity != 16384 || nanr_output == NULL ||
        nanr_output_size == NULL || nanr_capacity < expected_nanr) return -2;
    uint8_t *ncgr = NULL, *nanr = NULL;
    size_t ncgr_length = 0, nanr_length = 0;
    CompressionType ncgr_type = COMPRESSION_NONE, nanr_type = COMPRESSION_NONE;
    NcgrImage image = {0};
    int result = -10;
    if (Lz_Decompress(ncgr_data, ncgr_size, &ncgr, &ncgr_length, &ncgr_type) != 0 ||
        ncgr_length != expected_ncgr || ncgr_type != COMPRESSION_LZ11) goto cleanup;
    result = -11;
    if (Ncgr_Parse(ncgr, ncgr_length, &image) != 0) goto cleanup;
    result = -12;
    if (image.bpp != 4 || image.tile_count != 512 || image.width_tiles != 32 ||
        image.tile_data_size != tiles_capacity || image.tile_data == NULL) goto cleanup;
    result = -13;
    if (Lz_Decompress(nanr_data, nanr_size, &nanr, &nanr_length, &nanr_type) != 0 ||
        nanr_length != expected_nanr || nanr_type != COMPRESSION_LZ11 ||
        memcmp(nanr, "RNAN", 4) != 0) goto cleanup;
    memcpy(tiles, image.tile_data, tiles_capacity);
    memcpy(nanr_output, nanr, nanr_length);
    *nanr_output_size = nanr_length;
    result = 0;
cleanup:
    Ncgr_Free(&image);
    free(ncgr);
    free(nanr);
    return result;
}

static int32_t read_i32(const uint8_t *data) {
    uint32_t value = (uint32_t)data[0] | (uint32_t)data[1] << 8 |
                     (uint32_t)data[2] << 16 | (uint32_t)data[3] << 24;
    int32_t result;
    memcpy(&result, &value, sizeof(result));
    return result;
}

static int valid_scale(int scale) {
    return scale == 0 || (scale >= 128 && scale <= 65536) ||
           (scale <= -128 && scale >= -65536);
}

static int valid_transform(int scale_x, int scale_y, int x, int y) {
    return valid_scale(scale_x) && valid_scale(scale_y) &&
           x >= -4096 && x <= 4096 && y >= -4096 && y <= 4096;
}

static int use_rectangles(NcerFile *cells, const uint8_t *data, size_t size) {
    if (data == NULL || size < 14) return -1;
    int32_t count = read_i32(data);
    if (count <= 0 || count > 4096 || count != cells->cell_count ||
        size < 12 + (size_t)count * 48 + 2) return -2;
    for (int i = 0; i < count; i++) {
        NcerOam parsed[2] = {0};
        int n = 0;
        for (int q = 0; q < 2; q++) {
            const uint8_t *record = data + 12 + (size_t)i * 48 + q * 24;
            int32_t x = read_i32(record), y = read_i32(record + 4);
            int32_t width = read_i32(record + 8), height = read_i32(record + 12);
            int32_t u = read_i32(record + 16), v = read_i32(record + 20);
            if (width == 0 && height == 0) continue;
            if (x % 256 || y % 256 || x < -1048576 || x > 1048576 ||
                y < -1048576 || y > 1048576 || width <= 0 || height <= 0 ||
                width % 4096 || height % 4096 || u < 0 || v < 0 ||
                u % 32768 || v % 32768 ||
                (int64_t)u + width > 256 * 4096 || (int64_t)v + height > 128 * 4096) {
                n = -1;
                break;
            }
            NcerOam *oam = &parsed[n++];
            oam->x = x / 256;
            oam->y = (int)(-(int64_t)y / 256);
            oam->width = width / 4096;
            oam->height = height / 4096;
            oam->tile_index = (v / 32768) * 32 + (u / 32768);
        }
        NcerOam *replacement = n > 0 ? malloc((size_t)n * sizeof(NcerOam)) : NULL;
        if (n > 0 && replacement == NULL) return -4;
        for (int j = 0; j < n; j++) replacement[j] = parsed[n - 1 - j];
        free(cells->cells[i].oams);
        cells->cells[i].oams = replacement;
        cells->cells[i].oam_count = n;
    }
    return 0;
}

static int render_sample(const AvProbeRequest *request, uint8_t *output,
                         size_t output_size, int32_t *details,
                         size_t details_count, const CoordFile *coords,
                         const uint8_t *rectangles, size_t rectangles_size,
                         int render_scale, int record_index) {
    if (request == NULL || output == NULL || details == NULL) return -1;
    if (request->tiles == NULL || request->tile_size != 16384 ||
        !valid_input(request->ncer, request->ncer_size, "RECN") ||
        !valid_input(request->nanr, request->nanr_size, "RNAN") ||
        !valid_input(request->nmcr, request->nmcr_size, "RCMN") ||
        !valid_input(request->nmar, request->nmar_size, "RAMN") ||
        request->timeline < 0 || request->timeline > 128 ||
        request->tick < 0 ||
        request->min_x < -4096 || request->min_x > 4096 ||
        request->min_y < -4096 || request->min_y > 4096 ||
        request->width <= 0 || request->width > 256 ||
        request->height <= 0 || request->height > 256 ||
        request->child_mode != 0 || (render_scale != 1 && render_scale != 2) ||
        output_size != (size_t)request->width * (size_t)request->height ||
        details_count < 8 || details_count > 4103) return -2;
    if (!valid_index_budget(request->ncer, request->ncer_size, "KBEC", 32, 6) ||
        !valid_index_budget(request->nmcr, request->nmcr_size, "KBCM", 24, 8) ||
        !valid_animation_budget(request->nanr, request->nanr_size, 0) ||
        !valid_animation_budget(request->nmar, request->nmar_size, 1)) return -4;
    NcerFile cells = {0};
    NanrFile animations = {0};
    NmcrFile maps = {0};
    NmarFile timelines = {0};
    NmarFrame parent_frame = {0};
    int result = -3;
    if (Ncer_Parse(request->ncer, request->ncer_size, &cells) != 0 ||
        Nanr_Parse(request->nanr, request->nanr_size, &animations) != 0 ||
        Nmcr_Parse(request->nmcr, request->nmcr_size, &maps) != 0 ||
        Nmar_Parse(request->nmar, request->nmar_size, &timelines) != 0) goto cleanup;
    if (rectangles != NULL && use_rectangles(&cells, rectangles, rectangles_size) != 0) {
        result = -30;
        goto cleanup;
    }
    int map_index = Nmar_GetFrameAtTick(&timelines, request->timeline, request->tick, &parent_frame);
    if (map_index < 0 || map_index >= maps.map_count || maps.maps == NULL) goto cleanup;
    if (!valid_transform(parent_frame.scale_x, parent_frame.scale_y,
                         parent_frame.translate_x, parent_frame.translate_y)) {
        result = -5;
        goto cleanup;
    }
    NmcrMap *map = &maps.maps[map_index];
    if (map->record_count <= 0 || map->record_count > 128 || map->records == NULL ||
        details_count < 8 + (size_t)map->record_count * 2) goto cleanup;
    NmcrMap single = {0};
    if (record_index >= 0) {
        if (record_index >= map->record_count) goto cleanup;
        single = *map;
        single.records = &map->records[record_index];
        single.record_count = 1;
        map = &single;
    }
    int total_oams = 0;
    for (int i = 0; i < map->record_count; i++) {
        NanrFrame frame = {0};
        int cell_id = Nanr_GetResolvedCellIdAtTick(&animations, map->records[i].animation_index,
                                                   request->tick, &frame);
        if (cell_id < 0 || cell_id >= cells.cell_count || cells.cells == NULL) goto cleanup;
        if (!valid_transform(frame.scale_x, frame.scale_y,
                             frame.translate_x, frame.translate_y) ||
            map->records[i].x < -4096 || map->records[i].x > 4096 ||
            map->records[i].y < -4096 || map->records[i].y > 4096) {
            result = -5;
            goto cleanup;
        }
        NcerCell *cell = &cells.cells[cell_id];
        if (cell->oam_count < 0) {
            result = -30;
            goto cleanup;
        }
        if (cell->oam_count > 128 ||
            (cell->oam_count && cell->oams == NULL)) goto cleanup;
        total_oams += cell->oam_count;
        if (total_oams > 2048) goto cleanup;
        for (int j = 0; j < cell->oam_count; j++) {
            NcerOam *oam = &cell->oams[j];
            if (oam->width <= 0 || oam->width > (rectangles ? 256 : 64) ||
                (!rectangles && oam->width % 8) ||
                oam->height <= 0 || oam->height > (rectangles ? 128 : 64) ||
                (!rectangles && oam->height % 8) ||
                oam->tile_index < 0 ||
                oam->tile_index + ((oam->height + 7) / 8 - 1) * 32 +
                    (oam->width + 7) / 8 > 512) goto cleanup;
        }
        details[8 + i * 2] = map->records[i].animation_index;
        details[9 + i * 2] = cell_id;
    }
    NcgrImage image = {.tile_data = request->tiles, .tile_data_size = request->tile_size,
                       .bpp = 4, .tile_count = 512, .width_tiles = 32, .height_tiles = 16};
    NclrPalette palette = {.color_count = 16};
    ComposerTransform parent = {.rotation = parent_frame.rotation,
                                .scale_x = parent_frame.scale_x,
                                .scale_y = parent_frame.scale_y,
                                .translate_x = parent_frame.translate_x,
                                .translate_y = parent_frame.translate_y};
    if (render_scale == 2) {
        int64_t sx = (int64_t)(parent.scale_x == 0 ? NANR_SCALE_ONE : parent.scale_x) * 2;
        int64_t sy = (int64_t)(parent.scale_y == 0 ? NANR_SCALE_ONE : parent.scale_y) * 2;
        int64_t tx = (int64_t)parent.translate_x * 2;
        int64_t ty = (int64_t)parent.translate_y * 2;
        if (sx < INT32_MIN || sx > INT32_MAX || sy < INT32_MIN || sy > INT32_MAX ||
            tx < INT32_MIN || tx > INT32_MAX || ty < INT32_MIN || ty > INT32_MAX) goto cleanup;
        parent.scale_x = (int)sx;
        parent.scale_y = (int)sy;
        parent.translate_x = (int)tx;
        parent.translate_y = (int)ty;
    }
    result = Composer_RenderFrameIndexedWithTransform(
        &cells, &animations, map, &image, &palette, request->tick, 32,
        request->min_x, request->min_y, request->width, request->height, 0,
        output, coords, &parent);
    if (result == 0) {
        details[0] = map_index;
        details[1] = map->record_count;
        details[2] = total_oams;
        details[3] = parent.rotation;
        details[4] = parent.scale_x;
        details[5] = parent.scale_y;
        details[6] = cells.cell_count;
        details[7] = request->tick;
    }
cleanup:
    Nmar_Free(&timelines);
    Nmcr_Free(&maps);
    Nanr_Free(&animations);
    Ncer_Free(&cells);
    return result;
}

AV_PUBLIC int av_probe_render_sample(const AvProbeRequest *request, uint8_t *output,
                                     size_t output_size, int32_t *details,
                                     size_t details_count) {
    return render_sample(request, output, output_size, details, details_count, NULL, NULL, 0, 1, -1);
}

AV_PUBLIC int av_probe_render_with_coords(const AvProbeRequest *request, uint8_t *output,
                                          size_t output_size, int32_t *details,
                                          size_t details_count, const uint8_t *data,
                                          size_t data_size, int32_t *parsed,
                                          size_t parsed_count) {
    if (data == NULL || data_size > 1048576 || parsed == NULL || parsed_count < 13) return -1;
    CoordFile coords = {0};
    int status = Coord_Parse(data, data_size, &coords);
    if (status != 0) return -20;
    if (coords.record_count <= 0 || coords.records == NULL) {
        Coord_Free(&coords);
        return -21;
    }
    parsed[0] = coords.record_count;
    for (int i = 0; i < 12; i++) parsed[i + 1] = coords.records[0].raw_words[i];
    status = render_sample(request, output, output_size, details, details_count, &coords, NULL, 0, 1, -1);
    Coord_Free(&coords);
    return status;
}

AV_PUBLIC int av_probe_render_rectangles(const AvProbeRequest *request, uint8_t *output,
                                         size_t output_size, int32_t *details,
                                         size_t details_count, const uint8_t *data,
                                         size_t data_size) {
    if (data == NULL || data_size > 1048576) return -1;
    return render_sample(request, output, output_size, details, details_count, NULL, data, data_size, 1, -1);
}

AV_PUBLIC int av_probe_render_rectangle_piece(const AvProbeRequest *request, uint8_t *output,
                                              size_t output_size, int32_t *details,
                                              size_t details_count, const uint8_t *data,
                                              size_t data_size, int record_index) {
    if (data == NULL || data_size > 1048576 || record_index < 0) return -1;
    return render_sample(request, output, output_size, details, details_count,
                         NULL, data, data_size, 1, record_index);
}

AV_PUBLIC int av_probe_render_rectangles_at_2x(const AvProbeRequest *request, uint8_t *output,
                                               size_t output_size, int32_t *details,
                                               size_t details_count, const uint8_t *data,
                                               size_t data_size) {
    if (data == NULL || data_size > 1048576 || request == NULL ||
        request->width != 256 || request->height != 256 ||
        request->min_x != -128 || request->min_y != -128) return -1;
    return render_sample(request, output, output_size, details, details_count, NULL, data, data_size, 2, -1);
}

AV_PUBLIC int av_probe_describe_cells(const uint8_t *data, size_t data_size,
                                     int32_t *output, size_t output_count) {
    if (!valid_input(data, data_size, "RECN") || output == NULL || output_count < 1) return -1;
    NcerFile cells = {0};
    if (Ncer_Parse(data, data_size, &cells) != 0) return -2;
    if (cells.cell_count <= 0 || cells.cell_count > 128 ||
        output_count < 1 + (size_t)cells.cell_count * 45) {
        Ncer_Free(&cells);
        return -3;
    }
    output[0] = cells.cell_count;
    for (int i = 0; i < cells.cell_count; i++) {
        NcerCell *cell = &cells.cells[i];
        if (cell->oam_count < 0 || cell->oam_count > 4) {
            Ncer_Free(&cells);
            return -4;
        }
        int32_t *entry = output + 1 + i * 45;
        entry[0] = cell->oam_count;
        for (int j = 0; j < cell->oam_count; j++) {
            NcerOam *oam = &cell->oams[j];
            int32_t *values = entry + 1 + j * 11;
            int x = 0, y = 0;
            Ncer_GetOamDrawOrigin(oam, &x, &y);
            values[0] = x;
            values[1] = y;
            values[2] = oam->width;
            values[3] = oam->height;
            values[4] = oam->tile_index;
            values[5] = oam->palette;
            values[6] = oam->priority;
            values[7] = oam->flip_h;
            values[8] = oam->flip_v;
            values[9] = oam->affine;
            values[10] = oam->double_size;
        }
    }
    Ncer_Free(&cells);
    return 0;
}
