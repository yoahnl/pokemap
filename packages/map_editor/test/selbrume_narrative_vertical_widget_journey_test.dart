import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_command_palette.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_destination.dart';
import 'package:map_editor/src/ui/canvas/narrative_studio/narrative_studio_product_shell.dart';

import 'support/narrative_studio_product_shell_harness.dart';
import 'support/selbrume_narrative_authoring_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'navigates Storyline, Dialogue, Scene, Event and Validator by keyboard',
      (tester) async {
    late final SelbrumeNarrativeAuthoringHarness harness;
    late final SelbrumeNarrativeReconstructionResult authored;
    await tester.runAsync(() async {
      harness = await SelbrumeNarrativeAuthoringHarness.createPhysicalFixture();
      authored = await harness.authorVerticalSlice();
    });
    addTearDown(harness.dispose);
    final project = authored.reloadedProject;
    final validation = validateNarrativeProject(
      project,
      maps: <MapData>[authored.map],
    );
    final index = buildNarrativeGlobalSearchIndex(
      project: project,
      dependencyIndex: buildNarrativeDependencyIndex(
        project: project,
        maps: <MapData>[authored.map],
      ),
      diagnostics: validation.diagnostics,
      revision: 1,
    );
    final workspaceFocus = FocusNode(debugLabel: 'selbrume-workspace');
    addTearDown(workspaceFocus.dispose);
    var location = NarrativeStudioRouteLocation.storylines();

    await tester.pumpWidget(
      hostNarrativeStudioVisualWidget(
        StatefulBuilder(
          builder: (context, setState) {
            void selectLocation(NarrativeStudioRouteLocation next) {
              setState(() => location = next);
            }

            return NarrativeStudioProductShell(
              selectedDestination: location.destination,
              selectedLocation: location,
              onSelectDestination: (destination) => selectLocation(
                _rootLocation(destination),
              ),
              onSelectLocation: selectLocation,
              onOpenMaps: () {},
              globalSearchIndex: index,
              onOpenSearchEntry: (entry) {
                final target = resolveNarrativeStudioSearchLocation(entry);
                if (target != null) selectLocation(target);
              },
              workspace: Focus(
                focusNode: workspaceFocus,
                autofocus: true,
                child: Center(
                  child: Text(
                    'route:${location.destination.name} '
                    'asset:${location.selection?.assetId ?? 'none'} '
                    'errors:${validation.errorCount}',
                    key: const ValueKey('selbrume-authored-route'),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();

    for (final target in <({String query, String id, String destination})>[
      (
        query: authored.storylineId,
        id: authored.storylineId,
        destination: 'storylines',
      ),
      (
        query: authored.dialogueId,
        id: authored.dialogueId,
        destination: 'dialogues',
      ),
      (
        query: authored.sceneId,
        id: authored.sceneId,
        destination: 'scenes',
      ),
      (
        query: authored.eventId,
        id: authored.eventId,
        destination: 'events',
      ),
    ]) {
      workspaceFocus.requestFocus();
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.byKey(narrativeCommandPaletteKey), findsOneWidget);

      await tester.enterText(
        find.byKey(narrativeCommandPaletteSearchKey),
        target.query,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.byKey(narrativeCommandPaletteKey), findsNothing);
      expect(workspaceFocus.hasFocus, isTrue);
      expect(
        find.textContaining(
          'route:${target.destination} asset:${target.id}',
        ),
        findsOneWidget,
      );
    }

    final validator = find.byKey(
      const ValueKey('narrative-studio-product-nav-validator'),
    );
    expect(await _focusWithTab(tester, validator), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(
      find.text(
        'route:validator asset:none errors:${validation.errorCount}',
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

NarrativeStudioRouteLocation _rootLocation(
  NarrativeStudioDestination destination,
) =>
    switch (destination) {
      NarrativeStudioDestination.overview =>
        NarrativeStudioRouteLocation.overview(),
      NarrativeStudioDestination.storylines =>
        NarrativeStudioRouteLocation.storylines(),
      NarrativeStudioDestination.scenes =>
        NarrativeStudioRouteLocation.scenes(),
      NarrativeStudioDestination.events =>
        NarrativeStudioRouteLocation.events(),
      NarrativeStudioDestination.cinematics =>
        NarrativeStudioRouteLocation.cinematics(),
      NarrativeStudioDestination.dialogues =>
        NarrativeStudioRouteLocation.dialogues(),
      NarrativeStudioDestination.facts => NarrativeStudioRouteLocation.facts(),
      NarrativeStudioDestination.shops => NarrativeStudioRouteLocation.shops(),
      NarrativeStudioDestination.worldRules =>
        NarrativeStudioRouteLocation.worldRules(),
      NarrativeStudioDestination.validator =>
        NarrativeStudioRouteLocation.validator(),
    };

Future<bool> _focusWithTab(WidgetTester tester, Finder target) async {
  FocusManager.instance.primaryFocus?.unfocus();
  for (var attempt = 0; attempt < 32; attempt++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    if (_primaryFocusIsInside(target)) return true;
  }
  return false;
}

bool _primaryFocusIsInside(Finder finder) {
  final target = finder.evaluate().single;
  final focusContext = FocusManager.instance.primaryFocus?.context;
  if (focusContext == null) return false;
  var current = focusContext as Element?;
  while (current != null) {
    if (identical(current, target)) return true;
    Element? parent;
    current.visitAncestorElements((ancestor) {
      parent = ancestor;
      return false;
    });
    current = parent;
  }
  return false;
}
