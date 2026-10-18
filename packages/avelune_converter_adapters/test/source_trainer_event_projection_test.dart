import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:avelune_converter_adapters/src/source_event_projection.dart';
import 'package:avelune_converter_adapters/src/source_trainer_event_bindings.dart';

final class _Files implements SourceFilePort {
  _Files(this.bytes, this.paths, this.sourceRoot);
  final Map<ConverterId, List<int>> bytes;
  final Map<ConverterId, String> paths;
  final String sourceRoot;

  @override
  Future<List<int>> read(ConverterId id) async => bytes.containsKey(id)
      ? List.of(bytes[id]!)
      : File('$sourceRoot/${paths[id]}').readAsBytes();
}

Future<(NormalizedSourceProject, SourceFilePort)> _source(
    String folder, String sourceRoot,
    {bool unrelatedRosterChange = false,
    String? additionalHeader,
    String? loseTextOverride}) async {
  final input = jsonDecode(await File('$folder/snapshot.json').readAsString())
      as Map<String, dynamic>;
  final frozen =
      jsonDecode(await File('$folder/normalized.json').readAsString())
          as Map<String, dynamic>;
  final bytes = <ConverterId, List<int>>{
    for (final dynamic row in frozen['archive']['files'])
      ConverterId(row['entry']['fileId'] as String):
          base64Decode(row['rawBytes'] as String)
  };
  final paths = <ConverterId, String>{
    for (final dynamic row in input['entries'])
      ConverterId(row['fileId'] as String): row['relativePath'] as String,
  };
  final rosterId = paths.entries
      .singleWhere((entry) => entry.value == 'PBS/trainers.txt')
      .key;
  final rosterBytes = await File('$sourceRoot/PBS/trainers.txt').readAsBytes();
  final changedFiles = <ConverterId>{};
  if (unrelatedRosterChange) {
    bytes[rosterId] = [
      ...rosterBytes,
      ...utf8.encode('\n# unrelated attested comment\n')
    ];
  }
  if (additionalHeader != null) {
    final raw = utf8.decode(rosterBytes);
    bytes[rosterId] = utf8.encode(raw.replaceFirst('[FRLG_BUGCATCHER,Brent]',
        '[FRLG_BUGCATCHER,Brent]\n$additionalHeader'));
  }
  if (loseTextOverride != null) {
    bytes[rosterId] = utf8.encode(utf8.decode(rosterBytes).replaceFirst(
        'LoseText = WHAT? What a total waste of time!',
        'LoseText = $loseTextOverride'));
  }
  if (bytes.containsKey(rosterId)) changedFiles.add(rosterId);
  if (loseTextOverride != null) {
    final compiledId = paths.entries
        .singleWhere((entry) => entry.value == 'Data/trainers.dat')
        .key;
    final compiled = await File('$sourceRoot/Data/trainers.dat').readAsBytes();
    final before = utf8.encode('WHAT? What a total waste of time!');
    final pattern = [34, before.length + 5, ...before];
    final offsets = <int>[];
    for (var offset = 0; offset <= compiled.length - pattern.length; offset++) {
      if (pattern.indexed
          .every((entry) => compiled[offset + entry.$1] == entry.$2)) {
        offsets.add(offset);
      }
    }
    if (offsets.length != 1) {
      throw StateError('Expected one exact compiled Brent LoseText witness');
    }
    final after = utf8.encode(loseTextOverride);
    if (after.length > 122) {
      throw StateError(
          'The controlled fixture requires a short Marshal literal');
    }
    bytes[compiledId] = [
      ...compiled.take(offsets.single),
      34,
      after.isEmpty ? 0 : after.length + 5,
      ...after,
      ...compiled.skip(offsets.single + pattern.length),
    ];
    changedFiles.add(compiledId);
  }
  final files = _Files(bytes, paths, sourceRoot);
  final snapshot = SourceSnapshot(
      logicalProjectNamespace:
          ConverterId(input['logicalProjectNamespace'] as String),
      policyHash: Sha256Hash(input['policyHash'] as String),
      entries: [
        for (final dynamic row in input['entries'])
          SourceFileEntry(
              fileId: ConverterId(row['fileId'] as String),
              relativePath: row['relativePath'] as String,
              kind: SourceNodeKind.values.byName(row['kind'] as String),
              byteLength:
                  changedFiles.contains(ConverterId(row['fileId'] as String))
                      ? bytes[ConverterId(row['fileId'] as String)]!.length
                      : row['byteLength'] as int,
              sha256: row['sha256'] == null
                  ? null
                  : Sha256Hash(changedFiles
                          .contains(ConverterId(row['fileId'] as String))
                      ? crypto.sha256
                          .convert(bytes[ConverterId(row['fileId'] as String)]!)
                          .toString()
                      : row['sha256'] as String),
              format: row['format'] as String,
              family: row['family'] as String)
      ],
      diagnostics: [],
      excludedPaths: (input['excludedPaths'] as List).cast<String>(),
      profileEvidence: [
        for (final dynamic row in input['profileEvidence'])
          SourceProfileEvidence(
              relativePath: row['relativePath'] as String,
              fileHash: Sha256Hash(row['fileHash'] as String),
              version: row['version'] as String,
              line: row['line'] as int,
              excerpt: row['excerpt'] as String)
      ],
      state: SourceScanState.values.byName(input['state'] as String));
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: files,
      selectedMapIds: {98, 100},
      includeEventSystem: true);
  return (source, files);
}

Map<int, MapData> _nativeMaps(NormalizedSourceProject source,
    {List<MapEntity> occupied = const [], bool blockBrent = false}) {
  final resolver = SourceSemanticResolver.forProject(source);
  return {
    for (final ir in source.maps)
      ir.map.sourceMapId: MapData(
          id: 'native_${ir.map.sourceMapId}',
          name: ir.map.name,
          size: GridSize(width: ir.map.width, height: ir.map.height),
          entities: ir.map.sourceMapId == 98 ? occupied : const [],
          layers: [
            MapLayer.collision(
                id: 'collision_${ir.map.sourceMapId}',
                name: 'Collision',
                collisions:
                    List.generate(ir.map.width * ir.map.height, (index) {
                  final x = index % ir.map.width, y = index ~/ ir.map.width;
                  final brent = ir.map.events
                      .where((event) => event.sourceEventId == 1)
                      .firstOrNull;
                  if (blockBrent &&
                      ir.map.sourceMapId == 98 &&
                      brent?.x == x &&
                      brent?.y == y) {
                    return true;
                  }
                  return resolver
                          .resolveConnectionEntryTile(
                              resolver.cellAt(ir.map.sourceMapId, x, y))
                          .status ==
                      SourcePassageStatus.blocked;
                }))
          ])
  };
}

Map<String, SourceEventCharacterBinding> _characters(
        NormalizedSourceProject source, SourceEventAnalysis analysis) =>
    {
      for (final graphic in analysis.events
          .expand((event) => event.pages)
          .map((page) => page.graphic)
          .whereType<SourceEventGraphic>())
        for (final file in source.snapshot.entries.where((file) =>
            file.relativePath ==
            'Graphics/Characters/${graphic.characterName}.png'))
          sourceEventCharacterBindingKey(
                  characterName: graphic.characterName,
                  pattern: graphic.pattern,
                  direction: graphic.direction):
              SourceEventCharacterBinding(
                  characterId: 'native_${graphic.characterName}',
                  sourceSnapshotHash: source.snapshot.canonicalHash,
                  sourceFileId: file.fileId,
                  sourceFileHash: file.sha256!,
                  sourcePattern: graphic.pattern,
                  sourceDirection: graphic.direction)
    };

Map _eventEvidence(
        SourceEventProjection projection, SourceEventDefinition event) =>
    (projection.semanticEvidence['events'] as List)
        .cast<Map>()
        .singleWhere((row) => row['sourceIdentity'] == event.identity.value);

MapEntity _anchor(
        SourceEventProjection projection, SourceEventDefinition event) =>
    projection.nativeMaps[event.sourceMapId]!.entities.singleWhere((entity) =>
        entity.properties['sourceEventIdentity'] == event.identity.value);

SceneAsset _scene(SourceEventProjection projection, SourceEventDefinition event,
        int pageIndex) =>
    projection.scenes.singleWhere((scene) =>
        scene.metadata['sourceEventIdentity'] == event.identity.value &&
        scene.metadata['sourcePageIndex'] == '$pageIndex');

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final sourceRoot = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  group('source trainer native event projection', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    late SourceTrainerEventBindings bindings;
    late Map<int, MapData> nativeMaps;
    late SourceEventProjection projection;
    SourceEventProjection project(
            {SourceEventAnalysis? overrideAnalysis,
            Map<int, MapData>? maps,
            bool bindCharacters = true,
            bool bindTrainers = true}) =>
        const SourceEventProjector().project(
            source: source,
            analysis: overrideAnalysis ?? analysis,
            nativeMaps: maps ?? nativeMaps,
            characterBindings:
                bindCharacters ? _characters(source, analysis) : const {},
            trainerBindings:
                bindTrainers ? bindings.byEventIdentity : const {});
    setUpAll(() async {
      final fixture = await _source(archive!, sourceRoot!);
      source = fixture.$1;
      final full = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
      analysis = SourceEventAnalysis(
          profile: full.profile,
          events: full.events
              .where((event) => event.pages
                  .expand((page) => page.body.nodes)
                  .whereType<SourceTrainerProgramNode>()
                  .isNotEmpty)
              .toList(),
          diagnostics: full.diagnostics);
      bindings = await const SourceTrainerEventBindingResolver()
          .read(source: source, analysis: analysis, files: fixture.$2);
      nativeMaps = _nativeMaps(source);
      projection = project();
    });

    test('eleven source trainers become native NPC encounters with bounded autonomous routes', () {
      final eligible = const SourceEventProjector().characterImportCandidates(
          source: source,
          analysis: analysis,
          nativeMaps: nativeMaps,
          trainerBindings: bindings.byEventIdentity);
      expect(eligible, hasLength(11));
      for (final event in eligible) {
        final program =
            event.pages.first.body.nodes.single as SourceTrainerProgramNode;
        final evidence = _eventEvidence(projection, event);
        expect(evidence['status'], 'adaptedStaticSemantics',
            reason: '${evidence['gaps']}');
        final entity = _anchor(projection, event);
        expect(entity.kind, MapEntityKind.npc);
        expect(entity.pos, GridPos(x: event.x, y: event.y));
        expect(entity.blocksMovement, isTrue);
        expect(entity.npc!.trainerId,
            bindings.byEventIdentity[event.identity]!.nativeTrainer.id);
        expect(entity.npc!.lineOfSightRange, program.detectionDistance);
        final records = projection.registry.records
            .where((record) =>
                record.definitionOrNull?.source.toJson()['entityId'] ==
                entity.id)
            .toList();
        expect(records, hasLength(2));
        expect(
            records.every((record) =>
                record.definitionOrNull!.source.toJson()['kind'] ==
                'entityInteract'),
            isTrue);
        expect(
            records.every((record) =>
                record.definitionOrNull!.reusePolicy ==
                NarrativeEventReusePolicy.reusable),
            isTrue);
        expect(
            _scene(projection, event, 0)
                .graph
                .nodes
                .where((node) => node.kind == SceneNodeKind.battle),
            hasLength(1));
        expect(
            _scene(projection, event, 1)
                .graph
                .nodes
                .where((node) => node.kind == SceneNodeKind.battle),
            isEmpty);
      }
      expect(projection.scenes, hasLength(22));
      expect(projection.facts, hasLength(11));
      expect(
          projection.nativeMaps.values.expand((map) => map.triggers), isEmpty);
    });

    test('native front interactions reach each qualified trainer anchor', () {
      for (final event in analysis.events.where((event) =>
          (event.pages.first.body.nodes.single as SourceTrainerProgramNode)
              .sourceMoveType ==
          0)) {
        final map = projection.nativeMaps[event.sourceMapId]!;
        final positions = [
          (GridPos(x: event.x, y: event.y + 1), Direction.north),
          (GridPos(x: event.x, y: event.y - 1), Direction.south),
          (GridPos(x: event.x + 1, y: event.y), Direction.west),
          (GridPos(x: event.x - 1, y: event.y), Direction.east),
        ];
        final available = positions.where((candidate) =>
            candidate.$1.x >= 0 &&
            candidate.$1.y >= 0 &&
            candidate.$1.x < map.size.width &&
            candidate.$1.y < map.size.height &&
            !map.layers.whereType<CollisionLayer>().any((layer) =>
                layer.collisions[
                    candidate.$1.y * map.size.width + candidate.$1.x]) &&
            !map.entities.any((entity) =>
                resolveEntityCollisionCells(entity).contains(candidate.$1)));
        expect(available, isNotEmpty, reason: event.name);
        final position = available.first;
        final interaction = stepGameplayWorld(
            GameplayWorldState.initial(
                map: map, playerPos: position.$1, playerFacing: position.$2),
            const InteractIntent());
        expect(interaction, isA<NpcInteracted>(), reason: event.name);
        expect((interaction as NpcInteracted).entity.id,
            _anchor(projection, event).id);
      }
    });

    test('three autonomous trainers retain native typed routes and trainer bindings', () {
      for (final eventId in [6, 8, 11]) {
        final event = analysis.eventAt(98, eventId)!;
        expect(_eventEvidence(projection, event)['status'], 'adaptedStaticSemantics');
        expect(_eventEvidence(projection, event)['gaps'], isEmpty);
        final entity = _anchor(projection, event);
        expect(entity.npc!.movement.mode, MapEntityNpcMovementMode.fixedRoute);
        expect(entity.npc!.movement.routeSteps, isNotEmpty);
        expect(entity.npc!.trainerId, bindings.byEventIdentity[event.identity]!.nativeTrainer.id);
        expect(projection.scenes.where((scene) =>
            scene.metadata['sourceEventIdentity'] == event.identity.value), hasLength(2));
      }
    });

    test('native line of sight uses source facing, range and real obstacles',
        () {
      final event = analysis.eventAt(98, 1)!;
      final map = projection.nativeMaps[98]!;
      final entity = _anchor(projection, event);
      final direction = entity.npc!.facing.asDirection;
      GridPos at(int distance) => GridPos(
          x: event.x + direction.dx * distance,
          y: event.y + direction.dy * distance);
      bool sees(MapData current, GridPos player) => checkLineOfSight(
          npcPos: entity.pos,
          npcFacing: entity.npc!.facing,
          lineOfSightRange: entity.npc!.lineOfSightRange,
          playerPos: player,
          world: GameplayWorldState.initial(map: current, playerPos: player));
      expect(sees(map, at(2)), isTrue);
      expect(sees(map, at(3)), isFalse);
      expect(sees(map, at(-1)), isFalse);
      final blocked = map.copyWith(layers: [
        MapLayer.collision(
            id: 'blocked',
            name: 'Blocked',
            collisions: List.generate(map.size.width * map.size.height,
                (index) => index == at(1).y * map.size.width + at(1).x))
      ]);
      expect(sees(blocked, at(2)), isFalse);
    });

    test(
        'real dispatch selects encounter then after-win page across save reload',
        () {
      final maps = projection.nativeMaps.values.toList();
      final project = ProjectManifest(
          name: 'Trainer source projection',
          tilesets: const [],
          maps: [
            for (final map in maps)
              ProjectMapEntry(
                  id: map.id,
                  name: map.name,
                  relativePath: 'maps/${map.id}.json')
          ],
          eventRegistry: projection.registry,
          facts: projection.facts,
          scenes: projection.scenes,
          dialogues: projection.dialogues,
          trainers: bindings.byEventIdentity.values
              .map((binding) => binding.nativeTrainer)
              .toList());
      final catalog =
          buildNarrativeEventProjectCatalog(project: project, maps: maps);
      for (final event in analysis.events.where((event) =>
          (event.pages.first.body.nodes.single as SourceTrainerProgramNode)
              .sourceMoveType ==
          0)) {
        final entity = _anchor(projection, event);
        final ready = NarrativeEventDispatchAuthority.prepare(
            registryResult:
                EventRegistryDecodeResult.decoded(projection.registry),
            occurrence: NarrativeEventOccurrence(
                source: NarrativeEventSourceRef.entityInteract(
                    projection.nativeMaps[event.sourceMapId]!.id, entity.id)),
            factResolver:
                NarrativeFactRuntimeResolver.fromFacts(projection.facts),
            projectCatalog: catalog,
            project: project,
            maps: maps);
        expect(ready, isA<NarrativeEventDispatchAuthorityReady>());
        final program =
            event.pages.first.body.nodes.single as SourceTrainerProgramNode;
        for (final won in [false, true]) {
          final state = GameState(
              saveId: 'source-trainer',
              narrativeFactRuntimeState: NarrativeFactRuntimeState(
                  overridesByFactId: {
                    sourceEventFactBindingId(program.defeatedFactId): won
                  }));
          final loaded = GameState.fromJson(state.toJson());
          final decision = (ready as NarrativeEventDispatchAuthorityReady)
              .plan(gameState: loaded);
          expect(decision, isA<NarrativeEventDispatchHandled>(),
              reason: '$decision');
          expect((decision as NarrativeEventDispatchHandled).sceneId,
              _scene(projection, event, won ? 1 : 0).id);
        }
      }
    });

    test(
        'missing trainer or character bindings cannot create active encounters',
        () {
      final event = analysis.eventAt(98, 1)!;
      for (final entry in [
        (project(bindTrainers: false), 'sourceTrainerBindingsMissing'),
        (project(bindCharacters: false), 'characterBindingMissing')
      ]) {
        expect(
            _eventEvidence(entry.$1, event)['status'], 'quarantinedWholeEvent');
        expect(_eventEvidence(entry.$1, event)['gaps'], contains(entry.$2));
        expect(entry.$1.scenes, isEmpty);
        expect(entry.$1.facts, isEmpty);
      }
    });

    test('native collision and full occupied footprints refuse the anchor', () {
      final event = analysis.eventAt(98, 1)!;
      for (final entry in [
        (
          project(maps: _nativeMaps(source, blockBrent: true)),
          'sourceTrainerAnchorPassageUnqualified'
        ),
        (
          project(
              maps: _nativeMaps(source, occupied: [
            MapEntity(
                id: 'wide',
                kind: MapEntityKind.custom,
                pos: GridPos(x: event.x - 1, y: event.y),
                size: const GridSize(width: 2, height: 1),
                blocksMovement: true)
          ])),
          'sourceTrainerAnchorOccupied'
        )
      ]) {
        expect(
            _eventEvidence(entry.$1, event)['status'], 'quarantinedWholeEvent');
        expect(_eventEvidence(entry.$1, event)['gaps'], contains(entry.$2));
        expect(
            entry.$1.scenes.where((scene) =>
                scene.metadata['sourceEventIdentity'] == event.identity.value),
            isEmpty);
      }
    });

    test('forged analysis cannot reuse a sealed trainer binding', () {
      final event = analysis.eventAt(98, 1)!;
      final page = event.pages.first;
      final changed = SourceEventDefinition(
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
                diagnostics: []),
            event.pages.last
          ]);
      final refused = project(
          overrideAnalysis: SourceEventAnalysis(
              profile: analysis.profile,
              events: [
                for (final original in analysis.events)
                  if (original.identity == event.identity) changed else original
              ],
              diagnostics: analysis.diagnostics));
      expect(_eventEvidence(refused, event)['status'], 'quarantinedWholeEvent');
      expect(_eventEvidence(refused, event)['gaps'],
          contains('sourceTrainerSourceBindingInvalid'));
      expect(
          refused.scenes.where((scene) =>
              scene.metadata['sourceEventIdentity'] == event.identity.value),
          isEmpty);
    });

    for (final outcome in [
      'victory',
      'defeat',
      'cancelled',
      'unknown',
      'throw'
    ]) {
      test(
          'native battle $outcome sets A only after acknowledged victory speech',
          () async {
        final event = analysis.eventAt(98, 1)!;
        final binding = bindings.byEventIdentity[event.identity]!;
        final program =
            event.pages.first.body.nodes.single as SourceTrainerProgramNode;
        final trace = <String>[];
        final result = await SceneRuntimeExecutor(
            callbacks: SceneRuntimeExecutionCallbacks(
                evaluateCondition: (_) =>
                    throw StateError('No source branch engine'),
                showDialogue: (intent) {
                  final content =
                      projection.dialogueSources[intent.dialogueId]!;
                  trace.add(content.contains(binding.loseText!)
                      ? 'loseText'
                      : 'challenge');
                  expect(trace.contains('A'), isFalse);
                  return 'completed';
                },
                startBattle: (intent) {
                  expect(intent.trainerId, binding.nativeTrainer.id);
                  expect(intent.npcEntityId, _anchor(projection, event).id);
                  expect(intent.battleDeclaredOutcomes, ['victory', 'defeat']);
                  trace.add('battle');
                  if (outcome == 'throw') {
                    throw StateError('Native battle unavailable');
                  }
                  return outcome;
                },
                playCinematic: (_) =>
                    throw StateError('No imported battle engine'),
                applyConsequence: (consequence) {
                  expect(
                      consequence,
                      SceneConsequence.setFact(
                          factId:
                              sourceEventFactBindingId(program.defeatedFactId),
                          value: true));
                  expect(trace.last, 'loseText');
                  trace.add('A');
                  return 'completed';
                })).execute(
            buildSceneRuntimePlan(_scene(projection, event, 0)).plan!);
        if (outcome == 'victory') {
          expect(result.status, SceneRuntimeExecutionStatus.completed);
          expect(trace, ['challenge', 'battle', 'loseText', 'A']);
        } else {
          expect(
              result.status,
              outcome == 'defeat'
                  ? SceneRuntimeExecutionStatus.completed
                  : SceneRuntimeExecutionStatus.failed);
          expect(trace, ['challenge', 'battle']);
        }
      });
    }

    test('closing victory speech before completion leaves source A unchanged',
        () async {
      final event = analysis.eventAt(98, 1)!;
      final binding = bindings.byEventIdentity[event.identity]!;
      var factWrites = 0;
      final result = await SceneRuntimeExecutor(
              callbacks: SceneRuntimeExecutionCallbacks(
                  evaluateCondition: (_) => throw StateError('No condition'),
                  showDialogue: (intent) {
                    if (projection.dialogueSources[intent.dialogueId]!
                        .contains(binding.loseText!)) {
                      throw StateError('Dialogue interrupted');
                    }
                    return 'completed';
                  },
                  startBattle: (_) => 'victory',
                  playCinematic: (_) => throw StateError('No cinematic'),
                  applyConsequence: (_) {
                    factWrites++;
                    return 'completed';
                  }))
          .execute(buildSceneRuntimePlan(_scene(projection, event, 0)).plan!);
      expect(result.status, SceneRuntimeExecutionStatus.failed);
      expect(factWrites, 0);
    });

    test('source message boxes, PBS speech and after-win text keep their order',
        () async {
      for (final event in analysis.events.where((event) =>
          (event.pages.first.body.nodes.single as SourceTrainerProgramNode)
              .sourceMoveType ==
          0)) {
        final binding = bindings.byEventIdentity[event.identity]!;
        for (final pageIndex in [0, 1]) {
          final program = event.pages[pageIndex].body.nodes.single
              as SourceTrainerProgramNode;
          final lines = <String>[];
          final feedback = <DialogueLineFeedback>[];
          final result = await SceneRuntimeExecutor(
              callbacks: SceneRuntimeExecutionCallbacks(
                  evaluateCondition: (_) => throw StateError('No condition'),
                  showDialogue: (intent) {
                    lines.add(intent.linePolicies.single.feedback.plainText);
                    feedback.add(intent.linePolicies.single.feedback);
                    return 'completed';
                  },
                  startBattle: (_) => 'victory',
                  playCinematic: (_) => throw StateError('No cinematic'),
                  applyConsequence: (_) => 'completed')).execute(
              buildSceneRuntimePlan(_scene(projection, event, pageIndex))
                  .plan!);
          expect(result.status, SceneRuntimeExecutionStatus.completed);
          expect(
              lines,
              (pageIndex == 0
                      ? [...program.challengeLines, binding.loseText!]
                      : program.afterWinLines)
                  .map((line) => line
                      .replaceAll(r'\n', '\n')
                      .replaceAll(r'\b', '')
                      .replaceAll(r'\r', ''))
                  .toList());
          final sourceLines =
              pageIndex == 0 ? program.challengeLines : program.afterWinLines;
          for (final line in sourceLines.indexed) {
            if (line.$2.startsWith(r'\b') || line.$2.startsWith(r'\r')) {
              final segment =
                  feedback[line.$1].segments.first as DialogueTextSegment;
              expect(segment.style!.colorArgb,
                  line.$2.startsWith(r'\b') ? 0xff3050c8 : 0xffe00808);
              expect(segment.style!.shadowColorArgb, 0xffd0d0c8);
            }
          }
          expect(lines.any((line) => line.startsWith('EndSpeech:')), isFalse);
        }
      }
    });

    test('adaptation evidence preserves raw programs and native battle scope',
        () {
      final event = analysis.eventAt(98, 1)!;
      final evidence =
          _eventEvidence(projection, event)['nativeTrainerEncounter'] as Map;
      expect(evidence['sourceRawPages'], hasLength(2));
      expect(evidence['nativeTrainerId'],
          bindings.byEventIdentity[event.identity]!.nativeTrainer.id);
      expect(evidence['nativeActivation'],
          'aveluneNpcLineOfSightAndEntityInteract');
      expect(evidence['sourceScriptsExecuted'], 0);
      expect(evidence['fullSourceTrainerParityQualified'], isFalse);
      expect(evidence['sourceEndSpeechCommentExecuted'], isFalse);
      expect(
          evidence['sourceDefeatedCondition'], 'victoryOnlyAfterPbsLoseText');
    });

    for (final text in ['', r'\b']) {
      test(
          text.isEmpty
              ? 'empty PBS victory speech uses the proven ellipsis fallback'
              : 'control-only PBS speech quarantines its complete trainer event',
          () async {
        final fixture =
            await _source(archive!, sourceRoot!, loseTextOverride: text);
        final changed = fixture.$1;
        final full = SourceEventAnalyzer.forProject(changed,
                profile: SourceEventProfile.kantoForProject(changed))
            .analyze();
        final changedAnalysis = SourceEventAnalysis(
            profile: full.profile,
            events: full.events
                .where((event) => event.pages
                    .expand((page) => page.body.nodes)
                    .whereType<SourceTrainerProgramNode>()
                    .isNotEmpty)
                .toList(),
            diagnostics: full.diagnostics);
        final changedBindings = await const SourceTrainerEventBindingResolver()
            .read(
                source: changed, analysis: changedAnalysis, files: fixture.$2);
        final changedProjection = const SourceEventProjector().project(
            source: changed,
            analysis: changedAnalysis,
            nativeMaps: _nativeMaps(changed),
            characterBindings: _characters(changed, changedAnalysis),
            trainerBindings: changedBindings.byEventIdentity);
        final event = changedAnalysis.eventAt(98, 1)!;
        expect(changedBindings.byEventIdentity[event.identity]!.loseText, text);
        if (text.isNotEmpty) {
          expect(_eventEvidence(changedProjection, event)['status'],
              'quarantinedWholeEvent');
          expect(_eventEvidence(changedProjection, event)['gaps'],
              contains('sourceTrainerTextControlUnsupported'));
          expect(
              changedProjection.scenes.where((scene) =>
                  scene.metadata['sourceEventIdentity'] ==
                  event.identity.value),
              isEmpty);
          return;
        }
        expect(_eventEvidence(changedProjection, event)['status'],
            'adaptedStaticSemantics');
        final speech = <String>[];
        var factWrites = 0;
        final result = await SceneRuntimeExecutor(
            callbacks: SceneRuntimeExecutionCallbacks(
                evaluateCondition: (_) => throw StateError('No condition'),
                showDialogue: (intent) {
                  speech.add(intent.linePolicies.single.feedback.plainText);
                  return 'completed';
                },
                startBattle: (_) => 'victory',
                playCinematic: (_) => throw StateError('No cinematic'),
                applyConsequence: (_) {
                  factWrites++;
                  return 'completed';
                })).execute(
            buildSceneRuntimePlan(_scene(changedProjection, event, 0)).plan!);
        expect(result.status, SceneRuntimeExecutionStatus.completed);
        expect(speech.last, '...');
        expect(factWrites, 1);
      });
    }
  }, skip: archive == null || sourceRoot == null);
}
