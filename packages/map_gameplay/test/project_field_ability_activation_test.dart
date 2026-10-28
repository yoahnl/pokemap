import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

import 'field_obstacle_action_test.dart' as obstacles;
import 'flash_zone_action_test.dart' as flash;
import 'fly_action_test.dart' as fly;
import 'dive_action_test.dart' as dive;
import 'waterfall_action_test.dart' as waterfall;
import 'whirlpool_action_test.dart' as whirlpool;

ProjectSettings disabled(FieldAbility ability) => ProjectSettings(
      fieldAbilities:
          ProjectFieldAbilitiesSettings(disabledAbilities: [ability]),
    );
ProjectManifest project(FieldAbility ability) => ProjectManifest(
      name: 'CS',
      maps: const [],
      tilesets: const [],
      settings: disabled(ability),
    );

void main() {
  for (final ability in FieldAbility.values) {
    test('${ability.name} activation is independent from saved unlocks', () {
      final state = obstacles.ready(ability);
      final settings = ability == FieldAbility.surf
          ? const ProjectSettings(surf: ProjectSurfSettings(enabled: false))
          : disabled(ability);
      final result = evaluateFieldAbilityGate(
        ability: ability,
        supportedAbilities: {ability},
        unlockedFieldAbilities:
            state.progression.unlockedFieldAbilities.toSet(),
        party: state.party,
        projectSettings: settings,
      );
      expect(result.status, FieldAbilityGateStatus.disabled);
      expect(state.progression.unlockedFieldAbilities, [ability]);
      expect(GameState.fromJson(state.toJson()), state);
    });
  }

  for (final kind in [
    FieldObstacleKind.cutTree,
    FieldObstacleKind.strengthBoulder,
    FieldObstacleKind.rockSmashRock
  ]) {
    final ability = MapEntityFieldObstacleData(kind: kind).ability!;
    test(
        '${ability.name} obstacle evaluation and confirmation refuse a disabled project',
        () {
      final map = obstacles.obstacleMap(kind), state = obstacles.ready(ability);
      expect(
          evaluateFieldObstacleAttempt(
              map: map,
              gameState: state,
              entityId: 'rock',
              projectSettings: disabled(ability)),
          isA<FieldObstacleUnavailable>().having(
              (e) => e.reason, 'reason', FieldObstacleBlockReason.disabled));
      final result = (ability == FieldAbility.strength
              ? commitStrengthActivation
              : commitDestructibleFieldObstacleAction)(
          ticket: obstacles.ticket(state, ability),
          map: map,
          gameState: state,
          currentStateRevision: 4,
          confirmedEntityId: 'rock',
          project: project(ability));
      expect(
          result,
          isA<FieldObstacleRefused>().having((e) => e.refusal, 'refusal',
              FieldActionRefusal.noLongerAvailable));
    });
  }

  test('Flash is refused before the prompt and rechecked at confirmation', () {
    final map = flash.darkMap(), state = flash.flashReady();
    expect(
        evaluateFlashAttempt(
            map: map,
            gameState: state,
            zoneId: map.gameplayZones.first.id,
            projectSettings: disabled(FieldAbility.flash)),
        isA<FlashUnavailable>()
            .having((e) => e.reason, 'reason', FlashBlockReason.disabled));
    expect(
        commitFlashAction(
            ticket: flash.flashTicket(state),
            map: map,
            gameState: state,
            currentStateRevision: 4,
            projectSettings: disabled(FieldAbility.flash)),
        isA<FlashRefused>());
  });

  test('Fly is refused before the prompt and rechecked at confirmation', () {
    final state = fly.readyForFly(),
        source = fly.sourceMap(),
        target = fly.targetMap(),
        catalog = fly.flyCatalog();
    final ready = evaluateFlyAttempt(
        sourceMap: source,
        sourceRole: MapRole.exterior,
        targetMap: target,
        gameState: state,
        catalog: catalog,
        pointId: 'town.poi') as CanUseFly;
    expect(
        evaluateFlyAttempt(
            sourceMap: source,
            sourceRole: MapRole.exterior,
            targetMap: target,
            gameState: state,
            catalog: catalog,
            pointId: 'town.poi',
            projectSettings: disabled(FieldAbility.fly)),
        isA<FlyUnavailable>()
            .having((e) => e.reason, 'reason', FlyBlockReason.disabled));
    expect(
        commitFlyAction(
            ticket: FlyActionTicket(
                evaluation: ready,
                gameState: state,
                sourceMap: source,
                targetMap: target,
                catalog: catalog,
                issuedAtStateRevision: 4),
            sourceMap: source,
            sourceRole: MapRole.exterior,
            targetMap: target,
            gameState: state,
            catalog: catalog,
            currentStateRevision: 4,
            projectSettings: disabled(FieldAbility.fly)),
        isA<FlyRefused>());
  });

  test('disabled Dive prevents entering but preserves a saved ascent', () {
    final source = dive.diveMap('sea', DiveZoneRole.surface),
        target = dive.diveMap('deep', DiveZoneRole.underwater);
    final state = dive.diveReady();
    expect(
        evaluateDiveAttempt(
            sourceMap: source,
            targetMap: target,
            gameState: state,
            zoneId: 'point',
            project: project(FieldAbility.dive)),
        isA<DiveUnavailable>()
            .having((e) => e.reason, 'reason', DiveBlockReason.disabled));
    final underwater = dive.diveReady(underwater: true);
    expect(
        evaluateDiveAttempt(
            sourceMap: target,
            targetMap: source,
            gameState: underwater,
            zoneId: 'point',
            project: project(FieldAbility.dive)),
        isA<CanUseDive>());
  });
  test('Waterfall checks activation during evaluation and ticket validation',
      () {
    final map = waterfall.waterfallMap(), state = waterfall.waterfallReady();
    expect(
        evaluateWaterfallAttempt(
            map: map,
            gameState: state,
            zoneId: 'fall',
            project: project(FieldAbility.waterfall)),
        isA<WaterfallUnavailable>()
            .having((e) => e.reason, 'reason', WaterfallBlockReason.disabled));
    final ticket = WaterfallActionTicket(
        fieldAction: FieldActionTicket(
            ability: FieldAbility.waterfall,
            targetCell: state.playerPosition,
            issuedAtStateRevision: 4),
        zone: map.gameplayZones.single,
        entryState: state,
        instance: null);
    expect(
        validateWaterfallTicket(
            ticket: ticket,
            map: map,
            gameState: state,
            currentStateRevision: 4,
            projectSettings: disabled(FieldAbility.waterfall)),
        FieldActionRefusal.noLongerAvailable);
  });

  test('Whirlpool checks activation during evaluation and ticket validation',
      () {
    final map = whirlpool.whirlpoolMap(), state = whirlpool.whirlpoolReady();
    expect(
        evaluateWhirlpoolAttempt(
            map: map,
            gameState: state,
            zoneId: map.gameplayZones.first.id,
            project: project(FieldAbility.whirlpool)),
        isA<WhirlpoolUnavailable>()
            .having((e) => e.reason, 'reason', WhirlpoolBlockReason.disabled));
    final ticket = WhirlpoolActionTicket(
        fieldAction: FieldActionTicket(
            ability: FieldAbility.whirlpool,
            targetCell: state.playerPosition,
            issuedAtStateRevision: 4),
        zone: map.gameplayZones.first,
        entryState: state,
        instance: null);
    expect(
        validateWhirlpoolTicket(
            ticket: ticket,
            map: map,
            gameState: state,
            currentStateRevision: 4,
            projectSettings: disabled(FieldAbility.whirlpool)),
        FieldActionRefusal.noLongerAvailable);
  });

  test('Dive ticket rechecks activation while a saved ascent remains valid',
      () {
    final surface = dive.diveMap('sea', DiveZoneRole.surface),
        underwater = dive.diveMap('deep', DiveZoneRole.underwater);
    for (final ascending in [false, true]) {
      final state = dive.diveReady(underwater: ascending);
      final source = ascending ? underwater : surface,
          target = ascending ? surface : underwater;
      final evaluation = evaluateDiveAttempt(
          sourceMap: source,
          targetMap: target,
          gameState: state,
          zoneId: 'point') as CanUseDive;
      final ticket = DiveActionTicket(
          evaluation: evaluation,
          gameState: state,
          sourceMap: source,
          targetMap: target,
          issuedAtStateRevision: 4);
      expect(
          validateDiveTicket(
              ticket: ticket,
              sourceMap: source,
              targetMap: target,
              gameState: state,
              currentStateRevision: 4,
              project: project(FieldAbility.dive)),
          ascending ? isNull : FieldActionRefusal.noLongerAvailable);
    }
  });

  test('legacy Cut entry point enforces the project policy too', () {
    final map = obstacles.obstacleMap(FieldObstacleKind.cutTree),
        state = obstacles.ready(FieldAbility.cut);
    expect(
        evaluateCutObstacleAttempt(
            map: map,
            gameState: state,
            entityId: 'rock',
            projectSettings: disabled(FieldAbility.cut)),
        isA<CutObstacleUnavailable>().having(
            (e) => e.reason, 'reason', CutObstacleBlockReason.disabled));
    final ticket = CutObstacleTicket(
        fieldAction: obstacles.ticket(state, FieldAbility.cut).fieldAction,
        instance: state.mapInstanceWorldState.instanceRef(map.id)!,
        entityId: 'rock',
        playerPosition: state.playerPosition,
        playerFacing: state.playerFacing);
    expect(
        commitCutObstacleAction(
            ticket: ticket,
            map: map,
            gameState: state,
            currentStateRevision: 4,
            confirmedEntityId: 'rock',
            projectSettings: disabled(FieldAbility.cut)),
        isA<CutObstacleRefused>());
  });

  test(
      'canUseFieldAbility respects activation while unlocked condition stays a save fact',
      () {
    final state = obstacles.ready(FieldAbility.dive),
        settings = disabled(FieldAbility.dive);
    expect(
        evaluateScenePartyCondition(
            source: SceneConditionSource.partyCanUseFieldAbility(
                ability: FieldAbility.dive),
            gameState: state,
            context: ScenePartyConditionContext(
                supportedFieldAbilities: [FieldAbility.dive],
                projectSettings: settings)),
        isFalse);
    expect(
        const ScriptConditionEvaluator().evaluate(
            const ScriptCondition(
                type: ScriptConditionType.fieldAbilityUnlocked,
                params: {'ability': 'dive'}),
            state),
        isTrue);
    expect(state.progression.unlockedFieldAbilities, [FieldAbility.dive]);
  });

  test('disabled Cut preserves a cleared obstacle across save and projection',
      () {
    final map = obstacles.obstacleMap(FieldObstacleKind.cutTree),
        state = obstacles.ready(FieldAbility.cut);
    final scope = state.mapInstanceWorldState.instanceRef(map.id)!;
    final saved = GameState.fromJson(state
        .copyWith(
            mapInstanceWorldState:
                state.mapInstanceWorldState.clearFieldObstacle(scope, 'rock'))
        .toJson());
    final projected = applyFieldObstacleWorldStateToMap(
        map: map,
        instances: saved.mapInstanceWorldState,
        instance: scope,
        project: project(FieldAbility.cut));
    expect(projected.entities, isEmpty);
    expect(saved.mapInstanceWorldState.isFieldObstacleCleared(scope, 'rock'),
        isTrue);
    expect(saved.progression.unlockedFieldAbilities, [FieldAbility.cut]);
  });

  test('disabled Strength preserves activation and moved positions across save',
      () {
    final map = obstacles.obstacleMap(FieldObstacleKind.strengthBoulder),
        state = obstacles.ready(FieldAbility.strength);
    final scope = state.mapInstanceWorldState.instanceRef(map.id)!;
    final saved = GameState.fromJson(state
        .copyWith(
            mapInstanceWorldState: state.mapInstanceWorldState
                .activateStrength(scope)
                .moveFieldObstacle(scope, 'rock', const GridPos(x: 3, y: 1)))
        .toJson());
    final projected = applyFieldObstacleWorldStateToMap(
        map: map,
        instances: saved.mapInstanceWorldState,
        instance: scope,
        project: project(FieldAbility.strength));
    expect(projected.entities.single.pos, const GridPos(x: 3, y: 1));
    expect(saved.mapInstanceWorldState.isStrengthActive(scope), isTrue);
    expect(
        evaluateFieldObstacleAttempt(
            map: projected,
            gameState:
                saved.copyWith(playerPosition: const GridPos(x: 2, y: 1)),
            entityId: 'rock',
            projectSettings: disabled(FieldAbility.strength)),
        isA<FieldObstacleUnavailable>().having(
            (e) => e.reason, 'reason', FieldObstacleBlockReason.disabled));
  });
}
