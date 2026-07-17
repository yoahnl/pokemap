import 'package:flutter/cupertino.dart';
import 'package:map_core/map_core.dart';

import '../../../application/models/narrative_event_migration_persistence_models.dart';
import '../../design_system/design_system.dart';

class EventBuilderV2MigrationSheet extends StatefulWidget {
  const EventBuilderV2MigrationSheet({
    super.key,
    required this.preview,
    required this.onCancel,
    required this.onCommit,
    this.onRecover,
    this.onActivateV2,
  });

  final NarrativeEventMigrationPreview preview;
  final VoidCallback onCancel;
  final Future<NarrativeEventMigrationPersistenceResult> Function() onCommit;
  final Future<NarrativeEventMigrationPersistenceResult> Function()? onRecover;
  final Future<NarrativeEventMigrationPersistenceResult> Function()?
      onActivateV2;

  @override
  State<EventBuilderV2MigrationSheet> createState() =>
      _EventBuilderV2MigrationSheetState();
}

class _EventBuilderV2MigrationSheetState
    extends State<EventBuilderV2MigrationSheet> {
  bool _working = false;
  NarrativeEventMigrationPersistenceResult? _result;

  @override
  Widget build(BuildContext context) {
    final preview = widget.preview;
    final blockers = preview.plan.diagnostics.where(
      (diagnostic) =>
          diagnostic.severity == LegacyMigrationDiagnosticSeverity.error,
    );
    final canActivateV2 = preview.modeBefore == EventSystemMode.legacyOnly &&
        widget.onActivateV2 != null;
    final hasLegacyContent = preview.legacyItemCount > 0;
    return PokeMapPageSurface(
      key: const ValueKey('event-builder-v2-migration-sheet'),
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Text(
            'Préparer les événements V2',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'PokeMap convertit les événements historiques à partir des '
            'éléments déjà présents dans vos maps. Aucun JSON n’est demandé.',
            style: TextStyle(fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 14),
          PokeMapCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MigrationCount(
                  icon: CupertinoIcons.bolt_circle,
                  label: _countLabel(
                    preview.proposedEventCount,
                    singular: 'événement à créer',
                    plural: 'événements à créer',
                  ),
                ),
                const SizedBox(height: 8),
                _MigrationCount(
                  icon: CupertinoIcons.link,
                  label: _countLabel(
                    preview.proposedClaimCount,
                    singular: 'lien de compatibilité',
                    plural: 'liens de compatibilité',
                  ),
                ),
                const SizedBox(height: 8),
                _MigrationCount(
                  icon: CupertinoIcons.checkmark_shield,
                  label: _countLabel(
                    preview.choiceCount,
                    singular: 'correspondance confirmée',
                    plural: 'correspondances confirmées',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const PokeMapDiagnosticCallout(
            severity: PokeMapDiagnosticSeverity.info,
            title: 'Activation séparée',
            message: 'Après cette préparation, le mode de jeu reste inchangé. '
                'Les nouveaux événements restent désactivés jusqu’à leur '
                'validation explicite.',
          ),
          if (canActivateV2) ...[
            const SizedBox(height: 12),
            PokeMapDiagnosticCallout(
              severity: PokeMapDiagnosticSeverity.info,
              title: hasLegacyContent
                  ? 'Compatibilité historique disponible'
                  : 'Projet sans événement historique',
              message: hasLegacyContent
                  ? 'Activez Event V2 en conservant les sources historiques '
                      'non converties dans leur runtime actuel.'
                  : 'Aucune source historique n’est à convertir. Vous pouvez '
                      'activer Event V2 explicitement pour ce projet.',
            ),
          ],
          if (blockers.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final blocker in blockers) ...[
              PokeMapDiagnosticCallout(
                severity: PokeMapDiagnosticSeverity.error,
                title: 'Conversion bloquée',
                message: blocker.message,
              ),
              const SizedBox(height: 8),
            ],
          ],
          if (_result != null) ...[
            const SizedBox(height: 12),
            PokeMapDiagnosticCallout(
              key: const ValueKey('event-migration-result'),
              severity: _result!.succeeded
                  ? PokeMapDiagnosticSeverity.info
                  : PokeMapDiagnosticSeverity.warning,
              title:
                  _result!.succeeded ? 'Opération terminée' : 'Action requise',
              message: _result!.message,
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: PokeMapButton(
                  key: const ValueKey('event-migration-cancel'),
                  onPressed: _working ? null : widget.onCancel,
                  variant: PokeMapButtonVariant.ghost,
                  child: const Text('Annuler'),
                ),
              ),
              if (widget.onRecover != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: PokeMapButton(
                    key: const ValueKey('event-migration-recover'),
                    onPressed: _working ? null : _recover,
                    variant: PokeMapButtonVariant.secondary,
                    child: const Text('Récupérer'),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: PokeMapButton(
                  key: const ValueKey('event-migration-commit'),
                  onPressed: !_working && preview.canCommit ? _commit : null,
                  variant: PokeMapButtonVariant.primary,
                  leading: _working
                      ? const CupertinoActivityIndicator()
                      : const Icon(CupertinoIcons.arrow_right_circle_fill),
                  child: const Text('Préparer'),
                ),
              ),
              if (canActivateV2) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: PokeMapButton(
                    key: const ValueKey('event-migration-activate-v2'),
                    onPressed: _working ? null : _activateV2,
                    variant: PokeMapButtonVariant.primary,
                    leading: _working
                        ? const CupertinoActivityIndicator()
                        : const Icon(CupertinoIcons.checkmark_shield_fill),
                    child: Text(
                      hasLegacyContent ? 'Activer en parallèle' : 'Activer V2',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _commit() async {
    setState(() => _working = true);
    final result = await widget.onCommit();
    if (!mounted) return;
    setState(() {
      _working = false;
      _result = result;
    });
  }

  Future<void> _recover() async {
    setState(() => _working = true);
    final result = await widget.onRecover!();
    if (!mounted) return;
    setState(() {
      _working = false;
      _result = result;
    });
  }

  Future<void> _activateV2() async {
    setState(() => _working = true);
    final result = await widget.onActivateV2!();
    if (!mounted) return;
    setState(() {
      _working = false;
      _result = result;
    });
  }
}

class _MigrationCount extends StatelessWidget {
  const _MigrationCount({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

String _countLabel(
  int count, {
  required String singular,
  required String plural,
}) =>
    '$count ${count == 1 ? singular : plural}';
