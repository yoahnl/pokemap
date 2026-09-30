import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'project_creation_contracts.dart';

final class ClairboisProjectTemplate {
  const ClairboisProjectTemplate({this.read});
  final Future<List<int>> Function(Uri)? read;

  static const revision = 'e3d3766ed80d34b6b451ad4d0cd5647d6373c230';
  static final archiveUri = Uri.parse(
      'https://codeload.github.com/yoahnl/avelune-template-clairbois/zip/$revision');
  static final previewUri = Uri.parse(
      'https://raw.githubusercontent.com/yoahnl/avelune-template-clairbois/$revision/preview/village.png');
  static const _archiveHash =
      'ba60603d627d91b2c41d8f502ae4d3818774e3f00c000b3610316dc767a4942f';
  static const _previewHash =
      'a14d950e16aeeb6857c6318390132fb2349f2b057976ae099c0f5c8c9c6c254b';

  Future<List<int>> preview() => _verified(previewUri, _previewHash);

  Future<List<int>> download({bool Function()? isCancelled}) =>
      _verified(archiveUri, _archiveHash, isCancelled: isCancelled);

  Future<List<int>> _verified(Uri uri, String hash,
      {bool Function()? isCancelled}) async {
    if (isCancelled?.call() ?? false) throw const ProjectCreationCancelled();
    try {
      final bytes =
          await (read == null ? _download(uri, isCancelled) : read!(uri));
      if (isCancelled?.call() ?? false) throw const ProjectCreationCancelled();
      if (bytes.length > 16 * 1024 * 1024 ||
          sha256.convert(bytes).toString() != hash) {
        throw const ProjectCreationException('project.template_integrity',
            'Le téléchargement de Clairbois est incomplet ou ne correspond pas au modèle attendu. Réessayez.');
      }
      return bytes;
    } on ProjectCreationCancelled {
      rethrow;
    } on ProjectCreationException {
      rethrow;
    } on Object {
      throw const ProjectCreationException('project.template_download',
          'Clairbois n’a pas pu être téléchargé depuis GitHub. Vérifiez votre connexion puis réessayez. Aucun projet n’a été créé.');
    }
  }
}

Future<List<int>> _download(Uri uri, bool Function()? isCancelled) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    return await (() async {
      final request = await client.getUrl(uri);
      request.followRedirects = false;
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok ||
          response.contentLength > 16 * 1024 * 1024) {
        throw const FormatException('Template response refused');
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        if (isCancelled?.call() ?? false) {
          throw const ProjectCreationCancelled();
        }
        if (bytes.length + chunk.length > 16 * 1024 * 1024) {
          throw const FormatException('Template download too large');
        }
        bytes.addAll(chunk);
      }
      return bytes;
    })()
        .timeout(const Duration(seconds: 45));
  } finally {
    client.close(force: true);
  }
}
