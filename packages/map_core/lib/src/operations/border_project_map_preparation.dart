import '../exceptions/map_exceptions.dart';
import '../models/border_blueprint.dart';
import '../models/map_data.dart';
import '../models/map_layer.dart';
import '../models/project_manifest.dart';
import '../validation/validators.dart';
import 'border_catalog_operations.dart';
import 'border_layer_operations.dart';
import 'project_manifest_border_catalog_operations.dart';

/// The two independently versioned values prepared by one logical Border
/// creation action.
final class PreparedBorderProjectMapUpdate {
  const PreparedBorderProjectMapUpdate({
    required this.manifest,
    required this.map,
  });

  final ProjectManifest manifest;
  final MapData map;
}

/// Prepares the first persisted Border draft and map layer as one pure unit.
///
/// Both candidate values are built and strictly validated before this function
/// exposes either of them. Any failure is propagated and the immutable source
/// values remain available to the caller unchanged.
PreparedBorderProjectMapUpdate prepareFirstBorderDraftAndLayer({
  required ProjectManifest manifest,
  required MapData map,
  required BorderBlueprintRecord draftRecord,
  required String layerId,
  required String layerName,
  int? insertIndex,
}) {
  if (manifest.borderCatalog.isNotEmpty) {
    throw const ValidationException(
      'First Border creation requires an empty project Border catalog',
    );
  }
  if (map.layers.any((layer) => layer is BorderLayer)) {
    throw const ValidationException(
      'First Border creation requires a map without Border layers',
    );
  }
  if (draftRecord.latestPublished != null) {
    throw const ValidationException(
      'First Border creation requires an unpublished draft record',
    );
  }
  if (draftRecord.draft.baseRevision != 0) {
    throw const ValidationException(
      'First Border creation requires draft baseRevision 0',
    );
  }
  if (insertIndex != null &&
      (insertIndex < 0 || insertIndex > map.layers.length)) {
    throw ValidationException(
      'Invalid first Border layer insertIndex: $insertIndex',
    );
  }

  final preparedCatalog = addBorderBlueprintRecord(
    manifest.borderCatalog,
    draftRecord,
  );
  final preparedManifest = replaceProjectBorderCatalog(
    manifest,
    preparedCatalog,
  );
  final preparedMap = addBorderLayer(
    map,
    id: layerId,
    name: layerName,
    insertIndex: insertIndex,
  );

  ProjectValidator.validate(preparedManifest);
  MapValidator.validate(
    preparedMap,
    projectDialogueContext: preparedManifest,
  );

  return PreparedBorderProjectMapUpdate(
    manifest: preparedManifest,
    map: preparedMap,
  );
}
