import 'dart:convert';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'support/literal_tile_fixture.dart';

Future<({SourceEventProjection projection, SourceEventAnalysis analysis})> _project({
  int target = 0, bool repeat = false, bool skippable = false,
  List<int> codes = const [26, 15, 25], int ticks = 8,
  bool barrier = true, bool corruptCopy = false, bool warp = false,
  bool orientationRead = false, int moveType = 0,
  bool forgeOwner = false, bool parallel = false,
}) async {
  final steps = [for (final code in codes) LiteralFixtureObject('RPG::MoveCommand',
      {'@code': code, '@parameters': code == 15 ? <Object?>[ticks] : <Object?>[]})];
  final commands = <LiteralFixtureEventCommand>[
    const LiteralFixtureEventCommand(101, ['Before.']),
    LiteralFixtureEventCommand(209, [target, LiteralFixtureObject('RPG::MoveRoute', {
      '@repeat': repeat, '@skippable': skippable,
      '@list': [...steps, const LiteralFixtureObject('RPG::MoveCommand',
        {'@code': 0, '@parameters': <Object?>[]})],
    })]),
    for (final (index, step) in steps.indexed) LiteralFixtureEventCommand(509,
      [corruptCopy && index == 0 ? const LiteralFixtureObject('RPG::MoveCommand',
          {'@code': 25, '@parameters': <Object?>[]}) : step]),
    if (barrier) const LiteralFixtureEventCommand(210, []),
    if (warp) const LiteralFixtureEventCommand(201, [0, 1, 0, 0, 2, 0]),
    if (orientationRead) ...const [LiteralFixtureEventCommand(111, [6, 0, 2]),
      LiteralFixtureEventCommand(101, ['Orientation.'], indent: 1),
      LiteralFixtureEventCommand(0, [], indent: 1), LiteralFixtureEventCommand(412, [])],
    const LiteralFixtureEventCommand(101, ['After.']),
    const LiteralFixtureEventCommand(0, []),
  ];
  final fixture = await LiteralTileFixture.create(
    interpretationProfile: syntheticSourceInterpretationProfile,
    scriptsBytes: syntheticInterpretationArchive, includeEventSystem: true,
    extraFiles: {'Graphics/Characters/Guide.png': image.encodePng(image.Image(width: 128, height: 192))},
    maps: [LiteralFixtureMap(id: 1, width: 3, height: 3,
      layers: [List.filled(9, 384), List.filled(9, 0), List.filled(9, 0)],
      events: [LiteralFixtureEvent(id: 1, x: 1, y: 1, name: 'Stationary guide',
        pages: [LiteralFixtureEventPage(characterName: 'Guide', moveType: moveType,
          commands: commands)]),
        if (parallel) const LiteralFixtureEvent(id: 2, x: 0, y: 0, name: 'Parallel',
          pages: [LiteralFixtureEventPage(trigger: 4, commands: [
            LiteralFixtureEventCommand(101, ['Concurrent.']), LiteralFixtureEventCommand(0, [])])]),
      ])]);
  var analysis = SourceEventAnalyzer.forProject(fixture.source,
      profile: SourceEventProfile.forProject(fixture.source)).analyze();
  if (forgeOwner) {
    final owner = analysis.events.single;
    analysis = SourceEventAnalysis(profile: analysis.profile, diagnostics: analysis.diagnostics,
      events: [SourceEventDefinition(identity: owner.identity, sourceFileId: owner.sourceFileId,
        sourceMapId: owner.sourceMapId, sourceEventId: owner.sourceEventId,
        name: 'Forged owner', x: owner.x, y: owner.y,
        locator: owner.locator, pages: owner.pages)]);
  }
  final imported = await const SourceEventCharacterImporter().read(snapshot: fixture.snapshot,
      files: fixture.files, charsetName: 'Guide', sourcePattern: 0, sourceDirection: 2);
  return (analysis: analysis, projection: const SourceEventProjector().project(
      source: fixture.source, analysis: analysis,
      nativeMaps: {1: const MapData(id: 'guide-map', name: 'Guide', size: GridSize(width: 3, height: 3))},
      characterBindings: {imported.bindingKey: imported.binding}));
}

void main() {
  test('stationary relative turn preserves all three steps and source barrier', () async {
    final result = await _project();
    final row = (result.projection.semanticEvidence['events'] as List).single as Map;
    expect(row['status'], 'adaptedStaticSemantics', reason: '${row['gaps']}');
    expect(result.analysis.events.single.pages.single.body.nodes
        .map((n) => n.runtimeType.toString()), contains('SourceRelativeFacingRouteNode'));
    final scene = SceneAsset.fromJson(jsonDecode(jsonEncode(result.projection.scenes.single.toJson())));
    final commands = scene.graph.nodes.map((n) => n.payload)
        .whereType<SceneActionPayload>().map((p) => p.interactiveCommand);
    final routes = commands.whereType<SceneActorRouteInteractiveCommand>().toList();
    expect(routes, hasLength(4));
    for (final route in routes) {
      expect(route.target.kind, SceneActorTargetKind.entity);
      expect(route.skippable, isFalse);
      expect(route.steps, hasLength(3));
      final away = route.steps.first as SceneActorFaceStep;
      expect((route.steps[1] as SceneActorWaitStep).durationMs, 400);
      final toward = route.steps.last as SceneActorFaceStep;
      expect(toward.direction, switch (away.direction) {
        EntityFacing.north => EntityFacing.south,
        EntityFacing.south => EntityFacing.north,
        EntityFacing.east => EntityFacing.west,
        EntityFacing.west => EntityFacing.east,
      });
    }
    expect(commands.whereType<SceneWaitForActorRoutesInteractiveCommand>(), hasLength(1));
  });

  for (final facing in EntityFacing.values) {
    test('executes exactly the source facing order for player $facing', () async {
      final projection = (await _project()).projection;
      final scene = SceneAsset.fromJson(jsonDecode(jsonEncode(projection.scenes.single.toJson())));
      final plan = buildSceneRuntimePlan(scene);
      expect(plan.plan, isNotNull);
      final order = <String>[];
      final result = await SceneRuntimeExecutor(callbacks: SceneRuntimeExecutionCallbacks(
        evaluateCondition: (intent) => intent.conditionSource!.playerFacingDirection == facing ? 'true' : 'false',
        showDialogue: (_) { order.add('dialogue'); return 'completed'; },
        startBattle: (_) => throw StateError('No battle'),
        playCinematic: (_) => throw StateError('No cinematic'),
        executeInteractiveCommand: (intent) {
          final command = intent.interactiveCommand;
          if (command is SceneActorRouteInteractiveCommand) {
            expect((command.steps.first as SceneActorFaceStep).direction, facing);
            order.add('away/wait/toward');
          } else {
            expect(command, isA<SceneWaitForActorRoutesInteractiveCommand>());
            order.add('join');
          }
          return 'completed';
        },
        applyConsequence: (_) => throw StateError('No consequence'),
      )).execute(plan.plan!);
      expect(result.status, SceneRuntimeExecutionStatus.completed);
      expect(order, ['dialogue', 'away/wait/toward', 'join', 'dialogue']);
    });
  }

  test('refuses a forged source owner even with the original route binding', () async {
    expect((await _project(forgeOwner: true)).projection.scenes, isEmpty);
  });

  test('refuses the route when a concurrent source page can run', () async {
    final result = await _project(parallel: true);
    final row = (result.projection.semanticEvidence['events'] as List).cast<Map>()
        .singleWhere((row) => row['locator']['eventId'] == 1);
    expect(row['status'], 'quarantinedWholeEvent');
    expect(row['gaps'], contains('relativeInteractionFacingUnsupported'));
  });

  for (final variant in ['target', 'repeat', 'skippable', 'movement', 'order',
    'ticks', 'barrier', 'copy', 'warp', 'orientation', 'autonomous']) {
    test('refuses incomplete or nonstationary relative turn $variant', () async {
      final result = await _project(target: variant == 'target' ? -1 : 0,
        repeat: variant == 'repeat', skippable: variant == 'skippable',
        codes: variant == 'movement' ? [26, 1, 25] : variant == 'order' ? [25, 15, 26] : [26, 15, 25],
        ticks: variant == 'ticks' ? 7 : 8, barrier: variant != 'barrier',
        corruptCopy: variant == 'copy', warp: variant == 'warp',
        orientationRead: variant == 'orientation', moveType: variant == 'autonomous' ? 1 : 0);
      expect(result.projection.scenes, isEmpty);
    });
  }
}
