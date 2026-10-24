import 'narrative_fact.dart';
import 'narrative_value.dart';

final class ProjectContactDeviceConfig {
  static const capabilityId = 'project.contact-device@1';
  ProjectContactDeviceConfig({
    required String id,
    required String label,
    required String acquiredFactId,
    required String emptyMessage,
    required List<ProjectContactEntryConfig> contacts,
  }) : id = _required(id, 'id'),
       label = _required(label, 'label'),
       acquiredFactId = _required(acquiredFactId, 'acquiredFactId'),
       emptyMessage = _required(emptyMessage, 'emptyMessage'),
       contacts = List.unmodifiable(contacts) {
    if (contacts.map((c) => c.id).toSet().length != contacts.length ||
        contacts.map((c) => c.registeredFactId).toSet().length !=
            contacts.length) {
      throw const FormatException(
        'Contact identifiers and registration facts must be unique.',
      );
    }
    if (contacts.any((c) => c.registeredFactId == this.acquiredFactId)) {
      throw const FormatException(
        'Device acquisition and contact registration require separate facts.',
      );
    }
  }

  factory ProjectContactDeviceConfig.fromJson(Map<String, dynamic> json) {
    _fields(json, {
      'id',
      'label',
      'acquiredFactId',
      'emptyMessage',
      'contacts',
    });
    final raw = json['contacts'];
    if (raw is! List || raw.any((c) => c is! Map<String, dynamic>)) {
      throw const FormatException(
        'Contact device contacts must be an array of objects.',
      );
    }
    return ProjectContactDeviceConfig(
      id: _string(json, 'id'),
      label: _string(json, 'label'),
      acquiredFactId: _string(json, 'acquiredFactId'),
      emptyMessage: _string(json, 'emptyMessage'),
      contacts: [
        for (final c in raw)
          ProjectContactEntryConfig.fromJson(c as Map<String, dynamic>),
      ],
    );
  }

  final String id;
  final String label;
  final String acquiredFactId;
  final String emptyMessage;
  final List<ProjectContactEntryConfig> contacts;

  List<String> referenceErrors({
    required List<NarrativeFactDefinition> facts,
    required Set<String> sceneIds,
    required Set<String> characterIds,
  }) {
    final errors = <String>[];
    final definitions = {for (final f in facts) f.id: f};
    for (final factId in {
      acquiredFactId,
      ...contacts.map((c) => c.registeredFactId),
      ...contacts.map((c) => c.availableFactId).whereType<String>(),
    }) {
      if (definitions[factId]?.valueKind != NarrativeValueKind.boolean) {
        errors.add('Contact device requires a declared boolean fact: $factId');
      }
    }
    for (final contact in contacts) {
      for (final sceneId in {contact.sceneId, contact.unavailableSceneId}) {
        if (!sceneIds.contains(sceneId)) {
          errors.add(
            'Contact ${contact.id} references a missing scene: $sceneId',
          );
        }
      }
      final characterId = contact.characterId;
      if (characterId != null && !characterIds.contains(characterId)) {
        errors.add(
          'Contact ${contact.id} references a missing character: $characterId',
        );
      }
    }
    return List.unmodifiable(errors);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'acquiredFactId': acquiredFactId,
    'emptyMessage': emptyMessage,
    'contacts': contacts.map((c) => c.toJson()).toList(growable: false),
  };

  @override
  bool operator ==(Object other) =>
      other is ProjectContactDeviceConfig &&
      other.id == id &&
      other.label == label &&
      other.acquiredFactId == acquiredFactId &&
      other.emptyMessage == emptyMessage &&
      _equal(contacts, other.contacts);

  @override
  int get hashCode => Object.hash(
    id,
    label,
    acquiredFactId,
    emptyMessage,
    Object.hashAll(contacts),
  );
}

final class ProjectContactEntryConfig {
  ProjectContactEntryConfig({
    required String id,
    required String label,
    required String registeredFactId,
    required String sceneId,
    required String unavailableSceneId,
    String? availableFactId,
    String? characterId,
  }) : id = _required(id, 'contact.id'),
       label = _required(label, 'contact.label'),
       registeredFactId = _required(
         registeredFactId,
         'contact.registeredFactId',
       ),
       sceneId = _required(sceneId, 'contact.sceneId'),
       unavailableSceneId = _required(
         unavailableSceneId,
         'contact.unavailableSceneId',
       ),
       availableFactId = availableFactId == null
           ? null
           : _required(availableFactId, 'contact.availableFactId'),
       characterId = characterId == null
           ? null
           : _required(characterId, 'contact.characterId');

  factory ProjectContactEntryConfig.fromJson(Map<String, dynamic> json) {
    _fields(
      json,
      {
        'id',
        'label',
        'registeredFactId',
        'sceneId',
        'unavailableSceneId',
        'availableFactId',
        'characterId',
      },
      optional: {'availableFactId', 'characterId'},
    );
    return ProjectContactEntryConfig(
      id: _string(json, 'id'),
      label: _string(json, 'label'),
      registeredFactId: _string(json, 'registeredFactId'),
      sceneId: _string(json, 'sceneId'),
      unavailableSceneId: _string(json, 'unavailableSceneId'),
      availableFactId: json.containsKey('availableFactId')
          ? _string(json, 'availableFactId')
          : null,
      characterId: json.containsKey('characterId')
          ? _string(json, 'characterId')
          : null,
    );
  }

  final String id;
  final String label;
  final String registeredFactId;
  final String sceneId;
  final String unavailableSceneId;
  final String? availableFactId;
  final String? characterId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'registeredFactId': registeredFactId,
    'sceneId': sceneId,
    'unavailableSceneId': unavailableSceneId,
    if (availableFactId != null) 'availableFactId': availableFactId,
    if (characterId != null) 'characterId': characterId,
  };

  @override
  bool operator ==(Object other) =>
      other is ProjectContactEntryConfig &&
      other.id == id &&
      other.label == label &&
      other.registeredFactId == registeredFactId &&
      other.sceneId == sceneId &&
      other.unavailableSceneId == unavailableSceneId &&
      other.availableFactId == availableFactId &&
      other.characterId == characterId;

  @override
  int get hashCode => Object.hash(
    id,
    label,
    registeredFactId,
    sceneId,
    unavailableSceneId,
    availableFactId,
    characterId,
  );
}

String _required(String value, String name) {
  if (value.trim().isEmpty || value.trim() != value) {
    throw FormatException(
      'Contact device $name must be a nonempty trimmed string.',
    );
  }
  return value;
}

String _string(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is! String) {
    throw FormatException('Contact device $field must be a string.');
  }
  return value;
}

void _fields(
  Map<String, dynamic> json,
  Set<String> fields, {
  Set<String> optional = const {},
}) {
  if (json.keys.any((key) => !fields.contains(key)) ||
      fields.difference(optional).any((key) => !json.containsKey(key))) {
    throw const FormatException(
      'Contact device fields do not match the schema.',
    );
  }
}

bool _equal(List<Object> a, List<Object> b) =>
    a.length == b.length &&
    Iterable<int>.generate(a.length).every((i) => a[i] == b[i]);
