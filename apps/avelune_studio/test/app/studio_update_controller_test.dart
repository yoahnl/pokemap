import 'package:avelune_studio/features/updates/studio_update_catalog.dart';
import 'package:avelune_studio/features/updates/studio_update_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late StudioUpdateController controller;
  late List<String> calls;
  late bool allowRestart;
  late bool failOpening;
  late int checks;
  final release = StudioUpdateRelease(
    version: '0.4.0',
    notesUri: Uri.parse('https://example.com/release'),
  );

  setUp(() {
    calls = [];
    checks = 0;
    allowRestart = true;
    failOpening = false;
    controller = StudioUpdateController(
      nativeUpdater: true,
      checkRelease: () async {
        checks++;
        return release;
      },
      openNativeUpdate: (operationId) async {
        calls.add('open:$operationId');
        if (failOpening) throw StateError('native.unavailable');
      },
      respondToRestart: (operationId, allowed) async {
        calls.add('respond:$operationId:$allowed');
      },
      openReleaseNotes: (uri) async {
        calls.add('notes:$uri');
        return true;
      },
      prepareForRestart: () async {
        calls.add('prepare');
        return allowRestart;
      },
      resumeAfterFailure: () async => calls.add('resume'),
      createOperationId: () => 'operation-1',
    );
  });

  tearDown(() => controller.dispose());

  test(
    'checks preserve release and installation remains active until event',
    () async {
      await controller.checkForUpdates();
      expect(checks, 1);
      expect(controller.release, same(release));
      await controller.openUpdate();
      expect(controller.opening, isTrue);
      expect(controller.operationId, 'operation-1');
      expect(calls, ['open:operation-1']);
      await controller.openUpdate();
      expect(calls, ['open:operation-1']);
    },
  );

  test('unrelated operation cannot stop MCP or acknowledge restart', () async {
    await controller.checkForUpdates();
    await controller.openUpdate();
    await controller.handleEvent({
      'operationId': 'another-operation',
      'kind': 'restartRequested',
    });
    expect(calls, ['open:operation-1']);
    expect(controller.opening, isTrue);
  });

  test('denied restart responds without accepting installation', () async {
    allowRestart = false;
    await controller.checkForUpdates();
    await controller.openUpdate();
    await controller.handleEvent({
      'operationId': 'operation-1',
      'kind': 'restartRequested',
    });
    expect(calls, ['open:operation-1', 'prepare', 'respond:operation-1:false']);
    expect(controller.opening, isFalse);
    expect(controller.operationId, isNull);
    expect(controller.message, 'Enregistrez le projet avant la mise à jour.');
  });

  test(
    'accepted restart awaits preparation before acknowledging native',
    () async {
      await controller.checkForUpdates();
      await controller.openUpdate();
      await controller.handleEvent({
        'operationId': 'operation-1',
        'kind': 'restartRequested',
      });
      expect(calls, [
        'open:operation-1',
        'prepare',
        'respond:operation-1:true',
      ]);
      expect(controller.opening, isTrue);
    },
  );

  for (final terminal in ['failed', 'cancelled', 'noUpdate']) {
    test(
      '$terminal resumes services without losing release or session owner',
      () async {
        await controller.checkForUpdates();
        await controller.openUpdate();
        await controller.handleEvent({
          'operationId': 'operation-1',
          'kind': terminal,
        });
        expect(calls, ['open:operation-1', 'resume']);
        expect(controller.release, same(release));
        expect(controller.opening, isFalse);
        expect(controller.operationId, isNull);
        expect(
          controller.message,
          terminal == 'failed' ? 'La mise à jour a échoué. Réessayez.' : null,
        );
      },
    );
  }

  test(
    'external updater opens release notes without preparing restart',
    () async {
      final external = StudioUpdateController(
        nativeUpdater: false,
        checkRelease: () async => release,
        openNativeUpdate: (_) async => fail('unexpected native updater'),
        respondToRestart: (_, _) async => fail('unexpected restart response'),
        openReleaseNotes: (uri) async {
          calls.add('notes:$uri');
          return true;
        },
        prepareForRestart: () async {
          fail('unexpected restart preparation');
        },
        resumeAfterFailure: () async => fail('unexpected service resume'),
      );
      addTearDown(external.dispose);
      await external.checkForUpdates();
      await external.openUpdate();
      expect(calls, ['notes:${release.notesUri}']);
      expect(external.opening, isFalse);
      expect(external.operationId, isNull);
      expect(external.message, isNull);
    },
  );

  test(
    'native launch failure releases operation so installation can retry',
    () async {
      failOpening = true;
      await controller.checkForUpdates();
      await controller.openUpdate();
      expect(controller.opening, isFalse);
      expect(controller.operationId, isNull);
      expect(controller.message, 'Impossible d’ouvrir la mise à jour.');
      failOpening = false;
      await controller.openUpdate();
      expect(controller.opening, isTrue);
      expect(calls, ['open:operation-1', 'open:operation-1']);
    },
  );
}
