import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_conditions.dart';

class GameBehaviourConditions extends StatelessWidget {
  const GameBehaviourConditions({
    super.key,
    required this.binding,
    required this.record,
    required this.editable,
  });

  final MapBuilderStoryBinding binding;
  final NarrativeEventRecord record;
  final bool editable;

  @override
  Widget build(BuildContext context) => MapBuilderStoryConditions(
    key: ValueKey('map-story-conditions-${record.id}'),
    binding: binding,
    record: record,
    editable: editable,
  );
}
