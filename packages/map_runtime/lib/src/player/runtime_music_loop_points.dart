import 'dart:io';
import 'dart:typed_data';

/// Les points de boucle d'une piste, en échantillons — BETA-BAT-026.
///
/// Convention RPG Maker / Pokémon SDK, portée par les commentaires Vorbis des
/// `.ogg` : `LOOPSTART` est l'échantillon où la boucle reprend, `LOOPLENGTH`
/// sa longueur. Tout ce qui précède `LOOPSTART` est l'INTRO du morceau, jouée
/// une seule fois.
final class RuntimeMusicLoopPoints {
  const RuntimeMusicLoopPoints({
    required this.startSample,
    required this.lengthSamples,
    required this.sampleRate,
  });

  final int startSample;
  final int lengthSamples;
  final int sampleRate;

  Duration get start => Duration(
        microseconds: (startSample * 1000000 / sampleRate).round(),
      );

  Duration get end => Duration(
        microseconds:
            ((startSample + lengthSamples) * 1000000 / sampleRate).round(),
      );

  @override
  String toString() =>
      'RuntimeMusicLoopPoints(start: $startSample, length: $lengthSamples, '
      'rate: $sampleRate)';
}

/// Lit les points de boucle d'un fichier audio, ou null s'il n'en porte pas.
///
/// Volontairement un SCAN de commentaire, pas un parser Ogg complet : les
/// commentaires Vorbis vivent dans le deuxième paquet du flux, donc au tout
/// début du fichier. Lire un préfixe borné suffit et évite de charger
/// plusieurs mégaoctets pour deux entiers.
///
/// La fréquence d'échantillonnage est lue dans l'en-tête d'identification
/// Vorbis, qui précède les commentaires ; à défaut, 44,1 kHz — la valeur de
/// toutes les pistes de la référence.
RuntimeMusicLoopPoints? readRuntimeMusicLoopPoints(
  String path, {
  int maxPrefixBytes = 65536,
}) {
  if (maxPrefixBytes <= 0) return null;
  final file = File(path);
  if (!file.existsSync()) return null;
  Uint8List prefix;
  int fileLength;
  try {
    final handle = file.openSync();
    try {
      final length = handle.lengthSync();
      fileLength = length;
      prefix = handle.readSync(
        length < maxPrefixBytes ? length : maxPrefixBytes,
      );
    } finally {
      handle.closeSync();
    }
  } on Object {
    return null;
  }

  if (_matchesFourCC(prefix, 0, 'RIFF')) {
    return _readWaveLoopPoints(prefix, fileLength);
  }

  final startSample = _readTagValue(prefix, 'LOOPSTART');
  if (startSample == null || startSample < 0) return null;
  final lengthSamples = _readTagValue(prefix, 'LOOPLENGTH');
  if (lengthSamples == null || lengthSamples <= 0) return null;

  return RuntimeMusicLoopPoints(
    startSample: startSample,
    lengthSamples: lengthSamples,
    sampleRate: _readVorbisSampleRate(prefix) ?? 44100,
  );
}

RuntimeMusicLoopPoints? _readWaveLoopPoints(Uint8List bytes, int fileLength) {
  if (bytes.length < 12 || !_matchesFourCC(bytes, 8, 'WAVE')) return null;
  final data = ByteData.sublistView(bytes);
  final riffEnd = 8 + data.getUint32(4, Endian.little);
  if (riffEnd < 12 || riffEnd > fileLength) return null;
  int? sampleRate;
  int? blockAlign;
  int? dataLength;
  int? loopStart;
  int? loopEnd;
  var hasSampler = false;
  var offset = 12;
  while (offset < riffEnd) {
    if (offset + 8 > bytes.length || offset + 8 > riffEnd) return null;
    final length = data.getUint32(offset + 4, Endian.little);
    final payload = offset + 8;
    final chunkEnd = payload + length;
    final next = chunkEnd + length % 2;
    if (next > riffEnd) return null;
    if (_matchesFourCC(bytes, offset, 'fmt ')) {
      if (sampleRate != null || length < 16 || payload + 16 > bytes.length) {
        return null;
      }
      final format = data.getUint16(payload, Endian.little);
      final channels = data.getUint16(payload + 2, Endian.little);
      final rate = data.getUint32(payload + 4, Endian.little);
      final byteRate = data.getUint32(payload + 8, Endian.little);
      final alignment = data.getUint16(payload + 12, Endian.little);
      final bits = data.getUint16(payload + 14, Endian.little);
      if (format != 1 ||
          channels == 0 ||
          rate == 0 ||
          !const {8, 16, 24, 32}.contains(bits) ||
          alignment != channels * (bits ~/ 8) ||
          byteRate != rate * alignment) {
        return null;
      }
      sampleRate = rate;
      blockAlign = alignment;
    } else if (_matchesFourCC(bytes, offset, 'smpl')) {
      if (hasSampler || length < 36 || chunkEnd > bytes.length) return null;
      hasSampler = true;
      final loopCount = data.getUint32(payload + 28, Endian.little);
      final samplerDataLength = data.getUint32(payload + 32, Endian.little);
      if (36 + loopCount * 24 + samplerDataLength > length) return null;
      for (var index = 0; index < loopCount; index++) {
        final loop = payload + 36 + index * 24;
        if (data.getUint32(loop + 4, Endian.little) != 0) continue;
        final start = data.getUint32(loop + 8, Endian.little);
        final end = data.getUint32(loop + 12, Endian.little);
        if (end < start ||
            data.getUint32(loop + 16, Endian.little) != 0 ||
            data.getUint32(loop + 20, Endian.little) != 0) {
          return null;
        }
        loopStart ??= start;
        loopEnd ??= end;
      }
    } else if (_matchesFourCC(bytes, offset, 'data')) {
      if (dataLength != null) return null;
      dataLength = length;
    }
    offset = next;
  }
  if (sampleRate == null ||
      blockAlign == null ||
      dataLength == null ||
      dataLength % blockAlign != 0 ||
      loopStart == null ||
      loopEnd == null ||
      loopEnd >= dataLength ~/ blockAlign) {
    return null;
  }
  return RuntimeMusicLoopPoints(
    startSample: loopStart,
    lengthSamples: loopEnd - loopStart + 1,
    sampleRate: sampleRate,
  );
}

bool _matchesFourCC(Uint8List bytes, int offset, String value) {
  if (offset + 4 > bytes.length) return false;
  for (var index = 0; index < 4; index++) {
    if (bytes[offset + index] != value.codeUnitAt(index)) return false;
  }
  return true;
}

/// Cherche `NOM=` (insensible à la casse) et lit l'entier qui suit.
int? _readTagValue(Uint8List bytes, String name) {
  final needle = '$name='.codeUnits;
  for (var offset = 0; offset + needle.length < bytes.length; offset += 1) {
    var matches = true;
    for (var i = 0; i < needle.length; i += 1) {
      final actual = bytes[offset + i];
      final expected = needle[i];
      // Comparaison insensible à la casse sur l'ASCII des lettres.
      final normalizedActual =
          actual >= 0x61 && actual <= 0x7A ? actual - 0x20 : actual;
      final normalizedExpected =
          expected >= 0x61 && expected <= 0x7A ? expected - 0x20 : expected;
      if (normalizedActual != normalizedExpected) {
        matches = false;
        break;
      }
    }
    if (!matches) continue;
    var cursor = offset + needle.length;
    var value = 0;
    var digits = 0;
    while (cursor < bytes.length &&
        bytes[cursor] >= 0x30 &&
        bytes[cursor] <= 0x39) {
      value = value * 10 + (bytes[cursor] - 0x30);
      digits += 1;
      cursor += 1;
      if (digits > 18) return null;
    }
    if (digits == 0) continue;
    return value;
  }
  return null;
}

/// La fréquence d'échantillonnage de l'en-tête d'identification Vorbis.
///
/// Structure : `0x01` + `"vorbis"` + version (4 octets) + canaux (1) +
/// fréquence (4, petit-boutiste).
int? _readVorbisSampleRate(Uint8List bytes) {
  const signature = <int>[0x01, 0x76, 0x6F, 0x72, 0x62, 0x69, 0x73];
  for (var offset = 0; offset + signature.length + 9 < bytes.length; offset++) {
    var matches = true;
    for (var i = 0; i < signature.length; i += 1) {
      if (bytes[offset + i] != signature[i]) {
        matches = false;
        break;
      }
    }
    if (!matches) continue;
    final rateOffset = offset + signature.length + 5;
    if (rateOffset + 4 > bytes.length) return null;
    final rate = bytes[rateOffset] |
        (bytes[rateOffset + 1] << 8) |
        (bytes[rateOffset + 2] << 16) |
        (bytes[rateOffset + 3] << 24);
    return rate > 0 ? rate : null;
  }
  return null;
}
