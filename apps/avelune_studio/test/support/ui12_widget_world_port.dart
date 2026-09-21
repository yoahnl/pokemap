import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/features/world/domain/world_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'm2_ui_fixture.dart';

/// Runs the real writes of [WorldPort] where a widget test can await them.
class Ui12WidgetWorldPort implements WorldPort {
  Ui12WidgetWorldPort(this.delegate, this.tester);
  final WorldPort delegate;
  final WidgetTester tester;
  int writes = 0;

  Future<T> _run<T>(Future<T> Function() action) async {
    final operation = tester.runAsync(() async {
      try {
        return (await action(), null);
      } catch (error) {
        return (null, error);
      }
    });
    WidgetResourcePort.pending = operation;
    try {
      final result = (await operation)!;
      if (result.$2 case final error?) throw error;
      return result.$1 as T;
    } finally {
      if (identical(WidgetResourcePort.pending, operation)) {
        WidgetResourcePort.pending = null;
      }
    }
  }

  @override
  Future<ResourceMutationReceipt> publishFact({
    required NarrativeFactDefinition? base,
    required NarrativeFactDefinition current,
  }) {
    writes++;
    return _run(() => delegate.publishFact(base: base, current: current));
  }

  @override
  Future<ResourceMutationReceipt> deleteFact(NarrativeFactDefinition base) {
    writes++;
    return _run(() => delegate.deleteFact(base));
  }

  @override
  Future<ResourceMutationReceipt> publishRule({
    required WorldRuleDefinition? base,
    required WorldRuleDefinition current,
  }) {
    writes++;
    return _run(() => delegate.publishRule(base: base, current: current));
  }

  @override
  Future<ResourceMutationReceipt> deleteRule(WorldRuleDefinition base) {
    writes++;
    return _run(() => delegate.deleteRule(base));
  }

  @override
  Future<List<MapData>> loadMaps() => _run(delegate.loadMaps);
}
