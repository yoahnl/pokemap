import 'package:map_authoring/map_authoring.dart'
    show AuthoringActor, AuthoringPermissionScope;
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/exterior_decoration_fixture.dart';

void main() {
  test(
      'worker keeps first and repeated saves targeted after initial playable load',
      () async {
    final base = Directory(
        '/Users/karim/Library/Caches/AveluneQA/exterior-decoration/authoring');
    await base.create(recursive: true);
    final root = await base.createTemp('worker_');
    addTearDown(() => root.delete(recursive: true));
    await createExteriorDecorationFixture(root.path);
    final mapFile = File('${root.path}/maps/route.json');
    final original =
        jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>;
    original['name'] = 'x' * 1600000;
    await mapFile.writeAsString(jsonEncode(original));
    final bytes = await mapFile.readAsBytes();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
    final port = ReceivePort();
    addTearDown(port.close);
    final traces = <Map>[];
    final subscription = port.listen((value) => traces.add(value as Map));
    addTearDown(subscription.cancel);
    final service = LocalMapExteriorDecorationAuthoring(
        policy: policy, runInWorker: true, diagnosticsPort: port.sendPort);
    var state = await service.inspect(projectRoot: root.path, mapId: 'route');
    Future<Map> trace() async {
      for (var i = 0; i < 100 && traces.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(traces, isNotEmpty);
      return traces.removeAt(0);
    }

    expect(
        ((await trace())['rows'] as List).any((row) =>
            row['path'] == 'maps/route.json' && row['operation'] == 'read'),
        isTrue);
    final prepared = await service.prepareIncomingReferences(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision: state.revision,
        operationId: 'worker-prepare');
    expect(prepared.afterRevision, state.revision);
    await trace();
    for (var i = 1; i <= 2; i++) {
      final sector = ExteriorDecorationSector(
          id: 'west',
          originX: -16,
          originZ: 0,
          scene: MapSpatialScene(
              width: 16, depth: 16, heightLevels: List.filled(256, i)));
      final changed = await service.setSectors(
          projectRoot: root.path,
          mapId: 'route',
          expectedRevision: state.revision,
          sectors: [sector],
          operationId: 'worker-$i');
      final rows = (await trace())['rows'] as List;
      expect(
          rows.where((row) =>
              row['path'] == 'maps/route.json' &&
              const {'read', 'openRead', 'streamDelivered'}
                  .contains(row['operation'])),
          isEmpty);
      state = await service.inspect(projectRoot: root.path, mapId: 'route');
      await trace();
      expect(state.revision, changed.afterRevision);
      expect(state.decoration!.sectors.single.scene.heightLevels.first, i);
      if (i == 2) {
        final undone = await service.undo(
            projectRoot: root.path,
            mapId: 'route',
            mutation: changed,
            operationId: 'worker-undo');
        await trace();
        await service.redoReceipt(
            projectRoot: root.path,
            mapId: 'route',
            receiptId: changed.receipt.receiptId,
            expectedRevision: undone.afterRevision,
            operationId: 'worker-redo');
        await trace();
      }
    }
    final catalog = await service.inspectNativeCatalogRevision(
        projectRoot: root.path, mapId: 'route');
    await trace();
    await service.nativeEdit(
        projectRoot: root.path,
        mapId: 'route',
        expectedRevision: state.revision,
        expectedCatalogRevision: catalog,
        operationId: 'worker-native',
        edit: {
          'kind': 'terrain.paint',
          'presetId': 'grass',
          'sectorId': 'west',
          'cells': [
            {'x': -2, 'z': 2}
          ]
        });
    expect(
        ((await trace())['rows'] as List).where((row) =>
            row['path'] == 'maps/route.json' && row['operation'] == 'read'),
        isEmpty);
    await expectLater(
        service.setSector(
            projectRoot: root.path,
            mapId: 'route',
            expectedRevision: 'sha256:${'f' * 64}',
            operationId: 'worker-stale',
            sector: ExteriorDecorationSector(
                id: 'west',
                originX: -16,
                originZ: 0,
                scene: MapSpatialScene(width: 16, depth: 16))),
        throwsA(isA<FormatException>()));
    await trace();
    expect(await mapFile.readAsBytes(), bytes);
    final next = Map<String, dynamic>.from(original)
      ..['name'] = 'changed dependency';
    await mapFile.writeAsString(jsonEncode(next));
    state = await service.inspect(projectRoot: root.path, mapId: 'route');
    expect(
        ((await trace())['rows'] as List).any((row) =>
            row['path'] == 'maps/route.json' && row['operation'] == 'read'),
        isTrue);
  });
  test(
      'worker preserves actor permissions and rejects custom callback preconditions',
      () async {
    final base = Directory(
        '/Users/karim/Library/Caches/AveluneQA/exterior-decoration/authoring');
    await base.create(recursive: true);
    final root = await base.createTemp('worker_permissions_');
    addTearDown(() => root.delete(recursive: true));
    await createExteriorDecorationFixture(root.path);
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path],
        fileReader: const LocalProjectFileReader());
    final readonly = LocalMapExteriorDecorationAuthoring(
        policy: policy,
        runInWorker: true,
        actor: AuthoringActor(
            actorId: 'readonly',
            permissions: const [AuthoringPermissionScope.projectRead]));
    final state =
        await readonly.inspect(projectRoot: root.path, mapId: 'route');
    final before =
        await File('${root.path}/maps/route.decoration.json').readAsBytes();
    await expectLater(
        readonly.configure(
            projectRoot: root.path,
            mapId: 'route',
            expectedRevision: state.revision,
            decoration: MapExteriorDecoration(
                mapId: 'route',
                playableWidth: 16,
                playableDepth: 16,
                west: 16,
                south: 1),
            operationId: 'denied'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('project.write'))));
    final noRecovery = LocalMapExteriorDecorationAuthoring(
        policy: policy,
        runInWorker: true,
        actor: AuthoringActor(actorId: 'author', permissions: const [
          AuthoringPermissionScope.projectRead,
          AuthoringPermissionScope.projectWrite
        ]));
    await expectLater(
        noRecovery.prepareIncomingReferences(
            projectRoot: root.path,
            mapId: 'route',
            expectedRevision: state.revision,
            operationId: 'denied-recovery'),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('recovery.apply'))));
    final normal =
        LocalMapExteriorDecorationAuthoring(policy: policy, runInWorker: true);
    await expectLater(
        normal.configure(
            projectRoot: root.path,
            mapId: 'route',
            expectedRevision: state.revision,
            decoration: MapExteriorDecoration(
                mapId: 'route',
                playableWidth: 16,
                playableDepth: 16,
                west: 16,
                south: 1),
            operationId: 'custom-callback',
            precondition: () {}),
        throwsArgumentError);
    expect(await File('${root.path}/maps/route.decoration.json').readAsBytes(),
        before);
  });
}
