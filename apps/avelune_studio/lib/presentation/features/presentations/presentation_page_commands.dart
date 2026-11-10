part of 'presentation_workspace_page.dart';

extension _PresentationPageCommands on _PresentationWorkspacePageState {
  Future<void> save() async {
    if (!flush()) return;
    transport.pause();
    await controller.save();
    refresh();
  }

  Future<void> create() async {
    if (!flush()) return;
    final name = await askNarrativeName(context, 'Nouvelle présentation');
    if (!mounted || name == null) return;
    if (!mounted) return;
    final template = await chooseTemplate();
    if (!mounted || template == null) return;
    await controller.create(title: name, templateId: template);
    refresh();
  }

  bool patch(Map<String, Object?> values) {
    final clip = view?.selected;
    final success = clip != null && controller.patchClip(clip.id, values);
    refresh();
    return success;
  }

  void deleteSelection() {
    if (!flush() || view == null || view!.editing.selectedClipIds.isEmpty) {
      return;
    }
    controller.apply('presentationClip.deleteBatch', {
      'clipIds': view!.editing.selectedClipIds.toList(),
    });
    refresh();
  }

  void selectAddedClip(String? id) {
    if (id != null) {
      sync();
      view!.editing.selectClip(id);
      transport.seek(view!.selected!.startUs);
    }
    refresh();
  }

  void addText() {
    if (flush()) selectAddedClip(controller.addText(timeUs: transport.timeUs));
  }

  void addMarker({bool interaction = false}) {
    if (flush())
      selectAddedClip(
        controller.addMarker(
          timeUs: transport.timeUs,
          interaction: interaction,
        ),
      );
  }

  Future<void> addMedia(ProjectMediaKind kind) async {
    if (!flush() || controller.active == null) return;
    final owner = controller.activeId;
    final entries = controller.active!.mediaCatalog.entries
        .where((m) => m.kind == kind)
        .toList();
    final media = await showDialog<ProjectMediaAsset>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisir un média du projet'),
        content: SizedBox(
          width: 480,
          height: 340,
          child: entries.isEmpty
              ? const StudioNotice(
                  'Aucun média de ce type dans le catalogue. Importez une ressource pour la préparer.',
                )
              : ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return ListTile(
                      title: Text(entry.label),
                      subtitle: Text(entry.kind.id),
                      onTap: () => Navigator.pop(context, entry),
                    );
                  },
                ),
        ),
        actions: [
          if (widget.mediaPicker != null)
            StudioButton(
              label: 'Importer un média',
              icon: Icons.file_upload_outlined,
              onPressed: () async {
                final source = await widget.mediaPicker!(kind);
                if (source == null ||
                    !mounted ||
                    owner != controller.activeId) {
                  return;
                }
                final staged = await controller.importMedia(
                  sourcePath: source.path,
                  label: source.label,
                  kind: kind,
                );
                if (context.mounted &&
                    staged != null &&
                    owner == controller.activeId) {
                  Navigator.pop(context, staged.media);
                }
              },
            ),
          StudioButton(
            label: 'Annuler',
            secondary: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
    if (!mounted || owner != controller.activeId || media == null) return;
    selectAddedClip(controller.addMediaClip(media, timeUs: transport.timeUs));
  }
}
