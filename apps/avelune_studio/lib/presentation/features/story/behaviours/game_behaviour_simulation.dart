import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_simulation.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class GameBehaviourSimulation extends StatelessWidget {
  const GameBehaviourSimulation({
    super.key,
    required this.binding,
    required this.record,
  });

  final MapBuilderStoryBinding binding;
  final NarrativeEventRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final open = binding.simulating == record.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: StudioButton(
            key: const ValueKey('map-story-simulate'),
            variant: StudioButtonVariant.secondary,
            icon: Icons.play_circle_outline,
            label: open ? l10n.simulationClose : l10n.simulationOpen,
            onPressed: binding.ready
                ? () => binding.toggleSimulation(record.id)
                : null,
          ),
        ),
        if (open)
          MapBuilderStorySimulation(
            key: ValueKey(record.id),
            binding: binding,
            record: record,
          ),
      ],
    );
  }
}
