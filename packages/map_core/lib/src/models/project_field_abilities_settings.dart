import 'enums.dart';
import 'map_spatial_scene.dart';
import 'project_manifest.dart';

final class ProjectFieldAbilitiesSettings {
  factory ProjectFieldAbilitiesSettings({
    Iterable<FieldAbility> disabledAbilities = const [],
  }) {
    final values = disabledAbilities.toList();
    if (values.contains(FieldAbility.surf)) {
      throw const FormatException(
        'Surf activation belongs to settings.surf.enabled.',
      );
    }
    if (values.toSet().length != values.length) {
      throw const FormatException('Disabled field abilities must be unique.');
    }
    return ProjectFieldAbilitiesSettings._(Set.unmodifiable(values));
  }

  const ProjectFieldAbilitiesSettings.empty() : disabledAbilities = const {};
  const ProjectFieldAbilitiesSettings._(this.disabledAbilities);

  final Set<FieldAbility> disabledAbilities;
  bool get isEmpty => disabledAbilities.isEmpty;
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
    final values = <FieldAbility>[];
    for (final id in raw) {
      final matching = FieldAbility.values.where(
        (ability) => ability.moveId == id,
      );
      if (matching.isEmpty) {
        throw FormatException('Unknown field ability "$id".');
      }
      values.add(matching.single);
    }
    return ProjectFieldAbilitiesSettings(disabledAbilities: values);
  }

  Map<String, dynamic> toJson() => {
    'disabledAbilities':
        disabledAbilities.map((ability) => ability.moveId).toList()..sort(),
  };

  @override
  bool operator ==(Object other) =>
      other is ProjectFieldAbilitiesSettings &&
      disabledAbilities.length == other.disabledAbilities.length &&
      disabledAbilities.containsAll(other.disabledAbilities);

  @override
  int get hashCode => Object.hashAllUnordered(disabledAbilities);
}

bool isProjectFieldAbilityEnabled(
  ProjectSettings settings,
  FieldAbility ability,
) => ability == FieldAbility.surf
    ? settings.surf?.enabled ?? settings.dimension == ProjectDimension.twoD
    : !(settings.fieldAbilities?.disabledAbilities.contains(ability) ?? false);
