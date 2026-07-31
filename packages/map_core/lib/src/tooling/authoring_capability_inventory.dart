/// Evidence status for one row of the PokeMap authoring capability baseline.
///
/// This status describes the canonical Authoring API coverage, not whether a
/// feature happens to exist in an editor widget or runtime component.
enum AuthoringCapabilityStatus {
  supported('SUPPORTED'),
  notApplicable('NOT_APPLICABLE'),
  blocked('BLOCKED'),
  missing('MISSING');

  const AuthoringCapabilityStatus(this.wireName);

  final String wireName;

  static AuthoringCapabilityStatus fromWireName(String value) {
    return AuthoringCapabilityStatus.values.firstWhere(
      (status) => status.wireName == value,
      orElse: () => throw FormatException(
        'Unknown authoring capability status: $value',
      ),
    );
  }
}

/// Origin of an inventory row.
enum AuthoringCapabilityKind {
  catalogAction('catalog_action'),
  projectManifestField('project_manifest_field'),
  mapDataField('map_data_field'),
  editorUseCase('editor_use_case'),
  coreOperation('core_operation'),
  evaluationCommand('evaluation_command');

  const AuthoringCapabilityKind(this.wireName);

  final String wireName;

  static AuthoringCapabilityKind fromWireName(String value) {
    return AuthoringCapabilityKind.values.firstWhere(
      (kind) => kind.wireName == value,
      orElse: () => throw FormatException(
        'Unknown authoring capability kind: $value',
      ),
    );
  }
}

/// One traceable fact in the repository-wide authoring baseline.
///
/// Every row names an owner, source, and runtime consumer even when the
/// canonical capability is missing. This prevents a UI-only implementation
/// from being mistaken for an end-to-end supported capability.
final class AuthoringCapabilityInventoryEntry {
  AuthoringCapabilityInventoryEntry({
    required String id,
    required this.kind,
    required String ownerPackage,
    required this.status,
    required String sourceReference,
    required String runtimeConsumer,
    Iterable<String> evidenceReferences = const [],
    Iterable<String> relatedFgLots = const [],
    required this.hasCanonicalMutation,
  })  : id = _requireNonBlank(id, 'id'),
        ownerPackage = _requireNonBlank(ownerPackage, 'ownerPackage'),
        sourceReference = _requireNonBlank(sourceReference, 'sourceReference'),
        runtimeConsumer = _requireNonBlank(runtimeConsumer, 'runtimeConsumer'),
        evidenceReferences = _normalizedStrings(
          evidenceReferences,
          'evidenceReference',
        ),
        relatedFgLots = _normalizedStrings(
          relatedFgLots,
          'relatedFgLot',
        ) {
    if (status == AuthoringCapabilityStatus.supported &&
        this.evidenceReferences.isEmpty) {
      throw ArgumentError.value(
        this.evidenceReferences,
        'evidenceReferences',
        'A SUPPORTED capability requires evidence',
      );
    }
  }

  factory AuthoringCapabilityInventoryEntry.fromJson(
    Map<String, dynamic> json,
  ) {
    return AuthoringCapabilityInventoryEntry(
      id: _readString(json, 'id'),
      kind: AuthoringCapabilityKind.fromWireName(_readString(json, 'kind')),
      ownerPackage: _readString(json, 'ownerPackage'),
      status:
          AuthoringCapabilityStatus.fromWireName(_readString(json, 'status')),
      sourceReference: _readString(json, 'sourceReference'),
      runtimeConsumer: _readString(json, 'runtimeConsumer'),
      evidenceReferences: _readStringList(json, 'evidenceReferences'),
      relatedFgLots: _readStringList(json, 'relatedFgLots'),
      hasCanonicalMutation: _readBool(json, 'hasCanonicalMutation'),
    );
  }

  final String id;
  final AuthoringCapabilityKind kind;
  final String ownerPackage;
  final AuthoringCapabilityStatus status;
  final String sourceReference;
  final String runtimeConsumer;
  final List<String> evidenceReferences;
  final List<String> relatedFgLots;
  final bool hasCanonicalMutation;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'kind': kind.wireName,
      'ownerPackage': ownerPackage,
      'status': status.wireName,
      'sourceReference': sourceReference,
      'runtimeConsumer': runtimeConsumer,
      'evidenceReferences': evidenceReferences,
      'relatedFgLots': relatedFgLots,
      'hasCanonicalMutation': hasCanonicalMutation,
    };
  }
}

/// Sorted, duplicate-free collection used to generate the PMCP-000 baseline.
final class AuthoringCapabilityInventory {
  AuthoringCapabilityInventory(Iterable<AuthoringCapabilityInventoryEntry> rows)
      : entries = _validatedAndSorted(rows);

  factory AuthoringCapabilityInventory.fromJson(Map<String, dynamic> json) {
    if (json['formatVersion'] != 1) {
      throw FormatException(
        'Unsupported authoring inventory formatVersion: '
        '${json['formatVersion']}',
      );
    }
    final rawEntries = json['entries'];
    if (rawEntries is! List) {
      throw const FormatException('entries must be a JSON list');
    }
    return AuthoringCapabilityInventory(
      rawEntries.map((entry) {
        if (entry is! Map) {
          throw const FormatException('inventory entry must be a JSON object');
        }
        return AuthoringCapabilityInventoryEntry.fromJson(
          Map<String, dynamic>.from(entry),
        );
      }),
    );
  }

  final List<AuthoringCapabilityInventoryEntry> entries;

  Map<String, Object?> toJson() {
    return {
      'formatVersion': 1,
      'entries': entries.map((entry) => entry.toJson()).toList(growable: false),
    };
  }

  /// Renders byte-stable Markdown suitable for a tracked evidence report.
  String toMarkdown({
    String title = 'PokeMap authoring capability baseline',
  }) {
    final buffer = StringBuffer()
      ..writeln('# $title')
      ..writeln()
      ..writeln(
        '| Capability | Kind | Owner | Status | Source | Runtime consumer | '
        'Evidence | FG lots | Canonical mutation |',
      )
      ..writeln(
        '|---|---|---|---|---|---|---|---|---|',
      );

    for (final entry in entries) {
      buffer
        ..write('| `${_escapeCell(entry.id)}` ')
        ..write('| `${entry.kind.wireName}` ')
        ..write('| `${_escapeCell(entry.ownerPackage)}` ')
        ..write('| `${entry.status.wireName}` ')
        ..write('| `${_escapeCell(entry.sourceReference)}` ')
        ..write('| `${_escapeCell(entry.runtimeConsumer)}` ')
        ..write('| ${_formatCodeList(entry.evidenceReferences)} ')
        ..write('| ${_formatCodeList(entry.relatedFgLots)} ')
        ..writeln('| `${entry.hasCanonicalMutation}` |');
    }

    return buffer.toString();
  }

  static List<AuthoringCapabilityInventoryEntry> _validatedAndSorted(
    Iterable<AuthoringCapabilityInventoryEntry> rows,
  ) {
    final byId = <String, AuthoringCapabilityInventoryEntry>{};
    for (final row in rows) {
      if (byId.containsKey(row.id)) {
        throw ArgumentError.value(
          row.id,
          'entries',
          'Duplicate authoring capability id',
        );
      }
      byId[row.id] = row;
    }
    final sorted = byId.values.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    return List.unmodifiable(sorted);
  }
}

String _formatCodeList(List<String> values) {
  if (values.isEmpty) return '—';
  return values.map((value) => '`${_escapeCell(value)}`').join('<br>');
}

String _escapeCell(String value) {
  return value.replaceAll('|', r'\|').replaceAll('\n', '<br>');
}

String _requireNonBlank(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, name, 'must not be blank');
  }
  return normalized;
}

String _readString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('$key must be a string');
  }
  return value;
}

bool _readBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw FormatException('$key must be a boolean');
  }
  return value;
}

List<String> _readStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$key must be a list of strings');
  }
  return value.cast<String>();
}

List<String> _normalizedStrings(Iterable<String> values, String field) {
  final normalized = values
      .map((value) => _requireNonBlank(value, field))
      .toSet()
      .toList()
    ..sort();
  return List.unmodifiable(normalized);
}
