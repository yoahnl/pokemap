import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_resource_owner_bindings.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/coordination/model_resource_workflow.dart'
    as models;
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/model_source_picker.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../packages/map_authoring/test/support/glb_fixture.dart';
import '../support/resource_replacement_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'a replacement publishes the native model receipt and preserves its map',
    () async {
      final (host, source, id) = await _model();
      final map = await host.fixture.mapFile.readAsBytes();
      await source.writeAsBytes(animatedGlb());
      var replacements = 0;
      final result = await _bindings(host.workspace).replaceCatalogModelSource(
        host.navigation,
        id,
        replace: (navigation, modelId) {
          replacements++;
          return models.replaceStudioModelSource(
            navigation,
            modelId,
            picker: () async => PickedModelSource(source.path, 'Actualisée'),
          );
        },
      );
      expect(result, isTrue);
      expect(replacements, 1);
      expect(host.navigation.pendingReceipt, isNull);
      expect(host.workspace.project!.models3d.single.id, id);
      expect(
        host
            .workspace
            .project!
            .models3d
            .single
            .inspection
            .animations
            .single
            .name,
        'Wind',
      );
      expect((await host.reopen()).models3d.single.id, id);
      expect(await host.fixture.mapFile.readAsBytes(), map);
    },
  );

  for (final sameInspection in [false, true]) {
    test(
      'retry reconciles a published manifest model receipt without repeating the picker or mutation, same inspection=$sameInspection',
      () async {
        var failReconciliation = false;
        final (host, source, id) = await _model(
          beforeReconciliation: () async {
            if (failReconciliation) throw StateError('Relecture indisponible');
          },
        );
        final bindings = _bindings(host.workspace);
        final map = await host.fixture.mapFile.readAsBytes();
        final original = host.workspace.project!.models3d.single;
        final replacement = sameInspection
            ? triangleGlb(
                edit: (json) => json['asset']['generator'] = 'replacement',
              )
            : animatedGlb();
        await source.writeAsBytes(replacement);
        var replacements = 0;
        Future<ResourceMutationReceipt?> replace(
          ResourceNavigation navigation,
          String modelId,
        ) {
          replacements++;
          return models.replaceStudioModelSource(
            navigation,
            modelId,
            picker: () async => PickedModelSource(source.path, 'Actualisée'),
          );
        }

        failReconciliation = true;
        await expectLater(
          bindings.replaceCatalogModelSource(
            host.navigation,
            id,
            replace: replace,
          ),
          throwsA(
            isA<ResourceFailure>().having(
              (error) => error.partialReceipt,
              'receipt',
              isNotNull,
            ),
          ),
        );
        final published = host.navigation.pendingReceipt!;
        expect(published.changedModels, isEmpty);
        expect(published.actionId, 'model3d.source.replace');
        expect(published.changedPaths, contains(original.relativePath));
        expect(published.pathRevisions[original.relativePath], isNotNull);
        expect(
          published.resourceRevisions['asset:${original.sourceAssetId}'],
          isNotNull,
        );
        final project = await host.fixture.manifestFile.readAsBytes();
        final persisted = (await host.reopen()).models3d.single;
        if (sameInspection) {
          expect(persisted, original);
        } else {
          expect(persisted.inspection.animations.single.name, 'Wind');
        }
        expect(
          await File('${host.fixture.root.path}/${original.relativePath}')
              .readAsBytes(),
          replacement,
        );
        failReconciliation = false;
        expect(
          await bindings.replaceCatalogModelSource(
            host.navigation,
            id,
            replace: replace,
          ),
          isTrue,
        );
        expect(replacements, 1);
        expect(host.navigation.pendingReceipt, isNull);
        expect(await host.fixture.manifestFile.readAsBytes(), project);
        expect(await host.fixture.mapFile.readAsBytes(), map);
      },
    );
  }

  test('a manifest model retry refuses a tampered published source without replaying or rewriting files', () async {
    var failReconciliation = false;
    final (host, source, id) = await _model(
      beforeReconciliation: () async {
        if (failReconciliation) throw StateError('Relecture indisponible');
      },
    );
    expect(host.fixture.session.storage, ProjectSessionStorage.manifest);
    final bindings = _bindings(host.workspace);
    final original = host.workspace.project!.models3d.single;
    final replacement = animatedGlb();
    await source.writeAsBytes(replacement);
    var replacements = 0;
    Future<ResourceMutationReceipt?> replace(
      ResourceNavigation navigation,
      String modelId,
    ) {
      replacements++;
      return models.replaceStudioModelSource(
        navigation,
        modelId,
        picker: () async => PickedModelSource(source.path, 'Actualisée'),
      );
    }

    failReconciliation = true;
    await expectLater(
      bindings.replaceCatalogModelSource(host.navigation, id, replace: replace),
      throwsA(
        isA<ResourceFailure>().having(
          (error) => error.partialReceipt,
          'receipt',
          isNotNull,
        ),
      ),
    );
    final receipt = host.navigation.pendingReceipt!;
    expect(receipt.changedModels, isEmpty);
    expect(receipt.actionId, 'model3d.source.replace');
    expect(receipt.changedPaths, contains(original.relativePath));
    expect(receipt.pathRevisions[original.relativePath], isNotNull);
    final publishedSource = File(
      '${host.fixture.root.path}/${original.relativePath}',
    );
    expect(await publishedSource.readAsBytes(), replacement);
    await publishedSource.writeAsBytes(triangleGlb());
    final beforeRetry = await host.files();
    final currentProject = host.workspace.project;
    failReconciliation = false;
    await expectLater(
      bindings.replaceCatalogModelSource(host.navigation, id, replace: replace),
      throwsA(
        isA<ResourceFailure>().having(
          (error) => error.partialReceipt,
          'receipt',
          same(receipt),
        ),
      ),
    );
    expect(replacements, 1);
    expect(host.navigation.pendingReceipt, same(receipt));
    expect(host.navigation.error, isNotEmpty);
    expect(host.workspace.project, same(currentProject));
    expect(await host.files(), beforeRetry);
  });

  test('a published receipt refuses a same-name model backed by the same original bytes', () async {
    var failReconciliation = false;
    final (host, source, id) = await _model(
      beforeReconciliation: () async {
        if (failReconciliation) throw StateError('Relecture indisponible');
      },
    );
    await models.importStudioModel(
      host.navigation,
      picker: () async => PickedModelSource(source.path, 'Fontaine'),
    );
    expect(host.navigation.error, isNull);
    final original = host.workspace.project!.models3d.singleWhere(
      (model) => model.id == id,
    );
    final other = host.workspace.project!.models3d.singleWhere(
      (model) => model.id != id,
    );
    expect(original.name, other.name);
    expect(original.relativePath, isNot(other.relativePath));
    expect(
      await File('${host.fixture.root.path}/${original.relativePath}')
          .readAsBytes(),
      await File('${host.fixture.root.path}/${other.relativePath}')
          .readAsBytes(),
    );
    failReconciliation = true;
    await source.writeAsBytes(animatedGlb());
    expect(
      await models.replaceStudioModelSource(
        host.navigation,
        id,
        picker: () async => PickedModelSource(source.path, 'Actualisée'),
      ),
      isNull,
    );
    final receipt = host.navigation.pendingReceipt!;
    failReconciliation = false;
    final before = await host.files();
    var replacements = 0;
    await expectLater(
      _bindings(host.workspace).replaceCatalogModelSource(
        host.navigation,
        other.id,
        replace: (_, _) async {
          replacements++;
          return null;
        },
      ),
      throwsA(isA<ResourceFailure>()),
    );
    expect(replacements, 0);
    expect(host.navigation.pendingReceipt, same(receipt));
    expect(await host.files(), before);
  });

  test('a pending receipt for another model is preserved and blocks the replacement', () async {
    final (host, source, id) = await _model();
    await source.writeAsBytes(animatedGlb());
    final receipt = await models.replaceStudioModelSource(
      host.navigation,
      id,
      picker: () async => PickedModelSource(source.path, 'Actualisée'),
    );
    host.navigation.pendingReceipt = receipt;
    final before = await host.fixture.manifestFile.readAsBytes();
    var replacements = 0;
    await expectLater(
      _bindings(host.workspace).replaceCatalogModelSource(
        host.navigation,
        'another-model',
        replace: (_, _) async {
          replacements++;
          return null;
        },
      ),
      throwsA(
        isA<ResourceFailure>().having(
          (error) => error.message,
          'message',
          contains('ressource précédente'),
        ),
      ),
    );
    expect(replacements, 0);
    expect(host.navigation.pendingReceipt, same(receipt));
    expect(await host.fixture.manifestFile.readAsBytes(), before);
  });

  test(
    'a cancelled native picker returns false without altering project files',
    () async {
      final (host, _, id) = await _model();
      final before = await host.fixture.manifestFile.readAsBytes();
      expect(
        await _bindings(host.workspace).replaceCatalogModelSource(
          host.navigation,
          id,
          replace: (navigation, modelId) => models.replaceStudioModelSource(
            navigation,
            modelId,
            picker: () async => null,
          ),
        ),
        isFalse,
      );
      expect(host.navigation.error, isNull);
      expect(host.navigation.pendingReceipt, isNull);
      expect(await host.fixture.manifestFile.readAsBytes(), before);
    },
  );

  test(
    'unavailable and busy owners refuse before invoking a replacement',
    () async {
      final (host, _, id) = await _model();
      final bindings = _bindings(host.workspace);
      var replacements = 0;
      Future<ResourceMutationReceipt?> replace(
        ResourceNavigation navigation,
        String modelId,
      ) async {
        replacements++;
        return null;
      }

      await expectLater(
        bindings.replaceCatalogModelSource(null, id, replace: replace),
        throwsA(isA<ResourceFailure>()),
      );
      host.navigation.busy = true;
      await expectLater(
        bindings.replaceCatalogModelSource(
          host.navigation,
          id,
          replace: replace,
        ),
        throwsA(isA<ResourceFailure>()),
      );
      host.navigation.busy = false;
      expect(replacements, 0);
    },
  );

  test('a model read failure propagates the source error while preserving project data', () async {
    final (host, source, id) = await _model();
    final before = await host.fixture.manifestFile.readAsBytes();
    await source.writeAsBytes(const [1, 2, 3]);
    await expectLater(
      _bindings(host.workspace).replaceCatalogModelSource(
        host.navigation,
        id,
        replace: (navigation, modelId) => models.replaceStudioModelSource(
          navigation,
          modelId,
          picker: () async => PickedModelSource(source.path, 'Invalide'),
        ),
      ),
      throwsA(
        isA<ResourceFailure>().having(
          (error) => error.message,
          'message',
          isNotEmpty,
        ),
      ),
    );
    expect(host.navigation.error, isNotNull);
    expect(host.navigation.pendingReceipt, isNull);
    expect(await host.fixture.manifestFile.readAsBytes(), before);
  });

  test(
    'a late result stays bound to its initial resource owner after rebinding',
    () async {
      final (host, _, id) = await _model();
      final newer = await ResourceReplacementFixture.create();
      var current = host.navigation;
      final gate = Completer<ResourceMutationReceipt?>();
      ResourceNavigation? received;
      final replacing = _bindings(host.workspace).replaceCatalogModelSource(
        current,
        id,
        replace: (navigation, _) {
          received = navigation;
          return gate.future;
        },
      );
      current = newer.navigation;
      final before = await newer.fixture.manifestFile.readAsBytes();
      gate.complete(null);
      expect(await replacing, isFalse);
      expect(received, same(host.navigation));
      expect(current, same(newer.navigation));
      expect(newer.navigation.error, isNull);
      expect(newer.navigation.pendingReceipt, isNull);
      expect(await newer.fixture.manifestFile.readAsBytes(), before);
    },
  );
}

Future<(ResourceReplacementFixture, File, String)> _model({
  Future<void> Function()? beforeReconciliation,
}) async {
  final host = await ResourceReplacementFixture.create(
    beforeReconciliation: beforeReconciliation,
  );
  final source = File('${host.fixture.root.path}/source.glb');
  await source.writeAsBytes(triangleGlb());
  await models.importStudioModel(
    host.navigation,
    picker: () async => PickedModelSource(source.path, 'Fontaine'),
  );
  expect(host.navigation.error, isNull);
  return (host, source, host.workspace.project!.models3d.single.id);
}

WorkspaceResourceOwnerBindings _bindings(MapWorkspaceController controller) =>
    WorkspaceResourceOwnerBindings(
      controller: controller,
      views: () => {},
      pokemon: () => null,
      dialogues: () => null,
      narrative: () => null,
      cinematics: () => null,
      drawEnvironment: (_) async {},
      retainBrush: () {},
    );
