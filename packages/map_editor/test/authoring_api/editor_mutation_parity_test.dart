import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/use_cases/map_use_cases.dart';
import 'package:map_editor/src/infrastructure/authoring_api/editor_project_file_reader.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  group('AuthoringMutationAdapter', () {
    test('plans without writing, applies once, and replays idempotently',
        () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      final before = await File(fixture.mapPath).readAsBytes();
      final updated = fixture.map.copyWith(name: 'Edited through Authoring');

      final plan = await fixture.mutations.plan(
        fixture.root.path,
        actionId: 'map.save',
        parameters: {'map': updated.toJson()},
        idempotencyKey: 'editor_save_plan_01',
      );

      expect(await File(fixture.mapPath).readAsBytes(), before);
      expect(plan.receipt.status, AuthoringReceiptStatus.planned);
      expect(plan.receipt.actionId, 'map.save');

      final applied = await fixture.mutations.apply(
        plan,
        operationId: 'editor_save_apply_01',
      );
      final replay = await fixture.mutations.apply(
        plan,
        operationId: 'editor_save_apply_01',
      );

      expect(replay.receipt.toJson(), applied.receipt.toJson());
      expect(applied.receipt.status, AuthoringReceiptStatus.applied);
      expect((await FileMapRepository().loadMap(fixture.mapPath)).name,
          'Edited through Authoring');
    });

    test('product SaveMapUseCase returns Authoring receipt parity', () async {
      final direct = await _MutationFixture.create();
      final product = await _MutationFixture.create();
      addTearDown(direct.dispose);
      addTearDown(product.dispose);
      final directMap = direct.map.copyWith(name: 'Receipt parity');
      final productMap = product.map.copyWith(name: 'Receipt parity');

      final directPlan = await direct.mutations.plan(
        direct.root.path,
        actionId: 'map.save',
        parameters: {'map': directMap.toJson()},
        idempotencyKey: 'direct_receipt_parity',
      );
      final directResult = await direct.mutations.apply(
        directPlan,
        operationId: 'direct_receipt_parity',
      );

      final legacyDocument =
          await FileMapRepository().loadMapDocument(product.mapPath);
      final useCase = SaveMapUseCase(
        FileMapRepository(),
        authoringMutations: product.mutations,
      );
      final productRevision = await useCase.executeRevisioned(
        productMap,
        product.mapPath,
        expectedRevision: legacyDocument.revision,
        projectDialogueContext: product.project,
      );
      final productReceipt = product.mutations.lastAppliedReceipt;

      expect(productRevision, isNotNull);
      expect(productReceipt, isNotNull);
      expect(
        _stableReceipt(productReceipt!),
        _stableReceipt(directResult.receipt),
      );
    });

    test('saveMap accepts gameplay zones with nested geometry', () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      const zone = MapGameplayZone(
        id: 'zone_port_entry',
        name: 'zone_port_entry',
        kind: GameplayZoneKind.special,
        area: MapRect(
          pos: GridPos(x: 1, y: 0),
          size: GridSize(width: 1, height: 2),
        ),
        special: SpecialZonePayload(
          properties: <String, String>{
            'contractRole': 'navigation_anchor',
            'inert': 'true',
          },
        ),
      );
      final updated = fixture.map.copyWith(
        gameplayZones: const <MapGameplayZone>[zone],
      );
      final baseline =
          await FileMapRepository().loadMapDocument(fixture.mapPath);

      final result = await fixture.mutations.saveMap(
        updated,
        fixture.mapPath,
        expectedMapRevision: baseline.revision,
      );

      expect(result.resourceRevision, isNotNull);
      expect(
        (await FileMapRepository().loadMap(fixture.mapPath)).gameplayZones,
        const <MapGameplayZone>[zone],
      );
    });

    test('stale external bytes are visible and never overwritten', () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      final baseline =
          await FileMapRepository().loadMapDocument(fixture.mapPath);
      final local = fixture.map.copyWith(name: 'Local edit');
      await FileMapRepository().saveMap(
        fixture.map.copyWith(name: 'External edit'),
        fixture.mapPath,
        projectDialogueContext: fixture.project,
      );
      final useCase = SaveMapUseCase(
        FileMapRepository(),
        authoringMutations: fixture.mutations,
      );

      await expectLater(
        () => useCase.executeRevisioned(
          local,
          fixture.mapPath,
          expectedRevision: baseline.revision,
          projectDialogueContext: fixture.project,
        ),
        throwsA(isA<EditorConflictException>()),
      );
      expect((await FileMapRepository().loadMap(fixture.mapPath)).name,
          'External edit');
    });

    test('undo is a forward history receipt and restores exact map semantics',
        () async {
      final fixture = await _MutationFixture.create();
      addTearDown(fixture.dispose);
      final plan = await fixture.mutations.plan(
        fixture.root.path,
        actionId: 'map.save',
        parameters: {
          'map': fixture.map.copyWith(name: 'Undo me').toJson(),
        },
        idempotencyKey: 'editor_history_apply_01',
      );
      final applied = await fixture.mutations.apply(
        plan,
        operationId: 'editor_history_apply_01',
      );

      final undone = await fixture.mutations.undo(
        fixture.root.path,
        entryId: applied.receipt.receiptId,
        idempotencyKey: 'editor_history_undo_01',
      );

      expect(undone.receipt.actionId, 'history.undo');
      expect((await FileMapRepository().loadMap(fixture.mapPath)).toJson(),
          fixture.map.toJson());
    });

    test('receipt presenter keeps domain codes and confirmations actionable',
        () {
      const presenter = EditorReceiptPresenter();
      final conflict = presenter.failure(
        const EditorAuthoringMutationFailure(
          code: 'transaction.revision_conflict',
          message: 'The project changed.',
          remediation: ['Reload the project.'],
        ),
      );
      final confirmation = presenter.failure(
        const EditorAuthoringMutationFailure(
          code: 'confirmation.required',
          message: 'Confirmation required.',
        ),
      );

      expect(conflict.code, 'transaction.revision_conflict');
      expect(conflict.isConflict, isTrue);
      expect(conflict.message.toLowerCase(), contains('recharg'));
      expect(confirmation.requiresConfirmation, isTrue);
    });
  });
}

Map<String, Object?> _stableReceipt(AuthoringReceipt receipt) => {
      'actionId': receipt.actionId,
      'actionVersion': receipt.actionVersion,
      'status': receipt.status.wireName,
      'diff': receipt.diff.toJson(),
      'affectedResources': [
        for (final resource in receipt.affectedResources)
          {'kind': resource.kind, 'id': resource.id},
      ],
    };

final class _MutationFixture {
  _MutationFixture({
    required this.root,
    required this.project,
    required this.map,
    required this.queries,
    required this.mutations,
  });

  static Future<_MutationFixture> create() async {
    final root = await Directory.systemTemp.createTemp('pmcp081_editor_');
    const project = ProjectManifest(
      name: 'PMCP-081 editor fixture',
      maps: [
        ProjectMapEntry(
          id: 'alpha',
          name: 'Alpha',
          relativePath: 'maps/alpha.json',
        ),
      ],
      tilesets: [],
    );
    const map = MapData(
      id: 'alpha',
      name: 'Alpha',
      size: GridSize(width: 2, height: 2),
      version: ProjectVersion.v3,
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: [
        MapLayer.tile(
          id: 'l_base',
          name: 'Base',
          tiles: [0, 0, 0, 0],
        ),
        MapLayer.terrain(
          id: 'l_terrain',
          name: 'Terrain',
          terrains: [
            TerrainType.none,
            TerrainType.none,
            TerrainType.none,
            TerrainType.none,
          ],
        ),
        MapLayer.collision(
          id: 'l_collisions',
          name: 'Collisions',
          collisions: [false, false, false, false],
        ),
      ],
    );
    await FileProjectRepository()
        .saveProject(project, p.join(root.path, 'project.json'));
    await FileMapRepository().saveMap(
      map,
      p.join(root.path, 'maps', 'alpha.json'),
      projectDialogueContext: project,
    );
    const reader = EditorProjectFileReader();
    final queries = AuthoringQueryAdapter(fileReader: reader);
    final mutations = AuthoringMutationAdapter(
      fileReader: reader,
      queries: queries,
      projectRoots: reader,
    );
    return _MutationFixture(
      root: root,
      project: project,
      map: map,
      queries: queries,
      mutations: mutations,
    );
  }

  final Directory root;
  final ProjectManifest project;
  final MapData map;
  final AuthoringQueryAdapter queries;
  final AuthoringMutationAdapter mutations;

  String get mapPath => p.join(root.path, 'maps', 'alpha.json');

  Future<void> dispose() async {
    await mutations.closeAll();
    await queries.closeAll();
    if (await root.exists()) await root.delete(recursive: true);
  }
}
