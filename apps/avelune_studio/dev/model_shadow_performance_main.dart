import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_rendering/avelune_rendering.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/resources/model_resource_library.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_detail_panel.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_toggle_row.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../test/support/model_shadow_fixture.dart';

final _host = ValueNotifier<Widget>(const SizedBox());

Iterable<Element> _elements(Element root) sync* {
  yield root;
  final children = <Element>[];
  root.visitChildren(children.add);
  for (final child in children) {
    yield* _elements(child);
  }
}

Element _toggle() => _elements(WidgetsBinding.instance.rootElement!).firstWhere(
  (element) =>
      element.widget.key == const ValueKey('model-casts-shadows-default'),
);

Future<void> _frame() async {
  WidgetsBinding.instance.scheduleFrame();
  await WidgetsBinding.instance.endOfFrame;
}

Future<void> main() async {
  AveluneWidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: ValueListenableBuilder(
          valueListenable: _host,
          builder: (_, child, _) => child,
        ),
      ),
    ),
  );
  await _frame();
  try {
    for (final storage in [
      ProjectSessionStorage.workingCatalog,
      ProjectSessionStorage.manifest,
    ]) {
      for (final unrelated in [0, 120]) {
        for (final library in [false, true]) {
          Stopwatch? operation;
          int? painted;
          var target = false;
          var phases = <String, int>{};
          final fixture = await ModelShadowFixture.create(
            storage: storage,
            unrelated: unrelated,
            phaseObserver: (phase) {
              if (operation != null) {
                phases[phase] = operation.elapsedMicroseconds;
              }
            },
          );
          final project = (await fixture.maps.resourceBaseline(fixture.session))
              .manifest;
          final workspace = MapWorkspaceController(
            fixture.session,
            fixture.maps,
          )..project = project;
          final visuals = await StudioMapResources.load(
            fixture.session,
            project,
          );
          final navigation = ResourceNavigation(
            workspace: workspace,
            port: fixture.resources,
            visuals: visuals,
            onUse: (_) {},
          );
          try {
            Widget panel() {
              final current = workspace.project!;
              final model = current.models3d.firstWhere(
                (entry) => entry.id == 'house',
              );
              final item = ResourceItem(
                id: model.id,
                name: model.name,
                kind: ResourceKind.decors,
                model3d: model,
              );
              if (library) {
                return ModelResourceLibrary(
                  navigation: navigation,
                  items: [item],
                  previewBuilder: (_, _) => const SizedBox(height: 80),
                );
              }
              return SingleChildScrollView(
                child: ResourceDetailPanel(
                  item: item,
                  project: current,
                  preview: const SizedBox(height: 80),
                  onUse: (_) {},
                  onEdit: (_) {},
                  onTerrain: (_) {},
                  onModelShadowsChanged: (entry, enabled) => navigation.mutate(
                    'model3d.configure',
                    {'modelId': entry.id, 'castsShadowsByDefault': enabled},
                  ),
                ),
              );
            }

            _host.value = ListenableBuilder(
              listenable: navigation,
              builder: (_, _) => panel(),
            );
            await _frame();
            await Scrollable.ensureVisible(_toggle(), duration: Duration.zero);
            await _frame();
            final rows = <Map<String, Object?>>[];
            for (var repeat = 0; repeat < 12; repeat++) {
              target = !target;
              painted = null;
              phases = {};
              final reads = <String>[];
              final toggle = _toggle();
              final box = toggle.findRenderObject()! as RenderBox;
              final point = box.localToGlobal(box.size.center(Offset.zero));
              void observe(Duration _) {
                if (operation == null || painted != null) return;
                final value = _toggle().widget as StudioToggleRow;
                if (value.value == target) {
                  painted = operation.elapsedMicroseconds;
                } else {
                  WidgetsBinding.instance.addPostFrameCallback(observe);
                }
              }

              operation = Stopwatch()..start();
              WidgetsBinding.instance.addPostFrameCallback(observe);
              await fixture.observe(() async {
                GestureBinding.instance.handlePointerEvent(
                  PointerDownEvent(pointer: repeat + 1, position: point),
                );
                GestureBinding.instance.handlePointerEvent(
                  PointerUpEvent(pointer: repeat + 1, position: point),
                );
                final deadline = DateTime.now().add(
                  const Duration(seconds: 30),
                );
                while (!phases.containsKey('reconciliation.end') ||
                    navigation.busy ||
                    painted == null) {
                  if (navigation.error != null) {
                    throw StateError(navigation.error!);
                  }
                  if (DateTime.now().isAfter(deadline)) {
                    throw TimeoutException(
                      'Shadow toggle',
                      const Duration(seconds: 30),
                    );
                  }
                  await _frame();
                  await Future<void>.delayed(const Duration(milliseconds: 1));
                }
              }, reads);
              rows.add({
                'repeat': repeat,
                'feedbackUs': painted,
                'durableUs': phases['apply.end'],
                'totalUs': operation.elapsedMicroseconds,
                'foreignReads': reads.length,
                'phasesUs': phases,
              });
              operation = null;
              await _frame();
            }
            stdout.writeln(
              jsonEncode({
                'storage': storage.name,
                'unrelatedModels': unrelated,
                'maps': unrelated + 1,
                'entry': library ? 'library' : 'detail',
                'mode': 'release',
                'samples': rows,
              }),
            );
          } finally {
            _host.value = const SizedBox();
            await _frame();
            navigation.dispose();
            workspace.dispose();
            visuals.dispose();
            await fixture.dispose();
          }
        }
      }
    }
    exit(0);
  } on Object catch (error, stack) {
    stderr.writeln('$error\n$stack');
    exit(1);
  }
}
