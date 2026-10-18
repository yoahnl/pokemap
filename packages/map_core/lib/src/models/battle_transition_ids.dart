import 'battle_transition_definition.dart';
import 'project_battle_transitions.dart';

List<String> battleTransitionIdsForUsage(
    ProjectBattleTransitionConfig? config, BattleTransitionUsage usage) =>
    List.unmodifiable((config?.definitionsById.values ?? const <BattleTransitionDefinition>[])
        .where((definition) => definition.usages.contains(usage))
        .map((definition) => definition.id));

Map<String, String> battleTransitionLabels(ProjectBattleTransitionConfig? config) =>
    Map.unmodifiable({for (final definition in config?.definitionsById.values ?? const <BattleTransitionDefinition>[])
      definition.id: definition.label});
