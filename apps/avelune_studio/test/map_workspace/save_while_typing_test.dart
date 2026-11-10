import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_shortcuts.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_catalog_fixture.dart';

void main() {
  late MapCatalogFixture fixture;
  late MapWorkspaceController controller;
  late WorkspaceWorkflow workflow;
  late MapEntity sign;
  late String mapId;
  late FocusNode canvas;
  Future<bool?>? saving;

  Future<void> openTypingOnSign(WidgetTester tester) async {
    fixture = (await tester.runAsync(() async {
      final parent = Directory(
        '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109',
      );
      await parent.create(recursive: true);
      final fixture = await MapCatalogFixture.create(parent: parent);
      await fixture.controller.activate(
        fixture.controller.project!.maps.firstWhere(
          (entry) => entry.id == 'jardin',
        ),
      );
      return fixture;
    }))!;
    controller = fixture.controller;
    addTearDown(() => tester.runAsync(fixture.dispose));
    final document = controller.active!;
    mapId = document.current.id;
    final commands = MapEntityEditingCommands(document, controller.project!);
    sign = commands.place(MapEntityKind.sign, const GridPos(x: 5, y: 5));
    final view = MapWorkspaceEditingState();
    view.select(document, MapSelectionFamily.marker, sign.id);
    canvas = FocusNode();
    addTearDown(canvas.dispose);
    saving = null;
    workflow = WorkspaceWorkflow(
      controller: controller,
      isActive: () => !controller.isDisposed,
      changed: () {},
      resources: () => null,
      narrative: () => null,
      confirmClose: () async => WorkspaceCloseChoice.cancel,
      flushFocus: () {
        FocusManager.instance.primaryFocus?.unfocus();
        FocusManager.instance.applyFocusChangesIfNeeded();
      },
      launchMap: (_, _) async {},
    );
    void save() => saving = tester.runAsync(workflow.saveForExport);
    await tester.pumpWidget(
      MaterialApp(
        home: CallbackShortcuts(
          bindings: mapEditingShortcuts(
            controller,
            view,
            (action) => action(),
            guardedWhileTyping: (action) => action(),
            onSave: save,
          ),
          child: Scaffold(
            body: Column(
              children: [
                TextField(
                  onChanged: (value) =>
                      commands.updateSign(sign.id, title: value),
                ),
                Focus(
                  focusNode: canvas,
                  child: const SizedBox(width: 100, height: 100),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Quai numéro 3');
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>(),
      isNotNull,
    );
    expect(document.dirty, isTrue);
  }

  Future<String?> savedTitle(WidgetTester tester) async {
    return tester.runAsync(() async {
      final reopened = MapWorkspaceController(fixture.session, fixture.adapter);
      try {
        await reopened.initialize();
        await reopened.activate(
          reopened.project!.maps.firstWhere((entry) => entry.id == mapId),
        );
        return reopened.active!.current.entities
            .firstWhere((entry) => entry.id == sign.id)
            .sign!
            .title;
      } finally {
        reopened.dispose();
      }
    });
  }

  testWidgets(
    'save workflow persists a canonical title draft while its field is focused',
    (tester) async {
      await openTypingOnSign(tester);
      expect(await tester.runAsync(workflow.saveForExport), isTrue);
      expect(controller.active!.dirty, isFalse);
      expect(await savedTitle(tester), 'Quai numéro 3');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'save shortcut reaches the workflow from inside an editable field',
    (tester) async {
      await openTypingOnSign(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      expect(saving, isNotNull);
      expect(await saving!, isTrue);
      expect(controller.active!.dirty, isFalse);
      expect(await savedTitle(tester), 'Quai numéro 3');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'delete stays local to typing and resumes on the unfocused editor',
    (tester) async {
      await openTypingOnSign(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(
        controller.active!.current.entities.where(
          (entry) => entry.id == sign.id,
        ),
        hasLength(1),
      );
      canvas.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(
        controller.active!.current.entities.where(
          (entry) => entry.id == sign.id,
        ),
        isEmpty,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
