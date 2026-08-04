import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/pokemap_button.dart';
import '../../../ui/design_system/pokemap_card.dart';
import '../../../ui/design_system/pokemap_dropdown_field.dart';
import '../../../ui/design_system/pokemap_section_header.dart';
import '../application/project_branding_image_import_service.dart';
import 'project_branding_title_preview.dart';

class ProjectBrandingEditor extends StatelessWidget {
  const ProjectBrandingEditor({
    super.key,
    required this.profile,
    required this.onImportImage,
    required this.onRemoveImage,
    this.projectName = 'Projet',
    this.projectRootPath = '',
    this.theme = safeProjectSemanticTheme,
    this.typography,
    this.onEditAccent,
    this.onResetAccent,
    this.onLayoutVariantChanged,
    this.onImportTitleMusic,
    this.onToggleTitleMusicPreview,
    this.onRemoveTitleMusic,
    this.isTitleMusicPreviewPlaying = false,
  });

  final ProjectBrandingProfile profile;
  final ValueChanged<ProjectBrandingImageRole> onImportImage;
  final ValueChanged<ProjectBrandingImageRole> onRemoveImage;
  final String projectName;
  final String projectRootPath;
  final ProjectSemanticThemeProfile theme;
  final ProjectTypographyProfile? typography;
  final VoidCallback? onEditAccent;
  final VoidCallback? onResetAccent;
  final ValueChanged<String>? onLayoutVariantChanged;
  final VoidCallback? onImportTitleMusic;
  final VoidCallback? onToggleTitleMusicPreview;
  final VoidCallback? onRemoveTitleMusic;
  final bool isTitleMusicPreviewPlaying;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey<String>('project-branding-editor'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ProjectBrandingTitlePreview(
          projectName: projectName,
          projectRootPath: projectRootPath,
          branding: profile,
          theme: theme,
          typography: typography,
        ),
        const SizedBox(height: 18),
        const PokeMapSectionHeader(
          title: 'Images de marque',
          description:
              'Importez des fichiers appartenant au projet. Le logo du titre '
              'utilise le rôle hero.',
        ),
        const SizedBox(height: 8),
        for (final role in ProjectBrandingImageRole.values) ...<Widget>[
          _BrandingImageRoleCard(
            role: role,
            path: _pathForRole(profile, role),
            onImport: () => onImportImage(role),
            onRemove: _pathForRole(profile, role) == null
                ? null
                : () => onRemoveImage(role),
          ),
          if (role != ProjectBrandingImageRole.values.last)
            const SizedBox(height: 10),
        ],
        const SizedBox(height: 18),
        const PokeMapSectionHeader(
          title: 'Identité du titre',
          description:
              'Choisissez la coque de la cartouche Avelune, les accents du '
              'titre et la composition générale.',
        ),
        const SizedBox(height: 8),
        PokeMapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Couleur de cartouche Avelune et accent',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text(
                'Cette couleur teinte la coque de la cartouche dans Avelune '
                'et les accents de l’écran titre.',
              ),
              const SizedBox(height: 6),
              Text(profile.accentColor ?? 'Thème par défaut'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  PokeMapButton(
                    key: const ValueKey<String>('branding-edit-accent'),
                    size: PokeMapButtonSize.compact,
                    leading: const Icon(Icons.colorize_outlined),
                    onPressed: onEditAccent,
                    child: const Text('Modifier'),
                  ),
                  PokeMapButton(
                    key: const ValueKey<String>('branding-reset-accent'),
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.compact,
                    onPressed:
                        profile.accentColor == null ? null : onResetAccent,
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              PokeMapDropdownField<String>(
                key: const ValueKey<String>('branding-layout'),
                label: 'Disposition du titre',
                value: profile.layoutVariant,
                items: const <PokeMapDropdownItem<String>>[
                  PokeMapDropdownItem<String>(
                    value: 'standard',
                    label: 'Standard',
                  ),
                  PokeMapDropdownItem<String>(
                    value: 'centered',
                    label: 'Centrée',
                  ),
                  PokeMapDropdownItem<String>(
                    value: 'cinematic',
                    label: 'Cinématique',
                  ),
                ],
                enabled: onLayoutVariantChanged != null,
                onChanged: onLayoutVariantChanged ?? (_) {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const PokeMapSectionHeader(
          title: 'Musique du titre',
          description:
              'Importez un morceau appartenant au projet et écoutez-le avant '
              'd’enregistrer le profil.',
        ),
        const SizedBox(height: 8),
        PokeMapCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(profile.titleMusicPath ?? 'Aucun morceau importé'),
              const SizedBox(height: 4),
              const Text(
                'OGG, WAV, MP3, FLAC ou M4A • 30 Mio maximum',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  PokeMapButton(
                    key: const ValueKey<String>(
                      'branding-import-title-music',
                    ),
                    size: PokeMapButtonSize.compact,
                    leading: const Icon(Icons.library_music_outlined),
                    onPressed: onImportTitleMusic,
                    child: Text(
                      profile.titleMusicPath == null ? 'Importer' : 'Remplacer',
                    ),
                  ),
                  PokeMapButton(
                    key: const ValueKey<String>(
                      'branding-preview-title-music',
                    ),
                    variant: PokeMapButtonVariant.secondary,
                    size: PokeMapButtonSize.compact,
                    leading: Icon(
                      isTitleMusicPreviewPlaying
                          ? Icons.stop_rounded
                          : Icons.play_arrow_rounded,
                    ),
                    onPressed: profile.titleMusicPath == null
                        ? null
                        : onToggleTitleMusicPreview,
                    child: Text(
                      isTitleMusicPreviewPlaying ? 'Arrêter' : 'Écouter',
                    ),
                  ),
                  PokeMapButton(
                    key: const ValueKey<String>(
                      'branding-remove-title-music',
                    ),
                    variant: PokeMapButtonVariant.ghost,
                    size: PokeMapButtonSize.compact,
                    leading: const Icon(Icons.delete_outline_rounded),
                    onPressed: profile.titleMusicPath == null
                        ? null
                        : onRemoveTitleMusic,
                    child: const Text('Retirer'),
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

class _BrandingImageRoleCard extends StatelessWidget {
  const _BrandingImageRoleCard({
    required this.role,
    required this.path,
    required this.onImport,
    required this.onRemove,
  });

  final ProjectBrandingImageRole role;
  final String? path;
  final VoidCallback onImport;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            _roleLabel(role),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(path ?? 'Aucun fichier importé'),
          const SizedBox(height: 4),
          Text(_roleRequirements(role)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              PokeMapButton(
                key: ValueKey<String>('branding-import-${role.name}'),
                size: PokeMapButtonSize.compact,
                leading: const Icon(Icons.upload_file_outlined),
                onPressed: onImport,
                child: Text(path == null ? 'Importer' : 'Remplacer'),
              ),
              PokeMapButton(
                key: ValueKey<String>('branding-remove-${role.name}'),
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.compact,
                leading: const Icon(Icons.delete_outline_rounded),
                onPressed: onRemove,
                child: const Text('Retirer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String? _pathForRole(
  ProjectBrandingProfile profile,
  ProjectBrandingImageRole role,
) =>
    switch (role) {
      ProjectBrandingImageRole.icon => profile.iconPath,
      ProjectBrandingImageRole.cover => profile.coverPath,
      ProjectBrandingImageRole.hero => profile.heroPath,
    };

String _roleLabel(ProjectBrandingImageRole role) => switch (role) {
      ProjectBrandingImageRole.icon => 'Icône du jeu',
      ProjectBrandingImageRole.cover => 'Cover de bibliothèque',
      ProjectBrandingImageRole.hero => 'Logo / hero du titre',
    };

String _roleRequirements(ProjectBrandingImageRole role) => switch (role) {
      ProjectBrandingImageRole.icon =>
        'PNG, JPEG ou WebP • image carrée, de 64 × 64 à 1024 × 1024 px • 10 Mio maximum',
      ProjectBrandingImageRole.cover =>
        'PNG, JPEG ou WebP • minimum 640 × 360 px • 4096 px par côté • 10 Mio maximum',
      ProjectBrandingImageRole.hero =>
        'PNG, JPEG ou WebP • minimum 256 × 128 px • 4096 px par côté • 10 Mio maximum',
    };
