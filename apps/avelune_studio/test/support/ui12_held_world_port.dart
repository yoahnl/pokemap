import 'dart:async';

import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/world/domain/world_port.dart';
import 'package:map_core/map_core_domain.dart';

/// Holds a rule publication open so a test can act while it is in flight.
class Ui12HeldWorldPort implements WorldPort {
  Ui12HeldWorldPort(this.delegate);
  final WorldPort delegate;
  final sentRules = <WorldRuleDefinition>[];
  Completer<void>? ruleGate;
  Object? ruleFailure;

  @override
  Future<ResourceMutationReceipt> publishRule({
    required WorldRuleDefinition? base,
    required WorldRuleDefinition current,
  }) async {
    sentRules.add(current);
    if (ruleGate case final gate?) await gate.future;
    if (ruleFailure case final failure?) throw failure;
    return delegate.publishRule(base: base, current: current);
  }

  @override
  Future<ResourceMutationReceipt> publishFact({
    required NarrativeFactDefinition? base,
    required NarrativeFactDefinition current,
  }) => delegate.publishFact(base: base, current: current);

  @override
  Future<ResourceMutationReceipt> deleteFact(NarrativeFactDefinition base) =>
      delegate.deleteFact(base);

  @override
  Future<ResourceMutationReceipt> deleteRule(WorldRuleDefinition base) =>
      delegate.deleteRule(base);

  @override
  Future<List<MapData>> loadMaps() => delegate.loadMaps();
}
