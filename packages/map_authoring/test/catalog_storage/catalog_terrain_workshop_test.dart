import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/reliability_map_fixture.dart' show ReliabilityCountingReader;
import '../support/terrain_workshop_fixture.dart';

void main() {
  test('publishes a raster change without rereading the painted map', () async {
    final fixture = await _TerrainFixture.open();
    addTearDown(fixture.close);
    final original = await fixture.readTerrain();
    final originalUnit = await fixture.readTerrainUnit();
    final tilesetDefinition = await fixture.readDefinitionPath(
        CatalogDefinitionKind.tileset, 'water');
    final map = File('${fixture.root.path}/maps/$terrainWorkshopMapId.json');
    final mapBytes = await map.readAsBytes();
    final asset = File('${fixture.root.path}/assets/water.png');
    final imageBytes = await asset.readAsBytes();
    final descriptor =
        await File('${fixture.root.path}/project.json').readAsBytes();
    expect(await fixture.readCenter(), 96);

    var current = original;
    for (final (index, column) in [2, 1].indexed) {
      final next = _withCenterColumn(current, column);
      final request = await fixture.request('raccord-$index', next);
      fixture.reader.paths.clear();
      fixture.snapshotLoads.clear();
      fixture.promotions.clear();
      final head = await fixture.readHead();
      final plan =
          await fixture.mutations.planMutation(fixture.project, request);
      expect(plan.plan.changeSet.changes.map((change) => change.storageKey),
          ['catalog/HEAD.json']);
      expect(plan.receipt.diff.entries.map((entry) => entry.path),
          contains('/smartTileCatalog/presets/$terrainWorkshopPresetId'));
      expect(await fixture.readHead(), head);
      await fixture.mutations.applyMutation(fixture.project,
          planId: plan.planId, operationId: 'raccord-$index');
      expect(fixture.promotions, ['catalog/HEAD.json']);
      expect(fixture.snapshotLoads, isEmpty);
      expect(
        fixture.reader.paths.where((path) =>
            path.startsWith('maps/') ||
            path.startsWith('assets/') ||
            fixture.foreignPaths.contains(path)),
        isEmpty,
      );
      expect(fixture.reader.paths.length, lessThan(64));
      expect(fixture.reader.paths, isNot(contains(tilesetDefinition)));
      expect(await map.readAsBytes(), mapBytes);
      expect(await asset.readAsBytes(), imageBytes);
      expect(await File('${fixture.root.path}/project.json').readAsBytes(),
          descriptor);
      await fixture.reopen();
      expect(await fixture.readTerrain(), next);
      expect(await fixture.readCenter(), column * 32);
      final saved = await fixture.readTerrainUnit();
      final compact = ProjectSmartTileCatalog(presets: [next]).toJson();
      expect(saved.payload, {
        ...originalUnit.payload,
        'value': (compact['presets'] as List).single,
      });
      expect(saved.references, originalUnit.references);
      current = next;
    }
  });

  test(
      'shared action refuses a structural change and coordinates outside the atlas',
      () async {
    final fixture = await _TerrainFixture.open();
    addTearDown(fixture.close);
    final original = await fixture.readTerrain();
    final head = await fixture.readHead();
    await expectLater(
      fixture.request(
          'usage', original.copyWith(usage: SmartTileUsage.terrain)),
      throwsA(isA<AuthoringPlanException>().having(
          (error) => error.code, 'code', 'catalog.mutation_scope_required')),
    );
    for (final column in [4, 0x7fffffffffffffff]) {
      final invalid = await fixture.request(
          'hors-planche-$column', _withCenterColumn(original, column));
      await expectLater(
        fixture.mutations.planMutation(fixture.project, invalid),
        throwsA(isA<MapAuthoringException>()),
      );
    }
    expect(await fixture.readHead(), head);
    expect(await fixture.readTerrain(), original);
  });

  test('JSONL uses the same scoped action and its receipt supports undo',
      () async {
    final fixture = await _TerrainFixture.open();
    addTearDown(fixture.close);
    final original = await fixture.readTerrain();
    final request =
        await fixture.request('jsonl-raccord', _withCenterColumn(original, 1));
    final worker = JsonlWorker(api: fixture.api, mutations: fixture.mutations);
    Future<Map<String, Object?>> call(
        String command, Map<String, Object?> args) async {
      final result = jsonDecode(await worker.processLine(jsonEncode({
        'id': command,
        'command': command,
        'args': {'projectHandle': fixture.project.value, ...args},
      }))) as Map;
      expect(result['status'], 'success', reason: result.toString());
      return Map<String, Object?>.from(result['data'] as Map);
    }

    final planned = await call('plan', {'request': request.toJson()});
    final applied = await call('apply', {
      'planId': planned['planId'],
      'operationId': 'jsonl-raccord',
    });
    expect(await fixture.readCenter(), 32);
    await fixture.mutations.undoMutation(
      fixture.project,
      entryId: (applied['receipt'] as Map)['receiptId'] as String,
      idempotencyKey: 'annulation-raccord',
    );
    await fixture.reopen();
    expect(await fixture.readTerrain(), original);
    expect(await fixture.readCenter(), 96);
  });
}

ProjectSmartTilePreset _withCenterColumn(
    ProjectSmartTilePreset preset, int column) {
  final rule = preset.rules.last;
  final candidate = rule.candidates.single;
  final part = candidate.parts.single;
  final frame = (part.source as SmartTileFrameSource).frame;
  return preset.copyWith(rules: [
    ...preset.rules.take(15),
    rule.copyWith(candidates: [
      candidate.copyWith(parts: [
        part.copyWith(
            source: SmartTileVisualSource.frame(
                frame: frame.copyWith(column: column))),
      ]),
    ]),
  ]);
}

final class _TerrainFixture {
  _TerrainFixture(this.root, this.reader, this.openService, this.api,
      this.mutations, this.promotions, this.snapshotLoads, this.foreignPaths);

  final Directory root;
  final ReliabilityCountingReader reader;
  final ProjectOpenService openService;
  final AuthoringReadApi api;
  final LocalMapAuthoringMutationApi mutations;
  final List<String> promotions;
  final List<ProjectSnapshotLoadProfile> snapshotLoads;
  final Set<String> foreignPaths;
  late OpenedProject opened;
  ProjectHandle get project => opened.projectHandle;

  static Future<_TerrainFixture> open() async {
    final root = await Directory.systemTemp.createTemp('terrain-workshop-');
    final paths = await writeTerrainWorkshopFixture(root, unrelatedRecords: 32);
    final reader = ReliabilityCountingReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final loads = <ProjectSnapshotLoadProfile>[];
    final loader =
        ProjectSnapshotLoader(handles: handles, profileSink: loads.add);
    final opening = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final promotions = <String>[];
    final fixture = _TerrainFixture(
      root,
      reader,
      opening,
      AuthoringReadApi(openService: opening, snapshotLoader: loader),
      LocalMapAuthoringMutationApi(
        policy: policy,
        snapshotLoader: loader,
        catalogFileReader: reader,
        faultInjector: (context) {
          if (context.checkpoint ==
              AuthoringTransactionCheckpoint.beforeResourcePromotion) {
            promotions.add(context.storageKey!);
          }
        },
      ),
      promotions,
      loads,
      paths,
    );
    await fixture.attach();
    await fixture.mutations.prepareWorkshopCatalog(fixture.project);
    await fixture.mutations
        .prepareWorkshopCatalog(fixture.project, scope: 'nativeResources');
    return fixture;
  }

  Future<List<int>> readHead() =>
      File('${root.path}/catalog/HEAD.json').readAsBytes();

  Future<AuthoringRequest> request(
      String key, ProjectSmartTilePreset preset) async {
    const action = 'smart_tile.preset.publish';
    final parameters = {'preset': preset.toJson()};
    final scope = await mutations.readWorkshopSnapshot(project,
        actionId: action, parameters: parameters);
    return AuthoringRequest(
        requestId: key,
        actionId: action,
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        expectedRevision: scope.revision,
        idempotencyKey: key,
        parameters: parameters,
        extensions: const {'workshopScope': true});
  }

  Future<ProjectSmartTilePreset> readTerrain() async =>
      ProjectSmartTilePreset.fromJson(Map<String, dynamic>.from(
          (await readTerrainUnit()).payload['value'] as Map));

  Future<CatalogDefinitionUnit> readTerrainUnit() async {
    final catalog = (await openService.catalogProject(project))!;
    return catalog.read((current) async => (await current.lookup(
        CatalogDefinitionKey(
            CatalogDefinitionKind.smartTilePreset, terrainWorkshopPresetId)))!);
  }

  Future<String> readDefinitionPath(
      CatalogDefinitionKind kind, String id) async {
    final catalog = (await openService.catalogProject(project))!;
    final entry = await catalog.read(
        (current) => current.snapshot.indexEntry(CatalogDefinitionKey(kind, id)));
    return 'catalog/objects/${entry!.reference.sha256}.json';
  }

  Future<int> readCenter() async {
    final catalog = (await openService.catalogProject(project))!;
    final content = await File('${root.path}/maps/$terrainWorkshopMapId.json')
        .readAsString();
    final map =
        MapData.fromJson(Map<String, dynamic>.from(jsonDecode(content) as Map));
    final definitions = await catalog
        .read((current) => ProjectCatalogSelection(current).forMap(map));
    final visuals = resolveSmartTileLayerVisuals(
      map: map,
      layer: map.layers.whereType<SmartTileLayer>().single,
      catalog: definitions.smartTileCatalog,
      pass: SmartTileVisualPass.background,
    );
    return visuals
        .singleWhere((visual) => visual.cellX == 1 && visual.cellY == 1)
        .sourceRect
        .x;
  }

  Future<void> attach() async {
    opened = await api.openProject(root.path);
    await mutations.attachProject(
        projectRootPath: root.path,
        workspaceHandle: opened.workspaceHandle,
        projectHandle: project);
  }

  Future<void> detach() async {
    await mutations.detachWorkspace(opened.workspaceHandle);
    await api.closeWorkspace(opened.workspaceHandle);
  }

  Future<void> reopen() async {
    await detach();
    await attach();
  }

  Future<void> close() async {
    await detach();
    await root.delete(recursive: true);
  }
}
