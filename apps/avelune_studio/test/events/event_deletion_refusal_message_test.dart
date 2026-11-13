import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/events/domain/event_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_inspector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

final _project = workspaceProject.copyWith(
  eventRegistry: NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.legacyOnly,
    records: [
      NarrativeEventRecord.draft(
        NarrativeEventDraft(
          id: 'evt_019abcde-0000-7000-8000-000000000001',
          name: 'Arrivée',
          source: NarrativeEventSourceRef.mapEnter('a'),
          conditions: const [],
          priority: 0,
          order: 0,
        ),
      ),
    ],
    legacyClaims: const [],
  ),
);

void main() {
  Future<MapBuilderStoryBinding> open(WidgetTester tester, Locale locale) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final port = WorkspaceMemoryPort(manifest: _project);
    port.saved['a'] = workspaceMap('a');
    final maps = MapWorkspaceController(workspaceSession, port);
    addTearDown(maps.dispose);
    await maps.initialize();
    if (maps.active == null) await maps.activate(maps.project!.maps.first);
    final tick = ValueNotifier(0);
    addTearDown(tick.dispose);
    final story = MapBuilderStoryBinding(
      maps: maps,
      changed: () => tick.value++,
      view: () => null,
    );
    final element = story.elements!.elements.singleWhere(
      (element) => element.key == 'map:a',
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListenableBuilder(
            listenable: tick,
            builder: (context, _) => SingleChildScrollView(
              child: MapBuilderStoryInspector(binding: story, element: element),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return story;
  }

  Future<void> show(
    WidgetTester tester,
    MapBuilderStoryBinding story,
    EventDeletionRefused refusal,
  ) async {
    story.error = refusal.message;
    story.changed();
    await tester.pump();
  }

  testWidgets('a refused deletion names every user in French', (tester) async {
    final story = await open(tester, const Locale('fr'));

    await show(
      tester,
      story,
      EventDeletionRefused.inUse(const [
        (kind: 'worldRule', label: 'Portail fermé'),
        (kind: 'map', label: 'Bourg'),
        (kind: 'event', label: 'Rencontre'),
      ]),
    );

    expect(
      find.text(
        'Suppression refusée : ce comportement est encore utilisé par '
        'la règle « Portail fermé », la carte « Bourg », '
        'le comportement « Rencontre ». Retirez ces usages, puis réessayez.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('an unknown coverage is explained in English', (tester) async {
    final story = await open(tester, const Locale('en'));

    await show(tester, story, EventDeletionRefused.coverageUnknown());

    expect(
      find.text(
        'Deletion refused: the behaviour uses of this project are not '
        'indexed yet, so Avelune cannot prove this one is unused. '
        'Nothing was changed.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining(EventDeletionRefused.prefix), findsNothing);
  });
}
