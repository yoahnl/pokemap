import 'dart:io';
import 'package:avelune_studio/presentation/features/project_creation/project_creation_dialog.dart';
import 'package:avelune_studio/presentation/features/project_creation/project_creation_steps.dart';
import 'package:avelune_studio/presentation/features/home/studio_home_projects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/project_creation_workspace_fixture.dart';
import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/m2_ui_fixture.dart' show pumpIo;

void main() {
  for (final size in [
    const Size(1536, 960),
    const Size(1280, 800),
    const Size(1024, 640),
  ]) {
    for (final scale in [1.0, if (size.width == 1024) 1.5]) {
      testWidgets(
        'creator adapts to $size text $scale and preserves the five steps',
        (tester) async {
          final parent = (await tester.runAsync(() async {
            await loadDesktopCaptureFonts();
            return Directory.systemTemp.createTemp('creator-ui-');
          }))!;
          final fixture = ProjectCreationWorkspaceFixture(
            tester,
            parent,
            File('${parent.path}/demo.avelunegame'),
          );
          addTearDown(() async {
            await fixture.dispose();
            await tester.runAsync(() => parent.delete(recursive: true));
          });
          final key = GlobalKey();
          await fixture.mount(size: size, textScale: scale, captureKey: key);
          final label = '${size.width.toInt()}-${size.height.toInt()}-$scale';
          await captureM3Widget(tester, key, 'home-$label');
          final button = find.descendant(
            of: find.byType(StudioHomeRecentProjects),
            matching: find.byKey(const ValueKey('home-new-project')),
          );
          if (size.width == 1024) {
            await tester.scrollUntilVisible(
              button,
              180,
              scrollable: find
                  .descendant(
                    of: find.byKey(const ValueKey('home-local-content-scroll')),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
          }
          expect(button, findsOneWidget);
          await Scrollable.ensureVisible(
            tester.element(button),
            alignment: 0.4,
          );
          await tester.pumpAndSettle();
          await tester.tap(button);
          await pumpIo(tester, frames: 8);
          await tester.pumpAndSettle();
          expect(find.byType(ProjectCreationDialog), findsOneWidget);
          await tester.enterText(
            find.widgetWithText(TextField, 'Nom du projet'),
            'Mon aventure',
          );
          await tester.enterText(
            find.widgetWithText(TextField, 'Nom du dossier'),
            'mon-dossier',
          );
          await tester.enterText(
            find.widgetWithText(TextField, 'Nom du projet'),
            'Mon aventure finale',
          );
          expect(find.text('mon-dossier'), findsOneWidget);
          await tester.pumpAndSettle();
          await captureM3Widget(tester, key, 'information-$label');
          await fixture.next();
          await tester.pumpAndSettle();
          await captureM3Widget(tester, key, 'model-$label');
          await tester.tap(find.text('Projet vide'));
          await fixture.next();
          await tester.tap(find.byKey(const ValueKey('creation-grid-48')));
          await pumpIo(tester, frames: 6);
          await tester.pumpAndSettle();
          await captureM3Widget(tester, key, 'settings-$label');
          await fixture.next();
          await tester.tap(
            find.byKey(const ValueKey('creation-choose-parent')),
          );
          await pumpIo(tester, frames: 8);
          await tester.pumpAndSettle();
          await captureM3Widget(tester, key, 'destination-$label');
          expect(
            find.descendant(
              of: find.byType(ProjectCreationSteps),
              matching: find.byType(SelectableText),
            ),
            findsNothing,
          );
          expect(
            find.descendant(
              of: find.byType(ProjectCreationSteps),
              matching: find.byType(SelectionArea),
            ),
            findsNWidgets(2),
          );
          expect(
            find.byKey(const ValueKey('create-project-confirm')).hitTestable(),
            findsOneWidget,
          );
          await tester.tap(find.text('Précédent'));
          await pumpIo(tester, frames: 4);
          expect(find.textContaining('960 × 720 px'), findsOneWidget);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await pumpIo(tester, frames: 4);
          await tester.pumpAndSettle();
          expect(find.byType(ProjectCreationDialog), findsNothing);
          expect(parent.listSync(), isEmpty);
          expect(fixture.session.state.project, isNull);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
