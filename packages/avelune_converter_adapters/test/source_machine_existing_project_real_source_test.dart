import 'dart:convert';
import 'dart:io';

import 'package:avelune_converter_adapters/avelune_converter_adapters.dart';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/source_external_original_fixture.dart';

void main() {
  final sourceRoot = Platform.environment['AVELUNE_STATIC_DOOR_SOURCE_ROOT'];
  final snapshot = Platform.environment['AVELUNE_STATIC_DOOR_SNAPSHOT'];
  final project = Platform.environment['AVELUNE_MACHINE_PROJECT'];
  final export = Platform.environment['AVELUNE_MACHINE_UPDATE_EXPORT'];
  test('existing source machines acquire only attested native machine metadata',
      () async {
    final fixture = await readExternalOriginalSource(sourceRoot!, snapshot!,
        selectedMapIds: const {75},
        supplementalRoots:
            (Platform.environment['AVELUNE_STATIC_DOOR_SUPPLEMENTAL_ROOTS'] ??
                    '')
                .split('|')
                .where((value) => value.isNotEmpty)
                .toList());
    final pbs = await const SourcePbsParser().read(
        snapshot: fixture.source.snapshot,
        files: fixture.files,
        families: const {
          SourcePbsFamily.items,
          SourcePbsFamily.moves,
          SourcePbsFamily.species,
          SourcePbsFamily.forms
        });
    final manifest = ProjectManifest.fromJson(
        jsonDecode(await File('$project/project.json').readAsString()));
    final itemPath = manifest.pokemon.catalogFiles['items']!;
    final itemBytes = await File('$project/$itemPath').readAsBytes();
    final rawItems = jsonDecode(utf8.decode(itemBytes)) as Map;
    final before =
        ProjectItemCatalog.fromJson(Map<String, dynamic>.from(rawItems));
    final byId = <String, String>{
      for (final entry in pbs.entries.where((entry) =>
          entry.family == SourcePbsFamily.items &&
          entry.identity?.sourceSymbol != null))
        'source-item-${canonicalHashOf({
              'namespace': pbs.logicalProjectNamespace.value,
              'sourceSymbol': entry.identity!.sourceSymbol
            }).value.substring(0, 24)}': entry.identity!.sourceSymbol!
    };
    final symbols = <String>[];
    for (final item in before.entries
        .where((item) => item.pocketId == 'machines' && item.machine == null)) {
      expect(byId[item.id], isNotNull, reason: item.id);
      symbols.add(byId[item.id]!);
    }
    final bindings = await const SourceEventItemBindingResolver().read(
        snapshot: fixture.source.snapshot,
        files: fixture.files,
        symbols: symbols,
        eventProfile: SourceEventProfile.forProject(fixture.source));
    final updates = <Map<String, Object?>>[];
    final unresolved = <Map<String, Object?>>[];
    for (final item
        in before.entries.where((item) => symbols.contains(byId[item.id]))) {
      final symbol = byId[item.id]!;
      final binding = bindings.bindings[symbol];
      final machine = binding?.definition.machine;
      if (machine == null) {
        unresolved.add({
          'itemId': item.id,
          'sourceSymbol': symbol,
          'binding': binding?.toJson(),
          'refusals': bindings.quarantinedSymbols[symbol]
        });
        continue;
      }
      final after = item.copyWith(machine: machine);
      expect(after.copyWith(machine: item.machine), item);
      updates.add({
        'itemId': item.id,
        'sourceSymbol': symbol,
        'beforeHash': canonicalHashOf((rawItems['entries'] as List)
            .cast<Map>()
            .singleWhere((row) => row['id'] == item.id)).value,
        'value': {
          ...(rawItems['entries'] as List)
              .cast<Map>()
              .singleWhere((row) => row['id'] == item.id),
          'machine': machine.toJson()
        },
        'sourceProof': binding!.toJson()
      });
    }
    for (final symbol in ['TM100', 'TM038']) {
      final changed =
          updates.where((row) => row['sourceSymbol'] == symbol).toList();
      final id = byId.entries.singleWhere((entry) => entry.value == symbol).key;
      final machine = changed.isNotEmpty
          ? (changed.single['value'] as Map)['machine'] as Map
          : before.entries
              .singleWhere((item) => item.id == id)
              .machine!
              .toJson();
      expect(machine['moveId'], symbol == 'TM100' ? 'rock_tomb' : 'fire_blast');
    }
    final learnsetUpdates = <Map<String, Object?>>[];
    final dir = Directory('$project/${manifest.pokemon.learnsetsDir}');
    await for (final file in dir.list()) {
      if (file is! File || !file.path.endsWith('.json')) continue;
      final raw = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final source = PokemonLearnsetFile.fromJson(raw);
      final after = projectNativeFieldMachineLearnset(source);
      if (canonicalJsonOf(after.toJson()) == canonicalJsonOf(source.toJson())) {
        continue;
      }
      final value = {
        ...raw,
        'hm': after.hm.map((entry) => entry.toJson()).toList()
      };
      expect({...value, 'hm': raw['hm']}, raw);
      learnsetUpdates.add({
        'relativePath': file.path.substring(project!.length + 1),
        'beforeHash': canonicalHashOf(raw).value,
        'value': value
      });
    }
    final native = NativePsdkCatalogManifest.builtin();
    final library = await const SourceCatalogProjector().read(
        source: fixture.source,
        pbs: pbs,
        files: fixture.files,
        nativeMapIds: const {},
        nativeTrainerBundle: native,
        nativeTrainerMovePolicy: NativeTrainerMovePolicy.nativeAveluneDefaults);
    for (final document in library.documents.where(
        (document) => document.kind == SourceCatalogDocumentKind.learnset)) {
      final original =
          native.learnsetsBySpeciesId[document.document['speciesId']]!;
      expect(document.document,
          projectNativeFieldMachineLearnset(original).toJson());
    }
    final missingDocuments = <Map<String, Object?>>[];
    final catalogAdditions = <Map<String, Object?>>[];
    for (final document in library.documents) {
      if (document.kind == SourceCatalogDocumentKind.catalog) {
        if (document.document['catalog'] == 'items') {
          continue;
        }
        final file = File('$project/${document.relativePath}');
        if (!await file.exists()) {
          missingDocuments.add(document.toJson());
          continue;
        }
        final current = jsonDecode(await file.readAsString()) as Map;
        final known = (current['entries'] as List)
            .cast<Map>()
            .map((row) => row['id'])
            .toSet();
        final added = (document.document['entries'] as List)
            .cast<Map>()
            .where((row) => !known.contains(row['id']))
            .toList();
        if (added.isNotEmpty) {
          catalogAdditions.add({
            'relativePath': document.relativePath,
            'catalog': document.document['catalog'],
            'beforeHash': canonicalHashOf(current).value,
            'entries': added
          });
        }
      } else if (!await File('$project/${document.relativePath}').exists()) {
        missingDocuments.add(document.toJson());
      }
    }
    final assets = <Map<String, Object?>>[];
    if (export != null) {
      final folder = Directory('$export.artifacts');
      await folder.create(recursive: true);
      final byHandle = {
        for (final artifact in library.artifacts) artifact.handle: artifact
      };
      for (final mutation in library.assetMutations) {
        final target = mutation.parameters['logicalPath'] as String;
        if (await File('$project/$target').exists()) {
          continue;
        }
        final artifact = byHandle[mutation.parameters['artifactHandle']]!;
        final file = File('${folder.path}/${artifact.rawSha256.value}');
        await file.writeAsBytes(artifact.bytes);
        assets.add({
          'logicalPath': target,
          'artifactPath': file.path,
          'sha256': artifact.rawSha256.value,
          'mutation': mutation.toJson(assets.length)
        });
      }
      await File(export).writeAsString(jsonEncode({
        'kind': 'sourceMachineAndNativeLearnsetTargetedUpdates',
        'sourceSnapshotHash': fixture.source.snapshot.canonicalHash.value,
        'projectPath': project,
        'itemCatalogPath': itemPath,
        'itemCatalogBeforeHash': canonicalHashOf(before.toJson()).value,
        'machineUpdates': updates,
        'unresolvedMachines': unresolved,
        'learnsetUpdates': learnsetUpdates,
        'missingNativeDocuments': missingDocuments,
        'nativeCatalogAdditions': catalogAdditions,
        'missingNativeAssets': assets,
        'sourceScriptsExecuted': 0,
        'aiCalls': 0,
        'battleRulesModified': false
      }));
    }
    stdout.writeln(jsonEncode({
      'sourceMachines': symbols.length,
      'machineUpdates': updates.length,
      'unresolved': unresolved.map((row) => row['sourceSymbol']).toList(),
      'learnsetUpdates': learnsetUpdates.length,
      'missingNativeDocuments': missingDocuments.length,
      'catalogAdditions': catalogAdditions.length,
      'assets': assets.length
    }));
    expect(unresolved, isEmpty);
  },
      timeout: const Timeout(Duration(minutes: 4)),
      skip: sourceRoot == null || snapshot == null || project == null
          ? 'Requires explicit exact source, snapshot and project.'
          : false);
}
