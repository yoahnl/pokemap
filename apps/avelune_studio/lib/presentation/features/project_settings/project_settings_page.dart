import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../platform/playtest/studio_playtest_builders.dart';

export '../../../platform/playtest/studio_playtest_builders.dart'
    show StudioVisualTestBuilder;

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../../features/project_audio/application/project_audio_controller.dart';
import '../../../features/project_cs/application/project_cs_controller.dart';
import '../../../features/project_settings/application/project_identity_controller.dart';
import '../../../features/project_settings/application/project_settings_session_controller.dart';
import '../../../features/project_settings/application/project_settings_preview_controller.dart';
import '../../../features/project_settings/application/project_verification_overview.dart';
import '../../../features/verification/application/studio_failure_diagnosis.dart';
import '../../../features/project_surf/application/project_surf_controller.dart';
import '../../../features/project_visuals/application/project_visuals_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'package:avelune_studio/features/presentations/domain/presentation_media_picker.dart';
export 'project_settings_navigator.dart' show ProjectSettingsSectionLabels;

import 'project_audio_panel.dart';
import 'project_cs_panel.dart';
import 'project_general_panel.dart';
import 'project_settings_navigator.dart';
import 'project_settings_section_footer.dart';
import 'project_surf_panel.dart';
import 'project_verification_panel.dart';
import 'spatial_visual_controls.dart';

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
    this.identity,
    this.initialSection = ProjectSettingsSection.general,
    this.onOpenOwner,
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
  final ProjectIdentityController? identity;
  final ProjectSettingsSection initialSection;
  final ValueChanged<StudioFailureOwner>? onOpenOwner;
  @override
  State<ProjectSettingsPage> createState() => _ProjectSettingsPageState();
}

class _ProjectSettingsPageState extends State<ProjectSettingsPage> {
  ProjectVisualsController get owner => widget.owner;
  MapWorkspaceController get workspace => widget.workspace;
  late final ProjectSettingsSessionController session;
  late final ProjectSettingsPreviewController _previewController;
  ValueNotifier<SpatialVisualPatch> get rendered => _previewController.rendered;
  SpatialVisualPatch get base => _previewController.base;
  ProjectMapEntry? get preview => _previewController.preview;
  ProjectVisualsController? get mapDraft => _previewController.mapDraft;
  bool get previewLoading => _previewController.previewLoading;
  bool get previewSpatial => _previewController.previewSpatial;
  bool get showSaved => _previewController.showSaved;
  String? get previewProblem => _previewController.previewProblem;
  String? get scopeNotice => _previewController.scopeNotice;
  String? get testError => _previewController.testError;
  Widget? test;
  bool _refreshScheduled = false;

  @override
  void initState() {
    super.initState();
    session = ProjectSettingsSessionController(
      projectVisuals: owner,
      mapVisuals: _mapVisuals,
      fieldAbilities: widget.csOwner,
      surf: widget.surfOwner,
      audio: widget.audioOwner,
      general: switch (widget.identity) {
        final identity? => IdentitySettingsDraft(identity),
        null => null,
      },
      initialSection: widget.initialSection,
    );
    _previewController = ProjectSettingsPreviewController(
      workspace: workspace,
      owner: owner,
      session: session,
    );
    _previewController.addListener(_changed);
    if (widget.identity case final identity?
        when !identity.ready && !identity.loading) {
      unawaited(identity.open());
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_previewController.start());
    });
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
    if (previewLoading) test = null;
    setState(() {});
  }

  void _choosePreview(String id) =>
      unawaited(_previewController.choosePreview(id));

  void _chooseScope(String value) => _previewController.chooseScope(value);

  Future<void> _startTest() async {
    final builder = widget.testBuilder;
    if (builder == null) return;
    final launch = _previewController.preparePlaytest();
    if (launch == null) return;
    setState(
      () => test = builder(launch.entry, launch.revision, () {
        if (mounted) setState(() => test = null);
      }, rendered),
    );
  }

  @override
  void dispose() {
    _previewController.removeListener(_changed);
    _previewController.dispose();
    session.dispose();
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
        if (owner.dirty || mapDraft?.dirty == true) ...[
          const SizedBox(height: 12),
          Text('Aperçu en jeu', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          StudioTabs<bool>(
            key: const ValueKey('settings-preview-compare'),
            items: const {false: 'Brouillon', true: 'Mémorisé'},
            selected: showSaved,
            onChanged: (value) {
              _previewController.compareSaved(value);
            },
          ),
          const SizedBox(height: 4),
          Text(
            showSaved
                ? 'L’aperçu montre les valeurs enregistrées, sans le brouillon.'
                : 'L’aperçu montre le brouillon non enregistré.',
          ),
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

  String _provenance(
    ProjectVisualsController scoped,
    SpatialVisualParameter parameter,
  ) {
    final own = scoped.preview.value.value(parameter) != null;
    if (session.scopeMapId != null) {
      return own ? 'Propre à cette carte' : 'Suit le projet';
    }
    if (own) return 'Défini par le projet';
    return preview == null
        ? 'Valeur propre à chaque carte'
        : 'Valeur propre à chaque carte · ici ${preview!.name}';
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
            invalidInputs: Map.unmodifiable(scoped.invalidInputs),
            onInvalidInput: (parameter, text) => text == null
                ? scoped.clearInvalid(parameter)
                : scoped.reportInvalid(parameter, text),
            provenance: (parameter) => _provenance(scoped, parameter),
            onChanged: scoped.saving || scoped.loading ? null : scoped.edit,
          ),
      ],
    );
  }

  Widget _content(ProjectSettingsSection section) => switch (section) {
    ProjectSettingsSection.general => switch (widget.identity) {
      final identity? => ProjectGeneralPanel(
        identity: identity,
        onOpenExport: widget.onOpenExport,
      ),
      null => StudioPanel(
        title: 'Identité du jeu',
        icon: Icons.public,
        children: [
          Text('Projet : ${workspace.project?.name ?? workspace.session.name}'),
          const SizedBox(height: 8),
          const Text(
            'L’identité du jeu n’est pas modifiable ici pour ce projet : '
            'l’export n’est pas disponible dans cette session.',
          ),
        ],
      ),
    },
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
    ProjectSettingsSection.verification => ProjectVerificationPanel(
      rows: projectVerificationOverview(
        sectionLabels: {
          for (final value in ProjectSettingsSection.values) value: value.label,
        },
        blocked: {
          for (final value in ProjectSettingsSection.values)
            if (session.draft(value)?.blocked == true) value,
        },
        dirty: session.dirtySections,
        newGame: workspace.homeNewGame,
        mapNames: {
          for (final map in workspace.project?.maps ?? <ProjectMapEntry>[])
            map.id: map.name,
        },
        threeD:
            workspace.project?.settings.dimension == ProjectDimension.threeD,
      ),
      onSelectSection: session.select,
      onOpenOwner: widget.onOpenOwner,
      onOpenVerification: widget.onOpenVerification,
      onOpenExport: widget.onOpenExport,
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
              key: ValueKey('settings-scroll-${section.name}'),
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
