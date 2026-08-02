import 'dart:io';

import 'package:map_battle/src/data/psdk_source_locator.dart';
import 'package:test/test.dart';

void main() {
  test('finds PSDK corpora grouped in a repository sibling', () async {
    final temp = await Directory.systemTemp.createTemp('psdk_locator_');
    addTearDown(() => temp.delete(recursive: true));
    final repository = Directory('${temp.path}/pokemonProject')..createSync();
    final container = Directory('${temp.path}/pokemonProject other folders');
    final moves = Directory(
      '${container.path}/pokémon_sdk_test_project/Data/Studio/moves',
    )..createSync(recursive: true);
    final battle = Directory(
      '${container.path}/pokemonsdk-development/scripts/5 Battle',
    )..createSync(recursive: true);

    final sources = resolvePsdkSourceDirectories(
      repositoryRoot: repository,
    );

    expect(sources.containerDirectory.absolute.path, container.absolute.path);
    expect(sources.movesDirectory.absolute.path, moves.absolute.path);
    expect(sources.psdkBattleDirectory.absolute.path, battle.absolute.path);
  });
}
