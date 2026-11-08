import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';
import '../support/scoped_map_workspace_port.dart';

class _Resources implements ResourcePort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<(ResourceNavigation, ScopedTestMapPort, MapWorkspaceController)>
_navigation() async {
  final port = ScopedTestMapPort();
  final controller = MapWorkspaceController(scopedMapSession, port);
  addTearDown(controller.dispose);
  await controller.initialize();
  final navigation = ResourceNavigation(
    workspace: controller,
    port: _Resources(),
    visuals: WorkspaceTestVisuals(),
    onUse: (_) {},
  );
  addTearDown(navigation.dispose);
  return (navigation, port, controller);
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'returning from the character studio reloads the family the library shows',
    () async {
      final (navigation, port, controller) = await _navigation();
      expect(
        await navigation.loadFamily(ResourceLibraryFamily.environments),
        isTrue,
      );
      navigation.library.selectFamily(ResourceLibraryFamily.environments);
      await navigation.openCharacters();
      expect(navigation.page, ResourcePage.characters);
      expect(controller.hasResourceKind('environmentPreset'), isFalse);

      navigation.showLibrary();
      expect(navigation.page, ResourcePage.library);
      for (var turn = 0; turn < 5; turn++) {
        await _settle();
      }
      expect(port.resourceKinds, [
        'environmentPreset',
        'character',
        'environmentPreset',
      ]);
      expect(controller.hasResourceKind('environmentPreset'), isTrue);
    },
  );

  test(
    'showing the library with its family already loaded reads nothing',
    () async {
      final (navigation, port, _) = await _navigation();
      await navigation.loadFamily(ResourceLibraryFamily.environments);
      navigation.library.selectFamily(ResourceLibraryFamily.environments);
      navigation.showLibrary();
      for (var turn = 0; turn < 5; turn++) {
        await _settle();
      }
      expect(port.resourceKinds, ['environmentPreset']);
    },
  );
}
