import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';

import 'support/technical_map_journey_host.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the technical 2D viewport reorders overlapping decorations', (
    tester,
  ) async {
    _configureView(tester);
    final host = await TechnicalMapJourneyHost.open(tester);
    try {
      final diskBefore = await host.savedMapBytes();
      for (final id in ['arbre', 'rocher', 'arbre']) {
        await host.selectDecor(id);
        await host.viewport.tapCell(8, 7);
      }
      final commands = MapEditingCommands(host.document, host.maps.project!);
      final before = commands.stack(const GridPos(x: 8, y: 7));
      expect(before, hasLength(3));
      final selectedId = host.document.selectedId;
      expect(before.first.id, selectedId);
      expect(commands.canReorder(forward: false), isTrue);
      final history = host.document.undoCount;
      await host.chord(LogicalKeyboardKey.arrowDown);
      final after = commands.stack(const GridPos(x: 8, y: 7));
      expect(after, hasLength(3));
      expect(after[1].id, selectedId);
      expect(after.first.id, before[1].id);
      expect(host.document.undoCount, history + 1);
      expect(await host.savedMapBytes(), diskBefore);
      final authored = host.document.current;
      await host.save();

      final reopened = await host.readSavedMap('jardin');
      expect(reopened, authored);
      final stack = reopened.placedElements
          .where((element) => element.pos == const GridPos(x: 8, y: 7))
          .toList();
      expect(stack, hasLength(3));
      expect(stack.map((element) => element.layerId), everyElement('decor'));
      expect(
        stack.singleWhere((element) => element.id == selectedId).visualOrder,
        lessThan(
          stack
              .singleWhere((element) => element.id == before[1].id)
              .visualOrder,
        ),
      );
      expect(tester.takeException(), isNull);
    } finally {
      await host.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets(
    'the technical 2D decor eraser removes one top instance and is undoable',
    (tester) async {
      _configureView(tester);
      final host = await TechnicalMapJourneyHost.open(tester);
      try {
        final diskBefore = await host.savedMapBytes();
        for (final id in ['arbre', 'rocher']) {
          await host.selectDecor(id);
          await host.viewport.tapCell(8, 7);
        }
        Iterable<MapPlacedElement> stack() => host
            .document
            .current
            .placedElements
            .where((element) => element.pos == const GridPos(x: 8, y: 7));
        expect(stack(), hasLength(2));
        final topBefore = MapEditingCommands(
          host.document,
          host.maps.project!,
        ).stack(const GridPos(x: 8, y: 7)).first;

        await host.tool('Gomme de décors');
        expect(host.viewport.nativeView.tool, StudioMapTool.eraseDecor);
        await host.viewport.tapCell(8, 7);
        expect(stack(), hasLength(1));
        expect(stack().single.id, isNot(topBefore.id));
        final erased = host.document.current;
        await host.chord(LogicalKeyboardKey.keyZ);
        expect(stack(), hasLength(2));
        expect(stack().any((element) => element.id == topBefore.id), isTrue);
        await host.chord(LogicalKeyboardKey.keyZ, shift: true);
        expect(stack(), hasLength(1));
        expect(host.document.current, erased);
        expect(await host.savedMapBytes(), diskBefore);
        await host.save();

        final reopened = await host.readSavedMap('jardin');
        expect(reopened, erased);
        final savedStack = reopened.placedElements.where(
          (element) => element.pos == const GridPos(x: 8, y: 7),
        );
        expect(savedStack, hasLength(1));
        expect(savedStack.single.id, isNot(topBefore.id));
        expect(tester.takeException(), isNull);
      } finally {
        await host.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}

void _configureView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1536, 1024);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
