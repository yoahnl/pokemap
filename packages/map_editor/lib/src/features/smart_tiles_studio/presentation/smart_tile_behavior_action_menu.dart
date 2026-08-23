import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../editor/state/editor_notifier.dart';
import '../../../ui/design_system/design_system.dart';
import '../application/smart_tile_to_gameplay_zone_action.dart';
import 'smart_tile_to_gameplay_zone_dialog.dart';

enum _SmartTileBehaviorChoice {
  tallGrassEncounter,
  surfableWater,
  lavaHazard,
}

class SmartTileBehaviorActionMenu extends StatelessWidget {
  const SmartTileBehaviorActionMenu({
    super.key,
    required this.map,
    required this.smartTileLayer,
    required this.smartTilePresetId,
    required this.materialId,
    required this.catalog,
    required this.encounterTables,
    required this.notifier,
  });

  final MapData? map;
  final SmartTileLayer? smartTileLayer;
  final String? smartTilePresetId;
  final String? materialId;
  final ProjectSmartTileCatalog catalog;
  final List<ProjectEncounterTable> encounterTables;
  final EditorNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return PokeMapButton(
      onPressed: map == null ? null : () => _openBehaviorMenu(context),
      variant: PokeMapButtonVariant.secondary,
      size: PokeMapButtonSize.compact,
      leading: const Icon(Icons.auto_awesome_outlined),
      child: const Text('Créer un comportement'),
    );
  }

  Future<void> _openBehaviorMenu(BuildContext context) async {
    final choice =
        await showPokeMapConfirmationDialog<_SmartTileBehaviorChoice>(
      context: context,
      title: 'Créer un comportement depuis ce Smart Tile',
      message: 'Choisissez le comportement gameplay à créer.',
      actions: const <PokeMapDialogAction<_SmartTileBehaviorChoice>>[
        PokeMapDialogAction(
          label: 'Herbe haute avec rencontres',
          value: _SmartTileBehaviorChoice.tallGrassEncounter,
        ),
        PokeMapDialogAction(
          label: 'Eau surfable',
          value: _SmartTileBehaviorChoice.surfableWater,
        ),
        PokeMapDialogAction(
          label: 'Lave dangereuse',
          value: _SmartTileBehaviorChoice.lavaHazard,
        ),
      ],
    );

    if (!context.mounted || choice == null) {
      return;
    }

    switch (choice) {
      case _SmartTileBehaviorChoice.tallGrassEncounter:
        await _openTallGrassDialog(context);
      case _SmartTileBehaviorChoice.surfableWater:
        await _openSurfableWaterDialog(context);
      case _SmartTileBehaviorChoice.lavaHazard:
        await _openLavaHazardDialog(context);
    }
  }

  Future<void> _openTallGrassDialog(BuildContext context) async {
    final currentMap = map;
    final currentLayer = smartTileLayer;
    final currentMaterialId = materialId;
    if (currentMap == null ||
        currentLayer == null ||
        currentMaterialId == null) {
      return;
    }
    final configuration =
        await showDialog<SmartTileEncounterBehaviorConfiguration>(
      context: context,
      builder: (dialogContext) {
        return SmartTileEncounterBehaviorDialog(
          map: currentMap,
          smartTileLayer: currentLayer,
          smartTilePresetId: smartTilePresetId,
          materialId: currentMaterialId,
          catalog: catalog,
          encounterTables: encounterTables,
          onConfirm: (value) => Navigator.of(dialogContext).pop(value),
        );
      },
    );
    if (configuration == null) {
      return;
    }
    if (configuration.isClear) {
      await notifier.clearSmartTileLayerEncounterBehavior(
        mapId: currentMap.id,
        layerId: currentLayer.id,
      );
      return;
    }
    await notifier.applySmartTileLayerEncounterBehavior(
      mapId: currentMap.id,
      layerId: currentLayer.id,
      materialId: currentMaterialId,
      encounterTableId: configuration.encounterTableId,
      encounterKind: EncounterKind.walk,
    );
  }

  Future<void> _openSurfableWaterDialog(BuildContext context) async {
    final currentMap = map;
    if (currentMap == null) {
      return;
    }
    final plan = await showDialog<SmartTileGameplayZoneGenerationPlan>(
      context: context,
      builder: (dialogContext) {
        return SurfableWaterSmartTileGameplayZoneDialog(
          map: currentMap,
          smartTileLayer: smartTileLayer,
          smartTilePresetId: smartTilePresetId,
          materialId: materialId,
          catalog: catalog,
          onConfirm: (plan) => Navigator.of(dialogContext).pop(plan),
        );
      },
    );
    if (plan == null) {
      return;
    }
    applySurfableWaterGameplayZonePlan(
      notifier: notifier,
      plan: plan,
    );
  }

  Future<void> _openLavaHazardDialog(BuildContext context) async {
    final currentMap = map;
    if (currentMap == null) {
      return;
    }
    final plan = await showDialog<SmartTileGameplayZoneGenerationPlan>(
      context: context,
      builder: (dialogContext) {
        return LavaHazardSmartTileGameplayZoneDialog(
          map: currentMap,
          smartTileLayer: smartTileLayer,
          smartTilePresetId: smartTilePresetId,
          materialId: materialId,
          catalog: catalog,
          onConfirm: (plan) => Navigator.of(dialogContext).pop(plan),
        );
      },
    );
    if (plan == null) {
      return;
    }
    applyLavaHazardGameplayZonePlan(
      notifier: notifier,
      plan: plan,
    );
  }
}
