part of 'narrative_workspace_controller.dart';

extension NarrativeWorkspacePublication on NarrativeWorkspaceController {
  Future<bool> _save({EditableMapDocument? document}) async {
    if (busy || _disposed || workspace.isDisposed) return false;
    if (saveStoryDrafts != null && !await saveStoryDrafts!()) {
      error = publicationError ?? 'Les histoires n’ont pas été enregistrées.';
      changed();
      return false;
    }
    if (_disposed || workspace.isDisposed) return false;
    final target = document ?? active?.document ?? workspace.active;
    if (target == null) {
      if (saveStoryDrafts != null && !dirty) return true;
      error = 'Ouvrez une carte pour enregistrer cette histoire.';
      changed();
      return false;
    }
    if (target.saving) return false;
    final edits = sessions.values
        .where((s) => s.document == target && s.dirty)
        .toList();
    final snapshots = {for (final edit in edits) edit: edit.current};
    for (final edit in edits) {
      final sceneId = edit.current.interaction.sceneId;
      final stored = project.scenes
          .where((scene) => scene.id == sceneId)
          .firstOrNull;
      final problem = edit.readOnlySource != null
          ? 'Ce dialogue est en lecture seule.'
          : interactionBaseProblem(edit) ??
                sceneAccessProblem?.call(sceneId) ??
                (edit.sceneBaseKnown && stored != edit.baseScene
                    ? 'La scène liée a changé. Votre brouillon d’interaction est conservé ; ouvrez la scène actuelle avant de poursuivre.'
                    : null);
      if (problem != null) {
        error = publicationError = problem;
        changed();
        return false;
      }
    }
    final factSnapshot = saveStoryDrafts == null
        ? Map.of(pendingFacts)
        : <String, NarrativeFactDefinition>{};
    final storySnapshot = saveStoryDrafts == null
        ? Map.of(pendingStories)
        : <String, StorylineAsset>{};
    if (edits.isEmpty && factSnapshot.isEmpty && storySnapshot.isEmpty) {
      return workspace.save(target);
    }
    saving = true;
    _publishingInteractions.addAll(
      snapshots.values.map((state) => state.interaction.id),
    );
    error = null;
    target.saving = true;
    changed();
    try {
      final projections = snapshots.values
          .map((s) => s.interaction.project())
          .toList();
      final receipt = await port.publish(
        NarrativePublication(
          base: target.base,
          current: target.current,
          dialogues: snapshots.values.map((s) {
            final source = const DialogueDraftCodec().encode(s.dialogue);
            return NarrativeDialogueSource(
              entry: source.entry,
              source: source.source,
              revision: _sourceRevisions[source.entry.id] ?? source.revision,
            );
          }).toList(),
          scenes: projections.map((p) => p.scene).toList(),
          cinematics: projections.expand((p) => p.cinematics).toList(),
          events: projections.map((p) => p.event).toList(),
          expectedEvents: {
            for (final edit in edits)
              edit.current.interaction.id: edit.eventBaseKnown
                  ? edit.baseEvent
                  : project.eventRegistry?.records
                        .where((r) => r.id == edit.current.interaction.id)
                        .firstOrNull,
          },
          expectedScenes: {
            for (final edit in edits)
              edit.current.interaction.sceneId: edit.sceneBaseKnown
                  ? edit.baseScene
                  : project.scenes
                        .where((s) => s.id == edit.current.interaction.sceneId)
                        .firstOrNull,
          },
          expectedCinematics: {
            for (final edit in edits)
              for (final value in edit.current.interaction.project().cinematics)
                value.id: (edit.baseCatalog ?? project).cinematics
                    .where((c) => c.id == value.id)
                    .firstOrNull,
          },
          facts: factSnapshot.values.toList(),
          storylines: storySnapshot.values.toList(),
          expectedDialogues: {
            for (final edit in edits)
              edit.current.dialogue.entry.id: (edit.baseCatalog ?? project)
                  .dialogues
                  .where((entry) => entry.id == edit.current.dialogue.entry.id)
                  .firstOrNull,
          },
          expectedFacts: {
            for (final id in factSnapshot.keys)
              id: project.facts.where((fact) => fact.id == id).firstOrNull,
          },
          expectedStorylines: {
            for (final id in storySnapshot.keys)
              id: project.storylines
                  .where((story) => story.id == id)
                  .firstOrNull,
          },
        ),
      );
      if (_disposed ||
          workspace.isDisposed ||
          snapshots.keys.any(
            (edit) => sessions[edit.current.interaction.id] != edit,
          )) {
        return false;
      }
      workspace.acceptResources(receipt.beforeManifest, receipt.manifest);
      target.acceptSave(receipt.savedMap, receipt.revision);
      _sourceRevisions.addAll(receipt.sourceRevisions);
      for (final entry in snapshots.entries) {
        entry.key.acceptSave(entry.value);
        entry.key.baseScene = receipt.manifest.scenes
            .where((scene) => scene.id == entry.value.interaction.sceneId)
            .firstOrNull;
        entry.key.baseEvent = receipt.manifest.eventRegistry?.records
            .where((record) => record.id == entry.value.interaction.id)
            .firstOrNull;
        entry.key.baseCatalog = receipt.manifest;
      }
      pendingFacts.removeWhere((id, v) => identical(factSnapshot[id], v));
      pendingStories.removeWhere((id, v) => identical(storySnapshot[id], v));
      await acceptVisuals(receipt.manifest, receipt.changedPaths.toSet());
      if (_disposed || workspace.isDisposed) return false;
      publicationError = null;
      return true;
    } catch (e) {
      if (!_disposed && !workspace.isDisposed) {
        publicationError = error = e.toString();
      }
      return false;
    } finally {
      _publishingInteractions.clear();
      saving = false;
      target.saving = false;
      if (!_disposed && !workspace.isDisposed) changed();
    }
  }

  Future<bool> saveAll() async {
    if (workspace.documents.isEmpty) return save();
    for (final document in workspace.documents.values.toList()) {
      if (!await save(document: document)) return false;
    }
    return !dirty;
  }
}
