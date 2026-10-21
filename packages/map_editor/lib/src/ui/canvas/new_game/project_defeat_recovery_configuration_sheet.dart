import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';

import '../../../app/providers/core/repository_providers.dart';
import '../../../features/editor/state/editor_notifier.dart';
import '../../design_system/design_system.dart';

const projectDefeatRecoveryLauncherKey = ValueKey<String>(
  'project-defeat-recovery-launcher',
);

class ProjectDefeatRecoveryConfigurationSheet extends ConsumerWidget {
  const ProjectDefeatRecoveryConfigurationSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(editorNotifierProvider);
    final project = editor.project;
    final root = editor.projectRootPath?.trim();
    if (project == null || root == null || root.isEmpty) {
      return const PokeMapEmptyState(
        title: 'Projet indisponible',
        description:
            'Chargez un projet pour configurer son retour après une défaite.',
        icon: Icon(Icons.folder_open_rounded),
      );
    }
    return ProjectDefeatRecoveryConfigurationForm(
      project: project,
      onSave: (config) async {
        final queries = ref.read(authoringQueryAdapterProvider);
        await queries.invalidate(root);
        final before = await queries.open(root);
        if (before.manifest != ref.read(editorNotifierProvider).project) {
          throw StateError(
            'Le projet a changé. Rechargez sa configuration avant de continuer.',
          );
        }
        final operation =
            'editor_defeat_recovery_${DateTime.now().microsecondsSinceEpoch}';
        final mutations = ref.read(authoringMutationAdapterProvider);
        final plan = await mutations.plan(
          root,
          actionId: 'campaign.defeat_recovery.update',
          parameters: {'defeatRecovery': config?.toJson()},
          idempotencyKey: operation,
          requestId: operation,
          expectedRevision: before.snapshotRevision,
        );
        await mutations.apply(plan, operationId: operation);
        await queries.invalidate(root);
        ref
            .read(editorNotifierProvider.notifier)
            .acceptCanonicalProjectManifest(
              (await queries.open(root)).manifest,
              statusMessage: 'Retour après défaite sauvegardé.',
            );
        return true;
      },
    );
  }
}

class ProjectDefeatRecoveryConfigurationForm extends StatefulWidget {
  const ProjectDefeatRecoveryConfigurationForm({
    super.key,
    required this.project,
    required this.onSave,
  });

  final ProjectManifest project;
  final Future<bool> Function(ProjectDefeatRecoveryConfig? config) onSave;

  @override
  State<ProjectDefeatRecoveryConfigurationForm> createState() =>
      _ProjectDefeatRecoveryConfigurationFormState();
}

class _ProjectDefeatRecoveryConfigurationFormState
    extends State<ProjectDefeatRecoveryConfigurationForm> {
  late String _factId;
  bool _saving = false;
  String? _error;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _factId = widget.project.defeatRecovery?.recoveredFactId ?? '';
  }

  @override
  void didUpdateWidget(
    covariant ProjectDefeatRecoveryConfigurationForm oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project != widget.project && !_saving) {
      _factId = widget.project.defeatRecovery?.recoveredFactId ?? '';
      _error = null;
      _saved = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final facts = widget.project.facts
        .where((fact) => fact.valueKind == NarrativeValueKind.boolean)
        .toList(growable: false);
    final known = _factId.isEmpty || facts.any((fact) => fact.id == _factId);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        PokeMapPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Après une défaite'),
              const SizedBox(height: 8),
              const Text(
                'Lors du retour au point de reprise, un indicateur peut être activé pour déclencher un accueil ou un dialogue. Les soins, la perte d’argent et le point de reprise suivent les règles du jeu.',
              ),
              const SizedBox(height: 16),
              PokeMapDropdownField<String>(
                key: const ValueKey('defeat-recovery-fact-picker'),
                label: 'Indicateur de retour',
                value: _factId,
                enabled: !_saving,
                items: [
                  const PokeMapDropdownItem(
                    value: '',
                    label: 'Aucun indicateur',
                  ),
                  if (!known)
                    PokeMapDropdownItem(
                      value: _factId,
                      label: 'Indicateur indisponible',
                    ),
                  for (final fact in facts)
                    PokeMapDropdownItem(value: fact.id, label: fact.label),
                ],
                onChanged: (value) => setState(() {
                  _factId = value;
                  _error = null;
                  _saved = false;
                }),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cet indicateur reste actif jusqu’à ce qu’un événement le désactive. Un combat autorisant à continuer après une défaite ne l’active pas.',
              ),
            ],
          ),
        ),
        if (!known)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.error,
              message:
                  'Choisissez un indicateur booléen du projet ou désactivez ce branchement.',
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
              message: 'Retour après défaite sauvegardé.',
            ),
          ),
        const SizedBox(height: 16),
        PokeMapButton(
          key: const ValueKey('defeat-recovery-save'),
          onPressed: _saving || !known ? null : _save,
          child: Text(_saving ? 'Enregistrement…' : 'Enregistrer'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
      _saved = false;
    });
    try {
      final config = _factId.isEmpty
          ? null
          : ProjectDefeatRecoveryConfig(recoveredFactId: _factId);
      config?.validate(widget.project.facts);
      final saved = await widget.onSave(config);
      if (!mounted) return;
      setState(() {
        _saved = saved;
        if (!saved) _error = 'La configuration n’a pas été enregistrée.';
      });
    } on Object catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
