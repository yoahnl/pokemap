import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_gen5_actor_motion.dart';

final class _Scene {
  final owners = <Object, Object>{};
  final poses = <Object, BattleGen5ActorPose>{};
  final releases = <Object>[];
  int claims = 0;
  Object? failActor;

  bool claim(Object actor, Object owner) {
    claims++;
    final current = owners[actor];
    if (current != null && !identical(current, owner)) return false;
    owners[actor] = owner;
    return true;
  }

  bool apply(Object actor, Object owner, BattleGen5ActorPose pose) {
    if (actor == failActor || !identical(owners[actor], owner)) return false;
    poses[actor] = pose;
    return true;
  }

  void release(Object actor, Object owner) {
    releases.add(actor);
    if (identical(owners[actor], owner)) {
      owners.remove(actor);
      poses.remove(actor);
    }
  }

  BattleGen5ActorMotionController create() => BattleGen5ActorMotionController(
    claim: claim,
    apply: apply,
    release: release,
  );
}

void _start(
  BattleGen5ActorMotionController controller,
  Object actor,
  BattleGen5ActorMotionChannel channel, {
  int type = 2,
  int x = 4096,
  int y = 0,
  int frames = 2,
  int wait = 0,
  int times = 1,
  bool mirrorX = false,
}) => controller.start(
  actor: actor,
  channel: channel,
  type: type,
  xFx32: x,
  yFx32: y,
  frames: frames,
  wait: wait,
  times: times,
  mirrorX: mirrorX,
);

void main() {
  test('position and scale compose until each swing returns to neutral', () {
    final scene = _Scene();
    final controller = scene.create();
    _start(controller, 'user', BattleGen5ActorMotionChannel.position);
    _start(
      controller,
      'user',
      BattleGen5ActorMotionChannel.scale,
      x: 1024,
      y: -1024,
      frames: 1,
    );
    expect(scene.claims, 2);
    controller.tick();
    expect(scene.poses['user'], (
      offsetXFx32: 2048,
      offsetYFx32: 0,
      scaleXFx32: 5120,
      scaleYFx32: 3072,
    ));
    controller.tick();
    expect(scene.poses['user'], (
      offsetXFx32: 4096,
      offsetYFx32: 0,
      scaleXFx32: 4096,
      scaleYFx32: 4096,
    ));
    expect(
      controller.isChannelBusy('user', BattleGen5ActorMotionChannel.scale),
      isFalse,
    );
    expect(controller.isActorBusy('user'), isTrue);
    controller.tick();
    expect(scene.poses['user']!.offsetXFx32, 2048);
    controller.tick();
    expect(controller.isBusy, isFalse);
    expect(scene.owners, isEmpty);
    expect(scene.poses, isEmpty);
    expect(scene.releases, ['user']);
  });

  test('rounding, waits, repetitions and mirroring retain source units', () {
    final scene = _Scene();
    final controller = scene.create();
    _start(
      controller,
      'enemy',
      BattleGen5ActorMotionChannel.position,
      x: 1229,
      y: -1229,
      frames: 2,
      wait: 1,
      times: 2,
      mirrorX: true,
    );
    final xs = <int>[];
    final ys = <int>[];
    for (var tick = 0; tick < 14; tick++) {
      controller.tick();
      xs.add(scene.poses['enemy']!.offsetXFx32);
      ys.add(scene.poses['enemy']!.offsetYFx32);
    }
    expect(xs.take(4), [-615, -615, -1230, -1230]);
    expect(ys.take(4), [-614, -614, -1228, -1228]);
    expect(controller.isBusy, isTrue);
    controller.tick();
    expect(controller.isBusy, isFalse);
    expect(scene.releases, ['enemy']);
  });

  test(
    'same channel, invalid modes and unsafe scale reject before claiming',
    () {
      final scene = _Scene();
      final controller = scene.create();
      expect(
        () => _start(
          controller,
          'user',
          BattleGen5ActorMotionChannel.position,
          type: 1,
        ),
        throwsFormatException,
      );
      expect(
        () => _start(
          controller,
          'user',
          BattleGen5ActorMotionChannel.scale,
          x: -4095,
          frames: 600,
        ),
        throwsFormatException,
      );
      expect(
        () => _start(
          controller,
          'user',
          BattleGen5ActorMotionChannel.scale,
          mirrorX: true,
        ),
        throwsFormatException,
      );
      expect(scene.claims, 0);
      _start(controller, 'user', BattleGen5ActorMotionChannel.position);
      expect(
        () => _start(controller, 'user', BattleGen5ActorMotionChannel.position),
        throwsStateError,
      );
      expect(scene.claims, 1);
      expect(controller.isActorBusy('user'), isTrue);
    },
  );

  test(
    'foreign ownership blocks a new job without claiming or dispatching it',
    () {
      final scene = _Scene();
      final foreignOwner = Object();
      scene.owners['user'] = foreignOwner;
      final controller = scene.create();
      expect(
        () => _start(controller, 'user', BattleGen5ActorMotionChannel.position),
        throwsStateError,
      );
      expect(controller.isBusy, isFalse);
      expect(scene.owners['user'], same(foreignOwner));
      expect(scene.poses, isEmpty);
      expect(scene.releases, isEmpty);
    },
  );

  test('second channel checks ownership after an actor replacement', () {
    final scene = _Scene();
    final controller = scene.create();
    _start(controller, 'user', BattleGen5ActorMotionChannel.position);
    final replacement = Object();
    scene.owners['user'] = replacement;
    expect(
      () => _start(controller, 'user', BattleGen5ActorMotionChannel.scale),
      throwsStateError,
    );
    expect(controller.isBusy, isFalse);
    expect(scene.owners['user'], same(replacement));
    expect(scene.releases, ['user']);
  });

  test(
    'cancel clears only its own actor claim and preserves a replacement',
    () {
      final scene = _Scene();
      final controller = scene.create();
      _start(controller, 'user', BattleGen5ActorMotionChannel.position);
      _start(controller, 'enemy', BattleGen5ActorMotionChannel.position);
      controller.tick();
      final replacement = Object();
      scene.owners['user'] = replacement;
      controller.cancelActor('user');
      expect(scene.owners['user'], same(replacement));
      expect(controller.isActorBusy('user'), isFalse);
      expect(controller.isActorBusy('enemy'), isTrue);
      controller.cancel();
      controller.cancel();
      expect(controller.isBusy, isFalse);
      expect(scene.owners['user'], same(replacement));
      expect(scene.releases, ['user', 'enemy']);
    },
  );

  test('failed pose application releases all claimed actors exactly once', () {
    final scene = _Scene();
    final controller = scene.create();
    _start(controller, 'user', BattleGen5ActorMotionChannel.position);
    _start(controller, 'enemy', BattleGen5ActorMotionChannel.position);
    scene.failActor = 'enemy';
    expect(controller.tick, throwsStateError);
    expect(controller.isBusy, isFalse);
    expect(scene.owners, isEmpty);
    expect(scene.releases, ['user', 'enemy']);
    controller.cancel();
    expect(scene.releases, ['user', 'enemy']);
  });
}
