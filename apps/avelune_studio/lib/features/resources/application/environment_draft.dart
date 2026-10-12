import 'package:map_core/map_core.dart';

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
  final _offsetInputs = <String, Map<String, String>>{};
  String? _spacingInput;

  String weightInput(String id) =>
      _weightInputs[id] ??
      '${palette.firstWhere((item) => item.resourceId == id).weight}';
  String get spacingInput => _spacingInput ?? '${params.minSpacingCells}';

  String offsetInput(String id, String axis) {
    final offset =
        palette.firstWhere((item) => item.resourceId == id).cellOffsetWorld ??
        Model3dVector3.zero;
    return _offsetInputs[id]?[axis] ??
        '${switch (axis) {
          'x' => offset.x,
          'y' => offset.y,
          _ => offset.z,
        }}';
  }

  void setOffsetInput(String id, String axis, String input) {
    final values = _offsetInputs.putIfAbsent(
      id,
      () => {
        for (final name in ['x', 'y', 'z']) name: offsetInput(id, name),
      },
    );
    values[axis] = input;
    final coordinates = [
      for (final name in ['x', 'y', 'z'])
        double.tryParse(values[name]!.trim().replaceAll(',', '.')),
    ];
    if (coordinates.every(
      (coordinate) => coordinate != null && coordinate.isFinite,
    )) {
      setItem(
        id,
        cellOffset: Model3dVector3(
          x: coordinates[0]!,
          y: coordinates[1]!,
          z: coordinates[2]!,
        ),
      );
    }
  }

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

  void add(String resourceId, {bool spatial = false}) {
    if (palette.any((item) => item.resourceId == resourceId)) return;
    if (palette.isNotEmpty && palette.first.isSpatial != spatial) {
      throw const FormatException(
        'Utilisez une palette de décors 2D ou de modèles 3D.',
      );
    }
    palette = [
      ...palette,
      EnvironmentPaletteItem(
        elementId: spatial ? null : resourceId,
        modelId: spatial ? resourceId : null,
        weight: 1,
      ),
    ];
  }

  void remove(String resourceId) {
    palette = palette.where((item) => item.resourceId != resourceId).toList();
    _weightInputs.remove(resourceId);
    _offsetInputs.remove(resourceId);
  }

  void setItem(
    String id, {
    int? weight,
    EnvironmentCollisionMode? collision,
    Model3dVector3? cellOffset,
  }) {
    palette = [
      for (final item in palette)
        if (item.resourceId == id)
          EnvironmentPaletteItem(
            elementId: item.elementId,
            modelId: item.modelId,
            weight: weight ?? item.weight,
            collisionMode: collision ?? item.collisionMode,
            tags: item.tags,
            cellOffsetWorld: cellOffset ?? item.cellOffsetWorld,
          )
        else
          item,
    ];
  }

  EnvironmentPreset build() {
    for (final values in _offsetInputs.values) {
      for (final input in values.values) {
        final coordinate = double.tryParse(input.trim().replaceAll(',', '.'));
        if (coordinate == null || !coordinate.isFinite) {
          throw const FormatException(
            'Chaque décalage doit être un nombre fini en unités de carte.',
          );
        }
      }
    }
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
