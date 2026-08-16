import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_distribution/map_distribution.dart';

import '../../../application/services/pokemon_project_validator.dart';

export 'package:map_authoring/map_authoring.dart'
    show
        GamePackageArchiveBuilder,
        GamePackageAtomicFileWriter,
        GamePackageExportArtifact,
        GamePackageExportCertification,
        GamePackageExportWriteFailure;

final class GamePackageExportService {
  const GamePackageExportService({
    this.projectionBuilder = const RuntimeProjectProjectionBuilder(),
    this.gameplayReadinessGate = const GamePackageGameplayReadinessGate(),
    this.pokemonProjectValidator,
    this.packageBuilder = const GamePackageBuilder(),
    this.packageArchiveBuilder,
    this.atomicFileWriter,
  });

  final RuntimeProjectProjectionBuilder projectionBuilder;
  final GamePackageGameplayReadinessGate gameplayReadinessGate;
  final PokemonProjectValidator? pokemonProjectValidator;
  final GamePackageBuilder packageBuilder;
  final GamePackageArchiveBuilder? packageArchiveBuilder;
  final GamePackageAtomicFileWriter? atomicFileWriter;

  Future<GamePackageExportArtifact> build({
    required Directory projectRoot,
    required GamePackageExportProfile profile,
  }) =>
      _delegate().build(projectRoot: projectRoot, profile: profile);

  Future<GamePackageExportArtifact> exportToFile({
    required Directory projectRoot,
    required GamePackageExportProfile profile,
    required File outputFile,
  }) =>
      _delegate().exportToFile(
        projectRoot: projectRoot,
        profile: profile,
        outputFile: outputFile,
      );

  CanonicalGamePackageExportService _delegate() =>
      CanonicalGamePackageExportService(
        projectionBuilder: projectionBuilder,
        gameplayReadinessGate: gameplayReadinessGate,
        pokemonValidator: pokemonProjectValidator?.validateProjectFiles,
        packageBuilder: packageBuilder,
        packageArchiveBuilder: packageArchiveBuilder,
        atomicFileWriter: atomicFileWriter,
      );
}
