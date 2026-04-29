import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'package:map_editor/src/features/map_entities/application/npc_runtime_rules_authoring_catalog.dart';

void main() {
  test('knownStoryFlagIds dans globalProperties enrichit le catalogue flags', () {
    final project = ProjectManifest(surfaceCatalog: ProjectSurfaceCatalog(), 
      name: 'p',
      maps: const [],
      tilesets: const [],
      globalProperties: {
        'authoring.knownStoryFlagIds': ['declared_flag', 'other'],
      },
    );
    final catalog = buildNpcRuntimeAuthoringCatalog(project);
    final ids = catalog.flags.map((e) => e.id).toSet();
    expect(ids, contains('declared_flag'));
    expect(ids, contains('other'));
  });
}
