import 'package:avelune_studio/presentation/features/narrative/narrative_story_pane.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_action_card.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/m2_ui_fixture.dart';
import 'support/ui05_narrative_fixture.dart';

void main() {
  testWidgets(
    'retired scene creation and text deletion cannot mutate an owner draft',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(
        () => Ui05NarrativeFixture.create(tester),
      ))!;
      addTearDown(fixture.dispose);
      await tester.pumpWidget(fixture.app(tester, withOwners: true));
      await pumpIo(tester);
      await tester.tap(
        find.descendant(
          of: find.byType(StudioPrimaryNavigation),
          matching: find.byTooltip('Histoire'),
        ),
      );
      await tester.pumpAndSettle();
      final overview = tester.widget<NarrativeStoryPane>(
        find.byType(NarrativeStoryPane),
      );
      final owner = overview.sceneOwner!;
      final recorded = await tester.runAsync(fixture.diskSnapshot);
      for (final createNew in [false, true]) {
        if (createNew) {
          expect(owner.create('Autre scène'), isNotNull);
        } else {
          expect(owner.open(owner.scenes.first.id), isTrue);
        }
        final session = owner.active!;
        final original = session.current;
        final history = session.undoCount;
        final dirty = session.dirty;
        final count = owner.scenes.length;
        await tester.pumpAndSettle();
        final create = find.widgetWithText(StudioActionCard, 'Nouvelle scène');
        await tester.ensureVisible(create);
        expect(tester.widget<StudioActionCard>(create).onPressed, isNull);
        expect(overview.onScenes, isNull);
        expect(overview.onOpenScene, isNull);
        await tester.tap(create);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
        final search = find.widgetWithText(
          TextField,
          'Rechercher dans Histoire',
        );
        await tester.enterText(search, 'Un nom');
        await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
        await tester.pump();
        expect(owner.active, same(session));
        expect(session.current, same(original));
        expect(session.current.graph.edges, original.graph.edges);
        expect(session.undoCount, history);
        expect(session.dirty, dirty);
        expect(owner.scenes, hasLength(count));
        expect(await tester.runAsync(fixture.diskSnapshot), recorded);
        await tester.enterText(search, '');
        await tester.pumpAndSettle();
      }
      expect(fixture.port.publications, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
