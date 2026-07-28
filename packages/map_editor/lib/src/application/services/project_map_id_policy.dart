import '../errors/application_errors.dart';

/// Validates IDs created by authoring workflows without rewriting legacy data.
///
/// A canonical ID is safe to embed in a map filename: it contains only
/// lowercase ASCII letters, digits, `_`, and `-`, with an alphanumeric first
/// and last character. Existing persisted IDs remain a separate migration
/// concern and must not be silently normalized by this policy.
final class ProjectMapIdPolicy {
  static const int maxLength = 64;

  static final RegExp _canonicalPattern = RegExp(
    r'^[a-z0-9](?:[a-z0-9_-]*[a-z0-9])?$',
  );

  static const Set<String> _windowsReservedNames = <String>{
    'con',
    'prn',
    'aux',
    'nul',
    'com1',
    'com2',
    'com3',
    'com4',
    'com5',
    'com6',
    'com7',
    'com8',
    'com9',
    'lpt1',
    'lpt2',
    'lpt3',
    'lpt4',
    'lpt5',
    'lpt6',
    'lpt7',
    'lpt8',
    'lpt9',
  };

  const ProjectMapIdPolicy();

  String requireValid(String rawId) {
    if (rawId.isEmpty) {
      throw const EditorValidationException('Map ID cannot be empty');
    }
    if (rawId.length > maxLength) {
      throw const EditorValidationException(
        'Map ID cannot exceed 64 characters',
      );
    }
    if (!_canonicalPattern.hasMatch(rawId)) {
      throw EditorValidationException(
        'Map ID "$rawId" must use lowercase ASCII letters, digits, "_" or '
        '"-", and start and end with a letter or digit',
      );
    }

    // Keep this platform-neutral: projects authored on macOS must remain
    // writable when moved to Windows.
    if (_windowsReservedNames.contains(rawId.toLowerCase())) {
      throw EditorValidationException(
        'Map ID "$rawId" is reserved by Windows',
      );
    }

    return rawId;
  }

  /// Lists persisted IDs that cannot participate in normal map authoring.
  ///
  /// The values are returned byte-for-byte so callers can diagnose legacy
  /// data without silently normalizing or migrating the project.
  List<String> nonCanonicalIds(Iterable<String> persistedIds) {
    final invalidIds = <String>[];
    for (final persistedId in persistedIds) {
      try {
        requireValid(persistedId);
      } on EditorValidationException {
        invalidIds.add(persistedId);
      }
    }
    return List<String>.unmodifiable(invalidIds);
  }

  void requireAvailable(
    String mapId,
    Iterable<String> existingIds, {
    String? excludingId,
  }) {
    final canonicalId = requireValid(mapId);
    final comparisonId = canonicalId.toLowerCase();

    for (final existingId in existingIds) {
      final existingComparisonId = existingId.toLowerCase();
      // Exclude only the identified source entry. A second entry that differs
      // only by case is still a real collision and must not be hidden.
      if (existingId == excludingId) {
        continue;
      }
      if (existingComparisonId == comparisonId) {
        throw EditorConflictException(
          'A map with the ID "$canonicalId" already exists',
        );
      }
    }
  }

  String nextCopyId(String sourceId, Iterable<String> existingIds) {
    final canonicalSourceId = requireValid(sourceId);
    final occupiedIds =
        existingIds.map((existingId) => existingId.toLowerCase()).toSet();

    var copyNumber = 0;
    while (true) {
      final suffix = copyNumber == 0 ? '_copy' : '_copy_$copyNumber';
      final sourceLength = maxLength - suffix.length;
      if (sourceLength < 1) {
        throw const EditorConflictException(
          'Unable to generate an available map copy ID',
        );
      }

      // Reserve the suffix before truncating so every generated candidate
      // remains canonical and never exceeds the persisted ID limit.
      final boundedSource = canonicalSourceId.length <= sourceLength
          ? canonicalSourceId
          : canonicalSourceId.substring(0, sourceLength);
      final candidate = '$boundedSource$suffix';
      if (!occupiedIds.contains(candidate.toLowerCase())) {
        return candidate;
      }

      copyNumber += 1;
    }
  }
}
