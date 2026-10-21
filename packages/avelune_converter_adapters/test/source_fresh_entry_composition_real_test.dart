import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';
import 'support/source_external_original_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final profile = Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'];
  test(
      'automatic source fresh entry survives strict writer and empty native factory',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('source-fresh-write-');
    addTearDown(() => temporary.delete(recursive: true));
    const selected = {1, 2, 7};
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: selected,
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((value) => value.isNotEmpty)
                .toList());
    final limits = sourceCatalogStudyWriteLimitsFor(selected.length,
        includeNativeCatalog: true);
    Future<LiteralTileComposition> literal(
            List<LiteralDependencyDecision> decisions) =>
        const LiteralTileComposer().compose(
            source: fixture.source,
            files: fixture.files,
            selectedSourceMapIds: selected.toList(),
            projectName: 'Source fresh entry',
            parentPath: temporary.path,
            folderName: 'native',
            dependencyDecisions: decisions,
            limits: limits);
    final probe = await literal([]);
    final base = await literal([
      for (final dependency in probe.dependencies)
        if (!selected.contains(dependency.targetSourceMapId))
          LiteralDependencyDecision(
              sourceSnapshotHash: fixture.source.snapshot.canonicalHash,
              selectionHash: probe.selectionHash,
              locator: dependency.locator,
              targetSourceMapId: dependency.targetSourceMapId,
              decision: LiteralDependencyDisposition.excludeStudy)
    ]);
    final semantic = (await const SourceSemanticStudyComposer().compose(
        source: fixture.source,
        base: base,
        files: fixture.files,
        limits: limits))!;
    final events = (await const SourceEventStudyComposer().compose(
        source: fixture.source,
        base: semantic,
        files: fixture.files,
        limits: limits))!;
    final fresh = events.freshEntry!;
    expect(fresh.config.initialParty, isEmpty);
    expect(fresh.config.starterOptions, isEmpty);
    expect(fresh.config.initialBag, isEmpty);
    expect(fresh.config.startingMoney, 3000);
    expect(fresh.imports.map((entry) => entry.selectedOutfit), [1, 1]);
    expect(fresh.config.playerAvatarCharacterIds, hasLength(2));
    expect(fresh.scene.executionProfile, SceneExecutionProfile.preSession);
    expect(events.draft.mutations.last.actionId, 'campaign.new_game.update');
    final approval = approveNativeFixtureDraft(events.draft);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, events.draft, limits: limits);
    expect(receipt.verified, isTrue);
    final project = ProjectManifest.fromJson(Map<String, dynamic>.from(
        jsonDecode(await File('${receipt.projectPath}/project.json')
            .readAsString()) as Map));
    expect(project.newGame, fresh.config);
    expect(project.defeatRecovery, fresh.defeatRecovery);
    expect(
        project.facts.singleWhere(
            (fact) => fact.id == project.defeatRecovery!.recoveredFactId)
            .initialValue,
        NarrativeValue.boolean(false));
    expect(project.scenes.where((scene) => scene.id == fresh.scene.id),
        hasLength(1));
    final maps = <String, MapData>{
      for (final entry in project.maps)
        entry.id: MapData.fromJson(Map<String, dynamic>.from(jsonDecode(
            await File('${receipt.projectPath}/${entry.relativePath}')
                .readAsString()) as Map))
    };
    for (final avatar in project.newGame.playerAvatarCharacterIds) {
      final state = createNewGameStateFromProject(
          project: project,
          startMap: maps[project.newGame.startMapId]!,
          initialRecoveryMap: maps[project.newGame.initialRecoveryPoint!.mapId],
          saveId: 'source-new-game-$avatar',
          playerName: 'Yoahn',
          playerAvatarCharacterId: avatar);
      expect(state.party.members, isEmpty);
      expect(state.pokemonStorage, const PokemonStorage());
      expect(state.bag.entries, isEmpty);
      expect(state.currentMapId, fresh.startMap.id);
      expect(state.playerPosition, const GridPos(x: 0, y: 0));
      final recovery = PlayerRecoveryPoint.tryRead(state);
      expect(recovery?.mapId, events.projection.nativeMaps[7]!.id);
      expect(recovery?.position, const GridPos(x: 9, y: 7));
      expect(recovery?.facing, EntityFacing.north);
      expect(state.narrativeFactRuntimeState.valueFor(
          project.defeatRecovery!.recoveredFactId), NarrativeValue.boolean(false));
      final freshFact = project.facts.singleWhere(
          (fact) => fact.description.contains(':nativeFreshEntry:'));
      expect(state.narrativeFactRuntimeState.valueFor(freshFact.id),
          NarrativeValue.boolean(true));
      for (final variable in [28, 29]) {
        final sourceFact = sourceEventIntegerVariableBindingId(
            'source:${fixture.source.snapshot.logicalProjectNamespace.value}:variable:$variable');
        expect(
            project.newGame.resolvedInitialFactValues.containsKey(sourceFact),
            isFalse);
      }
    }
    if (Platform.environment['AVELUNE_FRESH_PROJECT_OUTPUT']
        case final output?) {
      expect(await Directory(output).exists(), isFalse);
      await Directory(receipt.projectPath).rename(output);
      await File('$output.receipt.json').writeAsString(jsonEncode({
        'strictNativeWriter': true,
        'factoryEmptyParty': true,
        'factoryEmptyStorage': true,
        'factoryNoStarterSeed': true,
        'initialMoney': 3000,
        'sourceOutfit': 1,
        'recoverySourceMap': 2,
        'recoveryNativeHomeMap': 7,
        'defeatRecovery': project.defeatRecovery!.toJson(),
        'newGame': project.newGame.toJson(),
        'source': fresh.evidence,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'playerJourneyQualified': false,
        'masterUpdated': false,
      }));
    }
  },
      timeout: const Timeout(Duration(minutes: 6)),
      skip: root == null ||
          snapshot == null ||
          profile == null ||
          Platform.environment['AVELUNE_FRESH_STRICT_WRITE'] != '1');
}
