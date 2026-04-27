import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'package:map_editor/src/features/surface_studio/surface_studio_column_role_mapping_block.dart';
import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart';

void main() {
  group('SurfaceStudioColumnRoleMappingBlock', () {
    testWidgets('affiche la section Mapping des colonnes', (tester) async {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (_) {},
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );

      expect(find.text('Mapping des colonnes'), findsOneWidget);
    });

    testWidgets('affiche le résumé pour un atlas 23×32', (tester) async {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (_) {},
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );

      expect(find.text('Colonnes'), findsOneWidget);
      expect(find.text('Assignées'), findsOneWidget);
      expect(find.text('Non assignées'), findsOneWidget);
      expect(find.text('Doublons'), findsOneWidget);
    });

    testWidgets('affiche 23 colonnes dans la liste', (tester) async {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (_) {},
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );

      expect(find.text('Col 0'), findsOneWidget);
      expect(find.text('Col 1'), findsOneWidget);
    });

    testWidgets('affiche Non assignée pour les colonnes non assignées',
        (tester) async {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (_) {},
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );

      expect(find.text('Non assignée'), findsWidgets);
    });

    testWidgets('affiche les boutons d’action', (tester) async {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (_) {},
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );

      expect(find.text('Suggérer un mapping standard'), findsOneWidget);
      expect(find.text('Réinitialiser le mapping des colonnes'),
          findsOneWidget);
    });

    testWidgets('appelle onDraftChanged quand on suggère un mapping standard',
        (tester) async {
      SurfaceStudioColumnRoleMappingDraft? updatedDraft;
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (newDraft) {
                updatedDraft = newDraft;
              },
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Suggérer un mapping standard'));
      await tester.pumpAndSettle();

      expect(updatedDraft, isNotNull);
      expect(updatedDraft!.columnCount, 23);
      expect(updatedDraft!.assignments.length, 20);
    });

    testWidgets('appelle onDraftChanged quand on réinitialise le mapping',
        (tester) async {
      SurfaceStudioColumnRoleMappingDraft? updatedDraft;
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(23);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (newDraft) {
                updatedDraft = newDraft;
              },
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Réinitialiser le mapping des colonnes'));
      await tester.pumpAndSettle();

      expect(updatedDraft, isNotNull);
      expect(updatedDraft!.columnCount, 23);
      expect(updatedDraft!.assignments.length, 0);
    });

    testWidgets('affiche Atlas simple pour 1×1', (tester) async {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (_) {},
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 1,
              draftRows: 1,
            ),
          ),
        ),
      );

      expect(find.text('Mapping des colonnes'), findsOneWidget);
      expect(find.text('Atlas simple : mapping de colonnes non nécessaire.'),
          findsOneWidget);
      expect(find.text('Colonnes'), findsNothing);
    });

    testWidgets('affiche un message d’erreur pour des dimensions invalides',
        (tester) async {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (_) {},
              draftTileWidth: null,
              draftTileHeight: null,
              draftColumns: null,
              draftRows: null,
            ),
          ),
        ),
      );

      expect(find.text('Mapping des colonnes'), findsOneWidget);
      expect(find.text('Corrigez la grille avant de mapper les colonnes.'),
          findsOneWidget);
    });

    testWidgets('affiche un warning pour les doublons', (tester) async {
      final draft = const SurfaceStudioColumnRoleMappingDraft.empty(23)
          .withRoleForColumn(0, SurfaceVariantRole.isolated)
          .withRoleForColumn(1, SurfaceVariantRole.isolated);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (_) {},
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );

      expect(
        find.text('Attention : un rôle est assigné à plusieurs colonnes.'),
        findsOneWidget,
      );
    });

    testWidgets('affiche les libellés utilisateur des rôles', (tester) async {
      final draft = const SurfaceStudioColumnRoleMappingDraft.empty(23)
          .withRoleForColumn(0, SurfaceVariantRole.isolated)
          .withRoleForColumn(1, SurfaceVariantRole.cornerNE);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SurfaceStudioColumnRoleMappingBlock(
              label: const Color(0xFF000000),
              subtle: const Color(0xFF666666),
              draft: draft,
              onDraftChanged: (_) {},
              draftTileWidth: 32,
              draftTileHeight: 32,
              draftColumns: 23,
              draftRows: 32,
            ),
          ),
        ),
      );

      expect(find.text('Plein'), findsOneWidget);
      expect(find.text('Coin haut droit'), findsOneWidget);
    });
  });
}