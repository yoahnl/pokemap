part of 'presentation_workspace_page.dart';

extension _PresentationPageCommands on _PresentationWorkspacePageState {
  Future<void> save() async {
    if (!flush()) return;
    transport.pause();
    await controller.save();
    refresh();
  }

  Future<void> open(String id) async {
    if (!flush()) return;
    transport.stop();
    await widget.visuals.release();
    await controller.open(id);
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
    final asset = controller.active?.asset, clip = view?.selected;
    if (asset == null ||
        clip == null ||
        !view!.editing.isClipEditable(clip.id)) {
      return false;
    }
    final track = asset.tracks.firstWhere(
      (track) => track.clips.any((c) => c.id == clip.id),
    );
    final success = controller.apply('presentationClip.update', {
      'trackId': track.id,
      'clip': {...encodePresentationClip(clip), ...values},
    });
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

  String identity(String prefix) => controller.narrative.identity(prefix);
  void addClip(
    PresentationClip clip, {
    PresentationLayer? layer,
    required String label,
  }) {
    final trackId = identity('track');
    final commands = <PresentationCommand>[
      if (layer != null)
        PresentationCommand('presentationLayer.create', {
          'layer': encodePresentationLayer(layer),
        }),
      PresentationCommand('presentationTrack.create', {
        'track': {
          'id': trackId,
          'label': label,
          'kind': clip.trackKind.name,
          'clips': [encodePresentationClip(clip)],
        },
      }),
    ];
    if (controller.applyBatch(commands)) {
      sync();
      view!.editing.selectClip(clip.id);
      transport.seek(clip.startUs);
    }
    refresh();
  }

  PresentationLayer newLayer(String title) => PresentationLayer(
    id: identity('element'),
    label: title,
    zIndex:
        (controller.active!.asset.layers
            .map((l) => l.zIndex)
            .fold<int>(-1, (a, b) => a > b ? a : b)) +
        1,
  );
  int get startUs =>
      transport.timeUs >= transport.durationUs ? 0 : transport.timeUs;
  int get remainingUs => controller.active!.asset.durationUs - startUs;
  void addText() {
    if (!flush() || controller.active == null) return;
    final layer = newLayer('Texte');
    addClip(
      PresentationTextClip(
        id: identity('text'),
        startUs: startUs,
        durationUs: remainingUs,
        layerId: layer.id,
        text: 'Votre titre',
        style: PresentationTextStyle(
          fontSize: 48,
          weight: PresentationTextWeight.bold,
        ),
      ),
      layer: layer,
      label: 'Texte',
    );
  }

  void addMarker({bool interaction = false}) {
    if (!flush() || controller.active == null) return;
    addClip(
      PresentationMarkerClip(
        id: identity('marker'),
        startUs: startUs,
        label: interaction ? 'Interaction' : 'Repère',
        markerKind: interaction
            ? PresentationMarkerKind.interactionCue
            : PresentationMarkerKind.ordinary,
      ),
      label: 'Repères',
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
    if (kind == ProjectMediaKind.audio) {
      addClip(
        PresentationAudioClip(
          id: identity('audio'),
          startUs: startUs,
          durationUs: remainingUs,
          resourceId: media.id,
          audioKind: PresentationAudioKind.music,
        ),
        label: media.label,
      );
    } else if (kind == ProjectMediaKind.captions) {
      addClip(
        PresentationCaptionClip(
          id: identity('caption'),
          startUs: startUs,
          durationUs: remainingUs,
          captionId: media.id,
        ),
        label: media.label,
      );
    } else {
      final layer = newLayer(media.label);
      addClip(
        PresentationVisualClip(
          id: identity('image'),
          startUs: startUs,
          durationUs: remainingUs,
          layerId: layer.id,
          resourceId: media.id,
          mediaKind: kind == ProjectMediaKind.video
              ? PresentationVisualMediaKind.video
              : PresentationVisualMediaKind.image,
        ),
        layer: layer,
        label: media.label,
      );
    }
  }
}
