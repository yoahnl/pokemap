import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../editor/state/editor_notifier.dart';
import '../../editor/state/editor_selectors.dart';
import '../../editor/state/editor_state.dart';
import '../../../theme/theme.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/character_studio_media_resolver.dart';
import 'animations/character_studio_animations_tab.dart';
import 'catalog/animation_definition_manager.dart';
import 'catalog/portrait_state_manager.dart';
import 'identity/character_studio_delete_dialog.dart';
import 'identity/character_studio_identity_draft_controller.dart';
import 'identity/character_studio_identity_editor.dart';
import 'identity/character_studio_inspector.dart';
import 'library/character_studio_library.dart';
import 'portraits/character_studio_portraits_tab.dart';
import 'portraits/portrait_inspector.dart';
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
  String? _selectedPortraitStateId;
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
    final selectedPortraitStateId = _portraitStateId(project);

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
          (CharacterStudioSection.portraits, final character?) =>
            CharacterStudioPortraitsTab(
              project: project,
              character: character,
              projectRootPath: editorState.projectRootPath ?? '',
              projectRevision: Object.hash(
                project,
                notifier.projectSessionRevision,
              ).toString(),
              mediaResolver: _mediaResolver,
              isSaving: snapshot.isSaving,
              onImport: (stateId) => notifier.importCharacterPortrait(
                characterId: character.id,
                portraitStateId: stateId,
                fitMode:
                    character.portraits
                        .where(
                          (portrait) => portrait.portraitStateId == stateId,
                        )
                        .firstOrNull
                        ?.fitMode ??
                    CharacterPortraitFitMode.contain,
              ),
              onClear: (stateId) => notifier.clearCharacterPortrait(
                characterId: character.id,
                portraitStateId: stateId,
              ),
              onFitChanged: (stateId, fitMode) =>
                  notifier.setCharacterPortraitFitMode(
                    characterId: character.id,
                    portraitStateId: stateId,
                    fitMode: fitMode,
                  ),
              onManageGlobalStates: () =>
                  unawaited(_showPortraitStateManager()),
              selectedStateId: _selectedPortraitStateId,
              onSelectionChanged: (stateId) =>
                  setState(() => _selectedPortraitStateId = stateId),
            ),
          (CharacterStudioSection.animations, final character?) =>
            CharacterStudioAnimationsTab(
              project: project,
              character: character,
              projectRootPath: editorState.projectRootPath ?? '',
              projectRevision: Object.hash(
                project,
                notifier.projectSessionRevision,
              ).toString(),
              mediaResolver: _mediaResolver,
              isSaving: snapshot.isSaving,
              onManageDefinitions: _showAnimationDefinitionManager,
              onImportSource: (slot) => notifier.importCharacterAnimationSource(
                characterId: character.id,
                slotKey: slot.key,
                currentSourceAssetId: slot.sourceAssetId,
                loop: slot.loop,
              ),
              onSaveClip: (slot, frames, loop) =>
                  notifier.saveCharacterAnimationClip(
                    characterId: character.id,
                    slotKey: slot.key,
                    sourceAssetId: slot.sourceAssetId,
                    frames: frames,
                    loop: loop,
                  ),
            ),
          _ => _CharacterStudioSectionPlaceholder(section: _section),
        },
      ),
      inspector: switch ((_section, selectedCharacter)) {
        (CharacterStudioSection.portraits, final character?)
            when selectedPortraitStateId != null =>
          PortraitInspector(
            project: project,
            character: character,
            portraitStateId: selectedPortraitStateId,
            projectRootPath: editorState.projectRootPath ?? '',
            projectRevision: Object.hash(
              project,
              notifier.projectSessionRevision,
            ).toString(),
            mediaResolver: _mediaResolver,
            isSaving: snapshot.isSaving,
            onReplace: () => notifier.importCharacterPortrait(
              characterId: character.id,
              portraitStateId: selectedPortraitStateId,
              fitMode:
                  character.portraits
                      .where(
                        (portrait) =>
                            portrait.portraitStateId == selectedPortraitStateId,
                      )
                      .firstOrNull
                      ?.fitMode ??
                  CharacterPortraitFitMode.contain,
            ),
            onFitChanged: (fitMode) => notifier.setCharacterPortraitFitMode(
              characterId: character.id,
              portraitStateId: selectedPortraitStateId,
              fitMode: fitMode,
            ),
          ),
        _ => CharacterStudioInspector(
          project: project,
          character: selectedCharacter,
        ),
      },
    );
  }

  String? _portraitStateId(ProjectManifest project) {
    final states = project.characterStudioCatalog.portraitStates;
    if (states.isEmpty) return null;
    final selected = _selectedPortraitStateId;
    if (selected != null && states.any((state) => state.id == selected)) {
      return selected;
    }
    final sorted = states.toList()
      ..sort((left, right) {
        final order = left.sortOrder.compareTo(right.sortOrder);
        return order != 0 ? order : left.id.compareTo(right.id);
      });
    return sorted.first.id;
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

  Future<void> _showPortraitStateManager() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final project = ref.watch(editorProjectManifestProvider);
            final isSaving = ref.watch(
              editorNotifierProvider.select((state) => state.isSaving),
            );
            final notifier = ref.read(editorNotifierProvider.notifier);
            return PokeMapDialog(
              title: 'Expressions globales du projet',
              icon: CupertinoIcons.person_2_square_stack_fill,
              maxWidth: 780,
              footer: Align(
                alignment: Alignment.centerRight,
                child: PokeMapButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  variant: PokeMapButtonVariant.secondary,
                  child: const Text('Fermer'),
                ),
              ),
              child: SizedBox(
                height: 600,
                child: project == null
                    ? const PokeMapEmptyState(
                        title: 'Projet indisponible',
                        description:
                            'Rouvrez le projet pour gérer ses expressions.',
                      )
                    : PortraitStateManager(
                        project: project,
                        isSaving: isSaving,
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
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAnimationDefinitionManager() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Consumer(
          builder: (context, ref, _) {
            final project = ref.watch(editorProjectManifestProvider);
            final isSaving = ref.watch(
              editorNotifierProvider.select((state) => state.isSaving),
            );
            final notifier = ref.read(editorNotifierProvider.notifier);
            return PokeMapDialog(
              title: 'Animations globales du projet',
              icon: CupertinoIcons.play_rectangle_fill,
              maxWidth: 860,
              footer: Align(
                alignment: Alignment.centerRight,
                child: PokeMapButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  variant: PokeMapButtonVariant.secondary,
                  child: const Text('Fermer'),
                ),
              ),
              child: SizedBox(
                height: 680,
                child: project == null
                    ? const PokeMapEmptyState(
                        title: 'Projet indisponible',
                        description:
                            'Rouvrez le projet pour gérer ses animations.',
                      )
                    : AnimationDefinitionManager(
                        project: project,
                        isSaving: isSaving,
                        onCreate: notifier.createAnimationDefinition,
                        onUpdate: (id, label, mode) =>
                            notifier.updateAnimationDefinition(
                              id,
                              displayName: label,
                              mode: mode,
                            ),
                        onReorder: notifier.reorderAnimationDefinitions,
                        onPreviewDelete:
                            notifier.previewDeleteAnimationDefinition,
                        onDelete: (id, resolution, replacementId) =>
                            notifier.deleteAnimationDefinition(
                              id,
                              resolution: resolution,
                              replacementId: replacementId,
                            ),
                      ),
              ),
            );
          },
        );
      },
    );
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
