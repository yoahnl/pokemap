import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

import '../../support/event_builder_v2_product_route_fixture.dart';

void main() {
  group('NS-EVENT-V2 Phase 2 H3/H4/H5 creation and editing flow', () {
    testWidgets(
        'cancel writes nothing, Enter saves a draft, and the route reopens it',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.v2Only,
      );
      final initialMapBytes = await _readBytes(
        tester,
        '${fixture.root.path}/maps/port.json',
      );

      await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        readModelLoader: (_) => _reloadReadModel(fixture),
      );
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-new-event')),
      );

      await tester.tap(
        find.byKey(const ValueKey('event-builder-v2-new-event')),
      );
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-creation-sheet')),
      );
      await tester.enterText(
        _textFieldInside(
          find.byKey(const ValueKey('event-builder-v2-create-name')),
        ),
        'Annulation sans écriture',
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();

      expect(
        (await _readProject(tester, fixture)).eventRegistry!.records,
        hasLength(5),
      );

      await tester.tap(
        find.byKey(const ValueKey('event-builder-v2-new-event')),
      );
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-creation-sheet')),
      );
      await tester.enterText(
        _textFieldInside(
          find.byKey(const ValueKey('event-builder-v2-create-name')),
        ),
        'Brouillon clavier',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-creation-sheet')),
        absent: true,
      );
      await pumpEventBuilderV2ProductRouteFrames(tester, count: 4);
      await _waitFor(tester, find.text('Brouillon clavier'));

      final project = await _readProject(tester, fixture);
      final created = project.eventRegistry!.records.singleWhere(
        (record) => record.draftOrNull?.name == 'Brouillon clavier',
      );
      expect(created.draftOrNull?.source, isNull);
      expect(find.text('Brouillon clavier'), findsWidgets);
      expect(
        await _readBytes(tester, '${fixture.root.path}/maps/port.json'),
        initialMapBytes,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'edits source, ordered conditions, Scene, behavior, publication and activation',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.v2Only,
      );
      await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        readModelLoader: (_) => _reloadReadModel(fixture),
      );
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-new-event')),
      );
      await tester.tap(
        find.byKey(
          const ValueKey(
            'event-builder-v2-event-v2:$productRouteDraftEventId',
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Choisir un élément').first);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-source-sheet')),
      );
      await tester.tap(find.text('Enregistrer le déclencheur'));
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-source-sheet')),
        absent: true,
      );
      await _refresh(tester);
      await _selectDraft(tester);

      await tester.tap(find.text('Ajouter une condition').first);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-conditions-sheet')),
      );
      await tester.tap(find.text('Ajouter à la liste'));
      await tester.tap(find.text('Ajouter à la liste'));
      await tester.pump();
      await tester.tap(
        find.byKey(
          const ValueKey('event-builder-v2-toggle-condition-1'),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(
          const ValueKey('event-builder-v2-move-condition-up-1'),
        ),
      );
      await tester.pump();
      await tester.tap(
        find.byKey(
          const ValueKey('event-builder-v2-delete-condition-1'),
        ),
      );
      await tester.tap(find.text('Enregistrer les conditions'));
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-conditions-sheet')),
        absent: true,
      );
      await _refresh(tester);
      await _selectDraft(tester);

      await tester.tap(find.text('Choisir une Scene').first);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-scene-sheet')),
      );
      await tester.tap(find.text('Aucune Scene').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Duel du rival').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Enregistrer la Scene'));
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-scene-sheet')),
        absent: true,
      );
      await _refresh(tester);
      await _selectDraft(tester);

      await _openBehavior(tester);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-behavior-sheet')),
      );
      await tester.tap(find.text('Décider plus tard').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Une seule fois').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        _labelledTextField('Priorité'),
        '7',
      );
      await tester.enterText(
        _labelledTextField('Ordre d’évaluation'),
        '3',
      );
      await tester.tap(find.text('Enregistrer').last);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-behavior-sheet')),
        absent: true,
      );
      await _refresh(tester);
      await _selectDraft(tester);

      await _openBehavior(tester);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-behavior-sheet')),
      );
      await tester.tap(find.text('Publier désactivé').last);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-behavior-sheet')),
        absent: true,
      );
      await _refresh(tester);
      await _selectDraft(tester);

      await _openBehavior(tester);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-behavior-sheet')),
      );
      await tester.tap(find.text('Activer').last);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-behavior-sheet')),
        absent: true,
      );

      final project = await _readProject(tester, fixture);
      final record = project.eventRegistry!.records.singleWhere(
        (candidate) => candidate.id == productRouteDraftEventId,
      );
      final definition = record.definitionOrNull!;
      expect(definition.source, isNotNull);
      expect(definition.conditions, hasLength(1));
      expect(
        definition.conditions.single,
        NarrativeEventCondition.fact('fact_port_open', false),
      );
      expect(definition.sceneId, 'scene_rival');
      expect(definition.reusePolicy, NarrativeEventReusePolicy.oneShot);
      expect(definition.priority, 7);
      expect(definition.order, 3);
      expect(record.enabledOrNull, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Space activates the focused draft action and announces saving',
        (tester) async {
      final fixture = await createEventBuilderV2ProductRouteFixture(
        tester,
        mode: EventSystemMode.v2Only,
      );
      await pumpEventBuilderV2ProductRoute(
        tester,
        fixture: fixture,
        readModelLoader: (_) => _reloadReadModel(fixture),
      );
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-new-event')),
      );
      await tester.tap(
        find.byKey(const ValueKey('event-builder-v2-new-event')),
      );
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-creation-sheet')),
      );
      await tester.enterText(
        _textFieldInside(
          find.byKey(const ValueKey('event-builder-v2-create-name')),
        ),
        'Brouillon espace',
      );
      for (var index = 0; index < 4; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('event-builder-v2-saving')),
        findsOneWidget,
      );
      await _waitFor(
        tester,
        find.byKey(const ValueKey('event-builder-v2-creation-sheet')),
        absent: true,
      );

      final names = (await _readProject(tester, fixture))
          .eventRegistry!
          .records
          .map((record) => record.draftOrNull?.name)
          .whereType<String>();
      expect(names.where((name) => name == 'Brouillon espace'), hasLength(1));
      expect(tester.takeException(), isNull);
    });
  });
}

Future<NarrativeEventBuilderProjectReadModel> _reloadReadModel(
  EventBuilderV2ProductRouteFixture fixture,
) async {
  final session = await NarrativeEventAuthoringSession.prepare(
    fixture.projectPath,
  );
  return buildNarrativeEventBuilderProjectReadModel(
    project: session.manifest,
    maps: session.maps,
  );
}

Future<ProjectManifest> _readProject(
  WidgetTester tester,
  EventBuilderV2ProductRouteFixture fixture,
) async {
  final project = await tester.runAsync(() async {
    final json = jsonDecode(await File(fixture.projectPath).readAsString());
    return ProjectManifest.fromJson((json as Map).cast<String, dynamic>());
  });
  if (project == null) throw TestFailure('Project bytes were not read.');
  return project;
}

Future<List<int>> _readBytes(WidgetTester tester, String path) async {
  final bytes = await tester.runAsync(() => File(path).readAsBytes());
  if (bytes == null) throw TestFailure('File bytes were not read: $path');
  return bytes;
}

Finder _textFieldInside(Finder parent) => find.descendant(
      of: parent,
      matching: find.byType(TextField),
    );

Finder _labelledTextField(String label) {
  final field = find.ancestor(
    of: find.text(label),
    matching: find.byType(PokeMapTextField),
  );
  return _textFieldInside(field);
}

Future<void> _refresh(WidgetTester tester) async {
  await pumpEventBuilderV2ProductRouteFrames(tester, count: 4);
  await _waitFor(
    tester,
    find.byKey(const ValueKey('event-builder-v2-new-event')),
  );
}

Future<void> _selectDraft(WidgetTester tester) async {
  final draft = find.byKey(
    const ValueKey('event-builder-v2-event-v2:$productRouteDraftEventId'),
  );
  await _waitFor(tester, draft);
  await tester.tap(draft);
  await tester.pump();
}

Future<void> _openBehavior(WidgetTester tester) async {
  final action = find.text('Modifier');
  await _waitFor(tester, action);
  await tester.ensureVisible(action);
  await tester.pump();
  await tester.tap(action);
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  bool absent = false,
}) async {
  for (var attempt = 0; attempt < 1000; attempt++) {
    await tester.pump(const Duration(milliseconds: 10));
    final matched = finder.evaluate().isNotEmpty;
    if (absent ? !matched : matched) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  final visibleText = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .where((value) => value.trim().isNotEmpty)
      .join(' | ');
  throw TestFailure(
    '${absent ? 'Widget remained visible.' : 'Widget never became visible.'} '
    'Visible text: $visibleText',
  );
}
