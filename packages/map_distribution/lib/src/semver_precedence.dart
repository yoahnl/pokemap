import 'package:pub_semver/pub_semver.dart';

/// Returns a SemVer value whose ordering ignores build metadata as required by
/// SemVer 2.0.0 precedence rules.
Version semverPrecedenceVersion(Version version) => Version(
      version.major,
      version.minor,
      version.patch,
      pre: version.preRelease.isEmpty ? null : version.preRelease.join('.'),
    );

int compareSemverPrecedence(Version left, Version right) =>
    semverPrecedenceVersion(left).compareTo(semverPrecedenceVersion(right));

bool semverConstraintAllows(
  VersionConstraint constraint,
  Version version,
) {
  if (constraint.isEmpty) return false;
  if (constraint.isAny) return true;
  if (constraint is Version) {
    return compareSemverPrecedence(version, constraint) == 0;
  }
  if (constraint is VersionUnion) {
    return constraint.ranges.any(
      (range) => semverConstraintAllows(range, version),
    );
  }
  if (constraint is VersionRange) {
    final min = constraint.min;
    if (min != null) {
      final comparison = compareSemverPrecedence(version, min);
      if (comparison < 0 || (comparison == 0 && !constraint.includeMin)) {
        return false;
      }
    }
    final max = constraint.max;
    if (max != null) {
      final comparison = compareSemverPrecedence(version, max);
      if (comparison > 0 || (comparison == 0 && !constraint.includeMax)) {
        return false;
      }
    }
    return true;
  }
  throw ArgumentError(
    'Unsupported semantic version constraint: ${constraint.runtimeType}.',
  );
}
