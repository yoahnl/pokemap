import 'dart:io';

import 'narrative_title_fixture.dart';

Future<void> main(List<String> arguments) async {
  final fixture = await NarrativeTitleFixture.create(
      facts: 130, at: Directory(arguments.single));
  await fixture.close(delete: false);
}
