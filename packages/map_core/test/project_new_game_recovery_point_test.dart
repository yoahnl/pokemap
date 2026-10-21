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
