import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../maps/map_catalog_fixture.dart';
import 'resource_information_actions_test.dart' show informationFixture;
import 'resource_library_actions_test.dart' show librarySnapshot;

void main() {
  test('one classification preserves a thousand independent resources', () async {
    final base = informationFixture();
    final project = base.copyWith(elements: [
      for (var index = 0; index < 1000; index++)
        base.elements.single.copyWith(id: 'decor-$index'),
    ]);
    final draft = await MapMutationDispatcher.canonical().build(catalogContext(
      librarySnapshot([], project: project),
      'resource.classify_batch',
      {
        'entries': [
          for (final element in project.elements)
            {
              'resourceKind': 'element',
              'resourceId': element.id,
              'familyId': 'trees',
            },
        ],
      },
    ));
    expect(draft.changeSet.changes, hasLength(1));
    final updated = ProjectManifest.fromJson(jsonDecode(utf8.decode(
        draft.changeSet.changes.single.afterBytes!)) as Map<String, dynamic>);
    expect(updated.elements, project.elements);
    expect(updated.resourceLibraryCatalog.entries, hasLength(1000));
    expect(updated.resourceLibraryCatalog.entries.every((entry) =>
        entry.resourceKind == 'element' && entry.familyId == 'trees'), isTrue);
  });
}
