import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_use_verdict.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/border_catalog_fixture.dart';
import '../support/map_workspace_fixture.dart';

ProjectManifest _withEntry(ProjectManifest project, ResourceLibraryEntry entry) =>
    project.copyWith(
      resourceLibraryCatalog: ResourceLibraryCatalog(entries: [entry]),
    );

ResourceItem _decor(ProjectManifest project) =>
    resourceCatalog(project).singleWhere((item) => item.element != null);

ProjectManifest _borderProject(BorderBlueprintRecord record) =>
    workspaceProject.copyWith(
      borderCatalog: ProjectBorderCatalog(
        formatVersion: testBorderCatalog().formatVersion,
        visualSnapshots: testBorderCatalog().visualSnapshots,
        records: [record],
      ),
    );

ResourceUseVerdict _verdict(
  ResourceItem item,
  ProjectManifest project, {
  bool canUse = true,
  String? activeMapId,
}) => resourceUseVerdict(
  item,
  project,
  canUse: canUse,
  activeMapId: activeMapId,
);

void main() {
  test('a compatible decor is usable and carries no refusal message', () {
    final item = _decor(workspaceProject);
    final verdict = _verdict(item, workspaceProject, activeMapId: 'a');
    expect(verdict, ResourceUseVerdict.usable);
    expect(resourceUseRefusalMessage(verdict, item, workspaceProject), isNull);
  });

  test('a project without maps refuses first, even when the context allows use', () {
    final project = workspaceProject.copyWith(maps: const []);
    final item = _decor(project);
    final verdict = _verdict(item, project);
    expect(verdict, ResourceUseVerdict.noMaps);
    expect(
      resourceUseRefusalMessage(verdict, item, project),
      'Ce projet ne contient aucune carte. Les ressources restent consultables.',
    );
  });

  test('a library component is refused although it is compatible', () {
    final project = _withEntry(
      workspaceProject,
      ResourceLibraryEntry(
        resourceKind: 'element',
        resourceId: 'tree',
        role: ResourceLibraryRole.component,
      ),
    );
    final item = _decor(project);
    expect(item.compatibleWith(project.settings.dimension), isTrue);
    final verdict = _verdict(item, project, activeMapId: 'a');
    expect(verdict, ResourceUseVerdict.unavailable);
    expect(verdict, isNot(ResourceUseVerdict.usable));
    expect(
      resourceUseRefusalMessage(verdict, item, project),
      'L’utilisation sur la carte est momentanément indisponible.',
    );
  });

  test('a decor reserved to another map names that map and is usable on its own map', () {
    final project = _withEntry(
      workspaceProject,
      ResourceLibraryEntry(
        resourceKind: 'element',
        resourceId: 'tree',
        mapId: 'b',
      ),
    );
    final item = _decor(project);
    final verdict = _verdict(item, project, activeMapId: 'a');
    expect(verdict, ResourceUseVerdict.reservedToOtherMap);
    expect(
      resourceUseRefusalMessage(verdict, item, project),
      'Cette ressource est réservée à « Jardin ».',
    );
    expect(
      _verdict(item, project, activeMapId: 'b'),
      ResourceUseVerdict.usable,
    );
    expect(_verdict(item, project), ResourceUseVerdict.usable);
  });

  test('a 3D model is refused in a 2D project with the project dimension in the message', () {
    final model = ProjectModel3dEntry(
      id: 'lamp',
      name: 'Lamp',
      sourceAssetId: 'model3d_lamp',
      relativePath: 'assets/models3d/lamp.glb',
      inspection: Model3dInspection(
        bounds: Model3dBounds(
          min: Model3dVector3.zero,
          max: Model3dVector3(x: 1, y: 1, z: 1),
        ),
        meshCount: 1,
        triangleCount: 4,
      ),
    );
    final project = workspaceProject.copyWith(models3d: [model]);
    final item = resourceCatalog(
      project,
    ).singleWhere((item) => item.model3d != null);
    final verdict = _verdict(item, project);
    expect(verdict, ResourceUseVerdict.incompatibleDimension);
    expect(
      resourceUseRefusalMessage(verdict, item, project),
      'Cette ressource ne se place pas dans un projet 2D.',
    );
  });

  final published = testBorderCatalog().records.single;
  test('a published Border is usable', () {
    final project = _borderProject(published);
    final item = resourceCatalog(
      project,
    ).singleWhere((item) => item.border != null);
    expect(_verdict(item, project), ResourceUseVerdict.usable);
  });

  for (final state in ['unpublished', 'deprecated']) {
    test('an $state Border is refused with its own message', () {
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
      final project = _borderProject(record);
      final item = resourceCatalog(
        project,
      ).singleWhere((item) => item.border != null);
      final verdict = _verdict(item, project);
      expect(verdict, ResourceUseVerdict.borderUnavailable);
      expect(
        resourceUseRefusalMessage(verdict, item, project),
        'Cette bordure n’est pas disponible pour le tracé : elle n’est pas publiée ou elle est dépréciée.',
      );
    });
  }

  test('a busy or missing context refuses an otherwise usable decor', () {
    final item = _decor(workspaceProject);
    expect(
      _verdict(item, workspaceProject, canUse: false),
      ResourceUseVerdict.unavailable,
    );
  });

  test('the verdict is usable exactly when the catalogue rule accepts the item and the context allows it', () {
    final projects = [
      workspaceProject,
      _withEntry(
        workspaceProject,
        ResourceLibraryEntry(
          resourceKind: 'element',
          resourceId: 'tree',
          role: ResourceLibraryRole.component,
        ),
      ),
      _withEntry(
        workspaceProject,
        ResourceLibraryEntry(
          resourceKind: 'element',
          resourceId: 'tree',
          mapId: 'b',
        ),
      ),
    ];
    for (final project in projects) {
      final item = _decor(project);
      for (final activeMapId in [null, 'a', 'b']) {
        expect(
          _verdict(item, project, activeMapId: activeMapId) ==
              ResourceUseVerdict.usable,
          item.usableIn(project, activeMapId: activeMapId),
        );
      }
    }
  });
}
