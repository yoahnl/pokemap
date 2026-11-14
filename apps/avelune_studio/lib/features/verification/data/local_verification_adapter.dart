import 'dart:async';
import 'dart:isolate';

import 'package:map_authoring/map_authoring_local.dart'
    show LocalProjectFileReader;
import 'package:map_core/map_core_domain.dart';

import '../../map_workspace/data/local_map_workspace_adapter.dart';
import '../../narrative/data/local_narrative_adapter.dart';
import '../../project_session/domain/project_session.dart';
import '../../presentations/data/local_presentation_adapter.dart';
import '../domain/verification_port.dart';
import 'verification_analysis_worker.dart';
import 'verification_runtime_evidence.dart';

class LocalVerificationAdapter implements VerificationPort {
  LocalVerificationAdapter({required this.session, required this.mapAdapter});

  static const receiptPath =
      '.pokemap/validation/narrative_runtime_smoke_receipt.json';

  final ProjectSession session;
  final LocalMapWorkspaceAdapter mapAdapter;

  @override
  Future<String> projectRevision() async =>
      (await mapAdapter.resourceBaseline(session)).revision;

  @override
  Future<List<VerificationMapSource>> readMaps({
    void Function(int loaded, int total)? progress,
  }) async {
    final entries = (await mapAdapter.resourceBaseline(session)).manifest.maps;
    final maps = <VerificationMapSource>[];
    for (final (index, entry) in entries.indexed) {
      maps.add(
        VerificationMapSource(
          entry: entry,
          bytes: await const LocalProjectFileReader().readBytes(
            projectRoot: session.directoryPath,
            relativePath: entry.relativePath,
          ),
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
            projectRoot: session.directoryPath,
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
