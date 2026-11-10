import 'package:map_core/map_core_domain.dart';

import '../../presentations/domain/presentation_media_picker.dart';
import 'project_audio_controller.dart';

const projectAudioSourceOptions = {
  'inherit': 'Réglage par défaut (hérité)',
  'builtin': 'Son intégré de cette action',
  'silent': 'Aucun son',
  'custom': 'Son personnalisé de la bibliothèque',
};

class ProjectAudioEditingSession {
  ProjectAudioEditingSession({
    required this.owner,
    this.pickMedia,
    ProjectSoundCue? selected,
  }) : _selected = selected ?? ProjectSoundCue.uiConfirm;

  final ProjectAudioController owner;
  final PickPresentationMedia? pickMedia;
  ProjectSoundCue _selected;
  bool _closed = false;
  Future<void>? _closing;

  ProjectSoundCue get selected => _selected;
  bool get available => !_closed && !owner.busy && owner.saved != null;
  ProjectSoundBinding get binding => owner.preview.value.bindingFor(selected);
  String get source => owner.pendingSources[selected] ??
      owner.preview.value.cues[selected]?.source.name ?? 'inherit';

  bool get canListenAssociation => available && source == 'custom' &&
      binding.mediaId != null && !owner.fieldErrors.containsKey(selected);

  bool get canSaveAssociation => available && owner.dirtyCues.contains(selected) &&
      !owner.fieldErrors.containsKey(selected) &&
      !owner.pendingSources.containsKey(selected);

  Future<void> open() async {
    await owner.open();
    if (_closed) return;
    await Future.wait([
      if (owner.library.isEmpty) owner.loadLibrary(),
      if (owner.legacyLibrary.isEmpty) owner.loadLegacyLibrary(),
    ]);
  }

  Future<bool> select(ProjectSoundCue cue) async {
    if (_closed || cue == _selected) return false;
    final stopped = owner.stop();
    _selected = cue;
    await stopped;
    return !_closed;
  }

  Future<void> listenAssociation() async {
    if (canListenAssociation) await owner.listen(binding.mediaId!);
  }

  Future<void> importSound() async {
    final pick = pickMedia;
    if (_closed || pick == null) return;
    final file = await pick(ProjectMediaKind.audio);
    if (file != null && !_closed) await owner.import(file.path, file.label);
  }

  String intention(ProjectSoundCue cue) {
    final pending = owner.pendingSources[cue];
    final binding = owner.preview.value.cues[cue];
    if (pending == 'custom') return 'Son de la bibliothèque à choisir';
    if (binding == null) return 'Réglage par défaut';
    return switch (binding.source) {
      ProjectSoundSource.builtin => 'Son intégré · ${(binding.gain * 100).round()} %',
      ProjectSoundSource.silent => 'Aucun son',
      ProjectSoundSource.custom =>
        '${owner.library[binding.mediaId]?.label ?? 'Son enregistré'} · '
        '${(binding.gain * 100).round()} %',
    };
  }

  Future<void> suspend() => _closed ? Future.value() : owner.stop();

  Future<void> close() {
    if (_closing != null) return _closing!;
    _closed = true;
    return _closing = owner.stop();
  }
}
