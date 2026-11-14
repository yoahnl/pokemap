part of 'terrain_draft_controller.dart';

extension _TerrainDraftSave on TerrainDraftController {
  Future<bool> _save(
    MutateTerrainResource mutate, {
    bool publish = false,
  }) async {
    if (busy) return false;
    if (publishedPreset case final preset?) {
      final problem = terrainPresetCompatibilityProblem(manifest, preset);
      if (problem != null) {
        error = problem;
        return false;
      }
      draft = draft.copyWith(sourcePresetId: draft.targetPresetId);
    }
    if (publish && !complete) {
      error = 'Associez les ${draft.rules.length} raccords avant de publier.';
      return false;
    }
    busy = true;
    error = null;
    publicationFailedAfterSave = false;
    final snapshot = draft;
    var saved = false;
    try {
      final canonical = manifest.smartTileCatalog.drafts
          .where((d) => d.id == snapshot.id)
          .firstOrNull;
      if (_saved != snapshot || canonical != snapshot || !publish) {
        manifest = await mutate('smart_tile.preset.draft.upsert', {
          'draft': snapshot.toJson(),
        });
        _saved =
            manifest.smartTileCatalog.drafts
                .where((d) => d.id == snapshot.id)
                .firstOrNull ??
            snapshot;
        if (draft == snapshot) draft = _saved!;
      }
      saved = true;
      if (publish) {
        manifest = await mutate('smart_tile.preset.publish', {
          'draftId': snapshot.id,
        });
        if (draft == _saved) {
          draft = draft.copyWith(sourcePresetId: draft.targetPresetId);
          _saved = draft;
        }
      }
      return true;
    } catch (failure) {
      publicationFailedAfterSave = publish && saved;
      error = publicationFailedAfterSave
          ? 'Brouillon enregistré ; publication non effectuée\n$failure'
          : failure.toString();
      return false;
    } finally {
      busy = false;
    }
  }
}
