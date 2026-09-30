import 'dart:io';
import 'package:avelune_studio/presentation/features/home/studio_home_projects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/project_creation_workspace_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;

void main() {
  testWidgets('new project is an active action inside existing recents', (
    tester,
  ) async {
    final parent = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('creation-entry-'),
    ))!;
    final fixture = ProjectCreationWorkspaceFixture(
      tester,
      parent,
      File('${parent.path}/demo.avelunegame'),
    );
    addTearDown(() async {
      await fixture.dispose();
      await tester.runAsync(() => parent.delete(recursive: true));
    });
    await fixture.mount();
    final action = find.descendant(
      of: find.byType(StudioHomeRecentProjects),
      matching: find.byKey(const ValueKey('home-new-project')),
    );
    expect(action, findsOneWidget);
    await tester.tap(action);
    await pumpIo(tester, frames: 8);
    await tester.pumpAndSettle();
    expect(find.text('Informations du projet'), findsOneWidget);
  });
}
