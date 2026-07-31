import 'json_contract_support.dart';

/// Protocol-neutral request envelope shared by direct API, CLI, editor, and
/// future MCP adapters.
final class AuthoringRequest {
  AuthoringRequest({
    required String requestId,
    required String actionId,
    required int actionVersion,
    required String workspaceHandle,
    Map<String, Object?> parameters = const {},
    String? expectedRevision,
    String? idempotencyKey,
    this.dryRun = false,
    Map<String, Object?> extensions = const {},
  })  : requestId = _nonBlank(requestId, 'requestId'),
        actionId = _nonBlank(actionId, 'actionId'),
        actionVersion = _positiveVersion(actionVersion),
        workspaceHandle = _nonBlank(workspaceHandle, 'workspaceHandle'),
        parameters = freezeContractJsonObject(
          parameters,
          field: 'parameters',
        ),
        expectedRevision = expectedRevision == null
            ? null
            : _nonBlank(expectedRevision, 'expectedRevision'),
        idempotencyKey = idempotencyKey == null
            ? null
            : _nonBlank(idempotencyKey, 'idempotencyKey'),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _reservedKeys,
        );

  factory AuthoringRequest.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    final rawParameters = json['parameters'];
    if (rawParameters is! Map) {
      throw const FormatException('parameters must be a JSON object');
    }
    try {
      return AuthoringRequest(
        requestId: requireContractString(json['requestId'], 'requestId'),
        actionId: requireContractString(json['actionId'], 'actionId'),
        actionVersion: requirePositiveContractVersion(
            json['actionVersion'], 'actionVersion'),
        workspaceHandle:
            requireContractString(json['workspaceHandle'], 'workspaceHandle'),
        parameters: Map<String, Object?>.from(rawParameters),
        expectedRevision: readOptionalContractString(
          json['expectedRevision'],
          'expectedRevision',
        ),
        idempotencyKey: readOptionalContractString(
          json['idempotencyKey'],
          'idempotencyKey',
        ),
        dryRun: requireContractBool(json['dryRun'], 'dryRun'),
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
    'actionId',
    'actionVersion',
    'workspaceHandle',
    'parameters',
    'expectedRevision',
    'idempotencyKey',
    'dryRun',
    'extensions',
  };

  final String requestId;
  final String actionId;
  final int actionVersion;
  final String workspaceHandle;
  final Map<String, Object?> parameters;
  final String? expectedRevision;
  final String? idempotencyKey;
  final bool dryRun;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'requestId': requestId,
      'actionId': actionId,
      'actionVersion': actionVersion,
      'workspaceHandle': workspaceHandle,
      'parameters': parameters,
      if (expectedRevision != null) 'expectedRevision': expectedRevision,
      if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
      'dryRun': dryRun,
    };
    writeContractExtensions(json, extensions);
    return json;
  }
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
