import 'dart:async';

import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/features/verification/application/studio_failure_diagnosis.dart';

class GameExportUiProbe implements StudioGameExportPort {
  @override
  String get projectName => 'UwU';
  @override
  StudioGameExportMetadata? metadata = const StudioGameExportMetadata(
    gameId: 'games.example.uwu',
    title: 'UwU',
    author: 'Yoahn',
    version: '0.1.0',
    locale: 'fr',
    locales: 'fr, en',
  );
  @override
  StudioExportStage stage = StudioExportStage.idle;
  @override
  StudioExportProgress? progress;
  @override
  String? error, warning, outputPath, packageSha256, sourceRevision;
  @override
  StudioFailureDiagnosis? failure;
  @override
  bool operationActive = false;
  bool loadFailed = false;
  StudioGameIdentityProblem? problem;
  Completer<void>? gate;
  StudioExportStage heldStage = StudioExportStage.building;
  int loads = 0, exports = 0, preparations = 0;
  bool? overwrite, publicationMode;
  StudioGameExportMetadata? submitted;
  final _changes = StreamController<void>.broadcast();
  @override
  Stream<void> get changes => _changes.stream;
  @override
  bool get busy => operationActive && stage != StudioExportStage.cancelled;
  @override
  bool get canCancel => busy && stage != StudioExportStage.writing;
  @override
  bool get canStart => !loadFailed && !operationActive;
  @override
  Future<void> load() async {
    loads++;
  }

  @override
  StudioGameIdentityProblem? checkIdentity(StudioGameExportMetadata value) =>
      problem;
  void notify() => _changes.add(null);
  @override
  void cancel() {
    if (!canCancel) return;
    stage = StudioExportStage.cancelled;
    notify();
  }

  @override
  Future<bool> export({
    required StudioGameExportMetadata metadata,
    required String outputPath,
    required bool overwriteConfirmed,
    required bool publication,
    required Future<bool> Function() prepare,
    String? Function()? preparationFailure,
    required bool Function() hasPendingChanges,
    required bool Function() isCurrentProject,
  }) async {
    exports++;
    submitted = metadata;
    overwrite = overwriteConfirmed;
    publicationMode = publication;
    operationActive = true;
    stage = StudioExportStage.preparing;
    progress = (
      step: StudioExportStep.saveProject,
      itemsChecked: null,
      itemCount: null,
    );
    notify();
    preparations++;
    final saved = await prepare();
    if (saved && !hasPendingChanges() && isCurrentProject()) {
      stage = heldStage;
      progress = (
        step: StudioExportStep.collectFiles,
        itemsChecked: null,
        itemCount: null,
      );
      notify();
      await gate?.future;
      if (stage != StudioExportStage.cancelled && isCurrentProject()) {
        stage = StudioExportStage.completed;
        this.outputPath = outputPath;
        this.metadata = metadata;
      }
    } else {
      stage = StudioExportStage.failed;
      error = preparationFailure?.call() ?? 'Enregistrement préalable refusé';
    }
    operationActive = false;
    notify();
    return stage == StudioExportStage.completed;
  }

  @override
  void dispose() {
    unawaited(_changes.close());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
