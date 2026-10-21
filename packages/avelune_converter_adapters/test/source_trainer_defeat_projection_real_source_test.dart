import 'dart:convert';
import 'dart:io';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'support/source_external_original_fixture.dart';
import 'source_gym_leader_projection_test.dart'
    show runSourceGymProjectionForTest;

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  test(
      'automatic original trainer conversion declares native full recovery only with exact source loss evidence',
      () async {
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: {20, 98},
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((v) => v.isNotEmpty)
                .toList());
    final source = fixture.source;
    final temporary =
        await Directory.systemTemp.createTemp('trainer-defeat-conversion-');
    addTearDown(() => temporary.delete(recursive: true));
    final limits =
        sourceCatalogStudyWriteLimitsFor(2, includeNativeCatalog: true);
    Future<LiteralTileComposition> literal(
            List<LiteralDependencyDecision> decisions) =>
        const LiteralTileComposer().compose(
            source: source,
            files: fixture.files,
            selectedSourceMapIds: [20, 98],
            projectName: 'Trainer recovery',
            parentPath: temporary.path,
            folderName: 'native',
            dependencyDecisions: decisions,
            limits: limits);
    final probe = await literal([]);
    final base = await literal([
      for (final dependency in probe.dependencies)
        if (!const {20, 98}.contains(dependency.targetSourceMapId))
          LiteralDependencyDecision(
              sourceSnapshotHash: source.snapshot.canonicalHash,
              selectionHash: probe.selectionHash,
              locator: dependency.locator,
              targetSourceMapId: dependency.targetSourceMapId,
              decision: LiteralDependencyDisposition.excludeStudy)
    ]);
    final semantic = (await const SourceSemanticStudyComposer().compose(
        source: source, base: base, files: fixture.files, limits: limits))!;
    final events = (await const SourceEventStudyComposer().compose(
        source: source, base: semantic, files: fixture.files, limits: limits))!;
    final rows =
        (events.projection.semanticEvidence['events'] as List).cast<Map>();
    final row = rows.singleWhere((row) =>
        row['locator']['mapId'] == 98 && row['locator']['eventId'] == 1);
    expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
    final scenes = events.projection.scenes.where((scene) =>
        scene.metadata['sourceEventIdentity'] ==
        source.eventIdentity(98, 1).value);
    final battles = scenes
        .expand((scene) => scene.graph.nodes)
        .map((node) => node.payload)
        .whereType<SceneBattlePayload>()
        .toList();
    expect(battles, hasLength(1));
    expect(battles.single.defeatRecovery,
        SceneBattleDefeatRecovery.returnToRecoveryPoint);
    expect(battles.single.declaredOutcomes, ['victory', 'defeat']);
    expect(battles.single.battleKind, 'trainer');
    final gymRow = rows.singleWhere((row) =>
        row['locator']['mapId'] == 20 && row['locator']['eventId'] == 3);
    expect(gymRow['status'], 'adaptedStaticSemantics',
        reason: '${gymRow['gaps']}');
    final gymScenes = events.projection.scenes
        .where((scene) =>
            scene.metadata['sourceEventIdentity'] ==
            source.eventIdentity(20, 3).value)
        .toList();
    final gymBattle = gymScenes
        .singleWhere((scene) => scene.metadata['sourcePageIndex'] == '0');
    final gymPayload = gymBattle.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneBattlePayload>()
        .single;
    expect(gymPayload.defeatRecovery,
        SceneBattleDefeatRecovery.returnToRecoveryPoint);
    final gymActions = gymBattle.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .toList();
    final badge = gymActions
        .map((payload) => payload.consequence)
        .whereType<SceneAwardBadgeConsequence>()
        .single;
    final gift = gymActions
        .map((payload) => payload.interactiveCommand)
        .whereType<SceneGiveItemInteractiveCommand>()
        .single;
    expect(badge.badgeId, 'source_badge_r1_b11_4d72f612ab3a89b5dc464f77');
    expect(gift.itemId, 'source-item-c85eb9dfd407526308e09068');
    expect(gift.quantity, 1);
    final outcomes = <String, Object?>{};
    for (final outcome in ['victory', 'defeat', 'cancel']) {
      final result = await runSourceGymProjectionForTest(
          events.projection, gymBattle, outcome);
      expect(result.effects,
          outcome == 'victory' ? ['badge', 'CT', 'count', 'flag'] : isEmpty);
      expect(result.state.trainerProfile.badgeIds,
          outcome == 'victory' ? [badge.badgeId] : isEmpty);
      expect(result.state.bag.entries,
          outcome == 'victory' ? hasLength(1) : isEmpty);
      if (outcome == 'victory') {
        final after = gymScenes
            .singleWhere((scene) => scene.metadata['sourcePageIndex'] == '1');
        final replay = await runSourceGymProjectionForTest(
            events.projection, after, 'victory',
            initial: result.state);
        expect(replay.effects, isEmpty);
        expect(replay.state.toJson(), result.state.toJson());
      }
      outcomes[outcome] = {
        'effects': result.effects,
        'gameState': result.state.toJson(),
        'battleOutcomeSimulatedAtSceneExecutorBoundary': true
      };
    }
    if (Platform.environment['AVELUNE_TRAINER_DEFEAT_RECEIPT']
        case final path?) {
      await File(path).writeAsString(jsonEncode({
        'sourceSnapshotHash': source.snapshot.canonicalHash.value,
        'sourceScriptsHash':
            source.interpretationProfile!.scriptsArchiveHash.value,
        'sourceMapId': 98,
        'sourceEventId': 1,
        'row': row,
        'battle': battles.single.toJson(),
        'gym20Battle': gymPayload.toJson(),
        'gym20RewardOracles': {
          'badgeCommandIndex': 16,
          'badgeIndex': 11,
          'itemCommandIndex': 24,
          'itemSymbol': 'TM100'
        },
        'gym20SceneOutcomeCases': outcomes,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'nativePlayerDefeatJourneyQualified': false
      }));
    }
  },
      skip: root == null ||
          snapshot == null ||
          Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'] == null,
      timeout: const Timeout(Duration(minutes: 3)));
}
