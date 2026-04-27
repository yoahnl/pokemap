import 'package:map_core/map_core.dart';

/// Assignation locale d’une colonne d’atlas vers un rôle Surface.
///
/// Modèle UI local uniquement : aucune persistance, aucune génération d’animation.
/// Permet à l’utilisateur de préparer un mapping avant génération.
class SurfaceStudioColumnRoleAssignment {
  const SurfaceStudioColumnRoleAssignment({
    required this.columnIndex,
    this.role,
  });

  /// Index de la colonne dans l’atlas (0-based).
  final int columnIndex;

  /// Rôle Surface assigné, ou `null` si la colonne est non assignée.
  final SurfaceVariantRole? role;

  /// Vrai si un rôle est assigné à cette colonne.
  bool get isAssigned => role != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioColumnRoleAssignment &&
          other.columnIndex == columnIndex &&
          other.role == role;

  @override
  int get hashCode => Object.hash(columnIndex, role);
}

/// Brouillon local de mapping des colonnes d’un atlas vertical vers des rôles Surface.
///
/// Ce modèle ne crée aucune animation ni preset. Il sert uniquement à préparer
/// l’authoring visuel dans Surface Studio.
class SurfaceStudioColumnRoleMappingDraft {
  const SurfaceStudioColumnRoleMappingDraft({
    required this.columnCount,
    this.assignments = const [],
  });

  /// Nombre total de colonnes dans l’atlas.
  final int columnCount;

  /// Liste des assignations (une par colonne assignée).
  /// Les colonnes non assignées ne sont pas dans cette liste.
  final List<SurfaceStudioColumnRoleAssignment> assignments;

  /// Crée un brouillon vide pour un nombre de colonnes donné.
  const SurfaceStudioColumnRoleMappingDraft.empty(this.columnCount)
      : assignments = const [];

  /// Crée un brouillon avec une suggestion standard : les rôles standards
  /// sont assignés dans l’ordre aux premières colonnes.
  factory SurfaceStudioColumnRoleMappingDraft.suggested(int columnCount) {
    final assignments = <SurfaceStudioColumnRoleAssignment>[];
    const roles = standardSurfaceVariantRoleOrder;
    final countToAssign = columnCount < roles.length ? columnCount : roles.length;

    for (var i = 0; i < countToAssign; i++) {
      assignments.add(SurfaceStudioColumnRoleAssignment(
        columnIndex: i,
        role: roles[i],
      ));
    }

    return SurfaceStudioColumnRoleMappingDraft(
      columnCount: columnCount,
      assignments: assignments,
    );
  }

  /// Rôle assigné à une colonne, ou `null` si non assignée.
  SurfaceVariantRole? roleForColumn(int columnIndex) {
    for (final assignment in assignments) {
      if (assignment.columnIndex == columnIndex) {
        return assignment.role;
      }
    }
    return null;
  }

  /// Vrai si la colonne a un rôle assigné.
  bool isColumnAssigned(int columnIndex) => roleForColumn(columnIndex) != null;

  /// Crée une copie avec un rôle assigné à une colonne.
  SurfaceStudioColumnRoleMappingDraft withRoleForColumn(
    int columnIndex,
    SurfaceVariantRole? role,
  ) {
    final newAssignments = <SurfaceStudioColumnRoleAssignment>[];
    var found = false;

    for (final assignment in assignments) {
      if (assignment.columnIndex == columnIndex) {
        if (role != null) {
          newAssignments.add(SurfaceStudioColumnRoleAssignment(
            columnIndex: columnIndex,
            role: role,
          ));
        }
        found = true;
      } else {
        newAssignments.add(assignment);
      }
    }

    if (!found && role != null) {
      newAssignments.add(SurfaceStudioColumnRoleAssignment(
        columnIndex: columnIndex,
        role: role,
      ));
    }

    return SurfaceStudioColumnRoleMappingDraft(
      columnCount: columnCount,
      assignments: newAssignments,
    );
  }

  /// Crée une copie avec toutes les assignations supprimées (brouillon vide).
  SurfaceStudioColumnRoleMappingDraft cleared() {
    return SurfaceStudioColumnRoleMappingDraft.empty(columnCount);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioColumnRoleMappingDraft &&
          other.columnCount == columnCount &&
          _assignmentsEqualInOrder(other.assignments);

  bool _assignmentsEqualInOrder(List<SurfaceStudioColumnRoleAssignment> other) {
    if (assignments.length != other.length) {
      return false;
    }
    for (var i = 0; i < assignments.length; i++) {
      if (assignments[i] != other[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(columnCount, Object.hashAll(assignments));
}

/// Résumé statistique d’un brouillon de mapping.
class SurfaceStudioColumnRoleMappingSummary {
  const SurfaceStudioColumnRoleMappingSummary({
    required this.columnCount,
    required this.assignedColumnCount,
    required this.unassignedColumnCount,
    required this.duplicateRoleCount,
    required this.hasDuplicateRoles,
    required this.coveredRoles,
  });

  /// Nombre total de colonnes.
  final int columnCount;

  /// Nombre de colonnes avec un rôle assigné.
  final int assignedColumnCount;

  /// Nombre de colonnes sans rôle assigné.
  final int unassignedColumnCount;

  /// Nombre de rôles assignés à plusieurs colonnes.
  final int duplicateRoleCount;

  /// Vrai si au moins un rôle est assigné à plusieurs colonnes.
  final bool hasDuplicateRoles;

  /// Ensemble des rôles couverts (au moins une colonne).
  final Set<SurfaceVariantRole> coveredRoles;

  /// Crée un résumé à partir d’un brouillon de mapping.
  factory SurfaceStudioColumnRoleMappingSummary.fromDraft(
    SurfaceStudioColumnRoleMappingDraft draft,
  ) {
    final assignedCount = draft.assignments.length;
    final unassignedCount = draft.columnCount - assignedCount;

    final roleCounts = <SurfaceVariantRole, int>{};
    for (final assignment in draft.assignments) {
      final role = assignment.role;
      if (role != null) {
        roleCounts[role] = (roleCounts[role] ?? 0) + 1;
      }
    }

    final duplicateCount = roleCounts.values.where((count) => count > 1).length;
    final hasDuplicates = duplicateCount > 0;

    final coveredRoles = roleCounts.keys.toSet();

    return SurfaceStudioColumnRoleMappingSummary(
      columnCount: draft.columnCount,
      assignedColumnCount: assignedCount,
      unassignedColumnCount: unassignedCount,
      duplicateRoleCount: duplicateCount,
      hasDuplicateRoles: hasDuplicates,
      coveredRoles: coveredRoles,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioColumnRoleMappingSummary &&
          other.columnCount == columnCount &&
          other.assignedColumnCount == assignedColumnCount &&
          other.unassignedColumnCount == unassignedColumnCount &&
          other.duplicateRoleCount == duplicateRoleCount &&
          other.hasDuplicateRoles == hasDuplicateRoles &&
          _coveredRolesEqual(other.coveredRoles);

  bool _coveredRolesEqual(Set<SurfaceVariantRole> other) {
    if (coveredRoles.length != other.length) {
      return false;
    }
    for (final role in coveredRoles) {
      if (!other.contains(role)) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        columnCount,
        assignedColumnCount,
        unassignedColumnCount,
        duplicateRoleCount,
        hasDuplicateRoles,
        Object.hashAll(coveredRoles),
      );
}

/// Libellés utilisateur pour les rôles Surface.
///
/// Ces textes sont destinés à l’UI et ne doivent pas contenir de jargon
/// technique interne.
class SurfaceStudioRoleLabels {
  SurfaceStudioRoleLabels._();

  static const Map<SurfaceVariantRole, String> _labels = {
    SurfaceVariantRole.isolated: 'Plein',
    SurfaceVariantRole.endNorth: 'Bord haut',
    SurfaceVariantRole.endEast: 'Bord droit',
    SurfaceVariantRole.endSouth: 'Bord bas',
    SurfaceVariantRole.endWest: 'Bord gauche',
    SurfaceVariantRole.horizontal: 'Horizontal',
    SurfaceVariantRole.vertical: 'Vertical',
    SurfaceVariantRole.cornerNE: 'Coin haut droit',
    SurfaceVariantRole.cornerSE: 'Coin bas droit',
    SurfaceVariantRole.cornerSW: 'Coin bas gauche',
    SurfaceVariantRole.cornerNW: 'Coin haut gauche',
    SurfaceVariantRole.innerCornerNE: 'Coin intérieur haut droit',
    SurfaceVariantRole.innerCornerSE: 'Coin intérieur bas droit',
    SurfaceVariantRole.innerCornerSW: 'Coin intérieur bas gauche',
    SurfaceVariantRole.innerCornerNW: 'Coin intérieur haut gauche',
    SurfaceVariantRole.teeNorth: 'Té haut',
    SurfaceVariantRole.teeEast: 'Té droit',
    SurfaceVariantRole.teeSouth: 'Té bas',
    SurfaceVariantRole.teeWest: 'Té gauche',
    SurfaceVariantRole.cross: 'Croix',
  };

  /// Libellé utilisateur pour un rôle Surface.
  static String labelForRole(SurfaceVariantRole role) {
    return _labels[role] ?? role.toString();
  }

  /// Liste de tous les rôles avec leurs libellés, dans l’ordre standard.
  static List<SurfaceVariantRole> get allRolesInOrder =>
      standardSurfaceVariantRoleOrder;
}