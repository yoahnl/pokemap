import 'enums.dart';

final class ProjectFieldAbilityEntry {
  const ProjectFieldAbilityEntry({
    required this.id,
    required this.label,
    this.fieldAbility,
  });

  final String id;
  final String label;
  final FieldAbility? fieldAbility;
  bool get activationOnly => fieldAbility == null;
}

abstract final class ProjectFieldAbilityRegistry {
  static const entries = <ProjectFieldAbilityEntry>[
    ProjectFieldAbilityEntry(
      id: 'fly',
      label: 'Vol',
      fieldAbility: FieldAbility.fly,
    ),
    ProjectFieldAbilityEntry(
      id: 'surf',
      label: 'Surf',
      fieldAbility: FieldAbility.surf,
    ),
    ProjectFieldAbilityEntry(
      id: 'cut',
      label: 'Coupe',
      fieldAbility: FieldAbility.cut,
    ),
    ProjectFieldAbilityEntry(
      id: 'strength',
      label: 'Force',
      fieldAbility: FieldAbility.strength,
    ),
    ProjectFieldAbilityEntry(
      id: 'flash',
      label: 'Flash',
      fieldAbility: FieldAbility.flash,
    ),
    ProjectFieldAbilityEntry(
      id: 'rock_smash',
      label: 'Éclate-Roc',
      fieldAbility: FieldAbility.rockSmash,
    ),
    ProjectFieldAbilityEntry(
      id: 'waterfall',
      label: 'Cascade',
      fieldAbility: FieldAbility.waterfall,
    ),
    ProjectFieldAbilityEntry(
      id: 'whirlpool',
      label: 'Siphon',
      fieldAbility: FieldAbility.whirlpool,
    ),
    ProjectFieldAbilityEntry(
      id: 'dive',
      label: 'Plongée',
      fieldAbility: FieldAbility.dive,
    ),
    ProjectFieldAbilityEntry(id: 'rock_climb', label: 'Escalade'),
    ProjectFieldAbilityEntry(id: 'defog', label: 'Anti-Brume'),
  ];

  static ProjectFieldAbilityEntry? find(String id) {
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }
}
