import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../../features/rendering/contracts/map_workspace_visuals.dart';
import '../../../features/resources/application/border_workshop_assembly.dart';
import '../../../features/resources/application/border_workshop_draft_input.dart';
import '../../../features/resources/application/project_resource_library.dart';
import '../../../features/resources/domain/project_border_workshop_port.dart';
import '../../../features/resources/domain/resource_port.dart';
import 'project_border_workshop_draft_fields.dart';
import 'project_border_workshop_preview.dart';

part 'project_border_workshop_editing.dart';

typedef _BorderWorkshopView = ({ProjectManifest project, String? revision});

class ProjectBorderWorkshop extends StatefulWidget {
  const ProjectBorderWorkshop({
    super.key,
    required this.item,
    required this.loadProject,
    required this.visuals,
    required this.onBack,
    this.editor,
    this.onUpdated,
    this.onBusyChanged,
    this.pendingReceipt,
    this.onPendingReceiptChanged,
    this.onDraftChanged,
  });

  final ProjectLibraryItem item;
  final Future<ProjectManifest> Function() loadProject;
  final MapWorkspaceVisuals? visuals;
  final VoidCallback onBack;
  final ProjectBorderWorkshopPort? editor;
  final Future<void> Function(ResourceMutationReceipt)? onUpdated;
  final ValueChanged<bool>? onBusyChanged;
  final ResourceMutationReceipt? pendingReceipt;
  final ValueChanged<ResourceMutationReceipt?>? onPendingReceiptChanged;
  final ValueChanged<bool>? onDraftChanged;

  @override
  State<ProjectBorderWorkshop> createState() => _ProjectBorderWorkshopState();
}

class _ProjectBorderWorkshopState extends State<ProjectBorderWorkshop> {
  late Future<_BorderWorkshopView> _reading;
  _BorderWorkshopView? _lastSaved;
  final _assemblies = <bool, BorderWorkshopAssembly>{};
  BorderWorkshopDraftInput? _input;
  ResourceMutationReceipt? _pendingReceipt;
  String? _problem, _status;
  var _saving = false;
  var _reopenRequired = false;
  var _draft = false;

  ProjectBorderWorkshopPort? get _editor {
    final editor = widget.editor;
    return editor?.canEditBorderWorkshop == true ? editor : null;
  }

  bool get _hasUnappliedDraft =>
      _input?.hasChanges == true && _pendingReceipt == null;

  void _update(VoidCallback change) {
    final previous = _hasUnappliedDraft;
    setState(change);
    if (_hasUnappliedDraft != previous) {
      widget.onDraftChanged?.call(_hasUnappliedDraft);
    }
  }

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void didUpdateWidget(ProjectBorderWorkshop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.item.identity != oldWidget.item.identity ||
        !identical(widget.editor, oldWidget.editor)) {
      _read();
    }
  }

  void _read() {
    final editor = _editor;
    _reading = editor == null
        ? Future.sync(
            () async => (project: await widget.loadProject(), revision: null),
          )
        : Future.sync(() => editor.readWorkshopBorder(widget.item.id));
    _lastSaved = null;
    _assemblies.clear();
    _input = null;
    _pendingReceipt = widget.pendingReceipt;
    _status = _problem = null;
    _saving = false;
    _reopenRequired = false;
    _draft = _pendingReceipt != null;
    if (_draft) _problem = _pendingBorderReadMessage;
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: StudioSpacing.xl,
          vertical: StudioSpacing.l,
        ),
        child: Wrap(
          spacing: StudioSpacing.l,
          runSpacing: StudioSpacing.m,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            StudioButton(
              label: 'Retour à la bibliothèque',
              icon: Icons.arrow_back,
              onPressed: _saving ? null : _leave,
              variant: StudioButtonVariant.quiet,
            ),
            Text('Bordures', style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
      const Divider(height: 1),
      Expanded(
        child: FutureBuilder<_BorderWorkshopView>(
          future: _reading,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(
                  semanticsLabel: 'Chargement de la bordure',
                ),
              );
            }
            if (snapshot.hasError) {
              return StudioEmptyState(
                title: 'Lecture de la bordure impossible',
                description:
                    'Vérifiez que sa fiche et ses pièces sont disponibles.',
                action: StudioButton(
                  label: 'Réessayer',
                  onPressed: () => setState(_read),
                ),
              );
            }
            final read = _lastSaved ?? snapshot.data!;
            final record = read.project.borderCatalog.recordById(
              widget.item.id,
            );
            if (record == null) {
              return const StudioEmptyState(
                title: 'Bordure introuvable',
                description:
                    'Actualisez la bibliothèque pour retrouver sa fiche.',
              );
            }
            return _content(context, read, record);
          },
        ),
      ),
    ],
  );

  Widget _content(
    BuildContext context,
    _BorderWorkshopView read,
    BorderBlueprintRecord record,
  ) {
    final project = read.project;
    final published = record.latestPublished;
    final showDraft = _draft || published == null;
    final definition = showDraft
        ? record.draft.definition
        : published.definition;
    final assembly = _assemblies.putIfAbsent(
      showDraft,
      () => buildBorderWorkshopAssembly(project, record, draft: showDraft),
    );
    final editor = _editor;
    final revision = read.revision;
    return ListView(
      padding: const EdgeInsets.all(StudioSpacing.xl),
      children: [
        Text(definition.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: StudioSpacing.m),
        Wrap(
          spacing: StudioSpacing.s,
          runSpacing: StudioSpacing.s,
          children: [
            StudioBadge(definition.isSpatial ? '3D' : '2D'),
            if (published == null) const StudioBadge('Brouillon'),
            if (record.isDeprecated) const StudioBadge('Retirée'),
          ],
        ),
        if (published != null) ...[
          const SizedBox(height: StudioSpacing.l),
          StudioTabBar<bool>(
            selected: showDraft,
            onSelected: (value) => setState(() => _draft = value),
            tabs: [
              StudioTab(
                value: false,
                label: 'Publiée · v${published.revision}',
                enabled: !_saving,
              ),
              StudioTab(value: true, label: 'Brouillon', enabled: !_saving),
            ],
          ),
        ],
        const SizedBox(height: StudioSpacing.l),
        ProjectBorderWorkshopPreview(
          key: ValueKey(showDraft),
          assembly: assembly,
          visuals: widget.visuals,
        ),
        if (showDraft &&
            editor != null &&
            revision != null &&
            supportsBorderWorkshopDraft(record)) ...[
          const SizedBox(height: StudioSpacing.l),
          _draftFields(read, record, editor, revision),
        ],
      ],
    );
  }
}
