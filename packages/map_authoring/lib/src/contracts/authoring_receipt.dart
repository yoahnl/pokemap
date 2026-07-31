import 'authoring_diff.dart';
import 'json_contract_support.dart';
import 'resource_ref.dart';

enum AuthoringReceiptStatus {
  planned('planned'),
  applied('applied'),
  recovered('recovered');

  const AuthoringReceiptStatus(this.wireName);

  final String wireName;

  static AuthoringReceiptStatus fromWireName(String value) {
    return AuthoringReceiptStatus.values.firstWhere(
      (item) => item.wireName == value,
      orElse: () => throw FormatException('Unknown receipt status: $value'),
    );
  }
}

/// Compact link to a generated artifact.
///
/// Local filesystem paths are forbidden because clients may run on another
/// machine and because paths can disclose private workspace information.
final class AuthoringArtifactRef {
  AuthoringArtifactRef({
    required String id,
    required String mediaType,
    required String uri,
    int? byteLength,
    String? sha256,
    Map<String, Object?> extensions = const {},
  })  : id = _nonBlank(id, 'id'),
        mediaType = _nonBlank(mediaType, 'mediaType'),
        uri = _safeArtifactUri(uri),
        byteLength = _nonNegativeLength(byteLength),
        sha256 = sha256 == null ? null : _nonBlank(sha256, 'sha256'),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _artifactReservedKeys,
        );

  factory AuthoringArtifactRef.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _artifactReservedKeys);
    final rawLength = json['byteLength'];
    if (rawLength != null && rawLength is! int) {
      throw const FormatException('byteLength must be an integer');
    }
    try {
      return AuthoringArtifactRef(
        id: requireContractString(json['id'], 'id'),
        mediaType: requireContractString(json['mediaType'], 'mediaType'),
        uri: requireContractString(json['uri'], 'uri'),
        byteLength: rawLength as int?,
        sha256: readOptionalContractString(json['sha256'], 'sha256'),
        extensions: readContractExtensions(
          json['extensions'],
          reservedKeys: _artifactReservedKeys,
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  final String id;
  final String mediaType;
  final String uri;
  final int? byteLength;
  final String? sha256;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'mediaType': mediaType,
      'uri': uri,
      if (byteLength != null) 'byteLength': byteLength,
      if (sha256 != null) 'sha256': sha256,
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

/// Durable evidence returned by a planned or applied authoring action.
final class AuthoringReceipt {
  AuthoringReceipt({
    required String receiptId,
    required String requestId,
    required String actionId,
    required int actionVersion,
    required this.status,
    String? beforeRevision,
    String? afterRevision,
    required String createdAtUtc,
    required this.diff,
    Iterable<AuthoringArtifactRef> artifacts = const [],
    Map<String, Object?> extensions = const {},
  })  : receiptId = _nonBlank(receiptId, 'receiptId'),
        requestId = _nonBlank(requestId, 'requestId'),
        actionId = _nonBlank(actionId, 'actionId'),
        actionVersion = _positiveVersion(actionVersion),
        beforeRevision = beforeRevision == null
            ? null
            : _nonBlank(beforeRevision, 'beforeRevision'),
        afterRevision = afterRevision == null
            ? null
            : _nonBlank(afterRevision, 'afterRevision'),
        createdAtUtc = _utcTimestamp(createdAtUtc),
        artifacts = _sortedArtifacts(artifacts),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _receiptReservedKeys,
        );

  factory AuthoringReceipt.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _receiptReservedKeys);
    final rawDiff = json['diff'];
    final rawArtifacts = json['artifacts'];
    final rawAffected = json['affectedResources'];
    if (rawDiff is! Map) {
      throw const FormatException('diff must be a JSON object');
    }
    if (rawArtifacts is! List) {
      throw const FormatException('artifacts must be a JSON list');
    }
    if (rawAffected is! List) {
      throw const FormatException('affectedResources must be a JSON list');
    }
    final diff = AuthoringDiff.fromJson(Map<String, dynamic>.from(rawDiff));
    late final AuthoringReceipt receipt;
    try {
      receipt = AuthoringReceipt(
        receiptId: requireContractString(json['receiptId'], 'receiptId'),
        requestId: requireContractString(json['requestId'], 'requestId'),
        actionId: requireContractString(json['actionId'], 'actionId'),
        actionVersion: requirePositiveContractVersion(
          json['actionVersion'],
          'actionVersion',
        ),
        status: AuthoringReceiptStatus.fromWireName(
          requireContractString(json['status'], 'status'),
        ),
        beforeRevision: readOptionalContractString(
          json['beforeRevision'],
          'beforeRevision',
        ),
        afterRevision: readOptionalContractString(
          json['afterRevision'],
          'afterRevision',
        ),
        createdAtUtc:
            requireContractString(json['createdAtUtc'], 'createdAtUtc'),
        diff: diff,
        artifacts: rawArtifacts.map((rawArtifact) {
          if (rawArtifact is! Map) {
            throw const FormatException('artifact must be a JSON object');
          }
          return AuthoringArtifactRef.fromJson(
            Map<String, dynamic>.from(rawArtifact),
          );
        }),
        extensions: readContractExtensions(
          json['extensions'],
          reservedKeys: _receiptReservedKeys,
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }

    final declaredAffected = rawAffected.map((rawReference) {
      if (rawReference is! Map) {
        throw const FormatException(
          'affected resource must be a JSON object',
        );
      }
      return AuthoringResourceRef.fromJson(
        Map<String, dynamic>.from(rawReference),
      ).toJson();
    }).toList(growable: false);
    final derivedAffected = receipt.diff.affectedResources
        .map((reference) => reference.toJson())
        .toList(growable: false);
    if (!_jsonListsEqual(declaredAffected, derivedAffected)) {
      throw const FormatException(
        'affectedResources must match resources derived from diff',
      );
    }
    return receipt;
  }

  final String receiptId;
  final String requestId;
  final String actionId;
  final int actionVersion;
  final AuthoringReceiptStatus status;
  final String? beforeRevision;
  final String? afterRevision;
  final String createdAtUtc;
  final AuthoringDiff diff;
  final List<AuthoringArtifactRef> artifacts;
  final Map<String, Object?> extensions;

  List<AuthoringResourceRef> get affectedResources => diff.affectedResources;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'receiptId': receiptId,
      'requestId': requestId,
      'actionId': actionId,
      'actionVersion': actionVersion,
      'status': status.wireName,
      if (beforeRevision != null) 'beforeRevision': beforeRevision,
      if (afterRevision != null) 'afterRevision': afterRevision,
      'createdAtUtc': createdAtUtc,
      'diff': diff.toJson(),
      'affectedResources': affectedResources
          .map((reference) => reference.toJson())
          .toList(growable: false),
      'artifacts': artifacts
          .map((artifact) => artifact.toJson())
          .toList(growable: false),
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

const Set<String> _artifactReservedKeys = {
  'id',
  'mediaType',
  'uri',
  'byteLength',
  'sha256',
  'extensions',
};

const Set<String> _receiptReservedKeys = {
  'receiptId',
  'requestId',
  'actionId',
  'actionVersion',
  'status',
  'beforeRevision',
  'afterRevision',
  'createdAtUtc',
  'diff',
  'affectedResources',
  'artifacts',
  'extensions',
};

String _safeArtifactUri(String value) {
  final normalized = _nonBlank(value, 'uri');
  final parsed = Uri.tryParse(normalized);
  if (parsed == null ||
      !parsed.hasScheme ||
      !const {'artifact', 'https'}.contains(parsed.scheme)) {
    throw ArgumentError.value(
      value,
      'uri',
      'must use artifact:// or https://',
    );
  }
  return normalized;
}

int? _nonNegativeLength(int? value) {
  if (value != null && value < 0) {
    throw ArgumentError.value(value, 'byteLength', 'must not be negative');
  }
  return value;
}

String _utcTimestamp(String value) {
  final normalized = _nonBlank(value, 'createdAtUtc');
  final parsed = DateTime.tryParse(normalized);
  if (parsed == null || !parsed.isUtc || !normalized.endsWith('Z')) {
    throw ArgumentError.value(
      value,
      'createdAtUtc',
      'must be an ISO-8601 UTC timestamp ending in Z',
    );
  }
  return normalized;
}

List<AuthoringArtifactRef> _sortedArtifacts(
  Iterable<AuthoringArtifactRef> artifacts,
) {
  final byId = <String, AuthoringArtifactRef>{};
  for (final artifact in artifacts) {
    if (byId.containsKey(artifact.id)) {
      throw ArgumentError.value(
        artifact.id,
        'artifacts',
        'duplicate artifact id',
      );
    }
    byId[artifact.id] = artifact;
  }
  final sorted = byId.values.toList()
    ..sort((left, right) => left.id.compareTo(right.id));
  return List.unmodifiable(sorted);
}

bool _jsonListsEqual(
  List<Map<String, Object?>> left,
  List<Map<String, Object?>> right,
) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index].toString() != right[index].toString()) return false;
  }
  return true;
}

String _nonBlank(String value, String field) {
  try {
    return requireContractString(value, field);
  } on FormatException catch (error) {
    throw ArgumentError.value(value, field, error.message);
  }
}

int _positiveVersion(int value) {
  try {
    return requirePositiveContractVersion(value, 'actionVersion');
  } on FormatException catch (error) {
    throw ArgumentError.value(value, 'actionVersion', error.message);
  }
}
