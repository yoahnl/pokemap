import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:map_authoring/map_authoring.dart'
    show projectMediaCatalogStorageKey;
import 'package:map_authoring/map_authoring_local.dart'
    show LocalProjectFileReader;
import 'package:map_core/map_core_domain.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../../presentations/data/local_presentation_adapter.dart';
import '../domain/verification_port.dart';
import 'verification_analysis_worker.dart';
import 'verification_input_revision.dart';
import 'verification_runtime_evidence.dart';

class LocalVerificationAdapter implements VerificationPort {
  LocalVerificationAdapter({required this.session, required this.mapAdapter});

  static const receiptPath =
      '.pokemap/validation/narrative_runtime_smoke_receipt.json';

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;

  @override
  Future<String> projectRevision() => mapAdapter.resourceRevision(session);

  @override
  Future<bool?> inputsMatch(List<VerificationInputRevision> inputs) async {
    var unconfirmed = false;
    for (final expected in inputs) {
      final observed = await _inputRevision(expected.path);
      if (expected.revision == null || observed.revision == null) {
        unconfirmed = true;
      } else if (expected.revision != observed.revision) {
        return false;
      }
    }
    return unconfirmed ? null : true;
  }

  Future<VerificationInputRevision> _inputRevision(String path) =>
      readVerificationInputRevision(session.directoryPath, path);

  @override
  Future<ProjectManifest> readProject() =>
      mapAdapter.readVerificationProject(session);

  @override
  Future<List<VerificationMapSource>> readMaps(
    List<ProjectMapEntry> entries, {
    void Function(int loaded, int total)? progress,
  }) async {
    final maps = <VerificationMapSource>[];
    for (final (index, entry) in entries.indexed) {
      final inputRevision = await _inputRevision(entry.relativePath);
      List<int> bytes;
      try {
        bytes = await const LocalProjectFileReader().readBytes(
          projectRoot: session.directoryPath,
          relativePath: entry.relativePath,
        );
      } on Object {
        bytes = const [];
      }
      maps.add(
        VerificationMapSource(
          entry: entry,
          bytes: bytes,
          inputRevision: inputRevision,
        ),
      );
      progress?.call(index + 1, entries.length);
    }
    return maps;
  }

  @override
  Future<List<VerificationDialogueSource>> readDialogueSources(
    List<ProjectDialogueEntry> entries,
  ) async {
    final sources = <VerificationDialogueSource>[];
    for (final entry in entries) {
      final inputRevision = await _inputRevision(entry.relativePath);
      try {
        final bytes = await const LocalProjectFileReader().readBytes(
          projectRoot: session.directoryPath,
          relativePath: entry.relativePath,
        );
        sources.add(
          VerificationDialogueSource(
            entry: entry,
            text: utf8.decode(bytes),
            origin: 'version enregistrée',
            revision: narrativeEventBytesFingerprint(bytes),
            inputRevision: inputRevision,
          ),
        );
      } on Object catch (failure) {
        sources.add(
          VerificationDialogueSource(
            entry: entry,
            text: '',
            origin: 'version enregistrée',
            problem: 'Source illisible : $failure',
            inputRevision: inputRevision,
          ),
        );
      }
    }
    return sources;
  }

  @override
  VerificationJob analyse({
    required ProjectManifest project,
    required List<VerificationMapSource> maps,
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
        final readMedia =
            hasPictures && project.settings.dimension == ProjectDimension.twoD;
        final mediaInput = readMedia
            ? await _inputRevision(projectMediaCatalogStorageKey)
            : null;
        final presentationMediaCatalog = readMedia
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
            projectRoot: session.directoryPath,
            catalog: session.storage != ProjectSessionStorage.manifest,
            presentationMediaCatalog: presentationMediaCatalog,
            mediaInput: mediaInput,
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

  @override
  Future<VerificationRuntimeEvidence> readRuntimeEvidence(
    NarrativeRuntimeSmokeProfile? profile,
  ) => readVerificationRuntimeEvidence(
    projectRoot: session.directoryPath,
    profile: profile,
    projectFingerprint: projectFingerprint,
  );

  Future<String> projectFingerprint() =>
      verificationProjectFingerprint(session.directoryPath);
}
