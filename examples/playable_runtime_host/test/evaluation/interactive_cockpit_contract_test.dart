import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pokemap_loader/src/evaluation/contracts/evaluation_policy.dart';
import 'package:pokemap_loader/src/evaluation/web/evaluation_web_server.dart';

void main() {
  test('capabilities advertise interactive only when available', () async {
    final unavailable = await _capabilities(
      const <EvaluationTarget>{EvaluationTarget.headless},
    );
    final available = await _capabilities(
      const <EvaluationTarget>{
        EvaluationTarget.headless,
        EvaluationTarget.interactive,
      },
    );

    expect(unavailable['targets'], <String>['headless']);
    expect(available['targets'], <String>['headless', 'interactive']);
    expect(
      available['interactive'],
      <String, Object?>{
        'platform': 'macos',
        'frameMetrics': true,
        'capture': true,
        'playbackRates': <double>[0.5, 1, 2],
      },
    );
  });

  test('client keeps policy separate from target and playback rate', () {
    final root = Directory.current.path;
    final source = File(
      p.join(root, 'tool', 'assets', 'pokemap_eval_web', 'app.js'),
    ).readAsStringSync();
    final markup = File(
      p.join(root, 'tool', 'assets', 'pokemap_eval_web', 'index.html'),
    ).readAsStringSync();

    expect(source, contains('selectedTarget'));
    expect(source, contains('scenario.policy'));
    expect(source, isNot(contains('policy = selectedTarget')));
    expect(source, contains("api('/api/capabilities')"));
    expect(source, contains('playbackRate'));
    expect(markup, contains('Vitesse de lecture'));
    expect(markup, contains('Fenêtre visible'));
  });
}

Future<Map<String, Object?>> _capabilities(
  Set<EvaluationTarget> targets,
) async {
  final root = await Directory.systemTemp.createTemp(
    'pokemap-eval-capabilities-',
  );
  try {
    final assets = Directory(p.join(root.path, 'assets'));
    await assets.create();
    await File(p.join(assets.path, 'index.html')).writeAsString(
      '<meta name="pokemap-eval-token" '
      'content="__POKEMAP_EVAL_TOKEN__">',
    );
    await File(p.join(assets.path, 'app.css')).writeAsString('');
    await File(p.join(assets.path, 'app.js')).writeAsString('');
    final server = await EvaluationWebServer.start(
      port: 0,
      assetsRoot: assets,
      orchestrator: _CapabilityOrchestrator(targets),
    );
    try {
      final client = HttpClient();
      try {
        final request = await client.getUrl(
          server.uri.resolve('/api/capabilities'),
        );
        final response = await request.close();
        expect(response.statusCode, HttpStatus.ok);
        return Map<String, Object?>.from(
          jsonDecode(await utf8.decoder.bind(response).join()) as Map,
        );
      } finally {
        client.close(force: true);
      }
    } finally {
      await server.close();
    }
  } finally {
    await root.delete(recursive: true);
  }
}

final class _CapabilityOrchestrator extends EvaluationWebOrchestrator {
  _CapabilityOrchestrator(this.availableTargets);

  @override
  final Set<EvaluationTarget> availableTargets;

  @override
  Future<void> close() async {}
}
