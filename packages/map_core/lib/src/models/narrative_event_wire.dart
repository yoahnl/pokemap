/// Base failure for the closed-world Narrative Event wire format.
///
/// This support type stays outside the public barrel while giving later Event
/// V2 contracts one shared invalid-versus-unsupported classification.
sealed class NarrativeEventWireException extends FormatException {
  NarrativeEventWireException(
    String message, {
    required this.path,
    Object? source,
  }) : super('$path: $message', source);

  final String path;
}

/// The payload may belong to a newer writer and must not be rewritten as V0.
final class NarrativeEventUnsupportedWireException
    extends NarrativeEventWireException {
  NarrativeEventUnsupportedWireException(
    super.message, {
    required super.path,
    super.source,
  });
}

/// The payload uses known V0 structure but is malformed or violates invariants.
final class NarrativeEventInvalidWireException
    extends NarrativeEventWireException {
  NarrativeEventInvalidWireException(
    super.message, {
    required super.path,
    super.source,
  });
}

/// Shared strict JSON primitives for the manual Event V2 codecs.
abstract final class NarrativeEventWire {
  static Map<String, Object?> object(
    Object? raw, {
    required String path,
  }) {
    if (raw is! Map) {
      return invalid(
        'Expected an object.',
        path: path,
        source: raw,
      );
    }

    final result = <String, Object?>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      if (key is! String) {
        return invalid(
          'Object keys must be strings.',
          path: path,
          source: raw,
        );
      }
      result[key] = entry.value;
    }
    return result;
  }

  static void expectExactFields(
    Map<String, Object?> object,
    Set<String> expectedFields, {
    required String path,
    Set<String>? knownFields,
  }) {
    final acceptedKnownFields = knownFields ?? expectedFields;
    final extraFields =
        object.keys.where((field) => !expectedFields.contains(field)).toList();
    final unknownFields = extraFields
        .where((field) => !acceptedKnownFields.contains(field))
        .toList()
      ..sort();
    if (unknownFields.isNotEmpty) {
      unsupported(
        'Unknown field(s): ${unknownFields.join(', ')}.',
        path: path,
        source: object,
      );
    }

    final incompatibleFields =
        extraFields.where(acceptedKnownFields.contains).toList()..sort();
    if (incompatibleFields.isNotEmpty) {
      invalid(
        'Field(s) incompatible with this variant: '
        '${incompatibleFields.join(', ')}.',
        path: path,
        source: object,
      );
    }
  }

  static String requiredString(
    Map<String, Object?> object,
    String field, {
    required String path,
  }) {
    if (!object.containsKey(field) || object[field] == null) {
      return invalid(
        'Required field "$field" is missing or null.',
        path: '$path.$field',
        source: object,
      );
    }

    final value = object[field];
    if (value is! String) {
      return invalid(
        'Field "$field" must be a string.',
        path: '$path.$field',
        source: value,
      );
    }
    return value;
  }

  static String requiredIdentity(
    Map<String, Object?> object,
    String field, {
    required String path,
  }) {
    final value = requiredString(object, field, path: path);
    if (value.isEmpty || value.trim() != value) {
      return invalid(
        'Identity "$field" must be non-empty and already trimmed.',
        path: '$path.$field',
        source: value,
      );
    }
    return value;
  }

  static Map<String, Object?> requiredObject(
    Map<String, Object?> object,
    String field, {
    required String path,
  }) {
    if (!object.containsKey(field) || object[field] == null) {
      return invalid(
        'Required field "$field" is missing or null.',
        path: '$path.$field',
        source: object,
      );
    }
    return NarrativeEventWire.object(
      object[field],
      path: '$path.$field',
    );
  }

  static bool requiredBool(
    Map<String, Object?> object,
    String field, {
    required String path,
  }) {
    if (!object.containsKey(field) || object[field] == null) {
      return invalid(
        'Required field "$field" is missing or null.',
        path: '$path.$field',
        source: object,
      );
    }
    final value = object[field];
    if (value is! bool) {
      return invalid(
        'Field "$field" must be a boolean.',
        path: '$path.$field',
        source: value,
      );
    }
    return value;
  }

  static int requiredInt(
    Map<String, Object?> object,
    String field, {
    required String path,
  }) {
    if (!object.containsKey(field) || object[field] == null) {
      return invalid(
        'Required field "$field" is missing or null.',
        path: '$path.$field',
        source: object,
      );
    }
    final value = object[field];
    if (value is! int) {
      return invalid(
        'Field "$field" must be an integer.',
        path: '$path.$field',
        source: value,
      );
    }
    return value;
  }

  static List<Object?> requiredList(
    Map<String, Object?> object,
    String field, {
    required String path,
  }) {
    if (!object.containsKey(field) || object[field] == null) {
      return invalid(
        'Required field "$field" is missing or null.',
        path: '$path.$field',
        source: object,
      );
    }
    final value = object[field];
    if (value is! List) {
      return invalid(
        'Field "$field" must be a list.',
        path: '$path.$field',
        source: value,
      );
    }
    return List<Object?>.from(value);
  }

  static Map<String, Object?>? optionalObject(
    Map<String, Object?> object,
    String field, {
    required String path,
  }) {
    if (!object.containsKey(field) || object[field] == null) {
      return null;
    }
    return NarrativeEventWire.object(object[field], path: '$path.$field');
  }

  static String? optionalIdentity(
    Map<String, Object?> object,
    String field, {
    required String path,
  }) {
    if (!object.containsKey(field) || object[field] == null) {
      return null;
    }
    return requiredIdentity(object, field, path: path);
  }

  static Never unsupported(
    String message, {
    required String path,
    Object? source,
  }) {
    throw NarrativeEventUnsupportedWireException(
      message,
      path: path,
      source: source,
    );
  }

  static Never invalid(
    String message, {
    required String path,
    Object? source,
  }) {
    throw NarrativeEventInvalidWireException(
      message,
      path: path,
      source: source,
    );
  }
}
