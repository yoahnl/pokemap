import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:test/test.dart';

import 'support/source_interaction_inventory_fixture.dart';

void main() {
  test(
      'inventory reconciles every page, preserves raw evidence and independent roles',
      () async {
    final source = await fixture();
    final analysis = analyze(source);
    final inventory = SourceInteractionInventory.build(
      source: source,
      analysis: analysis,
      toolRevision: 'test-revision',
    );
    final json = inventory.toJson();
    expect(
      jsonEncode(json),
      jsonEncode(
        SourceInteractionInventory.build(
          source: source,
          analysis: analysis,
          toolRevision: 'test-revision',
        ).toJson(),
      ),
    );
    expect(json['eventCount'], 2);
    expect(json['pageCount'], 3);
    final events = json['events'] as List;
    final pages = events.first['pages'] as List;
    expect(
      pages.first['roles'],
      containsAll(['dialogue', 'transfer', 'npcCandidate', 'reviewRequired']),
    );
    expect(pages.first['rawCommands'], hasLength(5));
    expect(pages.first['humanIdentity'], 'unknown');
    expect(pages.first['currentQualification'], 'notYetQualified');
    expect(pages[1]['commandBodyEmpty'], true);
    expect(pages[1]['rawCommandCount'], 1);
    expect(pages[1]['presence']['characterName'], 'Door');
    expect(pages[1]['selection']['higherPageWins'], true);
    expect(pages[1]['conditionsDataRef'], isNotNull);
    expect(pages[1]['rawConditionFields']['@switch1_valid'], true);
    expect(pages[1]['rawConditionFields']['@switch1_id'], 1);
    expect(events[1]['roles'], contains('controller'));
    expect(inventory.eventsCsv(), contains('sourceIdentity'));
    expect(inventory.pagesCsv(), contains('notYetQualified'));
    expect(json['globalPlayabilityCertified'], false);
    expect(json['sourceScriptsExecuted'], 0);
  });

  test('partial map selection cannot claim a complete source census', () async {
    final source = await fixture(selectedMapIds: {1});
    expect(source.maps, hasLength(1));
    expect(
        () => SourceInteractionInventory.build(
            source: source, analysis: analyze(source), toolRevision: 'tool'),
        throwsStateError);
  });
  test('CSV escapes formulas and quotes without changing source JSON', () {
    expect(
      SourceInteractionInventory.csvCell('=HYPERLINK("x")'),
      "\"'=HYPERLINK(\"\"x\"\")\"",
    );
    expect(SourceInteractionInventory.csvCell('\t+1'), "\"'\t+1\"");
    expect(SourceInteractionInventory.csvCell('a,b\nc'), '"a,b\nc"');
  });
  test('rejects missing duplicate or alien analysis rows', () async {
    final source = await fixture(), analysis = analyze(await fixture());
    SourceEventAnalysis rows(List<SourceEventDefinition> events) =>
        SourceEventAnalysis(
          profile: analysis.profile,
          events: events,
          diagnostics: [],
        );
    for (final events in [
      analysis.events.skip(1).toList(),
      [...analysis.events, analysis.events.first],
    ]) {
      expect(
        () => SourceInteractionInventory.build(
          source: source,
          analysis: rows(events),
          toolRevision: 'test',
        ),
        throwsStateError,
      );
    }
    final alienProfile = SourceEventProfile(
      scriptsArchiveHash: null,
      sourceSnapshotHash: Sha256Hash('0' * 64),
      normalizationHash: source.canonicalHash,
    );
    expect(
      () => SourceInteractionInventory.build(
        source: source,
        analysis: SourceEventAnalysis(
          profile: alienProfile,
          events: analysis.events,
          diagnostics: [],
        ),
        toolRevision: 'test',
      ),
      throwsStateError,
    );
  });

  test(
    'forged public analysis cannot replace source graphics or parsed body',
    () async {
      final source = await fixture(), analysis = analyze(await fixture());
      final event = analysis.events.first,
          page = analysis.events.first.pages.first;
      final forgedPage = SourceEventPageAnalysis(
        sourcePage: page.sourcePage,
        locator: page.locator,
        condition: page.condition,
        graphic: null,
        rawDataRef: page.rawDataRef,
        body: SourceEventBlock(nodes: [], span: page.body.span),
        diagnostics: [],
      );
      final forgedEvent = SourceEventDefinition(
        sourceMapId: event.sourceMapId,
        sourceEventId: event.sourceEventId,
        sourceFileId: event.sourceFileId,
        identity: event.identity,
        name: event.name,
        x: event.x,
        y: event.y,
        locator: event.locator,
        pages: [forgedPage, ...event.pages.skip(1)],
      );
      final supplied = SourceEventAnalysis(
        profile: analysis.profile,
        events: [forgedEvent, ...analysis.events.skip(1)],
        diagnostics: [],
      );
      final inventory = SourceInteractionInventory.build(
        source: source,
        analysis: supplied,
        toolRevision: 'tool',
      ).toJson();
      final actual = (inventory['events'] as List).first['pages'][0];
      expect(actual['presence']['characterName'], 'ObjectOrPerson');
      expect(actual['commandBodyEmpty'], false);
    },
  );
  test('public profile cannot invent an archive or interpretation witness',
      () async {
    final source = await fixture();
    final interpretation = SourceInterpretationProfile.fromJson({
      'kind': 'sourceInterpretationProfile',
      'schemaVersion': 2,
      'profileId': 'invented-unbound-profile',
      'semanticsId': 'rmxp-essentials-static-v1',
      'scriptsArchive': {
        'relativePath': 'Data/Scripts.rxdata',
        'sha256': 'a' * 64
      },
      'capabilities': ['events'],
      'sections': {
        'events.invented': {'index': 0, 'sha256': 'b' * 64}
      },
    });
    for (final witness in <SourceInterpretationProfile?>[
      null,
      interpretation
    ]) {
      final profile = SourceEventProfile(
          sourceSnapshotHash: source.snapshot.canonicalHash,
          normalizationHash: source.canonicalHash,
          scriptsArchiveHash: Sha256Hash('a' * 64),
          interpretationProfile: witness);
      final supplied =
          SourceEventAnalyzer.forProject(source, profile: profile).analyze();
      expect(
          () => SourceInteractionInventory.build(
              source: source, analysis: supplied, toolRevision: 'tool'),
          throwsStateError);
    }
  });
  test(
    'historical qualification is separately pinned and never current admission',
    () async {
      final source = await fixture(), analysis = analyze(await fixture());
      final baseline = historical(source, analysis);
      final inventory = SourceInteractionInventory.build(
        source: source,
        analysis: analysis,
        toolRevision: 'current-tool',
        historicalQualificationBytes: historicalBytes(baseline.$1),
        historicalProfileBytes: historicalBytes(baseline.$2),
        historicalFreezeBytes: historicalBytes(baseline.$3),
      );
      final json = inventory.toJson();
      expect(
        (json['historicalQualification'] as Map)['profileSchemaVersion'],
        1,
      );
      expect((json['analysisProfile'] as Map)['interpretationProfile'], null);
      expect(
        (json['historicalQualification'] as Map)['qualifiedEventCount'],
        1,
      );
      expect(json['notYetQualifiedEventCount'], 2);
      final binding = json['historicalQualification'] as Map;
      expect(binding['profileRawJsonCanonicalHash'],
          canonicalHashOf(baseline.$2).value);
      expect(binding['reportedInterpreterCanonicalHash'],
          baseline.$3['interpretationProfileCanonicalHash']);
      expect(binding['profileRawJsonCanonicalHash'],
          isNot(binding['reportedInterpreterCanonicalHash']));
      expect(binding['reportedInterpreterHashVerification'],
          'historicalReportedOnly');
      expect(json['historicalGapEventCounts'], {'one': 2, 'two': 1});
      expect(
        (json['events'] as List).first['historicalQualification']['status'],
        'adaptedStaticSemantics',
      );
    },
  );

  test('inventory snapshots archived input bytes and returned JSON', () async {
    final source = await fixture(), analysis = analyze(await fixture());
    final baseline = historical(source, analysis);
    final qualificationBytes = historicalBytes(baseline.$1);
    final profileBytes = historicalBytes(baseline.$2);
    final freezeBytes = historicalBytes(baseline.$3);
    final inventory = SourceInteractionInventory.build(
        source: source,
        analysis: analysis,
        toolRevision: 'tool',
        historicalQualificationBytes: qualificationBytes,
        historicalProfileBytes: profileBytes,
        historicalFreezeBytes: freezeBytes);
    final before = jsonEncode(inventory.toJson());
    for (final bytes in [qualificationBytes, profileBytes, freezeBytes]) {
      bytes.fillRange(0, bytes.length, 255);
    }
    (inventory.summaryJson()['analysisProfile'] as Map)['profile'] = 'mutated';
    (inventory.toJson()['events'] as List).clear();
    expect(jsonEncode(inventory.toJson()), before);
  });
  test(
      'historical binding fails closed on coverage identity hashes and profile mismatches',
      () async {
    final source = await fixture(), analysis = analyze(await fixture());
    for (final mutate in <void Function(
      Map<String, dynamic>,
      Map<String, dynamic>,
      Map<String, dynamic>,
    )>[
      (q, p, f) => q['events'].removeLast(),
      (q, p, f) => q['events'].add(q['events'][0]),
      (q, p, f) => q['events'][0]['sourceIdentity'] = 'foreign',
      (q, p, f) => q['events'][0]['sourceFileId'] = 'foreign',
      (q, p, f) => q['events'][0]['locator']['mapId'] = 8,
      (q, p, f) => q['events'][0]['pages'].removeLast(),
      (q, p, f) =>
          q['events'][0]['pages'][0]['rawDataRef']['contentHash'] = '0' * 64,
      (q, p, f) => q['events'][0]['pages'][0]['originalPageIndex'] = 9,
      (q, p, f) => q['sourceSnapshotHash'] = '0' * 64,
      (q, p, f) => q['profileEvidenceHash'] = '0' * 64,
      (q, p, f) => p['schemaVersion'] = 2,
      (q, p, f) => f['interpretationProfileSha256'] = '0' * 64,
      (q, p, f) => f['interpretationProfileCanonicalHash'] = 'invalid',
      (q, p, f) => q['qualifiedEventCount'] = 2,
    ]) {
      final baseline = historical(source, analysis);
      final q = jsonDecode(jsonEncode(baseline.$1)) as Map<String, dynamic>;
      final p = jsonDecode(jsonEncode(baseline.$2)) as Map<String, dynamic>;
      final f = jsonDecode(jsonEncode(baseline.$3)) as Map<String, dynamic>;
      mutate(q, p, f);
      expect(
        () => SourceInteractionInventory.build(
          source: source,
          analysis: analysis,
          toolRevision: 'test',
          historicalQualificationBytes: historicalBytes(q),
          historicalProfileBytes: historicalBytes(p),
          historicalFreezeBytes: historicalBytes(f),
        ),
        throwsStateError,
      );
    }
    final baseline = historical(source, analysis);
    expect(
        () => SourceInteractionInventory.build(
            source: source,
            analysis: analysis,
            toolRevision: 'test',
            historicalQualificationBytes: historicalBytes(baseline.$1),
            historicalProfileBytes: [32, ...historicalBytes(baseline.$2)],
            historicalFreezeBytes: historicalBytes(baseline.$3)),
        throwsStateError);
    expect(
      () => SourceInteractionInventory.build(
        source: source,
        analysis: analysis,
        toolRevision: 'test',
        historicalQualificationBytes:
            historicalBytes(historical(source, analysis).$1),
      ),
      throwsStateError,
    );
  });
}

(Map<String, Object?>, Map<String, Object?>, Map<String, Object?>) historical(
  NormalizedSourceProject source,
  SourceEventAnalysis analysis,
) {
  final profile = <String, Object?>{
    'kind': 'sourceInterpretationProfile',
    'schemaVersion': 1,
    'profileId': 'archived',
    'capabilities': ['walking', 'events'],
  };
  final qualification = <String, Object?>{
    'sourceSnapshotHash': source.snapshot.canonicalHash.value,
    'profileEvidenceHash': source.snapshot.profile.evidenceHash.value,
    'nativeDraftHash': 'd' * 64,
    'globalPlayabilityCertified': false,
    'sourceScriptsExecuted': 0,
    'aiSourceInferenceCalls': 0,
    'qualifiedEventCount': 1,
    'quarantinedEventCount': 1,
    'events': [
      for (final event in analysis.events)
        {
          'sourceIdentity': event.identity.value,
          'sourceFileId': event.sourceFileId.value,
          'locator': event.locator.toJson(),
          'status': event.sourceEventId == 1
              ? 'adaptedStaticSemantics'
              : 'quarantinedWholeEvent',
          'gaps': event.sourceEventId == 1 ? ['one', 'two'] : ['one'],
          'pages': [
            for (final page in event.pages)
              {
                'originalPageIndex': page.originalPageIndex,
                'triggerCode': page.triggerCode,
                'locator': page.locator.toJson(),
                'rawDataRef': page.rawDataRef!.toJson(),
                'isEmpty': page.isEmpty,
                'condition': page.condition.toJson(),
                'adaptedCommands': [],
              },
          ],
        },
    ],
  };
  return (
    qualification,
    profile,
    {
      'expectedSourceSnapshotHash': source.snapshot.canonicalHash.value,
      'interpretationProfileSha256':
          crypto.sha256.convert(historicalBytes(profile)).toString(),
      'interpretationProfileCanonicalHash': canonicalHashOf({
        ...profile,
        'capabilities': ['events', 'walking']
      }).value,
      'interpretationProfileId': 'archived',
      'commit': 'old-tool',
    },
  );
}

List<int> historicalBytes(Object value) => utf8.encode(jsonEncode(value));
