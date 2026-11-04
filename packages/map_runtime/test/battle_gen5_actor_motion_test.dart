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
  test('source rotation step reaches its absolute angle and can be released', () {
    final scene = _Scene();
    final controller = scene.create();
    _start(controller, 'enemy', BattleGen5ActorMotionChannel.rotation,
        type: 1, x: 268431360, frames: 4, times: 0, mirrorX: true);
    controller.tick();
    expect(scene.poses['enemy']!.rotationFx32, 67107840);
    expect(controller.isChannelBusy('enemy', BattleGen5ActorMotionChannel.rotation), isTrue);
    controller.tick();
    controller.tick();
    controller.tick();
    expect(scene.poses['enemy']!.rotationFx32, 268431360);
    expect(controller.isBusy, isFalse);
    controller.cancel();
    expect(scene.poses, isEmpty);
  });

  test('a zero-frame relative position reaches its destination in one tick', () {
    final scene = _Scene();
    final controller = scene.create();
    _start(controller, 'user', BattleGen5ActorMotionChannel.position,
        type: 1, x: 0, y: -131072, frames: 0, times: 0);
    controller.tick();
    expect(scene.poses['user']!.offsetYFx32, -131072);
    expect(controller.isBusy, isFalse);
    controller.cancel();
    expect(scene.owners, isEmpty);
  });

  test('relative positions persist and return to the battle position', () {
    final scene = _Scene();
    final controller = scene.create();
    _start(controller, 'user', BattleGen5ActorMotionChannel.position,
        type: 1, x: 8192, y: 4096, frames: 2, wait: 1, times: 0);
    controller.tick();
    expect((scene.poses['user']!.offsetXFx32, scene.poses['user']!.offsetYFx32),
        (4096, 2048));
    controller.tick();
    expect(scene.poses['user']!.offsetXFx32, 4096);
    controller.tick();
    expect(controller.isBusy, isFalse);
    expect((scene.poses['user']!.offsetXFx32, scene.poses['user']!.offsetYFx32),
        (8192, 4096));
    _start(controller, 'user', BattleGen5ActorMotionChannel.position,
        type: 1, x: 4096, y: 0, frames: 2, times: 0, mirrorX: true);
    controller.tick();
    controller.tick();
    expect((scene.poses['user']!.offsetXFx32, scene.poses['user']!.offsetYFx32),
        (4096, 4096));
    _start(controller, 'user', BattleGen5ActorMotionChannel.position,
        type: 5, x: 0, y: 0, frames: 2, times: 0);
    controller.tick();
    expect((scene.poses['user']!.offsetXFx32, scene.poses['user']!.offsetYFx32),
        (2048, 2048));
    controller.tick();
    expect(controller.isBusy, isFalse);
    expect(scene.owners, isEmpty);
  });

  test('position swing starts at the held relative position and can be cancelled', () {
    final scene = _Scene();
    final controller = scene.create();
    _start(controller, 'user', BattleGen5ActorMotionChannel.position,
        type: 1, x: 8192, frames: 1, times: 0);
    controller.tick();
    _start(controller, 'user', BattleGen5ActorMotionChannel.position,
        type: 2, x: 4096, frames: 1);
    controller.tick();
    expect(scene.poses['user']!.offsetXFx32, 12288);
    controller.tick();
    expect(scene.poses['user']!.offsetXFx32, 8192);
    expect(controller.isBusy, isFalse);
    controller.cancel();
    expect(scene.owners, isEmpty);
    expect(scene.poses, isEmpty);
  });

  test('a return command replaces an active position movement', () {
    final scene = _Scene();
    final controller = scene.create();
    _start(controller, 'user', BattleGen5ActorMotionChannel.position,
        type: 1, x: 8192, frames: 4, times: 0);
    controller.tick();
    expect(scene.poses['user']!.offsetXFx32, 2048);
    _start(controller, 'user', BattleGen5ActorMotionChannel.position,
        type: 5, x: 0, y: 0, frames: 2, times: 0);
    controller.tick();
    expect(scene.poses['user']!.offsetXFx32, 1024);
    controller.tick();
    expect(controller.isBusy, isFalse);
    expect(scene.owners, isEmpty);
  });

  test('a position swing can replace another swing from its current position', () {
    final scene = _Scene();
    final controller = scene.create();
    _start(controller, 'user', BattleGen5ActorMotionChannel.position,
        type: 2, x: 4096, frames: 4);
    controller.tick();
    expect(scene.poses['user']!.offsetXFx32, 1024);
    _start(controller, 'user', BattleGen5ActorMotionChannel.position,
        type: 2, x: 2048, frames: 1);
    controller.tick();
    expect(scene.poses['user']!.offsetXFx32, 3072);
    controller.tick();
    expect(controller.isBusy, isFalse);
    expect(scene.poses['user']!.offsetXFx32, 1024);
    controller.cancel();
    expect(scene.owners, isEmpty);
  });

  test('relative position refuses out of range targets before claiming', () {
    final scene = _Scene();
    final controller = scene.create();
    expect(
      () => _start(controller, 'user', BattleGen5ActorMotionChannel.position,
          type: 1, x: 131073, frames: 1, times: 0),
      throwsFormatException,
    );
    expect(scene.claims, 0);
  });

  test('a circle composes with a held relative position', () {
    final scene = _Scene();
    final controller = scene.create();
    _start(controller, 'user', BattleGen5ActorMotionChannel.position,
        type: 1, x: 8192, frames: 1, times: 0);
    controller.tick();
    controller.startCircle(
      actor: 'user', mode: 3, start: 3,
      radius1Fx32: 4096, radius2Fx32: 4096,
      frames: 4, wait: 0, count: 1, turnWait: 0,
    );
    controller.tick();
    expect(scene.poses['user']!.offsetXFx32, 4096);
    expect(scene.poses['user']!.offsetZFx32, -4096);
    for (var i = 0; i < 4; i++) {
      controller.tick();
    }
    expect(controller.isBusy, isFalse);
    expect(scene.poses['user']!.offsetXFx32, 8192);
    expect(scene.poses['user']!.spatialOffset, isFalse);
    controller.cancel();
    expect(scene.owners, isEmpty);
  });

  test('position shake moves to both sides and returns to rest', () {
    final scene = _Scene();
    final controller = scene.create();
    _start(controller, 'user', BattleGen5ActorMotionChannel.position,
        type: 3, x: 4096, frames: 1);
    final offsets = <int>[];
    for (var i = 0; i < 3; i++) {
      controller.tick();
      offsets.add(scene.poses['user']!.offsetXFx32);
    }
    expect(offsets, [4096, 0, -4096]);
    controller.tick();
    expect(controller.isBusy, isFalse);
    expect(scene.owners, isEmpty);
  });

  test('scale step holds its destination until a later step restores it', () {
    final scene = _Scene();
    final controller = scene.create();
    _start(controller, 'user', BattleGen5ActorMotionChannel.scale,
        type: 1, x: 2048, y: 2048, frames: 4, wait: 1, times: 0);
    final scales = <int>[];
    for (var i = 0; i < 7; i++) {
      controller.tick();
      scales.add(scene.poses['user']!.scaleXFx32);
    }
    expect(scales, [3584, 3584, 3072, 3072, 2560, 2560, 2048]);
    expect(controller.isBusy, isFalse);
    expect(scene.owners, contains('user'));
    controller.tick();
    expect(scene.poses['user']!.scaleXFx32, 2048);
    _start(controller, 'user', BattleGen5ActorMotionChannel.scale,
        type: 1, x: 4096, y: 4096, frames: 2, times: 0);
    controller.tick();
    expect(scene.poses['user']!.scaleXFx32, 3072);
    controller.tick();
    expect(controller.isBusy, isFalse);
    expect(scene.owners, isEmpty);
  });

  test('scale shake starts from the held scale and cancellation restores it', () {
    final scene = _Scene();
    final controller = scene.create();
    _start(controller, 'user', BattleGen5ActorMotionChannel.scale,
        type: 1, x: 2048, y: 2048, frames: 1, times: 0);
    controller.tick();
    _start(controller, 'user', BattleGen5ActorMotionChannel.scale,
        type: 3, x: 512, y: 0, frames: 1);
    controller.tick();
    expect(scene.poses['user']!.scaleXFx32, 2560);
    controller.tick();
    expect(scene.poses['user']!.scaleXFx32, 2048);
    controller.tick();
    expect(scene.poses['user']!.scaleXFx32, 1536);
    controller.tick();
    expect(scene.poses['user']!.scaleXFx32, 2048);
    expect(controller.isBusy, isFalse);
    controller.cancel();
    expect(scene.owners, isEmpty);
    expect(scene.poses, isEmpty);
  });

  test('scale shake moves in both directions and returns to neutral', () {
    final scene = _Scene();
    final controller = scene.create();
    _start(controller, 'user', BattleGen5ActorMotionChannel.scale,
        type: 3, x: 1024, y: -1024, frames: 2);
    final sizes = <(int, int)>[];
    for (var i = 0; i < 7; i++) {
      controller.tick();
      final pose = scene.poses['user']!;
      sizes.add((pose.scaleXFx32, pose.scaleYFx32));
    }
    expect(sizes, [
      (4608, 3584), (5120, 3072), (4608, 3584), (4096, 4096),
      (3584, 4608), (3072, 5120), (3584, 4608),
    ]);
    controller.tick();
    expect(controller.isBusy, isFalse);
    expect(scene.owners, isEmpty);
  });

  test('scale shake rejects an excursion to zero before claiming', () {
    final scene = _Scene();
    final controller = scene.create();
    expect(
      () => _start(controller, 'user', BattleGen5ActorMotionChannel.scale,
          type: 3, x: 4096, frames: 2),
      throwsFormatException,
    );
    expect(scene.claims, 0);
  });

  test('circular motion preserves BW2 depth and returns the actor to rest', () {
    final scene = _Scene();
    final controller = scene.create();
    controller.startCircle(
      actor: 'user',
      mode: 3,
      start: 3,
      radius1Fx32: 4096,
      radius2Fx32: 4096,
      frames: 4,
      wait: 0,
      count: 1,
      turnWait: 0,
    );
    final offsets = <(int, int, int)>[];
    for (var i = 0; i < 4; i++) {
      controller.tick();
      final pose = scene.poses['user']!;
      offsets.add((pose.offsetXFx32, pose.offsetYFx32, pose.offsetZFx32));
      expect(pose.spatialOffset, isTrue);
    }
    expect(offsets, [
      (-4096, 0, -4096),
      (0, 0, -8192),
      (4096, 0, -4096),
      (0, 0, 0),
    ]);
    expect(controller.isChannelBusy('user', BattleGen5ActorMotionChannel.position), isTrue);
    controller.tick();
    expect(controller.isBusy, isFalse);
    expect(scene.owners, isEmpty);
  });

  test('circular motion mirrors the source starting position for the enemy', () {
    final scene = _Scene();
    final controller = scene.create();
    controller.startCircle(
      actor: 'enemy',
      mode: 3,
      start: 3,
      radius1Fx32: 4096,
      radius2Fx32: 4096,
      frames: 4,
      wait: 0,
      count: 1,
      turnWait: 0,
      mirror: true,
    );
    controller.tick();
    expect(scene.poses['enemy']!.offsetXFx32, 4096);
    expect(scene.poses['enemy']!.offsetZFx32, 4096);
    controller.cancel();
    expect(scene.owners, isEmpty);
  });

  test('invalid or conflicting circles do not displace the actor', () {
    final scene = _Scene();
    final controller = scene.create();
    expect(
      () => controller.startCircle(
        actor: 'user', mode: 3, start: 3,
        radius1Fx32: 4096, radius2Fx32: 4096,
        frames: 0, wait: 0, count: 1, turnWait: 0,
      ),
      throwsFormatException,
    );
    expect(scene.claims, 0);
    _start(controller, 'user', BattleGen5ActorMotionChannel.position);
    expect(
      () => controller.startCircle(
        actor: 'user', mode: 3, start: 3,
        radius1Fx32: 4096, radius2Fx32: 4096,
        frames: 4, wait: 0, count: 1, turnWait: 0,
      ),
      throwsStateError,
    );
    expect(controller.isBusy, isTrue);
    controller.cancel();
  });

  test('rotates the combatant in both directions and releases ownership', () {
    final scene = _Scene();
    final controller = scene.create();
    _start(controller, 'user', BattleGen5ActorMotionChannel.rotation,
        type: 3, x: 0xaaaa00, frames: 2);
    final angles = <int>[];
    for (var i = 0; i < 7; i++) {
      controller.tick();
      angles.add(scene.poses['user']!.rotationFx32);
    }
    expect(angles, [0x555500, 0xaaaa00, 0x555500, 0,
      -0x555500, -0xaaaa00, -0x555500]);
    controller.tick();
    expect(controller.isBusy, isFalse);
    expect(scene.owners, isEmpty);
  });

  test('source rotation swing returns from its peak to rest', () {
    final scene = _Scene();
    final controller = scene.create();
    _start(controller, 'user', BattleGen5ActorMotionChannel.rotation,
        type: 2, x: 0xaaaa00, frames: 2);
    final angles = <int>[];
    for (var i = 0; i < 3; i++) {
      controller.tick();
      angles.add(scene.poses['user']!.rotationFx32);
    }
    expect(angles, [0x555500, 0xaaaa00, 0x555500]);
    controller.tick();
    expect(controller.isBusy, isFalse);
    expect(scene.owners, isEmpty);
  });

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
      offsetZFx32: 0,
      spatialOffset: false,
      scaleXFx32: 5120,
      scaleYFx32: 3072,
      rotationFx32: 0,
    ));
    controller.tick();
    expect(scene.poses['user'], (
      offsetXFx32: 4096,
      offsetYFx32: 0,
      offsetZFx32: 0,
      spatialOffset: false,
      scaleXFx32: 4096,
      scaleYFx32: 4096,
      rotationFx32: 0,
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
          type: 4,
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
      _start(controller, 'user', BattleGen5ActorMotionChannel.scale);
      expect(
        () => _start(controller, 'user', BattleGen5ActorMotionChannel.scale),
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
