import 'package:flutter/foundation.dart';

import '../assets/avelune_material_catalog.dart';

enum AveluneAppearanceOptionKind { background, furniture }

@immutable
final class AveluneAppearanceOption {
  const AveluneAppearanceOption({
    required this.id,
    required this.label,
    required this.kind,
    required this.assetPath,
  });

  final String id;
  final String label;
  final AveluneAppearanceOptionKind kind;
  final String? assetPath;

  bool get isCustom => id == AveluneAppearanceCatalog.customBackgroundId;
}

/// Stable V1 appearance IDs shared by persistence and the future settings UI.
abstract final class AveluneAppearanceCatalog {
  static const String defaultBackgroundId = 'amber';
  static const String defaultFurnitureId = 'walnut';
  static const String customBackgroundId = 'custom';

  static final List<AveluneAppearanceOption> backgrounds =
      List<AveluneAppearanceOption>.unmodifiable(
    <AveluneAppearanceOption>[
      _background('amber', 'Ambre'),
      _background('dawn', 'Aube'),
      _background('linen', 'Lin'),
      _background('violet', 'Crépuscule'),
      _background('slate', 'Ardoise'),
      const AveluneAppearanceOption(
        id: customBackgroundId,
        label: 'Mon image',
        kind: AveluneAppearanceOptionKind.background,
        assetPath: null,
      ),
    ],
  );

  static final List<AveluneAppearanceOption> furniture =
      List<AveluneAppearanceOption>.unmodifiable(
    <AveluneAppearanceOption>[
      _furniture('walnut', 'Noyer'),
      _furniture('ivory', 'Ivoire'),
      _furniture('oak', 'Chêne clair'),
      _furniture('ash', 'Frêne'),
      _furniture('mahogany', 'Acajou'),
      _furniture('ebony', 'Ébène'),
    ],
  );

  static final List<AveluneAppearanceOption> builtInPresets =
      List<AveluneAppearanceOption>.unmodifiable(
    <AveluneAppearanceOption>[
      ...backgrounds.where((option) => !option.isCustom),
      ...furniture,
    ],
  );

  static Set<String> get backgroundIds =>
      backgrounds.map((option) => option.id).toSet();

  static Set<String> get furnitureIds =>
      furniture.map((option) => option.id).toSet();

  static AveluneAppearanceOption background(String id) =>
      _find(backgrounds, id, 'background');

  static AveluneAppearanceOption furnitureFinish(String id) =>
      _find(furniture, id, 'furniture');

  static AveluneAppearanceOption _background(String id, String label) =>
      AveluneAppearanceOption(
        id: id,
        label: label,
        kind: AveluneAppearanceOptionKind.background,
        assetPath: AveluneMaterialCatalog.background(id).path,
      );

  static AveluneAppearanceOption _furniture(String id, String label) =>
      AveluneAppearanceOption(
        id: id,
        label: label,
        kind: AveluneAppearanceOptionKind.furniture,
        assetPath: AveluneMaterialCatalog.furnitureFinish(id).path,
      );

  static AveluneAppearanceOption _find(
    List<AveluneAppearanceOption> options,
    String id,
    String kind,
  ) {
    for (final option in options) {
      if (option.id == id) return option;
    }
    throw ArgumentError.value(id, 'id', 'Unknown Avelune $kind.');
  }
}
