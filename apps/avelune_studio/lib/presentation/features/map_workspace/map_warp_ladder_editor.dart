import 'package:flutter/material.dart';

import '../../../features/map_workspace/application/map_warp_drafts.dart';

import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';

class MapWarpLadderEditor extends StatefulWidget {
  const MapWarpLadderEditor({
    super.key,
    required this.warp,
    required this.onApply,
  });
  final MapWarp warp;
  final ValueChanged<MapWarpLadder?> onApply;

  @override
  State<MapWarpLadderEditor> createState() => _MapWarpLadderEditorState();
}

class _MapWarpLadderEditorState extends State<MapWarpLadderEditor> {
  late MapWarpLadderDraft draft;

  @override
  void initState() {
    super.initState();
    draft = MapWarpLadderDraft(widget.warp);
  }

  @override
  void didUpdateWidget(MapWarpLadderEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.warp.id != widget.warp.id ||
        oldWidget.warp.ladder != widget.warp.ladder) {
      draft.reset(widget.warp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = draft.value, invalid = draft.invalid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          label: 'Passage par échelle',
          value: draft.mode,
          options: const {
            'none': 'Désactivé',
            'up': 'Monter',
            'down': 'Descendre',
          },
          onChanged: (value) => setState(() => draft.mode = value),
        ),
        if (draft.mode != 'none') ...[
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Orientation sur l’échelle',
            value: draft.facing,
            options: const {
              'north': 'Nord',
              'south': 'Sud',
              'east': 'Est',
              'west': 'Ouest',
            },
            onChanged: (value) => setState(() => draft.facing = value),
          ),
          const SizedBox(height: 8),
          StudioDraftField(
            key: const ValueKey('ladder-height'),
            label: 'Hauteur parcourue (cases)',
            value: draft.height,
            keyboardType: TextInputType.number,
            errorText: invalid
                ? 'Hauteur : plus de 0 à 16 cases ; durée : plus de 0 à 10 000 ms.'
                : null,
            onChanged: (value) => setState(() => draft.height = value),
          ),
          const SizedBox(height: 8),
          StudioDraftField(
            key: const ValueKey('ladder-duration'),
            label: 'Durée de montée ou descente (ms)',
            value: draft.duration,
            keyboardType: TextInputType.number,
            onChanged: (value) => setState(() {
              draft.duration = value;
              draft.durationTouched = true;
            }),
          ),
        ],
        const SizedBox(height: 8),
        StudioButton(
          key: const ValueKey('apply-warp-ladder'),
          label: 'Appliquer le passage par échelle',
          onPressed: !invalid && value != widget.warp.ladder
              ? () => widget.onApply(value)
              : null,
        ),
      ],
    );
  }
}
