import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';

import 'source_external_original_fixture.dart';

Future<SourceEventStudyComposition> composeExternalOriginalSource({
  required String sourceRoot,
  required String snapshotPath,
  required String outputParentPath,
  void Function(String, int)? onStage,
}) async {
  final elapsed = Stopwatch()..start();
  void stage(String name) => onStage?.call(name, elapsed.elapsedMilliseconds);
  const selected = [98, 100, 102, 166, 205];
  const limits = NativeWriteLimits(maxArtifacts: 1024, maxMutations: 2048);
  stage('normalize.start');
  final fixture = await readExternalOriginalSource(sourceRoot, snapshotPath);
  stage('normalize.complete');
  final source = fixture.source;
  final selectionHash = literalSelectionHash(source, selected);
  final decisions = [
    for (final map in source.maps)
      for (final event in map.map.events)
        for (final page in event.pages)
          for (final command in page.commands)
            if (command.code == 201 &&
                command.parameters.length >= 2 &&
                command.parameters[0] == 0 &&
                command.parameters[1] is int &&
                !selected.contains(command.parameters[1]))
              LiteralDependencyDecision(
                  sourceSnapshotHash: source.snapshot.canonicalHash,
                  selectionHash: selectionHash,
                  locator: command.sourceLocator,
                  targetSourceMapId: command.parameters[1] as int,
                  decision: LiteralDependencyDisposition.excludeStudy)
  ];
  stage('literal.start');
  final tiles = await const LiteralTileComposer().compose(
      source: source,
      files: fixture.files,
      selectedSourceMapIds: selected,
      projectName: 'Original six native transitions',
      parentPath: outputParentPath,
      folderName: 'original-six-transitions',
      sourceRootPath: sourceRoot,
      allowFirstFrameAutotiles: true,
      dependencyDecisions: decisions,
      limits: limits);
  stage('literal.complete');
  if (tiles.draft == null) {
    throw StateError(
        'Original literal refused: ${tiles.diagnostics.map((d) => d.code)}');
  }
  stage('semantics.start');
  final semantics = await const SourceSemanticStudyComposer().compose(
      source: source, base: tiles, files: fixture.files, limits: limits);
  stage('semantics.complete');
  if (semantics == null) throw StateError('Original semantics unavailable.');
  stage('events.start');
  final events = await const SourceEventStudyComposer().compose(
      source: source, base: semantics, files: fixture.files, limits: limits);
  stage('events.complete');
  if (events == null) throw StateError('Original events unavailable.');
  return events;
}
