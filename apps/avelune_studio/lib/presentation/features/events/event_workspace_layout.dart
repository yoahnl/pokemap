part of 'event_workspace_page.dart';

extension _EventWorkspaceLayout on _EventWorkspacePageState {
  Widget _buildEventPage(BuildContext context) {
    final record = c.active;
    final project = c.project;
    final sceneDirtyIds =
        widget.scenes?.sessions.values
            .where((s) => s.dirty)
            .map((s) => s.current.id)
            .toSet() ??
        <String>{};
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _save,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _save,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () =>
            _restore(false),
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () =>
            _restore(false),
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          meta: true,
          shift: true,
        ): () =>
            _restore(true),
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): () =>
            _restore(true),
      },
      child: Focus(
        focusNode: _pageFocus,
        autofocus: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 1150 ||
                MediaQuery.textScalerOf(context).scale(14) > 20;
            final library = EventLibrary(
              project: project,
              maps: c.maps,
              mapsComplete: c.prepared,
              onLoadHistory: () async {
                await c.prepare();
                _refresh();
              },
              records: c.records,
              activeId: c.activeId,
              dirtyIds: c.dirtyIds,
              view: view,
              onChanged: _refresh,
              onOpen: _open,
              onCreate: _create,
            );
            final summary = record == null
                ? const SizedBox()
                : EventSummary(
                    record: record,
                    project: project,
                    sceneDirty: sceneDirtyIds.contains(eventSceneId(record)),
                    onTab: _tab,
                    onScene: eventSceneId(record) == null
                        ? null
                        : () => _scene(eventSceneId(record)!),
                  );
            final content = record == null
                ? const Center(
                    child: Text(
                      'Sélectionnez un événement ou créez un brouillon.',
                    ),
                  )
                : EventPageContent(
                    record: record,
                    controller: c,
                    view: view,
                    loader: widget.loader,
                    visuals: widget.visuals,
                    onLocate: _locate,
                    onScene: _scene,
                    mutate: _mutate,
                    sceneDirtyIds: sceneDirtyIds,
                    onMode: () => showEventRegistryDialog(context, c),
                  );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StudioPageHeader(
                  title: 'Événements et déclencheurs',
                  prominent: !compact,
                  description: compact
                      ? 'Histoire > Événements'
                      : 'Quand ceci arrive, si les conditions sont réunies, jouer cette scène.',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        StudioButton(
                          label: 'Retour',
                          secondary: true,
                          icon: Icons.arrow_back,
                          onPressed: () async {
                            _flush();
                            await _pending;
                            if (mounted) widget.onBack();
                          },
                        ),
                        const SizedBox(width: 8),
                        if (compact) ...[
                          StudioButton(
                            label: 'Bibliothèque',
                            secondary: true,
                            onPressed: () {
                              view.library = !view.library;
                              view.inspector = false;
                              _refresh();
                            },
                          ),
                          const SizedBox(width: 8),
                          StudioButton(
                            label: 'Résumé',
                            secondary: true,
                            onPressed: () {
                              view.inspector = !view.inspector;
                              view.library = false;
                              _refresh();
                            },
                          ),
                          const SizedBox(width: 8),
                        ],
                        StudioButton(
                          label: 'Nouvel événement',
                          icon: Icons.add,
                          onPressed: _create,
                        ),
                        const SizedBox(width: 8),
                        StudioButton(
                          label: 'Enregistrer',
                          icon: Icons.save_outlined,
                          onPressed: c.busy ? null : _save,
                        ),
                        const SizedBox(width: 8),
                        StudioButton(
                          label: 'Simulation',
                          secondary: true,
                          icon: Icons.science_outlined,
                          onPressed: record == null
                              ? null
                              : () async {
                                  _flush();
                                  await _pending;
                                  if (await c.prepare() && context.mounted) {
                                    await showEventSimulation(
                                      context,
                                      c,
                                      record.id,
                                    );
                                  }
                                },
                        ),
                        const SizedBox(width: 8),
                        StudioButton(
                          label: 'Tester sur la carte',
                          secondary: true,
                          icon: Icons.play_arrow,
                          onPressed:
                              record == null ||
                                  eventMapId(eventSource(record)) == null
                              ? null
                              : () async {
                                  _flush();
                                  await _pending;
                                  if (mounted) await widget.onTest();
                                },
                        ),
                        const SizedBox(width: 8),
                        StudioTool(
                          label: 'Annuler la modification',
                          icon: Icons.undo,
                          onPressed: c.canUndo ? () => _restore(false) : null,
                        ),
                        StudioTool(
                          label: 'Rétablir la modification',
                          icon: Icons.redo,
                          onPressed: c.canRedo ? () => _restore(true) : null,
                        ),
                        if (record != null)
                          PopupMenuButton<String>(
                            tooltip: 'Actions de l’événement',
                            onSelected: (value) {
                              if (value == 'duplicate') {
                                _mutate(() => c.duplicate(record.id) != null);
                              }
                              if (value == 'delete') _remove(record.id);
                              if (value == 'reload') _reload(record.id);
                            },
                            itemBuilder: (_) => const [
                              PopupMenuItem(
                                value: 'duplicate',
                                child: Text('Dupliquer'),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Text('Supprimer'),
                              ),
                              PopupMenuItem(
                                value: 'reload',
                                child: Text('Recharger'),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
                if (c.error ?? _notice case final message?)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: StudioNotice(message, isError: true),
                  ),
                const SizedBox(height: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: compact && view.library
                        ? library
                        : compact && view.inspector
                        ? summary
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!compact) ...[
                                SizedBox(width: 250, child: library),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (record != null) ...[
                                      StudioCommitField(
                                        key: ValueKey(
                                          'event-name:${record.id}',
                                        ),
                                        label: 'Nom de l’événement',
                                        value: eventName(record),
                                        onCommit: (value) => _mutate(
                                          () => c.rename(record.id, value),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      EventStatusBadge(
                                        record: record,
                                        dirty: c.isDirty(record.id),
                                      ),
                                      const SizedBox(height: 10),
                                      StudioTabs(
                                        items: const {
                                          EventTab.trigger: 'Déclencheur',
                                          EventTab.conditions: 'Conditions',
                                          EventTab.scene: 'Scène',
                                          EventTab.options: 'Options',
                                        },
                                        selected: view.tab,
                                        onChanged: _tab,
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    Expanded(child: content),
                                  ],
                                ),
                              ),
                              if (!compact && record != null) ...[
                                const SizedBox(width: 12),
                                SizedBox(width: 286, child: summary),
                              ],
                            ],
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
