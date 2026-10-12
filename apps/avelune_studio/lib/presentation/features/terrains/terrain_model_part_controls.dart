import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_draft_field.dart';
import '../../shared/widgets/inputs/studio_select.dart';

class TerrainModelPartControls extends StatefulWidget {
  const TerrainModelPartControls({
    super.key,
    required this.part,
    required this.onApply,
  });
  final SmartTileVisualPart part;
  final void Function(
    double scale,
    double offsetX,
    double offsetY,
    double offsetZ,
    int quarterTurns,
  )
  onApply;

  @override
  State<TerrainModelPartControls> createState() =>
      _TerrainModelPartControlsState();
}

class _TerrainModelPartControlsState extends State<TerrainModelPartControls> {
  late String scale, offset, offsetX, offsetZ;
  late int rotation;

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void didUpdateWidget(TerrainModelPartControls old) {
    super.didUpdateWidget(old);
    if (old.part != widget.part) _read();
  }

  void _read() {
    final source = widget.part.source as SmartTileModel3dSource;
    scale = source.scale.toString();
    offset = source.offsetY.toString();
    offsetX = source.offsetX.toString();
    offsetZ = source.offsetZ.toString();
    rotation = widget.part.transform.quarterTurns;
  }

  double? _number(String value) {
    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
    return parsed != null && parsed.isFinite ? parsed : null;
  }

  @override
  Widget build(BuildContext context) {
    final factor = _number(scale), height = _number(offset);
    final x = _number(offsetX), z = _number(offsetZ);
    final validScale = factor != null && factor > 0;
    final followsTerrain =
        (widget.part.source as SmartTileModel3dSource).followTerrain;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          label: 'Rotation de la pièce',
          value: '$rotation',
          options: const {'0': '0°', '1': '90°', '2': '180°', '3': '270°'},
          onChanged: (value) => setState(() => rotation = int.parse(value)),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StudioDraftField(
                key: const ValueKey('terrain-model-scale'),
                label: 'Échelle de la pièce',
                value: scale,
                errorText: validScale ? null : 'Nombre positif requis',
                onChanged: (value) => setState(() => scale = value),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StudioDraftField(
                key: const ValueKey('terrain-model-height'),
                label: followsTerrain ? 'Décalage vertical' : 'Hauteur absolue',
                helperText: followsTerrain
                    ? 'En cases, au-dessus du sol'
                    : 'En unités de carte, indépendante du relief',
                value: offset,
                errorText: height == null ? 'Nombre fini requis' : null,
                onChanged: (value) => setState(() => offset = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StudioDraftField(
                key: const ValueKey('terrain-model-offset-x'),
                label: 'Décalage X',
                value: offsetX,
                errorText: x == null ? 'Nombre fini requis' : null,
                onChanged: (value) => setState(() => offsetX = value),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StudioDraftField(
                key: const ValueKey('terrain-model-offset-z'),
                label: 'Décalage Z',
                value: offsetZ,
                errorText: z == null ? 'Nombre fini requis' : null,
                onChanged: (value) => setState(() => offsetZ = value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('En unités de carte, avant la rotation de la pièce.'),
        const SizedBox(height: 8),
        StudioButton(
          key: const ValueKey('terrain-model-apply'),
          label: 'Appliquer à cette pièce',
          secondary: true,
          onPressed: validScale && height != null && x != null && z != null
              ? () => widget.onApply(factor, x, height, z, rotation)
              : null,
        ),
      ],
    );
  }
}
