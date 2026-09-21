import 'package:avelune_studio/features/presentations/data/local_presentation_adapter.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/presentation_renderer.dart';
import 'ui11_presentation_fixture.dart';

class Ui11RuntimeFixture {
  Ui11RuntimeFixture(
    this.source,
    this.project,
    this.asset,
    this.revision,
    this.media,
  );
  final Ui11PresentationFixture source;
  final ProjectManifest project;
  final PresentationCinematicAsset asset;
  final String revision;
  final ProjectDirectoryPresentationMedia media;
  String get root => source.source.directory.path;
  static Future<Ui11RuntimeFixture> create() async {
    final fixture = await Ui11PresentationFixture.create();
    final adapter = LocalPresentationAdapter(
      session: fixture.source.session,
      mapAdapter: fixture.source.maps,
    );
    final base = await adapter.load(fixture.asset.id);
    final asset = PresentationCinematicAsset(
      id: base.asset.id,
      title: base.asset.title,
      durationUs: 3000000,
      layers: base.asset.layers,
      tracks: [
        PresentationTrack(
          id: 'image',
          label: 'Illustration',
          kind: PresentationTrackKind.visual,
          clips: [
            PresentationVisualClip(
              id: 'image.clip',
              startUs: 0,
              durationUs: 3000000,
              layerId: 'landscape',
              resourceId: fixture.mediaId,
            ),
          ],
        ),
        PresentationTrack(
          id: 'title',
          label: 'Titre',
          kind: PresentationTrackKind.visual,
          clips: [
            PresentationTextClip(
              id: 'title.clip',
              startUs: 250000,
              durationUs: 2500000,
              layerId: 'title',
              text: 'L’appel de l’horizon',
              style: PresentationTextStyle(fontSize: 32, colorHex: '#FFF8E7'),
              from: PresentationVisualComposition(
                translateX: -.1,
                scaleX: .9,
                scaleY: .9,
              ),
              to: PresentationVisualComposition(
                translateX: .1,
                translateY: -.1,
                rotationTurns: .025,
              ),
              transitionIn: PresentationVisualTransition(
                kind: PresentationVisualTransitionKind.fade,
                durationUs: 500000,
              ),
              transitionOut: PresentationVisualTransition(
                kind: PresentationVisualTransitionKind.fade,
                durationUs: 250000,
              ),
            ),
          ],
        ),
        PresentationTrack(
          id: 'markers',
          label: 'Repère',
          kind: PresentationTrackKind.marker,
          clips: [
            PresentationMarkerClip(
              id: 'name-cue',
              startUs: 750000,
              label: 'Votre nom',
              markerKind: PresentationMarkerKind.interactionCue,
            ),
          ],
        ),
      ],
    );
    await adapter.publish(asset: asset, base: base);
    final manifest = await fixture.source.readManifest();
    final project = manifest.copyWith(
      scenes: [_scene(asset.id)],
      newGame: const ProjectNewGameConfig(
        enabled: true,
        startMapId: 'isolated-start',
        preSessionSceneId: 'intro-scene',
      ),
    );
    await fixture.source.writeManifest(project);
    final fresh = await adapter.load(asset.id);
    final media = (await loadProjectDirectoryPresentationMedia(
      projectRootDirectory: fixture.source.directory.path,
    ))!;
    return Ui11RuntimeFixture(
      fixture,
      project,
      fresh.asset,
      fresh.revision,
      media,
    );
  }

  Future<void> dispose() => source.dispose();
}

SceneAsset _scene(String assetId) => SceneAsset(
  id: 'intro-scene',
  name: 'Introduction',
  executionProfile: SceneExecutionProfile.preSession,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'presentation',
        kind: SceneNodeKind.presentationCinematic,
        payload: ScenePresentationCinematicPayload(
          presentationCinematicId: assetId,
          interactionCueBindings: [
            ScenePresentationInteractionCueBinding(
              markerId: 'name-cue',
              awaitableNodeId: 'ask-name',
            ),
          ],
        ),
      ),
      SceneNode(
        id: 'ask-name',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.preSessionInteraction(
          ScenePreSessionInteractionSpec.text(
            prompt: SceneInteractionPrompt(
              localizationKey: 'fixture.name',
              fallbackText: 'Comment vous appelez-vous ?',
            ),
            resultBinding: const ScenePreSessionResultBinding(
              field: ScenePreSessionDraftField.playerName,
            ),
          ),
        ),
      ),
      SceneNode(
        id: 'after',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.preSessionInteraction(
          ScenePreSessionInteractionSpec.message(
            prompt: SceneInteractionPrompt(
              localizationKey: 'fixture.after',
              fallbackText: 'La présentation est terminée.',
            ),
          ),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'enter',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'presentation',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'continue',
        fromNodeId: 'presentation',
        fromPortId: 'completed',
        toNodeId: 'after',
        kind: SceneEdgeKind.presentationCompleted,
      ),
      SceneEdge(
        id: 'finish',
        fromNodeId: 'after',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
    ],
  ),
);
