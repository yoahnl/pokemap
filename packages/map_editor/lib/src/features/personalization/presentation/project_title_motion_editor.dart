import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/pokemap_button.dart';
import '../../../ui/design_system/pokemap_card.dart';
import '../../../ui/design_system/pokemap_section_header.dart';
import '../application/project_title_motion_import_service.dart';

class ProjectTitleMotionEditor extends StatelessWidget {
  const ProjectTitleMotionEditor({
    super.key,
    required this.profile,
    required this.onImport,
    required this.onRemove,
  });

  final ProjectTitleMotionProfile? profile;
  final ValueChanged<ProjectTitleMotionLoopRole> onImport;
  final ValueChanged<ProjectTitleMotionLoopRole> onRemove;

  @override
  Widget build(BuildContext context) => Column(
    key: const ValueKey<String>('project-title-motion-editor'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      const PokeMapSectionHeader(
        title: 'Animations du titre',
        description:
            'Ajoutez une boucle avant le menu et une autre derrière le '
            'menu. Le mode mouvement réduit affiche automatiquement le '
            'poster.',
      ),
      const SizedBox(height: 8),
      _TitleMotionLoopCard(
        role: ProjectTitleMotionLoopRole.prompt,
        media: profile?.promptLoop,
        onImport: () => onImport(ProjectTitleMotionLoopRole.prompt),
        onRemove: profile?.promptLoop == null
            ? null
            : () => onRemove(ProjectTitleMotionLoopRole.prompt),
      ),
      const SizedBox(height: 10),
      _TitleMotionLoopCard(
        role: ProjectTitleMotionLoopRole.menu,
        media: profile?.menuLoop,
        onImport: () => onImport(ProjectTitleMotionLoopRole.menu),
        onRemove: profile?.menuLoop == null
            ? null
            : () => onRemove(ProjectTitleMotionLoopRole.menu),
      ),
    ],
  );
}

class _TitleMotionLoopCard extends StatelessWidget {
  const _TitleMotionLoopCard({
    required this.role,
    required this.media,
    required this.onImport,
    required this.onRemove,
  });

  final ProjectTitleMotionLoopRole role;
  final ProjectResponsiveVideoProfile? media;
  final VoidCallback onImport;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final variant = media?.landscape ?? media?.portrait;
    final label = switch (role) {
      ProjectTitleMotionLoopRole.prompt => 'Boucle d’invitation',
      ProjectTitleMotionLoopRole.menu => 'Boucle du menu',
    };
    final description = switch (role) {
      ProjectTitleMotionLoopRole.prompt =>
        'Visible avant que le joueur ouvre le menu du titre.',
      ProjectTitleMotionLoopRole.menu =>
        'Visible pendant les actions Nouvelle partie et Continuer.',
    };
    return PokeMapCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(description),
          const SizedBox(height: 8),
          Text(variant?.videoPath ?? 'Aucune boucle importée'),
          if (variant != null) ...<Widget>[
            const SizedBox(height: 3),
            Text('Poster : ${variant.posterPath}'),
          ],
          const SizedBox(height: 5),
          const Text('MP4 H.264 • 15 s et 24 Mio maximum par boucle'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              PokeMapButton(
                key: ValueKey<String>('title-motion-import-${role.name}'),
                size: PokeMapButtonSize.compact,
                leading: const Icon(Icons.movie_creation_outlined),
                onPressed: onImport,
                child: Text(variant == null ? 'Importer' : 'Remplacer'),
              ),
              PokeMapButton(
                key: ValueKey<String>('title-motion-remove-${role.name}'),
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
