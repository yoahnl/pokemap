import '../../verification/application/studio_failure_diagnosis.dart';

enum StudioExportStage {
  idle,
  preparing,
  building,
  writing,
  completed,
  failed,
  cancelled,
}

final class StudioGameExportDestination {
  const StudioGameExportDestination(this.path, {required this.exists});
  final String path;
  final bool exists;
}

typedef PickGameExportFile =
    Future<StudioGameExportDestination?> Function(String suggestedName);

final class StudioGameExportMetadata {
  const StudioGameExportMetadata({
    required this.gameId,
    required this.title,
    required this.version,
    required this.author,
    required this.locale,
    required this.locales,
  });

  final String gameId;
  final String title;
  final String version;
  final String author;
  final String locale;
  final String locales;

  StudioGameExportMetadata copyWith({
    String? title,
    String? version,
    String? author,
    String? locale,
    String? locales,
  }) => StudioGameExportMetadata(
    gameId: gameId,
    title: title ?? this.title,
    version: version ?? this.version,
    author: author ?? this.author,
    locale: locale ?? this.locale,
    locales: locales ?? this.locales,
  );

  @override
  bool operator ==(Object other) =>
      other is StudioGameExportMetadata &&
      other.gameId == gameId &&
      other.title == title &&
      other.version == version &&
      other.author == author &&
      other.locale == locale &&
      other.locales == locales;

  @override
  int get hashCode =>
      Object.hash(gameId, title, version, author, locale, locales);
}

enum StudioGameIdentityField { gameId, title, version, author, locale, locales }

final class StudioGameIdentityProblem {
  const StudioGameIdentityProblem(this.field, this.message);
  final StudioGameIdentityField? field;
  final String message;
}

final class StudioGameIdentityState {
  const StudioGameIdentityState({
    required this.metadata,
    required this.profileRevision,
    required this.contextRevision,
  });
  final StudioGameExportMetadata? metadata;
  final String profileRevision;
  final String contextRevision;
}

final class StudioGameIdentityConflict implements Exception {
  const StudioGameIdentityConflict(this.current, {required this.contextOnly});
  final StudioGameIdentityState current;
  final bool contextOnly;
}

abstract interface class StudioGameExportPort {
  String get projectName;
  StudioGameExportMetadata? get metadata;
  StudioExportStage get stage;
  String? get error;
  StudioFailureDiagnosis? get failure;
  String? get warning;
  String? get outputPath;
  String? get packageSha256;
  String? get sourceRevision;
  bool get busy;
  bool get canCancel;
  bool get canStart;
  bool get operationActive;
  Stream<void> get changes;

  Future<void> load();
  Future<StudioGameIdentityState> readIdentity();
  StudioGameIdentityProblem? checkIdentity(StudioGameExportMetadata metadata);
  Future<StudioGameIdentityState> saveIdentity(
    StudioGameExportMetadata metadata, {
    required String expectedProfileRevision,
    required String expectedContextRevision,
  });
  void cancel();
  Future<bool> export({
    required StudioGameExportMetadata metadata,
    required String outputPath,
    required bool overwriteConfirmed,
    required bool publication,
    required Future<bool> Function() prepare,
    String? Function()? preparationFailure,
    required bool Function() hasPendingChanges,
    required bool Function() isCurrentProject,
  });
  void dispose();
}
