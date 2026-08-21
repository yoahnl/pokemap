import 'dart:async';

import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

import 'presentation_frame_preview.dart';

/// Builds the session a preview run executes. Injected so a widget test drives
/// the real journey without a video decoder or an audio device.
typedef PresentationStudioPreviewSessionFactory =
    PresentationPreviewController Function({
  required ProjectMediaCatalog catalog,
  required Map<String, Uri> mediaUris,
  required bool reducedMotion,
});

/// Scenes that actually play [cinematicId], so an author previews the journey
/// their cinematic belongs to instead of a detached timeline.
List<SceneAsset> scenesPlayingPresentationCinematic(
  ProjectManifest project,
  String cinematicId,
) =>
    <SceneAsset>[
      for (final scene in project.scenes)
        if (scene.graph.nodes.any((node) {
          final payload = node.payload;
          return payload is ScenePresentationCinematicPayload &&
              payload.presentationCinematicId == cinematicId;
        }))
          scene,
    ];

/// Plays the authored journey inside the Studio, through the player's own
/// runner — BETA-CIN-080.
///
/// The preview owns no evaluator, no clock and no renderer of its own: the
/// frames come from the runtime surface controller and the interactions from
/// the player's surface. The sample draft lives here and is never persisted.
class PresentationStudioJourneyPreview extends StatefulWidget {
  const PresentationStudioJourneyPreview({
    super.key,
    required this.asset,
    required this.project,
    required this.projectRootDirectory,
    required this.projectRevision,
    required this.createSession,
    required this.onClose,
    this.loadMedia = loadProjectDirectoryPresentationMedia,
  });

  /// The asset as edited, published or not: a preview must show the draft.
  final PresentationCinematicAsset asset;
  final ProjectManifest project;
  final String projectRootDirectory;
  final String projectRevision;
  final PresentationStudioPreviewSessionFactory createSession;
  final VoidCallback onClose;
  final Future<ProjectDirectoryPresentationMedia?> Function({
    required String projectRootDirectory,
  }) loadMedia;

  @override
  State<PresentationStudioJourneyPreview> createState() =>
      _PresentationStudioJourneyPreviewState();
}

class _PresentationStudioJourneyPreviewState
    extends State<PresentationStudioJourneyPreview> {
  final _nameController = TextEditingController();
  PresentationPreviewController? _session;
  String? _sceneId;
  var _orientation = PresentationFrameOrientation.landscape;
  var _reducedMotion = false;
  String? _mediaFailure;
  var _runs = 0;

  List<SceneAsset> get _scenes =>
      scenesPlayingPresentationCinematic(widget.project, widget.asset.id);

  /// The project the run sees: the manifest with the edited asset substituted,
  /// so unpublished changes are what plays. Nothing is written back.
  ProjectManifest get _previewProject => widget.project.copyWith(
        presentationCinematics: <PresentationCinematicAsset>[
          for (final candidate in widget.project.presentationCinematics)
            if (candidate.id == widget.asset.id) widget.asset else candidate,
          if (widget.project.presentationCinematics
              .every((candidate) => candidate.id != widget.asset.id))
            widget.asset,
        ],
      );

  @override
  void initState() {
    super.initState();
    _sceneId = _scenes.isEmpty ? null : _scenes.first.id;
  }

  @override
  void dispose() {
    unawaited(_session?.close());
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _play() async {
    final sceneId = _sceneId;
    if (sceneId == null) return;
    setState(() => _mediaFailure = null);

    final ProjectDirectoryPresentationMedia? media;
    try {
      media = await widget.loadMedia(
        projectRootDirectory: widget.projectRootDirectory,
      );
    } on Object catch (error) {
      if (!mounted) return;
      setState(() => _mediaFailure = '$error');
      return;
    }
    if (!mounted) return;

    await _session?.close();
    final session = widget.createSession(
      catalog: media?.catalog ?? ProjectMediaCatalog(),
      mediaUris: media?.mediaUris ?? const <String, Uri>{},
      reducedMotion: _reducedMotion,
    );
    session.setOrientation(_orientation);
    session.addListener(_onSessionChanged);
    setState(() {
      _session = session;
      _runs += 1;
    });

    final project = _previewProject;
    final sample = NewGameDraft.start(
      draftId: 'studio-preview',
      projectRevision: widget.projectRevision,
      slotId: 'studio-preview-slot',
      config: project.newGame,
    );
    final seeded = _nameController.text.trim().isEmpty
        ? sample
        : sample
            .apply(
              NewGameDraftCommand.setPlayerName(
                playerName: _nameController.text.trim(),
                expectedRevision: sample.revision,
              ),
            )
            .draft;

    await session.run(
      project: project,
      projectRootDirectory: widget.projectRootDirectory,
      projectRevision: widget.projectRevision,
      sceneId: sceneId,
      sample: seeded,
      runId: 'studio-preview-$_runs',
    );
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _stop() async {
    await _session?.cancel();
    if (mounted) setState(() {});
  }

  Future<void> _closePreview() async {
    final session = _session;
    _session = null;
    session?.removeListener(_onSessionChanged);
    await session?.close();
    widget.onClose();
  }

  void _setOrientation(PresentationFrameOrientation value) {
    setState(() => _orientation = value);
    _session?.setOrientation(value);
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final scenes = _scenes;
    return Column(
      key: const ValueKey('presentation-studio-journey-preview'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildControls(scenes, session),
        if (_mediaFailure case final failure?)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Média du projet illisible : $failure',
              key: const ValueKey('presentation-preview-media-failure'),
            ),
          ),
        if (scenes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Aucune Scene ne joue cette cinématique : liez un nœud '
              'Presentation pour prévisualiser le parcours.',
              key: ValueKey('presentation-preview-no-scene'),
            ),
          ),
        if (session != null) Expanded(child: _buildStage(session)),
      ],
    );
  }

  Widget _buildControls(
    List<SceneAsset> scenes,
    PresentationPreviewController? session,
  ) =>
      Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          if (scenes.length > 1)
            DropdownButton<String>(
              key: const ValueKey('presentation-preview-scene'),
              value: _sceneId,
              items: <DropdownMenuItem<String>>[
                for (final scene in scenes)
                  DropdownMenuItem<String>(
                    value: scene.id,
                    child: Text(scene.name),
                  ),
              ],
              onChanged: (value) => setState(() => _sceneId = value),
            ),
          SizedBox(
            width: 200,
            child: TextField(
              key: const ValueKey('presentation-preview-sample-name'),
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom d’échantillon',
                helperText: 'Jamais enregistré dans le projet',
              ),
            ),
          ),
          SegmentedButton<PresentationFrameOrientation>(
            key: const ValueKey('presentation-preview-orientation'),
            segments: const <ButtonSegment<PresentationFrameOrientation>>[
              ButtonSegment<PresentationFrameOrientation>(
                value: PresentationFrameOrientation.landscape,
                label: Text('16:9'),
              ),
              ButtonSegment<PresentationFrameOrientation>(
                value: PresentationFrameOrientation.portrait,
                label: Text('9:16'),
              ),
            ],
            selected: <PresentationFrameOrientation>{_orientation},
            onSelectionChanged: (value) => _setOrientation(value.first),
          ),
          FilterChip(
            key: const ValueKey('presentation-preview-reduced-motion'),
            label: const Text('Mouvement réduit'),
            selected: _reducedMotion,
            onSelected: (value) => setState(() => _reducedMotion = value),
          ),
          FilledButton(
            key: const ValueKey('presentation-preview-play'),
            onPressed: scenes.isEmpty || (session?.isRunning ?? false)
                ? null
                : () => unawaited(_play()),
            child: const Text('Jouer le parcours'),
          ),
          OutlinedButton(
            key: const ValueKey('presentation-preview-stop'),
            onPressed:
                (session?.isRunning ?? false) ? () => unawaited(_stop()) : null,
            child: const Text('Arrêter'),
          ),
          TextButton(
            key: const ValueKey('presentation-preview-close'),
            onPressed: () => unawaited(_closePreview()),
            child: const Text('Fermer la preview'),
          ),
        ],
      );

  Widget _buildStage(PresentationPreviewController session) {
    final request = session.pendingRequest;
    // The author must see the journey in the player's own theme, dialogue
    // shell included: the interaction surface reads the player palette from
    // its context and cannot be mounted under the Editor theme.
    return Theme(
      data: PokeMapPlayerTheme.dark(),
      child: _buildStageBody(session, request),
    );
  }

  Widget _buildStageBody(
    PresentationPreviewController session,
    SceneInteractionRequest? request,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        ValueListenableBuilder<RuntimePresentationFrameSnapshot?>(
          valueListenable: session.frames,
          builder: (context, snapshot, _) => snapshot == null
              ? _buildStatus(session)
              : PresentationFramePreview(
                  key: const ValueKey('presentation-preview-frame'),
                  frame: snapshot.frame,
                  orientation: snapshot.orientation,
                  contentPort: session.contentPort,
                  playerTheme: PokeMapPlayerTheme.dark(),
                  reduceMotion: snapshot.reduceMotion,
                  reduceFlashes: snapshot.reduceFlashes,
                  showCaptions: snapshot.showCaptions,
                  orientationOverrides: snapshot.orientationOverrides,
                ),
        ),
        if (request != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: PlayerSceneInteractionSurface(
              key: const ValueKey('presentation-preview-interaction'),
              request: request,
              onResult: session.resolve,
            ),
          ),
      ],
    );
  }

  Widget _buildStatus(PresentationPreviewController session) => Center(
        child: Text(
          switch (session.status) {
            PresentationPreviewStatus.idle => 'Preview prête.',
            PresentationPreviewStatus.running => 'Lecture du parcours…',
            PresentationPreviewStatus.completed =>
              'Parcours terminé — nom retenu : '
                  '${session.resultDraft?.playerName ?? '-'}',
            PresentationPreviewStatus.cancelled => 'Preview arrêtée.',
            PresentationPreviewStatus.failed =>
              'Parcours interrompu : ${session.failure}',
          },
          key: const ValueKey('presentation-preview-status'),
        ),
      );
}
