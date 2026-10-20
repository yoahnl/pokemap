import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/authoring_mutation_adapter.dart';
import 'package:map_editor/src/application/authoring_api/authoring_query_adapter.dart';
import 'package:map_editor/src/application/authoring_api/editor_receipt_presenter.dart';

import '../../../map_gameplay/test/support/moving_platform_fixture.dart';

void main() {
  test(
    'editor deletes only the selected platform, replays and undoes after cold reopen',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final before = await fixture.authoredBytes();
      final original = await fixture.readMap();
      final plan = await fixture.planDelete('delete-platform');
      expect(plan.receipt.actionId, 'map.platform.delete');
      expect(plan.receipt.status, AuthoringReceiptStatus.planned);
      expect(plan.preview['platformId'], 'bridge');
      expect(await fixture.authoredBytes(), before);
      expect(await fixture.historyBytes(), isEmpty);

      final applied = await fixture.mutations.apply(
        plan,
        operationId: 'delete-platform',
      );
      expect(applied.receipt.actionId, 'map.platform.delete');
      expect(applied.receipt.status, AuthoringReceiptStatus.applied);
      final expected = original.copyWith(
        movingPlatforms: [fixture.otherPlatform],
      );
      expect(await fixture.readMap(), expected);
      expect((await fixture.readMap()).placedElements, original.placedElements);
      final after = await fixture.authoredBytes();
      expect(after['project.json'], before['project.json']);
      expect(after['maps/annex.json'], before['maps/annex.json']);
      final history = await fixture.historyBytes();
      expect(history, isNotEmpty);
      final replayed = await fixture.mutations.apply(
        plan,
        operationId: 'delete-platform',
      );
      expect(replayed.receipt.receiptId, applied.receipt.receiptId);
      expect(await fixture.authoredBytes(), after);
      expect(await fixture.historyBytes(), history);

      await fixture.coldReopen();
      expect(await fixture.queryMap(), expected);
      final undone = await fixture.mutations.undo(
        fixture.root.path,
        entryId: applied.receipt.receiptId,
        idempotencyKey: 'undo-delete-platform',
      );
      expect(undone.receipt.actionId, 'history.undo');
      expect(undone.receipt.status, AuthoringReceiptStatus.applied);
      expect(await fixture.authoredBytes(), before);
      await fixture.coldReopen();
      expect(await fixture.queryMap(), original);
    },
  );

  test(
    'editor refuses referenced and missing platforms without writes or history',
    () async {
      final referenced = await _Fixture.create(referenceTarget: true);
      addTearDown(referenced.dispose);
      final before = await referenced.authoredBytes();
      final history = await referenced.historyBytes();
      await expectLater(
        referenced.planDelete('referenced-platform'),
        throwsA(
          isA<EditorAuthoringMutationFailure>().having(
            (failure) => failure.code,
            'code',
            'map.platform_referenced',
          ),
        ),
      );
      expect(await referenced.authoredBytes(), before);
      expect(await referenced.historyBytes(), history);
      expect(referenced.mutations.lastAppliedReceipt, isNull);
      await referenced.coldReopen();
      expect(await referenced.queryMap(), await referenced.readMap());

      final missing = await _Fixture.create();
      addTearDown(missing.dispose);
      final missingBefore = await missing.authoredBytes();
      final missingHistory = await missing.historyBytes();
      await expectLater(
        missing.planDelete('missing-platform', platformId: 'absent'),
        throwsA(
          isA<EditorAuthoringMutationFailure>().having(
            (failure) => failure.code,
            'code',
            'map.platform_not_found',
          ),
        ),
      );
      expect(await missing.authoredBytes(), missingBefore);
      expect(await missing.historyBytes(), missingHistory);
      expect(missing.mutations.lastAppliedReceipt, isNull);
    },
  );

  test(
    'editor rejects stale platform deletion and preserves another platform edit',
    () async {
      final fixture = await _Fixture.create();
      addTearDown(fixture.dispose);
      final originalRevision = (await fixture.queries.open(
        fixture.root.path,
      )).snapshotRevision;
      final staleDelete = await fixture.planDelete(
        'stale-delete',
        expectedRevision: originalRevision,
      );
      final updatedOther = MovingPlatformDefinition.fromJson({
        ...fixture.otherPlatform.toJson(),
        'translationDistanceCells': 2,
      });
      final update = await fixture.mutations.plan(
        fixture.root.path,
        actionId: 'map.platform.upsert',
        parameters: {'mapId': 'gym', 'platform': updatedOther.toJson()},
        idempotencyKey: 'edit-other-platform',
        expectedRevision: originalRevision,
      );
      await fixture.mutations.apply(update, operationId: 'edit-other-platform');
      final afterEdit = await fixture.authoredBytes();
      final history = await fixture.historyBytes();
      await expectLater(
        fixture.mutations.apply(staleDelete, operationId: 'stale-delete'),
        throwsA(
          isA<EditorAuthoringMutationFailure>().having(
            (failure) => failure.code,
            'code',
            'plan.stale',
          ),
        ),
      );
      expect(await fixture.authoredBytes(), afterEdit);
      expect(await fixture.historyBytes(), history);
      await expectLater(
        fixture.planDelete(
          'stale-planning',
          expectedRevision: originalRevision,
        ),
        throwsA(
          isA<EditorAuthoringMutationFailure>().having(
            (failure) => failure.code,
            'code',
            'plan.stale',
          ),
        ),
      );
      expect(await fixture.authoredBytes(), afterEdit);
      expect(await fixture.historyBytes(), history);
      final fresh = await fixture.planDelete('fresh-delete');
      final applied = await fixture.mutations.apply(
        fresh,
        operationId: 'fresh-delete',
      );
      expect(applied.receipt.actionId, 'map.platform.delete');
      expect(applied.receipt.status, AuthoringReceiptStatus.applied);
      await fixture.coldReopen();
      final saved = await fixture.queryMap();
      expect(saved.movingPlatforms, [updatedOther]);
      expect(saved.placedElements, fixture.map.placedElements);
      expect(saved.layers, fixture.map.layers);
    },
  );
}

final class _Fixture {
  _Fixture(this.root, this.map, this.otherPlatform) {
    _openAdapters();
  }

  final Directory root;
  final MapData map;
  final MovingPlatformDefinition otherPlatform;
  late AuthoringQueryAdapter queries;
  late AuthoringMutationAdapter mutations;

  static Future<_Fixture> create({bool referenceTarget = false}) async {
    final temporary = await Directory.systemTemp.createTemp(
      'platform-delete-editor-',
    );
    final root = Directory(await temporary.resolveSymbolicLinks());
    final source = MovingPlatformFixture(
      smartTerrain: true,
      preciseTerrain: true,
    );
    final other = MovingPlatformDefinition.fromJson({
      ...source.definition.toJson(),
      'id': 'other-platform',
      'placedElementId': 'other-art',
      'initialPose': {'leftPx': 160, 'topPx': 64, 'quarterTurns': 0},
    });
    final map = source.map.copyWith(
      movingPlatforms: [source.definition, other],
      entities: [
        const MapEntity(
          id: 'note',
          name: 'Notice',
          kind: MapEntityKind.sign,
          pos: GridPos(x: 0, y: 0),
        ),
      ],
      placedElements: [
        ...source.map.placedElements,
        source.map.placedElements.single.copyWith(
          id: 'other-art',
          pos: const GridPos(x: 5, y: 2),
        ),
      ],
    );
    final project = source.project.copyWith(
      maps: [
        const ProjectMapEntry(
          id: 'gym',
          name: 'Workshop',
          relativePath: 'maps/workshop.json',
        ),
        const ProjectMapEntry(
          id: 'annex',
          name: 'Annex',
          relativePath: 'maps/annex.json',
        ),
      ],
      scenes: [_referenceScene(referenceTarget ? 'bridge' : 'other-platform')],
    );
    await Directory('${root.path}/maps').create();
    await File(
      '${root.path}/project.json',
    ).writeAsString(jsonEncode(project.toJson()));
    await File(
      '${root.path}/maps/workshop.json',
    ).writeAsString(jsonEncode(map.toJson()));
    await File('${root.path}/maps/annex.json').writeAsString(
      jsonEncode(
        source.map
            .copyWith(
              id: 'annex',
              name: 'Annex',
              movingPlatforms: [],
              placedElements: [],
            )
            .toJson(),
      ),
    );
    return _Fixture(root, map, other);
  }

  void _openAdapters() {
    const reader = LocalProjectFileReader();
    queries = AuthoringQueryAdapter(fileReader: reader);
    mutations = AuthoringMutationAdapter(
      fileReader: reader,
      queries: queries,
      projectRoots: _RootLocator(root.path),
    );
  }

  Future<EditorAuthoringMutationPlan> planDelete(
    String key, {
    String platformId = 'bridge',
    String? expectedRevision,
  }) async {
    final revision =
        expectedRevision ?? (await queries.open(root.path)).snapshotRevision;
    return mutations.plan(
      root.path,
      actionId: 'map.platform.delete',
      parameters: {'mapId': 'gym', 'platformId': platformId},
      idempotencyKey: key,
      requestId: key,
      expectedRevision: revision,
    );
  }

  Future<MapData> readMap() async => MapData.fromJson(
    jsonDecode(await File('${root.path}/maps/workshop.json').readAsString())
        as Map<String, dynamic>,
  );

  Future<Map<String, List<int>>> authoredBytes() async => {
    for (final path in [
      'project.json',
      'maps/workshop.json',
      'maps/annex.json',
    ])
      path: await File('${root.path}/$path').readAsBytes(),
  };

  Future<List<int>> historyBytes() async {
    final file = File('${root.path}/.pokemap/authoring/history.jsonl');
    return await file.exists() ? file.readAsBytes() : <int>[];
  }

  Future<MapData> queryMap() async {
    final session = await queries.open(root.path);
    final result = session.query(
      AuthoringQueryRequest(
        resourceKind: 'map',
        operation: AuthoringQueryOperation.get,
        view: AuthoringQueryView.detail,
        ids: ['gym'],
      ),
    );
    return MapData.fromJson(
      Map<String, dynamic>.from((result['items']! as List).single as Map),
    );
  }

  Future<void> coldReopen() async {
    await mutations.closeAll();
    await queries.closeAll();
    _openAdapters();
    await queries.open(root.path);
  }

  Future<void> dispose() async {
    await mutations.closeAll();
    await queries.closeAll();
    if (await root.exists()) await root.delete(recursive: true);
  }
}

final class _RootLocator implements EditorProjectRootLocator {
  const _RootLocator(this.root);
  final String root;
  @override
  Future<String> locateForResource(String resourcePath) async => root;
}

SceneAsset _referenceScene(String platformId) => SceneAsset(
  id: 'platform-reference',
  name: 'Platform reference',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'move',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.movePlatform(
            mapId: 'gym',
            platformId: platformId,
            motion: MovingPlatformMotion.forward,
          ),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'enter',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'move',
        kind: SceneEdgeKind.defaultFlow,
      ),
      for (final outcome in [
        'moved',
        'blocked',
        'notRiding',
        'rotationRequiresPivot',
      ])
        SceneEdge(
          id: outcome,
          fromNodeId: 'move',
          fromPortId: outcome,
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
    ],
  ),
);
