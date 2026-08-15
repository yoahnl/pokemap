import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../ports/project_file_reader.dart';
import '../ports/project_manifest_bootstrap_writer.dart';
import '../support/authoring_fingerprint.dart';
import 'workspace_policy.dart';

final class ProjectPokemonRulesetBootstrapException implements Exception {
  const ProjectPokemonRulesetBootstrapException(this.code, this.message);

  final String code;
  final String message;

  @override
  String toString() =>
      'ProjectPokemonRulesetBootstrapException($code): $message';
}

final class ProjectPokemonRulesetBootstrapPreview {
  const ProjectPokemonRulesetBootstrapPreview({
    required this.projectName,
    required this.currentRevision,
    required this.repairRequired,
    required this.ruleset,
  });

  final String projectName;
  final String currentRevision;
  final bool repairRequired;
  final PokemonRulesetProfile ruleset;

  Map<String, Object?> toJson() => {
        'projectName': projectName,
        'currentRevision': currentRevision,
        'repairRequired': repairRequired,
        'confirmation': repairRequired
            ? ProjectPokemonRulesetBootstrapService.confirmation
            : null,
        'ruleset': ruleset.toJson(),
      };
}

final class ProjectPokemonRulesetBootstrapReceipt {
  const ProjectPokemonRulesetBootstrapReceipt({
    required this.changed,
    required this.beforeRevision,
    required this.afterRevision,
    required this.ruleset,
  });

  final bool changed;
  final String beforeRevision;
  final String afterRevision;
  final PokemonRulesetProfile ruleset;

  Map<String, Object?> toJson() => {
        'changed': changed,
        'beforeRevision': beforeRevision,
        'afterRevision': afterRevision,
        'ruleset': ruleset.toJson(),
      };
}

abstract interface class ProjectPokemonRulesetBootstrapApiPort {
  Future<Map<String, Object?>> inspect(String projectRootPath);

  Future<Map<String, Object?>> repair({
    required String projectRootPath,
    required String expectedRevision,
    required String confirmation,
  });
}

final class ProjectPokemonRulesetBootstrapService
    implements ProjectPokemonRulesetBootstrapApiPort {
  const ProjectPokemonRulesetBootstrapService({
    required WorkspacePolicy policy,
    required ProjectFileReader fileReader,
    required ProjectManifestBootstrapWriter writer,
  })  : _policy = policy,
        _fileReader = fileReader,
        _writer = writer;

  static const confirmation = 'REPAIR POKEMON RULESET';

  final WorkspacePolicy _policy;
  final ProjectFileReader _fileReader;
  final ProjectManifestBootstrapWriter _writer;

  Future<ProjectPokemonRulesetBootstrapPreview> inspectProject(
    String projectRootPath,
  ) async {
    final canonicalRoot = await _policy.authorizeProjectRoot(projectRootPath);
    final bytes = await _fileReader.readBytes(
      projectRoot: canonicalRoot,
      relativePath: 'project.json',
    );
    final candidate = _decodeCandidate(bytes);
    return ProjectPokemonRulesetBootstrapPreview(
      projectName: candidate.manifest.name,
      currentRevision: _revision(bytes),
      repairRequired: candidate.repairRequired,
      ruleset: candidate.manifest.pokemon.ruleset,
    );
  }

  @override
  Future<Map<String, Object?>> inspect(String projectRootPath) async =>
      (await inspectProject(projectRootPath)).toJson();

  Future<ProjectPokemonRulesetBootstrapReceipt> repairProject({
    required String projectRootPath,
    required String expectedRevision,
    required String confirmation,
  }) async {
    if (confirmation != ProjectPokemonRulesetBootstrapService.confirmation) {
      throw const ProjectPokemonRulesetBootstrapException(
        'project.ruleset_repair_confirmation_required',
        'The exact Pokemon ruleset repair confirmation is required.',
      );
    }
    final canonicalRoot = await _policy.authorizeProjectRoot(projectRootPath);
    final bytes = await _fileReader.readBytes(
      projectRoot: canonicalRoot,
      relativePath: 'project.json',
    );
    final currentRevision = _revision(bytes);
    if (currentRevision != expectedRevision) {
      throw const ProjectPokemonRulesetBootstrapException(
        'project.ruleset_repair_revision_conflict',
        'The project manifest changed after the repair preview.',
      );
    }
    final candidate = _decodeCandidate(bytes);
    if (!candidate.repairRequired) {
      return ProjectPokemonRulesetBootstrapReceipt(
        changed: false,
        beforeRevision: currentRevision,
        afterRevision: currentRevision,
        ruleset: candidate.manifest.pokemon.ruleset,
      );
    }
    final replacementBytes = utf8.encode(
      '${const JsonEncoder.withIndent('  ').convert(candidate.repairedJson)}\n',
    );
    try {
      await _writer.replaceManifest(
        projectRoot: canonicalRoot,
        expectedBytes: bytes,
        replacementBytes: replacementBytes,
      );
    } on ProjectManifestBootstrapWriteException catch (error) {
      throw ProjectPokemonRulesetBootstrapException(error.code, error.message);
    }
    return ProjectPokemonRulesetBootstrapReceipt(
      changed: true,
      beforeRevision: currentRevision,
      afterRevision: _revision(replacementBytes),
      ruleset: candidate.manifest.pokemon.ruleset,
    );
  }

  @override
  Future<Map<String, Object?>> repair({
    required String projectRootPath,
    required String expectedRevision,
    required String confirmation,
  }) async =>
      (await repairProject(
        projectRootPath: projectRootPath,
        expectedRevision: expectedRevision,
        confirmation: confirmation,
      ))
          .toJson();
}

final class _BootstrapCandidate {
  const _BootstrapCandidate({
    required this.manifest,
    required this.repairRequired,
    required this.repairedJson,
  });

  final ProjectManifest manifest;
  final bool repairRequired;
  final Map<String, dynamic> repairedJson;
}

_BootstrapCandidate _decodeCandidate(List<int> bytes) {
  try {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map) throw const FormatException();
    final json = Map<String, dynamic>.from(decoded);
    final pokemonValue = json['pokemon'];
    if (pokemonValue is! Map) throw const FormatException();
    final pokemon = Map<String, dynamic>.from(pokemonValue);
    final repairRequired =
        !pokemon.containsKey('ruleset') || pokemon['ruleset'] == null;
    if (repairRequired) {
      pokemon['ruleset'] = PokemonRulesetProfile.pokeMapBetaV1.toJson();
      json['pokemon'] = pokemon;
    }
    final manifest = ProjectManifest.fromJson(json);
    return _BootstrapCandidate(
      manifest: manifest,
      repairRequired: repairRequired,
      repairedJson: json,
    );
  } on Object {
    throw const ProjectPokemonRulesetBootstrapException(
      'project.manifest_invalid',
      'The project manifest cannot be repaired automatically.',
    );
  }
}

String _revision(List<int> bytes) => computeAuthoringBytesFingerprint(
      bytes,
      logicalName: 'project.json',
    );
