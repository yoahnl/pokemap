import 'enums.dart';
import 'map_spatial_scene.dart';
import 'project_field_ability_registry.dart';
import 'project_manifest.dart';

final class ProjectFieldAbilitiesSettings {
  factory ProjectFieldAbilitiesSettings({
    Iterable<FieldAbility> disabledAbilities = const [],
  }) => ProjectFieldAbilitiesSettings.fromIds(
    disabledAbilities.map((ability) => ability.moveId),
  );

  factory ProjectFieldAbilitiesSettings.fromIds(
    Iterable<String> disabledAbilityIds,
  ) {
    final values = disabledAbilityIds.toList();
    if (values.contains('surf')) {
      throw const FormatException(
        'Surf activation belongs to settings.surf.enabled.',
      );
    }
    if (values.toSet().length != values.length) {
      throw const FormatException('Disabled field abilities must be unique.');
    }
    for (final id in values) {
      if (ProjectFieldAbilityRegistry.find(id) == null) {
        throw FormatException('Unknown field ability "$id".');
      }
    }
    final ids = Set<String>.unmodifiable(values);
    return ProjectFieldAbilitiesSettings._(
      ids,
      Set<FieldAbility>.unmodifiable(
        FieldAbility.values.where((ability) => ids.contains(ability.moveId)),
      ),
    );
  }

  const ProjectFieldAbilitiesSettings.empty()
    : disabledAbilityIds = const {},
      disabledAbilities = const {};
  const ProjectFieldAbilitiesSettings._(
    this.disabledAbilityIds,
    this.disabledAbilities,
  );

  final Set<String> disabledAbilityIds;
  final Set<FieldAbility> disabledAbilities;
  bool get isEmpty => disabledAbilityIds.isEmpty;
  ProjectFieldAbilitiesSettings validated() => this;

  factory ProjectFieldAbilitiesSettings.fromJson(Map<String, dynamic> json) {
    if (json.keys.any((key) => key != 'disabledAbilities')) {
      throw const FormatException('Unknown field ability activation setting.');
    }
    final raw = json.containsKey('disabledAbilities')
        ? json['disabledAbilities']
        : const <String>[];
    if (raw is! List || raw.any((value) => value is! String)) {
      throw const FormatException(
        'Disabled field abilities must be an array of identifiers.',
      );
    }
    return ProjectFieldAbilitiesSettings.fromIds(raw.cast<String>());
  }

  Map<String, dynamic> toJson() => {
    'disabledAbilities': disabledAbilityIds.toList()..sort(),
  };

  @override
  bool operator ==(Object other) =>
      other is ProjectFieldAbilitiesSettings &&
      disabledAbilityIds.length == other.disabledAbilityIds.length &&
      disabledAbilityIds.containsAll(other.disabledAbilityIds);

  @override
  int get hashCode => Object.hashAllUnordered(disabledAbilityIds);
}

bool isProjectFieldAbilityEnabled(
  ProjectSettings settings,
  FieldAbility ability,
) => ability == FieldAbility.surf
    ? settings.surf?.enabled ?? settings.dimension == ProjectDimension.twoD
    : !(settings.fieldAbilities?.disabledAbilities.contains(ability) ?? false);

bool isProjectFieldAbilityIdEnabled(ProjectSettings settings, String id) {
  final entry = ProjectFieldAbilityRegistry.find(id);
  if (entry == null) {
    throw ArgumentError.value(id, 'id', 'Unknown project field ability.');
  }
  final ability = entry.fieldAbility;
  return ability == null
      ? !(settings.fieldAbilities?.disabledAbilityIds.contains(id) ?? false)
      : isProjectFieldAbilityEnabled(settings, ability);
}
