import 'package:flutter/foundation.dart';
import 'package:map_core/map_core_domain.dart';

import '../../project_audio/application/project_audio_controller.dart';
import '../../project_cs/application/project_cs_controller.dart';
import '../../project_surf/application/project_surf_controller.dart';
import '../../project_visuals/application/project_visuals_controller.dart';
import 'project_settings_drafts.dart';

export 'project_settings_drafts.dart';

enum ProjectSettingsSection {
  general,
  fieldAbilities,
  image,
  timeWeather,
  sounds,
  verification;

  bool get followsScope => this == image || this == timeWeather;
}

bool isImageVisualParameter(SpatialVisualParameter parameter) =>
    parameter.isCamera || (parameter.isAtmosphere && !parameter.isWeather);

bool isTimeWeatherVisualParameter(SpatialVisualParameter parameter) =>
    !isImageVisualParameter(parameter);

final class ProjectSettingsSessionController extends ChangeNotifier {
  ProjectSettingsSessionController({
    required this.projectVisuals,
    this.mapVisuals,
    this.fieldAbilities,
    this.surf,
    this.audio,
    this.general,
    ProjectSettingsSection initialSection = ProjectSettingsSection.general,
  }) : _section = initialSection {
    _listen();
  }

  final ProjectVisualsController projectVisuals;
  final ProjectVisualsController? Function(String mapId)? mapVisuals;
  final ProjectCsController? fieldAbilities;
  final ProjectSurfController? surf;
  final ProjectAudioController? audio;
  final ProjectSettingsDraft? general;
  ProjectSettingsSection _section;
  String? _scopeMapId;
  final _confirmed = <(ProjectSettingsSection, String?)>{};
  final _listening = <Listenable>{};
  bool _disposed = false;

  ProjectSettingsSection get section => _section;
  String? get scopeMapId => _scopeMapId;

  ProjectVisualsController? get scopedVisuals {
    final id = _scopeMapId;
    return id == null ? projectVisuals : mapVisuals?.call(id);
  }

  void select(ProjectSettingsSection section) {
    if (_disposed || section == _section) return;
    _section = section;
    notifyListeners();
  }

  void scopeTo(String? mapId) {
    if (_disposed || mapId == _scopeMapId) return;
    _scopeMapId = mapId;
    _listen();
    notifyListeners();
  }

  ProjectSettingsDraft? draft(ProjectSettingsSection section) =>
      _draftFor(section, _scopeMapId);

  ProjectSettingsDraft? _draftFor(
    ProjectSettingsSection section,
    String? mapId,
  ) {
    ProjectVisualsController? visuals() =>
        mapId == null ? projectVisuals : mapVisuals?.call(mapId);
    return switch (section) {
      ProjectSettingsSection.general => general,
      ProjectSettingsSection.fieldAbilities =>
        fieldAbilities == null && surf == null
            ? null
            : FieldAbilitySettingsDraft(fieldAbilities, surf),
      ProjectSettingsSection.image => switch (visuals()) {
        final owner? => VisualSettingsDraft(owner, isImageVisualParameter),
        null => null,
      },
      ProjectSettingsSection.timeWeather => switch (visuals()) {
        final owner? => VisualSettingsDraft(
          owner,
          isTimeWeatherVisualParameter,
        ),
        null => null,
      },
      ProjectSettingsSection.sounds => switch (audio) {
        final owner? => SoundSettingsDraft(owner),
        null => null,
      },
      ProjectSettingsSection.verification => null,
    };
  }

  String? _scopeKey(ProjectSettingsSection section) =>
      section.followsScope ? _scopeMapId : null;

  bool isDirty(ProjectSettingsSection section) => draft(section)?.dirty == true;

  bool hasOtherScopeDraft(ProjectSettingsSection section) {
    if (!section.followsScope) return false;
    final other = _scopeMapId == null ? null : _draftFor(section, null);
    return other?.dirty == true;
  }

  bool isSaving(ProjectSettingsSection section) =>
      draft(section)?.saving == true;

  bool isConfirmed(ProjectSettingsSection section) =>
      _confirmed.contains((section, _scopeKey(section))) && !isDirty(section);

  String? errorOf(ProjectSettingsSection section) => draft(section)?.error;

  bool canUndo(ProjectSettingsSection section) =>
      draft(section)?.canUndo == true;

  bool canRedo(ProjectSettingsSection section) =>
      draft(section)?.canRedo == true;

  bool canSave(ProjectSettingsSection section) {
    final value = draft(section);
    return value != null &&
        value.ready &&
        value.dirty &&
        !value.saving &&
        !value.blocked;
  }

  Set<ProjectSettingsSection> get dirtySections => {
    for (final section in ProjectSettingsSection.values)
      if (isDirty(section) || hasOtherScopeDraft(section)) section,
  };

  Future<bool> save(ProjectSettingsSection section) async {
    final value = draft(section);
    if (value == null) return false;
    final key = (section, _scopeKey(section));
    _confirmed.remove(key);
    final saved = await value.save();
    if (_disposed) return saved;
    if (saved) _confirmed.add(key);
    notifyListeners();
    return saved;
  }

  void discard(ProjectSettingsSection section) {
    final value = draft(section);
    if (value == null || value.saving) return;
    value.discard();
  }

  void undo(ProjectSettingsSection section) => draft(section)?.undo();

  void redo(ProjectSettingsSection section) => draft(section)?.redo();

  void _listen() {
    final next = <Listenable>{
      projectVisuals,
      ?scopedVisuals,
      ?fieldAbilities,
      ?surf,
      ?audio,
      ?general?.changes,
    };
    for (final source in _listening.difference(next)) {
      source.removeListener(_changed);
    }
    for (final source in next.difference(_listening)) {
      source.addListener(_changed);
    }
    _listening
      ..clear()
      ..addAll(next);
  }

  void _changed() {
    if (_disposed) return;
    _confirmed.removeWhere((key) {
      final value = _draftFor(key.$1, key.$2);
      return value == null || value.dirty;
    });
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    for (final source in _listening) {
      source.removeListener(_changed);
    }
    _listening.clear();
    super.dispose();
  }
}
