import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';

import '../../bin/src/project_template_catalog_loader.dart';

void main() {
  const canonical = '{"schemaVersion":1,"templates":[]}';

  test('embedded catalogue uses the native parser without package resolution',
      () async {
    final result = await loadCliProjectTemplateCatalog(
      embeddedCatalogBase64: base64Encode(utf8.encode(canonical)),
      resolvePackageUri: (_) => throw StateError('package resolver invoked'),
    );
    expect(result.toJson(),
        ProjectTemplateCatalog.fromJson(jsonDecode(canonical)).toJson());
  });

  test('malformed embedded JSON refuses instead of falling back to packages',
      () async {
    await expectLater(
      loadCliProjectTemplateCatalog(
        embeddedCatalogBase64: base64Encode(utf8.encode('{broken')),
        resolvePackageUri: (_) => throw StateError('package resolver invoked'),
      ),
      throwsFormatException,
    );
  });

  test('invalid embedded catalogue schema refuses through the native parser',
      () async {
    await expectLater(
      loadCliProjectTemplateCatalog(
        embeddedCatalogBase64: base64Encode(
          utf8.encode('{"schemaVersion":99,"templates":[]}'),
        ),
        resolvePackageUri: (_) => throw StateError('package resolver invoked'),
      ),
      throwsFormatException,
    );
  });

  test('invalid base64 refuses without package fallback', () async {
    await expectLater(
      loadCliProjectTemplateCatalog(
        embeddedCatalogBase64: '%%%invalid',
        resolvePackageUri: (_) => throw StateError('package resolver invoked'),
      ),
      throwsFormatException,
    );
  });

  test('invalid embedded UTF8 refuses without package fallback', () async {
    await expectLater(
      loadCliProjectTemplateCatalog(
        embeddedCatalogBase64: base64Encode([255]),
        resolvePackageUri: (_) => throw StateError('package resolver invoked'),
      ),
      throwsFormatException,
    );
  });

  test('default JIT lookup reads the exact canonical asset', () async {
    final expected = ProjectTemplateCatalog.fromJson(
      jsonDecode(await File('assets/project_templates.v1.json').readAsString()),
    );
    expect((await loadCliProjectTemplateCatalog()).toJson(), expected.toJson());
  });

  test('missing package resolution refuses', () async {
    await expectLater(
      loadCliProjectTemplateCatalog(resolvePackageUri: (_) async => null),
      throwsStateError,
    );
  });

  test('missing package asset refuses', () async {
    final root = await Directory.systemTemp.createTemp('catalog-loader-');
    try {
      await expectLater(
        loadCliProjectTemplateCatalog(
          resolvePackageUri: (_) async =>
              root.uri.resolve('lib/map_authoring.dart'),
        ),
        throwsA(isA<FileSystemException>()),
      );
    } finally {
      await root.delete(recursive: true);
    }
  });
}
