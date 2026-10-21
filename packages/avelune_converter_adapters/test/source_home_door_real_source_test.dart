import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/native_writer_fixture.dart';
import 'support/source_external_original_fixture.dart';

SourceEventDefinition _replace(SourceEventDefinition event,
        {int? x, List<SourceEventPageAnalysis>? pages}) =>
    SourceEventDefinition(
        sourceMapId: event.sourceMapId,
        sourceEventId: event.sourceEventId,
        sourceFileId: event.sourceFileId,
        identity: event.identity,
        name: event.name,
        x: x ?? event.x,
        y: event.y,
        locator: event.locator,
        pages: pages ?? event.pages);

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final output = Platform.environment['AVELUNE_HOME_DOOR_OUTPUT'];
  group('original home door foreign state', () {
    late NormalizedSourceProject source;
    late SourceFilePort files;
    late SourceEventAnalysis analysis;
    setUpAll(() async {
      final fixture = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: {6, 7},
          supplementalRoots:
              (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                      '')
                  .split('|')
                  .where((s) => s.isNotEmpty)
                  .toList());
      source = fixture.source;
      files = fixture.files;
      analysis = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.forProject(source))
          .analyze();
    });
    test('binds all ordered foreign reads and writes to declared companions',
        () {
      final door = analysis.eventAt(6, 1)!;
      final program = sourceRoutedDoorPrograms(
          source: source, analysis: analysis)[door.identity];
      expect(program, isNotNull);
      expect(program!.foreignCompanionEventIds, {10, 11});
      expect(program.isBoundTo(source: source, analysis: analysis, event: door),
          isTrue);
      final conditionals = door.pages.first.body.nodes
          .whereType<SourceConditionalNode>()
          .toList();
      expect(conditionals, hasLength(3));
      final analyzer =
          SourceEventAnalyzer.forProject(source, profile: analysis.profile);
      expect(conditionals.map((n) => n.condition.factId), [
        analyzer.selfFactId(6, 11, 'A'),
        analyzer.selfFactId(6, 11, 'B'),
        analyzer.selfFactId(6, 11, 'C'),
      ]);
      expect(
          conditionals.map(
              (n) => (n.whenTrue.nodes.single as SourceSelfSwitchNode).factId),
          [
            analyzer.selfFactId(6, 11, 'A'),
            analyzer.selfFactId(6, 11, 'C'),
            analyzer.selfFactId(6, 10, 'A'),
          ]);
      expect(
          conditionals.map(
              (n) => (n.whenTrue.nodes.single as SourceSelfSwitchNode).value),
          [false, true, true]);
      expect(analysis.eventAt(6, 11)!.isQuarantined, isTrue);
      for (final actorId in [10, 11]) {
        final actor = analysis.eventAt(6, actorId)!;
        expect(
            sourceRoutedDoorCompanionIsBound(
                source: source, analysis: analysis, event: actor),
            isTrue);
        expect(
            sourceRoutedDoorCompanionIsBound(
                source: source,
                analysis: analysis,
                event: _replace(actor, x: actor.x + 1)),
            isFalse);
        final page = actor.pages.first;
        final changed = _replace(actor, pages: [
          SourceEventPageAnalysis(
              sourcePage: page.sourcePage,
              locator: page.locator,
              condition: SourceEventCondition(
                  kind: SourceEventConditionKind.variableAtLeast,
                  variableId: 29,
                  factId: analyzer.variableFactId(29),
                  minimum: 2),
              graphic: page.graphic,
              body: page.body,
              rawDataRef: page.rawDataRef,
              diagnostics: page.diagnostics),
          ...actor.pages.skip(1),
        ]);
        expect(
            sourceRoutedDoorCompanionIsBound(
                source: source, analysis: analysis, event: changed),
            isFalse);
      }
      final first = door.pages.first;
      final branch = conditionals.first;
      final write = branch.whenTrue.nodes.single as SourceSelfSwitchNode;
      final forgedBranch = SourceConditionalNode(branch.span,
          condition: branch.condition,
          whenTrue: SourceEventBlock(span: branch.whenTrue.span, nodes: [
            SourceSelfSwitchNode(write.span,
                letter: write.letter, value: true, factId: write.factId),
          ]),
          whenFalse: branch.whenFalse);
      final forged = _replace(door, pages: [
        SourceEventPageAnalysis(
            sourcePage: first.sourcePage,
            locator: first.locator,
            condition: first.condition,
            graphic: first.graphic,
            body: SourceEventBlock(span: first.body.span, nodes: [
              for (final n in first.body.nodes)
                identical(n, branch) ? forgedBranch : n
            ]),
            rawDataRef: first.rawDataRef,
            diagnostics: first.diagnostics),
        door.pages.last,
      ]);
      final forgedAnalysis = SourceEventAnalysis(
          profile: analysis.profile,
          diagnostics: analysis.diagnostics,
          events: [
            for (final e in analysis.events)
              e.identity == door.identity ? forged : e
          ]);
      expect(
          program.isBoundTo(
              source: source, analysis: forgedAnalysis, event: forged),
          isFalse);
      expect(
          sourceRoutedDoorPrograms(source: source, analysis: forgedAnalysis)
              .containsKey(door.identity),
          isFalse);
    });

    test(
        'complete maps 6 and 7 publish both home directions with quarantined tutorial',
        () async {
      final temporary =
          await Directory.systemTemp.createTemp('converted-home-door-');
      addTearDown(() => temporary.delete(recursive: true));
      final limits =
          sourceCatalogStudyWriteLimitsFor(2, includeNativeCatalog: false);
      Future<LiteralTileComposition> literal(
              List<LiteralDependencyDecision> decisions) =>
          const LiteralTileComposer().compose(
              source: source,
              files: files,
              selectedSourceMapIds: [6, 7],
              projectName: 'Original home door',
              parentPath: temporary.path,
              folderName: 'native',
              dependencyDecisions: decisions,
              limits: limits);
      final probe = await literal([]);
      final base = await literal([
        for (final dependency in probe.dependencies)
          if (!const {6, 7}.contains(dependency.targetSourceMapId))
            LiteralDependencyDecision(
                sourceSnapshotHash: source.snapshot.canonicalHash,
                selectionHash: probe.selectionHash,
                locator: dependency.locator,
                targetSourceMapId: dependency.targetSourceMapId,
                decision: LiteralDependencyDisposition.excludeStudy),
      ]);
      final semantic = (await const SourceSemanticStudyComposer()
          .compose(source: source, base: base, files: files, limits: limits))!;
      final events = (await const SourceEventStudyComposer().compose(
          source: source, base: semantic, files: files, limits: limits))!;
      final rows =
          (events.projection.semanticEvidence['events'] as List).cast<Map>();
      for (final (mapId, eventId) in [(6, 1), (7, 1), (7, 2), (7, 3)]) {
        final row = rows.singleWhere((r) =>
            r['locator']['mapId'] == mapId &&
            r['locator']['eventId'] == eventId);
        expect(row['status'], 'adaptedStaticSemantics',
            reason: '$mapId/$eventId ${row['gaps']}');
        expect(row['gaps'], isEmpty);
      }
      final tutorial = rows.singleWhere(
          (r) => r['locator']['mapId'] == 6 && r['locator']['eventId'] == 11);
      expect(tutorial['status'], 'quarantinedWholeEvent');
      expect(tutorial['gaps'], contains('sourceCommandUnqualified'));
      final pallet = events.projection.nativeMaps[6]!;
      for (final actorId in [10, 11]) {
        final actor = analysis.eventAt(6, actorId)!;
        final entity = pallet.entities.singleWhere(
            (e) => e.properties['sourceEventIdentity'] == actor.identity.value);
        expect(entity.properties['sourceInteractionPolicy'],
            'preservedQuarantinedWholeEvent');
        expect(entity.presentation!.variants, hasLength(actor.pages.length));
        if (actorId == 10) {
          expect(
              entity.npc!.movement, isNot(const MapEntityNpcMovementConfig()));
        }
      }
      final analyzer =
          SourceEventAnalyzer.forProject(source, profile: analysis.profile);
      for (final (id, letter) in [(11, 'A'), (11, 'B'), (11, 'C'), (10, 'A')]) {
        final key = analyzer.selfFactId(6, id, letter);
        final fact = events.projection.facts.singleWhere(
            (f) => f.description == 'Persistent source boolean: $key');
        expect(fact.defaultValue, isFalse);
      }
      final approval = approveNativeFixtureDraft(events.draft);
      final receipt = await NativeProjectWriter()
          .write(approval.plan, approval.context, events.draft, limits: limits);
      expect(receipt.verified, isTrue);
      final handles = WorkspaceHandleStore();
      const reader = LocalProjectFileReader();
      final policy = await WorkspacePolicy.create(
          allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
      final opener = ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles);
      final opened = await opener.openProject(receipt.projectPath);
      try {
        final loaded = await ProjectSnapshotLoader(handles: handles).load(
            opened.projectHandle,
            policy: ProjectSnapshotLoadPolicy.strict);
        expect(loaded.loadDiagnostics, isEmpty);
        expect(loaded.maps, hasLength(2));
      } finally {
        opener.closeWorkspace(opened.workspaceHandle);
      }
      if (output != null) {
        await Directory(output).create(recursive: true);
        final copy = await Process.run(
            'ditto', [receipt.projectPath, '$output/project']);
        expect(copy.exitCode, 0, reason: '${copy.stderr}');
        await File('$output/receipt.json').writeAsString(jsonEncode({
          'projectPath': '$output/project',
          'strictNativeWriterVerified': receipt.verified,
          'sourceSnapshotHash': source.snapshot.canonicalHash.value,
          'eventEvidence': rows,
          'scriptsExecuted': 0,
          'aiCalls': 0,
          'tutorialInteractionSupported': false,
        }));
      }
    }, timeout: const Timeout(Duration(minutes: 12)));
  },
      skip: root == null || snapshot == null
          ? 'Requires inert original source witness.'
          : false);
}
