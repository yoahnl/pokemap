import 'package:avelune_studio/main.dart' as entry;
import 'package:avelune_studio/app/studio_bootstrap.dart';
import 'package:avelune_studio/app/studio_app.dart';
import 'package:avelune_studio/app/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avelune_studio/features/project_creation/application/project_creation_controller.dart';
import 'package:avelune_studio/presentation/features/project_creation/project_creation_steps.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets(
    'an empty catalogue never advertises an implicit downloaded game',
    (tester) async {
      final controller = ProjectCreationController(
        const LocalProjectCreationService(),
      )..step = 1;
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProjectCreationSteps(
                controller: controller,
                chooseParent: () async {},
              ),
            ),
          ),
        ),
      );
      expect(find.text('Petit projet jouable'), findsOneWidget);
      expect(find.textContaining('Clairbois'), findsNothing);
      expect(find.textContaining('GitHub'), findsNothing);
    },
  );
  testWidgets(
    'two catalogue entries select their identity, geometry and preview independently',
    (tester) async {
      final port = _RecordingPort(
        ProjectTemplateCatalog.fromJson({
          'schemaVersion': 1,
          'templates': [
            _descriptor('alpha', 'Archipel Alpha', 16, 24, 18),
            _descriptor('beta', 'Domaine Beta', 48, 12, 10),
          ],
        }),
      );
      final controller = ProjectCreationController(port)..step = 1;
      final revision = ValueNotifier(0);
      controller.addListener(() => revision.value++);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ValueListenableBuilder<int>(
                valueListenable: revision,
                builder: (_, _, _) => ProjectCreationSteps(
                  controller: controller,
                  chooseParent: () async {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('creation-template-catalogue-alpha')),
      );
      await tester.pump();
      expect(controller.request.template, ProjectCreationTemplate.catalogue);
      expect(controller.request.templateId, 'alpha');
      expect(
        (controller.tileSize, controller.width, controller.height),
        (16, '24', '18'),
      );
      expect(port.previews.last.templateId, 'alpha');
      await tester.tap(
        find.byKey(const ValueKey('creation-template-catalogue-beta')),
      );
      await tester.pump();
      expect(controller.request.templateId, 'beta');
      expect(
        (controller.tileSize, controller.width, controller.height),
        (48, '12', '10'),
      );
      expect(port.previews.last.templateId, 'beta');
      controller.change(() => controller.step = 2);
      await tester.pump();
      expect(find.text('Votre copie de Domaine Beta'), findsOneWidget);
      expect(find.byKey(const ValueKey('creation-grid-48')), findsOneWidget);
      expect(find.byKey(const ValueKey('creation-grid-16')), findsNothing);
      controller.setTemplate(ProjectCreationTemplate.empty);
      await tester.pump();
      expect(controller.request.templateId, isNull);
      expect(controller.previewError, isNull);
      expect(
        () => controller.setCatalogueTemplate('missing'),
        throwsFormatException,
      );
      expect(controller.request.template, ProjectCreationTemplate.empty);
      await tester.pumpWidget(const SizedBox());
      revision.dispose();
    },
  );

  testWidgets(
    'the declared bundle catalogue reaches the creation port through composition',
    (tester) async {
      final catalog = (await tester.runAsync(
        entry.loadStudioProjectTemplateCatalog,
      ))!;
      expect(catalog.templates, isNotEmpty);
      await tester.pumpWidget(StudioBootstrap(templateCatalog: catalog));
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
