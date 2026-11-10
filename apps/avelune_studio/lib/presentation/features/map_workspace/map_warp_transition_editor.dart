import 'package:flutter/material.dart';

import '../../../features/map_workspace/application/map_warp_drafts.dart';

import 'package:map_core/map_core_domain.dart';
import 'package:map_runtime/map_runtime.dart' show MapWarpTransitionPreview;

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/dialogs/studio_review_dialog.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_asset_preview.dart';
import '../../shared/widgets/layout/studio_panel.dart';

class MapWarpTransitionEditor extends StatefulWidget {
  const MapWarpTransitionEditor({
    super.key,
    required this.warp,
    required this.onApply,
  });

  final MapWarp warp;
  final ValueChanged<MapWarpTransition> onApply;

  @override
  State<MapWarpTransitionEditor> createState() =>
      _MapWarpTransitionEditorState();
}

class _MapWarpTransitionEditorState extends State<MapWarpTransitionEditor> {
  late MapWarpTransitionDraft draft;

  @override
  void initState() {
    super.initState();
    draft = MapWarpTransitionDraft(widget.warp.transition);
  }

  @override
  void didUpdateWidget(MapWarpTransitionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.warp.id != widget.warp.id ||
        oldWidget.warp.transition != widget.warp.transition) {
      draft.reset(widget.warp.transition);
    }
  }

  void _preview(MapWarpTransition transition) {
    var replay = 0;
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => StudioReviewDialog(
          title: 'Aperçu de la transition',
          content: StudioAssetPreview(
            height: 240,
            checkerboard: false,
            child: MapWarpTransitionPreview(
              key: ValueKey('warp-transition-preview-$replay'),
              transition: transition,
              child: const StudioPanel(
                children: [
                  Center(child: Icon(Icons.home_outlined, size: 64)),
                  SizedBox(height: 12),
                  Center(child: Text('Carte d’arrivée')),
                ],
              ),
            ),
          ),
          confirmLabel: 'Rejouer',
          onConfirmed: () => update(() => replay++),
          cancelLabel: 'Fermer',
          onCancelled: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = draft.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          label: 'Transition d’écran',
          value: draft.type.name,
          options: const {
            'hgss': 'Obturateur (style HGSS)',
            'fade': 'Fondu noir',
            'none': 'Aucune',
          },
          onChanged: (type) => setState(() {
            draft.type = MapWarpTransitionType.values.byName(type);
          }),
        ),
        const SizedBox(height: 8),
        StudioDraftField(
          key: const ValueKey('warp-transition-duration'),
          label: 'Durée (ms)',
          value: draft.durationMs,
          keyboardType: TextInputType.number,
          helperText: draft.type == MapWarpTransitionType.none
              ? 'Aucun effet d’écran pour ce passage.'
              : 'Durée de chaque fermeture et ouverture, de 1 à 5 000 ms.',
          errorText: value == null
              ? 'Indiquez un nombre entier de 1 à 5 000 ms.'
              : null,
          onChanged: (value) => setState(() {
            draft.durationTouched = true;
            draft.durationMs = value;
          }),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StudioButton(
              key: const ValueKey('apply-warp-transition'),
              label: 'Appliquer la transition',
              onPressed: value != null && value != widget.warp.transition
                  ? () => widget.onApply(value)
                  : null,
            ),
            StudioButton(
              key: const ValueKey('preview-warp-transition'),
              label: 'Aperçu',
              icon: Icons.play_arrow,
              secondary: true,
              onPressed: value == null ? null : () => _preview(value),
            ),
            StudioTool(
              label: 'Valeurs par défaut',
              icon: Icons.restart_alt,
              onPressed: () => setState(() {
                draft.defaults();
              }),
            ),
          ],
        ),
      ],
    );
  }
}
