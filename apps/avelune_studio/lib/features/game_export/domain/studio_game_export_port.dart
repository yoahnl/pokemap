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
}

abstract interface class StudioGameExportPort {
  String get projectName;
  StudioGameExportMetadata? get metadata;
  StudioExportStage get stage;
  String? get error;
  String? get warning;
  String? get outputPath;
  String? get packageSha256;
  String? get sourceRevision;
  bool get busy;
  bool get canCancel;
  bool get canStart;
  Stream<void> get changes;

  Future<void> load();
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
