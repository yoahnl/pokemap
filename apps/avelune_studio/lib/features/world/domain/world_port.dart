import 'package:map_core/map_core_domain.dart';

import '../../resources/domain/resource_port.dart';

/// Publishes the states and world rules of a project.
///
/// States already have an owner: stories publish them through `fact.create`
/// and `fact.update`. This port keeps that contract and adds the rules, so a
/// state edited here and a state edited from a story remain the same document.
abstract interface class WorldPort {
  Future<ResourceMutationReceipt> publishFact({
    required NarrativeFactDefinition? base,
    required NarrativeFactDefinition current,
  });

  Future<ResourceMutationReceipt> deleteFact(NarrativeFactDefinition base);

  Future<ResourceMutationReceipt> publishRule({
    required WorldRuleDefinition? base,
    required WorldRuleDefinition current,
  });

  Future<ResourceMutationReceipt> deleteRule(WorldRuleDefinition base);

  /// The maps the target pickers, usages and simulation read.
  Future<List<MapData>> loadMaps();
}

class WorldFailure implements Exception {
  const WorldFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
