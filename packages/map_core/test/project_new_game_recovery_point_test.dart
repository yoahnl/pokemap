import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final point = <String, Object?>{
    'mapId': 'recovery',
    'position': {'x': 0, 'y': 1},
    'facing': 'south',
  };
  ProjectNewGameConfig decode(Object? recovery) =>
      ProjectNewGameConfig.fromJson({
        'enabled': true,
        'startMapId': 'intro',
        'initialRecoveryPoint': recovery,
      });
  test(
    'new game recovery is a typed optional round trip separate from entry',
    () {
      final config = decode(point);
      expect(config.toJson()['initialRecoveryPoint'], point);
      expect(config.startMapId, 'intro');
      expect(ProjectNewGameConfig.fromJson(config.toJson()), config);
      expect(
        const ProjectNewGameConfig().toJson().containsKey(
          'initialRecoveryPoint',
        ),
        isFalse,
      );
    },
  );
  for (final invalid in <Object?>[
    'recovery',
    {...point, 'facing': 'diagonal'},
    {...point, 'facing': 2},
    {
      ...point,
      'position': {'x': -1, 'y': 1},
    },
    {
      ...point,
      'position': {'x': 0.5, 'y': 1},
    },
    {...point, 'mapId': ''},
    {
      ...point,
      'metadata': {'custom': 'untyped'},
    },
  ]) {
    test('recovery refuses malformed native data $invalid', () {
      expect(() => decode(invalid), throwsFormatException);
    });
  }
  test('recovery-only validation accepts slim catalog metadata while full validation rejects unknown avatars', () {
    const project = ProjectManifest(name: 'Partitioned metadata', maps: [
      ProjectMapEntry(id: 'intro', name: 'Intro', relativePath: 'intro.json'),
      ProjectMapEntry(id: 'recovery', name: 'Recovery', relativePath: 'recovery.json'),
    ], tilesets: [], newGame: ProjectNewGameConfig(enabled: true, startMapId: 'intro',
      playerAvatarCharacterIds: ['unhydrated-avatar'],
      initialRecoveryPoint: ProjectNewGameRecoveryPoint(mapId: 'recovery', position: GridPos(x: 0, y: 1), facing: EntityFacing.south)));
    const map = MapData(id: 'recovery', name: 'Recovery', size: GridSize(width: 2, height: 2));
    expect(() => ProjectValidator.validateNewGameInitialRecoveryMap(project, map), returnsNormally);
    expect(() => ProjectValidator.validate(project), throwsA(isA<ValidationException>().having(
      (error) => error.message, 'avatar reference', contains('unknown character: unhydrated-avatar'))));
  });
  test('recovery-only validation leaves unhydrated Fact references to the full validator', () {
    final project = ProjectManifest(name: 'Partitioned Facts', maps: const [
      ProjectMapEntry(id: 'intro', name: 'Intro', relativePath: 'intro.json'),
      ProjectMapEntry(id: 'recovery', name: 'Recovery', relativePath: 'recovery.json'),
    ], tilesets: const [], newGame: ProjectNewGameConfig.fromJson({
      ...decode(point).toJson(), 'initialFacts': {'unhydrated-fact': true},
    }));
    const map = MapData(id: 'recovery', name: 'Recovery', size: GridSize(width: 2, height: 2));
    expect(() => ProjectValidator.validateNewGameInitialRecoveryMap(project, map), returnsNormally);
    expect(() => ProjectValidator.validate(project), throwsA(isA<ValidationException>().having(
      (error) => error.message, 'Fact reference', contains('unknown Fact: unhydrated-fact'))));
  });
  test('recovery-only validation retains project ownership, geometry and dimension guards', () {
    ProjectManifest project({String mapId = 'recovery', int x = 0, int y = 1, bool known = true, ProjectDimension dimension = ProjectDimension.twoD}) => ProjectManifest(
      name: 'Recovery guards', maps: [
        const ProjectMapEntry(id: 'intro', name: 'Intro', relativePath: 'intro.json'),
        if (known) const ProjectMapEntry(id: 'recovery', name: 'Recovery', relativePath: 'recovery.json'),
      ], tilesets: const [], settings: ProjectSettings(dimension: dimension),
      newGame: ProjectNewGameConfig(enabled: true, startMapId: 'intro', playerAvatarCharacterIds: const ['unhydrated-avatar'],
        initialRecoveryPoint: ProjectNewGameRecoveryPoint(mapId: mapId, position: GridPos(x: x, y: y), facing: EntityFacing.south)));
    const map = MapData(id: 'recovery', name: 'Recovery', size: GridSize(width: 2, height: 2));
    for (final invalid in [project(known: false), project(mapId: ''), project(mapId: ' recovery'), project(x: -1), project(y: -1), project(x: 2), project(y: 2), project(dimension: ProjectDimension.threeD)]) {
      expect(() => ProjectValidator.validateNewGameInitialRecoveryMap(invalid, map), throwsA(isA<ValidationException>()));
    }
    expect(() => ProjectValidator.validateNewGameInitialRecoveryMap(project(), map.copyWith(id: 'another')), throwsA(isA<ValidationException>()));
    expect(() => ProjectValidator.validateNewGameInitialRecoveryMap(project(), map.copyWith(version: ProjectVersion.v9)), throwsA(isA<ValidationException>()));
    expect(() => ProjectValidator.validateNewGameInitialRecoveryMap(project(), map.copyWith(spatialScene: MapSpatialScene(width: 2, depth: 2))), throwsA(isA<ValidationException>()));
  });
  test('project and map validation refuse shrinking the configured recovery map', () {
    final project = ProjectManifest(name:'Recovery',maps:const [
      ProjectMapEntry(id:'intro',name:'Intro',relativePath:'maps/intro.json'),
      ProjectMapEntry(id:'recovery',name:'Recovery',relativePath:'maps/recovery.json'),
    ],tilesets:const [],newGame:decode(point));
    const changed=MapData(id:'recovery',name:'Recovery',size:GridSize(width:1,height:1));
    expect(()=>ProjectValidator.validate(project,maps:[changed]),throwsA(isA<ValidationException>()));
    expect(()=>MapValidator.validate(changed,projectDialogueContext:project),throwsA(isA<ValidationException>()));
  });
  test('disabled recovery remains dormant until new game is enabled', () {
    const project = ProjectManifest(name: 'Dormant', maps: [], tilesets: [], newGame: ProjectNewGameConfig(
      initialRecoveryPoint: ProjectNewGameRecoveryPoint(mapId: 'unselected',position: GridPos(x: 10,y: 10),facing: EntityFacing.south)));
    expect(() => ProjectValidator.validate(project),returnsNormally);
    expect(() => ProjectValidator.validateNewGameInitialRecoveryMap(project,const MapData(id:'unselected',name:'Dormant',size:GridSize(width:1,height:1))),returnsNormally);
  });
  test('recovery map must belong to the same project', () {
    final project = ProjectManifest(
      name: 'Recovery',
      maps: const [
        ProjectMapEntry(
          id: 'intro',
          name: 'Intro',
          relativePath: 'maps/intro.json',
        ),
      ],
      tilesets: const [],
      newGame: decode(point),
    );
    expect(
      () => ProjectValidator.validate(project),
      throwsA(isA<ValidationException>()),
    );
  });
}
