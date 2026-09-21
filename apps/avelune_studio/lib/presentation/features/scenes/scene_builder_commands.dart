part of 'scene_builder_page.dart';

extension _SceneBuilderCommands on _SceneBuilderPageState {
  List<SceneBlockDragData> get blocks => [
    for (final kind in SceneNodeKind.values.where(
      (kind) => kind != SceneNodeKind.start,
    ))
      SceneBlockDragData(kind: kind, label: sceneBlockLabel(kind)),
  ];
  ProjectManifest get linkedProject => widget.presentationEntries == null
      ? widget.controller.project
      : widget.controller.project.copyWith(
          presentationCinematics: widget.presentationEntries!(),
        );

  Future<void> createPresentation(SceneNode node) async {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    final session = widget.controller.active;
    if (session == null ||
        session.saving ||
        session.base == null ||
        session.current.executionProfile != SceneExecutionProfile.preSession ||
        !session.current.graph.nodes.any((n) => n.id == node.id)) {
      return;
    }
    await widget.onCreatePresentation?.call(
      ScenePresentationCreationRequest(
        baseScene: session.base!,
        scene: session.current,
        targetNodeId: node.id,
      ),
    );
  }

  Future<void> openDocument(SceneNode node) {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    if (node.payload case SceneYarnDialoguePayload payload
        when widget.onDialogue != null) {
      return widget.onDialogue!(payload);
    }
    if (node.payload case SceneCinematicPayload payload
        when widget.onCinematic != null) {
      return widget.onCinematic!(payload);
    }
    if (node.payload case ScenePresentationCinematicPayload payload
        when widget.onPresentation != null) {
      return widget.onPresentation!(payload);
    }
    return documents.open(
      context,
      node,
      widget.controller.project,
      widget.narrative,
    );
  }

  Future<void> discardDraft() async {
    final session = widget.controller.active;
    if (session == null || session.saving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandonner ce brouillon de scène ?'),
        content: const Text(
          'Les modifications de cette scène seront perdues. Les autres scènes, cartes et documents restent ouverts. Cette action ne recharge pas les changements externes au projet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Conserver le brouillon'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Abandonner cette scène'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || widget.controller.active != session) {
      return;
    }
    final id = session.current.id;
    if (!widget.controller.discard(id)) return;
    if (widget.controller.project.scenes.any((scene) => scene.id == id)) {
      widget.controller.open(id);
    }
    refresh();
  }

  void delete() {
    final session = widget.controller.active;
    if (session == null) return;
    if (view?.edgeId case final id?) {
      if (session.disconnect(id)) view!.edgeId = null;
    } else if (view?.nodeId case final id?) {
      if (session.delete(id)) view!.nodeId = null;
    }
    refresh();
  }

  void duplicate() {
    if (view?.nodeId case final id?) widget.controller.active?.duplicate(id);
    refresh();
  }

  Future<void> add(
    SceneBlockDragData block,
    Offset point, {
    String? fromNodeId,
    String? fromPortId,
  }) async {
    final session = widget.controller.active;
    if (session == null) return;
    SceneNodePayload? payload = block.payload;
    if (payload == null &&
        {
          SceneNodeKind.yarnDialogue,
          SceneNodeKind.battle,
          SceneNodeKind.cinematic,
          SceneNodeKind.presentationCinematic,
          SceneNodeKind.action,
        }.contains(block.kind)) {
      payload = await chooseScenePayload(context, block.kind, linkedProject);
      if (!mounted || widget.controller.active != session || payload == null) {
        return;
      }
    }
    final selectedPayload = payload;
    String? createdId;
    final applied = session.mutate((scene) {
      late SceneAsset next;
      late SceneNode node;
      if (selectedPayload is SceneActionPayload) {
        final result = selectedPayload.consequence != null
            ? addSceneConsequenceActionNodeDraft(
                scene,
                consequence: selectedPayload.consequence!,
                title: block.label,
              )
            : addSceneCommandActionNodeDraft(
                scene,
                payload: selectedPayload,
                title: block.label,
              );
        next = result.updatedScene;
        node = result.createdNode;
      } else {
        final result = selectedPayload != null
            ? addSceneLinkedAssetNodeDraft(
                scene,
                payload: selectedPayload,
                title: block.label,
              )
            : block.kind == SceneNodeKind.branchByOutcome
            ? addSceneLinkedAssetNodeDraft(
                scene,
                payload: SceneBranchByOutcomePayload(),
                title: block.label,
              )
            : addSceneNodeDraft(scene, kind: block.kind, title: block.label);
        next = result.updatedScene;
        node = result.createdNode;
      }
      next = updateSceneNodeLayout(
        next,
        nodeId: node.id,
        x: point.dx,
        y: point.dy,
      ).updatedScene;
      if (fromNodeId != null && fromPortId != null) {
        next = addSceneEdgeDraft(
          next,
          fromNodeId: fromNodeId,
          fromPortId: fromPortId,
          toNodeId: node.id,
        ).updatedScene;
      }
      createdId = node.id;
      return next;
    });
    if (applied) {
      view!.nodeId = createdId;
      view!.edgeId = null;
    }
    refresh();
  }

  Future<void> create() async {
    final name = await askNarrativeName(context, 'Nom de la scène');
    if (!mounted || name == null) return;
    widget.controller.create(name);
    refresh();
  }
}
