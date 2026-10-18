import 'dart:convert';
import 'dart:io';
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';
import 'package:avelune_converter_adapters/src/source_pokedex_reward_binding.dart';
import 'package:avelune_converter_adapters/src/source_event_projection.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

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
    {bool changedDex = false, bool unrelatedDex = false}) async {
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
  final dexId = paths.entries
      .singleWhere((entry) => entry.value == 'Data/regional_dexes.dat')
      .key;
  if (changedDex || unrelatedDex) {
    final raw = await File('$sourceRoot/Data/regional_dexes.dat').readAsBytes();
    final before = utf8.encode(changedDex ? 'BULBASAUR' : 'MISSINGNO');
    final after = utf8.encode(changedDex ? 'NOTASAUUR' : 'OTHERDEXX');
    var found = false;
    for (var i = 0; i <= raw.length - before.length; i++) {
      if (before.indexed.every((pair) => raw[i + pair.$1] == pair.$2)) {
        raw.setRange(i, i + after.length, after);
        found = true;
        break;
      }
    }
    if (!found) throw StateError('Missing source dex symbol');
    bytes[dexId] = raw;
  }
  final changed = bytes.containsKey(dexId);
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
              byteLength: row['fileId'] == dexId.value && changed
                  ? bytes[dexId]!.length
                  : row['byteLength'] as int,
              sha256: row['sha256'] == null
                  ? null
                  : Sha256Hash(row['fileId'] == dexId.value && changed
                      ? crypto.sha256.convert(bytes[dexId]!).toString()
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
      selectedMapIds: {102},
      includeEventSystem: true);
  return (source, files);
}

Map<int, MapData> _nativeMaps(NormalizedSourceProject source,
    {List<MapEntity> occupied = const [], bool blockAide = false}) {
  final resolver = SourceSemanticResolver.forProject(source);
  return {
    for (final ir in source.maps)
      ir.map.sourceMapId: MapData(
          id: 'native_${ir.map.sourceMapId}',
          name: ir.map.name,
          size: GridSize(width: ir.map.width, height: ir.map.height),
          entities: ir.map.sourceMapId == 102 ? occupied : const [],
          layers: [
            MapLayer.collision(
                id: 'collision_${ir.map.sourceMapId}',
                name: 'Collision',
                collisions:
                    List.generate(ir.map.width * ir.map.height, (index) {
                  final x = index % ir.map.width, y = index ~/ ir.map.width;
                  final aide = ir.map.events
                      .where((event) => event.sourceEventId == 10)
                      .firstOrNull;
                  if (blockAide &&
                      ir.map.sourceMapId == 102 &&
                      aide?.x == x &&
                      aide?.y == y) {
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
  final root = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  group('original Everstone native reward projection', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    late SourcePokedexRewardBinding binding;
    late SourceEventProjection projection;
    late SourceEventDefinition event;
    late Map<int, MapData> maps;
    SourceEventProjection project(
            {SourceEventAnalysis? overrideAnalysis,
            bool bindReward = true,
            bool bindCharacter = true,
            Map<int, MapData>? overrideMaps}) =>
        const SourceEventProjector().project(
            source: source,
            analysis: overrideAnalysis ?? analysis,
            nativeMaps: overrideMaps ?? maps,
            characterBindings:
                bindCharacter ? _characters(source, analysis) : const {},
            pokedexRewardBinding: {if (bindReward) source.eventIdentity(102, 10): binding});
    setUpAll(() async {
      final fixture = await _source(archive!, root!);
      source = fixture.$1;
      final full = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source,
interpretationProfile: fixtureSourceInterpretationProfile,
))
          .analyze();
      event = full.eventAt(102, 10)!;
      analysis = SourceEventAnalysis(
          profile: full.profile,
          events: [event],
          diagnostics: full.diagnostics);
      binding = (await const SourcePokedexRewardBindingResolver()
          .read(sourceMapId: 102, sourceEventId: 10, source: source, analysis: analysis, files: fixture.$2))!;
      maps = _nativeMaps(source);
      projection = project();
    });
    test('actual stationary aide becomes two native reusable page scenes', () {
      final evidence = _eventEvidence(projection, event);
      expect(evidence['status'], 'adaptedStaticSemantics',
          reason: '${evidence['gaps']}');
      final anchor = _anchor(projection, event);
      expect(anchor.kind, MapEntityKind.npc);
      expect(anchor.pos, GridPos(x: 14, y: 7));
      expect(anchor.npc!.lineOfSightRange, 0);
      expect(anchor.npc!.trainerId, isNull);
      expect(projection.scenes, hasLength(2));
      expect(projection.facts, hasLength(1));
      expect(projection.itemCatalog!.entries.single.id,
          binding.item.definition.id);
      expect(
          projection.registry.records.every((r) =>
              r.definitionOrNull!.source.toJson()['kind'] == 'entityInteract'),
          isTrue);
      expect(
          projection.registry.records.every((r) =>
              r.definitionOrNull!.reusePolicy ==
              NarrativeEventReusePolicy.reusable),
          isTrue);
    });
    test('condition and text use the same typed canonical caught scope', () {
      final scene = _scene(projection, event, 0);
      final condition = scene.graph.nodes
          .where((n) => n.payload is SceneConditionPayload)
          .single
          .payload as SceneConditionPayload;
      expect(
          condition.conditionSource,
          SceneConditionSource.pokedexCaughtAtLeast(
              range: binding.range, minimum: 20));
      final text = projection.dialogueSources.values.join(' ');
      expect(text, contains(binding.range.dialoguePlaceholder));
      expect(text, contains('{{ player_name }}'));
      expect(text, isNot(contains(r'\v[2]')));
      expect(text, isNot(contains(r'\PN')));
      expect(scene.graph.nodes.any((n) => n.kind == SceneNodeKind.battle),
          isFalse);
    });
    for (final scenario in [
      'nineteen',
      'twenty',
      'no',
      'cancel',
      'close',
      'bagFull',
      'grantUnknown'
    ]) {
      test(
          'native graph $scenario grants once and sets source A only after success',
          () async {
        final trace = <String>[];
        final speciesIndex = PokemonSpeciesIndex([
          for (var number = 1; number <= 20; number++)
            PokemonSpeciesIndexEntry(
                id: 'test_species_$number',
                nationalDex: number,
                primaryName: 'Species $number',
                types: const ['normal'],
                relativePath: '$number.json')
        ]);
        var state = GameState(
            saveId: 'native-reward-unit',
            progression: PlayerProgression(caughtSpeciesIds: [
              for (var number = 1;
                  number <= (scenario == 'nineteen' ? 19 : 20);
                  number++)
                'test_species_$number'
            ]),
            bag: Bag(
                entries: scenario == 'bagFull'
                    ? [
                        BagEntry(
                            itemId: binding.item.definition.id,
                            quantity: maximumBagEntryQuantity)
                      ]
                    : const []));
        final initialBag = state.bag;
        final result = await SceneRuntimeExecutor(
                callbacks: SceneRuntimeExecutionCallbacks(
                    evaluateCondition: (intent) {
                      expect(intent.conditionSource!.sourceKind,
                          SceneConditionSourceKind.pokedexCaughtCount);
                      trace.add('count');
                      return evaluateScenePokedexCaughtCondition(
                              source: intent.conditionSource!,
                              gameState: state,
                              speciesIndex: speciesIndex)
                          ? 'true'
                          : 'false';
                    },
                    showDialogue: (intent) {
                      final content =
                          projection.dialogueSources[intent.dialogueId]!;
                      trace.add(content.contains('Oh...')
                          ? 'greeting'
                          : content.contains('Great!')
                              ? 'eligible'
                              : content.contains('Uh-oh!')
                                  ? 'insufficient'
                                  : content.contains('Oh. I see.')
                                      ? 'refused'
                                      : 'explanation');
                      if (intent.expectedOutcomes.isEmpty) return 'completed';
                      return switch (scenario) {
                        'no' => 'choice_1',
                        'cancel' =>
                          intent.choicePolicies.single.cancellation.outcomeId!,
                        'close' => 'completed',
                        _ => 'choice_0'
                      };
                    },
                    startBattle: (_) => throw StateError('No battle'),
                    playCinematic: (_) => throw StateError('No cinematic'),
                    applyConsequence: (consequence) {
                      if (consequence.kind == SceneConsequenceKind.giveItem) {
                        trace.add('grant');
                        expect(
                            consequence,
                            SceneConsequence.giveItem(
                                itemId: binding.item.definition.id,
                                quantity: 1));
                        if (scenario == 'grantUnknown') return 'unknown';
                        final granted = const BagOperations().give(
                            BagGiveRequest(
                                bag: state.bag,
                                itemId: binding.item.definition.id,
                                quantity: 1));
                        if (!granted.isSuccess) return 'itemGrantRejected';
                        state = state.copyWith(bag: granted.bag);
                        return 'completed';
                      }
                      expect(
                          consequence,
                          SceneConsequence.setFact(
                              factId: sourceEventFactBindingId(
                                  binding.programs.first.rewardFactId),
                              value: true));
                      expect(trace.last, 'explanation');
                      trace.add('A');
                      state = state.copyWith(
                          narrativeFactRuntimeState: NarrativeFactRuntimeState(
                              overridesByFactId: {
                            sourceEventFactBindingId(
                                binding.programs.first.rewardFactId): true
                          }));
                      return 'completed';
                    }))
            .execute(buildSceneRuntimePlan(_scene(projection, event, 0)).plan!);
        expect(
            trace,
            switch (scenario) {
              'twenty' => [
                  'greeting',
                  'count',
                  'eligible',
                  'grant',
                  'explanation',
                  'A'
                ],
              'nineteen' => ['greeting', 'count', 'insufficient'],
              'no' || 'cancel' => ['greeting', 'refused'],
              'close' => ['greeting'],
              _ => ['greeting', 'count', 'eligible', 'grant']
            });
        expect(
            result.status,
            scenario == 'bagFull' || scenario == 'grantUnknown'
                ? SceneRuntimeExecutionStatus.failed
                : SceneRuntimeExecutionStatus.completed);
        if (scenario == 'twenty') {
          final loaded = GameState.fromJson(state.toJson());
          expect(
              const BagOperations()
                  .quantityOf(loaded.bag, binding.item.definition.id),
              1);
          expect(
              loaded.narrativeFactRuntimeState.overridesByFactId[
                  sourceEventFactBindingId(
                      binding.programs.first.rewardFactId)],
              true);
        } else {
          expect(state.bag, initialBag);
          expect(state.narrativeFactRuntimeState.overridesByFactId, isEmpty);
        }
      });
    }
    test('post-reward page only explains without count, item or A mutation',
        () async {
      var lines = 0;
      final result = await SceneRuntimeExecutor(
              callbacks: SceneRuntimeExecutionCallbacks(
                  evaluateCondition: (_) => throw StateError('No count'),
                  showDialogue: (intent) {
                    lines += intent.linePolicies.length;
                    return 'completed';
                  },
                  startBattle: (_) => throw StateError('No battle'),
                  playCinematic: (_) => throw StateError('No cinematic'),
                  applyConsequence: (_) => throw StateError('No reward')))
          .execute(buildSceneRuntimePlan(_scene(projection, event, 1)).plan!);
      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(lines, 4);
    });
    test('missing semantic or character binding quarantines the entire event',
        () {
      for (final result in [
        project(bindReward: false),
        project(bindCharacter: false)
      ]) {
        expect(
            _eventEvidence(result, event)['status'], 'quarantinedWholeEvent');
        expect(result.scenes, isEmpty);
        expect(result.facts, isEmpty);
        expect(result.itemCatalog, isNull);
      }
    });
    test(
        'native collision and full occupied footprint refuse the source anchor',
        () {
      for (final value in [
        _nativeMaps(source, blockAide: true),
        _nativeMaps(source, occupied: [
          MapEntity(
              id: 'occupied',
              kind: MapEntityKind.custom,
              pos: GridPos(x: 13, y: 7),
              size: const GridSize(width: 2, height: 1),
              blocksMovement: true)
        ])
      ]) {
        final result = project(overrideMaps: value);
        expect(
            _eventEvidence(result, event)['status'], 'quarantinedWholeEvent');
        expect(result.scenes, isEmpty);
      }
    });
    test('dropping both typed bodies cannot bypass the raw reward binding', () {
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
            for (final page in event.pages)
              SourceEventPageAnalysis(
                  sourcePage: page.sourcePage,
                  locator: page.locator,
                  condition: page.condition,
                  graphic: page.graphic,
                  body: SourceEventBlock(nodes: const [], span: page.body.span),
                  rawDataRef: page.rawDataRef,
                  diagnostics: const [])
          ]);
      final result = project(
          overrideAnalysis: SourceEventAnalysis(
              profile: analysis.profile,
              events: [changed],
              diagnostics: const []));
      expect(_eventEvidence(result, event)['status'], 'quarantinedWholeEvent');
      expect(result.scenes, isEmpty);
      expect(result.facts, isEmpty);
    });
  },
      skip: archive == null || root == null
          ? 'Original source and archive required.'
          : false);
}
