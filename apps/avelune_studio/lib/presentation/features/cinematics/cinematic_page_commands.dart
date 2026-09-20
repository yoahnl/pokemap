part of 'cinematic_workspace_page.dart';

extension _CinematicPageCommands on _CinematicWorkspacePageState {
  void save() {
    if (flush()) unawaited(controller.save());
  }

  void undo() {
    if (flush()) controller.undo();
  }

  void redo() {
    if (flush()) controller.redo();
  }

  void copy() {
    if (flush()) clipboard = controller.copySteps(view!.selection);
  }

  void paste() {
    if (flush() && clipboard != null) {
      final a = controller.active!.asset;
      final index = a.timeline.steps.indexWhere((s) => s.id == view!.stepId);
      controller.pasteSteps(
        clipboard!,
        index < 0 ? a.timeline.steps.length : index + 1,
      );
    }
  }

  void deleteSteps() {
    if (flush()) controller.deleteSteps(view!.selection);
  }

  void open(String id) {
    if (!flush()) return;
    controller.transport.pause();
    unawaited(controller.open(id));
  }

  Future<void> create() async {
    if (!flush()) return;
    final name = await askNarrativeName(
      context,
      'Nouvelle cinématique sur carte',
    );
    if (name != null && mounted) {
      await controller.create(
        name,
        folderId: widget.views.folderId.isEmpty ? null : widget.views.folderId,
      );
    }
  }

  void duplicate() {
    if (flush()) unawaited(controller.duplicate(controller.activeId!));
  }

  Future<bool> confirm(String title, String text) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            StudioButton(
              label: 'Annuler',
              secondary: true,
              onPressed: () => Navigator.pop(context, false),
            ),
            StudioButton(
              label: 'Confirmer',
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> delete() async {
    if (!flush()) return;
    final owner = controller.active;
    if (await confirm(
      'Supprimer la cinématique ?',
      'Les scènes qui l’utilisent empêchent sa suppression.',
    )) {
      if (mounted &&
          controller.activeId == owner?.asset.id &&
          controller.active?.revision == owner?.revision) {
        await controller.delete(owner!.asset.id);
      }
    }
  }

  Future<void> reload() async {
    if (!flush()) return;
    final owner = controller.active!;
    if (controller.active!.dirty &&
        !await confirm(
          'Recharger ?',
          'Le brouillon de cette cinématique sera remplacé par la version enregistrée.',
        )) {
      return;
    }
    if (mounted &&
        controller.activeId == owner.asset.id &&
        controller.active?.revision == owner.revision) {
      await controller.reload();
    }
  }

  Future<void> archive() async {
    if (!flush()) return;
    await controller.setArchived(
      controller.project.cinematicLibraryCatalog.entries
              .where(
                (e) =>
                    e.family == CinematicLibraryFamily.world &&
                    e.cinematicId == controller.activeId,
              )
              .firstOrNull
              ?.isArchived !=
          true,
    );
  }

  void play() {
    if (!flush()) return;
    if (controller.transport.playing) {
      controller.transport.pause();
      return;
    }
    preparePlan();
    controller.transport.play();
  }

  Future<void> addAction(CinematicTimelineStepKind kind) async {
    if (!flush()) return;
    final state = view!, asset = controller.active!.asset;
    final after = state.stepId;
    String? id;
    switch (kind) {
      case CinematicTimelineStepKind.wait:
        id = controller.addBasic(
          CinematicTimelineBasicBlockKind.wait,
          afterStepId: after,
          durationMs: 1000,
        );
      case CinematicTimelineStepKind.camera:
        id = controller.addBasic(
          CinematicTimelineBasicBlockKind.camera,
          afterStepId: after,
          durationMs: 1000,
          cameraMode: CinematicTimelineCameraMode.focus,
          cameraFocusBinding: CinematicTimelineCameraFocusBinding(
            target: CinematicCameraTargetBinding.sceneCenter(),
            zoomPreset: CinematicCameraZoomPreset.medium,
          ),
        );
      case CinematicTimelineStepKind.fade:
        id = controller.addBasic(
          CinematicTimelineBasicBlockKind.fade,
          afterStepId: after,
          durationMs: 600,
        );
      case CinematicTimelineStepKind.actorMove:
        final actor = state.actorId;
        if (actor == null) {
          state.error = 'Ajoutez et sélectionnez un acteur.';
          break;
        }
        final target =
            asset.movementTargets.firstOrNull?.targetId ??
            controller.addTarget('Destination à choisir');
        if (target != null) {
          id = controller.addMove(actor, target, afterStepId: after);
        }
        state.mode = CinematicMapMode.destination;
      case CinematicTimelineStepKind.actorFace:
        if (state.actorId == null) {
          state.error = 'Sélectionnez un acteur.';
          break;
        }
        id = controller.addFace(
          state.actorId!,
          CinematicTimelineActorFacingDirection.down,
          afterStepId: after,
        );
      case CinematicTimelineStepKind.actorEmote:
        if (state.actorId == null) {
          state.error = 'Sélectionnez un acteur.';
          break;
        }
        id = controller.addEmote(
          state.actorId!,
          afterStepId: after,
          durationMs: 1000,
        );
      case CinematicTimelineStepKind.dialogueLine:
        final selected = await choose('Dialogue', {
          for (final d in controller.project.dialogues) d.id: d.name,
        });
        if (selected != null && mounted && controller.activeId == asset.id) {
          id = controller.addCommand(
            kind,
            dialogueId: selected,
            afterStepId: after,
          );
        }
      case CinematicTimelineStepKind.sound ||
          CinematicTimelineStepKind.music ||
          CinematicTimelineStepKind.fx:
        final type = kind == CinematicTimelineStepKind.sound
            ? CinematicMediaAssetKind.sound
            : kind == CinematicTimelineStepKind.music
            ? CinematicMediaAssetKind.music
            : CinematicMediaAssetKind.cinematicFx;
        final media = controller.project.cinematicMediaAssets
            .where((m) => m.kind == type)
            .toList();
        final selected = await choose('Média disponible', {
          for (final m in media) m.id: m.label,
        });
        if (selected != null && mounted && controller.activeId == asset.id) {
          id = controller.addCommand(
            kind,
            mediaAsset: media.firstWhere((m) => m.id == selected),
            afterStepId: after,
          );
        }
      case CinematicTimelineStepKind.marker || CinematicTimelineStepKind.shake:
        id = controller.addCommand(
          kind,
          afterStepId: after,
          durationMs: kind == CinematicTimelineStepKind.shake ? 600 : null,
          label: kind == CinematicTimelineStepKind.marker ? 'Repère' : null,
        );
      case CinematicTimelineStepKind.actorAnimation:
        final actorId = state.actorId;
        final characterId =
            model?.actors.actorById(actorId ?? '')?.appearance.characterId ??
            asset.stageContext?.actorAppearanceBindings
                .where((b) => b.actorId == actorId)
                .firstOrNull
                ?.characterId;
        final character = controller.project.characters
            .where((c) => c.id == characterId)
            .firstOrNull;
        final clips = character?.customAnimations ?? const [];
        final selected = await choose('Animation disponible', {
          for (var i = 0; i < clips.length; i++)
            '$i':
                '${controller.project.characterStudioCatalog.customAnimationDefinitions.where((d) => d.id == clips[i].definitionId).firstOrNull?.displayName ?? clips[i].definitionId}${clips[i].direction == null ? '' : ' · ${clips[i].direction!.name}'}',
        });
        if (selected != null &&
            mounted &&
            controller.activeId == asset.id &&
            actorId != null) {
          final clip = clips[int.parse(selected)];
          id = controller.addAnimation(
            CharacterCustomAnimationRuntimeCommand(
              actorId: actorId,
              definitionId: clip.definitionId,
              direction: clip.direction,
            ),
            afterStepId: after,
          );
        }
    }
    if (!mounted) return;
    if (id != null) {
      state.selection
        ..clear()
        ..add(id);
      state.error = null;
    }
    refresh();
  }

  Future<String?> choose(String title, Map<String, String> options) =>
      showDialog<String>(
        context: context,
        builder: (context) => SimpleDialog(
          title: Text(title),
          children: options.isEmpty
              ? [
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Aucune ressource de ce type dans le projet.'),
                  ),
                ]
              : [
                  for (final entry in options.entries)
                    SimpleDialogOption(
                      onPressed: () => Navigator.pop(context, entry.key),
                      child: Text(entry.value),
                    ),
                ],
        ),
      );
}
