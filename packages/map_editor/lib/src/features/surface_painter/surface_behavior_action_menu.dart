import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../editor/state/editor_notifier.dart';
import 'surface_to_gameplay_zone_action.dart';
import 'surface_to_gameplay_zone_dialog.dart';

enum _SurfaceBehaviorChoice {
  tallGrassEncounter,
  surfableWater,
  lavaHazard,
}

class SurfaceBehaviorActionMenu extends StatelessWidget {
  const SurfaceBehaviorActionMenu({
    super.key,
    required this.map,
    required this.surfaceLayer,
    required this.surfacePresetId,
    required this.presets,
    required this.encounterTables,
    required this.notifier,
  });

  final MapData? map;
  final SurfaceLayer? surfaceLayer;
  final String? surfacePresetId;
  final List<ProjectSurfacePreset> presets;
  final List<ProjectEncounterTable> encounterTables;
  final EditorNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      onPressed: map == null ? null : () => _openBehaviorMenu(context),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.wand_stars, size: 16),
          SizedBox(width: 4),
          Flexible(
            child: Text('Créer un comportement depuis cette surface'),
          ),
        ],
      ),
    );
  }

  Future<void> _openBehaviorMenu(BuildContext context) async {
    final choice = await showCupertinoModalPopup<_SurfaceBehaviorChoice>(
      context: context,
      builder: (sheetContext) {
        return CupertinoActionSheet(
          title: const Text('Créer un comportement depuis cette surface'),
          message: const Text('Choisissez le comportement gameplay à créer.'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop(
                _SurfaceBehaviorChoice.tallGrassEncounter,
              ),
              child: const Text('Herbe haute avec rencontres'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop(
                _SurfaceBehaviorChoice.surfableWater,
              ),
              child: const Text('Eau surfable'),
            ),
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(sheetContext).pop(
                _SurfaceBehaviorChoice.lavaHazard,
              ),
              child: const Text('Lave dangereuse'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Annuler'),
          ),
        );
      },
    );

    if (!context.mounted || choice == null) {
      return;
    }

    switch (choice) {
      case _SurfaceBehaviorChoice.tallGrassEncounter:
        await _openTallGrassDialog(context);
      case _SurfaceBehaviorChoice.surfableWater:
        await _openSurfableWaterDialog(context);
      case _SurfaceBehaviorChoice.lavaHazard:
        await _openLavaHazardDialog(context);
    }
  }

  Future<void> _openTallGrassDialog(BuildContext context) async {
    final currentMap = map;
    if (currentMap == null) {
      return;
    }
    final plan = await showCupertinoDialog<SurfaceGameplayZoneGenerationPlan>(
      context: context,
      builder: (dialogContext) {
        return SurfaceToGameplayZoneDialog(
          map: currentMap,
          surfaceLayer: surfaceLayer,
          surfacePresetId: surfacePresetId,
          presets: presets,
          encounterTables: encounterTables,
          onConfirm: (plan) => Navigator.of(dialogContext).pop(plan),
        );
      },
    );
    if (plan == null) {
      return;
    }
    applyTallGrassEncounterGameplayZonePlan(
      notifier: notifier,
      plan: plan,
    );
  }

  Future<void> _openSurfableWaterDialog(BuildContext context) async {
    final currentMap = map;
    if (currentMap == null) {
      return;
    }
    final plan = await showCupertinoDialog<SurfaceGameplayZoneGenerationPlan>(
      context: context,
      builder: (dialogContext) {
        return SurfableWaterSurfaceGameplayZoneDialog(
          map: currentMap,
          surfaceLayer: surfaceLayer,
          surfacePresetId: surfacePresetId,
          presets: presets,
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
    final plan = await showCupertinoDialog<SurfaceGameplayZoneGenerationPlan>(
      context: context,
      builder: (dialogContext) {
        return LavaHazardSurfaceGameplayZoneDialog(
          map: currentMap,
          surfaceLayer: surfaceLayer,
          surfacePresetId: surfacePresetId,
          presets: presets,
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
