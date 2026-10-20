import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

final _dialogueProfile = SourceInterpretationProfile.fromJson({
  ...syntheticSourceInterpretationProfile.toJson(),
  'sections': {
    ...syntheticSourceInterpretationProfile.toJson()['sections'] as Map,
    for (final role in ['Messages', 'MessageConfig', 'DrawText'])
      'events.$role': (syntheticSourceInterpretationProfile.toJson()['sections']
          as Map)['events.Interpreter'],
  },
});

const _messages = [
  LiteralFixtureEventCommand(101, [r'\w[signskin]Trainer Tips']),
  LiteralFixtureEventCommand(101, [r'\w[signskin]Recover your']),
  LiteralFixtureEventCommand(401, ['Pokémon.']),
  LiteralFixtureEventCommand(101, [r'\w[signskin]Come back soon.']),
];

Future<SourceEventProjection> _project({
  List<LiteralFixtureEventCommand> commands = _messages,
  int width = 1,
  int trigger = 1,
  bool conditionalPage = false,
  bool secondPage = false,
  bool sourceBlocked = true,
  bool nativeBlocked = true,
  bool overlapping = false,
  bool malformedCollision = false,
  bool forged = false,
  bool dialogueQualified = false,
  bool directional = false,
}) async {
  final profile = dialogueQualified
      ? _dialogueProfile
      : syntheticSourceInterpretationProfile;
  final fixture = await LiteralTileFixture.create(
      includeEventSystem: true,
      interpretationProfile: profile,
      scriptsBytes: syntheticInterpretationArchive,
      tilesets: [
        LiteralFixtureTileset(id: 1, passages: {400: sourceBlocked ? 15 : 0})
      ],
      maps: [
        LiteralFixtureMap(id: 1, width: 4, height: 3, layers: [
          [
            for (var i = 0; i < 12; i++)
              i == 5 || width == 2 && i == 6 ? 400 : 384
          ],
          List.filled(12, 0),
          List.filled(12, 0),
        ], events: [
          LiteralFixtureEvent(
              id: 1,
              x: 1,
              y: 1,
              name: width == 1 ? 'Notice' : 'Notice size(2,1)',
              pages: [
                LiteralFixtureEventPage(
                    trigger: trigger,
                    globalSwitch: conditionalPage ? 1 : null,
                    commands: [
                      if (directional)
                        const LiteralFixtureEventCommand(111, [6, -1, 8]),
                      for (final command in commands)
                        LiteralFixtureEventCommand(
                            command.code, command.parameters,
                            indent: directional ? 1 : command.indent),
                      if (directional) ...[
                        const LiteralFixtureEventCommand(0, [], indent: 1),
                        const LiteralFixtureEventCommand(412, []),
                      ],
                      const LiteralFixtureEventCommand(0, [])
                    ]),
                if (secondPage)
                  const LiteralFixtureEventPage(selfSwitch: 'A', commands: [
                    LiteralFixtureEventCommand(0, []),
                  ]),
              ]),
          if (overlapping)
            const LiteralFixtureEvent(id: 2, x: 1, y: 1, name: 'Other', pages: [
              LiteralFixtureEventPage(commands: [
                LiteralFixtureEventCommand(0, []),
              ])
            ]),
        ])
      ]);
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: fixture.snapshot,
      files: fixture.files,
      interpretationProfile: profile,
      includeEventSystem: true);
  var analysis = SourceEventAnalyzer.forProject(source,
          profile: SourceEventProfile.forProject(source))
      .analyze();
  if (forged) {
    final event = analysis.events.first,
        page = analysis.events.first.pages.single;
    analysis = SourceEventAnalysis(
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
                SourceEventPageAnalysis(
                  sourcePage: page.sourcePage,
                  locator: page.locator,
                  condition: page.condition,
                  graphic: page.graphic,
                  rawDataRef: page.rawDataRef,
                  diagnostics: [],
                  body: SourceEventBlock(span: page.body.span, nodes: [
                    page.body.nodes.first,
                    SourceTextNode(
                        page.body.nodes[1].span, r'\w[signskin]Forged!'),
                    ...page.body.nodes.skip(2),
                  ]),
                )
              ]),
        ]);
  }
  return const SourceEventProjector()
      .project(source: source, analysis: analysis, nativeMaps: {
    1: MapData(
        id: 'native',
        name: 'Town',
        size: const GridSize(width: 4, height: 3),
        layers: [
          MapLayer.collision(id: 'collision', name: 'Collision', collisions: [
            for (var i = 0; i < (malformedCollision ? 6 : 12); i++)
              nativeBlocked && (i == 5 || width == 2 && i == 6),
          ])
        ])
  });
}

Map _row(SourceEventProjection projection) =>
    (projection.semanticEvidence['events'] as List).first as Map;

void main() {
  for (final width in [1, 2]) {
    test(
        'static sign preserves every message and its blocked contact width=$width',
        () async {
      final result = await _project(width: width);
      expect(_row(result)['status'], 'adaptedStaticSemantics',
          reason: '${_row(result)['gaps']}');
      final map = result.nativeMaps[1]!;
      final source = result.registry.records.single.definitionOrNull!.source;
      expect(source.kind, NarrativeEventSourceKind.triggerBump);
      expect(map.triggers.single.area.size, GridSize(width: width, height: 1));
      final world = GameplayWorldState.initial(
          map: map,
          playerPos: const GridPos(x: 1, y: 2),
          playerFacing: Direction.north);
      final blocked =
          stepGameplayWorld(world, const MoveIntent(Direction.north));
      expect(blocked, isA<Blocked>());
      expect((blocked as Blocked).world.player.pos, const GridPos(x: 1, y: 2));
      expect(blocked.triggerBumpContacts.map((contact) => contact.triggerId),
          contains(map.triggers.single.id));
      final shown = <String>[];
      final execution = await SceneRuntimeExecutor(
          callbacks: SceneRuntimeExecutionCallbacks(
              evaluateCondition: (_) => throw StateError('No conditional page'),
              showDialogue: (intent) {
                shown.add(intent.linePolicies.single.feedback.plainText);
                return 'completed';
              },
              startBattle: (_) => throw StateError('No battle'),
              playCinematic: (_) => throw StateError('No cinematic'),
              applyConsequence: (_) => throw StateError('No writes'),
              executeInteractiveCommand: (_) =>
                  throw StateError('No services'))).execute(
          buildSceneRuntimePlan(result.scenes.single).plan!);
      expect(execution.status, SceneRuntimeExecutionStatus.completed);
      expect(
          shown, ['Trainer Tips', 'Recover your Pokémon.', 'Come back soon.']);
      final page = (_row(result)['pages'] as List).single as Map;
      final adapted = (page['adaptedCommands'] as List).cast<Map>();
      expect(adapted.map((row) => (row['span'] as Map)['firstCommandIndex']),
          [0, 1, 3]);
      expect(adapted.map((row) => (row['span'] as Map)['lastCommandIndex']),
          [0, 2, 3]);
      expect(result.facts, isEmpty);
    });
  }
  test('mailbox uses the qualified native player name placeholder', () async {
    final result = await _project(dialogueQualified: true, commands: const [
      LiteralFixtureEventCommand(101, [r"\w[signskin]\PN's house"]),
    ]);
    expect(_row(result)['status'], 'adaptedStaticSemantics');
    final payload = result.scenes.single.graph.nodes
        .map((node) => node.payload)
        .whereType<SceneYarnDialoguePayload>()
        .single;
    expect(payload.linePolicies.single.feedback.plainText,
        "{{ player_name }}'s house");
  });
  test('sign keeps a following ordinary message without inventing a control',
      () async {
    final result = await _project(commands: const [
      LiteralFixtureEventCommand(101, [r'\w[signskin]Pokémon Fan Club']),
      LiteralFixtureEventCommand(101, ['Trainers have written their names.']),
    ]);
    expect(_row(result)['status'], 'adaptedStaticSemantics');
    final feedback = result.dialogueSources.values.join('\n');
    expect(feedback, contains('Pokémon Fan Club'));
    expect(feedback, contains('Trainers have written their names.'));
    final page = (_row(result)['pages'] as List).single as Map;
    expect(((page['adaptedCommands'] as List).last as Map)['sourceControl'],
        isNull);
  });
  test('directional sign retains the existing facing guard around all messages',
      () async {
    final result = await _project(directional: true, commands: const [
      LiteralFixtureEventCommand(101, [r'\w[signskin]Fan Club']),
      LiteralFixtureEventCommand(101, ['Many Trainers have written']),
      LiteralFixtureEventCommand(401, [r'\ntheir names here.']),
    ]);
    expect(_row(result)['status'], 'adaptedStaticSemantics',
        reason: '${_row(result)['gaps']}');
    for (final facing in [Direction.north, Direction.south]) {
      final world = GameplayWorldState.initial(
          map: result.nativeMaps[1]!,
          playerPos: const GridPos(x: 1, y: 2),
          playerFacing: facing);
      final shown = <String>[];
      final execution = await SceneRuntimeExecutor(
              callbacks: SceneRuntimeExecutionCallbacks(
                  evaluateCondition: (intent) => evaluateScenePlayerFacing(
                          source: intent.conditionSource!, world: world)
                      ? 'true'
                      : 'false',
                  showDialogue: (intent) {
                    if (intent.linePolicies.isNotEmpty) {
                      shown.add(intent.linePolicies.single.feedback.plainText);
                    } else {
                      final document = const YarnDialogueCompiler()
                          .compile(result.dialogueSources[intent.dialogueId]!);
                      shown.addAll(document.nodes.single.steps
                          .whereType<RuntimeDialogueLine>()
                          .map((line) => line.text));
                    }
                    return 'completed';
                  },
                  startBattle: (_) => throw StateError('No battle'),
                  playCinematic: (_) => throw StateError('No cinematic'),
                  applyConsequence: (_) => throw StateError('No writes'),
                  executeInteractiveCommand: (_) =>
                      throw StateError('No services')))
          .execute(buildSceneRuntimePlan(result.scenes.single).plan!);
      expect(execution.status, SceneRuntimeExecutionStatus.completed);
      expect(
          shown,
          facing == Direction.north
              ? ['Fan Club', 'Many Trainers have written \ntheir names here.']
              : isEmpty);
    }
    final page = (_row(result)['pages'] as List).single as Map;
    final rows = (page['adaptedCommands'] as List).cast<Map>();
    expect(
        rows.map((row) => (row['span'] as Map)['firstCommandIndex']), [1, 2]);
    expect(rows.map((row) => (row['span'] as Map)['lastCommandIndex']), [1, 3]);
  });
  for (final defect in [
    'script',
    'choice',
    'unknownControl',
    'conditionalPage',
    'secondPage',
    'autorun',
    'playerTouch',
    'sourcePassable',
    'nativePassable',
    'overlap',
    'collisionLength',
    'forged',
    'tooManyMessages',
    'unqualifiedPlayerName',
    'unstyledFirst',
  ]) {
    test('static sign keeps the complete event refused for $defect', () async {
      final result = await _project(
          commands: switch (defect) {
            'script' => [
                ..._messages,
                const LiteralFixtureEventCommand(355, ['custom()'])
              ],
            'choice' => [
                ..._messages,
                const LiteralFixtureEventCommand(102, [
                  ['Yes', 'No'],
                  0
                ])
              ],
            'unknownControl' => const [
                LiteralFixtureEventCommand(101, [r'\w[signskin]\unknown'])
              ],
            'unqualifiedPlayerName' => const [
                LiteralFixtureEventCommand(101, [r"\w[signskin]\PN's house"]),
              ],
            'unstyledFirst' => const [
                LiteralFixtureEventCommand(101, ['Ordinary unknown bump.']),
                LiteralFixtureEventCommand(101, [r'\w[signskin]Sign?']),
              ],
            'tooManyMessages' => List.generate(
                17,
                (i) => const LiteralFixtureEventCommand(
                    101, [r'\w[signskin]Line'])),
            _ => _messages,
          },
          conditionalPage: defect == 'conditionalPage',
          secondPage: defect == 'secondPage',
          trigger: defect == 'autorun'
              ? 3
              : defect == 'playerTouch'
                  ? 2
                  : 1,
          sourceBlocked: defect != 'sourcePassable',
          nativeBlocked: defect != 'nativePassable',
          overlapping: defect == 'overlap',
          malformedCollision: defect == 'collisionLength',
          forged: defect == 'forged');
      expect(_row(result)['status'], 'quarantinedWholeEvent',
          reason: '${_row(result)['gaps']}');
    });
  }
}
