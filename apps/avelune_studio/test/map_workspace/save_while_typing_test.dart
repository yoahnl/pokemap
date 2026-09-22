import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_commit_field.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart' show writeExampleProject;
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/map_workspace_fixture.dart' show WorkspaceTestVisuals;

const departure = 'jardin';

void main() {
  late Directory directory;
  late ProjectSession session;
  late MapWorkspaceController controller;

  setUp(() async {
    final temporary = await Directory.systemTemp.createTemp('avelune_save_');
    directory = Directory(await temporary.resolveSymbolicLinks());
    await writeExampleProject(directory);
    session = ProjectSession(
      sessionId: directory.path,
      name: 'Sauvegarde pendant la saisie',
      directoryPath: directory.path,
    );
  });
  tearDown(() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  Finder field(String label) => find.byWidgetPredicate(
    (widget) => widget is StudioCommitField && widget.label == label,
  );

  /// Opens the real workspace screen on the temporary project and selects a
  /// sign, leaving the caret inside its title field.
  Future<MapEntity> openTypingOnSign(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    controller = MapWorkspaceController(session, LocalMapWorkspaceAdapter());
    late MapEntity sign;
    await tester.runAsync(() async {
      await controller.initialize();
      await controller.activate(
        controller.project!.maps.firstWhere((entry) => entry.id == departure),
      );
      sign = MapEntityEditingCommands(
        controller.active!,
        controller.project!,
      ).place(MapEntityKind.sign, const GridPos(x: 5, y: 5));
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: MapWorkspaceScreen(
          controller: controller,
          loadVisuals: (_, _) async => WorkspaceTestVisuals(),
          runtimeBuilder: (entry, revision, close) => const SizedBox(),
          onClose: () async {},
          registerExitGuard: (_) {},
        ),
      ),
    );
    await pumpIo(tester, frames: 10);

    final canvas = tester.getTopLeft(find.byKey(const ValueKey('map-canvas')));
    final size = controller.project!.settings;
    final tile = size.tileWidth * size.displayScale;
    await tester.tapAt(canvas + Offset(5 * tile + 4, 5 * tile + 4));
    await pumpIo(tester, frames: 10);
    expect(
      field('Titre'),
      findsOneWidget,
      reason: 'clicking the sign opens its inspector, like for an author',
    );

    await tester.enterText(field('Titre'), 'Quai numéro 3');
    await pumpIo(tester, frames: 10);
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>(),
      isNotNull,
      reason: 'the caret is still inside the field when the save is asked',
    );
    return sign;
  }

  /// Waits for the write the command started, without awaiting it from the
  /// test: the user command owns it.
  Future<void> settleSave(WidgetTester tester) async {
    for (var i = 0; i < 240 && controller.active!.dirty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(
      controller.active!.dirty,
      isFalse,
      reason: 'the document really reached the disk: ${controller.error}',
    );
  }

  Future<String?> savedTitle(WidgetTester tester, String entityId) async {
    String? title;
    await tester.runAsync(() async {
      final reopened = MapWorkspaceController(
        session,
        LocalMapWorkspaceAdapter(),
      );
      await reopened.initialize();
      await reopened.activate(
        reopened.project!.maps.firstWhere((entry) => entry.id == departure),
      );
      title = reopened.active!.current.entities
          .where((item) => item.id == entityId)
          .firstOrNull
          ?.sign
          ?.title;
      reopened.dispose();
    });
    return title;
  }

  testWidgets('the Save button applies the entry still being written', (
    tester,
  ) async {
    final sign = await openTypingOnSign(tester);

    await tester.tap(find.byKey(const ValueKey('Enregistrer')));
    await settleSave(tester);

    expect(
      await savedTitle(tester, sign.id),
      'Quai numéro 3',
      reason: 'the entry reached the file, it was not lost on save',
    );
    controller.dispose();
  });

  testWidgets('the save shortcut works from inside a field', (tester) async {
    final sign = await openTypingOnSign(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await pumpIo(tester, frames: 10);
    await settleSave(tester);

    expect(
      await savedTitle(tester, sign.id),
      'Quai numéro 3',
      reason: 'the shortcut is no longer swallowed by the typing guard',
    );
    controller.dispose();
  });

  testWidgets('deleting is still refused while the author types', (
    tester,
  ) async {
    final sign = await openTypingOnSign(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await pumpIo(tester, frames: 10);

    expect(
      controller.active!.current.entities.where((e) => e.id == sign.id),
      isNotEmpty,
      reason: 'the typing guard still protects the destructive commands',
    );
    controller.dispose();
  });
}
