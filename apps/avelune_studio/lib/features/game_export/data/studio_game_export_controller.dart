import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as p;

import '../domain/studio_game_export_port.dart';
import 'studio_export_revision.dart';

typedef BuildStudioGamePackage =
    Future<GamePackageExportArtifact> Function(
      Directory projectRoot,
      GamePackageExportProfile profile,
      GamePackageExportMode mode,
    );
typedef WriteStudioGamePackage =
    Future<void> Function(GamePackageExportArtifact artifact, File outputFile);
typedef ReadStudioSourceFingerprints =
    Future<Map<String, String>> Function(String projectRoot);
typedef CheckStudioExportDestination = Future<bool> Function(File outputFile);

final class StudioGameExportController implements StudioGameExportPort {
  StudioGameExportController({
    required this.projectRoot,
    required this.projectName,
    CanonicalGamePackageExportService? service,
    BuildStudioGamePackage? buildPackage,
    this.writePackage,
    ReadStudioSourceFingerprints? readFingerprints,
    CheckStudioExportDestination? destinationExists,
  }) : service = service ?? const CanonicalGamePackageExportService(),
       buildPackage = buildPackage ?? _buildInIsolate,
       readFingerprints =
           readFingerprints ??
           ((root) => Isolate.run(() => sourceFingerprints(root))),
       destinationExists = destinationExists ?? ((file) => file.exists());

  final Directory projectRoot;
  @override
  final String projectName;
  final CanonicalGamePackageExportService service;
  final BuildStudioGamePackage buildPackage;
  final WriteStudioGamePackage? writePackage;
  final ReadStudioSourceFingerprints readFingerprints;
  final CheckStudioExportDestination destinationExists;
  @override
  StudioExportStage stage = StudioExportStage.idle;
  GamePackageExportProfile? profile;
  @override
  StudioGameExportMetadata? get metadata => profile == null
      ? null
      : StudioGameExportMetadata(
          gameId: profile!.gameId,
          title: profile!.title,
          version: profile!.gameVersion,
          author: profile!.authorName,
          locale: profile!.defaultLocale,
          locales: profile!.supportedLocales.join(', '),
        );
  final _changes = StreamController<void>.broadcast();
  @override
  Stream<void> get changes => _changes.stream;
  @override
  String? error;
  @override
  String? warning;
  @override
  String? outputPath;
  @override
  String? packageSha256;
  @override
  String? sourceRevision;
  int _operation = 0;
  bool _disposed = false;
  bool _inFlight = false;
  bool _profileLoadFailed = false;
  @override
  bool get busy =>
      stage == StudioExportStage.preparing ||
      stage == StudioExportStage.building ||
      stage == StudioExportStage.writing;
  @override
  bool get canCancel =>
      !_disposed && busy && stage != StudioExportStage.writing;
  @override
  bool get canStart => !_inFlight && !_disposed && !_profileLoadFailed;
  @override
  bool get operationActive => _inFlight;

  @override
  Future<void> load() async {
    try {
      profile = await GamePackageExportProfileStore(
        projectRoot: projectRoot,
      ).load();
      _profileLoadFailed = false;
    } on Object catch (failure) {
      _profileLoadFailed = true;
      error = 'Profil d’export illisible : $failure';
      stage = StudioExportStage.failed;
    }
    _notify();
  }

  @override
  void cancel() {
    if (!canCancel) return;
    _operation++;
    stage = StudioExportStage.cancelled;
    error =
        'Export abandonné avant l’écriture du fichier. Un enregistrement déjà lancé peut toutefois se terminer.';
    _notify();
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
    if (!canStart) return false;
    final outputFile = File(outputPath);
    if (p.isWithin(projectRoot.absolute.path, outputFile.absolute.path) ||
        p.equals(projectRoot.absolute.path, outputFile.absolute.path)) {
      error = 'Choisissez une destination hors du projet auteur.';
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
    warning = null;
    stage = StudioExportStage.preparing;
    _notify();
    try {
      final profile = this.profile == null
          ? GamePackageExportProfile(
              gameId: metadata.gameId.trim(),
              gameVersion: metadata.version.trim(),
              title: metadata.title.trim(),
              authorName: metadata.author.trim(),
              defaultLocale: metadata.locale.trim(),
              supportedLocales: metadata.locales
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList(),
            )
          : this.profile!.copyWith(
              gameId: metadata.gameId.trim(),
              gameVersion: metadata.version.trim(),
              title: metadata.title.trim(),
              authorName: metadata.author.trim(),
              defaultLocale: metadata.locale.trim(),
              supportedLocales: metadata.locales
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList(),
            );
      if (!await prepare()) {
        throw StateError(
          'Enregistrement préalable refusé. ${preparationFailure?.call() ?? 'Consultez le document en échec.'} Les sauvegardes déjà terminées et tous les brouillons restent conservés.',
        );
      }
      if (!_valid(operation, isCurrentProject)) return false;
      if (hasPendingChanges()) {
        throw StateError(
          'Des modifications sont encore en cours. Corrigez-les et relancez l’export.',
        );
      }
      final root = projectRoot.path;
      final before = await readFingerprints(root);
      if (!_valid(operation, isCurrentProject)) return false;
      stage = StudioExportStage.building;
      _notify();
      final artifact = await buildPackage(
        Directory(root),
        profile,
        publication
            ? GamePackageExportMode.publication
            : GamePackageExportMode.localTest,
      );
      if (!_valid(operation, isCurrentProject)) return false;
      final after = await readFingerprints(root);
      if (!_valid(operation, isCurrentProject)) return false;
      if (!sameSourceFiles(before, after) || hasPendingChanges()) {
        throw StateError(
          'Le projet a changé pendant la construction. Aucun paquet n’a été écrit ; relancez l’export.',
        );
      }
      if (!overwriteConfirmed && await destinationExists(outputFile)) {
        throw StateError(
          'Le fichier de destination existe désormais. Confirmez son remplacement et relancez l’export.',
        );
      }
      if (!_valid(operation, isCurrentProject)) return false;
      stage = StudioExportStage.writing;
      _notify();
      if (writePackage case final write?) {
        await write(artifact, outputFile);
      } else {
        await service.writeArtifactToFile(
          artifact: artifact,
          outputFile: outputFile,
        );
      }
      if (!_valid(operation, isCurrentProject)) return false;
      try {
        final latest = await readFingerprints(root);
        if (!_valid(operation, isCurrentProject)) return false;
        if (!sameSourceFiles(after, latest) || hasPendingChanges()) {
          warning =
              'Le projet a changé après sa capture. Ces modifications ne figurent pas dans ce paquet.';
        }
      } on Object {
        if (!_valid(operation, isCurrentProject)) return false;
        warning =
            'Le paquet est prêt, mais les modifications plus récentes du projet n’ont pas pu être vérifiées.';
      }
      this.profile = profile;
      try {
        await GamePackageExportProfileStore(
          projectRoot: projectRoot,
        ).save(profile);
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
        error = [
          failure.message,
          if (failure.path != null) failure.path!,
        ].join(' · ');
        stage = StudioExportStage.failed;
        _notify();
      }
      return false;
    } on Object catch (failure) {
      if (_valid(operation, isCurrentProject)) {
        error = failure is StateError
            ? failure.message.toString()
            : 'Export impossible : $failure';
        stage = StudioExportStage.failed;
        _notify();
      }
      return false;
    } finally {
      _inFlight = false;
      _notify();
    }
  }

  bool _valid(int operation, bool Function() isCurrentProject) =>
      !_disposed && operation == _operation && isCurrentProject();

  void _notify() {
    if (!_disposed) _changes.add(null);
  }

  @override
  void dispose() {
    _disposed = true;
    _operation++;
    _changes.close();
  }
}

Future<GamePackageExportArtifact> _buildInIsolate(
  Directory root,
  GamePackageExportProfile profile,
  GamePackageExportMode mode,
) => Isolate.run(
  () => const CanonicalGamePackageExportService().build(
    projectRoot: root,
    profile: profile,
    mode: mode,
  ),
);
