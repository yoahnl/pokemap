import 'dart:async';

import 'package:avelune_studio/features/scenes/application/scene_actor_action_draft.dart';
import 'package:avelune_studio/features/scenes/application/scene_action_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

ProjectManifest _project({
  List<ProjectCharacterEntry>? characters,
  List<CinematicMediaAsset>? media,
  bool spatial = false,
}) => ProjectManifest(
  name: 'Original actor UI QA',
  maps: const [
    ProjectMapEntry(
      id: 'alpha',
      name: 'Alpha',
      relativePath: 'maps/alpha.json',
    ),
    ProjectMapEntry(id: 'beta', name: 'Beta', relativePath: 'maps/beta.json'),
  ],
  settings: ProjectSettings(
    dimension: spatial ? ProjectDimension.threeD : ProjectDimension.twoD,
  ),
  tilesets: const [
    ProjectTilesetEntry(
      id: 'sheet',
      name: 'Original QA sheet',
      relativePath: 'assets/sheet.png',
    ),
  ],
  characters:
      characters ??
      const [
        ProjectCharacterEntry(
          id: 'actor-character',
          name: 'Original actor',
          tilesetId: 'sheet',
        ),
      ],
  cinematicMediaAssets:
      media ??
      [
        for (final id in ['door', 'bell'])
          CinematicMediaAsset(
            id: id,
            label: id == 'door' ? 'Porte' : 'Cloche',
            kind: CinematicMediaAssetKind.sound,
            relativePath: 'audio/$id.wav',
          ),
      ],
);

MapData _map(String id, {List<MapEntity>? entities, bool spatial = false}) =>
    MapData(
      version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
      id: id,
      name: id,
      size: const GridSize(width: 4, height: 4),
      spatialScene: spatial ? MapSpatialScene(width: 4, depth: 4) : null,
      entities:
          entities ??
          [
            MapEntity(
              id: 'actor',
              name: '$id actor',
              kind: MapEntityKind.npc,
              pos: const GridPos(x: 1, y: 1),
              npc: const MapEntityNpcData(characterId: 'actor-character'),
            ),
          ],
    );

List<SceneActorRouteStep> _steps() => [
  SceneActorRouteStep.face(direction: EntityFacing.east, durationMs: 50),
  SceneActorRouteStep.move(direction: EntityFacing.south, durationMs: 200),
  SceneActorRouteStep.wait(durationMs: 0),
  SceneActorRouteStep.through(enabled: true),
  SceneActorRouteStep.sound(mediaAssetId: 'bell', gain: 0.35),
];

SceneActionPayload _route({
  SceneActorTarget? target,
  List<SceneActorRouteStep>? steps,
  ActorRouteTransientScope transientScope = ActorRouteTransientScope.route,
}) => SceneActionPayload.interactive(
  SceneInteractiveCommand.actorRoute(
    target:
        target ?? SceneActorTarget.entity(mapId: 'alpha', entityId: 'actor'),
    steps: steps ?? _steps(),
    skippable: true,
    transientScope: transientScope,
  ),
  actionKind: 'keep-action',
  parameters: const {'keep': 'parameter'},
);

SceneActionPayload _egress({List<SceneActorRouteStep>? steps}) => _route(
  target: SceneActorTarget.player(mapId: 'alpha'),
  steps:
      steps ??
      [
        SceneActorRouteStep.move(
          direction: EntityFacing.south,
          durationMs: 200,
          initialCollisionOwnerEntityId: 'actor',
        ),
      ],
);

Future<SceneActorActionDraft> _ready({
  ProjectManifest? project,
  SceneActionPayload? current,
  Future<MapData> Function(String)? loadMap,
  bool withLoader = true,
  String commandId = NarrativeCommandIds.actorRoute,
}) async {
  final ready = Completer<void>();
  late SceneActorActionDraft draft;
  draft = SceneActorActionDraft(
    project: project ?? _project(),
    current: current ?? _route(),
    commandId: commandId,
    loadMap: withLoader ? loadMap ?? (id) async => _map(id) : null,
    changed: () {
      if (!draft.loading && !ready.isCompleted) ready.complete();
    },
  );
  if (!draft.loading) ready.complete();
  addTearDown(draft.dispose);
  await ready.future;
  return draft;
}

void main() {
  for (final enabled in [false, true]) {
    test(
      'all typed route steps and transient restoration survive round trip render=$enabled',
      () async {
        final original = _route(
          transientScope: ActorRouteTransientScope.scene,
          steps: [
            ..._steps().take(2),
            SceneActorRouteStep.moveDiagonal(
              horizontal: EntityFacing.west,
              vertical: EntityFacing.north,
              durationMs: 350,
            ),
            ..._steps().skip(2).take(2),
            SceneActorRouteStep.renderAboveMap(enabled: enabled),
            SceneActorRouteStep.visibility(visible: enabled),
            _steps().last,
          ],
        );
        final draft = await _ready(current: original);
        expect(draft.payload, original);
        expect(SceneActionPayload.fromJson(draft.payload!.toJson()), original);
        draft.steps[2]
          ..horizontal = EntityFacing.east
          ..vertical = EntityFacing.south
          ..durationText = '420';
        draft.transientScope = ActorRouteTransientScope.route;
        final changed =
            draft.payload!.interactiveCommand
                as SceneActorRouteInteractiveCommand;
        expect(
          changed.steps[2],
          SceneActorRouteStep.moveDiagonal(
            horizontal: EntityFacing.east,
            vertical: EntityFacing.south,
            durationMs: 420,
          ),
        );
        expect(changed.transientScope, ActorRouteTransientScope.route);
        expect(draft.payload!.parameters, original.parameters);
        expect(draft.payload!.actionKind, original.actionKind);
      },
    );
  }

  test('appearance changes retain the target and metadata', () async {
    final project = _project(
      characters: [
        for (final id in ['actor-character', 'costume'])
          ProjectCharacterEntry(
            id: id,
            name: id,
            tilesetId: 'sheet',
            animations: [
              CharacterAnimation(
                state: CharacterAnimationState.idle,
                direction: EntityFacing.south,
                frames: const [
                  CharacterAnimationFrame(
                    source: TilesetSourceRect(x: 0, y: 0),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
    final original = _route(
      steps: [SceneActorRouteStep.appearance(characterId: 'actor-character')],
    );
    final draft = await _ready(project: project, current: original);
    expect(draft.characterOptions, contains('costume'));
    draft.steps.single.characterId = 'costume';
    final command =
        draft.payload!.interactiveCommand as SceneActorRouteInteractiveCommand;
    expect(command.steps, [
      SceneActorRouteStep.appearance(characterId: 'costume'),
    ]);
    expect(
      command.target,
      (original.interactiveCommand as SceneActorRouteInteractiveCommand).target,
    );
    expect(draft.current, same(original));
  });

  test('face yielding can change without losing its duration', () async {
    final draft = await _ready(
      current: _route(
        steps: [
          SceneActorRouteStep.face(
            direction: EntityFacing.east,
            durationMs: 50,
            yieldAfter: true,
          ),
        ],
      ),
    );
    expect(draft.steps.single.yieldAfter, isTrue);
    draft.steps.single.yieldAfter = false;
    expect(
      (draft.payload!.interactiveCommand as SceneActorRouteInteractiveCommand)
          .steps
          .single,
      SceneActorRouteStep.face(direction: EntityFacing.east, durationMs: 50),
    );
  });

  test('diagonal axes duration and inherited collision owner are validated before a payload exists', () async {
    final draft = await _ready(current: _egress());
    final step = draft.steps.single;
    step.changeKind(SceneActorRouteStepKind.moveDiagonal);
    expect(step.initialCollisionOwnerEntityId, 'actor');
    expect(draft.payload, isNull);
    draft.selectInitialOwner(step, '');
    expect(draft.payload, isNotNull);
    for (final invalid in ['0', '-1', '5.2', 'bad', '2147483648']) {
      step.durationText = invalid;
      expect(draft.payload, isNull);
    }
    step.durationText = '200';
    step.horizontal = EntityFacing.north;
    expect(draft.payload, isNull);
    step.horizontal = EntityFacing.east;
    step.vertical = EntityFacing.west;
    expect(draft.payload, isNull);
  });

  test(
    'egress owner survives edits reordering adding and deleting steps',
    () async {
      final draft = await _ready(current: _egress());
      final move = draft.steps.single;
      move
        ..direction = EntityFacing.west
        ..durationText = '350';
      final wait = draft.addStep()
        ..kind = SceneActorRouteStepKind.wait
        ..durationText = '1';
      draft.moveStep(move, 1);
      expect(draft.steps.last, same(move));
      expect(move.initialCollisionOwnerEntityId, 'actor');
      draft.removeStep(wait);
      expect(draft.steps.single, same(move));
      expect(draft.payload, isNotNull);
      draft.moveStep(move, -1);
      expect(draft.steps.single, same(move));
      draft.targetKind = SceneActorTargetKind.entity;
      draft.selectedEntityId = 'actor';
      expect(draft.payload, isNull);
      draft.selectInitialOwner(move, '');
      expect(draft.payload, isNotNull);
    },
  );

  test('cumulative through state invalidates an egress until reordered or explicitly cleared', () async {
    final draft = await _ready(
      current: _egress(
        steps: [
          SceneActorRouteStep.through(enabled: false),
          SceneActorRouteStep.move(
            direction: EntityFacing.south,
            durationMs: 200,
            initialCollisionOwnerEntityId: 'actor',
          ),
        ],
      ),
    );
    draft.steps.first.enabled = true;
    expect(draft.payload, isNull);
    final move = draft.steps.last;
    draft.moveStep(move, -1);
    expect(draft.payload, isNotNull);
    draft.moveStep(move, 1);
    expect(draft.payload, isNull);
    draft.steps.first.enabled = false;
    expect(draft.payload, isNotNull);
    move.changeKind(SceneActorRouteStepKind.face);
    expect(move.initialCollisionOwnerEntityId, 'actor');
    expect(draft.payload, isNull);
    draft.selectInitialOwner(move, '');
    expect(draft.payload, isNotNull);
  });

  test('egress map identity cannot silently rebind a same ID owner', () async {
    final draft = await _ready(current: _egress());
    final move = draft.steps.single;
    final oldOption = draft.initialOwnerOptionKey('actor');
    draft.selectedMapId = 'beta';
    final loaded = Completer<void>();
    draft.loadMap = (id) async {
      final result = _map(id);
      scheduleMicrotask(() => loaded.complete());
      return result;
    };
    draft.reloadMap();
    await loaded.future;
    await Future<void>.delayed(Duration.zero);
    expect(draft.payload, isNull);
    draft.selectInitialOwner(move, oldOption);
    expect(move.initialCollisionOwnerMapId, 'alpha');
    draft.selectInitialOwner(move, draft.initialOwnerOptionKey('actor'));
    expect(move.initialCollisionOwnerMapId, 'beta');
    expect(draft.payload, isNotNull);
  });

  for (final mode in [
    'sign',
    'ghost',
    'missing-character',
    'duplicate-entity',
    'duplicate-character',
    'wide-contact',
    'default-tall',
    'shifted-contact',
    'removed',
    'spatial',
    'wrong-map',
  ]) {
    test('egress refuses $mode while preserving its exact reference', () async {
      final entity = _map('alpha').entities.single;
      final project = _project();
      final entities = switch (mode) {
        'sign' => [entity.copyWith(kind: MapEntityKind.sign)],
        'ghost' => [entity.copyWith(npc: const MapEntityNpcData())],
        'missing-character' => [
          entity.copyWith(npc: const MapEntityNpcData(characterId: 'missing')),
        ],
        'duplicate-entity' => [
          entity,
          entity.copyWith(kind: MapEntityKind.sign),
        ],
        'wide-contact' => [
          entity.copyWith(size: const GridSize(width: 2, height: 1)),
        ],
        'default-tall' => [
          entity.copyWith(size: const GridSize(width: 1, height: 2)),
        ],
        'shifted-contact' => [
          entity.copyWith(
            size: const GridSize(width: 2, height: 1),
            properties: const {
              'collision.width': '1',
              'collision.height': '1',
              'collision.offsetX': '1',
            },
          ),
        ],
        'removed' => <MapEntity>[],
        _ => [entity],
      };
      final draft = await _ready(
        current: _egress(),
        project: mode == 'duplicate-character'
            ? project.copyWith(
                characters: [...project.characters, ...project.characters],
              )
            : project,
        loadMap: (id) async => _map(
          mode == 'wrong-map' ? 'beta' : id,
          entities: entities,
          spatial: mode == 'spatial',
        ),
      );
      expect(draft.payload, isNull);
      expect(draft.steps.single.initialCollisionOwnerEntityId, 'actor');
      if (mode != 'spatial' && mode != 'wrong-map') {
        draft.selectInitialOwner(draft.steps.single, '');
        expect(draft.payload, isNotNull);
      }
    });
  }

  test('trainer-backed tall NPC with a canonical one-cell footprint is a valid egress owner', () async {
    final entity = _map('alpha').entities.single.copyWith(
      size: const GridSize(width: 1, height: 2),
      properties: const {'collision.height': '1', 'collision.offsetY': '0'},
      npc: const MapEntityNpcData(trainerId: 'trainer'),
    );
    final project = _project().copyWith(
      trainers: const [
        ProjectTrainerEntry(
          id: 'trainer',
          name: 'Trainer',
          trainerClass: 'QA',
          characterId: 'actor-character',
        ),
      ],
    );
    final draft = await _ready(
      current: _egress(),
      project: project,
      loadMap: (id) async => _map(id, entities: [entity]),
    );
    expect(draft.payload, _egress());
  });

  for (final kind in [
    SceneActorTargetKind.player,
    SceneActorTargetKind.entity,
  ]) {
    test('visibility retains $kind target and action metadata', () async {
      final target = kind == SceneActorTargetKind.player
          ? SceneActorTarget.player(mapId: 'alpha')
          : SceneActorTarget.entity(mapId: 'alpha', entityId: 'actor');
      final original = SceneActionPayload.interactive(
        SceneInteractiveCommand.actorVisibility(target: target, visible: false),
        actionKind: 'keep',
        parameters: const {'collision': 'preserved'},
      );
      final draft = await _ready(
        current: original,
        commandId: NarrativeCommandIds.actorVisibility,
      );
      expect(draft.payload, original);
      draft.visible = true;
      final command =
          draft.payload!.interactiveCommand
              as SceneActorVisibilityInteractiveCommand;
      expect(command.visible, isTrue);
      expect(command.target, target);
      expect(draft.payload!.parameters, original.parameters);
    });
  }

  test('invalid gain duration and removed or looping sound cannot replace an imported route', () async {
    final original = _route();
    final draft = await _ready(current: original);
    final sound = draft.steps.last;
    for (final invalid in ['NaN', 'Infinity', '-0.1', '1.01', 'bad']) {
      sound.gainText = invalid;
      expect(draft.payload, isNull);
    }
    sound.gainText = '0.35';
    draft.steps.first.durationText = '-1';
    expect(draft.payload, isNull);
    draft.steps.first.durationText = '50';
    draft.project = _project(
      media: [
        CinematicMediaAsset(
          id: 'bell',
          label: 'Cloche',
          kind: CinematicMediaAssetKind.sound,
          relativePath: 'bell.wav',
          loopByDefault: true,
        ),
      ],
    );
    expect(draft.soundOptions, isNot(contains('bell')));
    expect(draft.payload, isNull);
    expect(draft.current, same(original));
  });

  test('3D dimension missing loader and ambiguous map descriptors cannot supply an actor', () async {
    final original = _egress();
    final spatial = await _ready(
      project: _project(spatial: true),
      current: original,
    );
    expect(spatial.mapOptions, isEmpty);
    expect(spatial.payload, isNull);
    final missing = await _ready(current: original, withLoader: false);
    expect(missing.payload, isNull);
    final project = _project();
    final duplicate = await _ready(
      current: original,
      project: project.copyWith(maps: [...project.maps, project.maps.first]),
    );
    expect(duplicate.mapOptions, isNot(contains('alpha')));
    expect(duplicate.payload, isNull);
  });
  for (final known in [true, false]) {
    test(
      'conditional actor requires every referenced character known=$known',
      () async {
        final entity = MapEntity(
          id: 'actor',
          name: 'Conditional actor',
          kind: MapEntityKind.custom,
          pos: const GridPos(x: 1, y: 1),
          presentation: MapEntityPresentation(
            variants: [
              for (final pair in <String?>[
                'actor-character',
                known ? 'second-character' : 'missing',
                null,
              ].indexed)
                MapEntityPresentationVariant(
                  id: 'variant_${pair.$1}',
                  condition: NarrativeEventConditionExpression.all(const []),
                  characterId: pair.$2,
                  blocksMovement: pair.$2 != null,
                ),
            ],
          ),
        );
        final draft = await _ready(
          project: _project(
            characters: const [
              ProjectCharacterEntry(
                id: 'actor-character',
                name: 'First',
                tilesetId: 'sheet',
              ),
              ProjectCharacterEntry(
                id: 'second-character',
                name: 'Second',
                tilesetId: 'sheet',
              ),
            ],
          ),
          loadMap: (id) async => _map(id, entities: [entity]),
        );
        expect(draft.actorOptions.containsKey('actor'), known);
        expect(draft.payload != null, known);
      },
    );
  }

  for (final mode in ['known', 'duplicate', 'missing-character']) {
    test(
      'trainer-backed actor resolves unique references mode=$mode',
      () async {
        const trainer = ProjectTrainerEntry(
          id: 'trainer',
          name: 'Trainer',
          trainerClass: 'QA',
          characterId: 'actor-character',
        );
        final project = _project().copyWith(
          trainers: [trainer, if (mode == 'duplicate') trainer],
          characters: mode == 'missing-character' ? [] : _project().characters,
        );
        final draft = await _ready(
          project: project,
          loadMap: (id) async => _map(
            id,
            entities: [
              MapEntity(
                id: 'actor',
                kind: MapEntityKind.npc,
                pos: const GridPos(x: 1, y: 1),
                npc: const MapEntityNpcData(trainerId: 'trainer'),
              ),
            ],
          ),
        );
        expect(draft.payload != null, mode == 'known');
      },
    );
  }

  for (final mode in ['duplicate', 'loop', 'removed']) {
    test(
      'sound registry counts every kind and refuses $mode references',
      () async {
        final project = _project();
        final bell = project.cinematicMediaAssets.last;
        final draft = await _ready(
          project: project.copyWith(
            cinematicMediaAssets: [
              project.cinematicMediaAssets.first,
              if (mode != 'removed')
                CinematicMediaAsset(
                  id: bell.id,
                  label: bell.label,
                  kind: bell.kind,
                  relativePath: bell.relativePath,
                  loopByDefault: mode == 'loop',
                ),
              if (mode == 'duplicate')
                CinematicMediaAsset(
                  id: bell.id,
                  label: bell.label,
                  kind: CinematicMediaAssetKind.music,
                  relativePath: bell.relativePath,
                ),
            ],
          ),
        );
        expect(draft.soundOptions.keys, ['door']);
        expect(draft.payload, isNull);
      },
    );
  }

  for (final failure in [false, true]) {
    test(
      'latest actor map wins over stale success or failure=$failure',
      () async {
        final old = Completer<MapData>(), latest = Completer<MapData>();
        var loadingNew = false;
        var observed = Completer<void>();
        late SceneActorActionDraft draft;
        draft = SceneActorActionDraft(
          project: _project(),
          commandId: NarrativeCommandIds.actorRoute,
          current: _egress(),
          loadMap: (id) => loadingNew
              ? id == 'beta'
                    ? old.future
                    : latest.future
              : Future.value(_map(id)),
          changed: () {
            if (!draft.loading && !observed.isCompleted) observed.complete();
          },
        );
        addTearDown(draft.dispose);
        await observed.future;
        loadingNew = true;
        observed = Completer<void>();
        draft.selectedMapId = 'beta';
        draft.reloadMap();
        draft.selectedMapId = 'alpha';
        draft.reloadMap();
        latest.complete(_map('alpha'));
        await observed.future;
        if (failure) {
          old.completeError(StateError('Stale'));
        } else {
          old.complete(_map('beta'));
        }
        await Future<void>.delayed(Duration.zero);
        expect(draft.stageMap!.id, 'alpha');
        expect(draft.mapError, isNull);
        expect(draft.payload, _egress());
      },
    );
  }
  test('new actor route creates each ordered native step with no implicit egress owner', () async {
    final draft = SceneActorActionDraft(
      project: _project(),
      commandId: NarrativeCommandIds.actorRoute,
      current: null,
      changed: () {},
      loadMap: (id) async => _map(id),
    );
    addTearDown(draft.dispose);
    expect(draft.payload, isNull);
    draft.selectedMapId = 'alpha';
    draft.targetKind = SceneActorTargetKind.entity;
    draft.selectedEntityId = 'actor';
    draft.reloadMap();
    await Future<void>.delayed(Duration.zero);
    final face = draft.addStep()
      ..direction = EntityFacing.east
      ..durationText = '50';
    final move = draft.addStep()
      ..kind = SceneActorRouteStepKind.move
      ..direction = EntityFacing.south
      ..durationText = '200';
    expect(move.initialCollisionOwnerEntityId, isNull);
    draft.addStep()
      ..kind = SceneActorRouteStepKind.wait
      ..durationText = '0';
    draft.addStep()
      ..kind = SceneActorRouteStepKind.through
      ..enabled = true;
    draft.addStep()
      ..kind = SceneActorRouteStepKind.sound
      ..soundId = 'bell'
      ..gainText = '0.35';
    final command =
        draft.payload!.interactiveCommand as SceneActorRouteInteractiveCommand;
    expect(command.steps, _steps());
    expect(
      command.target,
      SceneActorTarget.entity(mapId: 'alpha', entityId: 'actor'),
    );
    expect(command.skippable, isFalse);
    draft.moveStep(move, -1);
    draft.removeStep(draft.steps[2]);
    final added = draft.addStep()
      ..kind = SceneActorRouteStepKind.wait
      ..durationText = '75';
    expect(added.id, 5);
    expect(
      (draft.payload!.interactiveCommand as SceneActorRouteInteractiveCommand)
          .steps,
      [
        _steps()[1],
        _steps()[0],
        _steps()[3],
        _steps()[4],
        SceneActorRouteStep.wait(durationMs: 75),
      ],
    );
    expect(draft.steps[1], same(face));
  });

  test(
    'new visibility action chooses the exact player map with visible default',
    () async {
      final draft = SceneActorActionDraft(
        project: _project(),
        commandId: NarrativeCommandIds.actorVisibility,
        current: null,
        changed: () {},
        loadMap: (id) async => _map(id),
      );
      addTearDown(draft.dispose);
      draft.selectedMapId = 'beta';
      draft.reloadMap();
      await Future<void>.delayed(Duration.zero);
      expect(
        draft.payload!.interactiveCommand,
        SceneInteractiveCommand.actorVisibility(
          target: SceneActorTarget.player(mapId: 'beta'),
          visible: true,
        ),
      );
    },
  );

  test('actor target refuses non-NPC missing duplicated and unknown character references', () async {
    final project = _project();
    final actor = _map('alpha').entities.single;
    for (final mode in [
      'sign',
      'empty',
      'unknown',
      'duplicate-entity',
      'duplicate-character',
      'removed',
    ]) {
      final entities = switch (mode) {
        'sign' => [actor.copyWith(kind: MapEntityKind.sign)],
        'empty' => [actor.copyWith(npc: const MapEntityNpcData())],
        'unknown' => [
          actor.copyWith(npc: const MapEntityNpcData(characterId: 'missing')),
        ],
        'duplicate-entity' => [actor, actor],
        'removed' => <MapEntity>[],
        _ => [actor],
      };
      final original = _route();
      final draft = await _ready(
        project: mode == 'duplicate-character'
            ? project.copyWith(
                characters: [...project.characters, ...project.characters],
              )
            : project,
        current: original,
        loadMap: (id) async => _map(id, entities: entities),
      );
      expect(draft.actorOptions, isEmpty, reason: mode);
      expect(draft.payload, isNull, reason: mode);
      expect(draft.current, same(original));
    }
  });

  test('canonical command catalog exposes native actors only in two dimensional projects', () {
    final twoD = SceneActionDraft(project: _project(), changed: () {});
    addTearDown(twoD.dispose);
    expect(
      twoD.commands.map((command) => command.id),
      containsAll([
        NarrativeCommandIds.actorRoute,
        NarrativeCommandIds.actorVisibility,
      ]),
    );
    final threeD = SceneActionDraft(
      project: _project(spatial: true),
      changed: () {},
      commandCatalog: twoD.commands,
    );
    addTearDown(threeD.dispose);
    expect(
      threeD.commands.map((command) => command.id),
      isNot(contains(NarrativeCommandIds.actorRoute)),
    );
    expect(
      threeD.commands.map((command) => command.id),
      isNot(contains(NarrativeCommandIds.actorVisibility)),
    );
  });
}
