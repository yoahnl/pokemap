import 'dart:math' as math;

import 'package:map_core/map_core.dart';

final class SceneWorldPictureFrame {
  const SceneWorldPictureFrame({
    required this.slotId,
    required this.mediaAssetId,
    required this.scope,
    required this.referenceWidth,
    required this.referenceHeight,
    required this.origin,
    required this.composition,
  });
  final int slotId;
  final String mediaAssetId;
  final SceneVisualScope scope;
  final int referenceWidth;
  final int referenceHeight;
  final ScenePictureOrigin origin;
  final PresentationVisualComposition composition;
}

final class SceneWorldFlashFrame {
  const SceneWorldFlashFrame(this.red, this.green, this.blue, this.alpha);
  final double red;
  final double green;
  final double blue;
  final double alpha;
}

final class SceneWorldPresentationFrame {
  const SceneWorldPresentationFrame({
    required this.pictures,
    required this.flashes,
    required this.shakeOffset,
    required this.shakeReferenceWidth,
    required this.shakeReferenceHeight,
  });
  final List<SceneWorldPictureFrame> pictures;
  final List<SceneWorldFlashFrame> flashes;
  final double shakeOffset;
  final int? shakeReferenceWidth;
  final int? shakeReferenceHeight;
}

final class SceneWorldPresentationCheckpoint {
  SceneWorldPresentationCheckpoint._(
    this._pictures,
    this._effects,
    this._owners,
  );
  final Map<int, _WorldPicture> _pictures;
  final List<_WorldEffect> _effects;
  final Map<int, Object?> _owners;
}

final class SceneWorldPresentationController {
  final _pictures = <int, _WorldPicture>{};
  final _effects = <_WorldEffect>[];
  final _owners = <int, Object?>{};

  SceneWorldPresentationFrame get frame {
    final pictures = _pictures.values.map((value) => value.current).toList()
      ..sort((a, b) => a.slotId.compareTo(b.slotId));
    final shake = _effects
        .where(
          (value) =>
              value.command.operation == SceneWorldPresentationOperation.shake,
        )
        .lastOrNull;
    return SceneWorldPresentationFrame(
      pictures: List.unmodifiable(pictures),
      flashes: List.unmodifiable(
        _effects
            .where(
              (value) =>
                  value.command.operation ==
                  SceneWorldPresentationOperation.flash,
            )
            .map(
              (value) => SceneWorldFlashFrame(
                value.command.red!,
                value.command.green!,
                value.command.blue!,
                value.command.alpha! * (1 - value.progress),
              ),
            ),
      ),
      shakeOffset: shake == null
          ? 0
          : shake.command.power! *
                math.sin(2 * math.pi * shake.command.speed! * shake.elapsed),
      shakeReferenceWidth: shake?.command.referenceWidth,
      shakeReferenceHeight: shake?.command.referenceHeight,
    );
  }

  bool apply(
    SceneWorldPresentationInteractiveCommand command, {
    Object? sceneOwner,
  }) {
    switch (command.operation) {
      case SceneWorldPresentationOperation.showPicture:
        final previous = _pictures[command.slotId!];
        if (previous != null &&
            (previous.current.scope != command.scope ||
                (command.scope == SceneVisualScope.scene &&
                    !identical(_owners[command.slotId!], sceneOwner)))) {
          return false;
        }
        _pictures[command.slotId!] = _WorldPicture(
          _picture(command, command.mediaAssetId!),
          null,
          0,
          0,
        );
        _owners[command.slotId!] = sceneOwner;
      case SceneWorldPresentationOperation.movePicture:
        final previous = _pictures[command.slotId!];
        if (previous == null ||
            previous.current.scope != command.scope ||
            (command.scope == SceneVisualScope.scene &&
                !identical(_owners[command.slotId!], sceneOwner))) {
          return false;
        }
        _pictures[command.slotId!] = _WorldPicture(
          _picture(command, previous.current.mediaAssetId),
          previous.current,
          command.durationMs / 1000,
          0,
        );
      case SceneWorldPresentationOperation.erasePicture:
        final previous = _pictures[command.slotId!];
        if (previous != null &&
            (previous.current.scope != command.scope ||
                (command.scope == SceneVisualScope.scene &&
                    !identical(_owners[command.slotId!], sceneOwner)))) {
          return false;
        }
        _pictures.remove(command.slotId!);
        _owners.remove(command.slotId!);
      case SceneWorldPresentationOperation.flash:
      case SceneWorldPresentationOperation.shake:
        _effects.removeWhere(
          (value) =>
              value.command.operation == command.operation &&
              value.command.scope == command.scope,
        );
        _effects.add(_WorldEffect(command, 0, sceneOwner));
    }
    return true;
  }

  void advance(double dt) {
    if (!dt.isFinite || dt <= 0) {
      return;
    }
    _pictures.updateAll((key, value) => value.advance(dt));
    for (var index = 0; index < _effects.length; index++) {
      final effect = _effects[index];
      _effects[index] = _WorldEffect(
        effect.command,
        effect.elapsed + dt,
        effect.owner,
      );
    }
    _effects.removeWhere((value) => value.progress >= 1);
  }

  SceneWorldPresentationCheckpoint captureCheckpoint() =>
      SceneWorldPresentationCheckpoint._(
        Map.of(_pictures),
        List.of(_effects),
        Map.of(_owners),
      );
  void restoreCheckpoint(SceneWorldPresentationCheckpoint checkpoint) {
    _pictures
      ..clear()
      ..addAll(checkpoint._pictures);
    _effects
      ..clear()
      ..addAll(checkpoint._effects);
    _owners
      ..clear()
      ..addAll(checkpoint._owners);
  }

  void clearScene({Object? owner}) {
    final removed = _pictures.entries
        .where(
          (entry) =>
              entry.value.current.scope == SceneVisualScope.scene &&
              (owner == null || identical(_owners[entry.key], owner)),
        )
        .map((entry) => entry.key)
        .toList();
    for (final slot in removed) {
      _pictures.remove(slot);
      _owners.remove(slot);
    }
    _effects.removeWhere(
      (value) =>
          value.command.scope == SceneVisualScope.scene &&
          (owner == null || identical(value.owner, owner)),
    );
  }

  void reset() {
    _pictures.clear();
    _effects.clear();
    _owners.clear();
  }

  SceneWorldPictureFrame _picture(
    SceneWorldPresentationInteractiveCommand command,
    String mediaAssetId,
  ) => SceneWorldPictureFrame(
    slotId: command.slotId!,
    mediaAssetId: mediaAssetId,
    scope: command.scope,
    referenceWidth: command.referenceWidth!,
    referenceHeight: command.referenceHeight!,
    origin: command.origin,
    composition: PresentationVisualComposition(
      translateX: command.x! / command.referenceWidth!,
      translateY: command.y! / command.referenceHeight!,
      scaleX: command.scaleX,
      scaleY: command.scaleY,
      opacity: command.opacity,
    ),
  );
}

final class _WorldPicture {
  const _WorldPicture(this.target, this.start, this.duration, this.elapsed);
  final SceneWorldPictureFrame target;
  final SceneWorldPictureFrame? start;
  final double duration;
  final double elapsed;
  _WorldPicture advance(double dt) => start == null || duration == 0
      ? this
      : _WorldPicture(
          target,
          start,
          duration,
          math.min(duration, elapsed + dt),
        );
  SceneWorldPictureFrame get current {
    final initial = start;
    if (initial == null || duration == 0 || elapsed >= duration) {
      return target;
    }
    final t = elapsed / duration;
    double lerp(double a, double b) => a + (b - a) * t;
    return SceneWorldPictureFrame(
      slotId: target.slotId,
      mediaAssetId: target.mediaAssetId,
      scope: target.scope,
      referenceWidth: target.referenceWidth,
      referenceHeight: target.referenceHeight,
      origin: target.origin,
      composition: PresentationVisualComposition(
        translateX: lerp(
          initial.composition.translateX,
          target.composition.translateX,
        ),
        translateY: lerp(
          initial.composition.translateY,
          target.composition.translateY,
        ),
        scaleX: lerp(initial.composition.scaleX, target.composition.scaleX),
        scaleY: lerp(initial.composition.scaleY, target.composition.scaleY),
        opacity: lerp(initial.composition.opacity, target.composition.opacity),
      ),
    );
  }
}

final class _WorldEffect {
  const _WorldEffect(this.command, this.elapsed, this.owner);
  final SceneWorldPresentationInteractiveCommand command;
  final double elapsed;
  final Object? owner;
  double get progress => (elapsed * 1000 / command.durationMs).clamp(0, 1);
}
