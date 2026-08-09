import 'package:flutter_riverpod/flutter_riverpod.dart';

const List<int> kEnvironmentMaskBrushSizes = [1, 3, 5, 7];
const int kDefaultEnvironmentMaskBrushSize = 1;

final environmentMaskBrushSizeProvider =
    NotifierProvider<EnvironmentMaskBrushSizeController, int>(
  EnvironmentMaskBrushSizeController.new,
);

/// Owns the session-only brush size; validation remains in editor commands.
final class EnvironmentMaskBrushSizeController extends Notifier<int> {
  @override
  int build() => kDefaultEnvironmentMaskBrushSize;

  void setSize(int size) {
    if (state == size) return;
    state = size;
  }
}

bool isValidEnvironmentMaskBrushSize(int size) {
  return kEnvironmentMaskBrushSizes.contains(size);
}
