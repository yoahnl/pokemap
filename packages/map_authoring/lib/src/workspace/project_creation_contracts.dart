import 'package:map_core/map_core_domain.dart';

enum ProjectCreationTemplate { empty, playable, clairbois }

enum ProjectCreationPhase {
  validating,
  downloading,
  preparing,
  writing,
  verifying,
  completed
}

enum ProjectCreationCheckpoint {
  beforeReservation,
  afterReservation,
  afterApply
}

final class ProjectCreationRequest {
  const ProjectCreationRequest({
    required this.name,
    required this.folderName,
    required this.parentPath,
    this.template = ProjectCreationTemplate.playable,
    this.dimension = ProjectDimension.twoD,
    this.spatialCamera,
    this.tileSize = 16,
    this.mapWidth = 20,
    this.mapHeight = 15,
  });

  final String name;
  final String folderName;
  final String parentPath;
  final ProjectCreationTemplate template;
  final ProjectDimension dimension;
  final SpatialCameraProfile? spatialCamera;
  final int tileSize;
  final int mapWidth;
  final int mapHeight;

  void validate({bool requireDestination = true}) {
    if (name.trim().isEmpty || name.contains('\u0000')) {
      throw const FormatException('Le nom du projet est requis.', 'name');
    }
    if (folderName.isEmpty ||
        folderName.trim() != folderName ||
        folderName == '.' ||
        folderName == '..' ||
        RegExp(r'[\\/<>:"|?*\x00-\x1f]').hasMatch(folderName) ||
        folderName.endsWith('.') ||
        RegExp(r'^(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\.|$)',
                caseSensitive: false)
            .hasMatch(folderName)) {
      throw const FormatException(
          'Choisissez un nom de dossier valide.', 'folderName');
    }
    validateGeometry();
    if (requireDestination &&
        (parentPath.isEmpty || parentPath.contains('\u0000'))) {
      throw const FormatException('Choisissez un dossier parent.');
    }
  }

  void validateGeometry() {
    if (dimension == ProjectDimension.threeD &&
        template != ProjectCreationTemplate.empty) {
      throw const FormatException("Les projets 3D utilisent le modèle vide.");
    }
    if (dimension == ProjectDimension.twoD && spatialCamera != null) {
      throw const FormatException("Une caméra 3D exige un projet 3D.");
    }
    if (template == ProjectCreationTemplate.clairbois &&
        (tileSize != 32 || mapWidth != 32 || mapHeight != 26)) {
      throw const FormatException(
          'Clairbois utilise une grille de 32 × 32 pixels et une carte de 32 × 26 cases.');
    }
    if (!const [16, 32, 48].contains(tileSize)) {
      throw const FormatException('La grille doit être 16, 32 ou 48 pixels.');
    }
    if (mapWidth < 3 || mapHeight < 3 || mapWidth > 256 || mapHeight > 256) {
      throw const FormatException(
          'Les dimensions doivent être entre 3 et 256 cases.');
    }
  }
}

final class ProjectCreationCancelled implements Exception {
  const ProjectCreationCancelled();
  @override
  String toString() => 'Création annulée avant toute écriture.';
}

final class ProjectCreationReceipt {
  const ProjectCreationReceipt(
      {required this.projectPath, required this.manifest});
  final String projectPath;
  final ProjectManifest manifest;
}

final class ProjectCreationException implements Exception {
  const ProjectCreationException(this.code, this.message, {this.residualPath});
  final String code;
  final String message;
  final String? residualPath;

  @override
  String toString() => message;
}

abstract interface class ProjectCreationPort {
  Future<List<int>?> preview(ProjectCreationRequest request);
  Future<String> validateDestination(ProjectCreationRequest request);
  Future<ProjectCreationReceipt> create(
    ProjectCreationRequest request, {
    void Function(ProjectCreationPhase phase)? onPhase,
    bool Function()? isCancelled,
    String? expectedDestination,
  });
}
