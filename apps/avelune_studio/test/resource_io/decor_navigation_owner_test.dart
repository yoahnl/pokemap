import 'dart:io';

import 'package:avelune_studio/features/decors/application/decor_draft.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/resource_owner_host.dart';
import '../support/resource_owner_seed.dart';

Future<Map<String, List<int>>> _files(Directory root) async => {
  for (final entity in root.listSync(recursive: true))
    if (entity is File) entity.path: await entity.readAsBytes(),
};

Future<ResourceOwnerHost> _open() => ResourceOwnerHost.create(
  configure: (fixture) => seedFreeDecor(fixture),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('retired decor workshop keeps its owner and published use', () async {
    final host = await _open();
    final item = decorItem(host.workspace.project!);
    final beforeFiles = await _files(host.fixture.root);
    final beforeProject = host.workspace.project!.toJson();
    final beforeMap = host.workspace.active!.current;
    expect(item.usableIn(host.workspace.project!), isTrue);

    host.navigation.edit(item);
    final draft = host.navigation.decor!..name = 'Préparation conservée';
    draft.beginCollisionPointer(5, 10, fine: true, solid: true);
    draft.endCollisionPointer();
    final prepared = draft.build();
    expect(host.navigation.dirty, isTrue);
    expect(draft.canUndoCollision, isTrue);
    host.navigation.showLibrary();
    expect(host.navigation.page, ResourcePage.library);
    expect(host.navigation.decor, same(draft));
    expect(host.navigation.decorDraftFor(item.id), same(draft));
    expect(draft.build(), prepared);
    expect(draft.canUndoCollision, isTrue);
    expect(item.usableIn(host.workspace.project!), isTrue);
    expect(host.workspace.project!.toJson(), beforeProject);
    expect(host.workspace.active!.current, beforeMap);
    expect(await _files(host.fixture.root), beforeFiles);
  });

  test('imported source remains available when its retired decor route is requested', () async {
    final host = await _open();
    final beforeMap = host.workspace.active!.current;
    final sourceBytes = await host.fixture.source.readAsBytes();
    await host.navigation.import(
      ResourceImageImport(
        sourcePath: host.fixture.source.path,
        name: 'Source à conserver',
        tileWidth: host.workspace.project!.settings.tileWidth,
        tileHeight: host.workspace.project!.settings.tileHeight,
      ),
      intent: ResourceImportIntent.source,
    );
    expect(host.navigation.error, isNull);
    expect(host.navigation.decor, isNull);
    final source = host.navigation.importedSource!;
    expect(source.tileset, isNotNull);
    final beforeFiles = await _files(host.fixture.root);
    final beforeProject = host.workspace.project!.toJson();

    host.navigation.showLibrary(source);
    host.navigation.edit(source);
    expect(host.navigation.importedSource, isNull);
    expect(host.navigation.error, isNull);
    final draft = host.navigation.decor!;
    expect(draft.tileset.id, source.id);
    expect(draft.original, isNull);
    host.navigation.showLibrary();
    expect(host.navigation.decor, same(draft));
    expect(host.navigation.decors.values, contains(same(draft)));
    expect(host.navigation.page, ResourcePage.library);
    expect(host.workspace.project!.toJson(), beforeProject);
    expect(host.workspace.active!.current, beforeMap);
    expect(await _files(host.fixture.root), beforeFiles);
    expect(await host.fixture.source.readAsBytes(), sourceBytes);
  });
}
