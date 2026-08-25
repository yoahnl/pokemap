import 'dart:typed_data';

/// La source d'aléa des packages de stress — BETA-AVL-005.
///
/// PAS `dart:math`. `Random(seed)` ne garantit pas la même suite d'une
/// version de Dart à l'autre : un package golden dont le sha256 est épinglé
/// se mettrait donc à divergter tout seul, un beau jour, sans que rien du
/// dépôt n'ait changé. Ce xorshift128+ est écrit ici pour que la graine soit
/// le SEUL paramètre du résultat, aujourd'hui comme dans trois ans.
final class AveluneStressEntropy {
  AveluneStressEntropy(int seed)
      : _state0 = _mix(seed == 0 ? 0x9E3779B97F4A7C15 : seed),
        _state1 = _mix(seed ^ 0x6A09E667F3BCC909);

  int _state0;
  int _state1;

  static int _mix(int value) {
    var x = value;
    x ^= (x >>> 30);
    x *= 0xBF58476D1CE4E5B9;
    x ^= (x >>> 27);
    x *= 0x94D049BB133111EB;
    x ^= (x >>> 31);
    return x == 0 ? 0x9E3779B97F4A7C15 : x;
  }

  int nextInt64() {
    var s1 = _state0;
    final s0 = _state1;
    _state0 = s0;
    s1 ^= s1 << 23;
    _state1 = s1 ^ s0 ^ (s1 >>> 18) ^ (s0 >>> 5);
    return _state1 + s0;
  }

  int nextByte() => nextInt64() & 0xFF;

  /// Un entier dans `[0, bound)`.
  int nextBelow(int bound) {
    if (bound <= 0) {
      throw ArgumentError.value(bound, 'bound', 'doit être positif');
    }
    return nextInt64().abs() % bound;
  }

  /// Des octets à ENTROPIE PLEINE.
  ///
  /// Le ticket prévient qu'« une fixture compressible ou trop homogène
  /// fausserait les conclusions de compression et d'I/O ». Un bloc de zéros
  /// se compresse à néant et ne mesure ni le débit disque, ni ce qu'une
  /// compression future rapporterait : ces octets-là ne se compressent pas.
  Uint8List nextBytes(int length) {
    final bytes = Uint8List(length);
    var index = 0;
    while (index + 8 <= length) {
      final value = nextInt64();
      bytes[index] = value & 0xFF;
      bytes[index + 1] = (value >>> 8) & 0xFF;
      bytes[index + 2] = (value >>> 16) & 0xFF;
      bytes[index + 3] = (value >>> 24) & 0xFF;
      bytes[index + 4] = (value >>> 32) & 0xFF;
      bytes[index + 5] = (value >>> 40) & 0xFF;
      bytes[index + 6] = (value >>> 48) & 0xFF;
      bytes[index + 7] = (value >>> 56) & 0xFF;
      index += 8;
    }
    while (index < length) {
      bytes[index++] = nextByte();
    }
    return bytes;
  }

  /// Un mot prononçable, pour que les identifiants et les dialogues générés
  /// ressemblent à de la donnée d'auteur plutôt qu'à du base64.
  String nextWord({int minLength = 4, int maxLength = 9}) {
    const consonants = 'bcdfgklmnprstvz';
    const vowels = 'aeiou';
    final length = minLength + nextBelow(maxLength - minLength + 1);
    final buffer = StringBuffer();
    for (var index = 0; index < length; index++) {
      buffer.write(
        index.isEven
            ? consonants[nextBelow(consonants.length)]
            : vowels[nextBelow(vowels.length)],
      );
    }
    return buffer.toString();
  }
}
