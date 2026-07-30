import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/editor/application/map_layer_deletion_impact.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_layer_mutation_dialogs.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  group('showWorldMapLayerRenameDialog', () {
    testWidgets('trims the confirmed name', (tester) async {
      String? result;
      await _pumpLauncher(
        tester,
        onPressed: (context) async {
          result = await showWorldMapLayerRenameDialog(
            context: context,
            layerId: 'decor',
            currentName: 'Décor',
          );
        },
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '  Nouveau décor  ');
      await tester.tap(find.text('Renommer'));
      await tester.pumpAndSettle();

      expect(result, 'Nouveau décor');
    });

    testWidgets('cancel and empty confirmation are safe', (tester) async {
      String? result = 'unchanged';
      await _pumpLauncher(
        tester,
        onPressed: (context) async {
          result = await showWorldMapLayerRenameDialog(
            context: context,
            layerId: 'decor',
            currentName: 'Décor',
          );
        },
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(result, isNull);

      result = 'unchanged';
      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text('Renommer'));
      await tester.pumpAndSettle();
      expect(result, isNull);
    });
  });

  group('showWorldMapLayerDeleteDialog', () {
    testWidgets('shows structured impact and confirms an unblocked deletion',
        (tester) async {
      bool? result;
      await _pumpLauncher(
        tester,
        onPressed: (context) async {
          result = await showWorldMapLayerDeleteDialog(
            context: context,
            impact: const MapLayerDeletionImpact(
              layerId: 'decor',
              placedElementCount: 3,
              affectedMapEventIds: [],
              environmentGeneratedCount: 0,
              environmentAttachmentCount: 0,
              blockingReasons: [],
            ),
          );
        },
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();
      expect(find.text('Éléments placés'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Événements de map'), findsOneWidget);
      expect(find.text('0'), findsWidgets);
      await tester.tap(find.widgetWithText(PokeMapButton, 'Supprimer'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('lists ids and exposes blockers without destructive action',
        (tester) async {
      bool? result;
      await _pumpLauncher(
        tester,
        onPressed: (context) async {
          result = await showWorldMapLayerDeleteDialog(
            context: context,
            impact: const MapLayerDeletionImpact(
              layerId: 'decor',
              placedElementCount: 1,
              affectedMapEventIds: ['event_a', 'event_z'],
              environmentGeneratedCount: 2,
              environmentAttachmentCount: 1,
              blockingReasons: [
                'Impossible de supprimer ce layer : '
                    'un environnement lui est attaché.',
                'Impossible de supprimer ce layer : '
                    '2 événements de map y sont attachés.',
              ],
            ),
          );
        },
      );

      await tester.tap(find.text('Ouvrir'));
      await tester.pumpAndSettle();

      expect(find.text('event_a'), findsOneWidget);
      expect(find.text('event_z'), findsOneWidget);
      expect(find.byType(PokeMapDiagnosticCallout), findsNWidgets(2));
      expect(
        find.widgetWithText(PokeMapButton, 'Supprimer'),
        findsNothing,
      );
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });
  });
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required Future<void> Function(BuildContext context) onPressed,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Builder(
        builder: (context) => PokeMapButton(
          onPressed: () => onPressed(context),
          child: const Text('Ouvrir'),
        ),
      ),
    ),
  );
}
