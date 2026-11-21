import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('client subscribes to SSE and handles every terminal event', () {
    final source = _asset('app.js');

    expect(source, contains('new EventSource'));
    expect(source, contains("'run.finished'"));
    expect(source, contains("'worker.failed'"));
    expect(source, contains("'assertion.failed'"));
    expect(source, contains('X-PokeMap-Eval-Token'));
  });

  test('client never renders API text through innerHTML', () {
    final source = _asset('app.js');

    expect(source, isNot(contains('.innerHTML =')));
    expect(source, contains('.textContent ='));
    expect(source, contains('document.createElement'));
  });

  test('client wires controls and inspector tabs to stable contracts', () {
    final source = _asset('app.js');

    for (final action in <String>['step', 'pause', 'resume', 'cancel']) {
      expect(source, contains('/$action'));
    }
    for (final tab in <String>['diff', 'state', 'trace', 'proof']) {
      expect(source, contains("'$tab'"));
    }
    expect(source, contains('event.sequence'));
    expect(source, contains('selectedTab = \'diff\''));
    expect(source, contains('selectedTarget'));
    expect(source, contains("api('/api/capabilities')"));
    expect(source, contains('eventsFromReceipt'));
    expect(source, contains('receipt.stepResults'));
    expect(source, contains('infrastructure_failure'));
    expect(
      source,
      contains(
        'Le worker headless a interrompu l’exécution avant la première étape.',
      ),
    );
    expect(source, contains("setRunnerStatus('Worker en échec', 'failed')"));
  });
}

String _asset(String name) {
  return File(
    p.join(
      Directory.current.path,
      'tool',
      'assets',
      'pokemap_eval_web',
      name,
    ),
  ).readAsStringSync();
}
