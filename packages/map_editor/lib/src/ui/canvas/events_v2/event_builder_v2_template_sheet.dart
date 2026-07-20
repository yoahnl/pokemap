import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../application/services/narrative_template_catalog.dart';
import '../../design_system/design_system.dart';
import '../scenes/scene_action_builder.dart';

typedef EventBuilderV2TemplateApply = Future<String?> Function(
  NarrativeTemplatePreview preview,
);

final class EventBuilderV2TemplateDraft {
  const EventBuilderV2TemplateDraft({
    required this.kind,
    required this.name,
    required this.parameters,
    required this.expectedValue,
  });

  final NarrativeTemplateKind kind;
  final String name;
  final Map<String, String> parameters;
  final String expectedValue;
}

/// No-code composition of one existing Map source, one Event and one Scene.
class EventBuilderV2TemplateSheet extends StatefulWidget {
  const EventBuilderV2TemplateSheet({
    super.key,
    required this.project,
    required this.eventId,
    required this.sceneId,
    required this.spatialSources,
    required this.actionPickerOptions,
    required this.onApply,
    required this.onOpenMapEditor,
    this.initialDraft,
    this.physicalSourceKinds = const {},
  });

  final ProjectManifest project;
  final String eventId;
  final String sceneId;
  final List<NarrativeSpatialEventSourceOption> spatialSources;
  final Map<NarrativeCommandParameterKind, List<SceneActionPickerOption>>
      actionPickerOptions;
  final EventBuilderV2TemplateApply onApply;
  final ValueChanged<EventBuilderV2TemplateDraft> onOpenMapEditor;
  final EventBuilderV2TemplateDraft? initialDraft;
  final Map<String, NarrativeTemplatePhysicalSourceKind> physicalSourceKinds;

  @override
  State<EventBuilderV2TemplateSheet> createState() =>
      _EventBuilderV2TemplateSheetState();
}

class _EventBuilderV2TemplateSheetState
    extends State<EventBuilderV2TemplateSheet> {
  final _catalog = NarrativeTemplateCatalog.canonical();
  late final TextEditingController _nameController;
  late NarrativeTemplateKind _kind;
  String? _sourceKey;
  String? _factId;
  String _expectedValue = 'true';
  SceneActionBuildResult? _action;
  NarrativeTemplatePreview? _preview;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _kind = widget.initialDraft?.kind ?? NarrativeTemplateKind.simpleNpc;
    _nameController = TextEditingController(
      text: widget.initialDraft?.name ?? _definition.label,
    );
    _expectedValue = widget.initialDraft?.expectedValue ?? 'true';
    _factId = widget.initialDraft?.parameters['factId'];
    _selectFirstCompatibleSource();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  NarrativeTemplateDefinition get _definition => _catalog.byKind(_kind);

  List<NarrativeSpatialEventSourceOption> get _compatibleSources {
    final expected = _definition.physicalSourceKind;
    return [
      for (final option in widget.spatialSources)
        if (option.selectable &&
            option.source != null &&
            (widget.physicalSourceKinds.isEmpty ||
                widget.physicalSourceKinds[_keyForSource(option)] ==
                    expected) &&
            switch (expected) {
              NarrativeTemplatePhysicalSourceKind.entity ||
              NarrativeTemplatePhysicalSourceKind.object =>
                option.ownerKind == NarrativeSpatialEventSourceOwnerKind.entity,
              NarrativeTemplatePhysicalSourceKind.zone ||
              NarrativeTemplatePhysicalSourceKind.warp =>
                option.ownerKind ==
                    NarrativeSpatialEventSourceOwnerKind.trigger,
              null => false,
            })
          option,
    ];
  }

  NarrativeSpatialEventSourceOption? get _selectedSource {
    final key = _sourceKey;
    if (key == null) return null;
    return _compatibleSources
        .cast<NarrativeSpatialEventSourceOption?>()
        .firstWhere(
          (option) => _keyForSource(option!) == key,
          orElse: () => null,
        );
  }

  void _selectFirstCompatibleSource() {
    final sources = _compatibleSources;
    _sourceKey = sources.isEmpty ? null : _keyForSource(sources.first);
  }

  @override
  Widget build(BuildContext context) {
    final definition = _definition;
    final sources = _compatibleSources;
    return ListView(
      key: const ValueKey('event-builder-v2-template-sheet'),
      padding: const EdgeInsets.all(16),
      children: [
        PokeMapDropdownField<NarrativeTemplateKind>(
          label: 'Gabarit narratif',
          value: _kind,
          items: [
            for (final template in _catalog.eventSceneTemplates)
              PokeMapDropdownItem(
                value: template.kind,
                label: template.isPublishable
                    ? template.label
                    : '${template.label} · Indisponible',
              ),
          ],
          onChanged: (value) {
            setState(() {
              _kind = value;
              _nameController.text = _definition.label;
              _action = null;
              _preview = null;
              _error = null;
              _selectFirstCompatibleSource();
            });
          },
        ),
        const SizedBox(height: 12),
        PokeMapTextField(
          key: const ValueKey('event-builder-v2-template-name'),
          label: 'Nom de la composition',
          controller: _nameController,
          enabled: !_saving,
          onChanged: (_) => setState(() => _preview = null),
        ),
        const SizedBox(height: 12),
        if (definition.physicalSourceKind != null && sources.isNotEmpty)
          PokeMapDropdownField<String>(
            label: 'Élément physique existant',
            value: _sourceKey ?? _keyForSource(sources.first),
            items: [
              for (final option in sources)
                PokeMapDropdownItem(
                  value: _keyForSource(option),
                  label: '${option.mapLabel} · ${option.humanLabel}',
                ),
            ],
            onChanged: (value) => setState(() {
              _sourceKey = value;
              _preview = null;
            }),
          )
        else if (definition.physicalSourceKind != null)
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.warning,
            title: 'Source physique manquante',
            message: 'Créez d’abord le PNJ, l’objet ou la zone dans le Map '
                'Editor, puis revenez reprendre ce gabarit.',
            actionLabel: 'Ouvrir le Map Editor',
            onAction: _openMapEditor,
          ),
        if (_kind == NarrativeTemplateKind.conditionalNpc) ...[
          const SizedBox(height: 12),
          if (widget.project.facts.isEmpty)
            const PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.warning,
              title: 'Fact manquant',
              message: 'Créez un Fact avant de publier ce PNJ conditionnel.',
            )
          else ...[
            PokeMapDropdownField<String>(
              label: 'Fact de condition',
              value: _factId ?? widget.project.facts.first.id,
              items: [
                for (final fact in widget.project.facts)
                  PokeMapDropdownItem(value: fact.id, label: fact.label),
              ],
              onChanged: (value) => setState(() {
                _factId = value;
                _preview = null;
              }),
            ),
            const SizedBox(height: 12),
            PokeMapDropdownField<String>(
              label: 'Valeur attendue',
              value: _expectedValue,
              items: const [
                PokeMapDropdownItem(value: 'true', label: 'Vrai'),
                PokeMapDropdownItem(value: 'false', label: 'Faux'),
              ],
              onChanged: (value) => setState(() {
                _expectedValue = value;
                _preview = null;
              }),
            ),
          ],
        ],
        const SizedBox(height: 16),
        SceneActionBuilder(
          key: ValueKey('template-action-${definition.kind.name}'),
          initialCommandId: definition.command.id,
          allowCommandSelection: false,
          pickerOptions: widget.actionPickerOptions,
          initialParameters: widget.initialDraft?.parameters ?? const {},
          onSubmit: (_) {},
          onSubmitResult: (result) => setState(() {
            _action = result;
            _preview = _buildPreview(result);
            _error = null;
          }),
        ),
        if (_preview case final preview?) ...[
          const SizedBox(height: 12),
          PokeMapDiagnosticCallout(
            key: const ValueKey('event-builder-v2-template-preview'),
            severity: preview.canApply
                ? PokeMapDiagnosticSeverity.info
                : PokeMapDiagnosticSeverity.warning,
            title: preview.canApply
                ? 'Prévisualisation prête'
                : 'Prévisualisation bloquée',
            message: preview.canApply
                ? '1 Event → 1 Scene → 1 commande. La map reste inchangée.'
                : preview.diagnostics.join(' '),
            actionLabel:
                preview.requiresMapEditor ? 'Ouvrir le Map Editor' : null,
            onAction: preview.requiresMapEditor ? _openMapEditor : null,
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            title: 'Création impossible',
            message: _error!,
          ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: PokeMapButton(
            key: const ValueKey('event-builder-v2-template-apply'),
            variant: PokeMapButtonVariant.primary,
            leading: _saving
                ? const CupertinoActivityIndicator()
                : const Icon(CupertinoIcons.check_mark_circled),
            onPressed: _preview?.canApply == true && !_saving ? _apply : null,
            child: Text(_saving ? 'Création…' : 'Créer Event + Scene'),
          ),
        ),
      ],
    );
  }

  NarrativeTemplatePreview _buildPreview(SceneActionBuildResult action) {
    final source = _selectedSource;
    final definition = _definition;
    final parameters = <String, String>{...action.parameters};
    if (_kind == NarrativeTemplateKind.conditionalNpc &&
        widget.project.facts.isNotEmpty) {
      parameters['factId'] = _factId ?? widget.project.facts.first.id;
      parameters['expectedValue'] = _expectedValue;
    }
    return previewNarrativeTemplate(
      project: widget.project,
      request: NarrativeTemplateRequest(
        kind: _kind,
        eventId: widget.eventId,
        sceneId: widget.sceneId,
        name: _nameController.text.trim(),
        source:
            source?.source ?? NarrativeEventSourceRef.mapEnter('__missing__'),
        physicalSource: source == null || definition.physicalSourceKind == null
            ? null
            : NarrativeTemplatePhysicalSource(
                kind: definition.physicalSourceKind!,
                mapId: source.mapId,
                sourceId: source.ownerId!,
                exists: true,
              ),
        parameters: parameters,
      ),
    );
  }

  Future<void> _apply() async {
    final preview = _preview;
    if (preview == null || !preview.canApply || _action == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await widget.onApply(preview);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error == null) Navigator.of(context).pop();
  }

  void _openMapEditor() {
    Navigator.of(context).pop();
    widget.onOpenMapEditor(
      EventBuilderV2TemplateDraft(
        kind: _kind,
        name: _nameController.text,
        parameters: <String, String>{
          ...?widget.initialDraft?.parameters,
          ...?_action?.parameters,
          if (_kind == NarrativeTemplateKind.conditionalNpc &&
              (_factId != null || widget.project.facts.isNotEmpty))
            'factId': _factId ?? widget.project.facts.first.id,
        },
        expectedValue: _expectedValue,
      ),
    );
  }
}

String _keyForSource(NarrativeSpatialEventSourceOption source) =>
    '${source.ownerKind.name}:${source.mapId}:${source.ownerId ?? ''}';
