import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';
import '../ports/project_workspace.dart';
import 'project_map_id_policy.dart';

/// Validates that every manifest map path has one safe, unambiguous owner.
///
/// The workspace resolver remains authoritative for confinement and symlink
/// rejection. This policy adds the project-wide ownership check required
/// before a lifecycle or direct map write can safely start.
final class ProjectMapManifestIntegrityPolicy {
  const ProjectMapManifestIntegrityPolicy();

  static const ProjectMapIdPolicy _idPolicy = ProjectMapIdPolicy();

  List<String> diagnostics(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    String? allowedLegacyId,
  }) {
    final issues = <String>[];
    final ownersByResolvedPath = <String, ProjectMapEntry>{};
    final ownersById = <String, ProjectMapEntry>{};

    for (final entry in project.maps) {
      final idOwnershipKey = entry.id.toLowerCase();
      final previousIdOwner = ownersById[idOwnershipKey];
      if (previousIdOwner != null) {
        issues.add(
          'Les entrées « ${previousIdOwner.id} » et « ${entry.id} » '
          'utilisent le même identifiant de map.',
        );
      } else {
        ownersById[idOwnershipKey] = entry;
      }
      if (entry.id != allowedLegacyId) {
        try {
          _idPolicy.requireValid(entry.id);
        } on EditorValidationException catch (error) {
          issues.add(
            'La carte « ${entry.id} » utilise un identifiant legacy : $error',
          );
        }
      }

      late final String resolvedPath;
      try {
        resolvedPath = workspace.resolveMapPath(entry.relativePath);
      } on Object catch (error) {
        issues.add(
          'La carte « ${entry.id} » utilise un chemin non sûr '
          '« ${entry.relativePath} » : $error',
        );
        continue;
      }

      final ownershipKey = p.normalize(resolvedPath).toLowerCase();
      final previousOwner = ownersByResolvedPath[ownershipKey];
      if (previousOwner != null) {
        issues.add(
          'Les cartes « ${previousOwner.id} » et « ${entry.id} » '
          'référencent le même fichier de map.',
        );
        continue;
      }
      ownersByResolvedPath[ownershipKey] = entry;
    }

    return List<String>.unmodifiable(issues);
  }

  void requireValid(
    ProjectWorkspace workspace,
    ProjectManifest project, {
    String? allowedLegacyId,
  }) {
    final issues = diagnostics(
      workspace,
      project,
      allowedLegacyId: allowedLegacyId,
    );
    if (issues.isEmpty) return;
    throw EditorValidationException(
      'Le manifeste des maps est non conforme et reste en lecture seule. '
      '${issues.first}',
    );
  }
}
