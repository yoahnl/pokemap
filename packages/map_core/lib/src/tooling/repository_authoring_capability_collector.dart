import 'dart:io';

import 'authoring_capability_inventory.dart';

/// Collects repository facts for PMCP-000 without changing project data.
///
/// The collector intentionally uses source files as its input. It is tooling,
/// not runtime discovery, and must never become a gameplay dependency.
final class RepositoryAuthoringCapabilityCollector {
  RepositoryAuthoringCapabilityCollector({
    required Directory repositoryRoot,
  }) : repositoryRoot = repositoryRoot.absolute;

  final Directory repositoryRoot;

  AuthoringCapabilityInventory collect() {
    _requireRepositoryFile('pokemap_authoring_api_mcp_action_catalog.md');

    return AuthoringCapabilityInventory([
      ..._collectModelFields(
        generatedPath:
            'packages/map_core/lib/src/models/project_manifest.freezed.dart',
        sourcePath: 'packages/map_core/lib/src/models/project_manifest.dart',
        mixinMarker: r'mixin _$ProjectManifest {',
        idPrefix: 'model.project_manifest',
        kind: AuthoringCapabilityKind.projectManifestField,
      ),
      ..._collectModelFields(
        generatedPath: 'packages/map_core/lib/src/models/map_data.freezed.dart',
        sourcePath: 'packages/map_core/lib/src/models/map_data.dart',
        mixinMarker: r'mixin _$MapData {',
        idPrefix: 'model.map_data',
        kind: AuthoringCapabilityKind.mapDataField,
      ),
      ..._collectEditorUseCases(),
      ..._collectCoreOperations(),
      ..._collectEvaluationCommands(),
      ..._collectCatalogActions(),
    ]);
  }

  Iterable<AuthoringCapabilityInventoryEntry> _collectModelFields({
    required String generatedPath,
    required String sourcePath,
    required String mixinMarker,
    required String idPrefix,
    required AuthoringCapabilityKind kind,
  }) sync* {
    final source = _readRepositoryFile(generatedPath);
    final start = source.indexOf(mixinMarker);
    if (start < 0) {
      throw StateError('Missing generated model marker: $mixinMarker');
    }
    final end = source.indexOf('  /// Serializes this', start);
    if (end < 0) {
      throw StateError('Missing generated JSON boundary after $mixinMarker');
    }
    final block = source.substring(start, end);
    final fields = RegExp(
      r'\bget\s+([a-zA-Z][a-zA-Z0-9_]*)\s*(?:=>|;)',
    )
        .allMatches(block)
        .map((match) => match.group(1)!)
        .where((field) => field != 'copyWith')
        .toSet()
        .toList()
      ..sort();

    for (final field in fields) {
      yield AuthoringCapabilityInventoryEntry(
        id: '$idPrefix.$field',
        kind: kind,
        ownerPackage: 'map_core',
        // The data field exists, but phase 1 does not yet expose canonical
        // read/write actions for it.
        status: AuthoringCapabilityStatus.missing,
        sourceReference: '$sourcePath#$field',
        runtimeConsumer: 'map_editor,map_runtime',
        hasCanonicalMutation: false,
      );
    }
  }

  Iterable<AuthoringCapabilityInventoryEntry> _collectEditorUseCases() sync* {
    const useCaseRoot = 'packages/map_editor/lib/src/application/use_cases';
    final files = _dartFilesBelow(useCaseRoot);
    final declarationPattern = RegExp(
      r'^(?:final\s+)?class\s+([a-zA-Z][a-zA-Z0-9_]*UseCase)\b',
      multiLine: true,
    );

    for (final file in files) {
      final relativePath = _relativePath(file);
      final source = file.readAsStringSync();
      final classNames = declarationPattern
          .allMatches(source)
          .map((match) => match.group(1)!)
          .toSet()
          .toList()
        ..sort();
      for (final className in classNames) {
        yield AuthoringCapabilityInventoryEntry(
          id: 'editor.use_case.$className',
          kind: AuthoringCapabilityKind.editorUseCase,
          ownerPackage: 'map_editor',
          // Existing UI orchestration is deliberately not called canonical
          // until map_editor migrates in PMCP-080/081.
          status: AuthoringCapabilityStatus.missing,
          sourceReference: '$relativePath#$className',
          runtimeConsumer: 'map_runtime',
          relatedFgLots: _fgLotsForToken(className),
          hasCanonicalMutation: false,
        );
      }
    }
  }

  Iterable<AuthoringCapabilityInventoryEntry> _collectCoreOperations() sync* {
    const operationRoot = 'packages/map_core/lib/src/authoring';
    for (final file in _dartFilesBelow(operationRoot)) {
      final relativePath = _relativePath(file);
      final stem =
          file.uri.pathSegments.last.replaceFirst(RegExp(r'\.dart$'), '');
      final expectedTest = 'packages/map_core/test/${stem}_test.dart';
      final hasExpectedTest = File(
        '${repositoryRoot.path}/$expectedTest',
      ).existsSync();

      yield AuthoringCapabilityInventoryEntry(
        id: 'core.operation.$stem',
        kind: AuthoringCapabilityKind.coreOperation,
        ownerPackage: 'map_core',
        // A source file alone is not enough evidence for SUPPORTED.
        status: hasExpectedTest
            ? AuthoringCapabilityStatus.supported
            : AuthoringCapabilityStatus.missing,
        sourceReference: relativePath,
        runtimeConsumer: 'map_editor,map_runtime',
        evidenceReferences: hasExpectedTest ? [expectedTest] : const [],
        relatedFgLots: _fgLotsForToken(stem),
        hasCanonicalMutation: false,
      );
    }
  }

  Iterable<AuthoringCapabilityInventoryEntry>
      _collectEvaluationCommands() sync* {
    const catalogPath =
        'examples/playable_runtime_host/lib/src/evaluation/scenario/'
        'evaluation_command_catalog.dart';
    const evidencePath = 'examples/playable_runtime_host/test/evaluation/'
        'evaluation_scenario_runner_test.dart';
    final source = _readRepositoryFile(catalogPath);
    final commandIds = RegExp(
      r"^\s*'([^']+)': EvaluationCommandDefinition\(",
      multiLine: true,
    ).allMatches(source).map((match) => match.group(1)!).toSet().toList()
      ..sort();

    if (!File('${repositoryRoot.path}/$evidencePath').existsSync()) {
      throw StateError('Missing evaluation command evidence: $evidencePath');
    }

    for (final commandId in commandIds) {
      yield AuthoringCapabilityInventoryEntry(
        id: 'eval.command.$commandId',
        kind: AuthoringCapabilityKind.evaluationCommand,
        ownerPackage: 'playable_runtime_host',
        status: AuthoringCapabilityStatus.supported,
        sourceReference: '$catalogPath#$commandId',
        runtimeConsumer: 'map_runtime',
        evidenceReferences: const [evidencePath],
        relatedFgLots: _fgLotsForToken(commandId),
        hasCanonicalMutation: false,
      );
    }
  }

  Iterable<AuthoringCapabilityInventoryEntry> _collectCatalogActions() sync* {
    const catalogPath = 'pokemap_authoring_api_mcp_action_catalog.md';
    final source = _readRepositoryFile(catalogPath);
    final actionIds = <String>{};
    var insideCodeFence = false;

    for (final rawLine in source.split('\n')) {
      final line = rawLine.trim();
      if (line.startsWith('```')) {
        insideCodeFence = !insideCodeFence;
        continue;
      }
      if (insideCodeFence && _actionIdPattern.hasMatch(line)) {
        actionIds.add(line);
      }
    }

    for (final match in RegExp(
      r'`([a-z][a-zA-Z0-9_]*(?:\.[a-zA-Z0-9_]+)+)`',
    ).allMatches(source)) {
      final candidate = match.group(1)!;
      if (_actionIdPattern.hasMatch(candidate)) {
        actionIds.add(candidate);
      }
    }

    final sortedActionIds = actionIds.toList()..sort();
    for (final actionId in sortedActionIds) {
      yield AuthoringCapabilityInventoryEntry(
        id: 'action.$actionId',
        kind: AuthoringCapabilityKind.catalogAction,
        ownerPackage: _ownerForAction(actionId),
        status: AuthoringCapabilityStatus.missing,
        sourceReference: '$catalogPath#$actionId',
        runtimeConsumer: _runtimeConsumerForAction(actionId),
        relatedFgLots: _fgLotsForToken(actionId),
        hasCanonicalMutation: false,
      );
    }
  }

  List<File> _dartFilesBelow(String relativeDirectory) {
    final directory = Directory('${repositoryRoot.path}/$relativeDirectory');
    if (!directory.existsSync()) {
      throw StateError('Missing repository directory: $relativeDirectory');
    }
    final files = directory
        .listSync(recursive: true, followLinks: false)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList()
      ..sort((left, right) => left.path.compareTo(right.path));
    return files;
  }

  String _readRepositoryFile(String relativePath) {
    final file = _requireRepositoryFile(relativePath);
    return file.readAsStringSync();
  }

  File _requireRepositoryFile(String relativePath) {
    final file = File('${repositoryRoot.path}/$relativePath');
    if (!file.existsSync()) {
      throw StateError('Missing repository file: $relativePath');
    }
    return file;
  }

  String _relativePath(File file) {
    final normalizedRoot = repositoryRoot.path.replaceAll('\\', '/');
    final normalizedFile = file.absolute.path.replaceAll('\\', '/');
    final prefix = '$normalizedRoot/';
    if (!normalizedFile.startsWith(prefix)) {
      throw StateError('File is outside repository root: ${file.path}');
    }
    return normalizedFile.substring(prefix.length);
  }
}
final RegExp _actionIdPattern = RegExp(
  r'^[a-z][a-zA-Z0-9_]*(?:\.[a-zA-Z0-9_]+)+$',
);

String _ownerForAction(String actionId) {
  final root = actionId.split('.').first;
  if (root == 'battle') return 'map_battle';
  if ({
    'movement',
    'encounter',
    'gameplay',
  }.contains(root)) {
    return 'map_gameplay';
  }
  if ({
    'render',
    'playtest',
    'runtime',
    'evidence',
    'probe',
  }.contains(root)) {
    return 'map_runtime';
  }
  if ({
    'workspace',
    'project',
    'asset',
    'artifact',
    'job',
  }.contains(root)) {
    return 'map_editor';
  }
  if ({
    'map',
    'layer',
    'region',
    'terrain',
    'path',
    'surface',
    'dialogue',
    'scene',
    'storyline',
    'cinematic',
    'event',
    'fact',
    'world_rule',
  }.contains(root)) {
    return 'map_core';
  }
  return 'map_authoring';
}

String _runtimeConsumerForAction(String actionId) {
  final root = actionId.split('.').first;
  if ({
    'server',
    'capability',
    'resource_kind',
    'action',
    'schema',
    'validation_code',
  }.contains(root)) {
    return 'map_editor,map_runtime,mcp';
  }
  return 'map_runtime';
}

List<String> _fgLotsForToken(String token) {
  final normalized = token.toLowerCase();
  if (normalized.contains('newgame') ||
      normalized.contains('new_game') ||
      normalized.contains('party') ||
      normalized.contains('save') ||
      normalized.contains('pc')) {
    return const ['FG-010..FG-030'];
  }
  if (normalized.contains('battle') ||
      normalized.contains('item') ||
      normalized.contains('shop') ||
      normalized.contains('heal') ||
      normalized.contains('progress')) {
    return const ['FG-040..FG-073'];
  }
  if (normalized.contains('event') ||
      normalized.contains('dialogue') ||
      normalized.contains('scene') ||
      normalized.contains('story') ||
      normalized.contains('fact') ||
      normalized.contains('worldrule') ||
      normalized.contains('world_rule')) {
    return const ['FG-080..FG-094'];
  }
  if (normalized.contains('encounter')) {
    return const ['FG-100..FG-108'];
  }
  if (normalized.contains('movement') ||
      normalized.contains('terrain') ||
      normalized.contains('path')) {
    return const ['FG-120..FG-129'];
  }
  if (normalized.contains('trainer') ||
      normalized.contains('badge') ||
      normalized.contains('gym')) {
    return const ['FG-140..FG-147'];
  }
  if (normalized.contains('menu') || normalized.contains('overlay')) {
    return const ['FG-160..FG-165'];
  }
  return const [];
}
