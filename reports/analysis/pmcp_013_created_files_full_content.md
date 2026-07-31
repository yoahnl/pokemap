# PMCP-013 — Full created-file contents

This appendix is part of the PMCP-013 Evidence Pack and reproduces every production, executable, test, and golden file created by the lot. Evidence reports and this appendix exclude themselves to avoid recursive content.

## `packages/map_authoring/bin/pokemap_authoring.dart`

~~~~~~~~dart
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';

Future<void> main(List<String> arguments) async {
  late final _CliOptions options;
  try {
    options = _CliOptions.parse(arguments);
  } on _CliUsageException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(_usage);
    exitCode = AuthoringCliExitCodes.usage;
    return;
  }

  const fileReader = LocalProjectFileReader();
  late final WorkspacePolicy policy;
  try {
    policy = await WorkspacePolicy.create(
      allowedRootPaths: options.allowedRoots,
      fileReader: fileReader,
    );
  } on WorkspaceAccessException catch (error) {
    stderr.writeln(
      'Unable to initialize the allowed roots (${error.code}).',
    );
    exitCode = AuthoringCliExitCodes.config;
    return;
  } on Object {
    stderr.writeln('Unable to initialize the read-only workspace.');
    exitCode = AuthoringCliExitCodes.software;
    return;
  }

  final handles = WorkspaceHandleStore();
  final api = AuthoringReadApi(
    openService: ProjectOpenService(
      policy: policy,
      fileReader: fileReader,
      handles: handles,
    ),
    snapshotLoader: ProjectSnapshotLoader(handles: handles),
  );
  final worker = JsonlWorker(
    api: api,
    commandTimeout: options.commandTimeout,
    maxInputBytes: options.maxInputBytes,
  );

  try {
    final lines = stdin.transform(utf8.decoder).transform(const LineSplitter());
    await for (final line in lines) {
      stdout.writeln(await worker.processLine(line));
      await stdout.flush();
    }
    exitCode = AuthoringCliExitCodes.success;
  } on Object {
    stderr.writeln('The JSONL input stream failed unexpectedly.');
    exitCode = AuthoringCliExitCodes.ioError;
  }
}

const String _usage = 'Usage: pokemap_authoring --root <allowed-root> '
    '[--root <allowed-root> ...] [--timeout-ms <positive-int>] '
    '[--max-input-bytes <positive-int>]';

final class _CliOptions {
  const _CliOptions({
    required this.allowedRoots,
    required this.commandTimeout,
    required this.maxInputBytes,
  });

  factory _CliOptions.parse(List<String> arguments) {
    final roots = <String>[];
    var timeoutMs = 10000;
    var maxInputBytes = 64 * 1024;
    var index = 0;
    while (index < arguments.length) {
      final option = arguments[index++];
      switch (option) {
        case '--root':
          roots.add(_nextValue(arguments, index++, option));
        case '--timeout-ms':
          timeoutMs = _positiveInt(
            _nextValue(arguments, index++, option),
            option,
          );
        case '--max-input-bytes':
          maxInputBytes = _positiveInt(
            _nextValue(arguments, index++, option),
            option,
          );
        default:
          throw const _CliUsageException('Unknown command-line option.');
      }
    }
    if (roots.isEmpty) {
      throw const _CliUsageException(
        'At least one --root option is required.',
      );
    }
    return _CliOptions(
      allowedRoots: List.unmodifiable(roots),
      commandTimeout: Duration(milliseconds: timeoutMs),
      maxInputBytes: maxInputBytes,
    );
  }

  final List<String> allowedRoots;
  final Duration commandTimeout;
  final int maxInputBytes;
}

String _nextValue(List<String> arguments, int index, String option) {
  if (index >= arguments.length ||
      arguments[index].trim().isEmpty ||
      arguments[index].startsWith('--')) {
    throw _CliUsageException('$option requires a value.');
  }
  return arguments[index];
}

int _positiveInt(String value, String option) {
  final parsed = int.tryParse(value);
  if (parsed == null || parsed <= 0) {
    throw _CliUsageException('$option requires a positive integer.');
  }
  return parsed;
}

final class _CliUsageException implements Exception {
  const _CliUsageException(this.message);

  final String message;
}
~~~~~~~~

## `packages/map_authoring/lib/src/api/authoring_read_api.dart`

~~~~~~~~dart
import 'package:map_core/map_core.dart';

import '../contracts/json_contract_support.dart';
import '../contracts/query_request.dart';
import '../domains/project/capability_truth_adapter.dart';
import '../references/project_reference_index.dart';
import '../registry/resource_kind_registry.dart';
import '../workspace/project_open_service.dart';
import '../workspace/project_query_service.dart';
import '../workspace/project_snapshot_loader.dart';
import '../workspace/workspace_handle_store.dart';

/// Port consumed by protocol adapters and deterministic test doubles.
abstract interface class AuthoringReadApiPort {
  Map<String, Object?> describe();

  Future<Map<String, Object?>> open(String projectRootPath);

  Future<Map<String, Object?>> query(
    ProjectHandle projectHandle,
    AuthoringQueryRequest request,
  );

  Future<Map<String, Object?>> validate(
    ProjectHandle projectHandle, {
    Iterable<ProjectCapabilityTruthRecord> capabilityRecords = const [],
    Set<String> requiredCapabilityIds = const {},
  });

  Future<Map<String, Object?>> close(WorkspaceHandle workspaceHandle);
}

/// Shared read-only application API used directly and through JSONL.
final class AuthoringReadApi implements AuthoringReadApiPort {
  const AuthoringReadApi({
    required ProjectOpenService openService,
    required ProjectSnapshotLoader snapshotLoader,
    ProjectQueryService queryService = const ProjectQueryService(),
  })  : _openService = openService,
        _snapshotLoader = snapshotLoader,
        _queryService = queryService;

  final ProjectOpenService _openService;
  final ProjectSnapshotLoader _snapshotLoader;
  final ProjectQueryService _queryService;

  @override
  Map<String, Object?> describe() {
    final readableResourceKinds =
        AuthoringResourceKindRegistry.canonicalMinimal()
            .resourceKinds
            .where((kind) => kind.id == 'map' || kind.id == 'project')
            .map((kind) => kind.toJson())
            .toList(growable: false);
    return freezeContractJsonObject(
      {
        'schemaVersion': 1,
        'protocol': 'pokemap.authoring.read.v1',
        'readOnly': true,
        'commands': const [
          {
            'id': 'close',
            'summary': 'Close an in-memory read-only workspace.',
          },
          {
            'id': 'describe',
            'summary': 'Describe this read-only API.',
          },
          {
            'id': 'open',
            'summary': 'Open an allowed PokeMap project read-only.',
          },
          {
            'id': 'query',
            'summary': 'Query an immutable project snapshot.',
          },
          {
            'id': 'validate',
            'summary': 'Inspect references and explicit capability truth.',
          },
        ],
        'queryOperations': [
          for (final operation in AuthoringQueryOperation.values)
            operation.wireName,
        ],
        'resourceKinds': readableResourceKinds,
        'validation': const {
          'references': true,
          'capabilityTruth': 'explicit_only',
        },
      },
      field: 'describe',
    );
  }

  @override
  Future<Map<String, Object?>> open(String projectRootPath) async {
    final opened = await _openService.openProject(projectRootPath);
    return freezeContractJsonObject(opened.toJson(), field: 'open');
  }

  @override
  Future<Map<String, Object?>> query(
    ProjectHandle projectHandle,
    AuthoringQueryRequest request,
  ) async {
    final snapshot = await _snapshotLoader.load(projectHandle);
    return freezeContractJsonObject(
      _queryService.query(snapshot, request).toJson(),
      field: 'query',
    );
  }

  @override
  Future<Map<String, Object?>> validate(
    ProjectHandle projectHandle, {
    Iterable<ProjectCapabilityTruthRecord> capabilityRecords = const [],
    Set<String> requiredCapabilityIds = const {},
  }) async {
    final snapshot = await _snapshotLoader.load(projectHandle);
    final references = ProjectReferenceIndex.fromSnapshot(snapshot);
    final capabilityTruth = ProjectCapabilityTruthAdapter.evaluate(
      records: capabilityRecords,
      requiredCapabilityIds: requiredCapabilityIds,
    );
    final referenceHasErrors = references.diagnostics.any(
      (diagnostic) => diagnostic.severity == ProjectReferenceSeverity.error,
    );
    return freezeContractJsonObject(
      {
        'snapshotRevision': snapshot.revision,
        'valid': !referenceHasErrors && capabilityTruth.isPassing,
        'references': {
          'nodeCount': references.nodes.length,
          'edgeCount': references.edges.length,
          'hasErrors': referenceHasErrors,
          'diagnostics': references.diagnostics
              .map((diagnostic) => diagnostic.toJson())
              .toList(growable: false),
        },
        'capabilityTruth': capabilityTruth.toJson(),
      },
      field: 'validate',
    );
  }

  @override
  Future<Map<String, Object?>> close(WorkspaceHandle workspaceHandle) async {
    return Map.unmodifiable({
      'closed': _openService.closeWorkspace(workspaceHandle),
    });
  }
}
~~~~~~~~

## `packages/map_authoring/lib/src/tooling/cli_exit_codes.dart`

~~~~~~~~dart
/// Sysexits-style process codes used by the PokeMap authoring CLI.
abstract final class AuthoringCliExitCodes {
  static const int success = 0;
  static const int usage = 64;
  static const int dataError = 65;
  static const int noInput = 66;
  static const int software = 70;
  static const int ioError = 74;
  static const int config = 78;
}
~~~~~~~~

## `packages/map_authoring/lib/src/tooling/jsonl_worker.dart`

~~~~~~~~dart
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
~~~~~~~~

## `packages/map_authoring/test/tooling/jsonl_worker_test.dart`

~~~~~~~~dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('JsonlWorker', () {
    test('golden describe and malformed input are byte-for-byte stable',
        () async {
      final setup = await _TestSetup.create();
      final describe = await setup.worker.processLine(
        jsonEncode({
          'id': 'describe-1',
          'command': 'describe',
          'args': <String, Object?>{},
        }),
      );
      final malformed = await setup.worker.processLine('{');
      final transcript = '$describe\n$malformed\n';
      final golden = await File(
        'test/tooling/goldens/describe_and_error.jsonl',
      ).readAsString();

      expect(transcript, golden);
      for (final line in [describe, malformed]) {
        expect(line, isNot(contains('\n')));
        expect(jsonDecode(line), isA<Map<String, dynamic>>());
      }
    });

    test('describe advertises only the five read commands', () async {
      final setup = await _TestSetup.create();

      final result = await _request(
        setup.worker,
        id: 'describe-commands',
        command: 'describe',
      );

      expect(result.status, AuthoringResultStatus.success);
      final commands = (result.data['commands']! as List)
          .cast<Map<String, Object?>>()
          .map((command) => command['id']);
      expect(commands, ['close', 'describe', 'open', 'query', 'validate']);
      expect(
        jsonEncode(result.data).toLowerCase(),
        isNot(contains('"write"')),
      );
    });

    test('opens, queries, validates, and closes the real project', () async {
      final setup = await _TestSetup.create();
      final opened = await _request(
        setup.worker,
        id: 'open-1',
        command: 'open',
        args: {'projectRoot': setup.fixture.path},
      );
      final projectHandle = opened.data['projectHandle']! as String;
      final workspaceHandle = opened.data['workspaceHandle']! as String;
      final request = AuthoringQueryRequest(
        resourceKind: 'project',
        operation: AuthoringQueryOperation.get,
        view: AuthoringQueryView.summary,
        ids: const ['project'],
      );

      final queried = await _request(
        setup.worker,
        id: 'query-1',
        command: 'query',
        args: {
          'projectHandle': projectHandle,
          'request': request.toJson(),
        },
      );
      final validated = await _request(
        setup.worker,
        id: 'validate-1',
        command: 'validate',
        args: {'projectHandle': projectHandle},
      );
      final closed = await _request(
        setup.worker,
        id: 'close-1',
        command: 'close',
        args: {'workspaceHandle': workspaceHandle},
      );

      expect(opened.status, AuthoringResultStatus.success);
      expect(opened.data['readOnly'], isTrue);
      expect(queried.status, AuthoringResultStatus.success);
      expect(
        (queried.data['items']! as List).single,
        containsPair('name', 'P3 Narrative Smoke Slice'),
      );
      expect(validated.status, AuthoringResultStatus.success);
      expect(validated.data['snapshotRevision'], startsWith('sha256:'));
      expect(validated.data['references'], isA<Map<String, Object?>>());
      expect(validated.data['capabilityTruth'], isA<Map<String, Object?>>());
      expect(closed.data, {'closed': true});

      final afterClose = await _request(
        setup.worker,
        id: 'query-after-close',
        command: 'query',
        args: {
          'projectHandle': projectHandle,
          'request': request.toJson(),
        },
      );
      expect(afterClose.status, AuthoringResultStatus.failure);
      expect(afterClose.error?.code, AuthoringErrorCode.notFound);
      expect(
          jsonEncode(afterClose.toJson()), isNot(contains(setup.fixture.path)));
    });

    test('malformed and unknown requests do not terminate the worker',
        () async {
      final setup = await _TestSetup.create();

      final malformed = _decode(await setup.worker.processLine('not-json'));
      final unknown = await _request(
        setup.worker,
        id: 'unknown-1',
        command: 'delete',
      );
      final strict = _decode(
        await setup.worker.processLine(
          jsonEncode({
            'id': 'strict-1',
            'command': 'describe',
            'args': <String, Object?>{},
            'unexpected': true,
          }),
        ),
      );
      final recovered = await _request(
        setup.worker,
        id: 'describe-after-errors',
        command: 'describe',
      );

      expect(malformed.status, AuthoringResultStatus.failure);
      expect(malformed.requestId, 'invalid');
      expect(malformed.error?.code, AuthoringErrorCode.invalidRequest);
      expect(unknown.status, AuthoringResultStatus.failure);
      expect(unknown.error?.code, AuthoringErrorCode.unsupported);
      expect(strict.status, AuthoringResultStatus.failure);
      expect(strict.error?.code, AuthoringErrorCode.invalidRequest);
      expect(recovered.status, AuthoringResultStatus.success);
    });

    test('rejects a line above the UTF-8 byte limit', () async {
      final setup = await _TestSetup.create(maxInputBytes: 32);
      final result = _decode(
        await setup.worker.processLine(
          jsonEncode({
            'id': 'large',
            'command': 'describe',
            'args': {'padding': 'é' * 64},
          }),
        ),
      );

      expect(result.status, AuthoringResultStatus.failure);
      expect(result.requestId, 'invalid');
      expect(result.error?.code, AuthoringErrorCode.invalidRequest);
      expect(result.error?.details['domainCode'], 'worker.input_too_large');
    });

    test('times out one command without exposing its exception', () async {
      final worker = JsonlWorker(
        api: const _DelayedReadApi(),
        commandTimeout: const Duration(milliseconds: 1),
      );

      final result = await _request(
        worker,
        id: 'timeout-1',
        command: 'open',
        args: const {'projectRoot': 'ignored'},
      );

      expect(result.status, AuthoringResultStatus.failure);
      expect(result.error?.code, AuthoringErrorCode.internal);
      expect(result.error?.retryable, isTrue);
      expect(result.error?.details['domainCode'], 'worker.timeout');
      expect(jsonEncode(result.toJson()), isNot(contains('TimeoutException')));
    });

    test('redacts unexpected exception text and machine paths', () async {
      final worker = JsonlWorker(api: const _ThrowingReadApi());

      final result = await _request(
        worker,
        id: 'internal-1',
        command: 'open',
        args: const {'projectRoot': 'ignored'},
      );
      final encoded = jsonEncode(result.toJson());

      expect(result.status, AuthoringResultStatus.failure);
      expect(result.error?.code, AuthoringErrorCode.internal);
      expect(result.error?.details['domainCode'], 'worker.internal');
      expect(encoded, isNot(contains('/Users/secret/project')));
      expect(encoded, isNot(contains('StateError')));
      expect(encoded, isNot(contains('stack trace')));
    });

    test('returns the exact direct API query projection', () async {
      final setup = await _TestSetup.create();
      final opened = await setup.api.open(setup.fixture.path);
      final projectHandle = opened['projectHandle']! as String;
      final request = AuthoringQueryRequest(
        resourceKind: 'map',
        operation: AuthoringQueryOperation.list,
        view: AuthoringQueryView.summary,
        pageSize: 10,
      );

      final direct = await setup.api.query(
        ProjectHandle(projectHandle),
        request,
      );
      final transported = await _request(
        setup.worker,
        id: 'parity-1',
        command: 'query',
        args: {
          'projectHandle': projectHandle,
          'request': request.toJson(),
        },
      );

      expect(transported.status, AuthoringResultStatus.success);
      expect(transported.data, direct);
    });

    test('adapts explicit capability records during validation', () async {
      final setup = await _TestSetup.create();
      final opened = await _request(
        setup.worker,
        id: 'open-capability',
        command: 'open',
        args: {'projectRoot': setup.fixture.path},
      );

      final validated = await _request(
        setup.worker,
        id: 'validate-capability',
        command: 'validate',
        args: {
          'projectHandle': opened.data['projectHandle'],
          'capabilityTruth': {
            'requiredCapabilityIds': ['narrative.command.dialogue'],
            'records': [
              {
                'capabilityId': 'narrative.command.dialogue',
                'authoringControl': 'Dialogue picker',
                'contractField': 'DialogueCommand.dialogueId',
                'runtimeConsumer': 'DialogueCommandRunner',
                'playerSurface': 'Dialogue overlay',
                'positiveTest': 'dialogue_positive_test.dart',
                'negativeTest': 'dialogue_missing_test.dart',
                'status': 'promoted',
                'reason': null,
              },
            ],
          },
        },
      );

      final capabilityTruth =
          validated.data['capabilityTruth']! as Map<String, Object?>;
      expect(capabilityTruth['status'], 'pass');
      expect(
        (capabilityTruth['capabilities']! as List).single,
        containsPair('status', 'promoted'),
      );
    });

    test('rejects contradictory capability status fields', () async {
      final setup = await _TestSetup.create();
      final opened = await _request(
        setup.worker,
        id: 'open-contradictory-capability',
        command: 'open',
        args: {'projectRoot': setup.fixture.path},
      );

      final result = await _request(
        setup.worker,
        id: 'validate-contradictory-capability',
        command: 'validate',
        args: {
          'projectHandle': opened.data['projectHandle'],
          'capabilityTruth': {
            'requiredCapabilityIds': ['narrative.command.dialogue'],
            'records': [
              {
                'capabilityId': 'narrative.command.dialogue',
                'authoringControl': 'Dialogue picker',
                'contractField': 'DialogueCommand.dialogueId',
                'runtimeConsumer': 'DialogueCommandRunner',
                'playerSurface': 'Dialogue overlay',
                'positiveTest': 'dialogue_positive_test.dart',
                'negativeTest': 'dialogue_missing_test.dart',
                'status': 'promoted',
                'reason': 'Contradicts promoted status.',
              },
            ],
          },
        },
      );

      expect(result.status, AuthoringResultStatus.failure);
      expect(result.error?.code, AuthoringErrorCode.invalidRequest);
    });
  });
}

final class _TestSetup {
  const _TestSetup({
    required this.fixture,
    required this.api,
    required this.worker,
  });

  final Directory fixture;
  final AuthoringReadApi api;
  final JsonlWorker worker;

  static Future<_TestSetup> create({int maxInputBytes = 64 * 1024}) async {
    final fixture = Directory(
      [
        Directory.current.parent.parent.path,
        'examples',
        'playable_runtime_host',
        'p3_narrative_smoke_slice',
      ].join(Platform.pathSeparator),
    );
    var token = 0;
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [fixture.parent.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore(
      clock: () => DateTime.utc(2026, 7, 31, 12),
      tokenFactory: (prefix) => '$prefix${token++}',
    );
    final api = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
    );
    return _TestSetup(
      fixture: fixture,
      api: api,
      worker: JsonlWorker(
        api: api,
        maxInputBytes: maxInputBytes,
        commandTimeout: const Duration(seconds: 5),
      ),
    );
  }
}

Future<AuthoringResult> _request(
  JsonlWorker worker, {
  required String id,
  required String command,
  Map<String, Object?> args = const {},
}) async {
  return _decode(
    await worker.processLine(
      jsonEncode({
        'id': id,
        'command': command,
        'args': args,
      }),
    ),
  );
}

AuthoringResult _decode(String line) {
  final decoded = jsonDecode(line);
  return AuthoringResult.fromJson(
    Map<String, dynamic>.from(decoded as Map),
  );
}

final class _DelayedReadApi implements AuthoringReadApiPort {
  const _DelayedReadApi();

  @override
  Map<String, Object?> describe() => const {};

  @override
  Future<Map<String, Object?>> open(String projectRootPath) {
    return Future.delayed(
      const Duration(milliseconds: 50),
      () => const <String, Object?>{},
    );
  }

  @override
  Future<Map<String, Object?>> query(
    ProjectHandle projectHandle,
    AuthoringQueryRequest request,
  ) async =>
      const {};

  @override
  Future<Map<String, Object?>> validate(
    ProjectHandle projectHandle, {
    Iterable<ProjectCapabilityTruthRecord> capabilityRecords = const [],
    Set<String> requiredCapabilityIds = const {},
  }) async =>
      const {};

  @override
  Future<Map<String, Object?>> close(WorkspaceHandle workspaceHandle) async =>
      const {};
}

final class _ThrowingReadApi implements AuthoringReadApiPort {
  const _ThrowingReadApi();

  @override
  Map<String, Object?> describe() => throw StateError(
        '/Users/secret/project stack trace should never be serialized',
      );

  @override
  Future<Map<String, Object?>> open(String projectRootPath) {
    throw StateError(
      '/Users/secret/project stack trace should never be serialized',
    );
  }

  @override
  Future<Map<String, Object?>> query(
    ProjectHandle projectHandle,
    AuthoringQueryRequest request,
  ) async =>
      throw StateError(
        '/Users/secret/project stack trace should never be serialized',
      );

  @override
  Future<Map<String, Object?>> validate(
    ProjectHandle projectHandle, {
    Iterable<ProjectCapabilityTruthRecord> capabilityRecords = const [],
    Set<String> requiredCapabilityIds = const {},
  }) async =>
      throw StateError(
        '/Users/secret/project stack trace should never be serialized',
      );

  @override
  Future<Map<String, Object?>> close(WorkspaceHandle workspaceHandle) async =>
      throw StateError(
        '/Users/secret/project stack trace should never be serialized',
      );
}
~~~~~~~~

## `packages/map_authoring/test/tooling/cli_golden_test.dart`

~~~~~~~~dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  group('pokemap_authoring CLI', () {
    test('runs the real read-only JSONL session with direct API parity',
        () async {
      expect(
        File('bin/pokemap_authoring.dart').existsSync(),
        isTrue,
        reason: 'The declared CLI executable must exist.',
      );
      final fixture = _fixture();
      final directApi = await _directApi(fixture);
      final directOpened = await directApi.open(fixture.path);
      final projectQuery = AuthoringQueryRequest(
        resourceKind: 'project',
        operation: AuthoringQueryOperation.get,
        view: AuthoringQueryView.summary,
        ids: const ['project'],
      );
      final directQuery = await directApi.query(
        ProjectHandle(directOpened['projectHandle']! as String),
        projectQuery,
      );
      final session = await _CliSession.start(
        root: fixture.parent.path,
      );

      final malformed = await session.sendRaw('{');
      final described = await session.send(
        id: 'describe-cli',
        command: 'describe',
      );
      final opened = await session.send(
        id: 'open-cli',
        command: 'open',
        args: {'projectRoot': fixture.path},
      );
      final queried = await session.send(
        id: 'query-cli',
        command: 'query',
        args: {
          'projectHandle': opened.data['projectHandle'],
          'request': projectQuery.toJson(),
        },
      );
      final validated = await session.send(
        id: 'validate-cli',
        command: 'validate',
        args: {'projectHandle': opened.data['projectHandle']},
      );
      final closed = await session.send(
        id: 'close-cli',
        command: 'close',
        args: {'workspaceHandle': opened.data['workspaceHandle']},
      );
      final completed = await session.finish();

      expect(malformed.status, AuthoringResultStatus.failure);
      expect(malformed.error?.code, AuthoringErrorCode.invalidRequest);
      expect(described.status, AuthoringResultStatus.success);
      expect(opened.status, AuthoringResultStatus.success);
      expect(opened.data['readOnly'], isTrue);
      expect(queried.data, directQuery);
      expect(validated.status, AuthoringResultStatus.success);
      expect(validated.data['references'], isA<Map<String, Object?>>());
      expect(closed.data, {'closed': true});
      expect(completed.exitCode, AuthoringCliExitCodes.success);
      expect(completed.stderr, isEmpty);
      expect(
        completed.rawResponses.every((line) {
          if (line.contains('\n')) return false;
          return jsonDecode(line) is Map;
        }),
        isTrue,
      );
      expect(
        completed.rawResponses.join(),
        isNot(contains(fixture.parent.path)),
      );
    });

    test('requires at least one allowed root without polluting stdout',
        () async {
      expect(File('bin/pokemap_authoring.dart').existsSync(), isTrue);

      final result = await Process.run(
        Platform.resolvedExecutable,
        ['bin/pokemap_authoring.dart'],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, AuthoringCliExitCodes.usage);
      expect(result.stdout, isEmpty);
      expect(result.stderr, contains('--root'));
    });

    test('rejects an option token used as a root value', () async {
      final result = await Process.run(
        Platform.resolvedExecutable,
        [
          'bin/pokemap_authoring.dart',
          '--root',
          '--timeout-ms',
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, AuthoringCliExitCodes.usage);
      expect(result.stdout, isEmpty);
      expect(result.stderr, contains('--root requires a value'));
    });

    test('does not echo an unknown machine-local argument', () async {
      const secretArgument = '/Users/secret/project';
      final result = await Process.run(
        Platform.resolvedExecutable,
        [
          'bin/pokemap_authoring.dart',
          secretArgument,
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, AuthoringCliExitCodes.usage);
      expect(result.stdout, isEmpty);
      expect(result.stderr, isNot(contains(secretArgument)));
      expect(result.stderr, contains('Unknown command-line option'));
    });
  });
}

Directory _fixture() {
  return Directory(
    [
      Directory.current.parent.parent.path,
      'examples',
      'playable_runtime_host',
      'p3_narrative_smoke_slice',
    ].join(Platform.pathSeparator),
  );
}

Future<AuthoringReadApi> _directApi(Directory fixture) async {
  var token = 0;
  const reader = LocalProjectFileReader();
  final policy = await WorkspacePolicy.create(
    allowedRootPaths: [fixture.parent.path],
    fileReader: reader,
  );
  final handles = WorkspaceHandleStore(
    clock: () => DateTime.utc(2026, 7, 31, 12),
    tokenFactory: (prefix) => '$prefix${token++}',
  );
  return AuthoringReadApi(
    openService: ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    ),
    snapshotLoader: ProjectSnapshotLoader(handles: handles),
  );
}

final class _CliSession {
  _CliSession._({
    required Process process,
    required StreamIterator<String> stdoutLines,
    required Future<String> stderr,
  })  : _process = process,
        _stdoutLines = stdoutLines,
        _stderr = stderr;

  final Process _process;
  final StreamIterator<String> _stdoutLines;
  final Future<String> _stderr;
  final List<String> _rawResponses = [];

  static Future<_CliSession> start({required String root}) async {
    final process = await Process.start(
      Platform.resolvedExecutable,
      [
        'bin/pokemap_authoring.dart',
        '--root',
        root,
        '--timeout-ms',
        '5000',
        '--max-input-bytes',
        '65536',
      ],
      workingDirectory: Directory.current.path,
    );
    return _CliSession._(
      process: process,
      stdoutLines: StreamIterator(
        process.stdout.transform(utf8.decoder).transform(const LineSplitter()),
      ),
      stderr: process.stderr.transform(utf8.decoder).join(),
    );
  }

  Future<AuthoringResult> send({
    required String id,
    required String command,
    Map<String, Object?> args = const {},
  }) {
    return sendRaw(
      jsonEncode({
        'id': id,
        'command': command,
        'args': args,
      }),
    );
  }

  Future<AuthoringResult> sendRaw(String line) async {
    _process.stdin.writeln(line);
    await _process.stdin.flush();
    final hasLine = await _stdoutLines.moveNext().timeout(
          const Duration(seconds: 10),
        );
    if (!hasLine) {
      throw StateError('CLI closed stdout before returning a response.');
    }
    final response = _stdoutLines.current;
    _rawResponses.add(response);
    return AuthoringResult.fromJson(
      Map<String, dynamic>.from(jsonDecode(response) as Map),
    );
  }

  Future<_CliCompletion> finish() async {
    await _process.stdin.close();
    final exitCode = await _process.exitCode.timeout(
      const Duration(seconds: 10),
    );
    await _stdoutLines.cancel();
    return _CliCompletion(
      exitCode: exitCode,
      stderr: await _stderr,
      rawResponses: List.unmodifiable(_rawResponses),
    );
  }
}

final class _CliCompletion {
  const _CliCompletion({
    required this.exitCode,
    required this.stderr,
    required this.rawResponses,
  });

  final int exitCode;
  final String stderr;
  final List<String> rawResponses;
}
~~~~~~~~

## `packages/map_authoring/test/tooling/goldens/describe_and_error.jsonl`

~~~~~~~~json
{"requestId":"describe-1","status":"success","data":{"commands":[{"id":"close","summary":"Close an in-memory read-only workspace."},{"id":"describe","summary":"Describe this read-only API."},{"id":"open","summary":"Open an allowed PokeMap project read-only."},{"id":"query","summary":"Query an immutable project snapshot."},{"id":"validate","summary":"Inspect references and explicit capability truth."}],"protocol":"pokemap.authoring.read.v1","queryOperations":["list","get","batch_get","search","summary"],"readOnly":true,"resourceKinds":[{"displayName":"Map","id":"map","summary":"Editable PokeMap map","version":1},{"displayName":"Project","id":"project","summary":"PokeMap project manifest and project-owned content","version":1}],"schemaVersion":1,"validation":{"capabilityTruth":"explicit_only","references":true}},"artifacts":[]}
{"requestId":"invalid","status":"failure","data":{},"error":{"code":"invalid_request","message":"Request line must contain exactly one JSON object.","retryable":false,"remediation":[],"details":{"domainCode":"worker.invalid_json"}},"artifacts":[]}
~~~~~~~~
