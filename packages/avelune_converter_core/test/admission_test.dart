import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'contracts_test.dart' show fixture;

Map<String, Object?> realCandidate() =>
    fixture('asset_candidate')..['exampleOnly'] = false;
Map<String, Object?> realDecisions() =>
    fixture('review_decisions')..['exampleOnly'] = false;
Map<String, Object?> realProfile() {
  final input = fixture('target_capabilities')..['exampleOnly'] = false;
  (input['capabilities'] as List)[0]['status'] = 'supported';
  (input['capabilities'] as List)[0]['evidence'] = [
    {
      'type': 'test',
      'summary': 'Native load/save contract verified by fixture',
      'reference': 'receipt:test-native-1'
    }
  ];
  return input;
}

PlanContext contextFor(
  ConversionPlan plan, {
  Map<String, Object?>? candidate,
  Map<String, Object?>? decisions,
  Map<String, Object?>? profile,
  Sha256Hash? sourceHash,
  Sha256Hash? rulesHash,
  Sha256Hash? approvedHash,
  Set<ConverterId>? sources,
  Set<ConverterId>? targets,
  Map<String, ConverterId>? actions,
  Map<ConverterId, Sha256Hash>? approvedCandidateHashes,
}) =>
    PlanContext(
      logicalProjectNamespace: plan.logicalProjectNamespace,
      sessionId: ConverterId('session-demo'),
      sourceSnapshotHash: sourceHash ?? plan.sourceSnapshotHash,
      targetCapabilities: TargetCapabilities.fromJson(profile ?? realProfile()),
      rulesHash: rulesHash ?? plan.rulesHash,
      decisions: ReviewDecisions.fromJson(decisions ?? realDecisions()),
      candidates: [AssetCandidate.fromJson(candidate ?? realCandidate())],
      converterVersion: plan.converterVersion,
      approvedPlanHash: approvedHash ?? plan.canonicalHash,
      sourceMapIds: {1},
      sourceEntityIds: sources ?? {ConverterId('source-map-1')},
      targetEntityIds: targets ?? {ConverterId('target-map-1')},
      approvedCandidateHashes: approvedCandidateHashes ?? {},
      actionCapabilities: actions ??
          {'map.create': ConverterId('native.project.loadSaveReload')},
    );

Map<String, Object?> readyPlanJson() {
  final input = fixture('conversion_plan')
    ..['exampleOnly'] = false
    ..['state'] = 'ready'
    ..['approvedByHuman'] = true
    ..['findings'] = <Object?>[]
    ..['targetProfileHash'] =
        TargetCapabilities.fromJson(realProfile()).canonicalHash.value
    ..['decisionsHash'] =
        ReviewDecisions.fromJson(realDecisions()).canonicalHash.value;
  (input['operations'] as List)[0]['status'] = 'planned';
  (input['operations'] as List)[0]['targetActionId'] = 'map.create';
  return input;
}

final class RecordingTarget implements PlanApplicationPort {
  int calls = 0;
  @override
  Future<void> apply(AdmittedPlan admitted) async {
    calls++;
  }
}

VisionRequestContext visionContext() => VisionRequestContext(
      requestId: ConverterId('vision-request-demo'),
      sourceSnapshotHash: Sha256Hash('a' * 64),
      inputRevision: 1,
      candidateIds: {ConverterId('candidate-house-01')},
      sourceRegionIds: {ConverterId('region-house-01')},
    );

void main() {
  test('IR-02 stable identity ignores display names and current snapshots', () {
    final input = fixture('source_map_ir');
    final first = SourceMapIr.fromJson(input);
    (input['map'] as Map)['name'] = 'Renamed';
    input['sourceSnapshotHash'] = 'f' * 64;
    final second = SourceMapIr.fromJson(input);
    expect(
        SourceIdentity(first.logicalProjectNamespace, ConverterId('map'),
                first.map.sourceMapId)
            .stableId,
        SourceIdentity(second.logicalProjectNamespace, ConverterId('map'),
                second.map.sourceMapId)
            .stableId);
  });
  test('IR-02 equal display names never merge different source identities', () {
    final namespace = ConverterId('project:one');
    expect(SourceIdentity(namespace, ConverterId('map'), 1).stableId,
        isNot(SourceIdentity(namespace, ConverterId('map'), 2).stableId));
    expect(SourceIdentity(namespace, ConverterId('map'), 1).stableId,
        isNot(SourceIdentity(namespace, ConverterId('event'), 1).stableId));
    expect(
        SourceIdentity(namespace, ConverterId('map'), 1).stableId,
        isNot(SourceIdentity(ConverterId('project:two'), ConverterId('map'), 1)
            .stableId));
  });
  test('IR-02 tuple boundaries are unambiguous', () {
    expect(
        SourceIdentity(ConverterId('a:b'), ConverterId('c'), 1).stableId,
        isNot(
            SourceIdentity(ConverterId('a'), ConverterId('b:c'), 1).stableId));
  });
  test('IR-02 rejects negative source identities', () {
    expect(() => SourceIdentity(ConverterId('project'), ConverterId('map'), -1),
        throwsFormatException);
  });
  test('current ready plan reaches the port once', () async {
    final plan = ConversionPlan.fromJson(readyPlanJson());
    final port = RecordingTarget();
    await applyConversionPlan(plan, contextFor(plan), port);
    expect(port.calls, 1);
  });
  test('IR-03 example plan is refused before any target call', () async {
    final plan =
        ConversionPlan.fromJson(readyPlanJson()..['exampleOnly'] = true);
    final port = RecordingTarget();
    await expectLater(applyConversionPlan(plan, contextFor(plan), port),
        throwsFormatException);
    expect(port.calls, 0);
  });
  test('draft, stale and applied plans cannot be admitted', () {
    for (final state in ['draft', 'stale', 'applied']) {
      final plan = ConversionPlan.fromJson(readyPlanJson()..['state'] = state);
      expect(() => admitPlan(plan, contextFor(plan)), throwsFormatException);
    }
  });
  test('changed source snapshot cannot be admitted', () {
    final plan = ConversionPlan.fromJson(readyPlanJson());
    expect(
        () =>
            admitPlan(plan, contextFor(plan, sourceHash: Sha256Hash('f' * 64))),
        throwsFormatException);
  });
  test('changed rules cannot be admitted', () {
    final plan = ConversionPlan.fromJson(readyPlanJson());
    expect(
        () =>
            admitPlan(plan, contextFor(plan, rulesHash: Sha256Hash('f' * 64))),
        throwsFormatException);
  });
  test('changed target profile cannot be admitted', () {
    final plan = ConversionPlan.fromJson(readyPlanJson());
    final profile = realProfile()..['revision'] = 'new-revision';
    expect(() => admitPlan(plan, contextFor(plan, profile: profile)),
        throwsFormatException);
  });
  test('changed human decisions cannot be admitted', () {
    final plan = ConversionPlan.fromJson(readyPlanJson());
    final decisions = realDecisions()..['revision'] = 2;
    expect(() => admitPlan(plan, contextFor(plan, decisions: decisions)),
        throwsFormatException);
  });
  test('policy edits invalidate the exact approved plan hash', () {
    final original = ConversionPlan.fromJson(readyPlanJson());
    final input = readyPlanJson();
    (input['outputPolicy'] as Map)['offline'] = false;
    final changed = ConversionPlan.fromJson(input);
    expect(
        () => admitPlan(
            changed, contextFor(changed, approvedHash: original.canonicalHash)),
        throwsFormatException);
  });
  test('demonstration profile contaminates admission', () {
    final profile = realProfile()..['exampleOnly'] = true;
    final input = readyPlanJson()
      ..['targetProfileHash'] =
          TargetCapabilities.fromJson(profile).canonicalHash.value;
    final plan = ConversionPlan.fromJson(input);
    expect(() => admitPlan(plan, contextFor(plan, profile: profile)),
        throwsFormatException);
  });
  test('demonstration candidate contaminates admission', () {
    final plan = ConversionPlan.fromJson(readyPlanJson());
    expect(
        () => admitPlan(
            plan, contextFor(plan, candidate: fixture('asset_candidate'))),
        throwsFormatException);
  });
  test('an unknown source reference is rejected', () {
    final plan = ConversionPlan.fromJson(readyPlanJson());
    expect(() => admitPlan(plan, contextFor(plan, sources: {})),
        throwsFormatException);
  });
  test('an unknown target reference is rejected', () {
    final plan = ConversionPlan.fromJson(readyPlanJson());
    expect(() => admitPlan(plan, contextFor(plan, targets: {})),
        throwsFormatException);
  });
  test('an unaudited action is rejected', () {
    final plan = ConversionPlan.fromJson(readyPlanJson());
    expect(() => admitPlan(plan, contextFor(plan, actions: {})),
        throwsFormatException);
  });
  test('blocked operations cannot be admitted', () {
    final input = readyPlanJson();
    (input['operations'] as List)[0]['status'] = 'blocked';
    final plan = ConversionPlan.fromJson(input);
    expect(() => admitPlan(plan, contextFor(plan)), throwsFormatException);
  });
  test('approval of another candidate revision is rejected', () {
    final plan = ConversionPlan.fromJson(readyPlanJson());
    final candidate = realCandidate()..['revision'] = 2;
    expect(() => admitPlan(plan, contextFor(plan, candidate: candidate)),
        throwsFormatException);
  });
  test('candidate output policy must match the plan', () {
    final plan = ConversionPlan.fromJson(readyPlanJson());
    final candidate = realCandidate()..['outputMode'] = 'standaloneObjects';
    expect(() => admitPlan(plan, contextFor(plan, candidate: candidate)),
        throwsFormatException);
  });
  test('study loss requires a real confirmed decision', () {
    final input = readyPlanJson();
    final loss = (fixture('conversion_plan')['findings'] as List).first as Map;
    loss['cause'] = 'converterUnsupported';
    loss['disposition'] = 'acceptedStudyLoss';
    loss['acceptedByDecisionId'] = 'missing-decision';
    input['findings'] = [loss];
    final plan = ConversionPlan.fromJson(input);
    expect(() => admitPlan(plan, contextFor(plan)), throwsFormatException);
  });
  test('confirmed study loss cannot unlock playableSlice', () {
    final input = readyPlanJson()..['requestedMode'] = 'playableSlice';
    final loss = (fixture('conversion_plan')['findings'] as List).first as Map;
    loss['cause'] = 'converterUnsupported';
    loss['disposition'] = 'acceptedStudyLoss';
    loss['acceptedByDecisionId'] = 'decision-01';
    input['findings'] = [loss];
    final plan = ConversionPlan.fromJson(input);
    expect(() => admitPlan(plan, contextFor(plan)), throwsFormatException);
  });
  test('a scoped study loss can be admitted for study only', () {
    final input = readyPlanJson();
    final loss = (fixture('conversion_plan')['findings'] as List).first as Map;
    loss['cause'] = 'converterUnsupported';
    loss['disposition'] = 'acceptedStudyLoss';
    loss['acceptedByDecisionId'] = 'decision-01';
    input['findings'] = [loss];
    final plan = ConversionPlan.fromJson(input);
    expect(admitPlan(plan, contextFor(plan)).plan, same(plan));
  });
  test('security errors are never consentable even with cleared flags', () {
    final input = readyPlanJson();
    final loss = (fixture('conversion_plan')['findings'] as List).first as Map;
    loss['cause'] = 'security';
    loss['blocksStudy'] = false;
    loss['blocksPlayableSlice'] = false;
    loss['disposition'] = 'resolved';
    input['findings'] = [loss];
    final plan = ConversionPlan.fromJson(input);
    expect(() => admitPlan(plan, contextFor(plan)), throwsFormatException);
  });
  test('stale vision responses are rejected', () {
    final response = VisionResponse.fromJson(fixture('vision_response')
      ..['exampleOnly'] = false
      ..['inputRevision'] = 2);
    expect(() => validateVisionResponse(response, visionContext()),
        throwsFormatException);
  });
  test('vision cannot introduce arbitrary region IDs', () {
    final input = fixture('vision_response')..['exampleOnly'] = false;
    (input['suggestions'] as List)[0]['sourceRegionIds'] = ['unauthorized'];
    expect(
        () => validateVisionResponse(
            VisionResponse.fromJson(input), visionContext()),
        throwsFormatException);
  });
  test('a matching vision response only proposes known candidates', () {
    final response = VisionResponse.fromJson(
        fixture('vision_response')..['exampleOnly'] = false);
    expect(() => validateVisionResponse(response, visionContext()),
        returnsNormally);
  });
  test('admission context copies caller collections', () {
    final plan = ConversionPlan.fromJson(readyPlanJson());
    final actions = {
      'map.create': ConverterId('native.project.loadSaveReload')
    };
    final context = contextFor(plan, actions: actions);
    actions.clear();
    expect(admitPlan(plan, context).plan, same(plan));
    expect(context.actionCapabilities, isNotEmpty);
    expect(() => context.actionCapabilities.clear(), throwsUnsupportedError);
  });
}
