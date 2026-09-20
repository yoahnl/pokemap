import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../../features/terrains/application/terrain_draft_controller.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_notice.dart';
import '../../shared/widgets/inputs/studio_palette_tabs.dart';
import '../../shared/widgets/layout/studio_page_header.dart';
import 'terrain_rules_panel.dart';
import 'terrain_scratch_view.dart';
import 'terrain_source_panel.dart';
import 'terrain_trial_panel.dart';

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
  });
  final TerrainDraftController controller;
  final Widget image;
  final TerrainFrameBuilder frameBuilder;
  final MutateTerrainResource onMutate;
  final ValueChanged<ProjectSmartTilePreset> onUse;
  final VoidCallback onClose;
  final bool canPaint;
  @override
  State<TerrainEditorScreen> createState() => _TerrainEditorScreenState();
}

class _TerrainEditorScreenState extends State<TerrainEditorScreen> {
  late final _name = TextEditingController(text: model.draft.name);
  final _transform = TransformationController();
  String _tool = 'Examiner';
  String _page = 'Préparer';
  bool _advance = false, _missingOnly = false;
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
      final preset = model.manifest.smartTileCatalog.presets
          .where((preset) => preset.id == model.draft.targetPresetId)
          .firstOrNull;
      if (preset != null) widget.onUse(preset);
    }
  }

  void _assign(TilesetSourceRect rect) {
    final wasMissing = model.frameFor(model.selectedRule) == null;
    model.assign(rect.x, rect.y);
    if (_advance && wasMissing) model.selectNextMissing();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      StudioPageHeader(
        title: model.draft.name,
        description:
            'Terrain automatique · ${model.statusLabel} · ${model.assignedCount} / 16 raccords associés',
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
              );
              final rules = TerrainRulesPanel(
                model: model,
                frameBuilder: widget.frameBuilder,
                onChanged: _refresh,
                advance: _advance,
                onAdvance: (value) => setState(() => _advance = value),
                missingOnly: _missingOnly,
                onMissingOnly: (value) => setState(() => _missingOnly = value),
              );
              final trial = TerrainTrialPanel(
                model: model,
                tool: _tool,
                onTool: (value) => setState(() => _tool = value),
                frameBuilder: widget.frameBuilder,
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
    builder: (context, bounds) => bounds.maxHeight < 540
        ? SingleChildScrollView(child: SizedBox(height: 700, child: child))
        : child,
  );
}
