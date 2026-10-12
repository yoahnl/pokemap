import 'package:avelune_converter/vision_desktop_services.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.avelune.converter/vision_secret');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final vault = ConverterKeychainVault(channel: channel);
  var calls = 0;
  String? stored;

  setUp(() {
    calls = 0;
    stored = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls++;
      switch (call.method) {
        case 'read':
          return stored;
        case 'write':
          stored = (call.arguments as Map)['secret'] as String;
          return null;
        case 'delete':
          stored = null;
          return null;
        default:
          throw MissingPluginException();
      }
    });
  });

  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'the vault has no channel activity until explicitly requested',
    () async {
      expect(calls, 0);
      expect(await vault.read(), isNull);
      await vault.write('ac11-public-dummy-token');
      expect(await vault.read(), 'ac11-public-dummy-token');
      await vault.delete();
      expect(await vault.read(), isNull);
      expect(calls, 5);
    },
  );

  test('invalid secrets never enter the native channel', () async {
    for (final secret in ['', ' token', 'token ', 'token\n', 'x' * 4097]) {
      await expectLater(vault.write(secret), throwsArgumentError);
    }
    expect(calls, 0);
  });

  test('platform failures cannot disclose details from a secret', () async {
    const token = 'ac11-public-dummy-token';
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
        code: 'native-error-$token',
        message: 'Authorization: Bearer $token',
        details: {'secret': token},
      );
    });
    for (final action in [vault.read, () => vault.write(token), vault.delete]) {
      try {
        await action();
        fail('The native error must be propagated without its payload.');
      } catch (error) {
        expect(error, isA<ConverterKeychainFailure>());
        expect(error.toString(), isNot(contains(token)));
        expect(error.toString(), isNot(contains('Authorization')));
      }
    }
  });
}
