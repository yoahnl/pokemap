import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/presentation_renderer.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/runtime_startup_host.dart';
import 'package:pokemap_loader/src/standalone_presentation_media.dart';

/// Le host autonome joue la même Presentation interactive que le Hub —
/// BETA-CIN-082.
///
/// La composition est la classe PARTAGÉE, pas un player recopié : seule la
/// façade média diffère (un dossier projet au lieu d'un paquet installé). Le
/// parcours va jusqu'au bout — message, confirmation refusée, rejeu depuis le
/// repère, confirmation acceptée — à travers le VRAI contrôleur de surface.
void main() {
  const vtt = '''
WEBVTT

00:00.000 --> 00:03.000
Le train entre en gare.
''';

  Future<Directory> project({bool withAssetCatalog = true}) async {
    final root = await Directory.systemTemp.createTemp('standalone_cin082_');
    final digest = sha256.convert(utf8.encode(vtt)).toString();
    final store = Directory(p.join(root.path, 'assets', '.pokemap-store'));
    await store.create(recursive: true);
    await File(p.join(store.path, '$digest.blob')).writeAsString(vtt);
    await File(
      p.join(root.path, 'assets', '.pokemap-media.json'),
    ).writeAsString(
      jsonEncode(
        ProjectMediaCatalog(
          entries: [
            ProjectMediaAsset(
              id: 'media_captions',
              label: 'Sous-titres',
              kind: ProjectMediaKind.captions,
              sourceAssetId: 'asset_captions',
            ),
          ],
        ).toJson(),
      ),
    );
    if (withAssetCatalog) {
      await File(
        p.join(root.path, 'assets', '.pokemap-assets.json'),
      ).writeAsString(
        jsonEncode(<String, Object?>{
          'schemaVersion': 1,
          'records': <Object?>[
            <String, Object?>{
              'id': 'asset_captions',
              'artifact': <String, Object?>{'digest': 'sha256:$digest'},
            },
          ],
        }),
      );
    }
    return root;
  }

  ProjectManifest manifest() => ProjectManifest(
        name: 'Standalone CIN-082',
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

  test('the project-directory façade resolves the media store', () async {
    final root = await project();
    addTearDown(() => root.delete(recursive: true));

    final media = await loadStandalonePresentationMedia(
      projectRootDirectory: root.path,
    );

    expect(media, isNotNull);
    expect(media!.catalog.entries.single.id, 'media_captions');
    expect(
      File.fromUri(media.mediaUris['media_captions']!).readAsStringSync(),
      contains('WEBVTT'),
      reason: 'the blob is already a file on disk — no extraction needed',
    );
  });

  test('a project without a media catalog stays playable', () async {
    final root = await Directory.systemTemp.createTemp('standalone_no_media_');
    addTearDown(() => root.delete(recursive: true));
    expect(
      await loadStandalonePresentationMedia(projectRootDirectory: root.path),
      isNull,
    );
  });

  test('a declared media without its asset catalog fails closed', () async {
    final root = await project(withAssetCatalog: false);
    addTearDown(() => root.delete(recursive: true));
    await expectLater(
      loadStandalonePresentationMedia(projectRootDirectory: root.path),
      throwsA(isA<StandalonePresentationMediaException>()),
    );
  });

  test('a media blob missing from the store fails closed', () async {
    final root = await project();
    addTearDown(() => root.delete(recursive: true));
    final store = Directory(p.join(root.path, 'assets', '.pokemap-store'));
    for (final blob in store.listSync().whereType<File>()) {
      blob.deleteSync();
    }

    await expectLater(
      loadStandalonePresentationMedia(projectRootDirectory: root.path),
      throwsA(
        isA<StandalonePresentationMediaException>().having(
          (error) => error.mediaId,
          'mediaId',
          'media_captions',
        ),
      ),
      reason: 'handing the player a Uri to a file that is not there would '
          'surface as an opaque decoder failure at playback time',
    );
  });

  test('the shared composition runs the Non branch then the world hand-off',
      () async {
    final root = await project();
    addTearDown(() => root.delete(recursive: true));
    final media = (await loadStandalonePresentationMedia(
      projectRootDirectory: root.path,
    ))!;

    final session = RuntimePresentationSessionRuntime(
      runtimeSourceId: 'standalone-host',
      catalog: media.catalog,
      mediaUris: media.mediaUris,
      targetPlatform: PresentationMediaTargetPlatform.macos,
      audioMixer: RuntimeAudioMixer(),
      reducedMotion: true,
      videoDriver: _UnusedVideoDriver(),
      frameDeltas: (_) => Stream<int>.fromIterable(
        List<int>.filled(16, 150000),
      ),
    );
    addTearDown(session.close);

    final runner = session.buildPreSessionRunner(
      project: manifest(),
      projectRootDirectory: root.path,
      projectRevision: 'sha256:${'a' * 64}',
      sceneId: 'scene_intro',
    );

    final interactions = HeadlessSceneInteractionPort();
    addTearDown(interactions.close);
    final kinds = <String>[];
    final names = <String>['Zoé', 'Zoé Corrigée'];
    final answers = <bool>[false, true];
    var nameIndex = 0;
    var answerIndex = 0;
    final subscription = interactions.requests.listen((request) {
      kinds.add(request.kind.name);
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
        _ => SceneInteractionResult.acknowledged(
            requestId: request.requestId,
            revision: request.revision,
          ),
      });
    });
    addTearDown(subscription.cancel);

    final draft = await runner.run(
      runId: 'standalone-run',
      draft: NewGameDraft.start(
        draftId: 'standalone-draft',
        projectRevision: 'sha256:${'a' * 64}',
        slotId: 'slot_1',
        config: manifest().newGame,
      ),
      interactions: interactions,
    );

    expect(
      kinds,
      const <String>['text', 'confirmation', 'text', 'confirmation'],
      reason: 'the refused confirmation replayed the name entry through the '
          'real surface controller — the branch is not simulated here',
    );
    expect(
      draft.playerName,
      'Zoé Corrigée',
      reason: 'the accepted answer is the one that reaches the world',
    );
  });
  test('the host wires its Presentation stack into the New Game flow',
      () async {
    final root = await project();
    addTearDown(() => root.delete(recursive: true));
    final media = (await loadStandalonePresentationMedia(
      projectRootDirectory: root.path,
    ))!;
    final session = RuntimePresentationSessionRuntime(
      runtimeSourceId: 'standalone-host',
      catalog: media.catalog,
      mediaUris: media.mediaUris,
      targetPlatform: PresentationMediaTargetPlatform.macos,
      audioMixer: RuntimeAudioMixer(),
      reducedMotion: true,
      videoDriver: _UnusedVideoDriver(),
    );
    final projectFile = File(p.join(root.path, 'project.json'));
    await projectFile.writeAsString(jsonEncode(manifest().toJson()));

    final wired = StandaloneRuntimeStartupHost(
      projectFilePath: projectFile.path,
      manifest: manifest(),
      sessionPort: _InertSessionPort(),
      presentationSession: session,
    );
    addTearDown(wired.dispose);
    expect(
      wired.newGameFlowPort.supportsPreSession,
      isTrue,
      reason: 'without this the host would boot straight into the world and '
          'never play the authored pre-session — silently',
    );

    final bare = StandaloneRuntimeStartupHost(
      projectFilePath: projectFile.path,
      manifest: manifest(),
      sessionPort: _InertSessionPort(),
    );
    addTearDown(bare.dispose);
    expect(bare.newGameFlowPort.supportsPreSession, isFalse);
  });

}

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
                  markerId: 'cue_confirm',
                  awaitableNodeId: 'confirm_name',
                  outcomeRoutes: [
                    ScenePresentationCueOutcomeRoute(
                      outputPortId: 'declined',
                      outcome:
                          PresentationInteractionOutcome.repeatFromMarker(
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

final class _InertSessionPort implements StandaloneRuntimeSessionPort {
  @override
  Future<GameSessionCheckpoint?> captureCheckpoint() async => null;

  @override
  Future<void> dispose() async {}

  @override
  bool handleInput(RuntimeInputEvent event) => false;

  @override
  Future<void> launch(
    GameSessionDescriptor descriptor,
    GameSessionProgressReporter reportProgress,
    RuntimeInitialMapPreloadResult? preloadedInitialMap,
  ) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop(GameSessionExitReason reason) async {}
}
