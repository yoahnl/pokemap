import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

const int kRuntimeMaxTilesetChunkHeight = 4096;

@immutable
final class RuntimeTilesetChunk {
  const RuntimeTilesetChunk({
    required this.top,
    required this.height,
    required this.width,
  });

  final int top;
  final int height;
  final int width;

  int get bottom => top + height;
}

@immutable
final class RuntimeTilesetDrawSlice {
  const RuntimeTilesetDrawSlice({
    required this.chunkIndex,
    required this.sourceRect,
    required this.destinationRect,
  });

  final int chunkIndex;
  final ui.Rect sourceRect;
  final ui.Rect destinationRect;
}

List<RuntimeTilesetChunk> buildRuntimeTilesetChunks({
  required int totalWidth,
  required int totalHeight,
  int maxChunkHeight = kRuntimeMaxTilesetChunkHeight,
}) {
  if (totalWidth <= 0 || totalHeight <= 0 || maxChunkHeight <= 0) {
    return const <RuntimeTilesetChunk>[];
  }
  final chunks = <RuntimeTilesetChunk>[];
  var top = 0;
  while (top < totalHeight) {
    final remaining = totalHeight - top;
    final height = remaining > maxChunkHeight ? maxChunkHeight : remaining;
    if (height <= 0) {
      break;
    }
    chunks.add(
      RuntimeTilesetChunk(
        top: top,
        height: height,
        width: totalWidth,
      ),
    );
    top += height;
  }
  return chunks;
}

List<RuntimeTilesetDrawSlice> resolveRuntimeTilesetDrawSlices({
  required ui.Rect sourceRect,
  required ui.Rect destinationRect,
  required List<RuntimeTilesetChunk> chunks,
}) {
  if (chunks.isEmpty ||
      sourceRect.left < 0 ||
      sourceRect.top < 0 ||
      sourceRect.width <= 0 ||
      sourceRect.height <= 0 ||
      destinationRect.width <= 0 ||
      destinationRect.height <= 0) {
    return const <RuntimeTilesetDrawSlice>[];
  }

  final atlasWidth = chunks.first.width.toDouble();
  final atlasHeight = chunks.last.bottom.toDouble();
  if (sourceRect.right > atlasWidth || sourceRect.bottom > atlasHeight) {
    return const <RuntimeTilesetDrawSlice>[];
  }

  final slices = <RuntimeTilesetDrawSlice>[];
  for (var index = 0; index < chunks.length; index++) {
    final chunk = chunks[index];
    final chunkTop = chunk.top.toDouble();
    final chunkBottom = chunk.bottom.toDouble();
    final overlapTop = sourceRect.top > chunkTop ? sourceRect.top : chunkTop;
    final overlapBottom =
        sourceRect.bottom < chunkBottom ? sourceRect.bottom : chunkBottom;
    if (overlapBottom <= overlapTop) {
      continue;
    }

    final sliceHeight = overlapBottom - overlapTop;
    final sourceYOffset = overlapTop - sourceRect.top;
    final destinationYOffset =
        (sourceYOffset / sourceRect.height) * destinationRect.height;
    final destinationHeight =
        (sliceHeight / sourceRect.height) * destinationRect.height;

    slices.add(
      RuntimeTilesetDrawSlice(
        chunkIndex: index,
        sourceRect: ui.Rect.fromLTWH(
          sourceRect.left,
          overlapTop - chunkTop,
          sourceRect.width,
          sliceHeight,
        ),
        destinationRect: ui.Rect.fromLTWH(
          destinationRect.left,
          destinationRect.top + destinationYOffset,
          destinationRect.width,
          destinationHeight,
        ),
      ),
    );
  }
  return slices;
}

@immutable
final class RuntimeTilesetImage {
  RuntimeTilesetImage({
    required List<ui.Image> images,
    required List<RuntimeTilesetChunk> chunks,
    required this.width,
    required this.height,
  })  : _images = List<ui.Image>.unmodifiable(images),
        chunks = List<RuntimeTilesetChunk>.unmodifiable(chunks) {
    assert(_images.length == this.chunks.length);
  }

  final List<ui.Image> _images;
  final List<RuntimeTilesetChunk> chunks;
  final int width;
  final int height;

  @visibleForTesting
  int get chunkCount => chunks.length;

  bool containsSourceRect(ui.Rect sourceRect) {
    return sourceRect.left >= 0 &&
        sourceRect.top >= 0 &&
        sourceRect.width > 0 &&
        sourceRect.height > 0 &&
        sourceRect.right <= width &&
        sourceRect.bottom <= height;
  }

  void drawImageRect(
    ui.Canvas canvas,
    ui.Rect sourceRect,
    ui.Rect destinationRect,
    ui.Paint paint,
  ) {
    final slices = resolveRuntimeTilesetDrawSlices(
      sourceRect: sourceRect,
      destinationRect: destinationRect,
      chunks: chunks,
    );
    for (final slice in slices) {
      canvas.drawImageRect(
        _images[slice.chunkIndex],
        slice.sourceRect,
        slice.destinationRect,
        paint,
      );
    }
  }
}
