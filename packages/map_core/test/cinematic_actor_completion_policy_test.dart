import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'fixtures/cinematic_facing_fixture.dart';

void main() {
  test(
    'completion policy defaults to keepFinal and is serialized explicitly',
    () {
      final asset = facingCinematic();
      expect(asset.toJson()['actorCompletionPolicy'], 'keepFinal');
      final json = asset.toJson()..remove('actorCompletionPolicy');
      expect(
        CinematicAsset.fromJson(json).toJson()['actorCompletionPolicy'],
        'keepFinal',
      );
    },
  );
  for (final value in [null, '', 'unknown', ' keepFinal', 1]) {
    test('explicit invalid completion policy $value is rejected', () {
      final json = facingCinematic().toJson()
        ..['actorCompletionPolicy'] = value;
      expect(() => CinematicAsset.fromJson(json), throwsA(anything));
    });
  }
  test('restoreInitial changes only the terminal preview actor pose', () {
    final source = facingCinematic();
    final json = source.toJson()..['actorCompletionPolicy'] = 'restoreInitial';
    final asset = CinematicAsset.fromJson(json);
    final plan = buildCinematicPreviewPlaybackPlan(cinematic: asset);
    final during = plan.frameAt(500).actorPoseById('actor')!;
    final ended = plan.frameAt(plan.totalDurationMs).actorPoseById('actor')!;
    final initial = plan.actorTracks.single.initialPose;
    expect((during.x, during.y), (10.0, 8.0));
    expect(
      (ended.x, ended.y, ended.facing),
      (initial.x, initial.y, initial.facing),
    );
    expect(asset.toJson()['actorCompletionPolicy'], 'restoreInitial');
    expect(asset, isNot(source));
  });
  test('all authoring copy paths preserve an explicit restore policy', () {
    final asset = facingCinematic().copyWith(
      actorCompletionPolicy: CinematicActorCompletionPolicy.restoreInitial,
    );
    final project = facingProject(asset);
    final copies = [
      updateCinematicTimelineActorFacingStep(
        project,
        cinematicId: asset.id,
        stepId: 'face',
        direction: CinematicTimelineActorFacingDirection.up,
      ).cinematic,
      addCinematicRequiredActor(
        project,
        cinematicId: asset.id,
        label: 'Other',
      ).cinematic,
      addCinematicMovementTarget(
        project,
        cinematicId: asset.id,
        label: 'Other',
      ).cinematic,
      updateCinematicStageContext(
        project,
        cinematicId: asset.id,
        stageContext: asset.stageContext,
      ).cinematic,
      updateCinematicStageMap(
        project,
        cinematicId: asset.id,
        mapId: 'room',
      ).cinematic,
      duplicateCinematicAsset(project, cinematicId: asset.id).cinematic,
    ];
    for (final copy in copies) {
      expect(
        copy.actorCompletionPolicy,
        CinematicActorCompletionPolicy.restoreInitial,
      );
      expect(CinematicAsset.fromJson(copy.toJson()), copy);
    }
    final changed = setCinematicActorCompletionPolicy(
      project,
      cinematicId: asset.id,
      policy: CinematicActorCompletionPolicy.keepFinal,
    );
    expect(
      changed.cinematic.actorCompletionPolicy,
      CinematicActorCompletionPolicy.keepFinal,
    );
    expect(
      project.cinematics.single.actorCompletionPolicy,
      CinematicActorCompletionPolicy.restoreInitial,
    );
  });

  test('keepFinal preview retains its terminal position and facing', () {
    final asset = facingCinematic();
    final plan = buildCinematicPreviewPlaybackPlan(cinematic: asset);
    final ended = plan.frameAt(1000).actorPoseById('actor')!;
    expect(
      (ended.x, ended.y, ended.facing),
      (12.0, 8.0, CinematicActorPreviewDirection.west),
    );
    expect(plan.frameAt(500).actorPoseById('actor')!.x, 10);
    expect(plan.frameAt(1000).actorPoseById('actor')!.x, 12);
  });
}
