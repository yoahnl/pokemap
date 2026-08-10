import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../editor/state/editor_notifier.dart';
import '../../editor/state/editor_selectors.dart';
import '../../editor/state/editor_state.dart';
import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/character_studio_media_resolver.dart';
import 'catalog/portrait_state_manager.dart';
import 'identity/character_studio_delete_dialog.dart';
import 'identity/character_studio_identity_draft_controller.dart';
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
  final CharacterStudioMediaResolver _mediaResolver =
      CharacterStudioMediaResolver(
        source: const FileCharacterStudioMediaSource(),
      );

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
    final editorState = ref.watch(editorNotifierProvider);
    final projectRootPath = _draftProjectKey(editorState);
    final identityDraft = selectedCharacterId == null
        ? null
        : ref
              .watch(characterStudioIdentityDraftProvider)
              .draftFor(
                projectRootPath: projectRootPath,
                characterId: selectedCharacterId,
              );

    return CharacterStudioWorkspaceShell(
      key: const ValueKey<String>('character-studio-workspace'),
      project: project,
      isSaving: snapshot.isSaving,
      hasUnsavedChanges: identityDraft != null,
      statusMessage: snapshot.statusMessage,
      library: CharacterStudioLibrary(
        project: project,
        selectedCharacterId: selectedCharacterId,
        isSaving: snapshot.isSaving,
        resolveTilesetPath: notifier.getTilesetAbsolutePathById,
        canCreate: _discardIdentityChangesIfNeeded,
        projectRootPath: editorState.projectRootPath,
        projectRevision: Object.hash(
          project,
          notifier.projectSessionRevision,
        ).toString(),
        mediaResolver: _mediaResolver,
        onSelect: (characterId) => unawaited(_selectCharacter(characterId)),
        onCreate: (draft) => unawaited(_createCharacter(draft)),
      ),
      canvas: CharacterStudioCanvasFrame(
        characterName: selectedCharacter?.name,
        characterId: selectedCharacter?.id,
        tags: selectedCharacter?.tags ?? const <String>[],
        activeSection: _section,
        onSectionChanged: (section) => unawaited(_selectSection(section)),
        child: switch ((_section, selectedCharacter)) {
          (CharacterStudioSection.identity, final character?) =>
            CharacterStudioIdentityEditor(
              project: project,
              character: character,
              isDefaultCharacter:
                  project.settings.defaultPlayerCharacterId == character.id,
              isSaving: snapshot.isSaving,
              initialDraft: identityDraft,
              onDraftChanged: (draft) => _updateIdentityDraft(
                projectRootPath: projectRootPath,
                character: character,
                draft: draft,
              ),
              onSave: (draft) => unawaited(_saveIdentity(character.id, draft)),
              onSetDefault: () =>
                  unawaited(notifier.setPlayerCharacter(character.id)),
              onDelete: () => unawaited(_deleteCharacter(character.id)),
            ),
          (CharacterStudioSection.portraits, _) => PortraitStateManager(
            project: project,
            isSaving: snapshot.isSaving,
            onCreate: notifier.createPortraitState,
            onRename: notifier.renamePortraitState,
            onReorder: notifier.reorderPortraitStates,
            onPreviewDelete: notifier.previewDeletePortraitState,
            onDelete: (id, resolution, replacementId) =>
                notifier.deletePortraitState(
                  id,
                  resolution: resolution,
                  replacementId: replacementId,
                ),
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

  void _updateIdentityDraft({
    required String projectRootPath,
    required ProjectCharacterEntry character,
    required CharacterIdentityFormDraft draft,
  }) {
    final controller = ref.read(characterStudioIdentityDraftProvider.notifier);
    if (draft.matches(character)) {
      controller.clear(
        projectRootPath: projectRootPath,
        characterId: character.id,
      );
      return;
    }
    controller.update(
      projectRootPath: projectRootPath,
      characterId: character.id,
      draft: draft,
    );
  }

  Future<bool> _discardIdentityChangesIfNeeded() async {
    final editorState = ref.read(editorNotifierProvider);
    final characterId =
        editorState.selectedCharacterId ??
        editorState.project?.characters.firstOrNull?.id;
    if (characterId == null) return true;
    final projectRootPath = _draftProjectKey(editorState);
    final controller = ref.read(characterStudioIdentityDraftProvider.notifier);
    final draft = ref
        .read(characterStudioIdentityDraftProvider)
        .draftFor(projectRootPath: projectRootPath, characterId: characterId);
    if (draft == null) return true;
    final discard = await showPokeMapConfirmationDialog<bool>(
      context: context,
      title: 'Modifications non enregistrées',
      message:
          'L’identité du personnage contient des changements non enregistrés.',
      actions: const <PokeMapDialogAction<bool>>[
        PokeMapDialogAction<bool>(label: 'Rester ici', value: false),
        PokeMapDialogAction<bool>(
          label: 'Ignorer les modifications',
          value: true,
          variant: PokeMapButtonVariant.danger,
        ),
      ],
    );
    if (discard != true) return false;
    controller.clear(
      projectRootPath: projectRootPath,
      characterId: characterId,
    );
    return true;
  }

  Future<void> _selectCharacter(String characterId) async {
    final editorState = ref.read(editorNotifierProvider);
    final selectedId =
        editorState.selectedCharacterId ??
        editorState.project?.characters.firstOrNull?.id;
    if (selectedId == characterId) return;
    if (!await _discardIdentityChangesIfNeeded() || !mounted) return;
    ref.read(editorNotifierProvider.notifier).selectCharacter(characterId);
  }

  Future<void> _selectSection(CharacterStudioSection section) async {
    if (_section == section) return;
    if (_section == CharacterStudioSection.identity &&
        !await _discardIdentityChangesIfNeeded()) {
      return;
    }
    if (!mounted) return;
    setState(() => _section = section);
  }

  Future<void> _createCharacter(CharacterCreateDraft draft) async {
    await ref
        .read(editorNotifierProvider.notifier)
        .createCharacter(
          name: draft.name,
          tilesetId: draft.tilesetId,
          frameWidth: draft.frameWidth,
          frameHeight: draft.frameHeight,
        );
  }

  Future<void> _saveIdentity(
    String characterId,
    CharacterIdentityDraft draft,
  ) async {
    final notifier = ref.read(editorNotifierProvider.notifier);
    await notifier.updateCharacter(
      characterId: characterId,
      name: draft.name,
      tilesetId: draft.tilesetId,
      frameWidth: draft.frameWidth,
      frameHeight: draft.frameHeight,
      tags: draft.tags,
    );
    if (!mounted) return;
    final editorState = ref.read(editorNotifierProvider);
    if (editorState.errorMessage != null) return;
    final saved = editorState.project?.characters
        .where((character) => character.id == characterId)
        .firstOrNull;
    if (saved == null ||
        saved.name != draft.name ||
        saved.tilesetId != draft.tilesetId ||
        saved.frameWidth != draft.frameWidth ||
        saved.frameHeight != draft.frameHeight ||
        !_sameTags(saved.tags, draft.tags)) {
      return;
    }
    ref
        .read(characterStudioIdentityDraftProvider.notifier)
        .clear(
          projectRootPath: _draftProjectKey(editorState),
          characterId: characterId,
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
    if (mounted &&
        ref
                .read(editorProjectManifestProvider)
                ?.characters
                .every((character) => character.id != characterId) ==
            true) {
      ref
          .read(characterStudioIdentityDraftProvider.notifier)
          .clear(
            projectRootPath: _draftProjectKey(ref.read(editorNotifierProvider)),
            characterId: characterId,
          );
    }
  }
}

String _draftProjectKey(EditorState state) {
  final root = state.projectRootPath?.trim();
  if (root != null && root.isNotEmpty) return root;
  return 'memory:${state.project?.name ?? 'character-studio'}';
}

bool _sameTags(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
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
