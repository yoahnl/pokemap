import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../editor/state/editor_notifier.dart';
import '../../editor/state/editor_selectors.dart';
import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import 'identity/character_studio_delete_dialog.dart';
import 'identity/character_studio_identity_editor.dart';
import 'identity/character_studio_inspector.dart';
import 'library/character_studio_library.dart';
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
    final selectedCharacter =
        project.characters
            .where((character) => character.id == snapshot.selectedCharacterId)
            .firstOrNull ??
        project.characters.firstOrNull;
    final selectedCharacterId = selectedCharacter?.id;
    final notifier = ref.read(editorNotifierProvider.notifier);

    return CharacterStudioWorkspaceShell(
      key: const ValueKey<String>('character-studio-workspace'),
      project: project,
      isSaving: snapshot.isSaving,
      statusMessage: snapshot.statusMessage,
      library: CharacterStudioLibrary(
        project: project,
        selectedCharacterId: selectedCharacterId,
        onSelect: notifier.selectCharacter,
        onCreate: (draft) => unawaited(
          notifier.createCharacter(
            name: draft.name,
            tilesetId: draft.tilesetId,
            frameWidth: draft.frameWidth,
            frameHeight: draft.frameHeight,
          ),
        ),
      ),
      canvas: CharacterStudioCanvasFrame(
        characterName: selectedCharacter?.name,
        characterId: selectedCharacter?.id,
        tags: selectedCharacter?.tags ?? const <String>[],
        activeSection: _section,
        onSectionChanged: (section) => setState(() => _section = section),
        child: switch ((_section, selectedCharacter)) {
          (CharacterStudioSection.identity, final character?) =>
            CharacterStudioIdentityEditor(
              project: project,
              character: character,
              isDefaultCharacter:
                  project.settings.defaultPlayerCharacterId == character.id,
              isSaving: snapshot.isSaving,
              onSave: (draft) => unawaited(
                notifier.updateCharacter(
                  characterId: character.id,
                  name: draft.name,
                  tilesetId: draft.tilesetId,
                  frameWidth: draft.frameWidth,
                  frameHeight: draft.frameHeight,
                  tags: draft.tags,
                ),
              ),
              onSetDefault: () =>
                  unawaited(notifier.setPlayerCharacter(character.id)),
              onDelete: () => unawaited(_deleteCharacter(character.id)),
            ),
          _ => _CharacterStudioSectionPlaceholder(section: _section),
        },
      ),
      inspector: CharacterStudioInspector(
        project: project,
        character: selectedCharacter,
      ),
    );
  }

  Future<void> _deleteCharacter(String characterId) async {
    final notifier = ref.read(editorNotifierProvider.notifier);
    final plan = await notifier.previewDeleteCharacter(characterId);
    if (!mounted || plan == null) return;
    final project = ref.read(editorProjectManifestProvider);
    final character = project?.characters
        .where((entry) => entry.id == characterId)
        .firstOrNull;
    if (character == null) return;
    final decision = await showCharacterDeleteDialog(
      context: context,
      characterName: character.name,
      plan: plan,
    );
    if (!mounted || decision == null) return;
    await notifier.deleteCharacter(
      characterId,
      resolution: decision.resolution,
      replacementId: decision.replacementId,
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
