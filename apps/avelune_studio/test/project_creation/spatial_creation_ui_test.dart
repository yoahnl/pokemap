import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/project_creation_workspace_fixture.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;

void main() {
  testWidgets(
    'wizard chooses exclusively 3D and creates a real empty spatial project',
    (tester) async {
      final parent = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('spatial-creation-ui-'),
      ))!;
      final fixture = ProjectCreationWorkspaceFixture(
        tester,
        parent,
        File('${parent.path}/unused.avelunegame'),
      );
      addTearDown(() async {
        await fixture.dispose();
        await tester.runAsync(() => parent.delete(recursive: true));
      });
      await fixture.mount(
        createdWorkspaceBuilder: (session, close) => Text(session.name),
      );
      await tester.tap(find.text('Nouveau projet'));
      await pumpIo(tester, frames: 4);
      await tester.enterText(
        find.widgetWithText(TextField, 'Nom du projet'),
        'Mon monde 3D',
      );
      await fixture.next();
      await tester.tap(find.byKey(const ValueKey('creation-dimension-threeD')));
      await pumpIo(tester, frames: 4);
      expect(find.text('Petit projet jouable'), findsNothing);
      expect(find.text('Projet 3D vide'), findsOneWidget);
      await fixture.next();
      expect(find.byKey(const ValueKey('creation-grid-32')), findsNothing);
      await tester.enterText(
        find.widgetWithText(TextField, 'Largeur en cases · X'),
        '16',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Profondeur en cases · Z'),
        '12',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Inclinaison en degrés'),
        '60',
      );
      await fixture.next();
      await tester.tap(find.byKey(const ValueKey('creation-choose-parent')));
      await pumpIo(tester, frames: 8);
      await tester.tap(find.byKey(const ValueKey('create-project-confirm')));
      for (var i = 0; i < 100 && fixture.session.state.project == null; i++) {
        await pumpIo(tester, frames: 2);
      }
      final project = fixture.session.state.project;
      expect(project, isNotNull);
      final manifest = (await tester.runAsync(
        () async => ProjectManifest.fromJson(
          jsonDecode(
                await File(
                  '${project!.directoryPath}/project.json',
                ).readAsString(),
              )
              as Map<String, dynamic>,
        ),
      ))!;
      expect(manifest.settings.dimension, ProjectDimension.threeD);
      expect(manifest.settings.spatialCamera!.pitchDegrees, 60);
      expect(manifest.settings.defaultMapWidth, 16);
      expect(manifest.maps, hasLength(1));
      expect(tester.takeException(), isNull);
    },
  );
}
