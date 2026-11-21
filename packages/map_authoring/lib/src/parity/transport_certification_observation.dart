part of 'transport_certification_scenario.dart';

final class AuthoringTransportObservation {
  const AuthoringTransportObservation._(this.path, this.at, this.condition,
      this.expected, this.catalogDefinition);

  factory AuthoringTransportObservation.fromJson(Map<String, Object?> json) {
    const conditions = {'equals', 'exists', 'absent', 'sha256'};
    transportEvidenceFields(json, const {'path'},
        optional: {'at', 'catalogDefinition', ...conditions});
    final selected = json.keys.where(conditions.contains).toList();
    if (selected.length != 1) {
      throw const FormatException(
          'An observation requires exactly one condition.');
    }
    final condition = selected.single;
    final expected = json[condition];
    final path = transportEvidencePath(json['path']);
    final at = json['at'] ?? const [];
    final definition = json.containsKey('catalogDefinition')
        ? CatalogDefinitionKey.fromJson(
            transportEvidenceObject(json['catalogDefinition'], 'catalog key'))
        : null;
    if (path.split('/').first == '.pokemap' ||
        at is! List ||
        at.any((value) => value is! String && (value is! int || value < 0)) ||
        (condition == 'sha256' &&
            (at.isNotEmpty || !isTransportEvidenceDigest(expected))) ||
        (definition != null &&
            (path != CatalogStorageStore.headStorageKey ||
                condition == 'sha256')) ||
        ((condition == 'exists' || condition == 'absent') &&
            expected != true)) {
      throw FormatException('Invalid persisted observation: $path.');
    }
    return AuthoringTransportObservation._(
        path, List.unmodifiable(at), condition, expected, definition);
  }

  final String path;
  final List<Object?> at;
  final String condition;
  final Object? expected;
  final CatalogDefinitionKey? catalogDefinition;

  Future<Map<String, Object?>> read(Directory root) async {
    final file = File(p.join(root.path, path));
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return const {'present': false};
    if (type != FileSystemEntityType.file ||
        !p.isWithin(root.path, await file.resolveSymbolicLinks())) {
      throw FormatException(
          'Observation must read a regular project file: $path.');
    }
    Object? value;
    if (catalogDefinition case final definition?) {
      final store = await CatalogStorageStore.open(projectRoot: root.path);
      final head = await store.readHead();
      if (head == null) return const {'present': false};
      final catalog = await store.openRoot(head);
      final unit = await catalog.snapshot.lookup(definition);
      if (unit == null) return const {'present': false};
      value = unit.payload;
    } else if (condition == 'sha256') {
      value = 'sha256:${(await sha256.bind(file.openRead()).first)}';
    } else if (at.isNotEmpty || condition == 'equals') {
      value = jsonDecode(await file.readAsString());
    }
    for (final selector in at) {
      if (selector is String && value is Map && value.containsKey(selector)) {
        value = value[selector];
      } else if (selector is int && value is List && selector < value.length) {
        value = value[selector];
      } else {
        return const {'present': false};
      }
    }
    return {'present': true, 'value': value};
  }

  void verify(Object? rawBefore, Object? rawAfter) {
    final before = _validatedObservation(rawBefore);
    final after = _validatedObservation(rawAfter);
    final matches = switch (condition) {
      'absent' => after['present'] == false,
      'exists' => after['present'] == true,
      _ => after['present'] == true &&
          canonicalAuthoringJson(after['value']) ==
              canonicalAuthoringJson(expected),
    };
    if (!matches) {
      throw FormatException(
        'Persisted observation $path $at expected $condition $expected, got $after.',
      );
    }
    if (condition == 'sha256' &&
        before['present'] == true &&
        !isTransportEvidenceDigest(before['value'])) {
      throw FormatException('Invalid prior file digest: $path.');
    }
  }

  Map<String, Object?> _validatedObservation(Object? input) {
    final result = transportEvidenceObject(input, 'observation result');
    final present = result['present'];
    if (present is! bool) {
      throw const FormatException('Missing observation presence.');
    }
    transportEvidenceFields(result, {'present', if (present) 'value'});
    return result;
  }
}
