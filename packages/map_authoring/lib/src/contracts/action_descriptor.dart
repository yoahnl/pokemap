import 'json_contract_support.dart';

enum AuthoringRiskLevel {
  readOnly('read_only'),
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  const AuthoringRiskLevel(this.wireName);

  final String wireName;

  static AuthoringRiskLevel fromWireName(String value) {
    return AuthoringRiskLevel.values.firstWhere(
      (item) => item.wireName == value,
      orElse: () => throw FormatException('Unknown riskLevel: $value'),
    );
  }
}

enum AuthoringPermission {
  projectRead('project.read'),
  projectWrite('project.write'),
  projectDestructive('project.destructive'),
  assetRead('asset.read'),
  assetWrite('asset.write'),
  renderRun('render.run'),
  playtestRun('playtest.run'),
  playtestControl('playtest.control'),
  importRun('import.run'),
  exportRun('export.run'),
  migrationRun('migration.run'),
  networkExternal('network.external'),
  processExecute('process.execute'),
  secretUse('secret.use'),
  recoveryApply('recovery.apply');

  const AuthoringPermission(this.wireName);

  final String wireName;

  static AuthoringPermission fromWireName(String value) {
    // Phase-1 descriptors used three provisional short names. Accept them on
    // input while every new serialization emits the canonical catalog scope.
    if (value == 'render') return AuthoringPermission.renderRun;
    if (value == 'playtest') return AuthoringPermission.playtestRun;
    if (value == 'recovery') return AuthoringPermission.recoveryApply;
    return AuthoringPermission.values.firstWhere(
      (item) => item.wireName == value,
      orElse: () => throw FormatException('Unknown permission: $value'),
    );
  }
}

enum AuthoringGuarantee {
  dryRun('dry_run'),
  idempotent('idempotent'),
  atomic('atomic'),
  revisionChecked('revision_checked'),
  undoable('undoable');

  const AuthoringGuarantee(this.wireName);

  final String wireName;

  static AuthoringGuarantee fromWireName(String value) {
    return AuthoringGuarantee.values.firstWhere(
      (item) => item.wireName == value,
      orElse: () => throw FormatException('Unknown guarantee: $value'),
    );
  }
}

/// Public, protocol-neutral description of one canonical authoring action.
final class AuthoringActionDescriptor {
  AuthoringActionDescriptor({
    required String id,
    required int version,
    required String summary,
    required String inputSchemaId,
    required String outputSchemaId,
    required this.riskLevel,
    Iterable<String> resourceKinds = const [],
    Iterable<String> capabilityIds = const [],
    Iterable<AuthoringPermission> requiredPermissions = const [],
    Iterable<AuthoringGuarantee> guarantees = const [],
    Map<String, Object?> extensions = const {},
  })  : id = _actionId(id),
        version = _positiveVersion(version),
        summary = _nonBlank(summary, 'summary'),
        inputSchemaId = _nonBlank(inputSchemaId, 'inputSchemaId'),
        outputSchemaId = _nonBlank(outputSchemaId, 'outputSchemaId'),
        resourceKinds = normalizedContractStrings(
          resourceKinds,
          'resourceKinds',
        ),
        capabilityIds = normalizedContractStrings(
          capabilityIds,
          'capabilityIds',
        ),
        requiredPermissions = normalizedContractEnums(
          requiredPermissions,
          (permission) => permission.wireName,
        ),
        guarantees = normalizedContractEnums(
          guarantees,
          (guarantee) => guarantee.wireName,
        ),
        extensions = validateContractExtensions(
          extensions,
          reservedKeys: _reservedKeys,
        );

  factory AuthoringActionDescriptor.fromJson(Map<String, dynamic> json) {
    rejectUnknownContractKeys(json, _reservedKeys);
    try {
      return AuthoringActionDescriptor(
        id: requireContractString(json['id'], 'id'),
        version: requirePositiveContractVersion(json['version'], 'version'),
        summary: requireContractString(json['summary'], 'summary'),
        inputSchemaId:
            requireContractString(json['inputSchemaId'], 'inputSchemaId'),
        outputSchemaId:
            requireContractString(json['outputSchemaId'], 'outputSchemaId'),
        riskLevel: AuthoringRiskLevel.fromWireName(
          requireContractString(json['riskLevel'], 'riskLevel'),
        ),
        resourceKinds:
            readContractStringList(json['resourceKinds'], 'resourceKinds'),
        capabilityIds:
            readContractStringList(json['capabilityIds'], 'capabilityIds'),
        requiredPermissions: _readPermissions(json['requiredPermissions']),
        guarantees: _readGuarantees(json['guarantees']),
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
    'id',
    'version',
    'summary',
    'inputSchemaId',
    'outputSchemaId',
    'riskLevel',
    'resourceKinds',
    'capabilityIds',
    'requiredPermissions',
    'guarantees',
    'extensions',
  };

  final String id;
  final int version;
  final String summary;
  final String inputSchemaId;
  final String outputSchemaId;
  final AuthoringRiskLevel riskLevel;
  final List<String> resourceKinds;
  final List<String> capabilityIds;
  final List<AuthoringPermission> requiredPermissions;
  final List<AuthoringGuarantee> guarantees;
  final Map<String, Object?> extensions;

  Map<String, Object?> toJson() {
    final json = <String, Object?>{
      'id': id,
      'version': version,
      'summary': summary,
      'inputSchemaId': inputSchemaId,
      'outputSchemaId': outputSchemaId,
      'riskLevel': riskLevel.wireName,
      'resourceKinds': resourceKinds,
      'capabilityIds': capabilityIds,
      'requiredPermissions': requiredPermissions
          .map((permission) => permission.wireName)
          .toList(growable: false),
      'guarantees': guarantees
          .map((guarantee) => guarantee.wireName)
          .toList(growable: false),
    };
    writeContractExtensions(json, extensions);
    return json;
  }
}

List<AuthoringPermission> _readPermissions(Object? value) {
  return normalizedContractEnums(
    readContractStringList(value, 'requiredPermissions')
        .map(AuthoringPermission.fromWireName),
    (permission) => permission.wireName,
  );
}

List<AuthoringGuarantee> _readGuarantees(Object? value) {
  return normalizedContractEnums(
    readContractStringList(value, 'guarantees')
        .map(AuthoringGuarantee.fromWireName),
    (guarantee) => guarantee.wireName,
  );
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
    return requirePositiveContractVersion(value, 'version');
  } on FormatException catch (error) {
    throw ArgumentError.value(value, 'version', error.message);
  }
}

String _actionId(String value) {
  final normalized = _nonBlank(value, 'id');
  if (!RegExp(
    r'^[a-z][a-zA-Z0-9_]*(?:\.[a-zA-Z0-9_]+)+$',
  ).hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      'id',
      'must be a stable dotted action identifier',
    );
  }
  return normalized;
}
