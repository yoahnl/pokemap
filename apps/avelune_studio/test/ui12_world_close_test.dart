import 'dart:async';

import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/world/world_view_state.dart';
import 'package:avelune_studio/presentation/features/world/world_workspace_page.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'support/m2_ui_fixture.dart';
import 'support/ui05_narrative_fixture.dart';
import 'support/ui12_held_world_port.dart';
import 'support/ui12_widget_world_port.dart';
import 'support/ui12_world_harness.dart';

const _label = 'Train parti de Kisaragi';

Future<void> activate(WidgetTester tester, Finder finder) async {
  await tester.pump(const Duration(milliseconds: 350));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await pumpIo(tester, frames: 12);
}

Finder inDialog(String label) => find.descendant(
  of: find.byType(AlertDialog),
  matching: find.text(label),
);

String state(WorldWorkspaceController world, String label) {
  final id = world.createFact();
  world.editFact(
    NarrativeFactDefinition(
      id: id,
      label: label,
      initialValue: const NarrativeValue.boolean(false),
    ),
  );
  return id;
}

String composeRule(
  WorldWorkspaceController world,
  String factId, {
  bool complete = true,
}) {
  final map = world.maps.firstWhere((map) => map.entities.isNotEmpty);
  final entity = map.entities.first;
  final id = world.createRule(factId: factId);
  world.editRule(id, (draft) {
    draft.label = 'Masquer le conducteur';
    if (!complete) return;
    draft.target = WorldRuleTarget(
      kind: WorldRuleTargetKind.mapEntity,
      mapId: map.id,
      entityId: entity.id,
      label: entity.id,
    );
    draft.effect = const WorldRuleEffect(kind: WorldRuleEffectKind.entityHidden);
  });
  return id;
}

Future<(Ui12WorldHarness, Future<bool> Function())> host(
  WidgetTester tester, {
  WorldPort Function(WorldPort)? wrap,
}) async {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final h = (await tester.runAsync(
    () => Ui12WorldHarness.create(
      initialize: false,
      wrap: (port) =>
          Ui12WidgetWorldPort((wrap ?? (value) => value)(port), tester),
    ),
  ))!;
  final visuals = (await tester.runAsync(
    () => StudioMapResources.load(h.session, h.maps.project!),
  ))!;
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(h.dispose);
  });
  Future<bool> Function()? guard;
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: MapWorkspaceScreen(
        controller: h.maps,
        loadVisuals: (_, _) async => visuals,
        narrativePort: Ui05NarrativePort(
          LocalNarrativeAdapter(session: h.session, mapAdapter: h.adapter),
          tester,
        ),
        worldPort: h.port,
        onClose: () async {},
        registerExitGuard: (value) {
          if (value != null) guard = value;
        },
        runtimeBuilder: (_, _, _) => const SizedBox(),
      ),
    ),
  );
  await pumpIo(tester);
  await activate(
    tester,
    find.descendant(
      of: find.byType(StudioPrimaryNavigation),
      matching: find.byTooltip('Histoire'),
    ),
  );
  await activate(tester, find.text('États et règles du monde').first);
  expect(find.byType(WorldWorkspacePage), findsOneWidget);
  return (h, () => guard!());
}

WorldWorkspaceController opened(WidgetTester tester) =>
    tester.widget<WorldWorkspacePage>(find.byType(WorldWorkspacePage)).controller;

void main() {
  testWidgets('a rule draft alone still guards the close', (tester) async {
    final (h, guard) = await host(tester);
    final world = opened(tester);
    unawaited(world.saveFact(state(world, _label)));
    await pumpIo(tester, frames: 12);
    final factId = world.project.facts
        .firstWhere((fact) => fact.label == _label)
        .id;
    composeRule(world, factId);
    state(world, 'Conducteur prévenu');
    expect(world.hasRuleDraft, isTrue);

    tester
        .widget<WorldWorkspacePage>(find.byType(WorldWorkspacePage))
        .view
        .view = WorldView.rules;
    await pumpIo(tester, frames: 6);
    await tester.enterText(
      find.widgetWithText(TextField, 'Nom de la règle'),
      '',
    );
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Nom de la règle'))
          .controller!
          .text,
      isEmpty,
      reason: 'the invalid entry really is sitting in the field',
    );

    var pending = guard();
    await pumpIo(tester, frames: 8);
    expect(
      find.text('Conserver vos modifications ?'),
      findsOneWidget,
      reason: 'a rule draft must reach the workspace close protections',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await pumpIo(tester, frames: 8);
    expect(
      await pending,
      isFalse,
      reason: 'abandoning has to be chosen, never fallen into',
    );
    expect(world.hasRuleDraft, isTrue);

    pending = guard();
    await pumpIo(tester, frames: 8);
    await tester.tap(inDialog('Annuler'));
    await pumpIo(tester, frames: 8);
    expect(await pending, isFalse);
    expect(world.hasRuleDraft, isTrue);
    expect(world.project.worldRules, isEmpty);

    pending = guard();
    await pumpIo(tester, frames: 8);
    await tester.tap(inDialog('Enregistrer'));
    await pumpIo(tester, frames: 30);
    expect(await pending, isTrue, reason: world.error ?? '');
    expect(world.pendingRules, isEmpty);
    expect(world.project.worldRules, hasLength(1));
    expect(
      world.project.worldRules.single.label,
      'Masquer le conducteur',
      reason: 'an entry refused on the way out never rewrites the draft',
    );
    expect(
      world.project.facts.map((fact) => fact.label),
      containsAll([_label, 'Conducteur prévenu']),
      reason: 'the other dirty document must be saved, not overwritten',
    );

    final reopened = await tester.runAsync(
      () => Ui12WorldHarness.open(h.directory),
    );
    addTearDown(() async {
      await tester.runAsync(() => reopened!.dispose(deleteDirectory: false));
    });
    expect(reopened!.world.project.worldRules, hasLength(1));
  });

  testWidgets('an incomplete rule is never silently dropped', (tester) async {
    final (_, guard) = await host(tester);
    final world = opened(tester);
    unawaited(world.saveFact(state(world, _label)));
    await pumpIo(tester, frames: 12);
    final factId = world.project.facts
        .firstWhere((fact) => fact.label == _label)
        .id;
    final ruleId = composeRule(world, factId, complete: false);

    final pending = guard();
    await pumpIo(tester, frames: 8);
    expect(find.text('Conserver vos modifications ?'), findsOneWidget);
    await tester.tap(inDialog('Enregistrer'));
    await pumpIo(tester, frames: 20);
    expect(
      await pending,
      isFalse,
      reason: 'an unsaveable rule must keep the workspace open',
    );
    expect(world.ruleDraft(ruleId), isNotNull);
    expect(world.error, contains('la cible'));
    expect(world.project.worldRules, isEmpty);
  });

  testWidgets('a close asked during a publication is refused', (tester) async {
    late Ui12HeldWorldPort held;
    final (_, guard) = await host(
      tester,
      wrap: (port) => held = Ui12HeldWorldPort(port),
    );
    final world = opened(tester);
    unawaited(world.saveFact(state(world, _label)));
    await pumpIo(tester, frames: 12);
    final factId = world.project.facts
        .firstWhere((fact) => fact.label == _label)
        .id;
    final ruleId = composeRule(world, factId);

    held.ruleGate = Completer<void>();
    final writing = world.saveRule(ruleId);
    expect(world.saving, isTrue);
    expect(
      await guard(),
      isFalse,
      reason: 'the workspace stays open while a write is in flight',
    );
    expect(
      find.text('Conserver vos modifications ?'),
      findsNothing,
      reason: 'no choice is asked about a document being written',
    );

    held.ruleGate!.complete();
    await pumpIo(tester, frames: 20);
    expect(await writing, isTrue, reason: world.error ?? '');
    expect(world.pendingRules, isEmpty);
    expect(world.project.worldRules, hasLength(1));
  });
}
