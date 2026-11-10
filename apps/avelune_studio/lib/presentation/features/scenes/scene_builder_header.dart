part of 'scene_builder_page.dart';

extension _SceneBuilderHeader on _SceneBuilderPageState {
  List<Widget> _tools(
    bool compact,
    SceneEditSession? session,
    SceneBuilderViewState? state,
  ) {
    return [
      if (session != null)
        PopupMenuButton<String>(
          tooltip: 'Options de scène',
          onSelected: (_) => discardDraft(),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'discard',
              enabled: session.dirty && !session.saving,
              child: const Text('Abandonner ce brouillon'),
            ),
          ],
        ),
      StudioTool(
        label: 'Annuler la scène',
        icon: Icons.undo,
        shortcut: '⌘Z',
        onPressed: session?.canUndo == true
            ? () {
                session!.restore(redo: false);
                refresh();
              }
            : null,
      ),
      StudioTool(
        label: 'Rétablir la scène',
        icon: Icons.redo,
        shortcut: '⇧⌘Z',
        onPressed: session?.canRedo == true
            ? () {
                session!.restore(redo: true);
                refresh();
              }
            : null,
      ),
      StudioButton(
        label: compact ? 'Chemin' : 'Prévisualiser le chemin',
        secondary: true,
        icon: Icons.route,
        onPressed: state == null
            ? null
            : () {
                state.previewOpen = !state.previewOpen;
                refresh();
              },
      ),
      StudioButton(
        label: 'Enregistrer',
        icon: Icons.save_outlined,
        onPressed: session == null || session.saving
            ? null
            : () async {
                await widget.controller.save();
                refresh();
              },
      ),
      if (widget.onTest != null &&
          session != null &&
          widget.controller.project.eventRegistry?.records.any(
                (record) =>
                    record.definitionOrNull?.sceneId == session.current.id &&
                    record.definitionOrNull?.source.toJson()['mapId'] ==
                        widget.controller.workspace.active?.current.id,
              ) ==
              true)
        Tooltip(
          message:
              'Enregistre les scènes modifiées, la carte et ses interactions avant de lancer le jeu.',
          child: StudioButton(
            label: 'Tester dans le jeu',
            icon: Icons.play_arrow,
            secondary: true,
            onPressed: widget.onTest,
          ),
        ),
    ];
  }

  List<Widget> _header(
    BuildContext context,
    bool compact,
    bool small,
    SceneEditSession? session,
    SceneBuilderViewState? state,
  ) => [
    Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          TextButton(onPressed: widget.onBack, child: Text(widget.onBackLabel)),
          const Icon(Icons.chevron_right, size: 16),
          TextButton(
            onPressed: () {
              widget.views.sceneLibrary = true;
              if (state != null) state.libraryOpen = true;
              refresh();
            },
            child: const Text('Scènes'),
          ),
          if (session != null) ...[
            const Icon(Icons.chevron_right, size: 16),
            Expanded(
              child: Text(
                session.current.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    ),
    if (compact)
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Éditeur de scène',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _tools(compact, session, state),
            ),
          ],
        ),
      )
    else
      StudioPageHeader(
        title: 'Éditeur de scène',
        description: small
            ? null
            : 'Assemblez dialogues, conditions et actions. Reliez les blocs pour raconter une rencontre.',
        actions: _tools(compact, session, state),
        alignActionsToEnd: true,
      ),
    if ((session?.error ?? widget.controller.error) case final error?)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: SizedBox(
          height: 64,
          child: SingleChildScrollView(
            child: StudioNotice(error, isError: true),
          ),
        ),
      ),
    if (compact && session != null)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Wrap(
          spacing: 8,
          children: [
            StudioTool(
              label: 'Bibliothèque de scène',
              icon: Icons.view_sidebar_outlined,
              selected: state!.libraryOpen,
              onPressed: () {
                state.libraryOpen = !state.libraryOpen;
                state.inspectorOpen = false;
                refresh();
              },
            ),
            StudioTool(
              label: 'Inspecteur de scène',
              icon: Icons.tune,
              selected: state.inspectorOpen,
              onPressed: () {
                state.inspectorOpen = !state.inspectorOpen;
                state.libraryOpen = false;
                refresh();
              },
            ),
            Text(
              session.dirty ? 'Modifications non enregistrées' : 'Enregistrée',
            ),
          ],
        ),
      ),
  ];
}

String _summary(SceneNode node, ProjectManifest project, SceneAsset scene) =>
    switch (node.payload) {
      SceneYarnDialoguePayload(:final dialogueId) =>
        project.dialogues.where((d) => d.id == dialogueId).firstOrNull?.name ??
            'Dialogue introuvable',
      SceneConditionPayload(:final conditionSource) =>
        conditionSource?.label ?? 'Choisir une condition',
      SceneEndPayload(:final sceneOutcomeId) =>
        scene.declaredOutcomes
                .where((o) => o.id == sceneOutcomeId)
                .firstOrNull
                ?.label ??
            sceneOutcomeId ??
            'Scène terminée',
      SceneCinematicPayload(:final cinematicId) =>
        project.cinematics
                .where((c) => c.id == cinematicId)
                .firstOrNull
                ?.title ??
            'Cinématique introuvable',
      _ => node.description ?? sceneBlockLabel(node.kind),
    };
