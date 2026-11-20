part of 'transport_certification_session.dart';

final class _WireSession {
  _WireSession(this.process, this.mcp)
    : lines = StreamIterator(
        process.stdout.transform(utf8.decoder).transform(const LineSplitter()),
      ),
      errors = process.stderr.transform(utf8.decoder).join();

  final Process process;
  final bool mcp;
  final StreamIterator<String> lines;
  final Future<String> errors;
  int sequence = 0;

  static Future<TransportCertificationSession> open(
    AuthoringTransport transport,
    Directory project,
    Directory repository,
    String dart,
  ) async {
    final cli = p.join(repository.path, 'packages/map_authoring');
    final mcp = p.join(repository.path, 'tools/pokemap_mcp');
    final stdio = transport == AuthoringTransport.mcp;
    final process = await Process.start(
      stdio ? 'node' : dart,
      stdio
          ? [
              'dist/src/transport_certification_bridge.js',
              'dist/src/index.js',
              project.path,
              cli,
              dart,
            ]
          : ['run', 'bin/pokemap_authoring.dart', '--root', project.path],
      workingDirectory: stdio ? mcp : cli,
    );
    final session = _WireSession(process, stdio);
    try {
      final opened = await session.call('open', {'projectRoot': project.path});
      return (
        close: () async {
          try {
            await session.call('close', {
              'workspaceHandle': opened['workspaceHandle'],
            });
          } finally {
            await session._close();
          }
        },
        apply: (step, identity) =>
            session._apply(project, opened, step, identity),
      );
    } on Object {
      await session._close();
      rethrow;
    }
  }

  Future<AppliedTransportStep> _apply(
    Directory project,
    Map<String, Object?> opened,
    AuthoringTransportStep step,
    String identity,
  ) async {
    final bound = await _boundParameters(project, step, (path, media) async {
      final staged = await call('stage_artifact', {
        'sourcePath': path,
        'declaredMediaType': media,
      });
      return ContentArtifactRef.fromJson({
        'digest': staged['digest'],
        'handle': staged['artifactHandle'],
        'mediaType': staged['mediaType'],
        'byteLength': staged['byteLength'],
      });
    });
    final parameters = bound.parameters;
    final workspace = opened['workspaceHandle']! as String;
    final handle = {'projectHandle': opened['projectHandle']};
    Map<String, Object?>? workshop;
    if (step.revisionScope == AuthoringTransportRevisionScope.auto) {
      try {
        workshop = await call('workshop_snapshot', {
          ...handle,
          'actionId': step.actionId,
          'parameters': parameters,
          'includeDocuments': false,
        });
      } on _WireFailure catch (error) {
        if (!_unscopedCodes.contains(error.code)) rethrow;
      }
    }
    final snapshot =
        workshop ??
        await call('query', {
          ...handle,
          'request': AuthoringQueryRequest(
            resourceKind: 'project',
            operation: AuthoringQueryOperation.list,
            view: AuthoringQueryView.summary,
          ).toJson(),
        });
    final planned = await call('plan', {
      ...handle,
      'request': _request(
        step,
        identity,
        workspace,
        snapshot['snapshotRevision']! as String,
        parameters,
        workshop == null
            ? const {}
            : transportEvidenceObject(
                workshop['planExtensions'],
                'plan extensions',
              ),
      ).toJson(),
    });
    if (step.planOnly) {
      return (
        receipt: _receipt(planned),
        stagedArtifacts: bound.stagedArtifacts,
      );
    }
    final plan = {...handle, 'planId': planned['planId']};
    final confirmation = step.confirm
        ? (await call('confirm', plan))['confirmationToken']
        : null;
    final receipt = _receipt(
      await call('apply', {
        ...plan,
        'operationId': identity,
        if (confirmation != null) 'confirmationToken': confirmation,
      }),
    );
    return (receipt: receipt, stagedArtifacts: bound.stagedArtifacts);
  }

  Future<Map<String, Object?>> call(
    String command,
    Map<String, Object?> args,
  ) async {
    final id = 'transport-proof-${++sequence}';
    process.stdin.writeln(
      jsonEncode({'id': id, 'command': command, 'args': args}),
    );
    await process.stdin.flush();
    if (!await lines.moveNext().timeout(const Duration(minutes: 3))) {
      throw StateError('$command closed its protocol stream: ${await errors}');
    }
    final response = transportEvidenceObject(
      jsonDecode(lines.current),
      'response',
    );
    if (response[mcp ? 'id' : 'requestId'] != id) {
      throw FormatException('Unexpected $command response identity.');
    }
    if (mcp ? response['ok'] != true : response['status'] != 'success') {
      final error = transportEvidenceObject(response['error'], 'error');
      final details = error['details'];
      final code =
          error['domainCode'] ??
          (details is Map ? details['domainCode'] : null) ??
          error['code'];
      throw _WireFailure(code, '$command: $error');
    }
    return transportEvidenceObject(response['data'], 'response data');
  }

  Future<void> _close() async {
    await process.stdin.close();
    await lines.cancel();
    final status = await process.exitCode.timeout(
      const Duration(seconds: 8),
      onTimeout: () {
        process.kill();
        return process.exitCode;
      },
    );
    if (status != 0)
      throw StateError('Transport exited $status: ${await errors}');
  }
}

final class _WireFailure implements Exception {
  const _WireFailure(this.code, this.message);

  final Object? code;
  final String message;

  @override
  String toString() => message;
}
