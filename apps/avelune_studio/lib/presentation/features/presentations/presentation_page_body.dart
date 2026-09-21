part of 'presentation_workspace_page.dart';

extension _PresentationPageBody on _PresentationWorkspacePageState {
  Widget content(BuildContext context) {
    sync();
    final asset = controller.active?.asset, state = view;
    return StudioDialogueTheme(
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyS, meta: true): save,
          const SingleActivator(LogicalKeyboardKey.keyS, control: true): save,
          const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
            if (flush()) {
              controller.undo();
              refresh();
            }
          },
          const SingleActivator(
            LogicalKeyboardKey.keyZ,
            meta: true,
            shift: true,
          ): () {
            if (flush()) {
              controller.redo();
              refresh();
            }
          },
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 1000 ||
                MediaQuery.textScalerOf(context).scale(14) > 20;
            final library = PresentationLibrary(
              visuals: widget.visuals,
              beforeSelection: flush,
              controller: controller,
              views: widget.views,
              changed: refresh,
              onOpen: open,
              onCreate: create,
              onLayer: (action, params) {
                if (flush()) controller.apply(action, params);
                refresh();
              },
            );
            final inspector = asset == null || state == null
                ? null
                : PresentationInspector(
                    mediaCatalog: controller.active?.mediaCatalog,
                    consumers: consumers(asset),
                    beforeSelection: flush,
                    asset: asset,
                    view: state,
                    onPatch: patch,
                    changed: refresh,
                    onDelete: deleteSelection,
                  );
            return Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header(compact),
                  if (controller.busy) const LinearProgressIndicator(),
                  if (controller.error ?? state?.actionError case final error?)
                    StudioNotice(error, isError: true),
                  if (controller.active?.link != null)
                    const StudioNotice(
                      'Enregistrer publie ce montage et son lien dans la scène concernée.',
                    ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!compact && (state?.libraryOpen ?? true)) ...[
                          SizedBox(width: 250, child: library),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: asset == null || state == null
                              ? (compact
                                    ? library
                                    : Center(
                                        child: StudioButton(
                                          label: 'Créer une présentation',
                                          icon: Icons.add,
                                          loading: controller.busy,
                                          onPressed: create,
                                        ),
                                      ))
                              : Column(
                                  children: [
                                    Expanded(
                                      flex: (state.canvasShare * 100).round(),
                                      child: canvas(asset, state),
                                    ),
                                    transportBar(),
                                    GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onVerticalDragUpdate: (event) =>
                                          resizeCanvas(
                                            () => state.canvasShare =
                                                (state.canvasShare +
                                                        event.delta.dy /
                                                            constraints
                                                                .maxHeight)
                                                    .clamp(.25, .8),
                                          ),
                                      child: SizedBox(
                                        height: 8,
                                        child: Center(
                                          child: Container(
                                            width: 60,
                                            height: 2,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.outline,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: ((1 - state.canvasShare) * 100)
                                          .round(),
                                      child: PresentationTimeline(
                                        beforeSelection: flush,
                                        asset: asset,
                                        view: state,
                                        transport: transport,
                                        onCommand: (command) {
                                          controller.apply(
                                            command.actionId,
                                            command.parameters,
                                          );
                                          refresh();
                                        },
                                        changed: refresh,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: Row(
                                        children: [
                                          StudioButton(
                                            label: 'Texte',
                                            icon: Icons.title,
                                            secondary: true,
                                            onPressed: addText,
                                          ),
                                          const SizedBox(width: 6),
                                          StudioButton(
                                            label: 'Image',
                                            icon: Icons.image_outlined,
                                            secondary: true,
                                            onPressed: () => addMedia(
                                              ProjectMediaKind.image,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          StudioButton(
                                            label: 'Vidéo',
                                            icon: Icons.movie_outlined,
                                            secondary: true,
                                            onPressed: () => addMedia(
                                              ProjectMediaKind.video,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          StudioButton(
                                            label: 'Audio',
                                            icon: Icons.music_note,
                                            secondary: true,
                                            onPressed: () => addMedia(
                                              ProjectMediaKind.audio,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          StudioButton(
                                            label: 'Repère',
                                            icon: Icons.flag_outlined,
                                            secondary: true,
                                            onPressed: addMarker,
                                          ),
                                          const SizedBox(width: 6),
                                          StudioButton(
                                            label: 'Sous-titres',
                                            icon: Icons.closed_caption_outlined,
                                            secondary: true,
                                            onPressed: () => addMedia(
                                              ProjectMediaKind.captions,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          StudioButton(
                                            label: 'Interaction',
                                            icon: Icons.touch_app_outlined,
                                            secondary: true,
                                            onPressed: () =>
                                                addMarker(interaction: true),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        if (!compact &&
                            state?.inspectorOpen == true &&
                            inspector != null) ...[
                          const SizedBox(width: 10),
                          SizedBox(width: 280, child: inspector),
                        ],
                      ],
                    ),
                  ),
                  if (compact)
                    Row(
                      children: [
                        StudioButton(
                          label: 'Bibliothèque',
                          secondary: true,
                          onPressed: () => panel(library),
                        ),
                        if (inspector != null)
                          StudioButton(
                            label: 'Inspecteur',
                            secondary: true,
                            onPressed: () => panel(inspector),
                          ),
                      ],
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
