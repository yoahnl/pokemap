import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../domain/resource_port.dart';
import '../domain/border_sequence_primitives.dart';
import 'border_resource_primitive.dart';

export 'border_resource_primitive.dart';

part 'border_resource_spatial_sources.dart';
part 'border_resource_sprite_sources.dart';

Future<List<BorderResourcePrimitive>> prepareBorderResources({
  required ProjectManifest manifest,
  required String projectRoot,
  required BorderCreationRequest request,
}) async {
  final root = await Directory(projectRoot).resolveSymbolicLinks();
  final record = manifest.borderCatalog.recordById(request.blueprintId ?? '');
  if (record?.draft.definition.template == BorderBlueprintTemplate.ledgeLine &&
      record?.draft.definition.isSpatial == false) {
    if (request.capElementId != null ||
        request.straightElementId != null ||
        request.cornerElementId != null ||
        request.capModelId != null ||
        request.straightModelId != null ||
        request.cornerModelId != null ||
        request.primitiveModelIds.isNotEmpty ||
        request.primitiveModelSettings.isNotEmpty ||
        (request.sequenceLength != null && request.sequenceLength != 1) ||
        (request.straightOnly != null &&
            request.straightOnly != record!.draft.definition.straightOnly)) {
      throw const ResourceFailure(
        'Les variantes natives de ce rebord doivent être conservées.',
      );
    }
    return _prepareExistingSpriteSources(
      manifest,
      root,
      record!.draft.definition.primitives,
    );
  }
  final existing = manifest.borderCatalog
      .recordById(request.blueprintId ?? '')
      ?.draft
      .definition;
  final sequenceLength =
      request.sequenceLength ?? existing?.sequenceLength ?? 1;
  if (sequenceLength < 1 ||
      (sequenceLength > 64 && sequenceLength != existing?.sequenceLength) ||
      (sequenceLength > 1 &&
          (manifest.settings.dimension != ProjectDimension.threeD ||
              (request.template ??
                      existing?.template ??
                      BorderBlueprintTemplate.connectedLine) !=
                  BorderBlueprintTemplate.connectedLine))) {
    throw const ResourceFailure(
      'Un motif de 1 à 64 étapes nécessite une bordure 3D sur tracés connectés.',
    );
  }
  final isFacade =
      (request.template ?? existing?.template) ==
      BorderBlueprintTemplate.horizontalFacade;
  if (isFacade &&
      (request.cornerElementId != null ||
          request.capModelId != null ||
          request.straightModelId != null ||
          request.cornerModelId != null)) {
    throw const ResourceFailure(
      'Une façade horizontale utilise uniquement un corps et des extrémités 2D.',
    );
  }
  final directed =
      request.followContourDirection ??
      existing?.followContourDirection ??
      false;
  if (directed && manifest.settings.dimension != ProjectDimension.threeD ||
      !directed && request.innerCornerModelId != null) {
    throw const ResourceFailure(
      'Les angles rentrants nécessitent une bordure 3D orientée.',
    );
  }
  String primitiveId(BorderPrimitiveRole role, BorderCornerTurn? turn) =>
      turn == BorderCornerTurn.left ? 'lineCornerLeft' : role.name;
  bool matches(
    BorderPrimitiveDraft primitive,
    BorderPrimitiveRole role,
    BorderCornerTurn? turn,
  ) =>
      primitive.role == role &&
      (!directed ||
          role != BorderPrimitiveRole.lineCorner ||
          (primitive.cornerTurn ?? BorderCornerTurn.right) == turn);
  final chosen = <(BorderPrimitiveRole, BorderCornerTurn?, String?, String?)>[
    (
      BorderPrimitiveRole.lineCap,
      null,
      request.capElementId,
      request.capModelId,
    ),
    (
      BorderPrimitiveRole.lineStraight,
      null,
      request.straightElementId,
      request.straightModelId,
    ),
    if (!isFacade)
      (
        BorderPrimitiveRole.lineCorner,
        directed ? BorderCornerTurn.right : null,
        request.cornerElementId,
        request.cornerModelId,
      ),
    if (directed)
      (
        BorderPrimitiveRole.lineCorner,
        BorderCornerTurn.left,
        null,
        request.innerCornerModelId,
      ),
  ];
  final result = <BorderResourcePrimitive>[];
  final sequencePrimitives = borderSequencePrimitives(
    existing?.isSpatial == true
        ? existing!.primitives
        : sequenceLength > 1
        ? borderSequenceModelPrimitives(
            straightModelId: request.straightModelId,
            capModelId: request.capModelId,
            cornerModelId: request.straightOnly == true
                ? null
                : request.cornerModelId,
            innerCornerModelId: request.straightOnly == true
                ? null
                : request.innerCornerModelId,
            directed: directed,
          )
        : [],
    sequenceLength,
    previousLength: existing?.sequenceLength ?? 1,
  );
  final mapId = request.blueprintId == null
      ? null
      : manifest.resourceLibraryCatalog
            .entryFor('borderBlueprint', request.blueprintId!)
            ?.mapId;
  final settingsIds = {
    ...sequencePrimitives.map((primitive) => primitive.id),
    for (final source in chosen)
      if (source.$4 != null &&
          existing?.primitives.any(
                (primitive) => matches(primitive, source.$1, source.$2),
              ) !=
              true)
        primitiveId(source.$1, source.$2),
  };
  if (request.primitiveModelSettings.isNotEmpty &&
      (manifest.settings.dimension != ProjectDimension.threeD ||
          request.primitiveModelSettings.keys.any(
            (id) => !settingsIds.contains(id),
          ))) {
    throw const ResourceFailure(
      'Choisissez une pièce 3D existante pour ses réglages.',
    );
  }
  if (request.primitiveModelIds.isNotEmpty &&
      ((existing?.isSpatial != true && sequenceLength == 1) ||
          request.primitiveModelIds.keys.any(
            (id) => !sequencePrimitives.any((primitive) => primitive.id == id),
          ))) {
    throw const ResourceFailure(
      'Choisissez une variante existante de cette bordure 3D.',
    );
  }
  if (existing?.isSpatial == true || sequenceLength > 1) {
    return _prepareSpatialBorderResources(
      manifest: manifest,
      request: request,
      chosen: chosen,
      sequencePrimitives: sequencePrimitives,
      directed: directed,
      mapId: mapId,
      primitiveId: primitiveId,
      matches: matches,
    );
  }
  final preservedRoles = <(BorderPrimitiveRole, BorderCornerTurn?)>{};
  if (existing != null && !existing.isSpatial) {
    for (final (role, turn, elementId, modelId) in chosen) {
      final first = existing.primitives
          .where((primitive) => matches(primitive, role, turn))
          .firstOrNull;
      if (modelId == null &&
          elementId != null &&
          first?.sourceElementId == elementId) {
        preservedRoles.add((role, turn));
      }
    }
    result.addAll(
      await _prepareExistingSpriteSources(
        manifest,
        root,
        existing.primitives.where(
          (primitive) => preservedRoles.any(
            (source) => matches(primitive, source.$1, source.$2),
          ),
        ),
      ),
    );
  }
  for (final (role, turn, elementId, modelId) in chosen) {
    if (preservedRoles.contains((role, turn))) continue;
    if (modelId != null) {
      if (elementId != null ||
          manifest.settings.dimension != ProjectDimension.threeD ||
          !manifest.models3d.any((model) => model.id == modelId) ||
          !manifest.resourceLibraryCatalog.availableForMap(
            'model3d',
            modelId,
            mapId ?? '',
          )) {
        throw const ResourceFailure(
          'Choisissez un modèle 3D disponible pour cette bordure.',
        );
      }
      final original = manifest.borderCatalog
          .recordById(request.blueprintId ?? '')
          ?.draft
          .definition
          .primitives
          .where(
            (primitive) =>
                matches(primitive, role, turn) &&
                primitive.sourceModelId == modelId,
          )
          .firstOrNull;
      result.add(
        BorderResourcePrimitive(
          draft: _withModelSettings(
            manifest,
            request,
            original ??
                BorderPrimitiveDraft(
                  id: primitiveId(role, turn),
                  sourceModelId: modelId,
                  role: role,
                  cornerTurn: turn,
                  authoredOrientation: BorderPrimitiveOrientation.east,
                  weight: 1000,
                  transforms: BorderTransformPolicy(
                    allowFlipX: false,
                    allowedQuarterTurns: const [0, 1, 2, 3],
                  ),
                ),
          ),
          frames: const [],
        ),
      );
      continue;
    }
    if (elementId == null) continue;
    result.add(
      await _prepareElementSpriteSource(
        manifest: manifest,
        root: root,
        role: role,
        elementId: elementId,
        isFacade: isFacade,
      ),
    );
  }
  return result;
}
