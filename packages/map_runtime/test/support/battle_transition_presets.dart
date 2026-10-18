import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_transition_spec.dart';

File _catalogueFile() {
  var current = Directory.current.absolute;
  while (true) {
    final file = File('${current.path}/packages/map_core/assets/battle_transition_presets.v1.json');
    if (file.existsSync()) return file;
    if (current.parent.path == current.path) throw StateError('Transition preset data is unavailable.');
    current = current.parent;
  }
}

final transitionPresetDocument = jsonDecode(_catalogueFile().readAsStringSync()) as Map<String, dynamic>;
final transitionPresetDefinitions = List<BattleTransitionDefinition>.unmodifiable(
    (transitionPresetDocument['definitions'] as List).map(BattleTransitionDefinition.fromJson));
final battleTransitionRegistry = {
  for (final definition in transitionPresetDefinitions) definition.id: battleTransitionSpecFromDefinition(definition),
};
final battleWildTransitionIds = transitionPresetDefinitions.where((definition) =>
    definition.usages.contains(BattleTransitionUsage.wild)).map((definition) => definition.id).toList();
final battleTrainerTransitionIds = transitionPresetDefinitions.where((definition) =>
    definition.usages.contains(BattleTransitionUsage.trainer)).map((definition) => definition.id).toList();
final battleTransitionSheetManifest = {
  for (final asset in transitionPresetDocument['assets'] as List)
    (asset as Map)['reference'] as String: (asset['reference'] as String).substring('embedded:'.length),
};
ProjectBattleTransitionConfig transitionPresetConfig({String? wildTransitionId, String? trainerTransitionId}) =>
    ProjectBattleTransitionConfig(wildTransitionId: wildTransitionId,
        trainerTransitionId: trainerTransitionId, definitions: transitionPresetDefinitions);
final battleTransitionRbyWild = battleTransitionRegistry['rby_wild']!;
final battleTransitionDppTrainer = battleTransitionRegistry['dpp_trainer']!;
final battleTransitionRsWild = battleTransitionRegistry['rs_wild']!;
final battleTransitionRsCave = battleTransitionRegistry['rs_cave']!;
