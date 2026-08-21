import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_journey_preview.dart';
import 'package:map_player_ui/map_player_ui.dart';

/// The Studio preview surface — BETA-CIN-080.
///
/// These tests own one claim: the Studio renders whatever the shared preview
/// controller publishes, through the PLAYER's interaction surface, and forwards
/// the author's answers and controls back untouched. The journey semantics —
/// interpolation, the negative branch, the real resume, frame parity with the
/// installed runtime — are proven headlessly in map_player_ui, because a real
/// playback controller cannot run inside the fake-async clock of testWidgets.
void main() {
  const revision = 'sha256:bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'
      'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

  final sessions = <_ScriptedPreview>[];
  var reducedMotionSeen = <bool>[];

  PresentationPreviewController factory({
    required ProjectMediaCatalog catalog,
    required Map<String, Uri> mediaUris,
    required bool reducedMotion,
  }) {
    reducedMotionSeen.add(reducedMotion);
    final session = _ScriptedPreview();
    sessions.add(session);
    return session;
  }

  tearDown(() async {
    for (final session in sessions) {
      await session.close();
    }
    sessions.clear();
    reducedMotionSeen = <bool>[];
  });

  Future<void> pumpPreview(
    WidgetTester tester, {
    required ProjectManifest project,
    PresentationCinematicAsset? asset,
    VoidCallback? onClose,
    Future<ProjectDirectoryPresentationMedia?> Function({
      required String projectRootDirectory,
    })? loadMedia,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PresentationStudioJourneyPreview(
            asset: asset ?? project.presentationCinematics.single,
            project: project,
            projectRootDirectory: '/tmp/cin080-studio',
            projectRevision: revision,
            createSession: factory,
            onClose: onClose ?? () {},
            loadMedia:
                loadMedia ?? ({required projectRootDirectory}) async => null,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> settle(WidgetTester tester) async {
    for (var attempt = 0; attempt < 6; attempt += 1) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  Future<void> play(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const ValueKey<String>('presentation-preview-play')),
    );
    await settle(tester);
  }

  testWidgets('the author answers through the player interaction surface',
      (tester) async {
    await pumpPreview(tester, project: _manifest());
    await play(tester);
    final session = sessions.single;

    session.publish(_textRequest());
    await settle(tester);
    final field = find.byKey(
      const ValueKey<String>('scene-interaction-text-field'),
    );
    expect(
      field,
      findsOneWidget,
      reason: 'the Studio mounts the player surface, not a Studio replica',
    );
    await tester.enterText(field, 'Camille');
    await tester.tap(
      find.byKey(const ValueKey<String>('scene-interaction-text-submit')),
    );
    await settle(tester);

    expect(session.results, hasLength(1));
    expect(
      (session.results.single as SceneTextSubmittedInteractionResult).value,
      'Camille',
      reason: 'the answer reaches the controller verbatim',
    );

    session.publish(_confirmationRequest('On garde Camille ?'));
    await settle(tester);
    expect(find.textContaining('On garde Camille ?'), findsWidgets);
    await tester.tap(
      find.byKey(const ValueKey<String>('scene-interaction-confirm-no')),
    );
    await settle(tester);

    expect(session.results, hasLength(2));
    expect(
      (session.results.last as SceneConfirmedInteractionResult).value,
      isFalse,
    );

    session.complete(playerName: 'Camille B');
    await settle(tester);
    expect(find.textContaining('Camille B'), findsWidgets);
  });

  testWidgets('the sample name seeds the run and never reaches the project',
      (tester) async {
    final project = _manifest();
    final before = project.toJson();
    await pumpPreview(tester, project: project);

    await tester.enterText(
      find.byKey(const ValueKey<String>('presentation-preview-sample-name')),
      'Échantillon',
    );
    await play(tester);

    expect(sessions.single.samples.single.playerName, 'Échantillon');
    expect(
      sessions.single.projects.single.presentationCinematics.single.id,
      'opening',
      reason: 'the run sees the edited asset, published or not',
    );
    expect(
      project.toJson(),
      before,
      reason: 'a preview never writes a sample value into the project',
    );
  });

  testWidgets('the run plays the edited asset, not the published one',
      (tester) async {
    final project = _manifest();
    final published = project.presentationCinematics.single;
    // An unpublished edit: a new title and one more interaction cue.
    final edited = PresentationCinematicAsset(
      id: published.id,
      title: 'Ouverture retravaillée',
      durationUs: published.durationUs,
      tracks: <PresentationTrack>[
        PresentationTrack(
          id: 'markers',
          label: 'Repères',
          kind: PresentationTrackKind.marker,
          clips: <PresentationClip>[
            ...published.tracks.single.clips,
            PresentationMarkerClip(
              id: 'cue_confirm',
              startUs: 600000,
              label: 'Confirmer le nom',
              markerKind: PresentationMarkerKind.interactionCue,
            ),
          ],
        ),
      ],
    );

    await pumpPreview(tester, project: project, asset: edited);
    await play(tester);

    final played = sessions.single.projects.single.presentationCinematics
        .singleWhere((candidate) => candidate.id == 'opening');
    expect(
      played.title,
      'Ouverture retravaillée',
      reason: 'the preview plays the draft, so an author sees the edit they '
          'just made without publishing it first',
    );
    expect(
      played.tracks
          .expand((track) => track.clips)
          .map((clip) => clip.id),
      contains('cue_confirm'),
    );
    expect(
      project.presentationCinematics.single.title,
      'Ouverture',
      reason: 'and the published project is left exactly as it was',
    );
  });

  testWidgets('reduced motion and 9:16 drive the shared controller',
      (tester) async {
    await pumpPreview(tester, project: _manifest());
    await tester.tap(
      find.byKey(const ValueKey<String>('presentation-preview-reduced-motion')),
    );
    await settle(tester);
    await play(tester);

    expect(reducedMotionSeen, <bool>[true]);
    expect(
      sessions.single.orientations,
      <PresentationFrameOrientation>[PresentationFrameOrientation.landscape],
    );

    await tester.tap(find.text('9:16'));
    await settle(tester);

    expect(
      sessions.single.orientations.last,
      PresentationFrameOrientation.portrait,
      reason: 'the comparison re-orients the running journey instead of '
          'laying it out a second way in the Editor',
    );
  });

  testWidgets('stopping abandons the run and says so', (tester) async {
    await pumpPreview(tester, project: _manifest());
    await play(tester);
    final session = sessions.single;

    await tester.tap(
      find.byKey(const ValueKey<String>('presentation-preview-stop')),
    );
    await settle(tester);

    expect(session.cancelCount, 1);
    expect(find.text('Preview arrêtée.'), findsOneWidget);
  });

  testWidgets('closing the preview releases the session', (tester) async {
    var closed = false;
    await pumpPreview(
      tester,
      project: _manifest(),
      onClose: () => closed = true,
    );
    await play(tester);
    final session = sessions.single;

    await tester.tap(
      find.byKey(const ValueKey<String>('presentation-preview-close')),
    );
    await settle(tester);

    expect(closed, isTrue);
    expect(
      session.closeCount,
      greaterThanOrEqualTo(1),
      reason: 'no timer, decoder, audio handle or overlay may outlive the '
          'closed preview',
    );
  });

  testWidgets('disposing the Studio route releases the session too',
      (tester) async {
    await pumpPreview(tester, project: _manifest());
    await play(tester);
    final session = sessions.single;

    await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
    await settle(tester);

    expect(
      session.closeCount,
      greaterThanOrEqualTo(1),
      reason: 'a route change or a project reload must not leave a journey '
          'running behind the Studio',
    );
  });

  testWidgets('an unbound cinematic says so instead of offering a dead preview',
      (tester) async {
    await pumpPreview(tester, project: _manifest(bindScene: false));

    expect(
      find.byKey(const ValueKey<String>('presentation-preview-no-scene')),
      findsOneWidget,
    );
    final playButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey<String>('presentation-preview-play')),
    );
    expect(playButton.onPressed, isNull);
  });

  testWidgets('unreadable project media is reported, not swallowed',
      (tester) async {
    await pumpPreview(
      tester,
      project: _manifest(),
      loadMedia: ({required projectRootDirectory}) async =>
          throw const ProjectDirectoryPresentationMediaException(
        'The project asset catalog is invalid.',
      ),
    );

    await play(tester);

    expect(
      find.byKey(const ValueKey<String>('presentation-preview-media-failure')),
      findsOneWidget,
    );
    expect(sessions, isEmpty, reason: 'no session is opened on a dead media');
  });

  test('only the scenes that play the cinematic are offered', () {
    final project = _manifest();
    expect(
      scenesPlayingPresentationCinematic(project, 'opening')
          .map((scene) => scene.id),
      <String>['scene_intro'],
    );
    expect(scenesPlayingPresentationCinematic(project, 'absent'), isEmpty);
  });
}

SceneInteractionRequest _textRequest() => SceneInteractionRequest.text(
      requestId: 'ask_name',
      revision: 1,
      prompt: SceneInteractionPrompt(
        localizationKey: 'newGame.name',
        fallbackText: 'Ton nom ?',
      ),
    );

SceneInteractionRequest _confirmationRequest(String prompt) =>
    SceneInteractionRequest.confirmation(
      requestId: 'confirm_name',
      revision: 1,
      prompt: SceneInteractionPrompt(
        localizationKey: 'newGame.confirm',
        fallbackText: prompt,
      ),
    );

/// A preview controller the test scripts. It publishes requests and records
/// what the Studio sends back, so this suite measures the surface and nothing
/// else.
final class _ScriptedPreview extends ChangeNotifier
    implements PresentationPreviewController {
  final ValueNotifier<RuntimePresentationFrameSnapshot?> _frames =
      ValueNotifier<RuntimePresentationFrameSnapshot?>(null);
  final results = <SceneInteractionResult>[];
  final samples = <NewGameDraft>[];
  final projects = <ProjectManifest>[];
  final orientations = <PresentationFrameOrientation>[];
  var cancelCount = 0;
  var closeCount = 0;

  var _status = PresentationPreviewStatus.idle;
  SceneInteractionRequest? _pending;
  NewGameDraft? _draft;

  void publish(SceneInteractionRequest request) {
    _pending = request;
    notifyListeners();
  }

  void complete({required String playerName}) {
    _pending = null;
    _status = PresentationPreviewStatus.completed;
    _draft = samples.isEmpty
        ? null
        : samples.last
            .apply(
              NewGameDraftCommand.setPlayerName(
                playerName: playerName,
                expectedRevision: samples.last.revision,
              ),
            )
            .draft;
    notifyListeners();
  }

  @override
  PresentationPreviewStatus get status => _status;

  @override
  SceneInteractionRequest? get pendingRequest => _pending;

  @override
  NewGameDraft? get resultDraft => _draft;

  @override
  Object? get failure => null;

  @override
  bool get isRunning => _status == PresentationPreviewStatus.running;

  @override
  ValueListenable<RuntimePresentationFrameSnapshot?> get frames => _frames;

  @override
  PresentationFrameContentPort get contentPort => const _InertContentPort();

  @override
  PresentationFrameOrientation get orientation => orientations.isEmpty
      ? PresentationFrameOrientation.landscape
      : orientations.last;

  @override
  void setOrientation(PresentationFrameOrientation value) {
    orientations.add(value);
    notifyListeners();
  }

  @override
  Future<void> run({
    required ProjectManifest project,
    required String projectRootDirectory,
    required String projectRevision,
    required String sceneId,
    required NewGameDraft sample,
    required String runId,
  }) async {
    projects.add(project);
    samples.add(sample);
    _status = PresentationPreviewStatus.running;
    notifyListeners();
  }

  @override
  SceneInteractionResolution resolve(SceneInteractionResult result) {
    results.add(result);
    _pending = null;
    notifyListeners();
    return SceneInteractionResolution(
      status: SceneInteractionResolutionStatus.accepted,
    );
  }

  @override
  Future<void> cancel() async {
    cancelCount += 1;
    _pending = null;
    _status = PresentationPreviewStatus.cancelled;
    notifyListeners();
  }

  @override
  Future<void> close() async {
    closeCount += 1;
    _status = PresentationPreviewStatus.cancelled;
  }
}

final class _InertContentPort implements PresentationFrameContentPort {
  const _InertContentPort();

  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) =>
      const PresentationVisualUnavailable(
        reason: PresentationContentUnavailableReason.missing,
        message: 'unused',
      );

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) =>
      const PresentationCaptionUnavailable(
        reason: PresentationContentUnavailableReason.missing,
        message: 'unused',
      );
}

ProjectManifest _manifest({bool bindScene = true}) => ProjectManifest(
      name: 'CIN-080 studio',
      version: ProjectVersion.v7,
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      presentationCinematics: <PresentationCinematicAsset>[
        PresentationCinematicAsset(
          id: 'opening',
          title: 'Ouverture',
          durationUs: 1000000,
          tracks: <PresentationTrack>[
            PresentationTrack(
              id: 'markers',
              label: 'Repères',
              kind: PresentationTrackKind.marker,
              clips: <PresentationClip>[
                PresentationMarkerClip(
                  id: 'cue_name',
                  startUs: 200000,
                  label: 'Demander le nom',
                  markerKind: PresentationMarkerKind.interactionCue,
                ),
              ],
            ),
          ],
        ),
      ],
      scenes: <SceneAsset>[if (bindScene) _scene()],
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'start_map',
        preSessionSceneId: 'scene_intro',
      ),
    );

SceneAsset _scene() => SceneAsset(
      id: 'scene_intro',
      name: 'Pré-session',
      executionProfile: SceneExecutionProfile.preSession,
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: <SceneNode>[
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'presentation',
            kind: SceneNodeKind.presentationCinematic,
            payload: ScenePresentationCinematicPayload(
              presentationCinematicId: 'opening',
              interactionCueBindings: [
                ScenePresentationInteractionCueBinding(
                  markerId: 'cue_name',
                  awaitableNodeId: 'ask_name',
                ),
              ],
            ),
          ),
          SceneNode(
            id: 'ask_name',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.preSessionInteraction(
              ScenePreSessionInteractionSpec.text(
                prompt: SceneInteractionPrompt(
                  localizationKey: 'newGame.name',
                  fallbackText: 'Ton nom ?',
                ),
                resultBinding: const ScenePreSessionResultBinding(
                  field: ScenePreSessionDraftField.playerName,
                ),
              ),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: <SceneEdge>[
          SceneEdge(
            id: 'start_presentation',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'presentation',
            kind: SceneEdgeKind.defaultFlow,
          ),
          SceneEdge(
            id: 'presentation_end',
            fromNodeId: 'presentation',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.presentationCompleted,
          ),
        ],
      ),
    );
