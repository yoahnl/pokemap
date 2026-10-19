import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';

@immutable
final class SmartTilePatternRepeatAxis {
  factory SmartTilePatternRepeatAxis({
    required int repeatStart,
    required int repeatLength,
    int minimumRepeats = 1,
    int? maximumRepeats,
  }) {
    if (repeatStart < 0 ||
        repeatStart > 64 ||
        repeatLength < 1 ||
        repeatLength > 64 ||
        minimumRepeats < 0 ||
        minimumRepeats > 65536 ||
        (maximumRepeats != null &&
            (maximumRepeats < minimumRepeats || maximumRepeats > 65536))) {
      throw const ValidationException(
        'Invalid native construction repeat interval.',
        code: 'smart_tile.pattern.construction_axis_invalid',
      );
    }
    return SmartTilePatternRepeatAxis._(
      repeatStart,
      repeatLength,
      minimumRepeats,
      maximumRepeats,
    );
  }

  const SmartTilePatternRepeatAxis._(
    this.repeatStart,
    this.repeatLength,
    this.minimumRepeats,
    this.maximumRepeats,
  );

  factory SmartTilePatternRepeatAxis.fromJson(Map<String, dynamic> json) {
    _requireKeys(json, const {
      'repeatStart',
      'repeatLength',
      'minimumRepeats',
      'maximumRepeats',
    });
    return SmartTilePatternRepeatAxis(
      repeatStart: _integer(json, 'repeatStart'),
      repeatLength: _integer(json, 'repeatLength'),
      minimumRepeats: json.containsKey('minimumRepeats')
          ? _integer(json, 'minimumRepeats')
          : 1,
      maximumRepeats: json['maximumRepeats'] == null
          ? null
          : _integer(json, 'maximumRepeats'),
    );
  }

  final int repeatStart;
  final int repeatLength;
  final int minimumRepeats;
  final int? maximumRepeats;

  void validateSourceLength(int sourceLength) {
    if (repeatStart + repeatLength > sourceLength ||
        minimumLength(sourceLength) <= 0) {
      throw const ValidationException(
        'Native construction repeat interval exceeds its source or has an empty minimum footprint.',
        code: 'smart_tile.pattern.construction_axis_invalid',
      );
    }
  }

  int minimumLength(int sourceLength) =>
      sourceLength - repeatLength + repeatLength * minimumRepeats;

  int repeatsForLength(int sourceLength, int outputLength) {
    validateSourceLength(sourceLength);
    final repeated = outputLength - (sourceLength - repeatLength);
    final count = repeated ~/ repeatLength;
    if (outputLength <= 0 ||
        repeated < 0 ||
        repeated % repeatLength != 0 ||
        count < minimumRepeats ||
        (maximumRepeats != null && count > maximumRepeats!)) {
      throw ValidationException(
        'Native construction length $outputLength must preserve fixed ends and whole $repeatLength-cell periods.',
        code: 'smart_tile.pattern.construction_size_invalid',
      );
    }
    return count;
  }

  int sourceIndex({
    required int position,
    required int sourceLength,
    required int outputLength,
  }) {
    final count = repeatsForLength(sourceLength, outputLength);
    if (position < 0 || position >= outputLength) {
      throw RangeError.range(position, 0, outputLength - 1, 'position');
    }
    if (position < repeatStart) return position;
    final repeatedEnd = repeatStart + count * repeatLength;
    if (position < repeatedEnd) {
      return repeatStart + (position - repeatStart) % repeatLength;
    }
    return repeatStart + repeatLength + position - repeatedEnd;
  }

  Map<String, dynamic> toJson() => {
    'repeatStart': repeatStart,
    'repeatLength': repeatLength,
    'minimumRepeats': minimumRepeats,
    if (maximumRepeats != null) 'maximumRepeats': maximumRepeats,
  };

  @override
  bool operator ==(Object other) =>
      other is SmartTilePatternRepeatAxis &&
      repeatStart == other.repeatStart &&
      repeatLength == other.repeatLength &&
      minimumRepeats == other.minimumRepeats &&
      maximumRepeats == other.maximumRepeats;

  @override
  int get hashCode =>
      Object.hash(repeatStart, repeatLength, minimumRepeats, maximumRepeats);
}

@immutable
final class SmartTilePatternConstruction {
  factory SmartTilePatternConstruction({
    SmartTilePatternRepeatAxis? x,
    SmartTilePatternRepeatAxis? y,
  }) {
    if (x == null && y == null) {
      throw const ValidationException(
        'Native construction requires at least one repeated axis.',
        code: 'smart_tile.pattern.construction_axis_missing',
      );
    }
    return SmartTilePatternConstruction._(x, y);
  }

  const SmartTilePatternConstruction._(this.x, this.y);

  factory SmartTilePatternConstruction.fromJson(Map<String, dynamic> json) {
    _requireKeys(json, const {'x', 'y'});
    SmartTilePatternRepeatAxis? axis(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! Map<String, dynamic>) {
        throw FormatException(
          'Native construction $key must be an axis object.',
        );
      }
      return SmartTilePatternRepeatAxis.fromJson(value);
    }

    return SmartTilePatternConstruction(x: axis('x'), y: axis('y'));
  }

  final SmartTilePatternRepeatAxis? x;
  final SmartTilePatternRepeatAxis? y;

  void validateSource({required int width, required int height}) {
    x?.validateSourceLength(width);
    y?.validateSourceLength(height);
  }

  void validateSize({
    required int sourceWidth,
    required int sourceHeight,
    required int width,
    required int height,
  }) {
    validateSource(width: sourceWidth, height: sourceHeight);
    if ((x == null && width != sourceWidth) ||
        (y == null && height != sourceHeight)) {
      throw ValidationException(
        'Native construction requires its fixed ${x == null ? '$sourceWidth-cell width' : '$sourceHeight-cell height'}.',
        code: 'smart_tile.pattern.construction_size_invalid',
      );
    }
    x?.repeatsForLength(sourceWidth, width);
    y?.repeatsForLength(sourceHeight, height);
  }

  Map<String, dynamic> toJson() => {
    if (x != null) 'x': x!.toJson(),
    if (y != null) 'y': y!.toJson(),
  };

  @override
  bool operator ==(Object other) =>
      other is SmartTilePatternConstruction && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

int _integer(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('Native construction $key must be an exact integer.');
  }
  return value;
}

void _requireKeys(Map<String, dynamic> json, Set<String> allowed) {
  if (json.keys.any((key) => !allowed.contains(key))) {
    throw const FormatException('Unknown native construction field.');
  }
}
