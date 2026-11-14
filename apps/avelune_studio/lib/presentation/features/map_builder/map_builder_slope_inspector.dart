import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_slope_tool.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class MapBuilderSlopeInspector extends StatelessWidget {
  const MapBuilderSlopeInspector({
    super.key,
    required this.stair,
    required this.state,
    required this.models,
    required this.onModel,
  });

  final bool stair;
  final MapSlopeToolState state;
  final List<TerrainStairModel> models;
  final ValueChanged<TerrainStairModel> onModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final failure = state.loadFailure;
    final help = Text(
      stair ? l10n.stairHelp : l10n.slopeHelp,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    return Column(
      key: const ValueKey('map-slope-inspector'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!stair)
          StudioSection(title: l10n.slopeHelpTitle, children: [help])
        else ...[
          StudioSection(
            title: l10n.stairModelTitle,
            children: [
              if (state.loading)
                StudioLoadingState(label: l10n.stairModelLoading)
              else if (failure != null)
                StudioNotice(
                  l10n.stairModelLoadFailed('$failure'),
                  isError: true,
                )
              else if (models.isEmpty)
                StudioNotice(l10n.stairModelEmpty)
              else
                for (final model in models)
                  StudioChoice(
                    key: ValueKey('map-stair-model-${model.model.id}'),
                    label: model.model.name,
                    subtitle: l10n.stairModelSize(
                      model.acrossCells,
                      model.alongCells,
                      model.levels,
                    ),
                    selected: model.model.id == state.stairModelId,
                    onTap: () => onModel(model),
                  ),
            ],
          ),
          const SizedBox(height: StudioSpacing.l),
          help,
        ],
      ],
    );
  }
}

({String message, bool isError})? mapBuilderSlopeNotice(
  AppLocalizations l10n,
  MapSlopeOutcome? outcome,
) {
  final problem = outcome?.problem;
  if (problem == null) {
    return outcome?.mound == true
        ? (message: l10n.slopeNoticeMound, isError: false)
        : null;
  }
  return (
    message: switch (problem) {
      MapSlopeProblem.busy => l10n.slopeProblemBusy,
      MapSlopeProblem.outside => l10n.slopeProblemOutside,
      MapSlopeProblem.directionAmbiguous => l10n.slopeProblemDirection,
      MapSlopeProblem.downhill => l10n.slopeProblemDownhill,
      MapSlopeProblem.groundNotFlat => l10n.slopeProblemGroundNotFlat,
      MapSlopeProblem.noCliff => l10n.slopeProblemNoCliff,
      MapSlopeProblem.edgeAmbiguous => l10n.slopeProblemEdgeAmbiguous,
      MapSlopeProblem.heightMismatch => l10n.slopeProblemHeightMismatch,
      MapSlopeProblem.noRoom => l10n.slopeProblemNoRoom,
      MapSlopeProblem.noStairModel => l10n.slopeProblemNoStairModel,
      MapSlopeProblem.stairModelUnavailable =>
        l10n.slopeProblemStairModelUnavailable,
      MapSlopeProblem.rampConflict => l10n.slopeProblemRampConflict,
      MapSlopeProblem.surfaceLimit => l10n.slopeProblemSurfaceLimit,
      MapSlopeProblem.cliffRefused => l10n.slopeProblemCliffRefused,
      MapSlopeProblem.unknown => l10n.slopeProblemUnknown,
    },
    isError: true,
  );
}
