import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

import '../../../tools/gen5_battle_sprite/source_choice.dart';

Uint8List _atlas() => base64.decode(
  'iVBORw0KGgoAAAANSUhEUgAAAQAAAACACAMAAADTa0c4AAAAMFBMVEUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABaPxwLAAAAAXRSTlMAQObYZgAAADdJREFUeJztwTEBAAAAwqD1T20MH6AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgLcBgIAAARE6C/kAAAAASUVORK5CYII=',
);

Uint8List _ncer() {
  final b = Uint8List(62);
  final d = ByteData.sublistView(b);
  b.setRange(0, 4, ascii.encode('RECN'));
  d.setUint16(4, 0xfeff, Endian.little);
  d.setUint16(6, 0x100, Endian.little);
  d.setUint32(8, b.length, Endian.little);
  d.setUint16(12, 16, Endian.little);
  d.setUint16(14, 1, Endian.little);
  b.setRange(16, 20, ascii.encode('KBEC'));
  d.setUint32(20, 46, Endian.little);
  d.setUint16(24, 1, Endian.little);
  d.setUint32(28, 24, Endian.little);
  d.setUint16(48, 1, Endian.little);
  return b;
}

Uint8List _nmcr() {
  final b = Uint8List(64);
  final d = ByteData.sublistView(b);
  b.setRange(0, 4, ascii.encode('RCMN'));
  d.setUint16(4, 0xfeff, Endian.little);
  d.setUint16(6, 0x100, Endian.little);
  d.setUint32(8, b.length, Endian.little);
  d.setUint16(12, 16, Endian.little);
  d.setUint16(14, 1, Endian.little);
  b.setRange(16, 20, ascii.encode('KBCM'));
  d.setUint32(20, 48, Endian.little);
  d.setUint16(24, 1, Endian.little);
  d.setUint32(28, 24, Endian.little);
  d.setUint16(48, 1, Endian.little);
  d.setUint16(50, 1, Endian.little);
  return b;
}

Uint8List _animation({required bool multi}) {
  final b = Uint8List(96);
  final d = ByteData.sublistView(b);
  b.setRange(0, 4, ascii.encode(multi ? 'RAMN' : 'RNAN'));
  d.setUint16(4, 0xfeff, Endian.little);
  d.setUint16(6, 0x100, Endian.little);
  d.setUint32(8, b.length, Endian.little);
  d.setUint16(12, 16, Endian.little);
  d.setUint16(14, 1, Endian.little);
  b.setRange(16, 20, ascii.encode('KNBA'));
  d.setUint32(20, 80, Endian.little);
  d.setUint16(24, 1, Endian.little);
  d.setUint16(26, 1, Endian.little);
  d.setUint32(28, 24, Endian.little);
  d.setUint32(32, 40, Endian.little);
  d.setUint32(36, 48, Endian.little);
  d.setUint16(48, 1, Endian.little);
  d.setUint16(52, 1, Endian.little);
  d.setUint32(56, 2, Endian.little);
  d.setUint16(68, 9, Endian.little);
  d.setInt32(76, 4096, Endian.little);
  d.setInt32(80, 4096, Endian.little);
  return b;
}

Uint8List _lz11(Uint8List data) {
  final result = BytesBuilder()..add([0x11, data.length, 0, 0]);
  for (var i = 0; i < data.length; i += 8) {
    result.addByte(0);
    result.add(data.sublist(i, i + 8 > data.length ? data.length : i + 8));
  }
  return result.takeBytes();
}

Uint8List _info(int width) {
  final b = Uint8List(62);
  final d = ByteData.sublistView(b);
  d.setUint32(0, 1, Endian.little);
  d.setUint16(4, width, Endian.little);
  d.setUint16(6, 20, Endian.little);
  return b;
}

Map<String, Object?> _validSource() {
  Uint8List palette(String color) => Uint8List.fromList(
    ascii.encode('JASC-PAL\n0100\n16\n${List.filled(16, color).join('\n')}\n'),
  );
  final files = <String, Uint8List>{
    'front.png': _atlas(),
    'back.png': _atlas(),
    'front_animations.nanr.lz11': _lz11(_animation(multi: false)),
    'back_animations.nanr.lz11': _lz11(_animation(multi: false)),
    'front_cells.ncer': _ncer(),
    'back_cells.ncer': _ncer(),
    'front_multi_cells.nmcr': _nmcr(),
    'back_multi_cells.nmcr': _nmcr(),
    'front_multi_animations.nmar': _animation(multi: true),
    'back_multi_animations.nmar': _animation(multi: true),
    'front_info.bin': _info(31),
    'back_info.bin': _info(42),
    'normal.pal': palette('255 0 0'),
    'shiny.pal': palette('0 0 255'),
  };
  return {
    'format': 'gen5-battle-source-v1',
    'game': 'black2-white2',
    'scope': 'default-form',
    'species': 'pikachu',
    'nationalDex': 25,
    'assets': {
      for (final entry in files.entries)
        entry.key: {
          'encoding': 'base64',
          'size': entry.value.length,
          'sha256': sha256.convert(entry.value).toString(),
          'data': base64.encode(entry.value),
        },
    },
  };
}

void main() {
  test('refuses source data for a different requested species or dex', () {
    final source = _validSource();
    for (final (species, dex) in [('bulbasaur', 1), ('pikachu', 26)]) {
      final result = selectGen5SourceCandidate(
        document: source,
        expectedSpecies: species,
        expectedNationalDex: dex,
        view: 'front',
        shiny: false,
        gifAvailable: true,
        rendererSupported: true,
      );
      expect(result.kind, Gen5SourceCandidateKind.gifFallback);
      expect(result.reason, Gen5SourceCandidateReason.invalidSource);
    }
  });

  test('selects and decodes the requested view and palette when supported', () {
    final document = _validSource();
    for (final (side, shiny, width, red, blue) in [
      ('front', false, 31, 255, 0),
      ('back', true, 42, 0, 255),
    ]) {
      final result = selectGen5SourceCandidate(
        document: document,
        expectedSpecies: 'pikachu',
        expectedNationalDex: 25,
        view: side,
        shiny: shiny,
        gifAvailable: true,
        rendererSupported: true,
      );
      expect(result.kind, Gen5SourceCandidateKind.parsedSource);
      expect(result.reason, Gen5SourceCandidateReason.none);
      expect(result.view!.info.width, width);
      expect(result.view!.palette.first.r, red);
      expect(result.view!.palette.first.b, blue);
      expect(result.view!.indexedAtlas.indices.length, 256 * 128);
    }
  });

  test('uses the GIF candidate when articulated data is absent', () {
    final result = selectGen5SourceCandidate(
      document: null,
      expectedSpecies: 'pikachu',
      expectedNationalDex: 25,
      view: 'front',
      shiny: false,
      gifAvailable: true,
      rendererSupported: true,
    );
    expect(result.kind, Gen5SourceCandidateKind.gifFallback);
    expect(result.reason, Gen5SourceCandidateReason.missingSource);
    expect(result.view, isNull);
  });

  test('reports corruption and does not select missing GIF data', () {
    final withGif = selectGen5SourceCandidate(
      document: {},
      expectedSpecies: 'pikachu',
      expectedNationalDex: 25,
      view: 'back',
      shiny: false,
      gifAvailable: true,
      rendererSupported: true,
    );
    expect(withGif.kind, Gen5SourceCandidateKind.gifFallback);
    expect(withGif.reason, Gen5SourceCandidateReason.invalidSource);
    expect(withGif.diagnostic, isNotEmpty);
    final withoutGif = selectGen5SourceCandidate(
      document: {},
      expectedSpecies: 'pikachu',
      expectedNationalDex: 25,
      view: 'back',
      shiny: false,
      gifAvailable: false,
      rendererSupported: true,
    );
    expect(withoutGif.kind, Gen5SourceCandidateKind.unavailable);
    expect(withoutGif.reason, Gen5SourceCandidateReason.invalidSource);
  });

  test(
    'rejects an invalid requested view instead of silently falling back',
    () {
      expect(
        () => selectGen5SourceCandidate(
          document: null,
          expectedSpecies: 'pikachu',
          expectedNationalDex: 25,
          view: 'side',
          shiny: false,
          gifAvailable: true,
        ),
        throwsFormatException,
      );
    },
  );

  test('falls back for a truncated atlas even if its digest matches', () {
    final document = _validSource();
    final broken = _atlas().sublist(0, 33);
    ((document['assets'] as Map)['front.png'] as Map)
      ..['size'] = broken.length
      ..['sha256'] = sha256.convert(broken).toString()
      ..['data'] = base64.encode(broken);
    final result = selectGen5SourceCandidate(
      document: document,
      expectedSpecies: 'pikachu',
      expectedNationalDex: 25,
      view: 'front',
      shiny: false,
      gifAvailable: true,
      rendererSupported: true,
    );
    expect(result.kind, Gen5SourceCandidateKind.gifFallback);
    expect(result.reason, Gen5SourceCandidateReason.invalidSource);
  });

  test('keeps GIF fallback when the renderer cannot display the source', () {
    final result = selectGen5SourceCandidate(
      document: {},
      expectedSpecies: 'pikachu',
      expectedNationalDex: 25,
      view: 'front',
      shiny: false,
      gifAvailable: true,
      rendererSupported: false,
    );
    expect(result.kind, Gen5SourceCandidateKind.gifFallback);
    expect(result.reason, Gen5SourceCandidateReason.unsupportedRenderer);
  });
}
