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
  final file = File(path);
  if (!file.existsSync()) return null;
  Uint8List prefix;
  try {
    final handle = file.openSync();
    try {
      final length = handle.lengthSync();
      prefix = handle.readSync(
        length < maxPrefixBytes ? length : maxPrefixBytes,
      );
    } finally {
      handle.closeSync();
    }
  } on Object {
    return null;
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
