import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_creation_sources.dart';
import 'package:avelune_studio/features/resources/application/resource_family_tree.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/border_creation_owner_fixture.dart';
import '../support/spatial_border_fixture.dart';

void main() {
  test(
    'cliff edition keeps both corner families and ground ownership separately',
    () async {
      final base = spatialBorderProject();
      final raw = encodeBorderBlueprintRecordJson(
        base.borderCatalog.records.single,
        formatVersion: 5,
      );
      final definition = (raw['draft'] as Map)['definition'] as Map;
      definition['followContourDirection'] = true;
      definition['replacesGround'] = true;
      definition['groundBaseOffset'] = -.0625;
      final primitives = definition['primitives'] as List;
      final corner = primitives.cast<Map>().singleWhere(
        (p) => p['role'] == 'lineCorner',
      );
      corner['cornerTurn'] = 'right';
      primitives.add({...corner, 'id': 'lineCornerLeft', 'cornerTurn': 'left'});
      final project = base.copyWith(
        borderCatalog: ProjectBorderCatalog(
          formatVersion: 5,
          records: [decodeBorderBlueprintRecordJson(raw, formatVersion: 5)],
        ),
      );
      final host = BorderCreationOwnerFixture(
        project: project,
        initialRecord: project.borderCatalog.records.single,
      );
      final draft = host.draft;
      expect(draft.roles, containsAll(['lineCorner', 'lineCornerLeft']));
      expect(draft.setGroundLowering('-1'), isFalse);
      expect(draft.groundBaseOffset, -.0625);
      draft.setReplacesGround(false);
      expect(draft.groundBaseOffset, 0);
      draft.setReplacesGround(true);
      expect(draft.setGroundLowering('0,125'), isTrue);
      draft.setMasksGroundCells(true);
      expect(draft.replacesGround, isFalse);
      expect(draft.groundBaseOffset, 0);
      draft.setMasksGroundCells(false);
      draft.setReplacesGround(true);
      expect(draft.setGroundLowering('0,125'), isTrue);
      draft.setSettings(
        'lineCornerLeft',
        const BorderModelSettings(blocksMovement: false),
      );
      expect(await host.workflow.save(publish: true), isFalse);
      final request = host.port.requests.single;
      expect(request.followContourDirection, isTrue);
      expect(request.groundBaseOffset, -.125);
      expect(
        request.primitiveModelSettings['lineCornerLeft']!.blocksMovement,
        isFalse,
      );
      expect(request.primitiveModelSettings.containsKey('lineCorner'), isFalse);
    },
  );

  test('an incompatible unselected border variant refuses publication until its clip is cleared', () async {
    final base = spatialBorderVariantProject();
    final record = encodeBorderBlueprintRecordJson(
      base.borderCatalog.records.single,
      formatVersion: 5,
    );
    final definition = (record['draft'] as Map)['definition'] as Map;
    final south = (definition['primitives'] as List).cast<Map>().singleWhere(
      (primitive) => primitive['id'] == 'south-cap',
    );
    south['animationIndex'] = 0;
    final project = base.copyWith(
      borderCatalog: ProjectBorderCatalog(
        formatVersion: 5,
        records: [decodeBorderBlueprintRecordJson(record, formatVersion: 5)],
      ),
      models3d: [
        for (final model in base.models3d)
          ProjectModel3dEntry.fromJson({
            ...model.toJson(),
            'inspection': {
              ...model.inspection.toJson(),
              'animations': [
                if (model.id == 'oak')
                  {'index': 0, 'name': 'Eau', 'durationSeconds': 2.0},
              ],
            },
          }),
      ],
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          for (final id in ['oak', 'replacement'])
            ResourceLibraryEntry(
              resourceKind: 'model3d',
              resourceId: id,
              familyId: 'fences',
              role: ResourceLibraryRole.component,
            ),
        ],
      ),
    );
    final host = BorderCreationOwnerFixture(
      project: project,
      initialRecord: project.borderCatalog.records.single,
    );
    final draft = host.draft;
    expect(draft.settingsProblem, isNull);
    draft.selectPrimitive('lineCap', 'south-cap');
    draft.assignRole(
      'lineCap',
      resourceCatalog(project)
          .firstWhere((item) => item.model3d?.id == 'replacement'),
    );
    expect(
      draft.settingsProblem,
      contains('Choisissez une animation disponible'),
    );
    expect(await host.workflow.save(publish: true), isFalse);
    expect(host.port.requests, isEmpty);
    draft.selectPrimitive('lineCap', 'north-cap');
    expect(
      draft.settingsProblem,
      contains('Choisissez une animation disponible'),
    );
    expect(await host.workflow.save(publish: true), isFalse);
    expect(host.port.requests, isEmpty);
    draft.selectPrimitive('lineCap', 'south-cap');
    draft.setSettings('lineCap', const BorderModelSettings());
    expect(draft.settingsProblem, isNull);
  });

  test(
    'straight border edits one terminal variant without inventing a corner',
    () async {
      final project = spatialBorderVariantProject().copyWith(
        models3d: [
          for (final model in spatialBorderVariantProject().models3d)
            ProjectModel3dEntry.fromJson({
              ...model.toJson(),
              'inspection': {
                ...model.inspection.toJson(),
                'animations': [
                  {'index': 0, 'name': 'Eau', 'durationSeconds': 2.0},
                ],
              },
            }),
        ],
        resourceLibraryCatalog: ResourceLibraryCatalog(
          entries: [
            for (final id in ['oak', 'replacement'])
              ResourceLibraryEntry(
                resourceKind: 'model3d',
                resourceId: id,
                familyId: 'fences',
                role: ResourceLibraryRole.component,
              ),
          ],
        ),
      );
      final host = BorderCreationOwnerFixture(
        project: project,
        initialRecord: project.borderCatalog.records.single,
      );
      final draft = host.draft;
      expect(draft.roles, ['lineStraight', 'lineCap']);
      draft.selectPrimitive('lineCap', 'south-cap');
      draft.assignRole(
        'lineCap',
        resourceCatalog(project)
            .firstWhere((item) => item.model3d?.id == 'replacement'),
      );
      draft.setSettings(
        'lineCap',
        const BorderModelSettings(
          animationIndex: 0,
          animationLoop: false,
          animationSpeed: .5,
          blocksMovement: false,
        ),
      );
      expect(await host.workflow.save(publish: true), isFalse);
      final request = host.port.requests.single;
      expect(request.primitiveModelIds, {'south-cap': 'replacement'});
      expect(request.straightOnly, isTrue);
      expect(request.cornerModelId, isNull);
      expect(request.capModelId, isNull);
      expect(request.primitiveModelSettings, {
        'south-cap': const BorderModelSettings(
          animationIndex: 0,
          animationLoop: false,
          animationSpeed: .5,
          blocksMovement: false,
        ),
      });
    },
  );

  test(
    'creating a straight model border needs a body and terminal only',
    () async {
      final project = spatialBorderProject(straightOnly: true);
      final host = BorderCreationOwnerFixture(project: project);
      final draft = host.draft..name = 'Clôture droite';
      draft.setStraightOnly(true);
      expect(await host.workflow.save(publish: true), isFalse);
      expect(host.port.requests, isEmpty);
      final oak = resourceCatalog(project)
          .firstWhere((item) => item.model3d?.id == 'oak');
      draft.assignRole('lineStraight', oak);
      expect(await host.workflow.save(publish: true), isFalse);
      expect(host.port.requests, isEmpty);
      draft.assignRole('lineCap', oak);
      expect(await host.workflow.save(publish: true), isFalse);
      final request = host.port.requests.single;
      expect(request.straightOnly, isTrue);
      expect(request.capModelId, 'oak');
      expect(request.straightModelId, 'oak');
      expect(request.cornerModelId, isNull);
    },
  );

  test('border model sources share families and exclude unavailable local resources', () {
    final base = spatialBorderProject();
    final project = base.copyWith(
      models3d: [
        ...base.models3d,
        ProjectModel3dEntry(
          id: 'private',
          name: 'Pièce privée',
          sourceAssetId: 'private-source',
          relativePath: 'assets/models3d/private.glb',
          inspection: base.models3d.single.inspection,
        ),
      ],
      resourceLibraryCatalog: ResourceLibraryCatalog(
        families: [
          ResourceFamily(
            id: 'wooden-fences',
            name: 'Clôtures en bois',
            parentId: 'fences',
          ),
        ],
        entries: [
          ResourceLibraryEntry(
            resourceKind: 'model3d',
            resourceId: 'oak',
            familyId: 'wooden-fences',
          ),
          ResourceLibraryEntry(
            resourceKind: 'model3d',
            resourceId: 'private',
            familyId: 'wooden-fences',
            mapId: 'b',
          ),
        ],
      ),
    );
    final items = borderCreationSources(project);
    expect(items.map((item) => item.id), contains('oak'));
    expect(items.map((item) => item.id), isNot(contains('private')));
    final filters = ResourceCatalogFilterState(
      showComponents: true,
      familyId: 'fences',
    );
    final tree = ResourceFamilyTree(project, items, filters: filters);
    expect(tree.nodes.firstWhere((node) => node.id == 'fences').count, 1);
    final visible = filterResourceCatalog(project, items, filters);
    expect(visible.single.canonicalKind, 'model3d');
    expect(visible.single.id, 'oak');
    final border = resourceCatalog(project)
        .firstWhere((item) => item.border != null);
    expect(border.compatibleWith(ProjectDimension.threeD), isTrue);
    expect(border.compatibleWith(ProjectDimension.twoD), isFalse);
  });
}
