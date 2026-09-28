import 'package:map_core/map_core_domain.dart';

typedef CharacterClipKey = (CharacterAnimationState, EntityFacing);

final class CharacterStudioDraft {
  CharacterStudioDraft(this.saved)
    : name = saved.name,
      frameWidth = saved.frameWidth,
      frameHeight = saved.frameHeight;

  ProjectCharacterEntry saved;
  String name;
  int frameWidth;
  int frameHeight;
  final Map<CharacterClipKey, List<CharacterAnimationFrame?>> _frames = {};
  final Set<CharacterClipKey> _atlasAssignments = {};

  bool get dirty =>
      name != saved.name ||
      frameWidth != saved.frameWidth ||
      frameHeight != saved.frameHeight ||
      _frames.keys.any((key) => clipChanged(key));

  List<CharacterAnimationFrame?> framesFor(CharacterClipKey key) =>
      List.unmodifiable(
        _frames[key] ??
            List<CharacterAnimationFrame?>.from(
              saved.animations
                      .where(
                        (clip) =>
                            clip.state == key.$1 && clip.direction == key.$2,
                      )
                      .firstOrNull
                      ?.frames ??
                  const <CharacterAnimationFrame>[],
            ),
      );

  String? sourceAssetIdFor(CharacterClipKey key) =>
      _atlasAssignments.contains(key)
      ? null
      : saved.animations
            .where((clip) => clip.state == key.$1 && clip.direction == key.$2)
            .firstOrNull
            ?.sourceAssetId;

  bool clipChanged(CharacterClipKey key) {
    final edited = _frames[key];
    if (edited == null) return false;
    final original = saved.animations
        .where((clip) => clip.state == key.$1 && clip.direction == key.$2)
        .firstOrNull;
    if (_atlasAssignments.contains(key) && original?.sourceAssetId != null) {
      return true;
    }
    final originalFrames = original?.frames;
    if (originalFrames == null) return edited.any((frame) => frame != null);
    if (edited.length != originalFrames.length) return true;
    for (var i = 0; i < edited.length; i++) {
      if (edited[i] != originalFrames[i]) return true;
    }
    return false;
  }

  void assign(
    CharacterClipKey key,
    int index,
    TilesetSourceRect source, {
    int durationMs = 150,
  }) {
    if (index < 0 || index > 23) throw RangeError.range(index, 0, 23);
    final frames = _frames.putIfAbsent(
      key,
      () => List<CharacterAnimationFrame?>.from(framesFor(key)),
    );
    while (frames.length <= index) {
      frames.add(null);
    }
    frames[index] = CharacterAnimationFrame(
      source: source,
      durationMs: durationMs,
    );
    _atlasAssignments.add(key);
  }

  void clear(CharacterClipKey key, int index) {
    final frames = _frames.putIfAbsent(
      key,
      () => List<CharacterAnimationFrame?>.from(framesFor(key)),
    );
    if (index >= frames.length) return;
    frames[index] = null;
    _atlasAssignments.add(key);
    while (frames.isNotEmpty && frames.last == null) {
      frames.removeLast();
    }
  }

  bool assignClassicSheet(
    CharacterAnimationState state,
    ProjectRegularAtlasTilesetSource source, {
    required int frameWidth,
    required int frameHeight,
  }) {
    if (frameWidth <= 0 ||
        frameHeight <= 0 ||
        source.marginX != 0 ||
        source.marginY != 0 ||
        source.spacingX != 0 ||
        source.spacingY != 0 ||
        frameWidth * 3 > source.pixelWidth ||
        frameHeight * 4 > source.pixelHeight) {
      return false;
    }
    const directions = [
      EntityFacing.south,
      EntityFacing.west,
      EntityFacing.east,
      EntityFacing.north,
    ];
    for (var row = 0; row < directions.length; row++) {
      final key = (state, directions[row]);
      _atlasAssignments.add(key);
      _frames[key] = [
        for (var column = 0; column < 3; column++)
          CharacterAnimationFrame(
            source: TilesetSourceRect(x: column, y: row),
            durationMs: 150,
          ),
      ];
    }
    return true;
  }

  String? problemFor(CharacterClipKey key) {
    final frames = framesFor(key);
    if (frames.any((frame) => frame == null)) {
      return 'Complétez les poses précédentes avant d’enregistrer cette direction.';
    }
    return null;
  }

  List<CharacterAnimationFrame> completeFrames(CharacterClipKey key) {
    final problem = problemFor(key);
    if (problem != null) throw StateError(problem);
    return framesFor(key).cast<CharacterAnimationFrame>();
  }

  ProjectCharacterEntry get previewCharacter {
    final animations = saved.animations.toList();
    for (final key in changedClips) {
      if (problemFor(key) != null) continue;
      final frames = completeFrames(key);
      final index = animations.indexWhere(
        (clip) => clip.state == key.$1 && clip.direction == key.$2,
      );
      if (frames.isEmpty) {
        if (index >= 0) animations.removeAt(index);
        continue;
      }
      if (index < 0) {
        animations.add(
          CharacterAnimation(state: key.$1, direction: key.$2, frames: frames),
        );
      } else {
        animations[index] = CharacterAnimation(
          state: key.$1,
          direction: key.$2,
          frames: frames,
          loop: animations[index].loop,
        );
      }
    }
    return saved.copyWith(
      name: name,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
      animations: animations,
    );
  }

  Iterable<CharacterClipKey> get changedClips =>
      _frames.keys.where(clipChanged);

  void accept(ProjectCharacterEntry persisted) {
    final currentName = name;
    final pending = {
      for (final key in changedClips)
        key: List<CharacterAnimationFrame?>.from(framesFor(key)),
    };
    saved = persisted;
    if (currentName == persisted.name) name = persisted.name;
    _frames
      ..clear()
      ..addAll(pending);
    for (final key in pending.keys) {
      if (!clipChanged(key)) {
        _frames.remove(key);
        _atlasAssignments.remove(key);
      }
    }
  }

  void discard() {
    name = saved.name;
    frameWidth = saved.frameWidth;
    frameHeight = saved.frameHeight;
    _frames.clear();
    _atlasAssignments.clear();
  }
}
