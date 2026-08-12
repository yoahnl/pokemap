import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';

typedef ProjectTypographyMetricsChanged =
    void Function(
      ProjectTypographyRole role,
      ProjectTypographyMetricsProfile metrics,
    );

/// No-code typography editor with live loaded-font previews.
class ProjectTypographyEditor extends StatelessWidget {
  const ProjectTypographyEditor({
    super.key,
    required this.profile,
    required this.onImportRole,
    required this.onUseSystemFont,
    this.previewFamilies = const <ProjectTypographyRole, String>{},
    this.commonOnly = false,
    this.fixedRole,
    this.roles,
    this.onImportCommonFont,
    this.onUseSystemCommonFont,
    this.onMetricsChanged,
    this.onCommonMetricsChanged,
  });

  final ProjectTypographyProfile profile;
  final ValueChanged<ProjectTypographyRole> onImportRole;
  final ValueChanged<ProjectTypographyRole> onUseSystemFont;
  final Map<ProjectTypographyRole, String> previewFamilies;
  final bool commonOnly;
  final ProjectTypographyRole? fixedRole;
  final List<ProjectTypographyRole>? roles;
  final VoidCallback? onImportCommonFont;
  final VoidCallback? onUseSystemCommonFont;
  final ProjectTypographyMetricsChanged? onMetricsChanged;
  final ValueChanged<ProjectTypographyMetricsProfile>? onCommonMetricsChanged;

  @override
  Widget build(BuildContext context) {
    final role = fixedRole;
    if (role != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PokeMapSectionHeader(
            title: switch (role) {
              ProjectTypographyRole.dialogue => 'Typographie du dialogue',
              ProjectTypographyRole.combat => 'Typographie des combats',
              _ => 'Typographie ${_label(role).toLowerCase()}',
            },
            description: switch (role) {
              ProjectTypographyRole.dialogue =>
                'Choisissez la police utilisée pour les répliques.',
              ProjectTypographyRole.combat =>
                'Choisissez la police des commandes, messages et statuts de combat.',
              _ => 'Choisissez la police utilisée pour ce rôle.',
            },
          ),
          const SizedBox(height: 8),
          _RoleEditor(
            role: role,
            profile: _profileForRole(profile, role),
            previewFamily: previewFamilies[role],
            onImport: () => onImportRole(role),
            onUseSystem: () => onUseSystemFont(role),
            onMetricsChanged: onMetricsChanged == null
                ? null
                : (metrics) => onMetricsChanged!(role, metrics),
          ),
        ],
      );
    }
    final selectedRoles = roles;
    if (selectedRoles != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (
            var index = 0;
            index < selectedRoles.length;
            index++
          ) ...<Widget>[
            _RoleEditor(
              role: selectedRoles[index],
              profile: _profileForRole(profile, selectedRoles[index]),
              previewFamily: previewFamilies[selectedRoles[index]],
              onImport: () => onImportRole(selectedRoles[index]),
              onUseSystem: () => onUseSystemFont(selectedRoles[index]),
              onMetricsChanged: onMetricsChanged == null
                  ? null
                  : (metrics) =>
                        onMetricsChanged!(selectedRoles[index], metrics),
            ),
            if (index != selectedRoles.length - 1) const SizedBox(height: 12),
          ],
        ],
      );
    }
    return commonOnly
        ? _CommonTypographyEditor(
            profile: profile,
            previewFamily: previewFamilies[ProjectTypographyRole.body],
            onImport: onImportCommonFont,
            onUseSystem: onUseSystemCommonFont,
            onMetricsChanged: onCommonMetricsChanged,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const PokeMapCard(
                child: Text(
                  'Chaque rôle conserve un fallback système. Les fontes embarquées '
                  'doivent inclure une licence redistribuable et les glyphes joueur.',
                ),
              ),
              const SizedBox(height: 12),
              for (final role in ProjectTypographyRole.values) ...<Widget>[
                _RoleEditor(
                  role: role,
                  profile: _profileForRole(profile, role),
                  previewFamily: previewFamilies[role],
                  onImport: () => onImportRole(role),
                  onUseSystem: () => onUseSystemFont(role),
                  onMetricsChanged: onMetricsChanged == null
                      ? null
                      : (metrics) => onMetricsChanged!(role, metrics),
                ),
                if (role != ProjectTypographyRole.values.last)
                  const SizedBox(height: 12),
              ],
            ],
          );
  }
}

class _CommonTypographyEditor extends StatelessWidget {
  const _CommonTypographyEditor({
    required this.profile,
    required this.previewFamily,
    required this.onImport,
    required this.onUseSystem,
    required this.onMetricsChanged,
  });

  final ProjectTypographyProfile profile;
  final String? previewFamily;
  final VoidCallback? onImport;
  final VoidCallback? onUseSystem;
  final ValueChanged<ProjectTypographyMetricsProfile>? onMetricsChanged;

  @override
  Widget build(BuildContext context) {
    final roles = <ProjectTypographyRoleProfile>[
      profile.display,
      profile.body,
      profile.dialogue,
      profile.combat ?? profile.body,
      profile.numbers,
    ];
    final families = roles
        .map((role) => role.family)
        .whereType<String>()
        .toSet();
    final hasCustomFont = roles.any((role) => role.fontPath != null);
    final family = families.length == 1
        ? families.single
        : families.isEmpty
        ? 'Police système'
        : 'Plusieurs polices';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const PokeMapSectionHeader(
          title: 'Police commune',
          description:
              'Choisissez une police lisible pour les menus, dialogues et combats.',
        ),
        const SizedBox(height: 8),
        PokeMapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(family, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Une nouvelle aventure commence ici.',
                style: TextStyle(
                  fontFamily: previewFamily,
                  fontFamilyFallback: profile.body.fallbackFamilies,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              _TypographyMetricsEditor(
                roleKey: 'common',
                metrics: profile.body.metrics,
                onChanged: onMetricsChanged,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  PokeMapButton(
                    key: const ValueKey<String>('typography-import-common'),
                    onPressed: onImport,
                    leading: const Icon(Icons.font_download_outlined),
                    child: Text(hasCustomFont ? 'Remplacer' : 'Choisir'),
                  ),
                  if (hasCustomFont)
                    PokeMapButton(
                      key: const ValueKey<String>('typography-system-common'),
                      onPressed: onUseSystem,
                      variant: PokeMapButtonVariant.secondary,
                      leading: const Icon(
                        Icons.settings_backup_restore_outlined,
                      ),
                      child: const Text('Police système'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleEditor extends StatelessWidget {
  const _RoleEditor({
    required this.role,
    required this.profile,
    required this.previewFamily,
    required this.onImport,
    required this.onUseSystem,
    required this.onMetricsChanged,
  });

  final ProjectTypographyRole role;
  final ProjectTypographyRoleProfile profile;
  final String? previewFamily;
  final VoidCallback onImport;
  final VoidCallback onUseSystem;
  final ValueChanged<ProjectTypographyMetricsProfile>? onMetricsChanged;

  @override
  Widget build(BuildContext context) {
    final custom = profile.fontPath != null;
    final metrics = profile.metrics ?? const ProjectTypographyMetricsProfile();
    return PokeMapPanel(
      header: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(_icon(role), size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _label(role),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            PokeMapBadge(
              label: custom ? profile.family! : 'Fonte système',
              variant: custom
                  ? PokeMapBadgeVariant.success
                  : PokeMapBadgeVariant.info,
            ),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          PokeMapCard(
            child: Text(
              _sample(role),
              key: ValueKey<String>('typography-preview-${role.name}'),
              style: TextStyle(
                fontFamily: previewFamily,
                fontFamilyFallback: profile.fallbackFamilies,
                fontSize:
                    (role == ProjectTypographyRole.display ? 28 : 17) *
                    metrics.sizeScale,
                fontWeight: FontWeight.values[(metrics.weight ~/ 100) - 1],
                height: metrics.lineHeight,
                letterSpacing: metrics.letterSpacing,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              PokeMapBadge(
                label: 'Fallback : ${profile.fallbackFamilies.join(', ')}',
                icon: const Icon(Icons.alt_route_outlined),
              ),
              if (custom)
                const PokeMapBadge(
                  label: 'Licence jointe',
                  variant: PokeMapBadgeVariant.success,
                  icon: Icon(Icons.verified_outlined),
                ),
              if (custom)
                const PokeMapBadge(
                  label: 'Glyphes vérifiés',
                  variant: PokeMapBadgeVariant.success,
                  icon: Icon(Icons.translate_outlined),
                ),
            ],
          ),
          const SizedBox(height: 12),
          _TypographyMetricsEditor(
            roleKey: role.name,
            metrics: profile.metrics,
            onChanged: onMetricsChanged,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              PokeMapButton(
                key: ValueKey<String>('typography-import-${role.name}'),
                onPressed: onImport,
                leading: const Icon(Icons.font_download_outlined),
                child: Text(custom ? 'Remplacer' : 'Importer une fonte'),
              ),
              if (custom)
                PokeMapButton(
                  key: ValueKey<String>('typography-system-${role.name}'),
                  onPressed: onUseSystem,
                  variant: PokeMapButtonVariant.secondary,
                  leading: const Icon(Icons.settings_backup_restore_outlined),
                  child: const Text('Utiliser le fallback système'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypographyMetricsEditor extends StatelessWidget {
  const _TypographyMetricsEditor({
    required this.roleKey,
    required this.metrics,
    required this.onChanged,
  });

  final String roleKey;
  final ProjectTypographyMetricsProfile? metrics;
  final ValueChanged<ProjectTypographyMetricsProfile>? onChanged;

  @override
  Widget build(BuildContext context) {
    final value = metrics ?? const ProjectTypographyMetricsProfile();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Réglages du texte',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            SizedBox(
              width: 176,
              child: PokeMapDropdownField<double>(
                key: ValueKey<String>('typography-size-$roleKey'),
                label: 'Taille',
                value: value.sizeScale,
                enabled: onChanged != null,
                items: _withCurrentMetric(
                  current: value.sizeScale,
                  values: const <double>[.75, .9, 1, 1.1, 1.25, 1.5, 1.75],
                  label: (scale) => '${(scale * 100).round()} %',
                ),
                onChanged: (next) =>
                    onChanged!(value.copyWith(sizeScale: next)),
              ),
            ),
            SizedBox(
              width: 176,
              child: PokeMapDropdownField<int>(
                key: ValueKey<String>('typography-weight-$roleKey'),
                label: 'Graisse',
                value: value.weight,
                enabled: onChanged != null,
                items: <PokeMapDropdownItem<int>>[
                  for (final weight in supportedProjectTypographyWeights)
                    PokeMapDropdownItem<int>(value: weight, label: '$weight'),
                ],
                onChanged: (next) => onChanged!(value.copyWith(weight: next)),
              ),
            ),
            SizedBox(
              width: 176,
              child: PokeMapDropdownField<double>(
                key: ValueKey<String>('typography-line-height-$roleKey'),
                label: 'Interligne',
                value: value.lineHeight,
                enabled: onChanged != null,
                items: _withCurrentMetric(
                  current: value.lineHeight,
                  values: const <double>[1, 1.15, 1.25, 1.4, 1.6, 1.8],
                  label: (height) => '$height×',
                ),
                onChanged: (next) =>
                    onChanged!(value.copyWith(lineHeight: next)),
              ),
            ),
            SizedBox(
              width: 176,
              child: PokeMapDropdownField<double>(
                key: ValueKey<String>('typography-spacing-$roleKey'),
                label: 'Espacement',
                value: value.letterSpacing,
                enabled: onChanged != null,
                items: _withCurrentMetric(
                  current: value.letterSpacing,
                  values: const <double>[-1, 0, .5, 1, 2, 4],
                  label: (spacing) => '${spacing}px',
                ),
                onChanged: (next) =>
                    onChanged!(value.copyWith(letterSpacing: next)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

List<PokeMapDropdownItem<double>> _withCurrentMetric({
  required double current,
  required List<double> values,
  required String Function(double value) label,
}) {
  final resolved = values.contains(current)
      ? values
      : <double>[...values, current];
  return <PokeMapDropdownItem<double>>[
    for (final value in resolved)
      PokeMapDropdownItem<double>(value: value, label: label(value)),
  ];
}

ProjectTypographyRoleProfile _profileForRole(
  ProjectTypographyProfile profile,
  ProjectTypographyRole role,
) => switch (role) {
  ProjectTypographyRole.display => profile.display,
  ProjectTypographyRole.body => profile.body,
  ProjectTypographyRole.dialogue => profile.dialogue,
  ProjectTypographyRole.combat => profile.combat ?? profile.body,
  ProjectTypographyRole.numbers => profile.numbers,
};

String _label(ProjectTypographyRole role) => switch (role) {
  ProjectTypographyRole.display => 'Titres & affichage',
  ProjectTypographyRole.body => 'Texte courant',
  ProjectTypographyRole.dialogue => 'Dialogues',
  ProjectTypographyRole.combat => 'Combats',
  ProjectTypographyRole.numbers => 'Nombres',
};

String _sample(ProjectTypographyRole role) => switch (role) {
  ProjectTypographyRole.display => 'Une nouvelle aventure',
  ProjectTypographyRole.body =>
    'Explorez le monde, découvrez ses secrets et rencontrez ses habitants.',
  ProjectTypographyRole.dialogue =>
    '« Prêt pour le départ ? Écoute bien : tout commence ici. »',
  ProjectTypographyRole.combat =>
    'Que doit faire BRINDIBOU ? · Attaquer · Sac · Équipe · Fuite',
  ProjectTypographyRole.numbers => 'Niveau 42 · PV 128 / 160 · 9 999 ₽',
};

IconData _icon(ProjectTypographyRole role) => switch (role) {
  ProjectTypographyRole.display => Icons.title_outlined,
  ProjectTypographyRole.body => Icons.subject_outlined,
  ProjectTypographyRole.dialogue => Icons.chat_bubble_outline,
  ProjectTypographyRole.combat => Icons.sports_martial_arts_outlined,
  ProjectTypographyRole.numbers => Icons.numbers_outlined,
};
