import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../application/smart_tile_to_gameplay_zone_presenter.dart';

class SmartTileToGameplayZoneDialog extends StatefulWidget {
  const SmartTileToGameplayZoneDialog({
    super.key,
    required this.map,
    required this.smartTileLayer,
    required this.smartTilePresetId,
    this.materialId,
    required this.catalog,
    required this.encounterTables,
    required this.onConfirm,
    this.onCancel,
  });

  final MapData? map;
  final SmartTileLayer? smartTileLayer;
  final String? smartTilePresetId;
  final String? materialId;
  final ProjectSmartTileCatalog catalog;
  final List<ProjectEncounterTable> encounterTables;
  final ValueChanged<SmartTileGameplayZoneGenerationPlan> onConfirm;
  final VoidCallback? onCancel;

  @override
  State<SmartTileToGameplayZoneDialog> createState() =>
      _SmartTileToGameplayZoneDialogState();
}

class _SmartTileToGameplayZoneDialogState
    extends State<SmartTileToGameplayZoneDialog> {
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
    final preview = buildTallGrassEncounterSmartTileGameplayZonePreview(
      map: widget.map,
      smartTileLayer: widget.smartTileLayer,
      smartTilePresetId: widget.smartTilePresetId,
      materialId: widget.materialId,
      catalog: widget.catalog,
      encounterTableId: _encounterTableController.text,
    );

    return CupertinoAlertDialog(
      title: const Text('Créer une zone de rencontre depuis ce Smart Tile'),
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
          if (preview.isSynchronization)
            _InfoLine(
              label: 'Remplacées',
              value: '${preview.existingZoneCount}',
            ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Table de rencontres'),
          ),
          const SizedBox(height: 6),
          CupertinoTextField(
            key: const Key('smart-tile-to-gameplay-zone-encounter-table-field'),
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
          child: Text(
            preview.isSynchronization
                ? 'Synchroniser les zones'
                : 'Créer les zones',
          ),
        ),
      ],
    );
  }
}

class SurfableWaterSmartTileGameplayZoneDialog extends StatelessWidget {
  const SurfableWaterSmartTileGameplayZoneDialog({
    super.key,
    required this.map,
    required this.smartTileLayer,
    required this.smartTilePresetId,
    this.materialId,
    required this.catalog,
    required this.onConfirm,
    this.onCancel,
  });

  final MapData? map;
  final SmartTileLayer? smartTileLayer;
  final String? smartTilePresetId;
  final String? materialId;
  final ProjectSmartTileCatalog catalog;
  final ValueChanged<SmartTileGameplayZoneGenerationPlan> onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final preview = buildSurfableWaterSmartTileGameplayZonePreview(
      map: map,
      smartTileLayer: smartTileLayer,
      smartTilePresetId: smartTilePresetId,
      materialId: materialId,
      catalog: catalog,
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
          if (preview.isSynchronization)
            _InfoLine(
              label: 'Remplacées',
              value: '${preview.existingZoneCount}',
            ),
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
          child: Text(
            preview.isSynchronization
                ? 'Synchroniser la zone Surf'
                : 'Créer la zone Surf',
          ),
        ),
      ],
    );
  }
}

class LavaHazardSmartTileGameplayZoneDialog extends StatefulWidget {
  const LavaHazardSmartTileGameplayZoneDialog({
    super.key,
    required this.map,
    required this.smartTileLayer,
    required this.smartTilePresetId,
    this.materialId,
    required this.catalog,
    required this.onConfirm,
    this.onCancel,
  });

  final MapData? map;
  final SmartTileLayer? smartTileLayer;
  final String? smartTilePresetId;
  final String? materialId;
  final ProjectSmartTileCatalog catalog;
  final ValueChanged<SmartTileGameplayZoneGenerationPlan> onConfirm;
  final VoidCallback? onCancel;

  @override
  State<LavaHazardSmartTileGameplayZoneDialog> createState() =>
      _LavaHazardSmartTileGameplayZoneDialogState();
}

class _LavaHazardSmartTileGameplayZoneDialogState
    extends State<LavaHazardSmartTileGameplayZoneDialog> {
  late final TextEditingController _damageController;

  @override
  void initState() {
    super.initState();
    _damageController = TextEditingController(text: '5');
  }

  @override
  void dispose() {
    _damageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preview = buildLavaHazardSmartTileGameplayZonePreview(
      map: widget.map,
      smartTileLayer: widget.smartTileLayer,
      smartTilePresetId: widget.smartTilePresetId,
      materialId: widget.materialId,
      catalog: widget.catalog,
      damagePerStep: int.tryParse(_damageController.text.trim()),
    );

    return CupertinoAlertDialog(
      title: const Text('Créer une zone de lave dangereuse'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          _InfoLine(label: 'Surface', value: preview.surfaceLabel),
          _InfoLine(label: 'Cellules', value: '${preview.sourceCellCount}'),
          const _InfoLine(label: 'Type', value: 'Lave dangereuse'),
          _InfoLine(label: 'Zones', value: '${preview.generatedZoneCount}'),
          if (preview.isSynchronization)
            _InfoLine(
              label: 'Remplacées',
              value: '${preview.existingZoneCount}',
            ),
          const SizedBox(height: 10),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Dégâts par pas'),
          ),
          const SizedBox(height: 6),
          CupertinoTextField(
            key: const Key('smart-tile-to-gameplay-zone-lava-damage-field'),
            controller: _damageController,
            keyboardType: TextInputType.number,
            placeholder: '5',
            onChanged: (_) => setState(() {}),
          ),
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
          child: Text(
            preview.isSynchronization
                ? 'Synchroniser la zone de lave'
                : 'Créer la zone de lave',
          ),
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
