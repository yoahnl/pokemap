import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/src/catalog_storage/catalog_generation_retention.dart';
import 'package:map_authoring/src/catalog_storage/catalog_storage_store.dart';

Future<void> main(List<String> arguments) async {
  final store = await CatalogStorageStore.open(projectRoot: arguments.single);
  final reader = await CatalogGenerationRetention(store: store).openSnapshot();
  stdout.writeln(jsonEncode({'leaseId': reader.lease.id, 'pid': pid}));
  await stdout.flush();
  await stdin.transform(utf8.decoder).transform(const LineSplitter()).first;
  exit(0);
}
