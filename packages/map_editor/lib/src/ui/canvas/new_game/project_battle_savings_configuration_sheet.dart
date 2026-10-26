import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../application/authoring_api/battle_savings_authoring_gateway.dart';
import '../../../features/editor/state/editor_notifier.dart';
import '../../design_system/design_system.dart';

class ProjectBattleSavingsConfigurationSheet extends ConsumerWidget {
  const ProjectBattleSavingsConfigurationSheet({
    super.key,
    this.saveConfiguration,
  });

  final Future<ProjectManifest> Function(
    String projectRoot,
    ProjectManifest project,
    ProjectBattleSavingsConfig? configuration,
  )?
  saveConfiguration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorNotifierProvider);
    final project = editor.project;
    final root = editor.projectRootPath;
    if (project == null || root == null || root.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Projet indisponible',
        description: 'Chargez un projet pour configurer son épargne.',
        icon: Icon(Icons.folder_open_rounded),
      );
    }
    return ProjectBattleSavingsConfigurationForm(
      project: project,
      onSave: (configuration) async {
        final saved =
            await (saveConfiguration?.call(root, project, configuration) ??
                BattleSavingsAuthoringGateway().save(
                  root,
                  project: project,
                  configuration: configuration,
                ));
        final current = ref.read(editorNotifierProvider).project;
        if (current == null ||
            ref.read(editorNotifierProvider).projectRootPath != root) {
          return true;
        }
        return ref
            .read(editorNotifierProvider.notifier)
            .acceptCanonicalBattleSavingsConfiguration(
              saved.battleSavings,
              projectRootPath: root,
              previousConfiguration: project.battleSavings,
            );
      },
    );
  }
}

class ProjectBattleSavingsConfigurationForm extends StatefulWidget {
  const ProjectBattleSavingsConfigurationForm({
    super.key,
    required this.project,
    required this.onSave,
  });

  final ProjectManifest project;
  final Future<bool> Function(ProjectBattleSavingsConfig?) onSave;

  @override
  State<ProjectBattleSavingsConfigurationForm> createState() =>
      _ProjectBattleSavingsConfigurationFormState();
}

class _ProjectBattleSavingsConfigurationFormState
    extends State<ProjectBattleSavingsConfigurationForm> {
  late String _enabledFactId;
  late String _balanceFactId;
  final _percentage = TextEditingController();
  final _maximum = TextEditingController();
  bool _saving = false;
  String? _error;
  bool _saved = false;

  void _load() {
    final config = widget.project.battleSavings;
    _enabledFactId = config?.enabledFactId ?? '';
    _balanceFactId = config?.balanceFactId ?? '';
    _percentage.text = '${config?.percentage ?? 25}';
    _maximum.text = '${config?.maximumBalance ?? 999999}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(
    covariant ProjectBattleSavingsConfigurationForm oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (!_saving &&
        oldWidget.project.battleSavings != widget.project.battleSavings) {
      _load();
    }
  }

  @override
  void dispose() {
    _percentage.dispose();
    _maximum.dispose();
    super.dispose();
  }

  Widget _picker({
    required String label,
    required String value,
    required NarrativeValueKind kind,
    required Key fieldKey,
    required ValueChanged<String> onChanged,
  }) {
    final facts = widget.project.facts
        .where((fact) => fact.valueKind == kind)
        .toList();
    return PokeMapDropdownField<String>(
      key: fieldKey,
      label: label,
      value: value,
      enabled: !_saving,
      items: [
        PokeMapDropdownItem(
          value: '',
          label: kind == NarrativeValueKind.boolean
              ? 'Aucune épargne'
              : 'Choisir un compteur',
        ),
        if (value.isNotEmpty && !facts.any((fact) => fact.id == value))
          PokeMapDropdownItem(value: value, label: 'Indicateur indisponible'),
        for (final fact in facts)
          PokeMapDropdownItem(value: fact.id, label: fact.label),
      ],
      onChanged: (value) => setState(() {
        onChanged(value);
        _error = null;
        _saved = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      PokeMapPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Épargne des gains de combat'),
            const SizedBox(height: 8),
            const Text(
              'Une part des gains positifs est mise de côté lorsque l’indicateur choisi est actif. Le reste rejoint le portefeuille. Le compteur de réserve est conservé avec la sauvegarde.',
            ),
            const SizedBox(height: 16),
            _picker(
              label: 'Épargne active quand',
              value: _enabledFactId,
              kind: NarrativeValueKind.boolean,
              fieldKey: const ValueKey('battle-savings-enabled-picker'),
              onChanged: (value) => _enabledFactId = value,
            ),
            if (_enabledFactId.isNotEmpty) ...[
              const SizedBox(height: 12),
              _picker(
                label: 'Compteur de réserve',
                value: _balanceFactId,
                kind: NarrativeValueKind.integer,
                fieldKey: const ValueKey('battle-savings-balance-picker'),
                onChanged: (value) => _balanceFactId = value,
              ),
              const SizedBox(height: 12),
              PokeMapTextField(
                label: 'Part épargnée (%)',
                controller: _percentage,
                keyboardType: TextInputType.number,
                enabled: !_saving,
              ),
              const SizedBox(height: 12),
              PokeMapTextField(
                label: 'Plafond de la réserve',
                controller: _maximum,
                keyboardType: TextInputType.number,
                enabled: !_saving,
              ),
              const SizedBox(height: 12),
              const Text(
                'Le versement est arrondi à l’entier inférieur. Quand la réserve atteint son plafond, seul le montant réellement mis de côté est déduit.',
              ),
            ],
          ],
        ),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.error,
            message: _error!,
          ),
        ),
      if (_saved)
        const Padding(
          padding: EdgeInsets.only(top: 12),
          child: PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.info,
            message: 'Épargne sauvegardée.',
          ),
        ),
      const SizedBox(height: 16),
      PokeMapButton(
        key: const ValueKey('battle-savings-save'),
        onPressed: _saving ? null : _save,
        child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
      ),
    ],
  );

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _saved = false;
    });
    try {
      ProjectBattleSavingsConfig? config;
      if (_enabledFactId.isNotEmpty) {
        final percentage = int.tryParse(_percentage.text);
        final maximum = int.tryParse(_maximum.text);
        if (percentage == null || maximum == null) {
          throw const FormatException(
            'Saisissez un pourcentage et un plafond entiers.',
          );
        }
        config = ProjectBattleSavingsConfig(
          enabledFactId: _enabledFactId,
          balanceFactId: _balanceFactId,
          percentage: percentage,
          maximumBalance: maximum,
        );
        config.validate(widget.project.facts);
      }
      final saved = await widget.onSave(config);
      if (mounted) {
        setState(() {
          _saved = saved;
          if (!saved) _error = 'La configuration n’a pas été enregistrée.';
        });
      }
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
