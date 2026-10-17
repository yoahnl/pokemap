import 'dart:io';
import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_sound_binding.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';
import 'support/native_writer_fixture.dart';

Object? _raw(MarshalDocument document, int id) {
  final node = document.node(id);
  return switch (node.kind) {
    MarshalKind.nil => null,
    MarshalKind.integer => node.integerValue!.toInt(),
    MarshalKind.boolean => node.booleanValue,
    MarshalKind.string => node.text().text,
    MarshalKind.symbol => node.name,
    MarshalKind.array => node.elements.map((id) => _raw(document, id)).toList(),
    MarshalKind.object => {
        'class': node.className,
        for (final pair in node.instanceVariables)
          document.node(pair.key).name!: _raw(document, pair.value)
      },
    MarshalKind.userDefined => {
        'class': node.className,
        'payload': base64Encode(node.bytes!)
      },
    _ => throw StateError('Unexpected raw source kind ${node.kind}'),
  };
}

Map<String, dynamic> _rawEvent(
    NormalizedSourceProject source, int mapId, int eventId) {
  final ir = source.maps.singleWhere((ir) => ir.map.sourceMapId == mapId);
  final document = source.archive.files[ir.map.sourceFileId]!.document;
  final root = document.node(document.rootId);
  final events = document.node(root.instanceVariables
      .singleWhere((pair) => document.node(pair.key).name == '@events')
      .value);
  final id = events.pairs
      .singleWhere((pair) =>
          document.node(pair.key).integerValue == BigInt.from(eventId))
      .value;
  return Map<String, dynamic>.from(_raw(document, id) as Map);
}

SourceEventDefinition _copyEvent(SourceEventDefinition event,
        {int? eventId, List<SourceEventPageAnalysis>? pages}) =>
    SourceEventDefinition(
        sourceMapId: event.sourceMapId,
        sourceEventId: eventId ?? event.sourceEventId,
        sourceFileId: event.sourceFileId,
        identity: event.identity,
        name: event.name,
        x: event.x,
        y: event.y,
        locator: event.locator,
        pages: pages ?? event.pages);

SourceEventDefinition _changeCommands(NormalizedSourceProject source,
    SourceEventDefinition event, void Function(List<dynamic>) mutate) {
  final ir =
      source.maps.singleWhere((ir) => ir.map.sourceMapId == event.sourceMapId);
  final json = jsonDecode(jsonEncode(ir.toJson())) as Map<String, dynamic>;
  final sourceEvent = (json['map']['events'] as List).cast<Map>().singleWhere(
      (candidate) => candidate['sourceEventId'] == event.sourceEventId);
  mutate(sourceEvent['pages'][0]['commands'] as List<dynamic>);
  for (final (index, command)
      in (sourceEvent['pages'][0]['commands'] as List).indexed) {
    command['originalIndex'] = index;
    command['sourceLocator']['commandIndex'] = index;
  }
  final changed = SourceMapIr.fromJson(json).map.events.singleWhere(
      (candidate) => candidate.sourceEventId == event.sourceEventId);
  final page = event.pages.first;
  return _copyEvent(event, pages: [
    SourceEventPageAnalysis(
        sourcePage: changed.pages.first,
        locator: page.locator,
        condition: page.condition,
        graphic: page.graphic,
        body: page.body,
        rawDataRef: page.rawDataRef,
        diagnostics: page.diagnostics),
    ...event.pages.skip(1)
  ]);
}

Future<
        ({
          SceneRuntimeExecutionResult result,
          List<SceneConsequence> consequences,
          List<SceneInteractiveCommand> commands
        })>
    _execute(SceneAsset scene,
        {bool onAnchor = false,
        bool cancelWarp = false,
        bool blockWarp = false}) async {
  final consequences = <SceneConsequence>[];
  final commands = <SceneInteractiveCommand>[];
  final plan = buildSceneRuntimePlan(scene);
  expect(plan.canBuild, true);
  final result = await SceneRuntimeExecutor(
      callbacks: SceneRuntimeExecutionCallbacks(
          evaluateCondition: (_) => onAnchor ? 'true' : 'false',
          showDialogue: (_) => throw StateError('Unexpected dialogue'),
          startBattle: (_) => throw StateError('Unexpected battle'),
          playCinematic: (_) => throw StateError('Unexpected cinematic'),
          applyConsequence: (consequence) {
            consequences.add(consequence);
            return 'completed';
          },
          executeInteractiveCommand: (intent) {
            if (cancelWarp &&
                intent.interactiveCommand is SceneWarpInteractiveCommand) {
              throw StateError('Cancelled warp');
            }
            commands.add(intent.interactiveCommand!);
            if (blockWarp &&
                intent.interactiveCommand is SceneWarpInteractiveCommand) {
              return 'blocked';
            }
            return 'completed';
          })).execute(plan.plan!);
  return (result: result, consequences: consequences, commands: commands);
}

void main() {
  final root = Platform.environment['AVELUNE_WARP_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_WARP_SOURCE_SNAPSHOT'];
  group('bounded native warp tiles', () {
    late NormalizedSourceProject source;
    late SourceEventAnalysis analysis;
    late Map<int, MapData> maps;
    MapInstanceRetentionPolicy? retention;
    late SourceFilePort files;
    late SourceEventProjection projection;
    final sounds = <String, SourceEventSoundBinding>{};
    setUpAll(() async {
      final fixture = await readExternalOriginalSource(root!, snapshot!,
          selectedMapIds: {57, ...List.generate(10, (index) => 214 + index)},
          supplementalRoots:
              (Platform.environment['AVELUNE_WARP_SUPPLEMENTAL_ROOTS'] ?? '')
                  .split('|')
                  .where((value) => value.isNotEmpty)
                  .toList());
      source = fixture.source;
      files = fixture.files;
      if (Platform.environment['AVELUNE_WARP_EVIDENCE_ROOT']
          case final evidenceRoot?) {
        await File('$evidenceRoot/normalized-map-hashes.json')
            .writeAsString(jsonEncode({
          for (final ir in source.maps)
            '${ir.map.sourceMapId}': canonicalHashOf(ir.toJson()).value
        }));
      }
      final full = SourceEventAnalyzer.forProject(source,
              profile: SourceEventProfile.kantoForProject(source))
          .analyze();
      if (Platform.environment['AVELUNE_WARP_EVIDENCE_ROOT']
          case final evidenceRoot?) {
        await File('$evidenceRoot/excluded-64th-source.json')
            .writeAsString(jsonEncode({
          'sourceMapId': 217,
          'sourceEventId': 39,
          'pages': full
              .eventAt(217, 39)!
              .pages
              .map((page) => page.sourcePage.toJson())
              .toList(),
        }));
      }
      analysis = SourceEventAnalysis(
          profile: full.profile,
          diagnostics: [],
          events: full.events
              .where((event) => event.name.startsWith('Warp Tile'))
              .toList());
      maps = {
        for (final ir in source.maps)
          ir.map.sourceMapId: MapData(
              id: 'native_${ir.map.sourceMapId}',
              name: ir.map.name,
              size: GridSize(width: ir.map.width, height: ir.map.height),
              layers: [])
      };
      retention = await sourceEventMapRetentionPolicy(
          source: source,
          files: fixture.files,
          nativeMapIds: {
            for (final entry in maps.entries) entry.key: entry.value.id
          });
      for (final name in ['frlg_teleport_to', 'frlg_teleport_from']) {
        sounds[name] = await const SourceEventSoundResolver()
            .read(source: source, files: files, name: name);
      }
      projection = const SourceEventProjector().project(
          source: source,
          analysis: analysis,
          nativeMaps: maps,
          retentionPolicy: retention,
          soundBindings: sounds,
          limits: const NativeWriteLimits(maxMutations: 16384));
    });
    test('adapts complete native programs while retaining armed arrival pages',
        () {
      final evidence =
          (projection.semanticEvidence['events'] as List).cast<Map>();
      final event = analysis.eventAt(57, 92)!;
      final result = evidence
          .singleWhere((row) => row['sourceIdentity'] == event.identity.value);
      expect(result['status'], 'adaptedStaticSemantics');
      expect(
          projection.scenes.where((scene) =>
              scene.metadata['sourceEventIdentity'] == event.identity.value),
          hasLength(2));
      final programs =
          sourceWarpTileNativePrograms(source: source, analysis: analysis);
      expect(programs.programs.values.where((program) => !program.isActivation),
          hasLength(64));
      expect(programs.programs.values.where((program) => program.repairsTarget),
          hasLength(10));
      expect(programs.refusals, isEmpty);
      expect(programs.programs.values.where((program) => program.isActivation),
          hasLength(201));
      expect(
          projection.facts
              .where((fact) => fact.valueKind == NarrativeValueKind.integer),
          hasLength(3));
      expect(
          projection.artifacts.single.bytes.length, lessThanOrEqualTo(1048576));
      if (Platform.environment['AVELUNE_WARP_EVIDENCE_ROOT']
          case final evidenceRoot?) {
        File('$evidenceRoot/projected-programs.json')
            .writeAsStringSync(jsonEncode({
          'policy': sourceWarpTileNativePolicyEvidence,
          'programs': programs.programs.values
              .map((program) => program.toJson())
              .toList(),
          'refusals': {
            for (final entry in programs.refusals.entries)
              entry.key.value: entry.value
          },
          'evidenceArtifactBytes': projection.artifacts.single.bytes.length,
          'scenes': projection.scenes.length,
          'sourceAudioBindings': {
            for (final entry in sounds.entries) entry.key: entry.value.evidence
          },
          'nativeAudio': (projection.semanticEvidence['events'] as List)
              .cast<Map>()
              .where((row) =>
                  row['nativeWarpTile'] is Map &&
                  (row['nativeWarpTile'] as Map)['audio'] != null)
              .map((row) => {
                    'identity': row['sourceIdentity'],
                    'audio': (row['nativeWarpTile'] as Map)['audio']
                  })
              .toList(),
        }));
      }
    });
    test('the complete 64th variant only repeats the graphical selection block',
        () {
      final standard = _rawEvent(source, 57, 92);
      final variant = _rawEvent(source, 217, 39);
      final standardPages = standard['@pages'] as List;
      final variantPages = variant['@pages'] as List;
      expect(
          canonicalJsonOf(variantPages[1]), canonicalJsonOf(standardPages[1]));
      final departure = Map<String, dynamic>.from(variantPages[0] as Map);
      final commands = List<dynamic>.from(departure['@list'] as List);
      expect(canonicalJsonOf(commands.sublist(3, 6)),
          canonicalJsonOf(commands.sublist(6, 9)));
      commands.removeRange(6, 9);
      departure['@list'] = commands;
      final normalizedStandard =
          jsonDecode(jsonEncode(standardPages[0])) as Map;
      for (final page in [normalizedStandard, departure]) {
        for (final command in page['@list'] as List) {
          if (command['@code'] == 201) {
            command['@parameters'] = [0, 'boundDestination'];
          }
        }
      }
      expect(canonicalJsonOf(departure), canonicalJsonOf(normalizedStandard));
      if (Platform.environment['AVELUNE_WARP_EVIDENCE_ROOT']
          case final evidenceRoot?) {
        File('$evidenceRoot/64th-raw-variant-proof.json')
            .writeAsStringSync(jsonEncode({
          'sourceMapId': 217,
          'sourceEventId': 39,
          'rawPagesCompared': 2,
          'onlyExtraCommands': [6, 7, 8],
          'extraCodes': [355, 655, 655],
          'normalizedDepartureHash': canonicalHashOf(departure).value,
          'arrivalHash': canonicalHashOf(variantPages[1]).value,
          'sourceFileHash': source
              .archive
              .files[source.maps
                  .singleWhere((ir) => ir.map.sourceMapId == 217)
                  .map
                  .sourceFileId]!
              .contentHash
              .value,
          'persistentStateDifference': false,
          'sourceScriptsExecuted': 0,
        }));
      }
    });
    for (final pair in [(57, 92), (215, 34)]) {
      test(
          'departure ${pair.$1}:${pair.$2} commits shared variables only after successful native warp',
          () async {
        final event = analysis.eventAt(pair.$1, pair.$2)!;
        final scene = projection.scenes.singleWhere((scene) =>
            scene.metadata['sourceEventIdentity'] == event.identity.value &&
            scene.metadata['sourcePageIndex'] == '0');
        final execution = await _execute(scene);
        expect(execution.result.status, SceneRuntimeExecutionStatus.completed);
        expect(execution.consequences.map((value) => value.toJson()['value']),
            [event.sourceMapId, event.x, event.y]);
        expect(execution.commands, hasLength(2));
        expect(execution.commands.last, isA<SceneWarpInteractiveCommand>());
        expect(execution.commands.first.toJson()['volume'], 0.432);
        final cancelled = await _execute(scene, cancelWarp: true);
        expect(cancelled.result.status, SceneRuntimeExecutionStatus.failed);
        expect(cancelled.consequences, isEmpty);
        expect(cancelled.commands.whereType<SceneWarpInteractiveCommand>(),
            isEmpty);
        final blocked = await _execute(scene, blockWarp: true);
        expect(blocked.result.status, SceneRuntimeExecutionStatus.completed);
        expect(blocked.consequences, isEmpty);
      });
      for (final onAnchor in [false, true]) {
        test(
            'arrival ${pair.$1}:${pair.$2} onAnchor=$onAnchor preserves unconditional cleanup',
            () async {
          final event = analysis.eventAt(pair.$1, pair.$2)!;
          final scene = projection.scenes.singleWhere((scene) =>
              scene.metadata['sourceEventIdentity'] == event.identity.value &&
              scene.metadata['sourcePageIndex'] == '1');
          final execution = await _execute(scene, onAnchor: onAnchor);
          expect(
              execution.result.status, SceneRuntimeExecutionStatus.completed);
          expect(
              execution.consequences.map((value) => value.toJson()['value']),
              onAnchor
                  ? [event.sourceMapId, event.x, event.y - 6, false, true]
                  : [false, true]);
          expect(execution.consequences.last,
              isA<SceneSetMapEventInstanceBooleanConsequence>());
          expect(execution.commands, hasLength(onAnchor ? 1 : 0));
        });
      }
    }
    test('missing or unqualified source audio refuses every warp and activator',
        () async {
      final nativeAudio = await const SourceEventSoundResolver().read(
          source: source,
          files: files,
          name: 'frlg_teleport_to',
          policy: SourceEventSoundPolicy.nativeAuthoredVolume);
      final cases = <Map<String, SourceEventSoundBinding>>[
        {},
        for (final omitted in sounds.keys) {...sounds}..remove(omitted),
        {...sounds, 'frlg_teleport_to': nativeAudio},
      ];
      for (final bindings in cases) {
        final refused = const SourceEventProjector().project(
            source: source,
            analysis: analysis,
            nativeMaps: maps,
            retentionPolicy: retention,
            soundBindings: bindings,
            limits: const NativeWriteLimits(maxMutations: 16384));
        expect(refused.scenes, isEmpty);
        expect(refused.semanticEvidence['qualifiedEventCount'], 0);
        expect(
            (refused.semanticEvidence['events'] as List).cast<Map>().every(
                (row) => (row['gaps'] as List).contains(
                    'sourceWarpTileAudioBindingMissingOrUnsupported')),
            true);
      }
    });
    test('unsupported source sound pitch cannot reuse an exact whole program',
        () {
      final original = analysis.eventAt(57, 92)!;
      final page = original.pages.first;
      var changedSounds = 0;
      final changed = _copyEvent(original, pages: [
        SourceEventPageAnalysis(
            sourcePage: page.sourcePage,
            locator: page.locator,
            condition: page.condition,
            graphic: page.graphic,
            rawDataRef: page.rawDataRef,
            diagnostics: page.diagnostics,
            body: SourceEventBlock(
                span: page.body.span,
                diagnostics: page.body.diagnostics,
                nodes: [
                  for (final node in page.body.nodes)
                    if (node is SourceSoundEffectNode) ...[
                      SourceSoundEffectNode(node.span,
                          name: node.name,
                          volume: node.volume,
                          pitch: 101 + changedSounds++,
                          rawDataRef: node.rawDataRef,
                          profileHash: node.profileHash)
                    ] else
                      node
                ])),
        ...original.pages.skip(1),
      ]);
      expect(changedSounds, 1);
      final changedAnalysis = SourceEventAnalysis(
          profile: analysis.profile,
          diagnostics: [],
          events: [
            for (final event in analysis.events)
              event.identity == original.identity ? changed : event
          ]);
      expect(
          sourceWarpTileNativePrograms(
                  source: source, analysis: changedAnalysis)
              .programs,
          isEmpty);
      final refused = const SourceEventProjector().project(
          source: source,
          analysis: changedAnalysis,
          nativeMaps: maps,
          retentionPolicy: retention,
          soundBindings: sounds,
          limits: const NativeWriteLimits(maxMutations: 16384));
      expect(refused.scenes, isEmpty);
    });
    for (final scenario in [
      'missingActivator',
      'wrongEventId',
      'extra209',
      'extra509',
      'missingTerminator',
      'intruder'
    ]) {
      test('$scenario refuses complete source programs', () {
        final original = analysis.eventAt(57, 92)!;
        final changed = switch (scenario) {
          'wrongEventId' => _copyEvent(original, eventId: 999),
          'extra209' ||
          'extra509' =>
            _changeCommands(source, original, (commands) {
              final inserted =
                  jsonDecode(jsonEncode(commands[0])) as Map<String, dynamic>;
              inserted['code'] = scenario == 'extra209' ? 209 : 509;
              commands.insert(1, inserted);
            }),
          'missingTerminator' => _changeCommands(
              source, original, (commands) => commands.removeLast()),
          _ => original,
        };
        final selected = SourceEventAnalysis(
            profile: analysis.profile,
            diagnostics: [],
            events: [
              for (final event in analysis.events)
                if (!(scenario == 'missingActivator' &&
                    event.sourceMapId == 57 &&
                    event.sourceEventId == 18))
                  event.identity == original.identity ? changed : event,
              if (scenario == 'intruder') _copyEvent(original, eventId: 999),
            ]);
        expect(
            sourceWarpTileNativePrograms(source: source, analysis: selected)
                .programs,
            isEmpty);
      });
    }
    for (final journey in [
      (
        <int>{57, ...List.generate(10, (index) => 214 + index)},
        [(57, 92), (57, 96), (215, 34), (221, 12), (221, 26), (217, 39)]
      )
    ]) {
      test('real composer writer and strict reopen ${journey.$1}', () async {
        final temporary =
            await Directory.systemTemp.createTemp('warp-native-writer-');
        addTearDown(() => temporary.delete(recursive: true));
        const limits =
            NativeWriteLimits(maxArtifacts: 512, maxMutations: 16384);
        Future<LiteralTileComposition> literal(
                List<LiteralDependencyDecision> decisions) =>
            const LiteralTileComposer().compose(
                source: source,
                files: files,
                selectedSourceMapIds: journey.$1.toList()..sort(),
                projectName: 'Native warp tiles',
                parentPath: temporary.path,
                folderName: 'native-warps',
                dependencyDecisions: decisions,
                limits: limits);
        final probe = await literal([]);
        final composed = await literal([
          for (final dependency in probe.dependencies)
            if (!journey.$1.contains(dependency.targetSourceMapId))
              LiteralDependencyDecision(
                  sourceSnapshotHash: source.snapshot.canonicalHash,
                  selectionHash: probe.selectionHash,
                  locator: dependency.locator,
                  targetSourceMapId: dependency.targetSourceMapId,
                  decision: LiteralDependencyDisposition.excludeStudy)
        ]);
        expect(composed.draft, isNotNull,
            reason: composed.diagnostics.toString());
        final semantic = await const SourceSemanticStudyComposer().compose(
            source: source, base: composed, files: files, limits: limits);
        final events = await const SourceEventStudyComposer().compose(
            source: source, base: semantic!, files: files, limits: limits);
        expect(events, isNotNull);
        for (final pair in journey.$2) {
          final event = analysis.eventAt(pair.$1, pair.$2)!;
          expect(
              events!.projection.scenes.where((scene) =>
                  scene.metadata['sourceEventIdentity'] ==
                  event.identity.value),
              hasLength(2));
        }
        final forgedEvidence =
            jsonDecode(jsonEncode(events!.draft.compositionEvidence))
                as Map<String, dynamic>;
        final sourceEvents =
            forgedEvidence['sourceEvents'] as Map<String, dynamic>;
        final forgedProjection =
            sourceEvents['projection'] as Map<String, dynamic>;
        final forgedPolicy =
            forgedProjection['warpTileNativePolicy'] as Map<String, dynamic>;
        forgedPolicy['nativeFadeOutMs'] = 301;
        final forgedDraft = NativeProjectDraft(
            source: events.draft.source,
            projectName: events.draft.projectName,
            parentPath: events.draft.parentPath,
            folderName: events.draft.folderName,
            sourceRootPath: events.draft.sourceRootPath,
            mapIds: events.draft.mapIds,
            artifacts: events.draft.artifacts,
            sourceArtifacts: events.draft.sourceArtifacts,
            mutations: events.draft.mutations,
            compositionEvidence: forgedEvidence,
            defaultMapWidth: events.draft.defaultMapWidth,
            defaultMapHeight: events.draft.defaultMapHeight,
            limits: limits);
        final forgedApproval = approveNativeFixtureDraft(forgedDraft);
        final forgedStages = <NativeWriteStage>[];
        await expectLater(
            NativeProjectWriter(
                    checkpoint: (stage, _, __) => forgedStages.add(stage))
                .write(forgedApproval.plan, forgedApproval.context, forgedDraft,
                    limits: limits),
            throwsA(isA<NativeWriteException>().having((error) => error.code,
                'code', 'native.semantics.regeneration')));
        expect(forgedStages, isEmpty);
        final approval = approveNativeFixtureDraft(events.draft);
        final snapshotProfiles = <ProjectSnapshotLoadProfile>[];
        final writerWatch = Stopwatch()..start();
        final receipt =
            await NativeProjectWriter(snapshotProfileSink: snapshotProfiles.add)
                .write(approval.plan, approval.context, events.draft,
                    limits: limits);
        writerWatch.stop();
        expect(receipt.verified, true);
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
          expect(
              loaded.manifest.facts.where(
                  (fact) => fact.valueKind == NarrativeValueKind.integer),
              hasLength(3));
          expect(loaded.manifest.scenes, containsAll(events.projection.scenes));
          if (Platform.environment['AVELUNE_WARP_EVIDENCE_ROOT']
              case final evidenceRoot?) {
            await File('$evidenceRoot/writer-${journey.$1.join('-')}.json')
                .writeAsString(jsonEncode({
              'verified': receipt.verified,
              'maps': journey.$1.toList(),
              'strictLoadDiagnostics': loaded.loadDiagnostics.length,
              'sceneCount': loaded.manifest.scenes.length,
              'factCount': loaded.manifest.facts.length,
              'writerElapsedMilliseconds': writerWatch.elapsedMilliseconds,
              'snapshotLoadProfileSummary': {
                'loads': snapshotProfiles.length,
                'cacheHits': snapshotProfiles
                    .where((profile) => profile.cacheHit)
                    .length,
                'initialReadMicrosecondsSum': snapshotProfiles.fold<int>(
                    0, (sum, profile) => sum + profile.initialReadMicroseconds),
                'decodeModelMicrosecondsSum': snapshotProfiles.fold<int>(
                    0, (sum, profile) => sum + profile.decodeModelMicroseconds),
                'secondObservationMicrosecondsSum': snapshotProfiles.fold<int>(
                    0,
                    (sum, profile) =>
                        sum + profile.secondObservationMicroseconds),
                'fingerprintMicrosecondsSum': snapshotProfiles.fold<int>(
                    0, (sum, profile) => sum + profile.fingerprintMicroseconds),
                'projectionMicrosecondsSum': snapshotProfiles.fold<int>(
                    0, (sum, profile) => sum + profile.projectionMicroseconds),
                'totalMicrosecondsSum': snapshotProfiles.fold<int>(
                    0, (sum, profile) => sum + profile.totalMicroseconds),
                'resourceCountSum': snapshotProfiles.fold<int>(
                    0, (sum, profile) => sum + profile.resourceCount),
                'resourceBytesSum': snapshotProfiles.fold<int>(
                    0, (sum, profile) => sum + profile.resourceBytes),
                'assetBlobVerificationsSum': snapshotProfiles.fold<int>(
                    0, (sum, profile) => sum + profile.assetBlobVerifications),
                'revisionHashedBytesSum': snapshotProfiles.fold<int>(
                    0, (sum, profile) => sum + profile.revisionHashedBytes),
              },
              'compositionEvidenceHash':
                  canonicalHashOf(events.draft.compositionEvidence).value,
              'warpTilePolicy':
                  events.projection.semanticEvidence['warpTileNativePolicy'],
            }));
          }
        } finally {
          opener.closeWorkspace(opened.workspaceHandle);
        }
      }, timeout: const Timeout(Duration(minutes: 40)), tags: ['writer']);
    }
  },
      skip: root == null || snapshot == null
          ? 'Original complete source required.'
          : false);
}
