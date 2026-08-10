import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';

/// Four-role no-code typography editor with live loaded-font previews.
class ProjectTypographyEditor extends StatelessWidget {
  const ProjectTypographyEditor({
    super.key,
    required this.profile,
    required this.onImportRole,
    required this.onUseSystemFont,
    this.previewFamilies = const <ProjectTypographyRole, String>{},
    this.commonOnly = false,
    this.fixedRole,
    this.onImportCommonFont,
    this.onUseSystemCommonFont,
  });

  final ProjectTypographyProfile profile;
  final ValueChanged<ProjectTypographyRole> onImportRole;
  final ValueChanged<ProjectTypographyRole> onUseSystemFont;
  final Map<ProjectTypographyRole, String> previewFamilies;
  final bool commonOnly;
  final ProjectTypographyRole? fixedRole;
  final VoidCallback? onImportCommonFont;
  final VoidCallback? onUseSystemCommonFont;

  @override
  Widget build(BuildContext context) {
    final role = fixedRole;
    if (role != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const PokeMapSectionHeader(
            title: 'Typographie du dialogue',
            description: 'Choisissez la police utilisée pour les répliques.',
          ),
          const SizedBox(height: 8),
          _RoleEditor(
            role: role,
            profile: _profileForRole(profile, role),
            previewFamily: previewFamilies[role],
            onImport: () => onImportRole(role),
            onUseSystem: () => onUseSystemFont(role),
          ),
        ],
      );
    }
    return commonOnly
        ? _CommonTypographyEditor(
            profile: profile,
            previewFamily: previewFamilies[ProjectTypographyRole.body],
            onImport: onImportCommonFont,
            onUseSystem: onUseSystemCommonFont,
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
  });

  final ProjectTypographyProfile profile;
  final String? previewFamily;
  final VoidCallback? onImport;
  final VoidCallback? onUseSystem;

  @override
  Widget build(BuildContext context) {
    final roles = <ProjectTypographyRoleProfile>[
      profile.display,
      profile.body,
      profile.dialogue,
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
  });

  final ProjectTypographyRole role;
  final ProjectTypographyRoleProfile profile;
  final String? previewFamily;
  final VoidCallback onImport;
  final VoidCallback onUseSystem;

  @override
  Widget build(BuildContext context) {
    final custom = profile.fontPath != null;
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
                fontSize: role == ProjectTypographyRole.display ? 28 : 17,
                fontWeight: role == ProjectTypographyRole.display
                    ? FontWeight.w700
                    : FontWeight.w400,
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

ProjectTypographyRoleProfile _profileForRole(
  ProjectTypographyProfile profile,
  ProjectTypographyRole role,
) => switch (role) {
  ProjectTypographyRole.display => profile.display,
  ProjectTypographyRole.body => profile.body,
  ProjectTypographyRole.dialogue => profile.dialogue,
  ProjectTypographyRole.numbers => profile.numbers,
};

String _label(ProjectTypographyRole role) => switch (role) {
  ProjectTypographyRole.display => 'Titres & affichage',
  ProjectTypographyRole.body => 'Texte courant',
  ProjectTypographyRole.dialogue => 'Dialogues',
  ProjectTypographyRole.numbers => 'Nombres',
};

String _sample(ProjectTypographyRole role) => switch (role) {
  ProjectTypographyRole.display => 'Une nouvelle aventure',
  ProjectTypographyRole.body =>
    'Explorez le monde, découvrez ses secrets et rencontrez ses habitants.',
  ProjectTypographyRole.dialogue =>
    '« Prêt pour le départ ? Écoute bien : tout commence ici. »',
  ProjectTypographyRole.numbers => 'Niveau 42 · PV 128 / 160 · 9 999 ₽',
};

IconData _icon(ProjectTypographyRole role) => switch (role) {
  ProjectTypographyRole.display => Icons.title_outlined,
  ProjectTypographyRole.body => Icons.subject_outlined,
  ProjectTypographyRole.dialogue => Icons.chat_bubble_outline,
  ProjectTypographyRole.numbers => Icons.numbers_outlined,
};
