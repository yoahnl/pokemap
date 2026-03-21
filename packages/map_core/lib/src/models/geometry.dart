import 'package:freezed_annotation/freezed_annotation.dart';

part 'geometry.freezed.dart';
part 'geometry.g.dart';

@freezed
class GridPos with _$GridPos {
  const factory GridPos({
    required int x,
    required int y,
  }) = _GridPos;

  factory GridPos.fromJson(Map<String, dynamic> json) => _$GridPosFromJson(json);
}

@freezed
class GridSize with _$GridSize {
  const factory GridSize({
    required int width,
    required int height,
  }) = _GridSize;

  factory GridSize.fromJson(Map<String, dynamic> json) => _$GridSizeFromJson(json);
}

@freezed
class MapRect with _$MapRect {
  const factory MapRect({
    required GridPos pos,
    required GridSize size,
  }) = _MapRect;

  factory MapRect.fromJson(Map<String, dynamic> json) => _$MapRectFromJson(json);
}
