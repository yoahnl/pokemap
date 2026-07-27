import 'package:map_core/map_core.dart';

/// Summary level used by the Personalization Studio publication gate.
enum PersonalizationReadinessStatus {
  ready,
  attention,
  blocked,
}

/// A normalized publication issue, independent from its future presentation.
final class PersonalizationReadinessIssue {
  const PersonalizationReadinessIssue({
    required this.code,
    required this.category,
    required this.severity,
    required this.path,
    required this.message,
  });

  factory PersonalizationReadinessIssue.fromDiagnostic(
    ProjectPresentationDiagnostic diagnostic,
  ) =>
      PersonalizationReadinessIssue(
        code: diagnostic.code,
        category: diagnostic.category,
        severity: diagnostic.severity,
        path: diagnostic.path,
        message: diagnostic.message,
      );

  final String code;
  final ProjectPresentationCategory category;
  final ProjectPresentationDiagnosticSeverity severity;
  final String path;
  final String message;

  bool get isBlocker => severity == ProjectPresentationDiagnosticSeverity.error;
}

/// Readiness of one stable Personalization Studio category.
final class PersonalizationCategoryReadiness {
  PersonalizationCategoryReadiness({
    required this.category,
    required this.isConfigured,
    required Iterable<PersonalizationReadinessIssue> issues,
  }) : issues = List<PersonalizationReadinessIssue>.unmodifiable(issues);

  final ProjectPresentationCategory category;
  final bool isConfigured;
  final List<PersonalizationReadinessIssue> issues;

  int get blockerCount => issues.where((issue) => issue.isBlocker).length;

  int get warningCount => issues.length - blockerCount;

  PersonalizationReadinessStatus get status {
    if (blockerCount > 0) return PersonalizationReadinessStatus.blocked;
    if (warningCount > 0) return PersonalizationReadinessStatus.attention;
    return PersonalizationReadinessStatus.ready;
  }
}

/// Pure, deterministic projection used by the Studio readiness dashboard.
final class PersonalizationPublishReadiness {
  PersonalizationPublishReadiness._({
    required this.profile,
    required Iterable<PersonalizationReadinessIssue> issues,
  })  : issues = List<PersonalizationReadinessIssue>.unmodifiable(issues),
        categories = List<PersonalizationCategoryReadiness>.unmodifiable(
          ProjectPresentationCategory.values.map(
            (category) => PersonalizationCategoryReadiness(
              category: category,
              isConfigured: profile.configuredCategories.contains(category),
              issues: issues.where((issue) => issue.category == category),
            ),
          ),
        );

  factory PersonalizationPublishReadiness.fromProfile(
    ProjectPresentationProfile profile,
  ) =>
      PersonalizationPublishReadiness._(
        profile: profile,
        issues: validateProjectPresentationProfile(profile)
            .map(PersonalizationReadinessIssue.fromDiagnostic),
      );

  factory PersonalizationPublishReadiness.fromIssues({
    required ProjectPresentationProfile profile,
    required Iterable<PersonalizationReadinessIssue> issues,
  }) =>
      PersonalizationPublishReadiness._(
        profile: profile,
        issues: issues,
      );

  final ProjectPresentationProfile profile;
  final List<PersonalizationReadinessIssue> issues;
  final List<PersonalizationCategoryReadiness> categories;

  int get blockerCount => issues.where((issue) => issue.isBlocker).length;

  int get warningCount => issues.length - blockerCount;

  bool get isReadyToExport => blockerCount == 0;

  PersonalizationReadinessStatus get status {
    if (blockerCount > 0) return PersonalizationReadinessStatus.blocked;
    if (warningCount > 0) return PersonalizationReadinessStatus.attention;
    return PersonalizationReadinessStatus.ready;
  }

  PersonalizationCategoryReadiness forCategory(
    ProjectPresentationCategory category,
  ) =>
      categories.firstWhere((item) => item.category == category);
}
