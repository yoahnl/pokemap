import 'package:map_core/map_core_domain.dart';

import '../../map_workspace/application/editable_map_document.dart';
import '../domain/dialogue_draft.dart';
import 'dialogue_draft_codec.dart';
import 'interaction_edit_session.dart';
import 'narrative_editing.dart';
import 'narrative_interaction.dart';
import 'narrative_interaction_reader.dart';
import 'narrative_source_location.dart';
import 'narrative_workspace_controller.dart';

part 'narrative_interaction_loading.dart';

class NarrativeInteractionOpener {
  NarrativeInteractionOpener(this.controller);
  final NarrativeWorkspaceController controller;
  final _eventIds = NarrativeEventIdGenerator();
  var _generation = 0;
  var _disposed = false;
  bool loading = false;

  void cancel() {
    _generation++;
    loading = false;
  }

  void dispose() {
    _disposed = true;
    cancel();
  }

  Future<bool> _run(
    Future<bool> Function(ProjectManifest, bool Function()) action, {
    bool clearActive = true,
  }) async {
    if (_disposed || controller.workspace.isDisposed || controller.saving) {
      return false;
    }
    final generation = ++_generation;
    final project = controller.project;
    bool valid() =>
        !_disposed &&
        !controller.workspace.isDisposed &&
        generation == _generation &&
        identical(project, controller.workspace.project);
    loading = true;
    if (clearActive) controller.active = null;
    controller.error = null;
    controller.changed();
    try {
      return await action(project, valid) && valid();
    } catch (failure) {
      if (valid()) controller.error = failure.toString();
      return false;
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        if (!controller.workspace.isDisposed) controller.changed();
      }
    }
  }

  Future<EditableMapDocument?> _activate(
    ProjectManifest project,
    String mapId,
    bool Function() valid,
  ) async {
    final map = project.maps.where((map) => map.id == mapId).firstOrNull;
    if (map == null) {
      controller.error = 'La carte liée est absente du projet.';
      return null;
    }
    await controller.workspace.activate(map, isCurrent: valid);
    if (!valid()) return null;
    final document = controller.workspace.active;
    if (document?.current.id != mapId) {
      controller.error =
          controller.workspace.error ?? 'La carte liée est indisponible.';
      return null;
    }
    return document;
  }

  Future<bool> openSession(InteractionEditSession session) {
    controller.reconcileCleanInteractionSessions();
    if (!identical(
      controller.sessions[session.current.interaction.id],
      session,
    )) {
      final record = controller.project.eventRegistry?.records
          .where((record) => record.id == session.current.interaction.id)
          .firstOrNull;
      if (record != null) return openRecord(record);
      final scene = controller.project.scenes
          .where((s) => s.id == session.current.interaction.sceneId)
          .firstOrNull;
      controller.error = session.sceneBaseKnown && scene != session.baseScene
          ? 'La scène liée a changé. Rouvrez sa version actuelle ; cette interaction n’est plus disponible.'
          : 'Cette interaction est introuvable.';
      controller.changed();
      return Future.value(false);
    }
    return _run((project, valid) async {
      if (!_canOpenSession(session, project)) return false;
      final document = await _activate(
        project,
        session.document.current.id,
        valid,
      );
      if (!valid() || document != session.document) return false;
      controller.active = session;
      return true;
    });
  }

  Future<bool> openRecord(NarrativeEventRecord record) => _run((
    project,
    valid,
  ) async {
    controller.reconcileCleanInteractionSessions();
    final latest = project.eventRegistry?.records
        .where((candidate) => candidate.id == record.id)
        .firstOrNull;
    if (latest == null) {
      controller.error = 'Cet événement est introuvable.';
      return false;
    }
    record = latest;
    final eventProblem = controller.eventAccessProblem?.call(record.id);
    if (eventProblem != null) {
      controller.error = eventProblem;
      return false;
    }
    final sceneId = record.definitionOrNull?.sceneId ?? 'scene_${record.id}';
    if (!_canOpenScene(sceneId)) return false;
    final local = controller.sessions[record.id];
    if (local != null) {
      if (!_canOpenSession(local, project)) return false;
      final document = await _activate(
        project,
        local.document.current.id,
        valid,
      );
      if (!valid() || document != local.document) return false;
      controller.active = local;
      return true;
    }
    final draft = readStudioInteraction(record, project);
    if (draft == null) {
      controller.error =
          'Cette interaction avancée reste conservée, mais son édition visuelle n’est pas disponible.';
      return false;
    }
    final dialogue = project.dialogues
        .where((entry) => entry.id == draft.dialogueId)
        .firstOrNull;
    if (dialogue == null) {
      controller.error = 'Le dialogue lié est manquant.';
      return false;
    }
    final document = await _activate(project, draft.mapId, valid);
    if (!valid() || document == null) return false;
    return _load(
      document,
      draft.source,
      draft.name,
      project,
      valid,
      existing: dialogue,
      interaction: draft,
    );
  });

  Future<bool> openSource(
    EditableMapDocument document,
    NarrativeEventSourceRef source,
    String name, {
    ProjectDialogueEntry? existing,
    NarrativeInteractionDraft? interaction,
  }) => _run(
    (project, valid) => _load(
      document,
      source,
      name,
      project,
      valid,
      existing: existing,
      interaction: interaction,
    ),
  );

  bool _canOpenScene(String id) {
    final problem = controller.sceneAccessProblem?.call(id);
    if (problem == null) return true;
    controller.error = problem;
    return false;
  }

  bool _canOpenSession(
    InteractionEditSession session,
    ProjectManifest project,
  ) {
    final eventProblem = controller.interactionBaseProblem(session);
    if (eventProblem != null) {
      controller.error = eventProblem;
      return false;
    }
    final id = session.current.interaction.sceneId;
    if (!_canOpenScene(id)) return false;
    final stored = project.scenes.where((scene) => scene.id == id).firstOrNull;
    if (session.sceneBaseKnown && stored != session.baseScene) {
      controller.error =
          'La scène liée a changé. Ouvrez sa version actuelle ; ce brouillon reste conservé.';
      return false;
    }
    return true;
  }

  Future<NarrativeSourceLocation?> locate(String id) async {
    NarrativeSourceLocation? location;
    final located = await _run((project, valid) async {
      final record = project.eventRegistry?.records
          .where((record) => record.id == id)
          .firstOrNull;
      final source =
          controller.sessions[id]?.current.interaction.source ??
          record?.definitionOrNull?.source ??
          record?.draftOrNull?.source;
      final fields = source?.toJson();
      final mapId = fields?['mapId'];
      if (mapId is! String ||
          (fields?['entityId'] == null && fields?['triggerId'] == null)) {
        controller.error =
            source?.when(
              entityInteract: (_, _) => null,
              triggerEnter: (_, _) => null,
              mapEnter: (_) =>
                  'Cette interaction concerne l’arrivée sur une carte, sans point de localisation précis.',
              outcomeReceived: (_) =>
                  'Cette interaction réagit à un résultat, sans carte source définie.',
            ) ??
            'Cette interaction ne définit pas d’emplacement précis sur une carte.';
        return false;
      }
      final document = await _activate(project, mapId, valid);
      if (!valid() || document == null) return false;
      location = NarrativeSourceLocation.fromSource(document, source!);
      if (location == null) {
        controller.error =
            'Le personnage ou la zone source a disparu de cette carte.';
      }
      return location != null;
    }, clearActive: false);
    return located ? location : null;
  }
}
