import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../features/terrains/application/terrain_draft_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_palette_tabs.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import 'terrain_pattern_panel.dart';
import 'terrain_scratch_view.dart';
import 'terrain_source_panel.dart';
import 'terrain_trial_panel.dart';
import 'terrain_usage_summary.dart';
import '../../../features/terrains/domain/terrain_connections.dart';

import 'package:avelune_studio/platform/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/features/resources/application/resource_catalog.dart';

import '../resources/resource_preview.dart';

class TerrainEditorScreen extends StatefulWidget {
  const TerrainEditorScreen({
    super.key,
    required this.controller,
    required this.image,
    required this.frameBuilder,
    required this.onMutate,
    required this.onUse,
    required this.onClose,
    this.canPaint = true,
    this.visuals,
  });
  final TerrainDraftController controller;
  final Widget image;
  final TerrainFrameBuilder frameBuilder;
  final MutateTerrainResource onMutate;
  final ValueChanged<ProjectSmartTilePreset> onUse;
  final VoidCallback onClose;
  final bool canPaint;
  final MapWorkspaceVisuals? visuals;
  @override
  State<TerrainEditorScreen> createState() => _TerrainEditorScreenState();
}

class _TerrainEditorScreenState extends State<TerrainEditorScreen> {
  late final _name = TextEditingController(text: model.draft.name);
  final _transform = TransformationController();
  String _tool = 'Examiner';
  String _page = 'Préparer';
  bool _advance = false, _missingOnly = false;
  TilesetSourceRect? _selectedSource;
  TerrainDraftController get model => widget.controller;

  @override
  void dispose() {
    _name.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _refresh() {
    if (_name.text != model.draft.name) {
      _name.value = TextEditingValue(
        text: model.draft.name,
        selection: TextSelection.collapsed(offset: model.draft.name.length),
      );
    }
    setState(() {});
  }

  Future<void> _save(bool publish) async {
    final pending = model.save(widget.onMutate, publish: publish);
    setState(() {});
    final success = await pending;
    if (!mounted) return;
    setState(() {});
    if (success && publish) {
      final preset = model.publishedPreset;
      if (preset != null) widget.onUse(preset);
    }
  }

  void _assign(TilesetSourceRect rect) {
    _selectedSource = rect;
    model.assignSelectedFrame(rect, advanceMissing: _advance);
    setState(() {});
  }

  void _assignModel(ProjectModel3dEntry source) {
    model.assignSelectedModel(source, advanceMissing: _advance);
    setState(() {});
  }

  Widget _partPreview(SmartTileVisualPart part, double size) {
    final source = part.source;
    if (source is SmartTileFrameSource) {
      return widget.frameBuilder(source.frame, size);
    }
    if (source is SmartTileModel3dSource && widget.visuals != null) {
      final model = this.model.manifest.models3d
          .where((model) => model.id == source.modelId)
          .firstOrNull;
      if (model != null) {
        return resourcePreview(
          ResourceItem(
            id: model.id,
            name: model.name,
            kind: ResourceKind.decors,
            model3d: model,
          ),
          this.model.manifest,
          widget.visuals!,
          size: size,
        );
      }
    }
    return const StudioNotice('Aperçu indisponible');
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StudioPageHeader(
        title: model.draft.name,
        description:
            '${terrainUsageLabel(model.draft.usage)} · ${model.statusLabel} · ${model.assignedCount} / ${model.draft.rules.length} pièces associées',
        alignActionsToEnd: true,
        actions: [
          StudioButton(
            label: 'Ressources › Terrains',
            icon: Icons.arrow_back,
            secondary: true,
            onPressed: model.busy ? null : widget.onClose,
          ),
          StudioButton(
            label: 'Enregistrer le brouillon',
            icon: Icons.save_outlined,
            secondary: true,
            onPressed: model.busy ? null : () => _save(false),
          ),
          StudioButton(
            label: widget.canPaint
                ? 'Publier et peindre'
                : 'Publier dans Ressources',
            icon: Icons.brush_outlined,
            onPressed: model.busy || !model.complete ? null : () => _save(true),
          ),
        ],
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: TerrainUsageSummary(usage: model.draft.usage),
      ),
      if (model.error != null)
        StudioNotice(model.error!, isError: true, maxLines: 2),
      if (model.busy) const LinearProgressIndicator(),
      Expanded(
        child: AbsorbPointer(
          absorbing: model.busy,
          child: LayoutBuilder(
            builder: (context, bounds) {
              final compact =
                  bounds.maxWidth < 1000 ||
                  MediaQuery.textScalerOf(context).scale(14) > 20;
              final source = TerrainSourcePanel(
                model: model,
                name: _name,
                image: widget.image,
                transform: _transform,
                onChanged: () => setState(() {}),
                onAssign: _assign,
                selectedSource: _selectedSource,
                frameBuilder: widget.frameBuilder,
                visuals: widget.visuals,
                onAssignModel: _assignModel,
              );
              final rules = TerrainPatternPanel(
                model: model,
                frameBuilder: widget.frameBuilder,
                partBuilder: _partPreview,
                onChanged: _refresh,
                advance: _advance,
                onAdvance: (value) => setState(() => _advance = value),
                missingOnly: _missingOnly,
                onMissingOnly: (value) => setState(() => _missingOnly = value),
                selectedSource: _selectedSource,
              );
              final trial = TerrainTrialPanel(
                model: model,
                tool: _tool,
                onTool: (value) => setState(() => _tool = value),
                frameBuilder: widget.frameBuilder,
                visuals: widget.visuals,
                onChanged: () {
                  if (_tool == 'Examiner') _missingOnly = false;
                  setState(() {});
                },
              );
              final preparation = Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _scrollShortPanel(source)),
                  const SizedBox(width: 12),
                  Expanded(child: _scrollShortPanel(rules)),
                ],
              );
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (compact) ...[
                      StudioPaletteTabs(
                        items: const ['Préparer', 'Essayer'],
                        selected: _page,
                        onChanged: (value) => setState(() => _page = value),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Expanded(
                      child: compact
                          ? _page == 'Préparer'
                                ? preparation
                                : trial
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: preparation),
                                const SizedBox(width: 14),
                                SizedBox(
                                  width: (bounds.maxWidth * .3).clamp(320, 420),
                                  child: trial,
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ],
  );

  Widget _scrollShortPanel(Widget child) => LayoutBuilder(
    builder: (context, bounds) => bounds.maxHeight < 750
        ? SingleChildScrollView(child: SizedBox(height: 950, child: child))
        : child,
  );
}
