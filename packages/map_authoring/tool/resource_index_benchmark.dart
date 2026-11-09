import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/src/workspace/catalog/catalog_resource_usage_index.dart';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';

import '../test/support/resource_index_fixture.dart';

Future<void> main(List<String> arguments) async {
  final root = Directory(arguments.single);
  final canonical = await root.resolveSymbolicLinks();
  if (!canonical.startsWith(
      '/Users/karim/Library/Caches/AveluneQA/resource-inverse-index/')) {
    throw StateError('The benchmark requires its owned QA copy.');
  }
  Future<T> measure<T>(String phase, Future<T> Function() body,
      {ResourceIndexFixture? fixture}) async {
    fixture?.reader.clear();
    final clock = Stopwatch()..start();
    final T result;
    try {
      result = await body();
    } on VisualLibraryException catch (error) {
      stderr.writeln(jsonEncode(
          {'phase': phase, 'code': error.code, 'details': error.details}));
      rethrow;
    }
    clock.stop();
    stdout.writeln(jsonEncode({
      'phase': phase,
      'elapsedUs': clock.elapsedMicroseconds,
      if (fixture != null) ...{
        'reads': fixture.reader.paths.length,
        'decodedUnits':
            fixture.reader.decodedUnits.values.fold(0, (a, b) => a + b),
        'externalReads': fixture.reader.paths
            .where((path) => path.startsWith('maps/'))
            .length,
      }
    }));
    return result;
  }

  final fixture = await measure(
      'openAndAdmit', () => ResourceIndexFixture.openExisting(root));
  try {
    await measure('prepareResourceIndexes', fixture.prepare, fixture: fixture);
    final catalog = await fixture.catalog();
    final portable = await PortableProjectCatalog.fromSnapshot(catalog,
        metadataFields: {'maps'});
    final maps =
        portable.projectMetadata.maps.map((entry) => entry.id).toList();
    String? resourceId;
    String? mapId;
    String? cursor;
    do {
      final page = await catalog.page(
          kind: CatalogDefinitionKind.model3d, cursor: cursor);
      for (final entry in page.items) {
        final uses = await CatalogResourceUsageIndex.mapUsages(
            catalog, 'model3d', entry.key.id, maps);
        if (uses.length <= 1) {
          resourceId = entry.key.id;
          mapId = uses.firstOrNull ?? maps.first;
          break;
        }
      }
      cursor = page.nextCursor;
    } while (resourceId == null && cursor != null);
    if (resourceId == null) throw StateError('No suitable model is available.');
    stdout.writeln(jsonEncode({
      'resourceId': resourceId,
      'mapId': mapId,
      'maps': maps.length,
      'catalogUnits': catalog.definitionCount
    }));
    for (var i = 0; i < 3; i++) {
      await measure(
          'reserve-$i',
          () => fixture.mutate('resource.classify', {
                'resourceKind': 'model3d',
                'resourceId': resourceId,
                'mapId': mapId,
                'description': 'Index benchmark $i',
              }),
          fixture: fixture);
    }
    for (var i = 0; i < 3; i++) {
      final id = 'index-benchmark-$i-${DateTime.now().microsecondsSinceEpoch}';
      await fixture.mutate('resource.family.create',
          {'familyId': id, 'name': 'Index benchmark $i'});
      await measure('delete-family-$i',
          () => fixture.mutate('resource.family.delete', {'familyId': id}),
          fixture: fixture);
    }
    final reopened = await fixture.catalog();
    final classification = await reopened.lookup(CatalogDefinitionKey(
        CatalogDefinitionKind.resourceLibraryEntry, 'model3d:$resourceId'));
    if ((classification?.payload['value'] as Map?)?['mapId'] != mapId) {
      throw StateError('The reservation did not survive reopening.');
    }
    await fixture.mutate('resource.classify', {
      'resourceKind': 'model3d',
      'resourceId': resourceId,
      'mapId': null,
      'description': null,
    });
  } finally {
    await fixture.close();
  }
}
