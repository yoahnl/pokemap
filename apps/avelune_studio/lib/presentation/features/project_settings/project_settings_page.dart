import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../../features/map_workspace/domain/map_atmosphere_port.dart';
import '../../../features/project_audio/application/project_audio_controller.dart';
import '../../../features/project_cs/application/project_cs_controller.dart';
import '../../../features/project_settings/application/project_settings_session_controller.dart';
import '../../../features/project_surf/application/project_surf_controller.dart';
import '../../../features/project_visuals/application/project_visuals_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../presentations/presentation_media_picker.dart';
export 'project_settings_navigator.dart' show ProjectSettingsSectionLabels;

import 'project_audio_panel.dart';
import 'project_cs_panel.dart';
import 'project_settings_navigator.dart';
import 'project_settings_section_footer.dart';
import 'project_surf_panel.dart';
import 'spatial_visual_controls.dart';

typedef StudioVisualTestBuilder = Widget Function(
  ProjectMapEntry entry,
  String revision,
  VoidCallback close,
  ValueListenable<SpatialVisualPatch> preview,
);

class ProjectSettingsPage extends StatefulWidget {
  const ProjectSettingsPage({
    super.key,
    required this.workspace,
    required this.owner,
    this.testBuilder,
    this.surfOwner,
    this.csOwner,
    this.audioOwner,
    this.pickMedia,
    this.loadItems,
    this.onOpenVerification,
    this.onOpenExport,
  });
  final MapWorkspaceController workspace;
  final ProjectVisualsController owner;
  final StudioVisualTestBuilder? testBuilder;
  final ProjectSurfController? surfOwner;
  final ProjectCsController? csOwner;
  final ProjectAudioController? audioOwner;
  final PickPresentationMedia? pickMedia;
  final Future<Map<String, String>> Function()? loadItems;
  final VoidCallback? onOpenVerification, onOpenExport;
  @override
  State<ProjectSettingsPage> createState() => _ProjectSettingsPageState();
}

class _ProjectSettingsPageState extends State<ProjectSettingsPage> {
  ProjectVisualsController get owner => widget.owner;
  MapWorkspaceController get workspace => widget.workspace;
  late final ProjectSettingsSessionController session;
  final rendered = ValueNotifier(SpatialVisualPatch());
  SpatialVisualPatch base = SpatialVisualPatch.fromScene(
    camera: SpatialCameraProfile(),
    atmosphere: SpatialAtmosphereSettings(),
  );
  ProjectMapEntry? preview;
  ProjectVisualsController? mapDraft;
  SpatialVisualPatch local = SpatialVisualPatch();
  bool previewLoading = false, previewSpatial = false;
  String? previewProblem, scopeNotice, testError;
  Widget? test;
  int _previewGeneration = 0;
  bool _refreshScheduled = false;
  (String?, String)? _applied;

  @override
  void initState() {
    super.initState();
    session = ProjectSettingsSessionController(
      projectVisuals: owner,
      mapVisuals: _mapVisuals,
      fieldAbilities: widget.csOwner,
      surf: widget.surfOwner,
      audio: widget.audioOwner,
    );
    session.addListener(_changed);
    owner.addListener(_changed);
    final maps = workspace.project?.maps ?? <ProjectMapEntry>[];
    preview =
        maps.where((e) => e.id == workspace.active?.base.mapId).firstOrNull ??
        maps.firstOrNull;
    if ((owner.saved == null && !owner.loading) ||
        (owner.scope != null && !owner.dirty)) {
      unawaited(owner.open());
    }
    if (preview case final entry?) {
      previewLoading = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && identical(preview, entry)) {
          unawaited(_loadPreview(entry));
        }
      });
    }
    _changed();
  }

  ProjectVisualsController? _mapVisuals(String mapId) {
    final document = workspace.documents[mapId];
    if (document == null || document.current.spatialScene == null) {
      return null;
    }
    return workspace.weatherDraftFor(document);
  }

  void _changed() {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      if (_refreshScheduled) return;
      _refreshScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _refreshScheduled = false;
        _changed();
      });
      return;
    }
    final saved = owner.saved;
    if (saved != null &&
        owner.scope == null &&
        _applied != (null, saved.revision)) {
      _applied = (null, saved.revision);
      workspace.acceptVisualProfile(saved.profile);
    }
    rendered.value = base
        .overriddenBy(owner.preview.value)
        .overriddenBy(mapDraft?.preview.value ?? local);
    setState(() {});
  }

  void _watchMapDraft(ProjectVisualsController? next) {
    if (identical(next, mapDraft)) return;
    mapDraft?.removeListener(_changed);
    mapDraft = next;
    mapDraft?.addListener(_changed);
  }

  Future<void> _loadPreview(ProjectMapEntry entry) async {
    final generation = ++_previewGeneration;
    setState(() {
      previewLoading = true;
      previewProblem = null;
      testError = null;
      test = null;
    });
    bool current() => mounted && generation == _previewGeneration;
    try {
      await workspace.activate(entry, isCurrent: current);
      if (!current()) return;
      final document = workspace.documents[entry.id];
      final scene = document?.current.spatialScene;
      if (document == null || scene == null) {
        base = SpatialVisualPatch.fromScene(
          camera: SpatialCameraProfile(),
          atmosphere: SpatialAtmosphereSettings(),
        );
        previewSpatial = false;
        local = SpatialVisualPatch();
        _watchMapDraft(null);
        previewProblem =
            'La carte « ${entry.name} » n’a pas de rendu 3D : l’aperçu en jeu '
            'est indisponible. Les réglages du projet restent modifiables.';
      } else {
        final source = workspace.port;
        final atmosphere =
            document.atmosphere?.current ??
            (source is MapAtmospherePort
                ? (await (source as MapAtmospherePort).loadAtmosphere(
                    workspace.session,
                    entry.id,
                  )).settings
                : SpatialAtmosphereSettings());
        if (!current()) return;
        final existing = document.weatherVisuals;
        final saved =
            existing?.saved?.profile ??
            (await owner.port.loadVisuals(
              workspace.session,
              map: entry,
            )).profile;
        if (!current()) return;
        base = SpatialVisualPatch.fromScene(
          camera: scene.camera,
          atmosphere: atmosphere,
          cycle: scene.dayNightCycle,
        );
        previewSpatial = true;
        local = saved;
        _watchMapDraft(existing);
      }
      if (session.scopeMapId != null) {
        if (!previewSpatial) {
          session.scopeTo(null);
          scopeNotice =
              'La portée est revenue à « Tout le projet » : la carte '
              '« ${entry.name} » n’a pas de réglages 3D locaux. Les brouillons '
              'restent conservés.';
        } else {
          session.scopeTo(entry.id);
          _watchMapDraft(document?.weatherVisuals);
        }
      }
    } on Object catch (failure) {
      if (current()) previewProblem = '$failure';
    } finally {
      if (current()) {
        previewLoading = false;
        _changed();
      }
    }
  }

  void _choosePreview(String id) {
    final entry = workspace.project?.maps.where((e) => e.id == id).firstOrNull;
    if (entry == null || entry.id == preview?.id) return;
    preview = entry;
    scopeNotice = null;
    unawaited(_loadPreview(entry));
  }

  void _chooseScope(String value) {
    scopeNotice = null;
    final id = value == 'map' && previewSpatial ? preview?.id : null;
    session.scopeTo(id);
    if (id != null) _watchMapDraft(workspace.documents[id]?.weatherVisuals);
  }

  Future<void> _startTest() async {
    final entry = preview;
    final builder = widget.testBuilder;
    final active = workspace.active;
    if (entry == null || builder == null || active == null) return;
    if (active.dirty) {
      setState(
        () => testError =
            'Enregistrez d’abord les modifications de la carte dans '
            'l’éditeur. Les réglages restent en aperçu.',
      );
      return;
    }
    setState(
      () => test = builder(entry, active.base.revision, () {
        if (mounted) setState(() => test = null);
      }, rendered),
    );
  }

  @override
  void dispose() {
    _previewGeneration++;
    session.removeListener(_changed);
    owner.removeListener(_changed);
    mapDraft?.removeListener(_changed);
    session.dispose();
    rendered.dispose();
    super.dispose();
  }

  bool _available(ProjectSettingsSection section) => switch (section) {
    ProjectSettingsSection.fieldAbilities =>
      widget.surfOwner != null || widget.csOwner != null,
    ProjectSettingsSection.sounds => widget.audioOwner != null,
    _ => true,
  };

  String get _scopeLabel => session.scopeMapId == null
      ? 'Tout le projet'
      : 'Carte « ${preview?.name ?? session.scopeMapId} »';

  Widget _scopePanel(ProjectSettingsSection section) {
    final maps = workspace.project?.maps ?? <ProjectMapEntry>[];
    return StudioPanel(
      title: 'Portée et aperçu',
      icon: Icons.visibility_outlined,
      children: [
        StudioSelect(
          key: const ValueKey('settings-preview-map'),
          label: 'Carte utilisée pour l’aperçu',
          value: preview?.id,
          options: {for (final entry in maps) entry.id: entry.name},
          onChanged: maps.isEmpty ? null : _choosePreview,
        ),
        const SizedBox(height: 4),
        Text(
          session.scopeMapId == null
              ? 'Ce choix ne change que l’aperçu : les modifications '
                    's’appliquent toujours à tout le projet.'
              : 'Les modifications visent la carte d’aperçu, comme une '
                    'dérogation locale à cette carte.',
        ),
        const SizedBox(height: 12),
        StudioSelect(
          key: const ValueKey('settings-scope'),
          label: 'Portée des modifications',
          value: session.scopeMapId == null ? 'project' : 'map',
          options: {
            'project': 'Tout le projet',
            if (previewSpatial && preview != null)
              'map': 'Cette carte uniquement : ${preview!.name}',
          },
          onChanged: previewLoading ? null : _chooseScope,
        ),
        if (scopeNotice case final notice?) ...[
          const SizedBox(height: 8),
          StudioNotice(notice),
        ],
        if (session.hasOtherScopeDraft(section)) ...[
          const SizedBox(height: 8),
          const StudioNotice(
            'Un brouillon « Tout le projet » de cette rubrique est conservé, '
            'non enregistré.',
          ),
        ],
        if (previewProblem case final problem?) ...[
          const SizedBox(height: 8),
          StudioNotice(problem),
        ],
        if (testError case final problem?) ...[
          const SizedBox(height: 8),
          StudioNotice(problem, isError: true),
        ],
        if (widget.testBuilder != null) ...[
          const SizedBox(height: 12),
          StudioButton(
            key: const ValueKey('test-project-visuals'),
            label: test == null ? 'Jouer dans cette carte' : 'Arrêter le test',
            icon: test == null ? Icons.play_arrow : Icons.stop,
            secondary: true,
            onPressed: previewLoading || (!previewSpatial && test == null)
                ? null
                : test == null
                ? _startTest
                : () => setState(() => test = null),
          ),
        ],
      ],
    );
  }

  Widget _visuals(ProjectSettingsSection section) {
    final scoped = session.scopedVisuals;
    if (scoped == null) {
      return const StudioNotice(
        'Les réglages de cette carte ne sont pas disponibles.',
      );
    }
    final inherited = session.scopeMapId == null
        ? base
        : base.overriddenBy(owner.preview.value);
    final image = section == ProjectSettingsSection.image;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _scopePanel(section),
        const SizedBox(height: 12),
        if (scoped.saved == null)
          const Center(child: CircularProgressIndicator())
        else
          SpatialVisualControls(
            key: ValueKey('settings-visuals-${section.name}'),
            patch: scoped.preview.value,
            inherited: inherited,
            camera: image,
            effects: image,
            clock: !image,
            weather: !image,
            onEditStart: scoped.beginGesture,
            onEditEnd: scoped.endGesture,
            onChanged: scoped.saving || scoped.loading ? null : scoped.edit,
          ),
      ],
    );
  }

  Widget _content(ProjectSettingsSection section) => switch (section) {
    ProjectSettingsSection.general => StudioPanel(
      title: 'Identité du jeu',
      icon: Icons.public,
      children: [
        Text('Projet : ${workspace.project?.name ?? workspace.session.name}'),
        const SizedBox(height: 8),
        const Text(
          'Le titre, l’auteur, la version du contenu et les langues du jeu se '
          'règlent pour l’instant dans la préparation de l’export.',
        ),
        if (widget.onOpenExport case final open?) ...[
          const SizedBox(height: 12),
          StudioButton(
            label: 'Ouvrir la préparation de l’export',
            icon: Icons.ios_share,
            secondary: true,
            onPressed: open,
          ),
        ],
      ],
    ),
    ProjectSettingsSection.fieldAbilities =>
      widget.csOwner != null && widget.surfOwner != null
          ? ProjectCsPanel(
              owner: widget.csOwner!,
              surf: widget.surfOwner!,
              settings: workspace.project!.settings,
              loadItems: widget.loadItems,
              showActions: false,
            )
          : widget.surfOwner != null
          ? ProjectSurfPanel(
              owner: widget.surfOwner!,
              loadItems: widget.loadItems,
              showActions: false,
            )
          : const StudioNotice(
              'Ce projet ne propose pas de capacités de terrain.',
            ),
    ProjectSettingsSection.image ||
    ProjectSettingsSection.timeWeather => _visuals(section),
    ProjectSettingsSection.sounds => switch (widget.audioOwner) {
      final audio? => ProjectAudioPanel(
        owner: audio,
        pickMedia: widget.pickMedia,
        showActions: false,
      ),
      null => const StudioNotice('Ce projet ne propose pas de sons.'),
    },
    ProjectSettingsSection.verification => StudioPanel(
      title: 'Vérifications et export',
      icon: Icons.fact_check_outlined,
      children: [
        const Text(
          'Les vérifications listent les points à examiner avant de tester '
          'ou d’exporter. L’export reste une action explicite : rien n’est '
          'préparé depuis cette page.',
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (widget.onOpenVerification case final open?)
              StudioButton(
                label: 'Ouvrir les vérifications',
                icon: Icons.fact_check_outlined,
                secondary: true,
                onPressed: open,
              ),
            if (widget.onOpenExport case final open?)
              StudioButton(
                label: 'Préparer l’export',
                icon: Icons.ios_share,
                secondary: true,
                onPressed: open,
              ),
          ],
        ),
      ],
    ),
  };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final compact = bounds.maxWidth < 900;
      final section = session.section;
      final body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compact)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ProjectSettingsNavigator(
                session: session,
                available: _available,
                compact: true,
              ),
            ),
          StudioPageHeader(
            key: ValueKey('settings-header-${section.name}'),
            title: section.label,
            description: section.summary,
          ),
          Expanded(
            child: SingleChildScrollView(
              key: PageStorageKey('settings-scroll-${section.name}'),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _content(section),
            ),
          ),
          ProjectSettingsSectionFooter(
            session: session,
            section: section,
            scopeLabel: _scopeLabel,
          ),
        ],
      );
      final main = test == null || !section.followsScope
          ? body
          : compact
          ? Column(
              children: [
                Expanded(child: test!),
                SizedBox(height: bounds.maxHeight * .5, child: body),
              ],
            )
          : Row(
              children: [
                Expanded(child: test!),
                SizedBox(width: 420, child: body),
              ],
            );
      if (compact) return main;
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 280,
            child: ProjectSettingsNavigator(
              session: session,
              available: _available,
              compact: false,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: main),
        ],
      );
    },
  );
}
