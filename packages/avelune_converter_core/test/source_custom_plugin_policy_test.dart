import 'dart:convert';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:test/test.dart';

import 'support/interpretation_profile_fixture.dart';

void main() {
  test('absent plugin policy retains the strict profile and its canonical hash', () {
    final original = fixtureSourceInterpretationProfile;
    final profile = SourceInterpretationProfile.fromJson(original.toJson());
    expect(profile.customPluginPolicy, SourceCustomPluginPolicy.requireAbsent);
    expect(profile.toJson(), isNot(contains('customPluginPolicy')));
    expect(profile.canonicalHash, original.canonicalHash);
    final explicit = SourceInterpretationProfile.fromJson({
      ...original.toJson(), 'customPluginPolicy': 'requireAbsent',
    });
    expect(explicit.toJson(), original.toJson());
    expect(explicit.canonicalHash, original.canonicalHash);
  });

  test('custom behavior exclusion is explicit typed and changes the profile binding', () {
    final original = fixtureSourceInterpretationProfile;
    final profile = SourceInterpretationProfile.fromJson({
      ...original.toJson(), 'customPluginPolicy': 'excludeCustomBehavior',
    });
    expect(profile.customPluginPolicy, SourceCustomPluginPolicy.excludeCustomBehavior);
    expect(profile.toJson()['customPluginPolicy'], 'excludeCustomBehavior');
    expect(profile.canonicalHash, isNot(original.canonicalHash));
    expect(SourceInterpretationProfile.fromJson(jsonDecode(jsonEncode(profile.toJson())))
        .canonicalHash, profile.canonicalHash);
  });

  for (final value in [null, false, 0, 'ignore', 'EXCLUDE', [], {}]) {
    test('rejects unknown or untyped plugin policy $value', () {
      expect(() => SourceInterpretationProfile.fromJson({
        ...fixtureSourceInterpretationProfile.toJson(), 'customPluginPolicy': value,
      }), throwsA(isA<ContractError>()));
    });
  }
}
