import 'dart:io';

import 'package:avelune_player_host/features/installation/data/repositories/installed_file_stamps.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('installed-file-stamps-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  File write(String relativePath, int length) =>
      File(p.join(root.path, relativePath))
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(List<int>.filled(length, 7));

  test('bulk stamps equal the stamps read one file at a time', () {
    final files = [
      for (var index = 0; index < 3000; index++)
        write('big/file_$index.bin', index % 17),
      write('café/éte.json', 12),
      write('a/b/c/deep.txt', 3),
      write('top.json', 0),
    ];
    final bulk = readInstalledFileStampsInBulk(files);
    expect(bulk, isNotNull);
    expect(bulk, statInstalledFileStamps(files));
  }, skip: Platform.isMacOS || Platform.isIOS ? false : 'Darwin only');

  test('missing files and directories read as absent', () {
    final present = write('here/present.bin', 5);
    final files = [
      present,
      File(p.join(root.path, 'here', 'missing.bin')),
      File(p.join(root.path, 'gone', 'missing.bin')),
      Directory(p.join(root.path, 'here', 'folder'))..createSync(),
    ].map((entity) => File(entity.path)).toList();
    final stamps = readInstalledFileStamps(files);
    expect(
      [
        for (var index = 0; index < files.length; index++)
          stamps[index * installedFileStampFields],
      ],
      [5, -1, -1, -1],
    );
    expect(stamps, statInstalledFileStamps(files));
  });

  test('a file rewritten in place changes its bulk stamp', () async {
    final file = write('dir/data.bin', 4);
    final before = readInstalledFileStamps([file]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    file.writeAsBytesSync([1, 2, 3, 4], flush: true);
    final after = readInstalledFileStamps([file]);
    expect(after[0], before[0]);
    expect(after.sublist(1), isNot(before.sublist(1)));
  });
}
