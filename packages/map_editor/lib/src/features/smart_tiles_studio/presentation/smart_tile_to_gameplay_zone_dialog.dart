import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/smart_tile_to_gameplay_zone_presenter.dart';

final class SmartTileEncounterBehaviorConfiguration {
  const SmartTileEncounterBehaviorConfiguration.set({
    required this.encounterTableId,
  }) : isClear = false;

  const SmartTileEncounterBehaviorConfiguration.clear()
    : encounterTableId = '',
      isClear = true;

  final String encounterTableId;
  final bool isClear;
}

class SmartTileEncounterBehaviorDialog extends StatefulWidget {
  const SmartTileEncounterBehaviorDialog({
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
  final ValueChanged<SmartTileEncounterBehaviorConfiguration> onConfirm;
  final VoidCallback? onCancel;

  @override
  State<SmartTileEncounterBehaviorDialog> createState() =>
      _SmartTileEncounterBehaviorDialogState();
}

class _SmartTileEncounterBehaviorDialogState
    extends State<SmartTileEncounterBehaviorDialog> {
  String? _encounterTableId;

  @override
  void initState() {
    super.initState();
    final walkTables = _walkTables;
    final currentTableId =
        widget.smartTileLayer?.encounterBehavior?.encounter.encounterTableId;
    _encounterTableId = walkTables.any((table) => table.id == currentTableId)
        ? currentTableId
        : walkTables.firstOrNull?.id;
  }

  @override
  Widget build(BuildContext context) {
    final walkTables = _walkTables;
    final sourceCellCount = _sourceCellCount;
    final canConfirm =
        widget.map != null &&
        widget.smartTileLayer != null &&
        widget.materialId != null &&
        sourceCellCount > 0 &&
        _encounterTableId != null;
    final isUpdate = widget.smartTileLayer?.encounterBehavior != null;

    return PokeMapDialog(
      title: isUpdate
          ? 'Modifier les hautes herbes du calque'
          : 'Ajouter les hautes herbes au calque',
      icon: Icons.grass,
      maxWidth: 520,
      footer: Wrap(
        alignment: WrapAlignment.end,
        spacing: 8,
        children: [
          PokeMapButton(
            onPressed: widget.onCancel ?? () => Navigator.of(context).pop(),
            variant: PokeMapButtonVariant.secondary,
            child: const Text('Annuler'),
          ),
          if (isUpdate)
            PokeMapButton(
              key: const Key('smart-tile-encounter-behavior-clear'),
              onPressed: () => widget.onConfirm(
                const SmartTileEncounterBehaviorConfiguration.clear(),
              ),
              variant: PokeMapButtonVariant.danger,
              child: const Text('Retirer du calque'),
            ),
          PokeMapButton(
            key: const Key('smart-tile-encounter-behavior-confirm'),
            onPressed: canConfirm
                ? () => widget.onConfirm(
                    SmartTileEncounterBehaviorConfiguration.set(
                      encounterTableId: _encounterTableId!,
                    ),
                  )
                : null,
            child: Text(isUpdate ? 'Mettre à jour' : 'Ajouter au calque'),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Les rencontres suivront exactement les cellules peintes de ce '
            'calque. Aucune zone de rencontre séparée ne sera créée.',
          ),
          const SizedBox(height: 12),
          _InfoLine(
            label: 'Calque',
            value: widget.smartTileLayer?.name ?? 'Aucun',
          ),
          _InfoLine(label: 'Cellules', value: '$sourceCellCount'),
          const SizedBox(height: 12),
          if (walkTables.isEmpty)
            const PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.info,
              title: 'Aucune table pour les hautes herbes',
              message:
                  'Créez d’abord une table de rencontres à pied dans '
                  'Encounter Studio.',
            )
          else
            PokeMapDropdownField<String>(
              key: const Key('smart-tile-encounter-table-picker'),
              label: 'Table de rencontres',
              value: _encounterTableId!,
              items: [
                for (final table in walkTables)
                  PokeMapDropdownItem(
                    value: table.id,
                    label: '${table.name} (${table.id})',
                  ),
              ],
              onChanged: (value) => setState(() => _encounterTableId = value),
            ),
          if (sourceCellCount == 0) ...[
            const SizedBox(height: 12),
            const PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.error,
              title: 'Aucune cellule peinte',
              message:
                  'Peignez ce matériau sur le calque avant d’ajouter '
                  'le comportement.',
            ),
          ],
          const SizedBox(height: 12),
          const PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.info,
            title: 'Plusieurs zones de rencontres',
            message:
                'Utilisez un calque Smart Tile par table de rencontres. '
                'Chaque calque peut couvrir une zone différente.',
          ),
        ],
      ),
    );
  }

  List<ProjectEncounterTable> get _walkTables => widget.encounterTables
      .where((table) => table.encounterKind == EncounterKind.walk)
      .toList(growable: false);

  int get _sourceCellCount {
    final layer = widget.smartTileLayer;
    final materialId = widget.materialId;
    final map = widget.map;
    if (layer == null || materialId == null || map == null) return 0;
    final materialValue = layer.materialPalette.indexOf(materialId);
    if (materialValue <= 0) return 0;
    final cellLimit = map.size.width * map.size.height;
    final cells = layer.field.semanticCells;
    final upperBound = cells.length < cellLimit ? cells.length : cellLimit;
    var count = 0;
    for (var index = 0; index < upperBound; index++) {
      if (cells[index] == materialValue) count++;
    }
    return count;
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
