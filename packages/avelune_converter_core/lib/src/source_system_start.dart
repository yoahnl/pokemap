part of '../avelune_converter_core.dart';

final class SourceSystemStart {
  SourceSystemStart._(
      this.sourceSnapshotHash,
      this.normalizationHash,
      this.systemFileId,
      this.systemContentHash,
      this.sourceMapId,
      this.x,
      this.y);

  final Sha256Hash sourceSnapshotHash, normalizationHash, systemContentHash;
  final ConverterId systemFileId;
  final int sourceMapId, x, y;

  bool isBoundTo(NormalizedSourceProject source) =>
      source.snapshot.canonicalHash == sourceSnapshotHash &&
      source.canonicalHash == normalizationHash &&
      canonicalJsonOf(sourceSystemStart(source)?.toJson()) ==
          canonicalJsonOf(toJson());

  Map<String, Object?> toJson() => {
        'kind': 'sourceSystemStart',
        'sourceSnapshotHash': sourceSnapshotHash.value,
        'normalizationHash': normalizationHash.value,
        'systemFileId': systemFileId.value,
        'systemContentHash': systemContentHash.value,
        'sourceMapId': sourceMapId,
        'x': x,
        'y': y,
      };
}

SourceSystemStart? sourceSystemStart(NormalizedSourceProject source) {
  final analyzer = SourceEventAnalyzer.forProject(source,
      profile: SourceEventProfile.forProject(source));
  if (!analyzer._isQualified) {
    return null;
  }
  try {
    final systems = source.sourceFiles.values.where((file) =>
        sourcePathCollisionKey(file.entry.relativePath) ==
        'data/system.rxdata');
    if (systems.length != 1 ||
        !analyzer._admitted(systems.single) ||
        systems.single.isAdapted) {
      return null;
    }
    final system = systems.single;
    final fields =
        _eventFields(system.document, system.document.rootId, 'RPG::System');
    int integer(String name) =>
        _eventInt(system.document, _eventField(fields, name));
    final mapId = integer('@start_map_id');
    final x = integer('@start_x');
    final y = integer('@start_y');
    final maps = source.maps.where((entry) => entry.map.sourceMapId == mapId);
    if (maps.length != 1 ||
        x < 0 ||
        y < 0 ||
        x >= maps.single.map.width ||
        y >= maps.single.map.height) {
      return null;
    }
    return SourceSystemStart._(source.snapshot.canonicalHash,
        source.canonicalHash, system.fileId, system.contentHash, mapId, x, y);
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  } on RangeError {
    return null;
  } on StateError {
    return null;
  }
}
