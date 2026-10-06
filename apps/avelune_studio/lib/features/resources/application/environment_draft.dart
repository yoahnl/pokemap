import 'package:map_core/map_core_domain.dart';

class EnvironmentDraft {
  EnvironmentDraft({EnvironmentPreset? original})
    : _original = original,
      id =
          original?.id ??
          'environment-${DateTime.now().microsecondsSinceEpoch}',
      name = original?.name ?? '',
      palette = [...?original?.palette],
      params =
          original?.defaultParams ?? EnvironmentGenerationParams.standard(),
      templateId = original?.templateId ?? 'manual',
      categoryId = original?.categoryId,
      sortOrder = original?.sortOrder ?? 0;

  EnvironmentDraft.copy(EnvironmentPreset source)
    : _original = null,
      id = 'environment-${DateTime.now().microsecondsSinceEpoch}',
      name = '${source.name} — copie',
      palette = [...source.palette],
      params = source.defaultParams,
      templateId = source.templateId,
      categoryId = source.categoryId,
      sortOrder = source.sortOrder;

  EnvironmentPreset? _original;
  EnvironmentPreset? get original => _original;
  final String id;
  String name;
  List<EnvironmentPaletteItem> palette;
  EnvironmentGenerationParams params;
  final String templateId;
  final String? categoryId;
  final int sortOrder;
  final _weightInputs = <String, String>{};
  String? _spacingInput;

  String weightInput(String id) =>
      _weightInputs[id] ??
      '${palette.firstWhere((item) => item.elementId == id).weight}';
  String get spacingInput => _spacingInput ?? '${params.minSpacingCells}';

  void setWeightInput(String id, String input) {
    _weightInputs[id] = input;
    final value = int.tryParse(input);
    if (value != null && value >= 1) setItem(id, weight: value);
  }

  void setSpacingInput(String input) {
    _spacingInput = input;
    final value = int.tryParse(input);
    if (value != null && value >= 0) {
      params = EnvironmentGenerationParams(
        density: params.density,
        variation: params.variation,
        edgeDensity: params.edgeDensity,
        minSpacingCells: value,
      );
    }
  }

  bool get dirty {
    try {
      return build() != original;
    } on FormatException {
      return true;
    }
  }

  void add(String elementId) {
    if (palette.any((item) => item.elementId == elementId)) return;
    palette = [
      ...palette,
      EnvironmentPaletteItem(elementId: elementId, weight: 1),
    ];
  }

  void remove(String elementId) {
    palette = palette.where((item) => item.elementId != elementId).toList();
    _weightInputs.remove(elementId);
  }

  void setItem(String id, {int? weight, EnvironmentCollisionMode? collision}) {
    palette = [
      for (final item in palette)
        if (item.elementId == id)
          EnvironmentPaletteItem(
            elementId: id,
            weight: weight ?? item.weight,
            collisionMode: collision ?? item.collisionMode,
            tags: item.tags,
          )
        else
          item,
    ];
  }

  EnvironmentPreset build() {
    for (final input in _weightInputs.values) {
      final value = int.tryParse(input);
      if (value == null || value < 1) {
        throw const FormatException(
          'Le poids doit être un entier supérieur ou égal à 1.',
        );
      }
    }
    final spacing = int.tryParse(spacingInput);
    if (spacing == null || spacing < 0) {
      throw const FormatException(
        'L’espacement doit être un entier positif ou nul.',
      );
    }
    if (name.trim().isEmpty) {
      throw const FormatException('Nommez cet environnement.');
    }
    if (palette.isEmpty) {
      throw const FormatException('Ajoutez au moins un décor à la palette.');
    }
    return EnvironmentPreset(
      id: id,
      name: name,
      templateId: templateId,
      palette: palette,
      defaultParams: params,
      categoryId: categoryId,
      sortOrder: sortOrder,
    );
  }

  void rebase(EnvironmentPreset saved) => _original = saved;
}
