part of 'terrain_draft_controller.dart';

extension _TerrainDraftSpatialEdits on TerrainDraftController {
  bool _setSelectedModelAnimation(int? animationIndex) {
    final part = partFor(selectedRule);
    final source = part?.source;
    if (source is! SmartTileModel3dSource || part == null) return false;
    final model = manifest.models3d
        .where((entry) => entry.id == source.modelId)
        .firstOrNull;
    if (model == null) return false;
    assignModel(
      model,
      scale: source.scale,
      offsetX: source.offsetX,
      offsetY: source.offsetY,
      offsetZ: source.offsetZ,
      quarterTurns: part.transform.quarterTurns,
      animationIndex: animationIndex,
      changeAnimation: true,
    );
    return true;
  }

  void _assignModel(
    ProjectModel3dEntry model, {
    bool all = false,
    double scale = 1,
    double? offsetX,
    double offsetY = 0,
    double? offsetZ,
    int quarterTurns = 0,
    int? animationIndex,
    bool changeAnimation = false,
  }) {
    final owner = manifest.resourceLibraryCatalog
        .entryFor('smartTilePreset', draft.targetPresetId)
        ?.mapId;
    if (!spatial ||
        !scale.isFinite ||
        scale <= 0 ||
        !offsetY.isFinite ||
        (offsetX != null && !offsetX.isFinite) ||
        (offsetZ != null && !offsetZ.isFinite) ||
        quarterTurns < 0 ||
        quarterTurns > 3 ||
        (changeAnimation &&
            animationIndex != null &&
            !model.inspection.animations.any(
              (clip) => clip.index == animationIndex,
            )) ||
        !manifest.models3d.any((entry) => entry.id == model.id) ||
        !manifest.resourceLibraryCatalog.availableForMap(
          'model3d',
          model.id,
          owner ?? '',
        )) {
      return;
    }
    final previous = partFor(selectedRule);
    final previousSource = previous?.source;
    final baseSource =
        previousSource is SmartTileModel3dSource &&
            previousSource.modelId == model.id
        ? previousSource.copyWith(
            scale: scale,
            offsetX: offsetX ?? previousSource.offsetX,
            offsetY: offsetY,
            offsetZ: offsetZ ?? previousSource.offsetZ,
          )
        : SmartTileVisualSource.model3d(
            modelId: model.id,
            scale: scale,
            offsetX: offsetX ?? 0,
            offsetY: offsetY,
            offsetZ: offsetZ ?? 0,
          );
    final source = changeAnimation
        ? (baseSource as SmartTileModel3dSource).copyWith(
            animationIndex: animationIndex,
          )
        : baseSource;
    final transform = SmartTileSpriteTransform(quarterTurns: quarterTurns);
    final part = previous == null
        ? SmartTileVisualPart(source: source, transform: transform)
        : previous.copyWith(source: source, transform: transform);
    final expanded = selectedRule >= 16 && draft.rules.length == 16;
    final rules = <SmartTileRule>[
      ...draft.rules,
      if (expanded)
        for (var index = 16; index < 20; index++)
          spatialTerrainRule(
            index,
            null,
            draft.defaultMaterialId!,
            uniform: false,
          ),
    ];
    _record(
      draft.copyWith(
        rules: [
          for (var index = 0; index < rules.length; index++)
            if (all || index == selectedRule)
              rules[index].candidates.isEmpty
                  ? spatialTerrainRule(
                      index,
                      part,
                      draft.defaultMaterialId!,
                      uniform: uniform,
                    )
                  : rules[index].copyWith(
                      candidates: [
                        rules[index].candidates.single.copyWith(parts: [part]),
                      ],
                    )
            else
              rules[index],
        ],
        topology: expanded ? SmartTileTopology.blob8 : draft.topology,
        templateHint: expanded
            ? SmartTileTemplateHint.blob47
            : draft.templateHint,
        guideId: expanded ? 'avelune-spatial-path20-v1' : draft.guideId,
        transformPolicy: quarterTurns == 0
            ? draft.transformPolicy
            : draft.transformPolicy.copyWith(allowQuarterTurns: true),
      ),
    );
  }

  void _setSpatialConnections(bool connections) {
    if (!spatial || connections == !uniform) return;
    final part = partFor(selectedRule);
    selectedRule = 0;
    _record(
      draft.copyWith(
        rules: [
          for (var index = 0; index < (connections ? 16 : 1); index++)
            spatialTerrainRule(
              index,
              part,
              draft.defaultMaterialId!,
              uniform: !connections,
            ),
        ],
        topology: connections
            ? SmartTileTopology.cardinal4
            : SmartTileTopology.uniform,
        templateHint: connections
            ? SmartTileTemplateHint.edge16
            : SmartTileTemplateHint.simple,
        coveragePolicy: connections
            ? SmartTileCoveragePolicy.sparse
            : SmartTileCoveragePolicy.complete,
        guideId: connections
            ? 'avelune-spatial-cardinal4-v1'
            : 'avelune-spatial-uniform-v1',
      ),
    );
  }
}
