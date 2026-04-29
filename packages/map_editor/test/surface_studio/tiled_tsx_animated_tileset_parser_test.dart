import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_animated_tileset_parser.dart';
import 'package:path/path.dart' as p;

void main() {
  group('parseTiledTsxAnimatedTileset', () {
    test('parses the Pokemon SDK TECH animated tileset summary', () {
      final audit = parseTiledTsxAnimatedTileset(_readTechAnimationsTsx());

      expect(audit.hasErrors, isFalse);
      expect(audit.summary.name, 'TECH-Animations');
      expect(audit.summary.tileWidth, 32);
      expect(audit.summary.tileHeight, 32);
      expect(audit.summary.columns, 98);
      expect(audit.summary.tileCount, 10682);
      expect(audit.summary.imageSource, '../Assets/TECH-Nature-animations.png');
      expect(audit.summary.imageWidth, 3136);
      expect(audit.summary.imageHeight, 3488);
      expect(audit.summary.transparentColor, 'f05ba1');
      expect(audit.summary.animationCount, 242);
      expect(audit.animations, hasLength(242));
    });

    test('parses tile id 99 animation frames and durations', () {
      final audit = parseTiledTsxAnimatedTileset(_readTechAnimationsTsx());

      final animation = audit.animationForBaseTileId(99);

      expect(animation, isNotNull);
      expect(animation!.baseTileId, 99);
      expect(
        animation.frames.take(3).map((frame) => frame.tileId),
        [99, 105, 111],
      );
      expect(animation.frames, hasLength(16));
      expect(
        animation.frames.map((frame) => frame.durationMs).toSet(),
        {100},
      );
    });

    test('resolves Tiled 0-based tile ids to source coordinates', () {
      final tile99 = resolveTiledTsxTileCoordinate(
        tileId: 99,
        columns: 98,
        tileWidth: 32,
        tileHeight: 32,
      );
      final tile105 = resolveTiledTsxTileCoordinate(
        tileId: 105,
        columns: 98,
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(tile99.row, 1);
      expect(tile99.column, 1);
      expect(tile99.sourceX, 32);
      expect(tile99.sourceY, 32);

      expect(tile105.row, 1);
      expect(tile105.column, 7);
      expect(tile105.sourceX, 224);
      expect(tile105.sourceY, 32);
    });

    test('reports a TSX missing its image tag', () {
      final audit = parseTiledTsxAnimatedTileset('''
<?xml version="1.0" encoding="UTF-8"?>
<tileset name="NoImage" tilewidth="32" tileheight="32" tilecount="1" columns="1">
</tileset>
''');

      expect(audit.hasErrors, isTrue);
      expect(audit.summary.name, 'NoImage');
      expect(audit.summary.imageSource, isEmpty);
      expect(audit.diagnostics.any((d) => d.message.contains('image')), isTrue);
    });

    test('allows a TSX without animations', () {
      final audit = parseTiledTsxAnimatedTileset('''
<?xml version="1.0" encoding="UTF-8"?>
<tileset name="Static" tilewidth="32" tileheight="32" tilecount="1" columns="1">
 <image source="../Assets/static.png" width="32" height="32"/>
</tileset>
''');

      expect(audit.hasErrors, isFalse);
      expect(audit.summary.animationCount, 0);
      expect(audit.animations, isEmpty);
    });

    test('reports missing frame duration', () {
      final audit = parseTiledTsxAnimatedTileset('''
<?xml version="1.0" encoding="UTF-8"?>
<tileset name="MissingDuration" tilewidth="32" tileheight="32" tilecount="2" columns="1">
 <image source="../Assets/static.png" width="32" height="64"/>
 <tile id="0">
  <animation>
   <frame tileid="0"/>
  </animation>
 </tile>
</tileset>
''');

      expect(audit.hasErrors, isTrue);
      expect(audit.animations.single.frames, isEmpty);
      expect(
        audit.diagnostics.any((d) => d.message.contains('duration')),
        isTrue,
      );
    });

    test('warns when an animation frame references a tile outside tilecount',
        () {
      final audit = parseTiledTsxAnimatedTileset('''
<?xml version="1.0" encoding="UTF-8"?>
<tileset name="OutOfBounds" tilewidth="32" tileheight="32" tilecount="2" columns="1">
 <image source="../Assets/static.png" width="32" height="64"/>
 <tile id="0">
  <animation>
   <frame tileid="2" duration="100"/>
  </animation>
 </tile>
</tileset>
''');

      expect(audit.hasWarnings, isTrue);
      expect(audit.animations.single.frames.single.tileId, 2);
      expect(
        audit.diagnostics.any((d) => d.message.contains('outside tilecount')),
        isTrue,
      );
    });
  });
}

String _readTechAnimationsTsx() {
  final repoRoot = Directory.current.parent.parent;
  final sdkProject = repoRoot
      .listSync()
      .whereType<Directory>()
      .firstWhere((dir) => p.basename(dir.path).contains('sdk_test_project'));
  final tsxFile = File(
    p.join(
      sdkProject.path,
      'Data',
      'Tiled',
      'Tilesets',
      'TECH-Animations.tsx',
    ),
  );
  return tsxFile.readAsStringSync();
}
