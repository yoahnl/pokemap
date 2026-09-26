import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late ProjectSession session;
  late ProjectManifest manifest;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('studio_render_test_');
    await writeExampleProject(directory);
    final root = await directory.resolveSymbolicLinks();
    session = ProjectSession(
      sessionId: 'test',
      name: 'Example',
      directoryPath: root,
    );
    manifest = ProjectManifest.fromJson(
      jsonDecode(await File('$root/project.json').readAsString())
          as Map<String, dynamic>,
    );
  });
  tearDown(() async => directory.delete(recursive: true));

  test('example is two real maps with atlas, decor and character', () async {
    expect(manifest.maps, hasLength(2));
    expect(manifest.characters.single.animations, hasLength(8));
    expect(manifest.elements, hasLength(3));
    for (final entry in manifest.maps) {
      final map = MapData.fromJson(
        jsonDecode(
              await File(
                '${directory.path}/${entry.relativePath}',
              ).readAsString(),
            )
            as Map<String, dynamic>,
      );
      expect(map.id, entry.id);
      expect(map.layers.whereType<TileLayer>().first.cells, hasLength(384));
      expect(map.placedElements, hasLength(3));
    }
  });

  test(
    'loads once and paints real atlas without reading files again',
    () async {
      final resources = await StudioMapResources.load(session, manifest);
      addTearDown(resources.dispose);
      expect(resources.images, isEmpty);
      final renderer = resources.renderer(exampleMap('test', 'Test'))
        ..update(0);
      resources.setActiveMap(exampleMap('test', 'Test'));
      await resources.settled;
      expect(resources.warnings, isEmpty);
      expect(resources.images, hasLength(1));
      expect(resources.decodedBytes, 160 * 64 * 4);
      await File('${directory.path}/assets/atelier.png').delete();
      final recorder = ui.PictureRecorder();
      renderer.paint(ui.Canvas(recorder));
      final picture = recorder.endRecording();
      final image = await picture.toImage(768, 512);
      picture.dispose();
      final rgba = await image.toByteData();
      image.dispose();
      final offset = (20 * 768 + 20) * 4;
      expect(rgba!.buffer.asUint8List().sublist(offset, offset + 4), [
        104,
        158,
        96,
        255,
      ]);
      final retained = resources.images.values.single;
      await resources.dispose();
      await resources.dispose();
      expect(retained.debugDisposed, isTrue);
      expect(resources.decodedBytes, 0);
    },
  );

  test(
    'budget refuses image before decoding and preserves authored references',
    () async {
      final resources = await StudioMapResources.load(
        session,
        manifest,
        maximumBytes: 4000,
      );
      addTearDown(resources.dispose);
      resources.setActiveMap(exampleMap('test', 'Test'));
      await resources.settled;
      expect(resources.images, isEmpty);
      expect(resources.warnings.single, contains('Atelier libre'));
      expect(manifest.elements.first.tilesetId, 'atelier');
      expect(resources.decodedBytes, 0);
    },
  );

  test('missing resource is local failure and keeps project usable', () async {
    await File('${directory.path}/assets/atelier.png').delete();
    final resources = await StudioMapResources.load(session, manifest);
    addTearDown(resources.dispose);
    resources.setActiveMap(exampleMap('test', 'Test'));
    await resources.settled;
    expect(resources.images, isEmpty);
    expect(resources.warnings, hasLength(1));
    expect(
      () => resources.renderer(exampleMap('test', 'Test')),
      returnsNormally,
    );
  });

  test(
    'invalid Border stays diagnostic and other map visuals remain usable',
    () async {
      final resources = await StudioMapResources.load(session, manifest);
      addTearDown(resources.dispose);
      final source = exampleMap('border-error', 'Border error');
      final map = source.copyWith(
        layers: [
          ...source.layers,
          BorderLayer(
            id: 'broken-border',
            name: 'Broken border',
            content: BorderLayerContent(
              features: [
                BorderFeature(
                  id: 'missing-materialization',
                  name: 'Missing materialization',
                  blueprintId: 'missing-blueprint',
                  seed: BorderSignedInt64.zero,
                  geometry: BorderRegionGeometry(
                    width: 1,
                    height: 1,
                    cells: [true],
                  ),
                  overrides: const [],
                  keepOutRegions: const [],
                ),
              ],
            ),
          ),
        ],
      );
      resources.setActiveMap(map);
      await resources.settled;
      expect(resources.borderPreviewReady, isFalse);
      expect(resources.borderPreviewLoading, isFalse);
      expect(resources.diagnostics.single.resourceId, 'border:${map.id}');
      expect(resources.diagnostics.single.detail, contains('broken-border'));
      final renderer = resources.renderer(map)..update(0);
      final recorder = ui.PictureRecorder();
      renderer.paint(ui.Canvas(recorder));
      final picture = recorder.endRecording();
      final image = await picture.toImage(768, 512);
      image.dispose();
      picture.dispose();
      await resources.retryResources(['border:${map.id}']);
      expect(resources.diagnostics.single.resourceId, 'border:${map.id}');
    },
  );

  test('resource symlink cannot escape project root', () async {
    final outside = await Directory.systemTemp.createTemp('studio_outside_');
    addTearDown(() => outside.delete(recursive: true));
    await File(
      '${directory.path}/assets/atelier.png',
    ).copy('${outside.path}/atlas.png');
    await File('${directory.path}/assets/atelier.png').delete();
    await Link(
      '${directory.path}/assets/atelier.png',
    ).create('${outside.path}/atlas.png');
    final resources = await StudioMapResources.load(session, manifest);
    addTearDown(resources.dispose);
    resources.setActiveMap(exampleMap('test', 'Test'));
    await resources.settled;
    expect(resources.images, isEmpty);
    expect(resources.warnings, hasLength(1));
  });
}
