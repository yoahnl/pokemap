import 'dart:convert';
import 'dart:io';

import 'reliability_map_fixture.dart';

Future<void> main(List<String> arguments) async {
  if (arguments.length < 2 || arguments.length > 3) {
    throw ArgumentError('Provide a reliability variant and storage kind.');
  }
  final fixture = await ReliabilityMapFixture.create(
      variant: ReliabilityMapVariant.values.byName(arguments[0]),
      storage: ReliabilityStorage.values.byName(arguments[1]),
      qaRoot: arguments.length == 3 ? arguments[2] : '/Users/karim/Library/Caches/AveluneQA/mcp-map-reliability/r3');
  try {
    await fixture.api.prepareWorkshopCatalog(fixture.opened.projectHandle);
    await fixture.api.detachWorkspace(fixture.opened.workspaceHandle);
    fixture.handles.closeWorkspace(fixture.opened.workspaceHandle);
    stdout.writeln(jsonEncode({
      'root': fixture.root.path,
      'mapId': fixture.content.map.id,
      'mapPath': fixture.mapFile.path,
      'storage': fixture.storage.name,
    }));
  } catch (_) {
    await fixture.dispose();
    rethrow;
  }
}
