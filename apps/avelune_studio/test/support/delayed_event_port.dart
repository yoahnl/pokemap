import 'dart:async';
import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:map_core/map_core_domain.dart';

class DelayedEventPort implements EventPort {
  DelayedEventPort(this.delegate, {this.failOn});
  final EventPort delegate;
  final String? failOn;
  final entered = Completer<void>();
  final release = Completer<void>();
  @override
  Future<ResourceMutationReceipt> publishEvent({
    required String id,
    required NarrativeEventRecord? base,
    required NarrativeEventRecord? current,
  }) async {
    if (!entered.isCompleted) entered.complete();
    await release.future;
    if (id == failOn) throw const EventFailure('Échec simulé du stockage');
    return delegate.publishEvent(id: id, base: base, current: current);
  }
}
