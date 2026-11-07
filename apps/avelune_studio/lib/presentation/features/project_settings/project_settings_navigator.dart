import 'package:avelune_design_system/presentation/shared/widgets/layout/studio_navigation_entry.dart';
import 'package:flutter/material.dart';

import '../../../features/project_settings/application/project_settings_session_controller.dart';
import '../../shared/widgets/inputs/studio_select.dart';

extension ProjectSettingsSectionLabels on ProjectSettingsSection {
  String get label => switch (this) {
    ProjectSettingsSection.general => 'Général',
    ProjectSettingsSection.fieldAbilities => 'Capacités de terrain',
    ProjectSettingsSection.image => 'Image et caméra',
    ProjectSettingsSection.timeWeather => 'Temps et météo',
    ProjectSettingsSection.sounds => 'Sons',
    ProjectSettingsSection.verification => 'Vérifications et export',
  };

  String get summary => switch (this) {
    ProjectSettingsSection.general => 'Identité et langues du jeu',
    ProjectSettingsSection.fieldAbilities => 'Activation et conditions de Surf',
    ProjectSettingsSection.image => 'Cadrage et effets par défaut',
    ProjectSettingsSection.timeWeather => 'Heure et fonctionnement météo',
    ProjectSettingsSection.sounds => 'Bibliothèque et actions du jeu',
    ProjectSettingsSection.verification => 'Points à examiner et préparation',
  };

  IconData get icon => switch (this) {
    ProjectSettingsSection.general => Icons.public,
    ProjectSettingsSection.fieldAbilities => Icons.terrain_outlined,
    ProjectSettingsSection.image => Icons.photo_camera_outlined,
    ProjectSettingsSection.timeWeather => Icons.wb_twilight_outlined,
    ProjectSettingsSection.sounds => Icons.volume_up_outlined,
    ProjectSettingsSection.verification => Icons.fact_check_outlined,
  };
}

class ProjectSettingsNavigator extends StatelessWidget {
  const ProjectSettingsNavigator({
    super.key,
    required this.session,
    required this.available,
    required this.compact,
  });

  final ProjectSettingsSessionController session;
  final bool Function(ProjectSettingsSection section) available;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dirty = session.dirtySections;
    final colors = Theme.of(context).colorScheme;
    final entries = [
      for (final section in ProjectSettingsSection.values)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: StudioNavigationEntry(
            key: ValueKey('settings-section-${section.name}'),
            label: section.label,
            detail: section.summary,
            icon: section.icon,
            selected: session.section == section,
            unavailableReason: available(section)
                ? null
                : 'Ce projet ne propose pas cette rubrique.',
            marker: dirty.contains(section)
                ? Icon(Icons.circle, size: 10, color: colors.primary)
                : null,
            markerLabel: dirty.contains(section)
                ? 'brouillon non enregistré'
                : null,
            onTap: available(section) ? () => session.select(section) : null,
          ),
        ),
    ];
    if (compact) {
      return StudioSelect(
        key: const ValueKey('settings-section-select'),
        label: 'Rubrique',
        value: session.section.name,
        options: {
          for (final section in ProjectSettingsSection.values)
            if (available(section))
              section.name: dirty.contains(section)
                  ? '${section.label} · brouillon'
                  : section.label,
        },
        onChanged: (value) =>
            session.select(ProjectSettingsSection.values.byName(value)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
          child: Text(
            'Réglages du projet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        ...entries,
        const Divider(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Changer de rubrique n’enregistre rien : chaque brouillon reste '
            'attaché à sa rubrique jusqu’à son enregistrement ou son abandon.',
          ),
        ),
      ],
    );
  }
}
