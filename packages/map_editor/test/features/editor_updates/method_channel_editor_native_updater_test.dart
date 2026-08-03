import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_native_updater.dart';
import 'package:map_editor/src/features/editor_updates/domain/editor_update_models.dart';
import 'package:map_editor/src/features/editor_updates/infrastructure/method_channel_editor_native_updater.dart';
import 'package:pub_semver/pub_semver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('map_editor/test_updates');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('sends only the release contract needed by the native updater',
      () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    final updater = MethodChannelEditorNativeUpdater(
      channel: channel,
      isSupported: true,
      capabilities: EditorNativeUpdaterCapabilities.macosV1,
    );

    await updater.openUpdateFlow(
      operationId: 'operation-1',
      release: _release(),
    );
    await updater.setRestartReady(canRestart: true);
    await updater.respondToRestart(
      operationId: 'operation-1',
      canRestart: false,
    );

    expect(calls.map((call) => call.method), [
      'openUpdateFlow',
      'setRestartReady',
      'respondToRestart',
    ]);
    expect(calls.first.arguments, {
      'operationId': 'operation-1',
      'version': '0.3.1',
      'tag': 'pokemap-v0.3.1',
    });
    expect(calls[1].arguments, {'canRestart': true});
    expect(calls.last.arguments, {
      'operationId': 'operation-1',
      'canRestart': false,
    });

    await updater.dispose();
  });

  test('maps a safe native callback to a typed controller event', () async {
    final updater = MethodChannelEditorNativeUpdater(
      channel: channel,
      isSupported: true,
      capabilities: EditorNativeUpdaterCapabilities.windowsV1,
    );
    final event = updater.events.first;

    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('updateEvent', {
          'kind': 'restartRequested',
          'operationId': 'operation-2',
        }),
      ),
      (_) {},
    );

    expect((await event).kind, EditorNativeUpdateEventKind.restartRequested);
    await updater.dispose();
  });

  test('exposes native Help menu requests separately from install events',
      () async {
    final updater = MethodChannelEditorNativeUpdater(
      channel: channel,
      isSupported: true,
      capabilities: EditorNativeUpdaterCapabilities.macosV1,
    );
    final request = updater.manualCheckRequests.first;

    await messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('manualCheckRequested'),
      ),
      (_) {},
    );

    await request;
    await updater.dispose();
  });

  test('ignores malformed and unknown native callbacks', () async {
    final updater = MethodChannelEditorNativeUpdater(
      channel: channel,
      isSupported: true,
      capabilities: EditorNativeUpdaterCapabilities.windowsV1,
    );
    final events = <EditorNativeUpdateEvent>[];
    final subscription = updater.events.listen(events.add);

    for (final arguments in [
      {'kind': 'restartRequested'},
      {'kind': 'surprise', 'operationId': 'operation-3'},
      'not-a-map',
    ]) {
      await messenger.handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(
          MethodCall('updateEvent', arguments),
        ),
        (_) {},
      );
    }
    await pumpEventQueue();

    expect(events, isEmpty);
    await subscription.cancel();
    await updater.dispose();
  });
}

EditorUpdateRelease _release() {
  return EditorUpdateRelease(
    version: Version.parse('0.3.1'),
    tag: 'pokemap-v0.3.1',
    publishedAt: DateTime.utc(2026, 8, 3),
    releaseNotesUri: Uri.parse(
      'https://github.com/yoahnl/pokemap/releases/tag/pokemap-v0.3.1',
    ),
  );
}
