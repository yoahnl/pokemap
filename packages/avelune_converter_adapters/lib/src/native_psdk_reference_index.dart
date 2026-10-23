import 'package:avelune_converter_core/avelune_converter_core.dart';

import 'native_psdk_trainer_bundle.dart';

final class NativePsdkReferenceIndex {
  NativePsdkReferenceIndex._(this.document, this.canonicalHash);

  factory NativePsdkReferenceIndex.fromJson(
    Map<String, Object?> document, {
    required Sha256Hash expectedHash,
    required Sha256Hash catalogManifestHash,
    required Iterable<String> catalogSpeciesIds,
  }) {
    const limits =
        ContractLimits(maxNodes: 2000000, maxTextCodeUnits: 16777216);
    final hash = canonicalHashOf(document, limits: limits);
    final frozen = _freeze(document) as Map<String, Object?>;
    if (hash != expectedHash ||
        frozen['kind'] != 'nativePsdkReferenceAdmission' ||
        frozen['version'] != 1 ||
        frozen['catalogManifestHash'] != catalogManifestHash.value ||
        frozen['sourceScriptsExecuted'] != 0 ||
        frozen['aiSourceInferenceCalls'] != 0) {
      _invalid('identity');
    }
    final definitions = frozen['definitions'];
    final families = frozen['families'];
    final counts = frozen['counts'];
    if (definitions is! List ||
        definitions.isEmpty ||
        definitions.length > 8192 ||
        families is! List ||
        families.isEmpty ||
        families.length > definitions.length ||
        counts is! Map) {
      _invalid('partition');
    }
    final byBase = <String, Map>{};
    final admitted = <String>{};
    var formsCount = 0;
    var admittedCount = 0;
    for (final row in definitions) {
      if (row is! Map ||
          row['baseId'] is! String ||
          !RegExp(r'^[a-z0-9_]+$').hasMatch(row['baseId'] as String) ||
          byBase.containsKey(row['baseId']) ||
          row['familyId'] is! String ||
          !const {'admitted', 'refused'}.contains(row['status'])) {
        _invalid('partition');
      }
      final forms = row['forms'];
      final ids = row['nativeSpeciesIds'];
      final reasons = row['reasons'];
      if (forms is! List ||
          forms.length > 256 ||
          forms.any((form) => form is! int || form < 0 || form > 999) ||
          forms.toSet().length != forms.length ||
          ids is! List ||
          ids.length != forms.length ||
          reasons is! List ||
          (row['status'] == 'admitted' &&
              (!forms.contains(0) ||
                  reasons.isNotEmpty ||
                  row['englishName'] is! String ||
                  (row['englishName'] as String).trim().isEmpty)) ||
          (row['status'] == 'refused' && reasons.isEmpty)) {
        _invalid('partition');
      }
      for (var index = 0; index < forms.length; index++) {
        if (ids[index] !=
            nativePsdkFormSpeciesId(
                row['baseId'] as String, forms[index] as int)) {
          _invalid('partition');
        }
        if (row['status'] == 'admitted' && !admitted.add(ids[index] as String)) {
          _invalid('partition');
        }
      }
      formsCount += forms.length;
      if (row['status'] == 'admitted') admittedCount++;
      byBase[row['baseId'] as String] = row;
    }
    final grouped = <String>{};
    final familyIds = <String>{};
    for (final family in families) {
      if (family is! Map ||
          family['familyId'] is! String ||
          !familyIds.add(family['familyId'] as String) ||
          family['baseIds'] is! List ||
          (family['baseIds'] as List).isEmpty ||
          family['reasons'] is! List) {
        _invalid('partition');
      }
      for (final base in family['baseIds'] as List) {
        final row = byBase[base];
        if (base is! String ||
            row == null ||
            !grouped.add(base) ||
            row['familyId'] != family['familyId'] ||
            row['status'] != family['status'] ||
            canonicalJsonOf(row['reasons']) !=
                canonicalJsonOf(family['reasons'])) {
          _invalid('partition');
        }
      }
    }
    final expectedIds = catalogSpeciesIds.toSet();
    if (grouped.length != byBase.length ||
        counts['inspectedBases'] != byBase.length ||
        counts['inspectedForms'] != formsCount ||
        counts['admittedBases'] != admittedCount ||
        counts['refusedBases'] != byBase.length - admittedCount ||
        admitted.length != expectedIds.length ||
        !admitted.containsAll(expectedIds)) {
      _invalid('partition');
    }
    return NativePsdkReferenceIndex._(frozen, expectedHash);
  }

  final Map<String, Object?> document;
  final Sha256Hash canonicalHash;

  Map<String, Object?> get summary => {
        'kind': 'nativePsdkReferenceAvailability',
        'version': 1,
        'indexHash': canonicalHash.value,
        'referenceSnapshotHash': document['referenceSnapshotHash'],
        'catalogManifestHash': document['catalogManifestHash'],
        'counts': document['counts'],
        'refusedFamilies': [
          for (final family in document['families'] as List)
            if ((family as Map)['status'] == 'refused') family,
        ],
      };
}

Never _invalid(String code) => throw ContractError(
    'native_catalog.reference_$code',
    r'$',
    'The native reference inventory must attest the complete admitted and refused partition of this exact catalogue.');

Object? _freeze(Object? value) => switch (value) {
      Map value => Map<String, Object?>.unmodifiable(
          value.map((key, entry) => MapEntry(key as String, _freeze(entry)))),
      List value => List<Object?>.unmodifiable(value.map(_freeze)),
      _ => value,
    };
