import 'dart:io';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:path/path.dart' as p;

const offlineClairbois = ClairboisProjectTemplate(read: readClairboisFixture);

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
  if (uri == ClairboisProjectTemplate.archiveUri) return bytes;
  if (uri == ClairboisProjectTemplate.previewUri) {
    return ZipDecoder()
        .decodeBytes(bytes)
        .files
        .singleWhere((file) => file.name.endsWith('/preview/village.png'))
        .content;
  }
  throw StateError('Unexpected template URL: $uri');
}
