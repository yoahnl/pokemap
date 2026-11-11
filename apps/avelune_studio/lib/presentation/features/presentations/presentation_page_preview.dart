part of 'presentation_workspace_page.dart';

extension _PresentationPagePreview on _PresentationWorkspacePageState {
  Widget consumers(PresentationCinematicAsset asset) {
    final links = controller.sceneUses(asset.id, selected: view?.selected);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Utilisations dans les scènes (${links.length})'),
        for (final link in links)
          StudioButton(
            label: '${link.scene.name} · ${link.node.title ?? 'Présentation'}',
            secondary: true,
            onPressed: widget.onConsumer == null
                ? null
                : () {
                    if (flush()) {
                      transport.pause();
                      widget.onConsumer!(link.scene.id, link.node.id);
                    }
                  },
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget canvas(PresentationCinematicAsset asset, PresentationViewState state) {
    final editor = PresentationCanvas(
      asset: asset,
      view: state,
      transport: transport,
      visuals: widget.visuals,
      onPatch: patch,
      changed: refresh,
      beforeSelection: flush,
    );
    if (!state.compare) return editor;
    return Row(
      children: [
        Expanded(child: editor),
        const SizedBox(width: 8),
        Expanded(
          child: AnimatedBuilder(
            animation: PresentationTransportListenable(transport),
            builder: (context, _) => Center(
              child: AspectRatio(
                aspectRatio: state.portrait ? 16 / 9 : 9 / 16,
                child: transport.frame == null
                    ? const SizedBox.shrink()
                    : widget.visuals.frame(
                        asset: asset,
                        frame: transport.frame!,
                        portrait: !state.portrait,
                        reduceMotion: state.reduceMotion,
                        reduceFlashes: state.reduceFlashes,
                        showCaptions: state.captions,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> scenarioPreview() async {
    if (!flush() || controller.active == null) return;
    final asset = controller.active!.asset;
    final scenes = controller.scenarioScenes(asset.id);
    if (scenes.isEmpty) {
      view!.actionError = presentationScenarioUnlinkedError;
      refresh();
      return;
    }
    var scene = presentationScenarioScene(scenes, widget.previewSceneId);
    if (scene == null) {
      scene = await showDialog<SceneAsset>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tester quelle scène ?'),
          content: SizedBox(
            width: 400,
            height: 300,
            child: ListView(
              children: [
                for (final entry in scenes)
                  ListTile(
                    title: Text(entry.name),
                    onTap: () => Navigator.pop(context, entry),
                  ),
              ],
            ),
          ),
        ),
      );
      if (!mounted || scene == null) return;
    }
    final testedScene = scene;
    transport.pause();
    await widget.visuals.release();
    if (!mounted) return;
    final preview = await widget.visuals.createScenarioPreview(
      project: controller.project,
      sceneId: testedScene.id,
      asset: asset,
      portrait: view!.portrait,
      reducedMotion: view!.reduceMotion,
    );
    if (!mounted) {
      await preview.close();
      return;
    }
    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          child: SizedBox(
            width: 1000,
            height: 650,
            child: AnimatedBuilder(
              animation: preview,
              builder: (context, _) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${testedScene.name} · ${preview.statusLabel}',
                          ),
                        ),
                        StudioButton(
                          label: 'Lancer le parcours',
                          onPressed: preview.running
                              ? null
                              : () => unawaited(preview.run()),
                        ),
                        StudioButton(
                          label: 'Fermer l’aperçu',
                          secondary: true,
                          onPressed: () async {
                            await preview.stop();
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  if (preview.failure case final failure?)
                    StudioNotice('$failure', isError: true),
                  Expanded(child: preview.surface()),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      await preview.close();
      if (mounted) {
        await widget.visuals.prepare(asset, portrait: view!.portrait);
      }
    }
  }
}
