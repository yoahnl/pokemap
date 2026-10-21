import 'dart:convert';
import 'dart:io';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_converter_adapters/src/source_home_recovery_program.dart';
import 'package:test/test.dart';
import 'support/source_external_original_fixture.dart';
import 'support/native_writer_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  test(
      'automatic home recovery preserves ordered native party heal and clears the source recovery switch',
      () async {
    final output = Platform.environment['AVELUNE_HOME_RECOVERY_PROJECT_OUTPUT'];
    final selected = output == null ? const {1, 2, 7} : const {1, 2, 7, 98};
    final fixture = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: selected,
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((v) => v.isNotEmpty)
                .toList());
    final source = fixture.source;
    final analysis = SourceEventAnalyzer.forProject(source,
            profile: SourceEventProfile.forProject(source))
        .analyze();
    final event = analysis.eventAt(7, 9)!;
    final program = SourceHomeRecoveryProgram.read(
        source: source, analysis: analysis, event: event);
    expect(program, isNotNull,
        reason: {
          'conditions': event.pages.map((p) => p.condition.toJson()).toList(),
          'parameters': event.pages
              .expand((p) => p.sourcePage.commands)
              .where((c) => const {314, 249}.contains(c.code))
              .map((c) => c.toJson())
              .toList(),
          'fresh': sourceFreshEntryProgram(source)?.isBoundTo(source),
          'nodes': event.pages
              .map((page) =>
                  page.body.nodes.map((node) => node.runtimeType).toList())
              .toString()
        }.toString());
    for (final changed in [
      _changedEvent(event, 2, event.pages[2].body.nodes.reversed.toList()),
      _changedEvent(event, 2, [
        for (final node in event.pages[2].body.nodes)
          if (node is SourceSwitchNode)
            SourceSwitchNode(node.span,
                firstId: node.firstId,
                lastId: node.lastId,
                value: true,
                factIds: node.factIds)
          else
            node
      ]),
      _changedEvent(event, 1, [
        for (final node in event.pages[1].body.nodes)
          if (node is! SourceMoveRouteBarrierNode) node
      ]),
    ]) {
      expect(
          SourceHomeRecoveryProgram.read(
              source: source, analysis: analysis, event: changed),
          isNull);
    }
    final temporary =
        await Directory.systemTemp.createTemp('trainer-defeat-conversion-');
    addTearDown(() => temporary.delete(recursive: true));
    final limits = sourceCatalogStudyWriteLimitsFor(selected.length,
        includeNativeCatalog: output != null);
    Future<LiteralTileComposition> literal(
            List<LiteralDependencyDecision> decisions) =>
        const LiteralTileComposer().compose(
            source: source,
            files: fixture.files,
            selectedSourceMapIds: selected.toList(),
            projectName: 'Trainer recovery',
            parentPath: temporary.path,
            folderName: 'native',
            dependencyDecisions: decisions,
            limits: limits);
    final probe = await literal([]);
    final base = await literal([
      for (final dependency in probe.dependencies)
        if (!selected.contains(dependency.targetSourceMapId))
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
    final row = rows
        .singleWhere((row) => row['sourceIdentity'] == event.identity.value);
    expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
    expect((row['nativeHomeRecovery'] as Map)['diagnostic'],
        'sourceStoredPokemonHealingUnsupported');
    final scenes = events.projection.scenes
        .where((scene) =>
            scene.metadata['sourceEventIdentity'] == event.identity.value)
        .toList();
    expect(scenes, hasLength(3));
    final recovery =
        scenes.singleWhere((scene) => scene.metadata['sourcePageIndex'] == '2');
    expect(
        recovery.graph.nodes
            .map((node) => node.payload)
            .whereType<SceneActionPayload>()
            .map((payload) => payload.consequence)
            .whereType<SceneHealPartyConsequence>(),
        hasLength(1));
    final clear = recovery.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .map((payload) => payload.consequence)
        .whereType<SceneSetFactConsequence>()
        .single;
    expect(clear.value, isFalse);
    expect(
        clear.factId,
        sourceEventFactBindingId(
            'source:${source.snapshot.logicalProjectNamespace.value}:switch:1'));
    expect(program!.waitTicksByPage, {1: 60, 2: 58});
    final media = events.draft.mutations.where((m) =>
        m.actionId == 'scene.dialogue.audioMedia.import' &&
        m.parameters['label'] == program.musicName);
    expect(media, isNotEmpty);
    if (output != null) {
      expect(events.freshEntry, isNotNull);
      final trainerScene = events.projection.scenes.singleWhere((scene) =>
          scene.metadata['sourceEventIdentity'] ==
              source.eventIdentity(98, 1).value &&
          scene.metadata['sourcePageIndex'] == '0');
      expect(
          trainerScene.graph.nodes
              .map((node) => node.payload)
              .whereType<SceneBattlePayload>()
              .single
              .defeatRecovery,
          SceneBattleDefeatRecovery.returnToRecoveryPoint);
      final catalogs = (await SourceCatalogStudyComposer(
              nativeTrainerCatalog: NativePsdkCatalogManifest.builtin(),
              nativeTrainerQualification: events.trainerQualification,
              automaticNativeEncounters: false)
          .compose(
              source: source,
              base: events.draft,
              files: fixture.files,
              limits: limits))!;
      final approval = approveNativeFixtureDraft(catalogs.draft);
      final receipt = await NativeProjectWriter().write(
          approval.plan, approval.context, catalogs.draft,
          limits: limits);
      expect(receipt.verified, isTrue);
      expect(await Directory(output).exists(), isFalse);
      await Directory(receipt.projectPath).rename(output);
      await File('$output.receipt.json').writeAsString(jsonEncode({
        'strictNativeWriter': true,
        'sourceMapIds': selected.toList(),
        'sourceTrainerSceneId': trainerScene.id,
        'sourceTrainerIdentity': source.eventIdentity(98, 1).value,
        'nativeHomeRecoverySceneId': recovery.id,
        'homeProgram': program.toJson(),
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'masterModified': false
      }));
    }
    if (Platform.environment['AVELUNE_HOME_RECOVERY_RECEIPT']
        case final path?) {
      await File(path).writeAsString(jsonEncode({
        'sourceSnapshotHash': source.snapshot.canonicalHash.value,
        'program': program.toJson(),
        'row': row,
        'scenes': scenes.map((scene) => scene.toJson()).toList(),
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'nativePlayerDefeatJourneyQualified': false
      }));
    }
  },
      skip: root == null ||
          snapshot == null ||
          Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'] == null,
      timeout: const Timeout(Duration(minutes: 10)));
}

SourceEventDefinition _changedEvent(
        SourceEventDefinition event, int index, List<SourceEventNode> nodes) =>
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
            if (page.originalPageIndex == index)
              SourceEventPageAnalysis(
                  sourcePage: page.sourcePage,
                  locator: page.locator,
                  condition: page.condition,
                  graphic: page.graphic,
                  body: SourceEventBlock(nodes: nodes, span: page.body.span),
                  rawDataRef: page.rawDataRef,
                  diagnostics: page.diagnostics)
            else
              page
        ]);
