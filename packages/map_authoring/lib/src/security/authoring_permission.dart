enum AuthoringPermissionScope {
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

  const AuthoringPermissionScope(this.wireName);

  final String wireName;

  static AuthoringPermissionScope fromWireName(String value) {
    return AuthoringPermissionScope.values.firstWhere(
      (scope) => scope.wireName == value,
      orElse: () => throw FormatException('Unknown permission scope.'),
    );
  }
}

enum AuthoringSecurityOperation {
  plan('plan'),
  apply('apply'),
  recover('recover'),
  assetWrite('asset.write'),
  networkAccess('network.access');

  const AuthoringSecurityOperation(this.wireName);

  final String wireName;

  static AuthoringSecurityOperation fromWireName(String value) {
    return AuthoringSecurityOperation.values.firstWhere(
      (operation) => operation.wireName == value,
      orElse: () => throw FormatException('Unknown security operation.'),
    );
  }

  AuthoringPermissionScope get primaryPermission => switch (this) {
        AuthoringSecurityOperation.plan => AuthoringPermissionScope.projectRead,
        AuthoringSecurityOperation.apply =>
          AuthoringPermissionScope.projectWrite,
        AuthoringSecurityOperation.recover =>
          AuthoringPermissionScope.recoveryApply,
        AuthoringSecurityOperation.assetWrite =>
          AuthoringPermissionScope.assetWrite,
        AuthoringSecurityOperation.networkAccess =>
          AuthoringPermissionScope.networkExternal,
      };
}

/// Immutable server-side identity and its granted least-privilege scopes.
final class AuthoringActor {
  AuthoringActor({
    required String actorId,
    Iterable<AuthoringPermissionScope> permissions = const [
      AuthoringPermissionScope.projectRead,
    ],
  })  : actorId = _safeSecurityIdentifier(actorId, 'actorId'),
        permissions = _sortedPermissions(permissions);

  final String actorId;
  final List<AuthoringPermissionScope> permissions;

  bool allows(AuthoringPermissionScope permission) =>
      permissions.contains(permission);
}

List<AuthoringPermissionScope> _sortedPermissions(
  Iterable<AuthoringPermissionScope> permissions,
) {
  final unique = permissions.toSet().toList()
    ..sort((left, right) => left.wireName.compareTo(right.wireName));
  return List.unmodifiable(unique);
}

String safeAuthoringSecurityIdentifier(String value, String field) =>
    _safeSecurityIdentifier(value, field);

String _safeSecurityIdentifier(String value, String field) {
  if (value.length > 160 ||
      value.trim() != value ||
      !_securityIdentifierPattern.hasMatch(value)) {
    throw ArgumentError.value(value, field, 'must be a safe opaque identity');
  }
  return value;
}

final RegExp _securityIdentifierPattern =
    RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.:@-]*$');
