import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart' show Direction;
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';

const _mapId = 'event_v2_entity_interaction_map';
const _legacyFlag = 'test.event_v2.entity.legacy_fallback';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Overworld interaction projection', () {
    test('consultation identifies the effective action without executing it',
        () async {
      final fixture = _entityFixtures.first;
      var preparations = 0;
      final game = _TestPlayableMapGame(
        bundle: _v2Bundle(fixture),
        projectFilePath: '/tmp/overworld_projection/project.json',
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind ==
              NarrativeEventSourceKind.entityInteract) {
            preparations++;
          }
        },
      );
      await _load(game);
      final state = game.gameStateSnapshot;
      final revision = game.debugGameStateRevision;
      final projection = game.overworldInteractionSnapshot;
      final action = projection.primaryAction!;
      expect(action.request.targetId, fixture.entity.id);
      expect(action.request.mapId, _mapId);
      expect(action.verb, RuntimeOverworldInteractionVerb.interact);
      expect(action.targetCell, fixture.entity.pos);
      for (var i = 0; i < 20; i++) {
        expect(game.overworldInteractionSnapshot, projection);
      }
      expect(game.debugGameStateRevision, revision);
      expect(game.gameStateSnapshot, state);
      expect(preparations, 0);
      expect(game.debugNotificationText, isNull);
    });

    test('targeted execution consumes exactly the projected Event V2 action',
        () async {
      final fixture = _entityFixtures.first;
      final game = _TestPlayableMapGame(
        bundle: _v2Bundle(fixture),
        projectFilePath: '/tmp/overworld_targeted/project.json',
      );
      await _load(game);
      final request = game.overworldInteractionSnapshot.primaryAction!.request;
      expect(game.dispatchOverworldInteraction(request), isTrue);
      expect(game.dispatchOverworldInteraction(request), isFalse);
      await _pumpUntil(
          game,
          () => game.gameStateSnapshot.narrativeEventProgress
              .consumedNarrativeEventIds
              .contains(fixture.eventId));
      expect(game.overworldInteractionSnapshot.primaryAction, isNull);
      expect(game.dispatchOverworldInteraction(request), isFalse);
      expect(game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_legacyFlag)));
    });

    test('a request from another live session is refused without effects',
        () async {
      final fixture = _entityFixtures.first;
      final first = _TestPlayableMapGame(
        bundle: _v2Bundle(fixture),
        projectFilePath: '/tmp/overworld_session_a/project.json',
      );
      final second = _TestPlayableMapGame(
        bundle: _v2Bundle(fixture),
        projectFilePath: '/tmp/overworld_session_b/project.json',
      );
      await _load(first);
      await _load(second);
      final request = first.overworldInteractionSnapshot.primaryAction!.request;
      expect(second.dispatchOverworldInteraction(request), isFalse);
      expect(second.debugIsNarrativeSpatialDispatchInFlight, isFalse);
      expect(
          second.gameStateSnapshot.narrativeEventProgress
              .consumedNarrativeEventIds,
          isEmpty);
    });

    test(
        'a blocking surface withdraws the action and refuses a captured request',
        () async {
      final game = _TestPlayableMapGame(
        bundle: _v2Bundle(_entityFixtures.first),
        projectFilePath: '/tmp/overworld_authority/project.json',
      );
      await _load(game);
      final request = game.overworldInteractionSnapshot.primaryAction!.request;
      game.setExternalInputLock(RuntimeExternalInputLock.pauseMenu,
          locked: true);
      expect(game.overworldInteractionSnapshot.primaryAction, isNull);
      expect(game.dispatchOverworldInteraction(request), isFalse);
      game.setExternalInputLock(RuntimeExternalInputLock.pauseMenu,
          locked: false);
      expect(game.overworldInteractionSnapshot.primaryAction, isNotNull);
    });

    test('an arbitrary scenario remains generic and is not run by consultation',
        () async {
      final fixture = _entityFixtures.first;
      final game = _TestPlayableMapGame(
        bundle: _legacyOnlyBundle(fixture.entity,
            scenarios: [_legacyScenario(fixture.entity.id)]),
        projectFilePath: '/tmp/overworld_scenario/project.json',
      );
      await _load(game);
      final action = game.overworldInteractionSnapshot.primaryAction!;
      expect(action.verb, RuntimeOverworldInteractionVerb.interact);
      expect(game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_legacyFlag)));
      expect(game.dispatchOverworldInteraction(action.request), isTrue);
      await _pumpUntil(
          game,
          () => game.gameStateSnapshot.storyFlags.activeFlags
              .contains(_legacyFlag));
    });

    test('claimed but ineligible entities do not advertise a fallback',
        () async {
      final game = _TestPlayableMapGame(
        bundle: _claimedIneligibleBundle(_entityFixtures.first),
        projectFilePath: '/tmp/overworld_ineligible/project.json',
      );
      await _load(game);
      expect(game.overworldInteractionSnapshot.primaryAction, isNull);
    });

    test(
        'turning away invalidates the request without sending primary elsewhere',
        () async {
      final game = _TestPlayableMapGame(
        bundle: _v2Bundle(_entityFixtures.first),
        projectFilePath: '/tmp/overworld_facing/project.json',
      );
      await _load(game);
      final request = game.overworldInteractionSnapshot.primaryAction!.request;
      game.debugSetPlayerStateForTest(
          position: const GridPos(x: 0, y: 0), facing: Direction.south);
      expect(game.dispatchOverworldInteraction(request), isFalse);
      expect(game.debugNotificationText, isNull);
      expect(
          game.gameStateSnapshot.narrativeEventProgress
              .consumedNarrativeEventIds,
          isEmpty);
    });

    test('a target lost during authority preparation never executes', () async {
      final started = Completer<void>();
      final release = Completer<void>();
      final game = _TestPlayableMapGame(
        bundle: _v2Bundle(_entityFixtures.first),
        projectFilePath: '/tmp/overworld_late_stale/project.json',
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind ==
              NarrativeEventSourceKind.entityInteract) {
            started.complete();
            await release.future;
          }
        },
      );
      await _load(game);
      final request = game.overworldInteractionSnapshot.primaryAction!.request;
      expect(game.dispatchOverworldInteraction(request), isTrue);
      await started.future;
      game.debugSetPlayerStateForTest(
          position: const GridPos(x: 0, y: 0), facing: Direction.south);
      release.complete();
      await _pumpUntil(
          game, () => !game.debugIsNarrativeSpatialDispatchInFlight);
      expect(
          game.gameStateSnapshot.narrativeEventProgress
              .consumedNarrativeEventIds,
          isEmpty);
      expect(game.gameStateSnapshot.storyFlags.activeFlags,
          isNot(contains(_legacyFlag)));
    });

    test('hidden items stay undisclosed while canonical primary still works',
        () async {
      final original = _entityFixtures[2];
      final fixture = _EntityFixture(
          entity: original.entity.copyWith(
              item: original.entity.item!
                  .copyWith(visibility: MapEntityItemVisibility.hidden)),
          eventId: original.eventId,
          sceneId: original.sceneId,
          factId: original.factId);
      final game = _TestPlayableMapGame(
          bundle: _v2Bundle(fixture),
          projectFilePath: '/tmp/overworld_hidden/project.json');
      await _load(game);
      expect(game.overworldInteractionSnapshot.primaryAction, isNull);
      expect(_pressPrimary(game), isTrue);
      await _pumpUntil(
          game,
          () => game.gameStateSnapshot.narrativeEventProgress
              .consumedNarrativeEventIds
              .contains(fixture.eventId));
    });

    test('unchanged frames do not publish and do not invalidate a request',
        () async {
      final game = _TestPlayableMapGame(
          bundle: _v2Bundle(_entityFixtures.first),
          projectFilePath: '/tmp/overworld_stable/project.json');
      await _load(game);
      final projection = game.overworldInteractionSnapshot;
      var publications = 0;
      game.overworldInteractions.addListener(() => publications++);
      await _pumpMicrotasks(game, ticks: 30);
      expect(game.overworldInteractionSnapshot, same(projection));
      expect(publications, 0);
      game.setExternalInputLock(RuntimeExternalInputLock.pauseMenu,
          locked: true);
      expect(publications, 1);
      game.setExternalInputLock(RuntimeExternalInputLock.pauseMenu,
          locked: false);
      expect(publications, 2);
      expect(
          game.dispatchOverworldInteraction(projection.primaryAction!.request),
          isTrue);
      await _pumpUntil(
          game, () => !game.debugIsNarrativeSpatialDispatchInFlight);
    });
  });

  group('Overworld interaction lifecycle and visibility', () {
    test('placed action keeps its footprint, stable projection and cooldown',
        () async {
      final bundle = _placedMessageBundle(MapPlacedElementTriggerType.onAction);
      final game = _TestPlayableMapGame(
          bundle: bundle,
          projectFilePath: '/tmp/overworld_placed/project.json');
      await _load(game);
      final projection = game.overworldInteractionSnapshot;
      final action = projection.primaryAction!;
      expect(action.request.targetKind,
          RuntimeOverworldInteractionTargetKind.placedElement);
      expect(action.verb, RuntimeOverworldInteractionVerb.read);
      expect(
          action.targetBounds.widthPx, bundle.manifest.settings.tileWidth * 2);
      expect(action.targetBounds.heightPx,
          bundle.manifest.settings.tileHeight * 2);
      var publications = 0;
      game.overworldInteractions.addListener(() => publications++);
      await _pumpMicrotasks(game, ticks: 20);
      expect(game.overworldInteractionSnapshot, same(projection));
      expect(publications, 0);
      expect(game.dispatchOverworldInteraction(action.request), isTrue);
      expect(game.debugNotificationText, _tileEventMessage);
      expect(game.overworldInteractionSnapshot.primaryAction, isNull);
      expect(game.dispatchOverworldInteraction(action.request), isFalse);
      await _pumpMicrotasks(game, ticks: 50);
      expect(game.overworldInteractionSnapshot.primaryAction, action);
    });

    test('an automatic placed trigger does not become a primary action',
        () async {
      final game = _TestPlayableMapGame(
          bundle: _placedMessageBundle(MapPlacedElementTriggerType.onEnter),
          projectFilePath: '/tmp/overworld_placed_automatic/project.json');
      await _load(game);
      expect(game.overworldInteractionSnapshot.primaryAction, isNull);
    });

    test('removing the runtime withdraws its observable action', () async {
      final game = _TestPlayableMapGame(
          bundle: _v2Bundle(_entityFixtures.first),
          projectFilePath: '/tmp/overworld_removed/project.json');
      await _load(game);
      var publications = 0;
      final observable = game.overworldInteractions;
      final request = observable.value.primaryAction!.request;
      observable.addListener(() => publications++);
      game.onRemove();
      expect(observable.value.primaryAction, isNull);
      expect(publications, 1);
      expect(game.dispatchOverworldInteraction(request), isFalse);
    });

    test('map scene preparation absorbs a repeated targeted or primary input',
        () async {
      final fixture = _entityFixtures.first;
      final event = _tileMessageEvent(const GridPos(x: 1, y: 0));
      final gate = NarrativeRuntimeActivityGate();
      final game = _TestPlayableMapGame(
          bundle: _bundle(
              entity: fixture.entity.copyWith(pos: const GridPos(x: 2, y: 1)),
              eventRegistry:
                  _legacyOnlyBundle(fixture.entity).manifest.eventRegistry!,
              facts: [
                NarrativeFactDefinition(
                    id: fixture.factId, label: fixture.factId)
              ],
              scenes: [
                _scene(fixture)
              ],
              events: [
                event.copyWith(pages: [
                  MapEventPage(
                      pageNumber: 0,
                      sceneTarget:
                          MapEventSceneTarget(sceneId: fixture.sceneId))
                ])
              ]),
          narrativeRuntimeActivityGate: gate,
          projectFilePath: '/tmp/overworld_map_scene/project.json');
      await _load(game);
      final action = game.overworldInteractionSnapshot.primaryAction!;
      expect(action.verb, RuntimeOverworldInteractionVerb.interact);
      expect(game.dispatchOverworldInteraction(action.request), isTrue);
      expect(gate.activity, NarrativeRuntimeActivity.sceneActive);
      expect(game.overworldInteractionSnapshot.primaryAction, isNull);
      expect(game.dispatchOverworldInteraction(action.request), isFalse);
      _pressPrimary(game);
      await _pumpUntil(
          game, () => gate.activity == NarrativeRuntimeActivity.idle);
      expect(
          game.gameStateSnapshot.narrativeFactRuntimeState
              .overridesByFactId[fixture.factId],
          isTrue);
      expect(game.debugNotificationText, isNot('Scene V1 impossible.'));
    });

    test('entity bounds preserve the existing collision footprint', () async {
      final entity = _entityFixtures.last.entity
          .copyWith(size: const GridSize(width: 2, height: 2));
      final bundle = _legacyOnlyBundle(entity);
      final game = _TestPlayableMapGame(
          bundle: bundle,
          projectFilePath: '/tmp/overworld_geometry/project.json');
      await _load(game);
      final action = game.overworldInteractionSnapshot.primaryAction!;
      final expected = resolveEntityCollisionRectPx(entity,
          tileWidthPx: bundle.manifest.settings.tileWidth,
          tileHeightPx: bundle.manifest.settings.tileHeight);
      expect(action.targetBounds.leftPx, expected.leftPx);
      expect(action.targetBounds.topPx, expected.topPx);
      expect(action.targetBounds.widthPx, expected.widthPx);
      expect(action.targetBounds.heightPx, expected.heightPx);
    });

    for (final hidden in [false, true]) {
      test(
          'map event hidden=$hidden keeps primary behavior and safe projection',
          () async {
        final event = _tileMessageEvent(const GridPos(x: 1, y: 0));
        final game = _TestPlayableMapGame(
          bundle: _legacyOnlyBundle(
              _entityFixtures.last.entity
                  .copyWith(pos: const GridPos(x: 2, y: 2)),
              events: [
                event.copyWith(
                    pages: [event.pages.single.copyWith(isHidden: hidden)])
              ]),
          projectFilePath: '/tmp/overworld_map_event/project.json',
        );
        await _load(game);
        final action = game.overworldInteractionSnapshot.primaryAction;
        if (hidden) {
          expect(action, isNull);
          expect(_pressPrimary(game), isTrue);
        } else {
          expect(action!.request.targetKind,
              RuntimeOverworldInteractionTargetKind.mapEvent);
          expect(action.verb, RuntimeOverworldInteractionVerb.read);
          expect(game.dispatchOverworldInteraction(action.request), isTrue);
        }
        expect(game.debugNotificationText, _tileEventMessage);
      });
    }

    test(
        'a save restore creates a new map activation and rejects the old request',
        () async {
      final gate = NarrativeRuntimeActivityGate();
      final repository = _CheckpointCountingRepository(gate);
      final game = _TestPlayableMapGame(
          bundle: _v2Bundle(_entityFixtures.first),
          projectFilePath: '/tmp/overworld_restore/project.json',
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository);
      await _load(game);
      final request = game.overworldInteractionSnapshot.primaryAction!.request;
      expect(await game.saveGame(), isTrue);
      expect(await game.loadGame(), isTrue);
      await _pumpUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
      expect(game.overworldInteractionSnapshot.mapActivationId,
          isNot(request.mapActivationId));
      expect(game.dispatchOverworldInteraction(request), isFalse);
      expect(
          game.gameStateSnapshot.narrativeEventProgress
              .consumedNarrativeEventIds,
          isEmpty);
    });
  });

  group('PlayableMapGame Event V2 entity interaction production hook', () {
    for (final fixture in _entityFixtures) {
      test(
        '${fixture.kind.name} executes its Scene once and suppresses legacy',
        () async {
          var nativeDialogueLoadCount = 0;
          final game = _TestPlayableMapGame(
            bundle: _v2Bundle(fixture),
            projectFilePath: '/tmp/event_v2_entity/project.json',
            dialogueSessionLoader: (_) async {
              nativeDialogueLoadCount++;
              return null;
            },
          );

          await _load(game);
          expect(_pressPrimary(game), isTrue);
          await _pumpUntil(
            game,
            () =>
                game.gameStateSnapshot.narrativeFactRuntimeState
                    .overridesByFactId[fixture.factId] ==
                true,
          );

          final state = game.gameStateSnapshot;
          expect(
            state.narrativeEventProgress.consumedNarrativeEventIds,
            contains(fixture.eventId),
            reason: 'The selected one-shot Event must be committed.',
          );
          expect(
            state.storyFlags.activeFlags,
            isNot(contains(_legacyFlag)),
            reason: 'A V2-handled occurrence must not run Scenario fallback.',
          );
          expect(
            nativeDialogueLoadCount,
            0,
            reason: 'NPC/sign native dialogue fallback must stay suppressed.',
          );
          expect(
            game.debugNotificationText,
            isNull,
            reason: 'Item/custom native feedback must stay suppressed.',
          );
        },
      );
    }

    test('spawn entities never create an entityInteract occurrence', () async {
      var entityAuthorityPreparationCount = 0;
      final game = _TestPlayableMapGame(
        bundle: _spawnExclusionBundle(),
        projectFilePath: '/tmp/event_v2_spawn_exclusion/project.json',
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind ==
              NarrativeEventSourceKind.entityInteract) {
            entityAuthorityPreparationCount++;
          }
        },
      );

      await _load(game);
      expect(_pressPrimary(game), isTrue);
      await _pumpMicrotasks(game);

      expect(entityAuthorityPreparationCount, 0);
    });

    test('legacyOnly noMatch keeps the matching Scenario fallback', () async {
      final fixture = _entityFixtures.first;
      final game = _TestPlayableMapGame(
        bundle: _legacyOnlyBundle(
          fixture.entity,
          scenarios: <ScenarioAsset>[_legacyScenario(fixture.entity.id)],
        ),
        projectFilePath: '/tmp/event_v2_legacy_scenario/project.json',
      );

      await _load(game);
      expect(_pressPrimary(game), isTrue);
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.storyFlags.activeFlags.contains(_legacyFlag),
      );

      expect(
        game.gameStateSnapshot.storyFlags.activeFlags,
        contains(_legacyFlag),
      );
    });

    test(
        'a Scenario that claims the entity suppresses the map event on its tile',
        () async {
      final fixture = _entityFixtures.first;
      final game = _TestPlayableMapGame(
        bundle: _legacyOnlyBundle(
          fixture.entity,
          scenarios: <ScenarioAsset>[_legacyScenario(fixture.entity.id)],
          events: <MapEventDefinition>[_tileMessageEvent(fixture.entity.pos)],
        ),
        projectFilePath: '/tmp/event_v2_priority_claimed/project.json',
      );

      await _load(game);
      expect(_pressPrimary(game), isTrue);
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.storyFlags.activeFlags.contains(_legacyFlag),
      );

      expect(
        game.debugNotificationText,
        isNot(_tileEventMessage),
        reason: 'a claimed entity interaction must not also fire its map event',
      );
    });

    test('an unclaimed generic entity still falls back to its map event',
        () async {
      const entity = MapEntity(
        id: 'custom_priority_fallback',
        name: 'Unclaimed custom entity',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 1, y: 0),
      );
      final game = _TestPlayableMapGame(
        bundle: _legacyOnlyBundle(
          entity,
          events: <MapEventDefinition>[_tileMessageEvent(entity.pos)],
        ),
        projectFilePath: '/tmp/event_v2_priority_unclaimed/project.json',
      );

      await _load(game);
      expect(_pressPrimary(game), isTrue);
      await _pumpUntil(
        game,
        () => game.debugNotificationText == _tileEventMessage,
      );

      expect(game.debugNotificationText, _tileEventMessage);
    });

    test('an unclaimed npc never falls back to the map event on its tile',
        () async {
      const npc = MapEntity(
        id: 'npc_priority_fallback',
        name: 'Unclaimed npc',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 1, y: 0),
      );
      final game = _TestPlayableMapGame(
        bundle: _legacyOnlyBundle(
          npc,
          events: <MapEventDefinition>[_tileMessageEvent(npc.pos)],
        ),
        projectFilePath: '/tmp/event_v2_priority_npc/project.json',
      );

      await _load(game);
      expect(_pressPrimary(game), isTrue);
      await _pumpMicrotasks(game, ticks: 60);

      expect(
        game.debugNotificationText,
        isNot(_tileEventMessage),
        reason: 'only a generic entity yields the tile event, never an npc',
      );
    });

    test('legacyOnly noMatch keeps native entity fallback', () async {
      const entity = MapEntity(
        id: 'custom_native_fallback',
        name: 'Native custom fallback',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 1, y: 0),
      );
      final game = _TestPlayableMapGame(
        bundle: _legacyOnlyBundle(entity),
        projectFilePath: '/tmp/event_v2_legacy_native/project.json',
      );

      await _load(game);
      expect(_pressPrimary(game), isTrue);
      await _pumpUntil(
        game,
        () => game.debugNotificationText == entity.name,
      );

      expect(game.debugNotificationText, entity.name);
    });

    test('dualRead claimed-ineligible occurrence suppresses all fallback',
        () async {
      final fixture = _entityFixtures.first;
      final game = _TestPlayableMapGame(
        bundle: _claimedIneligibleBundle(fixture),
        projectFilePath: '/tmp/event_v2_claimed_ineligible/project.json',
      );

      await _load(game);
      expect(_pressPrimary(game), isTrue);
      await _pumpMicrotasks(game);

      final state = game.gameStateSnapshot;
      expect(
        state.storyFlags.activeFlags,
        isNot(contains(_legacyFlag)),
        reason: 'A validated claim owns the occurrence even when disabled.',
      );
      expect(
        state.narrativeFactRuntimeState.overridesByFactId[fixture.factId],
        isNot(true),
      );
      expect(
        state.narrativeEventProgress.consumedNarrativeEventIds,
        isNot(contains(fixture.eventId)),
      );
      expect(game.debugNotificationText, isNull);
    });

    test('a second input during async authority preparation launches once',
        () async {
      final fixture = _entityFixtures.first;
      final preparationStarted = Completer<void>();
      final releasePreparation = Completer<void>();
      var entityAuthorityPreparationCount = 0;
      final gate = NarrativeRuntimeActivityGate();
      final repository = _CheckpointCountingRepository(gate);
      final game = _TestPlayableMapGame(
        bundle: _v2Bundle(fixture),
        projectFilePath: '/tmp/event_v2_entity_interlock/project.json',
        narrativeRuntimeActivityGate: gate,
        saveRepository: repository,
        beforeNarrativeAuthorityPreparation: (occurrence) async {
          if (occurrence.source.kind !=
              NarrativeEventSourceKind.entityInteract) {
            return;
          }
          entityAuthorityPreparationCount++;
          if (!preparationStarted.isCompleted) {
            preparationStarted.complete();
          }
          await releasePreparation.future;
        },
      );

      await _load(game);
      expect(_pressPrimary(game), isTrue);
      await preparationStarted.future;

      expect(gate.activity, NarrativeRuntimeActivity.dispatching);
      expect(await game.saveGame(), isFalse);
      expect(await game.loadGame(), isFalse);
      expect(repository.saveCount, 0);
      expect(repository.loadCount, 0);

      expect(_pressPrimary(game), isTrue);
      await _pumpMicrotasks(game);
      expect(
        entityAuthorityPreparationCount,
        1,
        reason: 'The in-flight spatial dispatch must absorb duplicate input.',
      );

      releasePreparation.complete();
      await _pumpUntil(
        game,
        () =>
            game.gameStateSnapshot.narrativeFactRuntimeState
                .overridesByFactId[fixture.factId] ==
            true,
      );

      expect(entityAuthorityPreparationCount, 1);
      expect(
        game.gameStateSnapshot.narrativeEventProgress.consumedNarrativeEventIds,
        contains(fixture.eventId),
      );
      expect(gate.activity, NarrativeRuntimeActivity.idle);
      expect(await game.saveGame(), isTrue);
      expect(repository.saveCount, 1);
    });

    test(
      'entity outcome retry stays pending without escaping its detached task',
      () async {
        final fixture = _entityFixtures.first;
        final gate = NarrativeRuntimeActivityGate();
        final repository = _CheckpointCountingRepository(gate);
        var outcomePreparationCount = 0;
        final game = _TestPlayableMapGame(
          bundle: _retryOutcomeBundle(fixture),
          projectFilePath: '/tmp/event_v2_entity_retry/project.json',
          narrativeRuntimeActivityGate: gate,
          saveRepository: repository,
          beforeNarrativeAuthorityPreparation: (occurrence) async {
            if (occurrence.source.kind !=
                NarrativeEventSourceKind.outcomeReceived) {
              return;
            }
            outcomePreparationCount++;
            throw StateError(
              'retryable entity outcome infrastructure failure',
            );
          },
        );

        await _load(game);
        final uncaughtErrors = await _captureDetachedErrors(() async {
          expect(_pressPrimary(game), isTrue);
          await _pumpUntil(
            game,
            () =>
                !game.debugIsNarrativeSpatialDispatchInFlight &&
                !game.debugIsNarrativeOutcomeWorkInFlight &&
                game.gameStateSnapshot.narrativeEventProgress
                    .pendingNarrativeOutcomeDeliveries.isNotEmpty,
          );
          await Future<void>.delayed(Duration.zero);
        });

        final state = game.gameStateSnapshot;
        final pending =
            state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries;
        expect(uncaughtErrors, isEmpty);
        expect(outcomePreparationCount, 1);
        expect(pending, hasLength(1));
        expect(pending.single.outcome.outcomeId, _entityRetryOutcomeId);
        expect(pending.single.attemptCount, 1);
        expect(
          state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
          isEmpty,
        );
        expect(
          state.narrativeEventProgress.consumedNarrativeEventIds,
          contains(fixture.eventId),
        );
        expect(game.debugIsNarrativeSpatialDispatchInFlight, isFalse);
        expect(game.debugIsNarrativeOutcomeWorkInFlight, isFalse);
        expect(game.debugIsGameplayInputLocked, isFalse);
        expect(gate.activity, NarrativeRuntimeActivity.idle);
        expect(await game.saveGame(), isTrue);
        expect(repository.saveCount, 1);
        expect(
          repository.storedState!.narrativeEventProgress
              .pendingNarrativeOutcomeDeliveries.single.attemptCount,
          1,
        );
      },
    );
  });
}

Future<List<Object>> _captureDetachedErrors(
  Future<void> Function() body,
) async {
  final errors = <Object>[];
  final bodyCompleted = Completer<void>();
  runZonedGuarded(
    () {
      body().then<void>(
        (_) => bodyCompleted.complete(),
        onError: (Object error, StackTrace stackTrace) {
          bodyCompleted.completeError(error, stackTrace);
        },
      );
    },
    (error, _) => errors.add(error),
  );
  await bodyCompleted.future;
  return errors;
}

final class _TestPlayableMapGame extends PlayableMapGame {
  _TestPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    super.dialogueSessionLoader,
    super.beforeNarrativeAuthorityPreparation,
    super.narrativeRuntimeActivityGate,
    super.saveRepository,
  });

  @override
  bool get isLoaded => true;
}

final class _CheckpointCountingRepository implements GameSaveRepository {
  _CheckpointCountingRepository(this.gate);

  final NarrativeRuntimeActivityGate gate;
  GameState? storedState;
  int saveCount = 0;
  int loadCount = 0;

  @override
  Future<void> save(GameState state) {
    return gate.runCheckpoint(
      NarrativeRuntimeCheckpointOperation.save,
      () async {
        saveCount++;
        storedState = state;
      },
    );
  }

  @override
  Future<GameState?> load() {
    return gate.runCheckpoint(
      NarrativeRuntimeCheckpointOperation.load,
      () async {
        loadCount++;
        return storedState;
      },
    );
  }

  @override
  Future<bool> exists() async => storedState != null;

  @override
  Future<void> delete() async {
    storedState = null;
  }
}

final class _EntityFixture {
  const _EntityFixture({
    required this.entity,
    required this.eventId,
    required this.sceneId,
    required this.factId,
  });

  final MapEntity entity;
  final String eventId;
  final String sceneId;
  final String factId;

  MapEntityKind get kind => entity.kind;
}

const _entityFixtures = <_EntityFixture>[
  _EntityFixture(
    entity: MapEntity(
      id: 'npc_v2',
      name: 'NPC V2',
      kind: MapEntityKind.npc,
      pos: GridPos(x: 1, y: 0),
      npc: MapEntityNpcData(
        displayName: 'NPC native fallback',
        dialogue: DialogueRef(dialogueId: 'native_dialogue'),
      ),
    ),
    eventId: 'evt_019abcde-2000-7000-8000-000000000001',
    sceneId: 'scene_entity_npc_v2',
    factId: 'fact.event_v2.entity.npc',
  ),
  _EntityFixture(
    entity: MapEntity(
      id: 'sign_v2',
      name: 'Sign V2',
      kind: MapEntityKind.sign,
      pos: GridPos(x: 1, y: 0),
      sign: MapEntitySignData(
        title: 'Sign native fallback',
        dialogue: DialogueRef(dialogueId: 'native_dialogue'),
      ),
    ),
    eventId: 'evt_019abcde-2000-7000-8000-000000000002',
    sceneId: 'scene_entity_sign_v2',
    factId: 'fact.event_v2.entity.sign',
  ),
  _EntityFixture(
    entity: MapEntity(
      id: 'item_v2',
      name: 'Item native fallback',
      kind: MapEntityKind.item,
      pos: GridPos(x: 1, y: 0),
      item: MapEntityItemData(gameItemId: 'item_native_fallback'),
    ),
    eventId: 'evt_019abcde-2000-7000-8000-000000000003',
    sceneId: 'scene_entity_item_v2',
    factId: 'fact.event_v2.entity.item',
  ),
  _EntityFixture(
    entity: MapEntity(
      id: 'custom_v2',
      name: 'Custom native fallback',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 1, y: 0),
    ),
    eventId: 'evt_019abcde-2000-7000-8000-000000000004',
    sceneId: 'scene_entity_custom_v2',
    factId: 'fact.event_v2.entity.custom',
  ),
];

const _entityRetryOutcomeId = 'entity.retry';

RuntimeMapBundle _v2Bundle(_EntityFixture fixture) {
  final source = NarrativeEventSourceRef.entityInteract(
    _mapId,
    fixture.entity.id,
  );
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      _eventRecord(fixture, source: source, enabled: true),
    ],
    legacyClaims: const <LegacySourceClaim>[],
  );
  return _bundle(
    entity: fixture.entity,
    eventRegistry: registry,
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(id: fixture.factId, label: fixture.factId),
    ],
    scenes: <SceneAsset>[_scene(fixture)],
    scenarios: <ScenarioAsset>[_legacyScenario(fixture.entity.id)],
  );
}

RuntimeMapBundle _retryOutcomeBundle(_EntityFixture fixture) {
  final source = NarrativeEventSourceRef.entityInteract(
    _mapId,
    fixture.entity.id,
  );
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: <NarrativeEventRecord>[
      _eventRecord(fixture, source: source, enabled: true),
    ],
    legacyClaims: const <LegacySourceClaim>[],
  );
  return _bundle(
    entity: fixture.entity,
    eventRegistry: registry,
    scenes: <SceneAsset>[_outcomeScene(fixture)],
  );
}

RuntimeMapBundle _claimedIneligibleBundle(_EntityFixture fixture) {
  final source = NarrativeEventSourceRef.entityInteract(
    _mapId,
    fixture.entity.id,
  );
  final scenario = _legacyScenario(fixture.entity.id);
  final provenance = LegacySourceRef.scenarioSourceNode(
    scenario.id,
    'source',
  );
  final member = LegacySourceClaimMember(
    provenance: provenance,
    sourceFingerprint: computeScenarioSourceFingerprint(
      scenarioId: scenario.id,
      nodeId: 'source',
      scenario: scenario,
    ),
  );
  final cohortId = computeLegacySourceCohortId(source, <LegacySourceRef>[
    provenance,
  ]);
  final claim = LegacySourceClaim(
    cohortId: cohortId,
    source: source,
    members: <LegacySourceClaimMember>[member],
    cohortFingerprint: computeLegacySourceCohortFingerprint(
      cohortId,
      <LegacySourceClaimMember>[member],
    ),
    targetEventIds: <String>[fixture.eventId],
    migrationReceiptId: 'receipt-entity-claimed-ineligible',
  );
  final registry = NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.dualRead,
    records: <NarrativeEventRecord>[
      _eventRecord(fixture, source: source, enabled: false),
    ],
    legacyClaims: <LegacySourceClaim>[claim],
  );
  return _bundle(
    entity: fixture.entity,
    eventRegistry: registry,
    facts: <NarrativeFactDefinition>[
      NarrativeFactDefinition(id: fixture.factId, label: fixture.factId),
    ],
    scenes: <SceneAsset>[_scene(fixture)],
    scenarios: <ScenarioAsset>[scenario],
  );
}

RuntimeMapBundle _legacyOnlyBundle(
  MapEntity entity, {
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
  List<MapEventDefinition> events = const <MapEventDefinition>[],
}) {
  return _bundle(
    entity: entity,
    events: events,
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.legacyOnly,
      records: const <NarrativeEventRecord>[],
      legacyClaims: const <LegacySourceClaim>[],
    ),
    scenarios: scenarios,
  );
}

RuntimeMapBundle _spawnExclusionBundle() {
  const spawnTarget = MapEntity(
    id: 'spawn_event_target',
    name: 'Excluded spawn',
    kind: MapEntityKind.spawn,
    pos: GridPos(x: 1, y: 0),
    blocksMovement: false,
    spawn: MapEntitySpawnData(role: EntitySpawnRole.event),
  );
  return _bundle(
    entity: spawnTarget,
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: const <NarrativeEventRecord>[],
      legacyClaims: const <LegacySourceClaim>[],
    ),
  );
}

RuntimeMapBundle _placedMessageBundle(MapPlacedElementTriggerType trigger) {
  final base = _legacyOnlyBundle(
      _entityFixtures.last.entity.copyWith(pos: const GridPos(x: 2, y: 1)));
  return RuntimeMapBundle(
    manifest: base.manifest.copyWith(elements: const [
      ProjectElementEntry(
          id: 'notice',
          name: 'Notice',
          tilesetId: 'missing',
          categoryId: 'objects',
          frames: [
            TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2))
          ])
    ]),
    map: base.map.copyWith(entities: [
      base.map.entities.first
    ], placedElements: [
      MapPlacedElement(
          id: 'notice-instance',
          layerId: 'objects',
          elementId: 'notice',
          pos: const GridPos(x: 1, y: 0),
          applyCollision: false,
          behaviors: [
            MapPlacedElementBehavior(
                id: 'read',
                trigger: trigger,
                effect: const MapPlacedElementEffect(
                    type: MapPlacedElementEffectType.showMessage,
                    message: _tileEventMessage))
          ])
    ]),
    projectRootDirectory: base.projectRootDirectory,
    tilesetAbsolutePathsById: base.tilesetAbsolutePathsById,
  );
}

RuntimeMapBundle _bundle({
  required MapEntity entity,
  required NarrativeEventRegistry eventRegistry,
  List<NarrativeFactDefinition> facts = const <NarrativeFactDefinition>[],
  List<SceneAsset> scenes = const <SceneAsset>[],
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
  List<MapEventDefinition> events = const <MapEventDefinition>[],
}) {
  final project = ProjectManifest(
    name: 'Event V2 entity interaction integration',
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: _mapId,
        name: 'Event V2 Entity Map',
        relativePath: 'maps/event_v2_entity.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[],
    dialogues: const <ProjectDialogueEntry>[
      ProjectDialogueEntry(
        id: 'native_dialogue',
        name: 'Native fallback dialogue',
        relativePath: 'dialogues/native.yarn',
      ),
    ],
    facts: facts,
    scenes: scenes,
    scenarios: scenarios,
    eventRegistry: eventRegistry,
  );
  return RuntimeMapBundle(
    manifest: project,
    map: _map(entity, events: events),
    projectRootDirectory: '/tmp/event_v2_entity',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

MapData _map(
  MapEntity entity, {
  List<MapEventDefinition> events = const <MapEventDefinition>[],
}) =>
    MapData(
      id: _mapId,
      name: 'Event V2 Entity Map',
      size: const GridSize(width: 3, height: 2),
      layers: const <MapLayer>[
        MapLayer.object(id: 'objects', name: 'Objects'),
      ],
      entities: <MapEntity>[
        const MapEntity(
          id: 'spawn_start',
          name: 'Player start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.east,
          ),
        ),
        entity,
      ],
      events: events,
      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn_start'),
    );

const _tileEventMessage = 'tile map event fired';

MapEventDefinition _tileMessageEvent(GridPos pos) => MapEventDefinition(
      id: 'tile_priority_event',
      title: 'Tile priority event',
      position: EventPosition(layerId: 'objects', x: pos.x, y: pos.y),
      pages: const <MapEventPage>[
        MapEventPage(pageNumber: 0, message: _tileEventMessage),
      ],
    );

NarrativeEventRecord _eventRecord(
  _EntityFixture fixture, {
  required NarrativeEventSourceRef source,
  required bool enabled,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: fixture.eventId,
      name: 'Entity Event ${fixture.kind.name}',
      source: source,
      conditions: const <NarrativeEventCondition>[],
      sceneId: fixture.sceneId,
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: 0,
      order: 0,
    ),
    enabled: enabled,
  );
}

SceneAsset _scene(_EntityFixture fixture) {
  return SceneAsset(
    id: fixture.sceneId,
    name: 'Entity Scene ${fixture.kind.name}',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'set_fact',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(factId: fixture.factId, value: true),
          ),
        ),
        SceneNode(id: 'end', kind: SceneNodeKind.end),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_fact',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'set_fact',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'fact_to_end',
          fromNodeId: 'set_fact',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.actionCompleted,
        ),
      ],
    ),
  );
}

SceneAsset _outcomeScene(_EntityFixture fixture) {
  return SceneAsset(
    id: fixture.sceneId,
    name: 'Entity retry Scene ${fixture.kind.name}',
    declaredOutcomes: <SceneOutcome>[
      SceneOutcome(id: _entityRetryOutcomeId, label: 'Entity retry'),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: <SceneNode>[
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: _entityRetryOutcomeId),
        ),
      ],
      edges: <SceneEdge>[
        SceneEdge(
          id: 'start_to_end',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'end',
          kind: SceneEdgeKind.defaultFlow,
        ),
      ],
    ),
  );
}

ScenarioAsset _legacyScenario(String entityId) {
  return ScenarioAsset(
    id: 'legacy_entity_$entityId',
    name: 'Legacy entity fallback',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'source',
    nodes: <ScenarioNode>[
      ScenarioNode(
        id: 'source',
        type: ScenarioNodeType.reference,
        payload: const ScenarioNodePayload(
          actionKind: kScenarioSourceEntityInteract,
        ),
        binding: ScenarioNodeBinding(mapId: _mapId, entityId: entityId),
      ),
      const ScenarioNode(
        id: 'set_legacy_flag',
        type: ScenarioNodeType.action,
        payload: ScenarioNodePayload(actionKind: kScenarioActionSetFlag),
        binding: ScenarioNodeBinding(flagName: _legacyFlag),
      ),
      const ScenarioNode(id: 'end', type: ScenarioNodeType.end),
    ],
    edges: const <ScenarioEdge>[
      ScenarioEdge(
        id: 'source_to_flag',
        fromNodeId: 'source',
        toNodeId: 'set_legacy_flag',
      ),
      ScenarioEdge(
        id: 'flag_to_end',
        fromNodeId: 'set_legacy_flag',
        toNodeId: 'end',
      ),
    ],
  );
}

Future<void> _load(PlayableMapGame game) async {
  game.onGameResize(Vector2(320, 240));
  await game.onLoad();
  await _pumpUntil(game, () => !game.debugIsMapActivationDispatchInFlight);
}

bool _pressPrimary(PlayableMapGame game) {
  return game.handleRuntimeInputEvent(
    const RuntimeInputEvent.press(RuntimeInputControl.primary),
  );
}

Future<void> _pumpMicrotasks(PlayableMapGame game, {int ticks = 12}) async {
  for (var i = 0; i < ticks; i++) {
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
}

Future<void> _pumpUntil(
  PlayableMapGame game,
  bool Function() done, {
  int maxTicks = 240,
}) async {
  for (var i = 0; i < maxTicks; i++) {
    if (done()) {
      return;
    }
    game.update(0.016);
    await Future<void>.delayed(Duration.zero);
  }
  fail('Timed out waiting for the Event V2 entity interaction runtime.');
}
