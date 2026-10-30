import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

void main() {
  test('discovery rejects every filesystem command before backend dispatch',
      () async {
    final api = _NoBackendApi();
    final worker = JsonlWorker(api: api, discoveryOnly: true);
    for (final command in [
      'open',
      'stage_artifact',
      'project_bootstrap_inspect',
      'project_native_prepare',
      'game_export'
    ]) {
      final response =
          AuthoringResult.fromJson(jsonDecode(await worker.processLine(
        jsonEncode(
            {'id': command, 'command': command, 'args': <String, Object?>{}}),
      )) as Map<String, dynamic>);
      expect(response.error?.code, AuthoringErrorCode.permissionDenied);
      expect(response.error?.details['domainCode'],
          'workspace.path_outside_allowed_roots');
    }
    expect(api.calls, 0);
    await worker.close();
  });
}

final class _NoBackendApi implements AuthoringReadApiPort {
  var calls = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('Discovery invoked a backend operation.');
  }
}
