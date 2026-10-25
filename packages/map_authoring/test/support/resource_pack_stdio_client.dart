import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

final class ResourcePackStdioClient {
  ResourcePackStdioClient._(this.process)
      : _output = StreamIterator(process.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())),
        _errors = process.stderr.transform(utf8.decoder).join();
  final Process process;
  final StreamIterator<String> _output;
  final Future<String> _errors;
  var _sequence = 0;
  Future<void>? _closing;

  static Future<ResourcePackStdioClient> start(String root,
      {bool controlled = false}) async {
    final binary = controlled
        ? Platform.environment['POKEMAP_RESOURCE_PACK_TEST_WORKER']
        : null;
    final executable =
        binary ?? Platform.environment['POKEMAP_TEST_DART'] ?? 'dart';
    return ResourcePackStdioClient._(await Process.start(executable, [
      if (binary == null) ...[
        'run',
        controlled
            ? 'test/support/resource_pack_controlled_jsonl_worker.dart'
            : 'bin/pokemap_authoring.dart'
      ],
      '--root',
      root,
    ]));
  }

  Future<Map<String, dynamic>> call(String command, Map<String, Object?> args,
      {String? error}) async {
    process.stdin.writeln(jsonEncode(
        {'id': 'rp-${++_sequence}', 'command': command, 'args': args}));
    await process.stdin.flush();
    if (!await _output.moveNext()) throw StateError('The JSONL worker exited.');
    final response = jsonDecode(_output.current) as Map<String, dynamic>;
    if (command == 'resource_pack') {
      expect(utf8.encode(_output.current).length, lessThanOrEqualTo(256 * 1024));
    }
    expect(response['status'], error == null ? 'success' : 'failure',
        reason: response.toString());
    if (error != null) {
      final failure = Map<String, dynamic>.from(response['error'] as Map);
      expect((failure['details'] as Map)['domainCode'], error);
      return failure;
    }
    return Map<String, dynamic>.from(response['data'] as Map);
  }

  Future<Map<String, dynamic>> pack(Map opened, String verb,
          [Map<String, Object?> input = const {}, String? error]) =>
      call(
          'resource_pack',
          {
            'projectHandle': opened['projectHandle'],
            'verb': verb,
            'input': input
          },
          error: error);

  Future<Map<String, dynamic>> poll(Map opened, Map start) async {
    for (var i = 0; i < 3000; i++) {
      final state = await pack(opened, 'get', {'jobId': start['jobId']});
      if (const ['succeeded', 'failed', 'cancelled']
          .contains((state['snapshot'] as Map)['state'])) {
        return state;
      }
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    throw StateError('The resource pack job did not settle.');
  }

  Future<Map<String, dynamic>> result(Map opened, Map start) async {
    final state = await poll(opened, start);
    expect((state['snapshot'] as Map)['state'], 'succeeded',
        reason: state.toString());
    return Map<String, dynamic>.from(state['result'] as Map);
  }

  Future<Map<String, dynamic>> planImport(
      Map opened, String sourcePath, String key) async {
    final staged = await result(
        opened, await pack(opened, 'stage', {'sourcePath': sourcePath}));
    final inspected = await result(
        opened,
        await pack(
            opened, 'inspect', {'archiveHandle': staged['archiveHandle']}));
    final selection = await pack(opened, 'selection.create',
        {'mode': 'archive', 'inspectionHandle': inspected['inspectionHandle']});
    final chosen = await pack(opened, 'selection.select_filtered', {
      'selectionHandle': selection['selectionHandle'],
      'revision': selection['revision'],
      'filter': {'kind': 'element'}
    });
    final validation =
        await call('validate', {'projectHandle': opened['projectHandle']});
    final prepared = await result(
        opened,
        await pack(opened, 'prepare', {
          'selectionHandle': chosen['selectionHandle'],
          'revision': chosen['revision'],
          'expectedRevision': validation['snapshotRevision'],
        }));
    final planned = await call('plan', {
      'projectHandle': opened['projectHandle'],
      'request': {
        'requestId': key,
        'actionId': 'resource_pack.import',
        'actionVersion': 1,
        'workspaceHandle': opened['workspaceHandle'],
        'expectedRevision': validation['snapshotRevision'],
        'parameters': {
          'preparedImportHandle': prepared['preparedImportHandle']
        },
        'idempotencyKey': key,
        'dryRun': false,
      }
    });
    return {...planned, 'inspection': inspected, 'selection': chosen, 'prepared': prepared};
  }

  Future<Map<String, dynamic>> history(
      Map opened, String operation, Object entryId, String operationId,
      {Object? expectedHeadEntryId}) async {
    final validation =
        await call('validate', {'projectHandle': opened['projectHandle']});
    return result(
        opened,
        await pack(opened, 'start_history', {
          'operation': operation,
          'entryId': entryId,
          'operationId': operationId,
          'expectedRevision': validation['snapshotRevision'],
          if (expectedHeadEntryId != null)
            'expectedHeadEntryId': expectedHeadEntryId,
        }));
  }

  Future<void> close() => _closing ??= _close();
  Future<void> _close() async {
    await process.stdin.close();
    final exitCode = await process.exitCode.timeout(const Duration(seconds: 10),
        onTimeout: () {
      process.kill();
      return -1;
    });
    await _output.cancel();
    final errors = await _errors;
    expect(exitCode, 0, reason: errors);
    expect(errors, isEmpty);
  }
}
