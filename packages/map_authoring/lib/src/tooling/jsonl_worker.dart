import 'dart:async';
import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../api/authoring_mutation_api.dart';
import '../api/authoring_read_api.dart';
import '../contracts/authoring_error.dart';
import '../contracts/authoring_request.dart';
import '../contracts/authoring_result.dart';
import '../contracts/json_contract_support.dart';
import '../contracts/query_request.dart';
import '../domains/assets/asset_actions.dart';
import '../domains/assets/character_studio_asset_actions.dart';
import '../domains/assets/tileset_actions.dart';
import '../domains/gameplay/character_studio/character_studio_action_support.dart';
import '../domains/gameplay/item_catalog_actions.dart';
import '../domains/gameplay/pokemon_ruleset_actions.dart';
import '../domains/maps/map_lifecycle_adapter.dart';
import '../domains/maps/map_region_query.dart';
import '../history/authoring_history.dart';
import '../ports/project_file_reader.dart';
import '../ports/artifact_store.dart';
import '../security/authorization_policy.dart';
import '../security/confirmation_token.dart';
import '../security/output_redaction.dart';
import '../transactions/idempotency_ledger.dart';
import '../transactions/journaled_transaction.dart';
import '../transactions/plan_store.dart';
import '../transactions/recovery_service.dart';
import '../transactions/revision_set.dart';
import '../workspace/project_open_service.dart';
import '../workspace/project_query_service.dart';
import '../workspace/project_snapshot.dart';
import '../workspace/workspace_handle_store.dart';

/// Bounded transport budget shared by the CLI worker and the MCP bridge.
///
/// One complete mixed-256 Smart Tile draft is intentionally accepted as a
/// single semantic mutation. Callers can still lower this limit explicitly.
const int defaultAuthoringJsonlMaxInputBytes = 1024 * 1024;

final class JsonlWorker {
  JsonlWorker({
    required AuthoringReadApiPort api,
    AuthoringMutationApiPort? mutations,
    this.maxInputBytes = defaultAuthoringJsonlMaxInputBytes,
    this.commandTimeout = const Duration(seconds: 10),
  })  : _api = api,
        _mutations = mutations {
    if (maxInputBytes <= 0) {
      throw ArgumentError.value(
        maxInputBytes,
        'maxInputBytes',
        'must be positive',
      );
    }
    if (commandTimeout <= Duration.zero) {
      throw ArgumentError.value(
        commandTimeout,
        'commandTimeout',
        'must be positive',
      );
    }
  }

  final AuthoringReadApiPort _api;
  final AuthoringMutationApiPort? _mutations;
  final int maxInputBytes;
  final Duration commandTimeout;

  Future<String> processLine(String line) async {
    var requestId = 'invalid';
    AuthoringResult result;
    try {
      if (utf8.encode(line).length > maxInputBytes) {
        throw const _WorkerRequestException(
          'worker.input_too_large',
          'Request line exceeds the configured UTF-8 byte limit.',
        );
      }
      final decoded = _decodeRequestObject(line);
      final rawId = decoded['id'];
      if (rawId is String && rawId.trim().isNotEmpty) {
        requestId = rawId.trim();
      }
      rejectUnknownContractKeys(decoded, const {'id', 'command', 'args'});
      requestId = requireContractString(decoded['id'], 'id');
      final command = requireContractString(decoded['command'], 'command');
      final args = _jsonObject(decoded['args'], 'args');
      final data = await _dispatch(command, args).timeout(commandTimeout);
      result = AuthoringResult.success(requestId: requestId, data: data);
    } on TimeoutException {
      result = _failure(
        requestId,
        code: AuthoringErrorCode.internal,
        domainCode: 'worker.timeout',
        message: 'The command exceeded its configured time limit.',
        retryable: true,
      );
    } on _UnsupportedWorkerCommand {
      result = _failure(
        requestId,
        code: AuthoringErrorCode.unsupported,
        domainCode: 'worker.command_unsupported',
        message: 'The requested command is not supported.',
      );
    } on _WorkerRequestException catch (error) {
      result = _failure(
        requestId,
        code: AuthoringErrorCode.invalidRequest,
        domainCode: error.code,
        message: error.message,
      );
    } on FormatException {
      result = _failure(
        requestId,
        code: AuthoringErrorCode.invalidRequest,
        domainCode: 'worker.request_invalid',
        message: 'The request does not match the command contract.',
      );
    } on ArgumentError {
      result = _failure(
        requestId,
        code: AuthoringErrorCode.invalidRequest,
        domainCode: 'worker.request_invalid',
        message: 'The request does not match the command contract.',
      );
    } on WorkspaceAccessException catch (error) {
      result = _workspaceFailure(requestId, error);
    } on WorkspaceHandleException catch (error) {
      result = _failure(
        requestId,
        code: AuthoringErrorCode.notFound,
        domainCode: error.code,
        message: error.message,
      );
    } on ProjectOpenException catch (error) {
      result = _failure(
        requestId,
        code: AuthoringErrorCode.validationFailed,
        domainCode: error.code,
        message: error.message,
      );
    } on ProjectSnapshotException catch (error) {
      result = _failure(
        requestId,
        code: error.code == 'project.changed_during_snapshot'
            ? AuthoringErrorCode.revisionConflict
            : AuthoringErrorCode.validationFailed,
        domainCode: error.code,
        message: error.message,
        retryable: error.code == 'project.changed_during_snapshot',
      );
    } on AuthoringQueryException catch (error) {
      result = _queryFailure(requestId, error);
    } on MapRegionQueryException catch (error) {
      result = _failure(
        requestId,
        code: AuthoringErrorCode.invalidRequest,
        domainCode: error.code,
        message: error.message,
      );
    } on ArtifactStoreException catch (error) {
      result = _failure(
        requestId,
        code: _artifactDomainErrorCode(error.code),
        domainCode: error.code,
        message: error.message,
      );
    } on AssetActionException catch (error) {
      result = _failure(
        requestId,
        code: _assetDomainErrorCode(error.code),
        domainCode: error.code,
        message: error.message,
        details: _safeDetails(error.details),
      );
    } on CharacterStudioAssetException catch (error) {
      result = _failure(
        requestId,
        code: _characterStudioDomainErrorCode(error.code),
        domainCode: error.code,
        message: error.message,
        details: _safeDetails(error.details),
      );
    } on VisualLibraryException catch (error) {
      result = _failure(
        requestId,
        code: _visualDomainErrorCode(error.code),
        domainCode: error.code,
        message: error.message,
        details: _safeDetails(error.details),
      );
    } on CharacterStudioActionException catch (error) {
      result = _failure(
        requestId,
        code: _characterStudioDomainErrorCode(error.code),
        domainCode: error.code,
        message: error.message,
        details: _safeDetails(error.details),
      );
    } on MapAuthoringException catch (error) {
      result = _failure(
        requestId,
        code: _mapDomainErrorCode(error.code),
        domainCode: error.code,
        message: error.message,
        remediation: error.remediation,
        details: _safeDetails(error.details),
      );
    } on ItemCatalogAuthoringException catch (error) {
      result = _failure(
        requestId,
        code: _itemDomainErrorCode(error.code),
        domainCode: error.code,
        message: error.message,
        details: _safeDetails(error.details),
      );
    } on PokemonRulesetAuthoringException catch (error) {
      result = _failure(
        requestId,
        code: AuthoringErrorCode.validationFailed,
        domainCode: error.code,
        message: error.message,
      );
    } on AuthoringPlanException catch (error) {
      result = _failure(
        requestId,
        code: error.code == 'plan.stale'
            ? AuthoringErrorCode.revisionConflict
            : AuthoringErrorCode.validationFailed,
        domainCode: error.code,
        message: error.message,
        remediation: error.remediation,
        retryable: error.code == 'plan.stale',
      );
    } on AuthoringAuthorizationException catch (error) {
      result = _failure(
        requestId,
        code: AuthoringErrorCode.permissionDenied,
        domainCode: error.code,
        message: error.message,
        remediation: error.remediation,
      );
    } on AuthoringConfirmationException catch (error) {
      result = _failure(
        requestId,
        code: AuthoringErrorCode.invalidRequest,
        domainCode: error.code,
        message: error.message,
      );
    } on AuthoringRevisionConflict catch (error) {
      result = _failure(
        requestId,
        code: AuthoringErrorCode.revisionConflict,
        domainCode: error.code,
        message: 'One or more mutation resources changed.',
        remediation: error.remediation,
        retryable: true,
      );
    } on AuthoringIdempotencyException catch (error) {
      result = _failure(
        requestId,
        code: AuthoringErrorCode.revisionConflict,
        domainCode: error.code,
        message: error.message,
        remediation: error.remediation,
        retryable: error.code == 'idempotency.recovery_required',
      );
    } on JournaledAuthoringTransactionException catch (error) {
      result = _failure(
        requestId,
        code: AuthoringErrorCode.revisionConflict,
        domainCode: error.code,
        message: error.message,
      );
    } on AuthoringRecoveryException catch (error) {
      result = _failure(
        requestId,
        code: AuthoringErrorCode.revisionConflict,
        domainCode: error.code,
        message: error.message,
      );
    } on AuthoringHistoryException catch (error) {
      result = _failure(
        requestId,
        code: error.code == 'history.entry_missing'
            ? AuthoringErrorCode.notFound
            : AuthoringErrorCode.revisionConflict,
        domainCode: error.code,
        message: error.message,
      );
    } on Object {
      result = _failure(
        requestId,
        code: AuthoringErrorCode.internal,
        domainCode: 'worker.internal',
        message: 'The command failed unexpectedly.',
      );
    }
    return jsonEncode(result.toJson());
  }

  Future<Map<String, Object?>> _dispatch(
    String command,
    Map<String, dynamic> args,
  ) async {
    switch (command) {
      case 'describe':
        rejectUnknownContractKeys(args, const {});
        return _combinedDescription();
      case 'open':
        rejectUnknownContractKeys(args, const {'projectRoot'});
        final projectRoot =
            requireContractString(args['projectRoot'], 'args.projectRoot');
        final opened = await _api.open(projectRoot);
        final mutations = _mutations;
        if (mutations == null) return opened;
        final workspaceHandle = WorkspaceHandle(
          requireContractString(
            opened['workspaceHandle'],
            'open.workspaceHandle',
          ),
        );
        final projectHandle = ProjectHandle(
          requireContractString(opened['projectHandle'], 'open.projectHandle'),
        );
        try {
          await mutations.attachProject(
            projectRootPath: projectRoot,
            workspaceHandle: workspaceHandle,
            projectHandle: projectHandle,
          );
        } on Object {
          await _api.close(workspaceHandle);
          rethrow;
        }
        return Map.unmodifiable({...opened, 'readOnly': false});
      case 'query':
        rejectUnknownContractKeys(
          args,
          const {'projectHandle', 'request'},
        );
        final request = _jsonObject(args['request'], 'args.request');
        return _api.query(
          ProjectHandle(
            requireContractString(
              args['projectHandle'],
              'args.projectHandle',
            ),
          ),
          AuthoringQueryRequest.fromJson(request),
        );
      case 'validate':
        rejectUnknownContractKeys(
          args,
          const {'projectHandle', 'capabilityTruth'},
        );
        final capabilityInput = _capabilityInput(args['capabilityTruth']);
        return _api.validate(
          ProjectHandle(
            requireContractString(
              args['projectHandle'],
              'args.projectHandle',
            ),
          ),
          capabilityRecords: capabilityInput.records,
          requiredCapabilityIds: capabilityInput.requiredIds,
        );
      case 'close':
        rejectUnknownContractKeys(args, const {'workspaceHandle'});
        final workspaceHandle = WorkspaceHandle(
          requireContractString(
            args['workspaceHandle'],
            'args.workspaceHandle',
          ),
        );
        await _mutations?.detachWorkspace(workspaceHandle);
        return _api.close(workspaceHandle);
      case 'plan':
        rejectUnknownContractKeys(args, const {'projectHandle', 'request'});
        final request = _jsonObject(args['request'], 'args.request');
        return _mutationApi().plan(
          _projectHandle(args),
          AuthoringRequest.fromJson(request),
        );
      case 'stage_artifact':
        rejectUnknownContractKeys(
          args,
          const {'sourcePath', 'declaredMediaType'},
        );
        return _artifactStagingApi().stageArtifact(
          sourcePath: requireContractString(
            args['sourcePath'],
            'args.sourcePath',
          ),
          declaredMediaType: readOptionalContractString(
            args['declaredMediaType'],
            'args.declaredMediaType',
          ),
        );
      case 'confirm':
        rejectUnknownContractKeys(args, const {'projectHandle', 'planId'});
        return _mutationApi().confirm(
          _projectHandle(args),
          planId: requireContractString(args['planId'], 'args.planId'),
        );
      case 'apply':
        rejectUnknownContractKeys(
          args,
          const {
            'projectHandle',
            'planId',
            'operationId',
            'confirmationToken',
          },
        );
        return _mutationApi().apply(
          _projectHandle(args),
          planId: requireContractString(args['planId'], 'args.planId'),
          operationId:
              requireContractString(args['operationId'], 'args.operationId'),
          confirmationToken: readOptionalContractString(
            args['confirmationToken'],
            'args.confirmationToken',
          ),
        );
      case 'undo':
        rejectUnknownContractKeys(
          args,
          const {'projectHandle', 'entryId', 'idempotencyKey'},
        );
        return _mutationApi().undo(
          _projectHandle(args),
          entryId: requireContractString(args['entryId'], 'args.entryId'),
          idempotencyKey: requireContractString(
            args['idempotencyKey'],
            'args.idempotencyKey',
          ),
        );
      case 'history':
        rejectUnknownContractKeys(
          args,
          const {'projectHandle', 'limit', 'cursor'},
        );
        final limit = args['limit'];
        if (limit is! int) {
          throw const FormatException('args.limit must be an integer');
        }
        return _mutationApi().history(
          _projectHandle(args),
          limit: limit,
          cursor: readOptionalContractString(
            args['cursor'],
            'args.cursor',
          ),
        );
      case 'recover':
        rejectUnknownContractKeys(
          args,
          const {'projectHandle', 'operationId'},
        );
        return _mutationApi().recover(
          _projectHandle(args),
          operationId:
              requireContractString(args['operationId'], 'args.operationId'),
        );
      default:
        throw const _UnsupportedWorkerCommand();
    }
  }

  AuthoringMutationApiPort _mutationApi() =>
      _mutations ?? (throw const _UnsupportedWorkerCommand());

  AuthoringArtifactStagingPort _artifactStagingApi() {
    final mutations = _mutations;
    if (mutations is! AuthoringArtifactStagingPort) {
      throw const _UnsupportedWorkerCommand();
    }
    return mutations as AuthoringArtifactStagingPort;
  }

  ProjectHandle _projectHandle(Map<String, dynamic> args) => ProjectHandle(
        requireContractString(args['projectHandle'], 'args.projectHandle'),
      );

  Map<String, Object?> _combinedDescription() {
    final read = _api.describe();
    final mutations = _mutations;
    if (mutations == null) return read;
    final mutation = mutations.describeMutations();
    final commands = <Map<String, Object?>>[
      for (final command in read['commands']! as List)
        Map<String, Object?>.from(command as Map),
      for (final command in mutation['commands']! as List)
        Map<String, Object?>.from(command as Map),
    ]..sort(
        (left, right) =>
            (left['id']! as String).compareTo(right['id']! as String),
      );
    return freezeContractJsonObject(
      {
        ...read,
        'protocol': 'pokemap.authoring.v1',
        'readOnly': false,
        'commands': commands,
        'mutationActions': mutation['actions'],
        'multiFileGuarantee': mutation['multiFileGuarantee'],
        'fullParity': mutation['fullParity'],
      },
      field: 'describe',
    );
  }
}

Map<String, dynamic> _decodeRequestObject(String line) {
  try {
    return _jsonObject(jsonDecode(line), 'request');
  } on FormatException {
    throw const _WorkerRequestException(
      'worker.invalid_json',
      'Request line must contain exactly one JSON object.',
    );
  }
}

Map<String, dynamic> _jsonObject(Object? value, String field) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw FormatException('$field must be a JSON object');
  }
  return Map<String, dynamic>.from(value);
}

_CapabilityInput _capabilityInput(Object? value) {
  if (value == null) {
    return const _CapabilityInput();
  }
  final json = _jsonObject(value, 'args.capabilityTruth');
  rejectUnknownContractKeys(
    json,
    const {'records', 'requiredCapabilityIds'},
  );
  final rawRecords = json['records'];
  final rawRequired = json['requiredCapabilityIds'];
  if (rawRecords is! List ||
      rawRequired is! List ||
      rawRequired.any((item) => item is! String)) {
    throw const FormatException('Invalid capability truth collections.');
  }
  return _CapabilityInput(
    records: rawRecords.map(_capabilityRecord).toList(growable: false),
    requiredIds: rawRequired.cast<String>().toSet(),
  );
}

ProjectCapabilityTruthRecord _capabilityRecord(Object? value) {
  final json = _jsonObject(value, 'capabilityTruth.records[]');
  rejectUnknownContractKeys(json, const {
    'capabilityId',
    'authoringControl',
    'contractField',
    'runtimeConsumer',
    'playerSurface',
    'positiveTest',
    'negativeTest',
    'status',
    'reason',
  });
  final capabilityId = _stringValue(json['capabilityId'], 'capabilityId');
  final status = _stringValue(json['status'], 'status');
  final authoringControl =
      _nullableString(json['authoringControl'], 'authoringControl');
  final contractField = _nullableString(json['contractField'], 'contractField');
  final runtimeConsumer =
      _nullableString(json['runtimeConsumer'], 'runtimeConsumer');
  final playerSurface = _nullableString(json['playerSurface'], 'playerSurface');
  final positiveTest = _nullableString(json['positiveTest'], 'positiveTest');
  final negativeTest = _nullableString(json['negativeTest'], 'negativeTest');
  final reason = _nullableString(json['reason'], 'reason');
  return switch (status) {
    'promoted' when reason == null => ProjectCapabilityTruthRecord.promoted(
        capabilityId: capabilityId,
        authoringControl: authoringControl ?? '',
        contractField: contractField ?? '',
        runtimeConsumer: runtimeConsumer ?? '',
        playerSurface: playerSurface ?? '',
        positiveTest: positiveTest ?? '',
        negativeTest: negativeTest ?? '',
      ),
    'deferred'
        when authoringControl == null &&
            contractField == null &&
            runtimeConsumer == null &&
            playerSurface == null &&
            positiveTest == null &&
            negativeTest == null =>
      ProjectCapabilityTruthRecord.deferred(
        capabilityId: capabilityId,
        reason: reason,
      ),
    'promoted' || 'deferred' => throw const FormatException(
        'Capability fields contradict the declared status.',
      ),
    _ => throw const FormatException(
        'Capability status must be promoted or deferred.',
      ),
  };
}

String _stringValue(Object? value, String field) {
  if (value is! String) throw FormatException('$field must be a string');
  return value;
}

String? _nullableString(Object? value, String field) {
  if (value == null) return null;
  return _stringValue(value, field);
}

AuthoringResult _workspaceFailure(
  String requestId,
  WorkspaceAccessException error,
) {
  final code = switch (error.code) {
    'workspace.path_outside_allowed_roots' ||
    'workspace.path_outside_project' =>
      AuthoringErrorCode.permissionDenied,
    'workspace.directory_unavailable' ||
    'workspace.file_unavailable' =>
      AuthoringErrorCode.notFound,
    _ => AuthoringErrorCode.invalidRequest,
  };
  return _failure(
    requestId,
    code: code,
    domainCode: error.code,
    message: error.message,
  );
}

AuthoringResult _queryFailure(
  String requestId,
  AuthoringQueryException error,
) {
  final code = switch (error.code) {
    'query.resource_kind_unsupported' => AuthoringErrorCode.unsupported,
    'query.resource_not_found' => AuthoringErrorCode.notFound,
    _ => AuthoringErrorCode.invalidRequest,
  };
  return _failure(
    requestId,
    code: code,
    domainCode: error.code,
    message: error.message,
  );
}

AuthoringResult _failure(
  String requestId, {
  required AuthoringErrorCode code,
  required String domainCode,
  required String message,
  bool retryable = false,
  Iterable<String> remediation = const [],
  Map<String, Object?> details = const {},
}) {
  return AuthoringResult.failure(
    requestId: requestId,
    error: AuthoringError(
      code: code,
      message: message,
      retryable: retryable,
      remediation: remediation,
      details: {'domainCode': domainCode, ...details},
    ),
  );
}

AuthoringErrorCode _mapDomainErrorCode(String code) {
  if (code.endsWith('_unsupported')) return AuthoringErrorCode.unsupported;
  if (code == 'map.not_found' || code == 'map.document_missing') {
    return AuthoringErrorCode.notFound;
  }
  return AuthoringErrorCode.validationFailed;
}

AuthoringErrorCode _itemDomainErrorCode(String code) => switch (code) {
      'item.definition_not_found' => AuthoringErrorCode.notFound,
      'item.action_unsupported' => AuthoringErrorCode.unsupported,
      'item.id_duplicate' ||
      'item.identity_change_forbidden' ||
      'item.parameter_invalid' ||
      'item.parameters_invalid' ||
      'item.use_context_mismatch' ||
      'item.held_effect_invalid' =>
        AuthoringErrorCode.invalidRequest,
      _ => AuthoringErrorCode.validationFailed,
    };

AuthoringErrorCode _artifactDomainErrorCode(String code) => switch (code) {
      'artifact.source_outside_allowed_roots' =>
        AuthoringErrorCode.permissionDenied,
      'artifact.source_unavailable' ||
      'artifact.source_root_unavailable' =>
        AuthoringErrorCode.notFound,
      _ when code.endsWith('_unsupported') => AuthoringErrorCode.unsupported,
      _ => AuthoringErrorCode.validationFailed,
    };

AuthoringErrorCode _characterStudioDomainErrorCode(String code) {
  if (code.endsWith('_unsupported')) return AuthoringErrorCode.unsupported;
  if (code.endsWith('_not_found') || code.endsWith('.not_found')) {
    return AuthoringErrorCode.notFound;
  }
  return AuthoringErrorCode.validationFailed;
}

AuthoringErrorCode _assetDomainErrorCode(String code) => switch (code) {
      'artifact.unknown' => AuthoringErrorCode.notFound,
      _ when code.endsWith('_unsupported') => AuthoringErrorCode.unsupported,
      _ => AuthoringErrorCode.validationFailed,
    };

AuthoringErrorCode _visualDomainErrorCode(String code) => switch (code) {
      'tileset_folder.unknown' ||
      'element_category.unknown' =>
        AuthoringErrorCode.notFound,
      _ when code.endsWith('_unsupported') => AuthoringErrorCode.unsupported,
      _ => AuthoringErrorCode.validationFailed,
    };

Map<String, Object?> _safeDetails(Map<String, Object?> details) {
  final redacted = const AuthoringOutputRedactor().redact(details);
  return redacted is Map<String, Object?> ? redacted : const {};
}

final class _CapabilityInput {
  const _CapabilityInput({
    this.records = const [],
    this.requiredIds = const {},
  });

  final List<ProjectCapabilityTruthRecord> records;
  final Set<String> requiredIds;
}

final class _WorkerRequestException implements Exception {
  const _WorkerRequestException(this.code, this.message);

  final String code;
  final String message;
}

final class _UnsupportedWorkerCommand implements Exception {
  const _UnsupportedWorkerCommand();
}
