import 'dart:io';

import 'narrative_title_fixture.dart';
import 'storyline_trame_fixture.dart';

Future<void> main(List<String> arguments) async {
  final fixture = await NarrativeTitleFixture.create(
      at: Directory(arguments.single), project: storylineOutlineProject(0));
  await fixture.close(delete: false);
}
