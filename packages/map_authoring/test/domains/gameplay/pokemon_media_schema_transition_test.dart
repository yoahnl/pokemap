import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const message =
      'Changing Pokemon media schema requires an explicit migration.';

  test('rejects v1 promotion before activating an opaque extension', () {
    final before = _media(1, frontAnimated: 'assets/legacy/front.gif');
    final after = {...before, 'schemaVersion': 2};

    expect(
      () => _plan(before: before, after: after),
      throwsA(isA<FormatException>()
          .having((error) => error.message, 'message', message)),
    );
    expect(((before['variants'] as Map)['base'] as Map)['frontAnimated'],
        'assets/legacy/front.gif');
  });

  test('rejects promotion before parsing a non-text v1 extension', () {
    final before = _media(1, frontAnimated: {'legacy': 'opaque'});
    final after = {...before, 'schemaVersion': 2};

    expect(
      () => _plan(before: before, after: after),
      throwsA(isA<FormatException>()
          .having((error) => error.message, 'message', message)),
    );
    expect(((before['variants'] as Map)['base'] as Map)['frontAnimated'],
        {'legacy': 'opaque'});
  });

  test('keeps opaque v1 values when the version stays unchanged', () {
    final before = _media(1, frontAnimated: {'legacy': 'opaque'});
    final after = _media(1,
        frontAnimated: {'legacy': 'opaque'}, frontStatic: 'assets/new.png');
    final encoded = _after(_plan(before: before, after: after));
    final variant = (encoded['variants'] as Map)['base'] as Map;

    expect(encoded['schemaVersion'], 1);
    expect(variant['frontAnimated'], {'legacy': 'opaque'});
    expect(variant['frontStatic'], 'assets/new.png');
    expect(encoded['vendorExtension'], {'keep': true});
  });

  test('allows new and existing v2 media without changing schema', () {
    final before = _media(2, frontAnimated: 'assets/old.gif');
    final after = _media(2, frontAnimated: 'assets/new.gif');
    for (final previous in [null, before]) {
      final encoded = _after(_plan(before: previous, after: after));
      final parsed = PokemonMediaFile.fromJson(encoded);
      expect(parsed.schemaVersion, 2);
      expect(parsed.variants['base']!.frontAnimated, 'assets/new.gif');
      expect(encoded['vendorExtension'], {'keep': true});
    }
  });

  test('rejects a v2 to v1 downgrade', () {
    final before = _media(2, frontAnimated: 'assets/front.gif');
    final after = _media(1, frontAnimated: 'assets/front.gif');

    expect(
      () => _plan(before: before, after: after),
      throwsA(isA<FormatException>()
          .having((error) => error.message, 'message', message)),
    );
  });

  test('rejects a schema change inside a document batch', () {
    final before = _media(1, frontAnimated: 'assets/legacy.gif');
    final after = {...before, 'schemaVersion': 2};

    expect(
      () => _plan(before: before, after: after, batch: true),
      throwsA(isA<FormatException>()
          .having((error) => error.message, 'message', message)),
    );
  });
}

Map<String, dynamic> _media(
  int version, {
  Object? frontAnimated,
  String frontStatic = 'assets/front.png',
}) =>
    {
      'schemaVersion': version,
      'speciesId': 'cyndaquil',
      'defaultFormId': 'base',
      'vendorExtension': {'keep': true},
      'variants': {
        'base': {
          'frontStatic': frontStatic,
          if (frontAnimated != null) 'frontAnimated': frontAnimated,
        },
      },
    };

AuthoringMutationDraft _plan({
  Map<String, dynamic>? before,
  required Map<String, dynamic> after,
  bool batch = false,
}) {
  final manifest =
      ProjectManifest(name: 'schema test', maps: const [], tilesets: const []);
  final snapshot = ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_schema_test'),
    revision: 'sha256:${'0' * 64}',
    manifest: manifest,
    maps: const [],
    resourceFingerprints: const {},
  );
  final parameters = <String, Object?>{
    'relativePath': '${manifest.pokemon.mediaDir}/cyndaquil.json',
    if (before != null)
      'beforeBytesBase64': base64Encode(utf8.encode(jsonEncode(before))),
    'document': after,
  };
  final request = AuthoringRequest(
    requestId: 'schema-test',
    actionId: batch ? 'pokemon.documents.write' : 'pokemon.media.write',
    actionVersion: 1,
    workspaceHandle: 'workspace-schema-test',
    parameters: batch
        ? {
            'documents': [
              {'actionId': 'pokemon.media.write', 'parameters': parameters}
            ]
          }
        : parameters,
  );
  return const PokemonCatalogActions().build(
    AuthoringPlanningContext(
        snapshot: snapshot, request: request, planId: 'schema-test', seed: 1),
  );
}

Map<String, dynamic> _after(AuthoringMutationDraft draft) =>
    jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
        as Map<String, dynamic>;
