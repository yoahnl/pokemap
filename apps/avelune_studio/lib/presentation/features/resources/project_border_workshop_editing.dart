part of 'project_border_workshop.dart';

const _pendingBorderReadMessage =
    'La bordure est enregistrée. Relisez l’enregistrement pour continuer.';

extension _ProjectBorderWorkshopEditing on _ProjectBorderWorkshopState {
  Widget _draftFields(
    _BorderWorkshopView read,
    BorderBlueprintRecord record,
    ProjectBorderWorkshopPort editor,
    String revision,
  ) {
    final input = _input ??= BorderWorkshopDraftInput(record.draft);
    final pending = _pendingReceipt;
    final reopenRequired =
        _reopenRequired ||
        pending != null &&
            read.revision != pending.beforeRevision &&
            read.revision != pending.revision;
    final enabled = !_saving && pending == null;
    final save = enabled ? input.candidate : null;
    final canPublish =
        enabled && !input.hasChanges && _differentPublication(record);
    return ProjectBorderWorkshopDraftFields(
      input: input,
      models: read.project.models3d,
      enabled: enabled,
      awaitingRecovery: pending != null,
      reopenRequired: reopenRequired,
      status: _saving ? 'Enregistrement en cours…' : _status,
      problem: reopenRequired ? BorderWorkshopReopenRequired.message : _problem,
      onChange: (change) => _update(() {
        change();
        _status = null;
      }),
      onSave: save == null
          ? null
          : () => _write(
              read,
              () => editor.saveBorderDraft(
                record.id,
                draft: save,
                expectedRevision: revision,
              ),
            ),
      onPublish: canPublish
          ? () => _confirmPublication(read, editor, record.id, revision)
          : null,
      onReconcile: pending == null || _saving || reopenRequired
          ? null
          : () => _write(read, () async {
              await editor.reconcileBorderWorkshop(record.id, pending);
              return pending;
            }),
    );
  }

  Future<void> _confirmPublication(
    _BorderWorkshopView read,
    ProjectBorderWorkshopPort editor,
    String borderId,
    String revision,
  ) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => StudioReviewDialog(
        title: 'Publier le brouillon ?',
        content: const Text(
          'La nouvelle version servira aux prochaines poses et à la régénération des bordures existantes.',
        ),
        confirmLabel: 'Publier la bordure',
        onConfirmed: () => Navigator.pop(context, true),
        onCancelled: () => Navigator.pop(context, false),
      ),
    );
    if (!mounted || accepted != true) return;
    await _write(
      read,
      () => editor.publishBorderDraft(borderId, expectedRevision: revision),
    );
  }

  Future<void> _write(
    _BorderWorkshopView read,
    Future<ResourceMutationReceipt> Function() operation,
  ) async {
    if (_saving) return;
    final reading = _reading;
    bool current() => mounted && identical(reading, _reading);
    final onBusyChanged = widget.onBusyChanged;
    final onPendingChanged = widget.onPendingReceiptChanged;
    final previousPending = _pendingReceipt;
    _update(() {
      _saving = true;
      _problem = null;
      _status = null;
    });
    ResourceMutationReceipt? completed;
    try {
      onBusyChanged?.call(true);
      final receipt = completed = await operation();
      if (!current()) {
        onPendingChanged?.call(receipt);
        return;
      }
      final border = receipt.manifest.borderCatalog.recordById(widget.item.id);
      if (border == null) {
        throw const ResourceFailure(
          'Le brouillon enregistré est indisponible.',
        );
      }
      await widget.onUpdated?.call(receipt);
      if (!current()) {
        onPendingChanged?.call(null);
        return;
      }
      final catalog = read.project.borderCatalog;
      final published = receipt.actionId == 'border.blueprint.publish';
      _update(() {
        _lastSaved = (
          project: read.project.copyWith(
            borderCatalog: ProjectBorderCatalog(
              formatVersion: receipt.manifest.borderCatalog.formatVersion,
              records: [
                for (final item in catalog.records)
                  item.id == border.id ? border : item,
              ],
              visualSnapshots: catalog.visualSnapshots,
            ),
          ),
          revision: receipt.revision,
        );
        _assemblies.remove(true);
        if (published) _assemblies.remove(false);
        _input = null;
        _pendingReceipt = null;
        _reopenRequired = false;
        _status = published ? 'Bordure publiée' : 'Brouillon enregistré';
      });
      if (previousPending != null) onPendingChanged?.call(null);
    } on Object catch (error) {
      final pending =
          (error is ResourceFailure ? error.partialReceipt : null) ??
          completed ??
          previousPending;
      if (!current()) {
        if (pending != null) onPendingChanged?.call(pending);
        return;
      }
      _update(() {
        _pendingReceipt = pending;
        _reopenRequired = error is BorderWorkshopReopenRequired;
        _problem = error is ResourceFailure && _pendingReceipt == null
            ? error.message
            : _pendingReceipt == null
            ? 'Impossible d’enregistrer la bordure. Votre saisie est conservée.'
            : _pendingBorderReadMessage;
      });
      if (!identical(previousPending, pending)) onPendingChanged?.call(pending);
    } finally {
      if (current()) _update(() => _saving = false);
      onBusyChanged?.call(false);
    }
  }

  Future<void> _leave() async {
    if (_pendingReceipt != null && widget.onPendingReceiptChanged == null) {
      return;
    }
    if (_hasUnappliedDraft) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => StudioReviewDialog(
          title: 'Quitter l’atelier ?',
          content: const Text(
            'Le brouillon affiché contient des changements à enregistrer.',
          ),
          cancelLabel: 'Rester dans l’atelier',
          confirmLabel: 'Quitter sans enregistrer',
          onConfirmed: () => Navigator.pop(context, true),
          onCancelled: () => Navigator.pop(context, false),
        ),
      );
      if (!mounted || accepted != true) return;
      _update(() => _input = null);
    }
    widget.onBack();
  }
}

bool _differentPublication(BorderBlueprintRecord record) {
  final definition = record.draft.definition;
  return definition.primitives.any((piece) => piece.weight > 0) &&
      spatialBorderPublicationDefinition(definition) !=
          record.latestPublished?.definition;
}
