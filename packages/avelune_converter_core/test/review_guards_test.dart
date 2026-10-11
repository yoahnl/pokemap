import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'admission_test.dart'
    show
        contextFor,
        readyPlanJson,
        realCandidate,
        realDecisions,
        RecordingTarget;
import 'contracts_test.dart' show fixture;

Map<String, Object?> approvedCandidate() => realCandidate()
  ..['state'] = 'approved'
  ..['approvedRevision'] = 1;

Map<String, Object?> approvingDecisions() {
  final input = realDecisions();
  (input['decisions'] as List)[0]['action'] = 'approve';
  return input;
}

ConversionPlan assetPlan(Map<String, Object?> decisions) {
  final input = readyPlanJson()
    ..['decisionsHash'] =
        ReviewDecisions.fromJson(decisions).canonicalHash.value;
  final operation = (input['operations'] as List)[0] as Map;
  operation['domain'] = 'assets';
  operation['sourceEntityIds'] = ['candidate-house-01'];
  return ConversionPlan.fromJson(input);
}

Map<String, Object?> successReport(String scope, String state) {
  final input = fixture('conversion_report')
    ..['exampleOnly'] = false
    ..['scope'] = scope
    ..['state'] = state
    ..['findings'] = <Object?>[]
    ..['artifacts'] = [
      {
        'relativePath': 'project.json',
        'sha256': 'a' * 64,
        'role': 'nativeProject'
      }
    ];
  final checks = input['checks'] as Map;
  for (final key in checks.keys) {
    checks[key] = 'passed';
  }
  if (scope == 'inventory') {
    checks['nativeLoad'] = 'notApplicable';
    checks['nativeSaveReload'] = 'notApplicable';
    checks['visualParity'] = 'notApplicable';
    checks['gameplayTrace'] = 'notApplicable';
  }
  return input;
}

void main() {
  test('JSON object keys obey per-string and aggregate quotas', () {
    expect(
      () => canonicalJsonOf(
        {'x' * 100: null},
        limits:
            const ContractLimits(maxStringCodeUnits: 10, maxTextCodeUnits: 10),
      ),
      throwsFormatException,
    );
    expect(
      () => canonicalJsonOf(
        {'abc': 'de', 'fg': null},
        limits: const ContractLimits(maxTextCodeUnits: 6),
      ),
      throwsFormatException,
    );
  });
  test('same revision cannot substitute the approved candidate content',
      () async {
    final decisions = approvingDecisions();
    final plan = assetPlan(decisions);
    final candidate = approvedCandidate();
    (candidate['parts'] as List)[0]['sourceRect']['x'] = 32;
    final port = RecordingTarget();
    await expectLater(
      applyConversionPlan(
        plan,
        contextFor(plan, candidate: candidate, decisions: decisions, sources: {
          ConverterId('candidate-house-01')
        }, approvedCandidateHashes: {
          ConverterId('candidate-house-01'):
              AssetCandidate.fromJson(approvedCandidate()).canonicalHash,
        }),
        port,
      ),
      throwsFormatException,
    );
    expect(port.calls, 0);
  });
  test('approved asset reaches the port with the exact approval receipt',
      () async {
    final decisions = approvingDecisions();
    final plan = assetPlan(decisions);
    final candidate = AssetCandidate.fromJson(approvedCandidate());
    final receipts = {candidate.candidateId: candidate.canonicalHash};
    final context = contextFor(plan,
        candidate: approvedCandidate(),
        decisions: decisions,
        sources: {candidate.candidateId},
        approvedCandidateHashes: receipts);
    receipts.clear();
    expect(
        () => context.approvedCandidateHashes.clear(), throwsUnsupportedError);
    final port = RecordingTarget();
    await applyConversionPlan(plan, context, port);
    expect(port.calls, 1);
    expect(
        () => admitPlan(
            plan,
            contextFor(plan,
                candidate: approvedCandidate(),
                decisions: decisions,
                sources: {candidate.candidateId})),
        throwsFormatException);
  });
  test('map operations cannot consume unapproved candidates', () async {
    final input = readyPlanJson();
    (input['operations'] as List)[0]
        ['sourceEntityIds'] = ['candidate-house-01'];
    final plan = ConversionPlan.fromJson(input);
    final port = RecordingTarget();
    await expectLater(
        applyConversionPlan(
            plan,
            contextFor(plan, sources: {ConverterId('candidate-house-01')}),
            port),
        throwsFormatException);
    expect(port.calls, 0);
  });
  for (final state in ['verified', 'published']) {
    for (final scope in ['inventory', 'study', 'playableSlice']) {
      test('$scope $state accepts appropriate independent checks', () {
        expect(
            ConversionReport.fromJson(successReport(scope, state)).state.name,
            state);
      });
      test('$scope $state requires an unchanged source check', () {
        final input = successReport(scope, state);
        (input['checks'] as Map)['sourceUnchanged'] = 'notRun';
        expect(() => ConversionReport.fromJson(input), throwsFormatException);
      });
      test('$scope $state requires artifact references', () {
        final input = successReport(scope, state)..['artifacts'] = <Object?>[];
        expect(() => ConversionReport.fromJson(input), throwsFormatException);
      });
    }
    for (final scope in ['study', 'playableSlice']) {
      for (final key in ['nativeLoad', 'nativeSaveReload']) {
        test('$scope $state requires $key', () {
          final input = successReport(scope, state);
          (input['checks'] as Map)[key] = 'notApplicable';
          expect(() => ConversionReport.fromJson(input), throwsFormatException);
        });
      }
    }
    for (final key in ['visualParity', 'gameplayTrace']) {
      test('playableSlice $state requires $key', () {
        final input = successReport('playableSlice', state);
        (input['checks'] as Map)[key] = 'notRun';
        expect(() => ConversionReport.fromJson(input), throwsFormatException);
      });
    }
    test('study $state cannot retain unresolved blocking errors', () {
      final input = successReport('study', state)
        ..['findings'] = fixture('conversion_report')['findings'];
      expect(() => ConversionReport.fromJson(input), throwsFormatException);
    });
    test('study $state cannot claim verification after a failed check', () {
      final input = successReport('study', state);
      (input['checks'] as Map)['visualParity'] = 'failed';
      expect(() => ConversionReport.fromJson(input), throwsFormatException);
    });
  }
}
