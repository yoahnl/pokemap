part of 'studio_game_export_controller.dart';

extension _StudioGameExportRun on StudioGameExportController {
  Future<bool> _runExport({
    required StudioGameExportMetadata metadata,
    required String outputPath,
    required bool overwriteConfirmed,
    required bool publication,
    required Future<bool> Function() prepare,
    String? Function()? preparationFailure,
    required bool Function() hasPendingChanges,
    required bool Function() isCurrentProject,
  }) async {
    if (!canStart) return false;
    _progress = null;
    final outputFile = File(outputPath);
    if (p.isWithin(projectRoot.absolute.path, outputFile.absolute.path) ||
        p.equals(projectRoot.absolute.path, outputFile.absolute.path)) {
      error = 'Choisissez une destination hors du projet auteur.';
      failure = StudioFailureDiagnosis(
        family: StudioCheckFamily.input,
        owner: StudioFailureOwner.exportDestination,
        summary: error!,
        detail: outputFile.path,
      );
      stage = StudioExportStage.failed;
      _notify();
      return false;
    }
    final operation = ++_operation;
    _inFlight = true;
    this.outputPath = null;
    packageSha256 = null;
    sourceRevision = null;
    error = null;
    failure = null;
    warning = null;
    stage = StudioExportStage.preparing;
    _showStep(StudioExportStep.saveProject);
    bool current() => _valid(operation, isCurrentProject);
    void itemsChecked(StudioExportStep step, int checked, int total) {
      if (!current() || total == 0) return;
      _showStep(step, itemsChecked: checked, itemCount: total);
    }

    try {
      final profile = _profileFrom(this.profile, metadata);
      if (!await prepare()) {
        throw _ExportStop(
          'Enregistrement préalable refusé. ${preparationFailure?.call() ?? 'Consultez le document en échec.'} Les sauvegardes déjà terminées et tous les brouillons restent conservés.',
          StudioCheckFamily.input,
        );
      }
      if (!_valid(operation, isCurrentProject)) return false;
      if (hasPendingChanges()) {
        throw const _ExportStop(
          'Des modifications sont encore en cours. Corrigez-les et relancez l’export.',
          StudioCheckFamily.input,
        );
      }
      final root = projectRoot.path;
      _showStep(StudioExportStep.checkItemIcons);
      final prepareAssets = prepareProjectAssets;
      if (prepareAssets != null) {
        await prepareAssets(root);
      } else {
        final assets = StudioProjectItemIcons.shared;
        await assets.prepareIcons(
          root,
          shouldContinue: current,
          onItemsChecked: (checked, total) =>
              itemsChecked(StudioExportStep.checkItemIcons, checked, total),
        );
        if (!current()) return false;
        _showStep(StudioExportStep.checkCaptureSprites);
        await assets.prepareCaptureSprites(
          root,
          shouldContinue: current,
          onItemsChecked: (checked, total) => itemsChecked(
            StudioExportStep.checkCaptureSprites,
            checked,
            total,
          ),
        );
      }
      if (!_valid(operation, isCurrentProject)) return false;
      if (hasPendingChanges()) {
        throw const _ExportStop(
          'Le projet a changé pendant la préparation des images. Relancez l’export.',
          StudioCheckFamily.launch,
        );
      }
      _showStep(StudioExportStep.verifyProfile);
      final profileStore = GamePackageExportProfileStore(
        projectRoot: projectRoot,
      );
      final profileSnapshot = await profileStore.validate(profile);
      if (_profileRevision != null &&
          _profileRevision != profileSnapshot.profileRevision) {
        throw const GamePackageExportException(
          code: 'exportProfileStale',
          message:
              'Le profil d’export a changé. Rechargez-le avant de continuer.',
        );
      }
      final before = await readFingerprints(root);
      if (!_valid(operation, isCurrentProject)) return false;
      stage = StudioExportStage.building;
      _showStep(StudioExportStep.collectFiles);
      final mode = publication
          ? GamePackageExportMode.publication
          : GamePackageExportMode.localTest;
      final build = buildPackage;
      final artifact = await (build == null
          ? _buildWithProgress(Directory(root), profile, mode, (phase) {
              if (current()) {
                _showStep(switch (phase) {
                  GamePackageBuildPhase.projection =>
                    StudioExportStep.collectFiles,
                  GamePackageBuildPhase.validation =>
                    StudioExportStep.validateGame,
                  GamePackageBuildPhase.archive =>
                    StudioExportStep.buildArchive,
                  GamePackageBuildPhase.inspection =>
                    StudioExportStep.inspectArchive,
                });
              }
            })
          : build(Directory(root), profile, mode));
      if (!_valid(operation, isCurrentProject)) return false;
      final after = await readFingerprints(root);
      if (!_valid(operation, isCurrentProject)) return false;
      if (!sameSourceFiles(before, after) || hasPendingChanges()) {
        throw const _ExportStop(
          'Le projet a changé pendant la construction. Aucun paquet n’a été écrit ; relancez l’export.',
          StudioCheckFamily.launch,
        );
      }
      if (!overwriteConfirmed && await destinationExists(outputFile)) {
        throw const _ExportStop(
          'Le fichier de destination existe désormais. Confirmez son remplacement et relancez l’export.',
          StudioCheckFamily.input,
          StudioFailureOwner.exportDestination,
        );
      }
      if (!_valid(operation, isCurrentProject)) return false;
      stage = StudioExportStage.writing;
      _showStep(StudioExportStep.writePackage);
      if (writePackage case final write?) {
        await write(artifact, outputFile);
      } else {
        await service.writeArtifactToFile(
          artifact: artifact,
          outputFile: outputFile,
        );
      }
      if (!_valid(operation, isCurrentProject)) return false;
      _showStep(StudioExportStep.finishExport);
      try {
        final latest = await readFingerprints(root);
        if (!_valid(operation, isCurrentProject)) return false;
        if (!sameSourceFiles(after, latest) || hasPendingChanges()) {
          warning = 'Le projet a changé après sa capture. Ces modifications ne figurent pas dans ce paquet.';
        }
      } on Object {
        if (!_valid(operation, isCurrentProject)) return false;
        warning = 'Le paquet est prêt, mais les modifications plus récentes du projet n’ont pas pu être vérifiées.';
      }
      this.profile = profile;
      try {
        final saved = await profileStore.save(
          profile,
          expectedProfileRevision: profileSnapshot.profileRevision,
          expectedContextRevision: profileSnapshot.contextRevision,
        );
        _profileRevision = saved.profileRevision;
      } on Object catch (failure) {
        if (!_valid(operation, isCurrentProject)) return false;
        warning = [
          ?warning,
          'Le paquet est prêt, mais le profil d’export n’a pas été mémorisé : $failure',
        ].join(' ');
      }
      if (!_valid(operation, isCurrentProject)) return false;
      sourceRevision = sourceRevisionOf(after);
      this.outputPath = outputFile.path;
      packageSha256 = artifact.packageSha256;
      stage = StudioExportStage.completed;
      _notify();
      return true;
    } on GamePackageExportException catch (failure) {
      if (_valid(operation, isCurrentProject)) {
        final summary = failure.code == 'runtime3d.publication_unsupported'
            ? 'L’export 3D est disponible en mode Test local. '
                  'La publication attend la validation complète sur iOS et Android.'
            : failure.message;
        error = [summary, if (failure.path != null) failure.path!].join(' · ');
        this.failure = diagnoseExportFailure(
          code: failure.code,
          summary: summary,
          path: failure.path,
          readinessCodes: [
            for (final item
                in failure.gameplayReadinessReport?.diagnostics ??
                    const <NarrativeProjectDiagnostic>[])
              if (item.severity == NarrativeProjectDiagnosticSeverity.error)
                item.code,
          ],
        );
        stage = StudioExportStage.failed;
        _notify();
      }
      return false;
    } on _ExportStop catch (stop) {
      if (_valid(operation, isCurrentProject)) {
        error = stop.message;
        failure = StudioFailureDiagnosis(
          family: stop.family,
          owner: stop.owner,
          summary: stop.message,
          detail: stop.message,
        );
        stage = StudioExportStage.failed;
        _notify();
      }
      return false;
    } on Object catch (failure) {
      if (_valid(operation, isCurrentProject)) {
        error = failure is StateError
            ? failure.message.toString()
            : 'Export impossible : $failure';
        this.failure = StudioFailureDiagnosis(
          summary: 'Export impossible.',
          detail: '$failure',
        );
        stage = StudioExportStage.failed;
        _notify();
      }
      return false;
    } finally {
      _inFlight = false;
      _notify();
    }
  }
}

final class _ExportStop implements Exception {
  const _ExportStop(this.message, this.family, [this.owner]);
  final String message;
  final StudioCheckFamily family;
  final StudioFailureOwner? owner;
}

Future<GamePackageExportArtifact> _buildInIsolate(
  Directory root,
  GamePackageExportProfile profile,
  GamePackageExportMode mode,
  SendPort progress,
) => Isolate.run(
  () => const CanonicalGamePackageExportService().build(
    projectRoot: root,
    profile: profile,
    mode: mode,
    onPhase: progress.send,
  ),
);

Future<GamePackageExportArtifact> _buildWithProgress(
  Directory root,
  GamePackageExportProfile profile,
  GamePackageExportMode mode,
  void Function(GamePackageBuildPhase phase) onPhase,
) async {
  final progress = ReceivePort();
  progress.listen((message) {
    if (message is GamePackageBuildPhase) onPhase(message);
  });
  try {
    return await _buildInIsolate(root, profile, mode, progress.sendPort);
  } finally {
    progress.close();
  }
}
