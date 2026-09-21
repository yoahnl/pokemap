import 'dart:convert';
import 'package:avelune_studio/features/presentations/data/local_presentation_adapter.dart';
import 'package:avelune_studio/features/presentations/domain/presentation_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import '../support/cinematic_adapter_fixture.dart';

void main() {
  late CinematicAdapterFixture f;
  late LocalPresentationAdapter port;
  setUp(() async {
    f = await CinematicAdapterFixture.create();
    port = LocalPresentationAdapter(session: f.session, mapAdapter: f.maps);
  });
  tearDown(() => f.dispose());
  Future<PresentationStagedMedia> stage(String name) async {
    final file = f.file('$name.png');
    await file.writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aZ1cAAAAASUVORK5CYII=',
      ),
    );
    return port.stageMedia(
      sourcePath: file.path,
      label: name,
      kind: ProjectMediaKind.image,
    );
  }

  test(
    'final edited asset, image and scene recover as one transaction',
    () async {
      var interrupted = false;
      port = LocalPresentationAdapter(
        session: f.session,
        mapAdapter: f.maps,
        faultInjector: (context) {
          if (!interrupted &&
              context.checkpoint ==
                  AuthoringTransactionCheckpoint.afterResourcePromoted) {
            interrupted = true;
            throw const AuthoringTransactionSimulatedCrash();
          }
        },
      );
      final scene = _scene();
      await f.writeManifest((await f.readManifest()).copyWith(scenes: [scene]));
      final media = await stage('Paysage');
      final asset = _asset('opening', media.media.id);
      final receipt = await port.publish(
        asset: asset,
        base: null,
        imports: [media],
        link: PresentationSceneLink(
          baseScene: scene,
          scene: scene,
          nodeId: 'opening',
          targetNodeId: 'end',
        ),
      );
      expect(interrupted, true);
      final reopened = await port.load(asset.id);
      expect(reopened.asset, asset);
      expect(
        reopened.asset.tracks.single.clips.single,
        isA<PresentationVisualClip>(),
      );
      expect(reopened.projection.mediaCatalog.find(media.media.id), isNotNull);
      expect(
        (await f.readManifest()).scenes.single.graph.nodes.any(
          (n) => n.id == 'opening',
        ),
        true,
      );
      expect(
        receipt.resources.changedPaths,
        contains('assets/.pokemap-media.json'),
      );
      await port.releaseMedia(media);
    },
  );
  test(
    'import into unchanged document saves sources and deletion keeps them',
    () async {
      final asset = PresentationCinematicAsset(
        id: 'a',
        title: 'A',
        durationUs: 1000000,
      );
      final base = await port.publish(asset: asset, base: null);
      final media = await stage('Image');
      final saved = await port.publish(
        asset: asset,
        base: base.snapshot,
        imports: [media],
      );
      expect(saved.snapshot!.asset, asset);
      expect(
        saved.snapshot!.projection.mediaCatalog.find(media.media.id),
        isNotNull,
      );
      final bytes = await f.file('assets/.pokemap-media.json').readAsBytes();
      await port.delete(saved.snapshot!);
      expect(await f.file('assets/.pokemap-media.json').readAsBytes(), bytes);
      await port.releaseMedia(media);
    },
  );
  test(
    'changed referenced media refuses while independent media import is preserved',
    () async {
      final media = await stage('Fond');
      final asset = _asset('a', media.media.id);
      final first = await port.publish(
        asset: asset,
        base: null,
        imports: [media],
      );
      final secondMedia = await stage('Indépendant');
      await port.publish(
        asset: PresentationCinematicAsset(
          id: 'b',
          title: 'B',
          durationUs: 1000000,
        ),
        base: null,
        imports: [secondMedia],
      );
      final updated = decodePresentationCinematicAsset({
        ...encodePresentationCinematicAsset(asset),
        'title': 'Titre ultérieur',
      });
      final saved = await port.publish(asset: updated, base: first.snapshot);
      expect(
        saved.snapshot!.projection.mediaCatalog.find(secondMedia.media.id),
        isNotNull,
      );
      final file = f.file('assets/.pokemap-media.json');
      final catalog = decodeProjectMediaCatalogBytes(await file.readAsBytes());
      final changed = ProjectMediaCatalog(
        entries: [
          for (final item in catalog.entries)
            if (item.id == media.media.id)
              ProjectMediaAsset.fromJson({
                ...item.toJson(),
                'label': 'Source remplacée',
              })
            else
              item,
        ],
      );
      await file.writeAsString(jsonEncode(changed.toJson()));
      final bytes = await f.file('project.json').readAsBytes();
      await expectLater(
        port.publish(asset: asset, base: saved.snapshot),
        throwsA(isA<PresentationFailure>()),
      );
      expect(await f.file('project.json').readAsBytes(), bytes);
      await port.releaseMedia(media);
      await port.releaseMedia(secondMedia);
    },
  );
}

PresentationCinematicAsset _asset(String id, String media) =>
    PresentationCinematicAsset(
      id: id,
      title: 'Titre final',
      durationUs: 2000000,
      layers: [PresentationLayer(id: 'image', label: 'Image', zIndex: 0)],
      tracks: [
        PresentationTrack(
          id: 'image',
          label: 'Image finale',
          kind: PresentationTrackKind.visual,
          clips: [
            PresentationVisualClip(
              id: 'image.clip',
              startUs: 200000,
              durationUs: 1800000,
              layerId: 'image',
              resourceId: media,
            ),
          ],
        ),
      ],
    );
SceneAsset _scene() => SceneAsset(
  id: 'scene',
  name: 'Introduction',
  executionProfile: SceneExecutionProfile.preSession,
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'end',
        kind: SceneNodeKind.end,
        payload: SceneEndPayload(
          sceneOutcomeId: 'ready',
          outcomePolicy: SceneOutcomePolicy.progression,
        ),
      ),
    ],
    edges: [
      SceneEdge(
        id: 'edge',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
  declaredOutcomes: [SceneOutcome(id: 'ready', label: 'Prêt')],
);
