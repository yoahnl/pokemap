import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:path/path.dart' as p;

String get _studioRoot => p.basename(Directory.current.path) == 'avelune_studio'
    ? Directory.current.path
    : p.join(Directory.current.path, '../avelune_studio');

final fixtureTemplateCatalog = ProjectTemplateCatalog.fromJson(
  jsonDecode(
    File(
      p.join(
        _studioRoot,
        '../../packages/map_authoring/assets/project_templates.v1.json',
      ),
    ).readAsStringSync(),
  ),
);
ProjectTemplateDescriptor get clairboisDescriptor =>
    fixtureTemplateCatalog.require('clairbois');
final offlineProjectCreation = LocalProjectCreationService(
  templateCatalog: fixtureTemplateCatalog,
  readTemplate: readClairboisFixture,
);

Future<List<int>> readClairboisFixture(Uri uri) async {
  final studio = p.basename(Directory.current.path) == 'avelune_studio'
      ? Directory.current.path
      : p.join(Directory.current.path, '../avelune_studio');
  final bytes = await File(
    p.join(
      studio,
      '../../packages/map_authoring/test/fixtures/project_creation/clairbois-e3d3766.zip',
    ),
  ).readAsBytes();
  if (uri == clairboisDescriptor.archiveUri) return bytes;
  if (uri == clairboisDescriptor.previewUri) {
    return ZipDecoder()
        .decodeBytes(bytes)
        .files
        .singleWhere((file) => file.name.endsWith('/preview/village.png'))
        .content;
  }
  throw StateError('Unexpected template URL: $uri');
}
