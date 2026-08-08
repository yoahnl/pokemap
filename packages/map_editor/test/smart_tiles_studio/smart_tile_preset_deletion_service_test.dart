import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_preset_deletion_service.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_publication_service.dart';

void main() {
  group('SmartTilePresetDeletionService', () {
    test('confirme puis applique la suppression canonique', () async {
      final gateway = _FakeDeletionGateway(
        before: _snapshot(presets: <ProjectSmartTilePreset>[_preset]),
        after: _snapshot(revision: 'revision-2'),
      );
      final service = SmartTilePresetDeletionService(gateway: gateway);

      final result = await service.deletePreset(
        projectRootPath: '/project',
        presetId: 'grass',
      );

      expect(gateway.plannedPresetId, 'grass');
      expect(gateway.expectedRevision, 'revision-1');
      expect(gateway.confirmedAndApplied, isTrue);
      expect(result.snapshotRevision, 'revision-2');
      expect(result.manifest.smartTileCatalog.presets, isEmpty);
    });

    test('traduit le blocage des références sans confirmer', () async {
      final gateway = _FakeDeletionGateway(
        before: _snapshot(presets: <ProjectSmartTilePreset>[_preset]),
        after: _snapshot(revision: 'revision-2'),
        planFailure: const EditorAuthoringMutationFailure(
          code: 'smart_tile.preset.references_blocking',
          message: 'The Smart Tile preset is still referenced by map layers.',
        ),
      );
      final service = SmartTilePresetDeletionService(gateway: gateway);

      await expectLater(
        service.deletePreset(
          projectRootPath: '/project',
          presetId: 'grass',
        ),
        throwsA(
          isA<EditorAuthoringMutationFailure>()
              .having(
                (failure) => failure.code,
                'code',
                'smart_tile.preset.references_blocking',
              )
              .having(
                (failure) => failure.message,
                'message',
                contains('utilisé par une ou plusieurs couches'),
              ),
        ),
      );
      expect(gateway.confirmedAndApplied, isFalse);
    });
  });
}

final class _FakeDeletionGateway implements SmartTilePresetDeletionGateway {
  _FakeDeletionGateway({
    required this.before,
    required this.after,
    this.planFailure,
  });

  final SmartTilePublicationCanonicalSnapshot before;
  final SmartTilePublicationCanonicalSnapshot after;
  final Object? planFailure;
  bool confirmedAndApplied = false;
  String? plannedPresetId;
  String? expectedRevision;

  @override
  Future<SmartTilePublicationCanonicalSnapshot> load({
    required String projectRootPath,
  }) async =>
      confirmedAndApplied ? after : before;

  @override
  Future<SmartTilePresetDeletionCanonicalPlan> planDelete({
    required String projectRootPath,
    required String presetId,
    required String expectedRevision,
    required String idempotencyKey,
  }) async {
    final failure = planFailure;
    if (failure != null) throw failure;
    plannedPresetId = presetId;
    this.expectedRevision = expectedRevision;
    return const SmartTilePresetDeletionCanonicalPlan(
      token: Object(),
      planId: 'delete-grass',
    );
  }

  @override
  Future<String> confirmAndApply({
    required SmartTilePresetDeletionCanonicalPlan plan,
    required String operationId,
  }) async {
    confirmedAndApplied = true;
    return after.snapshotRevision;
  }
}

SmartTilePublicationCanonicalSnapshot _snapshot({
  String revision = 'revision-1',
  List<ProjectSmartTilePreset> presets = const <ProjectSmartTilePreset>[],
}) =>
    SmartTilePublicationCanonicalSnapshot(
      snapshotRevision: revision,
      manifest: ProjectManifest(
        name: 'Deletion test',
        version: ProjectVersion.v6,
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        smartTileCatalog: ProjectSmartTileCatalog(presets: presets),
      ),
      maps: const <MapData>[],
      mapRevisions: const <String, String>{},
    );

const _preset = ProjectSmartTilePreset(
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
