import 'package:pokemap_hub/features/appearance/domain/entities/avelune_appearance_catalog.dart';
import 'package:pokemap_hub/presentation/design_system/assets/avelune_material_catalog.dart';

/// Resolves the design-system asset backing an appearance option.
///
/// The option itself deliberately carries no asset path: only the UI needs one,
/// and a domain entity that knows about the design system is a domain entity
/// pointing the wrong way. It carries the id; presentation resolves the rest.
String? appearanceAssetPath(AveluneAppearanceOption option) {
  if (option.isCustom) return null;
  return switch (option.kind) {
    AveluneAppearanceOptionKind.background =>
      AveluneMaterialCatalog.background(option.id).path,
    AveluneAppearanceOptionKind.furniture =>
      AveluneMaterialCatalog.furnitureFinish(option.id).path,
  };
}
