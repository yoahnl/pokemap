import 'package:map_core/map_core.dart';

final class EnvironmentPresetTilesetCompatibility {
  factory EnvironmentPresetTilesetCompatibility({
    required String? sourceTilesetId,
    required List<String> tilesetIds,
    required List<String> compatiblePaletteElementIds,
    required List<String> incompatiblePaletteElementIds,
    required List<String> missingPaletteElementIds,
    required List<String> unknownTilesetElementIds,
    required List<ProjectElementEntry> availableCompatibleElements,
  }) {
    return EnvironmentPresetTilesetCompatibility._(
      sourceTilesetId: sourceTilesetId,
      tilesetIds: List<String>.unmodifiable(tilesetIds),
      compatiblePaletteElementIds:
          List<String>.unmodifiable(compatiblePaletteElementIds),
      incompatiblePaletteElementIds:
          List<String>.unmodifiable(incompatiblePaletteElementIds),
      missingPaletteElementIds: List<String>.unmodifiable(
        missingPaletteElementIds,
      ),
      unknownTilesetElementIds: List<String>.unmodifiable(
        unknownTilesetElementIds,
      ),
      availableCompatibleElements: List<ProjectElementEntry>.unmodifiable(
        availableCompatibleElements,
      ),
    );
  }

  const EnvironmentPresetTilesetCompatibility._({
    required this.sourceTilesetId,
    required this.tilesetIds,
    required this.compatiblePaletteElementIds,
    required this.incompatiblePaletteElementIds,
    required this.missingPaletteElementIds,
    required this.unknownTilesetElementIds,
    required this.availableCompatibleElements,
  });

  final String? sourceTilesetId;
  final List<String> tilesetIds;
  final List<String> compatiblePaletteElementIds;
  final List<String> incompatiblePaletteElementIds;
  final List<String> missingPaletteElementIds;
  final List<String> unknownTilesetElementIds;
  final List<ProjectElementEntry> availableCompatibleElements;

  bool get hasSourceTileset => sourceTilesetId != null;

  bool get hasMixedTilesets => tilesetIds.length > 1;
}

String? resolveEnvironmentPresetElementTilesetId(ProjectElementEntry element) {
  if (element.frames.isNotEmpty) {
    final frameTilesetId = element.frames.first.tilesetId.trim();
    if (frameTilesetId.isNotEmpty) {
      return frameTilesetId;
    }
  }
  final elementTilesetId = element.tilesetId.trim();
  return elementTilesetId.isEmpty ? null : elementTilesetId;
}

EnvironmentPresetTilesetCompatibility
    buildEnvironmentPresetTilesetCompatibility({
  required Iterable<String> paletteElementIds,
  required Iterable<ProjectElementEntry> projectElements,
}) {
  final elements = projectElements.toList(growable: false);
  final elementsById = <String, ProjectElementEntry>{};
  for (final element in elements) {
    final id = element.id.trim();
    if (id.isNotEmpty) {
      elementsById[id] = element;
    }
  }

  String? sourceTilesetId;
  final tilesetIds = <String>[];
  final seenTilesetIds = <String>{};
  final compatiblePaletteElementIds = <String>[];
  final incompatiblePaletteElementIds = <String>[];
  final missingPaletteElementIds = <String>[];
  final unknownTilesetElementIds = <String>[];

  for (final rawElementId in paletteElementIds) {
    final elementId = rawElementId.trim();
    if (elementId.isEmpty) {
      continue;
    }
    final element = elementsById[elementId];
    if (element == null) {
      missingPaletteElementIds.add(elementId);
      continue;
    }
    final tilesetId = resolveEnvironmentPresetElementTilesetId(element);
    if (tilesetId == null) {
      unknownTilesetElementIds.add(elementId);
      continue;
    }
    sourceTilesetId ??= tilesetId;
    if (seenTilesetIds.add(tilesetId)) {
      tilesetIds.add(tilesetId);
    }
    if (tilesetId == sourceTilesetId) {
      compatiblePaletteElementIds.add(elementId);
    } else {
      incompatiblePaletteElementIds.add(elementId);
    }
  }

  final availableCompatibleElements = <ProjectElementEntry>[];
  for (final element in elements) {
    final tilesetId = resolveEnvironmentPresetElementTilesetId(element);
    if (tilesetId == null) {
      continue;
    }
    if (sourceTilesetId == null || tilesetId == sourceTilesetId) {
      availableCompatibleElements.add(element);
    }
  }

  return EnvironmentPresetTilesetCompatibility(
    sourceTilesetId: sourceTilesetId,
    tilesetIds: tilesetIds,
    compatiblePaletteElementIds: compatiblePaletteElementIds,
    incompatiblePaletteElementIds: incompatiblePaletteElementIds,
    missingPaletteElementIds: missingPaletteElementIds,
    unknownTilesetElementIds: unknownTilesetElementIds,
    availableCompatibleElements: availableCompatibleElements,
  );
}
