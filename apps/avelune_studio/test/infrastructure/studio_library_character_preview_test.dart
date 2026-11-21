import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:avelune_studio/features/resources/application/resource_preview_source.dart';
import 'package:avelune_studio/platform/rendering/studio_character_thumbnail.dart';
import 'package:avelune_studio/platform/rendering/studio_library_image_cache.dart';
import 'package:avelune_studio/platform/rendering/studio_library_image_preview.dart';
import 'package:avelune_studio/platform/rendering/studio_resource_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart'
    show
        AssetCatalog,
        AssetRecord,
        ContentArtifactRef,
        assetBlobStorageKey,
        assetCatalogStorageKey;
import 'package:map_core/map_core_domain.dart';

void main() {
  testWidgets(
    'pose changes draw new sprite pixels using the same image scope',
    (tester) async {
      final directory = (await tester.runAsync(_writeSprite))!;
      final catalog = StudioAssetCatalogCache(directory.path);
      final cache = StudioLibraryImageCache(catalog);
      addTearDown(() async {
        cache.dispose();
        await directory.delete(recursive: true);
      });

      Future<void> show(CharacterPreviewSource source) => tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: StudioLibraryImagePreview(
              cache: cache,
              source: source,
              project: _project,
              size: 168,
            ),
          ),
        ),
      );
      StudioCharacterThumbnail thumbnail() =>
          tester.widget(find.byType(StudioCharacterThumbnail));
      final painted = find.descendant(
        of: find.byType(StudioCharacterThumbnail),
        matching: find.byType(CustomPaint),
      );
      await tester.runAsync(() async {
        await show(const CharacterPreviewSource(_character));
        for (
          var attempt = 0;
          attempt < 250 && painted.evaluate().isEmpty;
          attempt++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          await tester.pump();
        }
      });
      expect(painted, findsOneWidget);
      final scope = thumbnail().resources;
      final sprite = scope.images['sprite'];
      expect(sprite, isNotNull);
      expect(catalog.reads, 1);
      Future<List<int>?> pixel() => tester.runAsync(
        () => _paintedPixel(tester.widget<CustomPaint>(painted).painter!),
      );
      expect(await pixel(), [213, 17, 37, 255]);

      await show(
        const CharacterPreviewSource(
          _character,
          animationState: CharacterAnimationState.walk,
          elapsedMs: 120,
        ),
      );
      expect(await pixel(), [12, 142, 85, 255]);
      expect(thumbnail().resources, same(scope));
      expect(thumbnail().resources.images['sprite'], same(sprite));

      await show(
        const CharacterPreviewSource(_character, facing: EntityFacing.east),
      );
      expect(await pixel(), [12, 142, 85, 255]);
      expect(thumbnail().resources, same(scope));
      expect(thumbnail().resources.images['sprite'], same(sprite));
      expect(catalog.reads, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}

Future<Directory> _writeSprite() async {
  final qaRoot = Platform.environment['AVELUNE_QA_ROOT'];
  final parent = qaRoot == null
      ? Directory.systemTemp
      : await Directory(qaRoot).create(recursive: true);
  final temporary = await parent.createTemp('library_sprite_');
  final directory = Directory(await temporary.resolveSymbolicLinks());
  try {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder)
      ..drawRect(
        const ui.Rect.fromLTWH(0, 0, 32, 32),
        ui.Paint()..color = const ui.Color(0xffd51125),
      )
      ..drawRect(
        const ui.Rect.fromLTWH(32, 0, 32, 32),
        ui.Paint()..color = const ui.Color(0xff0c8e55),
      );
    final bytes = await _render(recorder, 64, 32, ui.ImageByteFormat.png);
    final artifact = ContentArtifactRef.fromBytes(
      bytes,
      mediaType: 'image/png',
    );
    final blob = File('${directory.path}/${assetBlobStorageKey(artifact)}');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes(bytes);
    final registry = File('${directory.path}/$assetCatalogStorageKey');
    await registry.parent.create(recursive: true);
    await registry.writeAsString(
      jsonEncode(
        AssetCatalog(
          records: [
            AssetRecord(
              id: 'sprite',
              logicalPath: 'assets/sprite.png',
              artifact: artifact,
            ),
          ],
        ).toJson(),
      ),
    );
    return directory;
  } catch (_) {
    await directory.delete(recursive: true);
    rethrow;
  }
}

Future<List<int>> _paintedPixel(CustomPainter painter) async {
  const size = 168;
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder), const Size.square(168));
  final pixels = await _render(
    recorder,
    size,
    size,
    ui.ImageByteFormat.rawRgba,
  );
  const offset = (size ~/ 2 * size + size ~/ 2) * 4;
  return pixels.sublist(offset, offset + 4);
}

Future<Uint8List> _render(
  ui.PictureRecorder recorder,
  int width,
  int height,
  ui.ImageByteFormat format,
) async {
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  final bytes = (await image.toByteData(format: format))!;
  image.dispose();
  return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
}

const _project = ProjectManifest(
  name: 'Aperçus',
  maps: [],
  settings: ProjectSettings(tileWidth: 16, tileHeight: 16),
  tilesets: [
    ProjectTilesetEntry(
      id: 'sprite',
      name: 'Planche',
      relativePath: 'assets/sprite.png',
    ),
  ],
  characters: [_character],
);

const _character = ProjectCharacterEntry(
  id: 'guide',
  name: 'Guide',
  tilesetId: 'sprite',
  animations: [
    CharacterAnimation(
      state: CharacterAnimationState.idle,
      direction: EntityFacing.south,
      frames: [_redFrame],
    ),
    CharacterAnimation(
      state: CharacterAnimationState.idle,
      direction: EntityFacing.east,
      frames: [_greenFrame],
    ),
    CharacterAnimation(
      state: CharacterAnimationState.walk,
      direction: EntityFacing.south,
      frames: [_redFrame, _greenFrame],
    ),
  ],
);

const _redFrame = CharacterAnimationFrame(
  source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
  durationMs: 100,
);
const _greenFrame = CharacterAnimationFrame(
  source: TilesetSourceRect(x: 1, y: 0, width: 1, height: 2),
  durationMs: 100,
);
