import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

import 'project_creation_contracts.dart';
import 'project_template_catalog.dart';

final class ProjectTemplateDownloader {
  const ProjectTemplateDownloader({this.read});
  final Future<List<int>> Function(Uri)? read;

  Future<List<int>> preview(ProjectTemplateDescriptor template) =>
      _verified(template.previewUri, template.previewSha256);

  Future<List<int>> download(ProjectTemplateDescriptor template,
          {bool Function()? isCancelled}) =>
      _verified(template.archiveUri, template.archiveSha256,
          isCancelled: isCancelled);

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
            'Le téléchargement est incomplet ou ne correspond pas au modèle attendu. Réessayez.');
      }
      return bytes;
    } on ProjectCreationCancelled {
      rethrow;
    } on ProjectCreationException {
      rethrow;
    } on Object {
      throw const ProjectCreationException('project.template_download',
          'Le modèle n’a pas pu être téléchargé. Vérifiez votre connexion puis réessayez. Aucun projet n’a été créé.');
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
