import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import 'surface_to_gameplay_zone_presenter.dart';

class SurfaceToGameplayZoneDialog extends StatefulWidget {
  const SurfaceToGameplayZoneDialog({
    super.key,
    required this.map,
    required this.surfaceLayer,
    required this.surfacePresetId,
    required this.presets,
    required this.encounterTables,
    required this.onConfirm,
    this.onCancel,
  });

  final MapData? map;
  final SurfaceLayer? surfaceLayer;
  final String? surfacePresetId;
  final List<ProjectSurfacePreset> presets;
  final List<ProjectEncounterTable> encounterTables;
  final ValueChanged<SurfaceGameplayZoneGenerationPlan> onConfirm;
  final VoidCallback? onCancel;

  @override
  State<SurfaceToGameplayZoneDialog> createState() =>
      _SurfaceToGameplayZoneDialogState();
}

class _SurfaceToGameplayZoneDialogState
    extends State<SurfaceToGameplayZoneDialog> {
  late final TextEditingController _encounterTableController;

  @override
  void initState() {
    super.initState();
    _encounterTableController = TextEditingController(
      text:
          widget.encounterTables.isEmpty ? '' : widget.encounterTables.first.id,
    );
  }

  @override
  void dispose() {
    _encounterTableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = buildTallGrassEncounterSurfaceGameplayZonePreview(
      map: widget.map,
      surfaceLayer: widget.surfaceLayer,
      surfacePresetId: widget.surfacePresetId,
      presets: widget.presets,
      encounterTableId: _encounterTableController.text,
    );

    return CupertinoAlertDialog(
      title: const Text('Créer une zone de rencontre depuis cette surface'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          _InfoLine(label: 'Surface', value: preview.surfaceLabel),
          _InfoLine(label: 'Cellules', value: '${preview.sourceCellCount}'),
          _InfoLine(
            label: 'Zones',
            value: '${preview.generatedZoneCount}',
          ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Table de rencontres'),
          ),
          const SizedBox(height: 6),
          CupertinoTextField(
            key: const Key('surface-to-gameplay-zone-encounter-table-field'),
            controller: _encounterTableController,
            placeholder: 'route_1_grass',
            onChanged: (_) => setState(() {}),
          ),
          if (widget.encounterTables.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Disponible : ${widget.encounterTables.map((table) => table.id).join(', ')}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              preview.summaryTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(preview.summaryDescription),
          ),
          const SizedBox(height: 8),
          for (final message in preview.messages) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text('• ${message.title}'),
            ),
            const SizedBox(height: 3),
          ],
          if (preview.assessment != null) ...[
            const SizedBox(height: 8),
            _InfoLine(
              label: 'Couverture',
              value:
                  '${(preview.assessment!.coveragePercent * 100).toStringAsFixed(1)}%',
            ),
            _InfoLine(
              label: 'Hors surface',
              value:
                  '${(preview.assessment!.extraCellRatio * 100).toStringAsFixed(1)}%',
            ),
          ],
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed:
              preview.canConfirm ? () => widget.onConfirm(preview.plan!) : null,
          child: const Text('Créer les zones'),
        ),
      ],
    );
  }
}

class SurfableWaterSurfaceGameplayZoneDialog extends StatelessWidget {
  const SurfableWaterSurfaceGameplayZoneDialog({
    super.key,
    required this.map,
    required this.surfaceLayer,
    required this.surfacePresetId,
    required this.presets,
    required this.onConfirm,
    this.onCancel,
  });

  final MapData? map;
  final SurfaceLayer? surfaceLayer;
  final String? surfacePresetId;
  final List<ProjectSurfacePreset> presets;
  final ValueChanged<SurfaceGameplayZoneGenerationPlan> onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final preview = buildSurfableWaterSurfaceGameplayZonePreview(
      map: map,
      surfaceLayer: surfaceLayer,
      surfacePresetId: surfacePresetId,
      presets: presets,
    );

    return CupertinoAlertDialog(
      title: const Text('Rendre cette eau surfable'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          _InfoLine(label: 'Surface', value: preview.surfaceLabel),
          _InfoLine(label: 'Cellules', value: '${preview.sourceCellCount}'),
          const _InfoLine(label: 'Mode', value: 'Surf'),
          _InfoLine(label: 'Zones', value: '${preview.generatedZoneCount}'),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              preview.summaryTitle,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(preview.summaryDescription),
          ),
          const SizedBox(height: 8),
          for (final message in preview.messages) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text('• ${message.title}'),
            ),
            const SizedBox(height: 3),
          ],
          if (preview.assessment != null) ...[
            const SizedBox(height: 8),
            _InfoLine(
              label: 'Couverture',
              value:
                  '${(preview.assessment!.coveragePercent * 100).toStringAsFixed(1)}%',
            ),
            _InfoLine(
              label: 'Hors surface',
              value:
                  '${(preview.assessment!.extraCellRatio * 100).toStringAsFixed(1)}%',
            ),
          ],
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: onCancel ?? () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: preview.canConfirm ? () => onConfirm(preview.plan!) : null,
          child: const Text('Créer la zone Surf'),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
