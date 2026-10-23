import 'package:flutter/material.dart';
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
  late MapWarpTransitionType _type;
  late String _durationMs;
  bool _durationTouched = false;

  @override
  void initState() {
    super.initState();
    _reset(widget.warp.transition);
  }

  @override
  void didUpdateWidget(MapWarpTransitionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.warp.id != widget.warp.id ||
        oldWidget.warp.transition != widget.warp.transition) {
      _reset(widget.warp.transition);
    }
  }

  void _reset(MapWarpTransition transition) {
    _type = transition.type;
    _durationMs = (transition.durationSeconds * 1000).round().toString();
    _durationTouched = false;
  }

  MapWarpTransition? get _draft {
    final duration = _durationTouched ? int.tryParse(_durationMs.trim()) : null;
    if (_durationTouched &&
        (duration == null || duration < 1 || duration > 5000)) {
      return null;
    }
    return MapWarpTransition(
      type: _type,
      durationSeconds: duration == null
          ? widget.warp.transition.durationSeconds
          : duration / 1000,
    );
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
    final draft = _draft;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          label: 'Transition d’écran',
          value: _type.name,
          options: const {
            'hgss': 'Obturateur (style HGSS)',
            'fade': 'Fondu noir',
            'none': 'Aucune',
          },
          onChanged: (type) => setState(() {
            _type = MapWarpTransitionType.values.byName(type);
          }),
        ),
        const SizedBox(height: 8),
        StudioDraftField(
          key: const ValueKey('warp-transition-duration'),
          label: 'Durée (ms)',
          value: _durationMs,
          keyboardType: TextInputType.number,
          helperText: _type == MapWarpTransitionType.none
              ? 'Aucun effet d’écran pour ce passage.'
              : 'Durée de chaque fermeture et ouverture, de 1 à 5 000 ms.',
          errorText: draft == null
              ? 'Indiquez un nombre entier de 1 à 5 000 ms.'
              : null,
          onChanged: (value) => setState(() {
            _durationTouched = true;
            _durationMs = value;
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
              onPressed: draft != null && draft != widget.warp.transition
                  ? () => widget.onApply(draft)
                  : null,
            ),
            StudioButton(
              key: const ValueKey('preview-warp-transition'),
              label: 'Aperçu',
              icon: Icons.play_arrow,
              secondary: true,
              onPressed: draft == null ? null : () => _preview(draft),
            ),
            StudioTool(
              label: 'Valeurs par défaut',
              icon: Icons.restart_alt,
              onPressed: () => setState(() {
                _reset(const MapWarpTransition());
                _durationTouched = true;
              }),
            ),
          ],
        ),
      ],
    );
  }
}
