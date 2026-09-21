import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_player_ui/presentation_renderer.dart';

void main() {
  late Directory root;
  final catalog = ProjectMediaCatalog(entries: [
    ProjectMediaAsset(
      id: 'hero',
      label: 'Illustration',
      kind: ProjectMediaKind.image,
      sourceAssetId: 'hero-source',
    ),
  ]);
  setUp(() async {
    root = await Directory.systemTemp.createTemp('ui11_directory_media_');
  });
  tearDown(() => root.delete(recursive: true));

  Future<void> writeRegistry(Object value) async {
    final file = File('${root.path}/assets/.pokemap-assets.json');
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(value));
  }

  Future<ProjectDirectoryPresentationMedia?> load({bool tolerant = false}) =>
      loadProjectDirectoryPresentationMedia(
        projectRootDirectory: root.path,
        suppliedCatalog: catalog,
        allowMissingSources: tolerant,
      );

  test('supplied catalog avoids media file and defaults to strict sources',
      () async {
    expect(
        await loadProjectDirectoryPresentationMedia(
          projectRootDirectory: root.path,
        ),
        isNull);
    await expectLater(
        load(), throwsA(isA<ProjectDirectoryPresentationMediaException>()));
    final result = await load(tolerant: true);
    expect(result!.catalog, same(catalog));
    expect(result.mediaUris, isEmpty);
    expect(root.listSync(), isEmpty);
  });

  test('missing records and blobs are local only when explicitly requested',
      () async {
    await writeRegistry({'schemaVersion': 1, 'records': []});
    await expectLater(
        load(), throwsA(isA<ProjectDirectoryPresentationMediaException>()));
    expect((await load(tolerant: true))!.mediaUris, isEmpty);
    final digest = List.filled(64, 'a').join();
    await writeRegistry({
      'schemaVersion': 1,
      'records': [
        {
          'id': 'hero-source',
          'artifact': {'digest': 'sha256:$digest'}
        },
      ],
    });
    await expectLater(
        load(), throwsA(isA<ProjectDirectoryPresentationMediaException>()));
    expect((await load(tolerant: true))!.mediaUris, isEmpty);
    final blob = File('${root.path}/assets/.pokemap-store/$digest.blob');
    await blob.parent.create(recursive: true);
    await blob.writeAsBytes([1, 2, 3]);
    expect((await load())!.mediaUris['hero'], blob.uri);
  });

  test('malformed asset catalog is never silently accepted', () async {
    await writeRegistry({'schemaVersion': 2, 'records': []});
    await expectLater(load(tolerant: true),
        throwsA(isA<ProjectDirectoryPresentationMediaException>()));
    await writeRegistry({
      'schemaVersion': 1,
      'records': [
        {
          'id': 'hero-source',
          'artifact': {'digest': 'invalid'}
        }
      ]
    });
    await expectLater(load(tolerant: true),
        throwsA(isA<ProjectDirectoryPresentationMediaException>()));
  });
}
