import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:path/path.dart' as p;

import '../domain/studio_game_export_port.dart';
import '../../verification/application/studio_failure_diagnosis.dart';
import '../../pokemon/data/studio_project_item_icons.dart';
import 'studio_export_revision.dart';

part 'studio_game_export_identity.dart';
part 'studio_game_export_run.dart';

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
    this.prepareProjectAssets,
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
  final Future<void> Function(String projectRoot)? prepareProjectAssets;
  @override
  StudioExportStage stage = StudioExportStage.idle;
  GamePackageExportProfile? profile;
  String? _profileRevision;
  @override
  StudioGameExportMetadata? get metadata => _metadataOf(profile);

  StudioGameIdentityState _identityOf(
    GamePackageExportProfileSnapshot snapshot,
  ) => StudioGameIdentityState(
    metadata: _metadataOf(snapshot.profile),
    profileRevision: snapshot.profileRevision,
    contextRevision: snapshot.contextRevision,
  );

  @override
  Future<StudioGameIdentityState> readIdentity() async {
    final snapshot = await GamePackageExportProfileStore(
      projectRoot: projectRoot,
    ).read();
    profile = snapshot.profile;
    _profileRevision = snapshot.profileRevision;
    _profileLoadFailed = false;
    return _identityOf(snapshot);
  }

  @override
  StudioGameIdentityProblem? checkIdentity(StudioGameExportMetadata metadata) {
    try {
      _profileFrom(profile, metadata);
      return null;
    } on GamePackageExportException catch (failure) {
      return studioGameIdentityProblem(failure.code, metadata);
    }
  }

  @override
  Future<StudioGameIdentityState> saveIdentity(
    StudioGameExportMetadata metadata, {
    required String expectedProfileRevision,
    required String expectedContextRevision,
  }) async {
    final store = GamePackageExportProfileStore(projectRoot: projectRoot);
    if (_profileRevision != expectedProfileRevision) {
      final latest = await store.read();
      throw StudioGameIdentityConflict(
        _identityOf(latest),
        contextOnly: latest.profileRevision == expectedProfileRevision,
      );
    }
    final next = _profileFrom(profile, metadata);
    final GamePackageExportProfileSnapshot saved;
    try {
      saved = await store.save(
        next,
        expectedProfileRevision: expectedProfileRevision,
        expectedContextRevision: expectedContextRevision,
      );
    } on GamePackageExportException catch (failure) {
      if (failure.code != 'exportProfileStale') rethrow;
      final latest = await store.read();
      throw StudioGameIdentityConflict(
        _identityOf(latest),
        contextOnly: latest.profileRevision == expectedProfileRevision,
      );
    }
    profile = saved.profile;
    _profileRevision = saved.profileRevision;
    _profileLoadFailed = false;
    _notify();
    return _identityOf(saved);
  }
  final _changes = StreamController<void>.broadcast();
  @override
  Stream<void> get changes => _changes.stream;
  @override
  String? error;
  @override
  StudioFailureDiagnosis? failure;
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
      final saved = await GamePackageExportProfileStore(
        projectRoot: projectRoot,
      ).read();
      profile = saved.profile;
      _profileRevision = saved.profileRevision;
      _profileLoadFailed = false;
    } on Object catch (failure) {
      _profileLoadFailed = true;
      error = 'Profil d’export illisible : $failure';
      this.failure = StudioFailureDiagnosis(
        family: StudioCheckFamily.input,
        summary: 'Profil d’export illisible.',
        detail: '$failure',
      );
      stage = StudioExportStage.failed;
    }
    _notify();
  }

  @override
  void cancel() {
    if (!canCancel) return;
    _operation++;
    stage = StudioExportStage.cancelled;
    failure = null;
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
  }) => _runExport(
    metadata: metadata,
    outputPath: outputPath,
    overwriteConfirmed: overwriteConfirmed,
    publication: publication,
    prepare: prepare,
    preparationFailure: preparationFailure,
    hasPendingChanges: hasPendingChanges,
    isCurrentProject: isCurrentProject,
  );

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
