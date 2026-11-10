import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/project_creation/application/project_creation_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring_local.dart';

void main() {
  late Directory parent;
  late ProjectCreationController controller;
  setUp(() async {
    parent = await Directory.systemTemp.createTemp('creation-workflow-');
    controller = ProjectCreationController(const LocalProjectCreationService());
    controller.setName('Projet indépendant');
    controller.change(() {
      controller.template = ProjectCreationTemplate.empty;
      controller.parentPath = parent.path;
    });
  });
  tearDown(() async {
    controller.dispose();
    await parent.delete(recursive: true);
  });

  test(
    'parent selection blocks closure and a cancelled choice preserves the path',
    () async {
      final choice = Completer<String?>();
      final selecting = controller.chooseParent(() => choice.future);
      expect(controller.selecting, isTrue);
      expect(controller.canClose, isFalse);
      expect(await controller.create(), isNull);
      expect(parent.listSync(), isEmpty);
      choice.complete(null);
      await selecting;
      expect(controller.parentPath, parent.path);
      expect(controller.selecting, isFalse);
      expect(controller.canClose, isTrue);
      expect(parent.listSync(), isEmpty);
    },
  );

  test(
    'picker failure releases selection and retains the authored request',
    () async {
      await controller.chooseParent(
        () async => throw StateError('picker.failed'),
      );
      expect(controller.error, 'Le sélecteur de dossier est indisponible.');
      expect(controller.parentPath, parent.path);
      expect(controller.selecting, isFalse);
      expect(controller.canClose, isTrue);
      expect(parent.listSync(), isEmpty);
    },
  );

  test(
    'failed opening preserves the receipt and original project for retry',
    () async {
      await controller.checkDestination();
      final receipt = await controller.create();
      expect(receipt, isNotNull);
      final file = File('${receipt!.projectPath}/project.json');
      final original = await file.readAsBytes();
      expect(await controller.openCreated((_) async => false), isFalse);
      expect(controller.openError, contains('Projet créé et conservé'));
      expect(controller.receipt, same(receipt));
      expect(await file.readAsBytes(), original);
      expect(
        await controller.openCreated(
          (_) async => throw StateError('open.failed'),
        ),
        isFalse,
      );
      expect(controller.receipt, same(receipt));
      expect(await file.readAsBytes(), original);
      expect(
        await controller.openCreated(
          (value) async => identical(value, receipt),
        ),
        isTrue,
      );
      expect(controller.openError, isNull);
      expect(controller.opening, isFalse);
      expect(await file.readAsBytes(), original);
    },
  );

  test(
    'pending receipt opening cannot be launched twice or closed midway',
    () async {
      final receipt = await controller.create();
      expect(receipt, isNotNull);
      final result = Completer<bool>();
      var calls = 0;
      final pending = controller.openCreated((_) {
        calls++;
        return result.future;
      });
      expect(controller.opening, isTrue);
      expect(controller.canClose, isFalse);
      expect(
        await controller.openCreated((_) async {
          calls++;
          return true;
        }),
        isFalse,
      );
      result.complete(true);
      expect(await pending, isTrue);
      expect(calls, 1);
      expect(controller.canClose, isTrue);
    },
  );

  test(
    'disposed creator ignores a late parent choice without notifications',
    () async {
      final choice = Completer<String?>();
      var notifications = 0;
      controller.addListener(() => notifications++);
      final pending = controller.chooseParent(() => choice.future);
      expect(notifications, 1);
      controller.dispose();
      choice.complete('/late-destination');
      await pending;
      expect(controller.parentPath, parent.path);
      expect(controller.destination, isNull);
      expect(notifications, 1);
      expect(parent.listSync(), isEmpty);
    },
  );
}
