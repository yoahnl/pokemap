import 'package:map_core/map_core_domain.dart';
import '../../map_workspace/application/map_workspace_controller.dart';
import '../../map_workspace/application/editable_map_document.dart';
import '../domain/narrative_port.dart';
import 'dialogue_draft_codec.dart';
import 'interaction_edit_session.dart';
import 'narrative_interaction.dart';
import 'narrative_interaction_opener.dart';
import 'narrative_source_location.dart';

part 'narrative_workspace_publication.dart';

part 'narrative_session_coexistence.dart';

class NarrativeWorkspaceController {
  Future<bool> save({EditableMapDocument? document}) =>
      _save(document: document);

  NarrativeWorkspaceController(
    this.workspace,
    this.port,
    this.changed,
    this.acceptVisuals,
  ) {
    workspace.addListener(reconcileCleanInteractionSessions);
  }
  final MapWorkspaceController workspace;
  final NarrativePort port;
  final void Function() changed;
  final Future<void> Function(ProjectManifest, Set<String>) acceptVisuals;
  final sessions = <String, InteractionEditSession>{};
  final pendingFacts = <String, NarrativeFactDefinition>{};
  final pendingStories = <String, StorylineAsset>{};
  final pendingStoryDeletions = <String>{};
  Future<bool> Function()? saveStoryDrafts;
  bool Function()? storyDraftsBusy;
  final _sourceRevisions = <String, String>{};
  int _sequence = 0;
  late final _opener = NarrativeInteractionOpener(this);
  InteractionEditSession? active;
  bool saving = false;
  final _publishingInteractions = <String>{};
  bool get busy => saving || _opener.loading || storyDraftsBusy?.call() == true;
  bool get opening => _opener.loading;
  String? Function(String sceneId)? sceneAccessProblem;
  String? Function(String eventId)? eventAccessProblem;
  String? Function(String dialogueId)? dialogueAccessProblem;
  void Function(Set<String> ids)? dialoguesPublished;
  bool _disposed = false;
  String? error;
  String? publicationError;
  String search = '';
  bool get dirty =>
      pendingFacts.isNotEmpty ||
      pendingStories.isNotEmpty ||
      pendingStoryDeletions.isNotEmpty ||
      sessions.values.any((s) => s.dirty);
  ProjectManifest get project => workspace.project!;
  List<NarrativeFactDefinition> get facts => {
    ...{for (final f in project.facts) f.id: f},
    ...pendingFacts,
  }.values.toList();
  List<StorylineAsset> get stories => {
    ...{for (final s in project.storylines) s.id: s},
    ...pendingStories,
  }.values.where((s) => !pendingStoryDeletions.contains(s.id)).toList();
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
  void dispose() {
    _disposed = true;
    workspace.removeListener(reconcileCleanInteractionSessions);
    _opener.dispose();
  }

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
    final fact = addNarrativeFact(
      project.copyWith(facts: facts),
      label: label.trim(),
    ).createdFact;
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
}
