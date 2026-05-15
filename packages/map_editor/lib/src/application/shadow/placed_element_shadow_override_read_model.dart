import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/element_shadow_read_model.dart';

enum PlacedElementShadowOverrideUiMode {
  inherit,
  disabled,
  custom,
}

final class PlacedElementShadowOverrideReadModel {
  PlacedElementShadowOverrideReadModel({
    required this.instanceId,
    required this.mode,
    required this.override,
    required this.usesNullInheritance,
    required this.hasCompatibleProfiles,
    required List<ShadowProfileOptionReadModel> profileOptions,
    required this.selectedProfileId,
    required this.selectedProfileLabel,
    required this.sourceShadowMessage,
    required this.noCompatibleProfileMessage,
  }) : profileOptions =
            List<ShadowProfileOptionReadModel>.unmodifiable(profileOptions);

  final String instanceId;
  final PlacedElementShadowOverrideUiMode mode;
  final MapPlacedElementShadowOverride? override;
  final bool usesNullInheritance;
  final bool hasCompatibleProfiles;
  final List<ShadowProfileOptionReadModel> profileOptions;
  final String? selectedProfileId;
  final String selectedProfileLabel;
  final String? sourceShadowMessage;
  final String? noCompatibleProfileMessage;
}

PlacedElementShadowOverrideReadModel buildPlacedElementShadowOverrideReadModel({
  required ProjectManifest manifest,
  required ProjectElementEntry? element,
  required MapPlacedElement instance,
}) {
  final override = instance.shadowOverride;
  final profileOptions = buildShadowProfileOptionsForManifest(manifest);
  final mode = _overrideModeFor(override);
  final selectedProfileId = mode == PlacedElementShadowOverrideUiMode.custom
      ? override?.shadowProfileId
      : null;
  final selectedProfileLabel = _selectedProfileLabel(
    selectedProfileId,
    profileOptions,
  );

  return PlacedElementShadowOverrideReadModel(
    instanceId: instance.id,
    mode: mode,
    override: override,
    usesNullInheritance: override == null,
    hasCompatibleProfiles: profileOptions.isNotEmpty,
    profileOptions: profileOptions,
    selectedProfileId: selectedProfileId,
    selectedProfileLabel: selectedProfileLabel,
    sourceShadowMessage: _sourceShadowMessage(
      manifest: manifest,
      element: element,
    ),
    noCompatibleProfileMessage:
        profileOptions.isEmpty ? 'Aucun profil Shadow disponible.' : null,
  );
}

PlacedElementShadowOverrideUiMode _overrideModeFor(
  MapPlacedElementShadowOverride? override,
) {
  switch (override?.mode) {
    case null:
    case ShadowOverrideMode.inherit:
      return PlacedElementShadowOverrideUiMode.inherit;
    case ShadowOverrideMode.disabled:
      return PlacedElementShadowOverrideUiMode.disabled;
    case ShadowOverrideMode.custom:
      return PlacedElementShadowOverrideUiMode.custom;
  }
}

String _selectedProfileLabel(
  String? selectedProfileId,
  List<ShadowProfileOptionReadModel> profileOptions,
) {
  if (selectedProfileId == null) {
    return 'Profil de l’élément source';
  }
  for (final option in profileOptions) {
    if (option.id == selectedProfileId) {
      return option.label;
    }
  }
  return selectedProfileId;
}

String? _sourceShadowMessage({
  required ProjectManifest manifest,
  required ProjectElementEntry? element,
}) {
  if (element == null) {
    return 'Élément source introuvable.';
  }
  final shadow = element.shadow;
  if (shadow == null) {
    return 'L’élément source n’a pas d’ombre configurée.';
  }
  if (!shadow.castsShadow) {
    return 'L’ombre de l’élément source est désactivée.';
  }
  final profileId = shadow.shadowProfileId;
  if (profileId != null &&
      manifest.shadowCatalog.profileById(profileId) == null) {
    return 'Profil source introuvable : $profileId';
  }
  return null;
}
