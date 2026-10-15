import 'dart:convert';
import 'dart:io';
import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:avelune_converter_adapters/src/source_event_projection.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:map_core/map_core.dart';

final class _Files implements SourceFilePort {
  _Files(this.bytes, this.paths, this.sourceRoot);
  final Map<ConverterId, List<int>> bytes;
  final Map<ConverterId, String> paths;
  final String sourceRoot;

  @override
  Future<List<int>> read(ConverterId id) async => bytes.containsKey(id)
      ? List.of(bytes[id]!)
      : File('$sourceRoot/${paths[id]}').readAsBytes();
}

Future<(NormalizedSourceProject, SourceFilePort)> readFixedRouteSource(
    String folder, String sourceRoot,
    {bool unrelatedRosterChange = false,
    String? additionalHeader,
    String? loseTextOverride}) async {
  final input = jsonDecode(await File('$folder/snapshot.json').readAsString())
      as Map<String, dynamic>;
  final frozen =
      jsonDecode(await File('$folder/normalized.json').readAsString())
          as Map<String, dynamic>;
  final bytes = <ConverterId, List<int>>{
    for (final dynamic row in frozen['archive']['files'])
      ConverterId(row['entry']['fileId'] as String):
          base64Decode(row['rawBytes'] as String)
  };
  final paths = <ConverterId, String>{
    for (final dynamic row in input['entries'])
      ConverterId(row['fileId'] as String): row['relativePath'] as String,
  };
  final rosterId = paths.entries
      .singleWhere((entry) => entry.value == 'PBS/trainers.txt')
      .key;
  final rosterBytes = await File('$sourceRoot/PBS/trainers.txt').readAsBytes();
  if (unrelatedRosterChange) {
    bytes[rosterId] = [
      ...rosterBytes,
      ...utf8.encode('\n# unrelated attested comment\n')
    ];
  }
  if (additionalHeader != null) {
    final raw = utf8.decode(rosterBytes);
    bytes[rosterId] = utf8.encode(raw.replaceFirst('[FRLG_BUGCATCHER,Brent]',
        '[FRLG_BUGCATCHER,Brent]\n$additionalHeader'));
  }
  if (loseTextOverride != null) {
    bytes[rosterId] = utf8.encode(utf8.decode(rosterBytes).replaceFirst(
        'LoseText = WHAT? What a total waste of time!',
        'LoseText = $loseTextOverride'));
  }
  final rosterChanged = bytes.containsKey(rosterId);
  final files = _Files(bytes, paths, sourceRoot);
  final snapshot = SourceSnapshot(
      logicalProjectNamespace:
          ConverterId(input['logicalProjectNamespace'] as String),
      policyHash: Sha256Hash(input['policyHash'] as String),
      entries: [
        for (final dynamic row in input['entries'])
          SourceFileEntry(
              fileId: ConverterId(row['fileId'] as String),
              relativePath: row['relativePath'] as String,
              kind: SourceNodeKind.values.byName(row['kind'] as String),
              byteLength: row['fileId'] == rosterId.value && rosterChanged
                  ? bytes[rosterId]!.length
                  : row['byteLength'] as int,
              sha256: row['sha256'] == null
                  ? null
                  : Sha256Hash(row['fileId'] == rosterId.value && rosterChanged
                      ? crypto.sha256.convert(bytes[rosterId]!).toString()
                      : row['sha256'] as String),
              format: row['format'] as String,
              family: row['family'] as String)
      ],
      diagnostics: [],
      excludedPaths: (input['excludedPaths'] as List).cast<String>(),
      profileEvidence: [
        for (final dynamic row in input['profileEvidence'])
          SourceProfileEvidence(
              relativePath: row['relativePath'] as String,
              fileHash: Sha256Hash(row['fileHash'] as String),
              version: row['version'] as String,
              line: row['line'] as int,
              excerpt: row['excerpt'] as String)
      ],
      state: SourceScanState.values.byName(input['state'] as String));
  final source = await const RmxpSourceNormalizer().normalize(
      snapshot: snapshot,
      files: files,
      selectedMapIds: {98, 102},
      includeEventSystem: true);
  return (source, files);
}

Map<int, MapData> fixedRouteNativeMaps(NormalizedSourceProject source,
    {List<MapEntity> occupied = const [], bool blockBrent = false}) {
  final resolver = SourceSemanticResolver.forProject(source);
  return {
    for (final ir in source.maps)
      ir.map.sourceMapId: MapData(
          id: 'native_${ir.map.sourceMapId}',
          name: ir.map.name,
          size: GridSize(width: ir.map.width, height: ir.map.height),
          entities: ir.map.sourceMapId == 98 ? occupied : const [],
          layers: [
            MapLayer.collision(
                id: 'collision_${ir.map.sourceMapId}',
                name: 'Collision',
                collisions:
                    List.generate(ir.map.width * ir.map.height, (index) {
                  final x = index % ir.map.width, y = index ~/ ir.map.width;
                  final brent = ir.map.events
                      .where((event) => event.sourceEventId == 1)
                      .firstOrNull;
                  if (blockBrent &&
                      ir.map.sourceMapId == 98 &&
                      brent?.x == x &&
                      brent?.y == y) {
                    return true;
                  }
                  return resolver
                          .resolveConnectionEntryTile(
                              resolver.cellAt(ir.map.sourceMapId, x, y))
                          .status ==
                      SourcePassageStatus.blocked;
                }))
          ])
  };
}

Map<String, SourceEventCharacterBinding> fixedRouteCharacters(
        NormalizedSourceProject source, SourceEventAnalysis analysis) =>
    {
      for (final graphic in analysis.events
          .expand((event) => event.pages)
          .map((page) => page.graphic)
          .whereType<SourceEventGraphic>())
        for (final file in source.snapshot.entries.where((file) =>
            file.relativePath ==
            'Graphics/Characters/${graphic.characterName}.png'))
          sourceEventCharacterBindingKey(
                  characterName: graphic.characterName,
                  pattern: graphic.pattern,
                  direction: graphic.direction):
              SourceEventCharacterBinding(
                  characterId: 'native_${graphic.characterName}',
                  sourceSnapshotHash: source.snapshot.canonicalHash,
                  sourceFileId: file.fileId,
                  sourceFileHash: file.sha256!,
                  sourcePattern: graphic.pattern,
                  sourceDirection: graphic.direction)
    };
