import 'dart:convert';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import '../../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'literal_tile_fixture.dart';

final class DeclaredProgramFixtureEvent {
  const DeclaredProgramFixtureEvent(
      {required this.id,
      required this.name,
      required this.x,
      required this.y,
      required this.pages});
  final int id, x, y;
  final String name;
  final List<Map<String, Object?>> pages;
}

Object? declaredFixtureObject(Object? value) {
  if (value is Map) {
    if (value['__class__'] == 'Tone') {
      return LiteralFixtureUserDefined(
          'Tone', base64Decode(value['marshalPayload'] as String));
    }
    if (value['__class__'] case final String name) {
      return LiteralFixtureObject(name, {
        for (final entry in value.entries)
          if (entry.key != '__class__')
            '@${entry.key}': declaredFixtureObject(entry.value)
      });
    }
    return value.map((k, v) => MapEntry(k, declaredFixtureObject(v)));
  }
  if (value is List) return value.map(declaredFixtureObject).toList();
  return value;
}

Object? _marshalValue(MarshalDocument document, int id) {
  final node = document.node(id);
  return switch (node.kind) {
    MarshalKind.nil => null,
    MarshalKind.boolean => node.booleanValue,
    MarshalKind.integer => node.integerValue!.toInt(),
    MarshalKind.string => node.text().text,
    MarshalKind.symbol => LiteralFixtureSymbol(node.text().text!),
    MarshalKind.array => [
        for (final child in node.elements) _marshalValue(document, child)
      ],
    MarshalKind.hash => {
        for (final pair in node.pairs)
          _marshalValue(document, pair.key): _marshalValue(document, pair.value)
      },
    MarshalKind.object => LiteralFixtureObject(node.className!, {
        for (final pair in node.instanceVariables)
          document.node(pair.key).text().text!:
              _marshalValue(document, pair.value)
      }),
    MarshalKind.userDefined =>
      LiteralFixtureUserDefined(node.className!, node.bytes!),
    _ => throw StateError(
        'Unsupported declared fixture marshal kind ${node.kind}'),
  };
}

Future<({NormalizedSourceProject source, LiteralFixtureFiles files})>
    createDeclaredProgramFixture(
        {required String namespace,
        required SourceInterpretationProfile profile,
        required Map<int, List<DeclaredProgramFixtureEvent>> maps,
        Map<String, List<int>> extraFiles = const {},
        List<LiteralFixtureTileset>? tilesets,
        Map<int, Map<(int, int), int>> tileOverrides = const {}}) async {
  final base = await LiteralTileFixture.create(
      namespace: namespace,
      scriptsBytes: syntheticInterpretationArchive,
      includeEventSystem: true,
      extraFiles: extraFiles,
      tilesets: tilesets,
      maps: [
        for (final id in maps.keys)
          LiteralFixtureMap(id: id, width: 64, height: 64, layers: [
            [
              for (var index = 0; index < 4096; index++)
                tileOverrides[id]?[(index % 64, index ~/ 64)] ?? 384
            ],
            List.filled(4096, 0),
            List.filled(4096, 0)
          ])
      ]);
  final bytes = {...base.sourceBytes};
  for (final entry in maps.entries) {
    final path = 'Data/Map${entry.key.toString().padLeft(3, '0')}.rxdata';
    final doc = const MarshalDecoder().decode(bytes[path]!, sourcePath: path);
    final original = _marshalValue(doc, doc.rootId) as LiteralFixtureObject;
    bytes[path] = literalFixtureMarshal(LiteralFixtureObject(original.name, {
      ...original.fields,
      '@events': {
        for (final event in entry.value)
          event.id: LiteralFixtureObject('RPG::Event', {
            '@id': event.id,
            '@name': event.name,
            '@x': event.x,
            '@y': event.y,
            '@pages': event.pages.map(declaredFixtureObject).toList()
          })
      }
    }));
  }
  final systemPath = 'Data/System.rxdata';
  final systemDoc =
      const MarshalDecoder().decode(bytes[systemPath]!, sourcePath: systemPath);
  final system =
      _marshalValue(systemDoc, systemDoc.rootId) as LiteralFixtureObject;
  bytes[systemPath] = literalFixtureMarshal(LiteralFixtureObject(system.name, {
    ...system.fields,
    '@variables': [null, for (var id = 1; id <= 256; id++) 'Variable $id'],
    '@switches': [null, for (var id = 1; id <= 256; id++) 'Switch $id'],
  }));
  final snapshot = SourceSnapshot(
      logicalProjectNamespace: base.snapshot.logicalProjectNamespace,
      policyHash: base.snapshot.policyHash,
      entries: [
        for (final entry in base.snapshot.entries)
          SourceFileEntry(
              fileId: entry.fileId,
              relativePath: entry.relativePath,
              kind: entry.kind,
              byteLength: bytes[entry.relativePath]!.length,
              sha256: literalFixtureHash(bytes[entry.relativePath]!),
              format: entry.format,
              family: entry.family)
      ],
      diagnostics: [],
      excludedPaths: [],
      profileEvidence: base.snapshot.profileEvidence,
      state: SourceScanState.complete);
  final files = LiteralFixtureFiles(snapshot, bytes);
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: files,
      interpretationProfile: profile,
      includeEventSystem: true);
  return (source: source, files: files);
}
