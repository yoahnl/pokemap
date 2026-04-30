import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectPathPatternPreset JSON golden samples', () {
    test('minimal 1x1 golden decodes to the expected preset', () {
      final preset = decodeProjectPathPatternPreset(
        _readFixtureJson('project_path_pattern_preset_minimal_1x1.json'),
      );

      expect(preset.id, 'water-1x1');
      expect(preset.name, 'Water 1x1');
      expect(preset.basePathPresetId, 'legacy-water');
      expect(preset.sortOrder, 0);
      expect(preset.transparentColor, isNull);
      expect(preset.categoryId, isNull);
      expect(preset.centerPattern.size,
          PathCenterPatternSize(width: 1, height: 1));
      final cell = preset.centerPattern.cellAt(0, 0);
      expect(cell.frames.single.source, const TilesetSourceRect(x: 1, y: 2));
      expect(cell.frames.single.durationMs, isNull);
    });

    test('minimal 1x1 golden matches encode output', () {
      final preset = ProjectPathPatternPreset(
        id: 'water-1x1',
        name: 'Water 1x1',
        basePathPresetId: 'legacy-water',
        centerPattern: _minimalCenterPattern(),
      );

      expect(
        encodeProjectPathPatternPreset(preset),
        _readFixtureJson('project_path_pattern_preset_minimal_1x1.json'),
      );
    });

    test('complete 2x2 golden decodes to the expected preset', () {
      final preset = decodeProjectPathPatternPreset(
        _readFixtureJson('project_path_pattern_preset_complete_2x2.json'),
      );

      expect(preset.id, 'water-sea-2x2');
      expect(preset.name, 'Mer 2x2');
      expect(preset.basePathPresetId, 'legacy-water');
      expect(preset.sortOrder, 12);
      expect(preset.transparentColor,
          TilesetTransparentColor.fromHexRgb('f05ba1'));
      expect(preset.categoryId, 'water');
      expect(preset.centerPattern.size,
          PathCenterPatternSize(width: 2, height: 2));
      expect(
        preset.centerPattern.cells
            .map((cell) => [cell.localX, cell.localY])
            .toList(),
        [
          [0, 0],
          [1, 0],
          [0, 1],
          [1, 1],
        ],
      );
      final firstFrames = preset.centerPattern.cellAt(0, 0).frames;
      expect(firstFrames[0].source, const TilesetSourceRect(x: 0, y: 0));
      expect(firstFrames[0].durationMs, 100);
      expect(firstFrames[1].tilesetId, 'override_tileset');
      expect(firstFrames[1].source, const TilesetSourceRect(x: 1, y: 0));
      expect(firstFrames[1].durationMs, 110);
      expect(preset.centerPattern.cellAt(1, 0).frames.single.durationMs, 120);
      expect(preset.centerPattern.cellAt(0, 1).frames.single.durationMs, 130);
      expect(preset.centerPattern.cellAt(1, 1).frames.single.durationMs, 140);
    });

    test('complete 2x2 golden matches encode output', () {
      expect(
        encodeProjectPathPatternPreset(_completePreset()),
        _readFixtureJson('project_path_pattern_preset_complete_2x2.json'),
      );
    });

    test('goldens roundtrip through decode and encode', () {
      for (final name in _fixtureNames) {
        final fixture = _readFixtureJson(name);
        final preset = decodeProjectPathPatternPreset(fixture);

        expect(encodeProjectPathPatternPreset(preset), fixture, reason: name);
      }
    });

    test('goldens use two-space canonical formatting with final newline', () {
      for (final name in _fixtureNames) {
        final raw = _readFixture(name);
        final decoded = jsonDecode(raw) as Object?;
        const encoder = JsonEncoder.withIndent('  ');
        final pretty = _withTrailingNewline(encoder.convert(decoded));

        expect(raw.endsWith('\n'), isTrue, reason: name);
        expect(pretty, raw, reason: name);
      }
    });
  });
}

const _fixtureNames = [
  'project_path_pattern_preset_minimal_1x1.json',
  'project_path_pattern_preset_complete_2x2.json',
];

String _fixturePath(String name) => 'test/fixtures/path_pattern/$name';

String _readFixture(String name) => File(_fixturePath(name)).readAsStringSync();

Map<String, dynamic> _readFixtureJson(String name) {
  return jsonDecode(_readFixture(name)) as Map<String, dynamic>;
}

String _withTrailingNewline(String value) {
  if (value.endsWith('\n')) {
    return value;
  }
  return '$value\n';
}

ProjectPathPatternPreset _completePreset() {
  return ProjectPathPatternPreset(
    id: 'water-sea-2x2',
    name: 'Mer 2x2',
    basePathPresetId: 'legacy-water',
    centerPattern: _completeCenterPattern(),
    transparentColor: TilesetTransparentColor.fromHexRgb('f05ba1'),
    categoryId: 'water',
    sortOrder: 12,
  );
}

PathCenterPattern _minimalCenterPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 1, height: 1),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: [_frame(1, 2)],
      ),
    ],
  );
}

PathCenterPattern _completeCenterPattern() {
  return PathCenterPattern(
    size: PathCenterPatternSize(width: 2, height: 2),
    cells: [
      PathCenterPatternCell(
        localX: 0,
        localY: 0,
        frames: [
          _frame(0, 0, durationMs: 100),
          _frame(1, 0, tilesetId: 'override_tileset', durationMs: 110),
        ],
      ),
      PathCenterPatternCell(
        localX: 1,
        localY: 0,
        frames: [_frame(2, 0, durationMs: 120)],
      ),
      PathCenterPatternCell(
        localX: 0,
        localY: 1,
        frames: [_frame(3, 0, durationMs: 130)],
      ),
      PathCenterPatternCell(
        localX: 1,
        localY: 1,
        frames: [_frame(4, 0, durationMs: 140)],
      ),
    ],
  );
}

TilesetVisualFrame _frame(
  int x,
  int y, {
  String tilesetId = '',
  int? durationMs,
}) {
  return TilesetVisualFrame(
    tilesetId: tilesetId,
    source: TilesetSourceRect(x: x, y: y),
    durationMs: durationMs,
  );
}
