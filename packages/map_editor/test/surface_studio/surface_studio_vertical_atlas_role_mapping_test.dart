import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'package:map_editor/src/features/surface_studio/surface_studio_vertical_atlas_role_mapping.dart';

void main() {
  group('SurfaceStudioColumnRoleAssignment', () {
    test('crée une assignation avec rôle', () {
      const assignment = SurfaceStudioColumnRoleAssignment(
        columnIndex: 0,
        role: SurfaceVariantRole.isolated,
      );

      expect(assignment.columnIndex, 0);
      expect(assignment.role, SurfaceVariantRole.isolated);
      expect(assignment.isAssigned, true);
    });

    test('crée une assignation sans rôle', () {
      const assignment = SurfaceStudioColumnRoleAssignment(
        columnIndex: 0,
        role: null,
      );

      expect(assignment.columnIndex, 0);
      expect(assignment.role, null);
      expect(assignment.isAssigned, false);
    });

    test('égalité entre assignations', () {
      const a1 = SurfaceStudioColumnRoleAssignment(
        columnIndex: 0,
        role: SurfaceVariantRole.isolated,
      );
      const a2 = SurfaceStudioColumnRoleAssignment(
        columnIndex: 0,
        role: SurfaceVariantRole.isolated,
      );
      const a3 = SurfaceStudioColumnRoleAssignment(
        columnIndex: 1,
        role: SurfaceVariantRole.isolated,
      );

      expect(a1, equals(a2));
      expect(a1, isNot(equals(a3)));
    });
  });

  group('SurfaceStudioColumnRoleMappingDraft', () {
    test('crée un brouillon vide', () {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);

      expect(draft.columnCount, 23);
      expect(draft.assignments, isEmpty);
      expect(draft.roleForColumn(0), null);
      expect(draft.isColumnAssigned(0), false);
    });

    test('crée un brouillon avec suggestion standard', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(23);

      expect(draft.columnCount, 23);
      expect(draft.assignments.length, 20); // 20 rôles standards
      expect(draft.roleForColumn(0), SurfaceVariantRole.isolated);
      expect(draft.roleForColumn(1), SurfaceVariantRole.endNorth);
      expect(draft.roleForColumn(19), SurfaceVariantRole.cross);
      expect(draft.roleForColumn(20), null); // Colonnes restantes non assignées
    });

    test('crée un brouillon avec suggestion standard pour moins de colonnes',
        () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(5);

      expect(draft.columnCount, 5);
      expect(draft.assignments.length, 5);
      expect(draft.roleForColumn(0), SurfaceVariantRole.isolated);
      expect(draft.roleForColumn(4), SurfaceVariantRole.endWest);
    });

    test('assigne un rôle à une colonne', () {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);
      final updated = draft.withRoleForColumn(0, SurfaceVariantRole.isolated);

      expect(updated.roleForColumn(0), SurfaceVariantRole.isolated);
      expect(updated.isColumnAssigned(0), true);
      expect(draft.roleForColumn(0), null); // Original inchangé
    });

    test('désassigne une colonne', () {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);
      final withRole = draft.withRoleForColumn(0, SurfaceVariantRole.isolated);
      final withoutRole = withRole.withRoleForColumn(0, null);

      expect(withoutRole.roleForColumn(0), null);
      expect(withoutRole.isColumnAssigned(0), false);
    });

    test('modifie le rôle d’une colonne', () {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);
      final withRole1 = draft.withRoleForColumn(0, SurfaceVariantRole.isolated);
      final withRole2 =
          withRole1.withRoleForColumn(0, SurfaceVariantRole.endNorth);

      expect(withRole2.roleForColumn(0), SurfaceVariantRole.endNorth);
      expect(withRole2.assignments.length, 1); // Pas de duplication
    });

    test('réinitialise le mapping', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(23);
      final cleared = draft.cleared();

      expect(cleared.columnCount, 23);
      expect(cleared.assignments, isEmpty);
    });

    test('égalité entre brouillons', () {
      const d1 = SurfaceStudioColumnRoleMappingDraft.empty(23);
      const d2 = SurfaceStudioColumnRoleMappingDraft.empty(23);
      const d3 = SurfaceStudioColumnRoleMappingDraft.empty(24);

      expect(d1, equals(d2));
      expect(d1, isNot(equals(d3)));
    });
  });

  group('SurfaceStudioColumnRoleMappingSummary', () {
    test('crée un résumé pour un brouillon vide', () {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);
      final summary = SurfaceStudioColumnRoleMappingSummary.fromDraft(draft);

      expect(summary.columnCount, 23);
      expect(summary.assignedColumnCount, 0);
      expect(summary.unassignedColumnCount, 23);
      expect(summary.duplicateRoleCount, 0);
      expect(summary.hasDuplicateRoles, false);
      expect(summary.coveredRoles, isEmpty);
    });

    test('crée un résumé pour un brouillon avec suggestion standard', () {
      final draft = SurfaceStudioColumnRoleMappingDraft.suggested(23);
      final summary = SurfaceStudioColumnRoleMappingSummary.fromDraft(draft);

      expect(summary.columnCount, 23);
      expect(summary.assignedColumnCount, 20);
      expect(summary.unassignedColumnCount, 3);
      expect(summary.duplicateRoleCount, 0);
      expect(summary.hasDuplicateRoles, false);
      expect(summary.coveredRoles.length, 20);
    });

    test('détecte les doublons de rôles', () {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);
      final withDuplicates = draft
          .withRoleForColumn(0, SurfaceVariantRole.isolated)
          .withRoleForColumn(1, SurfaceVariantRole.isolated);
      final summary =
          SurfaceStudioColumnRoleMappingSummary.fromDraft(withDuplicates);

      expect(summary.columnCount, 23);
      expect(summary.assignedColumnCount, 2);
      expect(summary.unassignedColumnCount, 21);
      expect(summary.duplicateRoleCount, 1);
      expect(summary.hasDuplicateRoles, true);
      expect(summary.coveredRoles.length, 1);
    });

    test('égalité entre résumés', () {
      const draft = SurfaceStudioColumnRoleMappingDraft.empty(23);
      final s1 = SurfaceStudioColumnRoleMappingSummary.fromDraft(draft);
      final s2 = SurfaceStudioColumnRoleMappingSummary.fromDraft(draft);

      expect(s1, equals(s2));
    });
  });

  group('SurfaceStudioRoleLabels', () {
    test('fournit des libellés pour tous les rôles', () {
      final labels = SurfaceStudioRoleLabels.allRolesInOrder;

      expect(labels.length, 20);
      expect(labels.first, SurfaceVariantRole.isolated);
      expect(labels.last, SurfaceVariantRole.cross);
    });

    test('fournit un libellé lisible pour un rôle', () {
      final label =
          SurfaceStudioRoleLabels.labelForRole(SurfaceVariantRole.isolated);

      expect(label, 'Plein');
    });

    test('fournit un libellé lisible pour un coin', () {
      final label =
          SurfaceStudioRoleLabels.labelForRole(SurfaceVariantRole.cornerNE);

      expect(label, 'Coin haut droit');
    });

    test('fournit un libellé lisible pour un té', () {
      final label =
          SurfaceStudioRoleLabels.labelForRole(SurfaceVariantRole.teeNorth);

      expect(label, 'Té haut');
    });

    test('fournit un libellé lisible pour une croix', () {
      final label =
          SurfaceStudioRoleLabels.labelForRole(SurfaceVariantRole.cross);

      expect(label, 'Croix');
    });
  });
}
