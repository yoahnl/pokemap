import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'avelune_stress_entropy.dart';

/// Les médias synthétiques des packages de stress — BETA-AVL-005.
///
/// Ils doivent passer `GamePackageContentValidator`, qui ne se contente pas de
/// regarder l'extension : il lit la signature, décode les dimensions d'une
/// image et vérifie les magic bytes de chaque média. Un octet aléatoire nommé
/// `.png` fait échouer la construction du package, pas un stress-test.
abstract final class AveluneStressAssets {
  /// La signature PNG.
  static const List<int> _pngSignature = <int>[
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
  ];

  /// Un PNG réellement décodable, du poids demandé.
  ///
  /// Les pixels sont du bruit plein : le flux zlib ne les comprime pas, donc
  /// le fichier pèse ce que le profil demande ET mesure vraiment le décodage.
  /// Un PNG de zéros ferait 200 octets une fois compressé et ne mesurerait
  /// rien du tout.
  static Uint8List png({
    required int targetBytes,
    required AveluneStressEntropy entropy,
  }) {
    final side = _sideForRgbBytes(targetBytes);
    return pngOfSide(side: side, entropy: entropy);
  }

  /// Un PNG carré de `side` pixels de côté.
  ///
  /// Utilisé tel quel par le profil adversarial, dont l'intérêt est la
  /// DIMENSION — c'est elle qui coûte à la création de `ui.Image` et à
  /// l'upload GPU, pas le poids du fichier.
  static Uint8List pngOfSide({
    required int side,
    required AveluneStressEntropy entropy,
  }) {
    if (side <= 0) {
      throw ArgumentError.value(side, 'side', 'doit être positif');
    }
    // Une scanline PNG = un octet de filtre puis les pixels RGB.
    final raw = Uint8List(side * (1 + side * 3));
    var offset = 0;
    for (var row = 0; row < side; row++) {
      raw[offset++] = 0;
      final pixels = entropy.nextBytes(side * 3);
      raw.setRange(offset, offset + pixels.length, pixels);
      offset += pixels.length;
    }

    final ihdr = ByteData(13)
      ..setUint32(0, side, Endian.big)
      ..setUint32(4, side, Endian.big)
      ..setUint8(8, 8)
      ..setUint8(9, 2)
      ..setUint8(10, 0)
      ..setUint8(11, 0)
      ..setUint8(12, 0);

    final builder = BytesBuilder(copy: false)
      ..add(_pngSignature)
      ..add(_chunk('IHDR', ihdr.buffer.asUint8List()))
      ..add(_chunk('IDAT', Uint8List.fromList(const ZLibEncoder().encode(raw))))
      ..add(_chunk('IEND', Uint8List(0)));
    return builder.toBytes();
  }

  /// Un Ogg Vorbis plausible : pages `OggS` et en-tête d'identification.
  ///
  /// La charge audio est du bruit — ce qui est correct pour du Vorbis, dont
  /// les paquets encodés sont déjà à haute entropie.
  static Uint8List ogg({
    required int targetBytes,
    required AveluneStressEntropy entropy,
    int sampleRate = 44100,
  }) {
    final header = <int>[
      ...'OggS'.codeUnits,
      0, 0, 0, 0, 0, 0, 0, 0,
      0x01, ...'vorbis'.codeUnits,
      0, 0, 0, 0,
      2,
      sampleRate & 0xFF,
      (sampleRate >>> 8) & 0xFF,
      (sampleRate >>> 16) & 0xFF,
      (sampleRate >>> 24) & 0xFF,
      0, 0, 0, 0,
      ...'OggS'.codeUnits,
      0x03, ...'vorbis'.codeUnits,
      ...'ENCODER=pokemap-stress'.codeUnits,
      0,
    ];
    return _padded(header, targetBytes, entropy);
  }

  /// Un MP4 plausible : boîte `ftyp` puis du bruit.
  static Uint8List mp4({
    required int targetBytes,
    required AveluneStressEntropy entropy,
  }) {
    final header = <int>[
      0x00, 0x00, 0x00, 0x18,
      ...'ftyp'.codeUnits,
      ...'isom'.codeUnits,
      0x00, 0x00, 0x02, 0x00,
      ...'isomiso2'.codeUnits,
    ];
    return _padded(header, targetBytes, entropy);
  }

  /// Un blob du magasin content-addressé : des octets opaques.
  ///
  /// Le validateur lit le média EMBARQUÉ d'un `.blob` du magasin, donc on y
  /// place un vrai PNG : c'est ce que le magasin du Train contient.
  static Uint8List blob({
    required int targetBytes,
    required AveluneStressEntropy entropy,
  }) =>
      png(targetBytes: targetBytes, entropy: entropy);

  static Uint8List _padded(
    List<int> header,
    int targetBytes,
    AveluneStressEntropy entropy,
  ) {
    final total = targetBytes < header.length ? header.length : targetBytes;
    final bytes = Uint8List(total)..setRange(0, header.length, header);
    if (total > header.length) {
      final filler = entropy.nextBytes(total - header.length);
      bytes.setRange(header.length, total, filler);
    }
    return bytes;
  }

  static Uint8List _chunk(String type, Uint8List data) {
    final builder = BytesBuilder(copy: false);
    final length = ByteData(4)..setUint32(0, data.length, Endian.big);
    builder.add(length.buffer.asUint8List());
    final typeAndData = Uint8List(4 + data.length)
      ..setRange(0, 4, type.codeUnits)
      ..setRange(4, 4 + data.length, data);
    builder.add(typeAndData);
    final crc = ByteData(4)
      ..setUint32(0, getCrc32(typeAndData), Endian.big);
    builder.add(crc.buffer.asUint8List());
    return builder.toBytes();
  }

  /// Le côté d'un carré RGB dont le poids approche `targetBytes`.
  static int _sideForRgbBytes(int targetBytes) {
    if (targetBytes <= 0) return 1;
    // Trois octets par pixel, plus un octet de filtre par ligne.
    var side = 1;
    while ((side + 1) * (1 + (side + 1) * 3) <= targetBytes) {
      side++;
    }
    return side;
  }
}
