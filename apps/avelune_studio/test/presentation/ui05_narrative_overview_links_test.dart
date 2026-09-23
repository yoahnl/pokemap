import 'package:avelune_studio/presentation/features/scenes/scene_builder_page.dart';
import 'package:avelune_studio/presentation/features/dialogues/dialogue_workspace_page.dart';
import 'package:avelune_studio/presentation/features/events/event_workspace_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_action_card.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/capture_m3_widget.dart';
import '../support/m2_ui_fixture.dart';
import '../support/ui05_narrative_fixture.dart';

void main() {
  testWidgets(
    'scene draft remains with its owner after returning to overview',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(
        () => Ui05NarrativeFixture.create(tester),
      ))!;
      addTearDown(fixture.dispose);
      final before = await tester.runAsync(fixture.diskSnapshot);
      await tester.pumpWidget(fixture.app(tester, withOwners: true));
      await pumpIo(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(StudioPrimaryNavigation),
          matching: find.byTooltip('Histoire'),
        ),
      );
      await tester.pumpAndSettle();
      final scene = fixture.controller.project!.scenes.first;
      await tester.tap(find.widgetWithText(StudioActionCard, scene.name).first);
      await tester.pumpAndSettle();
      final builder = tester.widget<SceneBuilderPage>(
        find.byType(SceneBuilderPage),
      );
      final session = builder.controller.active!;
      expect(session.current.id, scene.id);
      expect(session.rename('Un brouillon de scène'), isTrue);
      final current = session.current;
      await tester.pumpAndSettle();
      await tester.tap(
        find
            .descendant(
              of: find.byType(SceneBuilderPage),
              matching: find.text('Histoire'),
            )
            .last,
      );
      await tester.pumpAndSettle();
      expect(find.text('Un brouillon de scène'), findsOneWidget);
      await captureM3Widget(
        tester,
        fixture.captureKey,
        'ui05-05-brouillon-scene',
      );
      await tester.tap(
        find.widgetWithText(StudioActionCard, 'Un brouillon de scène'),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SceneBuilderPage>(find.byType(SceneBuilderPage))
            .controller
            .active,
        same(session),
      );
      expect(session.current, same(current));
      expect(session.dirty, isTrue);
      expect(fixture.port.publications, 0);
      expect(await tester.runAsync(fixture.diskSnapshot), before);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('search opens exact dialogue and event documents', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = (await tester.runAsync(
      () => Ui05NarrativeFixture.create(tester),
    ))!;
    addTearDown(fixture.dispose);
    final before = await tester.runAsync(fixture.diskSnapshot);
    await tester.pumpWidget(fixture.app(tester, withOwners: true));
    await pumpIo(tester);
    await tester.tap(
      find.descendant(
        of: find.byType(StudioPrimaryNavigation),
        matching: find.byTooltip('Histoire'),
      ),
    );
    await tester.pumpAndSettle();
    final dialogue = fixture.controller.project!.dialogues.first;
    var search = find.widgetWithText(TextField, 'Rechercher dans Histoire');
    await tester.enterText(search, dialogue.name);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('overview-result-Dialogue-${dialogue.id}')),
    );
    await pumpIo(tester);
    expect(
      tester
          .widget<DialogueWorkspacePage>(find.byType(DialogueWorkspacePage))
          .controller
          .activeId,
      dialogue.id,
    );
    await tester.tap(find.text('Retour à Histoire'));
    await tester.pumpAndSettle();
    search = find.widgetWithText(TextField, 'Rechercher dans Histoire');
    expect(tester.widget<TextField>(search).controller!.text, dialogue.name);

    final event = fixture.controller.project!.eventRegistry!.records.first;
    final eventName = event.definitionOrNull?.name ?? event.draftOrNull!.name;
    await tester.enterText(search, eventName);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('overview-result-Événement-${event.id}')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<EventWorkspacePage>(find.byType(EventWorkspacePage))
          .controller
          .activeId,
      event.id,
    );
    await tester.tap(find.widgetWithText(StudioButton, 'Retour').first);
    await tester.pumpAndSettle();
    expect(find.text('Donnez vie à votre histoire'), findsOneWidget);
    expect(fixture.port.publications, 0);
    expect(await tester.runAsync(fixture.diskSnapshot), before);
    expect(tester.takeException(), isNull);
  });
}
