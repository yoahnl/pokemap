import '../../../features/scenes/application/scene_world_visual_draft.dart';
import '../project_settings/spatial_visual_controls.dart';

import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';

class SceneWorldVisualActionForm extends StatefulWidget {
  const SceneWorldVisualActionForm({
    super.key,
    required this.current,
    required this.onApply,
    this.loadVisualMedia,
  });
  final SceneActionPayload? current;
  final ValueChanged<SceneNodePayload> onApply;
  final Future<ProjectMediaCatalog> Function()? loadVisualMedia;
  @override
  State<SceneWorldVisualActionForm> createState() =>
      _SceneWorldVisualActionFormState();
}

class _SceneWorldVisualActionFormState
    extends State<SceneWorldVisualActionForm> {
  late final SceneWorldVisualDraft draft;
  @override
  void initState() {
    super.initState();
    draft = SceneWorldVisualDraft(
      current: widget.current,
      loadVisualMedia: widget.loadVisualMedia,
      changed: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void didUpdateWidget(SceneWorldVisualActionForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    draft.configure(
      current: widget.current,
      loadVisualMedia: widget.loadVisualMedia,
    );
  }

  @override
  void dispose() {
    draft.dispose();
    super.dispose();
  }

  Widget _select(String key, String label, Map<String, String> options) =>
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: StudioSelect(
          label: label,
          value: options.containsKey(draft.values[key])
              ? draft.values[key]
              : null,
          options: options,
          onChanged: (value) => setState(() {
            if (key == 'operation') {
              draft.defaults(value);
            } else {
              draft.values[key] = value;
            }
          }),
        ),
      );
  Widget _field(String key, String label, {String? help}) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: StudioDraftField(
      key: ValueKey('world-visual-$key'),
      label: label,
      value: draft.values[key] ?? '',
      helperText: help,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      onChanged: (value) => setState(() => draft.values[key] = value),
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _select('operation', 'Effet', const {
        'atmosphere': 'Changer l’ambiance 3D',
        'restoreAtmosphere': 'Rétablir l’ambiance héritée',
        'showPicture': 'Afficher une image',
        'movePicture': 'Déplacer une image',
        'erasePicture': 'Effacer une image',
        'flash': 'Flash coloré',
        'shake': 'Secouer l’écran',
      }),
      _select('scope', 'Durée de présence', const {
        'scene': 'Scène',
        'map': 'Carte',
      }),
      const StudioNotice(
        'Scène : disparaît à sa fin. Carte : reste jusqu’au changement de carte. Les effets sont suspendus pendant une présentation ou un combat.',
      ),
      if (draft.operation == 'atmosphere')
        SpatialVisualControls(
          patch: draft.visual,
          inherited: SpatialVisualPatch.fromScene(
            camera: SpatialCameraProfile(),
            atmosphere: SpatialAtmosphereSettings(),
          ),
          onChanged: (value) {
            if (!value.isEmpty) setState(() => draft.visual = value);
          },
        ),
      if (draft.isPicture || draft.operation == 'erasePicture')
        _field(
          'slotId',
          'Emplacement de l’image',
          help: 'De 1 à 100. Déplacer ou effacer reprend le même emplacement et la même portée.',
        ),
      if (draft.operation == 'showPicture') ...[
        _select('mediaAssetId', 'Image', draft.images),
        if (draft.images.isEmpty)
          const StudioNotice(
            'Importez une image dans la médiathèque de présentation pour la sélectionner ici.',
          ),
        if (draft.values['mediaAssetId'] != null &&
            !draft.images.containsKey(draft.values['mediaAssetId']))
          const StudioNotice(
            'L’image enregistrée est indisponible. Choisissez une image disponible.',
            isError: true,
          ),
        if (draft.error != null) StudioNotice(draft.error!, isError: true),
      ],
      if (draft.isFramed) ...[
        _field('referenceWidth', 'Largeur du cadre (px)'),
        _field(
          'referenceHeight',
          'Hauteur du cadre (px)',
          help:
              'Le cadre garde ses proportions et reste centré dans le Player.',
        ),
      ],
      if (draft.isPicture) ...[
        _select('origin', 'Origine', const {
          'topLeft': 'Coin supérieur gauche',
          'center': 'Centre',
        }),
        _field('x', 'Position horizontale (px)'),
        _field('y', 'Position verticale (px)'),
        _field('scaleX', 'Échelle horizontale'),
        _field('scaleY', 'Échelle verticale'),
        _field('opacity', 'Opacité', help: 'De 0 à 1.'),
      ],
      if (draft.operation == 'flash') ...[
        for (final entry in const {
          'red': 'Rouge',
          'green': 'Vert',
          'blue': 'Bleu',
          'alpha': 'Intensité',
        }.entries)
          _field(entry.key, entry.value, help: 'De 0 à 255.'),
      ],
      if (draft.operation == 'shake') ...[
        _field('power', 'Amplitude (px)', help: 'De 0 à 128 pixels du cadre.'),
        _field(
          'speed',
          'Fréquence (Hz)',
          help: 'De 0,1 à 60 oscillations par seconde.',
        ),
      ],
      if (draft.operation == 'atmosphere' ||
          draft.operation == 'restoreAtmosphere' ||
          draft.operation == 'movePicture' ||
          draft.operation == 'flash' ||
          draft.operation == 'shake') ...[
        _field(
          'durationMs',
          'Durée (ms)',
          help: 'Jusqu’à 60 000 ms, sur le temps de simulation.',
        ),
        StudioToggleRow(
          label: 'Attendre la fin',
          value: draft.values['waitForCompletion'] == 'true',
          onChanged: (value) =>
              setState(() => draft.values['waitForCompletion'] = '$value'),
        ),
      ],
      const SizedBox(height: 12),
      StudioButton(
        label: widget.current == null
            ? 'Ajouter l’action'
            : 'Appliquer l’action',
        onPressed: draft.payload == null
            ? null
            : () => widget.onApply(draft.payload!),
      ),
    ],
  );
}
