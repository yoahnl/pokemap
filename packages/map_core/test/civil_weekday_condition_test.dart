import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import 'periodic_reward_condition_reachability_test.dart'
    as fixtures
    show record;
import 'support/f1_runtime_catalog_fixture.dart';

void main() {
  test(
    'civil weekday conditions strictly roundtrip across all three contracts',
    () {
      for (final weekday in CivilWeekday.values) {
        for (final expected in [true, false]) {
          final scene = SceneConditionSource.civilWeekday(
            weekday: weekday,
            expectedValue: expected,
          );
          final event = NarrativeEventCondition.civilWeekday(
            weekday: weekday,
            expectedValue: expected,
          );
          final rule = WorldRuleSource.civilWeekday(
            weekday: weekday,
            expectedValue: expected,
          );
          expect(SceneConditionSource.fromJson(scene.toJson()), scene);
          expect(NarrativeEventCondition.fromJson(event.toJson()), event);
          expect(WorldRuleSource.fromJson(rule.toJson()), rule);
          for (final patch in <Map<String, dynamic>>[
            {'weekday': 'Friday'},
            {'weekday': 5},
            {'weekday': null},
            {'extra': true},
          ]) {
            expect(
              () =>
                  SceneConditionSource.fromJson({...scene.toJson(), ...patch}),
              throwsFormatException,
            );
            expect(
              () => NarrativeEventCondition.fromJson({
                ...event.toJson(),
                ...patch,
              }),
              throwsFormatException,
            );
            expect(
              () => WorldRuleSource.fromJson({...rule.toJson(), ...patch}),
              throwsFormatException,
            );
          }
        }
      }
    },
  );

  test('historical conditions keep their exact wire representation', () {
    final scene = {
      'sourceKind': 'factLikeStoryFlag',
      'sourceId': 'opened',
      'operator': 'isTrue',
    };
    final event = {'kind': 'fact', 'factId': 'opened', 'expectedValue': true};
    final rule = {'kind': 'fact', 'sourceId': 'opened', 'predicate': 'isTrue'};
    expect(SceneConditionSource.fromJson(scene).toJson(), scene);
    expect(NarrativeEventCondition.fromJson(event).toJson(), event);
    expect(WorldRuleSource.fromJson(rule).toJson(), rule);
    final old = ProjectManifest(
      name: 'Historical',
      version: ProjectVersion.v8,
      maps: const [],
      tilesets: const [],
    );
    expect(
      SpatialGameplayCapabilities.requiresCivilWeekdayCondition(
        ProjectManifest.fromJson(old.toJson()),
        maps: const [],
      ),
      isFalse,
    );
    for (final value in [scene, event, rule]) {
      expect(value.containsKey('weekday'), isFalse);
    }
    expect(
      () => SceneConditionSource.fromJson({...scene, 'weekday': 'friday'}),
      throwsFormatException,
    );
    expect(
      () => WorldRuleSource.fromJson({...rule, 'weekday': 'friday'}),
      throwsFormatException,
    );
  });

  test(
    'event dispatch and world projection consume civil weekdays without reward dependencies',
    () {
      final expression = NarrativeEventConditionExpression.leaf(
        NarrativeEventCondition.civilWeekday(
          weekday: CivilWeekday.friday,
          expectedValue: true,
        ),
      );
      final event = fixtures.record(expression: expression);
      final registry = NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [event],
        legacyClaims: const [],
      );
      final catalog = f1ProjectCatalogForRegistry(registry);
      final ready =
          NarrativeEventDispatchAuthority.prepare(
                registryResult: EventRegistryDecodeResult.decoded(registry),
                occurrence: NarrativeEventOccurrence(
                  source: NarrativeEventSourceRef.mapEnter('map'),
                ),
                factResolver: NarrativeFactRuntimeResolver.fromFacts(const []),
                projectCatalog: catalog,
                lookupRewardScenes: (_) =>
                    throw StateError('Weekdays do not read reward Scenes'),
              )
              as NarrativeEventDispatchAuthorityReady;
      final project = ProjectManifest(
        name: 'Calendar',
        maps: const [
          ProjectMapEntry(
            id: 'map',
            name: 'Map',
            relativePath: 'maps/map.json',
          ),
        ],
        tilesets: const [],
        worldRules: [
          WorldRuleDefinition(
            id: 'weekday',
            label: 'Weekday',
            source: WorldRuleSource.civilWeekday(
              weekday: CivilWeekday.friday,
              expectedValue: true,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'map',
              entityId: 'tree',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
        ],
      );
      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 4, height: 4),
        entities: [
          MapEntity(
            id: 'tree',
            kind: MapEntityKind.custom,
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      );
      for (final day in [null, '2026-11-06', '2026-11-07', '2026-11-13']) {
        final state = GameState(
          saveId: 'save',
          gameplayCalendarState: day == null
              ? const GameplayCalendarState.empty()
              : GameplayCalendarState(observedLocalDay: day, dayRevision: 1),
        );
        final friday = day == '2026-11-06' || day == '2026-11-13';
        final result = ready.plan(gameState: state);
        expect(result is NarrativeEventDispatchHandled, friday);
        expect(
          projectWorldRuleEffects(project, state, maps: [map]).isNotEmpty,
          friday,
        );
        final presentation = PresentationConditionContext(
          project: project,
          map: map,
        );
        expect(presentation.evaluate(expression, state).passed, friday);
      }
      final report = solveNarrativeSymbolicReachability(project, maps: [map]);
      expect(report.verdict, NarrativeSymbolicVerdict.indeterminate);
      expect(
        report.issues.any(
          (issue) =>
              issue.code == NarrativeSymbolicIssueCode.unsupportedCondition,
        ),
        isTrue,
      );
      expect(
        SpatialGameplayCapabilities.requiresCivilWeekdayCondition(
          project,
          maps: [map],
        ),
        isTrue,
      );
    },
  );

  test('civil calendar weekdays cover boundaries and unavailable negation', () {
    for (final entry in {
      '2026-11-06': CivilWeekday.friday,
      '2026-11-09': CivilWeekday.monday,
      '2024-02-29': CivilWeekday.thursday,
      '2027-01-01': CivilWeekday.friday,
    }.entries) {
      final calendar = GameplayCalendarState(
        observedLocalDay: entry.key,
        dayRevision: 1,
      );
      for (final weekday in CivilWeekday.values) {
        expect(
          evaluateCivilWeekdayCondition(
            weekday: weekday,
            expectedValue: true,
            calendar: calendar,
          ).passed,
          weekday == entry.value,
        );
        expect(
          evaluateCivilWeekdayCondition(
            weekday: weekday,
            expectedValue: false,
            calendar: calendar,
          ).passed,
          weekday != entry.value,
        );
      }
    }
    final unavailable = evaluateCivilWeekdayCondition(
      weekday: CivilWeekday.friday,
      expectedValue: false,
      calendar: const GameplayCalendarState.empty(),
    );
    expect(unavailable.unavailable, isTrue);
    expect(unavailable.passed, isFalse);
    final expression = NarrativeEventConditionExpression.not(
      NarrativeEventConditionExpression.leaf(
        NarrativeEventCondition.civilWeekday(
          weekday: CivilWeekday.friday,
          expectedValue: true,
        ),
      ),
    );
    expect(
      evaluateNarrativeConditionExpression(
        expression,
        evaluateLeaf: (_) => unavailable,
      ).passed,
      isFalse,
    );
  });
}
