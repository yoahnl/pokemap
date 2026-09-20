part of 'narrative_interaction_opener.dart';

extension NarrativeInteractionLoading on NarrativeInteractionOpener {
  Future<bool> _load(
    EditableMapDocument document,
    NarrativeEventSourceRef source,
    String name,
    ProjectManifest project,
    bool Function() valid, {
    ProjectDialogueEntry? existing,
    NarrativeInteractionDraft? interaction,
  }) async {
    final eventProblem = interaction == null
        ? null
        : controller.eventAccessProblem?.call(interaction.id);
    if (eventProblem != null) {
      controller.error = eventProblem;
      return false;
    }
    if (interaction != null && !_canOpenScene(interaction.sceneId)) {
      return false;
    }
    final id = _eventIds.generate(
      existingRecords: project.eventRegistry?.records ?? [],
    );
    final entry =
        existing ??
        ProjectDialogueEntry(
          id: 'dialogue_$id',
          name: name,
          relativePath: 'dialogues/$id.yarn',
          defaultStartNode: 'Start',
        );
    final dialogueProblem =
        controller.dialogueAccessProblem?.call(entry.id) ??
        controller.dialogueInteractionAccessProblem(entry.id);
    if (dialogueProblem != null) {
      controller.error = dialogueProblem;
      return false;
    }
    final original = existing == null
        ? null
        : await controller.port.readDialogue(existing);
    if (!valid() || controller.workspace.active != document) return false;
    final decoded = original == null
        ? null
        : const DialogueDraftCodec().decode(original);
    final rank = nextNarrativeRank(project, controller.sessions.values, source);
    final edit = InteractionEditSession(
      baseCatalog: project,
      baseEvent: project.eventRegistry?.records
          .where((record) => record.id == (interaction?.id ?? id))
          .firstOrNull,
      eventBaseKnown: true,
      accessProblem: () =>
          controller.dialogueAccessProblem?.call(entry.id) ??
          controller.sharedDialogueAccessProblem(
            entry.id,
            interaction?.id ?? id,
          ) ??
          controller.eventAccessProblem?.call(interaction?.id ?? id),
      baseScene: project.scenes
          .where((scene) => scene.id == (interaction?.sceneId ?? 'scene_$id'))
          .firstOrNull,
      sceneBaseKnown: true,
      document: document,
      dialogue: decoded ?? DialogueDraft.blank(entry),
      interaction:
          interaction ??
          NarrativeInteractionDraft(
            id: id,
            name: name,
            mapId: document.current.id,
            source: source,
            dialogueId: entry.id,
            order: rank.order,
            priority: rank.priority,
          ),
      readOnlySource: original != null && decoded == null
          ? original.source
          : null,
    );
    controller.sessions[edit.current.interaction.id] = edit;
    controller.active = edit;
    return true;
  }
}
