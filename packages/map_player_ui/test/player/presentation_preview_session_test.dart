import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/presentation_renderer.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

/// The Studio preview runs the player's own journey — BETA-CIN-080.
///
/// The risk this ticket names is a fake Editor player that drifts from the
/// installed runtime, so the first test drives the SAME fixture twice — once
/// through the preview session, once through the composition the player
/// coordinator builds by hand — and demands identical frames and outcomes.
void main() {
  const vtt = '''
WEBVTT

00:00.000 --> 00:03.000
Le train entre en gare.
''';
  const revision = 'sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa'
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  late Directory root;
  late ProjectMediaCatalog catalog;
  late Map<String, Uri> mediaUris;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('cin080_preview_');
    final captions = File(p.join(root.path, 'captions.vtt'));
    await captions.writeAsString(vtt);
    catalog = ProjectMediaCatalog(
      entries: <ProjectMediaAsset>[
        ProjectMediaAsset(
          id: 'media_captions',
          label: 'Sous-titres',
          kind: ProjectMediaKind.captions,
          sourceAssetId: 'asset_captions',
        ),
      ],
    );
    mediaUris = <String, Uri>{'media_captions': captions.uri};
  });

  tearDown(() async {
    if (root.existsSync()) await root.delete(recursive: true);
  });

  /// Fixed deltas so both runs advance the shared clock identically: the
  /// parity claim is about the journey, not about wall-clock luck.
  Stream<int> deltas(Object _) =>
      Stream<int>.fromIterable(List<int>.filled(24, 150000));

  NewGameDraft sample({String slotId = 'slot_1'}) => NewGameDraft.start(
        draftId: 'preview-draft',
        projectRevision: revision,
        slotId: slotId,
        config: _manifest().newGame,
      );

  test(
    'preview and runtime produce the same frames and the same outcome',
    () async {
      final previewRun = await _runThroughPreview(
        catalog: catalog,
        mediaUris: mediaUris,
        projectRootDirectory: root.path,
        revision: revision,
        frameDeltas: deltas,
        sample: sample(),
      );
      final runtimeRun = await _runThroughRuntimeComposition(
        catalog: catalog,
        mediaUris: mediaUris,
        projectRootDirectory: root.path,
        revision: revision,
        frameDeltas: deltas,
        sample: sample(),
      );

      expect(
        previewRun.frames,
        runtimeRun.frames,
        reason: 'the same asset, context, revision and timestamps must render '
            'the same frames — the preview owns no timing engine of its own',
      );
      expect(previewRun.assetRevisions, runtimeRun.assetRevisions);
      expect(
        previewRun.snapshotDigests,
        runtimeRun.snapshotDigests,
        reason: 'every value the renderer receives must match, not only the '
            'frame: reduced motion, flashes, captions, orientation and media '
            'bindings included',
      );
      expect(previewRun.requestKinds, runtimeRun.requestKinds);
      expect(previewRun.prompts, runtimeRun.prompts);
      expect(previewRun.draftName, runtimeRun.draftName);
      expect(previewRun.frames, isNotEmpty);
    },
  );

  test(
    'the previewer executes input, interpolation, the negative branch and '
    'a real resume',
    () async {
      final run = await _runThroughPreview(
        catalog: catalog,
        mediaUris: mediaUris,
        projectRootDirectory: root.path,
        revision: revision,
        frameDeltas: deltas,
        sample: sample(),
      );

      expect(
        run.requestKinds,
        const <String>[
          'text',
          'confirmation',
          'text',
          'confirmation',
          'choice',
        ],
        reason: 'the refused confirmation replays the name entry from its own '
            'marker: the negative branch and the resume are executed, not '
            'simulated',
      );
      expect(
        run.prompts[1],
        contains('Zoé'),
        reason: 'the confirmation prompt interpolates the draft the author '
            'just typed',
      );
      expect(
        run.prompts[3],
        contains('Zoé Corrigée'),
        reason: 'the replayed entry re-interpolates the corrected value',
      );
      expect(run.draftName, 'Zoé Corrigée');
    },
  );

  test('a changed sample value re-evaluates without touching the project',
      () async {
    final manifestBefore = _manifest().toJson();
    final session = PresentationPreviewSession(
      runtimeSourceId: 'studio-preview',
      catalog: catalog,
      mediaUris: mediaUris,
      targetPlatform: PresentationMediaTargetPlatform.macos,
      audioMixer: RuntimeAudioMixer(),
      reducedMotion: true,
      videoDriver: _UnusedVideoDriver(),
      frameDeltas: deltas,
    );
    addTearDown(session.close);

    final first = await _answer(
      session,
      names: <String>['Alma', 'Alma'],
      answers: <bool>[false, true],
      projectRootDirectory: root.path,
      revision: revision,
      sample: sample(),
    );
    final second = await _answer(
      session,
      names: <String>['Bruno', 'Bruno'],
      answers: <bool>[false, true],
      projectRootDirectory: root.path,
      revision: revision,
      sample: sample(slotId: 'slot_2'),
    );

    expect(first.draftName, 'Alma');
    expect(second.draftName, 'Bruno');
    expect(
      _manifest().toJson(),
      manifestBefore,
      reason: 'a preview never writes into the project or a save',
    );
  });

  test('cancelling mid-interaction abandons the run and refuses a late answer',
      () async {
    final session = PresentationPreviewSession(
      runtimeSourceId: 'studio-preview',
      catalog: catalog,
      mediaUris: mediaUris,
      targetPlatform: PresentationMediaTargetPlatform.macos,
      audioMixer: RuntimeAudioMixer(),
      reducedMotion: true,
      videoDriver: _UnusedVideoDriver(),
      frameDeltas: deltas,
    );
    addTearDown(session.close);

    SceneInteractionRequest? seen;
    session.addListener(() {
      seen ??= session.pendingRequest;
    });
    final running = session.run(
      project: _manifest(),
      projectRootDirectory: root.path,
      projectRevision: revision,
      sceneId: 'scene_intro',
      sample: sample(),
      runId: 'cancelled-run',
    );
    await _pumpUntil(() => seen != null);
    final pending = seen!;

    await session.cancel();
    expect(session.status, PresentationPreviewStatus.cancelled);
    expect(session.pendingRequest, isNull);

    final late = session.resolve(
      SceneInteractionResult.textSubmitted(
        requestId: pending.requestId,
        revision: pending.revision,
        value: 'Trop tard',
      ),
    );
    expect(
      late.status,
      SceneInteractionResolutionStatus.unknownRequest,
      reason: 'a callback arriving after the cancel must not reach the runner',
    );
    expect(session.resultDraft, isNull);
    expect(
      session.frames.value,
      isNull,
      reason: 'cancelling stops the presentation player itself, it does not '
          'merely stop listening to it',
    );
    final framesAfterCancel = <Object>[];
    void record() {
      final snapshot = session.frames.value;
      if (snapshot != null) framesAfterCancel.add(snapshot);
    }

    session.frames.addListener(record);
    addTearDown(() => session.frames.removeListener(record));
    await running;
    expect(session.status, PresentationPreviewStatus.cancelled);
    expect(
      framesAfterCancel,
      isEmpty,
      reason: 'no frame may reach the author after the preview was cancelled',
    );
  });

  test('a superseded run can no longer publish its own ending', () async {
    final session = PresentationPreviewSession(
      runtimeSourceId: 'studio-preview',
      catalog: catalog,
      mediaUris: mediaUris,
      targetPlatform: PresentationMediaTargetPlatform.macos,
      audioMixer: RuntimeAudioMixer(),
      reducedMotion: true,
      videoDriver: _UnusedVideoDriver(),
      frameDeltas: deltas,
    );
    addTearDown(session.close);

    var seenFirst = false;
    void watch() {
      if (session.pendingRequest != null) seenFirst = true;
    }

    session.addListener(watch);
    final superseded = session.run(
      project: _manifest(),
      projectRootDirectory: root.path,
      projectRevision: revision,
      sceneId: 'scene_intro',
      sample: sample(),
      runId: 'superseded-run',
    );
    await _pumpUntil(() => seenFirst);
    session.removeListener(watch);

    // A route change or a project reload starts a new run over the old one.
    // This drive accepts the first confirmation, so the replacement journey
    // ends on its own and cannot be confused with a replay.
    final answered = <String>{};
    void drive() {
      final request = session.pendingRequest;
      if (request == null) return;
      if (!answered.add('${request.requestId}:${request.revision}')) return;
      scheduleMicrotask(() {
        session.resolve(switch (request.kind) {
          SceneInteractionRequestKind.text =>
            SceneInteractionResult.textSubmitted(
              requestId: request.requestId,
              revision: request.revision,
              value: 'Nouvelle',
            ),
          SceneInteractionRequestKind.confirmation =>
            SceneInteractionResult.confirmed(
              requestId: request.requestId,
              revision: request.revision,
              value: true,
            ),
          SceneInteractionRequestKind.choice =>
            SceneInteractionResult.choiceSelected(
              requestId: request.requestId,
              revision: request.revision,
              selectedOptionId: 'vif',
            ),
          _ => SceneInteractionResult.acknowledged(
              requestId: request.requestId,
              revision: request.revision,
            ),
        });
      });
    }

    session.addListener(drive);
    addTearDown(() => session.removeListener(drive));
    final replacement = session.run(
      project: _manifest(),
      projectRootDirectory: root.path,
      projectRevision: revision,
      sceneId: 'scene_intro',
      sample: sample(slotId: 'slot_3'),
      runId: 'replacement-run',
    );
    await superseded;
    await replacement;

    expect(
      session.status,
      PresentationPreviewStatus.completed,
      reason: 'the superseded run must not overwrite the live one, whether it '
          'ended well or badly',
    );
    expect(session.failure, isNull);
    expect(session.resultDraft?.playerName, 'Nouvelle');
  });

  test('closing the preview leaves no frame and no live audio channel',
      () async {
    final mixer = RuntimeAudioMixer();
    final session = PresentationPreviewSession(
      runtimeSourceId: 'studio-preview',
      catalog: catalog,
      mediaUris: mediaUris,
      targetPlatform: PresentationMediaTargetPlatform.macos,
      audioMixer: mixer,
      reducedMotion: true,
      videoDriver: _UnusedVideoDriver(),
      frameDeltas: deltas,
    );

    final run = await _answer(
      session,
      names: <String>['Iris', 'Iris'],
      answers: <bool>[false, true],
      projectRootDirectory: root.path,
      revision: revision,
      sample: sample(),
    );
    expect(
      run.frames,
      isNotEmpty,
      reason: 'the journey really rendered before it was closed',
    );
    expect(
      session.frames.value,
      isNull,
      reason: 'the terminal release of BETA-CIN-076 already detached the '
          'frame when the journey completed',
    );

    await session.close();

    expect(session.frames.value, isNull);
    expect(session.pendingRequest, isNull);
    expect(
      () => session.run(
        project: _manifest(),
        projectRootDirectory: root.path,
        projectRevision: revision,
        sceneId: 'scene_intro',
        sample: sample(),
        runId: 'after-close',
      ),
      throwsStateError,
    );
  });
}

final class _PreviewRun {
  _PreviewRun({
    required this.frames,
    required this.assetRevisions,
    required this.snapshotDigests,
    required this.requestKinds,
    required this.prompts,
    required this.draftName,
  });

  final List<PresentationFrame> frames;
  final List<String> assetRevisions;
  final List<String> snapshotDigests;
  final List<String> requestKinds;
  final List<String> prompts;
  final String draftName;
}

/// Answers a journey through the preview session, recording what the author
/// would have seen.
Future<_PreviewRun> _answer(
  PresentationPreviewSession session, {
  required List<String> names,
  required List<bool> answers,
  required String projectRootDirectory,
  required String revision,
  required NewGameDraft sample,
}) async {
  final frames = <PresentationFrame>[];
  final assetRevisions = <String>[];
  final snapshotDigests = <String>[];
  final requestKinds = <String>[];
  final prompts = <String>[];
  var nameIndex = 0;
  var answerIndex = 0;
  final answered = <String>{};

  void onFrame() {
    final snapshot = session.frames.value;
    if (snapshot == null) return;
    frames.add(snapshot.frame);
    assetRevisions.add(snapshot.assetRevision);
    snapshotDigests.add(_snapshotDigest(snapshot));
  }

  void onChange() {
    final request = session.pendingRequest;
    if (request == null) return;
    final key = '${request.requestId}:${request.revision}';
    if (!answered.add(key)) return;
    requestKinds.add(request.kind.name);
    prompts.add(request.prompt.fallbackText ?? '');
    scheduleMicrotask(() {
      session.resolve(switch (request.kind) {
        SceneInteractionRequestKind.text =>
          SceneInteractionResult.textSubmitted(
            requestId: request.requestId,
            revision: request.revision,
            value: names[nameIndex++],
          ),
        SceneInteractionRequestKind.confirmation =>
          SceneInteractionResult.confirmed(
            requestId: request.requestId,
            revision: request.revision,
            value: answers[answerIndex++],
          ),
        SceneInteractionRequestKind.choice =>
          SceneInteractionResult.choiceSelected(
            requestId: request.requestId,
            revision: request.revision,
            selectedOptionId: 'vif',
          ),
        _ => SceneInteractionResult.acknowledged(
            requestId: request.requestId,
            revision: request.revision,
          ),
      });
    });
  }

  session.frames.addListener(onFrame);
  session.addListener(onChange);
  try {
    await session.run(
      project: _manifest(),
      projectRootDirectory: projectRootDirectory,
      projectRevision: revision,
      sceneId: 'scene_intro',
      sample: sample,
      runId: 'preview-run',
    );
  } finally {
    session.frames.removeListener(onFrame);
    session.removeListener(onChange);
  }
  return _PreviewRun(
    frames: frames,
    assetRevisions: assetRevisions,
    snapshotDigests: snapshotDigests,
    requestKinds: requestKinds,
    prompts: prompts,
    draftName: session.resultDraft?.playerName ?? '',
  );
}

Future<_PreviewRun> _runThroughPreview({
  required ProjectMediaCatalog catalog,
  required Map<String, Uri> mediaUris,
  required String projectRootDirectory,
  required String revision,
  required RuntimePresentationFrameDeltas frameDeltas,
  required NewGameDraft sample,
}) async {
  final session = PresentationPreviewSession(
    runtimeSourceId: 'cin080-parity',
    catalog: catalog,
    mediaUris: mediaUris,
    targetPlatform: PresentationMediaTargetPlatform.macos,
    audioMixer: RuntimeAudioMixer(),
    reducedMotion: true,
    videoDriver: _UnusedVideoDriver(),
    frameDeltas: frameDeltas,
  );
  try {
    return await _answer(
      session,
      names: <String>['Zoé', 'Zoé Corrigée'],
      answers: <bool>[false, true],
      projectRootDirectory: projectRootDirectory,
      revision: revision,
      sample: sample,
    );
  } finally {
    await session.close();
  }
}

/// The composition the player coordinator builds by hand: the same runtime, the
/// same port, no preview wrapper.
Future<_PreviewRun> _runThroughRuntimeComposition({
  required ProjectMediaCatalog catalog,
  required Map<String, Uri> mediaUris,
  required String projectRootDirectory,
  required String revision,
  required RuntimePresentationFrameDeltas frameDeltas,
  required NewGameDraft sample,
}) async {
  final runtime = RuntimePresentationSessionRuntime(
    runtimeSourceId: 'cin080-parity',
    catalog: catalog,
    mediaUris: mediaUris,
    targetPlatform: PresentationMediaTargetPlatform.macos,
    audioMixer: RuntimeAudioMixer(),
    reducedMotion: true,
    videoDriver: _UnusedVideoDriver(),
    frameDeltas: frameDeltas,
  );
  final frames = <PresentationFrame>[];
  final assetRevisions = <String>[];
  final snapshotDigests = <String>[];
  void onFrame() {
    final snapshot = runtime.controller.value;
    if (snapshot == null) return;
    frames.add(snapshot.frame);
    assetRevisions.add(snapshot.assetRevision);
    snapshotDigests.add(_snapshotDigest(snapshot));
  }

  runtime.controller.addListener(onFrame);
  final interactions = HeadlessSceneInteractionPort();
  final requestKinds = <String>[];
  final prompts = <String>[];
  final names = <String>['Zoé', 'Zoé Corrigée'];
  final answers = <bool>[false, true];
  var nameIndex = 0;
  var answerIndex = 0;
  final subscription = interactions.requests.listen((request) {
    requestKinds.add(request.kind.name);
    prompts.add(request.prompt.fallbackText ?? '');
    scheduleMicrotask(() {
      interactions.resolve(switch (request.kind) {
        SceneInteractionRequestKind.text =>
          SceneInteractionResult.textSubmitted(
            requestId: request.requestId,
            revision: request.revision,
            value: names[nameIndex++],
          ),
        SceneInteractionRequestKind.confirmation =>
          SceneInteractionResult.confirmed(
            requestId: request.requestId,
            revision: request.revision,
            value: answers[answerIndex++],
          ),
        SceneInteractionRequestKind.choice =>
          SceneInteractionResult.choiceSelected(
            requestId: request.requestId,
            revision: request.revision,
            selectedOptionId: 'vif',
          ),
        _ => SceneInteractionResult.acknowledged(
            requestId: request.requestId,
            revision: request.revision,
          ),
      });
    });
  });

  try {
    final draft = await runtime
        .buildPreSessionRunner(
          project: _manifest(),
          projectRootDirectory: projectRootDirectory,
          projectRevision: revision,
          sceneId: 'scene_intro',
        )
        .run(
          runId: 'preview-run',
          draft: sample,
          interactions: interactions,
        );
    return _PreviewRun(
      frames: frames,
      assetRevisions: assetRevisions,
      snapshotDigests: snapshotDigests,
      requestKinds: requestKinds,
      prompts: prompts,
      draftName: draft.playerName,
    );
  } finally {
    runtime.controller.removeListener(onFrame);
    await subscription.cancel();
    interactions.close();
    await runtime.close();
  }
}

/// Everything the renderer is handed, not just the frame: a preview that
/// quietly imposed its own reduced-motion, flashes, captions or orientation
/// would render differently from the installed runtime.
String _snapshotDigest(RuntimePresentationFrameSnapshot snapshot) => <String>[
      snapshot.assetRevision,
      snapshot.orientation.name,
      '${snapshot.reduceMotion}',
      '${snapshot.reduceFlashes}',
      '${snapshot.showCaptions}',
      '${snapshot.frame.timeUs}',
      snapshot.frame.cinematicId,
      snapshot.mediaBindings.map((binding) => binding.clipId).join(','),
    ].join('|');

Future<void> _pumpUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 2000; attempt += 1) {
    if (condition()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('condition never became true');
}

ProjectManifest _manifest() => ProjectManifest(
      name: 'CIN-080 preview',
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
              id: 'captions',
              label: 'Sous-titres',
              kind: PresentationTrackKind.caption,
              clips: <PresentationClip>[
                PresentationCaptionClip(
                  id: 'caption_intro',
                  startUs: 0,
                  durationUs: 1000000,
                  captionId: 'media_captions',
                ),
              ],
            ),
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
                PresentationMarkerClip(
                  id: 'cue_confirm',
                  startUs: 600000,
                  label: 'Confirmer le nom',
                  markerKind: PresentationMarkerKind.interactionCue,
                ),
                PresentationMarkerClip(
                  id: 'cue_tone',
                  startUs: 800000,
                  label: 'Choisir le ton',
                  markerKind: PresentationMarkerKind.interactionCue,
                ),
              ],
            ),
          ],
        ),
      ],
      scenes: <SceneAsset>[_scene()],
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
                ScenePresentationInteractionCueBinding(
                  markerId: 'cue_tone',
                  awaitableNodeId: 'choose_tone',
                ),
                ScenePresentationInteractionCueBinding(
                  markerId: 'cue_confirm',
                  awaitableNodeId: 'confirm_name',
                  outcomeRoutes: [
                    ScenePresentationCueOutcomeRoute(
                      outputPortId: 'declined',
                      outcome: PresentationInteractionOutcome.repeatFromMarker(
                        markerId: 'cue_name',
                      ),
                    ),
                  ],
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
          SceneNode(
            id: 'confirm_name',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.preSessionInteraction(
              ScenePreSessionInteractionSpec.confirmation(
                prompt: SceneInteractionPrompt(
                  localizationKey: 'newGame.confirm',
                  fallbackText: 'On garde {{draft.playerName}} ?',
                ),
              ),
            ),
          ),
          SceneNode(
            id: 'choose_tone',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.preSessionInteraction(
              ScenePreSessionInteractionSpec.choice(
                prompt: SceneInteractionPrompt(
                  localizationKey: 'newGame.tone',
                  fallbackText: 'Quel ton pour {{draft.playerName}} ?',
                ),
                options: <SceneInteractionOption>[
                  SceneInteractionOption(
                    id: 'calme',
                    label: SceneInteractionPrompt(
                      localizationKey: 'newGame.tone.calm',
                      fallbackText: 'Calme',
                    ),
                  ),
                  SceneInteractionOption(
                    id: 'vif',
                    label: SceneInteractionPrompt(
                      localizationKey: 'newGame.tone.lively',
                      fallbackText: 'Vif',
                    ),
                  ),
                ],
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

final class _UnusedVideoDriver
    implements RuntimePresentationVideoPlaybackDriver {
  @override
  Future<Object> prepare(Uri source, {required double initialVolume}) =>
      Future<Object>.error(StateError('unused'));

  @override
  Future<void> play(Object handle) async {}

  @override
  Future<void> pause(Object handle) async {}

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Future<void> dispose(Object handle) async {}
}
