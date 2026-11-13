import 'package:map_core/map_core_domain.dart';

import '../../resources/domain/resource_port.dart';

abstract interface class EventPort {
  Future<ResourceMutationReceipt> publishEvent({
    required String id,
    required NarrativeEventRecord? base,
    required NarrativeEventRecord? current,
  });
}

typedef EventRecordChange = ({
  String id,
  NarrativeEventRecord? base,
  NarrativeEventRecord? current,
});

abstract interface class EventBatchPort {
  static const maxRecords = 128;

  Future<ResourceMutationReceipt> publishEvents(
    List<EventRecordChange> changes,
  );
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

abstract interface class EventPresentationCatalogPort {
  Future<ProjectMediaCatalog> loadPresentationMediaCatalog(
    ProjectManifest project,
  );
}
