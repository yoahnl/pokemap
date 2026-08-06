// TEMPORARY diagnostic probe. Delete after use.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/game_export/application/game_package_export_profile.dart';
import 'package:map_editor/src/features/game_export/application/game_package_gameplay_readiness_gate.dart';
import 'package:map_editor/src/features/game_export/application/runtime_project_projection_builder.dart';
import 'package:map_editor/src/application/models/pokemon_validation_report.dart';
import 'package:map_editor/src/application/services/pokemon_project_validator.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';

void main() {
  test('probe readiness', () async {
    final root = Directory(
      '/Users/karim/Desktop/pokeMap Project/le_train_de_17h42',
    );
    final profile = GamePackageExportProfile(
      gameId: 'games.local.g6249978bbc2d9dbd766cd1205797fef2',
      gameVersion: '0.1.0',
      title: 'le train de 17h42',
      authorName: 'Projet local',
      defaultLocale: 'fr',
      supportedLocales: const ['fr'],
    );
    final projection = await const RuntimeProjectProjectionBuilder().build(
      projectRoot: root,
      profile: profile,
    );
    PokemonValidationReport? pokemonReport;
    Object? pokemonFailure;
    if (projection.project.pokemon.enabled) {
      try {
        pokemonReport = await const PokemonProjectValidator(
          FilePokemonReadRepository(),
        ).validate(ProjectFileSystem(root.path));
      } on Object catch (error) {
        pokemonFailure = error;
      }
    }
    final report = const GamePackageGameplayReadinessGate().evaluate(
      projection,
      pokemonValidationReport: pokemonReport,
      pokemonValidationFailure: pokemonFailure,
    );
    final buffer = StringBuffer();
    buffer.writeln('isPlayable=${report.isPlayable}');
    final counts = <String, int>{};
    for (final d in report.diagnostics) {
      if (d.severity != NarrativeProjectDiagnosticSeverity.error) continue;
      counts.update(d.code, (v) => v + 1, ifAbsent: () => 1);
    }
    buffer.writeln('--- error codes ---');
    for (final entry in counts.entries) {
      buffer.writeln('${entry.value.toString().padLeft(4)}  ${entry.key}');
    }
    buffer.writeln('--- all diagnostics ---');
    for (final d in report.diagnostics) {
      buffer.writeln('[${d.severity.name}] ${d.code} | ${d.path} | ${d.message}');
    }
    File('/private/tmp/claude-501/-Users-karim-Project-pokemonProject/b87054f1-b2df-44c4-beb6-5e75d36238ea/scratchpad/readiness.txt')
        .writeAsStringSync(buffer.toString());
    // ignore: avoid_print
    print(buffer.toString());
  }, timeout: const Timeout(Duration(minutes: 10)));
}
