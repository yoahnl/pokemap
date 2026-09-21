import 'dart:convert';
import 'package:avelune_studio/features/presentations/data/local_presentation_adapter.dart';
import 'package:avelune_studio/features/presentations/domain/presentation_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import '../support/cinematic_adapter_fixture.dart';

void main() {
  late CinematicAdapterFixture f;
  late LocalPresentationAdapter port;
  setUp(() async {
    f = await CinematicAdapterFixture.create();
    port = LocalPresentationAdapter(session: f.session, mapAdapter: f.maps);
  });
  tearDown(() async {
    await f.dispose();
  });
  PresentationCinematicAsset asset(String title) => PresentationCinematicAsset(
    id: 'intro',
    title: title,
    durationUs: 12000000,
  );
  test(
    'mapless final document and classification are published and independently reopened',
    () async {
      final saved = await port.publish(
        asset: asset('Introduction montée'),
        base: null,
      );
      expect(saved.snapshot!.asset, asset('Introduction montée'));
      expect(
        saved.snapshot!.entry!.family,
        CinematicLibraryFamily.presentation,
      );
      expect(
        (await LocalPresentationAdapter(
          session: f.session,
          mapAdapter: f.maps,
        ).load('intro')).asset,
        saved.snapshot!.asset,
      );
      expect((await f.readManifest()).maps, isEmpty);
    },
  );
  test(
    'independent manifest edits survive and conflicting document retains disk',
    () async {
      final first = await port.publish(asset: asset('Initial'), base: null);
      await f.writeManifest(
        (await f.readManifest()).copyWith(
          name: 'Import indépendant',
          cinematics: [CinematicAdapterFixture.asset('world')],
        ),
      );
      final second = await port.publish(
        asset: asset('Montage suivant'),
        base: first.snapshot,
      );
      expect((await f.readManifest()).name, 'Import indépendant');
      expect((await f.readManifest()).cinematics.single.id, 'world');
      await expectLater(
        port.publish(asset: asset('Obsolète'), base: first.snapshot),
        throwsA(isA<PresentationFailure>()),
      );
      expect((await port.load('intro')).asset, second.snapshot!.asset);
    },
  );
  test(
    'staged image creates no durable files before one atomic publication',
    () async {
      final source = f.file('source.png');
      await source.writeAsBytes(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aZ1cAAAAASUVORK5CYII=',
        ),
      );
      final before = await f.file('project.json').readAsBytes();
      final media = await port.stageMedia(
        sourcePath: source.path,
        label: 'Image',
        kind: ProjectMediaKind.image,
      );
      expect(await f.file('project.json').readAsBytes(), before);
      expect(await f.file('assets/.pokemap-media.json').exists(), false);
      final result = await port.publish(
        asset: asset('Avec image'),
        base: null,
        imports: [media],
      );
      expect(
        result.resources.changedPaths,
        containsAll([
          'project.json',
          'assets/.pokemap-media.json',
          'assets/.pokemap-assets.json',
        ]),
      );
      expect(
        result.snapshot!.projection.mediaCatalog.find(media.media.id)!.toJson(),
        media.media.toJson(),
      );
      await port.releaseMedia(media);
    },
  );
  test('abandoning staged image leaves no durable import', () async {
    final source = f.file('source.png');
    await source.writeAsBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aZ1cAAAAASUVORK5CYII=',
      ),
    );
    final media = await port.stageMedia(
      sourcePath: source.path,
      label: 'Image',
      kind: ProjectMediaKind.image,
    );
    await port.releaseMedia(media);
    expect(port.artifacts.list(), isEmpty);
    expect(await f.file('assets/.pokemap-media.json').exists(), false);
    expect((await f.readManifest()).presentationCinematics, isEmpty);
  });
  test(
    'create and link publishes final content and exact modified scene; stale source refuses',
    () async {
      final scene = _scene();
      await f.writeManifest((await f.readManifest()).copyWith(scenes: [scene]));
      final changed = SceneAsset.fromJson({
        ...scene.toJson(),
        'name': 'Scène modifiée',
      });
      final result = await port.publish(
        asset: asset('Titre final et non le modèle'),
        base: null,
        link: PresentationSceneLink(
          baseScene: scene,
          scene: changed,
          nodeId: 'presentation',
          targetNodeId: 'end',
        ),
      );
      expect(result.snapshot!.asset.title, 'Titre final et non le modèle');
      final current = (await f.readManifest()).scenes.single;
      expect(current.name, 'Scène modifiée');
      expect(
        current.graph.nodes.singleWhere((n) => n.id == 'presentation').payload,
        isA<ScenePresentationCinematicPayload>(),
      );
      await expectLater(
        port.delete(result.snapshot!),
        throwsA(isA<PresentationFailure>()),
      );
      await expectLater(
        port.publish(
          asset: PresentationCinematicAsset(
            id: 'other',
            title: 'Autre',
            durationUs: 1000000,
          ),
          base: null,
          link: PresentationSceneLink(
            baseScene: scene,
            scene: changed,
            nodeId: 'other',
            targetNodeId: 'end',
          ),
        ),
        throwsA(isA<PresentationFailure>()),
      );
      expect((await f.readManifest()).presentationCinematics.length, 1);
    },
  );
  test('archive and delete never remove imported media', () async {
    final saved = await port.publish(asset: asset('Introduction'), base: null);
    final archived = await port.setArchived(saved.snapshot!, true);
    expect(archived.snapshot!.entry!.isArchived, true);
    await port.delete(archived.snapshot!);
    expect((await f.readManifest()).presentationCinematics, isEmpty);
  });
}

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
        id: 'a',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.defaultFlow,
      ),
    ],
  ),
  declaredOutcomes: [SceneOutcome(id: 'ready', label: 'Prêt')],
);
