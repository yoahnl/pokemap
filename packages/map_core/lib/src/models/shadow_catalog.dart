import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import 'shadow.dart';

bool _projectShadowProfilesEqualInOrder(
  List<ProjectShadowProfile> a,
  List<ProjectShadowProfile> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i += 1) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Pure in-memory catalog of project shadow profiles.
///
/// Introduced as a standalone value object in Shadow-2, then persisted through
/// [ProjectManifest] in Shadow-5. It owns list immutability, order, id
/// uniqueness, and lookup.
@immutable
final class ProjectShadowCatalog {
  const ProjectShadowCatalog.empty() : _profiles = const [];

  ProjectShadowCatalog({
    List<ProjectShadowProfile> profiles = const [],
  }) : _profiles = _copyProfiles(profiles);

  final List<ProjectShadowProfile> _profiles;

  /// Profiles in insertion order. The returned list is unmodifiable.
  List<ProjectShadowProfile> get profiles => _profiles;

  int get profileCount => _profiles.length;

  bool get isEmpty => _profiles.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Exact, case-sensitive lookup by [ProjectShadowProfile.id].
  ProjectShadowProfile? profileById(String id) {
    for (final profile in _profiles) {
      if (profile.id == id) {
        return profile;
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectShadowCatalog &&
          _projectShadowProfilesEqualInOrder(_profiles, other._profiles);

  @override
  int get hashCode => Object.hashAll(_profiles);
}

List<ProjectShadowProfile> _copyProfiles(List<ProjectShadowProfile> profiles) {
  final copiedProfiles = List<ProjectShadowProfile>.from(profiles);
  _rejectDuplicateProfileIds(copiedProfiles);
  return List<ProjectShadowProfile>.unmodifiable(copiedProfiles);
}

void _rejectDuplicateProfileIds(List<ProjectShadowProfile> profiles) {
  final seen = <String>{};
  for (final profile in profiles) {
    if (!seen.add(profile.id)) {
      throw const ValidationException(
        'ProjectShadowCatalog.profiles must not contain duplicate ProjectShadowProfile.id',
      );
    }
  }
}
