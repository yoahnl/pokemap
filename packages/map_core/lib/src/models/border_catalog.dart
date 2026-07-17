import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import 'border_blueprint.dart';
import 'border_visual_snapshot.dart';

/// Project-owned catalog of Border blueprint records and immutable snapshots.
@immutable
final class ProjectBorderCatalog {
  static const int formatVersionV1 = 1;
  static const int formatVersionV2 = 2;
  static const int latestSupportedFormatVersion = formatVersionV2;

  /// Backward-compatible alias for [latestSupportedFormatVersion].
  ///
  /// New empty catalogs still default to [formatVersionV1] so merely reading
  /// or authoring unrelated legacy content does not promote the sub-format.
  static const int currentFormatVersion = latestSupportedFormatVersion;

  const ProjectBorderCatalog.empty()
      : formatVersion = formatVersionV1,
        _records = const <BorderBlueprintRecord>[],
        _visualSnapshots = const <BorderVisualSnapshot>[];

  ProjectBorderCatalog({
    this.formatVersion = formatVersionV1,
    List<BorderBlueprintRecord> records = const <BorderBlueprintRecord>[],
    List<BorderVisualSnapshot> visualSnapshots = const <BorderVisualSnapshot>[],
  })  : _records = List<BorderBlueprintRecord>.unmodifiable(records),
        _visualSnapshots =
            List<BorderVisualSnapshot>.unmodifiable(visualSnapshots) {
    if (formatVersion != formatVersionV1 && formatVersion != formatVersionV2) {
      throw ValidationException(
        'ProjectBorderCatalog.formatVersion must be 1 or 2',
      );
    }
    _rejectDuplicateIds<BorderBlueprintRecord>(
      _records,
      (record) => record.id,
      'ProjectBorderCatalog.records must not contain duplicate ids',
    );
    _rejectDuplicateIds<BorderVisualSnapshot>(
      _visualSnapshots,
      (snapshot) => snapshot.id,
      'ProjectBorderCatalog.visualSnapshots must not contain duplicate ids',
    );
  }

  final int formatVersion;
  final List<BorderBlueprintRecord> _records;
  final List<BorderVisualSnapshot> _visualSnapshots;

  List<BorderBlueprintRecord> get records => _records;

  List<BorderVisualSnapshot> get visualSnapshots => _visualSnapshots;

  int get recordCount => _records.length;

  int get visualSnapshotCount => _visualSnapshots.length;

  bool get isEmpty => _records.isEmpty && _visualSnapshots.isEmpty;

  bool get isNotEmpty => !isEmpty;

  BorderBlueprintRecord? recordById(String id) {
    for (final record in _records) {
      if (record.id == id) {
        return record;
      }
    }
    return null;
  }

  BorderVisualSnapshot? visualSnapshotById(String id) {
    for (final snapshot in _visualSnapshots) {
      if (snapshot.id == id) {
        return snapshot;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectBorderCatalog &&
          formatVersion == other.formatVersion &&
          _listsEqual(_records, other._records) &&
          _listsEqual(_visualSnapshots, other._visualSnapshots);

  @override
  int get hashCode => Object.hash(
        formatVersion,
        Object.hashAll(_records),
        Object.hashAll(_visualSnapshots),
      );
}

void _rejectDuplicateIds<T>(
  List<T> values,
  String Function(T) idOf,
  String message,
) {
  final seen = <String>{};
  for (final value in values) {
    final id = idOf(value);
    if (!seen.add(id)) {
      throw ValidationException('$message: $id');
    }
  }
}

bool _listsEqual<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}
