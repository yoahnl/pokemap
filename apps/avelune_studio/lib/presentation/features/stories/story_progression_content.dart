part of 'story_progression_page.dart';

extension _StoryProgressionContent on _StoryProgressionPageState {
  Widget _compactHeader() => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            StudioButton(
              label: 'Histoire',
              secondary: true,
              icon: Icons.arrow_back,
              onPressed: widget.onBack,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Histoires et progression',
                maxLines: 2,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StudioButton(
              label: 'Nouvelle histoire',
              icon: Icons.add,
              onPressed: _create,
            ),
            StudioButton(
              label: 'Enregistrer',
              icon: Icons.save_outlined,
              onPressed:
                  !controller.busy &&
                      (controller.active != null || controller.dirty)
                  ? _save
                  : null,
            ),
            Text(
              controller.busy
                  ? 'Enregistrement…'
                  : controller.dirty
                  ? 'Brouillons modifiés'
                  : 'Enregistré',
            ),
          ],
        ),
      ],
    ),
  );

  Widget _content(bool compact) {
    final story = controller.active;
    final library = StoryLibraryPanel(
      stories: controller.stories,
      activeId: controller.activeId,
      search: widget.views.search,
      type: widget.views.type,
      dirtyIds: controller.narrative.pendingStories.keys.toSet(),
      onSearch: _refresh,
      onType: (type) => _refresh(() {
        widget.views.type = type;
      }),
      onOpen: _open,
      onCreate: _create,
    );
    final inspector = story == null
        ? const SizedBox()
        : StoryInspector(
            controller: controller,
            selection: view.selection,
            onStructure: () => _structure(true),
            onOpenScene: widget.onOpenScene,
            onAddStep: _add,
          );
    final center = story == null
        ? const Center(
            child: StudioNotice(
              'Créez une histoire pour organiser ses chapitres et ses étapes.',
            ),
          )
        : view.structure
        ? StoryStructureView(
            controller: controller,
            story: story,
            scroll: view.scroll,
            selection: view.selection,
            onSelect: _select,
            onAddStep: _add,
            onGraph: () => _structure(false),
          )
        : StoryGraphCanvas(
            project: controller.project,
            storyId: story.id,
            viewState: view.graph,
            selection: view.selection,
            onSelect: _select,
            onConnect: (request) {
              controller.connect(request);
              _refresh();
            },
            onDisconnect: (edge) {
              controller.disconnect(edge.id);
              _refresh();
            },
            onAddStep: _add,
            onOpenScene: (id) => widget.onOpenScene(id),
          );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          if (!compact || view.library) ...[
            SizedBox(width: compact ? 240 : 260, child: library),
            const SizedBox(width: 12),
          ],
          Expanded(child: center),
          if (story != null && (!compact || view.inspector)) ...[
            const SizedBox(width: 12),
            SizedBox(width: compact ? 280 : 300, child: inspector),
          ],
        ],
      ),
    );
  }
}
