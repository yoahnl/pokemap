import 'dart:io';

import 'package:avelune_converter/desktop_services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('miguelruivo.flutter.plugins.filepicker');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late Directory root;
  late Directory plans;
  late File existingPlan;
  late String newPlanPath;
  String? fileSelection;
  String? directorySelection;
  final calls = <MethodCall>[];

  setUp(() async {
    final temporary = await Directory.systemTemp.createTemp(
      'converter-plan-picker-',
    );
    root = Directory(await temporary.resolveSymbolicLinks());
    plans = await Directory(path.join(root.path, 'plans')).create();
    existingPlan = await File(path.join(plans.path, 'existing.json'))
        .writeAsString('{"fixture":"unchanged"}\n');
    newPlanPath = path.join(plans.path, 'new.json');
    fileSelection = null;
    directorySelection = null;
    calls.clear();
    FilePickerMacOS.registerWith();
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      switch (call.method) {
        case 'saveFile':
          return fileSelection;
        case 'pickFiles':
          return fileSelection == null ? null : [fileSelection!];
        case 'getDirectoryPath':
          return directorySelection;
        default:
          throw MissingPluginException();
      }
    });
  });

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
    await root.delete(recursive: true);
  });

  for (final saving in [true, false]) {
    final operation = saving ? 'save' : 'load';
    final fileMethod = saving ? 'saveFile' : 'pickFiles';
    Future<String?> pick() => saving
        ? pickConverterPlanSavePath()
        : pickConverterPath(ConverterPathKind.planFile);

    test(
      '$operation selects the file before authorizing its exact parent',
      () async {
        fileSelection = saving ? newPlanPath : existingPlan.path;
        directorySelection = plans.path;

        expect(await pick(), fileSelection);
        expect(calls.map((call) => call.method), [
          fileMethod,
          'getDirectoryPath',
        ]);
        expect((calls.first.arguments as Map)['allowedExtensions'], ['json']);
        expect((calls.last.arguments as Map)['initialDirectory'], plans.path);
        expect(await File(newPlanPath).exists(), isFalse);
        expect(await existingPlan.readAsString(), '{"fixture":"unchanged"}\n');
      },
    );

    test('$operation file cancellation never asks for a directory', () async {
      directorySelection = plans.path;

      expect(await pick(), isNull);
      expect(calls.map((call) => call.method), [fileMethod]);
      expect(await File(newPlanPath).exists(), isFalse);
    });

    test('$operation parent cancellation discards the selected file', () async {
      fileSelection = saving ? newPlanPath : existingPlan.path;

      expect(await pick(), isNull);
      expect(calls.map((call) => call.method), [
        fileMethod,
        'getDirectoryPath',
      ]);
      expect(await File(newPlanPath).exists(), isFalse);
      expect(await existingPlan.readAsString(), '{"fixture":"unchanged"}\n');
    });

    test(
      '$operation refuses another directory without changing files',
      () async {
        final different = await Directory(path.join(root.path, 'different'))
            .create();
        fileSelection = saving ? newPlanPath : existingPlan.path;
        directorySelection = different.path;

        expect(await pick(), isNull);
        expect(calls.map((call) => call.method), [
          fileMethod,
          'getDirectoryPath',
        ]);
        expect(await different.list().toList(), isEmpty);
        expect(await File(newPlanPath).exists(), isFalse);
        expect(await existingPlan.readAsString(), '{"fixture":"unchanged"}\n');
      },
    );

    test(
      '$operation refuses an ancestor instead of broadening the grant',
      () async {
        fileSelection = saving ? newPlanPath : existingPlan.path;
        directorySelection = root.path;

        expect(await pick(), isNull);
        expect(await File(newPlanPath).exists(), isFalse);
      },
    );

    test('$operation refuses a descendant of the required parent', () async {
      final nested = await Directory(path.join(plans.path, 'nested')).create();
      fileSelection = saving ? newPlanPath : existingPlan.path;
      directorySelection = nested.path;

      expect(await pick(), isNull);
      expect(await nested.list().toList(), isEmpty);
    });

    test(
      '$operation accepts only the same canonical parent through an alias',
      () async {
        final alias = await Link(path.join(root.path, 'plans-alias'))
            .create(plans.path);
        fileSelection = path.join(
          alias.path,
          saving
              ? path.basename(newPlanPath)
              : path.basename(existingPlan.path),
        );
        directorySelection = plans.path;

        expect(await pick(), saving ? newPlanPath : existingPlan.path);
        expect((calls.last.arguments as Map)['initialDirectory'], alias.path);
        expect(await File(newPlanPath).exists(), isFalse);
        expect(await existingPlan.readAsString(), '{"fixture":"unchanged"}\n');
      },
    );

    test(
      '$operation accepts an alias of the exact authorized parent',
      () async {
        final alias = await Link(path.join(root.path, 'granted-alias'))
            .create(plans.path);
        fileSelection = saving ? newPlanPath : existingPlan.path;
        directorySelection = alias.path;

        expect(await pick(), fileSelection);
        expect(await File(newPlanPath).exists(), isFalse);
        expect(await existingPlan.readAsString(), '{"fixture":"unchanged"}\n');
      },
    );

    test(
      '$operation refuses a parent alias targeting the filesystem root',
      () async {
        final alias = await Link(path.join(root.path, 'root-alias'))
            .create('/');
        final rootPlan =
            '/converter-root-plan-${path.basename(root.path)}.json';
        fileSelection = path.join(alias.path, path.basename(rootPlan));
        directorySelection = '/';
        expect(await File(rootPlan).exists(), isFalse);

        expect(await pick(), isNull);
        expect(calls.map((call) => call.method), [
          fileMethod,
          'getDirectoryPath',
        ]);
        expect(await File(rootPlan).exists(), isFalse);
        expect(await existingPlan.readAsString(), '{"fixture":"unchanged"}\n');
      },
    );

    test(
      '$operation refuses a directory that vanished during selection',
      () async {
        final vanished = await Directory(path.join(root.path, 'vanished'))
            .create();
        fileSelection = saving ? newPlanPath : existingPlan.path;
        directorySelection = vanished.path;
        await vanished.delete();

        expect(await pick(), isNull);
        expect(await vanished.exists(), isFalse);
        expect(await File(newPlanPath).exists(), isFalse);
      },
    );
  }

  test(
    'save rejects a relative file selection before requesting access',
    () async {
      fileSelection = 'relative-plan.json';
      directorySelection = plans.path;

      expect(await pickConverterPlanSavePath(), isNull);
      expect(calls.map((call) => call.method), ['saveFile']);
    },
  );

  test('save rejects a relative directory selection', () async {
    fileSelection = newPlanPath;
    directorySelection = 'plans';

    expect(await pickConverterPlanSavePath(), isNull);
    expect(await File(newPlanPath).exists(), isFalse);
  });

  test('save never requests a filesystem-root grant', () async {
    fileSelection = '/new-plan.json';
    directorySelection = '/';

    expect(await pickConverterPlanSavePath(), isNull);
    expect(calls.map((call) => call.method), ['saveFile']);
  });

  for (final kind in [
    ConverterPathKind.sourceFolder,
    ConverterPathKind.destinationParent,
    ConverterPathKind.sourceProject,
  ]) {
    test('${kind.name} preserves its existing single-picker flow', () async {
      final isFile = kind == ConverterPathKind.sourceProject;
      fileSelection = existingPlan.path;
      directorySelection = plans.path;

      expect(
        await pickConverterPath(kind),
        isFile ? existingPlan.path : plans.path,
      );
      expect(calls.map((call) => call.method), [
        isFile ? 'pickFiles' : 'getDirectoryPath',
      ]);
    });
  }
}
