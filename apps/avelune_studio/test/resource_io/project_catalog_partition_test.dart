import 'dart:convert';

import 'package:avelune_studio/features/project_session/data/local_project_catalog_partition_adapter.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';

import 'resource_fixture.dart';

void main() {
  test('explicit partition preserves map bytes and reopens in the paged catalogue session', () async {
    final fixture = await ResourceFixture.create();
    addTearDown(fixture.dispose);
    final beforeMap = await fixture.mapFile.readAsBytes();
    await LocalProjectCatalogPartitionAdapter().partition(fixture.session);
    expect(
      (jsonDecode(await fixture.manifestFile.readAsString()) as Map)['format'],
      'avelune.working-catalog',
    );
    expect(await fixture.mapFile.readAsBytes(), beforeMap);
    final sessions = LocalProjectSessionAdapter();
    final reopened = await sessions.open(fixture.root.path);
    expect(reopened.storage, ProjectSessionStorage.workingCatalog);
    expect(reopened.name, fixture.session.name);
    await sessions.close(reopened);
  });
}
