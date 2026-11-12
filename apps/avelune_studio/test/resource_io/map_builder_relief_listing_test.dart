import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_preview_source.dart';
import 'package:avelune_studio/features/resources/application/resource_usage_category.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_resource_binding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart';

void main() {
  late Directory root;
  late LocalProjectSessionAdapter sessions;
  late ProjectSession session;
  late MapWorkspaceController workspace;
  const names = ['a', 'b', 'part'];

  setUp(() async {
    root = await Directory.systemTemp.createTemp('studio_relief_listing_');
    sessions = LocalProjectSessionAdapter();
    await writeExampleProject(root);
    for (final id in ['jardin', 'clairiere']) {
      final mapFile = File('${root.path}/maps/$id.json');
      final map = MapData.fromJson(
        jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>,
      );
      await mapFile.writeAsString(
        jsonEncode(
          MapData(
            id: map.id,
            name: map.name,
            version: ProjectVersion.v9,
            size: const GridSize(width: 8, height: 6),
            spatialScene: MapSpatialScene(
              width: 8,
              depth: 6,
              heightLevels: List.filled(48, 0),
            ),
          ).toJson(),
        ),
      );
    }
    final file = File('${root.path}/project.json');
    final source = ProjectManifest.fromJson(
      jsonDecode(await file.readAsString()) as Map<String, dynamic>,
    );
    await file.delete();
    await WorkingProjectCatalog.create(
      store: await CatalogStorageStore.open(projectRoot: root.path),
      projectId: 'relief-listing-test',
      project: source.copyWith(
        version: ProjectVersion.v9,
        settings: ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        ),
        models3d: [
          for (final name in names) ...[
            _model('piece_${name}_first'),
            _model('piece_${name}_second'),
          ],
        ],
        borderCatalog: ProjectBorderCatalog(
          formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
          records: [
            for (final name in names)
              _border('cliff_$name', [
                'piece_${name}_first',
                'piece_${name}_second',
              ]),
          ],
        ),
        resourceLibraryCatalog: ResourceLibraryCatalog(
          families: [ResourceFamily(id: 'family_cliffs', name: 'Falaises')],
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'borderBlueprint',
              resourceId: 'cliff_a',
              familyId: 'family_cliffs',
            ),
            ResourceLibraryEntry(
              resourceKind: 'borderBlueprint',
              resourceId: 'cliff_part',
              role: ResourceLibraryRole.component,
            ),
          ],
        ),
      ),
    );
    session = await sessions.open(await root.resolveSymbolicLinks());
    expect(session.storage, ProjectSessionStorage.workingCatalog);
    workspace = MapWorkspaceController(session, LocalMapWorkspaceAdapter());
    await workspace.initialize();
    expect(workspace.error, isNull);
  });

  tearDown(() async {
    workspace.dispose();
    await sessions.close(session);
    await root.delete(recursive: true);
  });

  Set<String> pieces() => {
    for (final model in workspace.project!.models3d)
      if (model.id.startsWith('piece_')) model.id,
  };

  ResourceItem item(String id) =>
      resourceCatalog(workspace.project!).singleWhere((item) => item.id == id);

  test(
    'the palette lists reliefs with only the piece their tile shows',
    () async {
      await workspace.ensureResourceKind(
        'borderBlueprint',
        placeableOnly: true,
      );

      final project = workspace.project!;
      expect(project.borderCatalog.records.map((record) => record.id).toSet(), {
        'cliff_a',
        'cliff_b',
      });
      expect(pieces(), {'piece_a_first', 'piece_b_first'});
      expect(
        project.resourceLibraryCatalog
            .entryFor('borderBlueprint', 'cliff_a')
            ?.familyId,
        'family_cliffs',
      );
      expect(
        project.resourceLibraryCatalog.families.map((family) => family.id),
        contains('family_cliffs'),
      );
      expect(
        resourceUsageCategory(item('cliff_a'), project),
        ResourceUsageCategory.relief,
      );
      expect(
        resourcePreviewSource(item('cliff_b'), workspace.visualProject!),
        isA<ModelPreviewSource>(),
      );
      expect(
        workspace.hasResourceClosure('borderBlueprint', 'cliff_a'),
        isFalse,
      );
      expect(workspace.hasBorderProfiles, isFalse);
    },
  );

  test(
    'choosing a listed relief loads its pieces before arming the tool',
    () async {
      final state = MapWorkspaceEditingState();
      final binding = MapBuilderResourceBinding(
        maps: workspace,
        view: () => state,
        visuals: () => null,
        isActive: () => true,
        changed: () {},
      );
      await workspace.ensureResourceKind(
        'borderBlueprint',
        placeableOnly: true,
      );

      await binding.use(item('cliff_a'));

      expect(binding.problem, isNull);
      expect(binding.armed?.id, 'cliff_a');
      expect(state.tool, StudioMapTool.border);
      expect(state.borderBlueprintId, 'cliff_a');
      expect(
        workspace.hasResourceClosure('borderBlueprint', 'cliff_a'),
        isTrue,
      );
      expect(workspace.hasBorderBlueprint('cliff_a'), isTrue);
      expect(pieces(), containsAll(['piece_a_first', 'piece_a_second']));
      expect(pieces(), isNot(contains('piece_b_second')));

      await workspace.ensureResourceKind('model3d', placeableOnly: true);

      expect(pieces(), containsAll(['piece_a_first', 'piece_a_second']));
    },
  );

  test('a full relief load still resolves every piece', () async {
    await workspace.ensureResourceKind('borderBlueprint');

    expect(pieces().length, 2 * names.length);
    expect(workspace.hasResourceClosure('borderBlueprint', 'cliff_b'), isTrue);
  });
}

BorderBlueprintRecord _border(String id, List<String> modelIds) {
  final transforms = BorderTransformPolicy(
    allowFlipX: false,
    allowedQuarterTurns: const [0, 1, 2, 3],
  );
  final defaults = BorderGenerationParams(
    irregularityPermille: 0,
    detailDensityPermille: 0,
    variationPermille: 0,
    maxOverlapPx: 0,
    gapTolerancePx: 0,
    depthRows: 1,
  );
  final roles = [
    BorderPrimitiveRole.lineStraight,
    BorderPrimitiveRole.lineCorner,
  ];
  final draft = BorderBlueprintDraftDefinition(
    name: 'Falaise $id',
    previewSeed: BorderSignedInt64.fromInt(3),
    template: BorderBlueprintTemplate.connectedLine,
    primitives: [
      for (final (index, role) in roles.indexed)
        BorderPrimitiveDraft(
          id: role.name,
          sourceModelId: modelIds[index],
          role: role,
          authoredOrientation: BorderPrimitiveOrientation.east,
          weight: 1000,
          transforms: transforms,
        ),
    ],
    defaults: defaults,
    sortOrder: 0,
  );
  return BorderBlueprintRecord(
    id: id,
    draft: BorderBlueprintDraft(baseRevision: 1, definition: draft),
    latestPublished: BorderBlueprintRevision(
      revision: 1,
      definition: BorderBlueprintPublishedDefinition(
        name: draft.name,
        previewSeed: draft.previewSeed,
        template: draft.template,
        primitives: [
          for (final primitive in draft.primitives)
            BorderPublishedPrimitive(
              id: primitive.id,
              sourceModelId: primitive.sourceModelId,
              role: primitive.role,
              authoredOrientation: primitive.authoredOrientation,
              weight: primitive.weight,
              transforms: primitive.transforms,
            ),
        ],
        defaults: defaults,
        sortOrder: 0,
      ),
    ),
  );
}

ProjectModel3dEntry _model(String id) => ProjectModel3dEntry(
  id: id,
  name: 'Pièce $id',
  sourceAssetId: 'source_$id',
  relativePath: 'assets/models3d/$id.glb',
  inspection: Model3dInspection(
    bounds: Model3dBounds(
      min: Model3dVector3.zero,
      max: Model3dVector3(x: 1, y: 1, z: 1),
    ),
    meshCount: 1,
    triangleCount: 4,
  ),
);
