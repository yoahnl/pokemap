import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';
import 'support/source_external_original_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  test(
      'automatic first rival composition preserves three lanes and nine native battles',
      () async {
    final output = Platform.environment['AVELUNE_RIVAL_PROJECT_OUTPUT'];
    final temporary =
        await Directory.systemTemp.createTemp('first-rival-native-');
    addTearDown(() => temporary.delete(recursive: true));
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: {9},
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((value) => value.isNotEmpty)
                .toList());
    final source = fixture.source, files = fixture.files;
    final limits =
        sourceCatalogStudyWriteLimitsFor(1, includeNativeCatalog: true);
    Future<LiteralTileComposition> literal(
            List<LiteralDependencyDecision> decisions) =>
        const LiteralTileComposer().compose(
            source: source,
            files: files,
            selectedSourceMapIds: [9],
            projectName: 'First Rival native QA',
            parentPath: output == null ? temporary.path : path.dirname(output),
            folderName: output == null ? 'native' : path.basename(output),
            dependencyDecisions: decisions,
            limits: limits);
    final probe = await literal([]);
    final base = await literal([
      for (final dependency in probe.dependencies)
        if (dependency.targetSourceMapId != 9)
          LiteralDependencyDecision(
              sourceSnapshotHash: source.snapshot.canonicalHash,
              selectionHash: probe.selectionHash,
              locator: dependency.locator,
              targetSourceMapId: dependency.targetSourceMapId,
              decision: LiteralDependencyDisposition.excludeStudy),
    ]);
    final semantic = (await const SourceSemanticStudyComposer()
        .compose(source: source, base: base, files: files, limits: limits))!;
    final composition = (await const SourceEventStudyComposer().compose(
        source: source, base: semantic, files: files, limits: limits))!;
    final projection = composition.projection;
    final rows = (projection.semanticEvidence['events'] as List).cast<Map>();
    final rivals = rows
        .where((row) =>
            row['locator']['mapId'] == 9 &&
            const [2, 3, 9].contains(row['locator']['eventId']))
        .toList();
    expect(rivals, hasLength(3));
    expect(rivals.every((row) => row['status'] == 'adaptedStaticSemantics'),
        isTrue,
        reason: '${rivals.map((r) => {
              'event': r['locator'],
              'gaps': r['gaps']
            }).toList()}');
    final trainerIds = <String>{};
    for (final row in rivals) {
      final binding = row['nativeFirstRival'] as Map;
      expect(binding['nativeBattleEngine'], 'avelune');
      expect(binding['sourceScriptsExecuted'], 0);
      trainerIds
          .addAll((binding['nativeTrainerIds'] as Map).values.cast<String>());
      expect(binding['program']['sourcePlaybackBookmarkRetained'], isFalse);
    }
    expect(trainerIds, hasLength(3));
    final fights = projection.scenes
        .expand((scene) => scene.graph.nodes)
        .map((node) => node.payload)
        .whereType<SceneBattlePayload>()
        .where((battle) => trainerIds.contains(battle.trainerId))
        .toList();
    expect(fights, hasLength(9));
    expect(
        fights.every((battle) =>
            battle.defeatRecovery == SceneBattleDefeatRecovery.continueScene),
        isTrue);
    final logicalFaces = projection.scenes.expand((scene) => scene.graph.nodes)
        .map((node) => node.payload).whereType<SceneActionPayload>()
        .map((payload) => payload.consequence).whereType<SceneSetNpcPoseConsequence>().toList();
    expect(logicalFaces, hasLength(9));
    expect(logicalFaces.every((pose) => pose.x == null && pose.y == null && pose.facing == EntityFacing.south), isTrue);
    final sceneMusic = projection.scenes
        .expand((scene) => scene.graph.nodes)
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .map((payload) => payload.interactiveCommand)
        .whereType<SceneMusicInteractiveCommand>()
        .toList();
    expect(
        sceneMusic
            .where((music) => music.operation == SceneMusicOperation.play)
            .length,
        greaterThanOrEqualTo(6));
    expect(
        sceneMusic
            .where((music) => music.operation == SceneMusicOperation.restore)
            .length,
        greaterThanOrEqualTo(6));
    if (Platform.environment['AVELUNE_RIVAL_STRICT_WRITE'] == 'true') {
      final catalog = await SourceCatalogStudyComposer(
              nativeTrainerCatalog: composition.pokemonGiftCatalog,
              nativeTrainerQualification: composition.trainerQualification)
          .compose(
              source: source,
              base: composition.draft,
              files: files,
              limits: limits);
      final draft = catalog?.draft ?? composition.draft;
      final approval = approveNativeFixtureDraft(draft);
      final receipt = await NativeProjectWriter()
          .write(approval.plan, approval.context, draft, limits: limits);
      expect(receipt.verified, isTrue);
      final target = output ?? path.join(temporary.path, 'native');
      final manifest = ProjectManifest.fromJson(jsonDecode(
              await File(path.join(target, 'project.json')).readAsString())
          as Map<String, dynamic>);
      expect(manifest.maps, hasLength(1));
      expect(
          manifest.trainers.where((trainer) => trainerIds.contains(trainer.id)),
          hasLength(3));
      final receiptOutput =
          Platform.environment['AVELUNE_RIVAL_COMPOSITION_RECEIPT'];
      if (receiptOutput != null) {
        await File(receiptOutput).writeAsString(jsonEncode({
          'kind': 'firstRivalStrictComposition',
          'projectRoot': target,
          'sourceMapIds': [9],
          'sourceEvents': [2, 3, 9],
          'nativeBattleBranches': 9,
          'nativeTrainerIds': trainerIds.toList()..sort(),
          'strictWriterVerified': true,
          'sourceTemporalAudioParity': false,
          'continuousCampaignQualified': false,
          'sourceScriptsExecuted': 0,
          'aiCalls': 0
        }));
      }
    }
  },
      skip: root == null || snapshot == null
          ? 'Requires attested external source and profile'
          : false,
      timeout: const Timeout(Duration(minutes: 10)));
}
