import '../../../avelune_converter_core/test/support/interpretation_profile_fixture.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_converter_core/avelune_converter_core.dart';
import 'package:crypto/crypto.dart' as crypto;

import 'literal_tile_fixture.dart';

final class SourceMapMusicOracle {
  const SourceMapMusicOracle._(this.scriptsBytes, this.gameIniBytes,
      this.mkxpConfigBytes, this.engineHash, this.engineByteLength);

  final List<int> scriptsBytes;
  final List<int> gameIniBytes;
  final List<int> mkxpConfigBytes;
  final Sha256Hash engineHash;
  final int engineByteLength;

  static Future<SourceMapMusicOracle> read(String scriptsPath) async {
    final root = File(scriptsPath).parent.parent;
    final engine = await File('${root.path}/Game.exe').readAsBytes();
    return SourceMapMusicOracle._(
      (await File(scriptsPath).readAsBytes()).asUnmodifiableView(),
      (await File('${root.path}/Game.ini').readAsBytes()).asUnmodifiableView(),
      (await File('${root.path}/mkxp.json').readAsBytes()).asUnmodifiableView(),
      Sha256Hash(crypto.sha256.convert(engine).toString()),
      engine.length,
    );
  }
}

final class SourceMapMusicFixture {
  const SourceMapMusicFixture._(
      this.source, this.files, this.snapshot, this.sourceBytes);

  final NormalizedSourceProject source;
  final LiteralFixtureFiles files;
  final SourceSnapshot snapshot;
  final Map<String, List<int>> sourceBytes;

  static Future<SourceMapMusicFixture> create({
    required SourceMapMusicOracle oracle,
    String namespace = 'source-map-music-test',
    List<LiteralFixtureMap>? maps,
    Map<String, List<int>> extraFiles = const {},
    bool includeEventSystem = false,
    Sha256Hash? engineHash,
    int? engineByteLength,
    bool missingEngine = false,
    Map<String, List<int>> filePatches = const {},
    List<SourceFileEntry> additionalEntries = const [],
  }) async {
    final original = await LiteralTileFixture.create(interpretationProfile: fixtureSourceInterpretationProfile,

      namespace: namespace,
      scriptsBytes: syntheticInterpretationArchive,
      maps: maps ??
          [
            LiteralFixtureMap(
                id: 1, autoplayBgm: true, bgmName: 'Original Route')
          ],
      includeEventSystem: includeEventSystem,
      extraFiles: {
        'Game.ini': oracle.gameIniBytes,
        'mkxp.json': oracle.mkxpConfigBytes,
        'Audio/BGM/Original Route.wav': sourceMapMusicFixtureWav(),
        ...extraFiles,
      },
    );
    final bytes = {...original.sourceBytes, ...filePatches};
    final snapshot = SourceSnapshot(
      logicalProjectNamespace: original.snapshot.logicalProjectNamespace,
      policyHash: original.snapshot.policyHash,
      entries: [
        for (final entry in original.snapshot.entries)
          SourceFileEntry(
              fileId: entry.fileId,
              relativePath: entry.relativePath,
              kind: entry.kind,
              byteLength: bytes[entry.relativePath]!.length,
              sha256: literalFixtureHash(bytes[entry.relativePath]!),
              format: entry.format,
              family: entry.family),
        if (!missingEngine)
          SourceFileEntry(
              fileId: ConverterId('source-music-engine'),
              relativePath: 'Game.exe',
              kind: SourceNodeKind.file,
              byteLength: engineByteLength ?? oracle.engineByteLength,
              sha256: engineHash ?? oracle.engineHash,
              format: 'unknown',
              family: 'project'),
        ...additionalEntries,
      ],
      diagnostics: [],
      excludedPaths: [],
      profileEvidence: original.snapshot.profileEvidence,
      state: SourceScanState.complete,
    );
    final files = LiteralFixtureFiles(snapshot, bytes);
    final source = await const RmxpSourceNormalizer().normalize(
        snapshot: snapshot,
        interpretationProfile: fixtureSourceInterpretationProfile,
        files: files,
        includeEventSystem: includeEventSystem);
    files.reads.clear();
    return SourceMapMusicFixture._(
        source, files, snapshot, Map.unmodifiable(bytes));
  }
}

Uint8List sourceMapMusicFixtureWav() {
  final bytes = Uint8List(8044);
  final data = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, utf8.encode('RIFF'));
  data.setUint32(4, bytes.length - 8, Endian.little);
  bytes.setRange(8, 16, utf8.encode('WAVEfmt '));
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 8000, Endian.little);
  data.setUint32(28, 8000, Endian.little);
  data.setUint16(32, 1, Endian.little);
  data.setUint16(34, 8, Endian.little);
  bytes.setRange(36, 40, utf8.encode('data'));
  data.setUint32(40, 8000, Endian.little);
  bytes.fillRange(44, bytes.length, 128);
  return bytes;
}
