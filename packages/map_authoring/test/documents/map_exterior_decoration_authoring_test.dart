import '../support/exterior_decoration_fixture.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:typed_data';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late WorkspacePolicy policy;
  setUp(() async {
    final base = Directory(
        '/Users/karim/Library/Caches/AveluneQA/exterior-decoration/authoring');
    await base.create(recursive: true);
    root = await base.createTemp('fixture_');
    await Directory('${root.path}/maps').create();
    await File('${root.path}/maps/shore.json').writeAsString(jsonEncode(MapData(
      id: 'shore',
      name: 'Shore',
      size: const GridSize(width: 256, height: 256),
      version: ProjectVersion.v9,
      spatialScene: MapSpatialScene(width: 256, depth: 256),
    ).toJson()));
    policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
  });
  tearDown(() async => root.delete(recursive: true));
  MapExteriorDecoration definition({int west = 32}) => MapExteriorDecoration(
      mapId: 'shore',
      playableWidth: 256,
      playableDepth: 256,
      west: west,
      east: 32,
      north: 32,
      south: 32);
  ExteriorDecorationSector sector(String id, int x, {int level = 0}) =>
      ExteriorDecorationSector(
          id: id,
          originX: x,
          originZ: 0,
          scene: MapSpatialScene(
              width: 16, depth: 16, heightLevels: List.filled(256, level)));
  Future<MapExteriorDecorationMutation> configure(
          LocalMapExteriorDecorationAuthoring service) async =>
      service.configure(
          projectRoot: root.path,
          mapId: 'shore',
          expectedRevision:
              (await service.inspect(projectRoot: root.path, mapId: 'shore'))
                  .revision,
          decoration: definition(),
          operationId: 'configure');
  test('absent decoration preserves prior map behavior and map bytes',
      () async {
    final mapBytes = await File('${root.path}/maps/shore.json').readAsBytes();
    final snapshot = await LocalMapExteriorDecorationAuthoring(policy: policy)
        .inspect(projectRoot: root.path, mapId: 'shore');
    expect(snapshot.decoration, isNull);
    expect(snapshot.sectorIds, isEmpty);
    expect(await File('${root.path}/maps/shore.json').readAsBytes(), mapBytes);
  });
  test('configure and sector edits reopen with no playable map mutation',
      () async {
    final original = await File('${root.path}/maps/shore.json').readAsBytes();
    final service = LocalMapExteriorDecorationAuthoring(policy: policy);
    final configured = await configure(service);
    final changed = await service.setSector(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: configured.afterRevision,
        sector: sector('west', -16),
        operationId: 'sector');
    final snapshot = await LocalMapExteriorDecorationAuthoring(policy: policy)
        .inspect(projectRoot: root.path, mapId: 'shore');
    expect(snapshot.revision, changed.afterRevision);
    expect(snapshot.decoration!.sectors.single, sector('west', -16));
    expect(snapshot.sectorIds, ['west']);
    expect(await File('${root.path}/maps/shore.json').readAsBytes(), original);
    final manifest = jsonDecode(
        await File('${root.path}/maps/shore.decoration.json')
            .readAsString()) as Map;
    expect((manifest['definition'] as Map)['sectors'], isEmpty);
    expect(await File('${root.path}/maps/shore.decoration/west.json').exists(),
        isTrue);
  });
  test('an empty definition can be cleared and its original bytes restored',
      () async {
    final service = LocalMapExteriorDecorationAuthoring(policy: policy);
    final configured = await configure(service);
    final original =
        await File('${root.path}/maps/shore.decoration.json').readAsBytes();
    final removed = await service.configure(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: configured.afterRevision,
        decoration: null,
        operationId: 'clear');
    expect(
        (await service.inspect(projectRoot: root.path, mapId: 'shore'))
            .decoration,
        isNull);
    await service.undo(
        projectRoot: root.path,
        mapId: 'shore',
        mutation: removed,
        operationId: 'undo_clear');
    expect(await File('${root.path}/maps/shore.decoration.json').readAsBytes(),
        original);
  });
  test('one logical Border spans sectors and persists without touching them',
      () async {
    await WorkingProjectCatalog.create(
        store: await CatalogStorageStore.open(projectRoot: root.path),
        projectId: 'game',
        project: exteriorDecorationFixtureProject(mapId: 'shore'));
    final service = LocalMapExteriorDecorationAuthoring(policy: policy);
    final configured = await configure(service);
    final added = await service.setSector(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: configured.afterRevision,
        sector: sector('west', -16),
        operationId: 'sector');
    final original = await File('${root.path}/maps/shore.decoration/west.json')
        .readAsBytes();
    final border = ExteriorDecorationBorder(
        id: 'coast',
        layerId: 'native_border',
        originX: -16,
        originZ: 0,
        width: 16,
        depth: 128,
        feature: BorderFeature(
            id: 'coast',
            name: 'Coast',
            blueprintId: 'fence',
            seed: BorderSignedInt64.fromInt(42),
            geometry: BorderStrokeGeometry(strokes: [
              BorderStroke(
                  id: 'whole_contour',
                  points: [for (var z = 0; z <= 100; z++) GridPos(x: 1, y: z)],
                  closed: false)
            ]),
            overrides: const [],
            keepOutRegions: const []));
    final changed = await service.setBorder(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: added.afterRevision,
        border: border,
        operationId: 'border');
    final snapshot =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    expect(snapshot.decoration!.borders.single, border);
    expect(snapshot.borderIds, ['coast']);
    expect(
        await File('${root.path}/maps/shore.decoration/west.json')
            .readAsBytes(),
        original);
    final removed = await service.removeBorder(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: changed.afterRevision,
        borderId: 'coast',
        operationId: 'remove_border');
    await service.undo(
        projectRoot: root.path,
        mapId: 'shore',
        mutation: removed,
        operationId: 'undo_border');
    final map = MapData.fromJson(
        jsonDecode(await File('${root.path}/maps/shore.json').readAsString())
            as Map<String, dynamic>);
    expect(
        (await loadMapExteriorDecoration(projectRoot: root.path, map: map))!
            .borders
            .single,
        border);
  });
  test(
      'stale writers and changed playable dimensions preserve current decoration',
      () async {
    final service = LocalMapExteriorDecorationAuthoring(policy: policy);
    final configured = await configure(service);
    final changed = await service.setSector(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: configured.afterRevision,
        sector: sector('west', -16),
        operationId: 'sector');
    await expectLater(
        service.configure(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: configured.afterRevision,
            decoration: definition(west: 16),
            operationId: 'stale'),
        throwsA(isA<FormatException>()));
    await expectLater(
        service.configure(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: changed.afterRevision,
            decoration: MapExteriorDecoration(
                mapId: 'shore', playableWidth: 20, playableDepth: 256),
            operationId: 'dimensions'),
        throwsA(isA<FormatException>()));
    expect(
        (await service.inspect(projectRoot: root.path, mapId: 'shore'))
            .revision,
        changed.afterRevision);
  });
  test('sector removal undo and redo survive authoring reopening', () async {
    final service = LocalMapExteriorDecorationAuthoring(policy: policy);
    final configured = await configure(service);
    final added = await service.setSector(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: configured.afterRevision,
        sector: sector('west', -16),
        operationId: 'sector');
    final removed = await service.removeSector(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: added.afterRevision,
        sectorId: 'west',
        operationId: 'remove');
    expect(
        (await service.inspect(projectRoot: root.path, mapId: 'shore'))
            .sectorIds,
        isEmpty);
    final fresh = LocalMapExteriorDecorationAuthoring(policy: policy);
    final undo = await fresh.undoReceipt(
        projectRoot: root.path,
        mapId: 'shore',
        receiptId: removed.receipt.receiptId,
        expectedRevision: removed.afterRevision,
        operationId: 'undo');
    expect(
        (await fresh.inspect(projectRoot: root.path, mapId: 'shore'))
            .decoration!
            .sectors
            .single,
        sector('west', -16));
    final redo = await fresh.undo(
        projectRoot: root.path,
        mapId: 'shore',
        mutation: undo,
        operationId: 'redo');
    expect(redo.afterRevision, removed.afterRevision);
    expect(await File('${root.path}/maps/shore.decoration/west.json').exists(),
        isFalse);
  });
  test('idempotent replay verifies exact intent', () async {
    final service = LocalMapExteriorDecorationAuthoring(policy: policy);
    final configured = await configure(service);
    final first = await service.setSector(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: configured.afterRevision,
        sector: sector('west', -16),
        operationId: 'sector');
    final replay = await LocalMapExteriorDecorationAuthoring(policy: policy)
        .setSector(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: configured.afterRevision,
            sector: sector('west', -16),
            operationId: 'sector');
    expect(replay.receipt.receiptId, first.receipt.receiptId);
    await expectLater(
        service.setSector(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: configured.afterRevision,
            sector: sector('west', -16, level: 1),
            operationId: 'sector'),
        throwsA(anything));
  });
  test('interrupted promotion requires recovery and resumes once', () async {
    final service = LocalMapExteriorDecorationAuthoring(policy: policy);
    final configured = await configure(service);
    final failing = LocalMapExteriorDecorationAuthoring(
        policy: policy,
        faultInjector: (context) {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        });
    await expectLater(
        failing.setSector(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: configured.afterRevision,
            sector: sector('west', -16),
            operationId: 'crash'),
        throwsA(anything));
    await expectLater(service.inspect(projectRoot: root.path, mapId: 'shore'),
        throwsA(isA<FormatException>()));
    final recovered = await service.setSector(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: configured.afterRevision,
        sector: sector('west', -16),
        operationId: 'crash');
    expect(
        (await service.inspect(projectRoot: root.path, mapId: 'shore'))
            .revision,
        recovered.afterRevision);
  });
  test(
      'every transaction checkpoint preserves or recovers the exact sector intent',
      () async {
    final service = LocalMapExteriorDecorationAuthoring(policy: policy);
    var revision = (await configure(service)).afterRevision;
    var level = 0;
    for (final checkpoint in AuthoringTransactionCheckpoint.values) {
      final next = sector('west', -16, level: level++);
      final operation = 'fault_${checkpoint.name}';
      final failing = LocalMapExteriorDecorationAuthoring(
          policy: policy,
          faultInjector: (context) {
            if (context.checkpoint == checkpoint) {
              throw const AuthoringTransactionSimulatedCrash();
            }
          });
      await expectLater(
          failing.setSector(
              projectRoot: root.path,
              mapId: 'shore',
              expectedRevision: revision,
              sector: next,
              operationId: operation),
          throwsA(anything));
      final recovered = await service.setSector(
          projectRoot: root.path,
          mapId: 'shore',
          expectedRevision: revision,
          sector: next,
          operationId: operation);
      revision = recovered.afterRevision;
      expect(
          (await service.inspect(projectRoot: root.path, mapId: 'shore'))
              .decoration!
              .sectors
              .single,
          next);
    }
  });
  test('selected sector never reads foreign content or accumulated history',
      () async {
    for (final relative in [
      '.pokemap/authoring/history.jsonl',
      '.pokemap/authoring/audit.jsonl',
      '.pokemap/authoring/idempotency.jsonl'
    ]) {
      final file = File('${root.path}/$relative');
      await file.parent.create(recursive: true);
      await file.writeAsString('x' * 2000000);
    }
    var service = LocalMapExteriorDecorationAuthoring(policy: policy);
    final configured = await configure(service);
    final west = await service.setSector(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: configured.afterRevision,
        sector: sector('west', -16),
        operationId: 'west');
    final east = await service.setSector(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: west.afterRevision,
        sector: sector('east', 256),
        operationId: 'east');
    final blocked = <String>[];
    for (final relative in [
      'project.json',
      'maps/foreign.json',
      'maps/shore.decoration/east.json',
      '.pokemap/authoring/history.jsonl',
      '.pokemap/authoring/audit.jsonl',
      '.pokemap/authoring/idempotency.jsonl',
      '.pokemap/authoring/transactions/foreign/journal.json'
    ]) {
      final file = File('${root.path}/$relative');
      await file.parent.create(recursive: true);
      if (!await file.exists()) await file.writeAsString('x' * 2000000);
      blocked.add(file.path);
    }
    final zone = Zone.current;
    final attempts = <String>[];
    var revision = east.afterRevision;
    await IOOverrides.runZoned(() async {
      service = LocalMapExteriorDecorationAuthoring(policy: policy);
      for (var i = 1; i <= 3; i++) {
        final changed = await service.setSector(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: revision,
            sector: sector('west', -16, level: i),
            operationId: 'bounded_$i');
        revision = changed.afterRevision;
        final snapshot = await service.inspect(
            projectRoot: root.path, mapId: 'shore', sectorIds: ['west']);
        expect(snapshot.decoration!.sectors.single.scene.heightLevels.first, i);
        expect(snapshot.sectorIds, ['west', 'east']);
      }
    }, createFile: (path) {
      final file = zone.run(() => File(path));
      return blocked.contains(path) ? _UnreadableFile(file, attempts) : file;
    });
    expect(attempts, isEmpty);
  });
  test('corrupt required sectors cannot be overwritten', () async {
    final service = LocalMapExteriorDecorationAuthoring(policy: policy);
    final configured = await configure(service);
    final added = await service.setSector(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: configured.afterRevision,
        sector: sector('west', -16),
        operationId: 'west');
    final file = File('${root.path}/maps/shore.decoration/west.json');
    await file.writeAsString('corrupt');
    await expectLater(service.inspect(projectRoot: root.path, mapId: 'shore'),
        throwsA(isA<FormatException>()));
    await expectLater(
        service.setSector(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: added.afterRevision,
            sector: sector('west', -16, level: 1),
            operationId: 'overwrite'),
        throwsA(isA<FormatException>()));
    expect(await file.readAsString(), 'corrupt');
  });
  test(
      'read-only loading creates no authoring files and requires all indexed sectors',
      () async {
    final service = LocalMapExteriorDecorationAuthoring(policy: policy);
    final configured = await configure(service);
    await service.setSector(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: configured.afterRevision,
        sector: sector('west', -16),
        operationId: 'sector');
    final map = MapData.fromJson(
        jsonDecode(await File('${root.path}/maps/shore.json').readAsString())
            as Map<String, dynamic>);
    await Directory('${root.path}/.pokemap').delete(recursive: true);
    final loaded =
        await loadMapExteriorDecoration(projectRoot: root.path, map: map);
    expect(loaded!.sectors.single, sector('west', -16));
    expect(await Directory('${root.path}/.pokemap').exists(), isFalse);
    await File('${root.path}/maps/shore.decoration/west.json').delete();
    await expectLater(
        loadMapExteriorDecoration(projectRoot: root.path, map: map),
        throwsA(isA<FormatException>()));
  });
  test('unchanged sectors and unrelated project growth do not add work',
      () async {
    final counters = _Counters();
    final service = LocalMapExteriorDecorationAuthoring(
        policy: policy, performanceObserver: counters);
    final configured = await configure(service);
    final added = await service.setSector(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: configured.afterRevision,
        sector: sector('west', -16),
        operationId: 'sector');
    counters.values.clear();
    final first = await service.setSector(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: added.afterRevision,
        sector: sector('west', -16, level: 1),
        operationId: 'edit_1');
    final baseline = Map<String, int>.from(counters.values);
    for (var i = 0; i < 50; i++) {
      await File('${root.path}/maps/unrelated_$i.json')
          .writeAsString('x' * 20000);
    }
    counters.values.clear();
    await service.setSector(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: first.afterRevision,
        sector: sector('west', -16, level: 2),
        operationId: 'edit_2');
    expect(counters.values, baseline);
    expect(baseline[AuthoringPerformanceCounterName.filesystemRead],
        greaterThan(0));
  });
  test('future schema and symlinked definitions are preserved', () async {
    final service = LocalMapExteriorDecorationAuthoring(policy: policy);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final file = File('${root.path}/maps/shore.decoration.json');
    await file
        .writeAsString('{"schemaVersion":999,"definition":{},"sectors":[]}');
    final original = await file.readAsString();
    await expectLater(
        service.configure(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            decoration: definition(),
            operationId: 'future'),
        throwsA(isA<FormatException>()));
    expect(await file.readAsString(), original);
    await file.delete();
    final protected = File('${root.path}/protected.json');
    await protected.writeAsString('preserve');
    await Link(file.path).create(protected.path);
    await expectLater(
        service.configure(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            decoration: definition(),
            operationId: 'symlink'),
        throwsA(anything));
    expect(await protected.readAsString(), 'preserve');
  });
  test('playable map changes during commit reject decoration writes', () async {
    final service = LocalMapExteriorDecorationAuthoring(policy: policy);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    await expectLater(
        service.configure(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            decoration: definition(),
            operationId: 'race',
            precondition: () => File('${root.path}/maps/shore.json')
                .writeAsString('changed externally')),
        throwsA(anything));
    expect(await File('${root.path}/maps/shore.decoration.json').exists(),
        isFalse);
  });
  test('JSONL discovers and transports sector configure set remove and undo',
      () async {
    final handles = WorkspaceHandleStore();
    final loader = ProjectSnapshotLoader(handles: handles);
    final worker = JsonlWorker(
        api: AuthoringReadApi(
            openService: ProjectOpenService(
                policy: policy,
                fileReader: const LocalProjectFileReader(),
                handles: handles),
            snapshotLoader: loader),
        mapExteriorDecoration:
            LocalMapExteriorDecorationAuthoring(policy: policy));
    addTearDown(worker.close);
    var sequence = 0;
    Future<Map<String, dynamic>> call(
        String command, Map<String, Object?> args) async {
      final result = jsonDecode(await worker.processLine(jsonEncode({
        'id': 'decoration_${sequence++}',
        'command': command,
        'args': args
      }))) as Map<String, dynamic>;
      expect(result['status'], 'success', reason: jsonEncode(result));
      return result['data'] as Map<String, dynamic>;
    }

    final description = await call('describe', {});
    expect(
        (description['mapExteriorDecorationAuthoring'] as List)
            .map((v) => (v as Map)['id']),
        containsAll([
          'map.exteriorDecoration.configure',
          'map.exteriorDecoration.sector.set',
          'map.exteriorDecoration.sector.remove'
        ]));
    final base = <String, Object?>{'projectRoot': root.path, 'mapId': 'shore'};
    final initial = await call('map_exterior_decoration_inspect', base);
    final configured = await call('map_exterior_decoration_configure', {
      ...base,
      'expectedRevision': initial['revision'],
      'decoration': definition().toJson(),
      'operationId': 'configure'
    });
    final added = await call('map_exterior_decoration_sector_set', {
      ...base,
      'expectedRevision': configured['afterRevision'],
      'sector': sector('west', -16).toJson(),
      'operationId': 'sector'
    });
    final selected = await call('map_exterior_decoration_inspect', {
      ...base,
      'sectorIds': ['west']
    });
    expect(((selected['decoration'] as Map)['sectors'] as List).single,
        sector('west', -16).toJson());
    final removed = await call('map_exterior_decoration_sector_remove', {
      ...base,
      'expectedRevision': added['afterRevision'],
      'sectorId': 'west',
      'operationId': 'remove'
    });
    await call('map_exterior_decoration_undo', {
      ...base,
      'expectedRevision': removed['afterRevision'],
      'receiptId': (removed['receipt'] as Map)['receiptId'],
      'operationId': 'undo'
    });
    expect((await call('map_exterior_decoration_inspect', base))['sectorIds'],
        ['west']);
  });
  test(
      'semantic native edits share canonical closure and stable Border ownership',
      () async {
    final store = await CatalogStorageStore.open(projectRoot: root.path);
    await WorkingProjectCatalog.create(
        store: store,
        projectId: 'game',
        project: exteriorDecorationFixtureProject(mapId: 'shore'));
    final service = LocalMapExteriorDecorationAuthoring(policy: policy);
    final configured = await configure(service);
    final added = await service.setSector(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: configured.afterRevision,
        sector: sector('west', -16),
        operationId: 'blank_sector');
    final catalog = await service.inspectNativeCatalogRevision(
        projectRoot: root.path, mapId: 'shore');
    final changed = await service.nativeEdit(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: added.afterRevision,
        expectedCatalogRevision: catalog,
        operationId: 'native_tree',
        edit: {
          'kind': 'environment.generate',
          'sectorId': 'west',
          'presetId': 'forest',
          'areaId': 'trees',
          'seed': 42,
          'cells': [
            {'x': -8, 'z': 8}
          ]
        });
    final snapshot =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    expect(snapshot.revision, changed.afterRevision);
    expect(
        snapshot.decoration!.sectors.single.layers
            .whereType<EnvironmentLayer>()
            .single
            .content
            .areas
            .single
            .presetId,
        'forest');
    expect(snapshot.decoration!.sectors.single.scene.instances, isNotEmpty);
    final terrain = await service.nativeEdit(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: changed.afterRevision,
        expectedCatalogRevision: catalog,
        operationId: 'native_ground',
        edit: {
          'kind': 'terrain.paint',
          'sectorId': 'west',
          'presetId': 'grass',
          'cells': [
            {'x': -8, 'z': 8}
          ]
        });
    final painted =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    expect(
        painted.decoration!.sectors.single.layers
            .whereType<SmartTileLayer>()
            .single
            .animationActivation,
        SmartTileAnimationActivation.always);
    expect(painted.decoration!.sectors.single.scene.instances, isNotEmpty);
    final firstBorder = await service.nativeEdit(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: terrain.afterRevision,
        expectedCatalogRevision: catalog,
        operationId: 'native_border',
        edit: {
          'kind': 'border.draw',
          'blueprintId': 'fence',
          'borderId': 'fence_owner',
          'seed': '42',
          'points': [
            {'x': -8, 'z': 4},
            {'x': -8, 'z': 40}
          ]
        });
    final beforeBorder =
        (await service.inspect(projectRoot: root.path, mapId: 'shore'))
            .decoration!
            .borders
            .single;
    final extended = await service.nativeEdit(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: firstBorder.afterRevision,
        expectedCatalogRevision: catalog,
        operationId: 'extend_border',
        edit: {
          'kind': 'border.draw',
          'blueprintId': 'fence',
          'borderId': 'fence_owner',
          'seed': '42',
          'points': [
            {'x': -8, 'z': 1},
            {'x': -8, 'z': 44}
          ]
        });
    final afterBorder =
        (await service.inspect(projectRoot: root.path, mapId: 'shore'))
            .decoration!
            .borders
            .single;
    expect(afterBorder.originX, beforeBorder.originX);
    expect(afterBorder.originZ, beforeBorder.originZ);
    expect(afterBorder.width, beforeBorder.width);
    expect(afterBorder.depth, beforeBorder.depth);
    final byPosition = {
      for (final item in afterBorder.instances)
        (item.position.x, item.position.z): item
    };
    final unchanged = beforeBorder.instances
        .where((v) =>
            v.position.z > 40 &&
            v.position.z < 65 &&
            byPosition.containsKey((v.position.x, v.position.z)))
        .toList();
    expect(unchanged, isNotEmpty);
    for (final item in unchanged) {
      expect(byPosition[(item.position.x, item.position.z)]!.id, item.id);
      expect(byPosition[(item.position.x, item.position.z)]!.modelId,
          item.modelId);
    }
    final erased = await service.nativeEdit(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: extended.afterRevision,
        expectedCatalogRevision: catalog,
        operationId: 'erase_border',
        edit: {
          'kind': 'border.erase',
          'borderId': 'fence_owner',
          'cells': [
            {'x': -8, 'z': 12}
          ]
        });
    final afterErase =
        (await service.inspect(projectRoot: root.path, mapId: 'shore'))
            .decoration!
            .borders
            .single;
    expect(afterErase.originX, afterBorder.originX);
    expect(afterErase.originZ, afterBorder.originZ);
    expect(afterErase.feature.geometry, isNot(afterBorder.feature.geometry));
    await expectLater(
        service.nativeEdit(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: erased.afterRevision,
            expectedCatalogRevision: 'sha256:${'f' * 64}',
            operationId: 'stale_catalog',
            edit: {
              'kind': 'environment.generate',
              'sectorId': 'west',
              'presetId': 'forest',
              'areaId': 'trees',
              'seed': 42,
              'cells': [
                {'x': -7, 'z': 8}
              ]
            }),
        throwsA(isA<FormatException>()));
  });
  test('legacy dotted and Unicode identities without a decoration still load',
      () async {
    for (final id in ['route.30', 'forêt_été']) {
      final map = MapData(
          id: id,
          name: id,
          size: const GridSize(width: 2, height: 2),
          version: ProjectVersion.v9,
          spatialScene: MapSpatialScene(width: 2, depth: 2));
      expect(await loadMapExteriorDecoration(projectRoot: root.path, map: map),
          isNull);
      final file = File('${root.path}/maps/$id.decoration.json');
      await file.writeAsString('corrupt_declared_document');
      await expectLater(
          loadMapExteriorDecoration(projectRoot: root.path, map: map),
          throwsA(isA<FormatException>()));
      expect(await file.readAsString(), 'corrupt_declared_document');
    }
  });
  test('legacy map paths containing decoration remain valid source documents',
      () async {
    final bytes = await File('${root.path}/maps/shore.json').readAsBytes();
    final service = LocalMapExteriorDecorationAuthoring(policy: policy);
    for (final path in [
      'maps/shore.decoration.notes.json',
      'custom.decoration/maps/shore.json'
    ]) {
      final file = File('${root.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      final state = await service.inspect(
          projectRoot: root.path, mapId: 'shore', mapRelativePath: path);
      final changed = await service.configure(
          projectRoot: root.path,
          mapId: 'shore',
          mapRelativePath: path,
          expectedRevision: state.revision,
          decoration: definition(west: path.startsWith('maps/') ? 31 : 30),
          operationId:
              path.startsWith('maps/') ? 'named_path' : 'directory_path');
      expect(changed.afterRevision, isNot(state.revision));
      expect(await file.readAsBytes(), bytes);
    }
  });
  test(
      'raw writers reject missing and foreign visual references before persistence',
      () async {
    final project = exteriorDecorationFixtureProject(mapId: 'shore');
    await WorkingProjectCatalog.create(
        store: await CatalogStorageStore.open(projectRoot: root.path),
        projectId: 'game',
        project: project.copyWith(
            maps: [
              ...project.maps,
              const ProjectMapEntry(
                  id: 'other', name: 'Other', relativePath: 'maps/other.json')
            ],
            resourceLibraryCatalog: ResourceLibraryCatalog(entries: [
              ResourceLibraryEntry(
                  resourceKind: 'model3d', resourceId: 'oak', mapId: 'other')
            ])));
    final service = LocalMapExteriorDecorationAuthoring(policy: policy);
    final configured = await configure(service);
    final bytes =
        await File('${root.path}/maps/shore.decoration.json').readAsBytes();
    for (final id in ['missing_model', 'oak']) {
      final candidate = ExteriorDecorationSector(
          id: 'west',
          originX: -16,
          originZ: 0,
          scene: MapSpatialScene(width: 16, depth: 16, instances: [
            SpatialModelInstance(
                id: 'instance',
                modelId: id,
                position: Model3dVector3(x: 4, y: 0, z: 4))
          ]));
      await expectLater(
          service.setSector(
              projectRoot: root.path,
              mapId: 'shore',
              expectedRevision: configured.afterRevision,
              sector: candidate,
              operationId: 'blocked_$id'),
          throwsA(anything));
      expect(
          await File('${root.path}/maps/shore.decoration.json').readAsBytes(),
          bytes);
      expect(
          await File('${root.path}/maps/shore.decoration/west.json').exists(),
          isFalse);
    }
  });
}

final class _Counters implements AuthoringPerformanceObserver {
  final values = <String, int>{};
  @override
  void incrementCounter(String name, {int by = 1}) =>
      values.update(name, (v) => v + by, ifAbsent: () => by);
  @override
  AuthoringPerformanceSpan? startSpan(String name) => null;
}

final class _UnreadableFile implements File {
  _UnreadableFile(this.delegate, this.attempts);
  final File delegate;
  final List<String> attempts;
  Never deny() {
    attempts.add(path);
    throw StateError('Unrelated file read: $path');
  }

  @override
  String get path => delegate.path;
  @override
  Uri get uri => delegate.uri;
  @override
  bool get isAbsolute => delegate.isAbsolute;
  @override
  File get absolute => delegate.absolute;
  @override
  Directory get parent => delegate.parent;
  @override
  Future<Uint8List> readAsBytes() async => deny();
  @override
  Future<String> readAsString({Encoding encoding = utf8}) async => deny();
  @override
  Stream<List<int>> openRead([int? start, int? end]) => deny();
  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) async =>
      deny();
  @override
  Future<bool> exists() => delegate.exists();
  @override
  Future<FileStat> stat() => delegate.stat();
  @override
  Future<String> resolveSymbolicLinks() => delegate.resolveSymbolicLinks();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
