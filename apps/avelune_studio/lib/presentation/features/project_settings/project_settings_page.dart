import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/map_workspace/application/map_workspace_controller.dart';
import '../../../features/map_workspace/domain/map_atmosphere_port.dart';
import '../../../features/project_visuals/application/project_visuals_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import '../../shared/widgets/layout/studio_panel.dart';
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
  });
  final MapWorkspaceController workspace;
  final ProjectVisualsController owner;
  final StudioVisualTestBuilder? testBuilder;
  @override
  State<ProjectSettingsPage> createState() => _ProjectSettingsPageState();
}

class _ProjectSettingsPageState extends State<ProjectSettingsPage> {
  ProjectVisualsController get owner => widget.owner;
  final rendered = ValueNotifier(SpatialVisualPatch());
  SpatialVisualPatch base = SpatialVisualPatch.fromScene(
    camera: SpatialCameraProfile(),
    atmosphere: SpatialAtmosphereSettings(),
  );
  SpatialVisualPatch project = SpatialVisualPatch(),
      local = SpatialVisualPatch();
  ProjectMapEntry? selected;
  bool localScope = false, opening = false;
  Widget? test;
  String? error;
  (String?, String)? _applied;
  @override
  void initState() {
    super.initState();
    owner.addListener(changed);
    final maps = widget.workspace.project?.maps ?? <ProjectMapEntry>[];
    selected =
        maps
            .where((e) => e.id == widget.workspace.active?.base.mapId)
            .firstOrNull ??
        maps.firstOrNull;
    localScope = owner.scope != null;
    unawaited(load(preserve: owner.saved != null));
  }

  SpatialVisualPatch get inherited =>
      localScope ? base.overriddenBy(project) : base;
  void changed() {
    final saved = owner.saved;
    if (saved != null && _applied != (owner.scope?.id, saved.revision)) {
      _applied = (owner.scope?.id, saved.revision);
      widget.workspace.acceptVisualProfile(
        saved.profile,
        mapId: owner.scope?.id,
      );
    }
    rendered.value = localScope
        ? inherited.overriddenBy(owner.preview.value)
        : base.overriddenBy(owner.preview.value).overriddenBy(local);
    if (mounted) setState(() {});
  }

  Future<void> load({bool preserve = false}) async {
    setState(() {
      opening = true;
      error = null;
      test = null;
    });
    try {
      final workspace = widget.workspace;
      final port = owner.port;
      project = (await port.loadVisuals(workspace.session)).profile;
      if (selected case final entry?) {
        await workspace.activate(entry);
        final scene = workspace.active?.current.spatialScene;
        final source = workspace.port;
        final atmosphere = source is MapAtmospherePort
            ? (await (source as MapAtmospherePort).loadAtmosphere(
                workspace.session,
                entry.id,
              )).settings
            : SpatialAtmosphereSettings();
        if (scene == null) {
          throw StateError('Choisissez une carte 3D pour tester les effets.');
        }
        base = SpatialVisualPatch.fromScene(
          camera: scene.camera,
          atmosphere: atmosphere,
          cycle: scene.dayNightCycle,
        );
        local = (await port.loadVisuals(workspace.session, map: entry)).profile;
      }
      if (!preserve) await owner.open(map: localScope ? selected : null);
      changed();
    } on Object catch (failure) {
      if (mounted) setState(() => error = '$failure');
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  Future<bool> keepDraft() async {
    if (!owner.dirty) return true;
    return owner.save();
  }

  Future<void> select(String id) async {
    if (!await keepDraft() || !mounted) return;
    selected = widget.workspace.project!.maps.firstWhere((e) => e.id == id);
    await load();
  }

  Future<void> scope(String value) async {
    if (!await keepDraft() || !mounted) return;
    localScope = value == 'map';
    await load();
  }

  Future<void> startTest() async {
    final entry = selected;
    final builder = widget.testBuilder;
    if (entry == null || builder == null || widget.workspace.active == null) {
      return;
    }
    if (widget.workspace.active!.dirty) {
      setState(
        () => error = 'Enregistrez d’abord les modifications de la carte dans l’éditeur. Les curseurs d’ambiance peuvent rester en aperçu.',
      );
      return;
    }
    setState(
      () => test = builder(entry, widget.workspace.active!.base.revision, () {
        if (mounted) setState(() => test = null);
      }, rendered),
    );
  }

  @override
  void dispose() {
    owner.removeListener(changed);
    rendered.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final workspace = widget.workspace;
    final settings = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioPanel(
          title: 'Réglages du projet',
          icon: Icons.tune,
          children: [
            const Text(
              'Réglez le rendu en direct, jouez dans la scène choisie, puis enregistrez ce que vous souhaitez garder.',
            ),
            const SizedBox(height: 12),
            StudioSelect(
              label: 'Scène à tester',
              value: selected?.id,
              options: {
                for (final entry
                    in workspace.project?.maps ?? <ProjectMapEntry>[])
                  entry.id: entry.name,
              },
              onChanged: opening || owner.saving ? null : select,
            ),
            const SizedBox(height: 12),
            StudioSelect(
              label: 'Appliquer les réglages à',
              value: localScope ? 'map' : 'project',
              options: {
                'project': 'Tout le projet',
                if (selected != null) 'map': 'Cette carte uniquement',
              },
              onChanged: opening || owner.saving ? null : scope,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StudioButton(
                  key: const ValueKey('save-project-visuals'),
                  label: owner.saving
                      ? 'Enregistrement…'
                      : 'Enregistrer les réglages',
                  icon: Icons.save_outlined,
                  loading: owner.saving,
                  onPressed: opening || !owner.dirty ? null : owner.save,
                ),
                StudioButton(
                  label: 'Annuler les modifications',
                  secondary: true,
                  onPressed: opening || !owner.dirty || owner.saving
                      ? null
                      : owner.discard,
                ),
                StudioButton(
                  label: 'Annuler',
                  icon: Icons.undo,
                  secondary: true,
                  onPressed: owner.canUndo && !owner.saving ? owner.undo : null,
                ),
                StudioButton(
                  label: 'Rétablir',
                  icon: Icons.redo,
                  secondary: true,
                  onPressed: owner.canRedo && !owner.saving ? owner.redo : null,
                ),
                StudioButton(
                  key: const ValueKey('test-project-visuals'),
                  label: test == null
                      ? 'Jouer dans cette scène'
                      : 'Arrêter le test',
                  icon: test == null ? Icons.play_arrow : Icons.stop,
                  secondary: true,
                  onPressed: opening || widget.testBuilder == null
                      ? null
                      : test == null
                      ? startTest
                      : () => setState(() => test = null),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              owner.dirty ? 'Aperçu non enregistré' : 'Réglages enregistrés · les champs hérités gardent leur source',
            ),
            if (owner.lastSaveMicroseconds case final micros?)
              Text(
                'Dernier enregistrement : ${(micros / 1000).toStringAsFixed(1)} ms',
              ),
            if (error ?? owner.error case final problem?)
              Text(
                problem,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (opening)
          const Center(child: CircularProgressIndicator())
        else
          SpatialVisualControls(
            patch: owner.preview.value,
            inherited: inherited,
            onEditStart: owner.beginGesture,
            onEditEnd: owner.endGesture,
            onChanged: owner.saving || owner.saved == null ? null : owner.edit,
          ),
      ],
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: StudioTabs<String>(
            items: const {'settings': 'Réglages', 'test': 'Test en jeu'},
            selected: test == null ? 'settings' : 'test',
            onChanged: (value) {
              if (opening) return;
              if (value == 'test' && test == null) {
                unawaited(startTest());
              } else if (value == 'settings') {
                setState(() => test = null);
              }
            },
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, bounds) {
              final controls = SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: settings,
              );
              if (test == null) return controls;
              if (bounds.maxWidth < 850) {
                return Column(
                  children: [
                    Expanded(child: test!),
                    SizedBox(height: bounds.maxHeight * .45, child: controls),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: test!),
                  SizedBox(width: 370, child: controls),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
