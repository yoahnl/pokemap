import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  final repositoryRoot = Directory.current.parent.parent;
  final contractFile = File(
    '${repositoryRoot.path}/documentation/architecture/contracts/'
    'cinematic_v2_contract_v1.json',
  );

  group('Cinematic V2 architecture contract', () {
    test('committed contract satisfies every P0 invariant', () {
      final contract = _readContract(contractFile);

      expect(_validateContract(contract), isEmpty);
    });

    test('keeps world and presentation cinematic families disjoint', () {
      final contract = _readContract(contractFile);
      final families = _objects(contract['assetFamilies']);

      expect(families.map((family) => family['model']).toSet(), {
        'CinematicAsset',
        'PresentationCinematicAsset',
      });
      expect(families.map((family) => family['idNamespace']).toSet(), {
        'worldCinematic',
        'presentationCinematic',
      });
      expect(
        families.every((family) => family['polymorphicFallback'] == false),
        isTrue,
      );
    });

    test('fails closed when preSession gains a world capability', () {
      final contract = _readContract(contractFile);
      final profile = _objectById(
        _objects(contract['sceneProfiles']),
        'preSession',
      );
      _strings(profile['allowedCapabilities']).add('world.battle');

      expect(
        _validateContract(contract),
        contains('scene.preSession.world_capability_allowed'),
      );
    });

    test('fails closed when presentation becomes a preSession dependency', () {
      final contract = _readContract(contractFile);
      final rails = _object(contract['deliveryRails']);
      _strings(rails['preSessionTextOnly']['forbiddenDependencies']).clear();

      expect(
        _validateContract(contract),
        contains('delivery.pre_session.presentation_dependency_missing'),
      );
    });

    test('fails closed on package cycles and forbidden reverse coupling', () {
      final contract = _readContract(contractFile);
      final ownership = _object(contract['packageOwnership']);
      _objects(
        ownership['dependencyEdges'],
      ).add({'from': 'map_runtime', 'to': 'map_player_ui'});

      final issues = _validateContract(contract);

      expect(issues, contains('packages.forbidden_dependency'));
      expect(issues, contains('packages.dependency_cycle'));
    });

    test('fails closed on missing decision ownership and duplicate errors', () {
      final contract = _readContract(contractFile);
      _objects(contract['decisions']).first['ownerPackages'] = <String>[];
      final codes = _strings(contract['stableErrorCodes']);
      codes.add(codes.first);

      final issues = _validateContract(contract);

      expect(issues, contains('decisions.owner_missing'));
      expect(issues, contains('errors.duplicate_code'));
    });

    test('fails closed on version, migration and audio authority drift', () {
      final contract = _readContract(contractFile);
      contract['projectSchema'] = {
        ..._object(contract['projectSchema']),
        'requiredVersion': 'v6',
      };
      contract['migration'] = {
        ..._object(contract['migration']),
        'runtimeDualRead': true,
      };
      contract['media'] = {
        ..._object(contract['media']),
        'audioAuthority': 'videoPlayer',
      };

      final issues = _validateContract(contract);

      expect(issues, contains('project_schema.gate_invalid'));
      expect(issues, contains('migration.policy_invalid'));
      expect(issues, contains('media.authority_invalid'));
    });

    test(
      'fails closed when Scene interaction ownership or input scope drifts',
      () {
        final contract = _readContract(contractFile);
        final timeline = _object(contract['timeline']);
        contract['timeline'] = {
          ...timeline,
          'trackKinds': [..._strings(timeline['trackKinds']), 'interaction'],
        };
        final accessibility = _object(contract['accessibilityAndInput']);
        contract['accessibilityAndInput'] = {
          ...accessibility,
          'editorForbidden': <String>[],
        };

        final issues = _validateContract(contract);

        expect(issues, contains('timeline.interaction_ownership_invalid'));
        expect(issues, contains('accessibility.input_scope_invalid'));
      },
    );

    test('repository boundaries and documentation match the contract', () {
      final contract = _readContract(contractFile);
      final runtimePubspec = File(
        '${repositoryRoot.path}/packages/map_runtime/pubspec.yaml',
      ).readAsStringSync();
      final architectureDocument = File(
        '${repositoryRoot.path}/documentation/architecture/'
        'cinematic_v2_architecture_contract.md',
      ).readAsStringSync();
      final roadmap = File(
        '${repositoryRoot.path}/documentation/roadmap/'
        'road_map_runtime_media_cinematics_audio_time.md',
      ).readAsStringSync();

      expect(runtimePubspec, isNot(contains('map_player_ui:')));
      for (final decision in _objects(contract['decisions'])) {
        expect(architectureDocument, contains('${decision['id']}'));
      }
      expect(roadmap, contains('cinematic_v2_architecture_contract.md'));
      expect(roadmap, contains('cinematic_v2_contract_v1.json'));
    });
  });
}

Map<String, dynamic> _readContract(File file) =>
    _object(jsonDecode(file.readAsStringSync()));

List<String> _validateContract(Map<String, dynamic> contract) {
  final issues = <String>[];
  final requiredCapabilities = {'scene.preSession', 'cinematic.presentation'};
  final projectSchema = _object(contract['projectSchema']);
  if (contract['contractId'] != 'pokemap.cinematic-v2' ||
      contract['formatVersion'] != 1 ||
      contract['ticketId'] != 'BETA-CIN-001' ||
      contract['status'] != 'accepted') {
    issues.add('contract.identity_invalid');
  }
  if (projectSchema['requiredVersion'] != 'v7' ||
      projectSchema['oldRuntimePolicy'] != 'failClosed' ||
      projectSchema['legacyReadPolicy'] != 'v6WithoutV2Only' ||
      projectSchema['futureVersionPolicy'] != 'failClosed' ||
      !_sameStrings(
        _strings(projectSchema['requiredCapabilities']),
        requiredCapabilities,
      )) {
    issues.add('project_schema.gate_invalid');
  }

  final families = _objects(contract['assetFamilies']);
  if (families.length != 2 ||
      families.map((family) => family['model']).toSet().difference({
        'CinematicAsset',
        'PresentationCinematicAsset',
      }).isNotEmpty ||
      families.map((family) => family['model']).toSet().length != 2 ||
      families.map((family) => family['idNamespace']).toSet().difference({
        'worldCinematic',
        'presentationCinematic',
      }).isNotEmpty ||
      families.map((family) => family['idNamespace']).toSet().length != 2 ||
      families.any((family) => family['polymorphicFallback'] != false)) {
    issues.add('assets.families_not_disjoint');
  }

  final library = _object(contract['cinematicLibraryCatalog']);
  if (library['model'] != 'CinematicLibraryCatalog' ||
      library['folderIdentity'] != 'stableCinematicFolderId' ||
      !_sameStrings(_strings(library['familyScopes']), {
        'world',
        'presentation',
      }) ||
      library['worldAssetModelMutationRequired'] != false ||
      library['recursiveFolders'] != true ||
      library['cyclePolicy'] != 'reject' ||
      library['nonEmptyDeletionPolicy'] != 'rejectUntilMovedOrDeleted' ||
      library['authoringAuthority'] != 'map_authoring' ||
      library['semanticTransportParity'] != '4/4Required') {
    issues.add('library.catalog_invalid');
  }

  final profiles = _objects(contract['sceneProfiles']);
  final preSession = _objectById(profiles, 'preSession');
  final allowedCapabilities = _strings(preSession['allowedCapabilities']);
  final forbiddenCapabilities = _strings(preSession['forbiddenCapabilities']);
  if (allowedCapabilities.any(
        (capability) => capability.startsWith('world.'),
      ) ||
      forbiddenCapabilities.isEmpty ||
      !forbiddenCapabilities.every(
        (capability) => capability.startsWith('world.'),
      )) {
    issues.add('scene.preSession.world_capability_allowed');
  }

  final inputs = _object(contract['structuredInputs']);
  if (!_sameStrings(_strings(inputs['requestKinds']), {
        'message',
        'choice',
        'text',
        'confirmation',
        'selection',
      }) ||
      inputs['terminalEmission'] != 'exactlyOnce' ||
      inputs['rawCharactersInRuntimeInputEvent'] != false ||
      inputs['textUnit'] != 'unicodeGraphemeCluster' ||
      inputs['imeCompositionRequired'] != true) {
    issues.add('input.contract_invalid');
  }

  final timeline = _object(contract['timeline']);
  if (timeline['tickUnit'] != 'microsecond' ||
      timeline['ticksPerSecond'] != 1000000 ||
      timeline['intervalSemantics'] != '[startUs,endUs)' ||
      timeline['runtimeClock'] != 'monotonic' ||
      timeline['editorSeek'] != 'explicitDeterministic') {
    issues.add('timeline.timebase_invalid');
  }
  final interactionCuePolicy = _object(timeline['interactionCuePolicy']);
  if (!_sameStrings(_strings(timeline['trackKinds']), {
        'visual',
        'audio',
        'caption',
        'marker',
      }) ||
      interactionCuePolicy['representation'] != 'zeroDurationNamedMarker' ||
      interactionCuePolicy['timelineOwnsTimingOnly'] != true ||
      interactionCuePolicy['sceneOwnsRequestAndResult'] != true ||
      interactionCuePolicy['requiredUnboundPolicy'] != 'validationError' ||
      interactionCuePolicy['resumePolicy'] !=
          'automaticSameRunAtHeldNarrativeTime') {
    issues.add('timeline.interaction_ownership_invalid');
  }
  final pausePolicy = _object(timeline['pausePolicy']);
  if (pausePolicy['userPause'] != 'freezeNarrativeAndMediaClocks' ||
      pausePolicy['lifecyclePause'] != 'freezeNarrativeAndMediaClocks' ||
      pausePolicy['interactionHold'] !=
          'freezeNarrativeClockAndAuthoredAnimations' ||
      pausePolicy['interactionHoldMusic'] != 'continueCurrentPlaybackOrLoop' ||
      pausePolicy['interactionHoldBackgroundVideo'] !=
          'continueCurrentPlaybackOrLoop' ||
      pausePolicy['interactionHoldOneShotAudio'] != 'neverRestart' ||
      pausePolicy['interactionResume'] !=
          'continueNarrativeAtHeldTimeWithoutSeekingContinuedAmbience') {
    issues.add('timeline.pause_policy_invalid');
  }

  final outcomes = _object(contract['executionOutcomes']);
  if (!_sameStrings(_strings(outcomes['terminal']), {
        'completed',
        'skipped',
        'cancelled',
        'failed',
      }) ||
      outcomes['emission'] != 'exactlyOnce') {
    issues.add('execution.outcomes_invalid');
  }

  final newGame = _object(contract['newGame']);
  if (newGame['entrypointField'] != 'preSessionSceneId' ||
      newGame['projectConfig'] != 'immutable' ||
      newGame['pipeline'] != 'NewGameDraft->NewGameSeed->GameState' ||
      newGame['commit'] != 'exactlyOnce' ||
      newGame['slotDecision'] != 'beforePreSession' ||
      newGame['overwriteConfirmation'] != 'beforePreSession' ||
      newGame['oldSaveOnNonCompletion'] != 'untouched' ||
      newGame['crashPolicyV1'] != 'abandonDraftAndReturnToTitle' ||
      newGame['preloadPolicy'] != 'immutableBytesOnlyAfterSlotDecision') {
    issues.add('new_game.transaction_invalid');
  }

  final migration = _object(contract['migration']);
  if (migration['sourceField'] != 'starterSelectionSceneId' ||
      migration['targetField'] != 'preSessionSceneId' ||
      migration['runtimeDualRead'] != false ||
      migration['automaticRuntimeMigration'] != false ||
      migration['mode'] != 'explicitOfflineDryRunThenApply') {
    issues.add('migration.policy_invalid');
  }

  final media = _object(contract['media']);
  if (media['logicalIdentity'] != 'stableMediaId' ||
      media['contentIdentity'] != 'sha256' ||
      media['audioAuthority'] != 'RuntimeAudioMixer' ||
      media['videoAudioDirectPlayback'] != false ||
      media['offlinePackageRequired'] != true ||
      !_sameStrings(_strings(media['audioModes']), {'muted', 'mixerManaged'})) {
    issues.add('media.authority_invalid');
  }
  final variants = _object(media['responsiveVariants']);
  if (!_sameStrings(_strings(variants['slots']), {'landscape', 'portrait'}) ||
      !_sameStrings(_strings(variants['variantCapableKinds']), {
        'image',
        'video',
        'voice',
        'soundEffect',
      }) ||
      !_sameStrings(_strings(variants['sharedOnlyKinds']), {'music'}) ||
      variants['singleSourceFallback'] != 'useAvailableSource' ||
      variants['sharedClipTiming'] != true ||
      variants['durationMismatchPolicy'] !=
          'blockUntilBothVariantsCoverSharedTrim') {
    issues.add('media.responsive_variants_invalid');
  }

  final createAndLink = _object(contract['createAndLinkTransaction']);
  if (createAndLink['draftVisibility'] != 'localRecoveryOnly' ||
      createAndLink['projectSave'] != 'publishAtomicallyAndStay' ||
      createAndLink['saveAndReturn'] != 'publishAtomicallyAndReturn' ||
      createAndLink['publishedUnits'] !=
          'presentationCinematic+sceneNode+reference+stagedMedia' ||
      createAndLink['undoEntries'] != 1 ||
      createAndLink['cancelOrFailure'] != 'zeroProjectMutationAndZeroOrphan' ||
      createAndLink['staleScenePolicy'] !=
          'rejectPublishKeepRecoverableDraft' ||
      createAndLink['mediaImportBeforePublish'] != 'transactionStagingOnly') {
    issues.add('authoring.create_and_link_invalid');
  }

  final budgets = _object(contract['securityAndBudgets']);
  if (budgets['maxArchiveBytes'] != 1073741824 ||
      budgets['maxArchiveEntries'] != 20000 ||
      budgets['maxFileBytes'] != 268435456 ||
      budgets['maxTotalPayloadBytes'] != 1073741824 ||
      budgets['maxImageDimension'] != 8192 ||
      budgets['maxImagePixels'] != 67108864 ||
      budgets['maxPresentationPayloadBytes'] != 230686720 ||
      budgets['maxSequenceDurationUs'] != 900000000 ||
      budgets['maxVideoWidth'] != 3840 ||
      budgets['maxVideoHeight'] != 2160 ||
      budgets['maxConcurrentVideoDecoders'] != 1) {
    issues.add('media.budgets_invalid');
  }

  final ownership = _object(contract['packageOwnership']);
  final packageIds = _objects(
    ownership['packages'],
  ).map((package) => package['id'] as String).toSet();
  if (packageIds.difference({
        'map_core',
        'map_gameplay',
        'map_authoring',
        'map_runtime',
        'map_player_ui',
        'map_distribution',
        'map_editor',
      }).isNotEmpty ||
      packageIds.length != 7) {
    issues.add('packages.ownership_invalid');
  }
  final edges = _objects(ownership['dependencyEdges']);
  final forbiddenEdges = _objects(ownership['forbiddenEdges']);
  final edgeKeys = edges.map(_edgeKey).toSet();
  if (forbiddenEdges.any((edge) => edgeKeys.contains(_edgeKey(edge)))) {
    issues.add('packages.forbidden_dependency');
  }
  if (!forbiddenEdges.map(_edgeKey).contains('map_runtime->map_player_ui')) {
    issues.add('packages.reverse_boundary_missing');
  }
  if (_hasCycle(packageIds, edges)) {
    issues.add('packages.dependency_cycle');
  }

  final rails = _object(contract['deliveryRails']);
  final textOnlyRail = _object(rails['preSessionTextOnly']);
  if (!_strings(
    textOnlyRail['forbiddenDependencies'],
  ).contains('cinematic.presentation')) {
    issues.add('delivery.pre_session.presentation_dependency_missing');
  }

  final parity = _object(contract['authoringParity']);
  if (!_sameStrings(_strings(parity['requiredTransports']), {
        'directApi',
        'jsonlCli',
        'editor',
        'mcp',
      }) ||
      !_strings(parity['resourceKinds']).contains('presentationCinematic') ||
      !_strings(parity['resourceKinds']).contains('presentationMedia')) {
    issues.add('authoring.parity_invalid');
  }

  final renderer = _object(contract['sharedRenderer']);
  if (renderer['implementationOwner'] != 'map_player_ui' ||
      renderer['runtimeSurfaceConsumer'] != 'map_player_ui' ||
      renderer['runtimeStateSource'] != 'map_runtime' ||
      renderer['previewConsumer'] != 'map_editor' ||
      renderer['secondRendererAllowed'] != false) {
    issues.add('renderer.ownership_invalid');
  }

  final platforms = {
    for (final platform in _objects(contract['platformMatrix']))
      platform['platform'] as String: platform,
  };
  const platformNames = <PresentationMediaTargetPlatform, String>{
    PresentationMediaTargetPlatform.macos: 'macOS',
    PresentationMediaTargetPlatform.ios: 'iOS',
    PresentationMediaTargetPlatform.android: 'Android',
    PresentationMediaTargetPlatform.web: 'Web',
    PresentationMediaTargetPlatform.windows: 'Windows',
    PresentationMediaTargetPlatform.linux: 'Linux',
  };
  if (platforms.keys.toSet().difference({
        'macOS',
        'iOS',
        'Android',
        'Web',
        'Windows',
        'Linux',
      }).isNotEmpty ||
      platforms.length != 6 ||
      platforms['macOS']?['packaging'] != 'spmOnly') {
    issues.add('platform.matrix_invalid');
  }
  for (final entry in platformNames.entries) {
    final platform = platforms[entry.value];
    final capabilities = presentationMediaPlatformCapabilities(entry.key);
    if (platform == null ||
        platform['image'] != capabilities.image.id ||
        platform['audio'] != capabilities.audio.id ||
        platform['video'] != capabilities.video.id ||
        platform['captions'] != capabilities.captions.id) {
      issues.add('platform.${entry.key.name}.capabilities_invalid');
    }
  }

  final accessibility = _object(contract['accessibilityAndInput']);
  if (!_sameStrings(_strings(accessibility['editorRequired']), {
        'keyboard',
        'mouse',
        'ime',
        'screenReader',
        'focusOrder',
      }) ||
      !_sameStrings(_strings(accessibility['editorForbidden']), {
        'touch',
        'gamepad',
      }) ||
      !_sameStrings(_strings(accessibility['playerRequired']), {
        'keyboard',
        'touch',
        'gamepad',
        'ime',
        'screenReader',
        'focusOrder',
        'localizedCaptions',
        'skip',
        'pause',
        'replay',
      }) ||
      accessibility['reducedMotionPolicy'] != 'userPreferenceWins' ||
      accessibility['reducedFlashesPolicy'] != 'userPreferenceWins') {
    issues.add('accessibility.input_scope_invalid');
  }

  final observability = _object(contract['observability']);
  if (observability['terminalEvent'] != 'exactlyOnePerRun' ||
      !_strings(observability['forbiddenLogFields']).toSet().containsAll({
        'playerName',
        'submittedText',
        'subtitleText',
        'absolutePath',
      })) {
    issues.add('observability.privacy_invalid');
  }

  final performance = _object(contract['performanceGates']);
  if (performance['lifecycleCycles'] != 50 ||
      performance['maxConcurrentVideoDecoders'] != 1 ||
      performance['finalOpenMediaHandles'] != 0 ||
      performance['rssDriftPercentCycles5To50'] != 10 ||
      performance['skipP95Ms'] != 100 ||
      performance['posterP95Ms'] != 500 ||
      performance['firstVideoFrameP95Ms'] != 1000 ||
      performance['maxMainIsolateStallMs'] != 100 ||
      performance['uiFrameBudgetMs'] != 16.7 ||
      performance['uiFramesWithinBudgetPercent'] != 99) {
    issues.add('performance.gates_invalid');
  }

  final errorCodes = _strings(contract['stableErrorCodes']);
  if (!_sameStrings(errorCodes, {
    'cinematic.presentation.project_version_unsupported',
    'cinematic.presentation.asset_schema_unsupported',
    'cinematic.presentation.capability_unsupported',
    'cinematic.presentation.reference_missing',
    'cinematic.presentation.media_missing',
    'cinematic.presentation.media_unsupported',
    'cinematic.presentation.media_corrupt',
    'cinematic.presentation.media_security_rejected',
    'cinematic.presentation.budget_exceeded',
    'cinematic.presentation.playback_failed',
    'scene.pre_session.capability_forbidden',
    'scene.pre_session.entrypoint_invalid',
    'new_game.draft_stale',
    'new_game.overwrite_required',
    'new_game.commit_duplicate',
    'new_game.commit_failed',
    'authoring.revision_conflict',
    'authoring.transport_unsupported',
    'platform.capability_unsupported',
  })) {
    issues.add('errors.duplicate_code');
  }

  final decisions = _objects(contract['decisions']);
  if (!_sameStrings(decisions.map((decision) => decision['id'] as String), {
        for (var index = 1; index <= 17; index++)
          'CIN-ADR-${index.toString().padLeft(3, '0')}',
      }) ||
      decisions.any(
        (decision) =>
            _strings(decision['ownerPackages']).isEmpty ||
            _strings(decision['verificationTickets']).isEmpty ||
            (decision['consequence'] as String?)?.trim().isEmpty != false,
      )) {
    issues.add('decisions.owner_missing');
  }

  final cutover = _object(contract['legacyCutover']);
  if (_strings(cutover['orderedTickets']).join('>') !=
          'BETA-CIN-042>BETA-CIN-043>BETA-CIN-044>BETA-CIN-010' ||
      cutover['dualReaderAfterCutover'] != false ||
      cutover['legacyFallbackAfterCutover'] != false) {
    issues.add('cutover.order_invalid');
  }

  return issues;
}

bool _hasCycle(Set<String> nodes, List<Map<String, dynamic>> edges) {
  final outgoing = {for (final node in nodes) node: <String>[]};
  for (final edge in edges) {
    final from = edge['from'] as String;
    final to = edge['to'] as String;
    if (nodes.contains(from) && nodes.contains(to)) {
      outgoing[from]!.add(to);
    }
  }
  final visiting = <String>{};
  final visited = <String>{};

  bool visit(String node) {
    if (visiting.contains(node)) return true;
    if (visited.contains(node)) return false;
    visiting.add(node);
    for (final next in outgoing[node]!) {
      if (visit(next)) return true;
    }
    visiting.remove(node);
    visited.add(node);
    return false;
  }

  return nodes.any(visit);
}

String _edgeKey(Map<String, dynamic> edge) => '${edge['from']}->${edge['to']}';

bool _sameStrings(Iterable<String> actual, Set<String> expected) =>
    actual.length == expected.length && actual.toSet().containsAll(expected);

Map<String, dynamic> _object(Object? value) =>
    Map<String, dynamic>.from(value! as Map);

List<Map<String, dynamic>> _objects(Object? value) =>
    (value! as List).cast<Map<String, dynamic>>();

List<String> _strings(Object? value) => (value! as List).cast<String>();

Map<String, dynamic> _objectById(
  List<Map<String, dynamic>> values,
  String id,
) => values.singleWhere((value) => value['id'] == id);
