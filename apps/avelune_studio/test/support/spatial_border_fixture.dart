import 'package:map_core/map_core.dart';

import 'spatial_environment_fixture.dart';

ProjectManifest spatialBorderProject({
  Model3dVector3? anchor,
  bool straightOnly = false,
}) {
  final base = spatialEnvironmentProject();
  final roles = [
    BorderPrimitiveRole.lineCap,
    BorderPrimitiveRole.lineStraight,
    if (!straightOnly) BorderPrimitiveRole.lineCorner,
  ];
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
  final draft = BorderBlueprintDraftDefinition(
    name: 'Clôture unitaire',
    previewSeed: BorderSignedInt64.fromInt(17),
    template: BorderBlueprintTemplate.connectedLine,
    straightOnly: straightOnly,
    primitives: [
      for (final role in roles)
        BorderPrimitiveDraft(
          id: role.name,
          sourceModelId: 'oak',
          role: role,
          authoredOrientation: BorderPrimitiveOrientation.east,
          weight: 1000,
          transforms: transforms,
          anchorWorld: anchor,
        ),
    ],
    defaults: defaults,
    sortOrder: 0,
  );
  final published = BorderBlueprintPublishedDefinition(
    name: draft.name,
    previewSeed: draft.previewSeed,
    template: draft.template,
    straightOnly: draft.straightOnly,
    primitives: [
      for (final primitive in draft.primitives)
        BorderPublishedPrimitive(
          id: primitive.id,
          sourceModelId: primitive.sourceModelId,
          role: primitive.role,
          authoredOrientation: primitive.authoredOrientation,
          weight: primitive.weight,
          transforms: primitive.transforms,
          anchorWorld: primitive.anchorWorld,
        ),
    ],
    defaults: defaults,
    sortOrder: 0,
  );
  return base.copyWith(
    borderCatalog: ProjectBorderCatalog(
      formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
      records: [
        BorderBlueprintRecord(
          id: 'fence',
          draft: BorderBlueprintDraft(baseRevision: 1, definition: draft),
          latestPublished: BorderBlueprintRevision(
            revision: 1,
            definition: published,
          ),
        ),
      ],
    ),
  );
}

MapData spatialBorderMap() => spatialEnvironmentMap();

ProjectManifest spatialBorderVariantProject() {
  final project = spatialBorderProject(straightOnly: true);
  final record = project.borderCatalog.records.single;
  final definition = record.draft.definition;
  final cap = definition.primitives.firstWhere(
    (primitive) => primitive.role == BorderPrimitiveRole.lineCap,
  );
  return project.copyWith(
    models3d: [
      ...project.models3d,
      ProjectModel3dEntry(
        id: 'replacement',
        name: 'Nouvelle extrémité',
        sourceAssetId: 'replacement-source',
        relativePath: 'assets/models3d/replacement.glb',
        inspection: project.models3d.single.inspection,
      ),
    ],
    borderCatalog: ProjectBorderCatalog(
      formatVersion: ProjectBorderCatalog.latestSupportedFormatVersion,
      records: [
        BorderBlueprintRecord(
          id: record.id,
          draft: BorderBlueprintDraft(
            baseRevision: 0,
            definition: BorderBlueprintDraftDefinition(
              name: definition.name,
              previewSeed: definition.previewSeed,
              template: definition.template,
              straightOnly: true,
              defaults: definition.defaults,
              sortOrder: 0,
              primitives: [
                definition.primitives.firstWhere(
                  (primitive) =>
                      primitive.role == BorderPrimitiveRole.lineStraight,
                ),
                BorderPrimitiveDraft(
                  id: 'north-cap',
                  sourceModelId: 'oak',
                  role: cap.role,
                  authoredOrientation: BorderPrimitiveOrientation.north,
                  weight: 400,
                  anchorWorld: Model3dVector3(x: .1, y: .2, z: .3),
                  transforms: cap.transforms,
                ),
                BorderPrimitiveDraft(
                  id: 'south-cap',
                  sourceModelId: 'oak',
                  role: cap.role,
                  authoredOrientation: BorderPrimitiveOrientation.south,
                  weight: 600,
                  anchorWorld: Model3dVector3(x: -.1, y: .3, z: -.2),
                  transforms: BorderTransformPolicy(
                    allowFlipX: false,
                    allowedQuarterTurns: const [0, 2],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
