import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'contracts_test.dart' show fixture;
import 'domain_test.dart' show event;
import 'admission_test.dart' show readyPlanJson, contextFor, realProfile;

void main() {
  for (final name in [
    'source_map_ir',
    'asset_candidate',
    'review_decisions',
    'vision_response',
    'target_capabilities',
    'conversion_plan',
    'conversion_report',
  ]) {
    for (final field in fixture(name).keys) {
      test('$name requires $field', () {
        final input = fixture(name)..remove(field);
        expect(() => decodeContract(input), throwsFormatException);
      });
    }
  }
  test('kind dispatch rejects unknown and mixed envelopes', () {
    expect(
        () => decodeContract(fixture('asset_candidate')..['kind'] = 'unknown'),
        throwsFormatException);
    expect(() => SourceMapIr.fromJson(fixture('asset_candidate')),
        throwsFormatException);
  });
  test('unknown minor versions cannot use an implicit compatibility path', () {
    expect(
        () => decodeContract(
            fixture('asset_candidate')..['schemaVersion'] = '1.1'),
        throwsFormatException);
  });
  test('bool and fractional numbers are not integer dimensions', () {
    for (final value in [true, 3.5, 0]) {
      final input = fixture('source_map_ir');
      (input['map'] as Map)['width'] = value;
      expect(() => decodeContract(input), throwsFormatException);
    }
  });
  test('cells and quarter-turns obey scalar bounds', () {
    final map = fixture('source_map_ir');
    ((map['map'] as Map)['layers'] as List)[0]['cells'][0] = 65536;
    expect(() => decodeContract(map), throwsFormatException);
    final asset = fixture('asset_candidate');
    (asset['parts'] as List)[0]['quarterTurns'] = 4;
    expect(() => decodeContract(asset), throwsFormatException);
  });
  test('unknown enum values are rejected', () {
    expect(
        () => decodeContract(
            fixture('asset_candidate')..['category'] = 'anything'),
        throwsFormatException);
  });
  test('hashes and IDs cannot contain malformed text', () {
    for (final hash in ['ABC', 'A' * 64, 'a' * 63]) {
      expect(
          () => decodeContract(
              fixture('asset_candidate')..['sourceSnapshotHash'] = hash),
          throwsFormatException);
    }
    for (final id in ['../escape', '', 'candidate\n']) {
      expect(
          () =>
              decodeContract(fixture('asset_candidate')..['candidateId'] = id),
          throwsFormatException);
    }
    expect(() => ConverterId('candidate\n'), throwsFormatException);
    expect(() => Sha256Hash('a' * 64 + '\n'), throwsFormatException);
  });
  test(
      'current approved candidates and confirmed approval decisions are representable',
      () {
    final candidate = AssetCandidate.fromJson(fixture('asset_candidate')
      ..['state'] = 'approved'
      ..['approvedRevision'] = 1);
    expect(candidate.state, CandidateState.approved);
    final input = fixture('review_decisions');
    (input['decisions'] as List)[0]['action'] = 'approve';
    expect(ReviewDecisions.fromJson(input).decisions.first.action,
        ReviewAction.approve);
    (input['decisions'] as List)[0]['humanConfirmed'] = false;
    expect(
        () => decodeContract(input),
        throwsA(isA<ContractError>()
            .having((e) => e.path, 'path', r'$.decisions[0].humanConfirmed')));
  });
  test('approved candidates require an approved revision', () {
    expect(
        () =>
            decodeContract(fixture('asset_candidate')..['state'] = 'approved'),
        throwsFormatException);
  });
  test('supported capabilities require relevant evidence', () {
    final profile = realProfile();
    expect(TargetCapabilities.fromJson(profile).capabilities.first.status,
        CapabilityStatus.supported);
    (profile['capabilities'] as List)[0]['evidence'] = [];
    expect(() => decodeContract(profile), throwsFormatException);
  });
  test('rectangles can touch the exact right and bottom image bounds', () {
    final input = fixture('asset_candidate');
    (input['parts'] as List)[0]['sourceRect']['x'] = 160;
    (input['parts'] as List)[0]['sourceRect']['y'] = 160;
    (input['parts'] as List)[0]['quarterTurns'] = 3;
    (input['parts'] as List)[0]['reflected'] = true;
    expect(AssetCandidate.fromJson(input).parts.first.reflected, isTrue);
    (input['parts'] as List)[0]['sourceRect']['y'] = 161;
    expect(() => decodeContract(input), throwsFormatException);
  });
  test('odd width uses explicit anchor rather than an implicit rounded center',
      () {
    final input = fixture('asset_candidate');
    input['canvasSize'] = {'width': 97, 'height': 96};
    expect(() => decodeContract(input), throwsFormatException);
    (input['anchor'] as Map)['convention'] = 'explicit';
    expect(AssetCandidate.fromJson(input).anchor.x, 48);
  });
  test('opaque nested getters and serialized snapshots are deeply immutable',
      () {
    final input = fixture('source_map_ir');
    (input['map'] as Map)['events'] = [event()];
    final ir = SourceMapIr.fromJson(input);
    final hash = ir.canonicalHash;
    final opaque =
        ir.map.events.first.pages.first.commands.first.parameters.first as Map;
    expect(() => opaque['inert'] = [], throwsUnsupportedError);
    expect(() => (opaque['inert'] as List).clear(), throwsUnsupportedError);
    expect(() => (ir.toJson()['map'] as Map)['events'] = [],
        throwsUnsupportedError);
    expect(() => (ir.toJson()['map'] as Map)['layers'][0]['cells'].clear(),
        throwsUnsupportedError);
    expect(ir.canonicalHash, hash);
  });
  test('canonical Unicode nested objects and numbers have a stable golden', () {
    expect(
        canonicalJsonOf({
          'z': null,
          'é': {
            'b': 1.0,
            'a': [true, 'été']
          }
        }),
        '{"z":null,"é":{"a":[true,"été"],"b":1}}');
    expect(canonicalHashOf(1), canonicalHashOf(1.0));
    expect(
        () => canonicalJsonOf({1: 'not a string key'}), throwsFormatException);
  });
  test('node and text quotas fail before copying an unbounded value', () {
    expect(
        () =>
            canonicalJsonOf([1, 2], limits: const ContractLimits(maxNodes: 2)),
        throwsFormatException);
    expect(
        () => canonicalJsonOf('four',
            limits: const ContractLimits(maxStringCodeUnits: 3)),
        throwsFormatException);
    expect(
        () => canonicalJsonOf(['ab', 'cd'],
            limits: const ContractLimits(maxTextCodeUnits: 3)),
        throwsFormatException);
  });
  test('study loss decisions are scoped to the same source locator', () {
    final input = readyPlanJson();
    final loss = (fixture('conversion_plan')['findings'] as List).first as Map;
    loss['cause'] = 'converterUnsupported';
    loss['disposition'] = 'acceptedStudyLoss';
    loss['acceptedByDecisionId'] = 'decision-01';
    loss['sourceLocator']['mapId'] = 2;
    input['findings'] = [loss];
    final plan = ConversionPlan.fromJson(input);
    expect(() => admitPlan(plan, contextFor(plan)), throwsFormatException);
  });
}
