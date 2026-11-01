import 'package:map_core/map_core.dart';

final class PokemonMediaPreimage {
  PokemonMediaPreimage({
    required this.relativePath,
    required List<int>? bytes,
    required this.media,
  }) : bytes = bytes == null ? null : List<int>.unmodifiable(bytes) {
    if ((this.bytes == null) != (media == null)) {
      throw ArgumentError('Media and its preimage must both be present or absent.');
    }
  }

  final String relativePath;
  final List<int>? bytes;
  final PokemonMediaFile? media;
}
