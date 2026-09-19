import 'package:map_core/map_core_domain.dart';
import '../../map_workspace/application/map_workspace_controller.dart';
import '../../map_workspace/application/editable_map_document.dart';
import '../domain/dialogue_draft.dart';
import '../domain/narrative_port.dart';
import 'dialogue_draft_codec.dart';
import 'interaction_edit_session.dart';
import 'narrative_interaction.dart';
import 'narrative_editing.dart';
import 'narrative_interaction_reader.dart';

class NarrativeWorkspaceController {
  NarrativeWorkspaceController(
    this.workspace,
    this.port,
    this.changed,
    this.acceptVisuals,
  );
  final MapWorkspaceController workspace;
  final NarrativePort port;
  final void Function() changed;
  final Future<void> Function(ProjectManifest, Set<String>) acceptVisuals;
  final sessions = <String, InteractionEditSession>{};
  final pendingFacts = <String, NarrativeFactDefinition>{};
  final pendingStories = <String, StorylineAsset>{};
  final _sourceRevisions = <String, String>{};
  int _sequence = 0;
  final _eventIds = NarrativeEventIdGenerator();
  InteractionEditSession? active;
  bool busy = false;
  String? error;
  String? publicationError;
  String search = '';
  bool get dirty =>
      pendingFacts.isNotEmpty ||
      pendingStories.isNotEmpty ||
      sessions.values.any((s) => s.dirty);
  ProjectManifest get project => workspace.project!;
  List<NarrativeFactDefinition> get facts => {
    ...{for (final f in project.facts) f.id: f},
    ...pendingFacts,
  }.values.toList();
  List<StorylineAsset> get stories => {
    ...{for (final s in project.storylines) s.id: s},
    ...pendingStories,
  }.values.toList();
  String identity(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_sequence++}';
  Future<void> openNpc(
    EditableMapDocument document,
    MapEntity entity, {
    bool create = false,
  }) async {
    final source = NarrativeEventSourceRef.entityInteract(
      document.current.id,
      entity.id,
    );
    final local = sessions.values
        .where((s) => s.current.interaction.source == source)
        .firstOrNull;
    if (!create && local != null) {
      active = local;
      changed();
      return;
    }
    if (!create) {
      final record = project.eventRegistry?.records
          .where((r) => r.definitionOrNull?.source == source)
          .firstOrNull;
      if (record != null) {
        await openRecord(record);
        return;
      }
    }
    final legacyId = create ? null : entity.npc?.dialogue?.dialogueId;
    await openSource(
      document,
      source,
      entity.name.isEmpty ? 'Personnage' : entity.name,
      existing: project.dialogues.where((d) => d.id == legacyId).firstOrNull,
    );
  }

  Future<void> openSource(
    EditableMapDocument document,
    NarrativeEventSourceRef source,
    String name, {
    ProjectDialogueEntry? existing,
    NarrativeInteractionDraft? interaction,
  }) async {
    if (busy) return;
    busy = true;
    active = null;
    error = null;
    changed();
    try {
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
      final original = existing == null
          ? null
          : await port.readDialogue(existing);
      final decoded = original == null
          ? null
          : const DialogueDraftCodec().decode(original);
      final dialogue = decoded ?? DialogueDraft.blank(entry);
      final edit = InteractionEditSession(
        document: document,
        dialogue: dialogue,
        interaction:
            interaction ??
            NarrativeInteractionDraft(
              id: id,
              name: name,
              mapId: document.current.id,
              source: source,
              dialogueId: entry.id,
              order: nextNarrativeRank(project, sessions.values, source).order,
              priority: nextNarrativeRank(
                project,
                sessions.values,
                source,
              ).priority,
            ),
        readOnlySource: original != null && decoded == null
            ? original.source
            : null,
      );
      sessions[edit.current.interaction.id] = edit;
      active = edit;
    } catch (e) {
      error = e.toString();
    } finally {
      busy = false;
      changed();
    }
  }

  Future<bool> openRecord(NarrativeEventRecord record) async {
    if (busy) return false;
    active = null;
    error = null;
    final local = sessions[record.id];
    if (local != null) return openSession(local);
    final draft = readStudioInteraction(record, project);
    if (draft == null) {
      error =
          'Cette interaction avancée reste conservée, mais son édition visuelle n’est pas disponible.';
      changed();
      return false;
    }
    final map = project.maps.where((m) => m.id == draft.mapId).firstOrNull;
    final dialogue = project.dialogues
        .where((d) => d.id == draft.dialogueId)
        .firstOrNull;
    if (map == null || dialogue == null) {
      error = 'La carte ou le dialogue lié est manquant.';
      changed();
      return false;
    }
    await workspace.activate(map);
    final document = workspace.active;
    if (document == null || document.current.id != map.id) return false;
    await openSource(
      document,
      draft.source,
      draft.name,
      existing: dialogue,
      interaction: draft,
    );
    return active?.current.interaction.id == record.id;
  }

  Future<bool> openSession(InteractionEditSession session) async {
    if (busy) return false;
    active = null;
    error = null;
    final map = project.maps
        .where((m) => m.id == session.document.current.id)
        .firstOrNull;
    if (map == null) return false;
    await workspace.activate(map);
    if (workspace.active != session.document) return false;
    active = session;
    changed();
    return true;
  }

  void addFact(String label) {
    if (label.trim().isEmpty) return;
    final fact = NarrativeFactDefinition(
      id: identity('etat'),
      label: label.trim(),
    );
    pendingFacts[fact.id] = fact;
    changed();
  }

  void addStory(String title, List<String> labels) {
    if (title.trim().isEmpty || labels.isEmpty) return;
    final story = createStudioStoryline(
      id: identity('histoire'),
      title: title.trim(),
      steps: {
        for (final label in labels.where((v) => v.trim().isNotEmpty))
          identity('etape'): label.trim(),
      },
    );
    pendingStories[story.id] = story;
    changed();
  }

  bool blocksDeletion(String entityId) => sessions.values.any(
    (s) =>
        s.dirty &&
        s.current.interaction.source.toJson()['entityId'] == entityId,
  );
  Future<bool> save({EditableMapDocument? document}) async {
    if (busy) return false;
    final target = document ?? active?.document ?? workspace.active;
    if (target == null) {
      error = 'Ouvrez une carte pour enregistrer cette histoire.';
      changed();
      return false;
    }
    if (target.saving) return false;
    final edits = sessions.values
        .where((s) => s.document == target && s.dirty)
        .toList();
    final snapshots = {for (final edit in edits) edit: edit.current};
    final factSnapshot = Map.of(pendingFacts),
        storySnapshot = Map.of(pendingStories);
    if (edits.isEmpty && factSnapshot.isEmpty && storySnapshot.isEmpty) {
      return workspace.save(target);
    }
    busy = true;
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
          facts: factSnapshot.values.toList(),
          storylines: storySnapshot.values.toList(),
        ),
      );
      workspace.acceptResources(receipt.beforeManifest, receipt.manifest);
      target.acceptSave(receipt.savedMap, receipt.revision);
      _sourceRevisions.addAll(receipt.sourceRevisions);
      for (final entry in snapshots.entries) {
        entry.key.acceptSave(entry.value);
      }
      pendingFacts.removeWhere((id, v) => identical(factSnapshot[id], v));
      pendingStories.removeWhere((id, v) => identical(storySnapshot[id], v));
      await acceptVisuals(receipt.manifest, receipt.changedPaths.toSet());
      publicationError = null;
      return true;
    } catch (e) {
      publicationError = error = e.toString();
      return false;
    } finally {
      busy = false;
      target.saving = false;
      changed();
    }
  }

  Future<bool> saveAll() async {
    for (final document in workspace.documents.values.toList()) {
      if (!await save(document: document)) return false;
    }
    return !dirty;
  }
}
