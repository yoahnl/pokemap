import '../models/border_blueprint.dart';
import '../models/border_catalog.dart';
import '../models/border_visual_snapshot.dart';
import 'border_blueprint_json_codec.dart';
import 'border_json_codec_helpers.dart';
import 'border_visual_snapshot_json_codec.dart';

const Set<String> _catalogKeys = <String>{
  'formatVersion',
  'records',
  'visualSnapshots',
};

/// Encodes a complete project Border catalog using its strict wire version.
///
/// Record, snapshot, and frame order is authored data and is preserved exactly.
/// References are not resolved by this codec.
Map<String, Object?> encodeProjectBorderCatalogJson(
  ProjectBorderCatalog catalog, {
  String path = r'$',
}) {
  final formatVersionPath = borderJsonPropertyPath(path, 'formatVersion');
  _requireSupportedVersion(catalog.formatVersion, formatVersionPath);

  final recordsPath = borderJsonPropertyPath(path, 'records');
  final records = <Object?>[];
  final recordIdPaths = <String, String>{};
  for (var index = 0; index < catalog.records.length; index += 1) {
    final record = catalog.records[index];
    final recordPath = borderJsonIndexPath(recordsPath, index);
    _rejectDuplicateId(
      id: record.id,
      idPath: borderJsonPropertyPath(recordPath, 'id'),
      firstPathsById: recordIdPaths,
    );
    records.add(
      encodeBorderBlueprintRecordJson(
        record,
        path: recordPath,
        formatVersion: catalog.formatVersion,
      ),
    );
  }

  final snapshotsPath = borderJsonPropertyPath(path, 'visualSnapshots');
  final visualSnapshots = <Object?>[];
  final snapshotIdPaths = <String, String>{};
  for (var index = 0; index < catalog.visualSnapshots.length; index += 1) {
    final snapshot = catalog.visualSnapshots[index];
    final snapshotPath = borderJsonIndexPath(snapshotsPath, index);
    _rejectDuplicateId(
      id: snapshot.id,
      idPath: borderJsonPropertyPath(snapshotPath, 'id'),
      firstPathsById: snapshotIdPaths,
    );
    visualSnapshots.add(
      encodeBorderVisualSnapshotJson(snapshot, path: snapshotPath),
    );
  }

  return <String, Object?>{
    'formatVersion': catalog.formatVersion,
    'records': records,
    'visualSnapshots': visualSnapshots,
  };
}

/// Decodes a standalone strict V1 through V4 project Border catalog.
///
/// Legacy manifest tolerance belongs to the manifest migration boundary. This
/// standalone codec rejects absent, null, malformed, and future catalog data.
ProjectBorderCatalog decodeProjectBorderCatalogJson(
  Object? json, {
  String path = r'$',
}) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _catalogKeys,
  );

  final formatVersionPath = borderJsonPropertyPath(path, 'formatVersion');
  final formatVersion = borderJsonRequireInt(
    borderJsonRequireField(value, 'formatVersion', path),
    formatVersionPath,
  );
  _requireSupportedVersion(formatVersion, formatVersionPath);

  final recordsPath = borderJsonPropertyPath(path, 'records');
  final recordValues = borderJsonRequireList(
    borderJsonRequireField(value, 'records', path),
    recordsPath,
  );
  final records = <BorderBlueprintRecord>[];
  final recordIdPaths = <String, String>{};
  for (var index = 0; index < recordValues.length; index += 1) {
    final recordPath = borderJsonIndexPath(recordsPath, index);
    final record = decodeBorderBlueprintRecordJson(
      recordValues[index],
      path: recordPath,
      formatVersion: formatVersion,
    );
    _rejectDuplicateId(
      id: record.id,
      idPath: borderJsonPropertyPath(recordPath, 'id'),
      firstPathsById: recordIdPaths,
    );
    records.add(record);
  }

  final snapshotsPath = borderJsonPropertyPath(path, 'visualSnapshots');
  final snapshotValues = borderJsonRequireList(
    borderJsonRequireField(value, 'visualSnapshots', path),
    snapshotsPath,
  );
  final visualSnapshots = <BorderVisualSnapshot>[];
  final snapshotIdPaths = <String, String>{};
  for (var index = 0; index < snapshotValues.length; index += 1) {
    final snapshotPath = borderJsonIndexPath(snapshotsPath, index);
    final snapshot = decodeBorderVisualSnapshotJson(
      snapshotValues[index],
      path: snapshotPath,
    );
    _rejectDuplicateId(
      id: snapshot.id,
      idPath: borderJsonPropertyPath(snapshotPath, 'id'),
      firstPathsById: snapshotIdPaths,
    );
    visualSnapshots.add(snapshot);
  }

  return borderJsonConstructAtPath(
    path,
    () => ProjectBorderCatalog(
      formatVersion: formatVersion,
      records: records,
      visualSnapshots: visualSnapshots,
    ),
  );
}

void _requireSupportedVersion(int value, String path) {
  if (value != ProjectBorderCatalog.formatVersionV1 &&
      value != ProjectBorderCatalog.formatVersionV2 &&
      value != ProjectBorderCatalog.formatVersionV3 &&
      value != ProjectBorderCatalog.formatVersionV4) {
    throw FormatException(
      '$path: expected ProjectBorderCatalog format version 1, 2, 3, or 4',
    );
  }
}

void _rejectDuplicateId({
  required String id,
  required String idPath,
  required Map<String, String> firstPathsById,
}) {
  final firstPath = firstPathsById[id];
  if (firstPath != null) {
    throw FormatException(
      '$idPath: duplicate id "$id"; first declared at $firstPath',
    );
  }
  firstPathsById[id] = idPath;
}
