import 'package:avelune_studio/features/cinematics/application/cinematic_preview_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/cinematic_adapter_fixture.dart';

final class _MediaPort implements CinematicMediaPlaybackPort {
  final played = <String>[];
  final active = <String>{};
  @override
  Future<CinematicMediaPlaybackCheckpoint> captureCheckpoint() async =>
      CinematicMediaPlaybackCheckpoint();
  @override
  Future<void> execute(CinematicMediaPlaybackCommand command) async {
    played.add(command.assetId!);
    active.add(command.assetId!);
  }

  @override
  Future<void> restore(CinematicMediaPlaybackCheckpoint checkpoint) async {
    active.clear();
  }
}

void main() {
  test('a previewed then stopped cinematic reopens with its moves, media and duration', () async {
    final media = CinematicMediaAsset(
      id: 'ambience',
      label: 'Ambiance du port',
      kind: CinematicMediaAssetKind.music,
      relativePath: 'audio/ambience.ogg',
      durationMs: 1000,
    );
    final staged = CinematicAsset(
      id: 'harbour',
      title: 'Arrivée au port',
      requiredActors: [CinematicActorRef(actorId: 'hero', label: 'Voyageur')],
      movementTargets: [
        CinematicMovementTargetRef(targetId: 'arrival', label: 'Arrivée'),
      ],
      stageContext: CinematicStageContext(
        initialPlacements: [
          CinematicActorInitialPlacement(
            actorId: 'hero',
            kind: CinematicActorInitialPlacementKind.stagePoint,
            stagePointId: 'start',
          ),
        ],
        stagePoints: [
          CinematicStagePoint(id: 'start', label: 'Départ', x: 0, y: 2),
          CinematicStagePoint(id: 'end', label: 'Arrivée', x: 8, y: 2),
        ],
        movementTargetBindings: [
          CinematicMovementTargetBinding(
            targetId: 'arrival',
            kind: CinematicMovementTargetBindingKind.stagePoint,
            sourceId: 'end',
          ),
        ],
      ),
      timeline: CinematicTimeline(),
    );
    final moving = addCinematicTimelineActorMoveStep(
      ProjectManifest(
        name: 'Port',
        maps: const [],
        tilesets: const [],
        cinematics: [staged],
      ),
      cinematicId: staged.id,
      actorId: 'hero',
      targetId: 'arrival',
      durationMs: 1000,
    ).cinematic;
    final asset = addCinematicTimelineCommandStep(
      moving,
      kind: CinematicTimelineStepKind.music,
      mediaAsset: media,
      durationMs: 1000,
      loop: true,
    ).cinematic;

    final f = await CinematicAdapterFixture.create();
    addTearDown(f.dispose);
    await f.writeManifest(
      (await f.readManifest()).copyWith(cinematicMediaAssets: [media]),
    );
    final audio = f.file('audio/ambience.ogg');
    await audio.parent.create(recursive: true);
    await audio.writeAsBytes(const [79, 103, 103, 83]);

    await f.adapter().publish(id: asset.id, base: null, asset: asset);
    final saved = (await f.adapter().load(asset.id)).asset;
    final authored = saved.toJson();

    CinematicPreviewPlaybackPlan plan(CinematicAsset value) =>
        buildCinematicPreviewPlaybackPlan(
          cinematic: value,
          mediaAssets: [media],
          stageBounds: const CinematicPreviewPlaybackStageBounds(
            width: 12,
            height: 12,
          ),
        );
    final port = _MediaPort();
    final transport = CinematicPreviewTransport()..configureMedia(port);
    addTearDown(transport.dispose);
    transport.install(plan(saved));
    final duration = transport.durationMs;
    transport.play();
    await transport.mediaSettled;
    transport.advance(400);
    expect(transport.frame!.actorPoseById('hero')!.x, closeTo(3.2, .001));
    await transport.mediaSettled;
    expect(port.played, isEmpty);
    transport.advance(700);
    await transport.mediaSettled;
    expect(port.played, ['ambience']);
    expect(port.active, {'ambience'});
    transport.stop();
    await transport.mediaSettled;
    expect(port.active, isEmpty);
    expect(transport.frame!.actorPoseById('hero')!.x, 0);
    expect(saved.toJson(), authored);

    final reopened = (await f.adapter().load(asset.id)).asset;
    expect(reopened.toJson(), authored);
    final again = plan(reopened);
    expect(again.totalDurationMs, duration);
    expect(again.frameAt(again.totalDurationMs).actorPoseById('hero')!.x, 8);
    final manifest = await f.readManifest();
    expect(
      manifest.cinematicMediaAssets.single.relativePath,
      media.relativePath,
    );
    expect(await audio.readAsBytes(), const [79, 103, 103, 83]);
  });
}
