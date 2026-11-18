part of 'story_page.dart';

extension _StoryPageBody on _StoryPageState {
  Widget _body(StorySection section, StoryPanelBuilder panels) {
    final l10n = context.l10n;
    final trameView = widget.trame?.view;
    final empty = StudioEmptyState(
      icon: Icons.touch_app_outlined,
      title: l10n.storySelectItem,
    );
    final unavailable = StudioEmptyState(
      key: const ValueKey('memory-unavailable'),
      icon: Icons.inventory_2_outlined,
      title: l10n.memoryUnavailable,
      description: l10n.memoryUnavailableHint,
    );
    return switch (section) {
      StorySection.trame when widget.trame != null => TrameView(
        trame: widget.trame!,
        source: widget.behaviourSource,
        navigate: widget.behaviours.open,
        openScene: widget.openScene,
        panels: panels,
        onSelected: (id) => _selectItem(
          StorySection.trame,
          id == null ? null : (kind: StoryDraftKind.story, id: id),
        ),
      ),
      StorySection.behaviours when _behaviours != null =>
        GameBehaviourWorkspace(
          list: GameBehavioursView(
            compact: true,
            selectedId:
                widget.behaviourCatalog?.editor?.selectedBehaviour?.id ??
                widget.behaviourCatalog?.selectedId,
            behaviours: _behaviours!,
            navigate: widget.behaviourCatalog == null
                ? widget.behaviours.open
                : _openCatalogBehaviour,
            openMap: widget.openMap,
            trame: widget.trame,
            simulate: widget.behaviourCatalog == null
                ? widget.simulate
                : (id) => _openCatalogBehaviour(id, simulate: true),
            openScene: widget.openScene,
            create: widget.staging.editable && widget.behaviourCatalog != null
                ? () => unawaited(_createTrigger())
                : null,
          ),
          editor: _creation && widget.behaviourCatalog != null
              ? StoryTriggerCreation(
                  key: ValueKey('trigger-creation-${_behaviours!.mapId}'),
                  catalog: widget.behaviourCatalog!,
                  maps: widget.maps,
                  mapId: _behaviours!.mapId,
                  editable: widget.staging.editable,
                  openMap: widget.openMapEntry,
                  created: (id) {
                    _creation = false;
                    _selectItem(StorySection.behaviours, (
                      kind: StoryDraftKind.event,
                      id: id,
                    ));
                    _changed();
                  },
                  cancel: () {
                    widget.behaviourCatalog!.clear();
                    _selectItem(StorySection.behaviours, null);
                    _creation = false;
                    _changed();
                  },
                )
              : widget.behaviourCatalog != null
              ? StoryBehaviourContext(
                  catalog: widget.behaviourCatalog!,
                  openMap: widget.behaviours.open,
                  retry: _openCatalogBehaviour,
                  editable: widget.staging.editable,
                  filtered: switch (widget
                          .behaviourCatalog
                          ?.editor
                          ?.selectedBehaviour
                          ?.id ??
                      widget.behaviourCatalog?.selectedId) {
                    final id? => !_behaviours!.includes(
                      id,
                      elementLabel: l10n.behaviourElement,
                      outside: trameView == null
                          ? null
                          : (row) =>
                                row.record != null &&
                                trameView.outside(row.record!),
                    ),
                    _ => false,
                  },
                  onSelected: (id) => _selectItem(
                    StorySection.behaviours,
                    id == null ? null : (kind: StoryDraftKind.event, id: id),
                    navigation: false,
                  ),
                )
              : StudioEmptyState(
                  icon: Icons.people_outline,
                  title: l10n.storyBehavioursHint,
                  description: l10n.storyBehavioursOpenHint,
                ),
        ),
      StorySection.facts ||
      StorySection.rules when _memory != null => GameMemoryView(
        memory: _memory!,
        maps: widget.maps,
        loadMap: widget.loadMap,
        behaviours: widget.behaviours,
        openUsage: _openMemoryUsage,
        panels: panels,
        section: section == StorySection.facts
            ? GameMemorySection.facts
            : GameMemorySection.rules,
      ),
      StorySection.scenes when _catalog != null => SceneCatalogView(
        catalog: _catalog!,
        openScene: widget.openScene,
        panels: panels,
        onSelected: (id) => _selectItem(
          StorySection.scenes,
          id == null ? null : (kind: StoryDraftKind.scene, id: id),
        ),
      ),
      StorySection.dialogues when _dialogues != null => StoryDialoguesView(
        catalog: _dialogues!,
      ),
      StorySection.verification => panels(
        VerificationView(
          verification: widget.verification,
          unsaved: widget.unsaved,
          destination: _destination,
        ),
        VerificationCoverageView(snapshot: widget.verification?.snapshot),
      ),
      _ => panels(unavailable, empty),
    };
  }
}
