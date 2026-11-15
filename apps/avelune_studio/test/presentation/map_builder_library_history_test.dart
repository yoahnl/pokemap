import 'package:avelune_studio/features/map_workspace/application/map_library_commands.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_header.dart';
import 'package:flutter_test/flutter_test.dart';

import 'map_builder_map_library_harness.dart';

void main() {
  testWidgets(
    'Annuler and Rétablir step through a library rename and the tree follows',
    (tester) async {
      final (controller, catalog) = await pumpMapLibrary(tester);
      expect(
        mapBuilderHistoryStep(controller, redo: false, editable: true),
        isNull,
      );

      await MapLibraryCommands(controller).renameMap('b', 'Bourg Geon');
      await tester.pumpAndSettle();
      expect(find.text('Bourg Geon'), findsOneWidget);
      expect(
        mapBuilderHistoryStep(controller, redo: false, editable: false),
        isNull,
      );

      mapBuilderHistoryStep(controller, redo: false, editable: true)!();
      await tester.pumpAndSettle();
      expect(catalog.calls.last.$1, 'history.undo');
      expect(find.text('Bourg Geon'), findsNothing);
      expect(find.text('Jardin'), findsOneWidget);
      expect(
        mapBuilderHistoryStep(controller, redo: false, editable: true),
        isNull,
      );

      mapBuilderHistoryStep(controller, redo: true, editable: true)!();
      await tester.pumpAndSettle();
      expect(catalog.calls.last.$1, 'history.redo');
      expect(find.text('Bourg Geon'), findsOneWidget);
    },
  );

  testWidgets(
    'an edit of the open map is undone before the library action that preceded it',
    (tester) async {
      final (controller, catalog) = await pumpMapLibrary(tester);
      await MapLibraryCommands(controller).renameMap('b', 'Bourg Geon');
      final document = controller.active!;
      document.commit(document.current.copyWith(properties: {'draft': true}));
      await tester.pumpAndSettle();

      mapBuilderHistoryStep(controller, redo: false, editable: true)!();
      await tester.pumpAndSettle();
      expect(document.current.properties, isEmpty);
      expect(catalog.calls.last.$1, 'map.update_metadata');
      expect(find.text('Bourg Geon'), findsOneWidget);

      mapBuilderHistoryStep(controller, redo: false, editable: true)!();
      await tester.pumpAndSettle();
      expect(catalog.calls.last.$1, 'history.undo');
      expect(find.text('Jardin'), findsOneWidget);
    },
  );
}
