import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:map_core/map_core.dart';

import '../../../../design_system/design_system.dart';

class PlacedElementWarpDestinationEditor extends StatefulWidget {
  const PlacedElementWarpDestinationEditor({
    super.key,
    required this.effect,
    required this.maps,
    required this.onChanged,
  });

  final MapPlacedElementEffect effect;
  final List<ProjectMapEntry> maps;
  final ValueChanged<MapPlacedElementEffect> onChanged;

  @override
  State<PlacedElementWarpDestinationEditor> createState() =>
      _PlacedElementWarpDestinationEditorState();
}

class _PlacedElementWarpDestinationEditorState
    extends State<PlacedElementWarpDestinationEditor> {
  late MapPlacedElementEffect _draftEffect;
  late final TextEditingController _xController;
  late final TextEditingController _yController;

  @override
  void initState() {
    super.initState();
    _draftEffect = widget.effect;
    _xController = TextEditingController(
      text: (_draftEffect.targetPos?.x ?? 0).toString(),
    );
    _yController = TextEditingController(
      text: (_draftEffect.targetPos?.y ?? 0).toString(),
    );
  }

  @override
  void didUpdateWidget(covariant PlacedElementWarpDestinationEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.effect == widget.effect) {
      return;
    }
    _draftEffect = widget.effect;
    _syncCoordinateController(
      _xController,
      (_draftEffect.targetPos?.x ?? 0).toString(),
    );
    _syncCoordinateController(
      _yController,
      (_draftEffect.targetPos?.y ?? 0).toString(),
    );
  }

  @override
  void dispose() {
    _xController.dispose();
    _yController.dispose();
    super.dispose();
  }

  void _syncCoordinateController(
    TextEditingController controller,
    String value,
  ) {
    if (controller.text == value) {
      return;
    }
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _emit(MapPlacedElementEffect next) {
    setState(() => _draftEffect = next);
    widget.onChanged(next);
  }

  void _updateCoordinate({int? x, int? y}) {
    final current = _draftEffect.targetPos ?? const GridPos(x: 0, y: 0);
    _emit(
      _draftEffect.copyWith(
        targetPos: GridPos(x: x ?? current.x, y: y ?? current.y),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedMapId = _draftEffect.targetMapId?.trim() ?? '';
    final mapItems = <PokeMapDropdownItem<String>>[
      for (final map in widget.maps)
        PokeMapDropdownItem(value: map.id, label: map.name),
    ];
    if (selectedMapId.isNotEmpty &&
        !mapItems.any((item) => item.value == selectedMapId)) {
      mapItems.add(
        PokeMapDropdownItem(
          value: selectedMapId,
          label: '$selectedMapId (introuvable)',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PokeMapDropdownField<String>(
          key: const Key('placed-warp-target-map'),
          label: 'Carte de destination',
          value: selectedMapId,
          items: mapItems,
          onChanged: (targetMapId) =>
              _emit(_draftEffect.copyWith(targetMapId: targetMapId)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: PokeMapTextField(
                label: 'Arrivée X',
                controller: _xController,
                fieldKey: const Key('placed-warp-target-x'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null) {
                    _updateCoordinate(x: parsed);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: PokeMapTextField(
                label: 'Arrivée Y',
                controller: _yController,
                fieldKey: const Key('placed-warp-target-y'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  final parsed = int.tryParse(value);
                  if (parsed != null) {
                    _updateCoordinate(y: parsed);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
