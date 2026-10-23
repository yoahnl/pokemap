import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:image/image.dart' as image;
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

Future<
        ({
          LiteralTileFixture fixture,
          SourceEventAnalysis analysis,
          SourceEventProjection projection
        })>
    _source(
        {bool common = false,
        int eventId = 1,
        int x = 1,
        String name = 'Original',
        String text = 'Chosen',
        int ticks = 2,
        int pages = 1,
        bool unsafeOwner = false,
        bool unsafeCaller = false,
        int commonId = 7,
        bool reverseAnnotations = false,
        bool playerMetadata = false,
        SourceEventAnalysis Function(SourceEventAnalysis)? transform}) async {
  final body = <LiteralFixtureEventCommand>[
    for (final label
        in reverseAnnotations ? ['Second', 'First'] : ['First', 'Second'])
      LiteralFixtureEventCommand(108, [label]),
    const LiteralFixtureEventCommand(121, [1, 1, 0]),
    const LiteralFixtureEventCommand(111, [0, 1, 0]),
    const LiteralFixtureEventCommand(
        102,
        [
          ['Accept', 'Decline'],
          0
        ],
        indent: 1),
    const LiteralFixtureEventCommand(402, [0, 'Accept'], indent: 1),
    LiteralFixtureEventCommand(101, [text], indent: 2),
    LiteralFixtureEventCommand(106, [ticks], indent: 2),
    const LiteralFixtureEventCommand(201, [0, 2, 0, 0, 0, 1], indent: 2),
    if (unsafeOwner) const LiteralFixtureEventCommand(123, ['A', 0], indent: 2),
    const LiteralFixtureEventCommand(402, [1, 'Decline'], indent: 1),
    const LiteralFixtureEventCommand(101, ['Declined'], indent: 2),
    const LiteralFixtureEventCommand(404, [], indent: 1),
    const LiteralFixtureEventCommand(412, []),
    const LiteralFixtureEventCommand(115, []),
    const LiteralFixtureEventCommand(101, ['Unreachable']),
  ];
  final fixture = await LiteralTileFixture.create(
      interpretationProfile: syntheticSourceInterpretationProfile,
      scriptsBytes: syntheticInterpretationArchive,
      includeEventSystem: true,
      switchNames: const [null, 'Gate'],
      extraFiles: {
        if (playerMetadata) ...{
          'PBS/metadata.txt':
              utf8.encode('[1]\nWalkCharset = OriginalPlayer\n'),
          'Graphics/Characters/OriginalPlayer.png': image
              .encodePng(image.Image(width: 128, height: 192, numChannels: 4)),
          'Data/map_connections.dat': literalFixtureMarshal([]),
        }
      },
      commonEvents: common ? {commonId: body} : const {},
      maps: [
        LiteralFixtureMap(id: 1, events: [
          LiteralFixtureEvent(id: eventId, x: x, y: 0, name: name, pages: [
            for (var i = 0; i < pages; i++)
              LiteralFixtureEventPage(
                  globalSwitch: i == 0 ? null : 1,
                  commands: common
                      ? [
                          LiteralFixtureEventCommand(117, [commonId]),
                          if (unsafeCaller)
                            const LiteralFixtureEventCommand(123, ['A', 0]),
                          const LiteralFixtureEventCommand(
                              101, ['Caller resumed'])
                        ]
                      : body),
          ]),
        ]),
        LiteralFixtureMap(id: 2)
      ]);
  final original = SourceEventAnalyzer.forProject(fixture.source,
          profile: SourceEventProfile.forProject(fixture.source))
      .analyze();
  final analysis = transform?.call(original) ?? original;
  final projection = const SourceEventProjector()
      .project(source: fixture.source, analysis: analysis, nativeMaps: {
    for (final id in [1, 2])
      id: MapData(
          id: 'map-$id',
          name: 'Map $id',
          size: const GridSize(width: 3, height: 1),
          layers: []),
  });
  return (fixture: fixture, analysis: analysis, projection: projection);
}

Future<List<String>> _run(SourceEventProjection projection,
    {String choice = 'choice_0'}) async {
  var state = const GameState(saveId: 'composition');
  final resolver = NarrativeFactRuntimeResolver.fromFacts(projection.facts);
  final writer = NarrativeFactRuntimeWriter(resolver);
  final trace = <String>[];
  final plan = buildSceneRuntimePlan(SceneAsset.fromJson(
      jsonDecode(jsonEncode(projection.scenes.first.toJson()))
          as Map<String, dynamic>));
  expect(plan.plan, isNotNull);
  final result = await SceneRuntimeExecutor(
      callbacks: SceneRuntimeExecutionCallbacks(
    evaluateCondition: (intent) {
      final condition = intent.conditionSource!;
      final resolved = resolver.resolve(
          factId: condition.sourceId,
          runtimeState: state.narrativeFactRuntimeState,
          storyFlags: state.storyFlags) as NarrativeFactRuntimeResolved;
      return resolved.narrativeValue.matches(condition.resolvedFactOperator,
              condition.resolvedExpectedFactValue)
          ? 'true'
          : 'false';
    },
    showDialogue: (intent) {
      final document = const YarnDialogueCompiler()
          .compile(projection.dialogueSources[intent.dialogueId]!);
      trace.addAll(document.nodes.single.steps
          .whereType<RuntimeDialogueLine>()
          .map((line) => line.text));
      return intent.declaredOutputPortIds.contains(choice)
          ? choice
          : 'completed';
    },
    applyConsequence: (consequence) {
      final set = consequence as SceneSetFactConsequence;
      state = writer
          .setFactValue(
              gameState: state, factId: set.factId, value: set.narrativeValue)
          .gameState;
      trace.add('effect');
      return 'completed';
    },
    executeInteractiveCommand: (intent) {
      final command = intent.interactiveCommand;
      if (command is SceneWaitInteractiveCommand) {
        trace.add('wait:${command.durationMs}');
      }
      if (command is SceneWarpInteractiveCommand) {
        trace.add('warp:${command.destinationMapId}');
      }
      return 'completed';
    },
    startBattle: (_) => throw StateError('No battle'),
    playCinematic: (_) => throw StateError('No cinematic'),
  )).execute(plan.plan!);
  expect(result.status, SceneRuntimeExecutionStatus.completed);
  return trace;
}

SourceEventBlock _mapNodes(SourceEventBlock block,
    SourceEventNode Function(SourceEventNode) transform) {
  SourceEventBlock visit(SourceEventBlock value) => _mapNodes(value, transform);
  SourceChoiceNode choice(SourceChoiceNode value) =>
      SourceChoiceNode(value.span,
          branches: [
            for (final branch in value.branches)
              SourceChoiceBranch(branch.index, branch.label, visit(branch.body))
          ],
          cancelType: value.cancelType,
          cancellation: value.cancellation,
          cancelBranch:
              value.cancelBranch == null ? null : visit(value.cancelBranch!));
  return SourceEventBlock(
      span: block.span,
      diagnostics: block.diagnostics,
      nodes: [
        for (final node in block.nodes)
          transform(switch (node) {
            SourceCommonEventCallNode() => SourceCommonEventCallNode(node.span,
                commonEventId: node.commonEventId,
                sourceMapId: node.sourceMapId,
                sourceEventId: node.sourceEventId,
                body: visit(node.body)),
            SourceConditionalNode() => SourceConditionalNode(node.span,
                condition: node.condition,
                whenTrue: visit(node.whenTrue),
                whenFalse: visit(node.whenFalse)),
            SourceChoiceNode() => choice(node),
            SourceTextNode() => SourceTextNode(node.span, node.text,
                annotations: node.annotations,
                followingChoice: node.followingChoice == null
                    ? null
                    : choice(node.followingChoice!)),
            _ => node,
          }),
      ]);
}

void main() {
  for (final common in [false, true]) {
    for (final tamper in ['duration', 'profile', 'warp', 'switch']) {
      test(
          'STD03 rejects forged $tamper semantics at their original spans common=$common',
          () async {
        final source = await _source(
            common: common,
            transform: (analysis) {
              final event = analysis.events.single;
              return SourceEventAnalysis(
                  profile: analysis.profile,
                  diagnostics: [],
                  events: [
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
                            SourceEventPageAnalysis(
                                sourcePage: page.sourcePage,
                                locator: page.locator,
                                condition: page.condition,
                                graphic: page.graphic,
                                rawDataRef: page.rawDataRef,
                                diagnostics: [],
                                body: _mapNodes(
                                    page.body,
                                    (node) => switch (node) {
                                          SourceWaitNode()
                                              when tamper == 'duration' ||
                                                  tamper == 'profile' =>
                                            SourceWaitNode(node.span,
                                                durationTicks:
                                                    tamper == 'duration'
                                                        ? 5
                                                        : node.durationTicks,
                                                profileHash: tamper == 'profile'
                                                    ? canonicalHashOf('forged')
                                                    : node.profileHash),
                                          SourceWarpNode()
                                              when tamper == 'warp' =>
                                            SourceWarpNode(node.span,
                                                targetSourceMapId:
                                                    node.targetSourceMapId,
                                                x: 1,
                                                y: node.y,
                                                direction: node.direction,
                                                fade: node.fade),
                                          SourceSwitchNode()
                                              when tamper == 'switch' =>
                                            SourceSwitchNode(node.span,
                                                firstId: node.firstId,
                                                lastId: node.lastId,
                                                value: !node.value,
                                                factIds: node.factIds),
                                          _ => node,
                                        })),
                        ]),
                  ]);
            });
        expect(source.projection.scenes, isEmpty);
        expect(jsonEncode(source.projection.semanticEvidence),
            contains('sourceCompositionSourceMismatch'));
      });
    }
  }

  test(
      'STD03 automatic event composition writes canonically and reopens strictly',
      () async {
    final temporary = await Directory.systemTemp.createTemp('std03-native-');
    addTearDown(() => temporary.delete(recursive: true));
    final original = await _source(common: true, playerMetadata: true);
    final fixture = original.fixture;
    final literal = await const LiteralTileComposer().compose(
        source: fixture.source,
        files: fixture.files,
        selectedSourceMapIds: [1, 2],
        projectName: 'Original composition',
        parentPath: temporary.path,
        folderName: 'native');
    final semantic = await const SourceSemanticStudyComposer()
        .compose(source: fixture.source, base: literal, files: fixture.files);
    expect(semantic, isNotNull);
    final composed = await const SourceEventStudyComposer()
        .compose(source: fixture.source, base: semantic!, files: fixture.files);
    expect(composed, isNotNull);
    expect(composed!.projection.scenes, hasLength(1),
        reason: jsonEncode(composed.projection.semanticEvidence['events']));
    expect(composed.projection.semanticEvidence['compositionContract'],
        isA<Map>());
    final approval = approveNativeFixtureDraft(composed.draft);
    final receipt = await NativeProjectWriter()
        .write(approval.plan, approval.context, composed.draft);
    expect(receipt.verified, isTrue);
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [receipt.stagingRoot], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(receipt.projectPath);
    try {
      final native = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      expect(native.loadDiagnostics, isEmpty);
      final commands = native.manifest.scenes
          .expand((scene) => scene.graph.nodes)
          .map((node) => node.payload)
          .whereType<SceneActionPayload>()
          .map((payload) => payload.interactiveCommand)
          .whereType<SceneInteractiveCommand>()
          .toList();
      expect(
          commands.whereType<SceneWaitInteractiveCommand>().single.durationMs,
          100);
      expect(
          commands
              .whereType<SceneWarpInteractiveCommand>()
              .single
              .destinationMapId,
          composed.draft.mapIds[2]);
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
  });

  for (final common in [false, true]) {
    test(
        'STD03 composes native effects, conditions, choices, wait and transfer common=$common',
        () async {
      final source = await _source(common: common);
      expect(source.projection.scenes, hasLength(1),
          reason: jsonEncode(source.projection.semanticEvidence));
      expect(await _run(source.projection), [
        'effect',
        'Chosen',
        'wait:100',
        'warp:map-2',
        if (common) 'Caller resumed'
      ]);
      expect(await _run(source.projection, choice: 'choice_1'),
          ['effect', 'Declined', if (common) 'Caller resumed']);
      final table =
          source.projection.semanticEvidence['compositionContract'] as Map;
      expect(table['version'], 2);
      expect(table['identityPolicy'], 'engineVersionOnly');
      expect(table['entries'], isNotEmpty);
    });
  }

  test(
      'STD03 composition does not impose page count or names, IDs and coordinates',
      () async {
    final source = await _source(
        common: true,
        pages: 4,
        eventId: 9,
        x: 2,
        name: 'Renamed decoration',
        text: 'Other words',
        ticks: 3);
    expect(source.projection.scenes, hasLength(4),
        reason: jsonEncode(source.projection.semanticEvidence));
    expect(await _run(source.projection),
        ['effect', 'Other words', 'wait:150', 'warp:map-2', 'Caller resumed']);
  });

  test(
      'STD03 names, IDs, coordinates and annotation order preserve the execution trace',
      () async {
    final original = await _source(common: true);
    final varied = await _source(
        common: true,
        commonId: 19,
        eventId: 9,
        x: 2,
        name: 'Different decoration',
        reverseAnnotations: true);
    expect(original.projection.scenes, hasLength(1));
    expect(varied.projection.scenes, hasLength(1));
    expect(await _run(varied.projection), await _run(original.projection));
    final inline = await _source();
    expect(
        await _run(inline.projection),
        (await _run(original.projection))
            .where((entry) => entry != 'Caller resumed')
            .toList());
  });

  test('STD03 a duration change changes observable behavior', () async {
    final original = await _source();
    final changed = await _source(ticks: 3);
    expect(
        await _run(original.projection), isNot(await _run(changed.projection)));
  });

  for (final common in [false, true]) {
    test(
        'STD03 owner-local effects after transfer remain refused common=$common',
        () async {
      final source = await _source(common: common, unsafeOwner: true);
      expect(source.projection.scenes, isEmpty);
      final event = (source.projection.semanticEvidence['events'] as List)
          .cast<Map>()
          .single;
      expect(
          event['gaps'],
          contains(common
              ? 'sourceCommonEventMapContextUnsupported'
              : 'sourceMapLocalContextUnsupported'));
    });
  }

  test(
      'STD03 returning from a transferred common cannot mutate the caller owner',
      () async {
    final source = await _source(common: true, unsafeCaller: true);
    expect(source.projection.scenes, isEmpty);
    final event = (source.projection.semanticEvidence['events'] as List)
        .cast<Map>()
        .single;
    expect(event['gaps'], contains('sourceCommonEventMapContextUnsupported'));
  });

  test(
      'STD03 map-local common continuation after transfer has a causal refusal',
      () async {
    final source = await _source(common: true, unsafeOwner: true);
    expect(source.projection.scenes, isEmpty);
    final event = (source.projection.semanticEvidence['events'] as List)
        .cast<Map>()
        .single;
    final refusals = (event['refusals'] as List).cast<Map>();
    expect(
        refusals,
        contains(predicate<Map>((refusal) =>
            refusal['rootCause'] == 'sourceCommonEventMapContextUnsupported' &&
            refusal['owner'] == 'converter' &&
            (refusal['dependents'] as List)
                .contains(source.analysis.events.single.identity.value))));
  });
}
