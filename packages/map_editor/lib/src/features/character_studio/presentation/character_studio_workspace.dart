import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../editor/state/editor_notifier.dart';
import '../../editor/state/editor_selectors.dart';
import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import 'character_studio_workspace_shell.dart';

class CharacterStudioWorkspace extends ConsumerStatefulWidget {
  const CharacterStudioWorkspace({super.key});

  @override
  ConsumerState<CharacterStudioWorkspace> createState() =>
      _CharacterStudioWorkspaceState();
}

class _CharacterStudioWorkspaceState
    extends ConsumerState<CharacterStudioWorkspace> {
  CharacterStudioSection _section = CharacterStudioSection.identity;

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(editorProjectManifestProvider);
    if (project == null) {
      return ColoredBox(
        key: const ValueKey<String>('character-studio-workspace'),
        color: context.pokeMapColors.contentSurface,
        child: const PokeMapEmptyState(
          title: 'Aucun projet ouvert',
          description: 'Ouvrez un projet pour accéder au Character Studio.',
          icon: Icon(CupertinoIcons.person_2_fill),
        ),
      );
    }
    final snapshot = ref.watch(
      editorNotifierProvider.select(
        (state) => (
          selectedCharacterId: state.selectedCharacterId,
          isSaving: state.isSaving,
          statusMessage: state.statusMessage,
        ),
      ),
    );
    final selectedCharacter = project.characters
        .where((character) => character.id == snapshot.selectedCharacterId)
        .firstOrNull;

    return CharacterStudioWorkspaceShell(
      key: const ValueKey<String>('character-studio-workspace'),
      project: project,
      isSaving: snapshot.isSaving,
      statusMessage: snapshot.statusMessage,
      library: _CharacterStudioPlaceholderRegion(
        title: 'Personnages',
        description: '${project.characters.length} dans le projet',
        icon: CupertinoIcons.person_2_fill,
        emptyTitle: project.characters.isEmpty
            ? 'Aucun personnage'
            : 'Bibliothèque prête',
        emptyDescription: project.characters.isEmpty
            ? 'Créez votre premier personnage depuis ce panneau.'
            : 'La liste détaillée arrive dans le prochain lot.',
      ),
      canvas: CharacterStudioCanvasFrame(
        characterName: selectedCharacter?.name,
        characterId: selectedCharacter?.id,
        tags: selectedCharacter?.tags ?? const <String>[],
        activeSection: _section,
        onSectionChanged: (section) => setState(() => _section = section),
        child: _CharacterStudioSectionPlaceholder(section: _section),
      ),
      inspector: const _CharacterStudioPlaceholderRegion(
        title: 'Inspecteur',
        description: 'Contexte de la sélection active',
        icon: CupertinoIcons.slider_horizontal_3,
        emptyTitle: 'Aucune propriété sélectionnée',
        emptyDescription:
            'Sélectionnez un personnage ou une propriété à inspecter.',
      ),
    );
  }
}

class _CharacterStudioPlaceholderRegion extends StatelessWidget {
  const _CharacterStudioPlaceholderRegion({
    required this.title,
    required this.description,
    required this.icon,
    required this.emptyTitle,
    required this.emptyDescription,
  });

  final String title;
  final String description;
  final IconData icon;
  final String emptyTitle;
  final String emptyDescription;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PokeMapSectionHeader(title: title, description: description),
          const SizedBox(height: 8),
          Expanded(
            child: PokeMapEmptyState(
              title: emptyTitle,
              description: emptyDescription,
              icon: Icon(icon),
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _CharacterStudioSectionPlaceholder extends StatelessWidget {
  const _CharacterStudioSectionPlaceholder({required this.section});

  final CharacterStudioSection section;

  @override
  Widget build(BuildContext context) {
    final (title, description, icon) = switch (section) {
      CharacterStudioSection.identity => (
        'Identité du personnage',
        'Sélectionnez un personnage pour modifier son identité.',
        CupertinoIcons.person_crop_circle,
      ),
      CharacterStudioSection.portraits => (
        'Portraits du personnage',
        'Les états globaux seront disponibles dans la session Portraits.',
        CupertinoIcons.photo,
      ),
      CharacterStudioSection.animations => (
        'Animations du personnage',
        'La matrice complète sera disponible dans la session Animations.',
        CupertinoIcons.play_rectangle,
      ),
    };
    return PokeMapEmptyState(
      title: title,
      description: description,
      icon: Icon(icon),
    );
  }
}
