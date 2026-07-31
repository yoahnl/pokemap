import 'dart:async';
import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../api/authoring_read_api.dart';
import '../contracts/authoring_error.dart';
import '../contracts/authoring_result.dart';
import '../contracts/json_contract_support.dart';
import '../contracts/query_request.dart';
import '../domains/maps/map_region_query.dart';
import '../ports/project_file_reader.dart';
import '../workspace/project_open_service.dart';
import '../workspace/project_query_service.dart';
import '../workspace/project_snapshot.dart';
import '../workspace/workspace_handle_store.dart';

final class JsonlWorker {
  JsonlWorker({
    required AuthoringReadApiPort api,
    this.maxInputBytes = 64 * 1024,
    this.commandTimeout = const Duration(seconds: 10),
  }) : _api = api {
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
        return _api.describe();
      case 'open':
        rejectUnknownContractKeys(args, const {'projectRoot'});
        return _api.open(
          requireContractString(args['projectRoot'], 'args.projectRoot'),
        );
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
        return _api.close(
          WorkspaceHandle(
            requireContractString(
              args['workspaceHandle'],
              'args.workspaceHandle',
            ),
          ),
        );
      default:
        throw const _UnsupportedWorkerCommand();
    }
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
}) {
  return AuthoringResult.failure(
    requestId: requestId,
    error: AuthoringError(
      code: code,
      message: message,
      retryable: retryable,
      details: {'domainCode': domainCode},
    ),
  );
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
