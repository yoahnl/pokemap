import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_mistral_animation_pack.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_models.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_mistral_grouping_prompt_builder.dart';

void main() {
  test('prompt forbids frame inference and lists exact Surface roles', () {
    final request = _request();
    final pack = buildTiledTsxMistralAnimationPack(
      request: request,
      atlasImageBytes: _atlasBytes(),
    );

    final prompt = buildTiledTsxMistralGroupingPrompt(
      request: request,
      metadataJson: pack.metadataJson,
    );

    expect(prompt, contains('Do not infer or change frames'));
    expect(
      prompt,
      contains(
        'Only propose mappings from SurfaceVariantRole to existing animationId',
      ),
    );
    expect(prompt, contains('Take your time internally'));
    expect(prompt, contains('Use high-effort visual reasoning'));
    expect(prompt, contains('Prefer abstaining over wrong mappings'));
    expect(prompt, contains('Return JSON only'));
    expect(prompt, contains('tech-animations-tile-99'));
    expect(prompt, contains('"frameCount": 3'));
    expect(
      prompt,
      contains(
        'isolated, endNorth, endEast, endSouth, endWest, horizontal, vertical, cornerNW, cornerNE, cornerSW, cornerSE, innerCornerNW, innerCornerNE, innerCornerSW, innerCornerSE, teeNorth, teeEast, teeSouth, teeWest, cross',
      ),
    );
  });

  test('vision pack creates a contact sheet and safe metadata', () {
    final request = _request();

    final pack = buildTiledTsxMistralAnimationPack(
      request: request,
      atlasImageBytes: _atlasBytes(),
    );

    expect(pack.contactSheetDataUrl, startsWith('data:image/png;base64,'));
    final metadata = jsonDecode(pack.metadataJson) as Map<String, dynamic>;
    final animations = metadata['animations'] as List<dynamic>;
    expect(animations, hasLength(2));
    expect(
      animations.first,
      containsPair('animationId', 'tech-animations-tile-99'),
    );
    expect(animations.first, containsPair('frameCount', 3));
    expect(pack.metadataJson, contains('"sampledFrames"'));
    expect(pack.metadataJson, isNot(contains('/Users/')));
    expect(pack.metadataJson, isNot(contains('MISTRAL_API_KEY')));
    expect(pack.metadataJson, isNot(contains('configured-secret')));
  });
}

TiledTsxMistralGroupingRequest _request() {
  return TiledTsxMistralGroupingRequest(
    animations: [
      _animation('tech-animations-tile-99', [
        (column: 1, row: 1, durationMs: 100),
        (column: 7, row: 1, durationMs: 100),
        (column: 13, row: 1, durationMs: 100),
      ]),
      _animation('tech-animations-tile-105', [
        (column: 2, row: 2, durationMs: 80),
        (column: 3, row: 2, durationMs: 120),
      ]),
    ],
    tileWidth: 8,
    tileHeight: 8,
    atlasColumns: 4,
    atlasRows: 3,
    availableRoles: standardSurfaceVariantRoleOrder,
  );
}

ProjectSurfaceAnimation _animation(
  String id,
  List<({int column, int row, int durationMs})> frames,
) {
  return ProjectSurfaceAnimation(
    id: id,
    name: id,
    timeline: SurfaceAnimationTimeline(
      frames: [
        for (final frame in frames)
          SurfaceAnimationFrame(
            tileRef: SurfaceAtlasTileRef(
              atlasId: 'tech-animations',
              column: frame.column,
              row: frame.row,
            ),
            durationMs: frame.durationMs,
          ),
      ],
    ),
  );
}

Uint8List _atlasBytes() {
  const tile = 8;
  final image = img.Image(width: 4 * tile, height: 3 * tile);
  for (var row = 0; row < 3; row++) {
    for (var column = 0; column < 4; column++) {
      img.fillRect(
        image,
        x1: column * tile,
        y1: row * tile,
        x2: column * tile + tile - 1,
        y2: row * tile + tile - 1,
        color: img.ColorRgb8(30 + column * 40, 70 + row * 50, 180),
      );
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}
