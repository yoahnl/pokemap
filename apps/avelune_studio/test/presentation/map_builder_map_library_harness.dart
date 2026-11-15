import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/application/map_library_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_catalog_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_map_tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

final class MemoryMapCatalogPort
    implements MapCatalogPort, MapCatalogPreparationPort {
  MemoryMapCatalogPort(this.manifest);

  ProjectManifest manifest;
  final calls = <(String, Map<String, Object?>)>[];
  final usages = <String, List<Map<String, Object?>>>{};
  var _revision = 0;

  @override
  Future<MapCatalogReceipt> mutate(
    ProjectSession session,
    String actionId,
    Map<String, Object?> parameters, {
    Map<String, String> expectedMapRevisions = const {},
    bool confirmDestructive = false,
    ProjectManifest? expectedManifest,
  }) async {
    calls.add((actionId, parameters));
    final before = manifest;
    String? created;
    final next = switch (actionId) {
      'map.create' => before.copyWith(
        maps: [
          ...before.maps,
          ProjectMapEntry(
            id: created = parameters['mapId']! as String,
            name: parameters['name']! as String,
            relativePath: 'maps/$created.json',
            groupId: parameters['groupId'] as String?,
          ),
        ],
      ),
      'map.duplicate' => before.copyWith(
        maps: [
          ...before.maps,
          ProjectMapEntry(
            id: created = parameters['targetMapId']! as String,
            name: parameters['name']! as String,
            relativePath: 'maps/$created.json',
            groupId: parameters['groupId'] as String?,
          ),
        ],
      ),
      'map.update_metadata' => before.copyWith(
        maps: [
          for (final map in before.maps)
            map.id == parameters['mapId']
                ? map.copyWith(name: parameters['name']! as String)
                : map,
        ],
      ),
      'map.library.reorganize' => _organize(before, parameters),
      'map.delete_apply' => before.copyWith(
        maps: [
          for (final map in before.maps)
            if (map.id != parameters['mapId']) map,
        ],
      ),
      _ => throw StateError(actionId),
    };
    return MapCatalogReceipt(
      before: before,
      manifest: next,
      beforeRevision: 'r$_revision',
      revision: 'r${++_revision}',
      changedPaths: const ['project.json'],
      createdMapId: created,
    );
  }

  ProjectManifest _organize(
    ProjectManifest before,
    Map<String, Object?> parameters,
  ) {
    final groups = parameters['groups'] as List?;
    final assignments = {
      for (final value in (parameters['assignments'] as List? ?? const []))
        (value as Map)['mapId']: value['groupId'],
    };
    return before.copyWith(
      groups: groups == null
          ? before.groups
          : [
              for (final group in groups)
                ProjectMapGroup.fromJson(Map<String, dynamic>.from(group)),
            ],
      maps: [
        for (final map in before.maps)
          assignments.containsKey(map.id)
              ? map.copyWith(groupId: assignments[map.id] as String?)
              : map,
      ],
    );
  }

  @override
  Future<void> reconcile(
    ProjectSession session,
    MapCatalogReceipt receipt,
  ) async {
    manifest = receipt.manifest;
  }

  @override
  Future<MapCatalogPreparation> prepare(
    ProjectSession session,
    String actionId,
    Map<String, Object?> parameters, {
    Map<String, String> expectedMapRevisions = const {},
    ProjectManifest? expectedManifest,
  }) async {
    final mapId = parameters['mapId']! as String;
    final dependents = usages[mapId] ?? const [];
    return MapCatalogPreparation(
      sessionId: session.sessionId,
      actionId: actionId,
      parameters: parameters,
      targetMapId: mapId,
      snapshotRevision: 'r$_revision',
      sourceMap: workspaceMap(mapId),
      canApply: dependents.isEmpty,
      details: {if (dependents.isNotEmpty) 'dependents': dependents},
    );
  }

  @override
  Future<MapCatalogReceipt> applyPrepared(
    ProjectSession session,
    MapCatalogPreparation preparation, {
    Map<String, String> expectedMapRevisions = const {},
    bool confirmDestructive = false,
    ProjectManifest? expectedManifest,
    String? Function()? validateBeforeApply,
  }) => mutate(
    session,
    preparation.actionId,
    preparation.parameters,
    confirmDestructive: confirmDestructive,
    expectedManifest: expectedManifest,
  );
}

const mapLibraryGroups = [
  ProjectMapGroup(id: 'johto', name: 'Johto', type: MapGroupType.route),
];

ProjectManifest mapLibraryProject() => workspaceProject.copyWith(
  groups: mapLibraryGroups,
  maps: [
    workspaceEntries.first.copyWith(groupId: 'johto'),
    workspaceEntries.last,
  ],
);

Future<(MapWorkspaceController, MemoryMapCatalogPort)> pumpMapLibrary(
  WidgetTester tester, {
  Locale locale = const Locale('fr'),
}) async {
  tester.view.physicalSize = const Size(900, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final project = mapLibraryProject();
  final catalog = MemoryMapCatalogPort(project);
  final controller = MapWorkspaceController(
    workspaceSession,
    WorkspaceMemoryPort(manifest: project),
    catalogPort: catalog,
  );
  addTearDown(controller.dispose);
  await controller.initialize();
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(width: 320, child: _Host(controller: controller)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('map-library-folder-unfiled')));
  await tester.pumpAndSettle();
  return (controller, catalog);
}

class _Host extends StatefulWidget {
  const _Host({required this.controller});

  final MapWorkspaceController controller;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  void _changed() => setState(() {});

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MapBuilderMapTree(
    groups: widget.controller.project?.groups ?? const [],
    maps: widget.controller.project?.maps ?? const [],
    activeMapId: widget.controller.active?.base.mapId,
    onSelect: widget.controller.activate,
    commands: MapLibraryCommands(widget.controller),
  );
}
