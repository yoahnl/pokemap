import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/native_mutation_batches.dart';
import 'package:path/path.dart' as path;
import 'lot6_connection_preflight.dart';
import 'lot6_source_decision_refresh.dart';
import 'lot6_routed_door_patterns.dart';

Future<void> main(List<String> args) async {
  if (args.length < 2 || args.length > 3 || !const {'world', 'full'}.contains(args[1])) {
    throw ArgumentError('Provide an unused absolute evidence directory, world or full, and an optional destination folder name.');
  }
  final contentScope = ConverterContentScope.values.byName(args[1]);
  final folderName = args.length == 3 ? args[2] : contentScope == ConverterContentScope.world
      ? 'Kanto — Monde explorable'
      : 'Kanto complet — EV10';
  if (folderName.isEmpty || folderName.trim() != folderName ||
      folderName == '.' || folderName == '..' ||
      folderName.contains('/') || folderName.contains(r'\') ||
      folderName.contains('\u0000') || path.isAbsolute(folderName)) {
    throw ArgumentError('The destination must be one nonempty folder name.');
  }
  final evidence = Directory(args.first);
  const evidenceParent = '/Users/karim/Project/avelune project/Inventaires/Kanto EV-10/lot6';
  if (!evidence.isAbsolute ||
      path.dirname(evidence.path) != evidenceParent ||
      path.normalize(evidence.path) != evidence.path ||
      await Directory(evidenceParent).resolveSymbolicLinks() != evidenceParent ||
      await FileSystemEntity.type(evidence.path, followLinks: false) != FileSystemEntityType.notFound) {
    throw ArgumentError('Evidence must be an unused child of the canonical lot6 directory.');
  }
  await evidence.create(recursive: true);
  const evidenceRoot = '/Users/karim/Project/avelune project/Inventaires/Kanto EV-09';
  var decisions = Map<String, Object?>.from(jsonDecode(await File('$evidenceRoot/preuves/source_adaptations.json').readAsString()) as Map);
  const sourceRoot = '/Users/karim/Downloads/The-PMon-World-Project-main/The Pokémon World Project - Kanto';
  const baseProfilePath = '/Users/karim/Project/avelune project/Inventaires/Kanto EV-10/source_profile_ev10_pickups.json';
  final rawProfile = Map<String, Object?>.from(jsonDecode(
      await File(baseProfilePath).readAsString()) as Map);
  var interpretationProfile = SourceInterpretationProfile.fromJson({
    ...rawProfile,
    'profileId': 'kanto-lot6-native-services-and-inline-audio',
    'presentationBindings': {
      ...rawProfile['presentationBindings'] as Map? ?? const {},
      'characterSubstitutions': [
        ...(rawProfile['presentationBindings']
                as Map?)?['characterSubstitutions'] as List? ??
            const [],
        {
          'requestedCharset': 'trainer_SCIENTIST',
          'actualCharset': 'NPC_FRLG_SCIENTIST',
          'targetSha256':
              'bf161720028e8197295d993a916d1ecf940f7701f094c3f0dcaaa967697e3c74',
          'reason':
              'Adaptation graphique déclarée du portrait : charset demandé absent ; conserver le scientifique de la scène avec un fichier attesté. Parité visuelle source non qualifiée.',
        },
      ],
    },
    'sections': {
      ...rawProfile['sections'] as Map,
      'events.Audio_Play': {
        'index': 93,
        'name': 'Audio_Play',
        'sha256': 'e21c2f9b086f99777b7421c850e4b04cb8e5db574876b3fbb9c0fd9932e1d1fb',
      },
    },
  });
  final profilePath = '${evidence.path}/interpretation-profile.json';
  await File(profilePath).writeAsString(
      jsonEncode(interpretationProfile.toJson()), flush: true);
  final watch = Stopwatch()..start();
  var appliedMutations = 0;
  final workflow = ConverterWorkflow(nativeWriteCheckpoint: (stage, staging, project) {
    if (stage == NativeWriteStage.afterMutation) appliedMutations++;
    if (stage != NativeWriteStage.afterMutation || appliedMutations % 25 == 0) {
      print(jsonEncode({
        'nativeStage': stage.name,
        'appliedMutationEnvelopes': appliedMutations,
        'stagingRoot': staging,
        'projectPath': project,
        'elapsedMs': watch.elapsedMilliseconds,
      }));
    }
  });
  final result = <String, Object?>{
    'kind': contentScope == ConverterContentScope.world
        ? 'kantoWorldFoundationDelivery'
        : 'fullKantoCanonicalConverterDelivery',
    'userRequest': 'Complete Kanto with doors and connections under Project/avelune project; Avelune battles; lot6 publication and qualification; no Git operations',
    'sourceScriptsExecuted': 0,
    'interpretationProfileId': interpretationProfile.profileId.value,
    'interpretationProfilePath': profilePath,
    'interpretationProfileHash': interpretationProfile.canonicalHash.value,
    'aiSourceInferenceCalls': 0,
    'contentScope': contentScope.name,
    'finalPlayableCertified': false,
    'projectPath': '/Users/karim/Project/avelune project/$folderName',
  };
  Future<void> save() => File('${evidence.path}/delivery.json')
      .writeAsString(jsonEncode(result), flush: true);
  String? lastPhase;
  SupplementedSourceTree? sourceTree;
  var lastProgressMs = 0;
  final subscription = workflow.events.listen((event) {
    final phase = event.state.phase?.name;
    if (phase != lastPhase || event.kind == ConverterWorkflowEventKind.failed ||
        watch.elapsedMilliseconds - lastProgressMs >= 10000) {
      lastPhase = phase;
      lastProgressMs = watch.elapsedMilliseconds;
      print(jsonEncode({
        'phase': phase,
        'kind': event.kind.name,
        'elapsedMs': watch.elapsedMilliseconds,
        'failure': event.state.failure?.toString(),
        'progress': event.state.progress == null ? null : {
          'done': event.state.progress!.done,
          'total': event.state.progress!.total,
          'unit': event.state.progress!.unit.name,
        },
      }));
    }
  });
  final termination = ProcessSignal.sigterm.watch().listen((_) {
    workflow.cancelCurrentJob();
  });
  try {
    final selection = ConverterSourceSelection(
      rootPath: sourceRoot,
      supplementalRootPaths: [
        sourceRoot.replaceFirst(' - Kanto', ' - Johto'),
        sourceRoot.replaceFirst(' - Kanto', ' - Hoenn'),
      ],
      logicalProjectNamespace: ConverterId('ev09-real-source-defects'),
    );
    final snapshot = await workflow.scanSource(selection);
    await File('${evidence.path}/source-snapshot.json')
        .writeAsString(jsonEncode(snapshot.toJson()), flush: true);
    result.addAll({
      'phase': 'sourceScanned',
      'snapshotHash': snapshot.canonicalHash.value,
      'profileEvidenceHash': snapshot.profile.evidenceHash.value,
      'sourceEntries': snapshot.entries.length,
      'elapsedMs': watch.elapsedMilliseconds,
    });
    await save();
    if (snapshot.canonicalHash.value != decisions['snapshotHash']) {
      decisions = refreshLot6SourceDecisionsForRootClippings(snapshot, decisions);
      result['sourceDecisionRefresh'] = decisions['inventoryRefresh'];
      await File('${evidence.path}/refreshed-source-decisions.json').writeAsString(jsonEncode(decisions), flush: true);
      await save();
    }
    final parent = Directory('/Users/karim/Project/avelune project');
    if (await parent.resolveSymbolicLinks() != parent.path ||
        await FileSystemEntity.type('${parent.path}/$folderName',
                followLinks: false) !=
            FileSystemEntityType.notFound) {
      throw StateError('The final destination must be fresh and canonical');
    }
    final ids = snapshot.entries
        .map((entry) => RegExp(r'^Data/Map(\d+)\.rxdata$')
            .firstMatch(entry.relativePath))
        .whereType<RegExpMatch>()
        .map((match) => int.parse(match.group(1)!))
        .toList()
      ..sort();
    if (ids.length != 383) throw StateError('Expected exactly383 source maps');
    final tree = await SupplementedSourceTree.open(sourceRoot,
        supplementalRootPaths: selection.supplementalRootPaths);
    sourceTree = tree;
    final files = await SnapshotSourceFiles.bind(source: tree, snapshot: snapshot);
    if (contentScope == ConverterContentScope.full) {
      final patterns = await deriveLot6RoutedDoorPatterns(
          snapshot: snapshot, files: files, profile: interpretationProfile);
      interpretationProfile = patterns.profile;
      await File(profilePath).writeAsString(
          jsonEncode(interpretationProfile.toJson()), flush: true);
      await File('${evidence.path}/routed-door-pattern-declarations.json')
          .writeAsString(jsonEncode(patterns.evidence), flush: true);
      result['interpretationProfileHash'] = interpretationProfile.canonicalHash.value;
      result['routedDoorPatternDeclarations'] = patterns.evidence;
      await save();
    }
    final dependencySource = await const RmxpSourceNormalizer().normalize(
        snapshot: snapshot, files: files, selectedMapIds: {295},
        includeEventSystem: true, interpretationProfile: interpretationProfile);
    final dynamicCommand = dependencySource.maps.single.map.events
        .singleWhere((event) => event.sourceEventId == 12).pages
        .singleWhere((page) => page.originalPageIndex == 1).commands
        .singleWhere((command) => command.originalIndex == 17);
    if (dynamicCommand.code != 201 || dynamicCommand.parameters.first != 1) {
      throw StateError('The historical variable transfer decision no longer matches its source');
    }
    await File('${evidence.path}/dynamic-transfer-source.json').writeAsString(
        jsonEncode(dynamicCommand.toJson()), flush: true);
    final selectionHash = canonicalHashOf({
      'kind': 'literalSelection',
      'version': 1,
      'sourceSnapshotHash': snapshot.canonicalHash.value,
      'logicalProjectNamespace': snapshot.logicalProjectNamespace.value,
      'selectedSourceMapIds': ids,
    });
    final rows = [{
      'sourceSnapshotHash': snapshot.canonicalHash.value,
      'selectionHash': selectionHash.value,
      'locator': {'file': 'Data/Map295.rxdata', 'mapId': 295, 'eventId': 12,
        'pageIndex': 1, 'commandIndex': 17, 'tileId': null, 'line': null},
      'targetSourceMapId': null,
      'decision': 'excludeStudy',
    }];
    await File('${evidence.path}/dependency-decisions.json').writeAsString(jsonEncode(rows), flush: true);
    workflow.updateSettings(ConverterStudySettings(
      contentScope: contentScope,
      projectName: folderName,
      parentPath: parent.path,
      folderName: folderName,
      selectedSourceMapIds: ids,
      interpretationProfile: interpretationProfile,
      sourceAdaptations: (decisions['decisions'] as List).map(SourceEventAdaptation.fromJson).toList(),
      missingItemBindings: contentScope == ConverterContentScope.full
          ? (decisions['missingItemBindings'] as List).map(SourceMissingItemBinding.fromJson).toList()
          : const [],
      allowFirstFrameAutotiles: true,
      profileAcknowledgement: SourceStudyAcknowledgement(
        sourceSnapshotHash: snapshot.canonicalHash,
        profileEvidenceHash: snapshot.profile.evidenceHash,
        humanConfirmed: true,
        reason: 'User authorized the full deterministic native Kanto conversion and existing Essentials21.1 study profile in this chat; retain Avelune battles',
      ),
      dependencyDecisions: [
        for (final Map row in rows)
          LiteralDependencyDecision(
            sourceSnapshotHash: Sha256Hash(row['sourceSnapshotHash']),
            selectionHash: Sha256Hash(row['selectionHash']),
            locator: SourceLocator.fromJson(row['locator']),
            targetSourceMapId: row['targetSourceMapId'],
            decision: LiteralDependencyDisposition.values.byName(row['decision']),
          ),
      ],
    ));
    final prepared = await workflow.prepareStudy();
    final draft = prepared.nativeDraft;
    if (draft != null) {
      final budget = sourceCatalogStudyWriteLimitsFor(383, includeNativeCatalog: true,
          fullGameContent: contentScope == ConverterContentScope.full);
      final images = <Map<String, Object?>>[];
      final nativeImages = <String, int>{};
      for (final role in ['native', 'sourceWitness']) {
        for (final artifact in role == 'native' ? draft.artifacts : draft.sourceArtifacts) {
          if (artifact.reference.mediaType != 'image/png') continue;
          final size = const NativePngValidator().headerDimensions(artifact.bytes, limits: budget);
          final pixels = size.$1 * size.$2;
          images.add({'role': role, 'handle': artifact.handle,
            'width': size.$1, 'height': size.$2, 'pixels': pixels});
          if (role == 'native') nativeImages[artifact.handle] = pixels;
        }
      }
      final retainedPixels = images.fold<int>(0, (sum, image) => sum + (image['pixels'] as int));
      final logicalPixels = draft.mutations.expand(nativeImportParameters)
          .fold<int>(0, (sum, row) => sum + (nativeImages[row['artifactHandle']] ?? 0));
      final nativeBytes = draft.artifacts.fold<int>(0, (sum, artifact) => sum + artifact.bytes.length);
      final witnessBytes = draft.sourceArtifacts.fold<int>(0, (sum, artifact) => sum + artifact.bytes.length);
      final artifactVolumes = <Map<String, Object?>>[];
      final mediaBytes = <String, int>{};
      for (final role in ['native', 'sourceWitness']) {
        for (final artifact in role == 'native' ? draft.artifacts : draft.sourceArtifacts) {
          final key = '$role:${artifact.reference.mediaType}';
          mediaBytes[key] = (mediaBytes[key] ?? 0) + artifact.bytes.length;
          artifactVolumes.add({'role': role, 'handle': artifact.handle,
            'mediaType': artifact.reference.mediaType, 'byteLength': artifact.bytes.length});
        }
      }
      artifactVolumes.sort((a, b) => (b['byteLength'] as int).compareTo(a['byteLength'] as int));
      final budgetProof = {'kind': 'actualFullPreparedKantoImageBudget',
        'nativeDraftHash': draft.canonicalHash.value, 'images': images,
        'retainedPixels': retainedPixels, 'logicalImportPixels': logicalPixels,
        'maxTotalImagePixels': budget.maxTotalImagePixels,
        'maxSingleImagePixels': budget.maxImagePixels,
        'nativeArtifactBytes': nativeBytes, 'sourceWitnessBytes': witnessBytes,
        'retainedArtifactBytes': nativeBytes + witnessBytes,
        'maxTotalArtifactBytes': budget.maxTotalArtifactBytes,
        'retainedByteAccounting': 'bothNativeAndSourceWitnessRoles',
        'artifactBytesByRoleAndMediaType': mediaBytes,
        'largestArtifacts': artifactVolumes.take(10).toList(),
        'derivedBordersCheckedSeparatelyBeforeStagingByNativeWriter': true,
        'sourceScriptsExecuted': 0};
      await File('${evidence.path}/prepared-image-budget.json')
          .writeAsString(jsonEncode(budgetProof), flush: true);
      if (retainedPixels > budget.maxTotalImagePixels || logicalPixels > budget.maxTotalImagePixels) {
        throw StateError('Full prepared image census exceeds its explicit budget');
      }
      result['preparedImageBudget'] = {...budgetProof, 'images': images.length};
      final sourceEvents = draft.compositionEvidence['sourceEvents'];
      final sourceProjection =
          sourceEvents is Map ? sourceEvents['projection'] : null;
      if (sourceProjection is Map) {
        await File('${evidence.path}/source-event-qualification.json')
            .writeAsString(jsonEncode({
          'kind': 'fullKantoSourceEventQualification',
          'sourceSnapshotHash': snapshot.canonicalHash.value,
          'profileEvidenceHash': snapshot.profile.evidenceHash.value,
          'nativeDraftHash': draft.canonicalHash.value,
          'qualifiedEventCount': sourceProjection['qualifiedEventCount'],
          'quarantinedEventCount': sourceProjection['quarantinedEventCount'],
          'events': sourceProjection['events'],
          'globalPlayabilityCertified': false,
          'sourceScriptsExecuted': 0,
          'aiSourceInferenceCalls': 0,
        }), flush: true);
        result['preparedSourceEventSummary'] = {
          'qualifiedEventCount': sourceProjection['qualifiedEventCount'],
          'quarantinedEventCount': sourceProjection['quarantinedEventCount'],
          'globalPlayabilityCertified':
              sourceProjection['globalPlayabilityCertified'],
        };
      }
      final actions = <String, int>{};
      final eventStates = <String, int>{};
      var logicalMutations = 0;
      for (final mutation in draft.mutations) {
        actions.update(mutation.actionId, (value) => value + 1,
            ifAbsent: () => 1);
        final records = switch (mutation.actionId) {
          'event_v2.record_upsert' => [mutation.parameters['record']],
          'event_v2.record_upsert_batch' =>
            mutation.parameters['records'] as List,
          _ => const <Object?>[],
        };
        for (final record in records.cast<Map>()) {
          final state = record['state'] == 'configured'
              ? (record['enabled'] == true ? 'enabled' : 'disabled')
              : record['state'] as String;
          eventStates.update(state, (value) => value + 1, ifAbsent: () => 1);
        }
        logicalMutations += switch (mutation.actionId) {
          'event_v2.record_upsert_batch' => records.length,
          'asset.import_batch' =>
            (mutation.parameters['entries'] as List).length,
          'element.batch_upsert' =>
            (mutation.parameters['elements'] as List).length,
          _ => 1,
        };
      }
      result['preparedNativeInventory'] = {
        'mapCount': draft.mapIds.length,
        'artifactEntries': draft.artifacts.length,
        'sourceArtifactEntries': draft.sourceArtifacts.length,
        'uniqueArtifactBlobs': {
          for (final artifact in [...draft.artifacts, ...draft.sourceArtifacts]) artifact.handle
        }.length,
        'mutationEnvelopes': draft.mutations.length,
        'logicalMutations': logicalMutations,
        'eventRecordStates': eventStates,
        'actions': actions,
      };
    }
    result.addAll({
      'phase': 'prepared',
      'canApprove': prepared.canApprove,
      'preparationHash': prepared.preparationHash.value,
      'nativeDraftHash': prepared.nativeDraft?.canonicalHash.value,
      'mapCount': prepared.nativeDraft?.mapIds.length,
      'elapsedMs': watch.elapsedMilliseconds,
    });
    await save();
    await File('${evidence.path}/prepared-review.json').writeAsString(jsonEncode(prepared.previewPlan?.toJson()), flush: true);
    await File('${evidence.path}/literal-diagnostics.json').writeAsString(
        jsonEncode(prepared.composition.diagnostics.map((value) => value.toJson()).toList()), flush: true);
    if (!prepared.canApprove) {
      throw StateError('The canonical workflow refused final preparation');
    }
    final recipe = workflow.exportStudyPlanRecipe();
    await File('${evidence.path}/plan-recipe.json')
        .writeAsString(recipe.encode(), flush: true);
    final preflight = await preflightConnections(prepared, files);
    await File('${evidence.path}/connection-preflight.json')
        .writeAsString(jsonEncode(preflight), flush: true);
    if (preflight['passed'] != true) {
      throw StateError('The full-world connection preflight failed: ${preflight['failure']}');
    }
    final approval = workflow.approvePrepared(
      sessionRevision: prepared.sessionRevision,
      preparationHash: prepared.preparationHash,
      humanConfirmed: true,
    );
    final delivered = await workflow.writeApproved(approval);
    result.addAll({
      'phase': 'published',
      'published': delivered.published,
      'verified': delivered.receipt.verified,
      'sourceUnchanged': delivered.sourceUnchanged,
      'projectPath': delivered.projectPath,
      'nativeRevision': delivered.receipt.nativeRevision,
      'importUndoHistoryRetained': delivered.receipt.importUndoHistoryRetained,
      'provenance': delivered.sourceProvenanceReceipt,
      'elapsedMs': watch.elapsedMilliseconds,
    });
    await save();
    final sourceEvents = draft!.compositionEvidence['sourceEvents'];
    await File('${evidence.path}/runtime-inputs.json').writeAsString(jsonEncode({
      'verified': delivered.published && delivered.receipt.verified && delivered.sourceUnchanged,
      'projectPath': delivered.projectPath,
      'contentScope': contentScope.name,
      'events': sourceEvents is Map ? sourceEvents['projection'] : null,
    }), flush: true);
  } catch (error, stack) {
    result.addAll({
      'phase': 'exception',
      'error': error.toString(),
      'locator': error is ConverterWorkflowFailure ? error.locator : null,
      'stack': stack.toString(),
      'elapsedMs': watch.elapsedMilliseconds,
    });
    await save();
    rethrow;
  } finally {
    await sourceTree?.close();
    await termination.cancel();
    await subscription.cancel();
    await workflow.dispose();
  }
}
