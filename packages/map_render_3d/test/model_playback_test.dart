import 'package:flame_3d/core.dart';
import 'package:flame_3d/model.dart';
import 'package:flame_3d/src/parser/gltf/animation_interpolation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/src/model_byte_loader.dart';
import 'package:map_render_3d/src/model_preview.dart';
import 'package:map_render_3d/src/model_playback.dart';

void main() {
  for (final commandIndex in [0, 1]) {
    test('cancel restores ambient clock for command clip $commandIndex', () {
      final clips = [_clip(), _clip()];
      final component = AnimatedModelComponent(
        model: Model(nodes: {}, animations: clips),
      )..bindAnimation(0, speed: .5);
      component.update(.6);
      component.bindRuntimeState(
        SpatialModelRuntimeState(
          modelId: 'model',
          animationIndex: commandIndex,
          normalizedTime: .8,
          blocksMovement: true,
        ),
        authoredAnimationIndex: 0,
        authoredSpeed: .5,
      );
      expect(component.playback.clock, .8);
      component.bindRuntimeState(
        null,
        authoredAnimationIndex: 0,
        authoredSpeed: .5,
        paused: true,
      );
      expect(component.playback.animationRef, same(clips.first));
      expect(component.playback.clock, closeTo(.3, 1e-9));
      expect(component.playback.speed, .5);
      expect(component.playback.loop, isTrue);
      component.update(20);
      expect(component.playback.clock, closeTo(.3, 1e-9));
      component.bindRuntimeState(
        null,
        authoredAnimationIndex: 0,
        authoredSpeed: .5,
      );
      component.update(.2);
      expect(component.playback.clock, closeTo(.4, 1e-9));
    });
  }

  test(
    'pending model replacement preserves the ambient pose before a command',
    () {
      final clips = [_clip(), _clip()];
      final model = Model(nodes: {}, animations: clips);
      final visible = AnimatedModelComponent(model: model)..bindAnimation(0);
      visible.update(.4);
      visible.bindRuntimeState(
        SpatialModelRuntimeState(
          modelId: 'model',
          animationIndex: 1,
          normalizedTime: .8,
          blocksMovement: true,
        ),
        authoredAnimationIndex: 0,
      );
      final replacement = AnimatedModelComponent(
        model: model,
        playback: ModelPlaybackState.from(visible.playback),
        runtimePoseBefore: visible.runtimePoseBefore,
      );
      replacement.bindRuntimeState(null, authoredAnimationIndex: 0);
      expect(replacement.playback.animationRef, same(clips.first));
      expect(replacement.playback.clock, .4);
      expect(visible.playback.clock, .8);
    },
  );

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
