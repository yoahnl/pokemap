import 'package:freezed_annotation/freezed_annotation.dart';

part 'geometry.freezed.dart';
part 'geometry.g.dart';

@freezed
abstract class PixelOffset with _$PixelOffset {
  const factory PixelOffset({
    @JsonKey(fromJson: _pixelIntegerFromJson) required int x,
    @JsonKey(fromJson: _pixelIntegerFromJson) required int y,
  }) = _PixelOffset;

  factory PixelOffset.fromJson(Map<String, dynamic> json) =>
      _$PixelOffsetFromJson(json);
}

@freezed
abstract class PixelSize with _$PixelSize {
  const factory PixelSize({
    @JsonKey(fromJson: _pixelIntegerFromJson) required int width,
    @JsonKey(fromJson: _pixelIntegerFromJson) required int height,
  }) = _PixelSize;

  factory PixelSize.fromJson(Map<String, dynamic> json) =>
      _$PixelSizeFromJson(json);
}

int _pixelIntegerFromJson(Object? value) {
  if (value is! int || value < -9007199254740991 || value > 9007199254740991) {
    throw FormatException(
      'Pixel geometry requires exactly representable integers',
      value,
    );
  }
  return value;
}

@freezed
abstract class GridPos with _$GridPos {
  const factory GridPos({
    required int x,
    required int y,
  }) = _GridPos;

  factory GridPos.fromJson(Map<String, dynamic> json) =>
      _$GridPosFromJson(json);
}

@freezed
abstract class GridSize with _$GridSize {
  const factory GridSize({
    required int width,
    required int height,
  }) = _GridSize;

  factory GridSize.fromJson(Map<String, dynamic> json) =>
      _$GridSizeFromJson(json);
}

@freezed
abstract class MapRect with _$MapRect {
  const factory MapRect({
    required GridPos pos,
    required GridSize size,
  }) = _MapRect;

  factory MapRect.fromJson(Map<String, dynamic> json) =>
      _$MapRectFromJson(json);
}
