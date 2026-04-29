import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_animated_tileset_parser.dart';
import 'package:map_editor/src/features/surface_studio/importers/tiled_tsx_surface_animation_importer.dart';
import 'package:path/path.dart' as p;

void main() {
  group('importTiledTsxSurfaceAnimations', () {
    test('imports the Pokemon SDK TSX as one atlas and 242 animations', () {
      final result = importTiledTsxSurfaceAnimationsFromXml(
        xml: _readTechAnimationsTsx(),
        options: const TiledTsxSurfaceAnimationImportOptions(
          atlasId: 'tech-animations',
          tilesetId: 'tech-nature-animations',
          animationIdPrefix: 'TECH-Animations',
        ),
      );

      expect(result.hasErrors, isFalse);
      expect(result.atlas, isNotNull);
      expect(result.atlas!.id, 'tech-animations');
      expect(result.atlas!.name, 'TECH-Animations');
      expect(result.atlas!.tilesetId, 'tech-nature-animations');
      expect(result.atlas!.geometry.tileSize.width, 32);
      expect(result.atlas!.geometry.tileSize.height, 32);
      expect(result.atlas!.geometry.gridSize.columns, 98);
      expect(result.atlas!.geometry.gridSize.rows, 109);
      expect(result.atlas!.geometry.layout, SurfaceAtlasLayout.grid);

      expect(result.animations, hasLength(242));
      expect(result.animations.first.id, 'tech-animations-tile-99');
      expect(
        result.animations.map((animation) => animation.id).toSet(),
        hasLength(result.animations.length),
      );
      expect(
        result.animations.every(
          (animation) => animation.timeline.frames.every(
            (frame) => frame.isInside(result.atlas!.geometry),
          ),
        ),
        isTrue,
      );
    });

    test('converts tile id 99 frames from explicit TSX tile ids', () {
      final result = importTiledTsxSurfaceAnimationsFromXml(
        xml: _readTechAnimationsTsx(),
        options: const TiledTsxSurfaceAnimationImportOptions(
          atlasId: 'tech-animations',
          tilesetId: 'tech-nature-animations',
          animationIdPrefix: 'tech-animations',
        ),
      );

      final animation = result.animationById('tech-animations-tile-99');

      expect(animation, isNotNull);
      expect(animation!.name, 'TECH-Animations tile 99');
      expect(animation.timeline.frames, hasLength(16));

      final first = animation.timeline.frames[0];
      expect(first.tileRef.atlasId, 'tech-animations');
      expect(first.tileRef.column, 1);
      expect(first.tileRef.row, 1);
      expect(first.durationMs, 100);

      final second = animation.timeline.frames[1];
      expect(second.tileRef.atlasId, 'tech-animations');
      expect(second.tileRef.column, 7);
      expect(second.tileRef.row, 1);
      expect(second.durationMs, 100);

      final last = animation.timeline.frames.last;
      expect(last.tileRef.atlasId, 'tech-animations');
      expect(last.tileRef.column, 91);
      expect(last.tileRef.row, 1);
      expect(last.durationMs, 100);
    });

    test('keeps TSX order and does not expose any preset output', () {
      final result = importTiledTsxSurfaceAnimationsFromXml(
        xml: _readTechAnimationsTsx(),
        options: const TiledTsxSurfaceAnimationImportOptions(
          atlasId: 'tech-animations',
          tilesetId: 'tech-nature-animations',
          animationIdPrefix: 'tech-animations',
        ),
      );

      expect(
        result.animations.take(4).map((animation) => animation.id),
        [
          'tech-animations-tile-99',
          'tech-animations-tile-100',
          'tech-animations-tile-197',
          'tech-animations-tile-198',
        ],
      );
    });

    test('reports invalid import options as blocking diagnostics', () {
      final audit = parseTiledTsxAnimatedTileset(_minimalTsx);

      final result = importTiledTsxSurfaceAnimations(
        audit: audit,
        options: const TiledTsxSurfaceAnimationImportOptions(
          atlasId: '  ',
          tilesetId: '',
          animationIdPrefix: ' ',
        ),
      );

      expect(result.hasErrors, isTrue);
      expect(result.atlas, isNull);
      expect(result.animations, isEmpty);
      expect(
        result.diagnostics.map((diagnostic) => diagnostic.message),
        containsAll([
          'atlasId must be non-empty.',
          'tilesetId must be non-empty.',
          'animationIdPrefix must be non-empty.',
        ]),
      );
    });

    test('imports a minimal TSX with explicit frame durations', () {
      final result = importTiledTsxSurfaceAnimationsFromXml(
        xml: _minimalTsx,
        options: const TiledTsxSurfaceAnimationImportOptions(
          atlasId: 'mini',
          tilesetId: 'mini-tileset',
          animationIdPrefix: 'mini',
          sortOrderBase: 12,
        ),
      );

      expect(result.hasErrors, isFalse);
      expect(result.atlas!.geometry.gridSize.columns, 2);
      expect(result.atlas!.geometry.gridSize.rows, 2);
      expect(result.atlas!.sortOrder, 12);
      expect(result.animations, hasLength(1));

      final animation = result.animations.single;
      expect(animation.id, 'mini-tile-1');
      expect(animation.sortOrder, 12);
      expect(animation.timeline.frames, hasLength(2));
      expect(animation.timeline.frames[0].tileRef.column, 1);
      expect(animation.timeline.frames[0].tileRef.row, 0);
      expect(animation.timeline.frames[0].durationMs, 100);
      expect(animation.timeline.frames[1].tileRef.column, 1);
      expect(animation.timeline.frames[1].tileRef.row, 1);
      expect(animation.timeline.frames[1].durationMs, 120);
    });

    test('blocks imports when TSX geometry cannot form a tile grid', () {
      final result = importTiledTsxSurfaceAnimationsFromXml(
        xml: '''
<?xml version="1.0" encoding="UTF-8"?>
<tileset name="bad" tilewidth="32" tileheight="32" tilecount="2" columns="2">
 <image source="../Assets/bad.png" width="63" height="64"/>
</tileset>
''',
        options: const TiledTsxSurfaceAnimationImportOptions(
          atlasId: 'bad',
          tilesetId: 'bad-tileset',
          animationIdPrefix: 'bad',
        ),
      );

      expect(result.hasErrors, isTrue);
      expect(result.atlas, isNull);
      expect(result.animations, isEmpty);
      expect(
        result.diagnostics.any(
          (diagnostic) => diagnostic.message.contains('imageWidth'),
        ),
        isTrue,
      );
    });

    test('reports duplicate generated animation ids as blocking diagnostics',
        () {
      final result = importTiledTsxSurfaceAnimationsFromXml(
        xml: '''
<?xml version="1.0" encoding="UTF-8"?>
<tileset name="duplicate" tilewidth="32" tileheight="32" tilecount="4" columns="2">
 <image source="../Assets/duplicate.png" width="64" height="64"/>
 <tile id="1">
  <animation>
   <frame tileid="1" duration="100"/>
  </animation>
 </tile>
 <tile id="1">
  <animation>
   <frame tileid="3" duration="100"/>
  </animation>
 </tile>
</tileset>
''',
        options: const TiledTsxSurfaceAnimationImportOptions(
          atlasId: 'duplicate',
          tilesetId: 'duplicate-tileset',
          animationIdPrefix: 'duplicate',
        ),
      );

      expect(result.hasErrors, isTrue);
      expect(result.atlas, isNull);
      expect(result.animations, isEmpty);
      expect(
        result.diagnostics.any(
          (diagnostic) => diagnostic.message.contains('Duplicate animation id'),
        ),
        isTrue,
      );
    });
  });
}

const _minimalTsx = '''
<?xml version="1.0" encoding="UTF-8"?>
<tileset name="mini" tilewidth="32" tileheight="32" tilecount="4" columns="2">
  <image source="../Assets/mini.png" width="64" height="64"/>
  <tile id="1">
    <animation>
      <frame tileid="1" duration="100"/>
      <frame tileid="3" duration="120"/>
    </animation>
  </tile>
</tileset>
''';

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
