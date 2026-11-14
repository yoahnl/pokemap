import 'dart:io';

import 'narrative_usage_fixture.dart';

Future<void> main(List<String> arguments) async {
  final fixture =
      await createNarrativeUsageFixture(at: Directory(arguments.single));
  await fixture.close(delete: false);
}
