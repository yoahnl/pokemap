import 'package:flutter_riverpod/flutter_riverpod.dart';

const List<int> kEnvironmentMaskBrushSizes = [1, 3, 5, 7];
const int kDefaultEnvironmentMaskBrushSize = 1;

final environmentMaskBrushSizeProvider = StateProvider<int>(
  (ref) => kDefaultEnvironmentMaskBrushSize,
);

bool isValidEnvironmentMaskBrushSize(int size) {
  return kEnvironmentMaskBrushSizes.contains(size);
}
