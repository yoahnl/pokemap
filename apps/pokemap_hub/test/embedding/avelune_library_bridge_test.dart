import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/avelune_embedded_runtime.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.avelune.runtime/library');
  const codec = StandardMethodCodec();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late AveluneLibraryBridge bridge;
  late Directory root;
  late int rootReads;
  late List<String> nativeNotifications;
  late Future<void> Function() stopPlayer;

  Future<Object?> invoke(String method, [Object? arguments]) {
    final result = Completer<Object?>();
    messenger.handlePlatformMessage(
      channel.name,
      codec.encodeMethodCall(MethodCall(method, arguments)),
      (data) {
        try {
          if (data == null) throw MissingPluginException();
          result.complete(codec.decodeEnvelope(data));
        } on Object catch (error) {
          result.completeError(error);
        }
      },
    );
    return result.future;
  }

  setUp(() async {
    root = await Directory.systemTemp.createTemp('avelune-embedded-bridge-');
    rootReads = 0;
    nativeNotifications = [];
    stopPlayer = () async {};
    messenger.setMockMethodCallHandler(channel, (call) async {
      nativeNotifications.add(call.method);
      return null;
    });
    bridge = AveluneLibraryBridge(
      stopPlayer: () => stopPlayer(),
      supportRootResolver: () async {
        rootReads++;
        return root;
      },
    );
    bridge.attach();
    await Future<void>.delayed(Duration.zero);
  });

  tearDown(() async {
    bridge.detach();
    messenger.setMockMethodCallHandler(channel, null);
    await root.delete(recursive: true);
  });

  test('notifies the shell only after the library handler is attached', () {
    expect(nativeNotifications, ['runtimeReady']);
  });

  test(
    'loads the canonical empty library once across repeated calls',
    () async {
      expect(await invoke('listGames'), isEmpty);
      expect(await invoke('listGames'), isEmpty);
      expect(rootReads, 1);
    },
  );

  test('reports a missing game without creating a player session', () async {
    await expectLater(
      invoke('playGame', {'gameId': 'missing'}),
      throwsA(
        isA<PlatformException>().having(
          (e) => e.code,
          'code',
          'gameNotInstalled',
        ),
      ),
    );
    expect(bridge.playing.value, isNull);
  });

  test('rejects malformed commands before loading storage', () async {
    for (final method in ['playGame', 'installGame', 'uninstallGame']) {
      await expectLater(
        invoke(method),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.code,
            'code',
            'invalidArguments',
          ),
        ),
      );
    }
    expect(rootReads, 0);
  });

  test('unknown methods do not initialize the runtime library', () async {
    await expectLater(
      invoke('unknown'),
      throwsA(isA<MissingPluginException>()),
    );
    expect(rootReads, 0);
  });

  test('stopping an idle session does not load storage', () async {
    expect(await invoke('stopGame'), isNull);
    expect(rootReads, 0);
  });

  test('acknowledges stop only after player resources close', () async {
    final stopped = Completer<void>();
    stopPlayer = () => stopped.future;
    var acknowledged = false;
    final response = invoke('stopGame').then((_) => acknowledged = true);
    await Future<void>.delayed(Duration.zero);
    expect(acknowledged, isFalse);
    stopped.complete();
    await response;
    expect(acknowledged, isTrue);
    expect(rootReads, 0);
  });

  test('failed stop remains an error and may be retried', () async {
    stopPlayer = () async => throw StateError('stop failed');
    await expectLater(invoke('stopGame'), throwsA(isA<PlatformException>()));
    stopPlayer = () async {};
    expect(await invoke('stopGame'), isNull);
  });
}
