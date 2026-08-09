import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/features/editor/application/smart_tile_layer_preset_change_gateway.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/smart_tile_layer_preset_change_flow.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:path/path.dart' as p;

void main() {
  testWidgets(
    'prévisualise le remappage puis applique le changement canonique',
    (tester) async {
      final gateway = _RecordingGateway();
      SmartTileLayerPresetChangeCanonicalResult? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showSmartTileLayerPresetChangeFlow(
                    context: context,
                    gateway: gateway,
                    projectRootPath: '/project',
                    manifest: _manifest,
                    map: _map,
                    layer: _layer,
                    targetPreset: _targetPreset,
                  );
                },
                child: const Text('Ouvrir'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('Changer le motif du calque'), findsOneWidget);
      expect(find.text('ERW — Terre sombre'), findsOneWidget);
      expect(find.text('Chemin de terre rurale'), findsOneWidget);
      expect(find.text('Remplacer Terre sombre'), findsOneWidget);

      await tester.tap(find.text('Prévisualiser'));
      await tester.pumpAndSettle();

      expect(gateway.planCalls, 1);
      expect(gateway.materialMappings, const <String, String>{'dark': 'rural'});
      expect(find.text('Vérifier le changement de motif'), findsOneWidget);
      expect(find.textContaining('2 valeurs de matière'), findsOneWidget);
      expect(find.textContaining('géométrie peinte'), findsOneWidget);

      await tester.tap(find.text('Appliquer'));
      await tester.pumpAndSettle();

      expect(gateway.applyCalls, 1);
      expect(result?.layerId, _layer.id);
      expect(
        result?.map.layers.whereType<SmartTileLayer>().single.presetId,
        'rural',
      );
    },
  );

  testWidgets('annuler ne prépare ni n’applique de mutation', (tester) async {
    final gateway = _RecordingGateway();

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.light(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showSmartTileLayerPresetChangeFlow(
                context: context,
                gateway: gateway,
                projectRootPath: '/project',
                manifest: _manifest,
                map: _map,
                layer: _layer,
                targetPreset: _targetPreset,
              ),
              child: const Text('Ouvrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(gateway.planCalls, 0);
    expect(gateway.applyCalls, 0);
  });

  test('le gateway éditeur applique et relit le snapshot canonique', () async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_layer_preset_change_',
    );
    final container = ProviderContainer();
    addTearDown(() async {
      container.dispose();
      if (await root.exists()) await root.delete(recursive: true);
    });
    final manifest = _canonicalManifest();
    final mapPath = p.join(root.path, 'maps', 'map.json');
    await Directory(p.dirname(mapPath)).create(recursive: true);
    await FileProjectRepository().saveProject(
      manifest,
      p.join(root.path, 'project.json'),
    );
    await FileMapRepository().saveMap(
      _map,
      mapPath,
      projectDialogueContext: manifest,
    );
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      projectRootPath: root.path,
      project: manifest,
      workspaceMode: EditorWorkspaceMode.map,
    );
    await notifier.loadMap('maps/map.json');
    final gateway = CanonicalSmartTileLayerPresetChangeGateway(
      mutations: container.read(authoringMutationAdapterProvider),
      queries: container.read(authoringQueryAdapterProvider),
    );

    final plan = await gateway.planChange(
      projectRootPath: root.path,
      mapId: _map.id,
      layerId: _layer.id,
      targetPresetId: _targetPreset.id,
      materialMappings: const <String, String>{'dark': 'rural'},
    );
    final result = await gateway.applyChange(plan: plan);

    expect(plan.remappedEntryCount, 2);
    expect(plan.clearedCandidateWeightCount, 1);
    expect(result.layerId, _layer.id);
    expect(result.receiptId, isNotEmpty);
    final changed = result.map.layers.single as SmartTileLayer;
    expect(changed.id, _layer.id);
    expect(changed.presetId, _targetPreset.id);
    expect(changed.materialPalette, const <String>['', 'rural']);
    expect(changed.candidateWeights, isEmpty);
    expect(smartTileSemanticCells(changed), const <int>[1, 0, 1, 0]);
    final diskLayer =
        (await FileMapRepository().loadMap(mapPath)).layers.single
            as SmartTileLayer;
    expect(diskLayer, changed);
    expect(
      notifier.acceptCanonicalSmartTileLayerPresetChange(
        projectRootPath: root.path,
        manifest: result.manifest,
        map: result.map,
        mapRevision: result.mapRevision,
        layerId: result.layerId,
        receiptId: result.receiptId,
        targetPresetId: result.targetPresetId,
        materialMappings: result.materialMappings,
        statusMessage: 'Motif appliqué.',
      ),
      isTrue,
    );
    expect(notifier.state.canUndoMap, isTrue);

    notifier.undoMap();
    await _waitUntil(
      () =>
          container
                  .read(authoringMutationAdapterProvider)
                  .lastAppliedReceipt
                  ?.actionId ==
              'history.undo' &&
          (notifier.state.activeMap!.layers.single as SmartTileLayer)
                  .presetId ==
              _sourcePreset.id,
    );
    expect(notifier.state.canRedoMap, isTrue);
  });

  test('le réglage éditeur persiste le déclenchement au passage', () async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_layer_animation_activation_',
    );
    final container = ProviderContainer();
    addTearDown(() async {
      container.dispose();
      if (await root.exists()) await root.delete(recursive: true);
    });
    final manifest = _canonicalManifest();
    final mapPath = p.join(root.path, 'maps', 'map.json');
    await Directory(p.dirname(mapPath)).create(recursive: true);
    await FileProjectRepository().saveProject(
      manifest,
      p.join(root.path, 'project.json'),
    );
    await FileMapRepository().saveMap(
      _map,
      mapPath,
      projectDialogueContext: manifest,
    );
    final notifier = container.read(editorNotifierProvider.notifier);
    notifier.state = EditorState(
      projectRootPath: root.path,
      project: manifest,
      workspaceMode: EditorWorkspaceMode.map,
    );
    await notifier.loadMap('maps/map.json');

    await notifier.applySmartTileLayerAnimationActivation(
      mapId: _map.id,
      layerId: _layer.id,
      activation: SmartTileAnimationActivation.onEnter,
    );

    final activeLayer =
        notifier.state.activeMap!.layers.single as SmartTileLayer;
    expect(
      activeLayer.animationActivation,
      SmartTileAnimationActivation.onEnter,
    );
    final diskLayer =
        (await FileMapRepository().loadMap(mapPath)).layers.single
            as SmartTileLayer;
    expect(diskLayer.animationActivation, SmartTileAnimationActivation.onEnter);
    expect(notifier.state.isDirty, isFalse);
  });
}

Future<void> _waitUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 200; attempt += 1) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out while waiting for canonical Smart Tile history.');
}

final class _RecordingGateway implements SmartTileLayerPresetChangeGateway {
  int planCalls = 0;
  int applyCalls = 0;
  Map<String, String>? materialMappings;

  @override
  Future<SmartTileLayerPresetChangeCanonicalPlan> planChange({
    required String projectRootPath,
    required String mapId,
    required String layerId,
    required String targetPresetId,
    required Map<String, String> materialMappings,
  }) async {
    planCalls += 1;
    this.materialMappings = materialMappings;
    return SmartTileLayerPresetChangeCanonicalPlan(
      token: Object(),
      planId: 'change-preset',
      projectRootPath: projectRootPath,
      mapId: mapId,
      layerId: layerId,
      targetPresetId: targetPresetId,
      remappedEntryCount: 2,
      clearedCandidateWeightCount: 1,
      materialMappings: materialMappings,
    );
  }

  @override
  Future<SmartTileLayerPresetChangeCanonicalResult> applyChange({
    required SmartTileLayerPresetChangeCanonicalPlan plan,
  }) async {
    applyCalls += 1;
    final changed = _layer.copyWith(
      presetId: 'rural',
      materialPalette: const <String>['', 'rural'],
      candidateWeights: const <String, int>{},
    );
    return SmartTileLayerPresetChangeCanonicalResult(
      manifest: _manifest,
      map: _map.copyWith(layers: <MapLayer>[changed]),
      mapRevision: 'map-revision-2',
      layerId: _layer.id,
      receiptId: 'receipt-change-preset',
      targetPresetId: 'rural',
      materialMappings: const <String, String>{'dark': 'rural'},
    );
  }
}

const _sourcePreset = ProjectSmartTilePreset(
  id: 'dark',
  name: 'ERW — Terre sombre',
  usage: SmartTileUsage.path,
  topology: SmartTileTopology.cardinal4,
  coveragePolicy: SmartTileCoveragePolicy.sparse,
  coverageProfile: SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.template,
  ),
  transformPolicy: SmartTileTransformPolicy(),
  status: SmartTilePresetStatus.published,
  defaultMaterialId: 'dark',
  allowedMaterialIds: <String>['dark'],
);

const _targetPreset = ProjectSmartTilePreset(
  id: 'rural',
  name: 'Chemin de terre rurale',
  usage: SmartTileUsage.path,
  topology: SmartTileTopology.cardinal4,
  coveragePolicy: SmartTileCoveragePolicy.sparse,
  coverageProfile: SmartTileCoverageProfile(
    mode: SmartTileCoverageMode.template,
  ),
  transformPolicy: SmartTileTransformPolicy(),
  status: SmartTilePresetStatus.published,
  defaultMaterialId: 'rural',
  allowedMaterialIds: <String>['rural'],
);

final _manifest = ProjectManifest(
  name: 'Preset change',
  maps: <ProjectMapEntry>[],
  tilesets: <ProjectTilesetEntry>[],
  smartTileCatalog: ProjectSmartTileCatalog(
    materials: const <ProjectSmartTileMaterial>[
      ProjectSmartTileMaterial(
        id: 'dark',
        name: 'Terre sombre',
        connectionGroupId: 'dark',
      ),
      ProjectSmartTileMaterial(
        id: 'rural',
        name: 'Terre rurale',
        connectionGroupId: 'rural',
      ),
    ],
    presets: const <ProjectSmartTilePreset>[_sourcePreset, _targetPreset],
  ),
);

const _layer = SmartTileLayer(
  id: 'path-layer',
  name: 'Chemin principal',
  presetId: 'dark',
  usage: SmartTileUsage.path,
  materialPalette: <String>['', 'dark'],
  field: SmartTileField.cell(semanticCells: <int>[1, 0, 1, 0]),
  candidateWeights: <String, int>{'dark-a': 700},
);

const _map = MapData(
  id: 'map',
  name: 'Map',
  version: ProjectVersion.v6,
  size: GridSize(width: 2, height: 2),
  layers: <MapLayer>[_layer],
);

ProjectManifest _canonicalManifest() => ProjectManifest(
  name: 'Canonical preset change',
  version: ProjectVersion.v6,
  maps: const <ProjectMapEntry>[
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  tilesets: const <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'paths',
      name: 'Paths',
      relativePath: 'assets/paths.png',
    ),
  ],
  smartTileCatalog: ProjectSmartTileCatalog(
    atlases: const <ProjectSmartTileAtlas>[
      ProjectSmartTileAtlas(
        id: 'paths-atlas',
        name: 'Paths atlas',
        tilesetId: 'paths',
        columns: 2,
        rows: 1,
      ),
    ],
    materials: _manifest.smartTileCatalog.materials,
    presets: <ProjectSmartTilePreset>[
      _sourcePreset.copyWith(
        topology: SmartTileTopology.uniform,
        templateHint: SmartTileTemplateHint.simple,
        coverageProfile: const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        rules: <SmartTileRule>[_darkRule],
      ),
      _targetPreset.copyWith(
        topology: SmartTileTopology.uniform,
        templateHint: SmartTileTemplateHint.simple,
        coverageProfile: const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        rules: <SmartTileRule>[_ruralRule],
      ),
    ],
  ),
);

const _darkRule = SmartTileRule(
  id: 'dark-fill',
  centerMatch: SmartTileSlotMatch.material('dark'),
  candidates: <SmartTileCandidate>[
    SmartTileCandidate(
      id: 'dark-fill-c0',
      parts: <SmartTileVisualPart>[
        SmartTileVisualPart(
          source: SmartTileVisualSource.frame(
            frame: SmartTileFrameRef(atlasId: 'paths-atlas', column: 0, row: 0),
          ),
        ),
      ],
    ),
  ],
);

const _ruralRule = SmartTileRule(
  id: 'rural-fill',
  centerMatch: SmartTileSlotMatch.material('rural'),
  candidates: <SmartTileCandidate>[
    SmartTileCandidate(
      id: 'rural-fill-c0',
      parts: <SmartTileVisualPart>[
        SmartTileVisualPart(
          source: SmartTileVisualSource.frame(
            frame: SmartTileFrameRef(atlasId: 'paths-atlas', column: 1, row: 0),
          ),
        ),
      ],
    ),
  ],
);
