import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('encounter behavior executes through direct API and JSONL', () async {
    final direct = await _EncounterBehaviorHarness.create('direct');
    final jsonl = await _EncounterBehaviorHarness.create('jsonl');
    addTearDown(direct.dispose);
    addTearDown(jsonl.dispose);

    final directReceipt = await direct.executeDirect();
    final jsonlReceipt = await jsonl.executeJsonl();

    expect(
        directReceipt['actionId'], 'smart_tile.layer.set_encounter_behavior');
    expect(jsonlReceipt['actionId'], 'smart_tile.layer.set_encounter_behavior');
    expect(directReceipt['status'], 'applied');
    expect(jsonlReceipt['status'], 'applied');
    expect(
      (await direct.behavior())?.encounter.encounterTableId,
      'route_grass',
    );
    expect(
      (await jsonl.behavior())?.encounter.encounterTableId,
      'route_grass',
    );

    final directClearReceipt = await direct.clearDirect();
    final jsonlClearReceipt = await jsonl.clearJsonl();

    expect(
      directClearReceipt['actionId'],
      'smart_tile.layer.clear_encounter_behavior',
    );
    expect(
      jsonlClearReceipt['actionId'],
      'smart_tile.layer.clear_encounter_behavior',
    );
    expect(await direct.behavior(), isNull);
    expect(await jsonl.behavior(), isNull);
  });

  group('BETA-BAT-034 : les transitions de combat du calque', () {
    test('sont persistées telles que choisies', () async {
      final harness = await _EncounterBehaviorHarness.create('transitions');
      addTearDown(harness.dispose);

      await harness.executeDirect(
        battleTransitionIds: <String>[
          battleWildTransitionIds[2],
          battleWildTransitionIds[0],
        ],
        suffix: 'transitions',
      );

      expect(
        (await harness.behavior())?.encounter.battleTransitionIds,
        <String>[battleWildTransitionIds[0], battleWildTransitionIds[2]],
        reason: 'validées, dédoublonnées et remises dans l’ordre du contrat '
            'partagé de map_core',
      );
    });

    test('refusent un identifiant inconnu au lieu de l’ignorer', () async {
      final harness = await _EncounterBehaviorHarness.create('unknown');
      addTearDown(harness.dispose);

      await expectLater(
        harness.executeDirect(
          battleTransitionIds: const <String>['transition_qui_nexiste_pas'],
          suffix: 'unknown',
        ),
        throwsA(anything),
        reason: 'un id inconnu doit être un refus explicite, jamais un '
            'silence qui laisse croire au choix',
      );
    });

    test('survivent à une mise à jour qui ne parle pas de transitions',
        () async {
      // Le payload est reconstruit de zéro à chaque mutation : sans garde,
      // changer la table de rencontres effaçait les transitions en silence.
      final harness = await _EncounterBehaviorHarness.create('preserve');
      addTearDown(harness.dispose);

      await harness.executeDirect(
        battleTransitionIds: <String>[battleWildTransitionIds[1]],
        suffix: 'preserve-set',
      );
      // Une mise à jour RÉELLE mais muette sur les transitions : sans la
      // préservation, l'opération changerait aussi les transitions. Le
      // changement de priorité est là pour que la mutation soit acceptée —
      // sans lui, l'API répond « changes nothing », ce qui est déjà la preuve
      // que rien n'est effacé, mais n'exerce pas le chemin d'écriture.
      await harness.executeDirect(suffix: 'preserve-update', priority: 7);

      expect(
        (await harness.behavior())?.encounter.battleTransitionIds,
        <String>[battleWildTransitionIds[1]],
        reason: 'un appelant qui ignore ce champ ne doit pas détruire ce '
            'qu’un autre a posé',
      );
    });

    test('partent vides quand personne n’en a jamais choisi', () async {
      final harness = await _EncounterBehaviorHarness.create('empty');
      addTearDown(harness.dispose);

      await harness.executeDirect(suffix: 'empty');

      expect(
        (await harness.behavior())?.encounter.battleTransitionIds,
        isEmpty,
      );
    });
  });
}

final class _EncounterBehaviorHarness {
  _EncounterBehaviorHarness({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
  });

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  static Future<_EncounterBehaviorHarness> create(String suffix) async {
    final root = await Directory.systemTemp.createTemp(
      'smart-tile-encounter-$suffix-',
    );
    await Directory('${root.path}/maps').create(recursive: true);
    await File('${root.path}/project.json').writeAsString(
      jsonEncode(_manifest().toJson()),
    );
    await File('${root.path}/maps/route.json').writeAsString(
      jsonEncode(_map().toJson()),
    );
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final readApi = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    return _EncounterBehaviorHarness(
      root: root,
      readApi: readApi,
      mutations: mutations,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  Future<Map<String, Object?>> executeDirect({
    List<String>? battleTransitionIds,
    String suffix = 'direct',
    int priority = 3,
  }) async {
    final opened = await readApi.openProject(root.path);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    final snapshot = await snapshots.load(opened.projectHandle);
    final plan = await mutations.plan(
      opened.projectHandle,
      _request(
        workspaceHandle: opened.workspaceHandle.value,
        revision: snapshot.revision,
        suffix: suffix,
        battleTransitionIds: battleTransitionIds,
        priority: priority,
      ),
    );
    final applied = await mutations.apply(
      opened.projectHandle,
      planId: plan['planId']! as String,
      operationId: 'smart-tile-encounter-$suffix',
    );
    return Map<String, Object?>.from(applied['receipt']! as Map);
  }

  Future<Map<String, Object?>> executeJsonl() async {
    final opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    final projectHandle = opened.data['projectHandle']! as String;
    final workspaceHandle = opened.data['workspaceHandle']! as String;
    final snapshot = await snapshots.load(ProjectHandle(projectHandle));
    final planned = await _jsonl('plan', <String, Object?>{
      'projectHandle': projectHandle,
      'request': _request(
        workspaceHandle: workspaceHandle,
        revision: snapshot.revision,
        suffix: 'jsonl',
      ).toJson(),
    });
    final applied = await _jsonl('apply', <String, Object?>{
      'projectHandle': projectHandle,
      'planId': planned.data['planId'],
      'operationId': 'smart-tile-encounter-jsonl',
    });
    return Map<String, Object?>.from(applied.data['receipt']! as Map);
  }

  Future<Map<String, Object?>> clearDirect() async {
    final opened = await readApi.openProject(root.path);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    final snapshot = await snapshots.load(opened.projectHandle);
    final plan = await mutations.plan(
      opened.projectHandle,
      _clearRequest(
        workspaceHandle: opened.workspaceHandle.value,
        revision: snapshot.revision,
        suffix: 'direct',
      ),
    );
    final applied = await mutations.apply(
      opened.projectHandle,
      planId: plan['planId']! as String,
      operationId: 'smart-tile-encounter-clear-direct',
    );
    return Map<String, Object?>.from(applied['receipt']! as Map);
  }

  Future<Map<String, Object?>> clearJsonl() async {
    final opened = await _jsonl('open', <String, Object?>{
      'projectRoot': root.path,
    });
    final projectHandle = opened.data['projectHandle']! as String;
    final workspaceHandle = opened.data['workspaceHandle']! as String;
    final snapshot = await snapshots.load(ProjectHandle(projectHandle));
    final planned = await _jsonl('plan', <String, Object?>{
      'projectHandle': projectHandle,
      'request': _clearRequest(
        workspaceHandle: workspaceHandle,
        revision: snapshot.revision,
        suffix: 'jsonl',
      ).toJson(),
    });
    final applied = await _jsonl('apply', <String, Object?>{
      'projectHandle': projectHandle,
      'planId': planned.data['planId'],
      'operationId': 'smart-tile-encounter-clear-jsonl',
    });
    return Map<String, Object?>.from(applied.data['receipt']! as Map);
  }

  AuthoringRequest _request({
    required String workspaceHandle,
    required String revision,
    required String suffix,
    List<String>? battleTransitionIds,
    int priority = 3,
  }) {
    return AuthoringRequest(
      requestId: 'smart-tile-encounter-$suffix',
      actionId: 'smart_tile.layer.set_encounter_behavior',
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: <String, Object?>{
        'mapId': 'route',
        'layerId': 'grass',
        'materialId': 'tall_grass',
        'priority': priority,
        'encounterTableId': 'route_grass',
        'encounterKind': 'walk',
        if (battleTransitionIds != null)
          'battleTransitionIds': battleTransitionIds,
      },
      expectedRevision: revision,
      idempotencyKey: 'smart-tile-encounter-$suffix',
      dryRun: false,
    );
  }

  AuthoringRequest _clearRequest({
    required String workspaceHandle,
    required String revision,
    required String suffix,
  }) {
    return AuthoringRequest(
      requestId: 'smart-tile-encounter-clear-$suffix',
      actionId: 'smart_tile.layer.clear_encounter_behavior',
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: const <String, Object?>{
        'mapId': 'route',
        'layerId': 'grass',
      },
      expectedRevision: revision,
      idempotencyKey: 'smart-tile-encounter-clear-$suffix',
      dryRun: false,
    );
  }

  Future<AuthoringResult> _jsonl(
    String command,
    Map<String, Object?> args,
  ) async {
    return AuthoringResult.fromJson(
      jsonDecode(
        await worker.processLine(
          jsonEncode(<String, Object?>{
            'id': 'smart-tile-encounter-$command',
            'command': command,
            'args': args,
          }),
        ),
      ) as Map<String, dynamic>,
    );
  }

  Future<SmartTileEncounterBehavior?> behavior() async {
    final map = MapData.fromJson(
      jsonDecode(await File('${root.path}/maps/route.json').readAsString())
          as Map<String, dynamic>,
    );
    return (map.layers.single as SmartTileLayer).encounterBehavior;
  }

  Future<void> dispose() async {
    await root.delete(recursive: true);
  }
}

ProjectManifest _manifest() {
  return ProjectManifest(
    name: 'Smart Tile encounter transport fixture',
    version: ProjectVersion.v6,
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'route',
        name: 'Route',
        relativePath: 'maps/route.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tiles',
        name: 'Tiles',
        relativePath: 'tiles.png',
        source: ProjectTilesetSource.regularAtlas(
          assetId: 'tiles-asset',
          pixelWidth: 32,
          pixelHeight: 32,
          tileWidth: 32,
          tileHeight: 32,
        ),
      ),
    ],
    encounterTables: <ProjectEncounterTable>[
      ProjectEncounterTable(
        id: 'route_grass',
        name: 'Route grass',
        encounterKind: EncounterKind.walk,
        entries: <ProjectEncounterEntry>[
          ProjectEncounterEntry(
            speciesId: 'pidgey',
            minLevel: 3,
            maxLevel: 3,
          ),
        ],
      ),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: <ProjectSmartTileAtlas>[
        ProjectSmartTileAtlas(
          id: 'grass-atlas',
          name: 'Grass atlas',
          tilesetId: 'tiles',
          columns: 1,
          rows: 1,
        ),
      ],
      materials: <ProjectSmartTileMaterial>[
        ProjectSmartTileMaterial(
          id: 'tall_grass',
          name: 'Tall grass',
          connectionGroupId: 'ground',
        ),
      ],
      presets: <ProjectSmartTilePreset>[
        ProjectSmartTilePreset(
          id: 'grass-preset',
          name: 'Grass preset',
          usage: SmartTileUsage.path,
          topology: SmartTileTopology.uniform,
          status: SmartTilePresetStatus.published,
          coveragePolicy: SmartTileCoveragePolicy.sparse,
          coverageProfile: SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.explicit,
            requiredScenarios: <SmartTileCoverageScenario>[
              SmartTileCoverageScenario(
                id: 'grass',
                centerMaterialId: 'tall_grass',
              ),
            ],
          ),
          transformPolicy: SmartTileTransformPolicy(),
          defaultMaterialId: 'tall_grass',
          allowedMaterialIds: <String>['tall_grass'],
          rules: <SmartTileRule>[
            SmartTileRule(
              id: 'grass',
              centerMatch: SmartTileSlotMatch.material('tall_grass'),
              candidates: <SmartTileCandidate>[
                SmartTileCandidate(
                  id: 'grass',
                  parts: <SmartTileVisualPart>[
                    SmartTileVisualPart(
                      source: SmartTileVisualSource.frame(
                        frame: SmartTileFrameRef(
                          atlasId: 'grass-atlas',
                          column: 0,
                          row: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

MapData _map() {
  return const MapData(
    id: 'route',
    name: 'Route',
    version: ProjectVersion.v6,
    size: GridSize(width: 1, height: 1),
    layers: <MapLayer>[
      SmartTileLayer(
        id: 'grass',
        name: 'Tall grass',
        presetId: 'grass-preset',
        usage: SmartTileUsage.path,
        materialPalette: <String>['', 'tall_grass'],
        field: SmartTileField.cell(semanticCells: <int>[1]),
      ),
    ],
  );
}
