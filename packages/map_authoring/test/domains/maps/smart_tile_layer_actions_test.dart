import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SmartTileLayerActions', () {
    test('advertises revisioned, idempotent, undoable canonical actions', () {
      final descriptors = SmartTileLayerActions.descriptors;

      expect(
        descriptors.map((descriptor) => descriptor.id),
        [
          'smart_tile.layer.create',
          'smart_tile.layer.change_preset',
          'smart_tile.layer.delete',
          'smart_tile.layer.merge',
          'smart_tile.layer.normalize',
          'smart_tile.layer.reconstruct',
          'smart_tile.layer.set_animation_activation',
          'smart_tile.layer.set_candidate_weights',
          'smart_tile.layer.set_encounter_behavior',
          'smart_tile.layer.clear_encounter_behavior',
        ],
      );
      for (final descriptor in descriptors) {
        expect(descriptor.guarantees, contains(AuthoringGuarantee.dryRun));
        expect(descriptor.guarantees, contains(AuthoringGuarantee.idempotent));
        expect(
          descriptor.guarantees,
          contains(AuthoringGuarantee.revisionChecked),
        );
        expect(descriptor.guarantees, contains(AuthoringGuarantee.undoable));
      }
      expect(
        descriptors
            .singleWhere(
              (descriptor) => descriptor.id == 'smart_tile.layer.reconstruct',
            )
            .riskLevel,
        AuthoringRiskLevel.high,
      );
    });

    test('previews a hidden native reconstruction without touching the source',
        () {
      final fixture = _reconstructionFixture();

      final draft = const SmartTileLayerActions().build(
        _context(
          fixture.snapshot,
          actionId: 'smart_tile.layer.reconstruct',
          parameters: const <String, Object?>{
            'mapId': 'map_hanazuki_village',
            'sourceLayerId': 'literal',
            'presetId': 'edge',
            'targetLayerId': 'native',
            'name': 'Native path',
          },
        ),
      );
      final projected = _projectedMap(draft);

      expect(projected.layers.map((layer) => layer.id), <String>[
        'literal',
        'native',
      ]);
      expect(projected.layers.first, fixture.map.layers.first);
      final native = projected.layers.last as SmartTileLayer;
      expect(native.isVisible, isFalse);
      expect(native.presetId, 'edge');
      expect(draft.preview, containsPair('sourcePreserved', true));
      expect(draft.preview, containsPair('coverage', 1.0));
      expect(draft.preview, containsPair('exactVisualMatchCount', 1));
      expect(
        draft.preview['assessmentChecksum'],
        isA<String>().having(
          (value) => value,
          'checksum',
          startsWith('sha256:'),
        ),
      );
    });

    test('normalizes the M01 terrain without losing metadata or layer order',
        () {
      final fixture = _m01Fixture();
      final beforeLayer = fixture.map.layers[1] as SmartTileLayer;

      final draft = const SmartTileLayerActions().build(
        _context(
          fixture.snapshot,
          actionId: 'smart_tile.layer.normalize',
          parameters: const {
            'mapId': 'map_hanazuki_village',
            'layerId': 'l_qc02_terrain',
          },
        ),
      );
      final projected = _projectedMap(draft);
      final normalized = projected.layers[1] as SmartTileLayer;

      expect(
        projected.layers.map((layer) => layer.id),
        fixture.map.layers.map((layer) => layer.id),
      );
      expect(normalized.materialPalette, ['', 'grass']);
      expect(smartTileSemanticCells(normalized),
          smartTileSemanticCells(beforeLayer));
      expect(
        smartTileHorizontalEdges(normalized),
        smartTileHorizontalEdges(beforeLayer),
      );
      expect(
        smartTileVerticalEdges(normalized),
        smartTileVerticalEdges(beforeLayer),
      );
      expect(smartTileCorners(normalized), smartTileCorners(beforeLayer));
      expect(normalized.id, beforeLayer.id);
      expect(normalized.name, beforeLayer.name);
      expect(normalized.isVisible, beforeLayer.isVisible);
      expect(normalized.opacity, beforeLayer.opacity);
      expect(normalized.presetId, beforeLayer.presetId);
      expect(normalized.usage, beforeLayer.usage);
      expect(normalized.layerSeed, beforeLayer.layerSeed);
      expect(normalized.properties, beforeLayer.properties);
      expect(draft.preview['removedMaterialCount'], 1);
      expect(draft.preview['removedMaterials'], [
        {'materialId': 'smart_material_empty', 'oldIndex': 2},
      ]);
      expect(draft.preview['reindexedEntryCount'], 0);
      expect(
        () => MapValidator.validate(
          projected,
          projectDialogueContext: fixture.manifest,
        ),
        returnsNormally,
      );
    });

    test('normalizes then merges the crossing M01 paths as one exact union',
        () {
      final fixture = _m01Fixture();
      final normalizedDraft = const SmartTileLayerActions().build(
        _context(
          fixture.snapshot,
          actionId: 'smart_tile.layer.normalize',
          parameters: const {
            'mapId': 'map_hanazuki_village',
            'layerId': 'l_qc02_terrain',
          },
        ),
      );
      final normalizedMap = _projectedMap(normalizedDraft);
      final normalizedSnapshot = _snapshot(fixture.manifest, normalizedMap);
      final targetBefore = normalizedMap.layers[2] as SmartTileLayer;

      final mergeDraft = const SmartTileLayerActions().build(
        _context(
          normalizedSnapshot,
          actionId: 'smart_tile.layer.merge',
          parameters: const {
            'mapId': 'map_hanazuki_village',
            'sourceLayerIds': [
              'l_qc02_path_dirt',
              'l_qc02_path_compacted',
            ],
            'targetLayerId': 'l_qc02_path_dirt',
            'mode': 'union',
            'removeSources': true,
            'conflictPolicy': 'reject',
          },
        ),
      );
      final mergedMap = _projectedMap(mergeDraft);
      final target = mergedMap.layers[2] as SmartTileLayer;

      expect(
        mergedMap.layers.map((layer) => layer.id),
        [
          'l_base',
          'l_qc02_terrain',
          'l_qc02_path_dirt',
          'l_collisions',
        ],
      );
      expect(target.materialPalette, ['', 'dirt']);
      expect(smartTileSemanticCells(target), [0, 1, 0, 1, 1, 1, 0, 1, 0]);
      expect(
        smartTileHorizontalEdges(target),
        [1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
      );
      expect(
        smartTileVerticalEdges(target),
        [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
      );
      expect(
        smartTileCorners(target),
        [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
      );
      expect(target.id, targetBefore.id);
      expect(target.name, targetBefore.name);
      expect(target.isVisible, targetBefore.isVisible);
      expect(target.opacity, targetBefore.opacity);
      expect(target.presetId, targetBefore.presetId);
      expect(target.usage, targetBefore.usage);
      expect(target.layerSeed, targetBefore.layerSeed);
      expect(target.properties, targetBefore.properties);
      expect(mergeDraft.preview['removedSourceLayerIds'], [
        'l_qc02_path_compacted',
      ]);
      expect(mergeDraft.preview['mergedEntryCount'], 6);
      expect(
        () => MapValidator.validate(
          mergedMap,
          projectDialogueContext: fixture.manifest,
        ),
        returnsNormally,
      );
    });

    test('accepts an explicit material correspondence for compatible presets',
        () {
      final fixture = _m01Fixture(
        sourceMaterialId: 'compacted',
        sourcePresetId: 'path_compacted',
      );
      final normalizedMap = _projectedMap(
        const SmartTileLayerActions().build(
          _context(
            fixture.snapshot,
            actionId: 'smart_tile.layer.normalize',
            parameters: const {
              'mapId': 'map_hanazuki_village',
              'layerId': 'l_qc02_terrain',
            },
          ),
        ),
      );

      final draft = const SmartTileLayerActions().build(
        _context(
          _snapshot(fixture.manifest, normalizedMap),
          actionId: 'smart_tile.layer.merge',
          parameters: const {
            'mapId': 'map_hanazuki_village',
            'sourceLayerIds': ['l_qc02_path_compacted'],
            'targetLayerId': 'l_qc02_path_dirt',
            'mode': 'union',
            'removeSources': true,
            'conflictPolicy': 'reject',
            'materialMappings': {
              'l_qc02_path_compacted': {'compacted': 'dirt'},
            },
          },
        ),
      );
      final target = _projectedMap(draft).layers[2] as SmartTileLayer;

      expect(target.materialPalette, ['', 'dirt']);
      expect(smartTileSemanticCells(target), [0, 1, 0, 1, 1, 1, 0, 1, 0]);
      expect(draft.preview['materialMappingsApplied'], 1);
    });

    test('rejects incompatible usage before removing a source layer', () {
      final fixture = _m01Fixture(sourceUsage: SmartTileUsage.forestSurface);
      final originalBytes = fixture.snapshot.resourceBytes(
        'map:map_hanazuki_village',
      );

      expect(
        () => const SmartTileLayerActions().build(
          _context(
            fixture.snapshot,
            actionId: 'smart_tile.layer.merge',
            parameters: const {
              'mapId': 'map_hanazuki_village',
              'sourceLayerIds': ['l_qc02_path_compacted'],
              'targetLayerId': 'l_qc02_path_dirt',
              'mode': 'union',
              'removeSources': true,
              'conflictPolicy': 'reject',
            },
          ),
        ),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'smart_tile.layer_usage_incompatible',
          ),
        ),
      );
      expect(
        fixture.snapshot.resourceBytes('map:map_hanazuki_village'),
        originalBytes,
      );
      expect(
        fixture.map.layers.map((layer) => layer.id),
        contains('l_qc02_path_compacted'),
      );
    });

    test('rejects source lattices that do not match the map dimensions', () {
      final fixture = _m01Fixture();
      final source = fixture.map.layers[3] as SmartTileLayer;
      final malformed = fixture.map.copyWith(
        layers: [
          ...fixture.map.layers.take(3),
          source.copyWith(
            field: SmartTileField.mixed(
              semanticCells: smartTileSemanticCells(source).take(8).toList(),
              horizontalEdges: smartTileHorizontalEdges(source),
              verticalEdges: smartTileVerticalEdges(source),
              corners: smartTileCorners(source),
            ),
          ),
          fixture.map.layers[4],
        ],
      );

      expect(
        () => const SmartTileLayerActions().build(
          _context(
            _snapshot(fixture.manifest, malformed),
            actionId: 'smart_tile.layer.merge',
            parameters: const {
              'mapId': 'map_hanazuki_village',
              'sourceLayerIds': ['l_qc02_path_compacted'],
              'targetLayerId': 'l_qc02_path_dirt',
              'mode': 'union',
              'removeSources': true,
              'conflictPolicy': 'reject',
            },
          ),
        ),
        throwsA(
          isA<MapAuthoringException>()
              .having(
                (error) => error.code,
                'code',
                'smart_tile.layer_dimensions_incompatible',
              )
              .having(
                (error) => error.details['field'],
                'field',
                'semanticCells',
              ),
        ),
      );
    });

    test('rejects presets with incompatible topology', () {
      final fixture = _m01Fixture();
      final catalog = fixture.manifest.smartTileCatalog;
      final manifest = fixture.manifest.copyWith(
        smartTileCatalog: ProjectSmartTileCatalog(
          formatVersion: catalog.formatVersion,
          categories: catalog.categories,
          atlases: catalog.atlases,
          materials: catalog.materials,
          animations: catalog.animations,
          presets: [
            ...catalog.presets,
            const ProjectSmartTilePreset(
              id: 'path_blob',
              name: 'Blob path',
              usage: SmartTileUsage.path,
              topology: SmartTileTopology.blob8,
              templateHint: SmartTileTemplateHint.blob47,
              coveragePolicy: SmartTileCoveragePolicy.complete,
              coverageProfile: SmartTileCoverageProfile(
                mode: SmartTileCoverageMode.template,
              ),
              transformPolicy: SmartTileTransformPolicy(),
              defaultMaterialId: 'dirt',
              allowedMaterialIds: ['dirt'],
            ),
          ],
        ),
      );
      final source = fixture.map.layers[3] as SmartTileLayer;
      final map = fixture.map.copyWith(
        layers: [
          ...fixture.map.layers.take(3),
          source.copyWith(presetId: 'path_blob'),
          fixture.map.layers[4],
        ],
      );

      expect(
        () => const SmartTileLayerActions().build(
          _context(
            _snapshot(manifest, map),
            actionId: 'smart_tile.layer.merge',
            parameters: const {
              'mapId': 'map_hanazuki_village',
              'sourceLayerIds': ['l_qc02_path_compacted'],
              'targetLayerId': 'l_qc02_path_dirt',
              'mode': 'union',
              'removeSources': true,
              'conflictPolicy': 'reject',
            },
          ),
        ),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'smart_tile.layer_preset_incompatible',
          ),
        ),
      );
    });

    test('rejects ambiguous overlaps with lattice and material diagnostics',
        () {
      final fixture = _m01Fixture(conflictingSourceMaterial: 'stone');

      expect(
        () => const SmartTileLayerActions().build(
          _context(
            fixture.snapshot,
            actionId: 'smart_tile.layer.merge',
            parameters: const {
              'mapId': 'map_hanazuki_village',
              'sourceLayerIds': ['l_qc02_path_compacted'],
              'targetLayerId': 'l_qc02_path_dirt',
              'mode': 'union',
              'removeSources': false,
              'conflictPolicy': 'reject',
            },
          ),
        ),
        throwsA(
          isA<MapAuthoringException>()
              .having(
                (error) => error.code,
                'code',
                'smart_tile.layer_merge_conflict',
              )
              .having(
                (error) => error.details['lattice'],
                'lattice',
                'semanticCells',
              )
              .having((error) => error.details['offset'], 'offset', 4),
        ),
      );
    });

    test('direct API and JSONL apply the same complete M01 repair', () async {
      final direct = await _M01TransportHarness.create('direct');
      final jsonl = await _M01TransportHarness.create('jsonl');
      addTearDown(direct.dispose);
      addTearDown(jsonl.dispose);

      final directResult = await direct.applyDirect();
      final jsonlResult = await jsonl.applyJsonl();

      expect(jsonlResult.map.toJson(), directResult.map.toJson());
      expect(directResult.map.version, ProjectVersion.v6);
      expect(jsonlResult.map.version, ProjectVersion.v6);
      expect(directResult.actionIds, [
        'smart_tile.layer.normalize',
        'smart_tile.layer.merge',
        'smart_tile.layer.set_animation_activation',
      ]);
      expect(jsonlResult.actionIds, directResult.actionIds);
      for (final validation in [
        directResult.validation,
        jsonlResult.validation,
      ]) {
        expect(
          validation['valid'],
          isTrue,
          reason: validation.toString(),
        );
        expect(validation['structure'], containsPair('valid', true));
        expect(validation['references'], containsPair('valid', true));
        expect(
          validation['capabilityCertification'],
          containsPair('status', 'not_requested'),
        );
      }
      expect(
        directResult.map.layers.map((layer) => layer.id),
        [
          'l_base',
          'l_qc02_terrain',
          'l_qc02_path_dirt',
          'l_collisions',
        ],
      );
      final merged = directResult.map.layers[2] as SmartTileLayer;
      expect(smartTileSemanticCells(merged), [0, 1, 0, 1, 1, 1, 0, 1, 0]);
      expect(merged.name, 'Target path metadata');
      expect(merged.properties, {'role': 'main', 'keep': 'yes'});
      expect(
        merged.animationActivation,
        SmartTileAnimationActivation.onEnter,
      );
    });

    test('direct API and JSONL confirm the same reconstruction plan', () async {
      final direct = await _M01TransportHarness.create(
        'reconstruct_direct',
        reconstruction: true,
      );
      final jsonl = await _M01TransportHarness.create(
        'reconstruct_jsonl',
        reconstruction: true,
      );
      addTearDown(direct.dispose);
      addTearDown(jsonl.dispose);

      final directResult = await direct.applyDirectReconstruction();
      final jsonlResult = await jsonl.applyJsonlReconstruction();

      expect(jsonlResult.toJson(), directResult.toJson());
      expect(directResult.layers.map((layer) => layer.id), <String>[
        'literal',
        'native',
      ]);
      expect(
          directResult.layers.first, _reconstructionFixture().map.layers.first);
      expect((directResult.layers.last as SmartTileLayer).isVisible, isFalse);
    });
  });

  group('smart_tile.layer.set_candidate_weights', () {
    const rules = <SmartTileRule>[
      SmartTileRule(
        id: 'fill',
        centerMatch: SmartTileSlotMatch.any(),
        candidates: <SmartTileCandidate>[
          SmartTileCandidate(id: 'fill-a', weight: 1000),
          SmartTileCandidate(id: 'fill-b', weight: 1000),
        ],
      ),
    ];

    // Fixture dédié : le _m01Fixture partagé porte un calque terrain dont la
    // palette sort du preset — une incohérence dormante que la validation de
    // carte projetée refuse dès qu'un draft complet la traverse.
    ProjectSnapshot snapshotWith({
      Map<String, int> layerWeights = const <String, int>{},
    }) {
      final manifest = ProjectManifest(
        name: 'Candidate weights fixture',
        version: ProjectVersion.v6,
        maps: const [
          ProjectMapEntry(
            id: 'map_hanazuki_village',
            name: 'Hanazuki Village',
            relativePath: 'maps/map_hanazuki_village.json',
          ),
        ],
        tilesets: const [],
        smartTileCatalog: ProjectSmartTileCatalog(
          materials: const [
            ProjectSmartTileMaterial(
              id: 'dirt',
              name: 'Dirt',
              connectionGroupId: 'path',
            ),
          ],
          presets: const [
            ProjectSmartTilePreset(
              id: 'path',
              name: 'Path',
              usage: SmartTileUsage.path,
              topology: SmartTileTopology.wang8,
              templateHint: SmartTileTemplateHint.mixed256,
              status: SmartTilePresetStatus.published,
              coveragePolicy: SmartTileCoveragePolicy.complete,
              coverageProfile: SmartTileCoverageProfile(
                mode: SmartTileCoverageMode.template,
              ),
              transformPolicy: SmartTileTransformPolicy(),
              defaultMaterialId: 'dirt',
              allowedMaterialIds: ['dirt'],
              rules: rules,
            ),
          ],
        ),
      );
      final map = MapData(
        id: 'map_hanazuki_village',
        name: 'Hanazuki Village',
        size: const GridSize(width: 3, height: 3),
        version: ProjectVersion.v6,
        visualStack: MapVisualStackConfig.canonicalV1,
        layers: [
          MapLayer.tile(
            id: 'l_base',
            name: 'Base',
            cells: List<int>.filled(9, 0),
          ),
          MapLayer.smartTile(
            id: 'l_qc02_path_dirt',
            name: 'Path',
            presetId: 'path',
            usage: SmartTileUsage.path,
            materialPalette: const ['', 'dirt'],
            field: SmartTileField.mixed(
              semanticCells: const [0, 0, 0, 1, 1, 1, 0, 0, 0],
              horizontalEdges: List<int>.filled(12, 0),
              verticalEdges: List<int>.filled(12, 0),
              corners: List<int>.filled(16, 0),
            ),
            candidateWeights: layerWeights,
          ),
        ],
      );
      return _snapshot(manifest, map);
    }

    AuthoringMutationDraft build(
      ProjectSnapshot snapshot,
      Map<String, Object?> weights,
    ) =>
        const SmartTileLayerActions().build(
          _context(
            snapshot,
            actionId: 'smart_tile.layer.set_candidate_weights',
            parameters: <String, Object?>{
              'mapId': 'map_hanazuki_village',
              'layerId': 'l_qc02_path_dirt',
              'weights': weights,
            },
          ),
        );

    SmartTileLayer projectedLayer(AuthoringMutationDraft draft) =>
        _projectedMap(draft)
            .layers
            .whereType<SmartTileLayer>()
            .firstWhere((layer) => layer.id == 'l_qc02_path_dirt');

    test('remplace la table du calque et la prévisualise', () {
      final draft = build(
        snapshotWith(),
        const <String, Object?>{'fill-a': 900, 'fill-b': 100},
      );

      expect(
        projectedLayer(draft).candidateWeights,
        <String, int>{'fill-a': 900, 'fill-b': 100},
      );
      expect(
        draft.preview,
        containsPair('operation', 'smart_tile.layer.set_candidate_weights'),
      );
      expect(draft.preview, containsPair('overriddenCandidateCount', 2));
    });

    test('remplace, ne fusionne pas', () {
      final draft = build(
        snapshotWith(
          layerWeights: const <String, int>{'fill-a': 1, 'fill-b': 999},
        ),
        const <String, Object?>{'fill-a': 500},
      );

      expect(
        projectedLayer(draft).candidateWeights,
        <String, int>{'fill-a': 500},
      );
    });

    test('une table vide rend le calque au preset', () {
      final draft = build(
        snapshotWith(layerWeights: const <String, int>{'fill-a': 1}),
        const <String, Object?>{},
      );

      expect(projectedLayer(draft).candidateWeights, isEmpty);
    });

    test('refuse un poids négatif ou non entier', () {
      final snapshot = snapshotWith();

      for (final invalid in <Object?>[-1, 'lourd', 1.5]) {
        expect(
          () => build(snapshot, <String, Object?>{'fill-a': invalid}),
          throwsA(
            isA<MapAuthoringException>().having(
              (error) => error.code,
              'code',
              'smart_tile.candidate_weight_invalid',
            ),
          ),
        );
      }
    });

    test('refuse un candidat absent du preset', () {
      expect(
        () => build(snapshotWith(), const <String, Object?>{'fantome': 10}),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'smart_tile.candidate_weight_unknown',
          ),
        ),
      );
    });

    test('refuse de vider une règle de tout candidat positif', () {
      expect(
        () => build(
          snapshotWith(),
          const <String, Object?>{'fill-a': 0, 'fill-b': 0},
        ),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'smart_tile.rule_without_positive_candidate',
          ),
        ),
      );
    });
  });

  group('smart_tile.layer.set_animation_activation', () {
    final manifest = ProjectManifest(
      name: 'Animation activation fixture',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'map_hanazuki_village',
          name: 'Map',
          relativePath: 'maps/map_hanazuki_village.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[
        ProjectTilesetEntry(
          id: 'grass-tileset',
          name: 'Grass',
          relativePath: 'tilesets/grass.png',
        ),
      ],
      smartTileCatalog: ProjectSmartTileCatalog(
        atlases: const <ProjectSmartTileAtlas>[
          ProjectSmartTileAtlas(
            id: 'grass-atlas',
            name: 'Grass',
            tilesetId: 'grass-tileset',
            columns: 1,
            rows: 1,
          ),
        ],
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'grass',
          ),
        ],
        presets: const <ProjectSmartTilePreset>[
          ProjectSmartTilePreset(
            id: 'grass-preset',
            name: 'Tall grass',
            usage: SmartTileUsage.path,
            topology: SmartTileTopology.uniform,
            templateHint: SmartTileTemplateHint.simple,
            status: SmartTilePresetStatus.published,
            coveragePolicy: SmartTileCoveragePolicy.complete,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'grass',
            allowedMaterialIds: <String>['grass'],
            rules: <SmartTileRule>[
              SmartTileRule(
                id: 'fill',
                centerMatch: SmartTileSlotMatch.material('grass'),
                candidates: <SmartTileCandidate>[
                  SmartTileCandidate(
                    id: 'fill',
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
    final map = MapData(
      id: 'map_hanazuki_village',
      name: 'Map',
      version: ProjectVersion.v6,
      size: const GridSize(width: 2, height: 1),
      layers: const <MapLayer>[
        SmartTileLayer(
          id: 'grass',
          name: 'Tall grass',
          presetId: 'grass-preset',
          usage: SmartTileUsage.path,
          materialPalette: <String>['', 'grass'],
          field: SmartTileField.cell(semanticCells: <int>[1, 1]),
        ),
      ],
    );

    test('changes only the layer activation policy', () {
      final snapshot = _snapshot(manifest, map);
      final before = map.layers.single as SmartTileLayer;
      final draft = const SmartTileLayerActions().build(
        _context(
          snapshot,
          actionId: 'smart_tile.layer.set_animation_activation',
          parameters: const <String, Object?>{
            'mapId': 'map_hanazuki_village',
            'layerId': 'grass',
            'activation': 'on_enter',
          },
        ),
      );
      final after = _projectedMap(draft).layers.single as SmartTileLayer;

      expect(
        after,
        before.copyWith(
          animationActivation: SmartTileAnimationActivation.onEnter,
        ),
      );
      expect(draft.preview, containsPair('activation', 'on_enter'));
      expect(draft.preview, containsPair('geometryPreserved', true));
    });

    test('rejects an unknown activation policy', () {
      expect(
        () => const SmartTileLayerActions().build(
          _context(
            _snapshot(manifest, map),
            actionId: 'smart_tile.layer.set_animation_activation',
            parameters: const <String, Object?>{
              'mapId': 'map_hanazuki_village',
              'layerId': 'grass',
              'activation': 'sometimes_maybe',
            },
          ),
        ),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'smart_tile.animation_activation_invalid',
          ),
        ),
      );
    });
  });

  group('Smart Tile encounter behavior', () {
    final fixture = _m01Fixture();
    final manifest = fixture.manifest.copyWith(
      encounterTables: const <ProjectEncounterTable>[
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
    );
    final map = fixture.map.copyWith(
      layers: <MapLayer>[
        (fixture.map.layers[2] as SmartTileLayer).copyWith(
          id: 'grass',
          isVisible: true,
          materialPalette: const <String>['', 'dirt'],
          field: const SmartTileField.mixed(
            semanticCells: <int>[1, 0, 0, 0, 0, 0, 0, 0, 0],
            horizontalEdges: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            verticalEdges: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            corners: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
        ),
      ],
    );

    test('sets then clears the behavior without generating gameplay zones', () {
      final setDraft = const SmartTileLayerActions().build(
        _context(
          _snapshot(manifest, map),
          actionId: 'smart_tile.layer.set_encounter_behavior',
          parameters: const <String, Object?>{
            'mapId': 'map_hanazuki_village',
            'layerId': 'grass',
            'materialId': 'dirt',
            'priority': 4,
            'encounterTableId': 'route_grass',
            'encounterKind': 'walk',
          },
        ),
      );
      final withBehavior = _projectedMap(setDraft);
      final behavior =
          (withBehavior.layers.single as SmartTileLayer).encounterBehavior;

      expect(behavior?.materialId, 'dirt');
      expect(behavior?.priority, 4);
      expect(behavior?.encounter.encounterTableId, 'route_grass');
      expect(withBehavior.gameplayZones, isEmpty);
      expect(setDraft.preview, containsPair('gameplayZonesChanged', false));

      final clearDraft = const SmartTileLayerActions().build(
        _context(
          _snapshot(manifest, withBehavior),
          actionId: 'smart_tile.layer.clear_encounter_behavior',
          parameters: const <String, Object?>{
            'mapId': 'map_hanazuki_village',
            'layerId': 'grass',
          },
        ),
      );
      expect(
        (_projectedMap(clearDraft).layers.single as SmartTileLayer)
            .encounterBehavior,
        isNull,
      );
    });
  });
}

final class _M01TransportHarness {
  const _M01TransportHarness._({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
  });

  static Future<_M01TransportHarness> create(
    String label, {
    ProjectVersion version = ProjectVersion.v6,
    bool reconstruction = false,
  }) async {
    final root = await Directory.systemTemp.createTemp('m01_$label');
    final fixture = reconstruction
        ? _reconstructionFixture()
        : _m01Fixture(version: version);
    final persistedManifest = version == ProjectVersion.v6
        ? fixture.manifest
        : fixture.manifest.copyWith(
            smartTileCatalog: ProjectSmartTileCatalog(),
          );
    final persistedMap = version == ProjectVersion.v6
        ? fixture.map
        : fixture.map.copyWith(
            layers: [fixture.map.layers.first, fixture.map.layers.last],
          );
    await Directory('${root.path}/maps').create();
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(persistedManifest.toJson()),
      flush: true,
    );
    await File('${root.path}/maps/map_hanazuki_village.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(persistedMap.toJson()),
      flush: true,
    );
    for (final directory in [
      'species',
      'learnsets',
      'evolutions',
      'media',
    ]) {
      await Directory('${root.path}/data/pokemon/$directory')
          .create(recursive: true);
    }
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
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
    return _M01TransportHarness._(
      root: root,
      readApi: readApi,
      mutations: mutations,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  Future<
      ({
        String code,
        String beforeRevision,
        String afterRevision,
        List<int> beforeMapBytes,
        List<int> afterMapBytes,
      })> rejectJsonl({
    required String actionId,
    required Map<String, Object?> parameters,
    required String sequence,
  }) async {
    final opened = await _jsonl('open', {'projectRoot': root.path});
    final projectHandle = opened['projectHandle']! as String;
    final workspaceHandle = opened['workspaceHandle']! as String;
    final project = ProjectHandle(projectHandle);
    final before = await snapshots.load(project);
    final mapFile = File('${root.path}/maps/map_hanazuki_village.json');
    final beforeMapBytes = await mapFile.readAsBytes();
    final rejected = await _jsonlResult('plan', {
      'projectHandle': projectHandle,
      'request': _transportRequest(
        actionId: actionId,
        parameters: parameters,
        sequence: sequence,
        workspaceHandle: workspaceHandle,
        revision: before.revision,
      ).toJson(),
    });
    expect(rejected.status, AuthoringResultStatus.failure);
    final after = await snapshots.load(project);
    return (
      code: rejected.error?.details['domainCode']! as String,
      beforeRevision: before.revision,
      afterRevision: after.revision,
      beforeMapBytes: beforeMapBytes,
      afterMapBytes: await mapFile.readAsBytes(),
    );
  }

  Future<MapData> applyDirectReconstruction() async {
    final opened = await readApi.open(root.path);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    final project = ProjectHandle(opened['projectHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    final snapshot = await snapshots.load(project);
    final planned = await mutations.plan(
      project,
      _transportRequest(
        actionId: 'smart_tile.layer.reconstruct',
        parameters: _reconstructionParameters,
        sequence: 'reconstruct_direct',
        workspaceHandle: workspace.value,
        revision: snapshot.revision,
      ),
    );
    final confirmation = await mutations.confirm(
      project,
      planId: planned['planId']! as String,
    );
    await mutations.apply(
      project,
      planId: planned['planId']! as String,
      operationId: 'operation_reconstruct_direct',
      confirmationToken: confirmation['confirmationToken']! as String,
    );
    return _readMap();
  }

  Future<MapData> applyJsonlReconstruction() async {
    final opened = await _jsonl('open', {'projectRoot': root.path});
    final projectHandle = opened['projectHandle']! as String;
    final validation = await _jsonl(
      'validate',
      {'projectHandle': projectHandle},
    );
    final planned = await _jsonl('plan', <String, Object?>{
      'projectHandle': projectHandle,
      'request': _transportRequest(
        actionId: 'smart_tile.layer.reconstruct',
        parameters: _reconstructionParameters,
        sequence: 'reconstruct_jsonl',
        workspaceHandle: opened['workspaceHandle']! as String,
        revision: validation['snapshotRevision']! as String,
      ).toJson(),
    });
    final confirmation = await _jsonl('confirm', <String, Object?>{
      'projectHandle': projectHandle,
      'planId': planned['planId'],
    });
    await _jsonl('apply', <String, Object?>{
      'projectHandle': projectHandle,
      'planId': planned['planId'],
      'operationId': 'operation_reconstruct_jsonl',
      'confirmationToken': confirmation['confirmationToken'],
    });
    return _readMap();
  }

  Future<
      ({
        MapData map,
        Map<String, Object?> validation,
        List<String> actionIds,
      })> applyDirect() async {
    final opened = await readApi.open(root.path);
    final workspace = WorkspaceHandle(opened['workspaceHandle']! as String);
    final project = ProjectHandle(opened['projectHandle']! as String);
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: workspace,
      projectHandle: project,
    );
    final actionIds = <String>[];

    Future<void> apply(
      String actionId,
      Map<String, Object?> parameters,
      String sequence,
    ) async {
      final snapshot = await snapshots.load(project);
      final planned = await mutations.plan(
        project,
        _transportRequest(
          actionId: actionId,
          parameters: parameters,
          sequence: sequence,
          workspaceHandle: workspace.value,
          revision: snapshot.revision,
        ),
      );
      final applied = await mutations.apply(
        project,
        planId: planned['planId']! as String,
        operationId: 'operation_direct_$sequence',
      );
      final receipt = applied['receipt']! as Map<String, Object?>;
      actionIds.add(receipt['actionId']! as String);
    }

    await apply(
      'smart_tile.layer.normalize',
      const {
        'mapId': 'map_hanazuki_village',
        'layerId': 'l_qc02_terrain',
      },
      'normalize',
    );
    await apply(
      'smart_tile.layer.merge',
      _mergeParameters,
      'merge',
    );
    await apply(
      'smart_tile.layer.set_animation_activation',
      const <String, Object?>{
        'mapId': 'map_hanazuki_village',
        'layerId': 'l_qc02_path_dirt',
        'activation': 'on_enter',
      },
      'animation_activation',
    );
    final validation = await readApi.validate(project);
    return (
      map: await _readMap(),
      validation: validation,
      actionIds: actionIds,
    );
  }

  Future<
      ({
        MapData map,
        Map<String, Object?> validation,
        List<String> actionIds,
      })> applyJsonl() async {
    final opened = await _jsonl('open', {'projectRoot': root.path});
    final projectHandle = opened['projectHandle']! as String;
    final workspaceHandle = opened['workspaceHandle']! as String;
    final actionIds = <String>[];

    Future<void> apply(
      String actionId,
      Map<String, Object?> parameters,
      String sequence,
    ) async {
      final validation = await _jsonl(
        'validate',
        {'projectHandle': projectHandle},
      );
      final planned = await _jsonl('plan', {
        'projectHandle': projectHandle,
        'request': _transportRequest(
          actionId: actionId,
          parameters: parameters,
          sequence: sequence,
          workspaceHandle: workspaceHandle,
          revision: validation['snapshotRevision']! as String,
        ).toJson(),
      });
      final applied = await _jsonl('apply', {
        'projectHandle': projectHandle,
        'planId': planned['planId'],
        'operationId': 'operation_jsonl_$sequence',
      });
      final receipt = applied['receipt']! as Map<String, Object?>;
      actionIds.add(receipt['actionId']! as String);
    }

    await apply(
      'smart_tile.layer.normalize',
      const {
        'mapId': 'map_hanazuki_village',
        'layerId': 'l_qc02_terrain',
      },
      'normalize',
    );
    await apply('smart_tile.layer.merge', _mergeParameters, 'merge');
    await apply(
      'smart_tile.layer.set_animation_activation',
      const <String, Object?>{
        'mapId': 'map_hanazuki_village',
        'layerId': 'l_qc02_path_dirt',
        'activation': 'on_enter',
      },
      'animation_activation',
    );
    final validation = await _jsonl(
      'validate',
      {'projectHandle': projectHandle},
    );
    return (
      map: await _readMap(),
      validation: validation,
      actionIds: actionIds,
    );
  }

  Future<Map<String, Object?>> _jsonl(
    String command,
    Map<String, Object?> args,
  ) async {
    final decoded = await _jsonlResult(command, args);
    expect(
      decoded.status,
      AuthoringResultStatus.success,
      reason: decoded.error?.toJson().toString(),
    );
    return decoded.data;
  }

  Future<AuthoringResult> _jsonlResult(
    String command,
    Map<String, Object?> args,
  ) async =>
      AuthoringResult.fromJson(
        jsonDecode(
          await worker.processLine(
            jsonEncode({
              'id': 'm01_$command',
              'command': command,
              'args': args,
            }),
          ),
        ) as Map<String, dynamic>,
      );

  Future<MapData> _readMap() async => MapData.fromJson(
        jsonDecode(
          await File('${root.path}/maps/map_hanazuki_village.json')
              .readAsString(),
        ) as Map<String, dynamic>,
      );

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

const Map<String, Object?> _mergeParameters = {
  'mapId': 'map_hanazuki_village',
  'sourceLayerIds': [
    'l_qc02_path_dirt',
    'l_qc02_path_compacted',
  ],
  'targetLayerId': 'l_qc02_path_dirt',
  'mode': 'union',
  'removeSources': true,
  'conflictPolicy': 'reject',
};

const Map<String, Object?> _reconstructionParameters = <String, Object?>{
  'mapId': 'map_hanazuki_village',
  'sourceLayerId': 'literal',
  'presetId': 'edge',
  'targetLayerId': 'native',
  'name': 'Native path',
};

AuthoringRequest _transportRequest({
  required String actionId,
  required Map<String, Object?> parameters,
  required String sequence,
  required String workspaceHandle,
  required String revision,
}) =>
    AuthoringRequest(
      requestId: 'request_$sequence',
      actionId: actionId,
      actionVersion: 1,
      workspaceHandle: workspaceHandle,
      parameters: parameters,
      expectedRevision: revision,
      idempotencyKey: 'idem_$sequence',
      dryRun: false,
    );

AuthoringPlanningContext _context(
  ProjectSnapshot snapshot, {
  required String actionId,
  required Map<String, Object?> parameters,
}) =>
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
        requestId: 'request_${actionId.replaceAll('.', '_')}',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: 'ws_m01',
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'idem_${actionId.replaceAll('.', '_')}',
        dryRun: true,
      ),
      planId: 'plan_m01',
      seed: 41,
    );

MapData _projectedMap(AuthoringMutationDraft draft) => MapData.fromJson(
      jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
          as Map<String, dynamic>,
    );

({
  ProjectManifest manifest,
  MapData map,
  ProjectSnapshot snapshot,
}) _m01Fixture({
  ProjectVersion version = ProjectVersion.v6,
  String sourceMaterialId = 'dirt',
  String sourcePresetId = 'path',
  SmartTileUsage sourceUsage = SmartTileUsage.path,
  String? conflictingSourceMaterial,
}) {
  final sourceMaterial = conflictingSourceMaterial ?? sourceMaterialId;
  final manifest = ProjectManifest(
    name: 'M01 Smart Tile fixture',
    version: version,
    maps: const [
      ProjectMapEntry(
        id: 'map_hanazuki_village',
        name: 'Hanazuki Village',
        relativePath: 'maps/map_hanazuki_village.json',
      ),
    ],
    tilesets: const [],
    smartTileCatalog: ProjectSmartTileCatalog(
      materials: const [
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Grass',
          connectionGroupId: 'ground',
        ),
        ProjectSmartTileMaterial(
          id: 'smart_material_empty',
          name: 'Legacy empty',
          connectionGroupId: 'empty',
          isEmpty: true,
        ),
        ProjectSmartTileMaterial(
          id: 'dirt',
          name: 'Dirt',
          connectionGroupId: 'path',
        ),
        ProjectSmartTileMaterial(
          id: 'compacted',
          name: 'Compacted dirt',
          connectionGroupId: 'path',
        ),
        ProjectSmartTileMaterial(
          id: 'stone',
          name: 'Stone',
          connectionGroupId: 'path',
        ),
      ],
      presets: [
        const ProjectSmartTilePreset(
          id: 'terrain',
          name: 'Terrain',
          usage: SmartTileUsage.terrain,
          topology: SmartTileTopology.wang8,
          templateHint: SmartTileTemplateHint.mixed256,
          coveragePolicy: SmartTileCoveragePolicy.complete,
          coverageProfile: SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ),
          transformPolicy: SmartTileTransformPolicy(),
          defaultMaterialId: 'grass',
          allowedMaterialIds: ['grass'],
        ),
        const ProjectSmartTilePreset(
          id: 'path',
          name: 'Path',
          usage: SmartTileUsage.path,
          topology: SmartTileTopology.wang8,
          templateHint: SmartTileTemplateHint.mixed256,
          coveragePolicy: SmartTileCoveragePolicy.complete,
          coverageProfile: SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ),
          transformPolicy: SmartTileTransformPolicy(),
          defaultMaterialId: 'dirt',
          allowedMaterialIds: ['dirt', 'stone'],
        ),
        const ProjectSmartTilePreset(
          id: 'path_compacted',
          name: 'Compacted path',
          usage: SmartTileUsage.path,
          topology: SmartTileTopology.wang8,
          templateHint: SmartTileTemplateHint.mixed256,
          coveragePolicy: SmartTileCoveragePolicy.complete,
          coverageProfile: SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ),
          transformPolicy: SmartTileTransformPolicy(),
          defaultMaterialId: 'compacted',
          allowedMaterialIds: ['compacted'],
        ),
        if (sourceUsage == SmartTileUsage.forestSurface)
          const ProjectSmartTilePreset(
            id: 'forest',
            name: 'Forest',
            usage: SmartTileUsage.forestSurface,
            topology: SmartTileTopology.wang8,
            templateHint: SmartTileTemplateHint.mixed256,
            coveragePolicy: SmartTileCoveragePolicy.complete,
            coverageProfile: SmartTileCoverageProfile(
              mode: SmartTileCoverageMode.template,
            ),
            transformPolicy: SmartTileTransformPolicy(),
            defaultMaterialId: 'dirt',
            allowedMaterialIds: ['dirt'],
          ),
      ],
    ),
  );
  final resolvedSourcePreset =
      sourceUsage == SmartTileUsage.forestSurface ? 'forest' : sourcePresetId;
  final map = MapData(
    id: 'map_hanazuki_village',
    name: 'Hanazuki Village',
    size: const GridSize(width: 3, height: 3),
    version: version,
    visualStack: MapVisualStackConfig.canonicalV1,
    layers: [
      MapLayer.tile(
        id: 'l_base',
        name: 'Base',
        cells: List<int>.filled(9, 0),
      ),
      MapLayer.smartTile(
        id: 'l_qc02_terrain',
        name: 'Terrain metadata',
        isVisible: false,
        opacity: 0.75,
        presetId: 'terrain',
        usage: SmartTileUsage.terrain,
        materialPalette: const ['', 'grass', 'smart_material_empty'],
        field: SmartTileField.mixed(
          semanticCells: List<int>.filled(9, 1),
          horizontalEdges: List<int>.filled(12, 0),
          verticalEdges: List<int>.filled(12, 0),
          corners: List<int>.filled(16, 0),
        ),
        layerSeed: 71,
        properties: const {'role': 'terrain', 'biome': 'village'},
      ),
      MapLayer.smartTile(
        id: 'l_qc02_path_dirt',
        name: 'Target path metadata',
        isVisible: false,
        opacity: 0.55,
        presetId: 'path',
        usage: SmartTileUsage.path,
        materialPalette: const ['', 'dirt'],
        field: SmartTileField.mixed(
          semanticCells: const [0, 0, 0, 1, 1, 1, 0, 0, 0],
          horizontalEdges: const [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
          verticalEdges: List<int>.filled(12, 0),
          corners: List<int>.filled(16, 0),
        ),
        layerSeed: 29,
        properties: const {'role': 'main', 'keep': 'yes'},
      ),
      MapLayer.smartTile(
        id: 'l_qc02_path_compacted',
        name: 'Source path',
        presetId: resolvedSourcePreset,
        usage: sourceUsage,
        materialPalette: ['', sourceMaterial],
        field: const SmartTileField.mixed(
          semanticCells: [0, 1, 0, 0, 1, 0, 0, 1, 0],
          horizontalEdges: [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
          verticalEdges: [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
          corners: [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
        ),
      ),
      MapLayer.collision(
        id: 'l_collisions',
        name: 'Collisions',
        collisions: List<bool>.filled(9, false),
      ),
    ],
  );
  return (
    manifest: manifest,
    map: map,
    snapshot: _snapshot(manifest, map),
  );
}

({
  ProjectManifest manifest,
  MapData map,
  ProjectSnapshot snapshot,
}) _reconstructionFixture() {
  const preset = ProjectSmartTilePreset(
    id: 'edge',
    name: 'Edge',
    usage: SmartTileUsage.path,
    topology: SmartTileTopology.wangEdge4,
    status: SmartTilePresetStatus.published,
    coveragePolicy: SmartTileCoveragePolicy.sparse,
    coverageProfile: SmartTileCoverageProfile(
      mode: SmartTileCoverageMode.explicit,
      requiredScenarios: <SmartTileCoverageScenario>[
        SmartTileCoverageScenario(
          id: 'north_grass',
          centerMaterialId: 'dirt',
          signature: SmartTileExactSignature(northEdge: 'grass'),
        ),
      ],
    ),
    transformPolicy: SmartTileTransformPolicy(),
    defaultMaterialId: 'dirt',
    allowedMaterialIds: <String>['dirt', 'grass'],
    rules: <SmartTileRule>[
      SmartTileRule(
        id: 'north_grass',
        centerMatch: SmartTileSlotMatch.any(),
        signature: SmartTileSignature(
          northEdge: SmartTileSlotMatch.material('grass'),
        ),
        candidates: <SmartTileCandidate>[
          SmartTileCandidate(
            id: 'north_grass_candidate',
            parts: <SmartTileVisualPart>[
              SmartTileVisualPart(
                source: SmartTileVisualSource.frame(
                  frame: SmartTileFrameRef(
                    atlasId: 'atlas',
                    column: 1,
                    row: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  final manifest = ProjectManifest(
    name: 'Reconstruction fixture',
    maps: <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map_hanazuki_village',
        name: 'Map',
        relativePath: 'maps/map_hanazuki_village.json',
      ),
    ],
    tilesets: <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tiles',
        name: 'Tiles',
        relativePath: 'tiles.png',
        source: ProjectTilesetSource.regularAtlas(
          assetId: 'asset',
          pixelWidth: 64,
          pixelHeight: 32,
          tileWidth: 32,
          tileHeight: 32,
        ),
      ),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: <ProjectSmartTileAtlas>[
        ProjectSmartTileAtlas(
          id: 'atlas',
          name: 'Atlas',
          tilesetId: 'tiles',
          columns: 2,
          rows: 1,
        ),
      ],
      materials: <ProjectSmartTileMaterial>[
        ProjectSmartTileMaterial(
          id: 'dirt',
          name: 'Dirt',
          connectionGroupId: 'ground',
        ),
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Grass',
          connectionGroupId: 'ground',
        ),
      ],
      presets: <ProjectSmartTilePreset>[preset],
    ),
  );
  const map = MapData(
    id: 'map_hanazuki_village',
    name: 'Map',
    version: ProjectVersion.v6,
    size: GridSize(width: 1, height: 1),
    layers: <MapLayer>[
      MapLayer.tile(
        id: 'literal',
        name: 'Literal',
        palette: <TileLayerPaletteEntry>[
          TileLayerPaletteEntry(tilesetId: 'tiles', localTileId: 1),
        ],
        cells: <int>[1],
      ),
    ],
  );
  return (manifest: manifest, map: map, snapshot: _snapshot(manifest, map));
}

ProjectSnapshot _snapshot(ProjectManifest manifest, MapData map) {
  final manifestBytes = _encode(manifest.toJson());
  final mapBytes = _encode(map.toJson());
  final projectRevision = computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
      relativePath: 'project.json',
      bytes: manifestBytes,
    ),
  ]);
  final mapRevision = computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
      relativePath: 'maps/map_hanazuki_village.json',
      bytes: mapBytes,
    ),
  ]);
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_m01'),
    revision: computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: manifestBytes,
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: 'maps/map_hanazuki_village.json',
        bytes: mapBytes,
      ),
    ]),
    manifest: manifest,
    maps: [map],
    resourceFingerprints: {
      'project': projectRevision,
      'map:map_hanazuki_village': mapRevision,
    },
    resourceStorageKeys: const {
      'project': 'project.json',
      'map:map_hanazuki_village': 'maps/map_hanazuki_village.json',
    },
    resourceBytes: {
      'project': manifestBytes,
      'map:map_hanazuki_village': mapBytes,
    },
  );
}

List<int> _encode(Object? value) =>
    utf8.encode(const JsonEncoder.withIndent('  ').convert(value));
