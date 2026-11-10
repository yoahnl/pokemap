import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';
import '../support/scoped_map_workspace_port.dart';

void main() {
  Future<(ResourceNavigation, ScopedTestMapPort, MapWorkspaceController)> open({
    Future<void> Function(String)? beforeResourceRead,
  }) async {
    final port = ScopedTestMapPort(beforeResourceRead: beforeResourceRead);
    final workspace = MapWorkspaceController(scopedMapSession, port);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final navigation = ResourceNavigation(
      workspace: workspace,
      port: _Resources(),
      visuals: WorkspaceTestVisuals(),
      onUse: (_) {},
    );
    addTearDown(() {
      if (!navigation.isDisposed) navigation.dispose();
    });
    return (navigation, port, workspace);
  }

  test(
    'only the latest prepared family can authorize a library change',
    () async {
      final firstEntered = Completer<void>();
      final firstRelease = Completer<void>();
      final secondEntered = Completer<void>();
      final secondRelease = Completer<void>();
      final (navigation, port, workspace) = await open(
        beforeResourceRead: (kind) async {
          if (kind == 'borderBlueprint') {
            firstEntered.complete();
            await firstRelease.future;
          } else if (kind == 'tileset') {
            secondEntered.complete();
            await secondRelease.future;
          }
        },
      );
      final first = navigation.loadFamily(ResourceLibraryFamily.borders);
      await firstEntered.future;
      final second = navigation.loadFamily(ResourceLibraryFamily.images);
      expect(port.resourceKinds, ['borderBlueprint']);
      firstRelease.complete();
      expect(await first, isFalse);
      await secondEntered.future;
      expect(workspace.hasResourceKind('tileset'), isFalse);
      secondRelease.complete();
      expect(await second, isTrue);
      expect(port.resourceKinds, ['borderBlueprint', 'tileset']);
      expect(workspace.hasResourceKind('tileset'), isTrue);
      expect(workspace.hasResourceKind('borderBlueprint'), isFalse);
      expect(navigation.error, isNull);
      expect(navigation.library.family, ResourceLibraryFamily.decors);
    },
  );

  test(
    'failed preparation keeps the library selection and reports its cause',
    () async {
      final (navigation, port, workspace) = await open(
        beforeResourceRead: (_) async => throw StateError('source unavailable'),
      );
      expect(
        await navigation.loadFamily(ResourceLibraryFamily.images),
        isFalse,
      );
      expect(navigation.error, contains('source unavailable'));
      expect(navigation.library.family, ResourceLibraryFamily.decors);
      expect(workspace.hasResourceKind('tileset'), isFalse);
      expect(port.resourceKinds, ['tileset']);
    },
  );

  test('disposing during preparation prevents a late authorization', () async {
    final entered = Completer<void>();
    final release = Completer<void>();
    final (navigation, port, _) = await open(
      beforeResourceRead: (_) async {
        entered.complete();
        await release.future;
      },
    );
    final pending = navigation.loadFamily(ResourceLibraryFamily.images);
    await entered.future;
    navigation.dispose();
    release.complete();
    expect(await pending, isFalse);
    expect(navigation.library.family, ResourceLibraryFamily.decors);
    expect(port.resourceKinds, ['tileset']);
    expect(navigation.error, isNull);
  });
}

class _Resources implements ResourcePort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
