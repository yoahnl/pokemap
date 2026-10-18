part of '../avelune_converter_core.dart';

final class SourceInteractionInventory {
  SourceInteractionInventory._(Map<String, Object?> json)
      : _json = jsonDecode(jsonEncode(json)) as Map<String, Object?>;

  final Map<String, Object?> _json;

  factory SourceInteractionInventory.build({
    required NormalizedSourceProject source,
    required SourceEventAnalysis analysis,
    required String toolRevision,
    List<int>? historicalQualificationBytes,
    List<int>? historicalProfileBytes,
    List<int>? historicalFreezeBytes,
  }) {
    void require(bool valid, String message) {
      if (!valid) throw StateError('Interaction inventory: $message');
    }

    require(toolRevision.trim().isNotEmpty, 'tool revision is required');
    require(
      source.snapshot.state == SourceScanState.complete &&
          source.unprocessedSourceMapIds.isEmpty,
      'complete source census required',
    );
    final sourceProfile = SourceEventProfile.forProject(source);
    require(
      analysis.profile.sourceSnapshotHash == source.snapshot.canonicalHash &&
          analysis.profile.normalizationHash == source.canonicalHash &&
          analysis.profile.canonicalHash == sourceProfile.canonicalHash,
      'analysis source/profile mismatch',
    );
    final derived = SourceEventAnalyzer.forProject(
      source,
      profile: sourceProfile,
    ).analyze();
    final derivedPages = {
      for (final event in derived.events)
        event.identity.value: {
          for (final page in event.pages) page.originalPageIndex: page,
        },
    };
    final sourceMapFiles = source.snapshot.entries
        .where(
          (entry) =>
              entry.kind == SourceNodeKind.file &&
              RegExp(r'^data/map([0-9]+)\.rxdata$')
                  .hasMatch(sourcePathCollisionKey(entry.relativePath)),
        )
        .toList();
    final sourceMapFileIds = sourceMapFiles.map((file) => file.fileId).toSet();
    require(
      sourceMapFiles.length == source.maps.length &&
          sourceMapFileIds.length == source.maps.length &&
          source.maps.map((map) => map.map.sourceFileId).toSet().length ==
              source.maps.length &&
          source.maps
              .every((map) => sourceMapFileIds.contains(map.map.sourceFileId)),
      'source map census is incomplete',
    );
    final expected = <String, (SourceMapIr, SourceEvent)>{};
    final mapNames = <int, String>{};
    for (final map in source.maps) {
      require(
        !mapNames.containsKey(map.map.sourceMapId),
        'duplicate source map',
      );
      mapNames[map.map.sourceMapId] = map.map.name;
      for (final event in map.map.events) {
        final identity = source
            .eventIdentity(map.map.sourceMapId, event.sourceEventId)
            .value;
        require(!expected.containsKey(identity), 'duplicate source event');
        expected[identity] = (map, event);
      }
    }
    final seen = <String>{};
    final ordered = analysis.events.toList()
      ..sort((a, b) {
        final map = a.sourceMapId.compareTo(b.sourceMapId);
        return map == 0 ? a.sourceEventId.compareTo(b.sourceEventId) : map;
      });
    final hasHistoricalInput = historicalQualificationBytes != null ||
        historicalProfileBytes != null ||
        historicalFreezeBytes != null;
    require(
        !hasHistoricalInput ||
            (historicalQualificationBytes != null &&
                historicalProfileBytes != null &&
                historicalFreezeBytes != null),
        'historical qualification requires all three archived byte inputs');
    final qualificationInput = historicalQualificationBytes == null
        ? null
        : _inventoryArchivedJson(historicalQualificationBytes);
    final profileInput = historicalProfileBytes == null
        ? null
        : _inventoryArchivedJson(historicalProfileBytes);
    final freezeInput = historicalFreezeBytes == null
        ? null
        : _inventoryArchivedJson(historicalFreezeBytes);
    final historicalQualification = qualificationInput?.$1;
    final historicalProfile = profileInput?.$1;
    final historicalFreeze = freezeInput?.$1;
    final historicalQualificationSha256 = qualificationInput?.$2;
    final historicalProfileSha256 = profileInput?.$2;
    final historicalFreezeSha256 = freezeInput?.$2;
    final baseline = <String, Map<String, Object?>>{};
    Map<String, Object?>? history;
    if (historicalQualification != null) {
      final q = historicalQualification;
      final p = historicalProfile ??
          (throw StateError('Historical profile required'));
      final f =
          historicalFreeze ?? (throw StateError('Historical freeze required'));
      require(
        historicalQualificationSha256 != null &&
            historicalProfileSha256 != null &&
            historicalFreezeSha256 != null,
        'historical qualification requires pinned profile and freeze',
      );
      for (final hash in [
        historicalQualificationSha256,
        historicalProfileSha256,
        historicalFreezeSha256,
      ]) {
        require(
          RegExp(r'^[a-f0-9]{64}$').hasMatch(hash!),
          'invalid historical byte hash',
        );
      }
      require(
        q['sourceSnapshotHash'] == source.snapshot.canonicalHash.value &&
            q['profileEvidenceHash'] ==
                source.snapshot.profile.evidenceHash.value &&
            f['expectedSourceSnapshotHash'] ==
                source.snapshot.canonicalHash.value,
        'historical snapshot/source detection mismatch',
      );
      require(
        f['interpretationProfileSha256'] == historicalProfileSha256 &&
            f['interpretationProfileCanonicalHash'] is String &&
            RegExp(r'^[a-f0-9]{64}$')
                .hasMatch(f['interpretationProfileCanonicalHash'] as String) &&
            f['interpretationProfileId'] == p['profileId'] &&
            p['kind'] == 'sourceInterpretationProfile' &&
            p['schemaVersion'] is int,
        'historical interpretation profile mismatch',
      );
      require(
        f['commit'] is String &&
            (f['commit'] as String).isNotEmpty &&
            q['nativeDraftHash'] is String &&
            q['globalPlayabilityCertified'] == false &&
            q['sourceScriptsExecuted'] == 0 &&
            q['aiSourceInferenceCalls'] == 0,
        'unsupported historical qualification envelope',
      );
      final rows = q['events'];
      require(rows is List, 'missing historical events');
      for (final row in rows as List) {
        require(
          row is Map<String, Object?> && row['sourceIdentity'] is String,
          'invalid historical event',
        );
        final value = row as Map<String, Object?>;
        final id = value['sourceIdentity'] as String;
        require(!baseline.containsKey(id), 'duplicate historical event');
        require(
          value['status'] == 'adaptedStaticSemantics' ||
              value['status'] == 'quarantinedWholeEvent',
          'unknown historical status',
        );
        require(
          value['gaps'] is List &&
              (value['gaps'] as List).every((gap) => gap is String),
          'invalid historical gaps',
        );
        baseline[id] = value;
      }
      require(
        baseline.length == expected.length &&
            baseline.keys.every(expected.containsKey),
        'historical event coverage mismatch',
      );
      require(
        q['qualifiedEventCount'] ==
                baseline.values
                    .where((e) => e['status'] == 'adaptedStaticSemantics')
                    .length &&
            q['quarantinedEventCount'] ==
                baseline.values
                    .where((e) => e['status'] == 'quarantinedWholeEvent')
                    .length,
        'historical count mismatch',
      );
      history = {
        'scope': 'historicalStaticQualificationOnly',
        'qualificationSha256': historicalQualificationSha256,
        'profileSha256': historicalProfileSha256,
        'profileRawJsonCanonicalHash': canonicalHashOf(p).value,
        'reportedInterpreterCanonicalHash':
            f['interpretationProfileCanonicalHash'],
        'reportedInterpreterHashVerification': 'historicalReportedOnly',
        'qualificationCanonicalHash': canonicalHashOf(
          q,
          limits: const ContractLimits(
            maxNodes: 8000000,
            maxTextCodeUnits: 134217728,
          ),
        ).value,
        'profileSchemaVersion': p['schemaVersion'],
        'profileId': p['profileId'],
        'freezeSha256': historicalFreezeSha256,
        'toolRevision': f['commit'],
        'nativeDraftHash': q['nativeDraftHash'],
        'sourceDetectionEvidenceHash': q['profileEvidenceHash'],
        'qualifiedEventCount': q['qualifiedEventCount'],
        'quarantinedEventCount': q['quarantinedEventCount'],
        'currentAdmissionCertified': false,
      };
    } else {
      require(
        historicalProfile == null &&
            historicalFreeze == null &&
            historicalQualificationSha256 == null &&
            historicalProfileSha256 == null &&
            historicalFreezeSha256 == null,
        'partial historical binding',
      );
    }
    final roleEventCounts = <String, int>{}, rolePageCounts = <String, int>{};
    final gapEventCounts = <String, int>{};
    final signalEventCounts = <String, int>{},
        signalPageCounts = <String, int>{};
    final events = <Map<String, Object?>>[];
    var pageCount = 0, commandCount = 0;
    for (final event in ordered) {
      require(seen.add(event.identity.value), 'duplicate analysis event');
      final raw = expected[event.identity.value];
      require(raw != null, 'alien analysis event');
      final sourceEvent = raw!.$2;
      final file = source.archive.files[raw.$1.map.sourceFileId];
      require(
        file != null &&
            event.sourceFileId == file.fileId &&
            event.sourceMapId == raw.$1.map.sourceMapId &&
            event.sourceEventId == sourceEvent.sourceEventId &&
            event.x == sourceEvent.x &&
            event.y == sourceEvent.y &&
            event.name == sourceEvent.name &&
            event.locator.file == file.entry.relativePath &&
            event.locator.mapId == event.sourceMapId &&
            event.locator.eventId == event.sourceEventId &&
            event.locator.pageIndex == null &&
            event.locator.commandIndex == null,
        'analysis event identity/locator mismatch',
      );
      final old = baseline[event.identity.value];
      final oldPages = <int, Map<String, Object?>>{};
      if (old != null) {
        require(
          old['sourceFileId'] == event.sourceFileId.value &&
              canonicalJsonOf(old['locator']) ==
                  canonicalJsonOf(event.locator.toJson()) &&
              old['pages'] is List,
          'historical event locator/file mismatch',
        );
        for (final row in old['pages'] as List) {
          require(
            row is Map<String, Object?> && row['originalPageIndex'] is int,
            'invalid historical page',
          );
          final value = row as Map<String, Object?>;
          final index = value['originalPageIndex'] as int;
          require(!oldPages.containsKey(index), 'duplicate historical page');
          oldPages[index] = value;
        }
      }
      final rawPages = <int, SourceEventPage>{};
      for (final page in sourceEvent.pages) {
        require(
          !rawPages.containsKey(page.originalPageIndex),
          'duplicate source page',
        );
        rawPages[page.originalPageIndex] = page;
      }
      require(
        event.pages.length == rawPages.length &&
            (old == null || oldPages.length == rawPages.length),
        'page coverage mismatch',
      );
      final seenPages = <int>{},
          eventRoles = <String>{},
          eventSignals = <String>{};
      final pages = <Map<String, Object?>>[];
      final sortedPages = event.pages.toList()
        ..sort((a, b) => a.originalPageIndex.compareTo(b.originalPageIndex));
      for (final supplied in sortedPages) {
        final index = supplied.originalPageIndex;
        require(
          seenPages.add(index) && rawPages.containsKey(index),
          'analysis page coverage mismatch',
        );
        final page = derivedPages[event.identity.value]![index]!;
        require(
          canonicalJsonOf(supplied.sourcePage.toJson()) ==
                  canonicalJsonOf(rawPages[index]!.toJson()) &&
              canonicalJsonOf(supplied.locator.toJson()) ==
                  canonicalJsonOf(page.locator.toJson()) &&
              canonicalJsonOf(supplied.rawDataRef?.toJson()) ==
                  canonicalJsonOf(page.rawDataRef?.toJson()) &&
              page.locator.file == event.locator.file &&
              page.locator.mapId == event.sourceMapId &&
              page.locator.eventId == event.sourceEventId &&
              page.locator.pageIndex == index &&
              page.locator.commandIndex == null,
          'analysis page locator/content mismatch',
        );
        final ref = source.archive.references[page.sourcePage.rawDataRef];
        require(
          ref != null &&
              ref.fileId == event.sourceFileId &&
              ref.contentHash == file!.contentHash &&
              canonicalJsonOf(ref.locator?.toJson()) ==
                  canonicalJsonOf(page.locator.toJson()) &&
              canonicalJsonOf(page.rawDataRef?.toJson()) ==
                  canonicalJsonOf(ref.toJson()),
          'page raw reference mismatch',
        );
        final oldPage = oldPages[index];
        if (old != null) {
          require(
            oldPage != null &&
                oldPage['triggerCode'] == page.triggerCode &&
                canonicalJsonOf(oldPage['locator']) ==
                    canonicalJsonOf(page.locator.toJson()) &&
                canonicalJsonOf(oldPage['rawDataRef']) ==
                    canonicalJsonOf(ref!.toJson()),
            'historical page locator/content mismatch',
          );
        }
        final commands = page.sourcePage.commands;
        final seenCommands = <int>{};
        for (final command in commands) {
          require(
            seenCommands.add(command.originalIndex) &&
                command.sourceLocator.file == page.locator.file &&
                command.sourceLocator.mapId == event.sourceMapId &&
                command.sourceLocator.eventId == event.sourceEventId &&
                command.sourceLocator.pageIndex == index &&
                command.sourceLocator.commandIndex == command.originalIndex,
            'duplicate or mismatched source command',
          );
        }
        final roles = <String>{};
        final signals = <Map<String, Object?>>[];
        void signal(String kind, Iterable<SourceCommand> matching) {
          final rows = matching.toList();
          if (rows.isNotEmpty)
            signals.add({
              'kind': kind,
              'commandIndices': rows.map((c) => c.originalIndex).toList(),
              'commandCodes': rows.map((c) => c.code).toSet().toList()..sort(),
            });
        }

        bool has(Set<int> codes) => commands.any((c) => codes.contains(c.code));
        if (has({101, 401, 102, 402, 403})) roles.add('dialogue');
        if (has({201})) roles.add('transfer');
        if (has({
          301,
          302,
          303,
          125,
          126,
          127,
          128,
          129,
          314,
          315,
          316,
          317,
          318,
        })) roles.add('specializedInteraction');
        if (page.triggerCode == 3 || page.triggerCode == 4)
          roles.add('controller');
        final graphic = page.graphic;
        if (graphic != null &&
            (graphic.characterName.isNotEmpty || graphic.tileId > 0))
          roles.add('visibleActor');
        if (graphic != null &&
            graphic.characterName.isNotEmpty &&
            graphic.tileId == 0 &&
            page.triggerCode == 0 &&
            roles.contains('dialogue')) roles.add('npcCandidate');
        final executable =
            commands.where((c) => !{0, 108, 408}.contains(c.code)).length;
        if (executable == 0) roles.add('passiveCandidate');
        roles.add('reviewRequired');
        signal('text', commands.where((c) => {101, 401}.contains(c.code)));
        signal('choice', commands.where((c) => c.code == 102));
        signal(
          'transferDestinationAsSourceParameters',
          commands.where((c) => c.code == 201),
        );
        signal(
          'commonEventCallUnresolved',
          commands.where((c) => c.code == 117),
        );
        signal(
          'rubyDataOnly',
          commands.where((c) => {355, 655}.contains(c.code)),
        );
        signal(
          'branchOrCondition',
          commands.where((c) => {111, 411, 412}.contains(c.code)),
        );
        signal(
          'stateMutation',
          commands.where((c) => {121, 122, 123}.contains(c.code)),
        );
        signal(
          'movementOrPresentation',
          commands.where(
            (c) => {106, 208, 209, 210, 223, 250, 509}.contains(c.code),
          ),
        );
        for (final signal in signals) {
          final kind = signal['kind'] as String;
          eventSignals.add(kind);
          signalPageCounts.update(kind, (n) => n + 1, ifAbsent: () => 1);
        }
        final sortedRoles = roles.toList()..sort();
        eventRoles.addAll(roles);
        for (final role in roles) {
          rolePageCounts.update(role, (n) => n + 1, ifAbsent: () => 1);
        }
        final conditionsRef =
            source.archive.references[page.sourcePage.conditionsDataRef];
        pages.add({
          'originalPageIndex': index,
          'locator': page.locator.toJson(),
          'triggerCode': page.triggerCode,
          'trigger': switch (page.triggerCode) {
            0 => 'action',
            1 => 'playerTouch',
            2 => 'eventTouch',
            3 => 'autorun',
            4 => 'parallel',
            _ => 'unknown',
          },
          'roles': sortedRoles,
          'humanIdentity': 'unknown',
          'classificationScope': 'observableSourceSignalsOnly',
          'noExecutableCommands': executable == 0,
          'unresolvedCommonEventCalls': commands
              .where((c) => c.code == 117)
              .map((c) => c.toJson())
              .toList(),
          'historicalStaticProgramKinds':
              ((oldPage?['adaptedCommands'] as List?) ?? [])
                  .whereType<Map>()
                  .map((c) => c['kind'])
                  .toSet()
                  .toList()
                ..sort((a, b) => a.toString().compareTo(b.toString())),
          'expectedBehaviorSignals': signals,
          'currentQualification': 'notYetQualified',
          'reviewReasons': [
            'inventoryDoesNotCertifyNativeOrRuntimeBehavior',
            if (!sourceProfile.isQualified) 'analysisProfileUnqualified',
            if (has({355, 655})) 'rubyPreservedWithoutExecution',
            ...page.diagnostics.map((d) => d.code).toSet().toList()..sort(),
          ],
          'staticAnalysisQuarantined': page.isQuarantined,
          'condition': page.condition.toJson(),
          'conditionsDataRef': conditionsRef?.toJson(),
          'rawConditionFields': conditionsRef == null
              ? null
              : _inventoryConditionFields(source, conditionsRef),
          'rawDataRef': ref!.toJson(),
          'presence': graphic == null
              ? null
              : {
                  'tileId': graphic.tileId,
                  'characterName': graphic.characterName,
                  'opacity': graphic.opacity,
                  'hue': graphic.hue,
                  'direction': graphic.direction,
                  'pattern': graphic.pattern,
                  'blendType': graphic.blendType,
                  'through': graphic.through,
                  'alwaysOnTop': graphic.alwaysOnTop,
                  'moveType': graphic.moveType,
                  'moveSpeed': graphic.moveSpeed,
                  'moveFrequency': graphic.moveFrequency,
                  'moveRouteNodeId': graphic.moveRouteNodeId,
                  'walkAnime': graphic.walkAnime,
                  'stepAnime': graphic.stepAnime,
                  'directionFix': graphic.directionFix,
                  'collisionQualification': 'notYetQualified',
                },
          'selection': {
            'higherPageWins': true,
            'originalPriority': index,
            'activePageAtRuntime': 'notEvaluated',
            'higherPageIndices': sortedPages
                .where((p) => p.originalPageIndex > index)
                .map((p) => p.originalPageIndex)
                .toList(),
          },
          'commandBodyEmpty': page.isEmpty,
          'rawCommandCount': commands.length,
          'rawExecutableCommandCount': executable,
          'rawCommands': commands.map((c) => c.toJson()).toList(),
          'parsedCommands': page.body.nodes
              .map(
                (n) => {
                  'kind': n.runtimeType.toString(),
                  'span': n.span.toJson(),
                },
              )
              .toList(),
          'diagnostics': page.diagnostics.map((d) => d.toJson()).toList(),
          'historicalQualification': oldPage == null
              ? null
              : {
                  'scope': 'historicalStaticQualificationOnly',
                  'commandBodyEmpty': oldPage['isEmpty'],
                  'condition': oldPage['condition'],
                  'nativeEventId': oldPage['nativeEventId'],
                  'adaptedCommands': oldPage['adaptedCommands'],
                },
        });
        pageCount++;
        commandCount += commands.length;
      }
      for (final signal in eventSignals) {
        signalEventCounts.update(signal, (n) => n + 1, ifAbsent: () => 1);
      }
      for (final role in eventRoles) {
        roleEventCounts.update(role, (n) => n + 1, ifAbsent: () => 1);
      }
      for (final gap in (old?['gaps'] as List? ?? []).cast<String>().toSet()) {
        gapEventCounts.update(gap, (n) => n + 1, ifAbsent: () => 1);
      }
      events.add({
        'sourceIdentity': event.identity.value,
        'locator': event.locator.toJson(),
        'sourceFileId': event.sourceFileId.value,
        'sourceFileSha256': file!.contentHash.value,
        'sourceMapId': event.sourceMapId,
        'mapName': mapNames[event.sourceMapId],
        'sourceEventId': event.sourceEventId,
        'name': event.name,
        'x': event.x,
        'y': event.y,
        'roles': eventRoles.toList()..sort(),
        'pageCount': pages.length,
        'currentQualification': 'notYetQualified',
        'historicalQualification': old == null
            ? null
            : {
                'scope': 'historicalStaticQualificationOnly',
                'status': old['status'],
                'gaps': (old['gaps'] as List).toSet().toList()..sort(),
              },
        'pages': pages,
      });
    }
    require(seen.length == expected.length, 'missing analysis events');
    Map<String, int> sorted(Map<String, int> values) => {
          for (final key in values.keys.toList()..sort()) key: values[key]!,
        };
    return SourceInteractionInventory._({
      'kind': 'sourceInteractionInventory',
      'schemaVersion': 1,
      'toolRevision': toolRevision,
      'sourceSnapshotHash': source.snapshot.canonicalHash.value,
      'normalizationHash': source.canonicalHash.value,
      'sourceArchiveHash': source.archive.canonicalHash.value,
      'logicalProjectNamespace': source.snapshot.logicalProjectNamespace.value,
      'sourceDetectionEvidenceHash': source.snapshot.profile.evidenceHash.value,
      'analysisProfile': sourceProfile.toJson(),
      'analysisProfileHash': sourceProfile.canonicalHash.value,
      'analysisProfileQualified': sourceProfile.isQualified,
      'historicalQualification': history,
      'mapCount': source.maps.length,
      'eventCount': events.length,
      'pageCount': pageCount,
      'rawCommandCount': commandCount,
      'notYetQualifiedEventCount': events.length,
      'notYetQualifiedPageCount': pageCount,
      'roleEventCounts': sorted(roleEventCounts),
      'rolePageCounts': sorted(rolePageCounts),
      'signalEventCounts': sorted(signalEventCounts),
      'signalPageCounts': sorted(signalPageCounts),
      'censusScope': 'allMapEventsAndPages',
      'roleDefinitions': {
        'dialogue': 'raw text or choice opcodes',
        'transfer':
            'raw opcode 201; door, stairs or teleport identity unresolved',
        'visibleActor':
            'source character or tile graphic, without human identity',
        'npcCandidate':
            'character graphic plus action trigger plus dialogue; human identity unresolved',
        'specializedInteraction':
            'raw battle/shop/party/inventory opcodes; native behavior unqualified',
        'controller': 'autorun or parallel trigger',
        'passiveCandidate':
            'no raw executable command; graphics, movement, collision and page conditions remain meaningful',
        'reviewRequired':
            'native/runtime qualification pending for every inventory page',
      },
      'roleCountsOverlap': true,
      'historicalGapEventCounts': sorted(gapEventCounts),
      'gapCountsOverlap': true,
      'exclusions': {
        'sourcePaths': source.snapshot.excludedPaths,
        'unprocessedSourceMapIds': source.unprocessedSourceMapIds,
        'notAssessedByThisInventory': [
          'sourceCommonEventBodies',
          'sourceGlobalScripts',
          'nativeAdmission',
          'runtimePlayability',
          'humanNpcIdentity',
          'doorVersusOtherTransferIdentity',
        ],
      },
      'normalizationDiagnostics':
          source.diagnostics.map((d) => d.toJson()).toList(),
      'globalPlayabilityCertified': false,
      'sourceScriptsExecuted': 0,
      'aiSourceInferenceCalls': 0,
      'events': events,
    });
  }

  Map<String, Object?> toJson() =>
      jsonDecode(jsonEncode(_json)) as Map<String, Object?>;

  Map<String, Object?> summaryJson() => jsonDecode(
        jsonEncode({
          for (final entry in _json.entries)
            if (entry.key != 'events') entry.key: entry.value,
        }),
      ) as Map<String, Object?>;

  static String csvCell(Object? value) {
    var text = value is String
        ? value
        : value == null
            ? ''
            : jsonEncode(value);
    if (RegExp(r'^[\x00-\x20]*[=+@-]|^[\t\r\n]').hasMatch(text))
      text = "'$text";
    return '"${text.replaceAll('"', '""')}"';
  }

  String eventsCsv() => _csv(false);
  String pagesCsv() => _csv(true);

  String _csv(bool pages) {
    final columns = [
      'sourceIdentity',
      'sourceMapId',
      'mapName',
      'sourceEventId',
      'name',
      'x',
      'y',
      if (pages) ...[
        'originalPageIndex',
        'triggerCode',
        'rawCommandCount',
        'rawExecutableCommandCount',
        'commandBodyEmpty',
      ],
      'roles',
      'currentQualification',
      'historicalQualification',
      if (pages) ...[
        'presence',
        'expectedBehaviorSignals',
        'rawConditionFields',
        'reviewReasons',
      ],
    ];
    final output = StringBuffer()
      ..write('${columns.map(csvCell).join(',')}\r\n');
    for (final event
        in (_json['events'] as List).cast<Map<String, Object?>>()) {
      final rows = pages
          ? ((event['pages'] as List).cast<Map<String, Object?>>())
          : [<String, Object?>{}];
      for (final page in rows) {
        final row = {...event, ...page};
        output.write('${columns.map((c) => csvCell(row[c])).join(',')}\r\n');
      }
    }
    return output.toString();
  }
}

Map<String, Object?> _inventoryConditionFields(
  NormalizedSourceProject source,
  SourcePreservedData ref,
) {
  final document = source.archive.files[ref.fileId]!.document;
  final Map<String, int> fields;
  try {
    fields = _eventFields(document, ref.nodeId, 'RPG::Event::Page::Condition');
  } on FormatException {
    return {'state': 'unparsedPreservedOnly', 'rawDataRef': ref.toJson()};
  }
  return {
    for (final key in fields.keys.toList()..sort())
      key: switch (document.node(fields[key]!).kind) {
        MarshalKind.boolean => document.node(fields[key]!).booleanValue,
        MarshalKind.integer =>
          document.node(fields[key]!).integerValue!.bitLength <= 63
              ? document.node(fields[key]!).integerValue!.toInt()
              : {
                  'kind': 'integer',
                  'decimal': document.node(fields[key]!).integerValue.toString()
                },
        MarshalKind.string => document.node(fields[key]!).text().text,
        _ => {
            'nodeId': fields[key],
            'kind': document.node(fields[key]!).kind.name,
          },
      },
  };
}

(Map<String, Object?>, String) _inventoryArchivedJson(List<int> input) {
  if (input.any((byte) => byte < 0 || byte > 255)) {
    throw StateError('Interaction inventory: invalid archived byte input');
  }
  final bytes = Uint8List.fromList(input);
  final value = jsonDecode(utf8.decode(bytes));
  if (value is! Map<String, Object?>) {
    throw StateError('Interaction inventory: archived JSON object required');
  }
  return (value, sha256.convert(bytes).toString());
}
