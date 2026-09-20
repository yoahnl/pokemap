import 'package:map_core/map_core_domain.dart';
import '../../resources/domain/resource_port.dart';

abstract interface class EventPort {
  Future<ResourceMutationReceipt> publishEvent({
    required String id,
    required NarrativeEventRecord? base,
    required NarrativeEventRecord? current,
  });
}

class EventFailure implements Exception {
  const EventFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

abstract interface class EventRegistryModePort {
  Future<ResourceMutationReceipt> changeMode({
    required NarrativeEventRegistry? base,
    required EventSystemMode mode,
  });
}
