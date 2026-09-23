import 'dart:io';

import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:avelune_studio/presentation/features/narrative/narrative_story_pane.dart';
import 'package:avelune_studio/presentation/features/stories/story_progression_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_action_card.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/capture_m3_widget.dart';
import '../support/m2_ui_fixture.dart';
import '../support/ui05_narrative_fixture.dart';

void main() {
  testWidgets('overview opens the exact story and step without publishing', (
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
    await tester.runAsync(() => seedTrainArtwork(fixture));
    expect(
      await tester.runAsync(
        () => fixture.port.readArtwork(NarrativeArtworkKind.hero),
      ),
      isNotNull,
    );
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
    await tester.runAsync(
      () => precacheImage(
        const AssetImage('assets/home/hero_landscape.png'),
        tester.element(find.byType(NarrativeStoryPane)),
      ),
    );
    await pumpIo(tester);
    expect(
      tester
          .widget<Image>(
            find.descendant(
              of: find.byKey(const ValueKey('narrative-hero-artwork')),
              matching: find.byType(Image),
            ),
          )
          .image,
      isA<MemoryImage>(),
    );
    expect(find.text('Donnez vie à votre histoire'), findsOneWidget);
    expect(find.text('Histoires du projet · 2'), findsOneWidget);
    expect(find.text('Contenu du projet'), findsOneWidget);
    expect(fixture.port.publications, 0);
    await captureM3Widget(tester, fixture.captureKey, 'ui05-finition-1536');

    await tester.tap(
      find.widgetWithText(StudioActionCard, 'Nouvelle histoire'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(StudioButton, 'Annuler'));
    await tester.pumpAndSettle();
    expect(find.text('Donnez vie à votre histoire'), findsOneWidget);
    await tester.tap(
      find.widgetWithText(StudioActionCard, 'Nouvelle histoire'),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'Une histoire en cours',
    );
    await tester.pump();
    expect(
      tester
          .widget<StudioButton>(find.widgetWithText(StudioButton, 'Créer'))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.widgetWithText(StudioButton, 'Créer'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(StoryProgressionPage), findsOneWidget);
    await tester.tap(find.widgetWithText(StudioButton, 'Histoire').last);
    await tester.pumpAndSettle();
    expect(find.text('Une histoire en cours'), findsWidgets);

    await tester.tap(
      find.byKey(const ValueKey('overview-story-garden-traces')),
    );
    await tester.pumpAndSettle();
    final progression = tester.widget<StoryProgressionPage>(
      find.byType(StoryProgressionPage),
    );
    expect(progression.controller.activeId, 'garden-traces');
    await tester.tap(find.widgetWithText(StudioButton, 'Histoire').last);
    await tester.pumpAndSettle();
    expect(find.text('Donnez vie à votre histoire'), findsOneWidget);

    final step = find.byKey(const ValueKey('overview-step-departure-unlinked'));
    await tester.ensureVisible(step);
    await tester.tap(step);
    await tester.pumpAndSettle();
    final selected = tester.widget<StoryProgressionPage>(
      find.byType(StoryProgressionPage),
    );
    expect(selected.controller.activeId, 'departure');
    expect(
      selected.views
          .forStory(selected.controller.project, 'departure')
          .selection
          ?.id,
      'step:unlinked',
    );
    await tester.tap(find.widgetWithText(StudioButton, 'Histoire').last);
    await tester.pumpAndSettle();
    expect(find.text('Donnez vie à votre histoire'), findsOneWidget);
    expect(fixture.port.publications, 0);
    expect(await tester.runAsync(fixture.diskSnapshot), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search and map shortcut preserve the author project', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final fixture = (await tester.runAsync(
      () => Ui05NarrativeFixture.create(tester),
    ))!;
    addTearDown(fixture.dispose);
    await tester.runAsync(() => seedTrainArtwork(fixture));
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
    await pumpIo(tester);
    await captureM3Widget(tester, fixture.captureKey, 'ui05-finition-1280');
    tester.view.physicalSize = const Size(1440, 900);
    await tester.pumpWidget(fixture.app(tester, withOwners: true));
    await pumpIo(tester);
    expect(tester.takeException(), isNull);
    await captureM3Widget(tester, fixture.captureKey, 'ui05-finition-1440');
    tester.view.physicalSize = const Size(1024, 640);
    await tester.pumpWidget(
      fixture.app(tester, textScale: 1.5, withOwners: true),
    );
    await pumpIo(tester);
    expect(tester.takeException(), isNull);
    await captureM3Widget(tester, fixture.captureKey, 'ui05-finition-1024-150');
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpWidget(fixture.app(tester, withOwners: true));
    await tester.pumpAndSettle();
    final search = find.widgetWithText(TextField, 'Rechercher dans Histoire');
    await tester.enterText(search, 'Clairière');
    await tester.pumpAndSettle();
    expect(find.text('Résultats · 3'), findsOneWidget);
    await tester.enterText(search, 'aucun document pareil');
    await tester.pumpAndSettle();
    expect(find.text('Aucun document correspondant.'), findsOneWidget);
    await tester.enterText(search, '');
    await tester.pumpAndSettle();
    final map = find.byKey(const ValueKey('overview-map-clairiere'));
    await tester.ensureVisible(map);
    await tester.tap(map);
    await pumpIo(tester);
    final layout = tester.widget<MapWorkspaceLayout>(
      find.byType(MapWorkspaceLayout),
    );
    expect(layout.activeSpace, 'map');
    expect(fixture.controller.active?.base.mapId, 'clairiere');
    expect(fixture.port.publications, 0);
    expect(await tester.runAsync(fixture.diskSnapshot), before);
    expect(tester.takeException(), isNull);
  });
}

Future<void> seedTrainArtwork(Ui05NarrativeFixture fixture) async {
  const source =
      '../../documentation/reports/avelune_studio/UI05_histoire/artwork_train';
  final root = fixture.source.session.directoryPath;
  final files = <String, String>{
    'hero.png': 'hero.png',
    'stories/departure.png': 'scenes/campaign-opening.png',
    'stories/garden-traces.png': 'scenes/campaign-shizune.png',
    for (final pair in fixture.controller.project!.scenes.take(4).indexed)
      'scenes/${pair.$2.id}.png': [
        'scenes/campaign-box-home.png',
        'scenes/campaign-opening.png',
        'scenes/campaign-shizune.png',
        'scenes/campaign-photo-home.png',
      ][pair.$1],
  };
  for (final entry in files.entries) {
    final destination = File('$root/assets/studio/narrative/${entry.key}');
    await destination.parent.create(recursive: true);
    await File('$source/${entry.value}').copy(destination.path);
  }
}
