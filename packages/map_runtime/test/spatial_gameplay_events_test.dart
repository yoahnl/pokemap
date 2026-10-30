import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/map_activation.dart';
import 'package:map_runtime/src/application/story_flags_manager.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:map_runtime/src/application/narrative_spatial_production_dispatch_bridge.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_runtime_host_callbacks.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_consequence_runtime_writer.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/spatial/spatial_gameplay_events.dart';
import 'package:map_runtime/src/spatial/spatial_model_interaction_index.dart';

void main() {
  test('already defeated boss keeps its authored missing reward Scene without a new battle', () async {
    final entity = MapEntity(id: 'trainer', kind: MapEntityKind.npc, pos: const GridPos(x: 2, y: 3), npc: const MapEntityNpcData(trainerId: 'coach', defeatDialogueRef: DialogueRef(dialogueId: 'talk')));
    final map = _map(entities: [entity]);
    final project = _project(map, records: [_event(10002, NarrativeEventSourceRef.entityInteract(map.id, entity.id), 'missing-reward')], scenes: [_scene('missing-reward', [SceneConsequence.giveItem(itemId: 'item_ct51', quantity: 1)])]).copyWith(trainers: const [ProjectTrainerEntry(id: 'coach', name: 'Coach', trainerClass: 'leader')]);
    var fights = 0, fallbackDialogues = 0;
    final host = await _Host.create(project, map, showEntityDialogue: (_, dialogue) async { fallbackDialogues++; }, createSceneCallbacks: (read, commit) => SceneRuntimeHostCallbacks(evaluateCondition: (_) => 'true', showDialogue: (_) => 'completed', startBattle: (_) { fights++; return 'victory'; }, playCinematic: (_) => 'completed'));
    host.state = const StoryFlagsManager().markTrainerDefeated(host.state, 'coach');
    await host.events.activateMap(_activation('reward-retry'));
    await host.events.interact();
    expect(host.state.bag.entries.single.itemId, 'item_ct51');
    expect(host.state.bag.entries.single.quantity, 1);
    expect(fights, 0);
    expect(fallbackDialogues, 0);
    await host.events.interact();
    expect(host.state.bag.entries.single.quantity, 1);
    expect(fights, 0);
    expect(fallbackDialogues, 1);
  });

  test('manual trainer interaction applies readiness lifecycle and badge guards before EventV2', () async {
    final entity = MapEntity(id: 'trainer', kind: MapEntityKind.npc, pos: const GridPos(x: 2, y: 3), npc: const MapEntityNpcData(trainerId: 'coach', dialogue: DialogueRef(dialogueId: 'talk'), defeatDialogueRef: DialogueRef(dialogueId: 'talk'), trainerBattleWhen: MapEntityRuntimePredicate(kind: MapEntityRuntimePredicateKind.badgeNotOwned, refId: 'hive'), trainerBattleReadyWhen: MapEntityRuntimePredicate(kind: MapEntityRuntimePredicateKind.partyUsableCountAtLeast, minimumCount: 2), trainerBattleNotReadyDialogue: DialogueRef(dialogueId: 'talk')));
    final map = _map(entities: [entity]);
    final event = _event(10001, NarrativeEventSourceRef.entityInteract(map.id, entity.id), 'battle');
    final project = _project(map, records: [event], scenes: [_battleScene()]).copyWith(trainers: const [ProjectTrainerEntry(id: 'coach', name: 'Coach', trainerClass: 'youngster')], badges: const [BadgeDefinition(id: 'hive', label: 'Hive')]);
    var fights = 0;
    final shown = <String?>[];
    final host = await _Host.create(project, map, showEntityDialogue: (_, dialogue) async => shown.add(dialogue.dialogueId), createSceneCallbacks: (read, commit) => SceneRuntimeHostCallbacks(evaluateCondition: (_) => 'true', showDialogue: (_) => 'completed', startBattle: (_) { fights++; return 'victory'; }, playCinematic: (_) => 'completed'));
    PlayerPokemon member(String id, {int hp = 10}) => PlayerPokemon(individualId: id, speciesId: 'bird', formId: 'bronze', natureId: 'hardy', abilityId: 'natural', currentHp: hp);
    host.state = host.state.copyWith(party: PlayerParty(members: [member('one'), member('fainted', hp: 0)]));
    await host.events.activateMap(_activation('readiness'));
    expect(host.events.canSpotTrainer(entity), isFalse);
    final original = host.state;
    await host.events.interact();
    expect(fights, 0);
    expect(shown, ['talk']);
    expect(host.state, original);
    host.state = host.state.copyWith(party: PlayerParty(members: [member('one'), member('two')]));
    expect(host.events.canSpotTrainer(entity), isTrue);
    await host.events.interact();
    expect(fights, 1);
    host.state = const StoryFlagsManager().markTrainerDefeated(host.state, 'coach');
    expect(host.events.canSpotTrainer(entity), isFalse);
    await host.events.interact();
    expect(fights, 1);
    expect(shown, ['talk', 'talk']);
    host.state = host.state.copyWith(storyFlags: const StoryFlags(), trainerProfile: host.state.trainerProfile.copyWith(badgeIds: ['hive']));
    expect(host.events.canSpotTrainer(entity), isFalse);
    await host.events.interact();
    expect(fights, 1);
    expect(shown, ['talk', 'talk', 'talk']);
  });

  test('collected bound model cannot become a ghost interaction target', () async {
    final item = MapEntity(id: 'native-item', kind: MapEntityKind.item, pos: const GridPos(x: 2, y: 3), item: const MapEntityItemData(gameItemId: 'resource'));
    final model = ProjectModel3dEntry(id: 'orb', name: 'Orb', sourceAssetId: 'orb-source', relativePath: 'assets/models3d/orb.glb',
      inspection: Model3dInspection(bounds: Model3dBounds(min: Model3dVector3(x: -.1, y: 0, z: -.1), max: Model3dVector3(x: .1, y: 1, z: .1)), meshCount: 1, triangleCount: 1));
    final raw = _map(entities: [item]);
    final map = raw.copyWith(spatialScene: raw.spatialScene!.copyWith(instances: [SpatialModelInstance(id: 'orb-instance', modelId: model.id, entityId: item.id, position: Model3dVector3(x: 2.5, y: 0, z: 3.5))]));
    final project = _project(map, records: [_event(999, NarrativeEventSourceRef.modelInteract(map.id, 'orb-instance'), 'ghost')], scenes: [_scene('ghost', [SceneConsequence.giveMoney(amount: 7)])]).copyWith(models3d: [model]);
    final host = await _Host.create(project, map);
    await host.events.activateMap(_activation('ghost'));
    expect(host.events.interactionTarget?.id, item.id);
    await host.events.interact();
    expect(host.events.entityIsPresent(map.id, item), isFalse);
    expect(host.events.interactionTarget, isNull);
    expect(host.events.modelInteractionTarget, isNull);
  });

  for (final unrelatedCount in [10, 1000]) {
    test('model interaction index visits $unrelatedCount records once', () {
      final owner = MapEntity(
        id: 'owner',
        kind: MapEntityKind.custom,
        pos: const GridPos(x: 2, y: 3),
      );
      final owners = _CountingList([
        owner,
        for (var index = 0; index < unrelatedCount; index++)
          owner.copyWith(id: 'unrelated-owner-$index'),
      ]);
      final target = _interactionInstance('target', entityId: owner.id);
      final map = _modelMap([
        target,
        for (var index = 0; index < unrelatedCount; index++)
          _interactionInstance('unrelated-$index'),
      ], entities: owners);
      final records = _CountingIterable([
        _event(
          0,
          NarrativeEventSourceRef.modelInteract(map.id, target.id),
          'interaction',
        ),
        for (var index = 0; index < unrelatedCount; index++)
          _event(
            index + 1,
            NarrativeEventSourceRef.modelInteract('other', 'foreign-$index'),
            'interaction',
          ),
      ]);
      final index = SpatialModelInteractionIndex(records);
      expect(records.iterations, 1);
      expect(records.reads, unrelatedCount + 1);
      final candidates = index.candidatesFor(map);
      expect(candidates.single.instance, same(target));
      expect(candidates.single.owner, same(owner));
      expect(owners.reads, greaterThan(0));
      owners.reads = 0;

      for (var query = 0; query < 300; query++) {
        expect(index.candidatesFor(map), same(candidates));
      }

      expect(records.iterations, 1);
      expect(records.reads, unrelatedCount + 1);
      expect(owners.reads, 0);
      expect(() => candidates.clear(), throwsUnsupportedError);
    });
  }

  test('model interaction index preserves map order and first owner', () {
    const first = MapEntity(
      id: 'owner',
      kind: MapEntityKind.custom,
      pos: GridPos(x: 2, y: 3),
    );
    final duplicate = first.copyWith(pos: const GridPos(x: 4, y: 4));
    final bound = _interactionInstance('z-bound', entityId: first.id);
    final free = _interactionInstance('a-free');
    final map = _modelMap(
      [
        bound,
        _interactionInstance('disabled'),
        _interactionInstance('draft'),
        _interactionInstance('wrong-source'),
        _interactionInstance('other-map'),
        _interactionInstance('missing-owner', entityId: 'missing'),
        free,
      ],
      entities: [first, duplicate],
    );
    final index = SpatialModelInteractionIndex([
      _event(
        1,
        NarrativeEventSourceRef.modelInteract(map.id, free.id),
        'interaction',
      ),
      _event(
        2,
        NarrativeEventSourceRef.modelInteract(map.id, bound.id),
        'interaction',
      ),
      _event(
        3,
        NarrativeEventSourceRef.modelInteract(map.id, free.id),
        'interaction',
      ),
      NarrativeEventRecord.configuredStructurallyUnchecked(
        _event(
          4,
          NarrativeEventSourceRef.modelInteract(map.id, 'disabled'),
          'interaction',
        ).definitionOrNull!,
        enabled: false,
      ),
      NarrativeEventRecord.draft(
        NarrativeEventDraft(
          id: _id('evt', 5),
          name: 'Draft',
          source: NarrativeEventSourceRef.modelInteract(map.id, 'draft'),
          conditions: [],
          priority: 0,
          order: 5,
        ),
      ),
      _event(
        6,
        NarrativeEventSourceRef.entityInteract(map.id, 'wrong-source'),
        'interaction',
      ),
      _event(
        7,
        NarrativeEventSourceRef.modelInteract('other', 'other-map'),
        'interaction',
      ),
      _event(
        8,
        NarrativeEventSourceRef.modelInteract(map.id, 'missing-owner'),
        'interaction',
      ),
    ]);

    final candidates = index.candidatesFor(map);
    expect(candidates.map((candidate) => candidate.instance), [bound, free]);
    expect(candidates.first.owner, same(first));
    expect(candidates.last.owner, isNull);
    final replacement = _interactionInstance('a-free');
    final replacementMap = _modelMap([replacement]);
    expect(replacementMap.id, map.id);
    expect(
      index.candidatesFor(replacementMap).single.instance,
      same(replacement),
    );
    final restored = index.candidatesFor(map);
    expect(restored, isNot(same(candidates)));
    expect(restored.map((candidate) => candidate.instance), [bound, free]);
  });

  for (final foreignEventCount in [0, 10, 1000]) {
    test(
      '300 model target queries skip definitions with $foreignEventCount foreign events',
      () async {
        final model = _interactionModel();
        final map = _modelMap([
          _interactionInstance('target'),
          for (var index = 0; index < foreignEventCount; index++)
            _interactionInstance('unrelated-$index'),
        ]);
        final definitions = _CountingIterable([model]);
        var definitionRequests = 0;
        final host = await _Host.create(
          _project(
            map,
            records: [
              for (var index = 0; index < foreignEventCount; index++)
                _event(
                  index,
                  NarrativeEventSourceRef.modelInteract(
                    'other',
                    'foreign-$index',
                  ),
                  'interaction',
                ),
            ],
            scenes: [_scene('interaction', [])],
          ).copyWith(models3d: [model]),
          map,
          currentModelDefinitions: () {
            definitionRequests++;
            return definitions;
          },
        );

        for (var query = 0; query < 300; query++) {
          expect(host.events.modelInteractionTarget, isNull);
        }

        expect(definitionRequests, 0);
        expect(definitions.iterations, 0);
        expect(definitions.reads, 0);
      },
    );
  }

  test(
    'real model targets still consume current definitions on each query',
    () async {
      final model = _interactionModel();
      final instance = _interactionInstance('target');
      final map = _modelMap([instance]);
      final definitions = _CountingIterable([model]);
      final host = await _Host.create(
        _project(
          map,
          records: [
            _event(
              1,
              NarrativeEventSourceRef.modelInteract(map.id, instance.id),
              'interaction',
            ),
          ],
          scenes: [_scene('interaction', [])],
        ).copyWith(models3d: [model]),
        map,
        currentModelDefinitions: () => definitions,
      );

      for (var query = 0; query < 3; query++) {
        expect(host.events.modelInteractionTarget, same(instance));
      }

      expect(definitions.iterations, 3);
      expect(definitions.reads, 3);
    },
  );

  test('absent authored instances and owners skip model definitions', () async {
    final model = _interactionModel();
    final map = _modelMap([
      _interactionInstance('orphan', entityId: 'missing-owner'),
    ]);
    var definitionRequests = 0;
    final host = await _Host.create(
      _project(
        map,
        records: [
          _event(
            1,
            NarrativeEventSourceRef.modelInteract(map.id, 'missing-instance'),
            'interaction',
          ),
          _event(
            2,
            NarrativeEventSourceRef.modelInteract(map.id, 'orphan'),
            'interaction',
          ),
        ],
        scenes: [_scene('interaction', [])],
      ).copyWith(models3d: [model]),
      map,
      currentModelDefinitions: () {
        definitionRequests++;
        return [model];
      },
    );

    for (var query = 0; query < 300; query++) {
      expect(host.events.modelInteractionTarget, isNull);
    }
    expect(definitionRequests, 0);
  });

  test(
    'cached model candidates keep hot definitions, facing and player position',
    () async {
      final model = _interactionModel();
      final instance = _interactionInstance('target');
      final map = _modelMap([instance]);
      var definitions = [model];
      var worldProject = _project(
        map,
        records: [
          _event(
            1,
            NarrativeEventSourceRef.modelInteract(map.id, instance.id),
            'interaction',
          ),
        ],
        scenes: [_scene('interaction', [])],
      ).copyWith(models3d: definitions);
      ProjectManifest? lastWorldProject;
      final host = await _Host.create(
        worldProject,
        map,
        currentModelDefinitions: () => definitions,
        currentWorldProject: () => lastWorldProject = worldProject,
      );

      expect(host.events.modelInteractionTarget, same(instance));
      definitions = [_interactionModel(minX: 2, maxX: 2.2)];
      expect(host.events.modelInteractionTarget, isNull);
      definitions = [model];
      expect(host.events.modelInteractionTarget, same(instance));
      host.state = host.state.copyWith(playerFacing: EntityFacing.north);
      expect(host.events.modelInteractionTarget, isNull);
      host.state = host.state.copyWith(playerFacing: EntityFacing.south);
      host.moveTo(4.5, 2.5);
      expect(host.events.modelInteractionTarget, isNull);
      host.moveTo(2.5, 2.5);
      expect(host.events.modelInteractionTarget, same(instance));
      worldProject = worldProject.copyWith(
        models3d: [_interactionModel(minX: 2, maxX: 2.2)],
        eventRegistry: null,
      );
      host.events.projectWorld();
      expect(lastWorldProject, same(worldProject));
      expect(host.events.modelInteractionTarget, same(instance));
    },
  );

  test('cached model candidates keep live obstacle runtime state', () async {
    final model = _interactionModel();
    final instance = _interactionInstance('target');
    final obstacle = SpatialModelInstance(
      id: 'obstacle',
      modelId: model.id,
      position: Model3dVector3(x: 2.5, y: 0, z: 3),
    );
    final map = _modelMap([obstacle, instance]);
    final host = await _Host.create(
      _project(
        map,
        records: [
          _event(
            1,
            NarrativeEventSourceRef.modelInteract(map.id, instance.id),
            'interaction',
          ),
        ],
        scenes: [_scene('interaction', [])],
      ).copyWith(models3d: [model]),
      map,
    );

    expect(host.events.modelInteractionTarget, isNull);
    host.state = host.state.copyWith(
      spatialWorldState: host.state.spatialWorldState.setModelState(
        map.id,
        obstacle.id,
        SpatialModelRuntimeState(
          modelId: model.id,
          animationIndex: null,
          normalizedTime: 0,
          blocksMovement: false,
        ),
      ),
    );
    expect(host.events.modelInteractionTarget, same(instance));
    host.state = host.state.copyWith(
      spatialWorldState: host.state.spatialWorldState.removeModelState(
        map.id,
        obstacle.id,
      ),
    );
    expect(host.events.modelInteractionTarget, isNull);
  });

  test(
    'cached bound model keeps live owner visibility and world projection',
    () async {
      final owner = MapEntity(
        id: 'owner',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 2, y: 3),
        npc: const MapEntityNpcData(
          visibilityRule: MapEntityNpcVisibilityRule(
            mode: MapEntityNpcVisibilityMode.visibleWhen,
            predicate: MapEntityRuntimePredicate(
              refId: 'visible',
              kind: MapEntityRuntimePredicateKind.storyFlagSet,
            ),
          ),
        ),
        presentation: MapEntityPresentation(
          variants: [
            MapEntityPresentationVariant(
              id: 'projected',
              condition: NarrativeEventConditionExpression.leaf(
                NarrativeEventCondition.fact('projected', true),
              ),
              blocksMovement: true,
            ),
          ],
        ),
      );
      final model = _interactionModel();
      final instance = _interactionInstance('target', entityId: owner.id);
      final map = _modelMap([instance], entities: [owner]);
      final project =
          _project(
            map,
            records: [
              _event(
                1,
                NarrativeEventSourceRef.modelInteract(map.id, instance.id),
                'interaction',
              ),
            ],
            scenes: [_scene('interaction', [])],
            worldRules: [
              WorldRuleDefinition(
                id: 'hide',
                label: 'Hide owner',
                source: WorldRuleSource(
                  kind: WorldRuleSourceKind.fact,
                  sourceId: 'hidden',
                  predicate: WorldRuleSourcePredicate.isTrue,
                ),
                target: WorldRuleTarget(
                  kind: WorldRuleTargetKind.mapEntity,
                  mapId: map.id,
                  entityId: owner.id,
                ),
                effect: const WorldRuleEffect(
                  kind: WorldRuleEffectKind.entityHidden,
                ),
              ),
            ],
          ).copyWith(
            models3d: [model],
            facts: [
              NarrativeFactDefinition(
                id: 'hidden',
                label: 'Hidden',
                legacyFlagName: 'hidden',
              ),
              NarrativeFactDefinition(
                id: 'projected',
                label: 'Projected',
                legacyFlagName: 'projected',
              ),
            ],
          );
      final host = await _Host.create(project, map);

      expect(host.events.modelInteractionTarget, isNull);
      host.state = const GameStateMutations().setFlag(host.state, 'visible');
      expect(host.events.modelInteractionTarget, isNull);
      host.state = const GameStateMutations().setFlag(host.state, 'projected');
      expect(host.events.modelInteractionTarget, same(instance));
      host.state = const GameStateMutations().setFlag(host.state, 'hidden');
      expect(host.events.modelInteractionTarget, isNull);
      host.state = const GameStateMutations().clearFlag(host.state, 'hidden');
      expect(host.events.modelInteractionTarget, same(instance));
      host.state = const GameStateMutations().clearFlag(host.state, 'visible');
      expect(host.events.modelInteractionTarget, isNull);
      host.state = const GameStateMutations().setFlag(host.state, 'visible');
      expect(host.events.modelInteractionTarget, same(instance));
      host.state = const GameStateMutations().clearFlag(
        host.state,
        'projected',
      );
      expect(host.events.modelInteractionTarget, isNull);
    },
  );


  test('native bag-full pickup preserves its model owner and never persists a partial grant', () async {
    final item = MapEntity(
      id: 'native-item',
      kind: MapEntityKind.item,
      pos: const GridPos(x: 2, y: 3),
      item: const MapEntityItemData(gameItemId: 'resource'),
    );
    final map = _map(entities: [item]);
    var saves = 0;
    final host = await _Host.create(
      _project(map),
      map,
      persistItemPickup: (_) async {
        saves++;
      },
      presentItemPickup: (entity, result, label) async {
        expect(result.outcome, SpatialItemPickupOutcome.bagFull);
      },
    );
    host.state = host.state.copyWith(
      bag: const Bag(
        entries: [
          BagEntry(itemId: 'resource', quantity: maximumBagEntryQuantity),
        ],
      ),
    );
    await host.events.activateMap(_activation('native-full'));
    await host.events.interact();
    expect(saves, 0);
    expect(host.state.bag.entries.single.quantity, maximumBagEntryQuantity);
    expect(host.state.consumedEventIds, isEmpty);
    expect(host.events.entityIsPresent(map.id, item), isTrue);
  });
  test(
    'an authored entity interaction keeps precedence over native pickup',
    () async {
      final item = MapEntity(
        id: 'native-item',
        kind: MapEntityKind.item,
        pos: const GridPos(x: 2, y: 3),
        item: const MapEntityItemData(gameItemId: 'resource'),
      );
      final map = _map(entities: [item]);
      final host = await _Host.create(
        _project(
          map,
          records: [
            _event(
              940,
              NarrativeEventSourceRef.entityInteract(map.id, item.id),
              'authored',
            ),
          ],
          scenes: [
            _scene('authored', [SceneConsequence.giveMoney(amount: 7)]),
          ],
        ),
        map,
      );
      await host.events.activateMap(_activation('native-priority'));
      await host.events.interact();
      expect(host.state.trainerProfile.money, 7);
      expect(host.state.bag.entries, isEmpty);
      expect(host.events.entityIsPresent(map.id, item), isTrue);
    },
  );
  test(
    'native once item pickup persists before commit and never grants twice',
    () async {
      final item = MapEntity(
        id: 'native-item',
        kind: MapEntityKind.item,
        pos: const GridPos(x: 2, y: 3),
        item: const MapEntityItemData(gameItemId: 'resource', quantity: 2),
      );
      final map = _map(entities: [item]);
      var saves = 0, messages = 0;
      final host = await _Host.create(
        _project(map),
        map,
        persistItemPickup: (candidate) async {
          saves++;
          expect(candidate.bag.entries.single.quantity, 2);
        },
        presentItemPickup: (entity, result, label) async {
          messages++;
          expect(result.outcome, SpatialItemPickupOutcome.received);
        },
      );
      await host.events.activateMap(_activation('native-item'));
      await host.events.interact();
      expect(host.state.bag.entries.single.quantity, 2);
      expect(host.events.entityIsPresent(map.id, item), isFalse);
      expect(saves, 1);
      expect(messages, 1);
      await host.events.interact();
      await host.events.activateMap(_activation('reentry-native-item'));
      await host.events.interact();
      expect(saves, 1);
      expect(host.state.bag.entries.single.quantity, 2);
    },
  );
  test('item persistence failure keeps bag and object present', () async {
    final item = MapEntity(
      id: 'native-item',
      kind: MapEntityKind.item,
      pos: const GridPos(x: 2, y: 3),
      item: const MapEntityItemData(gameItemId: 'resource'),
    );
    final map = _map(entities: [item]);
    final host = await _Host.create(
      _project(map),
      map,
      persistItemPickup: (_) async => throw StateError('disk unavailable'),
    );
    await host.events.activateMap(_activation('native-item'));
    await expectLater(host.events.interact(), throwsStateError);
    expect(host.state.bag.entries, isEmpty);
    expect(host.events.entityIsPresent(map.id, item), isTrue);
    expect(host.state.consumedEventIds, isEmpty);
  });

  test('empty connected activation preserves movement without taking the gameplay gate', () async {
    final map = _map();
    final host = await _Host.create(_project(map), map);
    final activation = _activation('connected', MapActivationReason.connection);
    final pending = host.events.activateMap(activation);
    expect(host.events.isBusy, isFalse);
    expect(host.gate.activity, NarrativeRuntimeActivity.idle);
    expect(host.state.narrativeEventProgress.activeNarrativeMapId, map.id);
    expect(host.state.narrativeEventProgress.visitedNarrativeMapIds, contains(map.id));
    host.moveTo(3.25, 2.5);
    await pending;
    expect(host.state.playerSpatialPosition, PlayerSpatialPosition(x: 3.25, z: 2.5));
  });

  test('map enter executes once per activation and persists one-shot reuse',
      () async {
    final map = _map();
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.mapEnter(map.id), 'reward')
    ], scenes: [
      _scene('reward', [SceneConsequence.giveMoney(amount: 25)])
    ]);
    final host = await _Host.create(project, map);
    final activation = _activation('first');
    await host.events.activateMap(activation);
    await host.events.activateMap(activation);
    await host.events.activateMap(_activation('second'));
    expect(host.state.trainerProfile.money, 25);
    expect(host.state.narrativeEventProgress.consumedNarrativeEventIds,
        {_id('evt', 1)});
    expect(host.gate.activity, NarrativeRuntimeActivity.idle);
  });

  test('connected activation drains a pending outcome instead of bypassing it', () async {
    final map = _map();
    final outcome = NarrativeOutcomeRef(producerKind: NarrativeOutcomeProducerKind.scene,
      producerId: 'producer', outcomeId: 'completed');
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.outcomeReceived(outcome), 'reward')
    ], scenes: [
      _scene('producer', [], outcome: 'completed'),
      _scene('reward', [SceneConsequence.giveMoney(amount: 25)]),
    ]);
    final host = await _Host.create(project, map, state: GameState(
      saveId: 'save', currentMapId: map.id,
      playerPosition: const GridPos(x: 2, y: 2),
      narrativeEventProgress: NarrativeEventProgress(pendingNarrativeOutcomeDeliveries: [
        NarrativeOutcomeDelivery(deliveryId: _id('outd', 2), outcome: outcome,
          rootCorrelationId: _id('corr', 3), depth: 0, attemptCount: 0),
      ]),
    ));
    final pending = host.events.activateMap(_activation('connected', MapActivationReason.connection));
    expect(host.events.isBusy, isTrue);
    await pending;
    expect(host.state.trainerProfile.money, 25);
    expect(host.state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries, isEmpty);
  });

  test('empty connected activation still resets one-shot interactions on reentry', () async {
    final map = _map(entities: const [MapEntity(id: 'pickup',
      kind: MapEntityKind.item, pos: GridPos(x: 2, y: 3))]);
    final event = NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(id: _id('evt', 1), name: 'Pickup',
        source: NarrativeEventSourceRef.entityInteract(map.id, 'pickup'),
        conditions: [], sceneId: 'reward', reusePolicy: NarrativeEventReusePolicy.oneShot,
        priority: 0, order: 0, resetPolicy: const NarrativeEventResetPolicy.onMapReentry()),
      enabled: true);
    final host = await _Host.create(_project(map, records: [event],
      scenes: [_scene('reward', [SceneConsequence.giveMoney(amount: 7)])]), map,
      state: GameState(saveId: 'save', currentMapId: map.id,
        playerPosition: const GridPos(x: 2, y: 2),
        playerSpatialPosition: PlayerSpatialPosition(x: 2.5, z: 2.5),
        narrativeEventProgress: NarrativeEventProgress(
          consumedNarrativeEventIds: {_id('evt', 1)},
          activeNarrativeMapId: 'previous', visitedNarrativeMapIds: {'previous', map.id})));
    final pending = host.events.activateMap(_activation('reentry', MapActivationReason.connection));
    expect(host.events.isBusy, isFalse);
    await pending;
    expect(host.state.narrativeEventProgress.consumedNarrativeEventIds, isEmpty);
    await host.events.interact();
    expect(host.state.trainerProfile.money, 7);
  });

  test('pickup commits once and world rule removes its interaction presence',
      () async {
    final map = _map(entities: const [
      MapEntity(
          id: 'pickup',
          kind: MapEntityKind.item,
          pos: GridPos(x: 2, y: 3),
          item: MapEntityItemData(gameItemId: 'item_potion', quantity: 2)),
    ]);
    final project = _project(map, records: [
      _event(
          1, NarrativeEventSourceRef.entityInteract(map.id, 'pickup'), 'pickup')
    ], scenes: [
      _scene('pickup', [
        SceneConsequence.giveItem(itemId: 'item_potion', quantity: 2),
        SceneConsequence.setFact(factId: 'picked', value: true),
      ])
    ], worldRules: [
      WorldRuleDefinition(
        id: 'hide_pickup',
        label: 'Hide collected pickup',
        source: WorldRuleSource(
            kind: WorldRuleSourceKind.fact,
            sourceId: 'picked',
            predicate: WorldRuleSourcePredicate.isTrue),
        target: const WorldRuleTarget(
            kind: WorldRuleTargetKind.mapEntity,
            mapId: 'map',
            entityId: 'pickup'),
        effect: const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden),
      )
    ]).copyWith(
        facts: [NarrativeFactDefinition(id: 'picked', label: 'Picked')]);
    final host = await _Host.create(project, map);
    await host.events.activateMap(_activation('pickup', MapActivationReason.connection));
    expect(host.events.interactionTarget?.id, 'pickup');
    expect(await host.events.interact(),
        isA<NarrativeSpatialProductionDispatchV2Handled>());
    expect(host.state.bag.entries.single.itemId, 'item_potion');
    expect(host.state.bag.entries.single.quantity, 2);
    expect(host.events.entityIsPresent(map.id, map.entities.single), isFalse);
    expect(host.events.interactionTarget, isNull);
    final reloaded =
        gameStateFromStrictSaveJson(strictGameStateSaveJson(host.state));
    final resumed = await _Host.create(project, map, state: reloaded);
    await resumed.events
        .activateMap(_activation('resume', MapActivationReason.saveRestore));
    expect(resumed.events.interactionTarget, isNull);
    expect(resumed.state.bag.entries.single.quantity, 2);
  });

  test('failed scene does not leak an earlier item consequence', () async {
    final map = _map(entities: const [
      MapEntity(
          id: 'pickup', kind: MapEntityKind.item, pos: GridPos(x: 2, y: 3)),
    ]);
    final project = _project(map, records: [
      _event(
          1, NarrativeEventSourceRef.entityInteract(map.id, 'pickup'), 'failed')
    ], scenes: [
      _scene('failed', [
        SceneConsequence.giveItem(itemId: 'item_potion', quantity: 2),
        SceneConsequence.takeItem(itemId: 'missing_item', quantity: 1),
      ])
    ]);
    final host = await _Host.create(project, map);
    await host.events.activateMap(_activation('failed'));
    final before = host.state;
    await expectLater(host.events.interact(), throwsStateError);
    expect(host.state, before);
    expect(host.state.bag.entries, isEmpty);
  });

  test('map enter failures preserve the underlying scene reason', () async {
    final map = _map();
    final host = await _Host.create(_project(map, records: [
      _event(1, NarrativeEventSourceRef.mapEnter(map.id), 'failed'),
    ], scenes: [_scene('failed', [SceneConsequence.takeItem(itemId: 'missing_item', quantity: 1)])]), map);
    await expectLater(host.events.activateMap(_activation('failed')),
        throwsA(isA<StateError>().having((error) => error.message, 'message',
            allOf(contains('Map enter failed (sceneFailure)'), contains('takeItem requires 1 of "missing_item"')))));
  });

  test('dialogue suspends checkpoint and disposal cancels the final commit',
      () async {
    final map = _map(entities: const [
      MapEntity(
          id: 'npc',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 3),
          npc: MapEntityNpcData()),
    ]);
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.entityInteract(map.id, 'npc'), 'talk')
    ], scenes: [
      _scene('talk', [SceneConsequence.giveMoney(amount: 50)], dialogue: true)
    ]);
    final dialogue = Completer<String>();
    final opened = Completer<void>();
    final host = await _Host.create(project, map, dialogue: () {
      opened.complete();
      return dialogue.future;
    });
    await host.events.activateMap(_activation('talk'));
    final before = host.state;
    final interaction = host.events.interact();
    await opened.future;
    expect(host.events.isBusy, isTrue);
    await expectLater(
        host.gate.runCheckpoint(
            NarrativeRuntimeCheckpointOperation.save, () async {}),
        throwsA(isA<NarrativeRuntimeCheckpointBlockedException>()));
    expect(host.state.trainerProfile.money, 0);
    host.events.dispose();
    dialogue.complete('completed');
    await interaction;
    expect(host.state, before);
    expect(host.events.isBusy, isFalse);
  });

  test('encounters use actual cell entries, never facing or blocked inputs',
      () async {
    final map = _map(zones: const [
      MapGameplayZone(
        id: 'grass',
        name: 'Grass',
        kind: GameplayZoneKind.encounter,
        area: MapRect(
            pos: GridPos(x: 1, y: 1), size: GridSize(width: 4, height: 4)),
        encounter: EncounterZonePayload(
            encounterTableId: 'grass_table', encounterKind: EncounterKind.walk),
      ),
    ]);
    final project = _project(map).copyWith(encounterTables: const [
      ProjectEncounterTable(
          id: 'grass_table',
          name: 'Grass',
          encounterKind: EncounterKind.walk,
          chancePerStep: 1,
          entries: [
            ProjectEncounterEntry(speciesId: 'zubat', minLevel: 5, maxLevel: 5),
          ]),
    ]);
    final host = await _Host.create(project, map);
    await host.events.activateMap(_activation('grass'));
    expect(host.battles, isEmpty);
    const start = GridPos(x: 2, y: 2);
    expect(
        await host.events
            .playerEnteredCell(previousPosition: start, currentPosition: start),
        isNull);
    host.canInput = false;
    expect(
        await host.events
            .playerEnteredCell(previousPosition: start, currentPosition: start),
        isNull);
    host.canInput = true;
    host.moveTo(3.125, 2.5625);
    const next = GridPos(x: 3, y: 2);
    final result = await host.events
        .playerEnteredCell(previousPosition: start, currentPosition: next);
    expect(result?.status, GameplayEncounterCheckStatus.triggered);
    expect(host.battles, hasLength(1));
    expect(host.battles.single.returnContext.playerPos, next);
    expect(
        await host.events
            .playerEnteredCell(previousPosition: start, currentPosition: next),
        isNull);
    expect(host.battles, hasLength(1));
  });

  test('spatial encounters sample the current clock again on every real step', () async {
    final map = _map(zones: const [MapGameplayZone(
      id: 'grass', name: 'Grass', kind: GameplayZoneKind.encounter,
      area: MapRect(pos: GridPos(x: 1, y: 1), size: GridSize(width: 4, height: 4)),
      encounter: EncounterZonePayload(encounterTableId: 'timed'),
    )]);
    final project = _project(map).copyWith(encounterTables: [
      ProjectEncounterTable(id: 'timed', name: 'Timed', encounterKind: EncounterKind.walk,
        chancePerStep: 1, variants: [
          for (final window in [('early', 0, 600), ('late', 600, 0)])
            ProjectEncounterVariant(id: window.$1, name: window.$1,
              timeWindows: [LocalTimeWindow(startMinute: window.$2, endMinute: window.$3)],
              entries: [ProjectEncounterEntry(speciesId: window.$1, minLevel: 3, maxLevel: 3)]),
        ]),
    ]);
    var clock = DateTime(2026, 10, 24, 9, 59);
    final host = await _Host.create(project, map, now: () => clock);
    await host.events.activateMap(_activation('clock'));
    host.moveTo(3.5, 2.5);
    await host.events.playerEnteredCell(previousPosition: const GridPos(x: 2, y: 2), currentPosition: const GridPos(x: 3, y: 2));
    expect(host.battles.single.speciesId, 'early');
    expect(host.battles.single.createdAtEpochMs, clock.millisecondsSinceEpoch);
    clock = DateTime(2026, 10, 24, 10);
    host.moveTo(4.5, 2.5);
    await host.events.playerEnteredCell(previousPosition: const GridPos(x: 3, y: 2), currentPosition: const GridPos(x: 4, y: 2));
    expect(host.battles, hasLength(2));
    expect(host.battles.last.speciesId, 'late');
    expect(host.battles.last.createdAtEpochMs, clock.millisecondsSinceEpoch);
    host.events.dispose();
  });

  for (final edition in ['amber', 'violet']) {
    for (final (minute, period) in [
      (0, 'night'), (239, 'night'), (240, 'morning'), (599, 'morning'),
      (600, 'day'), (1199, 'day'), (1200, 'night'), (1439, 'night'),
    ]) {
      test('spatial encounters resolve $edition $period at minute $minute', () async {
        final map = _map(zones: const [MapGameplayZone(
          id: 'grass', name: 'Grass', kind: GameplayZoneKind.encounter,
          area: MapRect(pos: GridPos(x: 1, y: 1), size: GridSize(width: 4, height: 4)),
          encounter: EncounterZonePayload(encounterTableId: 'timed'),
        )]);
        final project = _project(map).copyWith(
          facts: [NarrativeFactDefinition(id: 'edition', label: 'Edition',
            initialValue: NarrativeValue.string('amber'))],
          encounterTables: [ProjectEncounterTable(id: 'timed', name: 'Timed',
            encounterKind: EncounterKind.walk, chancePerStep: 1, variants: [
              for (final version in ['amber', 'violet'])
                for (final window in [
                  ('morning', 240, 600), ('day', 600, 1200), ('night', 1200, 240),
                ]) ProjectEncounterVariant(id: '$version-${window.$1}', name: window.$1,
                  conditions: [ScriptConditionFactory.factEquals('edition', NarrativeValue.string(version))],
                  timeWindows: [LocalTimeWindow(startMinute: window.$2, endMinute: window.$3)],
                  entries: [ProjectEncounterEntry(speciesId: '$version-${window.$1}', minLevel: 3, maxLevel: 3)]),
            ])],
        );
        final host = await _Host.create(project, map,
          now: () => DateTime(2026, 10, 24, minute ~/ 60, minute % 60));
        host.state = GameState.fromJson(host.state.copyWith(
          narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(valuesByFactId: {
            'edition': NarrativeValue.string(edition),
          }),
        ).toJson());
        await host.events.activateMap(_activation('timed'));
        host.moveTo(3.5, 2.5);
        final result = await host.events.playerEnteredCell(
          previousPosition: const GridPos(x: 2, y: 2), currentPosition: const GridPos(x: 3, y: 2));
        expect(result?.status, GameplayEncounterCheckStatus.triggered);
        expect(result?.encounter?.variantId, '$edition-$period');
        expect(host.battles.single.speciesId, '$edition-$period');
        host.events.dispose();
      });
    }
  }

  for (final coverage in ['painted', 'erased', 'hidden']) {
    test('native grass path encounters follow $coverage material coverage',
        () async {
      final size = _map().size;
      var layer = applySmartTileMaterialGesture(
          SmartTileLayer(
              id: 'grass-path',
              name: 'Grass',
              presetId: 'grass-preset',
              usage: SmartTileUsage.path,
              materialPalette: const ['', 'grass-material'],
              field: SmartTileField.cell(
                  semanticCells: List.filled(size.width * size.height, 0)),
              encounterBehavior: const SmartTileEncounterBehavior(
                  materialId: 'grass-material',
                  encounter: EncounterZonePayload(
                      encounterTableId: 'grass-table',
                      encounterKind: EncounterKind.walk))),
          mapSize: size,
          cells: const [GridPos(x: 3, y: 2)],
          materialId: 'grass-material');
      if (coverage == 'erased') {
        layer = applySmartTileMaterialGesture(layer,
            mapSize: size,
            cells: const [GridPos(x: 3, y: 2)],
            materialId: null);
      } else if (coverage == 'hidden') {
        layer = layer.copyWith(isVisible: false);
      }
      final map = _map().copyWith(layers: [layer]);
      final project = _project(map).copyWith(encounterTables: const [
        ProjectEncounterTable(
            id: 'grass-table',
            name: 'Grass',
            encounterKind: EncounterKind.walk,
            chancePerStep: 1,
            entries: [
              ProjectEncounterEntry(
                  speciesId: 'zubat', minLevel: 5, maxLevel: 5)
            ])
      ]);
      final host = await _Host.create(project, map);
      await host.events.activateMap(_activation('grass-path'));
      expect(host.battles, isEmpty);
      host.moveTo(3.5, 2.5);
      await host.events.playerEnteredCell(
          previousPosition: const GridPos(x: 2, y: 2),
          currentPosition: const GridPos(x: 3, y: 2));
      expect(host.battles, hasLength(coverage == 'painted' ? 1 : 0));
      if (coverage == 'painted') {
        expect(host.battles.single.encounterSourceKind,
            EncounterSourceKind.smartTileLayer);
        expect(host.battles.single.encounterSourceId,
            'smart_tile_layer:grass-path');
      }
      host.moveTo(4.5, 2.5);
      await host.events.playerEnteredCell(
          previousPosition: const GridPos(x: 3, y: 2),
          currentPosition: const GridPos(x: 4, y: 2));
      expect(host.battles, hasLength(coverage == 'painted' ? 1 : 0));
      host.events.dispose();
    });
  }

  test('event trigger fires on entry, then waits for a real reentry', () async {
    final map = _map(triggers: const [
      MapTrigger(
          id: 'entry',
          type: TriggerType.event,
          area: MapRect(
              pos: GridPos(x: 3, y: 2), size: GridSize(width: 1, height: 1))),
    ]);
    final project = _project(map, records: [
      _event(
          1, NarrativeEventSourceRef.triggerEnter(map.id, 'entry'), 'trigger',
          oneShot: false),
    ], scenes: [
      _scene('trigger', [SceneConsequence.giveMoney(amount: 10)])
    ]);
    final host = await _Host.create(project, map);
    await host.events.activateMap(_activation('trigger'));
    host.moveTo(3.5, 2.5);
    await host.events.playerEnteredCell(
        previousPosition: const GridPos(x: 2, y: 2),
        currentPosition: const GridPos(x: 3, y: 2));
    expect(host.state.trainerProfile.money, 10);
    await host.events.playerEnteredCell(
        previousPosition: const GridPos(x: 3, y: 2),
        currentPosition: const GridPos(x: 3, y: 2));
    expect(host.state.trainerProfile.money, 10);
    host.moveTo(2.5, 2.5);
    await host.events.playerEnteredCell(
        previousPosition: const GridPos(x: 3, y: 2),
        currentPosition: const GridPos(x: 2, y: 2));
    host.moveTo(3.5, 2.5);
    await host.events.playerEnteredCell(
        previousPosition: const GridPos(x: 2, y: 2),
        currentPosition: const GridPos(x: 3, y: 2));
    expect(host.state.trainerProfile.money, 20);
  });

  test('world projection uses manifest pixels and the canonical feet cell',
      () async {
    final map = _map();
    final host = await _Host.create(_project(map), map);
    host.moveTo(3.3125, 2.0);
    final world = host.events.projectWorld();
    expect(world.player.pos, const GridPos(x: 3, y: 2));
    expect(world.player.playerCollisionRectPx.bottomCenterPx.xPx, 106);
    expect(world.player.playerCollisionRectPx.bottomCenterPx.yPx, 48);
    expect(
        PlayerCollisionConventionsV1.projectFeetAnchorToCell(
          playerCollisionRectPx: world.player.playerCollisionRectPx,
          tileWidthPx: 32,
          tileHeightPx: 24,
          mapWidthCells: 6,
          mapHeightCells: 6,
        ),
        world.player.pos);
  });
  test('fact conditions claim an interaction without executing until eligible',
      () async {
    final map = _map(entities: const [
      MapEntity(id: 'sign', kind: MapEntityKind.sign, pos: GridPos(x: 2, y: 3))
    ]);
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.entityInteract(map.id, 'sign'),
          'conditional',
          conditions: [NarrativeEventCondition.fact('ready', true)])
    ], scenes: [
      _scene('conditional', [SceneConsequence.giveMoney(amount: 30)])
    ]).copyWith(facts: [
      NarrativeFactDefinition(
          id: 'ready', label: 'Ready', legacyFlagName: 'ready')
    ]);
    final host = await _Host.create(project, map);
    await host.events.activateMap(_activation('conditional'));
    expect(await host.events.interact(),
        isA<NarrativeSpatialProductionDispatchNoFallback>());
    expect(host.state.trainerProfile.money, 0);
    host.state = const GameStateMutations().setFlag(host.state, 'ready');
    expect(await host.events.interact(),
        isA<NarrativeSpatialProductionDispatchV2Handled>());
    expect(host.state.trainerProfile.money, 30);
  });

  test('restored outbox is delivered before map enter and child outcomes drain',
      () async {
    final map = _map();
    final producer = _scene('producer', [], outcome: 'finished');
    final pending = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'producer',
        outcomeId: 'finished');
    final child = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'outcome_reward',
        outcomeId: 'rewarded');
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.outcomeReceived(pending),
          'outcome_reward'),
      _event(2, NarrativeEventSourceRef.outcomeReceived(child), 'child_reward'),
      _event(3, NarrativeEventSourceRef.mapEnter(map.id), 'map_reward'),
    ], scenes: [
      producer,
      _scene('outcome_reward', [SceneConsequence.giveMoney(amount: 10)],
          outcome: 'rewarded'),
      _scene('child_reward', [SceneConsequence.giveMoney(amount: 1)]),
      _scene('map_reward', [SceneConsequence.giveMoney(amount: 100)]),
    ]);
    final deliveryId = _id('outd', 5);
    final host = await _Host.create(project, map,
        state: GameState(
          saveId: 'save',
          currentMapId: map.id,
          playerPosition: const GridPos(x: 2, y: 2),
          playerSpatialPosition: PlayerSpatialPosition(x: 2.5, z: 2.5),
          narrativeEventProgress:
              NarrativeEventProgress(pendingNarrativeOutcomeDeliveries: [
            NarrativeOutcomeDelivery(
                deliveryId: deliveryId,
                outcome: pending,
                rootCorrelationId: _id('corr', 6),
                depth: 0,
                attemptCount: 0),
          ]),
        ));
    await host.events
        .activateMap(_activation('restore', MapActivationReason.saveRestore));
    expect(host.state.trainerProfile.money, 111);
    expect(host.state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty);
    expect(
        host.state.narrativeEventProgress.deliveredNarrativeOutcomeDeliveryIds,
        contains(deliveryId));
    expect(host.state.narrativeEventProgress.consumedNarrativeEventIds,
        {_id('evt', 1), _id('evt', 2), _id('evt', 3)});
  });

  test('postcommit warp can await the destination activation without deadlock',
      () async {
    final first = _map();
    final second = _map().copyWith(id: 'second');
    final project = _project(first, records: [
      _event(1, NarrativeEventSourceRef.mapEnter(first.id), 'first_reward'),
      _event(2, NarrativeEventSourceRef.mapEnter(second.id), 'second_reward'),
    ], scenes: [
      _scene('first_reward', [SceneConsequence.giveMoney(amount: 10)]),
      _scene('second_reward', [SceneConsequence.giveMoney(amount: 20)]),
    ]).copyWith(maps: [
      const ProjectMapEntry(
          id: 'map', name: 'First', relativePath: 'maps/map.json'),
      const ProjectMapEntry(
          id: 'second', name: 'Second', relativePath: 'maps/second.json'),
    ]);
    late _Host host;
    var warped = false;
    host = await _Host.create(project, first,
        maps: {first.id: first, second.id: second},
        afterStateCommitted: (state) async {
      if (state.currentMapId == 'map' && !warped) {
        warped = true;
        host.state = state.copyWith(currentMapId: 'second');
        await host.events.activateMap(MapActivation(
            activationId: 'warp',
            mapId: 'second',
            reason: MapActivationReason.warp));
      }
    });
    await host.events
        .activateMap(_activation('initial'))
        .timeout(const Duration(seconds: 3));
    expect(host.state.currentMapId, 'second');
    expect(host.state.trainerProfile.money, 30);
    expect(host.events.isBusy, isFalse);
    expect(host.gate.activity, NarrativeRuntimeActivity.idle);
  });
  test('scene host writes remain private until the entire scene commits',
      () async {
    final map = _map(entities: const [
      MapEntity(id: 'sign', kind: MapEntityKind.sign, pos: GridPos(x: 2, y: 3))
    ]);
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.entityInteract(map.id, 'sign'),
          'host_write')
    ], scenes: [
      _scene('host_write', [SceneConsequence.giveMoney(amount: 30)],
          dialogue: true)
    ]);
    final finish = Completer<String>();
    final opened = Completer<void>();
    final host = await _Host.create(project, map,
        createSceneCallbacks: (read, commit) => SceneRuntimeHostCallbacks(
              evaluateCondition: (_) => 'true',
              showDialogue: (_) async {
                final state = read();
                commit(state.copyWith(
                    trainerProfile: state.trainerProfile.copyWith(money: 70)));
                opened.complete();
                return finish.future;
              },
              startBattle: (_) => 'victory',
              playCinematic: (_) => 'completed',
            ));
    await host.events.activateMap(_activation('host_write'));
    final interaction = host.events.interact();
    await opened.future;
    expect(host.state.trainerProfile.money, 0);
    expect(await host.events.interact(), isNull);
    finish.complete('completed');
    await interaction;
    expect(host.state.trainerProfile.money, 100);
  });

  test('scene projection keeps its final pose while termination effects finish', () async {
    final map = _map(entities: const [
      MapEntity(id: 'sign', kind: MapEntityKind.sign, pos: GridPos(x: 2, y: 3)),
    ]);
    final finishing = Completer<void>();
    final release = Completer<void>();
    final host = await _Host.create(_project(map, records: [
      _event(1, NarrativeEventSourceRef.entityInteract(map.id, 'sign'), 'held_pose'),
    ], scenes: [
      _scene('held_pose', [SceneConsequence.giveMoney(amount: 30)], dialogue: true),
    ]), map, createSceneCallbacks: (read, commit) => SceneRuntimeHostCallbacks(
      evaluateCondition: (_) => 'true',
      showDialogue: (_) async {
        commit(read().copyWith(playerPosition: const GridPos(x: 4, y: 3),
          playerSpatialPosition: PlayerSpatialPosition(x: 4.5, z: 3.5)));
        return 'completed';
      },
      startBattle: (_) => 'victory', playCinematic: (_) => 'completed',
    ), onSceneTerminated: (_) async {
      finishing.complete();
      await release.future;
    });
    await host.events.activateMap(_activation('held_pose'));
    final interaction = host.events.interact();
    await finishing.future;
    final projected = host.events.projectedSceneGameState;
    release.complete();
    await interaction;
    expect(projected?.playerSpatialPosition, PlayerSpatialPosition(x: 4.5, z: 3.5));
    expect(host.state.playerSpatialPosition, PlayerSpatialPosition(x: 4.5, z: 3.5));
    expect(host.state.trainerProfile.money, 30);
    expect(host.events.projectedSceneGameState, isNull);
  });

  test('invalidating a pending scene never revives its projection during termination', () async {
    final map = _map(entities: const [
      MapEntity(id: 'sign', kind: MapEntityKind.sign, pos: GridPos(x: 2, y: 3)),
    ]);
    final opened = Completer<void>();
    final dialogue = Completer<String>();
    final finishing = Completer<void>();
    final release = Completer<void>();
    final host = await _Host.create(_project(map, records: [
      _event(1, NarrativeEventSourceRef.entityInteract(map.id, 'sign'), 'invalidated_pose'),
    ], scenes: [_scene('invalidated_pose', [SceneConsequence.giveMoney(amount: 30)], dialogue: true)]), map,
      dialogue: () { opened.complete(); return dialogue.future; },
      onSceneTerminated: (_) async { finishing.complete(); await release.future; });
    await host.events.activateMap(_activation('invalidated_pose'));
    final interaction = host.events.interact();
    await opened.future;
    host.events.invalidate();
    expect(host.events.projectedSceneGameState, isNull);
    dialogue.complete('completed');
    await finishing.future;
    final projectedDuringTermination = host.events.projectedSceneGameState;
    release.complete();
    await interaction;
    expect(projectedDuringTermination, isNull);
    expect(host.events.projectedSceneGameState, isNull);
    expect(host.state.trainerProfile.money, 0);
  });

  test('committed scene relocation rearms cell entry at the cinematic arrival',
      () async {
    final map = _map(triggers: const [
      MapTrigger(id: 'arrival', type: TriggerType.event,
        area: MapRect(pos: GridPos(x: 4, y: 3),
          size: GridSize(width: 1, height: 1))),
    ]);
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.mapEnter(map.id), 'relocation'),
      _event(2, NarrativeEventSourceRef.triggerEnter(map.id, 'arrival'), 'reward',
        oneShot: false),
    ], scenes: [
      _scene('relocation', [], dialogue: true),
      _scene('reward', [SceneConsequence.giveMoney(amount: 10)]),
    ]);
    final host = await _Host.create(project, map,
      createSceneCallbacks: (read, commit) => SceneRuntimeHostCallbacks(
        evaluateCondition: (_) => 'true',
        showDialogue: (_) async {
          commit(read().copyWith(playerPosition: const GridPos(x: 4, y: 3),
            playerSpatialPosition: PlayerSpatialPosition(x: 4.5, z: 3.5)));
          return 'completed';
        },
        startBattle: (_) => 'victory',
        playCinematic: (_) => 'completed',
      ));
    await host.events.activateMap(_activation('arrival'));
    expect(host.state.playerPosition, const GridPos(x: 4, y: 3));
    expect(host.state.trainerProfile.money, 0);
    host.moveTo(4.5, 4.5);
    await host.events.playerEnteredCell(
      previousPosition: const GridPos(x: 4, y: 3),
      currentPosition: const GridPos(x: 4, y: 4));
    host.moveTo(4.5, 3.5);
    await host.events.playerEnteredCell(
      previousPosition: const GridPos(x: 4, y: 4),
      currentPosition: const GridPos(x: 4, y: 3));
    expect(host.state.trainerProfile.money, 10);
    host.moveTo(3.5, 3.5);
    expect(() => host.events.playerEnteredCell(
      previousPosition: const GridPos(x: 1, y: 1),
      currentPosition: const GridPos(x: 3, y: 3)), throwsStateError);
  });

  test('conditional NPC visibility also filters the query world collision',
      () async {
    final map = _map(entities: const [
      MapEntity(
        id: 'npc',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 2, y: 3),
        blocksMovement: true,
        npc: MapEntityNpcData(
            visibilityRule: MapEntityNpcVisibilityRule(
          mode: MapEntityNpcVisibilityMode.visibleWhen,
          predicate: MapEntityRuntimePredicate(
              kind: MapEntityRuntimePredicateKind.storyFlagSet,
              refId: 'visible'),
        )),
      )
    ]);
    final host = await _Host.create(_project(map), map);
    await host.events.activateMap(_activation('visible'));
    expect(host.events.entityIsPresent(map.id, map.entities.single), isFalse);
    expect(host.events.projectWorld().entityAt(2, 3), isNull);
    host.state = const GameStateMutations().setFlag(host.state, 'visible');
    expect(host.events.entityIsPresent(map.id, map.entities.single), isTrue);
    expect(host.events.interactionTarget?.id, 'npc');
    expect(host.events.projectWorld().entityAt(2, 3)?.id, 'npc');
  });
  test('postcommit host changes survive the following outcome transaction',
      () async {
    final map = _map();
    final parent = _scene('parent', [SceneConsequence.giveMoney(amount: 10)],
        outcome: 'finished');
    final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.scene,
        producerId: 'parent',
        outcomeId: 'finished');
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.mapEnter(map.id), 'parent'),
      _event(2, NarrativeEventSourceRef.outcomeReceived(outcome), 'child'),
    ], scenes: [
      parent,
      _scene('child', [SceneConsequence.giveMoney(amount: 20)])
    ]);
    late _Host host;
    var prepared = false;
    host = await _Host.create(project, map, afterStateCommitted: (state) async {
      if (!prepared) {
        prepared = true;
        host.state = state.copyWith(
            trainerProfile: state.trainerProfile
                .copyWith(money: state.trainerProfile.money + 5));
      }
    });
    await host.events.activateMap(_activation('host_change'));
    expect(host.state.trainerProfile.money, 35);
  });
  test('scene healing uses host recovery caps through the canonical writer',
      () async {
    final map = _map(entities: const [
      MapEntity(
          id: 'healer',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 3),
          npc: MapEntityNpcData())
    ]);
    final project = _project(map, records: [
      _event(
          1, NarrativeEventSourceRef.entityInteract(map.id, 'healer'), 'heal')
    ], scenes: [
      _scene('heal', [SceneConsequence.healParty()])
    ]);
    final state = GameState(
        saveId: 'save',
        currentMapId: map.id,
        playerPosition: const GridPos(x: 2, y: 2),
        playerSpatialPosition: PlayerSpatialPosition(x: 2.5, z: 2.5),
        party: const PlayerParty(members: [
          PlayerPokemon(
              speciesId: 'zubat',
              level: 5,
              currentHp: 3,
              abilityId: 'inner_focus',
              natureId: 'hardy')
        ]));
    final host = await _Host.create(project, map,
        state: state,
        buildSceneConsequenceWriter: (working, sceneId) async =>
            SceneConsequenceRuntimeWriter(
              project: project,
              mapsById: {map.id: map},
              maxHpByPartyIndex: const {0: 30},
            ));
    await host.events.activateMap(_activation('heal'));
    await host.events.interact();
    expect(host.state.party.members.single.currentHp, 30);
  });
  test('battle public outcome is collected once and committed with its scene',
      () async {
    final map = _map(entities: const [
      MapEntity(
          id: 'trainer',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 3),
          npc: MapEntityNpcData(trainerId: 'coach'))
    ]);
    final battleOutcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.battle,
        producerId: 'trainer:coach',
        outcomeId: 'victory');
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.entityInteract(map.id, 'trainer'),
          'battle'),
      _event(2, NarrativeEventSourceRef.outcomeReceived(battleOutcome),
          'after_battle'),
    ], scenes: [
      _battleScene(),
      _scene('after_battle', [SceneConsequence.giveMoney(amount: 5)])
    ]).copyWith(trainers: const [
      ProjectTrainerEntry(id: 'coach', name: 'Coach', trainerClass: 'youngster')
    ]);
    late _Host host;
    final request = _trainerRequest('attempt');
    host = await _Host.create(project, map,
        createSceneCallbacks: (read, commit) => SceneRuntimeHostCallbacks(
              evaluateCondition: (_) => 'true',
              showDialogue: (_) => 'completed',
              startBattle: (_) async {
                commit(read().copyWith(
                    trainerProfile: read().trainerProfile.copyWith(money: 7)));
                expect(
                    await host.events.publishBattleOutcome(
                        request: request, outcomeId: 'victory'),
                    isTrue);
                expect(
                    await host.events.publishBattleOutcome(
                        request: request, outcomeId: 'victory'),
                    isFalse);
                expect(host.state.trainerProfile.money, 0);
                expect(
                    host.state.narrativeEventProgress
                        .pendingNarrativeOutcomeDeliveries,
                    isEmpty);
                return 'victory';
              },
              playCinematic: (_) => 'completed',
            ));
    await host.events.activateMap(_activation('battle'));
    await host.events.interact();
    expect(host.state.trainerProfile.money, 12);
    expect(host.state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty);
    expect(
        await host.events
            .publishBattleOutcome(request: request, outcomeId: 'victory'),
        isFalse);
  });

  test('battle output does not escape a scene that fails after battle',
      () async {
    final map = _map(entities: const [
      MapEntity(
          id: 'trainer',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 3),
          npc: MapEntityNpcData(trainerId: 'coach'))
    ]);
    final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.battle,
        producerId: 'trainer:coach',
        outcomeId: 'victory');
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.entityInteract(map.id, 'trainer'),
          'battle'),
      _event(
          2, NarrativeEventSourceRef.outcomeReceived(outcome), 'after_battle'),
    ], scenes: [
      _battleScene(failAfterBattle: true),
      _scene('after_battle', [SceneConsequence.giveMoney(amount: 5)])
    ]).copyWith(trainers: const [
      ProjectTrainerEntry(id: 'coach', name: 'Coach', trainerClass: 'youngster')
    ]);
    late _Host host;
    host = await _Host.create(project, map,
        createSceneCallbacks: (read, commit) => SceneRuntimeHostCallbacks(
              evaluateCondition: (_) => 'true',
              showDialogue: (_) => 'completed',
              startBattle: (_) async {
                commit(read().copyWith(
                    trainerProfile: read().trainerProfile.copyWith(money: 7)));
                await host.events.publishBattleOutcome(
                    request: _trainerRequest('failed_attempt'),
                    outcomeId: 'victory');
                return 'victory';
              },
              playCinematic: (_) => 'completed',
            ));
    await host.events.activateMap(_activation('failed_battle'));
    final before = host.state;
    await expectLater(host.events.interact(), throwsStateError);
    expect(host.state, before);
  });
  test(
      'standalone battle publication is idempotent and checks the public contract',
      () async {
    final map = _map();
    final outcome = NarrativeOutcomeRef(
        producerKind: NarrativeOutcomeProducerKind.battle,
        producerId: 'trainer:coach',
        outcomeId: 'victory');
    final project = _project(map, records: [
      _event(1, NarrativeEventSourceRef.outcomeReceived(outcome), 'reward')
    ], scenes: [
      _scene('reward', [SceneConsequence.giveMoney(amount: 5)])
    ]).copyWith(trainers: const [
      ProjectTrainerEntry(id: 'coach', name: 'Coach', trainerClass: 'youngster')
    ]);
    final host = await _Host.create(project, map);
    await host.events.activateMap(_activation('standalone'));
    final request = _trainerRequest('standalone_attempt');
    expect(
        await host.events
            .publishBattleOutcome(request: request, outcomeId: 'captured'),
        isFalse);
    expect(
        await host.events
            .publishBattleOutcome(request: request, outcomeId: 'victory'),
        isTrue);
    expect(
        await host.events
            .publishBattleOutcome(request: request, outcomeId: 'victory'),
        isFalse);
    expect(host.state.trainerProfile.money, 5);
    expect(host.state.narrativeEventProgress.pendingNarrativeOutcomeDeliveries,
        isEmpty);
  });

  test(
      'wild returns cannot invent a battle producer outside the authoring catalog',
      () async {
    final map = _map();
    final host = await _Host.create(_project(map), map);
    await host.events.activateMap(_activation('wild'));
    final before = host.state;
    final request = WildBattleStartRequest(
        requestId: 'wild_attempt',
        createdAtEpochMs: 42,
        returnContext: const OverworldReturnContext(
            mapId: 'map',
            playerPos: GridPos(x: 2, y: 2),
            playerFacing: Direction.south),
        mapId: 'map',
        encounterSourceId: 'grass',
        encounterSourceKind: EncounterSourceKind.gameplayZone,
        tableId: 'grass_table',
        encounterKind: EncounterKind.walk,
        speciesId: 'zubat',
        level: 5,
        minLevel: 5,
        maxLevel: 5,
        weight: 1,
        playerPos: const GridPos(x: 2, y: 2));
    for (final outcome in ['victory', 'captured', 'runaway']) {
      expect(
          await host.events
              .publishBattleOutcome(request: request, outcomeId: outcome),
          isFalse);
    }
    expect(host.state, before);
  });
}

TrainerBattleStartRequest _trainerRequest(String attempt) =>
    TrainerBattleStartRequest(
      requestId: attempt,
      createdAtEpochMs: 42,
      returnContext: const OverworldReturnContext(
          mapId: 'map',
          playerPos: GridPos(x: 2, y: 2),
          playerFacing: Direction.south),
      trainerId: 'coach',
      npcEntityId: 'trainer',
      mapId: 'map',
      playerPos: const GridPos(x: 2, y: 2),
    );

SceneAsset _battleScene({bool failAfterBattle = false}) => SceneAsset(
    id: 'battle',
    name: 'Battle',
    graph: SceneGraph(startNodeId: 'start', nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
              battleKind: 'trainer',
              trainerId: 'coach',
              declaredOutcomes: const ['victory', 'defeat'])),
      if (failAfterBattle)
        SceneNode(
            id: 'failed',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(SceneConsequence.takeItem(
                itemId: 'missing_item', quantity: 1))),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ], edges: [
      SceneEdge(
          id: 'start_battle',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.defaultFlow),
      SceneEdge(
          id: 'victory',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: failAfterBattle ? 'failed' : 'end',
          kind: SceneEdgeKind.battleVictory),
      SceneEdge(
          id: 'defeat',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'end',
          kind: SceneEdgeKind.battleDefeat),
      if (failAfterBattle)
        SceneEdge(
            id: 'failed_end',
            fromNodeId: 'failed',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.actionCompleted),
    ]));

final class _Host {
  _Host(this.state);
  GameState state;
  late SpatialGameplayEvents events;
  final gate = NarrativeRuntimeActivityGate();
  final battles = <WildBattleStartRequest>[];
  bool canInput = true;
  int serial = 10;

  static Future<_Host> create(
    ProjectManifest project,
    MapData map, {
    GameState? state,
    Future<String> Function()? dialogue,
    Future<void> Function(MapEntity, DialogueRef)? showEntityDialogue,
    Map<String, MapData>? maps,
    SpatialSceneCallbackFactory? createSceneCallbacks,
    SpatialSceneConsequenceWriterFactory? buildSceneConsequenceWriter,
    Future<void> Function(GameState)? afterStateCommitted,
    Future<void> Function(Object)? onSceneTerminated,
    Future<void> Function(GameState)? persistItemPickup,
    Future<void> Function(MapEntity, SpatialItemPickupResult, String)?
    presentItemPickup,
    DateTime Function()? now,
    Iterable<ProjectModel3dEntry> Function()? currentModelDefinitions,
    ProjectManifest Function()? currentWorldProject,
  }) async {
    final host = _Host(
      state ??
          GameState(
            saveId: 'save',
            currentMapId: map.id,
            playerPosition: const GridPos(x: 2, y: 2),
            playerSpatialPosition: PlayerSpatialPosition(x: 2.5, z: 2.5),
          ),
    );
    host.events = await SpatialGameplayEvents.create(
      project: project,
      currentModelDefinitions: currentModelDefinitions,
      currentWorldProject: currentWorldProject,
      mapsById: maps ?? {map.id: map},
      readGameState: () => host.state,
      commitGameState: (state) => host.state = state,
      createSceneCallbacks:
          createSceneCallbacks ??
          (read, commit) => SceneRuntimeHostCallbacks(
            evaluateCondition: (_) => 'true',
            showDialogue: (_) async =>
                dialogue == null ? 'completed' : await dialogue(),
            startBattle: (_) => 'victory',
            playCinematic: (_) => 'completed',
          ),
      showEntityDialogue: showEntityDialogue ?? (_, __) async {},
      startWildBattle: (request) async => host.battles.add(request),
      activityGate: host.gate,
      isActive: () => true,
      canProcessInput: () => host.canInput,
      runtimeIdFactory: (prefix) => _id(prefix, host.serial++),
      afterStateCommitted: afterStateCommitted,
      onSceneTerminated: onSceneTerminated,
      persistItemPickup: persistItemPickup,
      presentItemPickup: presentItemPickup,
      buildSceneConsequenceWriter: buildSceneConsequenceWriter,
      random: Random(41),
      now: now ?? () => DateTime.fromMillisecondsSinceEpoch(42),
    );
    return host;
  }

  void moveTo(double x, double z) {
    state = state.copyWith(
        playerPosition: GridPos(x: x.floor(), y: z.floor()),
        playerSpatialPosition: PlayerSpatialPosition(x: x, z: z));
  }
}

final class _CountingIterable<T> extends IterableBase<T> {
  _CountingIterable(this.values);

  final Iterable<T> values;
  int iterations = 0;
  int reads = 0;

  @override
  Iterator<T> get iterator {
    iterations++;
    return values.map((value) {
      reads++;
      return value;
    }).iterator;
  }
}

final class _CountingList<T> extends ListBase<T> {
  _CountingList(this.values);

  final List<T> values;
  int reads = 0;

  @override
  int get length => values.length;

  @override
  set length(int value) => values.length = value;

  @override
  T operator [](int index) {
    reads++;
    return values[index];
  }

  @override
  void operator []=(int index, T value) => values[index] = value;
}

ProjectModel3dEntry _interactionModel({double minX = -.1, double maxX = .1}) =>
    ProjectModel3dEntry(
      id: 'orb',
      name: 'Orb',
      sourceAssetId: 'orb-source',
      relativePath: 'assets/models3d/orb.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3(x: minX, y: 0, z: -.1),
          max: Model3dVector3(x: maxX, y: 1, z: .1),
        ),
        meshCount: 1,
        triangleCount: 1,
      ),
    );

SpatialModelInstance _interactionInstance(String id, {String? entityId}) =>
    SpatialModelInstance(
      id: id,
      modelId: 'orb',
      entityId: entityId,
      position: Model3dVector3(x: 2.5, y: 0, z: 3.5),
    );

MapData _modelMap(
  List<SpatialModelInstance> instances, {
  List<MapEntity> entities = const [],
}) {
  final map = _map(entities: entities);
  return map.copyWith(
    spatialScene: map.spatialScene!.copyWith(instances: instances),
  );
}

String _id(String prefix, int value) =>
    '${prefix}_019abcde-0000-7000-8000-${value.toRadixString(16).padLeft(12, '0')}';
MapActivation _activation(String id,
        [MapActivationReason reason = MapActivationReason.initialBoot]) =>
    MapActivation(activationId: id, mapId: 'map', reason: reason);

MapData _map(
        {List<MapEntity> entities = const [],
        List<MapTrigger> triggers = const [],
        List<MapGameplayZone> zones = const []}) =>
    MapData(
      id: 'map',
      name: 'Spatial village',
      size: const GridSize(width: 6, height: 6),
      entities: entities,
      triggers: triggers,
      gameplayZones: zones,
      spatialScene: MapSpatialScene(
          width: 6,
          depth: 6,
          navigation:
              SpatialNavigationProfile(spawn: SpatialSpawn(x: 2.5, z: 2.5))),
    );

ProjectManifest _project(MapData map,
        {List<NarrativeEventRecord> records = const [],
        List<SceneAsset> scenes = const [],
        List<WorldRuleDefinition> worldRules = const []}) =>
    ProjectManifest(
      name: 'Spatial events',
      tilesets: const [],
      settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
          tileWidth: 32,
          tileHeight: 24),
      maps: [
        ProjectMapEntry(
            id: map.id, name: map.name, relativePath: 'maps/map.json')
      ],
      dialogues: const [
        ProjectDialogueEntry(
            id: 'talk', name: 'Talk', relativePath: 'dialogues/talk.yarn')
      ],
      eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: records,
          legacyClaims: const []),
      scenes: scenes,
      worldRules: worldRules,
    );

NarrativeEventRecord _event(
        int id, NarrativeEventSourceRef source, String sceneId,
        {bool oneShot = true,
        List<NarrativeEventCondition> conditions = const []}) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
        NarrativeEventDefinition(
          id: _id('evt', id),
          name: sceneId,
          source: source,
          conditions: conditions,
          sceneId: sceneId,
          reusePolicy: oneShot
              ? NarrativeEventReusePolicy.oneShot
              : NarrativeEventReusePolicy.reusable,
          priority: 0,
          order: id,
          resetPolicy: const NarrativeEventResetPolicy.never(),
        ),
        enabled: true);

SceneAsset _scene(String id, List<SceneConsequence> consequences,
    {bool dialogue = false, String? outcome}) {
  final nodes = <SceneNode>[
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    for (var index = 0; index < consequences.length; index++)
      SceneNode(
          id: 'action_$index',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(consequences[index])),
    if (dialogue)
      SceneNode(
          id: 'dialogue',
          kind: SceneNodeKind.yarnDialogue,
          payload: SceneYarnDialoguePayload(dialogueId: 'talk')),
    SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload:
            outcome == null ? null : SceneEndPayload(sceneOutcomeId: outcome)),
  ];
  return SceneAsset(
      id: id,
      name: id,
      declaredOutcomes: [
        if (outcome != null) SceneOutcome(id: outcome, label: outcome)
      ],
      graph: SceneGraph(startNodeId: 'start', nodes: nodes, edges: [
        for (var index = 0; index < nodes.length - 1; index++)
          SceneEdge(
            id: 'edge_$index',
            fromNodeId: nodes[index].id,
            fromPortId: 'completed',
            toNodeId: nodes[index + 1].id,
            kind: nodes[index].kind == SceneNodeKind.action
                ? SceneEdgeKind.actionCompleted
                : nodes[index].kind == SceneNodeKind.yarnDialogue
                    ? SceneEdgeKind.defaultFlow
                    : SceneEdgeKind.defaultFlow,
          )
      ]));
}
