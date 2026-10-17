import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';

SourceEventDefinition _withoutFloorWrite(SourceEventDefinition event) =>
    SourceEventDefinition(
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
            if (page.originalPageIndex != 0)
              page
            else
              SourceEventPageAnalysis(
                  sourcePage: page.sourcePage,
                  locator: page.locator,
                  condition: page.condition,
                  graphic: page.graphic,
                  body: SourceEventBlock(
                      nodes: page.body.nodes.skip(1).toList(),
                      span: page.body.span),
                  rawDataRef: page.rawDataRef,
                  diagnostics: [])
        ]);

final class _OverrideFiles implements SourceFilePort {
  _OverrideFiles(this.original, this.fileId, this.bytes);
  final SourceFilePort original;
  final ConverterId fileId;
  final List<int> bytes;
  @override
  Future<List<int>> read(ConverterId id) async =>
      id == fileId ? List.of(bytes) : original.read(id);
}

SourceSnapshot _replacingSnapshot(
        SourceSnapshot original, SourceFileEntry entry, List<int> bytes) =>
    SourceSnapshot(
        logicalProjectNamespace: original.logicalProjectNamespace,
        policyHash: original.policyHash,
        entries: [
          for (final current in original.entries)
            current.fileId == entry.fileId
                ? SourceFileEntry(
                    fileId: current.fileId,
                    relativePath: current.relativePath,
                    kind: current.kind,
                    byteLength: bytes.length,
                    sha256: Sha256Hash(crypto.sha256.convert(bytes).toString()),
                    format: current.format,
                    family: current.family)
                : current
        ],
        diagnostics: original.diagnostics,
        excludedPaths: original.excludedPaths,
        profileEvidence: original.profileEvidence,
        state: original.state);

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final supplemental = Platform
          .environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS']
          ?.split('|') ??
      const <String>[];
  final proof = Platform.environment['AVELUNE_ELEVATOR_AUDIT_PROOF'];

  test('existing native integer facts preserve both source variables on save',
      () {
    final facts = [
      for (final id in [10, 11])
        NarrativeFactDefinition(
            id: 'source_variable_$id',
            label: 'Source variable $id',
            initialValue: NarrativeValue.integer(0))
    ];
    final writer = NarrativeFactRuntimeWriter(
        NarrativeFactRuntimeResolver.fromFacts(facts));
    var state = const GameState(saveId: 'elevator_native_contract_probe');
    for (final floor in [1, 11, 2]) {
      final result = writer.setFactValue(
          gameState: state,
          factId: 'source_variable_10',
          value: NarrativeValue.integer(floor));
      expect(result.success, true);
      state = result.gameState;
    }
    final selected = writer.setFactValue(
        gameState: state,
        factId: 'source_variable_11',
        value: NarrativeValue.integer(0));
    final reopened = GameState.fromJson(
        jsonDecode(jsonEncode(selected.gameState.toJson()))
            as Map<String, dynamic>);
    expect(reopened.narrativeFactRuntimeState.valueFor('source_variable_10'),
        NarrativeValue.integer(2));
    expect(reopened.narrativeFactRuntimeState.valueFor('source_variable_11'),
        NarrativeValue.integer(0));
    final command = SceneConsequence.setFactValue(
        factId: facts.first.id, value: NarrativeValue.integer(11));
    expect(SceneConsequence.fromJson(command.toJson()), command);
    final condition = SceneConditionSource.factValue(
        factId: facts.first.id,
        operator: NarrativeFactOperator.greaterThan,
        expectedValue: NarrativeValue.integer(2));
    expect(SceneConditionSource.fromJson(condition.toJson()), condition);
  });

  group('complete elevator family remains unadmitted without state closure',
      () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    late SourceFilePort files;
    late List<SourceEventDefinition> doors;
    late Map<int, MapData> maps;
    setUpAll(() async {
      final fixture = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: {
            38,
            40,
            173,
            174,
            176,
            177,
            ...List.generate(12, (i) => 213 + i)
          },
          supplementalRoots: supplemental);
      source = fixture.source;
      files = fixture.files;
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
      doors = analysis.events
          .where((event) => event.name == 'Elevator door')
          .toList();
      maps = {
        for (final ir in source.maps)
          ir.map.sourceMapId: MapData(
              id: 'elevator_audit_${ir.map.sourceMapId}',
              name: ir.map.name,
              size: GridSize(width: ir.map.width, height: ir.map.height),
              layers: [])
      };
    });

    SourceEventProjection project(List<SourceEventDefinition> events) =>
        const SourceEventProjector().project(
            source: source,
            analysis: SourceEventAnalysis(
                profile: analysis.profile, events: events, diagnostics: []),
            nativeMaps: maps);

    test('complete source discovery includes all 19 elevator departures', () {
      final candidates = sourceDoorEventProjectionCandidates(
          source: source, analysis: analysis);
      expect(candidates.where((event) => event.name == 'Elevator door'),
          hasLength(19));
    });

    test('all 19 retain their floor write and both complete pages', () async {
      expect(analysis.profile.isQualified, true);
      expect(doors, hasLength(19));
      for (final event in doors) {
        expect(event.pages, hasLength(2));
        expect(event.isQuarantined, true);
        final write = event.pages.first.body.nodes.first as SourceUnknownNode;
        expect(write.command.code, 122);
        expect(write.command.parameters.take(4), [10, 10, 0, 0]);
        expect(write.command.parameters.last, inInclusiveRange(1, 11));
        expect(event.pages.last.body.nodes.first, isA<SourceConditionalNode>());
      }
      if (proof != null) {
        await File(proof).writeAsString(
            jsonEncode({
              'sourceSnapshotHash': source.snapshot.canonicalHash.value,
              'normalizationHash': source.canonicalHash.value,
              'profile': analysis.profile.toJson(),
              'selectedSourceMapIds': source.selectedSourceMapIds,
              'sourceScriptsExecuted': 0,
              'events': [
                for (final event in analysis.events.where((event) =>
                    doors.contains(event) ||
                    ({40, 177, 224}.contains(event.sourceMapId) &&
                        {1, 2, 3, 4, 5}.contains(event.sourceEventId))))
                  {
                    'sourceMapId': event.sourceMapId,
                    'sourceEventId': event.sourceEventId,
                    'sourceFileId': event.sourceFileId.value,
                    'sourceFileHash': source
                        .archive.files[event.sourceFileId]!.contentHash.value,
                    'eventIdentity': event.identity.value,
                    'name': event.name,
                    'position': [event.x, event.y],
                    'quarantined': event.isQuarantined,
                    'pages': [
                      for (final page in event.pages)
                        {
                          'source': page.sourcePage.toJson(),
                          'raw': page.rawDataRef?.toJson(),
                          'condition': page.condition.toJson(),
                          'diagnostics':
                              page.diagnostics.map((d) => d.code).toList(),
                          'nodeKinds': page.body.nodes
                              .map((n) => n.runtimeType.toString())
                              .toList(),
                          'forcedRoutes': page.body.nodes
                              .whereType<SourceForcedMoveRouteNode>()
                              .map((n) => n.toJson())
                              .toList()
                        }
                    ]
                  }
              ]
            }),
            flush: true);
      }
    });

    test('all 19 emit no native scenes, integer writes or partial doors', () {
      final projected = project(doors);
      expect(projected.scenes, isEmpty);
      expect(projected.facts, isEmpty);
      expect(projected.nativeMaps.values.expand((map) => map.warps), isEmpty);
      expect(sourceRoutedDoorPrograms(source: source, analysis: analysis).keys,
          isNot(contains(anyOf(doors.map((event) => event.identity)))));
    });

    test('omitting every reader and controller does not admit a departure', () {
      expect(project([doors.first]).scenes, isEmpty);
      expect(project([doors.first]).facts, isEmpty);
    });

    test('caller deletion of floor AST cannot mint a routed-door capability',
        () {
      final forged = _withoutFloorWrite(doors.first);
      expect(forged.isQuarantined, false);
      final subset = SourceEventAnalysis(
          profile: analysis.profile, events: [forged], diagnostics: []);
      expect(
          sourceRoutedDoorPrograms(source: source, analysis: subset), isEmpty);
      expect(project([forged]).scenes, isEmpty);
      final programs =
          sourceElevatorPrograms(source: source, analysis: analysis);
      expect(programs, hasLength(34));
      final changed = SourceEventAnalysis(profile: analysis.profile, events: [
        for (final event in analysis.events)
          if (event.identity == forged.identity) forged else event
      ], diagnostics: []);
      expect(
          sourceElevatorPrograms(source: source, analysis: changed), isEmpty);
      expect(
          programs[forged.identity]!
              .isBoundTo(source: source, analysis: changed, event: forged),
          false);
    });

    test('fresh context rejects source bytes changed after normalization',
        () async {
      final archive = source.archive.files.values.singleWhere(
          (file) => file.entry.relativePath == 'Data/Map038.rxdata');
      final bytes = List<int>.of(archive.rawBytes);
      bytes[bytes.length - 1] ^= 1;
      final program = sourceElevatorPrograms(source: source, analysis: analysis)
          .values
          .first;
      await expectLater(
          const SourceEventExecutionContextResolver().read(
              source: source,
              base: null,
              nativeMaps: maps,
              files: _OverrideFiles(files, archive.entry.fileId, bytes),
              elevatorProgram: program),
          throwsA(isA<NativeWriteException>().having((error) => error.code,
              'code', 'events.execution.witness.changed')));
    });

    for (final mutation in [
      'floorWrite',
      'raw509',
      'controller',
      'floorWriteRemoved'
    ]) {
      test('reattested source $mutation variation refuses the entire family',
          () async {
        final mapId = mutation == 'floorWriteRemoved'
            ? 213
            : mutation == 'controller'
                ? 40
                : 38;
        final archive = source.archive.files.values.singleWhere((file) =>
            file.entry.relativePath ==
            'Data/Map${mapId.toString().padLeft(3, '0')}.rxdata');
        final document = archive.document;
        final bytes = List<int>.of(archive.rawBytes);
        MarshalNode field(MarshalNode owner, String name) =>
            document.node(owner.instanceVariables
                .singleWhere((pair) => document.node(pair.key).name == name)
                .value);
        final events = field(document.node(document.rootId), '@events');
        final owner = document.node(events.pairs
            .singleWhere((pair) =>
                document.node(pair.key).integerValue ==
                BigInt.from(mutation == 'floorWriteRemoved'
                    ? 1
                    : mutation == 'controller'
                        ? 2
                        : 3))
            .value);
        final page = document.node(field(owner, '@pages').elements.first);
        final commands =
            field(page, '@list').elements.map(document.node).toList();
        if (mutation == 'floorWriteRemoved') {
          final command = commands.firstWhere((command) =>
              field(command, '@code').integerValue == BigInt.from(122));
          final code = field(command, '@code');
          final parameters = field(command, '@parameters');
          final offset = parameters.location.byteOffset;
          expect(bytes[code.location.byteOffset + 1], 127);
          expect(bytes.sublist(offset, offset + 2), [91, 10]);
          for (final (index, id) in parameters.elements.indexed) {
            expect(
                document.node(id).location.byteOffset, offset + 2 + index * 2);
          }
          bytes[code.location.byteOffset + 1] = 0;
          bytes[offset + 1] = 0;
          bytes.removeRange(offset + 2, offset + 12);
        } else {
          late MarshalNode changed;
          if (mutation == 'floorWrite') {
            final command = commands.firstWhere((command) =>
                field(command, '@code').integerValue == BigInt.from(122));
            changed =
                document.node(field(command, '@parameters').elements.last);
          } else if (mutation == 'raw509') {
            final command = commands.firstWhere((command) =>
                field(command, '@code').integerValue == BigInt.from(509));
            final move =
                document.node(field(command, '@parameters').elements.single);
            changed = field(move, '@code');
          } else {
            final command = commands.firstWhere((command) =>
                field(command, '@code').integerValue == BigInt.from(122));
            changed =
                document.node(field(command, '@parameters').elements.first);
          }
          final value = changed.integerValue!.toInt();
          expect(bytes[changed.location.byteOffset], 0x69);
          expect(bytes[changed.location.byteOffset + 1], value + 5);
          bytes[changed.location.byteOffset + 1] = value + 6;
        }
        final overlay = _OverrideFiles(files, archive.entry.fileId, bytes);
        final variant = await const RmxpSourceNormalizer().normalize(
            snapshot: _replacingSnapshot(source.snapshot, archive.entry, bytes),
            files: overlay,
            selectedMapIds: source.selectedSourceMapIds.toSet(),
            includeEventSystem: true,
            includeConnections: true);
        final current = SourceEventAnalyzer.forProject(variant,
                profile: SourceEventProfile.kantoForProject(variant))
            .analyze();
        expect(sourceElevatorPrograms(source: variant, analysis: current),
            isEmpty);
        if (mutation == 'floorWriteRemoved') {
          final changedDoor = current.eventAt(213, 1)!;
          expect(changedDoor.isQuarantined, false);
          expect(
              sourceDoorEventProjectionCandidates(
                      source: variant, analysis: current)
                  .where((event) => event.identity == changedDoor.identity),
              isEmpty);
          final result = const SourceEventProjector().project(
              source: variant,
              analysis: SourceEventAnalysis(
                  profile: current.profile,
                  events: [changedDoor],
                  diagnostics: []),
              nativeMaps: maps);
          final row = (result.semanticEvidence['events'] as List)
              .cast<Map>()
              .singleWhere(
                  (row) => row['sourceIdentity'] == changedDoor.identity.value);
          expect(row['gaps'],
              contains('sourceElevatorCompleteFamilyBindingMissing'));
        }
        final original =
            sourceElevatorPrograms(source: source, analysis: analysis)
                .values
                .first;
        expect(
            original.isBoundTo(
                source: variant,
                analysis: current,
                event: current.events.singleWhere(
                    (event) => event.identity == original.eventIdentity)),
            false);
      });
    }

    test('all cabin readers and controllers remain whole-event quarantined',
        () {
      final cabins = analysis.events
          .where((event) =>
              {40, 177, 224}.contains(event.sourceMapId) &&
              {1, 2}.contains(event.sourceEventId))
          .toList();
      expect(cabins, hasLength(6));
      expect(cabins.every((event) => event.isQuarantined), true);
      expect(project(cabins).scenes, isEmpty);
      expect(project(cabins).facts, isEmpty);
    });
  },
      skip: root == null || snapshot == null
          ? 'External source witness paths required'
          : false);
}
