import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_authoring/src/transactions/journaled_transaction.dart';
import 'package:map_authoring/src/documents/map_document_write_lock.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;
  late WorkspacePolicy policy;
  late File mapFile;
  late Map<String, dynamic> original;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('element_order_');
    root = Directory(await root.resolveSymbolicLinks());
    await Directory('${root.path}/maps').create();
    mapFile = File('${root.path}/maps/shore.json');
    original = MapData(
        id: 'shore',
        name: 'Shore',
        size: const GridSize(width: 1, height: 1),
        layers: const [
          TileLayer(id: 'rear', name: 'Rear', cells: [0]),
          TileLayer(id: 'front', name: 'Front', cells: [0]),
          ObjectLayer(id: 'markers', name: 'Markers'),
        ],
        placedElements: [
          for (final (index, id) in ['a', 'b', 'c'].indexed)
            MapPlacedElement(
                id: id,
                layerId: 'front',
                elementId: 'mist',
                pos: const GridPos(x: 0, y: 0),
                visualOrder: index),
          const MapPlacedElement(
              id: 'untouched',
              layerId: 'rear',
              elementId: 'tree',
              pos: GridPos(x: 0, y: 0),
              visualOrder: 91),
        ]).toJson();
    original['futureOptionalPresentation'] = {
      'keep': [1, 2, 3]
    };
    (original['layers'] as List).first['futureLayerDetail'] = {'keep': 'layer'};
    (original['placedElements'] as List).first['futureDecorDetail'] = {
      'keep': 'decor'
    };
    await mapFile.writeAsString(jsonEncode(original));
    await File('${root.path}/project.json').writeAsString('do not read');
    policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
  });
  tearDown(() => root.delete(recursive: true));

  test(
      'front-first layers preserve legacy direction and unknown document fields',
      () async {
    for (final legacy in [false, true]) {
      final raw = {
        ...original,
        if (legacy) 'properties': {'tileLayerOrder': 'bottom_to_top'}
      };
      await mapFile.writeAsString(jsonEncode(raw));
      final service = LocalMapElementOrderAuthoring(policy: policy);
      final before =
          await service.inspect(projectRoot: root.path, mapId: 'shore');
      final result = await service.reorder(
          projectRoot: root.path,
          mapId: 'shore',
          expectedRevision: before.revision,
          kind: 'layers',
          frontFirstIds: ['front', 'markers', 'rear'],
          operationId: 'layers_$legacy');
      expect(result.afterMap.layers.map((layer) => layer.id),
          legacy ? ['rear', 'markers', 'front'] : ['front', 'markers', 'rear']);
      final written = jsonDecode(await mapFile.readAsString()) as Map;
      expect(written['futureOptionalPresentation'],
          raw['futureOptionalPresentation']);
      expect(
          (written['layers'] as List).singleWhere(
              (layer) => layer['id'] == 'rear')['futureLayerDetail'],
          {'keep': 'layer'});
      expect(written['placedElements'], raw['placedElements']);
      expect(result.fileRevision,
          narrativeEventBytesFingerprint(await mapFile.readAsBytes()));
      final undone = await service.undo(
          projectRoot: root.path,
          mapId: 'shore',
          mutation: result,
          operationId: 'undo_$legacy');
      expect(undone.afterMap.layers, before.map.layers);
      expect(jsonDecode(await mapFile.readAsString()), raw);
    }
  });

  test(
      'decor ranks are front first within one tile layer without dropping data',
      () async {
    final service = LocalMapElementOrderAuthoring(policy: policy);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final result = await service.reorder(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        kind: 'decor',
        layerId: 'front',
        frontFirstIds: ['a', 'c', 'b'],
        operationId: 'decor');
    expect(
        sortMapPlacedElementsForPainting(result.afterMap.placedElements
            .where((e) => e.layerId == 'front')).reversed.map((e) => e.id),
        ['a', 'c', 'b']);
    expect(result.afterMap.placedElements.last, before.map.placedElements.last);
    final written = jsonDecode(await mapFile.readAsString()) as Map;
    expect(written['layers'], original['layers']);
    expect((written['placedElements'] as List).first['futureDecorDetail'],
        {'keep': 'decor'});
    expect(result.afterMap.placedElements.map((e) => e.id),
        before.map.placedElements.map((e) => e.id));
    final replay = await service.reorder(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        kind: 'decor',
        layerId: 'front',
        frontFirstIds: ['a', 'c', 'b'],
        operationId: 'decor');
    expect(replay.receipt.receiptId, result.receipt.receiptId);
    await expectLater(
        service.reorder(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            kind: 'decor',
            layerId: 'front',
            frontFirstIds: ['b', 'a', 'c'],
            operationId: 'stale'),
        throwsFormatException);
  });

  test(
      'invalid permutations unknown versions and no-op preserve original bytes',
      () async {
    final service = LocalMapElementOrderAuthoring(policy: policy);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final initial = await mapFile.readAsBytes();
    for (final ids in [
      ['rear', 'front'],
      ['rear', 'front', 'front'],
      ['rear', 'front', 'missing'],
      ['rear', 'front', 'markers']
    ]) {
      await expectLater(
          service.reorder(
              projectRoot: root.path,
              mapId: 'shore',
              expectedRevision: before.revision,
              kind: 'layers',
              frontFirstIds: ids,
              operationId: 'bad_${ids.join('_')}'),
          throwsFormatException);
      expect(await mapFile.readAsBytes(), initial);
    }
    await mapFile.writeAsString(jsonEncode({...original, 'version': 'v10'}));
    final future = await mapFile.readAsBytes();
    await expectLater(service.inspect(projectRoot: root.path, mapId: 'shore'),
        throwsFormatException);
    expect(await mapFile.readAsBytes(), future);
  });

  test(
      'cold reorder and receipt undo never read unrelated project or global history',
      () async {
    final blocked = <String>[];
    for (final relative in [
      'project.json',
      'maps/other.json',
      '.pokemap/authoring/history.jsonl',
      '.pokemap/authoring/audit.jsonl',
      '.pokemap/authoring/idempotency.jsonl',
      '.pokemap/authoring/transactions/foreign/journal.json'
    ]) {
      final file = File('${root.path}/$relative');
      await file.parent.create(recursive: true);
      await file.writeAsString('x' * 2000000);
      blocked.add(file.path);
    }
    final outside = Zone.current;
    final attempts = <String>[];
    await IOOverrides.runZoned(() async {
      final service = LocalMapElementOrderAuthoring(policy: policy);
      final before =
          await service.inspect(projectRoot: root.path, mapId: 'shore');
      final result = await service.reorder(
          projectRoot: root.path,
          mapId: 'shore',
          expectedRevision: before.revision,
          kind: 'decor',
          layerId: 'front',
          frontFirstIds: ['a', 'c', 'b'],
          operationId: 'bounded');
      await service.undo(
          projectRoot: root.path,
          mapId: 'shore',
          mutation: result,
          operationId: 'bounded_undo');
    }, createFile: (path) {
      final file = outside.run(() => File(path));
      return blocked.contains(file.path)
          ? _UnreadableFile(file, attempts)
          : file;
    });
    expect(attempts, isEmpty);
  });

  test('crashed reorder resumes the same intent without losing raw metadata',
      () async {
    final service = LocalMapElementOrderAuthoring(policy: policy);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final crash = LocalMapElementOrderAuthoring(
        policy: policy,
        faultInjector: (context) {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted) {
            throw const AuthoringTransactionSimulatedCrash();
          }
        });
    await expectLater(
        crash.reorder(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            kind: 'layers',
            frontFirstIds: ['front', 'markers', 'rear'],
            operationId: 'resume'),
        throwsA(anything));
    final result = await service.reorder(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        kind: 'layers',
        frontFirstIds: ['front', 'markers', 'rear'],
        operationId: 'resume');
    expect(result.afterMap.layers.first.id, 'front');
    expect(
        (jsonDecode(await mapFile.readAsString())
            as Map)['futureOptionalPresentation'],
        original['futureOptionalPresentation']);
  });

  test('order transactions share the native map writer lock', () async {
    final service = LocalMapElementOrderAuthoring(policy: policy);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final initial = await mapFile.readAsBytes();
    late Future<MapElementOrderMutation> pending;
    await withMapDocumentWriteLock(mapFile.path, (_) async {
      pending = service.reorder(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        kind: 'layers',
        frontFirstIds: ['front', 'markers', 'rear'],
        operationId: 'locked',
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(await mapFile.readAsBytes(), initial);
    });
    expect((await pending).afterMap.layers.first.id, 'front');
  });

  test('pending native save and same decoration order reject without mutation',
      () async {
    final service = LocalMapElementOrderAuthoring(policy: policy);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final initial = await mapFile.readAsBytes();
    await expectLater(
        service.reorder(
          projectRoot: root.path,
          mapId: 'shore',
          expectedRevision: before.revision,
          kind: 'decor',
          layerId: 'front',
          frontFirstIds: ['c', 'b', 'a'],
          operationId: 'no_change',
        ),
        throwsFormatException);
    final identity =
        narrativeEventBytesFingerprint(utf8.encode(p.normalize(mapFile.path)))
            .substring(7, 31);
    final journal = File(
        p.join(mapFile.parent.path, '.pokemap-map-$identity.journal.json'));
    await journal.writeAsString('pending native recovery');
    await expectLater(
        service.reorder(
          projectRoot: root.path,
          mapId: 'shore',
          expectedRevision: before.revision,
          kind: 'layers',
          frontFirstIds: ['front', 'markers', 'rear'],
          operationId: 'native_pending',
        ),
        throwsFormatException);
    expect(await mapFile.readAsBytes(), initial);
    expect(await journal.readAsString(), 'pending native recovery');
  });
  test('cold order worker preserves raw data replay conflict and undo',
      () async {
    final service =
        LocalMapElementOrderAuthoring(policy: policy, runInWorker: true);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final result = await service.reorder(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        kind: 'layers',
        frontFirstIds: ['front', 'markers', 'rear'],
        operationId: 'worker_order');
    final replay = await service.reorder(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        kind: 'layers',
        frontFirstIds: ['front', 'markers', 'rear'],
        operationId: 'worker_order');
    expect(replay.receipt.receiptId, result.receipt.receiptId);
    await expectLater(
        service.reorder(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            kind: 'layers',
            frontFirstIds: ['markers', 'rear', 'front'],
            operationId: 'worker_stale'),
        throwsFormatException);
    final undone = await service.undo(
        projectRoot: root.path,
        mapId: 'shore',
        mutation: result,
        operationId: 'worker_order_undo');
    expect(undone.afterMap, before.map);
    final raw = jsonDecode(await mapFile.readAsString()) as Map;
    expect(raw['futureOptionalPresentation'],
        original['futureOptionalPresentation']);
    expect(
        (raw['layers'] as List).first['futureLayerDetail'], {'keep': 'layer'});
  });

  test('order worker waits for the native host map queue', () async {
    final service =
        LocalMapElementOrderAuthoring(policy: policy, runInWorker: true);
    final before =
        await service.inspect(projectRoot: root.path, mapId: 'shore');
    final entered = Completer<void>();
    final release = Completer<void>();
    final held = withMapDocumentWriteLock(mapFile.path, (_) async {
      entered.complete();
      await release.future;
    });
    await entered.future;
    var completed = false;
    final pending = service
        .reorder(
            projectRoot: root.path,
            mapId: 'shore',
            expectedRevision: before.revision,
            kind: 'layers',
            frontFirstIds: ['front', 'markers', 'rear'],
            operationId: 'worker_map_queue')
        .then((value) {
      completed = true;
      return value;
    });
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(completed, isFalse);
    expect(jsonDecode(await mapFile.readAsString()), original);
    release.complete();
    await held;
    await pending;
    expect(completed, isTrue);
  });
  test('worker diagnostics count real I/O and exclude unrelated content',
      () async {
    final port = ReceivePort();
    final report = port.first;
    final service = LocalMapElementOrderAuthoring(
        policy: policy, runInWorker: true, diagnosticsPort: port.sendPort);
    final direct = LocalMapElementOrderAuthoring(policy: policy);
    final before = await direct.inspect(projectRoot: root.path, mapId: 'shore');
    await service.reorder(
        projectRoot: root.path,
        mapId: 'shore',
        expectedRevision: before.revision,
        kind: 'layers',
        frontFirstIds: ['front', 'markers', 'rear'],
        operationId: 'traced_worker');
    final trace = await report as Map;
    port.close();
    final rows = (trace['rows'] as List).cast<Map>();
    expect(rows.where((row) => row['operation'] == 'write'), isNotEmpty);
    expect(rows.where((row) => row['operation'] == 'flush'), isNotEmpty);
    final reads = rows.where((row) => [
          'read',
          'streamDelivered',
          'list',
          'listRecursive'
        ].contains(row['operation']));
    expect(
        reads.where((row) =>
            row['path'] == 'project.json' ||
            row['path'] == '.pokemap/authoring/history.jsonl' ||
            row['path'] == '.pokemap/authoring/idempotency.jsonl' ||
            (row['path'] as String).startsWith('assets/')),
        isEmpty);
  });
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
