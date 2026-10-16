import 'package:meta/meta.dart';

import '../exceptions/map_exceptions.dart';
import 'border_ground_footprint.dart';

@immutable
final class BorderGroundSurface {
  BorderGroundSurface({
    required this.sourceSmartTilePresetId,
    required this.materialId,
    required this.height,
    this.gradientX = 0,
    this.gradientZ = 0,
    required List<BorderGroundFootprint> footprints,
  }) : footprints = List.unmodifiable(footprints) {
    if (sourceSmartTilePresetId.trim().isEmpty ||
        materialId.trim().isEmpty ||
        !height.isFinite ||
        !gradientX.isFinite ||
        !gradientZ.isFinite ||
        footprints.isEmpty ||
        footprints.length > 8) {
      throw const ValidationException(
        'Ground surfaces require a terrain material, a finite height and 1 to 8 convex footprints',
      );
    }
  }

  final String sourceSmartTilePresetId;
  final String materialId;
  final double height;
  final double gradientX;
  final double gradientZ;
  final List<BorderGroundFootprint> footprints;

  @override
  bool operator ==(Object other) =>
      other is BorderGroundSurface &&
      sourceSmartTilePresetId == other.sourceSmartTilePresetId &&
      materialId == other.materialId &&
      height == other.height &&
      gradientX == other.gradientX &&
      gradientZ == other.gradientZ &&
      footprints.length == other.footprints.length &&
      Iterable<int>.generate(
        footprints.length,
      ).every((index) => footprints[index] == other.footprints[index]);

  @override
  int get hashCode => Object.hash(
    sourceSmartTilePresetId,
    materialId,
    height,
    gradientX,
    gradientZ,
    Object.hashAll(footprints),
  );
}

List<BorderGroundSurface> validatedBorderGroundSurfaces(
  List<BorderGroundSurface> surfaces,
  String? modelId,
) {
  if (surfaces.length > 8 || (surfaces.isNotEmpty && modelId == null)) {
    throw const ValidationException(
      'At most 8 ground surfaces require a spatial model source',
    );
  }
  return List.unmodifiable(surfaces);
}
