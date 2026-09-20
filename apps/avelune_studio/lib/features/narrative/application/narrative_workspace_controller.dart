import 'package:map_core/map_core_domain.dart';
import '../../map_workspace/application/map_workspace_controller.dart';
import '../../map_workspace/application/editable_map_document.dart';
import '../domain/narrative_port.dart';
import 'dialogue_draft_codec.dart';
import 'interaction_edit_session.dart';
import 'narrative_interaction.dart';
import 'narrative_interaction_opener.dart';
import 'narrative_source_location.dart';

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
  late final _opener = NarrativeInteractionOpener(this);
  InteractionEditSession? active;
  bool saving = false;
  bool get busy => saving || _opener.loading;
  bool get opening => _opener.loading;
  String? Function(String sceneId)? sceneAccessProblem;
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
      await openSession(local);
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
    await _opener.openSource(
      document,
      source,
      name,
      existing: existing,
      interaction: interaction,
    );
  }

  Future<bool> openRecord(NarrativeEventRecord record) =>
      _opener.openRecord(record);
  Future<bool> openSession(InteractionEditSession session) =>
      _opener.openSession(session);
  Future<NarrativeSourceLocation?> locateInteraction(String id) =>
      _opener.locate(id);
  void cancelOpening() => _opener.cancel();
  void dispose() => _opener.dispose();

  void invalidateCleanSceneSessions(String sceneId) {
    final removed = sessions.values
        .where(
          (session) =>
              !session.dirty && session.current.interaction.sceneId == sceneId,
        )
        .toSet();
    sessions.removeWhere((_, session) => removed.contains(session));
    if (removed.contains(active)) active = null;
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
    final steps = labels
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toList();
    if (title.trim().isEmpty || steps.isEmpty) return;
    final story = createStudioStoryline(
      id: identity('histoire'),
      title: title.trim(),
      steps: {for (final label in steps) identity('etape'): label},
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
    for (final edit in edits) {
      final sceneId = edit.current.interaction.sceneId;
      final stored = project.scenes
          .where((scene) => scene.id == sceneId)
          .firstOrNull;
      final problem =
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
    final factSnapshot = Map.of(pendingFacts),
        storySnapshot = Map.of(pendingStories);
    if (edits.isEmpty && factSnapshot.isEmpty && storySnapshot.isEmpty) {
      return workspace.save(target);
    }
    saving = true;
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
        entry.key.baseScene = receipt.manifest.scenes
            .where((scene) => scene.id == entry.value.interaction.sceneId)
            .firstOrNull;
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
      saving = false;
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
