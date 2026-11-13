import 'dart:convert';

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

typedef EventDeletionUser = ({String kind, String label});

class EventDeletionRefused extends EventFailure {
  EventDeletionRefused.inUse(List<EventDeletionUser> users)
    : this._(List.unmodifiable(users), false);

  EventDeletionRefused.coverageUnknown() : this._(const [], true);

  EventDeletionRefused._(this.users, this.coverageUnknown)
    : super(
        '$prefix${jsonEncode({
          'coverageUnknown': coverageUnknown,
          'users': [
            for (final user in users) {'kind': user.kind, 'label': user.label},
          ],
        })}',
      );

  static const prefix = 'storyDelete:';

  final List<EventDeletionUser> users;
  final bool coverageUnknown;

  static EventDeletionRefused? parse(String message) {
    if (!message.startsWith(prefix)) return null;
    try {
      final value = jsonDecode(message.substring(prefix.length));
      if (value is! Map || value['users'] is! List) return null;
      if (value['coverageUnknown'] == true) {
        return EventDeletionRefused.coverageUnknown();
      }
      return EventDeletionRefused.inUse([
        for (final user in value['users'] as List)
          if (user is Map && user['kind'] is String && user['label'] is String)
            (kind: user['kind'] as String, label: user['label'] as String),
      ]);
    } on FormatException {
      return null;
    }
  }

  @override
  String toString() => coverageUnknown
      ? 'Suppression refusée : les usages des comportements de ce projet ne sont pas encore recensés. Rien n’a été modifié.'
      : 'Suppression refusée : ce comportement est encore utilisé par ${users.map((user) => '« ${user.label} »').join(', ')}.';
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
