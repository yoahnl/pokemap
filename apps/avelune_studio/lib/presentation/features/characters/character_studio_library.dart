import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'character_studio_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../map_workspace/map_workspace_visuals.dart';
import 'character_workspace_visuals.dart';
import 'character_studio_create_dialog.dart';

class CharacterStudioLibrary extends StatelessWidget {
  const CharacterStudioLibrary({
    super.key,
    required this.project,
    required this.visuals,
    required this.controller,
    required this.search,
    required this.onCreate,
  });

  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final CharacterStudioController controller;
  final TextEditingController search;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final visible = controller.visibleCharacters;
    return StudioPanel(
      title: 'Personnages · ${visible.length}',
      compact: true,
      children: [
        TextField(
          key: const ValueKey('character-studio-search'),
          controller: search,
          decoration: const InputDecoration(
            hintText: 'Rechercher…',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: controller.setQuery,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Text(
                    project.characters.isEmpty
                        ? 'Aucun personnage dans ce projet.'
                        : 'Aucun résultat.',
                  ),
                )
              : ListView.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final character = visible[index];
                    final selected =
                        controller.selectedCharacter?.id == character.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Material(
                        color: selected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        child: ListTile(
                          key: ValueKey('character-studio-${character.id}'),
                          dense: true,
                          leading: character.animations.isEmpty
                              ? const Icon(Icons.person_outline)
                              : visuals is CharacterWorkspaceVisuals
                              ? (visuals as CharacterWorkspaceVisuals)
                                    .characterThumbnail(character, size: 38)
                              : const Icon(Icons.person),
                          title: Text(
                            character.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle:
                              controller.selectedId == character.id &&
                                  controller.selectedDraft?.dirty == true
                              ? const Text('Brouillon modifié')
                              : null,
                          onTap: () => controller.select(character.id),
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        StudioButton(
          label: 'Nouveau personnage',
          icon: Icons.add,
          onPressed: compatibleCharacterStudioTilesets(project).isEmpty
              ? null
              : onCreate,
        ),
      ],
    );
  }
}
