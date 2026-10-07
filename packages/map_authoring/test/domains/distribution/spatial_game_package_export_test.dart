import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('spatial-export-');
    final source = Directory(p.normalize(
        p.join(Directory.current.path, '..', '..', 'apps', 'hgss_first_map')));
    await for (final file in source.list(recursive: true, followLinks: false)) {
      final path = p.relative(file.path, from: source.path);
      if (file is! File || path.startsWith('.pokemap${p.separator}')) continue;
      final target = File(p.join(root.path, path));
      await target.parent.create(recursive: true);
      await file.copy(target.path);
    }
  });
  tearDown(() async => root.delete(recursive: true));

  test('exports the authored 3D map as autonomous localTest exploration',
      () async {
    final artifact = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: _profile(),
        mode: GamePackageExportMode.localTest);
    expect(artifact.manifest.compatibility.requiredCapabilities,
        contains('map3d@1'));
    expect(artifact.manifest.compatibility.requiredCapabilities,
        isNot(contains('map@1')));
    expect(artifact.manifest.compatibility.projectFormat, 'v9');
    final archive = ZipDecoder().decodeBytes(artifact.packageBytes);
    final project = jsonDecode(
        utf8.decode(archive.findFile('project/project.json')!.content));
    expect(project['newGame']['enabled'], false);
    expect(project['eventRegistry'], isNull);
    expect(project['dialogues'], isNotEmpty);
    for (final dialogue in project['dialogues']) {
      final compiled = archive.findFile('project/${dialogue['relativePath']}');
      expect(compiled, isNotNull);
      final document =
          const RuntimeDialogueDocumentCodec().decodeUtf8(compiled!.content);
      expect(
          document.nodes
              .expand((n) => n.steps)
              .every((step) => step is RuntimeDialogueLine),
          isTrue);
    }
    for (final model in project['models3d']) {
      expect(archive.findFile('project/${model['relativePath']}'), isNotNull);
    }
    expect(archive.findFile('project/assets/provenance/hgss.json'), isNull);
    await root.delete(recursive: true);
    root = await Directory.systemTemp.createTemp('spatial-export-clean-');
    final package = File(p.join(root.path, 'exploration.avelunegame'))
      ..writeAsBytesSync(artifact.packageBytes);
    final source = _FileSource(package.openSync());
    try {
      expect(
          const GamePackageInspector()
              .inspectSourceSync(source)
              .manifest
              .content
              .treeSha256,
          artifact.manifest.content.treeSha256);
    } finally {
      source.file.closeSync();
    }
    expect(artifact.certification.isCertified, false);
  });
  test('rejects 3D publication explicitly', () async {
    await expectLater(
        const CanonicalGamePackageExportService()
            .build(projectRoot: root, profile: _profile()),
        throwsA(isA<GamePackageExportException>().having(
            (e) => e.code, 'code', 'runtime3d.publication_unsupported')));
  });
}

GamePackageExportProfile _profile() => GamePackageExportProfile(
    gameId: 'games.example.spatial',
    gameVersion: '0.1.0',
    title: 'La halte des falaises',
    authorName: 'Yoahn',
    defaultLocale: 'fr',
    supportedLocales: ['fr']);

final class _FileSource implements RandomAccessPackageSource {
  _FileSource(this.file);
  final RandomAccessFile file;
  @override
  int get length => file.lengthSync();
  @override
  Uint8List readAtSync(int offset, int length) {
    file.setPositionSync(offset);
    return file.readSync(length);
  }
}
