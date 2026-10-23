import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:map_authoring/map_authoring_local.dart'
    show LocalProjectFileReader;
import 'package:map_core/map_core_domain.dart';
import 'package:path/path.dart' as p;

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../narrative/data/local_narrative_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../../presentations/data/local_presentation_adapter.dart';
import '../domain/verification_port.dart';
import 'verification_analysis_worker.dart';

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
  Future<List<VerificationDialogueSource>> readDialogueSources(
    List<ProjectDialogueEntry> entries,
  ) async {
    final reader = LocalNarrativeAdapter(
      session: session,
      mapAdapter: mapAdapter,
    );
    final sources = <VerificationDialogueSource>[];
    for (final entry in entries) {
      try {
        final read = await reader.readDialogue(entry);
        sources.add(
          VerificationDialogueSource(
            entry: read.entry,
            text: read.source,
            origin: 'version enregistrée',
            revision: read.revision,
          ),
        );
      } on Object catch (failure) {
        sources.add(
          VerificationDialogueSource(
            entry: entry,
            text: '',
            origin: 'version enregistrée',
            problem: 'Source illisible : $failure',
          ),
        );
      }
    }
    return sources;
  }

  @override
  VerificationJob analyse({
    required ProjectManifest project,
    required List<MapData> maps,
    required List<VerificationDialogueSource> sources,
  }) {
    final replies = ReceivePort();
    final completer = Completer<VerificationAnalysis>();
    Isolate? worker;
    var settled = false;
    void finish(void Function() apply) {
      if (settled) return;
      settled = true;
      replies.close();
      apply();
    }

    replies.listen((message) {
      if (message is VerificationAnalysis) {
        finish(() => completer.complete(message));
      } else {
        finish(
          () =>
              completer.completeError(VerificationFailure(message.toString())),
        );
      }
    });
    unawaited(() async {
      try {
        final itemCatalog = await _loadItemCatalog(project, maps);
        final hasPictures = project.scenes.any(
          (scene) => scene.graph.nodes.any((node) {
            final payload = node.payload;
            final command = payload is SceneActionPayload
                ? payload.interactiveCommand
                : null;
            return command is SceneWorldPresentationInteractiveCommand &&
                command.operation ==
                    SceneWorldPresentationOperation.showPicture;
          }),
        );
        final presentationMediaCatalog =
            hasPictures && project.settings.dimension == ProjectDimension.twoD
            ? (await LocalPresentationAdapter(
                session: session,
                mapAdapter: mapAdapter,
              ).prepare(project)).mediaCatalog
            : null;
        if (settled) return;
        final spawned = await Isolate.spawn(
          verificationAnalysisWorker,
          VerificationAnalysisRequest(
            replies.sendPort,
            project,
            maps,
            sources,
            itemCatalog: itemCatalog,
            presentationMediaCatalog: presentationMediaCatalog,
          ),
          debugName: verificationWorkerName,
          errorsAreFatal: true,
          onError: replies.sendPort,
          onExit: replies.sendPort,
        );
        if (settled) {
          spawned.kill(priority: Isolate.immediate);
          return;
        }
        worker = spawned;
      } on Object catch (error) {
        finish(
          () => completer.completeError(VerificationFailure(error.toString())),
        );
      }
    }());
    return VerificationJob(
      result: completer.future,
      cancel: () => finish(() {
        worker?.kill(priority: Isolate.immediate);
        worker = null;
        completer.completeError(
          const VerificationFailure('Contrôle abandonné.'),
        );
      }),
    );
  }

  Future<ProjectItemCatalog?> _loadItemCatalog(
    ProjectManifest project,
    List<MapData> maps,
  ) async {
    final required = buildNarrativeDependencyIndex(project: project, maps: maps)
        .usages
        .any(
          (usage) => usage.target.kind == NarrativeDependencyTargetKind.item,
        );
    final path = project.pokemon.catalogFiles['items']?.trim();
    if (!required || path == null || path.isEmpty) return null;
    try {
      final bytes = await const LocalProjectFileReader().readBytes(
        projectRoot: session.directoryPath,
        relativePath: path,
      );
      final catalog = decodeProjectItemCatalog(jsonDecode(utf8.decode(bytes)));
      final validation = validateProjectItemCatalog(
        catalog,
        capabilityTruth: itemSystemV1CapabilityTruth,
      );
      final blocking = validation.diagnostics
          .where((diagnostic) => diagnostic.isBlocking)
          .firstOrNull;
      if (blocking != null) {
        throw FormatException('${blocking.path} : ${blocking.message}');
      }
      return catalog;
    } on Object catch (failure) {
      throw VerificationFailure(
        'Catalogue des objets illisible ($path) : $failure',
      );
    }
  }

  @override
  Future<VerificationRuntimeEvidence> readRuntimeEvidence(
    NarrativeRuntimeSmokeProfile? profile,
  ) async {
    if (profile == null) {
      return const VerificationRuntimeEvidence(
        state: VerificationRuntimeState.unconfigured,
        reason: 'Aucun profil de vérification runtime n’est configuré pour ce projet.',
      );
    }
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
