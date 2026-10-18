import 'dart:io';
import 'dart:async';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'support/source_town_map_original_fixture.dart';

final class _AdditionalOriginalFiles implements SourceFilePort {
  const _AdditionalOriginalFiles(this.delegate, this.probeId, this.actualId);
  final SourceFilePort delegate;
  final ConverterId probeId, actualId;
  @override
  Future<List<int>> read(ConverterId id) =>
      delegate.read(id == probeId ? actualId : id);
}

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final root = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  group('original native party trade closed admission', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    late SourceEventDefinition event;
    late MapData map;
    late SourcePartyTradeBinding binding;
    late SourcePartyTradeBinding adaptedBinding;
    late SourceEventCharacterImport imported;
    late SourceFilePort files;
    late Map<String, SourceEventCharacterBinding> adaptedCharacters;
    SourceEventAnalysis selected(
            SourceEventDefinition? definition, SourceEventProfile? profile) =>
        SourceEventAnalysis(
            profile: profile ?? analysis.profile,
            events: [definition ?? event],
            diagnostics: const []);
    SourceEventProjection adaptedProject(
            {SourceEventDefinition? definition,
            Map<String, SourceEventCharacterBinding>? characters}) =>
        const SourceEventProjector().project(
            source: source,
            analysis: selected(definition, null),
            nativeMaps: {102: map},
            characterBindings: characters ?? adaptedCharacters,
            partyTradeBinding: {source.eventIdentity(102, 7): adaptedBinding});

    SourceEventProjection project(
            {bool bind = true,
            SourceEventDefinition? definition,
            MapData? nativeMap,
            SourceEventProfile? profile}) =>
        const SourceEventProjector().project(
            source: source,
            analysis: selected(definition, profile),
            nativeMaps: {102: nativeMap ?? map},
            partyTradeBinding: {if (bind) source.eventIdentity(102, 7): binding});
    List<SourceEventDefinition> candidates(
            {bool bind = true,
            SourceEventDefinition? definition,
            MapData? nativeMap,
            SourceEventProfile? profile}) =>
        const SourceEventProjector().characterImportCandidates(
            source: source,
            analysis: selected(definition, profile),
            nativeMaps: {102: nativeMap ?? map},
            partyTradeBinding: {if (bind) source.eventIdentity(102, 7): binding});
    Map evidence(SourceEventProjection projection) =>
        (projection.semanticEvidence['events'] as List).single as Map;
    setUpAll(() async {
      final fixture = await readOriginalTownMapSource(
          archivePath: archive!, sourceRoot: root!);
      source = fixture.$1;
      files = fixture.$2;
      final full = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      event = full.eventAt(102, 7)!;
      analysis = selected(event, full.profile);
      binding = const SourcePartyTradeBindingResolver()
          .resolve(sourceMapId: 102, sourceEventId: 7, source: source, analysis: analysis)!;
      adaptedBinding = const SourcePartyTradeBindingResolver().resolve(
          sourceMapId: 102, sourceEventId: 7, source: source,
          analysis: analysis,
          visualPolicy:
              SourcePartyTradeVisualPolicy.nativeWoman2ForExactGuard)!;
      imported = await const SourceEventCharacterImporter().read(
          snapshot: source.snapshot,
          files: fixture.$2,
          charsetName: adaptedBinding.visualAdaptation!.actualCharsetName,
          sourcePattern: 0,
          sourceDirection: 6);
      adaptedCharacters = {
        sourceEventCharacterBindingKey(
            characterName: 'NPC_FRLG_WOMAN_2_FORMAL',
            pattern: 0,
            direction: 6): imported.binding
      };
      final ir = source.maps.single.map;
      final resolver = SourceSemanticResolver.forProject(source);
      map = MapData(
          id: 'native_102',
          name: ir.name,
          size: GridSize(width: ir.width, height: ir.height),
          layers: [
            MapLayer.collision(
                id: 'collision',
                name: 'Collision',
                collisions: List.generate(
                    ir.width * ir.height,
                    (index) =>
                        resolver
                            .resolveConnectionEntryTile(resolver.cellAt(
                                102, index % ir.width, index ~/ ir.width))
                            .status ==
                        SourcePassageStatus.blocked))
          ]);
    });
    test(
        'exact raw program and actual native catalog form a closed inert binding',
        () {
      expect(
          binding.isBoundToEvent(
              source: source, analysis: analysis, event: event),
          true);
      expect(binding.program.sourceFacingDirection, 4);
      expect(binding.evidence['sourceScriptsExecuted'], 0);
      expect(binding.evidence['requiresNativePokemonCatalog'], true);
      expect(binding.program.toJson()['nativeExecutionQualified'], false);
    });
    test(
        'source blocked stair anchor and passable eastern approach are both preserved',
        () {
      final resolver = SourceSemanticResolver.forProject(source);
      expect(
          resolver
              .resolveConnectionEntryTile(resolver.cellAt(102, 3, 8))
              .status,
          SourcePassageStatus.blocked);
      expect(
          resolver
              .resolveConnectionEntryTile(resolver.cellAt(102, 4, 8))
              .status,
          SourcePassageStatus.allowed);
      final collision =
          map.layers.whereType<CollisionLayer>().single.collisions;
      expect(collision[8 * map.size.width + 3], true);
      expect(collision[8 * map.size.width + 4], false);
      expect(candidates().map((event) => event.identity), [event.identity]);
    });
    test(
        'missing original formal sprite never admits a substitute or a native scene',
        () {
      expect(
          source.snapshot.entries.where((entry) =>
              entry.relativePath ==
              'Graphics/Characters/NPC_FRLG_WOMAN_2_FORMAL.png'),
          isEmpty);
      final projection = project();
      expect(evidence(projection)['gaps'], ['characterBindingMissing']);
      expect(evidence(projection)['status'], 'quarantinedWholeEvent');
      expect(projection.nativeMaps[102]!.entities, isEmpty);
      expect(projection.scenes, isEmpty);
      expect(projection.facts, isEmpty);
      expect(projection.itemCatalog, isNull);
      expect(projection.semanticEvidence['usedPartyTrade'], false);
    });
    test(
        'bounded policy imports the real PNG under its own identity and source anchor',
        () {
      final projection = adaptedProject();
      expect(evidence(projection)['status'], 'adaptedStaticSemantics',
          reason: '${evidence(projection)['gaps']}');
      final npc = projection.nativeMaps[102]!.entities.single;
      expect(npc.pos, const GridPos(x: 3, y: 8));
      expect(npc.npc!.characterId, imported.character.id);
      expect(imported.imageFile.relativePath,
          'Graphics/Characters/NPC_FRLG_WOMAN_2.png');
      expect(imported.sheetWidth, 128);
      expect(imported.sheetHeight, 192);
      expect(imported.artifact.reference.mediaType, 'image/png');
      expect(projection.scenes, hasLength(1));
      expect(projection.facts, isEmpty);
      final result = stepGameplayWorld(
          GameplayWorldState.initial(
              map: projection.nativeMaps[102]!,
              playerPos: const GridPos(x: 4, y: 8),
              playerFacing: Direction.west),
          const InteractIntent());
      expect(result, isA<NpcInteracted>());
    });
    for (final path in [
      'Graphics/Characters/NPC_FRLG_WOMAN_2_FORMAL.png',
      'Graphics/Characters/npc_frlg_woman_2_formal.png'
    ]) {
      test('an inventoried original disables replacement: $path', () async {
        final original = source.snapshot;
        final actual = imported.imageFile;
        final probeId = ConverterId('counterexample-formal-presence');
        final snapshot = SourceSnapshot(
            logicalProjectNamespace: original.logicalProjectNamespace,
            policyHash: original.policyHash,
            entries: [
              ...original.entries,
              SourceFileEntry(
                  fileId: probeId,
                  relativePath: path,
                  kind: SourceNodeKind.file,
                  byteLength: actual.byteLength,
                  sha256: actual.sha256,
                  format: actual.format,
                  family: actual.family)
            ],
            diagnostics: original.diagnostics,
            excludedPaths: original.excludedPaths,
            profileEvidence: original.profileEvidence,
            state: original.state);
        final changed = await const RmxpSourceNormalizer().normalize(
            snapshot: snapshot,
            files: _AdditionalOriginalFiles(files, probeId, actual.fileId),
            selectedMapIds: {102},
            includeEventSystem: true);
        final changedAnalysis = SourceEventAnalyzer.forProject(changed,
                profile: SourceEventProfile.forProject(changed,
interpretationProfile: fixtureSourceInterpretationProfile,
))
            .analyze();
        final decision = const SourcePartyTradeBindingResolver().resolve(
            sourceMapId: 102, sourceEventId: 7, source: changed,
            analysis: changedAnalysis,
            visualPolicy:
                SourcePartyTradeVisualPolicy.nativeWoman2ForExactGuard);
        expect(decision, isNotNull);
        expect(decision!.visualAdaptation, isNull);
      });
    }
    test(
        'the visual policy cannot authorize another NPC or altered source identity',
        () {
      final other = SourceEventDefinition(
          sourceMapId: 102,
          sourceEventId: 8,
          sourceFileId: event.sourceFileId,
          identity: source.eventIdentity(102, 8),
          name: event.name,
          x: event.x,
          y: event.y,
          locator: event.locator,
          pages: event.pages);
      expect(evidence(adaptedProject(definition: other))['status'],
          'quarantinedWholeEvent');
      final original = imported.binding;
      final forged = SourceEventCharacterBinding(
          characterId: original.characterId,
          sourceSnapshotHash: original.sourceSnapshotHash,
          sourceFileId: original.sourceFileId,
          sourceFileHash: Sha256Hash('0' * 64),
          sourcePattern: 0,
          sourceDirection: 6);
      expect(
          evidence(adaptedProject(
              characters: {adaptedCharacters.keys.single: forged}))['gaps'],
          contains('characterBindingMissing'));
    });
    for (final outcome in ['completed', 'cancelled', 'unknown']) {
      test(
          'source graph awaits native $outcome after the intro without source mutations',
          () async {
        final projection = adaptedProject();
        final trace = <String>[];
        final result = await SceneRuntimeExecutor(
                callbacks: SceneRuntimeExecutionCallbacks(
                    evaluateCondition: (intent) {
                      expect(intent.conditionSource!.playerFacingDirection,
                          EntityFacing.west);
                      return 'true';
                    },
                    showDialogue: (intent) {
                      trace.add('intro');
                      expect(
                          intent.choicePolicies.single.cancellation.outcomeId,
                          'choice_1');
                      return 'choice_0';
                    },
                    executeInteractiveCommand: (intent) {
                      trace.add('trade');
                      expect(intent.interactiveCommand!.kind,
                          SceneInteractiveCommandKind.openPartyTrade);
                      return outcome;
                    },
                    startBattle: (_) => throw StateError('No battle'),
                    playCinematic: (_) => throw StateError('No cinematic'),
                    applyConsequence: (_) =>
                        throw StateError('No source mutation')))
            .execute(buildSceneRuntimePlan(projection.scenes.single).plan!);
        expect(trace, ['intro', 'trade']);
        expect(
            result.status,
            outcome == 'unknown'
                ? SceneRuntimeExecutionStatus.failed
                : SceneRuntimeExecutionStatus.completed);
      });
    }
    test('other facing opens neither dialogue nor service', () async {
      final projection = adaptedProject();
      final result = await SceneRuntimeExecutor(
              callbacks:
                  SceneRuntimeExecutionCallbacks(
                      evaluateCondition: (_) => 'false',
                      showDialogue: (_) => throw StateError('No text'),
                      executeInteractiveCommand: (_) =>
                          throw StateError('No trade'),
                      startBattle: (_) => throw StateError('No battle'),
                      playCinematic: (_) => throw StateError('No cinematic'),
                      applyConsequence: (_) => throw StateError('No mutation')))
          .execute(buildSceneRuntimePlan(projection.scenes.single).plan!);
      expect(result.status, SceneRuntimeExecutionStatus.completed);
    });
    test(
        'source refusal and mapped outer cancel display the farewell without trade',
        () async {
      final projection = adaptedProject();
      var shown = 0;
      final result = await SceneRuntimeExecutor(
          callbacks: SceneRuntimeExecutionCallbacks(
              evaluateCondition: (_) => 'true',
              showDialogue: (intent) {
                shown++;
                if (intent.choicePolicies.isNotEmpty) return 'choice_1';
                expect(projection.dialogueSources[intent.dialogueId],
                    contains('wonderful day!'));
                return 'completed';
              },
              executeInteractiveCommand: (_) => throw StateError('No trade'),
              startBattle: (_) => throw StateError('No battle'),
              playCinematic: (_) => throw StateError('No cinematic'),
              applyConsequence: (_) =>
                  throw StateError('No mutation'))).execute(
          buildSceneRuntimePlan(projection.scenes.single).plan!);
      expect(shown, 2);
      expect(result.status, SceneRuntimeExecutionStatus.completed);
    });
    test('source graph remains pending until the native service closes',
        () async {
      final projection = adaptedProject();
      final entered = Completer<void>(), close = Completer<String>();
      var finished = false;
      final running = SceneRuntimeExecutor(
              callbacks: SceneRuntimeExecutionCallbacks(
                  evaluateCondition: (_) => 'true',
                  showDialogue: (_) => 'choice_0',
                  executeInteractiveCommand: (_) {
                    entered.complete();
                    return close.future;
                  },
                  startBattle: (_) => throw StateError('No battle'),
                  playCinematic: (_) => throw StateError('No cinematic'),
                  applyConsequence: (_) => throw StateError('No mutation')))
          .execute(buildSceneRuntimePlan(projection.scenes.single).plan!)
          .then((value) {
        finished = true;
        return value;
      });
      await entered.future;
      expect(finished, false);
      close.complete('completed');
      expect((await running).status, SceneRuntimeExecutionStatus.completed);
    });
    for (final failure in [
      'binding',
      'floor',
      'approach',
      'occupied',
      'spatial',
      'profile',
      'raw'
    ]) {
      test('$failure mismatch refuses candidacy and whole-event native effects',
          () {
        var target = map;
        SourceEventDefinition? forged;
        if (failure == 'floor' || failure == 'approach') {
          final collisions = [
            ...map.layers.whereType<CollisionLayer>().single.collisions
          ];
          final index = 8 * map.size.width + (failure == 'floor' ? 3 : 4);
          collisions[index] = !collisions[index];
          target = map.copyWith(layers: [
            MapLayer.collision(
                id: 'mismatch', name: 'Mismatch', collisions: collisions)
          ]);
        } else if (failure == 'occupied') {
          target = map.copyWith(entities: [
            MapEntity(
                id: 'other_npc',
                kind: MapEntityKind.npc,
                pos: const GridPos(x: 2, y: 8),
                size: const GridSize(width: 2, height: 1),
                npc: const MapEntityNpcData(characterId: 'other'))
          ]);
        } else if (failure == 'spatial') {
          target = map.copyWith(version: ProjectVersion.v9);
        } else if (failure == 'raw') {
          final page = event.pages.single;
          forged = SourceEventDefinition(
              sourceMapId: event.sourceMapId,
              sourceEventId: event.sourceEventId,
              sourceFileId: event.sourceFileId,
              identity: event.identity,
              name: event.name,
              x: event.x,
              y: event.y,
              locator: event.locator,
              pages: [
                SourceEventPageAnalysis(
                    sourcePage: page.sourcePage,
                    locator: page.locator,
                    condition: page.condition,
                    graphic: page.graphic,
                    body: page.body,
                    rawDataRef: null,
                    diagnostics: const [])
              ]);
        }
        final profile = failure == 'profile'
            ? SourceEventProfile.forProject(source,
                scriptsArchiveHash: Sha256Hash('0' * 64),
interpretationProfile: fixtureSourceInterpretationProfile,
)
            : null;
        expect(
            candidates(
                bind: failure != 'binding',
                nativeMap: target,
                definition: forged,
                profile: profile),
            isEmpty);
        final projection = project(
            bind: failure != 'binding',
            nativeMap: target,
            definition: forged,
            profile: profile);
        expect(evidence(projection)['status'], 'quarantinedWholeEvent');
        expect(projection.scenes, isEmpty);
        expect(projection.dialogues, isEmpty);
        expect(projection.facts, isEmpty);
        expect(projection.itemCatalog, isNull);
        expect(projection.nativeMaps[102]!.entities.length,
            target.entities.length);
        expect(projection.semanticEvidence['usedPartyTrade'], false);
      });
    }
  },
      skip: archive == null || root == null
          ? 'Original source archive/root required.'
          : false);
}
