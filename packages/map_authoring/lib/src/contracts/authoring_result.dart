import 'authoring_error.dart';
import 'authoring_receipt.dart';
import 'json_contract_support.dart';

enum AuthoringResultStatus {
  success('success'),
  failure('failure');

  const AuthoringResultStatus(this.wireName);

  final String wireName;

  static AuthoringResultStatus fromWireName(String value) {
    return AuthoringResultStatus.values.firstWhere(
      (item) => item.wireName == value,
      orElse: () => throw FormatException('Unknown result status: $value'),
    );
  }
}

/// Compact, unambiguous result envelope shared by every authoring transport.
final class AuthoringResult {
  AuthoringResult({
    required String requestId,
    required this.status,
    Map<String, Object?> data = const {},
    this.error,
    this.receipt,
    Iterable<AuthoringArtifactRef> artifacts = const [],
    Map<String, Object?> extensions = const {},
  })  : requestId = _nonBlank(requestId, 'requestId'),
        data = freezeContractJsonObject(data, field: 'data'),
        artifacts = _sortedArtifacts(artifacts),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _reservedKeys,
        ) {
    if (status == AuthoringResultStatus.success && error != null) {
      throw ArgumentError.value(
        error,
        'error',
        'A successful result cannot contain an error',
      );
    }
    if (status == AuthoringResultStatus.failure && error == null) {
      throw ArgumentError.value(
        error,
        'error',
        'A failed result requires an error',
      );
    }
    if (status == AuthoringResultStatus.failure && receipt != null) {
      throw ArgumentError.value(
        receipt,
        'receipt',
        'A failed result cannot claim a receipt',
      );
    }
  }

  factory AuthoringResult.success({
    required String requestId,
    Map<String, Object?> data = const {},
    AuthoringReceipt? receipt,
    Iterable<AuthoringArtifactRef> artifacts = const [],
    Map<String, Object?> extensions = const {},
  }) {
    return AuthoringResult(
      requestId: requestId,
      status: AuthoringResultStatus.success,
      data: data,
      receipt: receipt,
      artifacts: artifacts,
      extensions: extensions,
    );
  }

  factory AuthoringResult.failure({
    required String requestId,
    required AuthoringError error,
    Map<String, Object?> data = const {},
    Iterable<AuthoringArtifactRef> artifacts = const [],
    Map<String, Object?> extensions = const {},
  }) {
    return AuthoringResult(
      requestId: requestId,
      status: AuthoringResultStatus.failure,
      data: data,
      error: error,
      artifacts: artifacts,
      extensions: extensions,
    );
  }

  factory AuthoringResult.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    final rawData = json['data'];
    final rawArtifacts = json['artifacts'];
    if (rawData is! Map) {
      throw const FormatException('data must be a JSON object');
    }
    if (rawArtifacts is! List) {
      throw const FormatException('artifacts must be a JSON list');
    }
    final rawError = json['error'];
    final rawReceipt = json['receipt'];
    if (rawError != null && rawError is! Map) {
      throw const FormatException('error must be a JSON object');
    }
    if (rawReceipt != null && rawReceipt is! Map) {
      throw const FormatException('receipt must be a JSON object');
    }
    try {
      return AuthoringResult(
        requestId: requireContractString(json['requestId'], 'requestId'),
        status: AuthoringResultStatus.fromWireName(
          requireContractString(json['status'], 'status'),
        ),
        data: Map<String, Object?>.from(rawData),
        error: rawError == null
            ? null
            : AuthoringError.fromJson(Map<String, dynamic>.from(rawError)),
        receipt: rawReceipt == null
            ? null
            : AuthoringReceipt.fromJson(
                Map<String, dynamic>.from(rawReceipt),
              ),
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
          reservedKeys: _reservedKeys,
        ),
      );
    } on ArgumentError catch (error) {
      throw FormatException(error.message.toString());
    }
  }

  static const Set<String> _reservedKeys = {
    'requestId',
    'status',
    'data',
    'error',
    'receipt',
    'artifacts',
    'extensions',
  };

  final String requestId;
  final AuthoringResultStatus status;
  final Map<String, Object?> data;
  final AuthoringError? error;
  final AuthoringReceipt? receipt;
  final List<AuthoringArtifactRef> artifacts;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'requestId': requestId,
      'status': status.wireName,
      'data': data,
      if (error != null) 'error': error!.toJson(),
      if (receipt != null) 'receipt': receipt!.toJson(),
      'artifacts': artifacts
          .map((artifact) => artifact.toJson())
          .toList(growable: false),
    };
    writeContractExtensions(json, extensions);
    return json;
  }
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

String _nonBlank(String value, String field) {
  try {
    return requireContractString(value, field);
  } on FormatException catch (error) {
    throw ArgumentError.value(value, field, error.message);
  }
}
