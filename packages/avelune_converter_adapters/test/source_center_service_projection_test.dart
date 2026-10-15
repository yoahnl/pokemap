import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:avelune_converter_adapters/src/source_event_projection.dart';
import 'package:avelune_converter_adapters/src/source_center_recovery_binding.dart';

final class _Files implements SourceFilePort {
  _Files(this.bytes);
  final Map<ConverterId, List<int>> bytes;

  @override
  Future<List<int>> read(ConverterId id) async => List.of(bytes[id]!);
}

List<int> _replaceLiteral(List<int> bytes, String before, String after) {
  final old = utf8.encode(before), next = utf8.encode(after);
  final pattern = [0x22, old.length + 5, ...old];
  for (var index = 0; index <= bytes.length - pattern.length; index++) {
    if (List.generate(pattern.length, (slot) => bytes[index + slot])
        .indexed
        .every((entry) => entry.$2 == pattern[entry.$1])) {
      return [
        ...bytes.take(index),
        0x22,
        next.length + 5,
        ...next,
        ...bytes.skip(index + pattern.length)
      ];
    }
  }
  throw StateError('Source literal not found: $before');
}

Future<NormalizedSourceProject> _source(String folder,
    {String? before, String? after}) async {
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
  final map = (input['entries'] as List)
      .cast<Map>()
      .singleWhere((row) => row['relativePath'] == 'Data/Map102.rxdata');
  final mapId = ConverterId(map['fileId'] as String);
  if (before != null) {
    bytes[mapId] = _replaceLiteral(bytes[mapId]!, before, after!);
  }
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
              byteLength: row['fileId'] == mapId.value && before != null
                  ? bytes[mapId]!.length
                  : row['byteLength'] as int,
              sha256: row['sha256'] == null
                  ? null
                  : Sha256Hash(row['fileId'] == mapId.value && before != null
                      ? crypto.sha256.convert(bytes[mapId]!).toString()
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
  return const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: _Files(bytes),
      selectedMapIds: {102},
      includeEventSystem: true);
}

SourceEventProjection _project(NormalizedSourceProject source,
    {bool nativeBlocked = true,
    SourceEventAnalysis? analysis,
    bool nativeCounter = false,
    bool bindNurse = false,
    SourceCenterRecoveryBinding? centerRecoveryBinding,
    List<MapEntity> nativeEntities = const []}) {
  final map = source.maps.single.map;
  final native = MapData(
      id: 'center_native',
      name: map.name,
      size: GridSize(width: map.width, height: map.height),
      entities: nativeEntities,
      layers: [
        MapLayer.collision(
            id: 'collision',
            name: 'Collision',
            collisions: List.generate(
                map.width * map.height,
                (index) =>
                    (nativeBlocked && index == 3 * map.width + 13) ||
                    (nativeCounter && index == 5 * map.width + 9)))
      ]);
  return const SourceEventProjector().project(
      source: source,
      analysis: analysis ??
          SourceEventAnalyzer.forProject(source,
                  profile: SourceEventProfile.kantoForProject(source))
              .analyze(),
      nativeMaps: {102: native},
      centerRecoveryBinding: centerRecoveryBinding,
      characterBindings: {
        if (bindNurse)
          for (final file in source.snapshot.entries.where((file) =>
              file.relativePath == 'Graphics/Characters/NPC_FRLG_NURSE.png'))
            sourceEventCharacterBindingKey(
                    characterName: 'NPC_FRLG_NURSE', pattern: 0, direction: 2):
                SourceEventCharacterBinding(
                    characterId: 'native_nurse',
                    sourceSnapshotHash: source.snapshot.canonicalHash,
                    sourceFileId: file.fileId,
                    sourceFileHash: file.sha256!,
                    sourcePattern: 0,
                    sourceDirection: 2),
      });
}

final class _OriginalAudioFiles implements SourceFilePort {
  _OriginalAudioFiles(this.source, this.root);
  final NormalizedSourceProject source;
  final String root;
  @override
  Future<List<int>> read(ConverterId id) => File(
          '$root/${source.snapshot.entries.singleWhere((entry) => entry.fileId == id).relativePath}')
      .readAsBytes();
}

Map _evidence(SourceEventProjection projection, int eventId) =>
    (projection.semanticEvidence['events'] as List)
        .cast<Map>()
        .singleWhere((row) => (row['locator'] as Map)['eventId'] == eventId);

void main() {
  final archive = Platform.environment['AVELUNE_AC13_DOOR_ARCHIVE'];
  final sourceRoot = Platform.environment['AVELUNE_AC13_SOURCE_ROOT'];
  group('source Center native projection', () {
    late NormalizedSourceProject source;
    late SourceEventProjection projection;
    setUpAll(() async {
      source = await _source(archive!);
      projection = _project(source);
    });

    test('PC two-page source becomes one native reusable interaction', () {
      final evidence = _evidence(projection, 3);
      expect(evidence['status'], 'adaptedStaticSemantics',
          reason: '${evidence['gaps']}');
      final anchor = projection.nativeMaps[102]!.entities
          .singleWhere((entity) => entity.name == 'PC');
      expect(anchor.pos, const GridPos(x: 13, y: 3));
      final records = projection.registry.records
          .where((record) =>
              record.definitionOrNull?.source.toJson()['entityId'] == anchor.id)
          .toList();
      expect(records, hasLength(1));
      final event = records.single.definitionOrNull!;
      expect(event.source.toJson()['kind'], 'entityInteract');
      expect(event.reusePolicy, NarrativeEventReusePolicy.reusable);
      expect(event.conditionExpression.leaves, isEmpty);
      final scene =
          projection.scenes.singleWhere((scene) => scene.id == event.sceneId);
      final commands = scene.graph.nodes
          .map((node) => node.payload)
          .whereType<SceneActionPayload>()
          .map((payload) => payload.interactiveCommand)
          .whereType<SceneInteractiveCommand>();
      expect(commands.single.kind, SceneInteractiveCommandKind.openPc);
      expect(
          scene.graph.nodes
              .where((node) => node.kind == SceneNodeKind.condition),
          isEmpty);
    });

    for (final serviceResult in ['completed', 'cancelled']) {
      test(
          'real source interaction dispatches one native PC command $serviceResult',
          () async {
        final map = projection.nativeMaps[102]!;
        final interaction = stepGameplayWorld(
            GameplayWorldState.initial(
                map: map,
                playerPos: const GridPos(x: 13, y: 4),
                playerFacing: Direction.north),
            const InteractIntent());
        expect(interaction, isA<EntityInteracted>());
        final anchor = (interaction as EntityInteracted).entity;
        final record = projection.registry.records.singleWhere((record) =>
            record.definitionOrNull?.source.toJson()['entityId'] == anchor.id);
        final scene = projection.scenes.singleWhere(
            (scene) => scene.id == record.definitionOrNull!.sceneId);
        final commands = <SceneInteractiveCommand>[];
        final result = await SceneRuntimeExecutor(
            callbacks: SceneRuntimeExecutionCallbacks(
                evaluateCondition: (_) =>
                    throw StateError('PC has no source cycle guard'),
                showDialogue: (_) =>
                    throw StateError('PC uses its native service'),
                startBattle: (_) => throw StateError('No battle'),
                playCinematic: (_) => throw StateError('No cinematic'),
                applyConsequence: (_) =>
                    throw StateError('No source self switch'),
                executeInteractiveCommand: (intent) {
                  commands.add(intent.interactiveCommand!);
                  return serviceResult;
                })).execute(buildSceneRuntimePlan(scene).plan!);
        expect(result.status, SceneRuntimeExecutionStatus.completed);
        expect(commands, [SceneInteractiveCommand.openPc()]);
      });
    }

    test('PC source cycle is explicitly adapted with both raw witnesses', () {
      final evidence = _evidence(projection, 3);
      final adaptation = evidence['nativeCenterService'] as Map;
      expect(adaptation['nativeCommand'], 'openPc');
      expect(adaptation['sourcePageIndices'], [0, 1]);
      expect(adaptation['sourceRawPages'], hasLength(2));
      expect(adaptation['fullSourceServiceParityQualified'], isFalse);
      expect(adaptation['sourcePcSelfSwitchCycleExecuted'], isFalse);
    });

    test('PC refuses missing native collision rather than changing the anchor',
        () {
      final rejected = _project(source, nativeBlocked: false);
      expect(_evidence(rejected, 3)['status'], 'quarantinedWholeEvent');
      expect(_evidence(rejected, 3)['gaps'],
          contains('sourceCenterPcContactUnqualified'));
      expect(rejected.nativeMaps[102]!.entities.where((e) => e.name == 'PC'),
          isEmpty);
    });

    test(
        'nurse remains refused until its real native counter capability is ready',
        () {
      expect(_evidence(projection, 2)['status'], 'quarantinedWholeEvent');
      expect(_evidence(projection, 2)['gaps'],
          contains('counterInteractionReachUnsupported'));
    });

    for (final variant in ['customWide', 'npcWide', 'npcOffset']) {
      test('PC refuses native collision footprint occupied by $variant', () {
        final occupant = MapEntity(
            id: 'existing_occupant',
            name: 'Occupant',
            kind: variant == 'customWide'
                ? MapEntityKind.custom
                : MapEntityKind.npc,
            pos: const GridPos(x: 12, y: 3),
            size: const GridSize(width: 2, height: 1),
            blocksMovement: true,
            npc: variant == 'customWide'
                ? null
                : const MapEntityNpcData(
                    characterId: 'existing_character', displayName: 'Occupant'),
            properties: {
              mapEntityCollisionWidthProperty:
                  variant == 'npcOffset' ? '1' : '2',
              mapEntityCollisionHeightProperty: '1',
              mapEntityCollisionOffsetXProperty:
                  variant == 'npcOffset' ? '1' : '0',
              mapEntityCollisionOffsetYProperty: '0',
            });
        expect(resolveEntityCollisionCells(occupant),
            contains(const GridPos(x: 13, y: 3)));
        final rejected = _project(source, nativeEntities: [occupant]);
        expect(_evidence(rejected, 3)['status'], 'quarantinedWholeEvent');
        expect(_evidence(rejected, 3)['gaps'],
            contains('sourceCenterPcAnchorOccupied'));
        expect(
            rejected.nativeMaps[102]!.entities
                .where((entity) => entity.name == 'PC'),
            isEmpty);
        expect(
            rejected.nativeMaps[102]!.entities
                .where((entity) => entity.id == occupant.id),
            [occupant]);
      });
    }

    test(
        'PC program refuses changed analyzed raw, condition and graphic witnesses',
        () {
      final analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
      final original = analysis.eventAt(102, 3)!;
      final page = original.pages.first;
      for (final changed in [
        SourceEventPageAnalysis(
            sourcePage: page.sourcePage,
            locator: page.locator,
            condition: page.condition,
            graphic: page.graphic,
            body: page.body,
            rawDataRef: null,
            diagnostics: []),
        SourceEventPageAnalysis(
            sourcePage: page.sourcePage,
            locator: page.locator,
            condition: SourceEventCondition(
                kind: SourceEventConditionKind.globalSwitch,
                factId: 'unrelated'),
            graphic: page.graphic,
            body: page.body,
            rawDataRef: page.rawDataRef,
            diagnostics: []),
        SourceEventPageAnalysis(
            sourcePage: page.sourcePage,
            locator: page.locator,
            condition: page.condition,
            graphic: null,
            body: page.body,
            rawDataRef: page.rawDataRef,
            diagnostics: []),
      ]) {
        final replacement = SourceEventDefinition(
            sourceMapId: original.sourceMapId,
            sourceEventId: original.sourceEventId,
            sourceFileId: original.sourceFileId,
            identity: original.identity,
            name: original.name,
            x: original.x,
            y: original.y,
            locator: original.locator,
            pages: [changed, original.pages.last]);
        final changedAnalysis = SourceEventAnalysis(
            profile: analysis.profile,
            events: [
              for (final event in analysis.events)
                if (event.identity == original.identity) replacement else event
            ],
            diagnostics: analysis.diagnostics);
        expect(
            _evidence(_project(source, analysis: changedAnalysis), 3)['status'],
            'quarantinedWholeEvent');
      }
    });
    for (final decision in ['yes', 'no', 'cancel', 'close', 'serviceCancel']) {
      test('nurse native scene follows $decision without source side effects',
          () async {
        final recovery = await const SourceCenterRecoveryResolver().read(
            source: source, files: _OriginalAudioFiles(source, sourceRoot!));
        final result = _project(source,
            bindNurse: true,
            nativeCounter: true,
            centerRecoveryBinding: recovery);
        final nurse = result.nativeMaps[102]!.entities
            .singleWhere((entity) => entity.name == 'Nurse');
        final record = result.registry.records.singleWhere((record) =>
            record.definitionOrNull?.source.toJson()['entityId'] == nurse.id);
        final definition = record.definitionOrNull!;
        expect(definition.source.toJson()['kind'], 'entityInteract');
        expect(definition.conditionExpression.leaves, isEmpty);
        expect(definition.reusePolicy, NarrativeEventReusePolicy.reusable);
        final scene = result.scenes
            .singleWhere((scene) => scene.id == definition.sceneId);
        final trace = <String>[];
        final music = <DialogueLineFeedback>[];
        final execution = await SceneRuntimeExecutor(
            callbacks: SceneRuntimeExecutionCallbacks(
                evaluateCondition: (_) =>
                    throw StateError('No source StartingOver guard'),
                showDialogue: (intent) {
                  final policies = intent.linePolicies;
                  trace.add(policies
                      .map((policy) => policy.feedback.plainText)
                      .join(' | '));
                  music.addAll(policies
                      .map((policy) => policy.feedback)
                      .where((feedback) => feedback.audioCue != null));
                  if (intent.expectedOutcomes.isEmpty) return 'completed';
                  expect(intent.choicePolicies.single.cancellation.outcomeId,
                      'choice_1');
                  return switch (decision) {
                    'yes' || 'serviceCancel' => 'choice_0',
                    'no' => 'choice_1',
                    'cancel' =>
                      intent.choicePolicies.single.cancellation.outcomeId!,
                    _ => 'completed',
                  };
                },
                startBattle: (_) => throw StateError('No battle'),
                playCinematic: (_) => throw StateError('No source animation'),
                applyConsequence: (_) => throw StateError(
                    'No source stats, facts or checkpoint mutation'),
                executeInteractiveCommand: (intent) {
                  expect(
                      intent.interactiveCommand,
                      SceneInteractiveCommand.openHeal(
                          requiresConfirmation: false));
                  trace.add('nativeHeal');
                  return decision == 'serviceCancel'
                      ? 'cancelled'
                      : 'completed';
                })).execute(buildSceneRuntimePlan(scene).plan!);
        expect(execution.status, SceneRuntimeExecutionStatus.completed);
        expect(
            trace.first, contains('Hello, and welcome to the Pokémon Center.'));
        if (decision == 'yes') {
          expect(trace, hasLength(4));
          expect(trace[1], contains('take your'));
          expect(trace[2], 'nativeHeal');
          expect(trace[3], contains('Thank you for waiting'));
          expect(music, hasLength(1));
          expect(music.single.audioCue!.mediaAssetId, recovery.mediaId);
          expect(music.single.advance.delayMicros, 2900000);
        } else {
          expect(music, isEmpty);
          expect(trace.where((line) => line.contains('Thank you for waiting')),
              isEmpty);
          expect(trace.where((line) => line == 'nativeHeal'),
              decision == 'serviceCancel' ? hasLength(1) : isEmpty);
          if (decision == 'no' || decision == 'cancel') {
            expect(trace.last, contains('see you again'));
          }
        }
      }, skip: sourceRoot == null);
    }

    test(
        'nurse refuses missing recovery music, native counter collision and character binding',
        () async {
      final recovery = await const SourceCenterRecoveryResolver().read(
          source: source, files: _OriginalAudioFiles(source, sourceRoot!));
      for (final entry in [
        (
          _project(source, bindNurse: true, nativeCounter: true),
          'sourceCenterRecoveryBindingMissing'
        ),
        (
          _project(source, bindNurse: true, centerRecoveryBinding: recovery),
          'counterInteractionReachUnsupported'
        ),
        (
          _project(source,
              nativeCounter: true, centerRecoveryBinding: recovery),
          'characterBindingMissing'
        ),
      ]) {
        expect(_evidence(entry.$1, 2)['status'], 'quarantinedWholeEvent');
        expect(_evidence(entry.$1, 2)['gaps'], contains(entry.$2));
        expect(
            entry.$1.nativeMaps[102]!.entities
                .where((entity) => entity.name == 'Nurse'),
            isEmpty);
      }
    }, skip: sourceRoot == null);

    test(
        'nurse refuses source and native footprints covering its counter or anchor',
        () async {
      final recovery = await const SourceCenterRecoveryResolver().read(
          source: source, files: _OriginalAudioFiles(source, sourceRoot!));
      final analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
      final book = analysis.eventAt(102, 5)!;
      final movedBook = SourceEventDefinition(
          sourceMapId: book.sourceMapId,
          sourceEventId: book.sourceEventId,
          sourceFileId: book.sourceFileId,
          identity: book.identity,
          name: book.name,
          x: 8,
          y: 5,
          locator: book.locator,
          pages: book.pages);
      final sourceOccupied = SourceEventAnalysis(
          profile: analysis.profile,
          events: [
            for (final event in analysis.events)
              if (event.identity == book.identity) movedBook else event
          ],
          diagnostics: analysis.diagnostics);
      final rejected = _project(source,
          analysis: sourceOccupied,
          nativeCounter: true,
          bindNurse: true,
          centerRecoveryBinding: recovery);
      expect(_evidence(rejected, 2)['status'], 'quarantinedWholeEvent');
      expect(_evidence(rejected, 2)['gaps'],
          contains('counterInteractionReachUnsupported'));
      for (final y in [4, 5]) {
        final nativeOccupied = _project(source,
            nativeCounter: true,
            bindNurse: true,
            centerRecoveryBinding: recovery,
            nativeEntities: [
              MapEntity(
                  id: 'wide_counter_occupant',
                  name: 'Wide occupant',
                  kind: MapEntityKind.custom,
                  pos: GridPos(x: 8, y: y),
                  size: const GridSize(width: 2, height: 1),
                  blocksMovement: true)
            ]);
        expect(_evidence(nativeOccupied, 2)['status'], 'quarantinedWholeEvent');
        expect(
            _evidence(nativeOccupied, 2)['gaps'],
            contains(y == 4
                ? 'sourceCenterNurseAnchorOccupied'
                : 'counterInteractionReachUnsupported'));
      }
    }, skip: sourceRoot == null);

    test(
        'nurse source consent opens native heal through the attested south counter',
        () async {
      final recovery = await const SourceCenterRecoveryResolver().read(
          source: source, files: _OriginalAudioFiles(source, sourceRoot!));
      final result = _project(source,
          bindNurse: true,
          nativeCounter: true,
          centerRecoveryBinding: recovery);
      expect(_evidence(result, 2)['status'], 'adaptedStaticSemantics',
          reason: '${_evidence(result, 2)['gaps']}');
      final nurse = result.nativeMaps[102]!.entities
          .singleWhere((entity) => entity.name == 'Nurse');
      expect(nurse.pos, const GridPos(x: 9, y: 4));
      expect(nurse.npc!.counterInteractionSides, [EntityFacing.south]);
      expect(
          stepGameplayWorld(
              GameplayWorldState.initial(
                  map: result.nativeMaps[102]!,
                  playerPos: const GridPos(x: 9, y: 6),
                  playerFacing: Direction.north),
              const InteractIntent()),
          isA<NpcInteracted>());
    }, skip: sourceRoot == null);
  }, skip: archive == null);
}
