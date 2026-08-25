import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../ui/design_system/design_system.dart';
import '../application/smart_tile_to_gameplay_zone_presenter.dart';

final class SmartTileEncounterBehaviorConfiguration {
  const SmartTileEncounterBehaviorConfiguration.set({
    required this.encounterTableId,
    this.battleTransitionIds = const <String>[],
    this.priority = 0,
  }) : isClear = false;

  const SmartTileEncounterBehaviorConfiguration.clear()
    : encounterTableId = '',
      battleTransitionIds = const <String>[],
      priority = 0,
      isClear = true;

  final String encounterTableId;

  /// Les transitions de début de combat de ce calque — BETA-BAT-034.
  ///
  /// Plusieurs sélections = le runtime en tire une par rencontre, de façon
  /// déterministe ; aucune = le défaut du projet, puis le défaut moteur.
  final List<String> battleTransitionIds;

  /// Qui gagne quand deux calques se recouvrent — BETA-ENC-008.
  ///
  /// À priorité égale sur des cases communes, l'export refuse le projet : le
  /// moteur ne saurait pas quelle table de rencontres appliquer.
  final int priority;

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
  late List<String> _battleTransitionIds;
  late int _priority;

  @override
  void initState() {
    super.initState();
    final walkTables = _walkTables;
    final behavior = widget.smartTileLayer?.encounterBehavior;
    final currentTableId = behavior?.encounter.encounterTableId;
    _encounterTableId = walkTables.any((table) => table.id == currentTableId)
        ? currentTableId
        : walkTables.firstOrNull?.id;
    _battleTransitionIds = List<String>.of(
      behavior?.encounter.battleTransitionIds ?? const <String>[],
    );
    _priority = behavior?.priority ?? 0;
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
                      battleTransitionIds: List<String>.unmodifiable(
                        _battleTransitionIds,
                      ),
                      priority: _priority,
                    ),
                  )
                : null,
            child: Text(isUpdate ? 'Mettre à jour' : 'Ajouter au calque'),
          ),
        ],
      ),
      // BETA-BAT-034 : le sélecteur de transitions allonge ce dialogue, et
      // PokeMapDialog ne défile pas — sur un écran court, le bouton de
      // validation sortait du cadre. Le contenu défile donc ici, le pied de
      // dialogue restant toujours atteignable.
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.55,
        ),
        child: SingleChildScrollView(
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
                  onChanged: (value) =>
                      setState(() => _encounterTableId = value),
                ),
              if (walkTables.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildPriorityPicker(context),
                const SizedBox(height: 16),
                _buildBattleTransitionsPicker(context),
              ],
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
        ),
      ),
    );
  }

  /// BETA-ENC-008 : qui gagne quand deux calques se recouvrent.
  ///
  /// À priorité égale sur des cases communes, l'export REFUSE le projet — le
  /// moteur ne saurait pas quelle table appliquer. Avant ce réglage, la
  /// priorité arrivait toujours à zéro depuis l'éditeur et la seule issue
  /// était la gomme : un recouvrement délibéré, un sous-bois dans une
  /// clairière, était impossible à authorer.
  Widget _buildPriorityPicker(BuildContext context) {
    // Une valeur posée hors de cette échelle — par le MCP, par exemple —
    // reste sélectionnable : le menu ne doit pas la faire disparaître.
    final levels = <int>{0, 1, 2, 3, _priority}.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PokeMapDropdownField<int>(
          key: const Key('smart-tile-encounter-priority'),
          label: 'Priorité de la rencontre',
          value: _priority,
          items: [
            for (final level in levels)
              PokeMapDropdownItem(
                value: level,
                label: switch (level) {
                  0 => 'Normale (0)',
                  1 => 'Au-dessus (1)',
                  2 => 'Prioritaire (2)',
                  3 => 'Maximale (3)',
                  _ => 'Niveau $level',
                },
              ),
          ],
          onChanged: (value) => setState(() => _priority = value),
        ),
        const SizedBox(height: 4),
        Text(
          'Deux calques qui se recouvrent doivent avoir des priorités '
          'différentes, sinon l’export est refusé.',
          style: TextStyle(
            fontSize: 11,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    );
  }

  /// BETA-BAT-034 : les transitions se choisissent ICI, sur le calque qui
  /// porte la rencontre.
  ///
  /// Le sélecteur existait sur les zones de gameplay et par dresseur, mais
  /// depuis BETA-ENC-007 les rencontres vivent sur les calques Smart Tile :
  /// il était resté là où l'auteur ne passe plus, et les quinze transitions
  /// de BETA-BAT-019 étaient devenues inatteignables.
  Widget _buildBattleTransitionsPicker(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Transitions de combat',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final transitionId in battleWildTransitionIds)
              PokeMapSelectableChip(
                key: Key('smart-tile-battle-transition-$transitionId'),
                label:
                    battleTransitionDisplayLabels[transitionId] ?? transitionId,
                selected: _battleTransitionIds.contains(transitionId),
                onToggle: () => setState(() {
                  final next = List<String>.of(_battleTransitionIds);
                  if (next.contains(transitionId)) {
                    next.remove(transitionId);
                  } else {
                    next.add(transitionId);
                  }
                  _battleTransitionIds = next;
                }),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _battleTransitionIds.isEmpty
              ? 'Aucune sélection : le défaut du projet s’applique.'
              : 'Plusieurs sélections : une transition est tirée à chaque '
                    'rencontre.',
          style: TextStyle(
            fontSize: 11,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
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
          onPressed: preview.canConfirm
              ? () => widget.onConfirm(preview.plan!)
              : null,
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
  const _InfoLine({required this.label, required this.value});

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
