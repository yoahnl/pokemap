import 'package:avelune_studio/features/map_workspace/application/spatial_field_obstacle_eligibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

SpatialModelInstance _instance(
  String id, {
  String modelId = 'oak',
  bool blocks = true,
  String? entityId,
}) => SpatialModelInstance(
  id: id,
  modelId: modelId,
  blocksMovement: blocks,
  entityId: entityId,
  position: Model3dVector3(x: 2.5, y: 0, z: 2.5),
);

ProjectManifest _project({List<NarrativeEventRecord> events = const []}) {
  final base = spatialEnvironmentProject();
  final oak = base.models3d.single;
  return base.copyWith(
    models3d: [
      oak,
      ProjectModel3dEntry(
        id: 'slope',
        name: 'Pente',
        sourceAssetId: 'slope-source',
        relativePath: 'assets/models3d/slope.glb',
        inspection: oak.inspection,
        rampProfile: Model3dRampProfile(
          x: 0,
          z: 0,
          width: 1,
          depth: 2,
          lowHeight: 0,
          highHeight: 1.5,
          direction: SpatialRampDirection.north,
        ),
      ),
    ],
    eventRegistry: events.isEmpty
        ? null
        : NarrativeEventRegistry(
            schemaVersion: 1,
            mode: EventSystemMode.v2Only,
            records: events,
            legacyClaims: const [],
          ),
  );
}

void main() {
  test('a refused field obstacle states the rule it breaks', () {
    final project = _project();
    final oak = project.models3d.first;
    final slope = project.models3d.last;
    expect(
      spatialFieldObstacleRefusal(_instance('a', blocks: false), oak, null),
      startsWith('Activez la collision du décor'),
    );
    expect(
      spatialFieldObstacleRefusal(
        _instance('b', modelId: 'slope'),
        slope,
        null,
      ),
      startsWith('Une rampe sert à la traversée'),
    );
    expect(
      spatialFieldObstacleRefusal(
        _instance('c', entityId: 'npc'),
        oak,
        const MapEntity(
          id: 'npc',
          name: 'Guide',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 2),
        ),
      ),
      startsWith('Ce décor porte déjà un autre élément du jeu'),
    );
    expect(spatialFieldObstacleRefusal(_instance('d'), null, null), isNotNull);
    expect(spatialFieldObstacleRefusal(_instance('e'), oak, null), isNull);
  });
}
