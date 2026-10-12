import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'asset_review_session_test.dart' show candidate, claim, sourceMap;
import 'contracts_test.dart' show fixture;
import 'domain_test.dart' show event;

Map<String, Object?> _copy(Object? input) =>
    (jsonDecode(jsonEncode(input)) as Map).cast<String, Object?>();

void main() {
  test('immutable SourceMapIr reuses its exact canonical hash object', () {
    final document = SourceMapIr.fromJson(fixture('source_map_ir'));
    final expected = canonicalHashOf(document.toJson());
    final hash = document.canonicalHash;
    expect(hash, expected);
    for (var index = 0; index < 64; index++) {
      expect(identical(document.canonicalHash, hash), isTrue);
    }
  });

  test('caller changes before first hash cannot alter frozen source bytes', () {
    final input = fixture('source_map_ir');
    (input['map'] as Map)['events'] = [event()];
    final document = SourceMapIr.fromJson(input);
    final bytes = canonicalJsonOf(document.toJson());
    final expected = canonicalHashOf(document.toJson());
    final map = input['map'] as Map;
    map['name'] = 'Changed caller name';
    ((map['layers'] as List).first as Map)['cells'][0] = 900;
    (((map['events'] as List).first['pages'] as List).first['commands'] as List)
        .first['parameters'][0]['inert'][2] = 'Changed caller text';
    expect(document.canonicalHash, expected);
    expect(canonicalJsonOf(document.toJson()), bytes);
    expect(identical(document.canonicalHash, document.canonicalHash), isTrue);
  });

  test(
      'serialized source is deeply frozen and mutable copies cannot stale hash',
      () {
    final input = fixture('source_map_ir');
    (input['map'] as Map)['events'] = [event()];
    final document = SourceMapIr.fromJson(input);
    final hash = document.canonicalHash;
    final bytes = canonicalJsonOf(document.toJson());
    final serialized = document.toJson();
    expect(() => serialized['sourceProfileId'] = 'changed',
        throwsUnsupportedError);
    expect(() => (serialized['map'] as Map)['name'] = 'changed',
        throwsUnsupportedError);
    expect(
        () => ((serialized['map'] as Map)['layers'] as List).first['cells'][0] =
            900,
        throwsUnsupportedError);
    final copy = _copy(serialized);
    final map = copy['map'] as Map;
    map['name'] = 'Changed copy name';
    ((map['layers'] as List).first as Map)['cells'][0] = 900;
    (((map['events'] as List).first['pages'] as List).first['commands'] as List)
        .first['parameters'][0]['inert'][2] = 'Changed copy text';
    final changed = SourceMapIr.fromJson(copy);
    expect(changed.canonicalHash, isNot(hash));
    expect(document.canonicalHash, hash);
    expect(identical(document.canonicalHash, hash), isTrue);
    expect(canonicalJsonOf(document.toJson()), bytes);
  });

  test('warmed source digest still rejects a claim against changed source data',
      () {
    final original = sourceMap();
    final sourceClaim = claim(original);
    final asset = candidate('tree');
    final hash = original.canonicalHash;
    sourceClaim.validateAgainst(original, asset);
    expect(identical(original.canonicalHash, hash), isTrue);
    final copy = _copy(original.toJson());
    (copy['map'] as Map)['name'] = 'Different exact source document';
    final changed = SourceMapIr.fromJson(copy);
    expect(changed.canonicalHash, isNot(hash));
    expect(
        () => sourceClaim.validateAgainst(changed, asset),
        throwsA(isA<ContractError>()
            .having((error) => error.code, 'code', 'review.claim.source')));
    sourceClaim.validateAgainst(original, asset);
    expect(identical(original.canonicalHash, hash), isTrue);
  });
}
