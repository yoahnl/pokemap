import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
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
    'Vision rejects equal bytes moved to an earlier supplemental root',
    () async {
      if (!Platform.isMacOS) return;
      final sandbox = await Directory('/private/tmp')
          .createTemp('cv-vision-origins-');
      final roots = <Directory>[];
      for (final name in ['primary', 'first', 'second']) {
        roots.add(
          await Directory('${sandbox.path}/$name/Graphics/Pictures')
              .create(recursive: true),
        );
      }
      final selection = ConverterSourceSelection(
        rootPath: roots[0].parent.parent.path,
        supplementalRootPaths: [
          roots[1].parent.parent.path,
          roots[2].parent.parent.path,
        ],
        logicalProjectNamespace: ConverterId('vision-origins'),
      );
      final tree = await SupplementedSourceTree.open(
        selection.rootPath,
        supplementalRootPaths: selection.supplementalRootPaths,
      );
      try {
        final original = await File('${roots[2].path}/witness.png')
            .writeAsString('original bytes');
        final snapshot = await SourceScanner().scan(
          source: tree,
          logicalProjectNamespace: selection.logicalProjectNamespace,
        );
        final provenance = tree.sharedSourceFilesFor(snapshot);
        expect(
          await verifyConverterVisionSource(selection, snapshot, provenance),
          isTrue,
        );
        await original.copy('${roots[1].path}/witness.png');
        final changed = isA<ConverterWorkflowFailure>().having(
          (error) => error.code,
          'code',
          'workflow.source_provenance_changed',
        );
        await expectLater(
          verifyConverterVisionSource(selection, snapshot, provenance),
          throwsA(changed),
        );
        final files = ConverterVisionSourceFiles(
          selection,
          snapshot,
          provenance,
        );
        await expectLater(
          files.read(
            snapshot.entries
                .singleWhere(
                  (entry) => entry.relativePath.endsWith('witness.png'),
                )
                .fileId,
          ),
          throwsA(changed),
        );
      } finally {
        await tree.close();
        await sandbox.delete(recursive: true);
      }
    },
  );

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
