import 'package:pokemap_loader/src/runtime_ios_project_picker.dart';
import 'package:pokemap_loader/src/runtime_project_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('playable_runtime_host/project_picker_test');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('returns selected when native iOS picker imports a project', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'pickProjectDirectory');
      return '/sandbox/my_project/project.json';
    });

    final result = await pickRuntimeProjectDirectoryOnIos(channel: channel);

    expect(result.outcome, RuntimeProjectPickOutcome.selected);
    expect(result.projectJsonPath, '/sandbox/my_project/project.json');
  });

  test('returns cancelled when native iOS picker is dismissed', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);

    final result = await pickRuntimeProjectDirectoryOnIos(channel: channel);

    expect(result.outcome, RuntimeProjectPickOutcome.cancelled);
  });

  test('maps invalid selection errors to a user-facing invalid result',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(
        code: 'invalid_selection',
        message: 'Le dossier sélectionné ne contient pas de project.json.',
      );
    });

    final result = await pickRuntimeProjectDirectoryOnIos(channel: channel);

    expect(result.outcome, RuntimeProjectPickOutcome.invalidSelection);
    expect(
      result.errorMessage,
      'Le dossier sélectionné ne contient pas de project.json.',
    );
  });
}
