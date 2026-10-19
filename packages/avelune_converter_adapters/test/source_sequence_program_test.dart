import 'dart:convert';
import 'dart:typed_data';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_adapters/src/source_event_execution_context.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

LiteralFixtureObject _step(int code, [List<Object?> args = const []]) =>
    LiteralFixtureObject(
        'RPG::MoveCommand', {'@code': code, '@parameters': args});

List<LiteralFixtureEventCommand> _route(
        {bool repeat = false,
        bool skippable = true,
        int target = -1,
        bool barrier = true,
        List<LiteralFixtureObject>? steps}) =>
    [
      LiteralFixtureEventCommand(209, [
        target,
        LiteralFixtureObject('RPG::MoveRoute', {
          '@repeat': repeat,
          '@skippable': skippable,
          '@list': [...?steps, if (steps == null) _step(4), _step(0)],
        })
      ]),
      for (final step in steps ?? [_step(4)])
        LiteralFixtureEventCommand(509, [step]),
      if (barrier) const LiteralFixtureEventCommand(210, []),
    ];

Future<({LiteralTileFixture fixture, SourceEventAnalysis analysis})> _source(
    List<LiteralFixtureEventCommand> commands,
    {int trigger = 0,
    bool terminal = false,
    String? terminalSwitch = 'A',
    bool terminalGraphic = false,
    bool activeFixed = false,
    bool activeGraphic = false,
    int? initialSwitch,
    String? initialSelfSwitch,
    int? initialVariable,
    int moveSpeed = 3}) async {
  final fixture = await LiteralTileFixture.create(
      interpretationProfile: syntheticSourceInterpretationProfile,
      scriptsBytes: syntheticInterpretationArchive,
      includeEventSystem: true,
      switchNames: const [null, 'Ready'],
      variableNames: const [null, 'Count'],
      extraFiles: {
        'Data/map_connections.dat': literalFixtureMarshal([]),
        if (terminalGraphic || activeFixed || activeGraphic)
          'Graphics/Characters/Wall.png': literalFixtureAtlas(),
      },
      maps: [
        LiteralFixtureMap(id: 1, events: [
          LiteralFixtureEvent(id: 1, x: 1, y: 0, pages: [
            LiteralFixtureEventPage(
                trigger: trigger,
                globalSwitch: initialSwitch,
                selfSwitch: initialSelfSwitch,
                variableId: initialVariable,
                variableThreshold: initialVariable == null ? 0 : 3,
                commands: commands,
                characterName: activeFixed || activeGraphic ? 'Wall' : '',
                directionFix: activeFixed,
                moveSpeed: moveSpeed),
            if (terminal)
              LiteralFixtureEventPage(
                  commands: const [],
                  selfSwitch: terminalSwitch,
                  characterName: terminalGraphic ? 'Wall' : '',
                  directionFix: terminalGraphic)
          ])
        ])
      ]);
  return (
    fixture: fixture,
    analysis: SourceEventAnalyzer.forProject(fixture.source,
            profile: SourceEventProfile.forProject(fixture.source))
        .analyze()
  );
}

Future<SourceEventProjection> _projection(LiteralTileFixture fixture,
    {bool context = true, bool mutateMap = false}) async {
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: fixture.snapshot,
      files: fixture.files,
      interpretationProfile: syntheticSourceInterpretationProfile,
      includeEventSystem: true,
      includeConnections: true);
  final analysis = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source))
      .analyze();
  final maps = {
    1: MapData(
        id: 'map',
        name: 'Map',
        size: const GridSize(width: 3, height: 1),
        layers: [])
  };
  final base = NativeProjectDraft(
      source: source,
      projectName: 'Sequence',
      parentPath: '/private/tmp',
      folderName: 'unused-sequence',
      mapIds: const {
        1: 'map'
      },
      artifacts: [],
      mutations: [
        NativeMutation(
            operationId: ConverterId('map-create'),
            actionId: 'map.create',
            sourceEntityIds: [
              source.mapIdentity(1)
            ],
            targetEntityIds: [
              ConverterId('map')
            ],
            parameters: const {
              'mapId': 'map',
              'name': 'Map',
              'width': 3,
              'height': 1
            }),
        NativeMutation(
            operationId: ConverterId('map-save'),
            actionId: 'map.save',
            sourceEntityIds: [source.mapIdentity(1)],
            targetEntityIds: [ConverterId('map')],
            parameters: {'map': maps[1]!.toJson()}),
      ],
      compositionEvidence: {
        'kind': 'literalTileComposition',
        'version': 2,
        'composition': {'kind': 'sequenceFixture'},
        'compositionHash': canonicalHashOf({'kind': 'sequenceFixture'}).value,
        'sourceSemantics': {},
      });
  final bound = context
      ? await const SourceEventExecutionContextResolver().read(
          source: source, base: base, nativeMaps: maps, files: fixture.files)
      : null;
  if (bound != null) expect(bound.refusals, isEmpty);
  if (mutateMap) maps[1] = maps[1]!.copyWith(name: 'Changed');
  return const SourceEventProjector().project(
      source: source,
      analysis: analysis,
      nativeMaps: maps,
      characterBindings: {
        for (final entry in fixture.snapshot.entries.where(
            (entry) => entry.relativePath == 'Graphics/Characters/Wall.png'))
          sourceEventCharacterBindingKey(
                  characterName: 'Wall', pattern: 0, direction: 2):
              SourceEventCharacterBinding(
                  characterId: 'wall-character',
                  sourceSnapshotHash: fixture.snapshot.canonicalHash,
                  sourceFileId: entry.fileId,
                  sourceFileHash: entry.sha256!,
                  sourcePattern: 0,
                  sourceDirection: 2)
      },
      executionContext: bound,
      retentionPolicy: MapInstanceRetentionPolicy(
          viewportWidthTiles: 20, viewportHeightTiles: 15, marginTiles: 1));
}

void main() {
  for (final kind in ['global', 'self', 'combined', 'numeric']) {
    test('finite autorun preserves its $kind initial guard', () async {
      final source = await _source(const [
        LiteralFixtureEventCommand(106, [2]),
        LiteralFixtureEventCommand(101, ['Guarded sequence.']),
        LiteralFixtureEventCommand(123, ['A', 0]),
      ], trigger: 3, terminal: true,
        initialSwitch: kind == 'self' || kind == 'numeric' ? null : 1,
        initialSelfSwitch: kind == 'global' || kind == 'numeric' ? null : 'B',
        initialVariable: kind == 'numeric' ? 1 : null);
      final event = source.analysis.events.single;
      final programs = sourceSequencePrograms(
          source: source.fixture.source, analysis: source.analysis);
      expect(programs, hasLength(1));
      expect(programs.values.single.isBoundTo(source: source.fixture.source,
          analysis: source.analysis, event: event), isTrue);
      final projection = await _projection(source.fixture);
      expect(projection.scenes, hasLength(2),
          reason: jsonEncode(projection.semanticEvidence));
      final encoded = jsonEncode(projection.semanticEvidence);
      expect(encoded, contains('finiteAutorun'));
      final sceneJson = jsonEncode(projection.scenes.map((scene) => scene.toJson()).toList());
      expect(sceneJson, contains('wait'));
      final registryJson = jsonEncode(projection.registry.toJson());
      expect(registryJson, contains('entityAutorun'));
      expect(registryJson, contains('"kind":"fact"'));
      if (kind == 'numeric') {
        expect(registryJson, contains('"operator":"greaterThanOrEqual"'));
        expect(registryJson, contains('"expectedValue":3'));
      }
      final condition = event.pages.first.condition;
      for (final guard in condition.kind == SourceEventConditionKind.all
          ? condition.children : [condition]) {
        expect(registryJson, contains(guard.kind == SourceEventConditionKind.variableAtLeast
            ? sourceEventIntegerVariableBindingId(guard.factId!)
            : sourceEventFactBindingId(guard.factId!)));
      }
      expect(sceneJson, contains(sourceEventFactBindingId(
          (event.pages.first.body.nodes.last as SourceSelfSwitchNode).factId)));
    });
  }
  test('guarded autorun still requires its final dominant self-switch page', () async {
    for (final terminal in [false, true]) {
      final source = await _source(const [
        LiteralFixtureEventCommand(106, [2]),
        LiteralFixtureEventCommand(123, ['A', 0]),
      ], trigger: 3, terminal: terminal, terminalSwitch: 'B', initialSwitch: 1);
      expect(sourceSequencePrograms(source: source.fixture.source,
          analysis: source.analysis), isEmpty);
    }
  });
  test('tone remains asynchronous and wait retains source ticks', () async {
    final bytes = ByteData(32)..setFloat64(0, -64, Endian.little);
    final source = await _source([
      LiteralFixtureEventCommand(223,
          [LiteralFixtureUserDefined('Tone', bytes.buffer.asUint8List()), 6]),
      const LiteralFixtureEventCommand(106, [8]),
    ]);
    final projection = await _projection(source.fixture);
    final json = jsonEncode(projection.scenes.single.toJson());
    expect(json, contains('worldTone'));
    expect(json, contains('300'));
    expect(json, contains('400'));
    final tone = source.analysis.events.single.pages.single.body.nodes.first
        as SourceToneNode;
    expect(tone.toJson()['waitForCompletion'], isFalse);
  });
  test('sound without a qualified source engine binding refuses whole sequence',
      () async {
    final source = await _source(const [
      LiteralFixtureEventCommand(101, ['Before']),
      LiteralFixtureEventCommand(250, [
        LiteralFixtureObject(
            'RPG::AudioFile', {'@name': 'Door', '@volume': 80, '@pitch': 100})
      ])
    ]);
    final projection = await _projection(source.fixture);
    expect(projection.scenes, isEmpty);
    expect(projection.dialogues, isEmpty);
    expect(jsonEncode(projection.semanticEvidence),
        contains('sourceSoundBindingMissing'));
  });
  test('autorun preserves its solid fixed graphic terminal page', () async {
    final source = await _source([
      ..._route(),
      const LiteralFixtureEventCommand(123, ['A', 0])
    ], trigger: 3, terminal: true, terminalGraphic: true);
    final projection = await _projection(source.fixture);
    expect(projection.scenes, hasLength(2),
        reason: jsonEncode(projection.semanticEvidence));
    final entity = projection.nativeMaps[1]!.entities.single;
    expect(jsonEncode(entity.toJson()), contains('wall-character'));
    expect(jsonEncode(entity.toJson()), contains('variants'));
  });
  test('active fixed graphic is refused for generic sequence motion', () async {
    final source = await _source(_route(target: 0), activeFixed: true);
    expect((await _projection(source.fixture)).scenes, isEmpty);
  });
  test('current owner motion at a different source speed is refused', () async {
    final source =
        await _source(_route(target: 0), moveSpeed: 4, activeGraphic: true);
    expect(
        sourceSequencePrograms(
            source: source.fixture.source, analysis: source.analysis),
        isEmpty);
  });
  test('current owner route requires an actual visible native actor', () async {
    final source = await _source(_route(target: 0));
    expect(
        sourceSequencePrograms(
            source: source.fixture.source, analysis: source.analysis),
        isEmpty);
  });
  test('current owner motion uses its actual native actor at attested speed',
      () async {
    final source = await _source(_route(target: 0), activeGraphic: true);
    expect(
        sourceSequencePrograms(
            source: source.fixture.source, analysis: source.analysis),
        hasLength(1));
    final projection = await _projection(source.fixture);
    expect(projection.scenes, hasLength(1));
    expect(
        jsonEncode(projection.scenes.single.toJson()), contains('actorRoute'));
  });
  for (final variant in [
    'complete',
    'missing first barrier',
    'missing reveal',
    'wrong actor',
    'wrong cleanup'
  ]) {
    test('routed arrival preserves complete visibility barriers: $variant',
        () async {
      LiteralFixtureUserDefined tone(double value) {
        final bytes = ByteData(32);
        for (var i = 0; i < 3; i++) {
          bytes.setFloat64(i * 8, value, Endian.little);
        }
        return LiteralFixtureUserDefined('Tone', bytes.buffer.asUint8List());
      }

      final fixture = await LiteralTileFixture.create(
          interpretationProfile: syntheticSourceInterpretationProfile,
          scriptsBytes: syntheticInterpretationArchive,
          includeEventSystem: true,
          switchNames: const [
            null,
            's:tsOff?("A")'
          ],
          maps: [
            LiteralFixtureMap(id: 1, events: [
              LiteralFixtureEvent(id: 1, x: 1, y: 0, pages: [
                LiteralFixtureEventPage(trigger: 1, commands: [
                  LiteralFixtureEventCommand(223, [tone(-255), 6]),
                  const LiteralFixtureEventCommand(106, [8]),
                  const LiteralFixtureEventCommand(208, [1]),
                  const LiteralFixtureEventCommand(201, [0, 1, 1, 0, 8, 1]),
                  LiteralFixtureEventCommand(223, [tone(0), 6]),
                ]),
                LiteralFixtureEventPage(trigger: 3, globalSwitch: 1, commands: [
                  const LiteralFixtureEventCommand(
                      111, [12, 'get_self.onEvent?']),
                  const LiteralFixtureEventCommand(208, [0], indent: 1),
                  if (variant != 'missing first barrier')
                    const LiteralFixtureEventCommand(210, [], indent: 1),
                  if (variant != 'missing reveal')
                    const LiteralFixtureEventCommand(208, [1], indent: 1),
                  for (final command in _route(
                      target: variant == 'wrong actor' ? 0 : -1,
                      steps: [_step(1)]))
                    LiteralFixtureEventCommand(command.code, command.parameters,
                        indent: 1),
                  const LiteralFixtureEventCommand(412, []),
                  LiteralFixtureEventCommand(355, [
                    variant == 'wrong cleanup'
                        ? 'setTempSwitchOn("B")'
                        : 'setTempSwitchOn("A")'
                  ]),
                ])
              ])
            ])
          ]);
      final analysis = SourceEventAnalyzer.forProject(fixture.source,
              profile: SourceEventProfile.forProject(fixture.source))
          .analyze();
      expect(
          sourceRoutedDoorPrograms(source: fixture.source, analysis: analysis)
              .length,
          variant == 'complete' ? 1 : 0,
          reason: jsonEncode(analysis.events.single.pages
              .expand((page) => page.diagnostics)
              .map((diagnostic) => diagnostic.toJson())
              .toList()));
    });
  }
  test('balanced visibility is projected in source order', () async {
    final source = await _source(const [
      LiteralFixtureEventCommand(208, [0]),
      LiteralFixtureEventCommand(106, [2]),
      LiteralFixtureEventCommand(208, [1])
    ]);
    final projection = await _projection(source.fixture);
    final commands = projection.scenes.single.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneActionPayload>()
        .map((payload) => payload.interactiveCommand)
        .whereType<SceneActorVisibilityInteractiveCommand>()
        .toList();
    expect(
        commands.map((command) => command.visible).toList()
          ..sort((a, b) => (a ? 1 : 0).compareTo(b ? 1 : 0)),
        [false, true]);
  });
  test('native executor keeps wait text and route barrier order', () async {
    final source = await _source([
      const LiteralFixtureEventCommand(101, ['Before']),
      const LiteralFixtureEventCommand(106, [4]),
      ..._route(steps: [_step(2)]),
      const LiteralFixtureEventCommand(101, ['After'])
    ]);
    final projection = await _projection(source.fixture);
    expect(projection.scenes, hasLength(1),
        reason: jsonEncode(projection.semanticEvidence));
    final visited = <String>[];
    final execution = await SceneRuntimeExecutor(
        callbacks: SceneRuntimeExecutionCallbacks(
            evaluateCondition: (_) => 'true',
            applyConsequence: (_) => 'completed',
            showDialogue: (intent) {
              final doc = const YarnDialogueCompiler()
                  .compile(projection.dialogueSources[intent.dialogueId]!);
              visited.addAll(doc.nodes.single.steps
                  .whereType<RuntimeDialogueLine>()
                  .map((line) => line.text));
              return 'completed';
            },
            startBattle: (_) => throw StateError('Battle'),
            playCinematic: (_) => throw StateError('Cinematic'),
            executeInteractiveCommand: (intent) {
              visited.add(intent.interactiveCommand!.kind.name);
              return 'completed';
            })).execute(buildSceneRuntimePlan(projection.scenes.single).plan!);
    expect(execution.status, SceneRuntimeExecutionStatus.completed);
    expect(visited,
        ['Before', 'wait', 'actorRoute', 'waitForActorRoutes', 'After']);
  });
  for (final mode in ['missing', 'different map']) {
    test('refuses sequence with $mode native context', () async {
      final source = await _source(_route());
      final projection = await _projection(source.fixture,
          context: mode != 'missing', mutateMap: mode == 'different map');
      expect(projection.scenes, isEmpty);
      expect(jsonEncode(projection.semanticEvidence),
          contains('sourceExecutionContextUnknown'));
    });
  }
  test('finite linear wait and text sequence is source attested', () async {
    final source = await _source(const [
      LiteralFixtureEventCommand(101, ['Before']),
      LiteralFixtureEventCommand(106, [4]),
      LiteralFixtureEventCommand(101, ['After'])
    ]);
    final programs = sourceSequencePrograms(
        source: source.fixture.source, analysis: source.analysis);
    expect(programs, hasLength(1));
    final program = programs.values.single;
    expect(
        program.isBoundTo(
            source: source.fixture.source,
            analysis: source.analysis,
            event: source.analysis.events.single),
        isTrue);
    expect(program.finiteAutorun, isFalse);
    expect(
        (source.analysis.events.single.pages.single.body.nodes[1]
                as SourceWaitNode)
            .durationMs,
        200);
  });
  test('forged typed duration cannot reuse the source command witness',
      () async {
    final source = await _source(const [
      LiteralFixtureEventCommand(106, [4])
    ]);
    final event = source.analysis.events.single;
    final page = event.pages.single;
    final wait = page.body.nodes.single as SourceWaitNode;
    final forged = SourceEventDefinition(
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
              body: SourceEventBlock(nodes: [
                SourceWaitNode(wait.span,
                    durationTicks: 1, profileHash: wait.profileHash)
              ], span: page.body.span),
              rawDataRef: page.rawDataRef,
              diagnostics: page.diagnostics)
        ]);
    final changed = SourceEventAnalysis(
        profile: source.analysis.profile,
        events: [forged],
        diagnostics: source.analysis.diagnostics);
    final original = sourceSequencePrograms(
            source: source.fixture.source, analysis: source.analysis)
        .values
        .single;
    expect(
        original.isBoundTo(
            source: source.fixture.source, analysis: changed, event: forged),
        isFalse);
    expect(
        sourceSequencePrograms(
            source: source.fixture.source, analysis: changed),
        isEmpty);
  });
  test('cardinal route with its immediate barrier is finite', () async {
    final source = await _source(_route(steps: [
      _step(37),
      _step(2),
      _step(3),
      _step(4),
      _step(1),
      _step(15, [8]),
      _step(16),
      _step(38)
    ]));
    expect(
        sourceSequencePrograms(
            source: source.fixture.source, analysis: source.analysis),
        hasLength(1));
  });
  test('finite autorun reaches its higher self-switch page', () async {
    final source = await _source([
      ..._route(),
      const LiteralFixtureEventCommand(123, ['A', 0])
    ], trigger: 3, terminal: true);
    expect(
        sourceSequencePrograms(
                source: source.fixture.source, analysis: source.analysis)
            .values
            .single
            .finiteAutorun,
        isTrue);
  });
  for (final entry in <String, List<LiteralFixtureEventCommand>>{
    'ordinary dialogue': const [
      LiteralFixtureEventCommand(101, ['Text'])
    ],
    'missing barrier': _route(barrier: false),
    'repeating route': _route(repeat: true),
    'non skippable': _route(skippable: false),
    'foreign actor': _route(target: 2),
    'unrestored through': _route(steps: [_step(37), _step(4)]),
    'through off without on': _route(steps: [_step(38)]),
    'diagonal route': _route(steps: [_step(7)]),
    'above map route': _route(steps: [_step(39), _step(40)]),
    'bare barrier': const [LiteralFixtureEventCommand(210, [])],
    'common call': const [
      LiteralFixtureEventCommand(106, [4]),
      LiteralFixtureEventCommand(117, [1])
    ],
    'warp': const [
      LiteralFixtureEventCommand(106, [4]),
      LiteralFixtureEventCommand(201, [0, 1, 1, 0, 0, 1])
    ],
    'unknown': const [
      LiteralFixtureEventCommand(106, [4]),
      LiteralFixtureEventCommand(999, [])
    ],
    'unrestored visibility': const [
      LiteralFixtureEventCommand(208, [0])
    ],
  }.entries) {
    test('refuses ${entry.key} atomically', () async {
      final source = await _source(entry.value);
      expect(
          sourceSequencePrograms(
              source: source.fixture.source, analysis: source.analysis),
          isEmpty);
    });
  }
  test('refuses autorun without termination page', () async {
    final source = await _source(_route(), trigger: 3);
    expect(
        sourceSequencePrograms(
            source: source.fixture.source, analysis: source.analysis),
        isEmpty);
  });
  test('refuses autorun with another terminal self switch', () async {
    final source = await _source([
      ..._route(),
      const LiteralFixtureEventCommand(123, ['A', 0])
    ], trigger: 3, terminal: true, terminalSwitch: 'B');
    expect(
        sourceSequencePrograms(
            source: source.fixture.source, analysis: source.analysis),
        isEmpty);
  });
}
