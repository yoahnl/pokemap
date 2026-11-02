import 'dart:convert';
import 'dart:typed_data';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'game_package_format_exception.dart';
import 'game_package_manifest.dart';
import 'game_package_security_policy.dart';
import 'package_path_policy.dart';
import 'pokemon_gif_inspector.dart';

final class GamePackagePokemonMediaValidator {
  const GamePackagePokemonMediaValidator(this.policy);

  final GamePackageSecurityPolicy policy;

  void validate({
    required ProjectManifest project,
    required Map<String, GamePackageFileEntry> inventory,
    required List<int>? Function(String path) readPayload,
  }) {
    final mediaDirectory = project.pokemon.mediaDir.trim();
    final normalizedDirectory = mediaDirectory.isEmpty
        ? '.'
        : p.posix.normalize(mediaDirectory.replaceAll(r'\', '/'));
    final prefix = normalizedDirectory == '.'
        ? 'project/'
        : PackagePathPolicy.normalizeNfc('project/$normalizedDirectory/');
    final documents = inventory.values
        .where((entry) =>
            entry.path.startsWith(prefix) &&
            !entry.path.substring(prefix.length).contains('/') &&
            p.extension(entry.path).toLowerCase() == '.json')
        .toList()
      ..sort((a, b) => PackagePathPolicy.compareUtf8(a.path, b.path));
    final verified = <String>{};
    for (final document in documents) {
      if (document.size > policy.maxJsonBytes) {
        _fail('pokemonAnimatedMediaInvalid', document.path,
            'Pokemon media metadata exceeds its size limit.');
      }
      final bytes = readPayload(document.path);
      if (bytes == null) {
        _fail('pokemonAnimatedMediaMissing', document.path,
            'Pokemon media metadata is missing.');
      }
      final raw = jsonDecode(utf8.decode(bytes, allowMalformed: false));
      if (raw is! Map ||
          raw['schemaVersion'] != currentPokemonMediaSchemaVersion ||
          raw['speciesId'] is! String ||
          raw['variants'] is! Map) {
        continue;
      }
      if (mediaDirectory != PackagePathPolicy.normalizeNfc(mediaDirectory)) {
        _fail('pokemonAnimatedPathNotNormalized', document.path,
            'Pokemon media directories must use NFC Unicode normalization.');
      }
      late final PokemonMediaFile media;
      try {
        media = PokemonMediaFile.fromJson(Map<String, dynamic>.from(raw));
        if (media.speciesId.isEmpty || raw['variants'] is! Map) {
          throw const FormatException('Invalid Pokemon media document.');
        }
      } on Object {
        _fail('pokemonAnimatedMediaInvalid', document.path,
            'Pokemon media metadata is invalid.');
      }
      for (final variant in media.variants.values) {
        for (final source in [
          variant.frontAnimated,
          variant.backAnimated,
          variant.frontShinyAnimated,
          variant.backShinyAnimated,
          variant.frontFemaleAnimated,
          variant.backFemaleAnimated,
          variant.frontShinyFemaleAnimated,
          variant.backShinyFemaleAnimated,
        ]) {
          if (source == null) continue;
          if (source.startsWith('/') ||
              source.startsWith('\\') ||
              source.split(RegExp(r'[/\\]')).contains('..') ||
              Uri.tryParse(source)?.hasScheme == true ||
              source.contains('\u0000')) {
            _fail('referenceEscapesRoot', document.path,
                'Project reference escapes the installed package.');
          }
          if (source != PackagePathPolicy.normalizeNfc(source)) {
            _fail('pokemonAnimatedPathNotNormalized', document.path,
                'Animated Pokemon media paths must use NFC Unicode normalization.');
          }
          final path = PackagePathPolicy.normalizeNfc('project/$source');
          PackagePathPolicy.validate(path, errorPath: document.path);
          if (!verified.add(path)) continue;
          final blob = RegExp(r'^project/assets/\.pokemap-store/([0-9a-f]{64})\.blob$')
              .firstMatch(path);
          if (blob == null && p.extension(path).toLowerCase() != '.gif') {
            _fail('pokemonAnimatedMediaInvalid', path,
                'Animated Pokemon media must reference a GIF or canonical blob.');
          }
          final entry = inventory[path];
          if (entry == null) {
            _fail('pokemonAnimatedMediaMissing', path,
                'Animated Pokemon media is missing from the package.');
          }
          if (entry.size > PokemonGifInspector.maxEncodedBytes) {
            _fail('pokemonAnimatedMediaInvalid', path,
                'Animated Pokemon media exceeds its GIF size limit.');
          }
          final content = readPayload(path);
          if (content == null || content.length != entry.size) {
            _fail('pokemonAnimatedMediaMissing', path,
                'Animated Pokemon media is missing from the package.');
          }
          if (blob != null) {
            final digest = (NarrativeProjectFingerprintBuilder()
                  ..startEntry(relativePath: 'artifact-content', byteLength: content.length)
                  ..addBytes(content)
                  ..endEntry())
                .close();
            if (digest != 'sha256:${blob.group(1)}') {
              _fail('pokemonAnimatedBlobDigestMismatch', path,
                  'Animated Pokemon media does not match its canonical blob identity.');
            }
          }
          try {
            final info = PokemonGifInspector(
              maxCanvasPixels: policy.maxImagePixels < 16777216
                  ? policy.maxImagePixels
                  : 16777216,
            ).inspect(content is Uint8List ? content : Uint8List.fromList(content));
            if (info.width > policy.maxImageDimension ||
                info.height > policy.maxImageDimension) {
              throw const FormatException('GIF dimensions exceed policy.');
            }
          } on FormatException {
            _fail('pokemonAnimatedMediaInvalid', path,
                'Animated Pokemon media is not a supported GIF.');
          }
        }
      }
    }
  }

  Never _fail(String code, String path, String message) =>
      throw GamePackageFormatException(code: code, path: path, message: message);
}
