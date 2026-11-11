import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/border_catalog_fixture.dart';
import '../support/map_workspace_fixture.dart';

ProjectManifest _projectWith(BorderBlueprintRecord record) =>
    workspaceProject.copyWith(
      borderCatalog: ProjectBorderCatalog(
        formatVersion: testBorderCatalog().formatVersion,
        visualSnapshots: testBorderCatalog().visualSnapshots,
        records: [record],
      ),
    );

ResourceItem _borderItem(ProjectManifest project) => resourceCatalog(
  project,
).singleWhere((item) => item.border != null);

void main() {
  final published = testBorderCatalog().records.single;

  test('published Borders remain usable when a retired workshop is requested', () {
    final project = _projectWith(published);
    final item = _borderItem(project);
    expect(item.canonicalKind, 'borderBlueprint');
    expect(item.usableIn(project), isTrue);
    expect(item.usableIn(project, activeMapId: 'any-map'), isTrue);
    expect(item.compatibleWith(project.settings.dimension), isTrue);
  });

  for (final state in ['unpublished', 'deprecated']) {
    test('$state Borders keep their placement refusal after workshop retirement', () {
      final record = switch (state) {
        'unpublished' => BorderBlueprintRecord(
          id: published.id,
          draft: published.draft,
        ),
        _ => BorderBlueprintRecord(
          id: published.id,
          draft: published.draft,
          latestPublished: published.latestPublished,
          isDeprecated: true,
        ),
      };
      final project = _projectWith(record);
      final item = _borderItem(project);
      expect(item.usableIn(project), isFalse);
      expect(item.usableIn(project, activeMapId: 'any-map'), isFalse);
      expect(
        filterResourceCatalog(
          project,
          [item],
          ResourceCatalogFilterState(usableOnly: true),
        ),
        isEmpty,
      );
      expect(
        filterResourceCatalog(project, [item], ResourceCatalogFilterState()),
        [item],
      );
    });
  }

  test('a resource reserved to another map is not usable there', () {
    final base = _projectWith(published);
    final project = base.copyWith(
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          ResourceLibraryEntry(
            resourceKind: 'borderBlueprint',
            resourceId: published.id,
            mapId: 'route',
          ),
        ],
      ),
    );
    final item = _borderItem(project);
    expect(item.usableIn(project, activeMapId: 'route'), isTrue);
    expect(item.usableIn(project, activeMapId: 'autre'), isFalse);
    expect(item.usableIn(project), isTrue);
  });
}
