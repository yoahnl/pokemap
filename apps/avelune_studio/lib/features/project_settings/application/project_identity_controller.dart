import 'package:flutter/foundation.dart';

import '../../game_export/domain/studio_game_export_port.dart';

export '../../game_export/domain/studio_game_export_port.dart'
    show
        StudioGameExportMetadata,
        StudioGameIdentityField,
        StudioGameIdentityState;

String studioGameIdSlug(String value) {
  final slug = value
      .toLowerCase()
      .replaceAll(RegExp('[àâä]'), 'a')
      .replaceAll(RegExp('[éèêë]'), 'e')
      .replaceAll(RegExp('[îï]'), 'i')
      .replaceAll(RegExp('[ôö]'), 'o')
      .replaceAll(RegExp('[ùûü]'), 'u')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp('^-+|-+\$'), '');
  if (slug.isEmpty) return 'jeu';
  return RegExp('^[a-z]').hasMatch(slug) ? slug : 'jeu-$slug';
}

final class ProjectIdentityController extends ChangeNotifier {
  ProjectIdentityController({required this.port});

  final StudioGameExportPort port;
  StudioGameIdentityState? saved;
  StudioGameIdentityState? conflict;
  late StudioGameExportMetadata draft = proposed;
  bool loading = false, saving = false;
  String? error;
  final fieldErrors = <StudioGameIdentityField, String>{};
  int _generation = 0;
  bool _disposed = false;

  StudioGameExportMetadata get proposed => StudioGameExportMetadata(
    gameId: 'games.avelune.${studioGameIdSlug(port.projectName)}',
    title: port.projectName,
    version: '0.1.0',
    author: 'Équipe du projet',
    locale: 'fr',
    locales: 'fr',
  );

  bool get ready => saved != null && !loading;
  bool get exists => saved?.metadata != null;
  StudioGameExportMetadata get persisted => saved?.metadata ?? proposed;
  StudioGameExportMetadata get exportMetadata => persisted;
  bool get dirty => saved != null && draft != persisted;
  bool get needsFirstSave => saved != null && !exists;
  bool get blocked => fieldErrors.isNotEmpty || conflict != null;

  Future<void> open() async {
    final generation = ++_generation;
    loading = true;
    error = null;
    _notify();
    try {
      final value = await port.readIdentity();
      if (_disposed || generation != _generation) return;
      final keepDraft = saved != null && dirty;
      saved = value;
      conflict = null;
      if (!keepDraft) draft = persisted;
      _validate();
    } on Object catch (failure) {
      if (!_disposed && generation == _generation) {
        error = 'Profil d’export illisible : $failure';
      }
    } finally {
      if (!_disposed && generation == _generation) {
        loading = false;
        _notify();
      }
    }
  }

  void edit({
    String? title,
    String? version,
    String? author,
    String? locale,
    String? locales,
  }) {
    if (saving || saved == null) return;
    final next = draft.copyWith(
      title: title,
      version: version,
      author: author,
      locale: locale,
      locales: locales,
    );
    if (next == draft) return;
    draft = next;
    error = null;
    _validate();
    _notify();
  }

  void _validate() {
    fieldErrors.clear();
    final problem = port.checkIdentity(draft);
    if (problem == null) return;
    fieldErrors[problem.field ?? StudioGameIdentityField.title] =
        problem.message;
  }

  void discard() {
    if (saving || saved == null) return;
    draft = persisted;
    error = null;
    _validate();
    _notify();
  }

  void reloadExternal() {
    final external = conflict;
    if (external == null || saving) return;
    saved = external;
    conflict = null;
    error = null;
    draft = persisted;
    _validate();
    _notify();
  }

  void keepDraftOnNewContext() {
    final external = conflict;
    if (external == null || saving) return;
    if (external.profileRevision != saved?.profileRevision) return;
    saved = external;
    conflict = null;
    error = null;
    _validate();
    _notify();
  }

  Future<bool> save() async {
    final base = saved;
    if (base == null || saving || loading) return false;
    if (!dirty && exists) return true;
    _validate();
    if (fieldErrors.isNotEmpty || conflict != null) {
      _notify();
      return false;
    }
    final generation = _generation;
    saving = true;
    error = null;
    _notify();
    try {
      final value = await port.saveIdentity(
        draft,
        expectedProfileRevision: base.profileRevision,
        expectedContextRevision: base.contextRevision,
      );
      if (_disposed || generation != _generation) return false;
      saved = value;
      draft = persisted;
      return true;
    } on StudioGameIdentityConflict catch (failure) {
      if (_disposed || generation != _generation) return false;
      conflict = failure.current;
      error = failure.contextOnly
          ? 'Le projet a changé depuis l’ouverture de cette rubrique (fichier '
                'projet, carte de départ ou images déclarées). L’identité '
                'enregistrée est la même : vous pouvez reprendre votre brouillon '
                'sur ce nouveau contexte.'
          : 'L’identité du jeu a été modifiée ailleurs. Votre brouillon est '
                'conservé et la version enregistrée n’a pas été remplacée.';
      return false;
    } on Object catch (failure) {
      if (!_disposed && generation == _generation) {
        error = 'Enregistrement impossible : $failure';
      }
      return false;
    } finally {
      if (!_disposed && generation == _generation) {
        saving = false;
        _notify();
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    super.dispose();
  }
}
