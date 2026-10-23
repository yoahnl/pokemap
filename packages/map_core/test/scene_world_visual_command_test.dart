import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'event project catalog validates pictures against the supplied media catalog',
    () {
      final scene = SceneAsset(
        id: 'pipeline_picture',
        name: 'Pipeline picture',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'show',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.interactive(
                SceneInteractiveCommand.worldPresentation(
                  operation: SceneWorldPresentationOperation.showPicture,
                  slotId: 1,
                  mediaAssetId: 'portrait',
                  referenceWidth: 512,
                  referenceHeight: 384,
                  x: 0,
                  y: 0,
                ),
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'start_show',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'show',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'show_end',
              fromNodeId: 'show',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
          ],
        ),
      );
      final project = ProjectManifest(
        name: 'Pipeline',
        maps: const [],
        tilesets: const [],
        scenes: [scene],
      );
      final media = ProjectMediaCatalog(
        entries: [
          ProjectMediaAsset(
            id: 'portrait',
            label: 'Portrait',
            kind: ProjectMediaKind.image,
            sourceAssetId: 'source',
          ),
        ],
      );
      expect(
        buildNarrativeEventProjectCatalog(
          project: project,
          maps: const [],
          presentationMediaCatalog: media,
        ).scenes.single.buildable,
        isTrue,
      );
      expect(
        buildNarrativeEventProjectCatalog(
          project: project,
          maps: const [],
          presentationMediaCatalog: ProjectMediaCatalog(),
        ).scenes.single.buildable,
        isFalse,
      );
      expect(
        buildNarrativeEventProjectCatalog(
          project: project,
          maps: const [],
        ).scenes.single.buildable,
        isFalse,
      );
    },
  );

  test('a Scene picture blocks deletion of its presentation media', () {
    final graph = PresentationReferenceGraph.build(
      cinematics: const [],
      scenes: [
        SceneAsset(
          id: 'picture_scene',
          name: 'Picture',
          graph: SceneGraph(
            startNodeId: 'start',
            nodes: [
              SceneNode(id: 'start', kind: SceneNodeKind.start),
              SceneNode(
                id: 'show',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.interactive(
                  SceneInteractiveCommand.worldPresentation(
                    operation: SceneWorldPresentationOperation.showPicture,
                    slotId: 1,
                    mediaAssetId: 'portrait',
                    referenceWidth: 512,
                    referenceHeight: 384,
                    x: 0,
                    y: 0,
                  ),
                ),
              ),
            ],
            edges: const [],
          ),
        ),
      ],
      mediaCatalog: ProjectMediaCatalog(
        entries: [
          ProjectMediaAsset(
            id: 'portrait',
            label: 'Portrait',
            kind: ProjectMediaKind.image,
            sourceAssetId: 'portrait_source',
          ),
        ],
      ),
    );
    expect(
      graph
          .planDeletion(const PresentationReferenceKey.media('portrait'))
          .canDelete,
      isFalse,
    );
  });

  test(
    'world presentation pictures roundtrip with explicit placement and scope',
    () {
      final show = SceneInteractiveCommand.worldPresentation(
        operation: SceneWorldPresentationOperation.showPicture,
        scope: SceneVisualScope.map,
        slotId: 1,
        mediaAssetId: 'portrait',
        referenceWidth: 512,
        referenceHeight: 384,
        x: 120,
        y: 60,
        scaleX: .5,
        scaleY: 2,
        opacity: .75,
        origin: ScenePictureOrigin.center,
      );
      final decoded =
          SceneInteractiveCommand.fromJson(show.toJson())
              as SceneWorldPresentationInteractiveCommand;
      expect(decoded.toJson(), show.toJson());
      expect(decoded.scope, SceneVisualScope.map);
      expect(decoded.outputPortIds, ['completed', 'blocked']);
    },
  );
  test('world presentation rejects malformed fields before runtime', () {
    expect(
      () => SceneInteractiveCommand.worldPresentation(
        operation: SceneWorldPresentationOperation.showPicture,
        slotId: 0,
        mediaAssetId: 'portrait',
        referenceWidth: 512,
        referenceHeight: 384,
        x: 0,
        y: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => SceneInteractiveCommand.worldPresentation(
        operation: SceneWorldPresentationOperation.movePicture,
        slotId: 1,
        referenceWidth: 512,
        referenceHeight: 384,
        x: double.nan,
        y: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => SceneInteractiveCommand.fromJson({
        'kind': 'worldPresentation',
        'operation': 'erasePicture',
        'slotId': 1,
        'blend': 1,
      }),
      throwsFormatException,
    );
  });
  test('flash and shake retain their explicit simulation durations', () {
    for (final command in [
      SceneInteractiveCommand.worldPresentation(
        operation: SceneWorldPresentationOperation.flash,
        scope: SceneVisualScope.scene,
        red: 255,
        green: 20,
        blue: 0,
        alpha: 128,
        durationMs: 300,
      ),
      SceneInteractiveCommand.worldPresentation(
        operation: SceneWorldPresentationOperation.shake,
        power: 8,
        speed: 3,
        referenceWidth: 512,
        referenceHeight: 384,
        durationMs: 500,
      ),
    ]) {
      expect(
        SceneInteractiveCommand.fromJson(command.toJson()).toJson(),
        command.toJson(),
      );
    }
  });
}
