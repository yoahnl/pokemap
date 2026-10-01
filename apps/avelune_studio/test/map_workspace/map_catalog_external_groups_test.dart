import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'map_catalog_fixture.dart';

void main() {
  test(
    'catalogue revision checking refuses externally changed map folders',
    () async {
      final fixture = await MapCatalogFixture.create();
      addTearDown(fixture.dispose);
      final original = fixture.controller.project!;
      final changed = original.copyWith(
        groups: [
          const ProjectMapGroup(
            id: 'external',
            name: 'Autre auteur',
            type: MapGroupType.city,
          ),
        ],
      );
      final file = File(p.join(fixture.root.path, 'project.json'));
      await file.writeAsString(jsonEncode(changed.toJson()));
      final bytes = await file.readAsBytes();
      final result = await fixture.controller.mutateCatalog(
        'map.library.reorganize',
        {'groups': [], 'assignments': []},
      );
      expect(result.published, isFalse);
      expect(await file.readAsBytes(), bytes);
      expect(fixture.controller.project, same(original));
    },
  );

  test(
    'another session owner cannot refresh a baseline then overwrite old UI groups',
    () async {
      final fixture = await MapCatalogFixture.create();
      addTearDown(fixture.dispose);
      final old = fixture.controller.project!;
      final changed = old.copyWith(
        groups: [
          const ProjectMapGroup(
            id: 'retained',
            name: 'À conserver',
            type: MapGroupType.city,
          ),
        ],
      );
      final file = File(p.join(fixture.root.path, 'project.json'));
      await file.writeAsString(jsonEncode(changed.toJson()));
      await fixture.adapter.loadProject(fixture.session);
      final bytes = await file.readAsBytes();
      final result = await fixture.controller.mutateCatalog(
        'map.library.reorganize',
        {'groups': [], 'assignments': []},
      );
      expect(result.published, isFalse);
      expect(result.error, contains('depuis son ouverture'));
      expect(await file.readAsBytes(), bytes);
      expect(fixture.controller.project, same(old));
    },
  );
}
