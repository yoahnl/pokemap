import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/home/domain/recent_studio_project.dart';
import '../../shared/widgets/layout/studio_application_frame.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'studio_home_hero.dart';
import 'studio_home_all_maps.dart';
import 'studio_home_projects.dart';
import 'studio_home_tools.dart';

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
    required this.onDestination,
    this.recentProjects = const [],
    required this.onRecent,
    required this.onRemoveRecent,
    this.maps = const [],
    this.mapLibrary,
    this.mapPreviewBuilder,
    required this.onMap,
    this.status,
    this.statusAtTop = false,
    this.searchController,
    this.searchFocusNode,
  });
  final String? projectName, projectPath;
  final bool busy, canTest;
  final VoidCallback onOpen;
  final VoidCallback? onResume, onExport, onClose;
  final ValueChanged<String> onDestination, onMap;
  final List<RecentStudioProject> recentProjects;
  final ValueChanged<RecentStudioProject> onRecent, onRemoveRecent;
  final List<({String id, String name})> maps;
  final ProjectManifest? mapLibrary;
  final Widget Function(String)? mapPreviewBuilder;
  final Widget? status;
  final bool statusAtTop;
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;

  @override
  State<StudioHomeScreen> createState() => _StudioHomeScreenState();
}

class _StudioHomeScreenState extends State<StudioHomeScreen> {
  late final _search = widget.searchController ?? TextEditingController();
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
    if (widget.searchController == null) _search.dispose();
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

    Widget guidance() => ExpansionTile(
      title: const Text('Premiers pas'),
      childrenPadding: const EdgeInsets.all(12),
      children: [
        Text(
          widget.projectName == null
              ? 'Ouvrez un projet existant pour retrouver vos cartes, vos ressources et votre histoire.'
              : 'Reprenez une carte, enrichissez ses rencontres, puis testez le résultat dans le jeu.',
        ),
        for (final action in [
          ('Préparer les ressources', 'resources'),
          ('Composer une carte', 'map'),
          ('Écrire une rencontre', 'story'),
        ])
          StudioButton(
            label: action.$1,
            variant: StudioButtonVariant.quiet,
            icon: Icons.arrow_forward,
            onPressed: widget.busy
                ? null
                : () => widget.onDestination(action.$2),
          ),
      ],
    );

    Widget sidebar({required bool bounded}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        if (bounded)
          Expanded(
            child: StudioHomeRecentProjects(
              entries: recent,
              onOpen: widget.onRecent,
              onRemove: widget.onRemoveRecent,
              busy: widget.busy,
              bounded: true,
            ),
          )
        else if (recent.isNotEmpty)
          SizedBox(
            height: (MediaQuery.sizeOf(context).height * .42).clamp(
              180.0,
              320.0,
            ),
            child: StudioHomeRecentProjects(
              entries: recent,
              onOpen: widget.onRecent,
              onRemove: widget.onRemoveRecent,
              busy: widget.busy,
              bounded: true,
            ),
          )
        else
          StudioHomeRecentProjects(
            entries: recent,
            onOpen: widget.onRecent,
            onRemove: widget.onRemoveRecent,
            busy: widget.busy,
          ),
        const SizedBox(height: 10),
        if (bounded)
          StudioPanel(compact: true, children: [guidance()])
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
        onDestination: widget.onDestination,
        hasProject: widget.projectName != null,
        canTest: widget.canTest,
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

    return StudioApplicationFrame(
      searchFocusNode: widget.searchFocusNode,
      search: _search,
      onSearch: (_) {},
      onDestination: widget.onDestination,
      projectName: widget.projectName,
      busy: widget.busy,
      canTest: widget.canTest,
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
              busy: widget.busy,
              previewBuilder: widget.mapPreviewBuilder,
              query: _query,
            )
          : LayoutBuilder(builder: (context, bounds) => content(bounds)),
    );
  }
}
