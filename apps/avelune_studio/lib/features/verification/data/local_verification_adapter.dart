import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core_domain.dart';
import 'package:map_gameplay/map_gameplay.dart'
    show
        NarrativePhysicalIssueCode,
        NarrativePhysicalReachabilityVerdict,
        validateNarrativePhysicalReachability;
import 'package:path/path.dart' as p;

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../domain/verification_port.dart';

class LocalVerificationAdapter implements VerificationPort {
  LocalVerificationAdapter({required this.session, required this.mapAdapter});

  static const receiptPath =
      '.pokemap/validation/narrative_runtime_smoke_receipt.json';
  static const _chunk = 1 << 16;

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;
  final _maps = <String, MapData>{};
  String? _mapsRevision;

  @override
  Future<String> projectRevision() async =>
      (await mapAdapter.resourceBaseline(session)).revision;

  @override
  Future<List<MapData>> loadMaps() async {
    final baseline = await mapAdapter.resourceBaseline(session);
    if (_mapsRevision != baseline.revision) {
      _maps.clear();
      _mapsRevision = baseline.revision;
    }
    for (final entry in baseline.manifest.maps) {
      if (_maps.containsKey(entry.id)) continue;
      _maps[entry.id] = (await mapAdapter.loadMap(session, entry)).map;
    }
    return _maps.values.toList(growable: false);
  }

  @override
  Future<NarrativeValidationDimensionResult> physicalReachability({
    required ProjectManifest project,
    required List<MapData> maps,
    required NarrativeSymbolicReachabilityReport? symbolic,
  }) async {
    if (symbolic == null) {
      return NarrativeValidationDimensionResult(
        status: NarrativeValidationStatus.notRun,
        limitations: const [
          'La preuve symbolique manque : aucune exploration physique n’a '
              'été tentée.',
        ],
      );
    }
    final report = validateNarrativePhysicalReachability(
      project: project,
      maps: maps,
      narrativeReport: symbolic,
    );
    return NarrativeValidationDimensionResult(
      status: switch (report.verdict) {
        NarrativePhysicalReachabilityVerdict.pass =>
          NarrativeValidationStatus.pass,
        NarrativePhysicalReachabilityVerdict.fail =>
          NarrativeValidationStatus.fail,
        NarrativePhysicalReachabilityVerdict.indeterminate =>
          NarrativeValidationStatus.indeterminate,
      },
      diagnostics: [
        for (final issue in report.issues)
          NarrativeMultidimensionalDiagnostic(
            id:
                'physical:${issue.code.name}:${issue.eventId ?? ''}'
                ':${issue.mapId ?? ''}',
            code: issue.code.name,
            severity:
                issue.code == NarrativePhysicalIssueCode.permanentlyBlocked
                ? 'error'
                : 'warning',
            message: issue.message,
            path: issue.mapId == null ? 'maps' : 'maps.${issue.mapId}',
          ),
      ],
    );
  }

  @override
  Future<VerificationRuntimeEvidence> readRuntimeEvidence(
    NarrativeRuntimeSmokeProfile profile,
  ) async {
    final file = File(p.join(session.directoryPath, receiptPath));
    if (!await file.exists()) {
      return const VerificationRuntimeEvidence(
        state: VerificationRuntimeState.absent,
        reason:
            'Aucune preuve d’exécution enregistrée pour ce projet. '
            'La vérification runtime n’a pas été exécutée.',
      );
    }
    final NarrativeRuntimeSmokeReceipt receipt;
    try {
      receipt = NarrativeRuntimeSmokeReceipt.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    } on Object catch (failure) {
      return VerificationRuntimeEvidence(
        state: VerificationRuntimeState.invalid,
        reason: 'La preuve d’exécution est illisible : $failure',
      );
    }
    if (receipt.profileId != profile.id ||
        receipt.profileVersion != profile.version) {
      return VerificationRuntimeEvidence(
        state: VerificationRuntimeState.profileMismatch,
        reason:
            'La preuve vient du profil ${receipt.profileId} '
            'v${receipt.profileVersion}, pas de ${profile.id} '
            'v${profile.version}.',
        receipt: receipt,
      );
    }
    if (!profile.acceptsSuites(receipt.suiteIds)) {
      return VerificationRuntimeEvidence(
        state: VerificationRuntimeState.incompleteSuites,
        reason:
            'La preuve ne couvre pas toutes les suites attendues : '
            '${profile.requiredSuiteIds.join(', ')}.',
        receipt: receipt,
      );
    }
    final String fingerprint;
    try {
      fingerprint = await projectFingerprint();
    } on Object catch (failure) {
      return VerificationRuntimeEvidence(
        state: VerificationRuntimeState.unreadable,
        reason:
            'L’empreinte du projet n’a pas pu être calculée, la preuve ne '
            'peut pas être rattachée à cette version : $failure',
        receipt: receipt,
      );
    }
    if (receipt.projectFingerprint != fingerprint) {
      return VerificationRuntimeEvidence(
        state: VerificationRuntimeState.stale,
        reason:
            'La preuve porte sur une autre version du projet '
            '(${receipt.projectFingerprint.substring(0, 17)}…).',
        receipt: receipt,
      );
    }
    final passed = receipt.result == NarrativeRuntimeSmokeResult.pass;
    return VerificationRuntimeEvidence(
      state: passed
          ? VerificationRuntimeState.freshPass
          : VerificationRuntimeState.freshFail,
      reason: passed
          ? 'Preuve d’exécution du ${receipt.completedAt.toIso8601String()} '
                'sur cette version du projet.'
          : 'L’exécution enregistrée pour cette version a échoué.',
      receipt: receipt,
    );
  }

  /// Same framing and exclusions as the canonical receipt writer, so a
  /// fingerprint computed here is comparable to the one it stored.
  Future<String> projectFingerprint() async {
    final root = Directory(p.normalize(p.absolute(session.directoryPath)));
    if (!await root.exists()) {
      throw const VerificationFailure('Le dossier du projet est introuvable.');
    }
    final files = <({File file, String relativePath})>[];
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relative = p.posix.normalize(
        p.relative(entity.path, from: root.path).replaceAll('\\', '/'),
      );
      if (_ignored(relative)) continue;
      files.add((file: entity, relativePath: relative));
    }
    files.sort(
      (left, right) => left.relativePath.compareTo(right.relativePath),
    );
    final builder = NarrativeProjectFingerprintBuilder();
    for (final entry in files) {
      final handle = await entry.file.open();
      try {
        final length = await handle.length();
        builder.startEntry(
          relativePath: entry.relativePath,
          byteLength: length,
        );
        var read = 0;
        while (read < length) {
          final remaining = length - read;
          final bytes = await handle.read(
            remaining < _chunk ? remaining : _chunk,
          );
          if (bytes.isEmpty) {
            throw const VerificationFailure(
              'Un fichier du projet a changé pendant le calcul.',
            );
          }
          builder.addBytes(bytes);
          read += bytes.length;
        }
        builder.endEntry();
      } finally {
        await handle.close();
      }
    }
    return builder.close();
  }

  static bool _ignored(String relativePath) =>
      relativePath == receiptPath ||
      relativePath.startsWith('.pokemap/validation/') ||
      relativePath.endsWith('.tmp') ||
      relativePath == '.DS_Store';
}
