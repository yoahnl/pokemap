import 'dart:async';

import 'package:avelune_studio/features/scenes/application/scene_action_draft.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('new warp selects a native arrival with canonical defaults and passive Scene identity', () async {
    final loaded = <String>[];
    final draft = _draft(
      _warpProject(),
      loadMap: (id) async {
        loaded.add(id);
        return _map(id);
      },
    );
    draft.choose(NarrativeCommandIds.warp);
    expect(draft.valid, isFalse);
    draft.changeParameter('destinationMapId', 'village');
    await _settle();
    expect(loaded, ['village']);
    expect(draft.valid, isFalse);
    expect(draft.options(NarrativeCommandParameterKind.warp).keys, [
      'village-entry',
    ]);
    draft.changeParameter('warpId', 'village-entry');
    expect(draft.valid, isTrue);
    expect(_command(draft).toJson(), {
      'kind': 'warp',
      'destinationMapId': 'village',
      'warpId': 'village-entry',
      'transition': 'mapDefault',
    });
    final passive = _draft(
      _warpProject(),
      loadMap: (id) async => _map(id).copyWith(
        warps: [
          MapWarp(
            id: 'scene-arrival',
            pos: const GridPos(x: 2, y: 3),
            targetMapId: id,
            targetPos: const GridPos(x: 2, y: 3),
            triggerMode: MapWarpTriggerMode.sceneOnly,
          ),
        ],
      ),
    );
    passive.choose(NarrativeCommandIds.warp);
    passive.changeParameter('destinationMapId', 'village');
    await _settle();
    passive.changeParameter('warpId', 'scene-arrival');
    expect(passive.valid, isTrue);
    expect(_command(passive).toJson()['warpId'], 'scene-arrival');
  });

  test(
    'warp direction transition and opaque metadata round trip without applying',
    () async {
      final original = SceneActionPayload.interactive(
        SceneInteractiveCommand.fromJson({
          'kind': 'warp',
          'destinationMapId': 'village',
          'warpId': 'village-entry',
          'arrivalFacing': 'east',
          'transition': 'none',
        }),
        actionKind: 'imported-transfer',
        parameters: const {'sourceEvent': '12'},
      );
      final draft = _draft(
        _warpProject(),
        current: original,
        loadMap: (id) async => _map(id),
      );
      await _settle();
      expect(draft.valid, isTrue);
      expect(draft.buildPayload(), original);
      for (final facing in ['north', 'south', 'east', 'west']) {
        draft.changeParameter('arrivalFacing', facing);
        expect(draft.valid, isTrue);
        final result = draft.buildPayload() as SceneActionPayload;
        expect(result.interactiveCommand!.toJson(), {
          'kind': 'warp',
          'destinationMapId': 'village',
          'warpId': 'village-entry',
          'arrivalFacing': facing,
          'transition': 'none',
        });
        expect(result.actionKind, original.actionKind);
        expect(result.parameters, original.parameters);
      }
      draft.changeParameter('arrivalFacing', '');
      draft.changeParameter('transition', 'mapDefault');
      expect(_command(draft).toJson().containsKey('arrivalFacing'), isFalse);
      expect(_command(draft).toJson()['transition'], 'mapDefault');
      expect(draft.current, same(original));
    },
  );

  test('changing warp destination clears even a shared arrival ID', () async {
    final original = SceneActionPayload.interactive(
      SceneInteractiveCommand.warp(
        destinationMapId: 'village',
        warpId: 'shared-entry',
      ),
    );
    final draft = _draft(
      _warpProject(),
      current: original,
      loadMap: (id) async => _map(id).copyWith(
        warps: [
          MapWarp(
            id: 'shared-entry',
            pos: const GridPos(x: 2, y: 3),
            targetMapId: 'other',
            targetPos: const GridPos(x: 1, y: 1),
          ),
        ],
      ),
    );
    await _settle();
    expect(draft.valid, isTrue);
    draft.changeParameter('destinationMapId', 'forest');
    await _settle();
    expect(draft.values['warpId'], isNull);
    expect(draft.valid, isFalse);
    expect(draft.current, same(original));
  });

  test('removed arrival and destination stay recorded and cannot apply or read a missing map', () async {
    final removedArrival = SceneActionPayload.interactive(
      SceneInteractiveCommand.warp(
        destinationMapId: 'village',
        warpId: 'deleted-entry',
      ),
    );
    final draft = _draft(
      _warpProject(),
      current: removedArrival,
      loadMap: (id) async => _map(id),
    );
    await _settle();
    expect(draft.options(NarrativeCommandParameterKind.warp).keys, [
      'village-entry',
    ]);
    expect(draft.values['warpId'], 'deleted-entry');
    expect(draft.valid, isFalse);
    expect(draft.current, same(removedArrival));
    final loaded = <String>[];
    final removedDestination = SceneActionPayload.interactive(
      SceneInteractiveCommand.warp(
        destinationMapId: 'removed',
        warpId: 'entry',
      ),
    );
    final missing = _draft(
      _warpProject(),
      current: removedDestination,
      loadMap: (id) async {
        loaded.add(id);
        return _map(id);
      },
    );
    await _settle();
    expect(loaded, isEmpty);
    expect(missing.valid, isFalse);
    expect(missing.values['destinationMapId'], 'removed');
    expect(missing.current, same(removedDestination));
  });

  test('warp draft rejects wrong map identity and an unavailable loader and retries failures', () async {
    final original = SceneActionPayload.interactive(
      SceneInteractiveCommand.warp(
        destinationMapId: 'village',
        warpId: 'village-entry',
      ),
    );
    final wrong = _draft(
      _warpProject(),
      current: original,
      loadMap: (_) async => _map('forest'),
    );
    await _settle();
    expect(wrong.referenceMap, isNull);
    expect(wrong.referenceError, isNotNull);
    expect(wrong.valid, isFalse);
    final unavailable = _draft(_warpProject(), current: original);
    await _settle();
    expect(unavailable.options(NarrativeCommandParameterKind.warp), isEmpty);
    expect(unavailable.valid, isFalse);
    var attempts = 0;
    final retry = _draft(
      _warpProject(),
      current: original,
      loadMap: (id) async {
        if (++attempts == 1) throw StateError('Unavailable');
        return _map(id);
      },
    );
    await _settle();
    expect(retry.valid, isFalse);
    expect(retry.referenceError, isNotNull);
    retry.loadReferenceMap();
    await _settle();
    expect(attempts, 2);
    expect(retry.referenceError, isNull);
    expect(retry.valid, isTrue);
    expect(retry.buildPayload(), original);
  });

  test('late warp map results cannot restore an older destination or notify after disposal', () async {
    final first = Completer<MapData>(), second = Completer<MapData>();
    final draft = _draft(
      _warpProject(),
      loadMap: (id) => id == 'village' ? first.future : second.future,
    );
    draft.choose(NarrativeCommandIds.warp);
    draft.changeParameter('destinationMapId', 'village');
    draft.changeParameter('destinationMapId', 'forest');
    second.complete(_map('forest'));
    await _settle();
    first.complete(_map('village'));
    await _settle();
    expect(draft.options(NarrativeCommandParameterKind.warp).keys, [
      'forest-entry',
    ]);
    final pending = Completer<MapData>();
    var notifications = 0;
    final disposed = SceneActionDraft(
      project: _warpProject(),
      changed: () => notifications++,
      current: SceneActionPayload.interactive(
        SceneInteractiveCommand.warp(
          destinationMapId: 'village',
          warpId: 'village-entry',
        ),
      ),
      loadMap: (_) => pending.future,
    );
    disposed.dispose();
    final before = notifications;
    pending.complete(_map('village'));
    await _settle();
    expect(notifications, before);
    expect(disposed.referenceMap, isNull);
  });

  test('illustrated warp keeps exact image values and cave exit clears typed image fields', () async {
    final project = _illustratedProject();
    final original = SceneActionPayload.interactive(
      SceneInteractiveCommand.warp(
        destinationMapId: 'village',
        warpId: 'village-entry',
        presentation: SceneWarpPresentation(
          mode: SceneWarpPresentationMode.illustrated,
          illustrationElementId: 'picture',
        ),
      ),
    );
    final draft = _draft(
      project,
      current: original,
      loadMap: (id) async => _map(id),
    );
    await _settle();
    final imageField = draft.command!.parameters.singleWhere(
      (field) => field.id == 'illustrationElementId',
    );
    expect(draft.options(imageField.kind), {'picture': 'Image de la grotte'});
    expect(draft.valid, isTrue);
    expect(draft.buildPayload(), original);
    draft.changeParameter('presentationMode', 'caveExit');
    expect(draft.valid, isTrue);
    final command = _command(draft) as SceneWarpInteractiveCommand;
    expect(command.presentation!.mode, SceneWarpPresentationMode.caveExit);
    expect(command.presentation!.illustrationElementId, isNull);
    expect(command.presentation!.illustrationHoldMs, isNull);
    final missing = _draft(
      project.copyWith(elements: []),
      current: original,
      loadMap: (id) async => _map(id),
    );
    await _settle();
    expect(missing.valid, isFalse);
    expect(missing.values['illustrationElementId'], 'picture');
    expect(missing.current, same(original));
  });

  test('3D basic warp keeps its exact command while presentation fields are unavailable', () async {
    final original = SceneActionPayload.interactive(
      SceneInteractiveCommand.warp(
        destinationMapId: 'village',
        warpId: 'village-entry',
      ),
    );
    final draft = _draft(
      _warpProject().copyWith(
        settings: const ProjectSettings(dimension: ProjectDimension.threeD),
      ),
      current: original,
      loadMap: (id) async => _map(id),
    );
    await _settle();
    expect(
      draft.command!.parameters
          .where(
            (field) =>
                field.id == 'presentationMode' ||
                field.id == 'illustrationElementId',
          )
          .every((field) => !draft.warpFieldVisible(field)),
      isTrue,
    );
    expect(draft.valid, isTrue);
    expect(draft.buildPayload(), original);
  });

  test('3D model action resolves the placed decor clip and exact typed speed and passage', () async {
    final draft = _draft(_modelProject(), loadMap: (id) async => _modelMap(id));
    draft.choose(NarrativeCommandIds.playModelAnimation);
    expect(draft.values['speed'], '1');
    draft.changeParameter('mapId', 'village');
    await _settle();
    expect(draft.valid, isFalse);
    draft.changeParameter('instanceId', 'village-door');
    draft.changeParameter('animationIndex', '0');
    draft.changeParameter('blocksMovementAfter', 'false');
    draft.changeParameter('speed', '.25');
    expect(draft.valid, isTrue);
    expect(
      _command(draft),
      SceneInteractiveCommand.playModelAnimation(
        mapId: 'village',
        instanceId: 'village-door',
        animationIndex: 0,
        speed: .25,
        blocksMovementAfter: false,
      ),
    );
  });

  test('3D model speed and clip validation preserve source and map changes clear dependents', () async {
    final original = SceneActionPayload.interactive(
      SceneInteractiveCommand.playModelAnimation(
        mapId: 'village',
        instanceId: 'village-door',
        animationIndex: 1,
      ),
    );
    final draft = _draft(
      _modelProject(),
      current: original,
      loadMap: (id) async => _modelMap(id),
    );
    await _settle();
    expect(draft.valid, isTrue);
    for (final speed in ['17', '0', '-1', 'NaN', 'Infinity', 'bad']) {
      draft.changeParameter('speed', speed);
      expect(draft.valid, isFalse, reason: speed);
    }
    draft.changeParameter('speed', '');
    expect(draft.valid, isTrue);
    expect(
      (_command(draft) as ScenePlayModelAnimationInteractiveCommand).speed,
      1,
    );
    draft.changeParameter('animationIndex', '9');
    expect(draft.valid, isFalse);
    draft.changeParameter('animationIndex', '1');
    draft.changeParameter('mapId', 'forest');
    await _settle();
    expect(draft.values['instanceId'], isNull);
    expect(draft.values['animationIndex'], isNull);
    expect(draft.valid, isFalse);
    draft.changeParameter('instanceId', 'forest-door');
    expect(draft.valid, isFalse);
    expect(draft.current, same(original));
  });

  test('a clip already missing at opening stays recorded and cannot apply', () async {
    final original = SceneActionPayload.interactive(
      SceneInteractiveCommand.playModelAnimation(
        mapId: 'village',
        instanceId: 'village-door',
        animationIndex: 9,
      ),
    );
    final draft = _draft(
      _modelProject(),
      current: original,
      loadMap: (id) async => _modelMap(id),
    );
    await _settle();
    expect(draft.values['animationIndex'], '9');
    expect(draft.valid, isFalse);
    expect(draft.current, same(original));
    expect(
      (original.interactiveCommand as ScenePlayModelAnimationInteractiveCommand).animationIndex,
      9,
    );
    draft.changeParameter('animationIndex', '1');
    expect(draft.valid, isTrue);
    expect(
      (_command(draft) as ScenePlayModelAnimationInteractiveCommand).animationIndex,
      1,
    );
    expect(draft.current, same(original));
  });

  test('late model result cannot replace current decor and 2D keeps unsupported source intact', () async {
    final first = Completer<MapData>(), second = Completer<MapData>();
    final draft = _draft(
      _modelProject(),
      loadMap: (id) => id == 'village' ? first.future : second.future,
    );
    draft.choose(NarrativeCommandIds.playModelAnimation);
    draft.changeParameter('mapId', 'village');
    draft.changeParameter('mapId', 'forest');
    second.complete(_modelMap('forest'));
    await _settle();
    first.complete(
      _modelMap('village')
          .copyWith(spatialScene: MapSpatialScene(width: 8, depth: 8)),
    );
    await _settle();
    final instance = draft.command!.parameters.singleWhere(
      (field) => field.id == 'instanceId',
    );
    expect(draft.options(instance.kind).keys, ['forest-door']);
    final original = SceneActionPayload.interactive(
      SceneInteractiveCommand.playModelAnimation(
        mapId: 'village',
        instanceId: 'village-door',
        animationIndex: 0,
      ),
    );
    final twoD = _draft(
      _modelProject().copyWith(settings: const ProjectSettings()),
      current: original,
    );
    expect(
      twoD.commands.map((entry) => entry.id),
      isNot(contains(NarrativeCommandIds.playModelAnimation)),
    );
    expect(twoD.valid, isFalse);
    expect(twoD.unsupported, isTrue);
    expect(twoD.current, same(original));
  });
}

SceneActionDraft _draft(
  ProjectManifest project, {
  SceneNodePayload? current,
  Future<MapData> Function(String)? loadMap,
}) {
  final draft = SceneActionDraft(
    project: project,
    current: current,
    loadMap: loadMap,
    changed: () {},
  );
  addTearDown(draft.dispose);
  return draft;
}

SceneInteractiveCommand _command(SceneActionDraft draft) =>
    (draft.buildPayload() as SceneActionPayload).interactiveCommand!;
Future<void> _settle() => Future<void>.delayed(Duration.zero);
ProjectManifest _warpProject() => const ProjectManifest(
  name: 'Téléportation',
  maps: [
    ProjectMapEntry(
      id: 'village',
      name: 'Village',
      relativePath: 'village.json',
    ),
    ProjectMapEntry(id: 'forest', name: 'Forêt', relativePath: 'forest.json'),
  ],
  tilesets: [],
);
MapData _map(String id) => MapData(
  id: id,
  name: id,
  size: const GridSize(width: 8, height: 8),
  warps: [
    MapWarp(
      id: '$id-entry',
      pos: const GridPos(x: 2, y: 3),
      targetMapId: 'other',
      targetPos: const GridPos(x: 1, y: 1),
    ),
  ],
);
ProjectManifest _illustratedProject() => _warpProject().copyWith(
  tilesets: const [
    ProjectTilesetEntry(
      id: 'sheet',
      name: 'Picture',
      relativePath: 'tilesets/picture.png',
      source: ProjectRegularAtlasTilesetSource(
        assetId: 'sheet',
        pixelWidth: 512,
        pixelHeight: 384,
        tileWidth: 512,
        tileHeight: 384,
      ),
    ),
  ],
  elements: const [
    ProjectElementEntry(
      id: 'picture',
      name: 'Image de la grotte',
      tilesetId: 'sheet',
      categoryId: 'pictures',
      frames: [TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0))],
    ),
  ],
);

ProjectManifest _modelProject() => ProjectManifest(
  name: 'Animation 3D',
  maps: const [
    ProjectMapEntry(
      id: 'village',
      name: 'Village',
      relativePath: 'village.json',
    ),
    ProjectMapEntry(id: 'forest', name: 'Forêt', relativePath: 'forest.json'),
  ],
  tilesets: [],
  settings: const ProjectSettings(dimension: ProjectDimension.threeD),
  models3d: [
    ProjectModel3dEntry(
      id: 'door',
      name: 'Porte NB2',
      sourceAssetId: 'door-source',
      relativePath: 'assets/models3d/door.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: 1, y: 2, z: .2),
        ),
        meshCount: 1,
        triangleCount: 4,
        animations: [
          Model3dAnimation(index: 0, name: 'Ouvrir', durationSeconds: .12),
          Model3dAnimation(index: 1, name: 'Fermer', durationSeconds: .12),
        ],
      ),
    ),
  ],
);

MapData _modelMap(String id) => MapData(
  id: id,
  name: id,
  size: const GridSize(width: 8, height: 8),
  spatialScene: MapSpatialScene(
    width: 8,
    depth: 8,
    instances: [
      SpatialModelInstance(
        id: '$id-door',
        modelId: 'door',
        position: Model3dVector3(x: 2.5, y: 0, z: 3.5),
      ),
    ],
  ),
);
