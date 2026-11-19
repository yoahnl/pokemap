import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../../features/map_workspace/domain/map_workspace_port.dart';
import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/resources/application/project_resource_library.dart';
import '../../shared/localization/studio_labels.dart';
import '../../shared/localization/studio_locale.dart';
import 'project_library_detail.dart';

class ProjectLibraryPage extends StatefulWidget {
  const ProjectLibraryPage({
    super.key,
    required this.active,
    required this.maps,
    required this.visuals,
  });

  final bool active;
  final MapWorkspaceController maps;
  final MapWorkspaceVisuals? visuals;

  @override
  State<ProjectLibraryPage> createState() => _ProjectLibraryPageState();
}

class _ProjectLibraryPageState extends State<ProjectLibraryPage> {
  final _search = TextEditingController();
  Future<ProjectResourceLibrary>? _reading;
  String? _family;
  String? _selected;
  var _role = ResourceLibraryRole.standard;

  @override
  void initState() {
    super.initState();
    if (widget.active) _read();
  }

  @override
  void didUpdateWidget(ProjectLibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active &&
        (!oldWidget.active ||
            _reading == null ||
            oldWidget.maps != widget.maps)) {
      _read();
    }
  }

  void _read() {
    final maps = widget.maps;
    if (maps.project == null) return;
    final port = maps.port;
    if (port is ProjectResourceLibraryPort) {
      _reading = (port as ProjectResourceLibraryPort).readResourceLibrary(
        maps.session,
      );
    } else if (!maps.hasCompleteProject && port is MapWorkspaceScopedPort) {
      _reading = port
          .materializeProject(maps.session)
          .then(ProjectResourceLibrary.fromManifest);
    } else {
      _reading = Future.value(
        ProjectResourceLibrary.fromManifest(maps.project!),
      );
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(StudioSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.railResources,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              IconButton(
                tooltip: l10n.libraryRefresh,
                icon: const Icon(Icons.refresh),
                onPressed: () => setState(_read),
              ),
            ],
          ),
          const SizedBox(height: StudioSpacing.l),
          Expanded(
            child: FutureBuilder<ProjectResourceLibrary>(
              future: _reading,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return StudioEmptyState(
                    title: l10n.resourcesUnavailable('${snapshot.error}'),
                  );
                }
                final library = snapshot.data;
                if (library == null ||
                    snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _content(library);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _content(ProjectResourceLibrary library) {
    final l10n = context.l10n;
    final family = library.families.containsKey(_family) ? _family : null;
    final results = library.search(_role, family, _search.text);
    final selected = results
        .where((item) => item.identity == _selected)
        .firstOrNull;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 224,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.libraryFamilies,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: StudioSpacing.m),
              Expanded(
                child: ListView(
                  children: [
                    StudioChoice(
                      label: l10n.libraryAllFamilies,
                      selected: family == null,
                      onTap: () => setState(() => _family = null),
                    ),
                    for (final id in library.populatedFamilies)
                      StudioChoice(
                        key: ValueKey('library-family-$id'),
                        label: library.familyPath(id),
                        selected: family == id,
                        onTap: () => setState(() => _family = id),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: StudioSpacing.xxl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              StudioSearchField(
                key: const ValueKey('library-search'),
                controller: _search,
                label: l10n.resourceSearch,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: StudioSpacing.m),
              Wrap(
                spacing: StudioSpacing.m,
                children: [
                  for (final role in ResourceLibraryRole.values)
                    StudioFilterChip(
                      key: ValueKey('library-role-${role.name}'),
                      label: role == ResourceLibraryRole.standard
                          ? l10n.libraryAuthorResources
                          : l10n.libraryComponents,
                      selected: role == _role,
                      onSelected: (_) => setState(() => _role = role),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: StudioSpacing.m),
                child: Text(
                  l10n.libraryResultCount(results.length),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              Expanded(
                child: results.isEmpty
                    ? StudioEmptyState(
                        title: l10n.resourceEmptyTitle,
                        description: l10n.resourceEmptyBody,
                      )
                    : ListView.builder(
                        key: ValueKey((family, _role, _search.text)),
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final item = results[index];
                          return StudioChoice(
                            key: ValueKey('library-item-${item.identity}'),
                            label: item.name,
                            subtitle: [
                              l10n.resourceKindLabel(item.kind),
                              if (item.familyId case final id?)
                                library.familyPath(id),
                            ].join(' · '),
                            selected: selected?.identity == item.identity,
                            onTap: () =>
                                setState(() => _selected = item.identity),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        if (selected != null) ...[
          const VerticalDivider(width: StudioSpacing.xxl),
          SizedBox(
            width: 245,
            child: ProjectLibraryDetail(
              key: ValueKey(selected.identity),
              item: selected,
              library: library,
              maps: widget.maps,
              visuals: widget.visuals,
            ),
          ),
        ],
      ],
    );
  }
}
