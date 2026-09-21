import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:map_player_ui/presentation_renderer.dart';
import 'package:map_player_ui/player_surfaces.dart';
import 'package:map_runtime/map_runtime.dart'
    show RuntimePresentationFrameDeltas;
import '../../presentation/features/presentations/presentation_scenario_preview.dart';

class StudioPresentationScenarioPreview implements PresentationScenarioPreview {
  StudioPresentationScenarioPreview({
    required this.projectRoot,
    required this.revision,
    required this.project,
    required this.sceneId,
    required ProjectMediaCatalog catalog,
    required Map<String, Uri> mediaUris,
    required bool portrait,
    bool reducedMotion = false,
    RuntimePresentationFrameDeltas? frameDeltas,
  }) : session = PresentationPreviewSession(
         runtimeSourceId: 'avelune-presentation-preview',
         catalog: catalog,
         mediaUris: mediaUris,
         targetPlatform: PresentationMediaTargetPlatform.macos,
         reducedMotion: reducedMotion,
         frameDeltas: frameDeltas,
       ) {
    session.setOrientation(
      portrait
          ? PresentationFrameOrientation.portrait
          : PresentationFrameOrientation.landscape,
    );
  }
  final String projectRoot, revision, sceneId;
  final ProjectManifest project;
  final PresentationPreviewSession session;
  int _runs = 0;
  bool _closed = false;
  @override
  bool get running => session.isRunning;
  @override
  bool get waitingForInteraction => session.pendingRequest != null;
  @override
  Object? get failure => session.failure;
  @override
  NewGameDraft? get result => session.resultDraft;
  @override
  String get statusLabel => waitingForInteraction
      ? 'En attente de votre réponse'
      : switch (session.status) {
          PresentationPreviewStatus.idle => 'Prêt pour le test isolé',
          PresentationPreviewStatus.running => 'Lecture de la scène',
          PresentationPreviewStatus.completed => 'Scène terminée',
          PresentationPreviewStatus.cancelled => 'Test arrêté',
          PresentationPreviewStatus.failed =>
            'Lecture impossible : ${session.failure}',
        };
  @override
  void addListener(VoidCallback listener) => session.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      session.removeListener(listener);
  @override
  Future<void> run({String? playerName}) async {
    if (_closed) return;
    var sample = NewGameDraft.start(
      draftId: 'avelune-preview',
      projectRevision: revision,
      slotId: 'avelune-preview-slot',
      config: project.newGame,
    );
    if (playerName != null && playerName.trim().isNotEmpty) {
      sample = sample
          .apply(
            NewGameDraftCommand.setPlayerName(
              playerName: playerName.trim(),
              expectedRevision: sample.revision,
            ),
          )
          .draft;
    }
    await session.run(
      project: project,
      projectRootDirectory: projectRoot,
      projectRevision: revision,
      sceneId: sceneId,
      sample: sample,
      runId: 'avelune-preview-${++_runs}',
    );
  }

  @override
  Future<void> stop() => session.cancel();
  @override
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await session.close();
  }

  @override
  Widget surface() => Theme(
    data: PokeMapPlayerTheme.dark(),
    child: AnimatedBuilder(
      animation: session,
      builder: (context, _) => Stack(
        fit: StackFit.expand,
        children: [
          ValueListenableBuilder<RuntimePresentationFrameSnapshot?>(
            valueListenable: session.frames,
            builder: (context, snapshot, _) => snapshot == null
                ? Center(child: Text(statusLabel))
                : RuntimePresentationFrameSurface(
                    snapshot: snapshot,
                    contentPort: session.contentPort,
                  ),
          ),
          if (session.pendingRequest case final request?)
            Align(
              alignment: Alignment.bottomCenter,
              child: PlayerSceneInteractionSurface(
                request: request,
                onResult: session.resolve,
              ),
            ),
        ],
      ),
    ),
  );
}
