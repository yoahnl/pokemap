import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';

BorderBlueprintRecord borderBlueprint(String id, List<String> modelIds) {
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

ProjectModel3dEntry borderModel(String id) => ProjectModel3dEntry(
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

String? storedObjectType(File file) {
  try {
    final raw = jsonDecode(file.readAsStringSync());
    return raw is Map ? raw['type'] as String? : null;
  } on Object {
    return null;
  }
}
