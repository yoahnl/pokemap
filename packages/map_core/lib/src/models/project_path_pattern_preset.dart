import 'path_center_pattern.dart';
import 'tileset_transparent_color.dart';

/// Project-level path preset extension whose center can be a local pattern.
final class ProjectPathPatternPreset {
  factory ProjectPathPatternPreset({
    required String id,
    required String name,
    required String basePathPresetId,
    required PathCenterPattern centerPattern,
    TilesetTransparentColor? transparentColor,
    String? categoryId,
    int sortOrder = 0,
  }) {
    _validateNonBlank(id, 'id');
    _validateNonBlank(name, 'name');
    _validateNonBlank(basePathPresetId, 'basePathPresetId');

    return ProjectPathPatternPreset._(
      id: id,
      name: name,
      basePathPresetId: basePathPresetId,
      centerPattern: centerPattern,
      transparentColor: transparentColor,
      categoryId: categoryId,
      sortOrder: sortOrder,
    );
  }

  const ProjectPathPatternPreset._({
    required this.id,
    required this.name,
    required this.basePathPresetId,
    required this.centerPattern,
    required this.transparentColor,
    required this.categoryId,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String basePathPresetId;
  final PathCenterPattern centerPattern;
  final TilesetTransparentColor? transparentColor;
  final String? categoryId;
  final int sortOrder;

  bool get hasTransparentColor => transparentColor != null;

  bool get usesSingleCellCenter => centerPattern.isSingleCell;

  bool get usesMultiCellCenter => centerPattern.isMultiCell;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProjectPathPatternPreset &&
            id == other.id &&
            name == other.name &&
            basePathPresetId == other.basePathPresetId &&
            centerPattern == other.centerPattern &&
            transparentColor == other.transparentColor &&
            categoryId == other.categoryId &&
            sortOrder == other.sortOrder;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      basePathPresetId,
      centerPattern,
      transparentColor,
      categoryId,
      sortOrder,
    );
  }
}

void _validateNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(
      value,
      name,
      'ProjectPathPatternPreset $name must not be blank.',
    );
  }
}
