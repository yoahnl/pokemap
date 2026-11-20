import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/resources/domain/project_library_editor.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/platform/files/native_resource_image_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart';
import '../../tool/example_project_assets.dart';
import 'working_catalog_classification_fixture.dart';

void main() {
  test('an import rejects PNG or GLB replaced after selection', () async {
    final fixture = await ClassificationFixture.create();
    addTearDown(fixture.dispose);
    await fixture.openWorkspace();
    const picker = NativeResourceImagePicker();
    final png = File('${fixture.root.path}/source.png');
    final glb = File('${fixture.root.path}/source.glb');
    await png.writeAsBytes(image.encodePng(image.Image(width: 16, height: 16)));
    await glb.writeAsBytes(triangleGlb());
    final pickedImage = await picker.inspectLibraryFile(png.path);
    final pickedModel = await picker.inspectLibraryFile(glb.path);
    final library = await fixture.maps.readResourceLibrary(fixture.session);
    final head = File('${fixture.root.path}/catalog/HEAD.json');
    final before = await head.readAsBytes();
    Future<Set<String>> assets() =>
        Directory('${fixture.root.path}/assets')
            .list(recursive: true)
            .map((entry) => entry.path)
            .toSet();
    final assetsBefore = await assets();

    await png.writeAsBytes(image.encodePng(image.Image(width: 32, height: 32)));
    await glb.writeAsBytes(
      triangleGlb(
        edit: (json) {
          json['nodes'][0]['translation'][0] = 11;
        },
      ),
    );
    expect(await glb.length(), pickedModel.artifact.byteLength);

    for (final picked in [pickedImage, pickedModel]) {
      await expectLater(
        fixture.resources.importResource(
          picked,
          name: picked.name,
          tileSize: picked.imageSize,
          expectedRevision: library.revision!,
        ),
        throwsA(
          isA<ResourceFailure>().having(
            (failure) => failure.message,
            'message',
            contains('a changé'),
          ),
        ),
      );
    }
    expect(await head.readAsBytes(), before);
    expect(await assets(), assetsBefore);
    expect(fixture.phases, isNot(contains('attach.start')));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test(
    'catalogue edits publish selected resources and survive reopening',
    () async {
      final costs = <int, List<({int objects, int writes})>>{};
      for (final unrelated in [0, 300]) {
        final fixture = await ClassificationFixture.create(
          unrelated: unrelated,
        );
        try {
          costs[unrelated] = await _editAndReopen(fixture, unrelated);
        } finally {
          await fixture.dispose();
        }
      }
      for (final (index, cost) in costs[300]!.indexed) {
        expect(cost.writes, lessThanOrEqualTo(costs[0]![index].writes + 3));
        expect(cost.objects, lessThanOrEqualTo(costs[0]![index].objects + 20));
      }
    },
  );
}

Future<List<({int objects, int writes})>> _editAndReopen(
  ClassificationFixture fixture,
  int unrelated,
) async {
  await fixture.openWorkspace();
  final session = fixture.session;
  final draft = fixture.workspace.active!;
  draft.commit(draft.current.copyWith(name: 'Brouillon en cours'));
  final map = File('${fixture.root.path}/maps/jardin.json');
  final mapBefore = await map.readAsBytes();
  final png = File('${fixture.root.path}/import.png');
  final glb = File('${fixture.root.path}/import.glb');
  await png.writeAsBytes(exampleAtlasPng());
  await glb.writeAsBytes(triangleGlb());
  final initial = await fixture.maps.readResourceLibrary(session);
  var revision = initial.revision!;
  final costs = <({int objects, int writes})>[];
  final outside = Zone.current;

  Future<ProjectLibraryEdit> edit(
    Future<ProjectLibraryEdit> Function() apply,
  ) async {
    final files = <String>{};
    final result = await IOOverrides.runZoned(
      apply,
      createFile: (path) {
        files.add(path);
        return outside.run(() => File(path));
      },
    );
    expect(files.where((path) => path.contains('/maps/')), isEmpty);
    expect(
      files.where((path) => path.endsWith('/assets/atelier.png')),
      isEmpty,
    );
    expect(result.receipt.beforeRevision, revision);
    expect(result.receipt.revision, isNot(revision));
    expect(result.receipt.changedPaths, contains('catalog/HEAD.json'));
    expect(
      result.receipt.changedPaths.where((path) => path.startsWith('maps/')),
      isEmpty,
    );
    costs.add((
      objects: files.where((path) => path.contains('/catalog/objects/')).length,
      writes: result.receipt.changedPaths.length,
    ));
    if (result.receipt.before != result.receipt.manifest) {
      fixture.accept(result.receipt);
    }
    revision = result.receipt.revision;
    return result;
  }

  const picker = NativeResourceImagePicker();
  final pickedImage = await picker.inspectLibraryFile(png.path);
  final pickedModel = await picker.inspectLibraryFile(glb.path);
  expect(pickedImage.imageSize, (width: 160, height: 64));
  expect(pickedModel.modelInspection?.meshCount, 1);
  expect(await fixture.maps.resourceRevision(session), revision);
  final image = await edit(
    () => fixture.resources.importResource(
      pickedImage,
      name: 'Planche d’essai',
      tileSize: (width: 16, height: 16),
      expectedRevision: revision,
    ),
  );
  expect(image.item.kind, 'tileset');
  final model = await edit(
    () => fixture.resources.importResource(
      pickedModel,
      name: 'Triangle',
      tileSize: null,
      expectedRevision: revision,
    ),
  );
  expect(model.item.kind, 'model3d');
  final renamed = await edit(
    () => fixture.resources.renameResource(
      model.item,
      name: '  Fontaine du jardin  ',
      expectedRevision: revision,
    ),
  );
  expect(renamed.item.id, model.item.id);
  expect(renamed.item.name, 'Fontaine du jardin');
  await expectLater(
    fixture.resources.renameResource(
      model.item,
      name: 'Ancienne révision',
      expectedRevision: initial.revision!,
    ),
    throwsA(isA<ResourceFailure>()),
  );
  final filed = await edit(
    () => fixture.resources.classifyResource(
      renamed.item,
      familyId: 'props',
      role: ResourceLibraryRole.component,
      expectedRevision: revision,
    ),
  );
  expect(filed.item.familyId, 'props');
  expect(filed.item.role, ResourceLibraryRole.component);
  expect(fixture.workspace.active, same(draft));
  expect(draft.current.name, 'Brouillon en cours');
  expect(await map.readAsBytes(), mapBefore);

  await fixture.reopen();
  final library = await fixture.maps.readResourceLibrary(fixture.session);
  expect(library.revision, revision);
  expect(library.items.length, initial.items.length + 2);
  final item = library.items.singleWhere(
    (item) => item.identity == filed.item.identity,
  );
  expect(item.name, 'Fontaine du jardin');
  expect(item.familyId, 'props');
  expect(item.role, ResourceLibraryRole.component);
  expect(await fixture.resources.readModel(model.item.id), triangleGlb());
  final preview = await fixture.maps.readResourcePreview(
    fixture.session,
    image.item.kind,
    image.item.id,
  );
  expect(preview.tilesets.single.name, 'Planche d’essai');
  final source =
      preview.tilesets.single.source as ProjectRegularAtlasTilesetSource;
  expect((source.pixelWidth, source.pixelHeight), (160, 64));
  expect((source.tileWidth, source.tileHeight), (16, 16));
  if (unrelated > 0) {
    final untouched = library.items.singleWhere(
      (item) => item.id == 'decor_0299',
    );
    expect(untouched.name, 'Décor 299');
    expect(untouched.familyId, 'buildings');
  }
  return costs;
}
