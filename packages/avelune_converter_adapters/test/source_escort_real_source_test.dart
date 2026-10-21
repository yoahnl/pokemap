import 'dart:io';
import 'dart:convert';
import 'package:map_core/map_core.dart';
import 'package:avelune_converter_adapters/src/source_event_projection.dart';
import 'package:avelune_converter_adapters/src/literal_tile_composer.dart';
import 'package:avelune_converter_adapters/src/source_catalog_study_composer.dart';
import 'package:avelune_converter_adapters/src/source_semantic_study_composer.dart';
import 'package:avelune_converter_adapters/src/source_event_study_composer.dart';
import 'support/native_writer_fixture.dart';
import 'package:avelune_converter_adapters/src/source_escort_program.dart';
import 'package:avelune_converter_adapters/src/native_project_writer.dart';
import 'package:avelune_converter_adapters/src/source_event_sound_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';
import 'support/source_external_original_fixture.dart';

void main() {
  final root = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final profile = Platform.environment['AVELUNE_CONVERTER_ORACLE_PROFILE'];
  test(
      'original escorts preserve their exact structural source chain without identity rules',
      () async {
    final f = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: {6, 9},
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((s) => s.isNotEmpty)
                .toList());
    final a = SourceEventAnalyzer.forProject(f.source,
            profile: SourceEventProfile.forProject(f.source))
        .analyze();
    final programs = sourceEscortPrograms(source: f.source, analysis: a);
    expect(programs.values.map((p) => p.event.sourceEventId).toSet(), {12, 14},
        reason: a.events
            .where(
                (e) => e.sourceMapId == 6 && [12, 14].contains(e.sourceEventId))
            .map((e) => '${e.sourceEventId}: ${e.pages.map((p) => {
                  'quarantined': p.isQuarantined,
                  'diagnostics': p.diagnostics.map((d) => d.code).toList(),
                  'bodyDiagnostics':
                      p.body.diagnostics.map((d) => d.code).toList(),
                  'nodes': p.body.nodes.map((n) => n.runtimeType).toList()
                }).toList()}')
            .join('\n'));
    for (final p in programs.values) {
      expect(p.isBoundTo(f.source, a, p.event), isTrue);
      expect(p.actorEventId, 13);
      expect(p.doorEventId, 2);
      expect(p.transfer.targetSourceMapId, 9);
      expect((p.transfer.x, p.transfer.y, p.transfer.direction), (8, 14, 8));
      expect(p.music.name, 'FRLG Misc - Prof. Oak (Prof. Oak)');
      expect(p.music.volume, 100);
      final binding = await const SourceEscortBindingResolver()
          .read(source: f.source, analysis: a, program: p, files: f.files);
      expect(binding.isBoundTo(f.source, a, p.event), isTrue);
      expect(binding.music.kind, SourceEventAudioKind.music);
      expect(binding.music.gainForVolume(100), .64);
      expect(binding.player.character.frameHeight, 2);
      expect(
          binding.actorImport.character.frameHeight, greaterThanOrEqualTo(2));
      final missingActor = SourceEventAnalysis(
          profile: a.profile,
          diagnostics: a.diagnostics,
          events: a.events
              .where((e) =>
                  e.sourceMapId != p.event.sourceMapId ||
                  e.sourceEventId != p.actorEventId)
              .toList());
      expect(binding.isBoundTo(f.source, missingActor, p.event), isFalse);
      await expectLater(
          const SourceEscortBindingResolver().read(
              source: f.source,
              analysis: missingActor,
              program: p,
              files: f.files),
          throwsA(isA<NativeWriteException>().having(
              (e) => e.code, 'code', 'events.escort.actor_unqualified')));

      final first = p.event.pages.first;
      final music = p.music;
      final variants = <String, SourceEventBlock>{
        'unknown effect': SourceEventBlock(
            nodes: first.body.nodes,
            span: first.body.span,
            diagnostics: [
              SourceEventDiagnostic('events.script.unsupported', first.locator)
            ]),
        'altered source music': SourceEventBlock(nodes: [
          for (final node in first.body.nodes)
            if (identical(node, music))
              SourceMusicNode(music.span,
                  name: '${music.name} changed',
                  volume: music.volume,
                  pitch: music.pitch,
                  rawDataRef: music.rawDataRef,
                  profileHash: music.profileHash)
            else
              node
        ], span: first.body.span),
        'missing synchronization': SourceEventBlock(nodes: [
          for (final node in first.body.nodes)
            if (node is! SourceMoveRouteBarrierNode) node
        ], span: first.body.span),
      };
      for (final variant in variants.entries) {
        final changedEvent = SourceEventDefinition(
            sourceMapId: p.event.sourceMapId,
            sourceEventId: p.event.sourceEventId,
            sourceFileId: p.event.sourceFileId,
            identity: p.event.identity,
            name: p.event.name,
            x: p.event.x,
            y: p.event.y,
            locator: p.event.locator,
            pages: [
              SourceEventPageAnalysis(
                  sourcePage: first.sourcePage,
                  locator: first.locator,
                  condition: first.condition,
                  graphic: first.graphic,
                  body: variant.value,
                  rawDataRef: first.rawDataRef,
                  diagnostics: first.diagnostics),
              p.event.pages.last
            ]);
        final altered = SourceEventAnalysis(
            profile: a.profile,
            diagnostics: a.diagnostics,
            events: [
              for (final event in a.events)
                if (event.identity == changedEvent.identity)
                  changedEvent
                else
                  event
            ]);
        expect(p.isBoundTo(f.source, altered, changedEvent), isFalse,
            reason: variant.key);
        expect(
            sourceEscortPrograms(source: f.source, analysis: altered)
                .containsKey(changedEvent.identity),
            isFalse,
            reason: variant.key);
      }
      expect(p.nodes.whereType<SourceTextNode>(), hasLength(4));
      final e = p.event;
      final forged = SourceEventDefinition(
          sourceMapId: e.sourceMapId,
          sourceEventId: e.sourceEventId,
          sourceFileId: e.sourceFileId,
          identity: e.identity,
          name: e.name,
          x: e.x + 1,
          y: e.y,
          locator: e.locator,
          pages: e.pages);
      expect(p.isBoundTo(f.source, a, forged), isFalse);
      final changed = SourceEventAnalysis(
          profile: a.profile,
          diagnostics: a.diagnostics,
          events: [
            for (final e in a.events)
              if (e.identity == forged.identity) forged else e
          ]);
      expect(
          sourceEscortPrograms(source: f.source, analysis: changed)
              .containsKey(e.identity),
          isFalse);
    }
  },
      timeout: const Timeout(Duration(minutes: 2)),
      skip: root == null || snapshot == null || profile == null
          ? 'Requires original source, exact snapshot and qualified profile.'
          : false);
  test(
      'original escorts survive complete native composition and strict writer replay',
      () async {
    final temporary =
        await Directory.systemTemp.createTemp('original-escort-write-');
    addTearDown(() => temporary.delete(recursive: true));
    const selected = {6, 9};
    final f = await readExternalOriginalSource(root!, snapshot!,
        selectedMapIds: selected,
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((s) => s.isNotEmpty)
                .toList());
    final limits = sourceCatalogStudyWriteLimitsFor(selected.length,
        includeNativeCatalog: true);
    Future<LiteralTileComposition> literal(
            List<LiteralDependencyDecision> decisions) =>
        const LiteralTileComposer().compose(
            source: f.source,
            files: f.files,
            selectedSourceMapIds: selected.toList(),
            projectName: 'Original escort',
            parentPath: temporary.path,
            folderName: 'native',
            dependencyDecisions: decisions,
            limits: limits);
    final probe = await literal([]);
    final base = await literal([
      for (final dependency in probe.dependencies)
        if (!selected.contains(dependency.targetSourceMapId))
          LiteralDependencyDecision(
              sourceSnapshotHash: f.source.snapshot.canonicalHash,
              selectionHash: probe.selectionHash,
              locator: dependency.locator,
              targetSourceMapId: dependency.targetSourceMapId,
              decision: LiteralDependencyDisposition.excludeStudy)
    ]);
    final semantic = (await const SourceSemanticStudyComposer().compose(
        source: f.source, base: base, files: f.files, limits: limits))!;
    final events = (await const SourceEventStudyComposer().compose(
        source: f.source, base: semantic, files: f.files, limits: limits))!;
    final rows =
        (events.projection.semanticEvidence['events'] as List).cast<Map>();
    for (final eventId in [12, 14]) {
      final row = rows.singleWhere((r) =>
          r['locator']['mapId'] == 6 && r['locator']['eventId'] == eventId);
      expect(row['status'], 'adaptedStaticSemantics');
      expect(row['gaps'], isEmpty);
    }
    final preparation = rows.singleWhere(
        (r) => r['locator']['mapId'] == 9 && r['locator']['eventId'] == 8);
    expect(preparation['status'], 'adaptedStaticSemantics',
        reason: '${preparation['gaps']}');
    expect(preparation['gaps'], isEmpty);
    expect(
        preparation['nativeActorPreparation']['nativePresentationAdaptation'],
        'stationaryFrameCycleToNativeIdle');
    final rivalNameId = sourceEventIntegerVariableBindingId(
        'source:ev09-real-source-defects:variable:28');
    final rivalName =
        events.projection.facts.singleWhere((f) => f.id == rivalNameId);
    expect(rivalName.initialValue.kind, NarrativeValueKind.string);
    expect(rivalName.initialValue.stringValue, '');
    expect(events.projection.dialogueSources.values.join('\n'),
        contains(dialogueFactPlaceholder(rivalNameId)));
    expect(events.projection.cinematics, hasLength(2));
    for (final movie in events.projection.cinematics) {
      expect(
          movie.timeline.steps
              .where((s) => s.id == 'player_face' || s.id == 'guide_face')
              .map((s) =>
                  s.metadata[cinematicTimelineActorDirectionMetadataKey]),
          ['down', 'up']);
    }
    final approval = approveNativeFixtureDraft(events.draft);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, events.draft, limits: limits);
    expect(receipt.verified, isTrue);
    expect(await File('${receipt.projectPath}/project.json').exists(), isTrue);
    final output = Platform.environment['AVELUNE_ESCORT_QA_OUTPUT'];
    if (output != null) {
      expect(await Directory(output).exists(), isFalse);
      await Directory(receipt.projectPath).rename(output);
      final artifacts = <Map<String, Object?>>[];
      final artifactRoot =
          await Directory('$output.artifacts').create(recursive: true);
      for (final artifact in events.draft.artifacts) {
        final file = File('${artifactRoot.path}/${artifact.rawSha256.value}');
        await file.writeAsBytes(artifact.bytes);
        artifacts.add({
          'handle': artifact.handle,
          'path': file.path,
          'sha256': artifact.rawSha256.value,
          'reference': artifact.reference.toJson()
        });
      }
      await File('$output.bundle.json').writeAsString(jsonEncode({
        'kind': 'boundedAutomaticEscortComposition',
        'sourceSnapshotHash': f.source.snapshot.canonicalHash.value,
        'maps': {
          for (final e in events.projection.nativeMaps.entries)
            '${e.key}': e.value.toJson()
        },
        'events': events.projection.semanticEvidence['events'],
        'scenes': events.projection.scenes.map((s) => s.toJson()).toList(),
        'cinematics':
            events.projection.cinematics.map((c) => c.toJson()).toList(),
        'facts': events.projection.facts.map((s) => s.toJson()).toList(),
        'registry': events.projection.registry.toJson(),
        'dialogues':
            events.projection.dialogues.map((s) => s.toJson()).toList(),
        'dialogueSources': events.projection.dialogueSources,
        'mutations': [
          for (var i = 0; i < events.draft.mutations.length; i++)
            events.draft.mutations[i].toJson(i)
        ],
        'artifacts': artifacts,
        'scriptsExecuted': 0,
        'aiCalls': 0,
        'strictNativeWriterVerified': receipt.verified
      }));
    }
  },
      timeout: const Timeout(Duration(minutes: 6)),
      skip: root == null ||
          snapshot == null ||
          profile == null ||
          Platform.environment['AVELUNE_ESCORT_STRICT_WRITE'] != '1');
}
