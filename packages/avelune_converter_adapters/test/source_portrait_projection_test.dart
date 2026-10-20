import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/source_portrait_program_test.dart'
    as portrait;
import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import '../../avelune_converter_core/test/support/trainer_program_fixture.dart';
import 'support/literal_tile_fixture.dart';
import 'support/native_writer_fixture.dart';

Object? _literal(Object? value) => switch (value) {
      TrainerRubyObject() => LiteralFixtureObject(value.name, {
          for (final field in value.fields.entries)
            field.key: _literal(field.value)
        }),
      List() => value.map(_literal).toList(),
      _ => value,
    };

Future<
        ({
          LiteralTileFixture fixture,
          SourceEventAnalysis analysis,
          SourcePortraitBinding? binding,
          SourceEventProjection projection
        })>
    _fixture(
        {bool bind = true,
        bool actor = true,
        bool actorQualified = true,
        bool pose = true,
        bool missingUtilities = false,
        bool substitute = false,
        bool wrongSubstitutionHash = false,
        bool unknownMemoryWriter = false,
        int actorMoveType = 0,
        String autorunContext = ''}) async {
  final png =
      image.encodePng(image.Image(width: 128, height: 128, numChannels: 4));
  final pin = syntheticSourceInterpretationProfile.sections.values.first;
  final profile = SourceInterpretationProfile.fromJson({
    ...syntheticSourceInterpretationProfile.toJson(),
    'sections': {
      ...syntheticSourceInterpretationProfile.sections,
      if (!missingUtilities) 'events.Utilities': pin,
      for (final role in ['Messages', 'MessageConfig', 'DrawText'])
        'events.$role': pin
    },
    if (substitute)
      'presentationBindings': {
        'characterSubstitutions': [
          {
            'requestedCharset': 'trainer_SCIENTIST',
            'actualCharset': 'NPC_FRLG_SCIENTIST',
            'targetSha256': wrongSubstitutionHash
                ? List.filled(64, '0').join()
                : literalFixtureHash(png).value,
            'reason':
                'Explicit presentation adaptation for a missing portrait graphic.'
          }
        ]
      },
  });
  final fixture = await LiteralTileFixture.create(
      scriptsBytes: syntheticInterpretationArchive,
      interpretationProfile: profile,
      includeEventSystem: true,
      variableNames: List.generate(40, (i) => 'Variable $i'),
      switchNames:
          List.generate(66, (i) => i == 22 ? 's:tsOff?("A")' : 'Switch $i'),
      extraFiles: {
        'Graphics/Characters/NPC_FRLG_SCIENTIST.png': png,
        'PBS/metadata.txt':
            utf8.encode('[1]\nWalkCharset = NPC_FRLG_SCIENTIST\n'),
        if (pose) 'Graphics/Characters/trainer_SCIENTIST.png': png
      },
      maps: [
        LiteralFixtureMap(id: 61, width: 6, height: 6, layers: [
          List.filled(36, 384),
          List.filled(36, 0),
          List.filled(36, 0)
        ], events: [
          LiteralFixtureEvent(id: 8, x: 1, y: 1, name: 'Fuji portrait', pages: [
            LiteralFixtureEventPage(commands: [
              for (final command in portrait.portraitCommands())
                LiteralFixtureEventCommand(
                    command.fields['@code'] as int,
                    (command.fields['@parameters'] as List)
                        .map(_literal)
                        .toList(),
                    indent: command.fields['@indent'] as int)
            ]),
          ]),
          if (actor)
            LiteralFixtureEvent(id: 9, x: 3, y: 3, name: 'Scientist', pages: [
              LiteralFixtureEventPage(
                  characterName: 'NPC_FRLG_SCIENTIST',
                  moveType: actorMoveType,
                  commands: [
                    if (actorQualified)
                      const LiteralFixtureEventCommand(101, ['A scientist.'])
                    else
                      const LiteralFixtureEventCommand(
                          355, ['unknownUnsafeRuby()']),
                    const LiteralFixtureEventCommand(0, []),
                  ]),
            ]),
          if (autorunContext.isNotEmpty)
            LiteralFixtureEvent(
                id: 31,
                x: autorunContext == 'overlapPc' ? 2 : 0,
                y: autorunContext == 'overlapPc' ? 1 : 4,
                name: 'Context',
                pages: autorunContext == 'door' ||
                        autorunContext == 'unsafeDoor'
                    ? _doorPages(unsafe: autorunContext == 'unsafeDoor')
                    : [
                        const LiteralFixtureEventPage(commands: [
                          LiteralFixtureEventCommand(123, ['A', 0]),
                          LiteralFixtureEventCommand(0, []),
                        ]),
                        LiteralFixtureEventPage(
                            selfSwitch: 'A',
                            trigger: autorunContext == 'parallelPc' ? 4 : 3,
                            commands: [
                              const LiteralFixtureEventCommand(
                                  355, ['pbPokeCenterPC']),
                              if (autorunContext == 'unsafePc')
                                const LiteralFixtureEventCommand(
                                    355, ['unknownContextEffect()']),
                              const LiteralFixtureEventCommand(123, ['A', 1]),
                              const LiteralFixtureEventCommand(0, []),
                            ]),
                      ]),
          if (unknownMemoryWriter)
            LiteralFixtureEvent(
                id: 10,
                x: 5,
                y: 5,
                name: 'Unsafe writer',
                pages: const [
                  LiteralFixtureEventPage(commands: [
                    LiteralFixtureEventCommand(122, [38, 38, 1, 0, 1]),
                    LiteralFixtureEventCommand(355, ['unknownMemoryEffect()']),
                    LiteralFixtureEventCommand(0, [])
                  ]),
                ])
        ])
      ]);
  final analysis = SourceEventAnalyzer.forProject(fixture.source,
          profile: SourceEventProfile.forProject(fixture.source))
      .analyze();
  final event = analysis.eventAt(61, 8)!;
  final program = event.pages.single.body.nodes
      .whereType<SourcePortraitProgramNode>()
      .singleOrNull;
  final binding = !bind || program == null
      ? null
      : await const SourcePortraitBindingResolver().read(
          source: fixture.source,
          analysis: analysis,
          event: event,
          program: program,
          files: fixture.files);
  final imported = actor
      ? await const SourceEventCharacterImporter().read(
          snapshot: fixture.snapshot,
          files: fixture.files,
          charsetName: 'NPC_FRLG_SCIENTIST',
          sourcePattern: 0,
          sourceDirection: 2)
      : null;
  final projection = const SourceEventProjector()
      .project(source: fixture.source, analysis: analysis, nativeMaps: {
    61: const MapData(
        id: 'lab', name: 'Lab', size: GridSize(width: 6, height: 6), layers: [])
  }, characterBindings: {
    if (imported != null) imported.bindingKey: imported.binding
  }, portraitBindings: {
    if (binding != null) event.identity: binding
  });
  return (
    fixture: fixture,
    analysis: analysis,
    binding: binding,
    projection: projection
  );
}

Future<({GameState state, List<String> cinematics, int dialogues})>
    _runPortrait(SourceEventProjection projection, SceneAsset scene, int memory,
        bool rescued) async {
  final resolver = NarrativeFactRuntimeResolver.fromFacts(projection.facts);
  final writer = NarrativeFactRuntimeWriter(resolver);
  var state = const GameState(
      saveId: 'portrait',
      currentMapId: 'lab',
      playerPosition: GridPos(x: 1, y: 2));
  final memoryFact = projection.facts
      .singleWhere((fact) => fact.valueKind == NarrativeValueKind.integer)
      .id;
  final rescuedFact = projection.facts
      .singleWhere((fact) => fact.valueKind == NarrativeValueKind.boolean)
      .id;
  state = writer
      .setFactValue(
          gameState: state,
          factId: memoryFact,
          value: NarrativeValue.integer(memory))
      .gameState;
  state = writer
      .setFactValue(
          gameState: state,
          factId: rescuedFact,
          value: NarrativeValue.boolean(rescued))
      .gameState;
  final played = <String>[];
  var dialogues = 0;
  final plan = buildSceneRuntimePlan(
      SceneAsset.fromJson(jsonDecode(jsonEncode(scene.toJson()))));
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
    showDialogue: (_) {
      dialogues++;
      return 'completed';
    },
    startBattle: (_) => throw StateError('Portrait must not start a battle'),
    playCinematic: (intent) {
      played.add(intent.cinematicId!);
      return 'completed';
    },
    applyConsequence: (consequence) {
      if (consequence is! SceneAdjustIntegerFactConsequence) {
        throw StateError('Unexpected portrait consequence');
      }
      state = writer
          .adjustIntegerFact(
              gameState: state,
              factId: consequence.factId,
              delta: consequence.delta,
              minimum: consequence.minimum,
              maximum: consequence.maximum)
          .gameState;
      return 'completed';
    },
  )).execute(plan.plan!);
  expect(result.status, SceneRuntimeExecutionStatus.completed,
      reason: '${result.message}');
  return (state: state, cinematics: played, dialogues: dialogues);
}

List<LiteralFixtureEventPage> _doorPages({required bool unsafe}) {
  LiteralFixtureUserDefined tone(double level) {
    final data = ByteData(32);
    for (var i = 0; i < 3; i++) {
      data.setFloat64(i * 8, level, Endian.little);
    }
    return LiteralFixtureUserDefined('Tone', data.buffer.asUint8List());
  }

  const move = LiteralFixtureObject(
      'RPG::MoveCommand', {'@code': 1, '@parameters': <Object?>[]});
  const route = LiteralFixtureObject('RPG::MoveRoute', {
    '@repeat': false,
    '@skippable': true,
    '@list': [
      move,
      LiteralFixtureObject(
          'RPG::MoveCommand', {'@code': 0, '@parameters': <Object?>[]})
    ]
  });
  return [
    LiteralFixtureEventPage(trigger: 1, commands: [
      LiteralFixtureEventCommand(223, [tone(-255), 6]),
      const LiteralFixtureEventCommand(106, [8]),
      const LiteralFixtureEventCommand(201, [0, 61, 5, 4, 8, 1]),
      LiteralFixtureEventCommand(223, [tone(0), 6]),
      const LiteralFixtureEventCommand(0, []),
    ]),
    LiteralFixtureEventPage(trigger: 3, globalSwitch: 22, commands: [
      const LiteralFixtureEventCommand(111, [12, 'get_self.onEvent?']),
      const LiteralFixtureEventCommand(208, [0], indent: 1),
      const LiteralFixtureEventCommand(210, [], indent: 1),
      const LiteralFixtureEventCommand(208, [1], indent: 1),
      const LiteralFixtureEventCommand(209, [-1, route], indent: 1),
      const LiteralFixtureEventCommand(509, [move], indent: 1),
      const LiteralFixtureEventCommand(210, [], indent: 1),
      const LiteralFixtureEventCommand(0, [], indent: 1),
      const LiteralFixtureEventCommand(412, []),
      if (unsafe)
        const LiteralFixtureEventCommand(355, ['unknownDoorEffect()']),
      const LiteralFixtureEventCommand(355, ['setTempSwitchOn("A")']),
      const LiteralFixtureEventCommand(0, []),
    ])
  ];
}

void main() {
  test(
      'complete portrait projects conditions, exact actor and three native cinematic stages',
      () async {
    final result = await _fixture();
    final row = (result.projection.semanticEvidence['events'] as List)
        .cast<Map>()
        .singleWhere((row) =>
            row['sourceIdentity'] ==
            result.analysis.eventAt(61, 8)!.identity.value);
    expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
    expect(result.projection.cinematics, hasLength(3));
    expect(
        result.projection.mutations
            .where((m) => m.actionId == 'cinematic.upsert'),
        hasLength(3));
    final poses = result.projection.cinematics.singleWhere((c) => c
        .timeline.steps
        .any((step) => step.kind == CinematicTimelineStepKind.actorAnimation));
    final custom = poses.timeline.steps.singleWhere(
        (step) => step.kind == CinematicTimelineStepKind.actorAnimation);
    final wait = poses.timeline.steps
        .singleWhere((step) => step.id == 'source_after_pose_wait');
    expect(custom.parallelGroupId, wait.parallelGroupId);
    expect(custom.durationMs, 400);
    expect(wait.durationMs, 500);
    expect(
        result.binding!.mutations
            .where((m) => m.actionId == 'characterStudio.animationClip.upsert')
            .single
            .parameters['frames'],
        hasLength(4));
    expect(
        result.projection.facts.any((fact) =>
            fact.id ==
            sourceEventIntegerVariableBindingId(result.analysis.events
                .singleWhere((event) => event.sourceEventId == 8)
                .pages
                .single
                .body
                .nodes
                .whereType<SourcePortraitProgramNode>()
                .single
                .body
                .nodes
                .whereType<SourceConditionalNode>()
                .single
                .condition
                .factId!)),
        isTrue);
  });

  test(
      'portrait composer publishes canonical editable clips and cinematics for strict reopening',
      () async {
    final result = await _fixture();
    final temporary = await Directory.systemTemp.createTemp('portrait-native-');
    addTearDown(() => temporary.delete(recursive: true));
    final literal = await const LiteralTileComposer().compose(
        source: result.fixture.source,
        files: result.fixture.files,
        selectedSourceMapIds: [61],
        projectName: 'Portrait',
        parentPath: temporary.path,
        folderName: 'native');
    final semantic = (await const SourceSemanticStudyComposer().compose(
        source: result.fixture.source,
        base: literal,
        files: result.fixture.files))!;
    final composed = (await const SourceEventStudyComposer().compose(
        source: result.fixture.source,
        base: semantic,
        files: result.fixture.files))!;
    expect(composed.projection.cinematics, hasLength(3));
    for (final action in [
      'cinematic.upsert',
      'characterStudio.animationClip.upsert'
    ]) {
      final original = composed.draft;
      final altered = NativeProjectDraft(
          source: original.source,
          projectName: original.projectName,
          parentPath: original.parentPath,
          folderName: original.folderName,
          mapIds: original.mapIds,
          artifacts: original.artifacts,
          sourceArtifacts: original.sourceArtifacts,
          sourceRootPath: original.sourceRootPath,
          compositionEvidence: original.compositionEvidence,
          defaultMapWidth: original.defaultMapWidth,
          defaultMapHeight: original.defaultMapHeight,
          mutations: [
            for (final mutation in original.mutations)
              if (mutation.actionId == action &&
                  (action == 'cinematic.upsert' ||
                      mutation.parameters['kind'] == 'custom'))
                NativeMutation(
                    operationId: mutation.operationId,
                    actionId: mutation.actionId,
                    sourceEntityIds: mutation.sourceEntityIds,
                    targetEntityIds: mutation.targetEntityIds,
                    parameters: {
                      ...mutation.parameters,
                      'unattestedEffect': true
                    })
              else
                mutation
          ]);
      final tamperApproval = approveNativeFixtureDraft(altered);
      await expectLater(
          NativeProjectWriter()
              .write(tamperApproval.plan, tamperApproval.context, altered),
          throwsA(isA<NativeWriteException>()));
    }
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
      expect(native.manifest.cinematics, hasLength(3));
      expect(native.manifest.characterStudioCatalog.customAnimationDefinitions,
          hasLength(1));
      expect(
          native.manifest.characters
              .expand((character) => character.customAnimations),
          hasLength(1));
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
  });

  for (final context in ['pc', 'door']) {
    test('portrait preserves serialized source-bound $context autorun context',
        () async {
      final result = await _fixture(autorunContext: context);
      final row = (result.projection.semanticEvidence['events'] as List)
          .cast<Map>()
          .singleWhere((row) =>
              row['sourceIdentity'] ==
              result.analysis.eventAt(61, 8)!.identity.value);
      expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
      expect(result.projection.cinematics, hasLength(3));
    });
  }
  for (final context in ['unsafePc', 'parallelPc', 'unsafeDoor', 'overlapPc']) {
    test('portrait refuses unsafe or overlapping $context autorun context',
        () async {
      final result = await _fixture(autorunContext: context);
      final row = (result.projection.semanticEvidence['events'] as List)
          .cast<Map>()
          .singleWhere((row) =>
              row['sourceIdentity'] ==
              result.analysis.eventAt(61, 8)!.identity.value);
      expect(row['gaps'],
          contains('sourcePortraitConcurrentInterpreterUnsupported'));
      expect(result.projection.cinematics, isEmpty);
    });
  }

  test('portrait without native binding stays wholly quarantined', () async {
    final result = await _fixture(bind: false);
    expect(result.projection.cinematics, isEmpty);
    expect(
        (result.projection.semanticEvidence['events'] as List)
            .cast<Map>()
            .singleWhere((row) =>
                row['sourceIdentity'] ==
                result.analysis.eventAt(61, 8)!.identity.value)['gaps'],
        contains('sourcePortraitPresentationBindingMissing'));
  });

  test(
      'explicit SHA-bound missing charset substitution remains a declared visual adaptation',
      () async {
    final result = await _fixture(pose: false, substitute: true);
    expect(result.projection.cinematics, hasLength(3));
    expect(
        result.binding!.presentation.toJson()['sourceVisualParity'], isFalse);
    expect(
        result.binding!.presentation.actualCharsetName, 'NPC_FRLG_SCIENTIST');
    expect(result.binding!.poseImport.sourceOffsetXPx,
        result.binding!.actorImport.sourceOffsetXPx);
    expect(result.binding!.poseImport.sourceOffsetYPx,
        result.binding!.actorImport.sourceOffsetYPx);
  });

  test('wrong substitution SHA cannot qualify the missing source pose',
      () async {
    await expectLater(
        _fixture(pose: false, substitute: true, wrongSubstitutionHash: true),
        throwsA(isA<NativeWriteException>()));
  });

  test(
      'portrait guards retain both gates and increment only exactly four memories',
      () async {
    final result = await _fixture();
    final scene = result.projection.scenes.singleWhere((s) =>
        s.metadata['sourceEventIdentity'] ==
        result.analysis.eventAt(61, 8)!.identity.value);
    for (final (memory, rescued, count, dialogues, after) in [
      (3, true, 0, 1, 3),
      (4, false, 0, 1, 4),
      (4, true, 3, 5, 5),
      (5, true, 3, 5, 5),
    ]) {
      final played =
          await _runPortrait(result.projection, scene, memory, rescued);
      expect(played.cinematics, hasLength(count));
      expect(played.dialogues, dialogues);
      final fact = result.projection.facts
          .singleWhere((fact) => fact.valueKind == NarrativeValueKind.integer);
      final value =
          NarrativeFactRuntimeResolver.fromFacts(result.projection.facts)
                  .resolve(
                      factId: fact.id,
                      runtimeState: played.state.narrativeFactRuntimeState,
                      storyFlags: played.state.storyFlags)
              as NarrativeFactRuntimeResolved;
      expect(value.narrativeValue, NarrativeValue.integer(after));
    }
  });

  test('portrait keeps the complete variable writer closure guard', () async {
    final result = await _fixture(unknownMemoryWriter: true);
    final row = (result.projection.semanticEvidence['events'] as List)
        .cast<Map>()
        .singleWhere((row) =>
            row['sourceIdentity'] ==
            result.analysis.eventAt(61, 8)!.identity.value);
    expect(row['gaps'], contains('sourceVariableWriterUnqualified'));
    expect(result.projection.cinematics, isEmpty);
  });

  test(
      'valid image binding cannot move the addressed source actor to another cell',
      () async {
    final result = await _fixture();
    final sourceActor = result.analysis.eventAt(61, 9)!;
    final forged = SourceEventDefinition(
        sourceMapId: sourceActor.sourceMapId,
        sourceEventId: sourceActor.sourceEventId,
        sourceFileId: sourceActor.sourceFileId,
        identity: sourceActor.identity,
        name: sourceActor.name,
        x: sourceActor.x + 1,
        y: sourceActor.y,
        locator: sourceActor.locator,
        pages: sourceActor.pages);
    final projection = const SourceEventProjector().project(
        source: result.fixture.source,
        analysis: SourceEventAnalysis(
            profile: result.analysis.profile,
            diagnostics: result.analysis.diagnostics,
            events: [result.analysis.eventAt(61, 8)!, forged]),
        nativeMaps: {
          61: const MapData(
              id: 'lab', name: 'Lab', size: GridSize(width: 6, height: 6))
        },
        portraitBindings: {
          result.analysis.eventAt(61, 8)!.identity: result.binding!
        },
        characterBindings: {
          result.binding!.actorImport.bindingKey:
              result.binding!.actorImport.binding
        });
    final row = (projection.semanticEvidence['events'] as List)
        .cast<Map>()
        .singleWhere((row) =>
            row['sourceIdentity'] ==
            result.analysis.eventAt(61, 8)!.identity.value);
    expect(row['gaps'], contains('sourcePortraitActorUnqualified'));
    expect(projection.cinematics, isEmpty);
  });

  for (final type in [1, 2, 3]) {
    test('portrait refuses unqualified autonomous actor motion type $type',
        () async {
      await expectLater(
          _fixture(actorMoveType: type), throwsA(isA<NativeWriteException>()));
    });
  }

  test('missing pose image cannot create a silent placeholder', () async {
    await expectLater(
        _fixture(pose: false), throwsA(isA<NativeWriteException>()));
  });

  test('missing source actor cannot create an unqualified decor actor',
      () async {
    await expectLater(
        _fixture(actor: false), throwsA(isA<NativeWriteException>()));
  });

  test('unqualified actor program cannot be hidden by valid image imports',
      () async {
    await expectLater(
        _fixture(actorQualified: false), throwsA(isA<NativeWriteException>()));
  });
}
