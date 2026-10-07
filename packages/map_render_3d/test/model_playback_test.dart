import 'package:flame_3d/core.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/src/parser/gltf/animation_interpolation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/src/model_byte_loader.dart';
import 'package:map_render_3d/src/model_preview.dart';
import 'package:map_render_3d/src/model_playback.dart';

void main() {
  test(
    'a pending replacement synchronizes to the visible clock only for the same clip',
    () {
      final clip = _clip();
      final visible = ModelPlaybackState()..play(clip, loop: false);
      visible.update(.2);
      final pending = ModelPlaybackState.from(visible)..speed = .25;
      visible.update(.4);
      pending.update(.1);
      expect(visible.clock, closeTo(.6, 1e-9));
      pending.synchronizeClock(visible);
      expect(pending.clock, visible.clock);
      expect(pending.speed, .25);
      pending.play(_clip(), loop: false);
      pending.synchronizeClock(visible);
      expect(pending.clock, 0);
      expect(visible.animationRef, same(clip));
    },
  );
  test('camera changes preserve preview while replay explicitly resets it', () {
    final controls = ModelPreviewController()..play(0);
    addTearDown(controls.dispose);
    final version = controls.animationVersion;
    controls.toggleAnimationPause();
    controls.orbit(2, 2);
    controls.reset();
    expect(controls.animationVersion, version);
    expect(controls.animationPaused, isTrue);
    controls.restartAnimation();
    expect(controls.animationVersion, version + 1);
    expect(controls.animationPaused, isFalse);
    controls.play(null);
    expect(controls.animation, isNull);
  });
  test(
    'rebuilding a placed component retains its clock until its clip changes',
    () {
      final clip = _clip();
      final model = Model(nodes: {}, animations: [clip]);
      final first = AnimatedModelComponent(model: model)
        ..bindAnimation(0, loop: false);
      first.update(.4);
      final rebuilt = AnimatedModelComponent(
        model: model,
        playback: ModelPlaybackState.from(first.playback),
      )..bindAnimation(0, loop: false, speed: .25);
      expect(rebuilt.playback.clock, .4);
      rebuilt.update(.4);
      expect(rebuilt.playback.clock, .5);
      expect(first.playback.clock, .4);
      rebuilt.bindAnimation(null);
      expect(rebuilt.playback.clock, 0);
      expect(rebuilt.playback.animationRef, isNull);
      expect(first.playback.animationRef, same(clip));
    },
  );
  test('one shot holds the final pose and resumes from its paused clock', () {
    final playback = ModelPlaybackState()..play(_clip(), loop: false, speed: 2);
    playback.update(.2);
    expect(playback.clock, closeTo(.4, 1e-9));
    playback.paused = true;
    playback.update(20);
    expect(playback.clock, closeTo(.4, 1e-9));
    playback.paused = false;
    playback.update(20);
    expect(playback.clock, 1);
    final pose = playback.maybeTransform(0, Matrix4.identity());
    expect(pose.getTranslation().x, 3);
    playback.update(1);
    expect(playback.clock, 1);
    playback.restart();
    expect(playback.clock, 0);
    expect(playback.paused, isFalse);
    playback.stop();
    expect(
      playback.maybeTransform(0, Matrix4.identity()).getTranslation().x,
      0,
    );
  });

  test(
    'shared clips have independent clocks and looping handles large deltas',
    () {
      final clip = _clip();
      final first = ModelPlaybackState()..play(clip);
      final second = ModelPlaybackState()..play(clip, loop: false);
      first.update(1000000.25);
      second.update(.6);
      expect(first.clock, closeTo(.25, 1e-9));
      expect(second.clock, .6);
      first.paused = true;
      second.update(.6);
      expect(first.clock, closeTo(.25, 1e-9));
      expect(second.clock, 1);
    },
  );

  test('invalid time and playback speed never corrupt the pose', () {
    final playback = ModelPlaybackState()..play(_clip());
    for (final dt in [double.nan, double.infinity, -1.0]) {
      playback.update(dt);
      expect(playback.clock, 0);
    }
    for (final speed in [0.0, -1.0, double.infinity, double.nan, 17.0]) {
      expect(() => playback.play(_clip(), speed: speed), throwsArgumentError);
    }
    playback.update(.2);
    expect(playback.clock, .2);
  });
}

ModelAnimation _clip() => ModelAnimation(
  name: 'door_op',
  nodes: {
    0: AbsoluteNodeAnimation(
      channels: [
        EndpointSafeAnimationController(
          animation: TranslationAnimationSpline.from(
            interpolation: AnimationInterpolation.linear,
            times: [0, 1],
            values: [Vector3.zero(), Vector3(3, 0, 0)],
          ),
        ),
      ],
    ),
  },
);
