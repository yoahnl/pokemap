import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/home/application/home_next_steps.dart';
import '../../../features/home/domain/recent_studio_project.dart';
import 'studio_home_frame.dart';
import 'studio_home_hero.dart';
import 'studio_home_all_maps.dart';
import 'studio_home_projects.dart';
import 'studio_home_tools.dart';
import 'studio_home_guidance.dart';
import 'studio_home_next_steps.dart';

typedef StudioHomeProjectAccess = ({
  List<RecentStudioProject> recent,
  VoidCallback open,
  ValueChanged<RecentStudioProject> openRecent,
  ValueChanged<RecentStudioProject> removeRecent,
});

class StudioHomeScreen extends StatefulWidget {
  const StudioHomeScreen({
    super.key,
    this.projectName,
    this.projectPath,
    this.busy = false,
    this.canTest = false,
    required this.onOpen,
    this.onResume,
    this.onExport,
    this.onClose,
    this.onCreate,
    this.onCreateMap,
    this.destinations = const {},
    this.recentProjects = const [],
    required this.onRecent,
    required this.onRemoveRecent,
    this.maps = const [],
    this.mapLibrary,
    this.newGame,
    this.mapPreviewBuilder,
    required this.onMap,
    this.status,
    this.statusAtTop = false,
  });
  final String? projectName, projectPath;
  final bool busy, canTest;
  final VoidCallback onOpen;
  final VoidCallback? onResume, onExport, onClose, onCreate, onCreateMap;
  final Map<String, VoidCallback> destinations;
  final ValueChanged<String> onMap;
  final List<RecentStudioProject> recentProjects;
  final ValueChanged<RecentStudioProject> onRecent, onRemoveRecent;
  final List<({String id, String name})> maps;
  final ProjectManifest? mapLibrary;
  final ProjectNewGameConfig? newGame;
  final Widget Function(String)? mapPreviewBuilder;
  final Widget? status;
  final bool statusAtTop;

  @override
  State<StudioHomeScreen> createState() => _StudioHomeScreenState();
}

class _StudioHomeScreenState extends State<StudioHomeScreen> {
  final _search = TextEditingController();
  final _contentScroll = ScrollController();
  String _query = '';
  bool _showAllMaps = false;

  @override
  void initState() {
    super.initState();
    _query = _search.text.trim().toLowerCase();
    _search.addListener(_searchChanged);
  }

  void _searchChanged() =>
      setState(() => _query = _search.text.trim().toLowerCase());

  @override
  void didUpdateWidget(StudioHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statusAtTop != widget.statusAtTop ||
        oldWidget.projectName != widget.projectName) {
      if (oldWidget.projectName != widget.projectName) _showAllMaps = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _contentScroll.hasClients) _contentScroll.jumpTo(0);
      });
    }
  }

  @override
  void dispose() {
    _search.removeListener(_searchChanged);
    _contentScroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recent = widget.recentProjects
        .where(
          (entry) =>
              entry.name.toLowerCase().contains(_query) ||
              entry.directoryPath.toLowerCase().contains(_query),
        )
        .toList();
    final maps = widget.maps
        .where((map) => map.name.toLowerCase().contains(_query))
        .toList();

    Widget guidance() => widget.projectName != null
        ? StudioHomeNextSteps(
            steps: homeNextSteps(
              maps: widget.maps,
              newGame: widget.newGame ?? widget.mapLibrary?.newGame,
              canTest: widget.canTest,
            ),
            busy: widget.busy,
            destinations: widget.destinations,
            onMap: widget.onMap,
          )
        : StudioHomeGuidance(
            hasProject: widget.projectName != null,
            busy: widget.busy,
            destinations: widget.destinations,
          );

    Widget recents({bool bounded = false}) => StudioHomeRecentProjects(
      entries: recent,
      onOpen: widget.onRecent,
      onRemove: widget.onRemoveRecent,
      busy: widget.busy,
      onCreate: widget.onCreate,
      bounded: bounded,
    );
    Widget sidebar({required bool bounded}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (bounded)
          Expanded(child: recents(bounded: true))
        else if (recent.isNotEmpty)
          SizedBox(
            height: (MediaQuery.sizeOf(context).height * .42).clamp(
              180.0,
              320.0,
            ),
            child: recents(bounded: true),
          )
        else
          recents(),
        const SizedBox(height: 10),
        if (bounded)
          Flexible(
            child: SingleChildScrollView(
              key: const ValueKey('home-guidance-scroll'),
              child: StudioPanel(compact: true, children: [guidance()]),
            ),
          )
        else ...[
          const StudioPanel(
            title: 'Conseil du jour',
            compact: true,
            children: [
              Text(
                'Préparez vos terrains dans Ressources, puis peignez la carte : les raccords se font automatiquement.',
              ),
            ],
          ),
          const SizedBox(height: 10),
          StudioPanel(compact: true, children: [guidance()]),
        ],
      ],
    );

    Widget content(BoxConstraints bounds) {
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final narrow = bounds.maxWidth < 950 || textScale > 1.25;
      final short = bounds.maxHeight < 700 || textScale > 1.25;
      final localScroll = narrow || short;
      final hero = StudioHomeHero(
        busy: widget.busy,
        onOpen: widget.onOpen,
        onResume: widget.onResume,
        onExport: widget.onExport,
        projectName: widget.projectName,
        compact: bounds.maxHeight < 850 || narrow,
        smallWindow: bounds.maxWidth < 600,
      );
      final tools = StudioHomeTools(
        destinations: widget.destinations,
        hasProject: widget.projectName != null,
        busy: widget.busy,
        dense: !localScroll,
      );
      final resume = StudioHomeResume(
        maps: maps,
        previewBuilder: widget.mapPreviewBuilder,
        onMap: widget.onMap,
        onAllMaps: () {
          _search.clear();
          setState(() => _showAllMaps = true);
        },
        hasProject: widget.projectName != null,
        busy: widget.busy,
        maxPreview: narrow ? 2 : 4,
      );
      final path = widget.projectPath == null
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                widget.projectPath!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
      if (localScroll) {
        return Column(
          children: [
            if (widget.statusAtTop && widget.status != null) widget.status!,
            Expanded(
              child: ListView(
                key: const ValueKey('home-local-content-scroll'),
                controller: _contentScroll,
                padding: const EdgeInsets.all(10),
                children: [
                  hero,
                  if (!widget.statusAtTop && widget.status != null)
                    widget.status!,
                  const SizedBox(height: 10),
                  tools,
                  const SizedBox(height: 10),
                  resume,
                  path,
                  const SizedBox(height: 10),
                  sidebar(bounded: false),
                ],
              ),
            ),
          ],
        );
      }
      return Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.statusAtTop && widget.status != null)
                    widget.status!,
                  hero,
                  const SizedBox(height: 10),
                  tools,
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      key: const ValueKey('home-maps-local-scroll'),
                      child: Column(children: [resume, path]),
                    ),
                  ),
                  if (!widget.statusAtTop && widget.status != null)
                    widget.status!,
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(width: 284, child: sidebar(bounded: true)),
          ],
        ),
      );
    }

    return StudioHomeFrame(
      search: _search,
      onSearch: (_) {},
      destinations: widget.destinations,
      projectName: widget.projectName,
      busy: widget.busy,
      onClose: widget.onClose,
      child: _showAllMaps
          ? StudioHomeAllMaps(
              maps:
                  widget.mapLibrary?.maps ??
                  [
                    for (final map in widget.maps)
                      ProjectMapEntry(
                        id: map.id,
                        name: map.name,
                        relativePath: '',
                      ),
                  ],
              groups: widget.mapLibrary?.groups ?? const [],
              onMap: widget.onMap,
              onBack: () => setState(() => _showAllMaps = false),
              onCreateMap: widget.onCreateMap,
              busy: widget.busy,
              previewBuilder: widget.mapPreviewBuilder,
              query: _query,
            )
          : LayoutBuilder(builder: (context, bounds) => content(bounds)),
    );
  }
}
