part of 'resource_pack_transfer_controller.dart';

extension _ResourcePackExportPublication on ResourcePackTransferController {
  Future<List<ResourcePackLocalDraft>> _reachedLocalDrafts(
    int epoch,
    String handle,
  ) async {
    final candidates = {
      for (final draft
          in localDrafts?.call() ?? const <ResourcePackLocalDraft>[])
        '${draft.kind}:${draft.id}': draft,
    };
    final found = <String, ResourcePackLocalDraft>{};
    if (candidates.isEmpty) return const [];
    String? cursor;
    do {
      final page = await port.transfer('preview', {
        'previewHandle': handle,
        'limit': 200,
        'cursor': ?cursor,
      });
      if (!_current(epoch) || _closing || _previewHandle != handle) {
        return const [];
      }
      for (final row in _rows(page['items'])) {
        final key = '${row['resourceKind']}:${row['nativeId']}';
        final draft = candidates[key];
        if (draft != null) found[key] = draft;
      }
      final next = page['nextCursor'] as String?;
      if (next != null && next == cursor) {
        throw const ResourceFailure('L’aperçu ne progresse plus.');
      }
      cursor = next;
    } while (cursor != null);
    final keys = found.keys.toList()..sort();
    return List.unmodifiable(keys.map((key) => found[key]!));
  }

  String _localSignature(List<ResourcePackLocalDraft> drafts) => jsonEncode(
    drafts.map((d) => [d.kind, d.id, d.signature, d.saving]).toList(),
  );
  Future<void> _export() {
    if (!canExport) return Future.value();
    return _run((epoch) async {
      final handle = _previewHandle!, prepared = _prepared!;
      final current = await _reachedLocalDrafts(epoch, handle);
      if (!_current(epoch) || _closing) return;
      if (_localSignature(current) != _localSignature(localNotices)) {
        localNotices = current;
        organizationAcknowledged = false;
        notice = 'Vos modifications en cours ont changé. Relisez les versions publiées avant de poursuivre.';
        return;
      }
      phase = ResourcePackTransferPhase.building;
      _changed();
      final artifact = await _monitor(
        await port.transfer('export', {
          'preparedExportHandle': prepared,
          'acknowledgeOrganizationRemoval': organizationAcknowledged,
        }),
      );
      _artifactHandle = artifact['artifactHandle']! as String;
      if (!_current(epoch) || _closing) return;
      phase = ResourcePackTransferPhase.writing;
      cancelAllowed = true;
      _changed();
      var published = false;
      try {
        final result = await exportSink!.publish(
          suggestedName: '${exportFields['name']}.aveluneassets',
          byteLength: artifact['byteLength']! as int,
          rawSha256: artifact['rawSha256']! as String,
          readChunk: (offset, length) => port.readExportPayloadChunk(
            artifact['payloadRef']! as String,
            offset,
            length,
          ),
          isCancelled: () => _closing || !_current(epoch),
          enterFinalization: () {
            if (_closing || !_current(epoch)) throw const _PackCancelled();
            cancelAllowed = false;
            phase = ResourcePackTransferPhase.publishing;
            _changed();
          },
        );
        published = result.published;
        _acceptPublication(result);
      } finally {
        try {
          await _releaseArtifact();
        } on Object catch (failure) {
          if (published) {
            notice = '$notice · Nettoyage à reprendre : $failure';
          } else {
            rethrow;
          }
        }
      }
    });
  }

  void _acceptPublication(ResourcePackPublication result) {
    _pendingPublicationToken = result.pendingToken;
    if (result.pendingToken != null) {
      phase = ResourcePackTransferPhase.publicationRequired;
      cancelAllowed = false;
      notice = result.warning ?? 'Le résultat de publication doit être relu avant de fermer le projet.';
      return;
    }
    if (result.published) {
      outputPath = result.path;
      phase = ResourcePackTransferPhase.complete;
      notice =
          'Pack exporté : ${result.path}${result.warning == null ? '' : ' · ${result.warning}'}';
    } else {
      phase = ResourcePackTransferPhase.preview;
      notice = result.warning ?? 'Export annulé. Aucun fichier n’a été publié.';
    }
  }

  Future<void> _releaseArtifact() async {
    final handle = _artifactHandle;
    if (handle == null) return;
    await port.transfer('release', {'handle': handle});
    _handles.remove(handle);
    _artifactHandle = null;
  }
}
