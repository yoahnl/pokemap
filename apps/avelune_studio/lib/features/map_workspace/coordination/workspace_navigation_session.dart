import 'dart:async';

import 'package:map_core/map_core_domain.dart';

import '../../cinematics/application/cinematic_workspace_controller.dart';
import '../../dialogues/application/dialogue_workspace_controller.dart';
import '../../events/application/event_workspace_controller.dart';
import '../../events/application/event_labels.dart';
import '../../narrative/application/narrative_workspace_controller.dart';
import '../application/editable_map_document.dart';
import 'map_editing_viewport_session.dart';
import '../../presentations/application/presentation_workspace_controller.dart';
import '../../scenes/application/scene_workspace_controller.dart';
import '../../stories/application/story_workspace_controller.dart';
import '../../verification/application/verification_workspace_controller.dart';
import '../../world/application/world_workspace_controller.dart';
import '../application/map_workspace_controller.dart';
import '../domain/map_workspace_workshop.dart';
import '../domain/workspace_navigation.dart';

part 'workspace_navigation_diagnostics.dart';
part 'workspace_navigation_event_source.dart';
part 'workspace_navigation_interactions.dart';

class WorkspaceNavigationSession {
  WorkspaceNavigationSession({
    required this.controller,
    required this.isActive,
    required this.changed,
    this.scenes,
    this.dialogues,
    this.presentations,
    this.cinematics,
    this.events,
    this.narrative,
    this.homeVisible,
    this.readEventFilter,
    this.eventFilterChanged,
    this.stories,
    this.world,
    this.verification,
    this.prepareWorkshop,
    this.navigationRequest,
    this.nextNavigationRequest,
    this.mapView,
    this.toolChanged,
    this.afterViewportLayout,
    this.onShow,
    this.focusScene,
    this.nodeSelected,
    this.selectProgressionNode,
    this.selectWorldMode,
  });

  final MapWorkspaceController controller;
  final bool Function() isActive;
  final void Function() changed;
  final SceneWorkspaceController? Function()? scenes;
  final DialogueWorkspaceController? Function()? dialogues;
  final PresentationWorkspaceController? Function()? presentations;
  final CinematicWorkspaceController? Function()? cinematics;
  final EventWorkspaceController? Function()? events;
  final NarrativeWorkspaceController? Function()? narrative;
  final bool Function()? homeVisible;
  final String? Function()? readEventFilter;
  final void Function(String?)? eventFilterChanged;
  final StoryWorkspaceController? Function()? stories;
  final WorldWorkspaceController? Function()? world;
  final VerificationWorkspaceController? Function()? verification;
  final Future<int?> Function(MapWorkspaceWorkshop)? prepareWorkshop;
  final int Function()? navigationRequest;
  final int Function()? nextNavigationRequest;
  final MapEditingViewportSession? Function()? mapView;
  final void Function()? toolChanged;
  final void Function(void Function())? afterViewportLayout;
  final void Function(WorkspaceSpace)? onShow;
  final void Function(SceneAsset, String)? focusScene;
  final void Function(String, String)? nodeSelected;
  final void Function(String, StorylineProgressionNode)? selectProgressionNode;
  final void Function(bool)? selectWorldMode;
  WorkspaceSpace space = WorkspaceSpace.map;
  WorkspaceReturn sceneOrigin = WorkspaceReturn.story;
  WorkspaceReturn presentationOrigin = WorkspaceReturn.story;
  WorkspaceReturn worldOrigin = WorkspaceReturn.story;
  WorkspaceReturn verificationOrigin = WorkspaceReturn.story;
  WorkspaceReturn progressionOrigin = WorkspaceReturn.story;
  WorkspaceSpace dialogueOrigin = WorkspaceSpace.story;
  WorkspaceSpace cinematicOrigin = WorkspaceSpace.story;
  WorkspaceSpace eventOrigin = WorkspaceSpace.story;
  WorkspaceSpace interactionOrigin = WorkspaceSpace.map;
  String? eventFilterMapId;
  bool verificationMapReturn = false;
  bool eventMapReturn = false;
  bool worldRules = false;
  final sceneNodes = <String, String>{};
  final progressionNodes = <String, StorylineProgressionNode>{};
  int _request = 0;
  int get request => navigationRequest?.call() ?? _request;
  String? get presentationPreviewSceneId =>
      presentationOrigin.space == WorkspaceSpace.scene
      ? presentationOrigin.documentId
      : null;

  Future<int?> _prepare(MapWorkspaceWorkshop workshop) async {
    if (prepareWorkshop case final prepare?) return prepare(workshop);
    return isActive() ? ++_request : null;
  }

  void show(WorkspaceSpace destination) {
    if (!isActive()) return;
    final callback = onShow;
    if (callback != null) {
      callback(destination);
    } else {
      space = destination;
      _request++;
      changed();
    }
  }

  void selectSceneNode(SceneAsset scene, String nodeId, {bool focus = true}) {
    if (!scene.graph.nodes.any((node) => node.id == nodeId)) return;
    sceneNodes[scene.id] = nodeId;
    nodeSelected?.call(scene.id, nodeId);
    if (focus) focusScene?.call(scene, nodeId);
  }

  Future<String?> openScene(
    String sceneId, {
    String? nodeId,
    WorkspaceReturn? origin,
  }) async {
    final from = space;
    final beforeOwner = scenes?.call();
    final backToOrigin =
        from == WorkspaceSpace.cinematic &&
        cinematicOrigin == WorkspaceSpace.scene &&
        beforeOwner?.active?.current.id == sceneId;
    if (await _prepare(MapWorkspaceWorkshop.scene) == null) return null;
    final owner = scenes?.call();
    if (owner == null) return 'L’éditeur de scène est indisponible.';
    if (!owner.open(sceneId)) return owner.error;
    if (!backToOrigin) {
      sceneOrigin =
          origin ??
          switch (from) {
            WorkspaceSpace.progression ||
            WorkspaceSpace.events ||
            WorkspaceSpace.verification ||
            WorkspaceSpace.pokemon => WorkspaceReturn(from),
            WorkspaceSpace.cinematic => WorkspaceReturn(
              WorkspaceSpace.cinematic,
              documentId: cinematics?.call()?.activeId,
            ),
            _ => WorkspaceReturn.story,
          };
    }
    final scene = owner.active?.current;
    if (nodeId != null && scene != null) selectSceneNode(scene, nodeId);
    show(WorkspaceSpace.scene);
    return null;
  }

  Future<String?> openDialogue(
    String id,
    WorkspaceSpace origin, {
    String? startNode,
  }) async {
    final ticket = await _prepare(MapWorkspaceWorkshop.dialogue);
    if (ticket == null) return null;
    final owner = dialogues?.call();
    if (owner == null) return null;
    final opened = await owner.open(id, startNode: startNode);
    if (!isActive() || ticket != request) return null;
    if (!opened) return owner.error;
    dialogueOrigin = origin;
    show(WorkspaceSpace.dialogue);
    return null;
  }

  void returnFromDialogue() => show(dialogueOrigin);

  Future<void> openScenePresentation(
    ScenePresentationCinematicPayload payload,
  ) async {
    final ticket = await _prepare(MapWorkspaceWorkshop.presentation);
    if (ticket == null) return;
    final owner = presentations?.call();
    if (owner == null ||
        !await owner.open(payload.presentationCinematicId) ||
        !isActive() ||
        ticket != request) {
      return;
    }
    presentationOrigin = WorkspaceReturn(
      WorkspaceSpace.scene,
      documentId: scenes?.call()?.active?.current.id,
    );
    show(WorkspaceSpace.presentation);
  }

  bool openPresentationConsumer(String sceneId, String nodeId) {
    final owner = scenes?.call();
    if (owner?.open(sceneId) != true) return false;
    selectSceneNode(owner!.active!.current, nodeId, focus: false);
    sceneOrigin = WorkspaceReturn(
      WorkspaceSpace.presentation,
      documentId: presentations?.call()?.activeId,
    );
    show(WorkspaceSpace.scene);
    return true;
  }

  Future<String?> returnToPresentation(String? id) async {
    final ticket = await _prepare(MapWorkspaceWorkshop.presentation);
    if (ticket == null) return null;
    final owner = presentations?.call();
    if (owner == null) return null;
    if (id != null && owner.activeId != id && !await owner.open(id)) {
      if (!isActive()) return null;
      sceneOrigin = WorkspaceReturn.story;
      show(WorkspaceSpace.story);
      return 'Cette présentation n’est plus disponible.';
    }
    if (isActive() && ticket == request) show(WorkspaceSpace.presentation);
    return null;
  }

  String? returnFromPresentation() {
    final origin = presentationOrigin;
    final sceneId = origin.documentId;
    if (origin.space == WorkspaceSpace.scene &&
        sceneId != null &&
        scenes?.call()?.open(sceneId) != true) {
      presentationOrigin = WorkspaceReturn.story;
      show(WorkspaceSpace.story);
      return 'Cette scène n’est plus disponible.';
    }
    show(origin.space);
    return null;
  }

  String? returnFromWorld() {
    final origin = worldOrigin;
    final sceneId = origin.documentId;
    if (origin.space == WorkspaceSpace.scene &&
        sceneId != null &&
        scenes?.call()?.open(sceneId) != true) {
      worldOrigin = WorkspaceReturn.story;
      show(WorkspaceSpace.story);
      return 'Cette scène n’est plus disponible.';
    }
    show(
      origin.space == WorkspaceSpace.world
          ? WorkspaceSpace.story
          : origin.space,
    );
    return null;
  }

  bool openSceneFromWorld(String id) {
    if (scenes?.call()?.open(id) != true) return false;
    sceneOrigin = const WorkspaceReturn(WorkspaceSpace.world);
    show(WorkspaceSpace.scene);
    return true;
  }

  void returnFromProgression() => show(progressionOrigin.space);
  void returnFromVerification() => show(verificationOrigin.space);
  void returnFromDiagnosticMap() {
    verificationMapReturn = false;
    show(WorkspaceSpace.verification);
  }
}
