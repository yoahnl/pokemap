import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/services/narrative_studio_validation_coordinator.dart';
import 'package:map_editor/src/application/services/pokemon_project_data_reader.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_runtime_smoke_receipt_repository.dart';
import 'package:path/path.dart' as p;

const _usageExitCode = 64;
const _softwareExitCode = 70;

Future<void> main(List<String> arguments) async {
  final invocation = _parseArguments(arguments);
  if (invocation case _CliUsageError(:final message)) {
    stderr.writeln(message);
    stderr.writeln(_usage);
    exit(_usageExitCode);
  }
  if (invocation is _CliHelp) {
    stdout.writeln(_usage);
    return;
  }
  final command = invocation as _CliCommand;
  try {
    final report = command.reportInput == null
        ? await _validateProject(command)
        : decodeNarrativeValidationReport(
            await File(command.reportInput!).readAsString(),
          );
    final encoded = encodeNarrativeValidationReport(report);
    final output = command.output;
    if (output == null) {
      stdout.writeln(encoded);
    } else {
      await _writeAtomically(File(output), '$encoded\n');
      stdout.writeln(
        '${report.overallStatus.name}: ${p.normalize(p.absolute(output))}',
      );
    }
    exit(narrativeValidationExitCode(report.overallStatus));
  } on Object catch (error) {
    stderr.writeln('Narrative validation unavailable: $error');
    exit(_softwareExitCode);
  }
}

Future<NarrativeMultidimensionalValidationReport> _validateProject(
  _CliCommand command,
) async {
  final projectRoot = p.normalize(p.absolute(command.projectRoot!));
  final session = await NarrativeEventAuthoringSession.prepare(
    p.join(projectRoot, 'project.json'),
  );
  final catalogs = await _loadPokemonCatalogs(
    projectRoot,
    enabled: session.manifest.pokemon.enabled,
  );
  final projectReport = validateNarrativeProject(
    session.manifest,
    maps: session.maps,
    knownSpeciesIds: catalogs.speciesIds,
    knownMoveIds: catalogs.moveIds,
    requirePokemonCatalogs: session.manifest.pokemon.enabled,
  );
  const receiptRepository = NarrativeRuntimeSmokeReceiptRepository();
  final fingerprint =
      await receiptRepository.computeProjectFingerprint(projectRoot);
  final receipt = await receiptRepository.read(
    projectRoot: projectRoot,
    expectedFingerprint: fingerprint,
    profile: selbrumeReleaseV1Profile,
  );
  return const NarrativeStudioValidationCoordinator().coordinate(
    project: session.manifest,
    maps: session.maps,
    projectReport: projectReport,
    projectFingerprint: fingerprint,
    profile: selbrumeReleaseV1Profile,
    runtimeReceipt: receipt,
  );
}

Future<({Set<String>? speciesIds, Set<String>? moveIds})> _loadPokemonCatalogs(
  String projectRoot, {
  required bool enabled,
}) async {
  if (!enabled) {
    return (speciesIds: const <String>{}, moveIds: const <String>{});
  }
  final workspace = ProjectFileSystem(projectRoot);
  final reader = PokemonProjectDataReader();
  Set<String>? speciesIds;
  Set<String>? moveIds;
  try {
    speciesIds = {
      for (final entry in await reader.listSpeciesIndexEntries(workspace))
        entry.id,
    };
  } on Object {
    speciesIds = null;
  }
  try {
    final catalog = await reader.readCatalogByKey(workspace, 'moves');
    moveIds = {
      for (final entry in catalog.entries)
        if (entry['id'] case final String id) id,
    };
  } on Object {
    moveIds = null;
  }
  return (speciesIds: speciesIds, moveIds: moveIds);
}

Future<void> _writeAtomically(File output, String contents) async {
  await output.parent.create(recursive: true);
  final temporary = File('${output.path}.$pid.tmp');
  try {
    await temporary.writeAsString(contents, flush: true);
    await temporary.rename(output.path);
  } finally {
    if (await temporary.exists()) await temporary.delete();
  }
}

sealed class _CliInvocation {
  const _CliInvocation();
}

final class _CliCommand extends _CliInvocation {
  const _CliCommand({
    required this.projectRoot,
    required this.reportInput,
    required this.output,
  });

  final String? projectRoot;
  final String? reportInput;
  final String? output;
}

final class _CliHelp extends _CliInvocation {
  const _CliHelp();
}

final class _CliUsageError extends _CliInvocation {
  const _CliUsageError(this.message);

  final String message;
}

_CliInvocation _parseArguments(List<String> arguments) {
  if (arguments.length == 1 &&
      (arguments.single == '--help' || arguments.single == '-h')) {
    return const _CliHelp();
  }
  String? projectRoot;
  String? profile;
  String? format;
  String? output;
  String? reportInput;
  for (var index = 0; index < arguments.length; index++) {
    final option = arguments[index];
    if (!const {
      '--project-root',
      '--profile',
      '--format',
      '--output',
      '--report-input',
    }.contains(option)) {
      return _CliUsageError('Unknown option "$option".');
    }
    if (index + 1 >= arguments.length ||
        arguments[index + 1].startsWith('--')) {
      return _CliUsageError('Missing value for "$option".');
    }
    final value = arguments[++index].trim();
    if (value.isEmpty) return _CliUsageError('Blank value for "$option".');
    switch (option) {
      case '--project-root':
        projectRoot = value;
      case '--profile':
        profile = value;
      case '--format':
        format = value;
      case '--output':
        output = value;
      case '--report-input':
        reportInput = value;
    }
  }
  if (format != 'json') {
    return const _CliUsageError('Only "--format json" is supported.');
  }
  if ((projectRoot == null) == (reportInput == null)) {
    return const _CliUsageError(
      'Provide exactly one of --project-root or --report-input.',
    );
  }
  if (projectRoot != null && profile != selbrumeReleaseV1Profile.id) {
    return _CliUsageError(
      'Project validation requires "--profile ${selbrumeReleaseV1Profile.id}".',
    );
  }
  if (reportInput != null && profile != null) {
    return const _CliUsageError(
      '--profile cannot be combined with --report-input.',
    );
  }
  return _CliCommand(
    projectRoot: projectRoot,
    reportInput: reportInput,
    output: output,
  );
}

const _usage = '''
Usage:
  dart run tool/validate_narrative_project.dart \\
    --project-root <path> --profile selbrume-release-v1 \\
    --format json [--output <path>]

  dart run tool/validate_narrative_project.dart \\
    --report-input <report.json> --format json [--output <path>]

Exit codes: 0=pass, 1=fail, 2=indeterminate, 3=notRun, 64=usage.
''';
