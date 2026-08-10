import 'dart:typed_data';

import 'package:map_core/map_core.dart';

final class CharacterAnimationSlicingException implements Exception {
  const CharacterAnimationSlicingException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() => 'CharacterAnimationSlicingException($code): $message';
}

final class CharacterAnimationSourceDimensions {
  const CharacterAnimationSourceDimensions(this.width, this.height);

  factory CharacterAnimationSourceDimensions.fromPng(Uint8List bytes) {
    const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
    final valid =
        bytes.length >= 24 &&
        List<int>.generate(
          8,
          (index) => index,
        ).every((index) => bytes[index] == signature[index]) &&
        bytes[12] == 73 &&
        bytes[13] == 72 &&
        bytes[14] == 68 &&
        bytes[15] == 82;
    if (!valid) {
      throw const CharacterAnimationSlicingException(
        'source_not_png',
        'La source doit être un fichier PNG valide.',
      );
    }
    final dimensions = CharacterAnimationSourceDimensions(
      _uint32(bytes, 16),
      _uint32(bytes, 20),
    );
    if (dimensions.width < 1 ||
        dimensions.height < 1 ||
        dimensions.width > 16384 ||
        dimensions.height > 16384) {
      throw const CharacterAnimationSlicingException(
        'source_dimensions_invalid',
        'Les dimensions doivent être comprises entre 1 et 16384 pixels.',
      );
    }
    return dimensions;
  }

  final int width;
  final int height;

  @override
  bool operator ==(Object other) {
    return other is CharacterAnimationSourceDimensions &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(width, height);
}

abstract final class CharacterAnimationSourceSlicing {
  static List<CharacterAnimationFrame> grid({
    required CharacterAnimationSourceDimensions dimensions,
    required int columns,
    required int rows,
    int durationMs = 150,
  }) {
    if (columns < 1 || rows < 1) {
      throw const CharacterAnimationSlicingException(
        'grid_invalid',
        'La grille doit contenir au moins une ligne et une colonne.',
      );
    }
    if (dimensions.width % columns != 0 || dimensions.height % rows != 0) {
      throw const CharacterAnimationSlicingException(
        'grid_not_divisible',
        'La grille doit diviser exactement les dimensions de la source.',
      );
    }
    if (durationMs <= 0) {
      throw const CharacterAnimationSlicingException(
        'duration_invalid',
        'La durée doit être supérieure à 0 ms.',
      );
    }
    final frameWidth = dimensions.width ~/ columns;
    final frameHeight = dimensions.height ~/ rows;
    return List<CharacterAnimationFrame>.unmodifiable(<CharacterAnimationFrame>[
      for (var row = 0; row < rows; row++)
        for (var column = 0; column < columns; column++)
          CharacterAnimationFrame(
            source: TilesetSourceRect(
              x: column * frameWidth,
              y: row * frameHeight,
              width: frameWidth,
              height: frameHeight,
            ),
            durationMs: durationMs,
          ),
    ]);
  }

  static void validateFrame(
    CharacterAnimationFrame frame,
    CharacterAnimationSourceDimensions dimensions,
  ) {
    final source = frame.source;
    if (frame.durationMs <= 0) {
      throw const CharacterAnimationSlicingException(
        'duration_invalid',
        'La durée doit être supérieure à 0 ms.',
      );
    }
    if (source.x < 0 ||
        source.y < 0 ||
        source.width <= 0 ||
        source.height <= 0 ||
        source.x + source.width > dimensions.width ||
        source.y + source.height > dimensions.height) {
      throw const CharacterAnimationSlicingException(
        'frame_out_of_bounds',
        'La frame doit rester entièrement dans la source.',
      );
    }
  }

  static void validateFrames(
    Iterable<CharacterAnimationFrame> frames,
    CharacterAnimationSourceDimensions dimensions,
  ) {
    for (final frame in frames) {
      validateFrame(frame, dimensions);
    }
  }
}

abstract final class CharacterAnimationTimelineEditing {
  static List<CharacterAnimationFrame> add(
    List<CharacterAnimationFrame> frames, {
    required CharacterAnimationFrame frame,
    required CharacterAnimationSourceDimensions dimensions,
  }) {
    return _validated(<CharacterAnimationFrame>[...frames, frame], dimensions);
  }

  static List<CharacterAnimationFrame> duplicate(
    List<CharacterAnimationFrame> frames, {
    required int index,
    required CharacterAnimationSourceDimensions dimensions,
  }) {
    _requireIndex(index, frames.length);
    final updated = frames.toList()..insert(index + 1, frames[index]);
    return _validated(updated, dimensions);
  }

  static List<CharacterAnimationFrame> delete(
    List<CharacterAnimationFrame> frames, {
    required int index,
    required CharacterAnimationSourceDimensions dimensions,
  }) {
    _requireIndex(index, frames.length);
    final updated = frames.toList()..removeAt(index);
    return _validated(updated, dimensions);
  }

  static List<CharacterAnimationFrame> reorder(
    List<CharacterAnimationFrame> frames, {
    required int fromIndex,
    required int toIndex,
    required CharacterAnimationSourceDimensions dimensions,
  }) {
    _requireIndex(fromIndex, frames.length);
    _requireIndex(toIndex, frames.length);
    final updated = frames.toList();
    final frame = updated.removeAt(fromIndex);
    updated.insert(toIndex, frame);
    return _validated(updated, dimensions);
  }

  static List<CharacterAnimationFrame> updateDuration(
    List<CharacterAnimationFrame> frames, {
    required int index,
    required int durationMs,
    required CharacterAnimationSourceDimensions dimensions,
  }) {
    _requireIndex(index, frames.length);
    final updated = frames.toList()
      ..[index] = frames[index].copyWith(durationMs: durationMs);
    return _validated(updated, dimensions);
  }

  static List<CharacterAnimationFrame> _validated(
    List<CharacterAnimationFrame> frames,
    CharacterAnimationSourceDimensions dimensions,
  ) {
    CharacterAnimationSourceSlicing.validateFrames(frames, dimensions);
    return List<CharacterAnimationFrame>.unmodifiable(frames);
  }

  static void _requireIndex(int index, int length) {
    if (index >= 0 && index < length) return;
    throw const CharacterAnimationSlicingException(
      'frame_index_invalid',
      'La frame sélectionnée n’existe plus.',
    );
  }
}

int _uint32(Uint8List bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}
