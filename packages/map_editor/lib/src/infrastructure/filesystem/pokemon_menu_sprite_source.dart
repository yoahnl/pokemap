import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as p;

final class PokemonMenuSpriteSource {
  PokemonMenuSpriteSource({
    required this.cacheRoot,
    required Map<String, dynamic> manifest,
    required this.client,
  }) : catalog = PokemonSpriteSourceCatalog.fromJson(
         manifest['species'] as Map<String, dynamic>,
       ),
       _assets = manifest['assets'] as Map<String, dynamic>,
       revision = manifest['revision'] as String {
    if (manifest['schemaVersion'] != 1 ||
        manifest['repository'] != 'https://github.com/smogon/sprites' ||
        !RegExp(r'^[a-f0-9]{40}$').hasMatch(revision)) {
      throw const FormatException('Catalogue de miniatures intégré invalide.');
    }
  }

  final String cacheRoot;
  final String revision;
  final PokemonSpriteSourceCatalog catalog;
  final http.Client client;
  final Map<String, dynamic> _assets;

  void verify(String relativePath, List<int> bytes) {
    final expected = _assets[relativePath] as Map<String, dynamic>?;
    if (expected == null ||
        bytes.length != expected['bytes'] ||
        sha256.convert(bytes).toString() != expected['sha256']) {
      throw const FormatException(
        'La miniature préparée a changé depuis sa vérification.',
      );
    }
  }

  Future<String?> resolve(String relativePath) async {
    final entry = _assets[relativePath] as Map<String, dynamic>?;
    if (entry == null) return null;
    if (!RegExp(
      r'^src/(minisprites/pokemon/home|previews/gen9)/s[0-9]+\.png$',
    ).hasMatch(relativePath)) {
      throw const FormatException(
        'Chemin du catalogue de miniatures invalide.',
      );
    }
    final expectedHash = entry['sha256'] as String;
    final expectedBytes = entry['bytes'] as int;
    if (expectedBytes <= 0 ||
        expectedBytes > 8 * 1024 * 1024 ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(expectedHash)) {
      throw const FormatException('Empreinte de miniature invalide.');
    }
    await Directory(cacheRoot).create(recursive: true);
    final root = await Directory(cacheRoot).resolveSymbolicLinks();
    final file = File(p.join(root, relativePath));
    var parent = root;
    for (final segment in p.split(p.dirname(relativePath))) {
      parent = p.join(parent, segment);
      final type = await FileSystemEntity.type(parent, followLinks: false);
      if (type == FileSystemEntityType.link ||
          (type != FileSystemEntityType.notFound &&
              type != FileSystemEntityType.directory)) {
        throw const FormatException('Dossier de cache non sûr.');
      }
      if (type == FileSystemEntityType.notFound) {
        await Directory(parent).create();
      }
    }
    if (!p.isWithin(root, await file.parent.resolveSymbolicLinks())) {
      throw const FormatException(
        'Le cache de miniatures sort de son dossier.',
      );
    }
    if (await FileSystemEntity.type(file.path, followLinks: false) ==
        FileSystemEntityType.link) {
      throw const FormatException('Lien symbolique interdit dans le cache.');
    }
    if (await file.exists() && await file.length() == expectedBytes) {
      final cached = await file.readAsBytes();
      if (sha256.convert(cached).toString() == expectedHash) return file.path;
    }
    final request = http.Request(
      'GET',
      Uri.https(
        'raw.githubusercontent.com',
        '/smogon/sprites/$revision/$relativePath',
      ),
    )..followRedirects = false;
    final response = await client
        .send(request)
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200 ||
        (response.contentLength != null &&
            response.contentLength != expectedBytes)) {
      throw const HttpException(
        'Impossible de récupérer une miniature vérifiée. Réessayez avec une connexion réseau.',
      );
    }
    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 25),
    )) {
      bytes.addAll(chunk);
      if (bytes.length > expectedBytes) {
        throw const FormatException('La miniature dépasse la taille attendue.');
      }
    }
    if (bytes.length != expectedBytes ||
        sha256.convert(bytes).toString() != expectedHash) {
      throw const FormatException(
        'La miniature reçue ne correspond pas au catalogue vérifié.',
      );
    }
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  static Map<String, dynamic> decodeManifest(String contents) =>
      jsonDecode(contents) as Map<String, dynamic>;
}
