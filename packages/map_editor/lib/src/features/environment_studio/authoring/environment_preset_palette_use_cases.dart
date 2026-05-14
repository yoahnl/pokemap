import 'package:map_core/map_core.dart';

import 'environment_preset_tileset_compatibility.dart';

final class UpdateEnvironmentPresetPaletteResult {
  const UpdateEnvironmentPresetPaletteResult({
    required this.manifest,
    required this.updatedPreset,
    required this.sourceTilesetId,
  });

  final ProjectManifest manifest;
  final EnvironmentPreset updatedPreset;
  final String sourceTilesetId;
}

final class UpdateEnvironmentPresetPaletteUseCase {
  const UpdateEnvironmentPresetPaletteUseCase();

  UpdateEnvironmentPresetPaletteResult call({
    required ProjectManifest manifest,
    required String presetId,
    required List<EnvironmentPaletteItem> palette,
  }) {
    final key = presetId.trim();
    if (key.isEmpty) {
      throw ArgumentError.value(
        presetId,
        'presetId',
        'Environment preset id must not be blank.',
      );
    }
    if (palette.isEmpty) {
      throw ArgumentError.value(
        palette,
        'palette',
        'Environment preset palette must not be empty.',
      );
    }

    final elementsById = <String, ProjectElementEntry>{
      for (final element in manifest.elements) element.id: element,
    };
    final tilesetIds = <String>{};
    for (final item in palette) {
      final element = elementsById[item.elementId];
      if (element == null) {
        throw ArgumentError.value(
          item.elementId,
          'palette',
          'Environment preset palette references a missing element.',
        );
      }
      final tilesetId = resolveEnvironmentPresetElementTilesetId(element);
      if (tilesetId == null) {
        throw ArgumentError.value(
          item.elementId,
          'palette',
          'Environment preset palette element has no resolvable tileset.',
        );
      }
      tilesetIds.add(tilesetId);
    }
    if (tilesetIds.length > 1) {
      throw ArgumentError.value(
        palette.map((item) => item.elementId).toList(growable: false),
        'palette',
        'Environment preset palette cannot mix multiple tilesets.',
      );
    }

    final presets = manifest.environmentPresets;
    final index = presets.indexWhere((preset) => preset.id == key);
    if (index < 0) {
      throw StateError('Environment preset "$key" not found.');
    }
    final source = presets[index];
    final updatedPreset = EnvironmentPreset(
      id: source.id,
      name: source.name,
      templateId: source.templateId,
      palette: palette,
      defaultParams: source.defaultParams,
      categoryId: source.categoryId,
      sortOrder: source.sortOrder,
    );
    final updatedPresets = List<EnvironmentPreset>.from(presets);
    updatedPresets[index] = updatedPreset;
    return UpdateEnvironmentPresetPaletteResult(
      manifest: manifest.copyWith(environmentPresets: updatedPresets),
      updatedPreset: updatedPreset,
      sourceTilesetId: tilesetIds.single,
    );
  }
}
