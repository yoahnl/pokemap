import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../../ui/assets/editor_image_cache.dart';
import '../../../../ui/design_system/design_system.dart';
import '../../application/smart_tile_form_projection.dart';
import '../../application/smart_tile_test_layer_controller.dart';
import '../workbench/smart_tile_lab_surface.dart';

class SmartTileTestStage extends StatelessWidget {
  const SmartTileTestStage({
    super.key,
    required this.controller,
    required this.tool,
    required this.forms,
    required this.scenarios,
    required this.isPublishable,
    required this.onToolChanged,
    required this.onTargetPressed,
    required this.onReset,
    required this.onScenarioSelected,
    this.onContinue,
    this.variantCount = 0,
    this.guideSummaryLabels = const <String>[],
    this.tilesetPathsById = const <String, String>{},
    this.showStructure = true,
    this.onShowStructureChanged,
    this.projectRootPath,
    this.imageCache,
  });

  static const double labCellExtent = 44;

  final SmartTileTestLayerController controller;
  final SmartTileLabTool tool;
  final List<SmartTileFormReadModel> forms;
  final List<SmartTileLabScenarioResult> scenarios;
  final bool isPublishable;
  final ValueChanged<SmartTileLabTool> onToolChanged;
  final ValueChanged<SmartTileLabTarget> onTargetPressed;
  final VoidCallback onReset;
  final ValueChanged<int> onScenarioSelected;
  final VoidCallback? onContinue;
  final int variantCount;
  final List<String> guideSummaryLabels;

  /// Absolute path of every tileset this preset samples, by tileset id.
  final Map<String, String> tilesetPathsById;
  final bool showStructure;
  final ValueChanged<bool>? onShowStructureChanged;
  final String? projectRootPath;
  final EditorImageCache? imageCache;

  @override
  Widget build(BuildContext context) {
    final resolved = scenarios.where((scenario) => scenario.isResolved).length;
    final missing = scenarios.length - resolved;
    final formsByMask = <int, SmartTileFormReadModel>{
      for (final form in forms) form.mask: form,
    };
    final inspection = controller.inspection;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        PokeMapSectionHeader(
          title: 'Laboratoire exact',
          description:
              'Cette couche temporaire utilise le même champ natif, le même contexte et le même résolveur que la carte et le runtime.',
          trailing: PokeMapBadge(
            key: const Key('smart-tiles-lab-result'),
            label: '$resolved / ${scenarios.length} résolus',
            variant: isPublishable
                ? PokeMapBadgeVariant.success
                : PokeMapBadgeVariant.error,
          ),
        ),
        const SizedBox(height: 12),
        PokeMapBadge(
          label: missing == 0
              ? 'Aucune forme manquante'
              : '$missing forme(s) non résolue(s)',
          variant: missing == 0
              ? PokeMapBadgeVariant.success
              : controller.preset.coveragePolicy ==
                      SmartTileCoveragePolicy.sparse
                  ? PokeMapBadgeVariant.warning
                  : PokeMapBadgeVariant.error,
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final label in guideSummaryLabels) PokeMapBadge(label: label),
            PokeMapBadge(label: '$variantCount variantes supplémentaires'),
          ],
        ),
        const SizedBox(height: 18),
        PokeMapSectionHeader(
          title: 'Peinture temporaire',
          description: _topologyInstruction(controller.preset.topology),
          trailing: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              PokeMapButton(
                key: const Key('smart-tiles-lab-pencil'),
                onPressed: () => onToolChanged(SmartTileLabTool.pencil),
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                isSelected: tool == SmartTileLabTool.pencil,
                leading: const Icon(CupertinoIcons.pencil, size: 14),
                child: const Text('Crayon'),
              ),
              PokeMapButton(
                key: const Key('smart-tiles-lab-eraser'),
                onPressed: () => onToolChanged(SmartTileLabTool.eraser),
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                isSelected: tool == SmartTileLabTool.eraser,
                leading: const Icon(CupertinoIcons.clear, size: 14),
                child: const Text('Gomme'),
              ),
              PokeMapButton(
                key: const Key('smart-tiles-lab-structure'),
                onPressed: onShowStructureChanged == null
                    ? null
                    : () => onShowStructureChanged!(!showStructure),
                variant: PokeMapButtonVariant.ghost,
                size: PokeMapButtonSize.small,
                isSelected: showStructure,
                leading: const Icon(CupertinoIcons.grid, size: 14),
                child: const Text('Structure'),
              ),
              PokeMapButton(
                key: const Key('smart-tiles-lab-reset'),
                onPressed: onReset,
                variant: PokeMapButtonVariant.secondary,
                size: PokeMapButtonSize.small,
                child: const Text('Réinitialiser'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        PokeMapPanel(
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SmartTileLabSurface(
              layer: controller.layer,
              mapSize: controller.size,
              topology: controller.preset.topology,
              visuals: controller.resolveVisuals(
                destinationCellWidth: labCellExtent,
                destinationCellHeight: labCellExtent,
              ),
              tilesetPathsById: tilesetPathsById,
              showStructure: showStructure,
              cellExtent: labCellExtent,
              projectRootPath: projectRootPath,
              imageCache: imageCache,
              selectedX: inspection?.x,
              selectedY: inspection?.y,
              onTargetPressed: onTargetPressed,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _SmartTileLabInspectionPanel(inspection: inspection),
        const SizedBox(height: 18),
        const PokeMapSectionHeader(
          title: 'Scénarios canoniques',
          description:
              'Chaque scénario recrée sa structure dans une couche neuve avant de solliciter le résolveur partagé.',
        ),
        const SizedBox(height: 8),
        if (scenarios.isEmpty)
          const PokeMapEmptyState(
            title: 'Aucun scénario standard',
            description:
                'Peignez librement la couche pour tester cette configuration sur mesure.',
          )
        else
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              for (final scenario in scenarios)
                PokeMapButton(
                  key: Key('smart-tiles-lab-scenario-${scenario.mask}'),
                  onPressed: () => onScenarioSelected(scenario.mask),
                  variant: PokeMapButtonVariant.ghost,
                  size: PokeMapButtonSize.small,
                  isSelected: scenario.isResolved,
                  leading: Icon(
                    scenario.isResolved
                        ? CupertinoIcons.check_mark_circled_solid
                        : CupertinoIcons.exclamationmark_circle,
                    size: 13,
                  ),
                  child: Text(
                    formsByMask[scenario.mask]?.label ?? 'Forme personnalisée',
                  ),
                ),
            ],
          ),
        if (onContinue != null) ...[
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerRight,
            child: PokeMapButton(
              key: const Key('smart-tiles-go-to-publish'),
              onPressed: isPublishable ? onContinue : null,
              trailing: const Icon(CupertinoIcons.chevron_right, size: 14),
              child: const Text('Vérifier avant publication'),
            ),
          ),
        ],
      ],
    );
  }
}

class _SmartTileLabInspectionPanel extends StatelessWidget {
  const _SmartTileLabInspectionPanel({required this.inspection});

  final SmartTileLabInspection? inspection;

  @override
  Widget build(BuildContext context) {
    final value = inspection;
    if (value == null) {
      return const PokeMapEmptyState(
        key: Key('smart-tiles-lab-empty-inspection'),
        title: 'Aucune cellule inspectée',
        description:
            'Peignez une cellule, un segment ou une intersection pour voir le résultat.',
        icon: Icon(CupertinoIcons.scope),
        compact: true,
      );
    }
    final status = value.resolution.status;
    final resolved = status == SmartTileResolutionStatus.resolved;
    return PokeMapPanel(
      key: const Key('smart-tiles-lab-inspection'),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          PokeMapSectionHeader(
            title: 'Cellule ${value.x + 1}, ${value.y + 1}',
            description: _resolutionDescription(status),
            trailing: PokeMapBadge(
              label: resolved ? 'Résolue' : 'À corriger',
              variant: resolved
                  ? PokeMapBadgeVariant.success
                  : PokeMapBadgeVariant.warning,
            ),
          ),
          if (value.visuals.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: <Widget>[
                for (final visual in value.visuals)
                  PokeMapBadge(
                    label: _channelLabel(visual.channel),
                    variant: PokeMapBadgeVariant.info,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            value.visuals.isEmpty
                ? 'Aucun élément visuel produit.'
                : '${value.visuals.length} élément(s) visuel(s), ordonnés comme dans la carte.',
          ),
        ],
      ),
    );
  }
}

String _topologyInstruction(SmartTileTopology topology) => switch (topology) {
      SmartTileTopology.uniform ||
      SmartTileTopology.cardinal4 ||
      SmartTileTopology.blob8 =>
        'Cliquez les cellules. Le voisinage est recalculé immédiatement.',
      SmartTileTopology.wangEdge4 =>
        'Cliquez au centre pour l’intention, puis sur les séparations pour les arêtes horizontales ou verticales.',
      SmartTileTopology.wangCorner4 =>
        'Cliquez au centre pour l’intention, puis aux intersections pour les coins.',
      SmartTileTopology.wang8 =>
        'Combinez cellules, séparations et intersections sur la même couche mixte.',
    };

String _resolutionDescription(SmartTileResolutionStatus status) =>
    switch (status) {
      SmartTileResolutionStatus.resolved =>
        'La règle, la variante et les transformations ont été résolues par map_core.',
      SmartTileResolutionStatus.noIntent =>
        'Cette cellule ne contient encore aucune intention de matière.',
      SmartTileResolutionStatus.noMatchingRule =>
        'Aucune forme publiée ne correspond à ce voisinage.',
      SmartTileResolutionStatus.ambiguousRule =>
        'Plusieurs formes ont la même priorité pour ce voisinage.',
      SmartTileResolutionStatus.noCandidate =>
        'La forme existe mais ne contient aucune variante utilisable.',
      SmartTileResolutionStatus.invalidRule =>
        'Une forme contient une contrainte incompatible avec sa structure.',
    };

String _channelLabel(SmartTileRenderChannel channel) => switch (channel) {
      SmartTileRenderChannel.ground => 'Sol',
      SmartTileRenderChannel.understory => 'Sous-bois',
      SmartTileRenderChannel.canopy => 'Canopée',
      SmartTileRenderChannel.foreground => 'Premier plan',
      SmartTileRenderChannel.shadow => 'Ombre',
    };
