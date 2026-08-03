import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor_updates/infrastructure/method_channel_editor_update_link_opener.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('map_editor/test_update_links');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('opens only trusted GitHub HTTPS links through the desktop bridge',
      () async {
    final calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    const opener = MethodChannelEditorUpdateLinkOpener(channel: channel);

    expect(
      await opener.open(
        Uri.parse(
          'https://github.com/yoahnl/pokemap/releases/tag/pokemap-v0.3.1',
        ),
      ),
      isTrue,
    );
    expect(calls.single.method, 'openExternalUri');
    expect(calls.single.arguments, {
      'uri': 'https://github.com/yoahnl/pokemap/releases/tag/pokemap-v0.3.1',
    });

    expect(
      await opener.open(Uri.parse('https://example.com/not-pokemap')),
      isFalse,
    );
    expect(calls, hasLength(1));
  });
}
