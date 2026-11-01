import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/painting.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';
import 'package:map_runtime/src/presentation/flutter/battle_command_overlay_snapshot.dart';
import 'package:map_runtime/src/presentation/flame/battle_camera_framing.dart';
import 'package:map_runtime/src/presentation/flame/battle_perspective_camera.dart';

void main() {
  const viewport = Rect.fromLTWH(0, 0, 390, 500);
  final actor = BattleCameraSubject(
    id: 'principal',
    geometry: const BattleCameraSubjectGeometry(
      foot: Offset(280, 300),
      bounds: Rect.fromLTWH(230, 170, 100, 130),
      focusAnchor: Offset(280, 235),
    ),
  );
  BattleCameraShot resolve({
    List<BattleCameraSubject>? subjects,
    List<Rect> obstacles = const [],
    BattleCameraShotIntent intent = BattleCameraShotIntent.target,
    Rect useful = viewport,
    BattlePerspectiveCamera? camera,
  }) => const BattleCameraShotResolver().resolve(
    camera: camera ?? BattlePerspectiveCamera(viewport: viewport),
    intent: intent,
    subjects: subjects ?? [actor],
    principalId: actor.id,
    usefulViewport: useful,
    obstacles: obstacles,
    playerSide: false,
  );

  test('preserves the approved ideal 1.08 focus when its envelope fits', () {
    final camera = BattlePerspectiveCamera(viewport: viewport);
    final expected = camera.idealFocusPose(
      actor.geometry.foot,
      playerSide: false,
    );
    final shot = resolve(camera: camera);
    expect(shot.eye.distanceTo(expected.eye), lessThan(.000001));
    expect(shot.aim.distanceTo(expected.aim), lessThan(.000001));
    expect(shot.fits, isTrue);
    final asymmetric = resolve(
      subjects: [
        BattleCameraSubject(
          id: actor.id,
          geometry: BattleCameraSubjectGeometry(
            foot: actor.geometry.foot,
            bounds: actor.geometry.bounds,
            focusAnchor: const Offset(250, 180),
          ),
        ),
      ],
      camera: camera,
    );
    expect(asymmetric.eye.distanceTo(expected.eye), lessThan(.000001));
    expect(asymmetric.aim.distanceTo(expected.aim), lessThan(.000001));
    expect(
      shot.projections.single.bounds.width / actor.geometry.bounds.width,
      closeTo(1.08, .000001),
    );
  });

  for (final bounds in [
    const Rect.fromLTWH(100, -150, 220, 450),
    const Rect.fromLTWH(-150, 200, 700, 100),
  ]) {
    test('fits full large opaque bounds $bounds rather than only feet', () {
      final shot = resolve(
        subjects: [
          BattleCameraSubject(
            id: actor.id,
            geometry: BattleCameraSubjectGeometry(
              foot: actor.geometry.foot,
              bounds: bounds,
              focusAnchor: bounds.center,
            ),
          ),
        ],
      );
      expect(shot.fits, isTrue);
      expect(
        viewport.deflate(8).contains(shot.projections.single.bounds.topLeft),
        isTrue,
      );
      expect(
        viewport
            .deflate(8)
            .contains(shot.projections.single.bounds.bottomRight),
        isTrue,
      );
      expect(shot.eye.isFinite && shot.aim.isFinite, isTrue);
      final evaluated = BattlePerspectiveCamera(viewport: viewport)
        ..moveTo(eye: shot.eye, aim: shot.aim, durationSeconds: 0);
      final projected = evaluated.billboardAt(actor.geometry.foot);
      final offset = bounds.topLeft - actor.geometry.foot;
      final actual = Rect.fromLTWH(
        projected.position.dx + offset.dx * projected.scale,
        projected.position.dy + offset.dy * projected.scale,
        bounds.width * projected.scale,
        bounds.height * projected.scale,
      );
      expect(actual, shot.projections.single.bounds);
      expect(viewport.deflate(8).contains(actual.topLeft), isTrue);
      expect(viewport.deflate(8).contains(actual.bottomRight), isTrue);
    });
  }

  test('fits around actual visible UI obstacle rectangles', () {
    const obstacle = Rect.fromLTWH(100, 120, 210, 160);
    final shot = resolve(obstacles: [obstacle]);
    expect(shot.fits, isTrue);
    expect(
      shot.projections.single.bounds.overlaps(obstacle.inflate(8)),
      isFalse,
    );
  });

  test(
    'overview requires every subject while focus permits secondary exclusion',
    () {
      final subjects = [
        actor,
        const BattleCameraSubject(
          id: 'secondary',
          geometry: BattleCameraSubjectGeometry(
            foot: Offset(50, 420),
            bounds: Rect.fromLTWH(0, 260, 120, 160),
            focusAnchor: Offset(60, 340),
          ),
        ),
      ];
      expect(resolve(subjects: subjects).projections.map((p) => p.id), [
        'principal',
      ]);
      final overview = resolve(
        subjects: subjects,
        intent: BattleCameraShotIntent.overview,
      );
      expect(overview.projections.map((p) => p.id), ['principal', 'secondary']);
      expect(overview.fits, isTrue);
    },
  );

  test('no free space returns a finite explicit unsatisfied diagnostic', () {
    final shot = resolve(obstacles: [viewport]);
    expect(shot.fits, isFalse);
    expect(shot.diagnostic, BattleCameraFramingDiagnostic.noSpace);
    expect(shot.eye.isFinite && shot.aim.isFinite, isTrue);
  });

  test('invalid metadata cannot create an invalid camera pose', () {
    final shot = resolve(
      subjects: [
        const BattleCameraSubject(
          id: 'principal',
          geometry: BattleCameraSubjectGeometry(
            foot: Offset(double.nan, 2),
            bounds: Rect.fromLTWH(0, 0, 100, 100),
            focusAnchor: Offset.zero,
          ),
        ),
      ],
    );
    expect(shot.fits, isFalse);
    expect(shot.diagnostic, BattleCameraFramingDiagnostic.invalidGeometry);
    expect(shot.eye.isFinite && shot.aim.isFinite, isTrue);
  });
  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    for (final doubles in [false, true]) {
      for (final mode in [
        BattleCommandOverlayMode.fight,
        BattleCommandOverlayMode.bag,
        BattleCommandOverlayMode.pokemon,
      ]) {
        test(
          'resolved layout $size doubles=$doubles menu=$mode fits all required opaque subjects',
          () {
            final layout = BattleSceneLayout.forViewport(
              viewportSize: size,
              safePadding: const EdgeInsets.fromLTRB(24, 44, 20, 34),
              commandPanelMode: mode,
            );
            final slots =
                [
                      for (final side in BattleSideId.values)
                        for (var index = 0; index < (doubles ? 2 : 1); index++)
                          BattleSlotRef(side: side, slotIndex: index),
                    ]
                    .where(
                      (slot) => !layout
                          .combatantGeometry(slot, doubles: doubles)
                          .spriteRect
                          .isEmpty,
                    )
                    .toList();
            final subjects = [
              for (final slot in slots)
                BattleCameraSubject(
                  id: '$slot',
                  geometry: BattleCameraSubjectGeometry(
                    foot: layout
                        .combatantGeometry(slot, doubles: doubles)
                        .footAnchor,
                    bounds: layout
                        .combatantGeometry(slot, doubles: doubles)
                        .spriteRect,
                    focusAnchor: layout
                        .combatantGeometry(slot, doubles: doubles)
                        .spriteRect
                        .center,
                  ),
                ),
            ];
            final shot = const BattleCameraShotResolver().resolve(
              camera: BattlePerspectiveCamera(viewport: layout.stageRect),
              intent: BattleCameraShotIntent.overview,
              subjects: subjects,
              usefulViewport: layout.arenaRect.intersect(
                Rect.fromLTRB(24, 44, size.width - 20, size.height - 34),
              ),
              obstacles: [
                layout.commandPanelRect,
                for (final slot in slots)
                  layout.combatantGeometry(slot, doubles: doubles).hudRect,
              ],
            );
            expect(shot.fits, isTrue, reason: '${shot.diagnostic}');
            expect(shot.projections.length, slots.length);
            expect(shot.eye.isFinite && shot.aim.isFinite, isTrue);
          },
        );
      }
    }
  }

  test('declared stable multipart animation envelope is fitted as a union', () {
    final geometry = actor.geometry;
    final envelope = geometry.bounds.expandToInclude(
      const Rect.fromLTWH(100, 20, 230, 280),
    );
    final shot = resolve(
      subjects: [
        BattleCameraSubject(
          id: actor.id,
          geometry: BattleCameraSubjectGeometry(
            foot: geometry.foot,
            bounds: geometry.bounds,
            focusAnchor: geometry.focusAnchor,
            animationEnvelope: envelope,
          ),
        ),
      ],
    );
    expect(shot.fits, isTrue);
    expect(
      shot.projections.single.bounds.width /
          shot.projections.single.bounds.height,
      closeTo(envelope.width / envelope.height, .000001),
    );
  });

  test(
    'checked intermediate trajectory keeps margin away from an obstacle',
    () {
      const obstacle = Rect.fromLTWH(0, 0, 120, 120);
      final camera = BattlePerspectiveCamera(viewport: viewport);
      final shot = resolve(camera: camera, obstacles: [obstacle]);
      expect(shot.trajectoryFits, isTrue);
      final start = (eye: camera.eye, aim: camera.aim);
      for (var i = 0; i <= 384; i++) {
        final t = i / 384;
        camera.moveTo(
          eye: start.eye + (shot.eye - start.eye) * t,
          aim: start.aim + (shot.aim - start.aim) * t,
          durationSeconds: 0,
        );
        final projected = camera.billboardAt(actor.geometry.foot);
        final offset = actor.geometry.bounds.topLeft - actor.geometry.foot;
        final bounds = Rect.fromLTWH(
          projected.position.dx + offset.dx * projected.scale,
          projected.position.dy + offset.dy * projected.scale,
          actor.geometry.bounds.width * projected.scale,
          actor.geometry.bounds.height * projected.scale,
        );
        expect(bounds.overlaps(obstacle.inflate(8)), isFalse);
        expect(viewport.deflate(8).contains(bounds.topLeft), isTrue);
        expect(viewport.deflate(8).contains(bounds.bottomRight), isTrue);
      }
    },
  );
  test(
    'finite sky-ray metadata produces a diagnostic rather than throwing',
    () {
      final camera = BattlePerspectiveCamera(viewport: viewport);
      final foot = Offset(viewport.center.dx, camera.groundHorizonY - 1);
      final shot = resolve(
        subjects: [
          BattleCameraSubject(
            id: actor.id,
            geometry: BattleCameraSubjectGeometry(
              foot: foot,
              bounds: const Rect.fromLTWH(10, 10, 20, 20),
              focusAnchor: const Offset(20, 20),
            ),
          ),
        ],
      );
      expect(shot.fits, isFalse);
      expect(shot.diagnostic, BattleCameraFramingDiagnostic.invalidGeometry);
      expect(shot.eye.isFinite && shot.aim.isFinite, isTrue);
    },
  );

  test('group intent fits exactly its declared required subjects', () {
    final camera = BattlePerspectiveCamera(viewport: viewport);
    final shot = const BattleCameraShotResolver().resolve(
      camera: camera,
      intent: BattleCameraShotIntent.group,
      subjects: [actor],
      groupIds: {actor.id},
      usefulViewport: viewport,
      obstacles: const [],
    );
    expect(shot.fits, isTrue);
    expect(shot.projections.map((p) => p.id), [actor.id]);
  });

  test('hold policy leaves the finite current pose unchanged', () {
    final camera = BattlePerspectiveCamera(viewport: viewport);
    final shot = const BattleCameraShotResolver().resolve(
      camera: camera,
      intent: BattleCameraShotIntent.target,
      subjects: [actor],
      principalId: actor.id,
      usefulViewport: viewport,
      obstacles: const [],
      policy: BattleCameraReframePolicy.holdPose,
    );
    expect(shot.fits, isTrue);
    expect(shot.eye.distanceTo(camera.eye), 0);
    expect(shot.aim.distanceTo(camera.aim), 0);
  });
  test('constrained fallback consumes an asymmetric visual focus anchor', () {
    const bounds = Rect.fromLTWH(-100, -150, 700, 600);
    BattleCameraShot shot(Offset anchor) => resolve(
      subjects: [
        BattleCameraSubject(
          id: actor.id,
          geometry: BattleCameraSubjectGeometry(
            foot: actor.geometry.foot,
            bounds: bounds,
            focusAnchor: anchor,
          ),
        ),
      ],
    );
    final centered = shot(bounds.center);
    final asymmetric = shot(const Offset(300, -50));
    expect(centered.fits && asymmetric.fits, isTrue);
    expect(centered.aim.distanceTo(asymmetric.aim), greaterThan(.01));
    expect(asymmetric.projections.single.bounds.left, greaterThanOrEqualTo(8));
    expect(
      asymmetric.projections.single.bounds.right,
      lessThanOrEqualTo(viewport.right - 8),
    );
    expect(asymmetric.projections.single.bounds.top, greaterThanOrEqualTo(8));
    expect(
      asymmetric.projections.single.bounds.bottom,
      lessThanOrEqualTo(viewport.bottom - 8),
    );
  });
  test(
    'finite ground beyond the neutral far plane returns invalid geometry',
    () {
      final camera = BattlePerspectiveCamera(viewport: viewport);
      final foot = Offset(195, camera.groundHorizonY + 1);
      expect(camera.tryGroundAt(foot), isNotNull);
      expect(camera.tryBillboardAt(foot), isNull);
      final shot = resolve(
        camera: camera,
        subjects: [
          BattleCameraSubject(
            id: actor.id,
            geometry: BattleCameraSubjectGeometry(
              foot: foot,
              bounds: const Rect.fromLTWH(150, 50, 100, 100),
              focusAnchor: const Offset(195, 100),
            ),
          ),
        ],
      );
      expect(shot.fits, isFalse);
      expect(shot.diagnostic, BattleCameraFramingDiagnostic.invalidGeometry);
      expect(shot.eye.isFinite && shot.aim.isFinite, isTrue);
    },
  );
  test('overview minimally translates actors around a HUD in their empty union space', () {
    const frame = Rect.fromLTWH(0, 0, 400, 500);
    const obstacle = Rect.fromLTWH(160, 400, 220, 100);
    final camera = BattlePerspectiveCamera(viewport: frame);
    const subjects = [
      BattleCameraSubject(
        id: 'near',
        geometry: BattleCameraSubjectGeometry(
          foot: Offset(70, 510),
          bounds: Rect.fromLTWH(30, 400, 80, 110),
          focusAnchor: Offset(70, 455),
        ),
      ),
      BattleCameraSubject(
        id: 'far',
        geometry: BattleCameraSubjectGeometry(
          foot: Offset(320, 260),
          bounds: Rect.fromLTWH(280, 180, 80, 80),
          focusAnchor: Offset(320, 220),
        ),
      ),
    ];
    BattleCameraShot shot() => const BattleCameraShotResolver().resolve(
      camera: camera,
      intent: BattleCameraShotIntent.overview,
      subjects: subjects,
      usefulViewport: frame,
      obstacles: const [obstacle],
    );
    final result = shot();
    expect(result.fits, isTrue);
    final near = result.projections.first.bounds;
    expect(near.width, closeTo(80, .000001));
    expect(near.bottom, greaterThan(485));
    expect(near.bottom, lessThanOrEqualTo(490));
    expect(
      result.eye.distanceTo(BattlePerspectiveCamera.homeEye),
      lessThan(.5),
    );
    for (final actor in result.projections) {
      expect(actor.bounds.inflate(8).overlaps(obstacle), isFalse);
    }
    final repeated = shot();
    expect(repeated.eye.distanceTo(result.eye), lessThan(.000000001));
    expect(repeated.aim.distanceTo(result.aim), lessThan(.000000001));
    expect(result.startPose.eye.distanceTo(camera.eye), 0);
  });
}
