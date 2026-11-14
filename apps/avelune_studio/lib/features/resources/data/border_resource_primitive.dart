import 'package:map_core/map_core.dart';

final class BorderResourceFrame {
  const BorderResourceFrame({
    required this.absolutePath,
    required this.relativePath,
    required this.rect,
    this.durationMs,
    this.transparentColorArgb,
  });

  final String absolutePath;
  final String relativePath;
  final BorderPixelRect rect;
  final int? durationMs;
  final int? transparentColorArgb;
}

final class BorderResourcePrimitive {
  const BorderResourcePrimitive({required this.draft, required this.frames});

  final BorderPrimitiveDraft draft;
  final List<BorderResourceFrame> frames;
}
