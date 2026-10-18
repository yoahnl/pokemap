import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/load_runtime_map_bundle.dart';
import 'package:map_runtime/src/application/narrative_event_runtime_snapshot.dart';
import 'package:map_runtime/src/application/runtime_project_catalog.dart';
import 'package:map_runtime/src/infrastructure/tile_image_loader.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog and media paths must belong to the same project', () async {
    final first = await _Fixture.create(0);
    final second = await _Fixture.create(0);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    final catalog = await RuntimeProjectCatalog.open(first.path);
    addTearDown(catalog.dispose);

    await expectLater(
      loadRuntimeMapBundle(
        projectFilePath: second.path,
        projectCatalog: catalog,
        mapId: 'a',
      ),
      throwsA(isA<MapLoadException>()),
    );
  });

  for (final multiplier in [1, 2, 4]) {
    test(
      'Player shares its catalog and decodes only map media $multiplier×',
      () async {
        final fixture = await _Fixture.create(multiplier * 100);
        addTearDown(fixture.dispose);
        final first = await loadRuntimeMapBundle(
          projectFilePath: fixture.path,
          mapId: 'a',
        );
        final catalog = first.projectCatalog!;
        final game = PlayableMapGame(
          bundle: first,
          projectFilePath: fixture.path,
        );
        addTearDown(game.onRemove);
        await File(fixture.path).writeAsString('{}');
        final second = await game.debugLoadRuntimeMapBundleCachedForTest('b');
        expect(second.projectCatalog, same(catalog));
        expect(second.resourceBudget, same(first.resourceBudget));
        expect(first.tilesetAbsolutePathsById.keys, ['a']);
        expect(second.tilesetAbsolutePathsById.keys, ['b']);
        final cache = RuntimeTilesetImageSingleFlightCache(
          loader: loadTilesetImagesById,
          resourceBudget: first.resourceBudget,
          identity: catalog.identity,
        );
        addTearDown(cache.dispose);
        final images = await cache.loadById(
          first.runtimeImageAbsolutePathsById,
        );
        final original = await _pixels(images['a']!);
        cache.trimToBudget(maxBytes: 0, retainedImages: []);
        expect(first.resourceBudget.residentBytes, 0);
        final returned = await game.debugLoadRuntimeMapBundleCachedForTest('a');
        final reloaded = await cache.loadById(
          returned.runtimeImageAbsolutePathsById,
        );
        final pixels = await _pixels(reloaded['a']!);
        expect(pixels, original);
        expect(first.resourceBudget.residentBytes, 16);
        cache.dispose();
        expect(first.resourceBudget.residentBytes, 0);
      },
    );
  }

  test(
    'narrative views share one generation and reject equal views from another',
    () async {
      final fixture = await _Fixture.create(2);
      addTearDown(fixture.dispose);
      final first = await RuntimeProjectCatalog.open(fixture.path);
      addTearDown(first.dispose);
      final a = await loadRuntimeCatalogMap(first, 'a');
      final b = await loadRuntimeCatalogMap(first, 'b');
      final snapshot = await NarrativeEventRuntimeSnapshot.build(
        project: a.project,
        loadMap: (id) => loadRuntimeCatalogMap(first, id),
      );
      expect(snapshot.matchesProject(b.project), isTrue);
      await fixture.publish(
        fixture.project.copyWith(
          tilesets: [
            ...fixture.project.tilesets,
            const ProjectTilesetEntry(
              id: 'another',
              name: 'Another',
              relativePath: 'another.png',
            ),
          ],
        ),
      );
      final second = await RuntimeProjectCatalog.open(fixture.path);
      addTearDown(second.dispose);
      final other = await loadRuntimeCatalogMap(second, 'a');
      expect(other.project, a.project);
      expect(first.identity, isNot(second.identity));
      expect(snapshot.matchesProject(other.project), isFalse);
      await expectLater(
        NarrativeEventRuntimeSnapshot.build(
          project: a.project,
          loadMap: (_) async => other,
        ),
        throwsStateError,
      );
      first.dispose();
      expect(snapshot.matchesProject(a.project), isFalse);
    },
  );
}

Future<Uint8List> _pixels(RuntimeTilesetImage source) async {
  final recorder = ui.PictureRecorder();
  source.drawImageRect(
    ui.Canvas(recorder),
    const ui.Rect.fromLTWH(0, 0, 2, 2),
    const ui.Rect.fromLTWH(0, 0, 2, 2),
    ui.Paint(),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(2, 2);
  try {
    final data = await image.toByteData();
    return Uint8List.fromList(data!.buffer.asUint8List());
  } finally {
    image.dispose();
    picture.dispose();
  }
}

final class _Fixture {
  _Fixture(this.root, this.project);
  final Directory root;
  final ProjectManifest project;
  String get path => '${root.path}/project.json';

  static Future<_Fixture> create(int unused) async {
    final root = await Directory.systemTemp.createTemp('l5-player-');
    final project = ProjectManifest(
      name: 'Scoped',
      version: ProjectVersion.v8,
      maps: [
        for (final id in ['a', 'b'])
          ProjectMapEntry(id: id, name: id, relativePath: 'maps/$id.json'),
      ],
      tilesets: [
        for (final id in ['a', 'b'])
          ProjectTilesetEntry(id: id, name: id, relativePath: '$id.png'),
        for (var i = 0; i < unused; i++)
          ProjectTilesetEntry(
            id: 'unused-$i',
            name: '$i',
            relativePath: 'missing-$i.png',
          ),
      ],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.dualRead,
        records: [],
        legacyClaims: [],
      ),
    );
    final fixture = _Fixture(root, project);
    await Directory('${root.path}/maps').create();
    for (final id in ['a', 'b']) {
      await File('${root.path}/maps/$id.json').writeAsString(
        jsonEncode(
          MapData(
            id: id,
            name: id,
            tilesetId: id,
            size: const GridSize(width: 2, height: 2),
          ).toJson(),
        ),
      );
      await File('${root.path}/$id.png').writeAsBytes(
        img.encodePng(
          img.Image(width: 2, height: 2)..setPixelRgba(0, 0, 100, 200, 50, 255),
        ),
      );
    }
    await fixture.publish(project);
    return fixture;
  }

  Future<void> publish(ProjectManifest project) async {
    final publication = PortableCatalogPublication.encodeProject(project);
    for (final object in publication.storage.objects.entries) {
      final file = File('${root.path}/catalog/objects/${object.key}.json');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(object.value);
    }
    await File(path).writeAsString(jsonEncode(publication.descriptor));
  }

  Future<void> dispose() => root.delete(recursive: true);
}
