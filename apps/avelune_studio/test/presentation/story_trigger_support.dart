import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/features/dialogues/domain/dialogue_catalog_port.dart';
import 'package:avelune_studio/features/game_behaviours/application/game_behaviour_editing.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/story/story_dialogue_link.dart';
import 'package:avelune_studio/presentation/features/story/behaviours/game_behaviour_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'map_builder_story_support.dart';

Future<void> pumpTrigger(
  WidgetTester tester,
  StoryFixture fixture, {
  DialogueCatalogLanguages? languages,
  Future<DialogueCatalogLanguages> Function()? loadLanguages,
  Future<void> Function(String)? openDialogue,
}) async {
  await fixture.story.prepare();
  await pumpStoryInspector(tester, fixture);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: StoryDialogueNavigation(
        open: openDialogue ?? (_) async {},
        loadLanguages:
            loadLanguages ?? (languages == null ? null : () async => languages),
        child: Scaffold(
          body: ListenableBuilder(
            listenable: fixture.tick,
            builder: (context, _) => SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GameBehaviourEditor(
                  binding: fixture.story,
                  editable: true,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

Finder triggerKey(String key) => find.byKey(ValueKey(key));

Future<StoryFixture> centralTriggerFixture(
  StoryFixture fixture,
  String id,
) async {
  await fixture.story.prepare();
  final central = MapBuilderStoryBinding(
    maps: fixture.maps,
    changed: () => fixture.tick.value++,
    view: () => null,
    loadDialogue: fixture.story.loadDialogue,
    editing: GameBehaviourEditing(
      project: fixture.maps.project!,
      map: fixture.story.map!,
      behaviours: fixture.story.behaviours,
      eventId: id,
    ),
  );
  return (
    maps: fixture.maps,
    ports: fixture.ports,
    tick: fixture.tick,
    story: central,
  );
}
