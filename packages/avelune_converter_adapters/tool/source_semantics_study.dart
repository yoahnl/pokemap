import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as path;

void require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<(Directory, Directory)> validateFreshStudyDirectories(
    String sourceRoot, String destinationPath, String evidencePath) async {
  Future<Directory> validate(String raw) async {
    final absolute = path.normalize(path.absolute(raw));
    require(
        await FileSystemEntity.type(absolute, followLinks: false) ==
            FileSystemEntityType.notFound,
        'A fresh output directory is required');
    var ancestor = path.dirname(absolute);
    while (await FileSystemEntity.type(ancestor, followLinks: false) ==
        FileSystemEntityType.notFound) {
      final parent = path.dirname(ancestor);
      require(parent != ancestor, 'An existing output ancestor is required');
      ancestor = parent;
    }
    require(
        await FileSystemEntity.type(ancestor, followLinks: false) ==
                FileSystemEntityType.directory &&
            await Directory(ancestor).resolveSymbolicLinks() == ancestor,
        'Output ancestors must be canonical directories without symlink aliases');
    require(
        !path.equals(sourceRoot, absolute) &&
            !path.isWithin(sourceRoot, absolute),
        'Output must be outside the source');
    return Directory(absolute);
  }

  final destination = await validate(destinationPath);
  final evidence = await validate(evidencePath);
  require(
      !path.equals(destination.path, evidence.path) &&
          !path.isWithin(destination.path, evidence.path) &&
          !path.isWithin(evidence.path, destination.path),
      'Destination and evidence directories must be separate');
  return (destination, evidence);
}

Future<void> main(List<String> args) async {
  require(
      args.length == 6 && args.last == '--approved-study',
      'Expected source root, fresh destination parent, fresh evidence directory, '
      'comma-separated map IDs, project name, --approved-study');
  final sourceRoot = await Directory(args[0]).resolveSymbolicLinks();
  final (destination, evidence) =
      await validateFreshStudyDirectories(sourceRoot, args[1], args[2]);
  final mapIds = args[3].split(',').map(int.parse).toList()..sort();
  require(mapIds.isNotEmpty && mapIds.toSet().length == mapIds.length,
      'Unique source map IDs are required');
  await destination.create(recursive: true);
  await evidence.create(recursive: true);
  require(
      await destination.resolveSymbolicLinks() == destination.path &&
          await evidence.resolveSymbolicLinks() == evidence.path,
      'Created output directories must remain canonical');
  final record = <String, Object?>{
    'kind': 'sourceSemanticStudyQualification',
    'version': 1,
    'sourceRoot': sourceRoot,
    'selectedSourceMapIds': mapIds,
    'sourceScriptsExecuted': 0,
    'aiCalls': 0,
    'published': false,
    'fullGameplayCertified': false,
    'status': 'running',
  };
  Future<void> save(String name, Object? value) async {
    await File(path.join(evidence.path, name))
        .writeAsString(jsonEncode(value), flush: true);
  }

  final workflow = ConverterWorkflow();
  ConverterWorkflowPhase? previousPhase;
  final subscription = workflow.events.listen((event) {
    if (event.state.phase == previousPhase) return;
    previousPhase = event.state.phase;
    stdout.writeln(jsonEncode(
        {'phase': previousPhase?.name, 'revision': event.state.revision}));
  });
  try {
    final snapshot = await workflow.scanSource(ConverterSourceSelection(
        rootPath: sourceRoot,
        logicalProjectNamespace: ConverterId('source-semantic-study')));
    require(snapshot.state == SourceScanState.complete,
        'A complete source snapshot is required');
    record['sourceSnapshotHash'] = snapshot.canonicalHash.value;
    record['availableSourceMapCount'] =
        workflow.state.availableSourceMapIds.length;
    await save('source-snapshot.json', snapshot.toJson());
    workflow.updateSettings(ConverterStudySettings(
        projectName: args[4],
        parentPath: destination.path,
        folderName: 'Projet converti',
        selectedSourceMapIds: mapIds,
        profileAcknowledgement: SourceStudyAcknowledgement(
            sourceSnapshotHash: snapshot.canonicalHash,
            profileEvidenceHash: snapshot.profile.evidenceHash,
            humanConfirmed: true,
            reason:
                'Explicitly approved local offline study; full game conversion remains uncertified.'),
        assetOutputMode: AssetOutputMode.sharedAtlas));
    final prepared = await workflow.prepareStudy();
    await save('normalized-source.json', prepared.normalizedSource.toJson());
    await save('preview-plan.json', prepared.previewPlan?.toJson());
    await save('review-session.json', prepared.reviewSession?.toJson());
    record['diagnostics'] = [
      ...prepared.normalizedSource.diagnostics.map((item) => item.toJson()),
      ...prepared.composition.diagnostics.map((item) => item.toJson()),
    ];
    require(prepared.canApprove && prepared.nativeDraft != null,
        'The source study is not admissible; diagnostics were retained');
    final draft = prepared.nativeDraft!;
    require(draft.compositionEvidence['sourceSemantics'] is Map,
        'The source profile has no qualified semantic projection');
    await save('composition-evidence.json', draft.compositionEvidence);
    final resolver =
        SourceSemanticResolver.forProject(prepared.normalizedSource);
    await save('source-transition-oracle.json', {
      'profile': resolver.profile.toJson(),
      'maps': [
        for (final normalized in prepared.normalizedSource.maps)
          {
            'sourceMapId': normalized.map.sourceMapId,
            'width': normalized.map.width,
            'height': normalized.map.height,
            'statuses': [
              for (var y = 0; y < normalized.map.height; y++)
                for (var x = 0; x < normalized.map.width; x++)
                  for (final direction in SourceCardinalDirection.values)
                    resolver
                        .resolveTransition(
                            resolver.cellAt(normalized.map.sourceMapId, x, y),
                            resolver.cellAt(normalized.map.sourceMapId,
                                x + direction.dx, y + direction.dy),
                            direction)
                        .status
                        .name
            ],
          }
      ],
    });

    record['nativeDraftHash'] = draft.canonicalHash.value;
    record['sourceSemantics'] = draft.compositionEvidence['sourceSemantics'];
    final approval = workflow.approvePrepared(
        sessionRevision: prepared.sessionRevision,
        preparationHash: prepared.preparationHash,
        humanConfirmed: true);
    await save('approved-plan.json', approval.approvedPlan.toJson());
    final result = await workflow.writeApproved(approval);
    require(
        result.receipt.verified && result.sourceUnchanged && !result.published,
        'A verified unpublished output and unchanged source are required');
    record['projectPath'] = result.receipt.projectPath;
    record['stagingRoot'] = result.receipt.stagingRoot;
    record['nativeRevision'] = result.receipt.nativeRevision;
    record['sourceUnchanged'] = result.sourceUnchanged;
    const reader = LocalProjectFileReader();
    final handles = WorkspaceHandleStore();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [result.receipt.stagingRoot], fileReader: reader);
    final opener = ProjectOpenService(
        policy: policy, fileReader: reader, handles: handles);
    final opened = await opener.openProject(result.receipt.projectPath);
    try {
      final native = await ProjectSnapshotLoader(handles: handles)
          .load(opened.projectHandle, policy: ProjectSnapshotLoadPolicy.strict);
      require(
          native.loadDiagnostics.isEmpty && native.maps.length == mapIds.length,
          'Strict native reopening must return all converted maps');
      final expected = {
        for (final mutation in draft.mutations)
          if (mutation.actionId == 'map.save')
            (mutation.parameters['map'] as Map)['id']:
                canonicalHashOf(mutation.parameters['map']).value
      };
      for (final map in native.maps) {
        require(expected[map.id] == canonicalHashOf(map.toJson()).value,
            'Reopened native map differs from its deterministic conversion');
        MapValidator.validate(map, projectDialogueContext: native.manifest);
      }
      ProjectValidator.validate(native.manifest, maps: native.maps);
      record['nativeMaps'] = native.maps
          .map((map) => {
                'id': map.id,
                'name': map.name,
                'hash': canonicalHashOf(map.toJson()).value,
                'defaultSpawnId': map.mapMetadata.defaultSpawnId,
                'placedElementCount': map.placedElements.length,
              })
          .toList();
      record['nativeCharacters'] = native.manifest.characters
          .map((character) => {
                'id': character.id,
                'animationCount': character.animations.length,
                'frameWidth': character.frameWidth,
                'frameHeight': character.frameHeight,
              })
          .toList();
      record['strictNativeReadPassed'] = true;
    } finally {
      opener.closeWorkspace(opened.workspaceHandle);
    }
    record['status'] = 'nativeStudyVerified';
  } catch (error, stack) {
    record['status'] = 'failed';
    record['error'] = error.toString();
    record['stack'] = stack.toString();
    record['workflowFailureCode'] = workflow.state.failure?.code;
    record['preservedFailureStagingPath'] = workflow.state.failure?.stagingPath;
    exitCode = 2;
  } finally {
    await subscription.cancel();
    await workflow.dispose();
    await save('qualification.json', record);
    stdout.writeln(jsonEncode({
      'status': record['status'],
      'projectPath': record['projectPath'],
      'error': record['error'],
      'evidencePath': evidence.path
    }));
  }
}
