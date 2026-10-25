import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final dimension in ProjectDimension.values) {
    for (final (projectDefault, override, required) in [
      (false, null, false),
      (true, null, true),
      (true, false, false),
      (false, true, true),
    ]) {
      test(
        '$dimension actor contacts $projectDefault/$override derive requirement',
        () {
          final project = ProjectManifest(
            name: 'Capability',
            maps: [],
            tilesets: [],
            settings: ProjectSettings(
              dimension: dimension,
              actorContactShadowsByDefault: projectDefault,
            ),
            characters: [
              ProjectCharacterEntry(
                id: 'hero',
                name: 'Hero',
                tilesetId: 'actors',
                contactShadow: override,
              ),
            ],
          );
          expect(
            SpatialActorContactShadowCapabilities.requiresCapability(project),
            dimension == ProjectDimension.threeD && required,
          );
        },
      );
    }
  }
  test('a project without characters requires no actor contact capability', () {
    const project = ProjectManifest(
      name: 'Empty',
      maps: [],
      tilesets: [],
      settings: ProjectSettings(
        dimension: ProjectDimension.threeD,
        actorContactShadowsByDefault: true,
      ),
    );
    expect(
      SpatialActorContactShadowCapabilities.requiresCapability(project),
      false,
    );
  });
}
