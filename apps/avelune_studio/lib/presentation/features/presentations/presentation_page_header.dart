part of 'presentation_workspace_page.dart';

extension _PresentationPageHeader on _PresentationWorkspacePageState {
  Widget header(bool compact) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (!compact)
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 4),
          child: Text(
            'Histoire  ›  Cinématiques  ›  ${controller.active?.asset.title ?? 'Présentation'}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      StudioPageHeader(
        title: 'Cinématique de présentation',
        prominent: !compact,
        description: compact
            ? null
            : 'Composez vos illustrations, vos titres et leurs apparitions.',
        alignActionsToEnd: true,
        actions: [
          StudioTool(
            label: 'Retour à ${widget.backLabel}',
            icon: Icons.arrow_back,
            onPressed: () {
              if (flush()) {
                transport.stop();
                widget.onBack();
              }
            },
          ),
          if (controller.active case final active?) ...[
            if (active.dirty) const Text('Modifié'),
            StudioTool(
              label: 'Renommer la présentation',
              icon: Icons.edit_outlined,
              onPressed: () async {
                if (!flush()) return;
                final owner = controller.activeId;
                final name = await askNarrativeName(
                  context,
                  'Renommer la présentation',
                );
                if (mounted && owner == controller.activeId && name != null) {
                  controller.rename(name);
                  refresh();
                }
              },
            ),
            StudioTool(
              label: 'Bibliothèque visible',
              icon: Icons.view_sidebar_outlined,
              selected: view!.libraryOpen,
              onPressed: () {
                if (flush()) {
                  view!.libraryOpen = !view!.libraryOpen;
                  refresh();
                }
              },
            ),
            StudioTool(
              label: 'Inspecteur visible',
              icon: Icons.tune,
              selected: view!.inspectorOpen,
              onPressed: () {
                if (flush()) {
                  view!.inspectorOpen = !view!.inspectorOpen;
                  refresh();
                }
              },
            ),
            StudioTool(
              label: 'Annuler',
              icon: Icons.undo,
              onPressed: controller.canUndo
                  ? () {
                      if (flush()) {
                        controller.undo();
                        refresh();
                      }
                    }
                  : null,
            ),
            StudioTool(
              label: 'Rétablir',
              icon: Icons.redo,
              onPressed: controller.canRedo
                  ? () {
                      if (flush()) {
                        controller.redo();
                        refresh();
                      }
                    }
                  : null,
            ),
            StudioButton(
              label: 'Enregistrer',
              icon: Icons.save_outlined,
              loading: controller.saving,
              onPressed: save,
            ),
            StudioButton(
              label: 'Tester la scène',
              icon: Icons.play_circle_outline,
              secondary: true,
              onPressed: scenarioPreview,
            ),
            StudioTool(
              label: 'Options de la présentation',
              icon: Icons.more_horiz,
              onPressed: documentMenu,
            ),
          ],
          if (widget.onMapCinematics != null)
            StudioButton(
              label: 'Sur carte',
              secondary: true,
              onPressed: () {
                if (flush()) widget.onMapCinematics!();
              },
            ),
        ],
      ),
    ],
  );
  Widget transportBar() => AnimatedBuilder(
    animation: Listenable.merge([
      PresentationTransportListenable(transport),
      widget.visuals,
    ]),
    builder: (context, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.visuals.diagnostic case final diagnostic?)
          StudioNotice(diagnostic, isError: true),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              StudioTool(
                label: 'Arrêter',
                icon: Icons.stop,
                onPressed: transport.stop,
              ),
              StudioTool(
                label: 'Image précédente',
                icon: Icons.skip_previous,
                onPressed: transport.stepBackward,
              ),
              StudioTool(
                label: transport.playing ? 'Pause' : 'Lire',
                icon: transport.playing ? Icons.pause : Icons.play_arrow,
                onPressed: () async {
                  if (!flush()) return;
                  if (transport.playing) {
                    transport.pause();
                  } else {
                    await widget.visuals.settled;
                    if (mounted) transport.play();
                  }
                },
              ),
              StudioTool(
                label: 'Image suivante',
                icon: Icons.skip_next,
                onPressed: transport.stepForward,
              ),
              Text(
                '${presentationTime(transport.timeUs)} / ${presentationTime(transport.durationUs)}',
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                child: StudioSelect(
                  label: 'Format',
                  value: view!.portrait ? 'portrait' : 'landscape',
                  options: const {
                    'landscape': 'Paysage 16:9',
                    'portrait': 'Portrait 9:16',
                  },
                  onChanged: (value) {
                    if (flush()) {
                      view!.portrait = value == 'portrait';
                      widget.visuals.setOrientation(view!.portrait);
                      refresh();
                    }
                  },
                ),
              ),
              StudioTool(
                label: 'Comparer les formats',
                icon: Icons.compare,
                selected: view!.compare,
                onPressed: () {
                  view!.compare = !view!.compare;
                  refresh();
                },
              ),
              StudioTool(
                label: 'Réduire les mouvements',
                icon: Icons.motion_photos_off,
                selected: view!.reduceMotion,
                onPressed: () {
                  view!.reduceMotion = !view!.reduceMotion;
                  refresh();
                },
              ),
              StudioTool(
                label: 'Sous-titres visibles',
                icon: Icons.closed_caption_outlined,
                selected: view!.captions,
                onPressed: () {
                  view!.captions = !view!.captions;
                  refresh();
                },
              ),
              StudioTool(
                label: 'Boucle',
                icon: Icons.repeat,
                selected: transport.loop,
                onPressed: () => transport.setLoop(!transport.loop),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
