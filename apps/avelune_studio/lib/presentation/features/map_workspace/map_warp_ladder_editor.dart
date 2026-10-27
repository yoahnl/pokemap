import 'package:flutter/material.dart';
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
  late String _mode, _facing, _height, _duration;
  bool _durationTouched = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void didUpdateWidget(MapWarpLadderEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.warp.id != widget.warp.id ||
        oldWidget.warp.ladder != widget.warp.ladder) {
      _reset();
    }
  }

  void _reset() {
    final ladder = widget.warp.ladder ?? MapWarpLadder();
    _mode = widget.warp.ladder?.direction.name ?? 'none';
    _facing = ladder.facing.name;
    _height = ladder.heightCells.toString();
    _duration = (ladder.durationSeconds * 1000).round().toString();
    _durationTouched = false;
  }

  MapWarpLadder? get _draft {
    if (_mode == 'none') return null;
    final height = double.tryParse(_height),
        duration = double.tryParse(_duration);
    if (height == null || duration == null) return null;
    try {
      return MapWarpLadder(
        direction: MapWarpLadderDirection.values.byName(_mode),
        facing: EntityFacing.values.byName(_facing),
        heightCells: height,
        durationSeconds: _durationTouched
            ? duration / 1000
            : (widget.warp.ladder?.durationSeconds ?? 16 / 30),
      );
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft, invalid = _mode != 'none' && _draft == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          label: 'Passage par échelle',
          value: _mode,
          options: const {
            'none': 'Désactivé',
            'up': 'Monter',
            'down': 'Descendre',
          },
          onChanged: (value) => setState(() => _mode = value),
        ),
        if (_mode != 'none') ...[
          const SizedBox(height: 8),
          StudioSelect(
            label: 'Orientation sur l’échelle',
            value: _facing,
            options: const {
              'north': 'Nord',
              'south': 'Sud',
              'east': 'Est',
              'west': 'Ouest',
            },
            onChanged: (value) => setState(() => _facing = value),
          ),
          const SizedBox(height: 8),
          StudioDraftField(
            key: const ValueKey('ladder-height'),
            label: 'Hauteur parcourue (cases)',
            value: _height,
            keyboardType: TextInputType.number,
            errorText: invalid
                ? 'Hauteur : plus de 0 à 16 cases ; durée : plus de 0 à 10 000 ms.'
                : null,
            onChanged: (value) => setState(() => _height = value),
          ),
          const SizedBox(height: 8),
          StudioDraftField(
            key: const ValueKey('ladder-duration'),
            label: 'Durée de montée ou descente (ms)',
            value: _duration,
            keyboardType: TextInputType.number,
            onChanged: (value) => setState(() {
              _duration = value;
              _durationTouched = true;
            }),
          ),
        ],
        const SizedBox(height: 8),
        StudioButton(
          key: const ValueKey('apply-warp-ladder'),
          label: 'Appliquer le passage par échelle',
          onPressed: !invalid && draft != widget.warp.ladder
              ? () => widget.onApply(draft)
              : null,
        ),
      ],
    );
  }
}
