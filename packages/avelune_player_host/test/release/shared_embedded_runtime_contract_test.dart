import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native mobile hosts use the same embedded player entry', () {
    for (final host in ['Avelune iOS', 'avelune_android']) {
      final entry = File('../../apps/$host/flutter_runtime/lib/main.dart');
      expect(entry.existsSync(), isTrue, reason: host);
      expect(
        entry.readAsStringSync(),
        contains('package:avelune_player_host/avelune_embedded_runtime.dart'),
      );
      expect(entry.readAsStringSync(), contains('runAveluneEmbeddedRuntime('));
      expect(
        entry.readAsStringSync(),
        isNot(contains('class AveluneLibraryBridge')),
      );
    }
    final shared = File('lib/embedding/avelune_library_bridge.dart');
    expect(shared.existsSync(), isTrue);
    expect(shared.readAsStringSync(), contains('InstallGamePackageUseCase'));
  });
}
