import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import 'presentation_view_state.dart';
import 'presentation_clip_labels.dart';

class PresentationLibraryElements extends StatelessWidget {
  const PresentationLibraryElements({
    super.key,
    required this.asset,
    required this.view,
    required this.changed,
    required this.onLayer,
    this.beforeSelection,
  });
  final PresentationCinematicAsset asset;
  final PresentationViewState view;
  final VoidCallback changed;
  final bool Function()? beforeSelection;
  final void Function(String, Map<String, Object?>) onLayer;
  List<PresentationLayer> _ordered(PresentationCinematicAsset asset) =>
      asset.layers.toList()..sort((a, b) {
        final z = b.zIndex.compareTo(a.zIndex);
        return z == 0 ? a.id.compareTo(b.id) : z;
      });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text('Ordre visuel · du devant vers le fond'),
      const SizedBox(height: 10),
      Expanded(
        child: ListView(
          children: [
            for (final layer in _ordered(asset)) ...[
              Row(
                children: [
                  StudioTool(
                    label:
                        '${layer.visible ? 'Masquer' : 'Afficher'} ${layer.label}',
                    icon: layer.visible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    onPressed: () => onLayer(
                      'presentationLayer.setVisibility',
                      {'layerId': layer.id, 'visible': !layer.visible},
                    ),
                  ),
                  StudioTool(
                    label:
                        '${layer.locked ? 'Déverrouiller' : 'Verrouiller'} ${layer.label}',
                    icon: layer.locked ? Icons.lock_outline : Icons.lock_open,
                    onPressed: () => onLayer('presentationLayer.setLocked', {
                      'layerId': layer.id,
                      'locked': !layer.locked,
                    }),
                  ),
                  Expanded(
                    child: Text(
                      layer.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  for (final direction in const {
                    -1: 'Devant',
                    1: 'Derrière',
                  }.entries)
                    Expanded(
                      child: StudioTool(
                        label: '${direction.value} : ${layer.label}',
                        icon: direction.key < 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        onPressed:
                            asset.isLayerEffectivelyLocked(layer.id) ||
                                _ordered(asset).indexOf(layer) + direction.key <
                                    0 ||
                                _ordered(asset).indexOf(layer) +
                                        direction.key >=
                                    asset.layers.length
                            ? null
                            : () => onLayer('presentationLayer.move', {
                                'layerId': layer.id,
                                'insertionIndex':
                                    _ordered(asset).indexOf(layer) +
                                    direction.key,
                                'targetFolderId': asset
                                    .folderForLayer(layer.id)
                                    ?.id,
                              }),
                      ),
                    ),
                ],
              ),
              for (final track in asset.tracks)
                for (final clip in track.clips.where(
                  (c) => presentationClipLayer(c) == layer.id,
                ))
                  ListTile(
                    dense: true,
                    selected: view.editing.selectedClipIds.contains(clip.id),
                    title: Text(
                      presentationClipLabel(clip),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(presentationClipKind(clip)),
                    onTap: () {
                      if (!(beforeSelection?.call() ?? true)) return;
                      view.editing.selectClip(clip.id);
                      changed();
                    },
                  ),
            ],
          ],
        ),
      ),
    ],
  );
}
