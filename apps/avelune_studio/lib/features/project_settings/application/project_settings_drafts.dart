import 'package:flutter/foundation.dart';
import 'package:map_core/map_core_domain.dart';

import '../../project_audio/application/project_audio_controller.dart';
import '../../project_cs/application/project_cs_controller.dart';
import '../../project_surf/application/project_surf_controller.dart';
import '../../project_visuals/application/project_visuals_controller.dart';
import 'project_identity_controller.dart';

abstract interface class ProjectSettingsDraft {
  Listenable get changes;
  bool get ready;
  bool get dirty;
  bool get needsFirstSave;
  bool get saving;
  bool get blocked;
  String? get error;
  bool get canUndo;
  bool get canRedo;
  Future<bool> save();
  void discard();
  void undo();
  void redo();
}

final class VisualSettingsDraft implements ProjectSettingsDraft {
  VisualSettingsDraft(this.owner, this.owns);
  final ProjectVisualsController owner;
  final SpatialVisualScope owns;
  @override
  Listenable get changes => owner;
  @override
  bool get ready => owner.saved != null && !owner.loading;
  @override
  bool get dirty => owner.dirtyWhere(owns);
  @override
  bool get needsFirstSave => false;
  @override
  bool get saving => owner.saving;
  @override
  bool get blocked => owner.invalidWhere(owns);
  @override
  String? get error => owner.error;
  @override
  bool get canUndo => owner.canUndoWhere(owns);
  @override
  bool get canRedo => owner.canRedoWhere(owns);
  @override
  Future<bool> save() => owner.saveWhere(owns);
  @override
  void discard() => owner.discardWhere(owns);
  @override
  void undo() => owner.undoWhere(owns);
  @override
  void redo() => owner.redoWhere(owns);
}

final class FieldAbilitySettingsDraft implements ProjectSettingsDraft {
  FieldAbilitySettingsDraft(this.abilities, this.surf);
  final ProjectCsController? abilities;
  final ProjectSurfController? surf;
  @override
  Listenable get changes => Listenable.merge([?abilities, ?surf]);
  @override
  bool get ready =>
      (abilities == null || abilities!.saved != null) &&
      (surf == null || surf!.saved != null);
  @override
  bool get dirty => abilities?.dirty == true || surf?.dirty == true;
  @override
  bool get needsFirstSave => false;
  @override
  bool get saving => abilities?.saving == true || surf?.saving == true;
  @override
  bool get blocked {
    final owner = surf;
    if (owner == null) return false;
    final configuration = owner.preview.value;
    return owner.inputError != null ||
        owner.speedInputError != null ||
        (configuration.accessMode == ProjectSurfAccessMode.condition &&
            configuration.condition == null);
  }

  @override
  String? get error => surf?.error ?? abilities?.error;
  @override
  bool get canUndo => abilities?.canUndo == true || surf?.canUndo == true;
  @override
  bool get canRedo => abilities?.canRedo == true || surf?.canRedo == true;
  @override
  Future<bool> save() async {
    if (surf case final owner? when !await owner.save()) return false;
    if (abilities case final owner? when !await owner.save()) return false;
    return true;
  }

  @override
  void discard() {
    abilities?.discard();
    surf?.discard();
  }

  @override
  void undo() {
    if (surf?.canUndo == true) {
      surf!.undo();
    } else {
      abilities?.undo();
    }
  }

  @override
  void redo() {
    if (abilities?.canRedo == true) {
      abilities!.redo();
    } else {
      surf?.redo();
    }
  }
}

final class SoundSettingsDraft implements ProjectSettingsDraft {
  SoundSettingsDraft(this.owner);
  final ProjectAudioController owner;
  @override
  Listenable get changes => owner;
  @override
  bool get ready => owner.saved != null && !owner.loading;
  @override
  bool get dirty => owner.dirty;
  @override
  bool get needsFirstSave => false;
  @override
  bool get saving => owner.saving;
  @override
  bool get blocked => owner.fieldErrors.isNotEmpty;
  @override
  String? get error => owner.error;
  @override
  bool get canUndo => owner.canUndo;
  @override
  bool get canRedo => owner.canRedo;
  @override
  Future<bool> save() => owner.save();
  @override
  void discard() => owner.discard();
  @override
  void undo() => owner.undo();
  @override
  void redo() => owner.redo();
}

final class IdentitySettingsDraft implements ProjectSettingsDraft {
  IdentitySettingsDraft(this.owner);
  final ProjectIdentityController owner;
  @override
  Listenable get changes => owner;
  @override
  bool get ready => owner.ready;
  @override
  bool get dirty => owner.dirty;
  @override
  bool get needsFirstSave => owner.needsFirstSave;
  @override
  bool get saving => owner.saving;
  @override
  bool get blocked => owner.blocked;
  @override
  String? get error => owner.conflict == null ? owner.error : null;
  @override
  bool get canUndo => false;
  @override
  bool get canRedo => false;
  @override
  Future<bool> save() => owner.save();
  @override
  void discard() => owner.discard();
  @override
  void undo() {}
  @override
  void redo() {}
}
