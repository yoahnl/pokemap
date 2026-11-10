import 'package:avelune_studio/main.dart' as entry;
import 'package:avelune_studio/app/studio_bootstrap.dart';
import 'package:avelune_studio/app/studio_app.dart';
import 'package:avelune_studio/app/di/providers.dart';
import 'package:avelune_studio/platform/mcp/studio_mcp_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avelune_studio/features/project_creation/application/project_creation_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  test('the creation default is the generic playable template', () {
    final controller = ProjectCreationController(
      const LocalProjectCreationService(),
    );
    addTearDown(controller.dispose);
    expect(controller.template, ProjectCreationTemplate.playable);
    expect(controller.tileSize, 16);
  });

  test('an empty catalogue never selects an implicit downloaded game', () {
    final controller = ProjectCreationController(
      const LocalProjectCreationService(),
    );
    addTearDown(controller.dispose);
    expect(controller.port.templateCatalog.templates, isEmpty);
    expect(controller.template, ProjectCreationTemplate.playable);
    expect(controller.selectedTemplate, isNull);
    expect(controller.request.templateId, isNull);
  });

  test(
    'two catalogue entries retain independent identity, geometry and preview',
    () async {
      final port = _RecordingPort(
        ProjectTemplateCatalog.fromJson({
          'schemaVersion': 1,
          'templates': [
            _descriptor('alpha', 'Archipel Alpha', 16, 24, 18),
            _descriptor('beta', 'Domaine Beta', 48, 12, 10),
          ],
        }),
      );
      final controller = ProjectCreationController(port);
      addTearDown(controller.dispose);
      controller.setCatalogueTemplate('alpha');
      await controller.loadPreview();
      expect(controller.request.template, ProjectCreationTemplate.catalogue);
      expect(controller.request.templateId, 'alpha');
      expect(
        (controller.tileSize, controller.width, controller.height),
        (16, '24', '18'),
      );
      expect(port.previews.last.templateId, 'alpha');
      controller.setCatalogueTemplate('beta');
      await controller.loadPreview();
      expect(controller.request.templateId, 'beta');
      expect(
        (controller.tileSize, controller.width, controller.height),
        (48, '12', '10'),
      );
      expect(controller.selectedTemplate!.label, 'Domaine Beta');
      expect(port.previews.last.templateId, 'beta');
      controller.setTemplate(ProjectCreationTemplate.empty);
      await controller.loadPreview();
      expect(controller.request.templateId, isNull);
      expect(controller.previewError, isNull);
      expect(
        () => controller.setCatalogueTemplate('missing'),
        throwsFormatException,
      );
      expect(controller.request.template, ProjectCreationTemplate.empty);
    },
  );

  testWidgets(
    'the declared bundle catalogue reaches the creation port through composition',
    (tester) async {
      final catalog = (await tester.runAsync(
        entry.loadStudioProjectTemplateCatalog,
      ))!;
      expect(catalog.templates, isEmpty);
      await tester.pumpWidget(
        StudioBootstrap(
          templateCatalog: catalog,
          mcpService: StudioMcpService(
            launch: () async => throw StateError('fixture.unavailable'),
          ),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(StudioApp)),
        listen: false,
      );
      expect(
        container.read(projectCreationPortProvider)!.templateCatalog,
        same(catalog),
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('switching to 3D clears the selected catalogue identity', () async {
    final controller = ProjectCreationController(
      _RecordingPort(
        ProjectTemplateCatalog.fromJson({
          'schemaVersion': 1,
          'templates': [_descriptor('custom', 'Custom', 32, 20, 15)],
        }),
      ),
    );
    controller.setCatalogueTemplate('custom');
    controller.setDimension(ProjectDimension.threeD);
    expect(controller.request.template, ProjectCreationTemplate.empty);
    expect(controller.request.templateId, isNull);
    controller.dispose();
  });
}

Map<String, Object?> _descriptor(
  String id,
  String label,
  int tileSize,
  int width,
  int height,
) => {
  'id': id,
  'label': label,
  'description': 'Contenu éditable de $label.',
  'revision': 'revision-$id',
  'projectPaths': ['project.json', 'maps/', 'assets/'],
  'archive': {
    'uri': 'https://example.invalid/$id.zip',
    'sha256': List.filled(64, '0').join(),
  },
  'preview': {
    'uri': 'https://example.invalid/$id.png',
    'sha256': List.filled(64, '1').join(),
  },
  'geometry': {'tileSize': tileSize, 'mapWidth': width, 'mapHeight': height},
};

final class _RecordingPort implements ProjectCreationPort {
  _RecordingPort(this.templateCatalog);
  @override
  final ProjectTemplateCatalog templateCatalog;
  final previews = <ProjectCreationRequest>[];
  @override
  Future<List<int>?> preview(ProjectCreationRequest request) async {
    previews.add(request);
    return null;
  }

  @override
  Future<String> validateDestination(ProjectCreationRequest request) async =>
      '/project';
  @override
  Future<ProjectCreationReceipt> create(
    ProjectCreationRequest request, {
    void Function(ProjectCreationPhase)? onPhase,
    bool Function()? isCancelled,
    String? expectedDestination,
  }) async => throw UnimplementedError();
}
