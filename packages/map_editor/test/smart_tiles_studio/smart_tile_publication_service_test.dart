import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_publication_service.dart';

void main() {
  group('SmartTilePublicationService', () {
    test('flushes then plans an explicit library publication', () async {
      final gateway = _FakeGateway(before: _snapshot());
      final service = SmartTilePublicationService(gateway: gateway);
      var flushed = false;

      final plan = await service.plan(
        projectRootPath: '/project',
        draftId: 'draft-grass',
        presetId: 'grass',
        target: const SmartTilePublicationTarget.library(),
        flushDraft: () async {
          flushed = true;
          gateway.didFlush = true;
        },
        diagnostics: <SmartTileDiagnostic>[_warning()],
      );

      expect(gateway.flushedBeforePlan, isTrue);
      expect(flushed, isTrue);
      expect(gateway.plannedParameters, <String, Object?>{
        'draftId': 'draft-grass',
      });
      expect(gateway.expectedRevision, 'revision-1');
      expect(plan.target.kind, SmartTilePublicationTargetKind.library);
      expect(plan.presetId, 'grass');
      expect(plan.layerId, isNull);
      expect(plan.warnings, hasLength(1));
      expect(plan.affectedResources.single.kind, 'project');
    });

    test('plans and adopts an atomic manifest plus map publication', () async {
      final before = _snapshot();
      const afterMap = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v6,
        size: GridSize(width: 2, height: 2),
        layers: <MapLayer>[
          MapLayer.smartTile(
            id: 'grass_layer',
            name: 'Herbe',
            presetId: 'grass',
            usage: SmartTileUsage.terrain,
            materialPalette: <String>['', 'grass'],
            field: SmartTileField.cell(
              semanticCells: <int>[1, 1, 1, 1],
            ),
          ),
        ],
      );
      final gateway = _FakeGateway(
        before: before,
        after: _snapshot(
          revision: 'revision-2',
          manifest: _publishedManifest(),
          maps: <MapData>[afterMap],
          mapRevisions: const <String, String>{'map': 'map-revision-2'},
        ),
        includeMapDiff: true,
      );
      final service = SmartTilePublicationService(gateway: gateway);
      var flushed = false;

      final plan = await service.plan(
        projectRootPath: '/project',
        draftId: 'draft-grass',
        presetId: 'grass',
        target: const SmartTilePublicationTarget.map(
          mapId: 'map',
          layerId: 'grass_layer',
          layerName: 'Herbe',
        ),
        flushDraft: () async {
          flushed = true;
          gateway.didFlush = true;
        },
      );
      final result = await service.apply(plan, projectRootPath: '/project');

      expect(flushed, isTrue);
      expect(gateway.plannedParameters, <String, Object?>{
        'draftId': 'draft-grass',
        'layer': <String, Object?>{
          'mapId': 'map',
          'layerId': 'grass_layer',
          'name': 'Herbe',
        },
      });
      expect(plan.affectedResources.map((resource) => resource.kind),
          containsAll(<String>['project', 'map']));
      expect(result.manifest.smartTileCatalog.drafts, isEmpty);
      expect(result.map, afterMap);
      expect(result.mapRevision, 'map-revision-2');
      expect(result.layerId, 'grass_layer');
      expect(gateway.appliedOperationId, '${plan.planId}-apply');
    });

    test('blocks diagnostics before flushing or planning', () async {
      final gateway = _FakeGateway(before: _snapshot());
      final service = SmartTilePublicationService(gateway: gateway);
      var flushed = false;

      await expectLater(
        service.plan(
          projectRootPath: '/project',
          draftId: 'draft-grass',
          presetId: 'grass',
          target: const SmartTilePublicationTarget.library(),
          flushDraft: () async => flushed = true,
          diagnostics: const <SmartTileDiagnostic>[
            SmartTileDiagnostic(
              code: 'smart_tile.test.blocking',
              severity: SmartTileDiagnosticSeverity.error,
              path: r'$.rules',
              message: 'Blocking',
            ),
          ],
        ),
        throwsA(
          isA<SmartTilePublicationException>().having(
            (failure) => failure.code,
            'code',
            'smart_tile.publish.incomplete',
          ),
        ),
      );
      expect(flushed, isFalse);
      expect(gateway.planCount, 0);
    });

    test('rejects a stale or missing durable draft', () async {
      final gateway = _FakeGateway(
        before: _snapshot(manifest: _publishedManifest()),
      )..didFlush = true;
      final service = SmartTilePublicationService(gateway: gateway);

      await expectLater(
        service.plan(
          projectRootPath: '/project',
          draftId: 'draft-grass',
          presetId: 'grass',
          target: const SmartTilePublicationTarget.library(),
          flushDraft: () async {},
        ),
        throwsA(
          isA<SmartTilePublicationException>().having(
            (failure) => failure.code,
            'code',
            'smart_tile.draft.unknown',
          ),
        ),
      );
    });

    test('suggests stable editable layer ids without collisions', () {
      expect(
        SmartTilePublicationService.suggestLayerId(
          presetId: 'Chemin clair !',
          existingLayerIds: const <String>[],
        ),
        'chemin_clair_layer',
      );
      expect(
        SmartTilePublicationService.suggestLayerId(
          presetId: 'grass',
          existingLayerIds: const <String>[
            'grass_layer',
            'grass_layer_2',
          ],
        ),
        'grass_layer_3',
      );
    });

    test('publishPreset recharge le snapshot canonique publié', () async {
      final gateway = _FakeGateway(before: _snapshot());
      final service = SmartTilePublicationService(gateway: gateway);

      final result = await service.publishPreset(
        projectRootPath: '/project',
        preset: _preset(),
      );

      expect(result.manifest, gateway.after.manifest);
      expect(result.snapshotRevision, gateway.after.snapshotRevision);
      expect(gateway.plannedParameters!.keys, <String>['preset']);
      expect(
        (gateway.plannedParameters!['preset']! as Map<String, Object?>)['id'],
        'grass',
      );
      expect(gateway.expectedRevision, 'revision-1');
      expect(gateway.appliedOperationId, isNotNull);
    });

    test('publishPreset lie sa clé d\'idempotence à la révision', () async {
      // Revenir à une table déjà appliquée est le geste normal quand on
      // tâtonne sur un curseur. Une clé dérivée du seul contenu se répète
      // alors sur une révision différente, et le journal la refuse
      // (idempotency.payload_conflict).
      final gateway = _FakeGateway(before: _snapshot());
      final service = SmartTilePublicationService(gateway: gateway);

      await service.publishPreset(
        projectRootPath: '/project',
        preset: _preset(),
      );
      final first = gateway.lastIdempotencyKey;
      final firstRevision = gateway.expectedRevision;

      await service.publishPreset(
        projectRootPath: '/project',
        preset: _preset(),
      );

      expect(first, isNotNull);
      expect(gateway.expectedRevision, isNot(firstRevision));
      expect(gateway.lastIdempotencyKey, isNot(first));
    });
  });
}

final class _FakeGateway implements SmartTilePublicationGateway {
  _FakeGateway({
    required this.before,
    SmartTilePublicationCanonicalSnapshot? after,
    this.includeMapDiff = false,
  }) : after = after ??
            _snapshot(
              revision: 'revision-2',
              manifest: _publishedManifest(),
            );

  final SmartTilePublicationCanonicalSnapshot before;
  final SmartTilePublicationCanonicalSnapshot after;
  final bool includeMapDiff;
  bool didFlush = false;
  bool applied = false;
  int planCount = 0;
  Map<String, Object?>? plannedParameters;
  String? expectedRevision;
  String? appliedOperationId;
  String? lastIdempotencyKey;

  bool get flushedBeforePlan => didFlush;

  @override
  Future<SmartTilePublicationCanonicalSnapshot> load({
    required String projectRootPath,
  }) async =>
      applied ? after : before;

  @override
  Future<SmartTilePublicationCanonicalPlan> plan({
    required String projectRootPath,
    required Map<String, Object?> parameters,
    required String expectedRevision,
    required String idempotencyKey,
  }) async {
    planCount++;
    plannedParameters = parameters;
    this.expectedRevision = expectedRevision;
    lastIdempotencyKey = idempotencyKey;
    final resources = <AuthoringResourceRef>[
      AuthoringResourceRef(kind: 'project', id: 'project'),
      if (includeMapDiff) AuthoringResourceRef(kind: 'map', id: 'map'),
    ];
    final receipt = AuthoringReceipt(
      receiptId: 'receipt-publication',
      requestId: idempotencyKey,
      actionId: 'smart_tile.preset.publish',
      actionVersion: 1,
      status: AuthoringReceiptStatus.planned,
      beforeRevision: expectedRevision,
      afterRevision: 'revision-2',
      createdAtUtc: '2026-08-03T12:00:00.000Z',
      diff: AuthoringDiff(<AuthoringDiffEntry>[
        for (final resource in resources)
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: resource,
            path: resource.kind == 'map'
                ? '/layers/grass_layer'
                : '/smartTileCatalog/presets/grass',
            after: const <String, Object?>{'published': true},
          ),
      ]),
      extensions: const <String, Object?>{
        'preview': <String, Object?>{
          'operation': 'smart_tile.preset.publish',
          'batchAtomicity': 'all_or_nothing',
        },
      },
    );
    return SmartTilePublicationCanonicalPlan(
      token: Object(),
      planId: 'plan-publication',
      snapshotRevision: expectedRevision,
      receipt: receipt,
    );
  }

  @override
  Future<String> apply({
    required SmartTilePublicationCanonicalPlan plan,
    required String operationId,
  }) async {
    applied = true;
    appliedOperationId = operationId;
    return after.snapshotRevision;
  }
}

SmartTilePublicationCanonicalSnapshot _snapshot({
  String revision = 'revision-1',
  ProjectManifest? manifest,
  List<MapData> maps = const <MapData>[],
  Map<String, String> mapRevisions = const <String, String>{},
}) =>
    SmartTilePublicationCanonicalSnapshot(
      snapshotRevision: revision,
      manifest: manifest ?? _draftManifest(),
      maps: maps,
      mapRevisions: mapRevisions,
    );

ProjectManifest _draftManifest() => ProjectManifest(
      name: 'Publication test',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      smartTileCatalog: ProjectSmartTileCatalog(
        drafts: <ProjectSmartTileAuthoringDraft>[_draft()],
      ),
    );

ProjectManifest _publishedManifest() => ProjectManifest(
      name: 'Publication test',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      smartTileCatalog: ProjectSmartTileCatalog(
        presets: <ProjectSmartTilePreset>[_preset()],
      ),
    );

ProjectSmartTileAuthoringDraft _draft() => const ProjectSmartTileAuthoringDraft(
      id: 'draft-grass',
      targetPresetId: 'grass',
      name: 'Grass',
      usage: SmartTileUsage.terrain,
      lastStage: SmartTileAuthoringStage.publish,
    );

ProjectSmartTilePreset _preset() => const ProjectSmartTilePreset(
      id: 'grass',
      name: 'Grass',
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.uniform,
      status: SmartTilePresetStatus.published,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: SmartTileTransformPolicy(),
      defaultMaterialId: 'grass',
      allowedMaterialIds: <String>['grass'],
    );

SmartTileDiagnostic _warning() => const SmartTileDiagnostic(
      code: 'smart_tile.test.warning',
      severity: SmartTileDiagnosticSeverity.warning,
      path: r'$.rules',
      message: 'Warning',
    );
