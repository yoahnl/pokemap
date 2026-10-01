import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'map_catalog_fixture.dart';

void main() {
  late MapCatalogFixture fixture;
  setUp(() async => fixture = await MapCatalogFixture.create());
  tearDown(() => fixture.dispose());

  test('preparing and abandoning a duplicate writes no project file', () async {
    final before = await _files(fixture.root);
    final source = fixture.controller.active!;
    final prepared = await fixture.controller.prepareCatalog('map.duplicate', {
      'sourceMapId': source.base.mapId,
      'name': '${source.current.name} — copie',
    });
    expect(prepared.canApply, isTrue, reason: '${prepared.issues}');
    expect(prepared.sourceMap, source.current);
    expect(await _files(fixture.root), before);
    expect(fixture.controller.active, same(source));
    expect(fixture.catalog.mutations, 0);
  });

  test(
    'duplicate destination may change without replacing the captured revision',
    () async {
      final source = fixture.controller.active!;
      final prepared = await fixture.controller.prepareCatalog(
        'map.duplicate',
        {'sourceMapId': source.base.mapId, 'name': 'Copie proposée'},
      );
      final destination = prepared.withDuplicateDestination(
        name: 'La nouvelle copie',
        groupId: null,
      );
      expect(destination.snapshotRevision, prepared.snapshotRevision);
      expect(destination.targetMapId, source.base.mapId);
      final result = await fixture.controller.applyPreparedCatalog(destination);
      expect(result.integrated, isTrue, reason: result.error);
      final copy = fixture.controller.project!.maps.singleWhere(
        (entry) => entry.id == result.receipt!.createdMapId,
      );
      expect(copy.name, 'La nouvelle copie');
      expect(copy.groupId, isNull);
    },
  );

  test(
    'a changed closed map invalidates a resize analysis before writing',
    () async {
      final source = fixture.controller.active!;
      final prepared = await fixture.controller
          .prepareCatalog('map.resize_apply', {
            'mapId': source.base.mapId,
            'width': source.current.size.width + 3,
            'height': source.current.size.height + 2,
          });
      expect(prepared.canApply, isTrue);
      final neighbour = fixture.controller.project!.maps.last;
      final file = File(p.join(fixture.root.path, neighbour.relativePath));
      final map = MapData.fromJson(jsonDecode(await file.readAsString()));
      await file.writeAsString(
        jsonEncode(map.copyWith(properties: {'concurrent': true}).toJson()),
      );
      final afterExternalChange = await _files(fixture.root);
      final result = await fixture.controller.applyPreparedCatalog(prepared);
      expect(result.published, isFalse);
      expect(result.error, contains('Relancez'));
      expect(await _files(fixture.root), afterExternalChange);
      expect(source.current.size, prepared.sourceMap.size);
    },
  );

  test(
    'dirty source must be explicitly saved before duplicate preparation',
    () async {
      final source = fixture.controller.active!;
      source.commit(source.current.copyWith(properties: {'unsaved': true}));
      final before = await _files(fixture.root);
      await expectLater(
        fixture.controller.prepareCatalog('map.duplicate', {
          'sourceMapId': source.base.mapId,
          'name': 'Copie',
        }),
        throwsA(
          isA<MapWorkspaceFailure>().having(
            (failure) => failure.message,
            'message',
            contains('Enregistrez'),
          ),
        ),
      );
      expect(source.dirty, isTrue);
      expect(await _files(fixture.root), before);
      expect(await fixture.controller.save(source), isTrue);
      final prepared = await fixture.controller.prepareCatalog(
        'map.duplicate',
        {'sourceMapId': source.base.mapId, 'name': 'Copie'},
      );
      expect(prepared.sourceMap.properties['unsaved'], isTrue);
    },
  );

  test(
    'dirty incoming passage blocks deletion without saving its owner',
    () async {
      final source = fixture.controller.active!;
      final target = fixture.controller.project!.maps.last;
      source.commit(
        source.current.copyWith(
          warps: [
            MapWarp(
              id: 'unsaved-incoming',
              pos: const GridPos(x: 2, y: 2),
              targetMapId: target.id,
              targetPos: const GridPos(x: 1, y: 1),
            ),
          ],
        ),
      );
      final before = await _files(fixture.root);
      await expectLater(
        fixture.controller.prepareCatalog('map.delete_apply', {
          'mapId': target.id,
        }),
        throwsA(
          isA<MapWorkspaceFailure>().having(
            (failure) => failure.message,
            'message',
            contains(source.current.name),
          ),
        ),
      );
      expect(source.dirty, isTrue);
      expect(await _files(fixture.root), before);
      expect(fixture.controller.active, same(source));
    },
  );

  test(
    'same size is a no-op that preserves source bytes and geometry history',
    () async {
      final source = fixture.controller.active!;
      source.commit(source.current.copyWith(properties: {'history': true}));
      expect(await fixture.controller.save(source), isTrue);
      final path = fixture.controller.project!.maps.first.relativePath;
      final file = File(p.join(fixture.root.path, path));
      final bytes = await file.readAsBytes();
      final inventory = await _files(fixture.root);
      final revision = source.base.revision;
      final prepared = await fixture.controller
          .prepareCatalog('map.resize_apply', {
            'mapId': source.base.mapId,
            'width': source.current.size.width,
            'height': source.current.size.height,
          });
      expect(prepared.noChange, isTrue);
      final result = await fixture.controller.applyPreparedCatalog(prepared);
      expect(result.integrated, isTrue, reason: result.error);
      expect(result.published, isFalse);
      expect(source.base.revision, revision);
      expect(source.canUndo, isTrue);
      expect(await file.readAsBytes(), bytes);
      expect(await _files(fixture.root), inventory);
    },
  );

  test(
    'a stale no-op does not pretend to validate the previous snapshot',
    () async {
      final source = fixture.controller.active!;
      final prepared = await fixture.controller
          .prepareCatalog('map.resize_apply', {
            'mapId': source.base.mapId,
            'width': source.current.size.width,
            'height': source.current.size.height,
          });
      expect(prepared.noChange, isTrue);
      final neighbour = fixture.controller.project!.maps.last;
      final file = File(p.join(fixture.root.path, neighbour.relativePath));
      final map = MapData.fromJson(jsonDecode(await file.readAsString()));
      await file.writeAsString(
        jsonEncode(map.copyWith(properties: {'concurrentNoop': true}).toJson()),
      );
      final beforeApply = await _files(fixture.root);
      final result = await fixture.controller.applyPreparedCatalog(prepared);
      expect(result.published, isFalse);
      expect(result.integrated, isFalse);
      expect(result.error, contains('Relancez'));
      expect(await _files(fixture.root), beforeApply);
    },
  );

  test(
    'missing required map does not produce an unreferenced deletion',
    () async {
      final source = fixture.controller.project!.maps.first;
      final target = fixture.controller.project!.maps.last;
      await File(p.join(fixture.root.path, source.relativePath)).delete();
      final before = await _files(fixture.root);
      await expectLater(
        fixture.controller.prepareCatalog('map.delete_apply', {
          'mapId': target.id,
        }),
        throwsA(anything),
      );
      expect(await _files(fixture.root), before);
      expect(fixture.catalog.mutations, 0);
    },
  );
}

Future<Map<String, List<int>>> _files(Directory root) async => {
  for (final file
      in await root
          .list(recursive: true)
          .where((entry) => entry is File)
          .cast<File>()
          .toList())
    p.relative(file.path, from: root.path): await file.readAsBytes(),
};
