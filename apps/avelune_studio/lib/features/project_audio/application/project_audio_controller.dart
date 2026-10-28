import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core_domain.dart';

import '../../project_session/domain/project_session.dart';
import '../domain/project_audio_port.dart';

final class ProjectAudioController extends ChangeNotifier {
  ProjectAudioController({
    required this.session,
    required this.port,
    this.audition,
    this.onSaved,
    this.onRevisionChanged,
  }) {
    audition?.playing.addListener(_playbackChanged);
  }
  final ProjectSession session;
  final ProjectAudioPort port;
  final ProjectAudioPreviewPort? audition;
  final ValueChanged<ProjectAudioSettings?>? onSaved;
  final void Function(String before, String after)? onRevisionChanged;
  final preview = ValueNotifier(ProjectAudioSettings());
  ProjectAudioState? saved;
  final library = <String, ProjectAudioEntry>{};
  String? nextCursor, error, libraryError, playingId;
  final pendingSources = <ProjectSoundCue, String>{};
  final rawGains = <ProjectSoundCue, String>{};
  final fieldErrors = <ProjectSoundCue, String>{};
  bool loading = false,
      saving = false,
      libraryLoading = false,
      importing = false;
  bool _disposed = false;
  int _libraryGeneration = 0, _previewGeneration = 0;
  String _query = '';
  final _undo = <ProjectAudioSettings>[], _redo = <ProjectAudioSettings>[];
  ProjectAudioSettings get _base =>
      saved?.configuration ?? ProjectAudioSettings();
  bool get dirty =>
      saved != null && (preview.value != _base || fieldErrors.isNotEmpty);
  bool get busy => loading || saving || importing;
  bool get canUndo => _undo.isNotEmpty || fieldErrors.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  Future<void> open() async {
    if (saved != null || loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final value = await port.loadAudio(session);
      if (!_disposed) {
        saved = value;
        preview.value = _base;
      }
    } on Object catch (failure) {
      if (!_disposed) error = '$failure';
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  void adoptRevision(String before, String after) {
    final current = saved;
    if (current != null && current.revision == before) {
      saved = ProjectAudioState(
        configuration: current.configuration,
        revision: after,
      );
    }
  }

  void _edit(ProjectAudioSettings value) {
    if (busy || saved == null || value == preview.value) return;
    _undo.add(preview.value);
    if (_undo.length > 100) _undo.removeAt(0);
    _redo.clear();
    preview.value = value;
    error = null;
    notifyListeners();
  }

  void source(ProjectSoundCue cue, String source) {
    if (busy) return;
    rawGains.remove(cue);
    fieldErrors.remove(cue);
    pendingSources.remove(cue);
    if (source == 'custom' && preview.value.cues[cue]?.mediaId == null) {
      pendingSources[cue] = source;
      fieldErrors[cue] = 'Choisissez un son dans la bibliothèque.';
      notifyListeners();
      return;
    }
    if (source == 'inherit') {
      _edit(preview.value.withCue(cue, null));
      notifyListeners();
      return;
    }
    final current = preview.value.bindingFor(cue);
    _edit(
      preview.value.withCue(
        cue,
        ProjectSoundBinding(
          source: ProjectSoundSource.values.byName(source),
          mediaId: source == 'custom' ? current.mediaId : null,
          gain: current.gain,
        ),
      ),
    );
    notifyListeners();
  }

  void assign(ProjectSoundCue cue, String mediaId) {
    if (busy) return;
    fieldErrors.remove(cue);
    pendingSources.remove(cue);
    _edit(
      preview.value.withCue(
        cue,
        ProjectSoundBinding(
          source: ProjectSoundSource.custom,
          mediaId: mediaId,
          gain: preview.value.bindingFor(cue).gain,
        ),
      ),
    );
    notifyListeners();
  }

  void gain(ProjectSoundCue cue, String raw) {
    if (busy) return;
    rawGains[cue] = raw;
    final value = double.tryParse(raw);
    if (value == null || !value.isFinite || value < 0 || value > 100) {
      fieldErrors[cue] = 'Saisissez un volume entre 0 et 100.';
      notifyListeners();
      return;
    }
    if (pendingSources.containsKey(cue)) return;
    fieldErrors.remove(cue);
    final current = preview.value.bindingFor(cue);
    _edit(
      preview.value.withCue(
        cue,
        ProjectSoundBinding(
          source: current.source,
          mediaId: current.mediaId,
          gain: value / 100,
        ),
      ),
    );
    notifyListeners();
  }

  void undo() {
    if (!canUndo || busy) return;
    if (fieldErrors.isNotEmpty) {
      fieldErrors.clear();
      pendingSources.clear();
      rawGains.clear();
    } else {
      _redo.add(preview.value);
      preview.value = _undo.removeLast();
      rawGains.clear();
    }
    notifyListeners();
  }

  void redo() {
    if (!canRedo || busy) return;
    _undo.add(preview.value);
    if (_undo.length > 100) _undo.removeAt(0);
    preview.value = _redo.removeLast();
    rawGains.clear();
    notifyListeners();
  }

  void discard() {
    if (busy) return;
    preview.value = _base;
    _undo.clear();
    _redo.clear();
    pendingSources.clear();
    rawGains.clear();
    fieldErrors.clear();
    error = null;
    notifyListeners();
  }

  Future<bool> save() async {
    if (busy || fieldErrors.isNotEmpty) return false;
    if (!dirty) return true;
    saving = true;
    error = null;
    notifyListeners();
    try {
      final draft = preview.value;
      for (final cue in ProjectSoundCue.values) {
        if (draft.cues[cue] == _base.cues[cue]) continue;
        final before = saved!.revision;
        final state = await port.saveAudioCue(
          session,
          cue,
          draft.cues[cue],
          before,
        );
        if (_disposed) return false;
        saved = state;
        onRevisionChanged?.call(before, state.revision);
        onSaved?.call(state.configuration);
      }
      return true;
    } on Object catch (failure) {
      if (!_disposed) error = '$failure';
      return false;
    } finally {
      if (!_disposed) {
        saving = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadLibrary({String? query, bool more = false}) async {
    if (libraryLoading || more && nextCursor == null) return;
    final generation = ++_libraryGeneration;
    libraryLoading = true;
    libraryError = null;
    if (!more) _query = query ?? _query;
    notifyListeners();
    try {
      final page = await port.queryAudio(
        session,
        query: _query,
        cursor: more ? nextCursor : null,
      );
      if (_disposed || generation != _libraryGeneration) return;
      if (!more) library.clear();
      library.addEntries(
        page.entries.map((entry) => MapEntry(entry.id, entry)),
      );
      nextCursor = page.nextCursor;
    } on Object catch (failure) {
      if (!_disposed && generation == _libraryGeneration) {
        libraryError = '$failure';
      }
    } finally {
      if (!_disposed && generation == _libraryGeneration) {
        libraryLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> import(String path, String label) async {
    if (busy || saved == null) return;
    importing = true;
    error = null;
    notifyListeners();
    try {
      final result = await port.importAudio(
        session,
        path,
        label,
        saved!.revision,
      );
      if (_disposed) return;
      adoptRevision(result.beforeRevision, result.revision);
      onRevisionChanged?.call(result.beforeRevision, result.revision);
      library[result.entry.id] = result.entry;
    } on Object catch (failure) {
      if (!_disposed) error = '$failure';
    } finally {
      if (!_disposed) {
        importing = false;
        notifyListeners();
      }
    }
  }

  void _playbackChanged() {
    if (_disposed) return;
    playingId = audition?.playing.value;
    notifyListeners();
  }

  Future<void> listen(String id) async {
    if (_disposed) return;
    final player = audition;
    if (player == null) return;
    if (playingId == id) {
      await stop();
      return;
    }
    final generation = ++_previewGeneration;
    playingId = null;
    notifyListeners();
    try {
      await player.stop();
      if (_disposed || generation != _previewGeneration) return;
      await player.play(id);
    } on Object catch (failure) {
      if (!_disposed && generation == _previewGeneration) {
        error = '$failure';
        notifyListeners();
      }
    }
  }

  Future<void> stop() async {
    _previewGeneration++;
    playingId = null;
    try {
      await audition?.stop();
    } on Object catch (failure) {
      if (!_disposed) error = '$failure';
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _libraryGeneration++;
    _previewGeneration++;
    audition?.playing.removeListener(_playbackChanged);
    unawaited(audition?.close());
    preview.dispose();
    super.dispose();
  }
}
