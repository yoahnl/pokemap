import 'package:avelune_studio/presentation/features/events/event_condition_dialog.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/world/world_workspace_page.dart';
import 'package:avelune_studio/presentation/features/world/world_view_state.dart';

import 'dart:async';

import 'package:avelune_studio/presentation/features/scenes/periodic_reward_picker.dart';
import 'package:avelune_studio/presentation/features/scenes/scene_condition_form.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

final revision = 'sha256:${List.filled(64, '0').join()}';
AuthoringQueryPage page(List<Map<String, Object?>> items) => AuthoringQueryPage(
  snapshotRevision: revision,
  items: items,
  totalAvailable: items.length,
);
PeriodicRewardReference reference(String scene) => PeriodicRewardReference(
  sceneId: scene,
  nodeId: 'claim',
  rewardId: 'daily-$scene',
);
Map<String, Object?> scene(String id) => PeriodicRewardSceneChoice(
  sceneId: id,
  label: 'Scène $id',
  revision: revision,
).toJson();
Map<String, Object?> node(String id) => PeriodicRewardNodeChoice(
  nodeId: 'claim',
  label: 'Fruit $id',
  itemId: 'fruit',
  quantity: 2,
  reference: reference(id),
  revision: revision,
).toJson();
StudioSelect select(WidgetTester tester, String label) => tester
    .widgetList<StudioSelect>(find.byType(StudioSelect))
    .singleWhere((value) => value.label == label);

void main() {
  for (final lateGet in [false, true]) {
    testWidgets(
      'refresh removes stale published nodes and ignores old get late=$lateGet',
      (tester) async {
        var removed = false;
        var getCount = 0;
        final oldGet = Completer<AuthoringQueryPage>();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: PeriodicRewardChoiceScope(
                  projectRootPath: '/project',
                  query: (request) async {
                    if (request.operation == AuthoringQueryOperation.get &&
                        lateGet &&
                        getCount++ == 0)
                      return oldGet.future;
                    if (removed) return page([]);
                    return request.resourceKind == 'periodicRewardScene'
                        ? page([scene(lateGet ? 'B' : 'A')])
                        : page([node(lateGet ? 'B' : 'A')]);
                  },
                  child: PeriodicRewardPicker(
                    initial: reference('A'),
                    onApply: (_, _) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (lateGet) {
          select(tester, 'Scène de la récompense').onChanged!('B');
          await tester.pumpAndSettle();
          select(tester, 'Action de récompense').onChanged!('claim');
          await tester.pumpAndSettle();
        }
        StudioButton button(String label) => tester
            .widgetList<StudioButton>(find.byType(StudioButton))
            .singleWhere((value) => value.label == label);
        expect(
          button('Appliquer la condition quotidienne').onPressed,
          isNotNull,
        );
        removed = true;
        button('Actualiser les sources').onPressed!();
        await tester.pumpAndSettle();
        expect(select(tester, 'Scène de la récompense').value, isNull);
        expect(select(tester, 'Action de récompense').options, isEmpty);
        expect(button('Appliquer la condition quotidienne').onPressed, isNull);
        if (lateGet) {
          oldGet.complete(page([scene('A')]));
          await tester.pumpAndSettle();
          expect(select(tester, 'Scène de la récompense').options, isEmpty);
          expect(select(tester, 'Action de récompense').options, isEmpty);
          expect(
            button('Appliquer la condition quotidienne').onPressed,
            isNull,
          );
        }
        expect(
          find.textContaining('La référence existante reste conservée'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'World Rule source modal preserves an existing negative daily predicate',
    (tester) async {
      tester.view.reset();
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final maps = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      await maps.initialize();
      addTearDown(maps.dispose);
      final narrative = NarrativeWorkspaceController(
        maps,
        _UnusedNarrativePort(),
        () {},
        (_, _) async {},
      );
      final world = WorldWorkspaceController(
        narrative,
        _UnusedWorldPort(),
        changed: () {},
      );
      addTearDown(world.dispose);
      await world.initialize();
      final id = world.createRule();
      world.editRule(
        id,
        (draft) => draft.source = WorldRuleSource.periodicRewardAvailable(
          reference: reference('A'),
          expectedValue: false,
        ),
      );
      final view = WorldViewState()..view = WorldView.rules;
      addTearDown(view.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeriodicRewardChoiceScope(
              projectRootPath: '/project',
              query: (request) async =>
                  request.resourceKind == 'periodicRewardScene'
                  ? page([scene('A')])
                  : page([node('A')]),
              child: WorldWorkspacePage(
                controller: world,
                view: view,
                onBack: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final block = find.byKey(const ValueKey('rule-block-Condition'));
      await tester.tapAt(tester.getTopLeft(block) + const Offset(20, 20));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Récompense quotidienne').last);
      await tester.pumpAndSettle();
      final dialog = find.byType(AlertDialog);
      final expected = tester
          .widgetList<StudioSelect>(
            find.descendant(of: dialog, matching: find.byType(StudioSelect)),
          )
          .singleWhere((value) => value.label == 'Disponibilité attendue');
      expect(expected.value, 'false');
      await tester.tap(
        find.descendant(
          of: dialog,
          matching: find.text('Appliquer la condition quotidienne'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        world.ruleDraft(id)!.source!.predicate,
        WorldRuleSourcePredicate.isFalse,
      );
      expect(world.ruleDraft(id)!.source!.rewardReference, reference('A'));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'a changed reward identity stays unresolved until explicitly selected',
    (tester) async {
      final applied = <PeriodicRewardReference>[];
      final original = PeriodicRewardReference(
        sceneId: 'A',
        nodeId: 'claim',
        rewardId: 'previous',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PeriodicRewardChoiceScope(
                projectRootPath: '/project',
                query: (request) async =>
                    request.resourceKind == 'periodicRewardScene'
                    ? page([scene('A')])
                    : page([node('A')]),
                child: PeriodicRewardPicker(
                  initial: original,
                  onApply: (reference, _) => applied.add(reference),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(select(tester, 'Action de récompense').value, isNull);
      expect(
        find.textContaining('La référence existante reste conservée'),
        findsOneWidget,
      );
      await tester.ensureVisible(
        find.text('Appliquer la condition quotidienne'),
      );
      await tester.tap(
        find.text('Appliquer la condition quotidienne'),
        warnIfMissed: false,
      );
      expect(applied, isEmpty);
      select(tester, 'Action de récompense').onChanged!('claim');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Appliquer la condition quotidienne'));
      expect(applied, [reference('A')]);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Event modal retains the published source scope across Navigator overlay',
    (tester) async {
      NarrativeEventCondition? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PeriodicRewardChoiceScope(
              projectRootPath: '/project',
              query: (request) async =>
                  request.resourceKind == 'periodicRewardScene'
                  ? page([scene('A')])
                  : page([node('A')]),
              child: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    result = await chooseEventCondition(
                      context,
                      facts: const [],
                      records: const [],
                    );
                  },
                  child: const Text('Choisir'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Choisir'));
      await tester.pumpAndSettle();
      select(tester, 'Condition sur').onChanged!('periodicReward');
      await tester.pumpAndSettle();
      select(tester, 'Scène de la récompense').onChanged!('A');
      await tester.pumpAndSettle();
      select(tester, 'Action de récompense').onChanged!('claim');
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.text('Appliquer la condition quotidienne'),
      );
      await tester.tap(find.text('Appliquer la condition quotidienne'));
      await tester.pumpAndSettle();
      expect(result?.rewardReference, reference('A'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'guided Scene picker applies an explicit published reward without raw fields',
    (tester) async {
      final changes = <SceneConditionSource>[];
      final requests = <AuthoringQueryRequest>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PeriodicRewardChoiceScope(
                projectRootPath: '/project',
                query: (request) async {
                  requests.add(request);
                  return request.resourceKind == 'periodicRewardScene'
                      ? page([scene('A')])
                      : page([node('A')]);
                },
                child: SceneConditionForm(
                  project: const ProjectManifest(
                    name: 'Test',
                    maps: [],
                    tilesets: [],
                  ),
                  current: SceneConditionPayload(
                    conditionSource:
                        SceneConditionSource.periodicRewardAvailable(
                          reference: reference('A'),
                          expectedValue: false,
                        ),
                  ),
                  onApply: changes.add,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(changes, isEmpty);
      expect(select(tester, 'Scène de la récompense').options.values, [
        'Scène A',
      ]);
      expect(select(tester, 'Action de récompense').options.values, [
        'Fruit A × 2',
      ]);
      expect(find.byType(TextField), findsNothing);
      await tester.ensureVisible(
        find.text('Appliquer la condition quotidienne'),
      );
      await tester.tap(find.text('Appliquer la condition quotidienne'));
      await tester.pumpAndSettle();
      expect(changes.single.rewardReference, reference('A'));
      expect(changes.single.operator, SceneConditionOperator.isFalse);
      expect(requests.last.filters, {'sceneId': 'A'});
      expect(requests.last.extensions, {'sourceRevision': revision});
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'late source response cannot overwrite a newer explicit selection',
    (tester) async {
      final slow = Completer<AuthoringQueryPage>();
      final applied = <PeriodicRewardReference>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: PeriodicRewardChoiceScope(
                projectRootPath: '/project',
                query: (request) async {
                  if (request.resourceKind == 'periodicRewardScene')
                    return page([scene('A'), scene('B')]);
                  return request.filters['sceneId'] == 'A'
                      ? slow.future
                      : page([node('B')]);
                },
                child: PeriodicRewardPicker(
                  onApply: (reference, expected) => applied.add(reference),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      select(tester, 'Scène de la récompense').onChanged!('A');
      await tester.pump();
      select(tester, 'Scène de la récompense').onChanged!('B');
      await tester.pumpAndSettle();
      slow.complete(page([node('A')]));
      await tester.pumpAndSettle();
      expect(select(tester, 'Action de récompense').options.values, [
        'Fruit B × 2',
      ]);
      select(tester, 'Action de récompense').onChanged!('claim');
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.text('Appliquer la condition quotidienne'),
      );
      await tester.tap(find.text('Appliquer la condition quotidienne'));
      expect(applied, [reference('B')]);
    },
  );

  testWidgets('missing published source preserves the unresolved condition', (
    tester,
  ) async {
    var changes = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: PeriodicRewardChoiceScope(
              projectRootPath: '/project',
              query: (request) async {
                if (request.operation == AuthoringQueryOperation.get)
                  throw StateError('missing');
                return page([]);
              },
              child: PeriodicRewardPicker(
                initial: reference('missing'),
                onApply: (_, expected) => changes++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(changes, 0);
    expect(
      find.textContaining('La référence existante reste conservée'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Appliquer la condition quotidienne'));
    await tester.tap(
      find.text('Appliquer la condition quotidienne'),
      warnIfMissed: false,
    );
    expect(changes, 0);
    expect(tester.takeException(), isNull);
  });
}

class _UnusedNarrativePort implements NarrativePort {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected publication');
}

class _UnusedWorldPort implements WorldPort {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Unexpected publication');
}
